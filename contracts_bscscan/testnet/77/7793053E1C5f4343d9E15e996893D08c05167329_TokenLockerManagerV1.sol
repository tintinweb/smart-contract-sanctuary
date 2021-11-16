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

import { Ownable } from "./Ownable.sol";
import { IERC20 } from "./library/IERC20.sol";
import { TokenLockerV1 } from "./TokenLockerV1.sol";

contract TokenLockerManagerV1 is Ownable {
  event TokenLockerCreated(
    uint40 id,
    address indexed owner,
    address indexed tokenAddress,
    uint256 amount,
    uint40 unlockTime
  );

  constructor() Ownable(msg.sender) {
    _creationEnabled = true;
  }


  bool private _creationEnabled;

  uint40 private _tokenLockerCount;

  /** @dev main mapping for lock data */
  mapping(uint40 => TokenLockerV1) private _tokenLockers;

  /** @dev this mapping makes it possible to search for locks */
  mapping(address => uint40[]) private _tokenLockersForAddress;

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
  function setCreationEnabled(bool value_) external onlyOwner() {
    _creationEnabled = value_;
  }

  function createTokenLocker(
    address tokenAddress_,
    uint256 amount_,
    uint40 unlockTime_
  ) external {
    require(_creationEnabled, "Locker creation is disabled");

    uint40 id = _tokenLockerCount++;
    _tokenLockers[id] = new TokenLockerV1(id, msg.sender, tokenAddress_, unlockTime_);

    IERC20 token = IERC20(tokenAddress_);
    token.transferFrom(msg.sender, address(_tokenLockers[id]), amount_);

    // add the creator to the token locker mapping, so it's
    // able to be searched.
    // NOTE that if the ownership is transferred, the new
    // owner will NOT be searchable with this setup.
    _tokenLockersForAddress[msg.sender].push(id);

    // add the locked token to the token lockers mapping
    _tokenLockersForAddress[tokenAddress_].push(id);
    // add the locker contract to this mapping as well, so it's
    // searchable in the same way as tokens within the locker.
    _tokenLockersForAddress[address(_tokenLockers[id])].push(id);

    // if this is an lp token, also add the paired tokens to the mapping
    {
      (bool hasLpData,,address token0Address,address token1Address,,,,) = _tokenLockers[id].getLpData();
      if (hasLpData) {
        _tokenLockersForAddress[token0Address].push(id);
        _tokenLockersForAddress[token1Address].push(id);
      }
    }

    emit TokenLockerCreated(id, msg.sender, tokenAddress_, _tokenLockers[id].balance(), unlockTime_);
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
    uint256 tokenBalance,
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

/**
 * @title Ownable
 * 
 * parent for ownable contracts
 */
abstract contract Ownable {
  constructor(address owner_) {
    _owner = owner_;
    emit OwnershipTransferred(address(0), _owner);
  }

  address private _owner;

  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(_owner == msg.sender, "Only the owner can execute this function");
    _;
  }

  function _getOwner() internal view returns (address) {
    return _owner;
  }

  function getOwner() external view returns (address) {
    return _owner;
  }

  function _transferOwnership(address newOwner_) private onlyOwner() {
    // keep track of old owner for event
    address oldOwner = _owner;

    // set the new owner
    _owner = newOwner_;

    // emit event about ownership change
    emit OwnershipTransferred(oldOwner, _owner);
  }

  function transferOwnership(address newOwner_) external onlyOwner() {
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

import { Ownable } from "./Ownable.sol";
import { IUniswapV2Pair } from "./library/Dex.sol";
import { IERC20 } from "./library/IERC20.sol";
import { Util } from "./Util.sol";

contract TokenLockerV1 is Ownable {
  event Extended(uint40 newUnlockTime);
  event Deposited(uint256 amount);
  event Withdrew();

  constructor(uint40 id_, address owner_, address tokenAddress_, uint40 unlockTime_) Ownable(owner_) {
    require(unlockTime_ > uint40(block.timestamp), "Unlock time must be in the future");

    _id = id_;
    _token = IERC20(tokenAddress_);
    _createdBy = owner_;
    _createdAt = uint40(block.timestamp);
    _unlockTime = unlockTime_;

    try Util.isLpToken(tokenAddress_) returns (bool isLpToken_) {
      _isLpToken = isLpToken_;
    } catch Error(string memory /* reason */) {
      _isLpToken = false;
    } catch (bytes memory /* lowLevelData */) {
      _isLpToken = false;
    }
  }

  bool private _isLpToken;
  uint40 private _id;
  IERC20 private _token;
  address private _createdBy;
  uint40 private _createdAt;
  uint40 private _unlockTime;

  function _balance() private view returns (uint256) {
    return _token.balanceOf(address(this));
  }

  function balance() external view returns (uint256) {
    return _balance();
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
    uint256 tokenBalance,
    uint256 totalSupply
  ){
    isLpToken = _isLpToken;
    id = _id;
    contractAddress = address(this);
    owner = _getOwner();
    token = address(_token);
    createdBy = _createdBy;
    createdAt = _createdAt;
    unlockTime = _unlockTime;
    tokenBalance = _balance();
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
  function deposit(uint256 amount_, uint40 newUnlockTime_) external onlyOwner() {
    if (amount_ != 0) {
      uint256 oldBalance = _balance();
      _token.transferFrom(msg.sender, address(this), amount_);
      emit Deposited(_balance() - oldBalance);
    }

    if (newUnlockTime_ != 0) {
      require(newUnlockTime_ >= _unlockTime, "New unlock time must be beyond the previous");
      require(newUnlockTime_ >= uint40(block.timestamp), "New unlock time must be in the future");
      _unlockTime = newUnlockTime_;
      emit Extended(_unlockTime);
    }
  }

  /**
   * @dev withdraw all of the deposited token
   */
  function withdraw() external onlyOwner() {
    require(uint40(block.timestamp) >= _unlockTime, "Wait until unlockTime to withdraw");

    _token.transfer(_getOwner(), _balance());

    emit Withdrew();
  }

  /**
   * @dev recovery function -
   * just in case this contract winds up with additional tokens (from dividends, etc).
   * attempting to withdraw the locked token will revert.
   */
  function withdrawToken(address address_) external onlyOwner() {
    require(address_ != address(_token), "Use 'withdraw' to withdraw the primary locked token");

    IERC20 theToken = IERC20(address_);
    theToken.transfer(_getOwner(), theToken.balanceOf(address(this)));
  }

  /**
   * @dev recovery function -
   * just in case this contract winds up with eth in it (from dividends etc)
   */
  function withdrawEth() external onlyOwner() {
    address payable receiver = payable(_getOwner());
    receiver.transfer(address(this).balance);
  }

  receive() external payable {
    // we need this function to receive eth,
    // which might happen from dividend tokens.
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
   * @dev like isLpToken, this function also errors when it's called
   * on something other than an lp token, which makes isLpToken kind of pointless
   * since we can call this and assume it's not an lp token if it throws an error.
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

    IERC20 erc0 = IERC20(token0);
    IERC20 erc1 = IERC20(token1);

    balance0 = erc0.balanceOf(address(_pair));
    balance1 = erc1.balanceOf(address(_pair));

    price0 = _pair.price0CumulativeLast();
    price1 = _pair.price1CumulativeLast();
  }
}