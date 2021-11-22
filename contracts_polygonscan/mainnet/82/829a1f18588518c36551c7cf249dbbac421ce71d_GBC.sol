// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./IERC20.sol";

contract GBC is
    Context,
    Ownable,
    ERC721Enumerable,
    ERC721Burnable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    string private _contractURI;
    uint256 public max = 10000;
    uint256 public maxMintPerTx = 10;

    bool public publicSaleStarted = false;
    bool public wlMintStarted = false;

    bool public tokenURIFrozen = false;
    uint256 public cost = 0.03 ether;

    address public wlSigner;
    mapping(address => bool) blacklist;


    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _tokenIdTracker.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function adminMint(uint256 _mintAmount) public onlyOwner{
        for (uint256 i = 1; i <= _mintAmount; i++) {
            require(_tokenIdTracker.current() <= max, "Transaction exceeds max mint amount");
            _mint(_msgSender(), _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }
    function whitelistMint(bytes memory sig) public {
        require(wlMintStarted == true, "WL Mint not started yet");
        require(checkSignature(sig, _msgSender()) == true, "Signature not valid");
        require(blacklist[_msgSender()] == false, "This address was already used");
        require(_tokenIdTracker.current() <= max, "Transaction exceeds max mint amount");
        _mint(_msgSender(), _tokenIdTracker.current());
        _tokenIdTracker.increment();
        blacklist[_msgSender()] = true;
    }
    function mint(uint256 _mintAmount) public payable {
        require(publicSaleStarted == true, "Public Sale not started yet");
        require(_mintAmount <= maxMintPerTx, "Exceeds max amount per mint");
        require(msg.value >= cost * _mintAmount, "Not enough ether provided");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            require(_tokenIdTracker.current() <= max, "Transaction exceeds max mint amount");
            _mint(_msgSender(), _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }
    function withdraw(address token, uint256 amount) public onlyOwner {
        if(token == address(0)) { 
            payable(_msgSender()).transfer(amount);
        } else {
            IERC20(token).transfer(_msgSender(), amount);
        }
    }
    
    function setContractURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        _contractURI = uri;
    }
    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        _baseTokenURI = uri;
    }
    
    function setWLSigner(address signer) public onlyOwner {
        wlSigner = signer;
    }

    function setCost(uint256 price) public onlyOwner {
        cost = price;
    }
    
    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }
    
    function startPublicSale() public onlyOwner {
        publicSaleStarted = true;
    }
    function startWLMint() public onlyOwner {
        wlMintStarted = true;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    function isBlacklisted(address _address) public view returns (bool) {
        return blacklist[_address];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function checkSignature(bytes memory sig, address sender) private view returns (bool){
        bytes32 hash = keccak256(abi.encodePacked(address(this), sender));
        address signer = recover(hash, sig);
        return(wlSigner == signer);
    }

    function recover(bytes32 hash, bytes memory sig) private pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
         }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
    
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
    
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(prefixedHash, v, r, s);
        }
    }
}