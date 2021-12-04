// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721EnumerableCheap.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

struct Phoenix {
        uint128 hash;
        uint8 level;
        string name;
}

struct MetadataStruct {

    uint tokenId;
    uint collectionId;
    uint numTraits;
    string description;
    string unRevealedImage;

}

struct PaymentStruct {
    address membersAddress;
    uint owed;
    uint payed;
}

struct ResurrectionInfo {
    uint tokenId;
    uint128 hash;
}


contract IBlazeToken {

    function updateTokens(address userAddress) external {}

    function updateTransfer(address _fromAddress, address _toAddress) external {}

    function burn(address  _from, uint256 _amount) external {}

}

contract IMetadataHandler {

    function tokenURI(Phoenix memory _phoenix, MetadataStruct memory _metadataStruct) external view returns(string memory)  {}

    function getSpecialToken(uint _collectionId, uint _tokenId) external view returns(uint) {}

    function resurrect(uint _collectionId, uint _tokenId) external {}

    function rewardMythics(uint _collectionId, uint _numMythics) external {}
}

/**
 __     __    __     __    __     ______     ______     ______   ______     __           
/\ \   /\ "-./  \   /\ "-./  \   /\  __ \   /\  == \   /\__  _\ /\  __ \   /\ \          
\ \ \  \ \ \-./\ \  \ \ \-./\ \  \ \ \/\ \  \ \  __<   \/_/\ \/ \ \  __ \  \ \ \____     
 \ \_\  \ \_\ \ \_\  \ \_\ \ \_\  \ \_____\  \ \_\ \_\    \ \_\  \ \_\ \_\  \ \_____\    
  \/_/   \/_/  \/_/   \/_/  \/_/   \/_____/   \/_/ /_/     \/_/   \/_/\/_/   \/_____/    
                                                                                         
             ______   __  __     ______     ______     __   __     __     __  __         
            /\  == \ /\ \_\ \   /\  __ \   /\  ___\   /\ "-.\ \   /\ \   /\_\_\_\        
            \ \  _-/ \ \  __ \  \ \ \/\ \  \ \  __\   \ \ \-.  \  \ \ \  \/_/\_\/_       
             \ \_\    \ \_\ \_\  \ \_____\  \ \_____\  \ \_\\"\_\  \ \_\   /\_\/\_\      
              \/_/     \/_/\/_/   \/_____/   \/_____/   \/_/ \/_/   \/_/   \/_/\/_/      
                                                                                         
*/


