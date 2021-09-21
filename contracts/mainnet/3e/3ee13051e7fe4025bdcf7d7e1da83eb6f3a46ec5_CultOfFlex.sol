// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";
import "./ERC721Enumerable.sol";

interface ArbitraryOwnerOf {
    function ownerOf(uint256) external view returns (address);
}

interface punkOwnerOf {
    function punkIndexToAddress(uint256) external view returns (address);
}

contract CultOfFlex is ERC721URIStorage, PaymentSplitter, Ownable, ERC721Enumerable {
    //******************************************************
    //CRITICAL CONTRACT PARAMETERS
    //******************************************************
    using SafeMath for uint256;
    uint256 _totalSupply = 0;
    uint256 _baseMintPrice = 0.03 ether;
    uint256 _estimatedBurnPrice = 0.01 ether;
    uint256 _estimatedTransferPrice = 0.01 ether;
    uint256 _relicMultiplier = 3;
    address _thisContractAddress;
    uint _maxStringLength = 256;
    
    //Special considerations for punks
    address punksAddress = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    
    //******************************************************
    //ROLES AND FEATURES DEFINITIONS
    //******************************************************
    
    //Allowable Contracts
    mapping(address => bool) whitelistedContracts;
    //Origin Minters
    mapping(address => bool) originMinters;
    //Relic Minters
    mapping(address => bool) relicMinters;
    //Integrated Contracts
    mapping(address => bool) integratedContracts;
    //Addresses for accounts which can mint for free + gas
    mapping(address => uint8) freeMints;
    
    //Parameters relating to attachment functionality
    mapping(uint256 => uint8) transfersLeft;
    
    //******************************************************
    //REGISTRATION STRUCT
    //******************************************************
    struct registration {
        address NFTContract;
        uint NFTID;
        string personalIdentifier;
    }
    
    //******************************************************
    //IMAGE URI STORAGE
    //******************************************************
   mapping(uint256 => bool) relicStatus;
   mapping(uint256 => string) ogRelics;
   mapping(uint256 => string) userRelics;
    
    //******************************************************
    //CONTRACT CONSTRUCTOR
    //******************************************************

    constructor(
        address[] memory approvedContracts,
        address[] memory payees,
        uint256[] memory paymentShares
    ) ERC721("Cult of Flex", "RLIC") PaymentSplitter(payees, paymentShares) {
        for(uint i=0; i < approvedContracts.length; i++) {
            whitelistedContracts[approvedContracts[i]];
        }
    }
    
    //******************************************************
    //OVERRIDES TO HANDLE CONFLICTS BETWEEN IMPORTS
    //******************************************************
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, amount);
    }
    
    function _burn(uint256 tokenID) internal virtual override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(tokenID);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory output;
        bytes memory currentURI = bytes(ERC721URIStorage.tokenURI(tokenId));
        registration memory currentRegistration;
        //Registered owner of an NFT
        address registeredOwner;
        //Current owner of that NFT
        address currentOwner;
        
        registeredOwner = ownerOf(tokenId);
        (currentRegistration.NFTContract, currentRegistration.NFTID, currentRegistration.personalIdentifier) = abi.decode(currentURI, (address, uint256, string));
        currentOwner = ArbitraryOwnerOf(currentRegistration.NFTContract).ownerOf(currentRegistration.NFTID);
        
        if(currentOwner != registeredOwner){
            output = string(_computeModifiedURI(tokenId, ''));
        } else {
            output = string(currentURI);
        }
        
        if(bytes(output).length != 0) {
            return output;
        }
        
        return ERC721URIStorage.tokenURI(tokenId);
    }
    
    //******************************************************
    //OWNER ONLY FUNCTIONS TO MANAGE CRITICAL PARAMETERS
    //******************************************************
    
    function whitelistIntegratedContract(address newIC, bool status) public onlyOwner {
        integratedContracts[newIC]=status;
    }
    
    function whitelistContract(address newContract, bool status) public onlyOwner {
        whitelistedContracts[newContract]=status;
    }
    
    function createOriginMinter(address newMinter, bool status) public onlyOwner {
        originMinters[newMinter]=status;
    }
    
    function createRelicMinter(address newMinter, bool status) public onlyOwner {
        relicMinters[newMinter]=status;
    }
    
    function issueMintPass(address minter, uint8 numberOfPasses) public onlyOwner {
        freeMints[minter] = numberOfPasses;
    }
    
    function updateThisContractAddress(address contractAddress) public onlyOwner {
        _thisContractAddress = contractAddress;
    }
    
    function setBaseMintPrice(uint256 newPrice) public onlyOwner {
        _baseMintPrice = newPrice;
    }
    
    function setTransferPrice(uint256 newPrice) public onlyOwner {
        _estimatedTransferPrice = newPrice;
    }
    
    function setBurnPrice(uint256 newPrice) public onlyOwner {
        _estimatedBurnPrice = newPrice;
    }
    
    function setRelicMultiplier(uint256 newMult) public onlyOwner {
        _relicMultiplier = newMult;
    }
    
    //******************************************************
    //FUNCTIONS FOR MANAGING METADATA AND TRANSFERS
    //******************************************************
    
    function _burnWhenInvalid(uint256 idToBurn) internal {
        _burn(idToBurn);
    }
    
    function _computeURI(address targetContract, uint256 targetID, string memory personalIdentifier) internal pure returns (bytes memory output) {
        bytes memory abiURI = abi.encode(targetContract, targetID, personalIdentifier);
        output = abiURI;
    }
    
    function _computeModifiedURI(uint256 tokenID, string memory newPersonalId) internal view returns (bytes memory output) {
        bytes memory currentURI = bytes(tokenURI(tokenID));
        registration memory workingRegistration;
        
        (workingRegistration.NFTContract, workingRegistration.NFTID, workingRegistration.personalIdentifier) = abi.decode(currentURI, (address, uint256, string));
        workingRegistration.personalIdentifier = newPersonalId;
        output = _computeURI(workingRegistration.NFTContract, workingRegistration.NFTID, workingRegistration.personalIdentifier);
        return output;
    }
    
    function _modifyURI(uint256 tokenID, string memory newPersonalId) internal {
        string memory newURI = string(_computeModifiedURI(tokenID, newPersonalId));
        _setTokenURI(tokenID, newURI);
    }
    
    function _sanitizeURI(uint256 tokenID) internal {
        _modifyURI(tokenID, "");
    }
    
    function _attachedTransfer(uint256 tokenID, address oldOwner, address newOwner) internal {
        if(transfersLeft[tokenID] > 0) {
            //Will need to update to use the contract override transferFrom function
            transferFrom(oldOwner, newOwner, tokenID);
            _sanitizeURI(tokenID);
            transfersLeft[tokenID] -= 1;
        } else {
            _burnWhenInvalid(tokenID);
        }
    }
    
    function uriHousekeeping(uint256 tokenID) public onlyOwner returns (string memory output) {
        bytes memory currentURI = bytes(ERC721URIStorage.tokenURI(tokenID));
        registration memory currentRegistration;
        //Registered owner of an NFT
        address registeredOwner;
        //Current owner of that NFT
        address currentOwner;
        
        registeredOwner = ownerOf(tokenID);
        (currentRegistration.NFTContract, currentRegistration.NFTID, currentRegistration.personalIdentifier) = abi.decode(currentURI, (address, uint256, string));
        currentOwner = ArbitraryOwnerOf(currentRegistration.NFTContract).ownerOf(currentRegistration.NFTID);
        
        if(currentOwner != registeredOwner){
            _attachedTransfer(tokenID, registeredOwner, currentOwner);
            output = ERC721URIStorage.tokenURI(tokenID);
        } else {
            output = string(currentURI);
        }
        
        return output;
    }
    
    function getOgRelic(uint256 tokenID) public view returns (string memory output) {
        return ogRelics[tokenID];
    }
    
    function getUserRelics(uint256 tokenID) public view returns (string memory output) {
        return userRelics[tokenID];
    }
    
    //Modifier checks to be sure that users cannot change other users' metadata
    modifier validateNativeOwner(uint256 targetID) {
        address owner = ownerOf(targetID);
        require(
            msg.sender == owner,
            "It appears that you have tried to change the URI of a token you do not own."
        );
        _;
    }

    function userUpdateURI(uint256 tokenID, string memory personalIdentifier) 
    public
    validateNativeOwner(tokenID)
    {
        _modifyURI(tokenID, personalIdentifier);
    }
    
    //******************************************************
    //VIEWS FOR GETTING PRICE INFORMATION
    //******************************************************

    function baseMintPrice() public view returns (uint256) {
        return _baseMintPrice;
    }

    function mintPrice(uint256 numberOfTransfers) public view returns (uint256) {
        if (numberOfTransfers < 0) {
            numberOfTransfers = 0;
        }
        uint256 transferFees = _estimatedTransferPrice.mul(numberOfTransfers);
        uint256 totalPrice = _baseMintPrice + transferFees + _estimatedBurnPrice;
        return totalPrice;
    }
    
    function relicPrice() public view returns (uint256) {
        uint baseForCalculation = mintPrice(1);
        return baseForCalculation.mul(_relicMultiplier);
    }
    
    //******************************************************
    //MODIFIERS FOR USE WITH MINT FUNCTIONS
    //******************************************************
    modifier checkStringLength(string memory stringToCheck) {
        require(
            bytes(stringToCheck).length <= _maxStringLength,
            "Attempted to write a string longer than 256 bytes"
        );
        _;
    }
    
    modifier validateCollection(address contractAddress) {
        require(
            whitelistedContracts[contractAddress] == true,
            "The given contract address is not in our approved list."
        );
        _;
    }
    
    function getOwnerAddress(address contractAddress, uint256 targetID) public view returns (address ownerAddress) {
        address trueOwner;
        if (contractAddress != punksAddress) {
            trueOwner = ArbitraryOwnerOf(contractAddress).ownerOf(targetID);
        } else {
            trueOwner = punkOwnerOf(contractAddress).punkIndexToAddress(targetID);
        }
        return trueOwner;
    }
    
    modifier validateOwnership(address contractAddress, uint256 targetID) {
        address trueOwner = getOwnerAddress(contractAddress, targetID);
        
        require(
            msg.sender == trueOwner,
            "Owner-Of inquiry on token did not match the minting address!"
        );
        _;
    }

    modifier validatePurchasePrice(uint256 numberOfTransfers) {
        require(
            mintPrice(numberOfTransfers) == msg.value,
            "Ether value sent is not correct"
        );
        _;
    }
    
    modifier validateOriginMinter(address sender) {
        require(
            originMinters[sender] == true,
            "You are not an authorized minter of Origin tokens"
        );
        _;
    }
    
    modifier validateRelicMinter(address sender) {
        require(
            relicMinters[sender] == true,
            "You are not an authorized minter of Relic tokens"
        );
        _;
    }
    
    modifier validateRelicMintPrice() {
        require(
            relicPrice() == msg.value,
            "Insufficient payment."
        );
        _;
    }
    
    modifier validateRelicStatus(uint256 idToCheck) {
        require(
            relicStatus[idToCheck] == true,
            "The item you have attempted to interact with is not a relic"
        );
        _;
    }
    
    //******************************************************
    //MINT FUNCTIONS FOR DIFFERENT USE CASES AND SCENARIOS
    //******************************************************

    function _mintToken(address to, bytes memory pID) internal {
        _totalSupply += 1;
        _safeMint(to, _totalSupply);
        _setTokenURI(_totalSupply, string(pID));
        approve(_thisContractAddress, _totalSupply);
    }
    
    function publicAccessMint(address targetContract, uint256 targetID, string memory pID, uint256 numberOfTransfers, address endUser)
        public
        payable
        validateCollection(targetContract)
        validateOwnership(targetContract, targetID)
        validatePurchasePrice(numberOfTransfers)
        checkStringLength(pID)
    {
        bytes memory uriForMint = _computeURI(targetContract, targetID, pID);
        address destinationAddress;
        
        if (integratedContracts[msg.sender] != true) {
            destinationAddress = msg.sender;
        } else {
            destinationAddress = endUser;
        }
        
        _mintToken(destinationAddress, uriForMint);
    }
    
    function originMint()
        public
        validateOriginMinter(msg.sender)
    {
        _totalSupply += 1;
        _safeMint(msg.sender, _totalSupply);
        string memory nameForToken = "";
        bytes memory uriForMint = _computeURI(_thisContractAddress, _totalSupply, nameForToken);
        _setTokenURI(_totalSupply, string(uriForMint));
        approve(_thisContractAddress, _totalSupply);
        relicStatus[_totalSupply]=true;
    }
    
    function relicMint()
        public
        payable
        validateRelicMinter(msg.sender)
        validateRelicMintPrice()
    {
        _totalSupply += 1;
        _safeMint(msg.sender, _totalSupply);
        string memory nameForToken = "";
        bytes memory uriForMint = _computeURI(_thisContractAddress, _totalSupply, nameForToken);
        _setTokenURI(_totalSupply, string(uriForMint));
        approve(_thisContractAddress, _totalSupply);
        relicStatus[_totalSupply]=true;
    }
    
    function setRelicImage(uint256 tokenID, string memory imgURI)
        public
        validateNativeOwner(tokenID)
        validateRelicStatus(tokenID)
        checkStringLength(imgURI)
        {
            if(bytes(ogRelics[tokenID]).length > 0) {
                userRelics[tokenID] = imgURI;
            } else {
                ogRelics[tokenID] = imgURI;
            }
        }
    
    //Complimentary Tokens will not have transfers available.
    function mintWithPass(address targetContract, uint256 targetID, string memory pID)
        public
        validateCollection(targetContract)
        validateOwnership(targetContract, targetID)
        checkStringLength(pID)
    {
        if(freeMints[msg.sender] > 0) {
            bytes memory uriForMint = _computeURI(targetContract, targetID, pID);
            _mintToken(msg.sender, uriForMint);
            freeMints[msg.sender] -= 1;
        }
    }
}