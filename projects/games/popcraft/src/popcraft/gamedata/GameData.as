//
// $Id$

package popcraft.gamedata {

import com.threerings.util.Map;
import com.threerings.util.Maps;
import com.threerings.util.XmlUtil;
import com.threerings.flashbang.util.*;

import popcraft.*;
import popcraft.util.*;

public class GameData
{
    public var dayLength :Number;
    public var nightLength :Number;
    public var dawnWarning :Number;
    public var initialDayPhase :int;
    public var disableDiurnalCycle :Boolean;
    public var enableEclipse :Boolean;
    public var eclipseLength :Number;

    public var spellDropTime :NumRange;
    public var spellDropScatter :NumRange;
    public var spellDropCenterOffset :NumRange;
    public var maxLosingPlayerSpellDropShift :Number;

    public var minResourceAmount :int;
    public var maxResourceAmount :int;
    public var maxSpellsPerType :int;

    public var maxMultiplier :int;
    public var multiplierDamageSoak :Number;

    public var puzzleData :PuzzleData;

    public var scoreData :ScoreData;

    public var units :Array = [];
    public var spells :Array = [];

    // Map<String, PlayerDisplayData>
    public var playerDisplayDatas :Map = Maps.newSortedMapOf(String);

    public function getPlayerDisplayData (playerName :String) :PlayerDisplayData
    {
        var data :PlayerDisplayData = playerDisplayDatas.get(playerName);
        return (data != null ? data : PlayerDisplayData.unknown);
    }

    public function clone () :GameData
    {
        var theClone :GameData = new GameData();

        theClone.dayLength = dayLength;
        theClone.nightLength = nightLength;
        theClone.dawnWarning = dawnWarning;
        theClone.initialDayPhase = initialDayPhase;
        theClone.disableDiurnalCycle = disableDiurnalCycle;
        theClone.enableEclipse = enableEclipse;
        theClone.eclipseLength = eclipseLength;
        theClone.spellDropTime = spellDropTime.clone();
        theClone.spellDropScatter = spellDropScatter.clone();
        theClone.spellDropCenterOffset = spellDropCenterOffset.clone();
        theClone.maxLosingPlayerSpellDropShift = maxLosingPlayerSpellDropShift;
        theClone.minResourceAmount = minResourceAmount;
        theClone.maxResourceAmount = maxResourceAmount;
        theClone.maxSpellsPerType = maxSpellsPerType;
        theClone.maxMultiplier = maxMultiplier;
        theClone.multiplierDamageSoak = multiplierDamageSoak;
        theClone.puzzleData = puzzleData.clone();
        theClone.scoreData = scoreData.clone();

        for each (var unitData :UnitData in units) {
            theClone.units.push(unitData.clone());
        }

        for each (var spellData :SpellData in spells) {
            theClone.spells.push(spellData.clone());
        }

        for each (var playerDisplayData :PlayerDisplayData in playerDisplayDatas.values()) {
            theClone.playerDisplayDatas.put(playerDisplayData.playerName, playerDisplayData.clone());
        }

        return theClone;
    }

    public static function fromXml (xml :XML, defaults :GameData = null) :GameData
    {
        var useDefaults :Boolean = (null != defaults);

        var data :GameData = (useDefaults ? defaults : new GameData());

        data.dayLength = XmlUtil.getNumberAttr(xml, "dayLength",
            (useDefaults ? defaults.dayLength : undefined));
        data.nightLength = XmlUtil.getNumberAttr(xml, "nightLength",
            (useDefaults ? defaults.nightLength : undefined));
        data.dawnWarning = XmlUtil.getNumberAttr(xml, "dawnWarning",
            (useDefaults ? defaults.dawnWarning : undefined));
        data.initialDayPhase = XmlUtil.getStringArrayAttr(xml, "initialDayPhase",
            Constants.DAY_PHASE_NAMES, (useDefaults ? defaults.initialDayPhase : undefined));
        data.disableDiurnalCycle = XmlUtil.getBooleanAttr(xml, "disableDiurnalCycle",
            (useDefaults ? defaults.disableDiurnalCycle : undefined));
        data.enableEclipse = XmlUtil.getBooleanAttr(xml, "enableEclipse",
            (useDefaults ? defaults.enableEclipse : undefined));
        data.eclipseLength = XmlUtil.getNumberAttr(xml, "eclipseLength",
            (useDefaults ? defaults.eclipseLength : undefined));

        var spellDropTimeMin :Number = XmlUtil.getNumberAttr(xml, "spellDropTimeMin",
            (useDefaults ? defaults.spellDropTime.min : undefined));
        var spellDropTimeMax :Number = XmlUtil.getNumberAttr(xml, "spellDropTimeMax",
            (useDefaults ? defaults.spellDropTime.max : undefined));
        data.spellDropTime = new NumRange(spellDropTimeMin, spellDropTimeMax, Rand.STREAM_GAME);

        var spellDropScatterMin :Number = XmlUtil.getNumberAttr(xml, "spellDropScatterMin",
            (useDefaults ? defaults.spellDropScatter.min : undefined));
        var spellDropScatterMax :Number = XmlUtil.getNumberAttr(xml, "spellDropScatterMax",
            (useDefaults ? defaults.spellDropScatter.max : undefined));
        data.spellDropScatter = new NumRange(spellDropScatterMin, spellDropScatterMax,
            Rand.STREAM_GAME);

        var spellDropCenterOffsetMin :Number = XmlUtil.getNumberAttr(xml,
            "spellDropCenterOffsetMin",
            (useDefaults ? defaults.spellDropCenterOffset.min : undefined));
        var spellDropCenterOffsetMax :Number = XmlUtil.getNumberAttr(xml,
            "spellDropCenterOffsetMax",
            (useDefaults ? defaults.spellDropCenterOffset.max : undefined));
        data.spellDropCenterOffset = new NumRange(spellDropCenterOffsetMin, spellDropCenterOffsetMax, Rand.STREAM_GAME);

        data.maxLosingPlayerSpellDropShift = XmlUtil.getNumberAttr(xml,
            "maxLosingPlayerSpellDropShift",
            (useDefaults ? defaults.maxLosingPlayerSpellDropShift : undefined));

        data.minResourceAmount = XmlUtil.getIntAttr(xml, "minResourceAmount",
            (useDefaults ? defaults.minResourceAmount : undefined));
        data.maxResourceAmount = XmlUtil.getIntAttr(xml, "maxResourceAmount",
            (useDefaults ? defaults.maxResourceAmount : undefined));
        data.maxSpellsPerType = XmlUtil.getIntAttr(xml, "maxSpellsPerType",
            (useDefaults ? defaults.maxSpellsPerType : undefined));

        data.maxMultiplier = XmlUtil.getUintAttr(xml, "maxMultiplier",
            (useDefaults ? defaults.maxMultiplier : undefined));
        data.multiplierDamageSoak = XmlUtil.getNumberAttr(xml, "multiplierDamageSoak",
            (useDefaults ? defaults.multiplierDamageSoak : undefined));

        var puzzleDataXml :XML = XmlUtil.getSingleChild(xml, "PuzzleSettings",
            (useDefaults ? null : undefined));
        if (puzzleDataXml != null) {
            data.puzzleData = PuzzleData.fromXml(puzzleDataXml,
                (useDefaults ? defaults.puzzleData : null));
        }

        var pointsDataXml :XML = XmlUtil.getSingleChild(xml, "ScoreValues",
            (useDefaults ? null : undefined));
        if (pointsDataXml != null) {
            data.scoreData = ScoreData.fromXml(pointsDataXml,
                (useDefaults ? defaults.scoreData : null));
        }

        var ii :int;
        var type :int;
        // init the unit data
        for (ii = data.units.length; ii < Constants.UNIT_NAMES.length; ++ii) {
            data.units.push(null);
        }

        for each (var unitNode :XML in xml.Units.Unit) {
            type = XmlUtil.getStringArrayAttr(unitNode, "type", Constants.UNIT_NAMES);
            data.units[type] = UnitData.fromXml(unitNode,
                (useDefaults ? defaults.units[type] : null));
        }

        // init the spell data
        for (ii = data.spells.length; ii < Constants.SPELL_TYPE__LIMIT; ++ii) {
            data.spells.push(null);
        }

        for each (var spellNode :XML in xml.Spells.Spell) {
            type = XmlUtil.getStringArrayAttr(spellNode, "type", Constants.SPELL_NAMES);
            var spellClass :Class =
                (type < Constants.CREATURE_SPELL_TYPE__LIMIT ? CreatureSpellData : SpellData);
            data.spells[type] = spellClass.fromXml(spellNode,
                (useDefaults ? defaults.spells[type] : null));
        }

        // read PlayerDisplayData
        for each (var playerDisplayXml :XML in xml.PlayerDisplayDatas.PlayerDisplay) {
            var name :String = XmlUtil.getStringAttr(playerDisplayXml, "name");
            var inheritDisplayData :PlayerDisplayData;
            if (defaults != null) {
                inheritDisplayData = defaults.getPlayerDisplayData(name);
            }
            data.playerDisplayDatas.put(name,
                PlayerDisplayData.fromXml(playerDisplayXml, inheritDisplayData));
        }

        return data;
    }

    public function generateUnitReport () :String
    {
        var report :String = "";

        for each (var srcUnit :UnitData in units) {

            if (srcUnit.name == "workshop") {
                continue;
            }

            report += srcUnit.name;

            var weapon :UnitWeaponData = srcUnit.weapon;

            var rangeMin :Number = weapon.damageRange.min;
            var rangeMax :Number = weapon.damageRange.max;
            var damageType :int = weapon.damageType;

            report += "\nWeapon damage range: (" + rangeMin + ", " + rangeMax + ")";

            for each (var dstUnit :UnitData in units) {
                var dmgMin :Number = (null != dstUnit.armor ? dstUnit.armor.getDamage(damageType,
                    rangeMin) : Number.NEGATIVE_INFINITY);
                var dmgMax :Number = (null != dstUnit.armor ? dstUnit.armor.getDamage(damageType,
                    rangeMax) : Number.NEGATIVE_INFINITY);
                // dot == damage over time
                var dotMin :Number = dmgMin / weapon.cooldown;
                var dotMax :Number = dmgMax / weapon.cooldown;
                // ttk == time-to-kill
                var ttkMin :Number = dstUnit.maxHealth / dotMax;
                var ttkMax :Number = dstUnit.maxHealth / dotMin;
                var ttkAvg :Number = (ttkMin + ttkMax) / 2;

                report += "\nvs " + dstUnit.name + ":"
                report += " (" + dmgMin.toFixed(2) + ", " + dmgMax.toFixed(2) + ")";
                report += " DOT: (" + dotMin.toFixed(2) + "/s, " + dotMax.toFixed(2) + "/s)";
                report += " avg time-to-kill: " + ttkAvg.toFixed(2);
            }

            report += "\n\n";
        }

        return report;
    }
}

}
