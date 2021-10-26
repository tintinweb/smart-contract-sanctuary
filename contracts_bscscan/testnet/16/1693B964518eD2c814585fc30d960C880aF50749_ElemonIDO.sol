//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './utils/Ownable.sol';
import './utils/ReentrancyGuard.sol';
import './interfaces/IERC20.sol';

contract ElemonIDO is Ownable, ReentrancyGuard {
    IERC20 public _busdToken;
    IERC20 public _elmonToken;
    address public _idoRecepientAddress;

    //The token price for BUSD, multipled by 1000
    uint256 public constant ELEMON_PRICE = 90;      //0.09
    uint256 public constant ONE_THOUSAND = 1000;

    uint256 public constant ALLOCATION = 1000000000000000000;
    uint256 public _totalBought = 0;

    uint256 public _startBlock;
    uint256 public _endBlock;
    uint256[] public _claimableBlocks;
    mapping(uint256 => uint256) public _claimablePercents;

    //Store the number of token that user can buy
    //Mapping user address and the number of ELEMON user can buy
    mapping(address => uint256) public _userSlots;
    mapping(address => uint256) public _userBoughts;
    mapping(address => uint256) public _claimCounts;

    constructor(
        address busdAddress, address elmonAddress, address idoRecepientAddress,
        uint256 startBlock, uint256 endBlock){
        _busdToken = IERC20(busdAddress);
        _elmonToken = IERC20(elmonAddress);
        _idoRecepientAddress = idoRecepientAddress;
        _startBlock = startBlock;
        _endBlock = endBlock;

        //THIS PROPERTIES WILL BE SET WHEN DEPLOYING CONTRACT
        //_claimableBlocks = [];
        //_claimablePercents[] = 50;
        //_claimablePercents[] = 25;
        //_claimablePercents[] = 25;
    }

    function buy(uint256 busdQuantity) external nonReentrant {
        require(_idoRecepientAddress != address(0), "IDO recepient address has not been setted");
        require(block.number >= _startBlock && block.number <= _endBlock, "Can not buy at this time");
        require(_userSlots[_msgSender()] > 0, "You are not in whitelist");
        uint256 maxTokenCanBuy = _userSlots[_msgSender()] - _userBoughts[_msgSender()];
        require(maxTokenCanBuy > 0, "You reach to maximum to buy");
        
        uint256 tokenQuantity = busdQuantity * ONE_THOUSAND / ELEMON_PRICE;
        require(tokenQuantity > 0, "No token to buy");

        if(tokenQuantity > maxTokenCanBuy){
            tokenQuantity = maxTokenCanBuy;

            busdQuantity = tokenQuantity * ELEMON_PRICE / ONE_THOUSAND;
        }

        _busdToken.transferFrom(_msgSender(), _idoRecepientAddress , busdQuantity);
        _userBoughts[_msgSender()] += tokenQuantity;
        _totalBought += tokenQuantity;

        emit Purchased(_msgSender(), tokenQuantity);
    }

    function claim() external nonReentrant{
        uint256 userBought = _userBoughts[_msgSender()];
        require(userBought > 0, "Nothing to claim");
        require(_claimableBlocks.length > 0, "Can not claim at this time");
        require(block.number >= _claimableBlocks[0], "Can not claim at this time");

        uint256 startIndex = _claimCounts[_msgSender()];
        require(startIndex < _claimableBlocks.length, "You have claimed all token");

        uint256 tokenQuantity = 0;
        for(uint256 index = startIndex; index < _claimableBlocks.length; index++){
            uint256 claimBlock = _claimableBlocks[index];
            if(block.number >= claimBlock){
                tokenQuantity += userBought * _claimablePercents[claimBlock] / 100;
                _claimCounts[_msgSender()]++;
            }else{
                break;
            }
        }

        require(tokenQuantity > 0, "Token quantity is not enough to claim");
        _elmonToken.transfer(_msgSender(), tokenQuantity);

        emit Claimed(_msgSender(), tokenQuantity);
    }

    function getClaimable(address account) external view returns(uint256){
        uint256 userBought = _userBoughts[account];
        if(userBought == 0) return 0;
        if(_claimableBlocks.length == 0) return 0;
        if(block.number < _claimableBlocks[0]) return 0;
        if(_claimCounts[account] >= _claimableBlocks.length) return 0;

        uint256 startIndex = _claimCounts[account];

        uint256 tokenQuantity = 0;
        for(uint256 index = startIndex; index < _claimableBlocks.length; index++){
            uint256 claimBlock = _claimableBlocks[index];
            if(block.number >= claimBlock){
                tokenQuantity += userBought * _claimablePercents[claimBlock] / 100;
            }else{
                break;
            }
        }

        return tokenQuantity;
    }

    function setBusdToken(address newAddress) external onlyOwner{
        require(newAddress != address(0), "Zero address");
        _busdToken = IERC20(newAddress);
    }

    function setElmonToken(address newAddress) external onlyOwner{
        require(newAddress != address(0), "Zero address");
        _elmonToken = IERC20(newAddress);
    }

    function setIdoRecepientAddress(address newAddress) external onlyOwner{
        require(newAddress != address(0), "Zero address");
        _idoRecepientAddress = newAddress;
    }

    function setIdoBlocks(uint256 startBlock, uint256 endBlock) external onlyOwner{
        require(startBlock > block.number, "Start block should be greater than current block");
        require(startBlock < endBlock, "Start block should be less than end block");
        _startBlock = startBlock;
        _endBlock = endBlock;
    }

    function setClaimableBlocks(uint256[] memory blocks) external onlyOwner{
        require(blocks.length > 0, "Empty input");
        _claimableBlocks = blocks;
    }

    function setClaimablePercents(uint256[] memory blocks, uint256[] memory percents) external onlyOwner{
        require(blocks.length > 0, "Empty input");
        require(blocks.length == percents.length, "Empty input");
        for(uint256 index = 0; index < blocks.length; index++){
            _claimablePercents[blocks[index]] = percents[index];
        }
    }

    event Purchased(address account, uint256 tokenQuantity);
    event Claimed(address account, uint256 tokenQuantity);
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