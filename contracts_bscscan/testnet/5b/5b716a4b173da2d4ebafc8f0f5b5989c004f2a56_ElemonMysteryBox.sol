// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IElemonNFT.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Runnable.sol";

contract ElemonMysteryBox is ReentrancyGuard, Runnable{
    address public _recepientAddress;

    IElemonNFT public _mysteryBoxNFT;
    uint256 public _startBlock;
    uint256 public _endBlock;
    uint256 public _price;
    uint256 public _boxToSell;
    uint256 public _purchasedBox;

    IERC20 public _busdToken;

    constructor(address mysteryBoxNFTAddress, address recepientAddress, address busdTokenAddress){
        require(mysteryBoxNFTAddress != address(0), "mysteryBoxNFTAddress is zero address");
        require(recepientAddress != address(0), "recepientAddress is zero address");

        _mysteryBoxNFT = IElemonNFT(mysteryBoxNFTAddress);
        _recepientAddress = recepientAddress;
        _busdToken = IERC20(busdTokenAddress);
    }

    function purchase() external nonReentrant whenRunning {
        require(_purchasedBox < _boxToSell, "Sold out");
        require(_startBlock <= block.number && _endBlock >= block.number, "Can not purchase this time");

        //Send fund to wallet
        require(_busdToken.transferFrom(_msgSender(), _recepientAddress, _price), "Can not transfer BUSD");

        //Mint NFT
        uint256 mysteryBoxTokenId = _mysteryBoxNFT.mint(_msgSender());

        _purchasedBox++;
        
        emit Purchased(_msgSender(), mysteryBoxTokenId, _price, block.timestamp);
    }

    function setSaleInfo(uint256 startBlock, uint256 endBlock, uint256 price, uint256 boxToSell) external onlyOwner{
        _startBlock = startBlock;
        _endBlock = endBlock;
        _price = price;
        _boxToSell = boxToSell;

        emit SaleInfoSeted(startBlock, endBlock, price, boxToSell);
    }

    function setMysteryBoxNFT(address newAddress) external onlyOwner{
        require(newAddress != address(0), "Address 0");
        _mysteryBoxNFT = IElemonNFT(newAddress);
    }

    function setBusdToken(address newAddress) external onlyOwner{
        require(newAddress != address(0), "Address 0");
        _busdToken = IERC20(newAddress);
    }

    function setRecepientTokenAddress(address recepientAddress) external onlyOwner{
        require(recepientAddress != address(0), "Address 0");
        _recepientAddress = recepientAddress;
    }

    function withdrawToken(address tokenAddress, address recepient, uint256 value) external onlyOwner {
        IERC20(tokenAddress).transfer(recepient, value);
    }

    event SaleInfoSeted(uint256 startBlock, uint256 endBlock, uint256 price, uint256 boxToSell);
    event Purchased(address account, uint256 tokenId, uint256 price, uint256 time);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";

contract Runnable is Ownable{
    modifier whenRunning{
        require(_isRunning, "Paused");
        _;
    }
    
    modifier whenNotRunning{
        require(!_isRunning, "Running");
        _;
    }
    
    bool public _isRunning;
    
    constructor(){
        _isRunning = true;
    }
    
    function toggleRunning() public onlyOwner{
        _isRunning = !_isRunning;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './Context.sol';

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    _owner = _msgSender();
    emit OwnershipTransferred(address(0), _msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
  
  function _now() internal view returns (uint256) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return block.timestamp;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IElemonNFT{
    function mint(address to) external returns(uint256);
    function setContractOwner(address newOwner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
    function isExisted(uint256 tokenId) external view returns(bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}