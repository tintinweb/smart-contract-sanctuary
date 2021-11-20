// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { ITokenLockerManagerV1 } from "./ITokenLockerManagerV1.sol";
import { Ownable } from "./Ownable.sol";
import { IERC20 } from "./library/IERC20.sol";
import { TokenLockerV1 } from "./TokenLockerV1.sol";

contract TokenLockerManagerV1 is ITokenLockerManagerV1, Ownable {
  event TokenLockerCreated(
    uint40 id,
    address indexed token,
    /** @dev LP token pair addresses - these will be address(0) for regular tokens */
    address indexed token0,
    address indexed token1,
    address createdBy,
    uint256 balance,
    uint40 unlockTime
  );

  constructor() Ownable(_msgSender()) {
    _creationEnabled = true;
  }

  bool private _creationEnabled;

  uint40 private _tokenLockerCount;

  /** @dev main mapping for lock data */
  mapping(uint40 => TokenLockerV1) private _tokenLockers;

  /**
   * @dev this mapping makes it possible to search for locks,
   * at the cost of paying higher gas fees to store the data.
   */
  mapping(address => uint40[]) private _tokenLockersForAddress;

  mapping(address => bool) private _addressCreationLocks;

  modifier allowCreation() {
    require(_creationEnabled, "Locker creation is disabled");
    _;
  }

  modifier lockCreation() {
    require(
      !_addressCreationLocks[_msgSender()],
      "Creation from this address is locked, wait until the previous transaction completes"
    );
    _addressCreationLocks[_msgSender()] = true;
    _;
    _addressCreationLocks[_msgSender()] = false;
  }

  function tokenLockerCount() external view returns (uint40) {
    return _tokenLockerCount;
  }

  function creationEnabled() external view returns (bool) {
    return _creationEnabled;
  }

  /**
   * @dev allow turning off new lockers from being created, so that we can
   * migrate to new versions of the contract & stop people from locking
   * with the older versions. this will not prevent extending, depositing,
   * or withdrawing from old locks - it only stops new locks from being created.
   */
  function setCreationEnabled(bool value_) external onlyOwner {
    _creationEnabled = value_;
  }

  function createTokenLocker(
    address tokenAddress_,
    uint256 amount_,
    uint40 unlockTime_
  ) external allowCreation lockCreation {
    require(_creationEnabled, "Locker creation is disabled");

    uint40 id = _tokenLockerCount++;
    _tokenLockers[id] = new TokenLockerV1(address(this), id, _msgSender(), tokenAddress_, unlockTime_);
    address lockerAddress = address(_tokenLockers[id]);

    IERC20 token = IERC20(tokenAddress_);
    token.transferFrom(_msgSender(), lockerAddress, amount_);

    // add the creator to the token locker mapping, so it's
    // able to be searched.
    _tokenLockersForAddress[_msgSender()].push(id);

    // add the locked token to the token lockers mapping
    _tokenLockersForAddress[tokenAddress_].push(id);
    // add the locker contract to this mapping as well, so it's
    // searchable in the same way as tokens within the locker.
    _tokenLockersForAddress[address(_tokenLockers[id])].push(id);

    // get lp data
    (bool hasLpData,,address token0Address,address token1Address,,,,) = _tokenLockers[id].getLpData();

    // if this is an lp token, also add the paired tokens to the mapping
    if (hasLpData) {
      _tokenLockersForAddress[token0Address].push(id);
      _tokenLockersForAddress[token1Address].push(id);
    }

    emit TokenLockerCreated(
      id,
      tokenAddress_,
      token0Address,
      token1Address,
      _msgSender(),
      token.balanceOf(lockerAddress),
      unlockTime_
    );
  }

  /**
   * @return the address of a locker contract with the given id
   */
  function getTokenLockAddress(uint40 id_) external view returns (address) {
    return address(_tokenLockers[id_]);
  }

  function getTokenLockData(uint40 id_) external view returns (
    bool isLpToken,
    uint40 id,
    address contractAddress,
    address owner,
    address token,
    address createdBy,
    uint40 createdAt,
    uint40 unlockTime,
    uint256 balance,
    uint256 totalSupply
  ){
    return _tokenLockers[id_].getLockData();
  }

  function getLpData(uint40 id_) external view returns (
    bool hasLpData,
    uint40 id,
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  ) {
    return _tokenLockers[id_].getLpData();
  }

  /** @return an array of locker ids matching the given search address */
  function getTokenLockersForAddress(address address_) external view returns (uint40[] memory) {
    return _tokenLockersForAddress[address_];
  }

  /**
   * @dev this gets called from TokenLockerV1.
   * it notifies this contract of the owner change so we can modify the search index
   */
  function notifyLockerOwnerChange(uint40 id_, address newOwner_, address previousOwner_, address createdBy_) external {
    require(
      _msgSender() == address(_tokenLockers[id_]),
      "Only the locker contract can call this function"
    );

    // remove the previous owner from the locker address mapping,
    // only if it's not the same address as the creator.
    if (previousOwner_ != createdBy_) {
      for (uint256 i = 0; i < _tokenLockersForAddress[previousOwner_].length; i++) {
        // continue searching for id_ in the array until we find a match
        if (_tokenLockersForAddress[previousOwner_][i] != id_) continue;
        // replace the old item at this index with the last value.
        // we don't care about the order.
        _tokenLockersForAddress[previousOwner_][i] = _tokenLockersForAddress[
          previousOwner_][_tokenLockersForAddress[previousOwner_].length - 1
        ];
        // remove the last item in the array, since we just moved it
        _tokenLockersForAddress[previousOwner_].pop();
        // and we're done
        break;
      }
    }

    // push the new owner to the lockers address mapping so the new owner is searchable,
    // only if they don't already have this id in the lockers address mapping.
    bool hasId = false;

    // look for the id in the new owners address mapping
    for (uint256 i = 0; i < _tokenLockersForAddress[newOwner_].length; i++) {
      if (_tokenLockersForAddress[newOwner_][i] == id_) {
        hasId = true;
        break;
      }
    }

    // only add the id if they didn't already have it
    if (!hasId) {
      _tokenLockersForAddress[newOwner_].push(id_);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

interface ITokenLockerManagerV1 {
  function tokenLockerCount() external view returns (uint40);
  function creationEnabled() external view returns (bool);
  function setCreationEnabled(bool value_) external;
  function createTokenLocker(
    address tokenAddress_,
    uint256 amount_,
    uint40 unlockTime_
  ) external;
  function getTokenLockAddress(uint40 id_) external view returns (address);
  function getTokenLockData(uint40 id_) external view returns (
    bool isLpToken,
    uint40 id,
    address contractAddress,
    address owner,
    address token,
    address createdBy,
    uint40 createdAt,
    uint40 unlockTime,
    uint256 balance,
    uint256 totalSupply
  );
  function getLpData(uint40 id_) external view returns (
    bool hasLpData,
    uint40 id,
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  );
  function getTokenLockersForAddress(address address_) external view returns (uint40[] memory);
  function notifyLockerOwnerChange(uint40 id_, address newOwner_, address previousOwner_, address createdBy_) external;
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { Context } from "./library/Context.sol";

/**
 * @title Ownable
 * 
 * parent for ownable contracts
 */
abstract contract Ownable is Context {
  constructor(address owner_) {
    _owner_ = owner_;
    emit OwnershipTransferred(address(0), _owner());
  }

  address private _owner_;

  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  function _owner() internal view returns (address) {
    return _owner_;
  }

  function owner() external view returns (address) {
    return _owner();
  }

  modifier onlyOwner() {
    require(_owner() == _msgSender(), "Only the owner can execute this function");
    _;
  }

  function _transferOwnership(address newOwner_) virtual internal onlyOwner {
    // keep track of old owner for event
    address oldOwner = _owner();

    // set the new owner
    _owner_ = newOwner_;

    // emit event about ownership change
    emit OwnershipTransferred(oldOwner, _owner());
  }

  function transferOwnership(address newOwner_) external onlyOwner {
    _transferOwnership(newOwner_);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { ITokenLockerManagerV1 } from "./ITokenLockerManagerV1.sol";
import { Ownable } from "./Ownable.sol";
import { IUniswapV2Pair } from "./library/Dex.sol";
import { IERC20 } from "./library/IERC20.sol";
import { Util } from "./Util.sol";

contract TokenLockerV1 is Ownable {
  event Extended(uint40 newUnlockTime);
  event Deposited(uint256 amount);
  event Withdrew();

  constructor(address manager_, uint40 id_, address owner_, address tokenAddress_, uint40 unlockTime_) Ownable(owner_) {
    require(unlockTime_ > uint40(block.timestamp), "Unlock time must be in the future");

    _manager = ITokenLockerManagerV1(manager_);
    _id = id_;
    _token = IERC20(tokenAddress_);
    _createdBy = owner_;
    _createdAt = uint40(block.timestamp);
    _unlockTime = unlockTime_;
    _isLpToken = Util.isLpToken(tokenAddress_);
    
  }

  ITokenLockerManagerV1 private _manager;
  bool private _isLpToken;
  uint40 private _id;
  IERC20 private _token;
  address private _createdBy;
  uint40 private _createdAt;
  uint40 private _unlockTime;

  bool private _transferLocked;

  modifier transferLocked() {
    require(!_transferLocked, "Transfering is locked. Wait for the previous transaction to complete");
    _transferLocked = true;
    _;
    _transferLocked = false;
  }

  function _balance() private view returns (uint256) {
    return _token.balanceOf(address(this));
  }

  function getIsLpToken() external view returns (bool) {
    return _isLpToken;
  }

  function getLockData() external view returns (
    bool isLpToken,
    uint40 id,
    address contractAddress,
    address owner,
    address token,
    address createdBy,
    uint40 createdAt,
    uint40 unlockTime,
    uint256 balance,
    uint256 totalSupply
  ){
    isLpToken = _isLpToken;
    id = _id;
    contractAddress = address(this);
    owner = _owner();
    token = address(_token);
    createdBy = _createdBy;
    createdAt = _createdAt;
    unlockTime = _unlockTime;
    balance = _balance();
    totalSupply = _token.totalSupply();
  }

  function getLpData() external view returns (
    bool hasLpData,
    uint40 id,
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  ) {
    // always return the id
    id = _id;

    if (!_isLpToken) {
      // if this isn't an lp token, don't even bother calling getLpData
      hasLpData = false;
    } else {
      // this is an lp token, so let's get some data
      try Util.getLpData(address(_token)) returns (
        address token0_,
        address token1_,
        uint256 balance0_,
        uint256 balance1_,
        uint256 price0_,
        uint256 price1_
      ){
        hasLpData = true;
        token0 = token0_;
        token1 = token1_;
        balance0 = balance0_;
        balance1 = balance1_;
        price0 = price0_;
        price1 = price1_;
      } catch Error(string memory /* reason */) {
        hasLpData = false;
      } catch (bytes memory /* lowLevelData */) {
        hasLpData = false;
      }
    }
  }

  /**
   * @dev deposit and extend duration in one call
   */
  function deposit(uint256 amount_, uint40 newUnlockTime_) external onlyOwner transferLocked {
    if (newUnlockTime_ != 0) {
      require(
        newUnlockTime_ >= _unlockTime && newUnlockTime_ >= uint40(block.timestamp),
        "New unlock time must be a future time beyond the previous value"
      );
      _unlockTime = newUnlockTime_;
      emit Extended(_unlockTime);
    }

    if (amount_ != 0) {
      uint256 oldBalance = _balance();
      _token.transferFrom(_msgSender(), address(this), amount_);
      emit Deposited(_balance() - oldBalance);
    }
  }

  /**
   * @dev withdraw all of the deposited token
   */
  function withdraw() external onlyOwner transferLocked {
    require(uint40(block.timestamp) >= _unlockTime, "Wait until unlockTime to withdraw");

    _token.transfer(_owner(), _balance());

    emit Withdrew();
  }

  /**
   * @dev recovery function -
   * just in case this contract winds up with additional tokens (from dividends, etc).
   * attempting to withdraw the locked token will revert.
   */
  function withdrawToken(address address_) external onlyOwner transferLocked {
    require(address_ != address(_token), "Use 'withdraw' to withdraw the primary locked token");

    IERC20 theToken = IERC20(address_);
    theToken.transfer(_owner(), theToken.balanceOf(address(this)));
  }

  /**
   * @dev recovery function -
   * just in case this contract winds up with eth in it (from dividends etc)
   */
  function withdrawEth() external onlyOwner transferLocked {
    address payable receiver = payable(_owner());
    receiver.transfer(address(this).balance);
  }

  function _transferOwnership(address newOwner_) override internal onlyOwner {
    address previousOwner = _owner();
    super._transferOwnership(newOwner_);

    // we need to notify the manager contract that we transferred
    // ownership, so that the new owner is searchable.
    _manager.notifyLockerOwnerChange(_id, newOwner_, previousOwner, _createdBy);
  }

  receive() external payable {
    // we need this function to receive eth,
    // which might happen from dividend tokens.
    // use `withdrawEth` to remove eth from the contract.
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;
  function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;

  function initialize(address, address) external;
}

interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IERC20 } from "./library/IERC20.sol";
import { IUniswapV2Pair } from "./library/Dex.sol";

library Util {
  /**
   * @dev retrieves basic information about a token, including sender balance
   */
  function getTokenData(address address_) external view returns (
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 totalSupply,
    uint256 balance
  ){
    IERC20 _token = IERC20(address_);

    name = _token.name();
    symbol = _token.symbol();
    decimals = _token.decimals();
    totalSupply = _token.totalSupply();
    balance = _token.balanceOf(msg.sender);
  }

  /**
   * @dev this throws an error on false, instead of returning false,
   * but can still be used the same way on frontend.
   */
  function isLpToken(address address_) external view returns (bool) {
    IUniswapV2Pair pair = IUniswapV2Pair(address_);

    try pair.token0() returns (address tokenAddress_) {
      // any address returned successfully should be valid?
      // but we might as well check that it's not 0
      return tokenAddress_ != address(0);
    } catch Error(string memory /* reason */) {
      return false;
    } catch (bytes memory /* lowLevelData */) {
      return false;
    }
  }

  /**
   * @dev this function will revert the transaction if it's called
   * on a token that isn't an LP token. so, it's recommended to be
   * sure that it's being called on an LP token, or expect the error.
   */
  function getLpData(address address_) external view returns (
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  ) {
    IUniswapV2Pair _pair = IUniswapV2Pair(address_);

    token0 = _pair.token0();
    token1 = _pair.token1();

    balance0 = IERC20(token0).balanceOf(address(_pair));
    balance1 = IERC20(token1).balanceOf(address(_pair));

    price0 = _pair.price0CumulativeLast();
    price1 = _pair.price1CumulativeLast();
  }
}