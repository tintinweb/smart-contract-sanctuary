/**
 *Submitted for verification at Etherscan.io on 2020-08-07
*/

pragma solidity ^0.5.16;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// import "../openzeppelin/upgrades/contracts/Initializable.sol";

// import "../openzeppelin/upgrades/contracts/Initializable.sol";

contract OwnableUpgradable is Initializable {
    address payable public owner;
    address payable internal newOwnerCandidate;

    modifier onlyOwner {
        require(msg.sender == owner, "Permission denied");
        _;
    }

    // ** INITIALIZERS – Constructors for Upgradable contracts **

    function initialize() public initializer {
        owner = msg.sender;
    }

    function initialize(address payable newOwner) public initializer {
        owner = newOwner;
    }

    function changeOwner(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate, "Permission denied");
        owner = newOwnerCandidate;
    }

    uint256[50] private ______gap;
}

contract AdminableUpgradable is Initializable, OwnableUpgradable {
    mapping(address => bool) public admins;

    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner ||
        admins[msg.sender], "Permission denied");
        _;
    }

    // Initializer – Constructor for Upgradable contracts
    function initialize() public initializer {
        OwnableUpgradable.initialize();  // Initialize Parent Contract
    }

    function initialize(address payable newOwner) public initializer {
        OwnableUpgradable.initialize(newOwner);  // Initialize Parent Contract
    }

    function setAdminPermission(address _admin, bool _status) public onlyOwner {
        admins[_admin] = _status;
    }

    function setAdminPermission(address[] memory _admins, bool _status) public onlyOwner {
        for (uint i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = _status;
        }
    }

    uint256[50] private ______gap;
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y, uint base) internal pure returns (uint z) {
        z = add(mul(x, y), base / 2) / base;
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    /*function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }*/
}

interface IController {
    function owner() view external returns (address);
}

interface IDfFinanceDeposits {
    function createStrategyDeposit(uint256 amountDAI, uint256 flashLoanAmount, address dfWallet) external returns (address);
    function createStrategyDepositFlashloan(uint256 amountDAI, uint256 flashLoanAmount, address dfWallet) external returns (address);
    function createStrategyDepositMulti(uint256 amountDAI, uint256 flashLoanAmount, uint32 times) external;

    function closeDepositDAI(address dfWallet, uint256 minDAIForCompound, bytes calldata data) external;
    function closeDepositFlashloan(address dfWallet, uint256 minUsdForComp, bytes calldata data) external;

    function partiallyCloseDepositDAI(address dfWallet, address tokenReceiver, uint256 amountDAI) external;
    function partiallyCloseDepositDAIFlashloan(address dfWallet, address tokenReceiver, uint256 amountDAI) external;

    function claimComps(address dfWallet, uint256 minDAIForCompound, bytes calldata data) external returns(uint256);
    function isClosed(address addrWallet) view external returns(bool);
}

interface IToken {
    function decimals() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function deposit() external payable;
    function withdraw(uint amount) external;
}

interface IDfDepositToken {

    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;

    function balanceOfAt(address account, uint256 snapshotId) external view returns(uint256);
    function totalSupplyAt(uint256 snapshotId) external view returns(uint256);
    function snapshot() external returns(uint256);

}

contract ConstantAddresses {
    address public constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant COMPOUND_ORACLE = 0x1D8aEdc9E924730DD3f9641CDb4D1B92B848b4bd;

    //    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    //    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    //    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    //    address public constant CUSDC_ADDRESS = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;

    //    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant CDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    address public constant COMP_ADDRESS = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
}

// import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
// import "./SafeMath.sol";

// import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

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

