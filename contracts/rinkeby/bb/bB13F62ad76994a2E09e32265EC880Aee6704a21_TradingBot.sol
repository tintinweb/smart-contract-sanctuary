pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IOneSplit.sol";
import "./interfaces/IWETH9.sol";
import "./DyDxFlashloan.sol";

contract TradingBot is
    DyDxFlashloan // Where the actual contract for the trading bot starts. anything above that are just libraries.
{
    using SafeERC20 for IERC20;

    uint256 public loan;

    // Addresses
    address payable public owner;

    // OneSplit Config
    address public oneSplitAddress; // Mainnet: (v1, stable) 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
    uint256 public parts = 10;
    uint256 public flags = 0;

    // ZRX Config
    address public zrxExchangeAddress; // Mainnet 0x61935CbDd02287B511119DDb11Aeb42F1593b7Ef;
    address public zrxERC20ProxyAddress; // Mainnet 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF
    address public zrxStakingProxy; // Mainnet 0xa26e80e7Dea86279c6d778D702Cc413E6CFfA777; // Fee collector

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner!");
        _;
    }

    // Allow the contract to receive Ether
    function() external payable {}

    constructor(
        address _oneSplitAddress,
        address _zrxExchangeAddress,
        address _zrxERC20ProxyAddress,
        address _zrxStakingProxy,
        address _weth,
        address _sai,
        address _usdc,
        address _dai
    )
        public
        payable
        DyDxFlashloan(
          _weth,
          _sai,
          _usdc,
          _dai
        )
    {
        _getWeth();
        _approveWeth(msg.value);
        owner = msg.sender;
        oneSplitAddress = _oneSplitAddress;
        zrxExchangeAddress = _zrxExchangeAddress;
        zrxERC20ProxyAddress = _zrxERC20ProxyAddress;
        zrxStakingProxy = _zrxStakingProxy;
    }

    function getFlashloan(
        address flashToken,
        uint256 flashAmount,
        address arbToken,
        bytes calldata zrxData,
        uint256 oneSplitMinReturn,
        uint256[] calldata oneSplitDistribution
    ) external payable onlyOwner {
        uint256 balanceBefore = IERC20(flashToken).balanceOf(address(this));
        bytes memory data = abi.encode(
            flashToken,
            flashAmount,
            balanceBefore,
            arbToken,
            zrxData,
            oneSplitMinReturn,
            oneSplitDistribution
        );
        flashloan(flashToken, flashAmount, data); // execution goes to `callFunction`

        // and this point we have succefully paid the dept
    }

    function callFunction(
        address, /* sender */
        Info calldata, /* accountInfo */
        bytes calldata data
    ) external onlyPool {
        (
            address flashToken,
            uint256 flashAmount,
            uint256 balanceBefore,
            address arbToken,
            bytes memory zrxData,
            uint256 oneSplitMinReturn,
            uint256[] memory oneSplitDistribution
        ) = abi.decode(
                data,
                (address, uint256, uint256, address, bytes, uint256, uint256[])
            );
        uint256 balanceAfter = IERC20(flashToken).balanceOf(address(this));
        require(
            balanceAfter - balanceBefore == flashAmount,
            "contract did not get the loan"
        );
        loan = balanceAfter;

        // do whatever you want with the money
        // the dept will be automatically withdrawn from this contract at the end of execution
        _arb(
            flashToken,
            arbToken,
            flashAmount,
            zrxData,
            oneSplitMinReturn,
            oneSplitDistribution
        );
    }

    function arb(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        bytes memory _0xData,
        uint256 _1SplitMinReturn,
        uint256[] memory _1SplitDistribution
    ) public payable onlyOwner {
        _arb(
            _fromToken,
            _toToken,
            _fromAmount,
            _0xData,
            _1SplitMinReturn,
            _1SplitDistribution
        );
    }

    function _arb(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        bytes memory _0xData,
        uint256 _1SplitMinReturn,
        uint256[] memory _1SplitDistribution
    ) internal {
        // Track original balance
        uint256 _startBalance = IERC20(_fromToken).balanceOf(address(this));

        // Perform the arb trade
        _trade(
            _fromToken,
            _toToken,
            _fromAmount,
            _0xData,
            _1SplitMinReturn,
            _1SplitDistribution
        );

        // Track result balance
        uint256 _endBalance = IERC20(_fromToken).balanceOf(address(this));

        // Require that arbitrage is profitable
        require(
            _endBalance > _startBalance,
            "End balance must exceed start balance."
        );
    }

    function trade(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        bytes memory _0xData,
        uint256 _1SplitMinReturn,
        uint256[] memory _1SplitDistribution
    ) public payable onlyOwner {
        _trade(
            _fromToken,
            _toToken,
            _fromAmount,
            _0xData,
            _1SplitMinReturn,
            _1SplitDistribution
        );
    }

    function _trade(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        bytes memory _0xData,
        uint256 _1SplitMinReturn,
        uint256[] memory _1SplitDistribution
    ) internal {
        // Track the balance of the token RECEIVED from the trade
        uint256 _beforeBalance = IERC20(_toToken).balanceOf(address(this));

        // Swap on 0x: give _fromToken, receive _toToken
        _zrxSwap(_fromToken, _fromAmount, _0xData);

        // Calculate the how much of the token we received
        uint256 _afterBalance = IERC20(_toToken).balanceOf(address(this));

        // Read _toToken balance after swap
        uint256 _toAmount = _afterBalance - _beforeBalance;

        // Swap on 1Split: give _toToken, receive _fromToken
        _oneSplitSwap(
            _toToken,
            _fromToken,
            _toAmount,
            _1SplitMinReturn,
            _1SplitDistribution
        );
    }

    function zrxSwap(
        address _from,
        uint256 _amount,
        bytes memory _calldataHexString
    ) public payable onlyOwner {
        _zrxSwap(_from, _amount, _calldataHexString);
    }

    function _zrxSwap(
        address _from,
        uint256 _amount,
        bytes memory _calldataHexString
    ) internal {
        // Approve tokens
        IERC20 _fromIERC20 = IERC20(_from);
        _fromIERC20.approve(zrxERC20ProxyAddress, _amount);

        // Swap tokens
        address(zrxExchangeAddress).call.value(msg.value)(_calldataHexString);

        // Reset approval
        _fromIERC20.approve(zrxERC20ProxyAddress, 0);
    }

    function oneSplitSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minReturn,
        uint256[] memory _distribution
    ) public payable onlyOwner {
        _oneSplitSwap(_from, _to, _amount, _minReturn, _distribution);
    }

    function _oneSplitSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minReturn,
        uint256[] memory _distribution
    ) internal {
        // Setup contracts
        IERC20 _fromIERC20 = IERC20(_from);
        IERC20 _toIERC20 = IERC20(_to);
        IOneSplit _oneSplitContract = IOneSplit(oneSplitAddress);

        // Approve tokens
        _fromIERC20.approve(oneSplitAddress, _amount);

        // Swap tokens: give _from, get _to
        _oneSplitContract.swap(
            _fromIERC20,
            _toIERC20,
            _amount,
            _minReturn,
            _distribution,
            flags
        );

        // Reset approval
        _fromIERC20.approve(oneSplitAddress, 0);
    }

    function getWeth() public payable onlyOwner {
        _getWeth();
    }

    function _getWeth() internal {
        IWETH9(weth).deposit();
    }

    function approveWeth(uint256 _amount) public onlyOwner {
        _approveWeth(_amount);
    }

    function _approveWeth(uint256 _amount) internal {
        IERC20 wethInstance = IERC20(weth);
        wethInstance.approve(zrxStakingProxy, 0);
        wethInstance.approve(zrxStakingProxy, _amount); // approves the 0x staking proxy - the proxy is the fee collector for 0x, i.e. we will use weth in order to pay for trading fees
    }

    // KEEP THIS FUNCTION IN CASE THE CONTRACT RECEIVES TOKENS!
    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).safeTransfer(owner, balance);
    }

    // KEEP THIS FUNCTION IN CASE THE CONTRACT KEEPS LEFTOVER ETHER!
    function withdrawEther() public onlyOwner {
        address self = address(this); // workaround for a possible solidity bug
        uint256 balance = self.balance;
        address(owner).transfer(balance);
    }
}

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

