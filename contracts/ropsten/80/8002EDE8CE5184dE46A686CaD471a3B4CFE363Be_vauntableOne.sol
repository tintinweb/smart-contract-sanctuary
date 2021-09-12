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

contract vauntableOne is ERC721URIStorage, PaymentSplitter, Ownable, ERC721Enumerable {
    //Basic Token Parameters
    using SafeMath for uint256;
    uint256 _totalSupply = 0;
    uint256 _baseMintPrice = 0.05 ether;
    address _thisContractAddress;
    
    //Allowable Contracts
    mapping(address => bool) whitelistedContracts;
    
    //Origin Minters
    mapping(address => bool) originMinters;
    
    //Addresses for accounts which can mint for free + gas
    mapping(address => uint8) freeMints;
    
    //Parameters relating to attachment functionality
    mapping(uint256 => uint8) transfersLeft;
    
    //Parameters relating to URI
    struct registration {
        address NFTContract;
        uint NFTID;
        string personalIdentifier;
    }

    constructor(
        address[] memory payees,
        uint256[] memory paymentShares
    ) ERC721("Quantigram", "QGM") PaymentSplitter(payees, paymentShares) {
    }
    
    //Overrides
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
        return ERC721URIStorage.tokenURI(tokenId);
    }
    
    function whitelistContract(address newContract) public onlyOwner {
        whitelistedContracts[newContract]=true;
    }
    
    function createOriginMinter(address newMinter) public onlyOwner {
        originMinters[newMinter]=true;
    }
    
    function issueMintPass(address minter, uint8 numberOfPasses) public onlyOwner {
        freeMints[minter] = numberOfPasses;
    }
    
    function updateThisContractAddress(address contractAddress) public onlyOwner {
        _thisContractAddress = contractAddress;
    }
    
    //******************************************************
    //INTERNAL FUNCTIONS FOR MANAGING METADATA AND TRANSFERS
    //******************************************************
    
    function _burnWhenInvalid(uint256 idToBurn) internal {
        _burn(idToBurn);
    }
    
    function _computeURI(address targetContract, uint256 targetID, string memory personalIdentifier) internal pure returns (bytes memory output) {
        bytes memory abiURI = abi.encode(targetContract, targetID, personalIdentifier);
        output = abiURI;
    }
    
    function _sanitizeURI(uint256 tokenID) internal {
        bytes memory currentURI = bytes(tokenURI(tokenID));
        registration memory workingRegistration;
        
        (workingRegistration) = abi.decode(currentURI, (registration));
        workingRegistration.personalIdentifier = "";
        
        string memory sanitizedURI = string(abi.encode(workingRegistration));
        _setTokenURI(tokenID, sanitizedURI);
    }
    
    function _modifyURI(uint256 tokenID, string memory newPersonalId) internal {
        bytes memory currentURI = bytes(tokenURI(tokenID));
        registration memory workingRegistration;
        
        (workingRegistration) = abi.decode(currentURI, (registration));
        workingRegistration.personalIdentifier = newPersonalId;
        
        string memory newURI = string(abi.encode(workingRegistration));
        _setTokenURI(tokenID, newURI);
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
    
    function getURI(uint256 tokenID) public returns (string memory output) {
        bytes memory currentURI = bytes(ERC721URIStorage.tokenURI(tokenID));
        registration memory currentRegistration;
        //Registered owner of an NFT
        address registeredOwner;
        //Current owner of that NFT
        address currentOwner;
        
        registeredOwner = ownerOf(tokenID);
        (currentRegistration) = abi.decode(currentURI,(registration));
        currentOwner = ArbitraryOwnerOf(currentRegistration.NFTContract).ownerOf(currentRegistration.NFTID);
        
        if(currentOwner != registeredOwner){
            _attachedTransfer(tokenID, registeredOwner, currentOwner);
            output = ERC721URIStorage.tokenURI(tokenID);
        } else {
            output = string(currentURI);
        }
        
        return output;
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

    function baseMintPrice() public view returns (uint256) {
        return _baseMintPrice;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        require(numberOfTokens > 0, "Cannot mint zero");
        return _baseMintPrice.mul(numberOfTokens);
    }
    
    modifier validateCollection(address contractAddress) {
        require(
            whitelistedContracts[contractAddress] == true,
            "The given contract address is not in our approved list."
        );
        _;
    }
    
    modifier validateOwnership(address contractAddress, uint256 targetID) {
        address trueOwner = ArbitraryOwnerOf(contractAddress).ownerOf(targetID);
        require(
            msg.sender == trueOwner,
            "Owner-Of inquiry on token did not match the minting address!"
        );
        _;
    }

    modifier validatePurchasePrice(uint256 numberOfTokens) {
        require(
            mintPrice(1) == msg.value,
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

    function _mintToken(address to, bytes memory pID) internal {
        _totalSupply += 1;
        _safeMint(to, _totalSupply);
        _setTokenURI(_totalSupply, string(pID));
    }
    
    //WORKING FUNCTION
    function publicAccessMint(address targetContract, uint256 targetID, string memory pID)
        public
        payable
        validateCollection(targetContract)
        validateOwnership(targetContract, targetID)
        validatePurchasePrice(1)
    {
        bytes memory uriForMint = _computeURI(targetContract, targetID, pID);
        _mintToken(msg.sender, uriForMint);
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
    }
    
    //WORKING FUNCTION
    function mintWithPass(address targetContract, uint256 targetID, string memory pID)
        public
        validateCollection(targetContract)
        validateOwnership(targetContract, targetID)
    {
        if(freeMints[msg.sender] > 0) {
            bytes memory uriForMint = _computeURI(targetContract, targetID, pID);
            _mintToken(msg.sender, uriForMint);
            freeMints[msg.sender] -= 1;
        }
    }
}