contract ImmortalPhoenix is ERC721EnumerableCheap, Ownable {

    mapping(uint256 => Phoenix) tokenIdToPhoenix;

    uint[6] levelUpCosts;

    bool public publicMint;

    uint16 public maxSupply = 5001;

    uint8 public totalLevelSix;

    uint8 public maxLevelSix = 200;

    //Price in wei = 0.055 eth
    uint public price = 0.055 ether;

    uint public nameCost = 80 ether;

    uint public resurrectCost = 100 ether;

    IMetadataHandler metadataHandler;

    mapping(address => uint) addressToLevels;

    IBlazeToken blazeToken;

    uint[] roleMaxMint;

    bytes32[] roots;

    PaymentStruct[] payments;

    mapping(address => uint) numMinted;

    mapping(string => bool) nameTaken;

    ResurrectionInfo previousResurrection;

    bool allowResurrection;

    uint resurrectionId;

    event LeveledUp(uint id, address indexed userAddress);
    event NameChanged(uint id, address indexed userAddress);

    constructor(address _blazeTokenAddress, address _metadataHandlerAddress, uint[] memory _roleMaxMint, PaymentStruct[] memory _payments) ERC721Cheap("Immortal Phoenix", "Phoenix") {

        levelUpCosts = [10 ether, 20 ether, 30 ether, 40 ether, 50 ether, 60 ether];

        blazeToken = IBlazeToken(_blazeTokenAddress);
        metadataHandler = IMetadataHandler(_metadataHandlerAddress);
        roleMaxMint = _roleMaxMint;

        for(uint i = 0; i < _payments.length; i++) {
            payments.push(_payments[i]);
        }
        
    }

    /**
     _      _      _      _    _      _____    _     _     _      _____    
    /\ "-./  \   /\ \   /\ "-.\ \   /\__  _\ /\ \   /\ "-.\ \   /\  ___\   
    \ \ \-./\ \  \ \ \  \ \ \-.  \  \/_/\ \/ \ \ \  \ \ \-.  \  \ \ \__ \  
     \ \_\ \ \_\  \ \_\  \ \_\\"\_\    \ \_\  \ \_\  \ \_\\"\_\  \ \_____\ 
      \/_/  \/_/   \/_/   \/_/ \/_/     \/_/   \/_/   \/_/ \/_/   \/_____/

    */

    /**
     * @dev Generates a random number that will be used by the metadata manager to generate the image.
     * @param _tokenId The token id used to generated the hash.
     * @param _address The address used to generate the hash.
     */
    function generateTraits(
        uint _tokenId,
        address _address
    ) internal view returns (uint128) {

        //TODO: turn back to internal

        return uint128(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                _tokenId,
                                _address
                                
                            )
                        )   
                    )
                );

    }

    /**
     * @dev internal function that mints a phoenix, generates its hash and base values, can be called by public or whistlist external functions.
     * @param thisTokenId is the token id of the soon to be minted phoenix
     * @param sender is the address to mint to
     */
    function mint(uint256 thisTokenId, address sender) internal {

        tokenIdToPhoenix[thisTokenId] = Phoenix(
            generateTraits(thisTokenId, sender),
            1,
            string("")
        );

        _mint(sender, thisTokenId);

    }

    /**
     * @dev public mint function, mints the requested number of phoenixs.
     * @param _amountToMint the number of phoenixs to mint in this transaction, limited to a max of 5
     */
    function mintPhoenix(uint _amountToMint) external payable {

        require(publicMint == true, "Minting isnt public at the moment");

        require(_amountToMint > 0, "Enter a valid amount to mint");

        require(_amountToMint < 6, "Attempting to mint too many");

        require(price * _amountToMint == msg.value, "Incorrect ETH value");

        uint tokenId = totalSupply();
        require(tokenId + _amountToMint < maxSupply, "All tokens already minted");

        address sender = _msgSender();

        for(uint i = 0; i < _amountToMint; i++) {
        
            mint(tokenId + i, sender);

        }

        blazeToken.updateTokens(sender);
        
        addressToLevels[sender] += _amountToMint;   
    }

    /**
     * @dev Mints new Phoenix if the address is on the whitelist.
     * @param _merkleProof the proof required to verify if this address is on the whilelist
     * @param _amountToMint is the number of phoenixs requested to mint, limited based on the whitelist the user is on
     * @param _merkleIndex is the index of the whitelist the user has submitted a proof for
     */
    function mintPhoenixWhiteList(bytes32[] calldata _merkleProof, uint _amountToMint, uint _merkleIndex) external payable {

        require(_amountToMint > 0, "Enter a valid amount to mint");

        uint thisTokenId = totalSupply();

        require(price * _amountToMint == msg.value, "Incorrect ETH value");
        require(thisTokenId + _amountToMint < maxSupply, "All tokens already minted");

        address sender = _msgSender();

        bytes32 leaf = keccak256(abi.encodePacked(sender));

        require(MerkleProof.verify(_merkleProof, roots[_merkleIndex], leaf), "Invalid proof");

        require(numMinted[sender] + _amountToMint <= roleMaxMint[_merkleIndex], "Trying to mint more than allowed");

        numMinted[sender] += _amountToMint;

        for(uint i = 0; i < _amountToMint; i++) {
            mint(thisTokenId + i, sender);
        }

        blazeToken.updateTokens(sender);

        addressToLevels[sender] += _amountToMint;
        
    }

    /** 
         __  __     ______   __     __         __     ______   __  __    
        /\ \/\ \   /\__  _\ /\ \   /\ \       /\ \   /\__  _\ /\ \_\ \   
        \ \ \_\ \  \/_/\ \/ \ \ \  \ \ \____  \ \ \  \/_/\ \/ \ \____ \  
         \ \_____\    \ \_\  \ \_\  \ \_____\  \ \_\    \ \_\  \/\_____\ 
          \/_____/     \/_/   \/_/   \/_____/   \/_/     \/_/   \/_____/                                                          

    */

    /**
    * @dev Levels up the chosen phoenix by the selected levels at the cost of blaze tokens
    * @param _tokenId is the id of the phoenix to level up
    * @param _levels is the number of levels to level up by
    */
    function levelUp(uint _tokenId, uint8 _levels) external {

        address sender = _msgSender();

        require(sender == ownerOf(_tokenId), "Not owner of token");

        uint8 currentLevel = tokenIdToPhoenix[_tokenId].level;

        uint8 level = currentLevel + _levels;

        if(level >= 6) {

            uint specialId = metadataHandler.getSpecialToken(0, _tokenId);

            if(specialId == 0) {
                require(level  <= 6, "Cant level up to seven unless unique");
                require(totalLevelSix < maxLevelSix, "Already max amount of levels 6 phoenixs created");
                totalLevelSix++;
            } else {
                require(level <= 7, "Not even uniques can level past 7");
            }

        }

        uint cost;
        for(uint8 i = currentLevel - 1; i < level; i++) {

            cost += levelUpCosts[i];

        }
        
        blazeToken.updateTokens(sender);

        blazeToken.burn(sender, cost);

        addressToLevels[sender] += uint(_levels);
        tokenIdToPhoenix[_tokenId].level = level;

        emit LeveledUp(_tokenId, sender);

    }

    /**
    * @dev Makes sure the name is valid with the constraints set
    * @param _name is the desired name to be verified
    * @notice credits to cyberkongz
    */ 
    function validateName(string memory _name) public pure returns (bool){

        bytes memory byteString = bytes(_name);
        
        if(byteString.length == 0) return false;
        
        if(byteString.length >= 20) return false;

        for(uint i; i < byteString.length; i++){

            bytes1 character = byteString[i];

            //limit the name to only have numbers, letters, or spaces
            if(
                !(character >= 0x30 && character <= 0x39) &&
                !(character >= 0x41 && character <= 0x5A) &&
                !(character >= 0x61 && character <= 0x7A) &&
                !(character == 0x20)
            )
                return false;
        }

        return true;
    }

    /**
    * @dev Changes the name of the selected phoenix, at the cost of blaze tokens
    * @param _name is the desired name to change the phoenix to
    * @param _tokenId is the id of the token whos name will be changed
    */
    function changeName(string memory _name, uint _tokenId) external {

        require(_msgSender() == ownerOf(_tokenId), "Only the owner of this token can change the name");

        require(validateName(_name) == true, "Invalid name");

        require(nameTaken[_name] == false, "Name is already taken");

        string memory currentName = tokenIdToPhoenix[_tokenId].name;

        blazeToken.burn(_msgSender(), nameCost);

        if(bytes(currentName).length == 0) {

            nameTaken[currentName] = false;

        }

        nameTaken[_name] = true;

        tokenIdToPhoenix[_tokenId].name = _name;

        emit NameChanged(_tokenId, _msgSender());

    }

    /**
    * @dev rerolls the traits of a phoenix, consuming blaze to rise anew from the ashes. This process happens with a slight delay to get info from the next resurection to take place
    * @param _tokenId is the id of the phoenix to be reborn
    */
    function resurrect(uint _tokenId) external {

        address sender = _msgSender();

        require(sender == ownerOf(_tokenId), "Only the owner of this token can resurect their phoenix");
        require(allowResurrection == true, "Resurection isn't allowed at this time");

        blazeToken.burn(sender, resurrectCost);

        uint128 hash = generateTraits(_tokenId, sender);

        ResurrectionInfo memory prevRes = previousResurrection;

        if(prevRes.hash != 0) {

            uint128 newHash = uint128(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                prevRes.hash,
                                hash,
                                prevRes.tokenId     
                            )
                        )   
                    )
                );

            Phoenix memory phoenix = tokenIdToPhoenix[prevRes.tokenId];

            phoenix.hash = newHash;

            tokenIdToPhoenix[prevRes.tokenId] = phoenix;

        }

        metadataHandler.resurrect(resurrectionId, _tokenId);

        previousResurrection = ResurrectionInfo(_tokenId, hash);

    }

    /**
         ______     ______     ______     _____    
        /\  == \   /\  ___\   /\  __ \   /\  __-.  
        \ \  __<   \ \  __\   \ \  __ \  \ \ \/\ \ 
         \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \____- 
          \/_/ /_/   \/_____/   \/_/\/_/   \/____/ 
                                           
    */
    
    /**
     * @dev Returns metadata for the token by asking for it from the set metadata manager, which generates the metadata all on chain
     * @param _tokenId is the id of the phoenix requesting its metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId));

        Phoenix memory _phoenix = tokenIdToPhoenix[_tokenId];

        MetadataStruct memory metaDataStruct = MetadataStruct(_tokenId,
                        0,
                            6,
                                "5000 Onchain Immortal Phoenix risen from the ashes onto the Ethereum blockchain ready to take nft land by storm.",
                                    "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwAgMAAAAqbBEUAAAAAXNSR0IArs4c6QAAAAxQTFRFAAAAuo+P+vr6/f3+BbtU0AAAAMNJREFUKM+t0b0NwyAQBeBHFBrXQezgKRiBgpOriFHwKC4t78MoqZM7QDaW8tPkWUJ8MveEbDy74A94TDtyzAcoBsvMUeDv3mZKJK/hyJlgyFsBCDoocgUqADcYZwq8gjw6MbRXDhwVBa4CU4UvMAKoawEPMVp4CEemhnHlxTZsW2ko+8syzNxQMcyXReoqAIZ6A3xBVyB9HUZ0x9Zy02OEb9owy2p/oeYjXDfD336HJpr2QyblDuX/tOgTUgd1QuwAxgtmj7BFtSVEWwAAAABJRU5ErkJggg=="
                                        );

        

        string memory metaData = metadataHandler.tokenURI(
            _phoenix,
                metaDataStruct
                    );

        return metaData;

        
    }

    function getLastResurrection() public view returns (ResurrectionInfo memory) {

        return previousResurrection;

    }

    /**
    * @dev returns the total levels of phoenixs a user has, used by the blaze contract to calculate token generation rate
    * @param _userAddress is the address in question
    */
    function getTotalLevels(address _userAddress) external view returns(uint) {

        return addressToLevels[_userAddress];

    }

    /**
     * @dev Returns the info about a given phoenix token
     * @param _tokenId of desired phoenix
    */
    function getPhoenixFromId(uint _tokenId) public view returns(Phoenix memory) {
        require(_tokenId < totalSupply(), "Token id outside range");
        return tokenIdToPhoenix[_tokenId];
    }

    /**
     * @dev Returns an array of token ids the address owns, mainly for frontend use, and helps with limitations set by storing less info
     * @param _addr address of interest
    */
    function getPhoenixesOfAddress(address _addr) public view returns(uint[] memory) {

        uint[] memory tempArray;

        if(addressToLevels[_addr] == 0) {
            return tempArray;
        }

        tempArray = new uint[](addressToLevels[_addr]);
        uint total = 0;
        for(uint i = 0; i < totalSupply(); i++) {
            if(_owners[i] == _addr) {
                tempArray[total] = i;
                total++;
            }
        }

        uint[] memory finalArray = new uint[](total);
        for(uint i = 0; i < total; i++) {
            finalArray[i] = tempArray[i];
        }
        
        return finalArray;

    }


    /**
         ______     __     __     __   __     ______     ______    
        /\  __ \   /\ \  _ \ \   /\ "-.\ \   /\  ___\   /\  == \   
        \ \ \/\ \  \ \ \/ ".\ \  \ \ \-.  \  \ \  __\   \ \  __<   
         \ \_____\  \ \__/".~\_\  \ \_\\"\_\  \ \_____\  \ \_\ \_\ 
          \/_____/   \/_/   \/_/   \/_/ \/_/   \/_____/   \/_/ /_/ 
                                                           
    */

    /**
    * @dev Sets the blaze token contract
    * @param _tokenAddress address of the blaze token
    */
    function setBlazeToken(address _tokenAddress) external onlyOwner {
        blazeToken = IBlazeToken(_tokenAddress);
    }

    /**
    * @dev sets the contract interface to interact with the metadata handler, which generates the phoenixs metadata on chain
    * @param _metaAddress is the address of the metadata handler
    */
    function setMetadataHandler(address _metaAddress) external onlyOwner {
        metadataHandler = IMetadataHandler(_metaAddress);
    }


    /**
    * @dev mint function called once after deploying the contract to reward the teams hard work, 2 will be minted for each team member, to a total of 8
    * @param addresses is an array of addresses of the devs that can mint
    * @param numEach is the number of phoenixs minted per address
    */
    function devMint(address[] calldata addresses, uint numEach) external onlyOwner {

        uint supply = totalSupply();

        require(supply + (addresses.length * numEach) <= 8, "Trying to mint more than you should");

        for(uint i = 0; i < addresses.length; i++) {

            address addr = addresses[i];

            for(uint j = 0; j < numEach; j++) {
                mint(supply, addr);
                supply++;
            }

            addressToLevels[addr] += numEach;

        }

    }

     /**
     * @dev Withdraw ether from this contract to the team for the agreed amounts, only callable by the owner
     */
    function withdraw() external onlyOwner {

        address thisAddress = address(this);

        require(thisAddress.balance > 0, "there is no balance in the address");
        require(payments.length > 0, "havent set the payments");

        for(uint i = 0; i < payments.length; i++) {

            if(thisAddress.balance == 0) {
                return;
            }

            PaymentStruct memory payment = payments[i];

            uint paymentLeft = payment.owed - payment.payed;

            if(paymentLeft > 0) {

                uint amountToPay;

                if(thisAddress.balance >= paymentLeft) {

                    amountToPay = paymentLeft;


                } else {
                    amountToPay = thisAddress.balance;
                }

                payment.payed += amountToPay;
                payments[i].payed = payment.payed;

                payable(payment.membersAddress).transfer(amountToPay);

            } 

        }

        if(thisAddress.balance > 0) {

            payable(payments[payments.length - 1].membersAddress).transfer(thisAddress.balance);
        }
        
    }

    /**
    * @dev sets the root of the merkle tree, used to verify whitelist addresses
    * @param _root the root of the merkle tree
    */
    function setMerkleRoots(bytes32[] calldata _root) external onlyOwner {
        roots = _root;
    }

    /**
    * @dev Lowers the max supply in case minting doesnt sell out
    * @param _newMaxSupply the new, and lower max supply
    */ 
    function lowerMaxSupply(uint _newMaxSupply) external onlyOwner {
        require(_newMaxSupply >= totalSupply());
        require(_newMaxSupply < maxSupply);

        maxSupply = uint16(_newMaxSupply);
    }

    /**
    * @dev toggles the ability for anyone to mint to whitelist only, of vice versa
    */
    function togglePublicMint() external onlyOwner {
        publicMint = !publicMint;
    }

    // @notice Will receive any eth sent to the contract
    receive() external payable {

    }

    /**
    * @dev Reverts the name back to the base initial name, will be used by the team to revert offensive names
    * @param _tokenId token id to be reverted
    */
    function revertName(uint _tokenId) external onlyOwner {

        tokenIdToPhoenix[_tokenId].name = ""; 

    }

    /**
    * @dev Toggle the ability to resurect phoenix tokens and reroll traits
    */
    function toggleResurrection() public onlyOwner {
        allowResurrection = !allowResurrection;
    }

    /**
    * @dev Give out mythics to phoenixs that have resurrected recently
    * @param _numMythics is the number of mythics that will be given out
    */
    function rewardMythics(uint _numMythics) external onlyOwner {

        require(allowResurrection == false, "Need to have resurrection paused mythics are rewarded");
        metadataHandler.rewardMythics(resurrectionId, _numMythics);

        toggleResurrection();

    }

    /**
    * @dev Allows the owner to raise the max level six cap, but only by 100 at a time
    * @param _newMax is the new level six cap to be set
    */
    function raiseMaxLevelSix(uint8 _newMax) external onlyOwner {

        require(_newMax > maxLevelSix, "Need to set the new max to be larger");

        require(_newMax - maxLevelSix <= 100, "Can't raise it by more than 100 at a time");

        maxLevelSix = _newMax;

    }

    function setRessurectionId(uint _id) external onlyOwner {

        resurrectionId = _id;

    } 

    function setBlazeCosts(uint _nameCost, uint _resurrectCost) external onlyOwner {

        nameCost = _nameCost;
        resurrectCost = _resurrectCost;
    }

    /**
         ______     __   __   ______     ______     ______     __     _____     ______    
        /\  __ \   /\ \ / /  /\  ___\   /\  == \   /\  == \   /\ \   /\  __-.  /\  ___\   
        \ \ \/\ \  \ \ \'/   \ \  __\   \ \  __<   \ \  __<   \ \ \  \ \ \/\ \ \ \  __\   
         \ \_____\  \ \__|    \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \____-  \ \_____\ 
          \/_____/   \/_/      \/_____/   \/_/ /_/   \/_/ /_/   \/_/   \/____/   \/_____/ 
                                                                                  
    */

    /**
    * @dev Override the transfer function to update the blaze token contract
    */
    function transferFrom(address from, address to, uint256 tokenId) public override {

        blazeToken.updateTransfer(from, to);

        uint level = uint(tokenIdToPhoenix[tokenId].level);

        addressToLevels[from] -= level;
        addressToLevels[to] += level;

        ERC721Cheap.transferFrom(from, to, tokenId);

    }

    /**
    * @dev Override the transfer function to update the blaze token contract
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {


        blazeToken.updateTransfer(from, to);

        uint level = uint(tokenIdToPhoenix[tokenId].level);

        addressToLevels[from] -= level;
        addressToLevels[to] += level;

        ERC721Cheap.safeTransferFrom(from, to, tokenId, _data);

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721Cheap.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 * Altered to remove all storage variables to make minting and transfers cheaper, at the cost of more time to query
 * 
 */