interface Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (externally)
        Sell, // sell an amount of some token (externally)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei // the amount is denominated in wei
    }

    enum AssetReference {
        Delta // the amount is given as a delta from the current value
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;

interface IWETH9 {
    function deposit() external payable;
}

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IOneSplit {
    // interface for 1inch exchange.
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    ) public view returns (uint256 returnAmount, uint256[] memory distribution);

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 disableFlags
    ) public payable;
}

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Structs.sol";

contract DyDxPool is Structs {
    function getAccountWei(Info memory account, uint256 marketId)
        public
        view
        returns (Wei memory);

    function operate(Info[] memory, ActionArgs[] memory) public;
}

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/Structs.sol";
import "./interfaces/DyDxPool.sol";

contract DyDxFlashloan is Structs {
    DyDxPool public pool; // Mainnet - DyDxPool(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    address public weth; // Mainnet - 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public sai; // Mainnet - 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public usdc; // Mainnet - 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public dai; // Mainnet - 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    mapping(address => uint256) public currencies;

    constructor(
        address _weth,
        address _sai,
        address _usdc,
        address _dai
    ) public {
        weth = _weth;
        sai = _sai;
        usdc = _usdc;
        dai = _dai;
        currencies[_weth] = 1;
        currencies[_sai] = 2;
        currencies[_usdc] = 3;
        currencies[_dai] = 4;
    }

    modifier onlyPool() {
        require(
            msg.sender == address(pool),
            "FlashLoan: could be called by DyDx pool only"
        );
        _;
    }

    function tokenToMarketId(address token) public view returns (uint256) {
        uint256 marketId = currencies[token];
        require(marketId != 0, "FlashLoan: Unsupported token");
        return marketId - 1;
    }

    // the DyDx will call `callFunction(address sender, Info memory accountInfo, bytes memory data) public` after during `operate` call
    function flashloan(
        address token,
        uint256 amount,
        bytes memory data
    ) internal {
        IERC20 tokenInstance = IERC20(token);
        tokenInstance.approve(address(pool), 0);
        tokenInstance.approve(address(pool), amount + 1);
        Info[] memory infos = new Info[](1);
        ActionArgs[] memory args = new ActionArgs[](3);

        infos[0] = Info(address(this), 0);

        AssetAmount memory wamt = AssetAmount(
            false,
            AssetDenomination.Wei,
            AssetReference.Delta,
            amount
        );
        ActionArgs memory withdraw;
        withdraw.actionType = ActionType.Withdraw;
        withdraw.accountId = 0;
        withdraw.amount = wamt;
        withdraw.primaryMarketId = tokenToMarketId(token);
        withdraw.otherAddress = address(this);

        args[0] = withdraw;

        ActionArgs memory call;
        call.actionType = ActionType.Call;
        call.accountId = 0;
        call.otherAddress = address(this);
        call.data = data;

        args[1] = call;

        ActionArgs memory deposit;
        AssetAmount memory damt = AssetAmount(
            true,
            AssetDenomination.Wei,
            AssetReference.Delta,
            amount + 1
        );
        deposit.actionType = ActionType.Deposit;
        deposit.accountId = 0;
        deposit.amount = damt;
        deposit.primaryMarketId = tokenToMarketId(token);
        deposit.otherAddress = address(this);

        args[2] = deposit;

        pool.operate(infos, args);
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}