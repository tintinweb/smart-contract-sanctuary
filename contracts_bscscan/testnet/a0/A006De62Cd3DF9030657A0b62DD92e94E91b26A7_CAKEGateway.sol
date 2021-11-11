// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IYieldSource.sol";
import "./../priceFeeds/ChainlinkPriceFeed.sol";
import "./../interfaces/IGateway.sol";
import "../interfaces/IChainlinkPriceFeed.sol";

contract CAKEGateway is OwnableUpgradeable {
    uint256 constant public UINT256_MAX = 2**256 - 1;
    address public lottery;
    IYieldSource public yieldSource;
    IERC20 public erc20;
    address public priceFeed;

    event ChangeLottery(address _oldLottery, address _newLottery);
    event ChangeYieldSource(address _oldYieldSource, address _newYieldSource);
    event ChangePriceFeed(address _oldPriceFeed, address _newPriceFeed);
    

    modifier onlyLottery() {
        require(_msgSender() == lottery, "CAKEGateway: No permission");
        _;
    }

    modifier onlyManager() {
        require(_msgSender() == owner() || _msgSender() == lottery, "CAKEGateway: No permission");
        _;
    }
    function initialize(address _lottery, IYieldSource _yieldSource, address _cake, address _priceFeed) public initializer {
        lottery = _lottery;
        erc20 = IERC20(_cake);
        yieldSource = _yieldSource;
        priceFeed = _priceFeed;
        __Ownable_init();
        _giveAllowances();
    }
    function stakeOnBalance() public {
        uint _balance = erc20.balanceOf(address(this));
        if(_balance > 0) {
            yieldSource.enterStaking(_balance);
        }
    }
    function harvest(address _prizePool, uint _systemFeePercent) public onlyLottery {
        uint _balance = erc20.balanceOf(address(this));
        uint pending = yieldSource.pendingCake(0, address(this));
        uint _fee = _systemFeePercent * pending / 10000;
        yieldSource.enterStaking(_balance + pending - _fee);
        erc20.transfer(_prizePool, _fee);
    }
    function deposit(address _from, uint _amount) public onlyLottery {
        require(erc20.transferFrom(_from, address(this), _amount));
        uint pending = yieldSource.pendingCake(0, address(this));
        yieldSource.enterStaking(_amount + pending);
    }
    function _withdraw(uint _amount) public onlyManager {
        yieldSource.leaveStaking(_amount);
    }
    function withdraw(address _account, uint _amount, address _prizePool, uint _penaltyFee) public onlyManager {
        uint stakingAmount;
        (stakingAmount,) = yieldSource.userInfo(0, address(this));
        uint wdAmount = _amount < stakingAmount ? _amount: stakingAmount;
        _withdraw(wdAmount + _penaltyFee);
        erc20.transfer(_account, _amount);

        if(_penaltyFee > 0) erc20.transfer(_prizePool, _penaltyFee);
        stakeOnBalance();
    }
    function upgrade(address newGateway) public onlyOwner {
        uint _balance = erc20.balanceOf(address(this));
        erc20.approve(newGateway, _balance);
        IGateway _newGateway = IGateway(newGateway);
        _newGateway.deposit(address(this), _balance);
    }
    function getTotalLock() public view returns(uint) {
        uint pending = yieldSource.pendingCake(0, address(this));
        uint amount;
        (amount,) = yieldSource.userInfo(0, address(this));
        return pending + amount;
    }
    function getTokenPrice(uint _erc20Amount) public view returns(uint) {
        return _erc20Amount * IChainlinkPriceFeed(priceFeed).getPrice(address(erc20)) / 1 ether;
    }
    // Pauses deposits and withdraws all funds from third party systems.
    function panic() external onlyOwner {
        yieldSource.emergencyWithdraw(0);
    }

    function removeAllowances() public onlyOwner {
        _removeAllowances();
    }

    function giveAllowances() external onlyOwner {
        _giveAllowances();
        stakeOnBalance();
    }

    function _giveAllowances() internal {
        erc20.approve(address(yieldSource), UINT256_MAX);
    }

    function _removeAllowances() internal {
        erc20.approve(address(yieldSource), 0);
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {
        require(_token != erc20, "!safe");

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
    function setLottery(address _lottery) public onlyOwner {
        require(_lottery != address(0), "CAKEGateway: _lottery must not be zero address");
        emit ChangeLottery(lottery, _lottery);
        lottery = _lottery;
    }
    function setYieldSource(address _yieldSource) public onlyOwner {
        require(_yieldSource != address(0), "CAKEGateway: _yieldSource must not be zero address");
        emit ChangeYieldSource(address(yieldSource), _yieldSource);
        yieldSource = IYieldSource(_yieldSource);
    }
    function setPriceFeed(address _priceFeed) public onlyOwner {
        require(_priceFeed != address(0), "CAKEGateway: _priceFeed must not be zero address");
        emit ChangePriceFeed(priceFeed, _priceFeed);
        priceFeed = _priceFeed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYieldSource {
    function deposit(uint _poolId, uint _amount) external;
    function withdraw(uint _poolId, uint _amount) external;
    function enterStaking(uint _amount) external;
    function leaveStaking(uint _amount) external;
    function emergencyWithdraw(uint _pid) external;
    function poolInfo(uint _poolId) external view returns (IERC20 lpToken, uint allocPoint, uint lastRewardBlock, uint accALIPerShare);
    function userInfo(uint _pid, address _user) external view returns (uint amount, uint rewardDebt);
    function pendingALI(uint _pid, address _user) external view returns (uint);
    function pendingCake(uint _pid, address _user) external view returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChainlinkPriceFeed {
    function getPrice(address _token) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGateway {
    function deposit(address _from, uint _amount) external;
    function withdraw(address _account, uint _amount, address _prizePool, uint _penaltyFee) external;
    function getTotalLock() external view returns (uint);
    function getTokenPrice(uint _erc20Amount) external view returns (uint);
    function harvest(address _prizePool, uint _systemFeePercent) external;
    function erc20() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IPair {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;
interface IRouter {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IChainlinkPriceFeed.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IPair.sol";


    /*
    * @title This contract to get a token price from Chainlink
	*   https://docs.chain.link/docs/binance-smart-chain-addresses/
    */

contract ChainlinkPriceFeed is IChainlinkPriceFeed, OwnableUpgradeable {

	mapping(address => address) public tokenToProxy;

    function initialize(address _cake, address _cakeProxy) public initializer {
        __Ownable_init();
        require(owner() != address(0), "ChainlinkPriceFeed: owner must be set");
        tokenToProxy[_cake] = _cakeProxy;
    }
	/*
     * @title Return the latest price on mantissa form. 
     *  Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is: 5100000000000000000
     * @notice The price from Chainlink has 8 decimals for a pair with USD (scaled by 10 ** 8).
     *  The price return int type because some prices can be negative (like oil futures price).
     */
    function getPrice(address _token) public override view returns (uint) {
        address proxy = tokenToProxy[_token];
        require(proxy != address(0), "ChainlinkPriceFeed: The proxy of _token is not set");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(proxy);
        ( ,int price, , ,) = priceFeed.latestRoundData();
        uint mantissaPrice = price <= 0 ? 0 : uint(price) * 10 ** 10;
        return mantissaPrice;
    }
    
    function setProxy(address _token, address _proxy) public onlyOwner {
        require(_token != address(0), "ChainlinkPriceFeed: The _token must not be zero address");
        tokenToProxy[_token] = _proxy;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}