abstract contract ERC721EnumerableCheap is ERC721Cheap, IERC721Enumerable {
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Cheap) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * Altered to loop through tokens rather thsn grab from stored map
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {

        uint ownerIndex;
        uint supply = totalSupply();
       
        for(uint i = 0; i < supply; i++) {

            if(_owners[i] == owner) {
                if(ownerIndex == index) {
                    return i;
                }

                ownerIndex++;
            }

        }

        //Need to catch this case additionally, can't call revert with a message so ill make sure it catches
        require(true == false, "ERC721Enumerable: owner index out of bounds");
        
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     * Altered to use the ERC721Cheap _owners array instead of _allTokens
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * Altered to use ERC721Cheap _owners array instead of _allTokens
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableCheap.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, _owners 
 *
 * Altered _owners to an array and removed _balances, to allow for a cheaper {Erc721Enumerable} implementation at the cost of time
 * to query ownership of tokens
 */
contract ERC721Cheap is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Array of token ID to owner address, set to internal to give {ERC721EnumerableCheap} access
    address[] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     * altered to remove the need to set a balances map
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint balance;
        uint totalSupply = _owners.length;

        for(uint i = 0; i < totalSupply; i++) {
            if(owner == _owners[i]) balance++;
        }
        return balance;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        require(tokenId < _owners.length, "token does now exist");
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Cheap.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /*
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */

     
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     *
     * Altered to check from the _owners array instead of map 
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length;
        //return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Cheap.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     *
     * Altered to add to _owners array instead of a map
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _owners.push(to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     * 
     * Altered to set the address of the token to the burn address instead of removing it
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Cheap.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     *
     * Altered to not use the balances map
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Cheap.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Cheap.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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