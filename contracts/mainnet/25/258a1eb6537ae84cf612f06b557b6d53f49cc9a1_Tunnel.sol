// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol


pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin\contracts\math\SafeMath.sol


pragma solidity ^0.6.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin\contracts\utils\Pausable.sol


pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts\interface\IAddressResolver.sol


pragma solidity ^0.6.12;

interface IAddressResolver {
    
    function key2address(bytes32 key) external view returns(address);
    function address2key(address addr) external view returns(bytes32);
    function requireAndKey2Address(bytes32 name, string calldata reason) external view returns(address);

    function setAddress(bytes32 key, address addr) external;
    function setMultiAddress(bytes32[] memory keys, address[] memory addrs) external;
}

// File: contracts\interface\ITunnel.sol


pragma solidity ^0.6.12;

interface ITunnel {
    function pledge(address account, uint amount) external;
    function redeem(address account, uint amount) external;
    function issue(address account, uint amount) external;
    function burn(address account, uint amount, string memory assetAddress) external;
    function totalValuePledge() external view  returns(uint);
    function canIssueAmount() external view returns(uint);
    function oTokenKey() external view returns(bytes32);
}

// File: contracts\ParamBook.sol


pragma solidity ^0.6.12;


contract ParamBook is Ownable {
    mapping(bytes32 => uint256) public params;
    mapping(bytes32 => mapping(bytes32 => uint256)) public params2;

    function setParams(bytes32 name, uint256 value) public onlyOwner {
        params[name] = value;
    }

    function setMultiParams(bytes32[] memory names, uint[] memory values) public onlyOwner {
        require(names.length == values.length, "ParamBook::setMultiParams:param length not match");
        for (uint i=0; i < names.length; i++ ) {
            params[names[i]] = values[i];
        }
    }

    function setParams2(
        bytes32 name1,
        bytes32 name2,
        uint256 value
    ) public onlyOwner {
        params2[name1][name2] = value;
    }

    function setMultiParams2(bytes32[] memory names1, bytes32[] memory names2, uint[] memory values) public onlyOwner {
        require(names1.length == names2.length, "ParamBook::setMultiParams2:param length not match");
        require(names1.length == values.length, "ParamBook::setMultiParams2:param length not match");
        for(uint i=0; i < names1.length; i++) {
            params2[names1[i]][names2[i]] = values[i];
        }
    }
}

// File: contracts\lib\SafeDecimalMath.sol

pragma solidity ^0.6.8;

// Libraries


// https://docs.synthetix.io/contracts/SafeDecimalMath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

// File: contracts\interface\IBoringDAO.sol


pragma solidity ^0.6.12;

interface IBoringDAO {
    // function openTunnel(bytes32 tunnelKey) external;

    function pledge(bytes32 tunnelKey, uint _amount) external;
    function redeem(bytes32 tunnelKey, uint _amount) external;

    function approveMint(bytes32 tunnelKey, string memory _txid, uint _amount, address account, string memory assetAddress) external;
    function burnBToken(bytes32 _tunnelKey, uint _amount, string memory assetAddress) external;

    function getTrustee(uint index) external view returns(address);
    function getTrusteeCount() external view returns(uint);
    function getRandomTrustee() external view returns (address);

}

// File: contracts\interface\IOracle.sol

pragma solidity ^0.6.12;

interface IOracle {
    
    function setPrice(bytes32 _symbol, uint _price) external;
    function getPrice(bytes32 _symbol) external view returns (uint);
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


pragma solidity ^0.6.0;

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

// File: contracts\interface\IFeePool.sol


pragma solidity ^0.6.12;

interface IFeePool {

    function earned(address account) external view returns(uint, uint);

    function notifyBORFeeAmount(uint amount) external;
    function notifyBTokenFeeAmount(uint amount) external;
    function notifyPTokenAmount(address account, uint amount) external;
    
    function withdraw(address account, uint amount) external;

}

// File: contracts\interface\IStakingRewardsFactory.sol


pragma solidity ^0.6.12;

interface IStakingRewardsFactory {
    function satelliteTVL() external view returns(uint);
}

// File: contracts\interface\IMintBurn.sol


pragma solidity ^0.6.12;

interface IMintBurn {

