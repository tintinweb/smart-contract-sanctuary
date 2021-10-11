/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;


// File: RetroCatsMetadata.sol

/** 
██████╗ ███████╗████████╗██████╗  ██████╗      ██████╗ █████╗ ████████╗███████╗    
██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    
██████╔╝█████╗     ██║   ██████╔╝██║   ██║    ██║     ███████║   ██║   ███████╗    
██╔══██╗██╔══╝     ██║   ██╔══██╗██║   ██║    ██║     ██╔══██║   ██║   ╚════██║    
██║  ██║███████╗   ██║   ██║  ██║╚██████╔╝    ╚██████╗██║  ██║   ██║   ███████║    
╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝      ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝    
                                                                                   
███╗   ███╗███████╗████████╗ █████╗ ██████╗  █████╗ ████████╗ █████╗               
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗              
██╔████╔██║█████╗     ██║   ███████║██║  ██║███████║   ██║   ███████║              
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║  ██║██╔══██║   ██║   ██╔══██║              
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║██████╔╝██║  ██║   ██║   ██║  ██║              
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝              
                                                                          
<<https://github.com/retro-cats/retro-cats-contracts>>

*/

/*
* @title Our contract for describing what a cat looks like.
* @dev This contract has almost 0 functionality, except for rngToCat
* which is used to "say" what the random number (the DNA) 
* of a cat would result in for a cat
*/
contract RetroCatsMetadata {
    uint256 internal s_maxChanceValue = 10000;
    struct RetroCat {
        Background background;
        Frame frame;
        Breed breed;
        Eyes eyes;
        Hair hair;
        Bling bling;
        Head head;
        Item item;
        Ring ring;
        Earring earring;
        Vice vice; 
    }

    struct TraitMetadata {
        uint256[34] backgrounds;
        uint256[12] frames;
        uint256[16] breeds;
        uint256[10] eyes;
        uint256[21] hairs;
        uint256[22] blings;
        uint256[21] heads;
        uint256[22] items;
        uint256[22] rings;
        uint256[22] earrings;
        uint256[22] vices;
    }

    enum Background{Black, Blue, Green, Grey, Orange, Pink, Purple, Red, Yellow, LightBlue, LightGreen, LightPink, LightYellow, D1B, D1O, D1P, D1Y, D2B, D2O, D2P, D2Y, D3B, D3O, D3P, D3Y, D4B, D4O, D4P, D4Y, D5B, D5O, D5P, D5Y}
    enum Frame{Black, Brass, Browne, Glit, Gold, Leather, Pine, Silver, White, Wood, None}
    enum Breed{Bengal, Calico, Chimera, HighColor, Mitted, Solid, Tabby, Tortie, Tuxedo, Van, Cloud, Lightning, Mister, Spotty, Tiger}
    enum Eyes{BlueOpen, BlueWink, Closed, GreenOpen, GreenWink, OrangeOpen, OrangeWink, YellowOpen, YellowWink}
    enum Hair{ Braid, Dreads, Fro, LongFlipped, LongStraight, Mullet, Muttonchops, Pageboy, ShortFlipped, None, BrownShag, GingerBangs, GingerShag, LongRocker, Pigtails, PunkSpikes, StackedPerm, TinyBraids, TVMom, Wedge }
    enum Bling{BlueNeckscarf, CopperBracelet, DiscoChest, HandlebarMustache, LongMustache, LoveBeads, MoonNecklaces, PeaceNecklace, PearlNecklace, PukaShellNecklace, CollarCuffs, FeatherBoa, CameoChoker, Woodenbeads, GoldFringe, TurquoiseNecklace, OrangeBoa, CoralNecklace, SilverFringe, SilverMoon, SunnyBeads}
    enum Head{AviatorGlasses, Daisy, Eyepatch, Headband, Headscarf, HeartGlasses, NewsboyCap, RoundGlasses, SquareGlasses, TopHat, BraidedHeadband, DaisyHeadband, DiscoHat, GoldTBand, GrandmaGlasses, GrandpaGlasses, GreenGlasses, RainbowScarf, RedBeret, TinselWig}
    enum Item{Atari, Disco, Ether, FlooyDisc, Houseplants, LandscapePainting, LavaLamp, PalmSurboard, Record, RedGuitar, TennisRacket, NerfFootball, Skateboard, Personalcomputer, Afghan, Fondue, LawnDarts, Rollerskates, Phone, Bicycle, Chair}
    enum Ring{Emerald, MoodBlue, MoodGreen, MoodPurple, MoodRed, Onyx, Ruby, Sapphire, Tortoiseshell, Turquoise, ChainRings, StackRings, NoseRing, MensGoldRing, MoonRing, EtherRing, OrbRing, GiantDiamond, TattooCat, TattooFish, TattooBird}
    enum Earring{Coral, DiamondStuds, GoldBobs, GoldChandelier, GoldHoops, OrangeWhite, RubyStuds, SilverHoops, Tortoiseshell, Turquoise, None, BlueWhite, GreenWhite, SilverChandelier, SapphireStuds, EmeraldStuds, PearlBobs, GoldChains, SilverChains, PinkMod, GoldJellyfish}
    enum Vice{Beer, Bong, Cigarette, Eggplant, JelloSalad, Joint, Mushrooms, PetRock, PurpleBagOfCoke, Whiskey, CheeseBall, ProtestSigns, TequilaSunrise, Grasshopper, PinaColada, QueensofDestructionCar, SPF4, SWPlush, SlideProjector, Tupperware, TigerMagazine}

    uint256 public constant maxChanceValue = 10000;
    string public constant purr = "Meow!";

    /**
    * @dev Percentages for each trait
    * @dev each row will always end with 10000
    * When picking a trait based on RNG, we will get a value between 0 - 99999
    * We choose the trait based on the sum of the integers up to the index
    * For example, if my random number is 251, and my array is [250, 200, 10000]
    *      This means my trait is at the 1st index. 251 is higher than 250, but lower than
    *      250 + 200
    */
    function traits() public pure returns(TraitMetadata memory allTraits) {
        allTraits = TraitMetadata(
            // backgrounds
            [500, 1100, 600, 1000, 900, 1400, 700, 2000, 800, 400, 270, 30, 100, 1, 6, 11, 16, 2, 7, 12, 17, 3, 8, 13, 18, 4, 9, 14, 19, 5, 10, 15, 10, maxChanceValue],
        // frames
            [250, 150, 300, 200, 40, 10, 80, 70, 400, 100, 8400, maxChanceValue],
            // breeds
            [90, 600, 75, 400, 900, 2700, 2100, 155, 2600, 280, 35, 1, 5, 50, 9, maxChanceValue],
            // eyes
            [1200, 10, 2000, 1400, 90, 1800, 1000, 1600, 900, maxChanceValue],
            // hairs
            [600, 4, 1000, 1200, 1200, 1, 500, 300, 700, 1600, 400, 450, 5, 7, 80, 3, 650, 350, 750, 200, maxChanceValue],
            // blings
            [1100, 200, 800, 500, 200, 700, 1400, 400, 800, 600, 1200, 40, 2, 350, 250, 450, 5, 50, 300, 650, 3, maxChanceValue],
            // heads
            [1200, 1100, 1, 1300, 600, 300, 1000, 400, 350, 900, 250, 60, 4, 300, 550, 500, 30, 950, 200, 5, maxChanceValue],
            // items
            [90, 800, 1, 1400, 1200, 900, 700, 550, 1300, 1000, 6, 400, 600, 200, 50, 60, 150, 250, 40, 300, 3, maxChanceValue],
            // rings
            [400, 1000, 900, 600, 850, 1300, 1200, 800, 500, 700, 250, 200, 150, 200, 500, 60, 350, 30, 1, 6, 3, maxChanceValue],
            // earings
            [400, 1, 200, 90, 1200, 500, 200, 1000, 300, 600, 3000, 250, 450, 105, 7, 5, 375, 725, 575, 4, 13, maxChanceValue],
            // vices
            [1000, 420, 1100, 1300, 50, 1200, 1450, 7, 30, 500, 400, 550, 200, 650, 460, 1, 20, 54, 2, 600, 6, maxChanceValue]
        );
    }

    function rngToCat(uint256 randomNumber) external pure returns (RetroCat memory retroCat){
        TraitMetadata memory allTraits = traits();
        
        // retroCat = RetroCat(Background(traitIndexes[0]),Frame(1),Breed(1),Eyes(1),Hair(1),Bling(1),Head(1),Item(1),Ring(1),Earring(1),Vice(1));
        retroCat = RetroCat({
            background: Background(getTraitIndex(allTraits.backgrounds, getModdedRNG(randomNumber, 0))),
            frame: Frame(getTraitIndex(allTraits.frames, getModdedRNG(randomNumber, 1))),
            breed: Breed(getTraitIndex(allTraits.breeds, getModdedRNG(randomNumber, 2))),
            eyes: Eyes(getTraitIndex(allTraits.eyes, getModdedRNG(randomNumber, 3))),
            hair: Hair(getTraitIndex(allTraits.hairs, getModdedRNG(randomNumber, 4))),
            bling: Bling(getTraitIndex(allTraits.blings, getModdedRNG(randomNumber, 5))),
            head: Head(getTraitIndex(allTraits.heads, getModdedRNG(randomNumber, 6))),
            item: Item(getTraitIndex(allTraits.items, getModdedRNG(randomNumber, 7))),
            ring: Ring(getTraitIndex(allTraits.rings, getModdedRNG(randomNumber, 8))),
            earring: Earring(getTraitIndex(allTraits.earrings, getModdedRNG(randomNumber, 9))),
            vice: Vice(getTraitIndex(allTraits.vices, getModdedRNG(randomNumber, 10)))
        });
    }

    function getModdedRNG(uint256 randomNumber, uint256 seed) public pure returns(uint256 modded_rng){
        uint256 newRng = uint256(keccak256(abi.encode(randomNumber, seed)));
        modded_rng = newRng % maxChanceValue;
    }

    function getTraitIndex(uint256[10] memory traitArray, uint256 moddedRNG) private pure returns(uint256){
        uint256 cumulativeSum = 0;
        for(uint i =0; i<traitArray.length; i++){
            if(moddedRNG >= cumulativeSum && moddedRNG < cumulativeSum + traitArray[i]){
                return i;
            }
            cumulativeSum = cumulativeSum + traitArray[i];
        }
        revert("Got a value outside of the maxChanceValue");
    }

    function getTraitIndex(uint256[12] memory traitArray, uint256 moddedRNG) private pure returns(uint256){
        uint256 cumulativeSum = 0;
        for(uint i =0; i<traitArray.length; i++){
            if(moddedRNG >= cumulativeSum && moddedRNG < cumulativeSum + traitArray[i]){
                return i;
            }
            cumulativeSum = cumulativeSum + traitArray[i];
        }
        revert("Got a value outside of the maxChanceValue");
    }

    function getTraitIndex(uint256[16] memory traitArray, uint256 moddedRNG) private pure returns(uint256){
    uint256 cumulativeSum = 0;
        for(uint i =0; i<traitArray.length; i++){
            if(moddedRNG >= cumulativeSum && moddedRNG < cumulativeSum + traitArray[i]){
                return i;
            }
            cumulativeSum = cumulativeSum + traitArray[i];
        }
        revert("Got a value outside of the maxChanceValue");
    }

    function getTraitIndex(uint256[21] memory traitArray, uint256 moddedRNG) private pure returns(uint256){
        uint256 cumulativeSum = 0;
        for(uint i =0; i<traitArray.length; i++){
            if(moddedRNG >= cumulativeSum && moddedRNG < cumulativeSum + traitArray[i]){
                return i;
            }
            cumulativeSum = cumulativeSum + traitArray[i];
        }
        revert("Got a value outside of the maxChanceValue");
    }

    function getTraitIndex(uint256[22] memory traitArray, uint256 moddedRNG) private pure returns(uint256){
        uint256 cumulativeSum = 0;
        for(uint i =0; i<traitArray.length; i++){
            if(moddedRNG >= cumulativeSum && moddedRNG < cumulativeSum + traitArray[i]){
                return i;
            }
            cumulativeSum = cumulativeSum + traitArray[i];
        }
        revert("Got a value outside of the maxChanceValue");
    }

    function getTraitIndex(uint256[34] memory traitArray, uint256 moddedRNG) private pure returns(uint256){
        uint256 cumulativeSum = 0;
        for(uint i =0; i<traitArray.length; i++){
            if(moddedRNG >= cumulativeSum && moddedRNG < cumulativeSum + traitArray[i]){
                return i;
            }
            cumulativeSum = cumulativeSum + traitArray[i];
        }
        revert("Got a value outside of the maxChanceValue");
    }
}