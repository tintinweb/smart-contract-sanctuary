// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MetadataStruct.sol";
import "./VRFConsumer.sol";

contract metadataAddonContract  {

    function getImage(uint _collectionId, uint _tokenId) external view returns (string memory) {}

    function getMetadata(uint _collectionId, uint _tokenId) external view returns (string memory) {}

}

contract MetadataManager is Ownable, VRFConsumerBase {

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

    string public constant header = '<svg id="phoenix" width="100%" height="100%" version="1.1" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer = '<style>#phoenix{image-rendering: pixelated;}</style></svg>';

    //Chainlink verifiable random number variables
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    uint numPhoenixToReveal;
    uint supplyPoolToGiveaway;
    uint revealingCollectionId;
    bool rewardFromPool;
    uint verifiablyRandomNumber;


    event randomNumberRecieved(uint randomness);



    constructor()  VRFConsumerBase(
                    0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
                    0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
                    ) {



        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)


    }

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

    function getPropertyRarities(uint _collectionId, uint _propertyIndex) public view returns(TraitRarity[] memory) {

        require(PropertyRarities[_collectionId][_propertyIndex].length > 0, "Property index out of range");

        return PropertyRarities[_collectionId][_propertyIndex];

    }

    function getRewardPool(uint _collectionId) public view returns(uint[] memory) {
        return mythicRewardPool[_collectionId];
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

    
    function revealCollection(uint _collectionId, uint _numProperties, uint _totalMythics) external onlyOwner {

        require(collectionRevealed[_collectionId] == false, "Collection already revealed");

        collectionRevealed[_collectionId] = true;

        for(uint i = 0; i < _numProperties; i++) {

            mixUpTraits(_collectionId, i);

        }

        totalMythics[_collectionId] = _totalMythics;

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

    function resurrect(uint _collectionId, uint _tokenId) external {

        require(acceptedAddresses[msg.sender] == true, "Address cannot call this function");

        require(mythicTokens[_collectionId][_tokenId] == 0, "Mythic tokens refuse to be resurected");

        mythicRewardPool[_collectionId].push(_tokenId);

    }


    //Mythic 1/1 functions


    function addMythicToPool(MythicInfo calldata _mythicInfo, uint _collectionId) external onlyOwner {

        uint total =  totalMythics[_collectionId];

        mythicInfoMap[_collectionId][total] = _mythicInfo;

        totalMythics[_collectionId] += 1;

    }

    

    function rewardMythics(uint _collectionId, uint _numMythics) external {

        require(verifiablyRandomNumber != 0, "verifiablyRandomNumber has not been set");

        require(acceptedAddresses[msg.sender] == true, "Address cannot call this function");

        uint lastMythic = mythicsAdded[_collectionId];

        uint numInPool = totalMythics[_collectionId] - lastMythic;

        require(numInPool <= _numMythics, "Trying to give away more mythics than exist");

        uint[] memory rewardPool = mythicRewardPool[_collectionId];

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


        //Reset this random number so we cant call this function before a new one is generated
        verifiablyRandomNumber = 0;


    }

    function revealMythics(uint _numMythic, uint _collectionId, uint _totalSupply, uint _verifiablyRandomNumber) internal {

        uint i = 0;
        uint uniqueChosen = 0;

        uint total = mythicsAdded[_collectionId];
    
        while(uniqueChosen < _numMythic) {

            uint randomInput = (_verifiablyRandomNumber / (_totalSupply**i) % _totalSupply);
            
            if(mythicTokens[_collectionId][randomInput] == 0) {
                uniqueChosen += 1;
                mythicTokens[_collectionId][randomInput] = total;
                total++; 
            }

            i++; 

        }

        mythicsAdded[_collectionId] = total;

    }



    function initiateCallToGiveawayMythics(uint _numMythics, uint _numberInSupply, uint _collectionId, bool _rewardFromResurrection) external onlyOwner {

        require(mythicsAdded[_collectionId] + _numMythics <= totalMythics[_collectionId], "Trying to give away too many mythics than exist");

        numPhoenixToReveal = _numMythics;
        supplyPoolToGiveaway = _numberInSupply;
        revealingCollectionId = _collectionId;
        rewardFromPool = _rewardFromResurrection;
        getRandomNumber();

    }


    /* Chainlink random functions
    /** 
     * Requests randomness 
     */
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {

        emit randomNumberRecieved(randomness);

        if(rewardFromPool) {
            //Set this so it can be used when the immortalPhoenix contract calls the function to destribute the reward
            //will have to make sure we toggle off resurrection before we call for this number to prevent manipulation
            verifiablyRandomNumber = randomness;
        } else {

            //We are giving randomly to the current supply of minted phoenixs
            revealMythics(numPhoenixToReveal, revealingCollectionId, supplyPoolToGiveaway, randomness);

        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
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

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

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