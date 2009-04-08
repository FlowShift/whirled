package vampire.feeding.variant {

public class Variant
{
    public static const INVALID :int = 0;
    public static const NORMAL :int = 1;
    public static const CORRUPTION :int = 2;

    public static function getSettings (variant :int) :Settings
    {
        var settings :Settings;
        switch (variant) {
        case NORMAL:
            settings = normal();
            break;

        case CORRUPTION:
            settings = corruption();
            break;

        default:
            throw new Error("Unrecognized variant type " + variant);
        }

        settings.variant = variant;
        return settings;
    }

    protected static function normal () :Settings
    {
        var settings :Settings = new Settings();

        settings.boardCreatesWhiteCells = true;
        settings.playerCreatesWhiteCells = false;
        settings.playerWhiteCellCreationTime = 0;
        settings.playerCarriesWhiteCells = true;
        settings.canDropWhiteCells = false;
        settings.scoreCorruption = false;
        settings.normalCellBirthTime = 0.5;
        settings.whiteCellBirthTime = 0.5;
        settings.whiteCellNormalTime = 8;
        settings.whiteCellExplodeTime = 7;
        settings.normalCellSpeed = 5;
        settings.whiteCellSpeed = 5;

        return settings;
    }

    protected static function corruption () :Settings
    {
        var settings :Settings = new Settings();

        settings.boardCreatesWhiteCells = false;
        settings.playerCreatesWhiteCells = true;
        settings.playerWhiteCellCreationTime = 2;
        settings.playerCarriesWhiteCells = false;
        settings.canDropWhiteCells = true;
        settings.scoreCorruption = true;
        settings.normalCellBirthTime = 0.5;
        settings.whiteCellBirthTime = 0;
        settings.whiteCellNormalTime = 0;
        settings.whiteCellExplodeTime = 2;
        settings.normalCellSpeed = 8;
        settings.whiteCellSpeed = 0;

        return settings;
    }
}

}