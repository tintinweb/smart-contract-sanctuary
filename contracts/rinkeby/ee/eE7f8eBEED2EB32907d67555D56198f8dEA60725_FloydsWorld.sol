/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    function balanceOf(address owner) external view returns (uint256 balance);

    
    function ownerOf(uint256 tokenId) external view returns (address owner);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function approve(address to, uint256 tokenId) external;

    
    function getApproved(uint256 tokenId) external view returns (address operator);

    
    function setApprovalForAll(address operator, bool _approved) external;

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    
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

    
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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

    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

abstract contract ReentrancyGuard {
    
    
    
    
    

    
    
    
    
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    
    modifier nonReentrant() {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        
        _status = _ENTERED;

        _;

        
        
        _status = _NOT_ENTERED;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract FloydsWorld is Ownable, ERC721 {

  string public baseURI = "https://floydnft.com/token/";
  uint public totalSupply;

  uint private lastPrivateSaleTokenIndex = 110;
  uint private lastPublicSaleTokenIndex = 1500;

  address public immutable treasury; 
  address public immutable privateSaleMinter; 

  uint public immutable salePrice; 
  uint public immutable saleStartDate; 

  ERC721 public immutable presaleTicket; 
  ERC721 public immutable auctionTicket; 

  uint private constant LAST_TOKEN_ID = 11110;

  modifier whenSaleIsOpen {
    require(block.timestamp >= saleStartDate, "Sale is not yet open");
    require(lastPublicSaleTokenIndex < LAST_TOKEN_ID, "Sale has already ended");
    _;
  }

  modifier whenSaleIsClosed {
    require(lastPublicSaleTokenIndex >= LAST_TOKEN_ID, "Sale has not yet ended");
    _;
  }

  constructor(
    uint _salePrice,
    uint _saleStartDate,
    address _presaleTicket,
    address _auctionTicket,
    address _treasury,
    address _privateSaleMinter
  ) ERC721("FloydsWorld", "FMW") {
    salePrice = _salePrice;
    saleStartDate = _saleStartDate;
    presaleTicket = ERC721(_presaleTicket);
    auctionTicket = ERC721(_auctionTicket);
    treasury = _treasury;
    privateSaleMinter = _privateSaleMinter;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _hashURI(string memory uri) internal pure returns (bytes32 hash) {
    string memory salt = "2abf47b893ebe6f710318290d798085f";
    return keccak256(abi.encode(salt, uri));
  }

  function hashString(string memory uri) external pure returns (bytes32 hash) {
    return _hashURI(uri);
  }

  function revealNFTs(string memory newURI) external whenSaleIsClosed {
    
    bytes32 hashedURI = "1234";
    require(_hashURI(newURI) == hashedURI, "Bad URI");
    baseURI = newURI;
  }

  function setBaseURI(string memory newURI) external onlyOwner {
    baseURI = newURI;
  }

  function _withdraw(uint amount) internal {
    (bool ok,) = payable(treasury).call{value : amount}("");
    require(ok, "Withdraw failed");
  }

  function withdrawAll() external onlyOwner {
    _withdraw(address(this).balance);
  }

  function _mintAndIncrementSupply(address to, uint tokenId) internal {
    _safeMint(to, tokenId);
    totalSupply++;
  }

  function buyNFT(uint quantity) external payable whenSaleIsOpen {

    uint lastTokenId = lastPublicSaleTokenIndex;
    uint remainder;

    require(msg.value == salePrice * quantity, "Invalid amount");

    for (uint i = 0; i < quantity; i++) {

      lastTokenId++;

      if (lastTokenId == 2000) {
        lastTokenId = 6851;
      }

      _mintAndIncrementSupply(msg.sender, lastTokenId);

      if (lastTokenId == LAST_TOKEN_ID) {
        remainder = quantity - i - 1;
        break;
      }
    }

    lastPublicSaleTokenIndex = lastTokenId;

    if (remainder > 0) {
      uint refund = remainder * salePrice;
      (bool ok,) = payable(msg.sender).call{value : refund}("");
      require(ok, "Refund failed");
    }

    if (lastTokenId == LAST_TOKEN_ID) {
      
      _withdraw(address(this).balance);
      return;
    }

    if (address(this).balance >= 15 ether) {
      
      _withdraw(15 ether);
    }
  }

  function privateSaleMint(uint quantity) external whenSaleIsClosed {

    uint lastTokenId = lastPrivateSaleTokenIndex;
    require(lastTokenId < 1500, "Already minted");

    for (uint i = 0; i < quantity; i++) {

      lastTokenId++;
      _mintAndIncrementSupply(privateSaleMinter, lastTokenId);

      if (lastTokenId == 1500) {
        break;
      }
    }

    lastPrivateSaleTokenIndex = lastTokenId;
  }

  
  
  
  
  
  

  function redeemNFT(uint[] calldata ids, uint[] calldata types) external whenSaleIsClosed {

    require(ids.length == types.length, "Array lengths don't match");

    address burnAddress = 0x000000000000000000000000000000000000dEaD;

    for (uint i = 0; i < ids.length; i++) {

      uint id = ids[i];
      uint ticketType = types[i];

      
      if (ticketType == 1) {

        
        require(
          (id >= 0 && id <= 110) || (id >= 2000 && id <= 5971),
          "Invalid presale ticket"
        );

        
        presaleTicket.safeTransferFrom(msg.sender, burnAddress, id);
        _mintAndIncrementSupply(msg.sender, id);
        continue;
      }

      
      if (ticketType == 2) {

        
        require(id >= 5972 && id <= 6850, "Invalid auction ticket");

        
        auctionTicket.safeTransferFrom(msg.sender, burnAddress, id);
        _mintAndIncrementSupply(msg.sender, id);
        continue;
      }
    }
  }

  function getTicketsOf(address buyer) external view returns (uint[] memory ids, uint[] memory types) {

    uint[5000] memory tempIds;
    uint[5000] memory tempTypes;
    uint idx;

    for (uint i = 0; i <= 100; i++) {
      if (presaleTicket.ownerOf(i) == buyer) {
        tempIds[idx] = i;
        tempTypes[idx] = 1;
        idx++;
      }
    }

    for (uint i = 2000; i <= 5971; i++) {
      if (presaleTicket.ownerOf(i) == buyer) {
        tempIds[idx] = i;
        tempTypes[idx] = 1;
        idx++;
      }
    }

    for (uint i = 5972; i <= 6850; i++) {
      if (auctionTicket.ownerOf(i) == buyer) {
        tempIds[idx] = i;
        tempTypes[idx] = 2;
        idx++;
      }
    }

    ids = new uint[](idx);
    types = new uint[](idx);

    for (uint i = 0; i < idx; i++) {
      ids[i] = tempIds[i];
      types[i] = tempTypes[i];
    }
  }

}