// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MetadataStruct.sol";

contract metadataAddonContract {

    function getImage(uint _collectionId, uint _tokenId) external view returns (string memory) {}

    function getMetadata(uint _collectionId, uint _tokenId) external view returns (string memory) {}

}

contract verifiableRandomNumberContract {
    function getRandomNumber() external returns(uint) {}
}

contract MetadataManager is Ownable {

    /**
     @notice Credits goes out to Ether Orcs
    */

    struct Phoenix {
        uint128 hash;
        uint8 level;
        string name;
    }

    struct TraitRarity {
        uint16 rarityRange;
        uint16 index;
    }

    struct MythicInfo {
        string image;
        string name;
    }

    mapping(uint => mapping(uint => address)) propertyAddresses;

    mapping(uint => mapping (uint => uint)) mythicTokens;

    mapping(uint => mapping(uint => uint16[])) PropertyRarityRanges;

    mapping(uint => mapping(uint => TraitRarity[])) PropertyRarities;

    mapping(uint => bool) collectionRevealed;

    mapping(uint => mapping(uint => MythicInfo)) mythicInfoMap;

    mapping(uint => uint) mythicsAdded;

    mapping(uint => uint) totalMythics;

    address[] addonAddresses;

    mapping(address => bool) acceptedAddresses;

    mapping(uint => uint[]) mythicRewardPool;

    verifiableRandomNumberContract randomNumberContract;

    string public constant header = '<svg id="phoenix" width="100%" height="100%" version="1.1" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer = '<style>#phoenix{image-rendering: pixelated;}</style></svg>';

    /**

         __    __     ______     ______   ______     _____     ______     ______   ______    
        /\ "-./  \   /\  ___\   /\__  _\ /\  __ \   /\  __-.  /\  __ \   /\__  _\ /\  __ \   
        \ \ \-./\ \  \ \  __\   \/_/\ \/ \ \  __ \  \ \ \/\ \ \ \  __ \  \/_/\ \/ \ \  __ \  
         \ \_\ \ \_\  \ \_____\    \ \_\  \ \_\ \_\  \ \____-  \ \_\ \_\    \ \_\  \ \_\ \_\ 
          \/_/  \/_/   \/_____/     \/_/   \/_/\/_/   \/____/   \/_/\/_/     \/_/   \/_/\/_/ 
                                                                                             

    */

    function generateImage(uint[] memory _traits, uint _tokenId, uint _collectionId, uint _numTraits) internal view returns(string memory) {

        uint mythicId = mythicTokens[_collectionId][_tokenId];
        string memory image;

        if (mythicId > 0) {

            MythicInfo memory mythicInfo = mythicInfoMap[_collectionId][mythicId];
            

            if(bytes(mythicInfo.name).length > 0) {
                image = wrapTag(mythicInfo.image);
            } else {
                image = getImage(_numTraits, mythicId - 1, _collectionId);
            }

            return string(abi.encodePacked(header, image, getAdditionalImage(_collectionId, _tokenId), footer));

        } 

        image = header;

        for(uint i = 0; i < _numTraits; i++) {
            image = string(abi.encodePacked(image, getImage(i, _traits[i], _collectionId)));
        }


        return string(abi.encodePacked(image, getAdditionalImage(_collectionId, _tokenId), footer));
    }


    function tokenURI(Phoenix memory _phoenix, MetadataStruct memory _metadataStruct) public view returns (string memory) {

        if(bytes(_phoenix.name).length == 0) {
            _phoenix.name = string(abi.encodePacked('Phoenix #', ImageHelper.toString(_metadataStruct.tokenId)));
        }

        if(collectionRevealed[_metadataStruct.collectionId] == false) {
            //Collection is yet to be revealed
            return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    ImageHelper.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "', _phoenix.name,'", "description": "', _metadataStruct.description, '", "image": "',
                                'data:image/svg+xml;base64,',
                                ImageHelper.encode((abi.encodePacked(header, wrapTag(_metadataStruct.unRevealedImage), footer))),
                                '","attributes": [{"trait_type": "Level", "value": "', ImageHelper.toString(_phoenix.level), '"}]}'
                            )
                        )
                    )
                )
            );
        }

        uint[] memory traits = getTraitsFromHash(_phoenix.hash, _metadataStruct.collectionId, _metadataStruct.numTraits);

        string memory image = ImageHelper.encode(bytes(generateImage(traits, _metadataStruct.tokenId, _metadataStruct.collectionId, _metadataStruct.numTraits)));

        return

            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    ImageHelper.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "', _phoenix.name,'", "description": "', _metadataStruct.description, '", "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '",',

                                getAttributes(traits, _metadataStruct.collectionId, _metadataStruct.numTraits, _phoenix.level, _metadataStruct.tokenId),
                                getAdditionalMetadata(_metadataStruct.collectionId, _metadataStruct.tokenId),
                                
                                ']',
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function call(address _source, bytes memory _sig) internal view returns (string memory) {
        (bool succ, bytes memory ret)  = _source.staticcall(_sig);
        require(succ, "failed to get data");
        return abi.decode(ret, (string));
    }

    function getImage(uint _propertyIndex, uint _id, uint _collectionId) internal view returns (string memory) {
        address source = propertyAddresses[_collectionId][uint(_propertyIndex)];

        string memory image = call(source, abi.encodeWithSignature(string(abi.encodePacked("trait", ImageHelper.toString(_id), "()")), ""));

        if(bytes(image).length > 0) {
             return wrapTag(image);
        } else {
            return "";
        }

       
    }

    function getTraitName(uint _propertyIndex, uint _id, uint _collectionId) internal view returns (string memory) {
        address source = propertyAddresses[_collectionId][uint(_propertyIndex)];

        return call(source, abi.encodeWithSignature(string(abi.encodePacked("name", ImageHelper.toString(_id), "()")), ""));
    }

    function getPropertyName(uint _propertyIndex,  uint _collectionId) internal view returns (string memory) {
        address source = propertyAddresses[_collectionId][_propertyIndex];

        return call(source, abi.encodeWithSignature("propertyName()", ""));
    }
    
    function wrapTag(string memory uri) internal pure returns (string memory) {
    
        return string(abi.encodePacked('<image x="0" y="0" width="48" height="48" xlink:href="data:image/png;base64,', uri, '"/>'));
    
    }

    function getAttributes(uint[] memory _traits, uint _collectionId, uint _numTraits, uint8 _level, uint _tokenId) internal view returns (string memory) {
       
        string memory attributeString;

        uint mythicId = mythicTokens[_collectionId][_tokenId];

        if (mythicId > 0) {

            MythicInfo memory mythicInfo = mythicInfoMap[_collectionId][mythicId];
            

            if(bytes(mythicInfo.name).length > 0) {
                attributeString = string(abi.encodePacked('{"trait_type": "', getPropertyName(_numTraits, _collectionId), '","value": "', mythicInfo.name,'"}', ",")) ;
            } else {
                attributeString = string(abi.encodePacked(getTraitAttributes(mythicId - 1, _numTraits, _collectionId)));
            }

        } else {
            for(uint i = 0; i < _numTraits; i++) {
                attributeString = string(abi.encodePacked(attributeString, getTraitAttributes(_traits[i], i, _collectionId)));
            }
        }

        return string(abi.encodePacked(
            '"attributes": [',
            attributeString, 
            '{"trait_type": "Level", "value": "', ImageHelper.toString(_level), '"}'));
    }

    function getTraitAttributes(uint _traitId, uint _propertyIndex, uint _collectionId) internal view returns(string memory) {

        string memory traitName = getTraitName(_propertyIndex, _traitId, _collectionId);
        if(bytes(traitName).length == 0) {
            return "";
        }
        return string(abi.encodePacked('{"trait_type": "', getPropertyName(_propertyIndex, _collectionId), '","value": "', traitName,'"}', ","));
    }

    function traitPicker(uint16 _randinput, TraitRarity[] memory _traitRarities) internal pure returns (uint)
    {

        uint minIndex = 0;
        uint maxIndex = _traitRarities.length -1;
        uint midIndex;

        //Do a binary search so we can limit the number of attempts to find the proper trait
        while(minIndex < maxIndex) {

            midIndex = (minIndex + maxIndex) / 2;

            if(minIndex == midIndex) {
                if(_randinput <= _traitRarities[minIndex].rarityRange) {
                    return _traitRarities[minIndex].index;
                }

                return _traitRarities[maxIndex].index;
            }

            if(_randinput <= _traitRarities[midIndex].rarityRange) {
                maxIndex = midIndex;

            } else {
                minIndex = midIndex;
                
            }

        }

        return _traitRarities[midIndex].index;
        
    }

    
    function getTraitsFromHash(uint128 _hash, uint _collectionId, uint _numTraits) public view returns(uint[] memory) {

        uint[] memory traits = new uint[](_numTraits);
        uint16 randomInput;

        for(uint i = 0; i < _numTraits; i++) {

            randomInput = uint16((_hash / 10000**i % 10000));

            traits[i] = traitPicker(randomInput, PropertyRarities[_collectionId][i]);

        }

        return traits;

    }


    function getAdditionalImage(uint _collectionId, uint _tokenId) internal view returns(string memory) {

        string memory images;

        for(uint i = 0; i < addonAddresses.length; i++) {

            abi.encodePacked(images, metadataAddonContract(addonAddresses[i]).getImage(_collectionId, _tokenId));

        }

        return images;

    }

    function getAdditionalMetadata(uint _collectionId, uint _tokenId) internal view returns(string memory) {

        string memory metaData;

        for(uint i = 0; i < addonAddresses.length; i++) {

            if(addonAddresses[i] != address(0)) {

                metaData = string(abi.encodePacked(metaData, metadataAddonContract(addonAddresses[i]).getMetadata(_collectionId, _tokenId)));

            }

        }

        if(bytes(metaData).length > 0) {
            //metadat isnt empty, so lets add a comma in front
            metaData = string(abi.encodePacked(",", metaData));
        }

        return metaData;
    }

    function getRarityIndex(uint _collectionId, uint index) external view returns(uint16[] memory) {
        return PropertyRarityRanges[_collectionId][index];
    }

    function getSpecialToken(uint _collectionId, uint _tokenId) public view returns(uint) {
        return mythicTokens[_collectionId][_tokenId];
    }


   /**
         ______     __     __     __   __     ______     ______    
        /\  __ \   /\ \  _ \ \   /\ "-.\ \   /\  ___\   /\  == \   
        \ \ \/\ \  \ \ \/ ".\ \  \ \ \-.  \  \ \  __\   \ \  __<   
         \ \_____\  \ \__/".~\_\  \ \_\\"\_\  \ \_____\  \ \_\ \_\ 
          \/_____/   \/_/   \/_/   \/_/ \/_/   \/_____/   \/_/ /_/ 
                                                                   
   */

    function setProperty(uint8 _propertyIndex, uint8 _collectionId, address _addr) external onlyOwner {

        propertyAddresses[_collectionId][_propertyIndex] = _addr;     
    }

    function setPropertyRarities(uint16[] calldata rarities, uint collectionId, uint propertyId) external onlyOwner {
  
        PropertyRarityRanges[collectionId][propertyId] = rarities; 
    }

    
    function revealCollection(uint _collectionId, uint _totalSupply, uint _numMythic, uint _numProperties) external onlyOwner {

        require(collectionRevealed[_collectionId] == false, "Collection already revealed");

        collectionRevealed[_collectionId] = true;

        revealMythics(_numMythic, _collectionId, _totalSupply);

        for(uint i = 0; i < _numProperties; i++) {

            mixUpTraits(_collectionId, i);

        }

    }

    function revealMythics(uint _numMythic, uint _collectionId, uint _totalSupply) internal onlyOwner {

        uint hash =  uint256(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty, _collectionId, _totalSupply, _numMythic)
                        )    
                    );

        uint i = 0;
        uint uniqueChosen = 0;
    
        while(uniqueChosen < _numMythic) {

            uint randomInput = (hash / _totalSupply**i % _totalSupply) ;
            
            if(mythicTokens[_collectionId][randomInput] == 0) {
                uniqueChosen += 1;
                mythicTokens[_collectionId][randomInput] = uniqueChosen; 
            }

            i++; 

        }

        totalMythics[_collectionId] = _numMythic;
        mythicsAdded[_collectionId] = _numMythic;

    }

    function mixUpTraits(uint _collectionId, uint _propertyIndex) internal onlyOwner {

        uint hash =  uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty, _collectionId, _propertyIndex)
                    )    
                );

        uint total = 0;

        uint16[] memory traitRarities = PropertyRarityRanges[_collectionId][_propertyIndex];

        uint tempLength = traitRarities.length;

        uint index = 0;

        require(tempLength > 0, "temp length should be more than zero");

        for(uint j = 0; j < traitRarities.length; j++) {

            index = (hash / ((j + 1) * 100000))  % tempLength;

            total += traitRarities[index];

            PropertyRarities[_collectionId][_propertyIndex].push(TraitRarity(
                uint16(total),
                uint16(index)
            ));

            uint16 last = traitRarities[tempLength - 1];

            traitRarities[index] = last;

            tempLength -= 1;
  
        }

    }

    function setAcceptedAddress(address _acceptedAddress, bool _value) external onlyOwner {

        acceptedAddresses[_acceptedAddress] = _value;

    }

    function setAddonContractAddress(address _addr, uint _index) external onlyOwner {

        require(_index <= addonAddresses.length, "index out of range");

        if(_index == addonAddresses.length) {
            addonAddresses.push(_addr);

        } else {
            addonAddresses[_index] = _addr;
        }

    }

    function setRandomNumberContract(address _addr) external onlyOwner {

        randomNumberContract = verifiableRandomNumberContract(_addr);

    }

    function addMythicToPool(MythicInfo calldata _mythicInfo, uint _collectionId) external onlyOwner {

        uint total =  totalMythics[_collectionId];

        mythicInfoMap[_collectionId][total] = _mythicInfo;

        totalMythics[_collectionId] += 1;

    }

    
    function resurrect(uint _collectionId, uint _tokenId) external {

        require(acceptedAddresses[msg.sender] == true, "Address cannot call this function");

        require(mythicTokens[_collectionId][_tokenId] == 0, "Mythic tokens refuse to be resurected");

        mythicRewardPool[_collectionId].push(_tokenId);

    }

    function rewardMythics(uint _collectionId, uint _numMythics) external {

        require(address(randomNumberContract) != address(0), "random number contract not set");

        require(acceptedAddresses[msg.sender] == true, "Address cannot call this function");

        uint lastMythic = mythicsAdded[_collectionId];

        uint numInPool = totalMythics[_collectionId] - lastMythic;

        require(numInPool <= _numMythics, "Trying to give away more mythics than exist");

        uint[] memory rewardPool = mythicRewardPool[_collectionId];

        //uint verifiablyRandomNumber = randomNumberContract.getRandomNumber();

        uint verifiablyRandomNumber = uint(keccak256(abi.encodePacked(msg.sender, _numMythics)));

        uint tempLength = rewardPool.length;

        require(tempLength >= _numMythics, "More mythics to add than there are tokens in pool to give");

        uint totalMythicsGiven = 0;

        while(totalMythicsGiven < _numMythics) {

            require(tempLength > 0, "Length of reward pool is zero");

            uint randindex = (verifiablyRandomNumber / ((totalMythicsGiven + 1) * 5000)) % tempLength;

            if(mythicTokens[_collectionId][rewardPool[randindex]] == 0) {
                //this token is not already a 1/1, so is chosen to be
                mythicTokens[_collectionId][rewardPool[randindex]] = lastMythic;
                mythicsAdded[_collectionId] += 1;

                lastMythic += 1;
                totalMythicsGiven += 1;
            }

            rewardPool[randindex] = rewardPool[tempLength - 1];

            tempLength -= 1;

        }

        uint[] memory clearedPool;

        //Clear the mythic reward pool
        mythicRewardPool[_collectionId] = clearedPool;


    }

}

    


library ImageHelper {

    
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    /// @notice developed by Brecht Devos - <[email protected]>
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

struct MetadataStruct {

	uint tokenId;
	uint collectionId;
	uint numTraits;
	string description;
	string unRevealedImage;

}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}