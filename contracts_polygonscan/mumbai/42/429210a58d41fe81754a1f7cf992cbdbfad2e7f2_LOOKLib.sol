/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

pragma solidity ^0.8.0;
library LOOKLib {

    function textures() public pure returns (string[64] memory) {
        return
        [
        "Silky",
        "Velvety",
        "Slimy",
        "Sharp",
        "Latex",
        "Wool",
        "Scaly",
        "Coarse",
        "Sandy",
        "Rocky",
        "Bumpy",
        "Slippery",
        "Fuzzy",
        "Synthetic",
        "Rough",
        "Fizzy",
        "Sticky",
        "Slick",
        "Popcorn",
        "Cotton Candy",
        "Slap Brush",
        "Feathery",
        "Prickly",
        "Crows Feet",
        "Smooth",
        "Cloudy",
        "Misty",
        "Bristly",
        "Solid",
        "Liquid",
        "Foamy",
        "Spongey",
        "Gelatinous",
        "Crumbly",
        "Spiked",
        "Crackled",
        "Barbed",
        "Crusty",
        "Powdery",
        "Leathery",
        "Squishy",
        "Wrinkly",
        "Reflective",
        "Glittery",
        "Felt",
        "Puffy",
        "Fleece",
        "Polymer",
        "Ceramic",
        "Chiffon",
        "Plastic",
        "Glass",
        "Lumpy",
        "Cotton",
        "Denim",
        "Lace",
        "Double Knit",
        "Knit",
        "Lace",
        "Mesh",
        "Nylon",
        "Satin",
        "Tactel",
        "Wool"
        ];

    }

    function flares() public pure returns (string[46] memory) {
        return
        [
        "Empty Wine Bottle",
        "Copper Dragon",
        "Sugary Cereal",
        "White Dragon",
        "Rainbow Serpent",
        "Paradise A Burn",
        "Asteroid En Route",
        "Neptune Sword",
        "Jupiter Honey",
        "Cosmic Heat",
        "Indie Luna",
        "Flashbulb Camera",
        "Category Four Hurricane",
        "Blood Mustang",
        "Candle in the Wind",
        "Diamond Wave",
        "All Powerful Trident",
        "Multifaceted Buzz",
        "1964 California Spyder",
        "Millions of Polka Dots",
        "Interstellar Mass",
        "Endless Galaxies",
        "A 1999 Video Game",
        "Glimmering Swimming Pool",
        "Black Cristal",
        "Zero Gravity",
        "Coney Island",
        "Aerodynamic Steering Wheel",
        "National Turbulence",
        "Heavy Metal Hour",
        "Seagull\xE2\x80\x99s Circling",
        "Mermaid Motel",
        "Self Loathing Poet",
        "Canyon\xE2\x80\x99s Infinite Abyss",
        "Diet Mountain Dew",
        "Heart Shaped Sunglasses",
        "Harem Silks From Bombay",
        "Rolling Party Ashes",
        "Gate of the Gargoyles",
        "Bel Air Palm Trees",
        "Rare Jazz Collection",
        "Hydroponic Weed",
        "Spicy Caviar",
        "Brooklyn Cola Bottle",
        "Wabi Sabi",
        "Summer Apartment Complex"
        ];
    }

    function colours() public pure returns (string[54] memory) {
        return [
        "Crow Black",
        "Raven Black",
        "Jet Black",
        "Black as Night",
        "Black as Ink",
        "Milky White",
        "Pearl White",
        "Sugar White",
        "Eggshell White",
        "Scarlet",
        "Crimson",
        "Ruby Red",
        "Cranberry",
        "Aqua",
        "Navy",
        "Turquoise",
        "Teal",
        "Aquamarine",
        "Golden Oak",
        "Sapphire Blue",
        "Glacial Blue",
        "Lemon Yellow",
        "Butter Yellow",
        "Military Green",
        "Sunshine Yellow",
        "Golden Blue",
        "Silver Red",
        "Silver Purple",
        "Golden Purple",
        "Golden Green",
        "Golden Orange",
        "Silver Teal",
        "Jade",
        "Lime Green",
        "Bottle Green",
        "Flamingo Pink",
        "Shell Pink",
        "Violet",
        "Pansy Purple",
        "Pumpkin Orange",
        "Sunset Orange",
        "Tiger Lily Orange",
        "Mocha Brown",
        "Coffee Brown",
        "Bronze Green",
        "Cinnamon Yellow",
        "Caramel Orange",
        "Burnt Red",
        "Caramel Yellow",
        "Hazel Gray",
        "Charcoal Gray",
        "Mellow Yellow",
        "Smoke Gray",
        "Cocoa Brown"
        ];
    }

    function backgroundColours() public pure returns (string[30] memory) {
        return [
        "FF0294",
        "02FF6A",
        "EE740D",
        "EE0D0D",
        "00C0D0",
        "0056F6",
        "C600F6",
        "F60091",
        "CA215C",
        "DA9708",
        "5EDA08",
        "DA801A",
        "771ADA",
        "1A6EDA",
        "1AC6DA",
        "18B144",
        "7E18B1",
        "A533DE",
        "A8DE33",
        "D9DE33",
        "DE7C33",
        "E36100",
        "E300BA",
        "731F64",
        "66D83F",
        "3FB5D8",
        "000000",
        "3B289B",
        "9B285E",
        "3ACFA4"
        ];
    }

    function lines() public pure returns (string[41] memory) {
        return [
        "Angular",
        "Fringe",
        "Quiff",
        "Pegged",
        "Blouson",
        "Halter",
        "Bouffant",
        "Tunic",
        "Chemise",
        "Balloon",
        "Bretelles",
        "Embroidery",
        "Drop Waist",
        "Peplum",
        "Bowl Cut",
        "Jagged",
        "Drape",
        "Princess Line",
        "Yolk Line",
        "Crossover Line",
        "Chain stitch",
        "Hand Stitch",
        "Lock Stitch",
        "Gimp",
        "Multi-Thread Stitch",
        "Over Edge Stitch",
        "Blanket Stitch",
        "Running Stitch",
        "Satin Stitch",
        "French Knot Stitch",
        "Lazy Daisy Stitch",
        "Herringbone Stitch",
        "Seed Stitch",
        "Bullion Knot",
        "Buttonhole Stitch",
        "Shell Tuck Stitch",
        "Square Knot",
        "Water Knot",
        "Rolling Hitch",
        "Blood Knot",
        "Tripod Lashing"
        ];
    }

    function shapes() public pure returns (string[41] memory) {
        return [
        "Spiral",
        "Maxi",
        "Empire",
        "Asymmetrical",
        "A-line",
        "Sheath",
        "Hourglass",
        "Bell",
        "Mermaid",
        "Ball",
        "Trumpet",
        "Squiggle",
        "Ruffle",
        "Lemniscate",
        "Mobius Strip",
        "Squircle",
        "Heptagram",
        "Butterfly Curve",
        "Inverted Bell",
        "Golden Ratio",
        "Cos",
        "Sine",
        "S Curve",
        "Deltoid",
        "Cassini Oval",
        "Spline",
        "B\xC3\xA9zier triangle",
        "Roulette",
        "Cone",
        "Torus",
        "Honeycomb",
        "Star",
        "Broken",
        "Obtuse",
        "Straight",
        "Wavy",
        "Diagonal",
        "Prism",
        "Ring",
        "ZigZag",
        "Mangled"
        ];
    }

    function forms() public pure returns (string[23] memory) {
        return [
        "Antifragile",
        "Fragile",
        "Shifting",
        "Temporal",
        "Terrestrial",
        "Ephemeral",
        "Transient",
        "Intense",
        "Flimsy",
        "Reliable",
        "Fading",
        "Bright",
        "Repaired",
        "Renewed",
        "Over Extended",
        "Retracted",
        "Halted",
        "Short Form",
        "Long Form",
        "Kintsugi",
        "Downforce",
        "Melting",
        "Quenched"
        ];
    }

    function elements() public pure returns (string[113] memory) {
        return [
        "Hydrogen",
        "Helium",
        "Lithium",
        "Beryllium",
        "Boron",
        "Carbon",
        "Nitrogen",
        "Oxygen",
        "Fluorine",
        "Neon",
        "Sodium",
        "Magnesium",
        "Aluminum",
        "Silicon",
        "Phosphorus",
        "Sulfur",
        "Chlorine",
        "Argon",
        "Potassium",
        "Calcium",
        "Scandium",
        "Titanium",
        "Vanadium",
        "Chromium",
        "Manganese",
        "Iron",
        "Cobalt",
        "Nickel",
        "Copper",
        "Zinc",
        "Gallium",
        "Germanium",
        "Arsenic",
        "Selenium",
        "Bromine",
        "Krypton",
        "Rubidium",
        "Strontium",
        "Yttrium",
        "Zirconium",
        "Niobium",
        "Molybdenum",
        "Technetium",
        "Ruthenium",
        "Rhodium",
        "Palladium",
        "Silver",
        "Cadmium",
        "Indium",
        "Tin",
        "Antimony",
        "Tellurium",
        "Iodine",
        "Xenon",
        "Cesium",
        "Barium",
        "Lanthanum",
        "Cerium",
        "Praseodymium",
        "Neodymium",
        "Promethium",
        "Samarium",
        "Europium",
        "Gadolinium",
        "Terbium",
        "Dysprosium",
        "Holmium",
        "Erbium",
        "Thulium",
        "Ytterbium",
        "Lutetium",
        "Hafnium",
        "Tantalum",
        "Tungsten",
        "Rhenium",
        "Osmium",
        "Iridium",
        "Platinum",
        "Gold",
        "Mercury",
        "Thallium",
        "Lead",
        "Bismuth",
        "Polonium",
        "Astatine",
        "Radon",
        "Francium",
        "Radium",
        "Actinium",
        "Thorium",
        "Protactinium",
        "Uranium",
        "Neptunium",
        "Plutonium",
        "Americium",
        "Curium",
        "Berkelium",
        "Californium",
        "Einsteinium",
        "Fermium",
        "Mendelevium",
        "Nobelium",
        "Lawrencium",
        "Rutherfordium",
        "Dubnium",
        "Seaborgium",
        "Bohrium",
        "Hassium",
        "Meitnerium",
        "Darmstadtium",
        "Roentgenium",
        "Ununbiium",
        "Ununquadium"
        ];
    }

    function prefixCommon() public pure returns (string[15] memory) {
        return [
        "Angel\xE2\x80\x99s",
        "Chimera\xE2\x80\x99s",
        "Demon\xE2\x80\x99s",
        "Dragon\xE2\x80\x99s",
        "Hydra\xE2\x80\x99s",
        "Aphrodite\xE2\x80\x99s",
        "Goblin",
        "Muses\xE2\x80\x99",
        "Phoenix\xE2\x80\x99s",
        "Pixie",
        "Trolls\xE2\x80\x99",
        "Vampire",
        "Amaterasu\xE2\x80\x99s",
        "Inari\xE2\x80\x99s",
        "Ebisu\xE2\x80\x99s"
        ];
    }

    function prefixSemirare() public pure returns (string[24] memory) {
        return [
        "Izanagi\xE2\x80\x99s",
        "Osiris\xE2\x80\x99s",
        "Horus\xE2\x80\x99",
        "Anubis\xE2\x80\x99s",
        "Zeus\xE2\x80\x99s",
        "Artemis\xE2\x80\x99s",
        "Apollo\xE2\x80\x99s",
        "Athena\xE2\x80\x99s",
        "Venus\xE2\x80\x99s",
        "Poseidon\xE2\x80\x99s",
        "Winter\xE2\x80\x99s",
        "Summer\xE2\x80\x99s",
        "Autumn\xE2\x80\x99s",
        "Eclectic\xE2\x80\x99s",
        "Pluto\xE2\x80\x99s",
        "Solar\xE2\x80\x99s",
        "King\xE2\x80\x99s",
        "Queen\xE2\x80\x99s",
        "Prince\xE2\x80\x99s",
        "Princess\xE2\x80\x99s",
        "Elve\xE2\x80\x99s",
        "Fairies\xE2\x80\x99",
        "Firebird\xE2\x80\x99s",
        "Cupid\xE2\x80\x99s"
        ];
    }

    function prefixExclusive() public pure returns (string[27] memory) {
        return [
        "Edgy",
        "Magical",
        "Charming",
        "Ambitious",
        "Bold",
        "Brave",
        "Daring",
        "Bright",
        "Audacious",
        "Courageous",
        "Fearless",
        "Pawned",
        "Dashing",
        "Dapper",
        "Gallant",
        "Funky",
        "Sophisticated",
        "Graceful",
        "Voguish",
        "Majestic",
        "Enchanting",
        "Elegant",
        "Saucy",
        "Sassy",
        "Roaring",
        "Vintage",
        "Honest"
        ];
    }

    function pickSuffixCategories(uint256 rand, uint256 tokenId) public pure returns (uint256[6] memory categoryIds){
        // Need to draw for the category that will be randomnly selected
        uint256 randCategory = random(string(abi.encodePacked("SuffixCategory", toString(rand))));
        uint256 selection = (randCategory + tokenId ) % 7; // Pick one suffix to omit

        uint256 counter = 0;
        // First add category ids in but omit one suffix category
        for(uint256 i = 0; i< 7; i++){
            if(i == selection){
                continue;
            }
            categoryIds[counter] = i;
            counter = counter + 1;
        }

        // Then remix these ids and get with rarity as well
        for( uint256 j = 0; j < 6; j++){
            // Just make some rarity

            uint256 randRarity = random(string(abi.encodePacked("SuffixRarity", toString(tokenId))));
            uint256 finalRarityResult = randRarity % 21;
            uint256 rarity = 0;
            if (finalRarityResult > 14){
                rarity = 1;
            }
            if (finalRarityResult > 19){
                rarity = 2;
            }
            categoryIds[j] = rarity + (categoryIds[j] * 3); // Suffix arrays -> 0,1,2 then 3,4,5 then 6,7,8 etc
        }

        // Now that we have selected categories, now we need to randomize the order more
        // Fisher Yates type Shuffle
        // Shuffle 10 times
        for(uint256 k= 1; k < 10; k++){
            for (uint256 i = 5; i == 0; i--) {
                // This next line is just a random code to try and get some shuffling in
                uint256 randomSelect = ((random(string(abi.encodePacked("FisherYates", rand))) * random(string(abi.encodePacked("RandomString"))) / random (string(abi.encodePacked(toString(tokenId))))) + (tokenId + (tokenId * k) * 234983)) % 6;
                uint256 x = categoryIds[i];
                categoryIds[i] = categoryIds[randomSelect];
                categoryIds[randomSelect] = x;
            }
        }

        return categoryIds;
    }

    function pickPrefix(uint256 rand, uint256 tokenId) public pure returns (string memory prefix1, string memory prefix2){
        // Need to draw for
        uint256 randRarity1Full = random(string(abi.encodePacked("PrefixRarityOne", toString(rand)))) + tokenId;
        uint256 randRarity2Full = random(string(abi.encodePacked("PrefixRarityTwo", toString(rand)))) + tokenId + 1;
        uint256 randRarity3Full = random(string(abi.encodePacked("PrefixRarityThree3", toString(rand)))) + tokenId + 2;

        uint256 randRarity1 = randRarity1Full % 21;
        uint256 randRarity2 = randRarity2Full % 21;
        uint256 randRarity3 = randRarity3Full % 21;

        prefix1 = prefixCommon()[randRarity1Full % prefixCommon().length];
        if (randRarity1 > 15){
            prefix1 = prefixSemirare()[randRarity1Full % prefixSemirare().length];
        }
        if(randRarity1 > 19){
            prefix1 = prefixExclusive()[randRarity1Full % prefixExclusive().length];
        }

        prefix2 = prefixCommon()[randRarity2Full % prefixCommon().length];
        if (randRarity2 > 15){
            prefix2 = prefixSemirare()[randRarity2Full % prefixSemirare().length];
        }
        if(randRarity2 > 19){
            prefix2 = prefixExclusive()[randRarity2Full % prefixExclusive().length];
        }

        if(keccak256(bytes(prefix1)) == keccak256(bytes(prefix2))){
            // Redraw once to try and prevent duplicates
            prefix2 = prefixCommon()[randRarity3Full % prefixCommon().length];
            if (randRarity3 > 15){
                prefix2 = prefixSemirare()[randRarity3Full % prefixSemirare().length];
                if(randRarity3 > 19)
                    prefix2 = prefixExclusive()[randRarity3Full % prefixExclusive().length];
            }
        }
        return (prefix1, prefix2);
    }

    function random(string memory input) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }


    function toString(uint256 value) public pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


}