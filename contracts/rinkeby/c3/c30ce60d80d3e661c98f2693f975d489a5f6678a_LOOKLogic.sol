/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.8.0;
library LOOKLogic {
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