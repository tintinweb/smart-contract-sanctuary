/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity ^0.8.1;

contract Storage {
    string[] public words;
    constructor() {
        // words[0] = "Transfixed by Zion\nThe New Jews spam hypertexts,\nLight-sick, Quivering.";
        // words[1] = "The quickest jury now;\nEver golden New form zone,\nNo expectations.";
        // words[2] = "The Ark groans, zags up\namethyst waves. Sea of squares;\njailborn code - next world.";
        // words[3] = "Hyperspectral dawn\nQuakes, beams blaze the jewel face,\nvenomized excess";
        // words[4] = "Zones flex, make new ruins.\nParadise conquistador\nJails veiled by light.";
        // words[5] = "Void arrows, zip like\nlarks, hymns mixing, joy cyphers;\nLiquid Gold Fusion.";
        // words[6] = "Jagged quartz towers,\nPacked above the navy bluffs,\nmix nectar and light.";
        // words[7] = "Verdant Perjury,\nlife, pixellized in ghost loams\nwarps, quickens, recedes.";
        // words[8] = "Nonreal packet maze\nthe jacquard blades of textiles;\nweaving light arrays";
        // words[9] = "Hacked Amazon\nJungle syntax waveform\nDisplaced by squares";
        // words[10] = "Quadratic Empire\nWe wove the megajoule helix\nblock by freezing block.";
        // words[11] = "Jinxed light-life ends;\nQuit, Respawn. Shadow playback,\nvenom horizon.";
        // words[12] = "subtropical shrines;\nhajiis, pixels liquidized\nwalk the lucent graves";
        // words[13] = "Body juts, friezed.\nfaqirs seek exemption, wilt -\nVibe Sarcophagi.";
        // words[14] = "Flesh, triumphal grave.\nHelix wreck, joyless, oblique;\nOzymandias.";
        // words[15] = "The fog of junk psalms\nRequests to the wreck reflex\nHypnotized blank verse";
        // words[16] = "About Plato's cave\nText jets quilt the azure sky \nwith glissando foam";
        // words[17] = "Darkness, refresh view\nComing flux; Onyx, Jasper\nThe Bezel \xc3\xa9poque.";
        // words[18] = "Hijacked forms, waves\nBody poem, dazzling equinox\nSelbstverselbstlichung.";
    }
    function addString(string memory newWord) public {
        words.push(newWord);
    }
}