// import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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

    function safeTransfer(IToken token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IToken token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IToken token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IToken token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IToken token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IToken token, bytes memory data) private {
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

library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IToken;

    IToken private constant ZERO_ADDRESS = IToken(0x0000000000000000000000000000000000000000);
    IToken private constant ETH_ADDRESS = IToken(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IToken token, address to, uint256 amount) internal {
        universalTransfer(token, to, amount, false);
    }

    function universalTransfer(IToken token, address to, uint256 amount, bool mayFail) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            if (mayFail) {
                return address(uint160(to)).send(amount);
            } else {
                address(uint160(to)).transfer(amount);
                return true;
            }
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalApprove(IToken token, address to, uint256 amount) internal {
        if (token != ZERO_ADDRESS && token != ETH_ADDRESS) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(IToken token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            require(from == msg.sender && msg.value >= amount, "msg.value is zero");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(uint256(msg.value).sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IToken token, address who) internal view returns (uint256) {
        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}

contract DfTokenizedDeposit is
Initializable,
AdminableUpgradable,
DSMath,
ConstantAddresses
{
    using UniversalERC20 for IToken;

    struct ProfitData {
        uint64 blockNumber;
        uint64 compProfit; // div 1e12 (6 dec)
        uint64 usdtProfit;
    }

    ProfitData[] public profits;

    IDfDepositToken public token;
    address public dfWallet;

    // IDfFinanceDeposits public constant dfFinanceDeposits = IDfFinanceDeposits(0xCa0648C5b4Cea7D185E09FCc932F5B0179c95F17); // Kovan
    IDfFinanceDeposits public constant dfFinanceDeposits = IDfFinanceDeposits(0xFff9D7b0B6312ead0a1A993BF32f373449006F2F); // Mainnet

    mapping(address => uint64) public lastProfitDistIndex;

    address usdtExchanger;

    event CompSwap(uint256 timestamp, uint256 compPrice);
    event Profit(address indexed user, uint64 index, uint64 usdtProfit, uint64 compProfit);

    function initialize() public initializer {
        address payable curOwner = 0xdAE0aca4B9B38199408ffaB32562Bf7B3B0495fE;
        AdminableUpgradable.initialize(curOwner);  // Initialize Parent Contract

        IToken(DAI_ADDRESS).approve(address(dfFinanceDeposits), uint256(-1));
    }

    function createStrategyDeposit(
        uint256 amount, uint256 flashLoanAmount, IDfDepositToken attachedToken, bool withFlashloan
    ) public onlyOwner {
        require(token == IDfDepositToken(0x0));
        require(dfWallet == address(0x0));

        token = attachedToken;
        IToken(DAI_ADDRESS).transferFrom(msg.sender, address(this), amount);

        if (withFlashloan) {
            dfWallet = dfFinanceDeposits.createStrategyDepositFlashloan(amount, flashLoanAmount, address(0x0));
        } else {
            dfWallet = dfFinanceDeposits.createStrategyDeposit(amount, flashLoanAmount, address(0x0));
        }

        token.mint(msg.sender, amount);
    }

    function addStrategyDeposit(
        uint256 amount, uint256 flashLoanAmount, bool withFlashloan
    ) public onlyOwner {
        require(token != IDfDepositToken(0x0));
        require(dfWallet != address(0x0));
        IToken(DAI_ADDRESS).transferFrom(msg.sender, address(this), amount);

        if (withFlashloan) {
            dfFinanceDeposits.createStrategyDepositFlashloan(amount, flashLoanAmount, dfWallet);
        } else {
            dfFinanceDeposits.createStrategyDeposit(amount, flashLoanAmount, dfWallet);
        }

        token.mint(msg.sender, amount);
    }

    function addUserStrategyDeposit(uint256 amount) public {
        require(msg.sender == tx.origin);
        require(token != IDfDepositToken(0x0));
        require(dfWallet != address(0x0));
        IToken(DAI_ADDRESS).transferFrom(msg.sender, address(this), amount);
        dfFinanceDeposits.createStrategyDepositFlashloan(amount, amount * 290 / 100, dfWallet);
        token.mint(msg.sender, amount);
    }

    function closeStrategyDeposit(
        uint256 minUsdtForCompound, bytes memory data, bool withFlashloan
    ) public onlyOwner {
        require(dfWallet != address(0x0));
        uint256 compStartAmount = IToken(COMP_ADDRESS).balanceOf(address(this));

        if (withFlashloan) {
            dfFinanceDeposits.closeDepositFlashloan(dfWallet, minUsdtForCompound, data);
        } else {
            dfFinanceDeposits.closeDepositDAI(dfWallet, minUsdtForCompound, data);
        }

        uint256 compProfit = sub(IToken(COMP_ADDRESS).balanceOf(address(this)), compStartAmount);

        ProfitData memory p;
        p.blockNumber = uint64(block.number);
        p.compProfit = p.compProfit + uint64(compProfit / 1e12);
        p.usdtProfit = p.usdtProfit + uint64(minUsdtForCompound);
        token.snapshot();
        profits.push(p);
    }

    function burnTokens(uint256 amount, bool withFlashloan) public {
        require(msg.sender == tx.origin);
        token.burnFrom(msg.sender, amount);
        // is closed ?
        if (dfFinanceDeposits.isClosed(dfWallet)) {
            IToken(DAI_ADDRESS).transfer(msg.sender, amount);
        } else {
            if (withFlashloan) {
                dfFinanceDeposits.partiallyCloseDepositDAIFlashloan(dfWallet, msg.sender, amount);
            } else {
                dfFinanceDeposits.partiallyCloseDepositDAI(dfWallet, msg.sender, amount);
            }
        }
    }

    function calcUserProfit(address userAddress, uint256 max) public view returns(
        uint256 totalCompProfit, uint256 totalUsdtProfit, uint64 index
    ) {
        if (profits.length < max) max = profits.length;

        index = lastProfitDistIndex[userAddress];
        for(; index < max; index++) {
            ProfitData memory p = profits[index];
            uint256 balanceAtBlock = token.balanceOfAt(userAddress, index + 1);
            uint256 totalSupplyAt = token.totalSupplyAt(index + 1);
            uint256 profitUsdt = wdiv(wmul(uint256(p.usdtProfit), balanceAtBlock), totalSupplyAt);
            uint256 profitComp = wdiv(wmul(mul(uint256(p.compProfit), 1e12),balanceAtBlock), totalSupplyAt);
            totalUsdtProfit = add(totalUsdtProfit, profitUsdt);
            totalCompProfit = add(totalCompProfit, profitComp);
        }
    }

    function claimProfitFromMarkets(uint64 lastIndex, uint256 totalUsdtProfit1, uint8 v1, bytes32 r1, bytes32 s1, uint256 totalUsdtProfit2, uint8 v2, bytes32 r2, bytes32 s2) onlyOwner public {
        require(msg.sender == tx.origin);
        // 0xc37a700CB7c5c254dD581feF6F5768B1B705a5Bb is a system contract for fast buying dDAI tokens
        userClaimProfitOptimizedInternal(0xc37a700CB7c5c254dD581feF6F5768B1B705a5Bb, owner, lastIndex, totalUsdtProfit1, 0, v1, r1, s1);
        // 0x71d88D9A24125b61e580bB73D7C0b20F0E29902f is a system contract for fast selling dDAI tokens
        userClaimProfitOptimizedInternal(0x71d88D9A24125b61e580bB73D7C0b20F0E29902f, owner, lastIndex, totalUsdtProfit2, 0, v2, r2, s2);
    }

    function userClaimProfitOptimized(uint64 lastIndex, uint256 totalUsdtProfit, uint256 totalCompProfit, uint8 v, bytes32 r, bytes32 s) public {
        require(msg.sender == tx.origin);
        userClaimProfitOptimizedInternal(msg.sender, msg.sender, lastIndex, totalUsdtProfit, totalCompProfit, v, r, s);
    }

    // Internal function
    function userClaimProfitOptimizedInternal(address userAddress, address target, uint64 lastIndex, uint256 totalUsdtProfit, uint256 totalCompProfit, uint8 v, bytes32 r, bytes32 s) internal {
        // check signature
        bytes32 hash = sha256(abi.encodePacked(this, userAddress, lastIndex, totalUsdtProfit, totalCompProfit));
        address src = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s);
        require(admins[src] == true, "Access denied");

        require(lastProfitDistIndex[userAddress] < lastIndex);

        lastProfitDistIndex[userAddress] = lastIndex;

        if (totalUsdtProfit > 0) {
            IToken(USDT_ADDRESS).universalTransfer(target, totalUsdtProfit);
        }

        if (totalCompProfit > 0) {
            IToken(COMP_ADDRESS).transfer(target, totalCompProfit);
        }
    }

    function userClaimProfitAndSendToAddresses(uint64 max, address[] memory targets, uint256[] memory amounts) public {
        require(msg.sender == tx.origin);
        require(targets.length == amounts.length);

        uint64 index;
        uint256 totalCompProfit;
        uint256 totalUsdtProfit;
        (totalCompProfit, totalUsdtProfit, index) = calcUserProfit(msg.sender, max);

        lastProfitDistIndex[msg.sender] = index;

        if (totalCompProfit > 0) {
            IToken(COMP_ADDRESS).transfer(msg.sender, totalCompProfit);
        }

        for(uint16 i = 0; i < targets.length;i++) {
            totalUsdtProfit = sub(totalUsdtProfit, amounts[i]);
            IToken(USDT_ADDRESS).universalTransfer(targets[i], amounts[i]);
        }

        if (totalUsdtProfit > 0) {
            IToken(USDT_ADDRESS).universalTransfer(msg.sender, totalUsdtProfit);
        }
    }

    function userClaimProfit(uint64 max) public {
        require(msg.sender == tx.origin);

        uint64 index;
        uint256 totalCompProfit;
        uint256 totalUsdtProfit;
        (totalCompProfit, totalUsdtProfit, index) = calcUserProfit(msg.sender, max);

        lastProfitDistIndex[msg.sender] = index;

        if (totalUsdtProfit > 0) {
            IToken(USDT_ADDRESS).universalTransfer(msg.sender, totalUsdtProfit);
        }

        if (totalCompProfit > 0) {
            IToken(COMP_ADDRESS).transfer(msg.sender, totalCompProfit);
        }
    }

    function setUSDTExchangeAddress(address _newAddress) public onlyOwnerOrAdmin {
        usdtExchanger = _newAddress;
    }

    function adminClaimProfitAndInternalSwapToUSDT(uint256 _compPriceInUsdt) public onlyOwnerOrAdmin {
        // Claim comps without exchange
        uint256 amountComps = dfFinanceDeposits.claimComps(dfWallet, 0, bytes(""));
        uint256 amountUsdt = mul(amountComps, _compPriceInUsdt) / 10**18; // COMP to USDT

        IToken(USDT_ADDRESS).universalTransferFrom(usdtExchanger, address(this), amountUsdt);
        IToken(COMP_ADDRESS).transfer(usdtExchanger, amountComps);

        ProfitData memory p;
        p.blockNumber = uint64(block.number);
        p.usdtProfit = p.usdtProfit + uint64(amountUsdt);
        profits.push(p);

        token.snapshot();

        emit CompSwap(block.timestamp, _compPriceInUsdt);
    }

    function adminClaimProfit(uint256 minUsdtForCompound, bytes memory data) public onlyOwnerOrAdmin {
        uint256 amount = dfFinanceDeposits.claimComps(dfWallet, minUsdtForCompound, data);
        ProfitData memory p;
        p.blockNumber = uint64(block.number);
        if (minUsdtForCompound == 0) {
            p.compProfit = p.compProfit + uint64(amount / 1e12);
        } else {
            p.usdtProfit = p.usdtProfit + uint64(amount);
        }
        profits.push(p);

        token.snapshot();
    }

}