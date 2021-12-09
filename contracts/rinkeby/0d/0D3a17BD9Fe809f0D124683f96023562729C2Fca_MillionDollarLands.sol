/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Interfaces
interface IERC165 {
  function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC721 {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) external view returns (address owner);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _to, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address operator);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Metadata {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721Receiver {
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

// Abstract Contracts
abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _owner = msg.sender;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function getOwner() public view returns (address) {
    return _owner;
  }

  function transferOwnership(address _newOwner) public virtual onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    _owner = _newOwner;
  }
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

// Contract
contract MillionDollarLands is Ownable, ReentrancyGuard {
  // ERC721
  mapping(uint256 => address) private _owners;
  mapping(address => uint256) private _balances;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  // ERC721Metadata
  string public name = 'The Million Dollar Lands';
  string public symbol = 'MDL';
  string public baseURI = 'https://milliondollarlands.com/api/metadata/';

  // ERC721Enumerable
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
  mapping(uint256 => uint256) private _ownedTokensIndex;
  uint256[] private _allTokens;
  mapping(uint256 => uint256) private _allTokensIndex;
  
  // Customized
  uint256 public INITIAL_LAND_PRICE = 220000000000000000; // 0.22 ETH
  uint256 private constant WORLD_WIDTH = 25;
  uint256 private constant WORLD_HEIGHT = 40;

  // Constructor
  constructor() {
    taxTreasury = payable(msg.sender);
  }

  // ERC165
  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId;
  }

  // Customized (variables)
  struct Land {
    address owner;
    uint256 price;
    uint256 taxDeposit;
    uint256 lastPrice;
    uint256 lastPurchased;
    uint256 lastTaxPaid;
  }

  uint256 public TAX_RATE = 7000; // 7% per year
  uint256 private constant BLOCKS_PER_YEAR = 2102400;
  mapping(uint256 => Land) private lands; // mapping(tokenId => Land)
  address payable public taxTreasury;
  uint256 public taxCollected;

  event Price(uint256 indexed tokenId, uint256 price);

  // Customized (public)
  function setBaseURI(string memory _baseURI) external onlyOwner returns (bool) {
    baseURI = _baseURI;
    return true;
  }

  function buy(uint256 _tokenId, uint256 _newPrice, uint256 _taxDeposit) external payable nonReentrant returns (bool) {
    uint256 currentPrice;
    address originalOwner;

    if(_exists(_tokenId)) {
      Land memory land = lands[_tokenId];
      uint256 taxDue = getTaxDue(_tokenId);

      // Check if tax payment overdue
      if(taxDue > land.taxDeposit) {
        currentPrice = INITIAL_LAND_PRICE;
        originalOwner = getOwner();
      }else{
        currentPrice = land.price;
        originalOwner = land.owner;
      }

      _transfer(land.owner, msg.sender, _tokenId);

      // Tax Refund
      if(taxDue < land.taxDeposit) {
        payable(land.owner).transfer(land.taxDeposit - taxDue);
      }
    } else {
      currentPrice = INITIAL_LAND_PRICE;
      originalOwner = getOwner();
      _mint(msg.sender, _tokenId);
    }

    require(msg.value >= currentPrice + _taxDeposit, "MDL: insufficient ETH is sent");

    // Payment
    payable(originalOwner).transfer(currentPrice);

    // Change
    if(msg.value > currentPrice) {
      payable(msg.sender).transfer(msg.value - currentPrice - _taxDeposit);
    }

    lands[_tokenId] = Land(
      msg.sender,
      _newPrice,
      _taxDeposit,
      currentPrice,
      block.timestamp,
      block.number
    );

    return true;
  }

  function addTaxDeposit(uint256 _tokenId) external payable returns (bool) {
    require(msg.value > 0, "MDL: send more than 0 ETH");
    lands[_tokenId].taxDeposit += msg.value;
    payTax(_tokenId);
    return true;
  }

  function payTax(uint256 _tokenId) public returns (bool) {
    require(_exists(_tokenId), "MDL: nonexistnet land");
    Land storage land = lands[_tokenId];
    uint256 taxDue = getTaxDue(_tokenId);
    if(land.taxDeposit >= taxDue) {
      land.taxDeposit -= taxDue;
      land.lastTaxPaid = block.number;
      taxTreasury.transfer(taxDue);
      taxCollected += taxDue;
    }
    return true;
  }

  function removeTaxDeposit(uint256 _tokenId, uint256 _amount) external returns (bool) {
    require(msg.sender == lands[_tokenId].owner, "MDL: msg.sender does not have ownership");
    payTax(_tokenId);

    Land storage land = lands[_tokenId];
    
    require(_amount <= land.taxDeposit, "MDL: insufficient tax deposit");
    land.taxDeposit -= _amount;
    payable(msg.sender).transfer(_amount);

    return true;
  }

  function setLandPrice(uint256 _tokenId, uint256 _price) external returns (bool) {
    require(msg.sender == lands[_tokenId].owner, "MDL: msg.sender does not have ownership");
    payTax(_tokenId);

    Land storage land = lands[_tokenId];
    land.price = _price;

    emit Price(_tokenId, _price);

    return true;
  }
 
  function getLand(uint256 _tokenId) external view returns (
    address owner,
    uint256 price,
    uint256 taxDeposit,
    uint256 taxDue,
    uint256 lastPrice,
    uint256 lastPurchased,
    uint256 lastTaxPaid    
  ) {
    if(_exists(_tokenId)) {
      Land memory land = lands[_tokenId];
      owner = land.owner;
      price = land.price;
      taxDeposit = land.taxDeposit;
      taxDue = getTaxDue(_tokenId);
      lastPrice = land.lastPrice;
      lastPurchased = land.lastPurchased;
      lastTaxPaid = land.lastTaxPaid;
    } else {
      owner = getOwner();
      price = INITIAL_LAND_PRICE;
      taxDeposit = 0;
      taxDue = 0;
      lastPrice = INITIAL_LAND_PRICE;
      lastPurchased = 0;
      lastTaxPaid = 0;
    }
  }

  function getTaxDue(uint256 _tokenId) public view returns (uint256) {
    Land memory land = lands[_tokenId];
    return land.price * TAX_RATE * (block.number - land.lastTaxPaid) / BLOCKS_PER_YEAR / 100000;
  }

  // Admin Functions
    function setInitialPrice(uint256 _price) external onlyOwner returns (bool) {
    INITIAL_LAND_PRICE = _price;
    return true;
  }

  function setTaxRate(uint256 _taxRate) external onlyOwner returns (bool) {
    TAX_RATE = _taxRate;
    return true;
  }

  function setTaxTreasury(address payable _taxTreasury) external onlyOwner returns (bool) {
    taxTreasury = _taxTreasury;
    return true;
  }

  function emergencyWithdraw() external onlyOwner returns (bool) {
    payable(msg.sender).transfer(address(this).balance);
    return true;
  }

  // Customized (private)
  function getTokenId(uint256 _x, uint256 _y) public pure returns (uint256 tokenId) {
    require(_x < WORLD_WIDTH, "MDL: x is out of range");
    require(_y < WORLD_HEIGHT, "MDL: y is out of range");
    return _x + _y * WORLD_WIDTH + 1;
  }

  function getCoordinates(uint256 _tokenId) public pure returns (uint256 x, uint256 y) {
    require(_tokenId <= WORLD_WIDTH * WORLD_HEIGHT, "MDL: tokenId is out of range");
    x = (_tokenId - 1) % WORLD_WIDTH;
    y = (_tokenId - 1) / WORLD_WIDTH;
  }

  // ERC721 (public)
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  function approve(address to, uint256 tokenId) public returns (bool) {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      msg.sender == owner || isApprovedForAll(owner, msg.sender),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
    return true;
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public returns (bool) {
    require(operator != msg.sender, "ERC721: approve to caller");

    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
    return true;
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(address from, address to, uint256 tokenId) public returns (bool) {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
    return true;
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public returns (bool) {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
    return true;
  }

  // ERC721 (private)
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) private {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  function _exists(uint256 tokenId) private view returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _safeMint(address to, uint256 tokenId) private {
    _safeMint(to, tokenId, "");
  }

  function _safeMint(address to, uint256 tokenId, bytes memory _data) private {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function _mint(address to, uint256 tokenId) private {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);

    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(address(0), getOwner(), tokenId);
    emit Transfer(getOwner(), to, tokenId);
  }

  function _burn(uint256 tokenId) private {
    address owner = ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    _balances[owner] -= 1;
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }

  function _transfer(address from, address to, uint256 tokenId) private {
    require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
    if (isContract(to)) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
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

  // ERC721Metadata
  function tokenURI(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(baseURI, toString(_tokenId)));
  }

  // ERC721Enumerable (public)
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
    return _allTokens[index];
  }

  // ERC721Enumerable (private)
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) private {
    if (from == address(0)) {
      _addTokenToAllTokensEnumeration(tokenId);
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      _removeTokenFromAllTokensEnumeration(tokenId);
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    uint256 lastTokenIndex = balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }

  // Utils
  function isContract(address account) private view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function toString(uint256 value) private pure returns (string memory) {
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

  function adminWithdraw(uint256 _amount) public onlyOwner returns (bool) {
    payable(msg.sender).transfer(_amount);
    return true;
  }
}