    function burn(address account, uint amount) external;
    function mint(address account, uint amount) external;
}

// File: contracts\interface\ITrusteeFeePool.sol


pragma solidity ^0.6.12;

interface ITrusteeFeePool {
    function exit(address account) external;
    function enter(address account) external;
    function notifyReward(uint reward) external;
}

// File: contracts\interface\ILiquidate.sol


pragma solidity ^0.6.12;

interface ILiquidate {
    function liquidate(address account) external;
}

// File: contracts\Tunnel.sol


pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;





contract Tunnel is Ownable, Pausable, ITunnel, ILiquidate {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    IAddressResolver addrResolver;
    bytes32 public constant BORINGDAO = "BoringDAO";
    // BTOKEN_BTC
    bytes32 public override oTokenKey;
    bytes32 public tunnelKey;
    bytes32 public constant MINT_FEE = "mint_fee";
    bytes32 public constant BURN_FEE = "burn_fee";
    bytes32 public constant MINT_FEE_TRUSTEE = "mint_fee_trustee";
    bytes32 public constant MINT_FEE_PLEDGER = "mint_fee_pledger";
    bytes32 public constant MINT_FEE_DEV = "mint_fee_dev";
    bytes32 public constant BURN_FEE_INSURANCE = "burn_fee_insurance";
    bytes32 public constant BURN_FEE_PLEDGER = "burn_fee_pledger";
    bytes32 public constant FEE_POOL = "FeePool";
    bytes32 public constant INSURANCE_POOL = "InsurancePool";
    bytes32 public constant DEV_ADDRESS = "DevUser";
    bytes32 public constant ADDRESS_BOOK = "AddressBook";
    bytes32 public constant ORACLE = "Oracle";
    bytes32 public constant BOR = "BOR";
    bytes32 public constant PLEDGE_RATE = "pledge_rate";
    bytes32 public constant NETWORK_FEE = "network_fee";
    bytes32 public constant PLEDGE_TOKEN = "oBTC-PPT";
    bytes32 public constant PARAM_BOOK = "ParamBook";
    bytes32 public constant TRUSTEE_FEE_POOL = "TrusteeFeePool";
    bytes32 public constant SATELLITE_POOL_FACTORY = "BTCSatellitePoolFactory";
    bytes32 public constant LIQUIDATION = "Liquidation";

    mapping(address => uint) public borPledgeInfo;
    // total pledge value in one token
    uint256 public totalPledgeBOR;

    // burn mini limit
    uint256 public burnMiniLimit=1e15;
    uint256 public redeemLockTxLimit=5;

    struct PledgerInfo {
        uint256 amount;
        uint256 feeDebt;
    }

    struct LockAmount{
        uint unlockTime;
        uint amount;
    }
    mapping(address=>LockAmount[]) public lockInfo;

    uint256 public lockDuration = 86400;

    constructor(
        IAddressResolver _addrResolver,
        bytes32 _oTokenKey,
        bytes32 _tunnelKey
    ) public {
        addrResolver = _addrResolver;
        oTokenKey = _oTokenKey;
        tunnelKey = _tunnelKey;
        _pause();
    }

    // view
    function otokenMintBurn() internal view returns (IMintBurn) {
        return IMintBurn(addrResolver.requireAndKey2Address(oTokenKey, "Tunnel::otokenMintBurn: oToken contract not exist in Tunnel"));
    }

    function otokenERC20() internal view returns (IERC20) {
        return IERC20(addrResolver.requireAndKey2Address(oTokenKey, "Tunnel::otokenERC20: oToken contract not exist in Tunnel"));
    }

    function borERC20() internal view returns (IERC20) {
        return IERC20(addrResolver.requireAndKey2Address(BOR, "borERC20::borERC20: BOR contract not exist in Tunnel"));
    }

    function boringDAO() internal view returns (IBoringDAO) {
        return IBoringDAO(addrResolver.key2address(BORINGDAO));
    }

    function oracle() internal view returns (IOracle) {
        return IOracle(addrResolver.key2address(ORACLE));
    }

    function ppTokenMintBurn() internal view returns (IMintBurn) {
        return IMintBurn(addrResolver.key2address(PLEDGE_TOKEN));
    }

    function ppTokenERC20() internal view returns (IERC20) {
        return IERC20(addrResolver.key2address(PLEDGE_TOKEN));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(addrResolver.key2address(FEE_POOL));
    }

    function trusteeFeePool() internal view returns (ITrusteeFeePool) {
        return ITrusteeFeePool(addrResolver.requireAndKey2Address(TRUSTEE_FEE_POOL, "Tunnel::trusteeFeePool is address(0)"));
    }

    function paramBook() internal view returns (ParamBook) {
        return ParamBook(addrResolver.key2address(PARAM_BOOK));
    }

    function getRate(bytes32 name) internal view returns (uint256) {
        return paramBook().params2(tunnelKey, name);
    }

    function satellitePoolFactory() internal view returns(IStakingRewardsFactory) {
        return IStakingRewardsFactory(addrResolver.key2address(SATELLITE_POOL_FACTORY));
    }

    function totalValuePledge() public override view returns (uint256) {
        uint256 borPrice = oracle().getPrice(BOR);
        return totalPledgeBOR.multiplyDecimal(borPrice);
    }

    function userLockLength(address account) public view returns (uint) {
        return lockInfo[account].length;
    }

    function userLockAmount() public view returns(uint256, uint256) {
        uint lock;
        uint unlock;
        for (uint i=0; i<lockInfo[msg.sender].length; i++) {
            if(block.timestamp >= lockInfo[msg.sender][i].unlockTime) {
                unlock = unlock.add(lockInfo[msg.sender][i].amount);
            } else {
                lock = lock.add(lockInfo[msg.sender][i].amount);
            }
        }
        return (lock, unlock);
    }

    // todo

    // duration should bigger than lockDuration
    function setLockDuration(uint duration) public onlyOwner {
        lockDuration = duration;
    }

    function setRedeemLockTxLimit(uint limit) public onlyOwner {
            redeemLockTxLimit = limit;
    }

    function setBurnMiniLimit(uint amount) public onlyOwner {
        burnMiniLimit = amount;
    }

    function pledge(address account, uint256 amount)
        external
        override
        onlyBoringDAO
    {
        borPledgeInfo[account] = borPledgeInfo[account].add(amount);
        totalPledgeBOR = totalPledgeBOR.add(amount);
        // mint pledge token
        ppTokenMintBurn().mint(account, amount);
        feePool().notifyPTokenAmount(account, amount);
        emit PledgeSuccess(account, amount);
    }

    function redeem(address account, uint256 amount)
        external
        override
        onlyBoringDAO
    {
        require(
            ppTokenERC20().balanceOf(account) >= amount,
            "Tunnel::redeem: not enough pledge provider token"
        );
        require(borPledgeInfo[account] >= amount, "Tunnel:redeem: Not enough bor amount");
        require(lockInfo[account].length < redeemLockTxLimit, "Tunnel::redeem: A user can only redeem at most five redeem, try again after extraction");
        borPledgeInfo[account] = borPledgeInfo[account].sub(amount);
        // send fee and burn ptoken
        // pledge token and fee
        // burn ptoken and tansfer back BOR
        lock(account, amount, block.timestamp.add(lockDuration));
        ppTokenMintBurn().burn(account, amount);
        feePool().withdraw(account, amount);
        emit RedeemSuccess(account, amount);
    }

    function lock(address account, uint amount, uint unlockTime) internal {
        lockInfo[account].push(LockAmount(unlockTime, amount));
    }

    function withdrawUnlock() public {
        uint unlock;
        uint  i = 0;
        while (i!=lockInfo[msg.sender].length) {
            if (block.timestamp >= lockInfo[msg.sender][i].unlockTime) {
                unlock = unlock.add(lockInfo[msg.sender][i].amount);
                lockInfo[msg.sender][i] = lockInfo[msg.sender][lockInfo[msg.sender].length.sub(1)];
                lockInfo[msg.sender].pop();
            } else {
                i++;
            }
        }
        if (unlock > 0 ) {
            totalPledgeBOR = totalPledgeBOR.sub(unlock);
            borERC20().transfer(msg.sender, unlock);
            emit WithdrawUnlockSuccess(
                msg.sender,
                unlock
            );
        }
    }


    // when approved then issue
    function issue(address account, uint256 amount)
        external
        override
        onlyBoringDAO
    {
        //network fee
        uint networkFee = paramBook().params2(tunnelKey, NETWORK_FEE);
        // calculate fee
        uint256 mintFeeRation = getRate(MINT_FEE);
        uint256 mintFeeAmount = amount.multiplyDecimal(mintFeeRation);
        uint256 mintAmount = amount.sub(mintFeeAmount).sub(networkFee);
        otokenMintBurn().mint(account, mintAmount);
        // handle fee
        // trustee fee
        uint256 mintFeeTrusteeRatio = getRate(MINT_FEE_TRUSTEE);
        uint256 mintFeeTrusteeAmount = mintFeeAmount.multiplyDecimal(mintFeeTrusteeRatio).add(networkFee);
        otokenMintBurn().mint(address(trusteeFeePool()), mintFeeTrusteeAmount);
        trusteeFeePool().notifyReward(mintFeeTrusteeAmount);

        // fee to pledger
        uint256 mintFeePledgerRation = getRate(MINT_FEE_PLEDGER);
        uint256 mintFeePledgerAmount = mintFeeAmount.multiplyDecimal(
            mintFeePledgerRation
        );
        address feePoolAddress = address(feePool());
        otokenMintBurn().mint(feePoolAddress, mintFeePledgerAmount);
        feePool().notifyBTokenFeeAmount(mintFeePledgerAmount);


        // to developer team
        uint256 mintFeeDevRation = getRate(MINT_FEE_DEV);
        uint256 mintFeeDevAmount = mintFeeAmount.multiplyDecimal(
            mintFeeDevRation
        );
        address devAddress = addrResolver.key2address(DEV_ADDRESS);

        otokenMintBurn().mint(devAddress, mintFeeDevAmount);
    }


    function burn(address account, uint256 amount, string memory assetAddress) external override onlyBoringDAO{
        require(amount>=burnMiniLimit, "Tunnel::burn: the amount too small");
        uint256 burnFeeAmountBToken = amount.multiplyDecimal(getRate(BURN_FEE));
        // convert to bor amount
        uint burnFeeAmount = oracle().getPrice(tunnelKey).multiplyDecimal(burnFeeAmountBToken).divideDecimal(oracle().getPrice(BOR));

        // insurance apart
        address insurancePoolAddress = addrResolver.key2address(INSURANCE_POOL);
        uint256 burnFeeAmountInsurance = burnFeeAmount.multiplyDecimal(
            getRate(BURN_FEE_INSURANCE)
        );


        // pledger apart
        uint256 burnFeeAmountPledger = burnFeeAmount.multiplyDecimal(
            getRate(BURN_FEE_PLEDGER)
        );
        borERC20().transferFrom(
            account,
            insurancePoolAddress,
            burnFeeAmountInsurance
        );
        //fee to feepool
        borERC20().transferFrom(
            account,
            address(feePool()),
            burnFeeAmountPledger
        );
        feePool().notifyBORFeeAmount(burnFeeAmountPledger);
        // otoken burn
        otokenMintBurn().burn(account, amount);
        emit BurnOToken(
            account,
            amount,
            boringDAO().getRandomTrustee(),
            assetAddress
        );
    }

    function totalTVL() public view returns(uint) {
        uint256 borTVL = totalValuePledge();
        uint satelliteTVL = satellitePoolFactory().satelliteTVL();
        return borTVL.add(satelliteTVL);
    }
    
    function pledgeRatio() public view returns(uint) {
        uint tvl = totalTVL();
        uint btokenValue = otokenERC20().totalSupply().multiplyDecimal(oracle().getPrice(tunnelKey));
        if (btokenValue == 0) {
            return 0;
        }
        return tvl.divideDecimal(btokenValue);
    }

    function canIssueAmount() external override view returns (uint256) {
        // satellite pool tvl
        uint total = totalTVL();
        uint256 pledgeRate = paramBook().params2(tunnelKey, PLEDGE_RATE);
        uint256 canIssueValue = total.divideDecimal(pledgeRate);
        uint256 tunnelKeyPrice = oracle().getPrice(tunnelKey);
        return canIssueValue.divideDecimal(tunnelKeyPrice);
    }

    function liquidate(address account) public override onlyLiquidation {
        borERC20().transfer(account, totalPledgeBOR);
    }

    function unpause() public returns (bool) {
        if (totalPledgeBOR >= 3000e18) {
            _unpause();
        } 
        return paused();
    }

    modifier onlyBoringDAO {
        require(msg.sender == addrResolver.key2address(BORINGDAO));
        _;
    }

    modifier onlyLiquidation {
        require(msg.sender == addrResolver.requireAndKey2Address(LIQUIDATION, "Tunnel::liquidation contract no exist"));
        _;
    }

    event BurnOToken(
        address indexed account,
        uint256 amount,
        address proposer,
        string assetAddress
    );

    event WithdrawUnlockSuccess(
        address account,
        uint    amount
    );

     event PledgeSuccess(
         address account,
         uint   amount
     );

    event RedeemSuccess(
        address account,
        uint amount
    );
}