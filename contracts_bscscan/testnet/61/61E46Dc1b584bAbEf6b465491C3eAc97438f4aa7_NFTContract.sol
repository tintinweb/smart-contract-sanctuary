/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
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
library ECDSA {
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;
    if (signature.length != 65) {
      return (address(0));
    }
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }
    if (v < 27) {
      v += 27;
    }
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }  
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require( address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require( success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall( address target, bytes memory data, string memory errorMessage ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue( address target, bytes memory data, uint256 value ) internal returns (bytes memory) {
        return functionCallWithValue( target, data, value, "Address: low-level call with value failed" );
    }
    function functionCallWithValue( address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require( address(this).balance >= value, "Address: insufficient balance for call" );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall( target, data, "Address: low-level static call failed");
    }
    function functionStaticCall( address target, bytes memory data, string memory errorMessage ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall( target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall( address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult( bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }
    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer( address indexed from, address indexed to, uint256 indexed tokenId );
    event Approval( address indexed owner, address indexed approved, uint256 indexed tokenId );
    event ApprovalForAll( address indexed owner, address indexed operator, bool approved );
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC721Receiver {
    function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require( owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require( owner != address(0), "ERC721: owner query for nonexistent token" );
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId),"ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom( address from, address to, uint256 tokenId) internal virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) internal virtual {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom( address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer( address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data),"ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint( address to, uint256 tokenId,bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
    function _transfer( address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    function _checkOnERC721Received( address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
    function _beforeTokenTransfer( address from, address to, uint256 tokenId ) internal virtual {}
}
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require( _exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require( newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract NFTContract is ERC721, ERC721URIStorage, Ownable {
    constructor(string memory tokenName, string memory tokenSymbol) ERC721(tokenName, tokenSymbol){}
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    mapping(uint256 => uint256) public prices; // tokenId => tokenId Price
    mapping(uint256 => bool) public bidded; // tokenId => Is tokenId already bidded
    mapping(uint256 => mapping(address=>uint256)) public bidsOffers; // tokenId => bidder address => price
    mapping(uint256 => address) public bidders; // tokenId => bidder address
    mapping(address => mapping(uint256 => bool)) seenNonces; //for mi
    mapping(uint256 => tokenInfo) public allTokensInfo;
    uint256 public newItemId;
    Counters.Counter private _tokenIds;
    struct tokenInfo {
        uint256 tokenId;
        address payable creator;
        address payable currentOwner;
        uint256 price;
        uint selling;
        address signer;
        address creator1;
    }
    struct createNftData {
        string metaData;
        address creator;
    }
    event NewBid(uint256 indexed tokenId,uint256 indexed price);
    event NewOffer(uint256 indexed tokenId,uint256 indexed price);
    event OfferAccepted(uint256 indexed tokenId,uint256 indexed price,address from,address to);
    event BidAccepted(uint256 indexed tokenId,uint256 indexed price,address from,address to);
    modifier onlyNftOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender,"Not the owner");
        _;
    }
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    function getTokenOwner(uint256 _tokenId) public view returns (address) {
        return ownerOf(_tokenId);
    }
    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) external onlyNftOwner(_tokenId) {
        tokenInfo memory tokenInfoById = allTokensInfo[_tokenId];
        tokenInfoById.price = _newPrice;
        allTokensInfo[_tokenId] = tokenInfoById;
    }
    function changeSellingStatus(uint256 _tokenId, uint status) external onlyNftOwner(_tokenId) {
        tokenInfo memory tokenInfoById = allTokensInfo[_tokenId];
        tokenInfoById.selling = status;
        allTokensInfo[_tokenId] = tokenInfoById;
    }
    function createNFT(createNftData memory _nftData, bytes32 hash, bytes memory signature) public returns (uint256) {
        address signer = hash.recover(signature);
        // require(signer == msg.sender && _nftData.creator == msg.sender, "Invalid creator signature");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        require(!_exists(newTokenId), "Token ID already exists");
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _nftData.metaData);
        tokenInfo memory newTokenInfo = tokenInfo(
            newTokenId,
            payable(msg.sender),
            payable(msg.sender),
            0,
            0,
            signer,
            _nftData.creator
        );
        allTokensInfo[newTokenId] = newTokenInfo;
        return newTokenId;
    }
    function checkData(uint256 tokenId) external view  returns (tokenInfo memory){
        tokenInfo memory tokenInfoById = allTokensInfo[tokenId];
        return tokenInfoById;
    }
    function placeBid(uint256 tokenId, uint256 price, bytes32 hash, bytes memory signature) external payable {
        address signer = hash.recover(signature);
        // require(signer == msg.sender, "Invalid User signature");
        require(price > 0,"Price must be non-zero");
        require(_exists(tokenId),"Non-existent tokenId");
        tokenInfo memory tokenInfoById = allTokensInfo[tokenId];
        require(tokenInfoById.selling == 2, "NFT not available for selling");
        bidsOffers[tokenId][msg.sender] = price;
        emit NewBid(tokenId,price);
    }
    function placeOffer(uint256 tokenId, uint256 price, bytes32 hash, bytes memory signature) external payable {
        address signer = hash.recover(signature);
        // require(signer == msg.sender, "Invalid User signature");
        require(price > 0,"Price must be non-zero");
        require(_exists(tokenId),"Non-existent tokenId");
        tokenInfo memory tokenInfoById = allTokensInfo[tokenId];
        require(tokenInfoById.selling == 1, "NFT not available for selling");
        bidsOffers[tokenId][msg.sender] = price;
        emit NewBid(tokenId,price);
    }
    function transferByAcceptOffer(uint256 tokenId, address newOwner, bytes32 hash, bytes memory signature) external payable onlyNftOwner(tokenId) {
        address signer = hash.recover(signature);
        // require(signer == msg.sender, "Invalid User signature");
        require(bidsOffers[tokenId][newOwner] > 0, "User did not made offer");
        require(msg.value == bidsOffers[tokenId][newOwner], "Invalid amount");
        tokenInfo memory tokenInfoById = allTokensInfo[tokenId];
        require(tokenInfoById.selling > 0, "NFT not available for sale");
        _transfer(msg.sender, newOwner, tokenId);
        tokenInfoById.currentOwner = payable(newOwner);
        allTokensInfo[tokenId] = tokenInfoById;
        payable(msg.sender).transfer(msg.value);
        emit OfferAccepted(tokenId,bidsOffers[tokenId][newOwner],msg.sender,newOwner);
    }
    function transferByBid(uint256 tokenId, address newOwner, bytes32 hash, bytes memory signature) external payable onlyNftOwner(tokenId) {
        address signer = hash.recover(signature);
        // require(signer == msg.sender, "Invalid User signature");
        require(bidsOffers[tokenId][newOwner] > 0, "User did not palce bid");
        require(msg.value == bidsOffers[tokenId][newOwner], "Invalid amount");
        tokenInfo memory tokenInfoById = allTokensInfo[tokenId];
        require(tokenInfoById.selling > 0, "NFT not available for sale");
        _transfer(msg.sender, newOwner, tokenId);
        tokenInfoById.currentOwner = payable(newOwner);
        allTokensInfo[tokenId] = tokenInfoById;
        payable(tokenInfoById.currentOwner).transfer(msg.value);
        emit BidAccepted(tokenId,bidsOffers[tokenId][newOwner],msg.sender,newOwner);
    }
}