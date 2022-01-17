// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IERC721.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract WhiteRabbitPFP is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;
    
    // metadata
    bool public metadataLocked = false;
    string public baseURI = "";

    // supply and phases
    uint256 public mintIndex;
    bool public mintPaused = true;

    // price
    uint256 public price = 0.02 ether;

    // limits
    mapping(address => uint256) public contractToNumberOfFreeMints;

    // track minted by token holder
    mapping(address => mapping(uint256 => bool)) public usedToken;

    // events
    event SetFreeMints(address indexed contractAddress, uint256 freeMints);
    event UsedToken(address indexed contractAddress, uint256 indexed tokenId);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection, and by setting supply caps, mint indexes, and reserves
     */
    constructor()
        ERC721("WhiteRabbitPFP", "WRPFP")
    {
    }
    
    /**
     * ------------ METADATA ------------ 
     */

    /**
     * @dev Gets base metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    /**
     * @dev Sets base metadata URI, callable by owner
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        require(metadataLocked == false);
        baseURI = _uri;
    }
    
    /**
     * @dev Lock metadata URI forever, callable by owner
     */
    function lockMetadata() external onlyOwner {
        require(metadataLocked == false);
        metadataLocked = true;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    
    /**
     * ------------ SALE AND PRESALE ------------ 
     */

    /**
     * @dev Pause/unpause sale or presale
     */
    function togglePauseMinting() external onlyOwner {
        mintPaused = !mintPaused;
    }

    /**
     * ------------ CONFIGURATION ------------ 
     */

    /**
     * @dev Set WhiteRabbitX contract addresses
     */
    function setFreeMintsContract(address _addr, uint256 _freeMints) external onlyOwner {
        contractToNumberOfFreeMints[_addr] = _freeMints;
        emit SetFreeMints(_addr, _freeMints);
    }

    /**
     * @dev Set sale parameters
     */
    function setSaleParameters(uint256 _price) external onlyOwner {
        price = _price;
    }
     
    /**
     * ------------ MINTING ------------ 
     */
    
    /**
     * @dev Mints `count` tokens to `to` address; internal
     */
    function mintInternal(address to, uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            _mint(to, mintIndex);
            mintIndex++;
        }
    }
    
    /**
     * @dev Public minting during public sale or presale
     */
    function mint(uint256 countPayable, address[] calldata contractAddresses, uint256[] calldata heldTokenIds) public payable{
        require(!mintPaused, "Minting is currently paused");
        require(contractAddresses.length == heldTokenIds.length, "Bad lengths");

        uint256 freeMints = 0;

        for (uint256 i = 0; i < heldTokenIds.length; i++) {
            require(contractToNumberOfFreeMints[contractAddresses[i]] > 0, "Contract not approved");
            require(IERC721(contractAddresses[i]).ownerOf(heldTokenIds[i]) == msg.sender, "You are not token owner");
            require(!usedToken[contractAddresses[i]][heldTokenIds[i]], "Token already used");

            freeMints += contractToNumberOfFreeMints[contractAddresses[i]];
            usedToken[contractAddresses[i]][heldTokenIds[i]] = true;
            emit UsedToken(contractAddresses[i], heldTokenIds[i]);
        }

        require(msg.value == countPayable * price, "Ether value incorrect");
        
        mintInternal(msg.sender, countPayable + freeMints);
    }

    /**
     * @dev Withdraw ether from this contract, callable by owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}