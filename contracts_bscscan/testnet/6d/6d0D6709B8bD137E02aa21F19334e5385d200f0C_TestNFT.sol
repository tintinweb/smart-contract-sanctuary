// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";



contract TestNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Address for address;

    uint256 private _currentTokenId = 0;

    string private _uri;

    uint256 public _price;

    address private ERC20Contract;

    // Mapping from token ID to token category
    mapping(uint256 => uint256) private _categories;

    // Mapping set ids to tokens list
    mapping(uint256 => uint256[]) private _sets;


    event SetCreated(address indexed wallet, uint256 _tokenId);

   constructor(string memory _name, string memory _symbol, address cOwner, string memory uri_) Ownable(cOwner) ERC721(_name, _symbol) {
        _uri = uri_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, tokenId.toString())) : "";
    }


    function setBaseURI(string memory _newuri) public onlyOwner {
        _uri = _newuri;

    }

    function setERC20Contract(address _account) public onlyOwner {
        ERC20Contract = _account;
    }


    function setMintPrice(uint256 _newprice) public onlyOwner {
        _price = _newprice;
    }


    function withdrawOwner() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }


    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId + 1;
    }


    function _incrementTokenId() private {
        _currentTokenId++;
    }


    function create(uint256 _category) public payable {
        if (_price > 0) {
            require(msg.value >= _price, "Insufficient BNB to mint token");
            uint256 change = msg.value - _price;
            if (change > 0) {
                payable(_msgSender()).transfer(change);
            }
        }
        uint256 newTokenId = _getNextTokenId();
        _safeMint(_msgSender(), newTokenId);
        _categories[newTokenId] = _category;
        _incrementTokenId();


    }


    function burn(uint256 tokenId) public  {
        require(ownerOf(tokenId) == _msgSender(), "Caller is not an owner of token");
        require(_exists(tokenId), "Token doesn't exist");
        _burn(tokenId);
        delete _categories[tokenId];
    }


    function createFromERC20(address _sender, uint256 _category) public returns (uint256) {
        require(_msgSender() == ERC20Contract, "Caller is not authorized to use this function");
        require(_sender != address(0), "Cannot mint to zero address");
        uint256 newTokenId = _getNextTokenId();
        _safeMint(_sender, newTokenId);
        _categories[newTokenId] = _category;
        _incrementTokenId();
        return newTokenId;
    }


    function getAllTokensByOwner(address account) public view returns (uint256[] memory) {
        uint256 length = balanceOf(account);
        uint256[] memory result = new uint256[](length);
        for (uint i = 0; i < length; i++)
            result[i] = tokenOfOwnerByIndex(account, i);
        return result;
    }


    function createSet(uint256[] memory _tokens) public {
        require(_tokens.length > 1, "Too few tokens to create set");
        for (uint i = 0; i < _tokens.length; i++) {
            transferFrom(_msgSender(), address(this), _tokens[i]);
        }
        uint256 newTokenId = _getNextTokenId();
        _safeMint(_msgSender(), newTokenId);
        _sets[newTokenId] = _tokens;
        _incrementTokenId();
        emit SetCreated(_msgSender(), newTokenId);
    }


    function redeemSet(uint256 _setId) public {
        require(_exists(_setId), "Set doesn't exist");
        require(_sets[_setId].length > 0, "Invalid Set ID");
        _burn(_setId);
        for (uint i = 0; i < _sets[_setId].length; i++) {
            transferFrom(address(this), _msgSender(), _sets[_setId][i]);
        }
        delete _sets[_setId];
    }

}