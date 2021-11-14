/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    Just for experimental, ERC721I (ERC721 0xInuarashi Edition)
    Mainly created as a learning experience and an attempt to try to exercise
    Gas saving practices
*/

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721Receiver {
    function onERC721Received(address operator_, address from_, uint256 tokenId_, bytes calldata data_) external returns (bytes4);
}

contract ERC721IE {
    // init the contract name and symbol with constructor
    string public name; string public symbol;
    string public baseTokenURI; string public baseTokenURI_EXT;
    constructor(string memory name_, string memory symbol_) { name = name_; symbol = symbol_; }

    uint256 public totalSupply; // ERC721I65535
    mapping(uint256 => address) public ownerOf; // ERC721I65535
    mapping(uint256 => address) public getApproved; // ERC721I65535
    mapping(address => mapping(address => bool)) public isApprovedForAll; // ERC721I65535

    mapping(address => uint256[]) public addressToTokens; // ERC721I65535Enumerable
    mapping(address => mapping(uint256 => uint256)) public addressToTokenIndex; // ERC721I65535Enumerable

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // // Embedded ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    // // Embedded OZ Standard
    function _isContract(address address_) internal view returns (bool) {
        uint256 _size; 
        assembly { _size := extcodesize(address_) }
        return _size > 0;
    }
    function _checkOnERC721Received(address from_, address to_, uint256 tokenId_, bytes memory data_) private returns (bool) {
        if (_isContract(to_)) { 
            try IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("NERC721I");
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

    // // internal write functions
    // mint
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(ownerOf[tokenId_] == address(0x0), "TE");

        // ERC721I65535 Starts Here
        ownerOf[tokenId_] = to_; 
        totalSupply++; 
        // ERC72165535 Ends Here

        // ERC721I65535Enumerable Starts Here
        addressToTokens[to_].push(tokenId_); 
        addressToTokenIndex[to_][tokenId_] = uint256(addressToTokens[to_].length) - 1;
        // ERC721I65535Enumerable Ends Here

        emit Transfer(address(0x0), to_, tokenId_);
    }

    // transfer
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        require(from_ == ownerOf[tokenId_], "OX");

        // ERC721I65535 Starts Here
        ownerOf[tokenId_] = to_; 
        // ERC72165535 Ends Here

        // // ERC721I65535Enumerable Starts Here
        // Remove Token & Index from Old Address
        uint256 _indexFrom = addressToTokenIndex[from_][tokenId_];
        uint256 _maxIndexFrom = uint256(addressToTokens[from_].length) - 1;
        if (_indexFrom != _maxIndexFrom) {
            addressToTokens[from_][_indexFrom] = addressToTokens[from_][_maxIndexFrom];
        } addressToTokens[from_].pop(); delete addressToTokenIndex[from_][tokenId_];

        // Add Token & Index to New Address
        addressToTokens[to_].push(tokenId_);
        addressToTokenIndex[to_][tokenId_] = uint256(addressToTokens[to_].length) - 1;
        // ERC721I65535Enumerable Ends Here

        emit Transfer(from_, to_, tokenId_);
    }
    function _safeTransfer(address from_, address to_, uint256 tokenId_, bytes memory data_) internal virtual {
        _transfer(from_, to_, tokenId_);
        require(_checkOnERC721Received(from_, to_, tokenId_, data_), "TNERC721I");
    }

    // approve
    function _approve(address to_, uint256 tokenId_) internal virtual {
        getApproved[tokenId_] = to_;
        emit Approval(ownerOf[tokenId_], to_, tokenId_);
    }
    function _setApprovalForAll(address owner_, address operator_, bool approved_) internal virtual {
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    // token uri
    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }
    function _setBaseTokenURI_EXT(string memory ext_) internal virtual {
        baseTokenURI_EXT = ext_;
    }

    // // Internal View Functions
    // Embedded Libraries
    function _toString(uint256 tokenId_) internal pure returns (string memory) {
        if (tokenId_ == 0) { return "0"; }
        uint256 _iterate = tokenId_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in tokenId_
        bytes memory _buffer = new bytes(_digits);
        while (tokenId_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(48 + uint256(tokenId_ % 10 ))); tokenId_ /= 10; } // create bytes of tokenId_
        return string(_buffer); // return string converted bytes of tokenId_
    }

    // Functional Views
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view virtual returns (bool) {
        address _owner = ownerOf[tokenId_];
        return (spender_ == _owner || spender_ == getApproved[tokenId_] || isApprovedForAll[_owner][spender_]);
    }
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return ownerOf[tokenId_] != address(0x0);
    }

    // // public write functions
    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf[tokenId_];
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender], "CNOA");
        _approve(to_, tokenId_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }
    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "TNCOA");
        _transfer(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "TNCOA");
        _safeTransfer(from_, to_, tokenId_, data_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    // // public view functions
    function balanceOf(address address_) public view returns (uint256) {
        return addressToTokens[address_].length;
    }
    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        return addressToTokens[address_];
    }

    // // token uri
    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        require(ownerOf[tokenId_] != address(0x0), "TNX");
        return string(abi.encodePacked(baseTokenURI, _toString(tokenId_), baseTokenURI_EXT));
    }
}

contract testNFT is ERC721IE {
    constructor() ERC721IE("TESTNFT", "TEST") {}
    function mint(uint qty_) public {
        for (uint i = 0; i < qty_; i++) {
            _mint(msg.sender, totalSupply);
        }
    }
}