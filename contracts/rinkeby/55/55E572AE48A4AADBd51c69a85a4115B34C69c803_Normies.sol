/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
// File: NormieLib.sol


pragma solidity ^0.8.9;

// @author TheNormiesNFT (https://twitter.com/thenormiesnft)
library NormieLib {

    struct Normie {
        uint32 skinType; // Max number is 4,294,967,296
        uint32 hair; 
        uint32 eyes;
        uint32 mouth;
        uint32 torso;
        uint32 pants;
        uint32 shoes;
        uint32 accessoryOne;
        uint32 accessoryTwo;
        uint32 accessoryThree;
    }

    struct Trait {
        string traitName;
        string traitType;
        string hash;
        uint16 pixelCount;
        uint32 traitID;
    }

    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /*
     * @dev Function taken from Brecht Devos - <[email protected]>
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /*
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "a";
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

    function parseInt(string memory _a) internal pure
    returns (uint8 _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    /*
     * @dev Returns a substring from [startIndex, endIndex) 
     */
    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure 
    returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}
// File: NormieTraits.sol


pragma solidity ^0.8.9;


// @author TheNormiesNFT (https://twitter.com/thenormiesnft)
contract NormieTraits {
    using NormieLib for uint8;

    // Private variables
    address private owner;
    uint256 private SEED_NONCE = 0;
    mapping(address => bool) private adminAccess;
    NormieLib.Trait private emptyTrait = NormieLib.Trait("Empty", "Empty", "", 0, 1000001);

    // Public variables
    string public colorString = ".c000{fill:#503e38}.c001{fill:#228b22}.c002{fill:#562c1a}.c003{fill:#313131}.c004{fill:#fee761}.c005{fill:#ff0044}"
    ".c006{fill:#ffffff}.c007{fill:#01badb}.c008{fill:#b9f2ff}.c009{fill:#000000}.c00A{fill:#01f8fc}.c00B{fill:#0088fc}.c00C{fill:#039112}.c00D{fill:#1a3276}"
    ".c00E{fill:#e2646d}.c00F{fill:#ea8c8f}.c00G{fill:#f6757a}.c00H{fill:#7234b2}.c00I{fill:#b881ef}.c00J{fill:#b90e0a}.c00K{fill:#e43b44}.c00L{fill:#f5999e}"
    ".c00M{fill:#1258d3}.c00N{fill:#733e39}.c00O{fill:#2dcf51}.c00P{fill:#260701}.c00Q{fill:#743d2b}.c00R{fill:#dcbeb5}.c00S{fill:#e8b796}.c00T{fill:#67371a}"
    ".c00U{fill:#874f2e}.c00V{fill:#182812}.c00W{fill:#115c35}.c00X{fill:#ff9493}.c00Y{fill:#a22633}.c00Z{fill:#302f2f}.c010{fill:#f0d991}.c011{fill:#f2e7c7}"
    ".c012{fill:#0099db}.c013{fill:#2ce8f5}.c014{fill:#124e89}.c015{fill:#b86f50}.c016{fill:#777777}.c017{fill:#afafaf}.c018{fill:#878787}.c019{fill:#ffed1b}"
    ".c01A{fill:#1b1a1b}.c01B{fill:#131314}.c01C{fill:#191970}.c01D{fill:#bb8b1f}.c01E{fill:#f8f7ed}.c01F{fill:#072083}.c01G{fill:#f65c1a}.c01H{fill:#4b5320}"
    ".c01I{fill:#8a9294}.c01J{fill:#969cba}.c01K{fill:#c0c0c0}.c01L{fill:#8c92ac}.c01M{fill:#01796f}.c01N{fill:#ce1141}.c01O{fill:#ff007f}.c01P{fill:#b6005b}"
    ".c01Q{fill:#feed26}.c01R{fill:#dccd21}.c01S{fill:#080808}.c01T{fill:#b2ffff}.c01U{fill:#18a8d8}.c01V{fill:#818589}.c01W{fill:#98fb98}.c01X{fill:#e0c4ff}"
    ".c01Y{fill:#e1c4ff}.c01Z{fill:#c0a8da}.c020{fill:#ce2029}.c021{fill:#b01b23}.c022{fill:#87ceeb}.c023{fill:#ff0000}";
    uint32 public CURRENT_TRAIT = 1;

    // Storage of all previous collections
    mapping(uint256 => uint256[]) public currentCollectionTraits;
    mapping(uint256 => NormieLib.Trait) public traitIDToTrait;

    string[] LETTERS = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"];

    // Array of the current trait rarity available in the current collection with 10 traits total
    uint256[][10] public traitRarity;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Not the owner");
        _;
    }

    /**
     * @dev Throws if called by an account that does not have adminAccess.
     */
    modifier onlyAdmin() {
        require(adminAccess[msg.sender], "No admin access");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        // Register the Empty trait.
        traitIDToTrait[1000001] = emptyTrait;

        // TODO: CHANGE BACK TO OG VALUES
        traitRarity[0] = [2500, 5000, 7500, 10000];
        traitRarity[1] = [400, 800, 1600, 2400, 3200, 4200, 5200, 6600, 8000, 10000];
        traitRarity[2] = [800, 1600, 2800, 4000, 5500, 7000, 8500, 10000];
        traitRarity[3] = [200, 400, 1300, 2200, 4150, 6100, 8050, 10000];
        traitRarity[4] = [200, 800, 1400, 2000, 3000, 4000, 5000, 6600, 8200, 10000];
        traitRarity[5] = [200, 600, 1600, 2800, 4000, 6000, 8000, 10000];
        traitRarity[6] = [100, 600, 1100, 2600, 4100, 7050, 10000];
        traitRarity[7] = [100,600,1100,2100,10000];
        traitRarity[8] = [100,800,2400,4400,10000];
        traitRarity[9] = [100,600,2100,10000];
    }

    ///////////////////////////// ONLY ADMIN FUNCTIONS /////////////////////////////

    /**
     * @dev Function used to generate a Normie.
     * @param tokenID The token ID of the new Normie.
     * @param _address The address that will own the Normie. Used in hashing function.
     * @return Edited normie. Used by mintNormie function in Normies.sol.
     */
    function generateNormie(uint256 tokenID, address _address) external onlyAdmin
    returns (NormieLib.Normie memory) {
        for (uint256 i=0; i < 10; i++){
            require(traitRarity[i].length == currentCollectionTraits[i].length, "Trait arrays mismatch");
        }
        uint256[] memory generatedHash = hash(tokenID, _address);

        return NormieLib.Normie(
            uint32(currentCollectionTraits[0][generatedHash[0]]),
            uint32(currentCollectionTraits[1][generatedHash[1]]),
            uint32(currentCollectionTraits[2][generatedHash[2]]),
            uint32(currentCollectionTraits[3][generatedHash[3]]),
            uint32(currentCollectionTraits[4][generatedHash[4]]),
            uint32(currentCollectionTraits[5][generatedHash[5]]),
            uint32(currentCollectionTraits[6][generatedHash[6]]),
            uint32(currentCollectionTraits[7][generatedHash[7]]),
            uint32(currentCollectionTraits[8][generatedHash[8]]),
            uint32(currentCollectionTraits[9][generatedHash[9]])
            );
    }

    /*
     * @dev Generates a array of length 10 that contains what indexes to use for each trait. 
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     * @return An array of size 10 with integers representing the trait within the current collection to use.
     */
    function hash(uint256 _t, address _a) public onlyAdmin 
    returns (uint256[] memory) {
        // This will generate a 10 trait array. All values in the array are random.
        uint256[] memory ret = new uint[](10);
        uint counter = SEED_NONCE;
        uint256 _randinput = 0;
        uint256 left = 0;
        uint256 right = 0;
        uint256 mid = 0;
        uint256 traitRarityValue = 0;
        for (uint256 i = 0; i <= 9; i++) {
            counter++;
            _randinput = 
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            counter
                        )
                    )
                ) % 10000;
            left = 0;
            right = traitRarity[i].length - 1;

            // Binary search for the index
            while (left < right){
                mid = (left + right) / 2;
                traitRarityValue = traitRarity[i][mid];
                if (traitRarityValue == _randinput){
                    left = mid;
                    break;
                }
                else if (traitRarityValue < _randinput){
                    left = mid + 1;
                } else {
                    right = mid;
                }
            }
            ret[i] = left;
        }
        SEED_NONCE = counter;
        return ret;
    }

    ///////////////////////////// PUBLIC READ FUNCTIONS /////////////////////////////

    /*
     * @dev Hash to SVG function for a normie.
     * @param normie The Normie that we are getting the URI of.
     * @param normieID the ID of the normie.
     * @return URI of a Normie as a string.
     */
    function getNormieURI(NormieLib.Normie memory normie, uint256 normieID) external view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                NormieLib.encode(
                    bytes(string(abi.encodePacked(
                        '{"name": "Normie #',
                        NormieLib.toString(normieID),
                        '", "description": "Normies are generated and stored 100% on the blockchain.", "image": "data:image/svg+xml;base64,',
                        NormieLib.encode(
                            bytes(normieToSVG(normie))
                        ),
                        // TODO: Add normie metadata
                        '","attributes":',
                        getMainTraitsString(normie),
                        getOptionalTraitsString(normie),
                        "}")))
            )));
    }

    /*
     * @dev Returns Asset URI for a given trait.
     * @param assetID The ID of the asset we are getting the URI of.
     * @return URI of an asset as a string.
     */
    function getAssetURI(uint256 assetID) external view returns (string memory) {
        NormieLib.Trait memory trait = traitIDToTrait[assetID];
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                NormieLib.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "',
                                trait.traitName,
                                '", "description": "Normie assets are generated and stored 100% on the blockchain.", "image": "data:image/svg+xml;base64,',
                                NormieLib.encode(
                                    bytes(assetToSVG(assetID))
                                ),
                                '","attributes":',
                                getSingleTraitString(trait),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Gets a trait by its ID number using the provided "traitID" and returns its trait type. Used in Normies.sol
     * @param traitID The traitID to get from the traitIDToTrait mapping.
     * @return string object.
     */
    function getTraitTypeByTraitID(uint256 traitID) external view returns (string memory){
        return traitIDToTrait[traitID].traitType;
    }

    /**
     * @dev Gets a trait from the current collection using the provided "traitIndex" and "index". 
     *      Used in minting function.
     * @param traitIndex The index which indicates what type of trait it is [0-9].
     * @param index The index of the specific trait to grab. Variable array size depending on collection.
     * @return Trait object.
     */
    function getTraitFromCurrentCollection(uint256 traitIndex, uint256 index) public view
    returns (NormieLib.Trait memory) {
        return traitIDToTrait[currentCollectionTraits[traitIndex][index]];
    }

    ///////////////////////////// PRIVATE READ FUNCTIONS /////////////////////////////

    /*
     * @notice Adapted function from Anonymice contract
     * @dev Hash to SVG function for normie.
     * @param normie The Normie object to generate an SVG image for.
     * @return Normie SVG as a string.
     */
    function normieToSVG(NormieLib.Normie memory normie) private view returns (string memory) {
        string memory svgString;
        for (uint8 i = 0; i <= 9; i++) {
            NormieLib.Trait memory trait = getNormieTraitObject(normie, i);
            for (uint16 j = 0; j < trait.pixelCount; j++) {
                string memory thisPixel = NormieLib.substring(trait.hash, j * 5, j * 5 + 5);
                uint8 x = letterToNumber(NormieLib.substring(thisPixel, 0, 1));
                uint8 y = letterToNumber(NormieLib.substring(thisPixel, 1, 2));
                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<rect class='c",
                        NormieLib.substring(thisPixel, 2, 5),
                        "' x='",
                        x.toString(),
                        "' y='",
                        y.toString(),
                        "'/>"
                    )
                );
            }
        }
        svgString = string(
            abi.encodePacked(
                '<svg id="normie-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24"> ',
                svgString,
                "<style>rect{width:1px;height:1px;} #normie-svg{shape-rendering: crispedges;} ",
                colorString,
                "</style></svg>"
            )
        );
        return svgString;
    }

    /*
     * @notice Adapted function from Anonymice contract
     * @dev Hash to SVG function for a trait.
     * @param assetID The assetID for the trait we want to create an SVG for.
     * @return Asset SVG as a string.
     */
    function assetToSVG(uint256 assetID) private view returns (string memory) {
        NormieLib.Trait memory trait = traitIDToTrait[assetID];
        string memory svgString;
        for (uint16 j = 0; j < trait.pixelCount; j++) {
            string memory thisPixel = NormieLib.substring(trait.hash, j * 5, j * 5 + 5);
            uint8 x = letterToNumber(NormieLib.substring(thisPixel, 0, 1));
            uint8 y = letterToNumber(NormieLib.substring(thisPixel, 1, 2));
            svgString = string(
                abi.encodePacked(
                    svgString,
                    "<rect class='c",
                    NormieLib.substring(thisPixel, 2, 5),
                    "' x='",
                    x.toString(),
                    "' y='",
                    y.toString(),
                    "'/>"
                )
            );
        }
        svgString = string(
            abi.encodePacked(
                '<svg id="normie-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24"> ',
                svgString,
                "<style>rect{width:1px;height:1px;} #normie-svg{shape-rendering: crispedges;} ",
                colorString,
                "</style></svg>"
            )
        );
        return svgString;
    }

    /* 
     * @notice Original author is Anonymice.
     * @dev Helper function to reduce pixel size within contract.
     * @param _inputLetter The letter to change from base26 to base10.
     * @return A base 10 number.
     */
    function letterToNumber(string memory _inputLetter) private view returns (uint8) {
        for (uint8 i = 0; i < LETTERS.length; i++) {
            if (
                keccak256(abi.encodePacked((LETTERS[i]))) ==
                keccak256(abi.encodePacked((_inputLetter)))
            ) return (i);
        }
        revert();
    }

    /*
     * @dev Gets the trait for a given "normie" using the provided "traitIndex".
     * @param normie The normie whose trait we want to get.
     * @param traitIndex Index that determines which trait to return [0-9].
     * @return Trait object.
     */
    function getNormieTraitObject(NormieLib.Normie memory normie, uint256 traitIndex) private view returns (NormieLib.Trait memory) {
            if (traitIndex == 0) {
                return traitIDToTrait[normie.skinType];
            } else if (traitIndex == 1) {
                return traitIDToTrait[normie.pants];
            } else if (traitIndex == 2){
                return traitIDToTrait[normie.shoes];
            } else if (traitIndex == 3) {
                return traitIDToTrait[normie.torso];
            } else if (traitIndex == 4) {
                return traitIDToTrait[normie.mouth];
            } else if (traitIndex == 5) {
                return traitIDToTrait[normie.eyes];
            } else if (traitIndex == 6) {
                return traitIDToTrait[normie.hair];
            } else if (traitIndex == 7) {
                return traitIDToTrait[normie.accessoryOne];
            } else if (traitIndex == 8) {
                return traitIDToTrait[normie.accessoryTwo];
            } else {
                return traitIDToTrait[normie.accessoryThree];
            }
    }

    /*
     * @dev Generates the string metadata for base Normie traits.
     * @param normie The normie object to generate URI string from.
     * @return Metadata for the normie as a string. Used for any call to URI..
     */
    function getMainTraitsString(NormieLib.Normie memory normie) private view returns (string memory) {
        return string(abi.encodePacked(
                '{"Skin Type":"', 
                traitIDToTrait[normie.skinType].traitName,
                '",Hair:"', traitIDToTrait[normie.hair].traitName,
                '","Eyes":"', traitIDToTrait[normie.eyes].traitName,
                '","Mouth":"', traitIDToTrait[normie.mouth].traitName,
                '","Torso":"', traitIDToTrait[normie.torso].traitName,
                '","Pants":"', traitIDToTrait[normie.pants].traitName,
                '","Shoes":"', traitIDToTrait[normie.shoes].traitName
            )
        );
    }

    /*
     * @dev Generates the string metadata for optional Normie traits.
     * @param normie The normie object to generate URI string from.
     * @return Metadata for the normie as a string. Used for any call to URI.
     */
    function getOptionalTraitsString(NormieLib.Normie memory normie) private view returns (string memory) {
        return string(abi.encodePacked(
                '","Accessory One":"', traitIDToTrait[normie.accessoryOne].traitName,
                '","Accessory Two":"', traitIDToTrait[normie.accessoryTwo].traitName,
                '","Accessory Three":"', traitIDToTrait[normie.accessoryThree].traitName,
                '"}'
            )
        );
    }

    /**
     * @dev Generates the string metadata for a single trait NFT.
     * @param trait The trait object to generate URI string from.
     * @return Metadata for the asset as a string. Used for any call to URI.
     */
    function getSingleTraitString(NormieLib.Trait memory trait) private pure returns (string memory) {
        return string(abi.encodePacked(
                '{"Trait Type":"', 
                trait.traitType,
                '","Trait Name":"', trait.traitName,
                '"}'
            )
        );
    }

    ///////////////////////////// OWNER FUNCTIONS /////////////////////////////

    //--------------------------
    // Trait Rarity functions
    //--------------------------
    /**
     * @dev Clears the trait rarity for a given trait (Ex. hair which is 0).
     * @param traitIndex The index we want to clear.
     */
    function clearTraitRarity(uint256 traitIndex) external onlyOwner {
        delete traitRarity[traitIndex];
    }

    /**
     * @dev Clears all trait rarities.
     */
    function clearAllTraitRarities() external onlyOwner {
        for (uint256 i = 0; i < traitRarity.length; i++){
            delete traitRarity[i];
        }
    }

    /**
     * @dev Adds an array of trait rarity values to the traix index. Contains safety check to ensure the array sums to 10,000.
            Also checks to make sure trait rarity is empty to begin with.
     * @param traitIndex The trait index to add trait rarities to.
     * @param newRarities Integer array of rarities that should sum to 10,000.
     */
    function addTraitRarity(uint256 traitIndex, uint256[] memory newRarities) external onlyOwner {
        require(traitRarity[traitIndex].length == 0, "Not empty trait");
        require(newRarities[newRarities.length-1] == 10000, "Trait rarity does not end in 10,000. Reverting");
        for (uint256 i = 0; i < newRarities.length; i++) {
            traitRarity[traitIndex].push(newRarities[i]);
        }
        return;
    }

    //--------------------------
    // Collection functions
    //--------------------------
    /**
     * @dev Clears the traits for a given trait index in the current collection (Ex. hair which is 0).
     * @param index The index to clear current collection traits from.
     */
    function clearCurrentCollectionTrait(uint256 index) external onlyOwner {
        delete currentCollectionTraits[index];
    }

    /**
     * @dev Clears all traits for the current collection.
     */
    function clearAllTraitsInCurrentCollection() external onlyOwner {
        for (uint256 i = 0; i < 10; i++){
            delete currentCollectionTraits[i];
        }
    }

    /**
     * Adds new trait to trait map. Good to use when adding new traits for giveaways or one offs.
     * @param newTraits Array of traits to add to trait map.
     */ 
    function addTraitToTraitMap(NormieLib.Trait[] memory newTraits) external onlyOwner {
        uint32 currentTraitLocal = CURRENT_TRAIT;
        for (uint256 i = 0; i < newTraits.length; i++){
            NormieLib.Trait memory _trait = NormieLib.Trait(
                    newTraits[i].traitName,
                    newTraits[i].traitType,
                    newTraits[i].hash,
                    newTraits[i].pixelCount,
                    1000001 + currentTraitLocal
            );
            traitIDToTrait[1000001 + currentTraitLocal] = _trait;
            currentTraitLocal = currentTraitLocal + 1;
        }
        CURRENT_TRAIT = currentTraitLocal;
    }

    /**
     * @dev Function used to edit a trait in place in case we hashed incorrectly or something.
     * @param traitID Trait ID of the trait we want to edit
     * @param newTraitData Struct containing data that we want to overwrite the current trait with.
     */
    function editTrait(uint256 traitID, NormieLib.Trait memory newTraitData) external onlyOwner {
        NormieLib.Trait memory _trait = traitIDToTrait[traitID];
        _trait.traitName = newTraitData.traitName;
        _trait.traitType = newTraitData.traitType;
        _trait.hash = newTraitData.hash;
        _trait.pixelCount = newTraitData.pixelCount;
        traitIDToTrait[traitID] = _trait;
    }

    /**
     * @dev Emergency function to remove incorrect traits from existence. Checks to make sure ID provided is greater than 1,000,000.
     * @param traitID The trait to remove from existence.
     */
    function removeTraitFromTraitMap(uint256 traitID) external onlyOwner {
        require(traitID >= 1000000, "Trait ID < 1,000,000");
        traitIDToTrait[traitID] = emptyTrait;
    }

    /**
     * @dev Adds traits to specific location. Good to use for reusing assets in another collection. (Ex. Reusing skinType assets).
     * @param traitIndex The index to add these traits to.
     * @param traitID Array of integers representing the traits to add to the given collectionNumber and traitIndex.
     */
    function addTraitsToCurrentCollection(uint256 traitIndex, uint256[] memory traitID) external onlyOwner {
        require(currentCollectionTraits[traitIndex].length + traitID.length <= traitRarity[traitIndex].length, "Trait array mismatch");
        for (uint256 i = 0; i < traitID.length; i++){
            currentCollectionTraits[traitIndex].push(traitID[i]);
        }
    }

    /**
     * @dev Sets the current color string. Allows us to add new colors in the future
     * @param _colorString The new color string.
     */
    function setColorString(string calldata _colorString) external onlyOwner {
        colorString = _colorString;
    }

    /**
     * @dev Used to add admin acccess for a contract
     * @param _addressToAdd The address to give admin access to.
     */
    function addAdminAccess(address _addressToAdd) external onlyOwner {
        adminAccess[_addressToAdd] = true;
    }
}
// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// File: Normies.sol


