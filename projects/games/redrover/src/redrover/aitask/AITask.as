package redrover.aitask {

/**
 * The base class for the nodes of the AI behavior tree.
 */
public class AITask
{
    /**
     * Returns the name of the task.
     * Subclasses can override this to return their own name.
     */
    public function get name () :String
    {
        return "[unnamed]";
    }

    /**
     * Advances the logic of the AITask.
     * @return true if the task is complete
     * Subclasses should override this to do something interesting.
     */
    public function update (dt :Number) :Boolean
    {
        return false;
    }

    /**
     * Returns a copy of this AITask.
     * AITasks that will be in repeating task sequences must implement this function.
     */
    public function clone () :AITask
    {
        throw new Error("This task does not implement clone()");
    }

    /**
     * Delivers a message to this task's parent. If the node has no
     * parent, the message will not be delivered.
     */
    protected function sendParentMessage (messageName :String, data :Object = null) :void
    {
        if (null != _parent) {
            _parent.receiveSubtaskMessageInternal(this, messageName, data);
        }
    }

    internal var _parent :AITaskTree;
}

}