pragma solidity ^0.8.9;






// @author TheNormiesNFT (https://twitter.com/thenormiesnft)
contract Normies is ERC1155, ERC1155Supply {
    using NormieLib for uint8;

    // Constants
    bytes32 private constant SKIN_TYPE_ENCODED = 0x5e47b691d06cb279a2b83088501f7f7b0810b33cdbc8844c9fdb87a16a66b4d2; 
    bytes32 private constant HAIR_ENCODED = 0x0aaac4442b72fa7fe81a222e1228a95232016724605a031667e60f7fce199df4;
    bytes32 private constant EYES_ENCODED = 0x64d4144b555b7316ce2973ff7e3cc9b8820c041e28a9c9439849589862f663d1;
    bytes32 private constant MOUTH_ENCODED = 0xd908a9a3716170d54dd91b434bdf0688b2c9d7dd05496173e40a5b3c359e0a5d;
    bytes32 private constant TORSO_ENCODED = 0x1feffdcc0b7d6d36bc3fbde6c0358074c13f6df6cbb4c3635167e516f9842361;
    bytes32 private constant PANTS_ENCODED = 0x6954a6332b7373d68e9dc351bffce9caf76b16493bad3034481d431b6add2dee;
    bytes32 private constant SHOES_ENCODED = 0x737a05110ae7219d78dc103c20b859c24da0b24052049edf853a13a0ef55b3a8;
    bytes32 private constant ACCESSORY_ENCODED = 0xea1a852ad5cf1fce5321823cddedf8aca1177f0c1acfb21e5eb86211bb8da1a7;
    bytes32 private constant ACCESSORY_ONE_ENCODED = 0xf9a9f51bd5106f9b945fe92fa2e7e1257dc60ef3bedd55ddba22a2be68c08f4d;
    bytes32 private constant ACCESSORY_TWO_ENCODED = 0xfc913118f916d1f1b5b00fee9486a2e642821127817edff3ed98980ed99d49bf;
    bytes32 private constant ACCESSORY_THREE_ENCODED = 0x76bbb549a0b8d61781a306d7d1deabaab974ad0f09eec4fea6fa556565443c2d;

    // Private variables
    address private owner;
    address payable private paymentAddress;

    // Public variables
    bool public paused = false;
    bool public allowMint = false;
    bool public allowWhitelistMint = false;
    bool public assetMint = false;
    bool public freeAssetMint = false;
    uint256 public mintNormiePrice = 0.02 ether;
    uint256 public currentNormieSupply = 0;
    uint256 public maxNormieSupply = 5000; // Will increment this as we do more releases
    uint256 public mintAssetsPrice = 0.01 ether;
    uint256 public currentAssetsSupply = 0;
    uint256 public maxAssetsSupply = 2000; // Will increment this as we do more releases

    bytes32 public merkleRoot; //Used for veryifing whitelist, must be hardcoded before hand
    mapping(address => bool) public whitelistClaimed; //used to verify whether or not this person actually claimed their whitelist

    // Basic Mappings 
    mapping(uint256 => NormieLib.Normie) public normieIdToNormie;
    mapping(uint256 => address) public normieOwner;

    mapping(uint256 => bool) public freeTokenMap;
    uint256[] public claimedFreeTokens; // Used to clean the freeTokenMap mapping for next free asset mint
    
    NormieTraits traits;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Not the owner");
        _;
    }

    constructor(address traitsContract, address payable _paymentaddr) ERC1155("") {
        owner = msg.sender;
        traits = NormieTraits(traitsContract);
        paymentAddress = payable(_paymentaddr);
    }

    ///////////////////////////// MINT FUNCTIONS /////////////////////////////
    /*
     * @dev Mint function for normies. Before calling make sure "maxNormieSupply" and "mintNormiePrice" have been updated.
     * @param amount Amount of mints being done in a transaction.
     */
    function mintNormie(uint256 amount)
    public payable {
        require(!allowMint, "Mint00");
        require(amount > 0, "Mint01");
        
        if (msg.sender != owner){
            require(msg.value >= mintNormiePrice * amount, "Not enough eth");
        }

        uint256 localCurrentNormieSupply = currentNormieSupply;
        require(localCurrentNormieSupply + amount <= maxNormieSupply, "Mint04");

        for (uint256 i = 1; i <= amount; i++){
            // Create each normie here.
            NormieLib.Normie memory newNormie = traits.generateNormie(localCurrentNormieSupply + i, msg.sender);
            normieIdToNormie[localCurrentNormieSupply + i] = newNormie;
            normieOwner[localCurrentNormieSupply + i] = msg.sender;
            _mint(msg.sender, localCurrentNormieSupply + i, 1, "");
        }
        currentNormieSupply = localCurrentNormieSupply + amount;
    }

    /*
     * @dev Whitelist Mint function for normies using MerkleTrees. Before calling make sure "maxNormieSupply" and "mintNormiePrice" have been updated.
     * @param amount Amount of mints being done in a transaction.
     * @param _merkleProof The hashed version of a user's address.
     */
    function whitelistMint(uint256 amount, bytes32[] calldata _merkleProof) 
    external payable {
        require(!allowWhitelistMint, "Mint00");

        //You can only mint up to 20 for whitelist
        require(amount > 0 && amount <= 20, "Mint01");

        //Make sure the person hasn't claimed yet
        require(!whitelistClaimed[msg.sender], "Address has already been claimed");

        //Verify the provided _merkleProof, given through the api call on our website.
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof");

        //Person has claimed their token.
        whitelistClaimed[msg.sender] = true;
        
        if (msg.sender != owner){
            require(msg.value >= mintNormiePrice * amount, "Not enough eth");
        }

        //Minting the token        
        uint256 localCurrentNormieSupply = currentNormieSupply;
        require(localCurrentNormieSupply + amount <= maxNormieSupply, "Mint04");

        for (uint256 i = 1; i <= amount; i++){
            // Create each normie here.
            NormieLib.Normie memory newNormie = traits.generateNormie(localCurrentNormieSupply + i, msg.sender);
            normieIdToNormie[localCurrentNormieSupply + i] = newNormie;
            normieOwner[localCurrentNormieSupply + i] = msg.sender;
            _mint(msg.sender, localCurrentNormieSupply + i, 1, "");
        }
        currentNormieSupply = localCurrentNormieSupply + amount;
    }

    /*
     * @dev Mint function for assets. Before calling make sure "maxAssetSupply" and "mintAssetPrice" have been updated.
     * @param amount Amount of mints being done in a transaction.
     */
    function mintAssets(uint256 amount)
    external payable {
        require(!assetMint, "Mint00");
        require(amount > 0, "Mint01");
        if (msg.sender != owner){
            require(msg.value >= mintAssetsPrice * amount, "Not enough eth");
        }

        uint256 localCurrentAssetsSupply = currentAssetsSupply;
        require(localCurrentAssetsSupply + amount <= maxAssetsSupply, "Mint04");

        uint256[] memory generatedHash;
        uint256 j = 0;
        uint256 currentTraitID;
        for (uint256 i = 1; i <= amount; i++){
            generatedHash = traits.hash(localCurrentAssetsSupply + i, msg.sender);
            for (j = 0; j < 10; j++){ 
                currentTraitID = traits.currentCollectionTraits(j,generatedHash[j]);
                if (currentTraitID != 1000001){
                    _mint(msg.sender, currentTraitID, 1, "");
                }
            }
        }

        currentAssetsSupply = localCurrentAssetsSupply + amount;
    }

    /*
     * @dev Mint function for token holders to get free assets.
     * @param tokenID Normie token ID. Used to verify that the person claiming the free asset actually owns the Normie.
     */
    function normieHolderMint(uint256 tokenID)
    external {
        require(!freeAssetMint, "Mint00");
        require(normieOwner[tokenID] == msg.sender, "Normie not owned by you");
        require(!freeTokenMap[tokenID], "Already claimed");

        uint256 localCurrentAssetsSupply = currentAssetsSupply;
        require(localCurrentAssetsSupply + 1 <= maxAssetsSupply, "Mint04");

        uint256[] memory generatedHash = traits.hash(localCurrentAssetsSupply + 1, msg.sender);
        uint256 currentTraitID;
        for (uint256 j = 0; j < 10; j++){ 
            currentTraitID = traits.currentCollectionTraits(j,generatedHash[j]);
            if (currentTraitID != 1000001){
                _mint(msg.sender, currentTraitID, 1, "");
            }
        }

        currentAssetsSupply = localCurrentAssetsSupply + 1;
        freeTokenMap[tokenID] = true;
        claimedFreeTokens.push(tokenID);
    }

    /*
     * @dev Overriden transfer function. When normies are transfered we update the normieOwner map.
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal override(ERC1155, ERC1155Supply) {
        require(!paused, "Paused");
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 tokenID = ids[i];
            if (tokenID <= 1000000) {
                normieOwner[tokenID] = to;
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    ///////////////////////////// NORMIE CUSTOMIZE FUNCTIONS /////////////////////////////

    /*
     * @dev Public facing function that allows someone to remove traits from a normie.
     * @param normieID Normie token ID to remove trait from.
     * @param traitType Trait type to remove from. (Ex. Shoes, Bag, etc).
     */
    function removeTrait(uint256 normieID, string calldata traitType) public {
        require(!paused, "Paused");
        require(msg.sender == normieOwner[normieID], "Not owner");
        uint256 removedTraitID = removeTraitHelper(normieID, traitType, false);
        if (removedTraitID != 1000001) {
            _mint(msg.sender, removedTraitID, 1, "");
        }
    }

    /*
     * @dev Public facing function that allows someone to equip traits to a normie.
     * @param normieID Normie token ID to remove trait from.
     * @param traitType Trait type to remove from. (Ex. Shoes, Bag, etc).
     * @param traitID ID of Trait to equip. Should be greater than 1,000,000.
     */
    function equipTrait(uint256 normieID, string calldata traitType, uint256 traitID) external {
        require(!paused, "Paused");
        require(msg.sender == normieOwner[normieID], "Not owner");
        require(balanceOf(msg.sender, traitID) >= 1, "Do not own traitID");
        require(traitID > 1000000, "Not a traitID");
        uint256 removedTraitID = removeTraitHelper(normieID, traitType, true);
        if (removedTraitID != 1000001) {
            _mint(msg.sender, removedTraitID, 1, "");
        }
        equipTraitHelper(normieID, traitType, traitID);
        _burn(msg.sender, traitID, 1);
    }

    /**
     * @dev Removes a trait from a given "normie" using the provided "traitType". 
     * @param normieID ID of the normie being edited.
     * @param traitType The trait type being edited (Ex. Shoes).
     * @param equipAfter Boolean that indicates if this function was called to just remove or will also equip after. 
                         Provides extra functionality to ensure that a Normie cannot be completely blank and must keep its skin on.
     * @return (uint256) traitID to mint to user's wallet.
     */
    function removeTraitHelper(uint256 normieID, string calldata traitType, bool equipAfter) private
    returns (uint256) {
        NormieLib.Normie storage normie = normieIdToNormie[normieID];
        uint256 traitID;
        bytes32 encodedTraitType = keccak256(abi.encodePacked(traitType));
        if (encodedTraitType == SHOES_ENCODED){
            traitID = normie.shoes;
            normie.shoes = 1000001;
        } else if (encodedTraitType == PANTS_ENCODED) {
            traitID = normie.pants;
            normie.pants = 1000001;
        } else if (encodedTraitType == TORSO_ENCODED) {
            traitID = normie.torso;
            normie.torso = 1000001;
        } else if (encodedTraitType == SKIN_TYPE_ENCODED
                    && equipAfter) {
            traitID = normie.skinType;
            normie.skinType = 1000001;
        } else if (encodedTraitType == MOUTH_ENCODED) {
            traitID = normie.mouth;
            normie.mouth = 1000001;
        } else if (encodedTraitType == EYES_ENCODED) {
            traitID = normie.eyes;
            normie.eyes = 1000001;
        } else if (encodedTraitType == HAIR_ENCODED) {
            traitID = normie.hair;
            normie.hair = 1000001;
        } else if (encodedTraitType == ACCESSORY_ONE_ENCODED) {
            traitID = normie.accessoryOne;
            normie.accessoryOne = 1000001;
        } else if (encodedTraitType == ACCESSORY_TWO_ENCODED) {
            traitID = normie.accessoryTwo;
            normie.accessoryTwo = 1000001;
        } else if (encodedTraitType == ACCESSORY_THREE_ENCODED) {
            traitID = normie.accessoryThree;
            normie.accessoryThree = 1000001;
        } else {
            revert();
        }
        return traitID;
    }

    /**
     * @dev Equips a new trait to a given "normie" using the provided "traitID". 
     *      Checks to make sure "traitType" provided is the same as the traitType being equipped.
     *      Returns the updated normie. Used to update normieIdToNormie mapping in Normies.sol.
     * @param normieID ID of the normie being edited.
     * @param traitType The trait type being edited (Ex. Shoes).
     * @param traitID The traitID of the trait to equip.
     */
    function equipTraitHelper(uint256 normieID, string calldata traitType, uint256 traitID) private {
        uint32 newTraitID = uint32(traitID);
        string memory newTraitType = traits.getTraitTypeByTraitID(traitID);
        bytes32 encodedTraitType = keccak256(abi.encodePacked(traitType));
        bytes32 newTraitEncoded = keccak256(abi.encodePacked(newTraitType));

        if (newTraitEncoded == ACCESSORY_ENCODED){
            require(encodedTraitType == ACCESSORY_ONE_ENCODED
                || encodedTraitType == ACCESSORY_TWO_ENCODED
                || encodedTraitType == ACCESSORY_THREE_ENCODED, "Accessory mismatch");
        } else {
            require(encodedTraitType == newTraitEncoded, "Not the same trait type");
        }

        NormieLib.Normie storage normie = normieIdToNormie[normieID];
        if (encodedTraitType == SHOES_ENCODED){
            normie.shoes = newTraitID;
        } else if (encodedTraitType == PANTS_ENCODED) {
            normie.pants = newTraitID;
        } else if (encodedTraitType == TORSO_ENCODED) {
            normie.torso = newTraitID;
        } else if (encodedTraitType == SKIN_TYPE_ENCODED) {
            normie.skinType = newTraitID;
        } else if (encodedTraitType == MOUTH_ENCODED) {
            normie.mouth = newTraitID;
        } else if (encodedTraitType == EYES_ENCODED) {
            normie.eyes = newTraitID;
        } else if (encodedTraitType == HAIR_ENCODED) {
            normie.hair = newTraitID;
        } else if (encodedTraitType == ACCESSORY_ONE_ENCODED) {
            normie.accessoryOne = newTraitID;
        } else if (encodedTraitType == ACCESSORY_TWO_ENCODED) {
            normie.accessoryTwo = newTraitID;
        } else if (encodedTraitType == ACCESSORY_THREE_ENCODED) {
            normie.accessoryThree = newTraitID;
        } else {
            revert();
        }
    }


    ///////////////////////////// OPENSEA READ FUNCTIONS /////////////////////////////

    /*
     * @dev Name function used by OpenSea to name a collection.
     */
    function name() external pure returns (string memory) {
        return "TEMP NAME";
    }

    /*
     * @dev Name function used by OpenSea to set the symbol for a collection.
     */
    function symbol() external pure returns (string memory) {
        return "TEMP";
    }

    /*
     * @dev URI function used by OpenSea to display NFTs.
     * @param _id Gets URI of a given token ID.
     * @return URI of a given token ID.
     */
    function uri(uint256 _id) 
    public view override 
    returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        if (_id <= 1000000){
            NormieLib.Normie storage normie = normieIdToNormie[_id];
            return traits.getNormieURI(normie, _id);
        } else {
            return traits.getAssetURI(_id);
        }
    }

    ///////////////////////////// OWNER FUNCTIONS /////////////////////////////
    /**
     * @dev Resets the freeTokenMap so that every address has a chance of claiming the free traits again.
     */
    function cleanFreeTokenMap() external onlyOwner {
        for (uint256 i = 0; i < claimedFreeTokens.length; i++){
            freeTokenMap[claimedFreeTokens[i]] = false;
        }
        delete claimedFreeTokens;
    }

    /**
     * @dev Sets normie mint price. Input is in wei and should be converted properly to eth before calling.
     * @param _mintNormiePrice New mint Normie price.
     */
    function setMintNormiePrice(uint256 _mintNormiePrice) external onlyOwner {
        require(_mintNormiePrice >= 0.01 ether, "Price less than 0.01 eth");
        mintNormiePrice = _mintNormiePrice;
    }

    /**
     * @dev Sets asset mint price. Input is in wei and should be converted propertly to eth before calling.
     * @param _mintAssetsPrice New mint assets price.
     */
    function setMintAssetsPrice(uint256 _mintAssetsPrice) external onlyOwner {
        require(_mintAssetsPrice >= 0.01 ether, "Price less than 0.01 eth");
        mintAssetsPrice = _mintAssetsPrice;
    }

    /**
     * @dev Sets the max normie supply. Altering this will allow us to increase the number of normies allowed to be minted.
     * @param _maxNormieSupply New max Normie supply.
     */
    function setMaxNormieSupply(uint256 _maxNormieSupply) external onlyOwner {
        maxNormieSupply = _maxNormieSupply;
    }

    /**
     * @dev Sets the max asset collection supply. Altering this will allow us to increase the number of asset packs allowed to be minted.
     * @param _maxAssetsSupply New max assets supply.
     */
    function setMaxAssetsSupply(uint256 _maxAssetsSupply) external onlyOwner {
        maxAssetsSupply = _maxAssetsSupply;
    }

    /**
     * @dev Owner mint function to be used to mint and giveaway assets.
     * @param tokenID An array of token IDs to mint to owner of contract.
     * @param amount An array of amounts for each associated token ID to mint.
     */
    function ownerMintAssets(uint256[] memory tokenID, uint256[] memory amount) external onlyOwner {
        require(tokenID.length == amount.length);
        for (uint256 i = 0; i < tokenID.length; i++){
            _mint(msg.sender, tokenID[i], amount[i], "");
        }
    }

    /**
     * @dev Flips the paused variable to pause/ unpause the contract.
     */
    function flipPaused() external onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Flips the assetMint variable to pause/ unpause the contract.
     */
    function flipAllowMint() external onlyOwner {
        allowMint = !allowMint;
    }

    /**
     * @dev Flips the whitelistPaused variable to pause/ unpause the contract.
     */
    function flipAllowWhitelistMint() external onlyOwner {
        allowWhitelistMint = !allowWhitelistMint;
    }

    /**
     * @dev Flips the assetMint variable to pause/ unpause asset minting.
     */
    function flipAssetMint() external onlyOwner {
        assetMint = !assetMint;
    }

    /**
     * @dev Flips the freeAssetMint variable to pause/ unpause free asset minting.
     */
    function flipFreeAssetMint() external onlyOwner {
        freeAssetMint = !freeAssetMint;
    }

    /**
     * @dev Update the payment address.
     * @param _addr The new payable address.
     */
    function setPaymentAddr(address payable _addr) external onlyOwner {
        paymentAddress = _addr;
    }

    /**
     * @dev Updates the merkle root.
     * @param _merkleroot The new merkle root.
     */
    function setMerkleRoot(bytes32 _merkleroot) external onlyOwner {
        merkleRoot = _merkleroot;   
    }

    /**
     * @dev Withdraw the ETH from the contract to the payments address.
     */
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(paymentAddress).call{value: address(this).balance}("");
        require(os);
    }
}