// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ILendingLogic.sol";
import "../../interfaces/IAToken.sol";
import "../../interfaces/IAaveLendingPool.sol";

contract AToken is IAToken {
    address public underlyingAssetAddress;
    function redeem(uint256 _amount) external override {}
}

contract LendingLogicAave is ILendingLogic {
    using SafeMath for uint256;

    IAaveLendingPool public lendingPool;
    uint16 public referralCode;

    constructor(address _lendingPool, uint16 _referralCode) {
        require(_lendingPool != address(0), "LENDING_POOL_INVALID");
        lendingPool = IAaveLendingPool(_lendingPool);
        referralCode = _referralCode;
    }

    function getAPRFromWrapped(address _token) external view override returns(uint256) {
        address underlying = AToken(_token).underlyingAssetAddress();
        return getAPRFromUnderlying(underlying);
    }

    function getAPRFromUnderlying(address _token) public view override returns(uint256) {
        address _lendingPool = address(lendingPool);
        uint256[5] memory ret;

        // https://ethereum.stackexchange.com/questions/84597/ilendingpool-getreservedata-function-gives-yulexception-stack-too-deep-when-com
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("getReserveData(address)")), _token);
        assembly {
            let success := staticcall(
                gas(),         // gas remaining
                _lendingPool,  // destination address
                add(data, 32), // input buffer (starts after the first 32 bytes in the `data` array)
                mload(data),   // input length (loaded from the first 32 bytes in the `data` array)
                ret,           // output buffer
                160             // output length
            )
            if iszero(success) {
                revert(0, 0)
            }
        }
        return ret[4].div(1000000000);
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 underlying = IERC20(_underlying);

        address core = lendingPool.core();

        targets = new address[](3);
        data = new bytes[](3);

        // zero out approval to be sure
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, address(core), 0);

        // Set approval
        targets[1] = _underlying;
        data[1] = abi.encodeWithSelector(underlying.approve.selector, address(core), _amount);

        // Deposit into Aave
        targets[2] = address(lendingPool);
        data[2] =  abi.encodeWithSelector(lendingPool.deposit.selector, _underlying, _amount, referralCode);

        return(targets, data);
    }

    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _wrapped;
        data[0] = abi.encodeWithSelector(IAToken.redeem.selector, _amount);

        return(targets, data);
    }

    function exchangeRate(address) external pure override returns(uint256) {
        return 10**18;
    }

    function exchangeRateView(address) external pure override returns(uint256) {
        return 10**18;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

interface ILendingLogic {
    /**
        @notice Get the APR based on underlying token.
        @param _token Address of the underlying token
        @return Interest with 18 decimals
    */
    function getAPRFromUnderlying(address _token) external view returns(uint256);

    /**
        @notice Get the APR based on wrapped token.
        @param _token Address of the wrapped token
        @return Interest with 18 decimals
    */
    function getAPRFromWrapped(address _token) external view returns(uint256);

    /**
        @notice Get the calls needed to lend.
        @param _underlying Address of the underlying token
        @param _amount Amount of the underlying token
        @return targets Addresses of the contracts to call
        @return data Calldata of the calls
    */
    function lend(address _underlying, uint256 _amount) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the calls needed to unlend
        @param _wrapped Address of the wrapped token
        @param _amount Amount of the underlying tokens
        @return targets Addresses of the contracts to call
        @return data Calldata of the calls
    */
    function unlend(address _wrapped, uint256 _amount) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the underlying wrapped exchange rate
        @param _wrapped Address of the wrapped token
        @return The exchange rate
    */
    function exchangeRate(address _wrapped) external returns(uint256);

    /**
        @notice Get the underlying wrapped exchange rate in a view (non state changing) way
        @param _wrapped Address of the wrapped token
        @return The exchange rate
    */
    function exchangeRateView(address _wrapped) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

interface IAToken {
    function redeem(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

interface IAaveLendingPool {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external;
    function core() external view returns(address);
    function getReserveData(address _reserve)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            address aTokenAddress,
            uint40 lastUpdateTimestamp
        );
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ILendingLogic.sol";
import "../../interfaces/IATokenV2.sol";
import "../../interfaces/IAaveLendingPoolV2.sol";

contract ATokenV2 is IATokenV2 {
    address public UNDERLYING_ASSET_ADDRESS;
}

contract LendingLogicAaveV2 is ILendingLogic {
    using SafeMath for uint128;

    IAaveLendingPoolV2 public lendingPool;
    uint16 public referralCode;
    address public tokenHolder;

    constructor(address _lendingPool, uint16 _referralCode, address _tokenHolder) {
        require(_lendingPool != address(0), "LENDING_POOL_INVALID");
        lendingPool = IAaveLendingPoolV2(_lendingPool);
        referralCode = _referralCode;
        tokenHolder = _tokenHolder;
    }

    function getAPRFromWrapped(address _token) external view override returns(uint256) {
        address underlying = ATokenV2(_token).UNDERLYING_ASSET_ADDRESS();
        return getAPRFromUnderlying(underlying);
    }

    function getAPRFromUnderlying(address _token) public view override returns(uint256) {
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(_token);
        return reserveData.currentLiquidityRate.div(1000000000);
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 underlying = IERC20(_underlying);

        targets = new address[](3);
        data = new bytes[](3);

        // zero out approval to be sure
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, address(lendingPool), 0);

        // Set approval
        targets[1] = _underlying;
        data[1] = abi.encodeWithSelector(underlying.approve.selector, address(lendingPool), _amount);

        // Deposit into Aave
        targets[2] = address(lendingPool);
        data[2] =  abi.encodeWithSelector(lendingPool.deposit.selector, _underlying, _amount, tokenHolder, referralCode);

        return(targets, data);
    }

    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        ATokenV2 wrapped = ATokenV2(_wrapped);

        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = address(lendingPool);
        data[0] = abi.encodeWithSelector(
            lendingPool.withdraw.selector,
            wrapped.UNDERLYING_ASSET_ADDRESS(),
            _amount,
            tokenHolder
        );

        return(targets, data);
    }

    function exchangeRate(address) external pure override returns(uint256) {
        return 10**18;
    }

    function exchangeRateView(address) external pure override returns(uint256) {
        return 10**18;
    }

}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

interface IATokenV2 {

}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

interface IAaveLendingPoolV2 {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external;

    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ILendingLogic.sol";
import "./LendingRegistry.sol";
import "../../interfaces/ICToken.sol";

contract LendingLogicCompound is Ownable, ILendingLogic {
    using SafeMath for uint256;

    LendingRegistry public lendingRegistry;
    bytes32 public immutable protocolKey;
    uint256 public blocksPerYear;

    constructor(address _lendingRegistry, bytes32 _protocolKey) {
        require(_lendingRegistry != address(0), "INVALID_LENDING_REGISTRY");
        lendingRegistry = LendingRegistry(_lendingRegistry);
        protocolKey = _protocolKey;
    }

    function setBlocksPerYear(uint256 _blocks) external onlyOwner {
        // calculated by taking APY onn compound.finance  / dividing by supplyrate per block
        // this is apparently the amount of blocks compound expects to be minted this year
        // 2145683;
        blocksPerYear = _blocks;
    }

    function getAPRFromWrapped(address _token) public view override returns(uint256) {
        return ICToken(_token).supplyRatePerBlock().mul(blocksPerYear);
    }

    function getAPRFromUnderlying(address _token) external view override returns(uint256) {
        address cToken = lendingRegistry.underlyingToProtocolWrapped(_token, protocolKey);
        return getAPRFromWrapped(cToken);
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 underlying = IERC20(_underlying);

        targets = new address[](3);
        data = new bytes[](3);


        address cToken = lendingRegistry.underlyingToProtocolWrapped(_underlying, protocolKey);

        // zero out approval to be sure
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, cToken, 0);

        // Set approval
        targets[1] = _underlying;
        data[1] = abi.encodeWithSelector(underlying.approve.selector, cToken, _amount);

        // Deposit into Compound
        targets[2] = cToken;

        data[2] =  abi.encodeWithSelector(ICToken.mint.selector, _amount);

        return(targets, data);
    }

    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _wrapped;
        data[0] = abi.encodeWithSelector(ICToken.redeem.selector, _amount);

        return(targets, data);
    }

    function exchangeRate(address _wrapped) external override returns(uint256) {
        return ICToken(_wrapped).exchangeRateCurrent();
    }

    function exchangeRateView(address _wrapped) external view override returns(uint256) {
        return ICToken(_wrapped).exchangeRateStored();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
abstract contract Ownable is Context {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;


import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/ILendingLogic.sol";

// TODO consider making this contract upgradeable
contract LendingRegistry is Ownable {

    // Maps wrapped token to protocol
    mapping(address => bytes32) public wrappedToProtocol;
    // Maps wrapped token to underlying
    mapping(address => address) public wrappedToUnderlying;

    mapping(address => mapping(bytes32 => address)) public underlyingToProtocolWrapped;

    // Maps protocol to addresses containing lend and unlend logic
    mapping(bytes32 => address) public protocolToLogic;

    event WrappedToProtocolSet(address indexed wrapped, bytes32 indexed protocol);
    event WrappedToUnderlyingSet(address indexed wrapped, address indexed underlying);
    event ProtocolToLogicSet(bytes32 indexed protocol, address indexed logic);
    event UnderlyingToProtocolWrappedSet(address indexed underlying, bytes32 indexed protocol, address indexed wrapped);

    /**
        @notice Set which protocl a wrapped token belongs to
        @param _wrapped Address of the wrapped token
        @param _protocol Bytes32 key of the protocol
    */
    function setWrappedToProtocol(address _wrapped, bytes32 _protocol) onlyOwner external {
        wrappedToProtocol[_wrapped] = _protocol;
        emit WrappedToProtocolSet(_wrapped, _protocol);
    }

    /**
        @notice Set what is the underlying for a wrapped token
        @param _wrapped Address of the wrapped token
        @param _underlying Address of the underlying token
    */
    function setWrappedToUnderlying(address _wrapped, address _underlying) onlyOwner external {
        wrappedToUnderlying[_wrapped] = _underlying;
        emit WrappedToUnderlyingSet(_wrapped, _underlying);
    }

    /**
        @notice Set the logic contract for the protocol
        @param _protocol Bytes32 key of the procol
        @param _logic Address of the lending logic contract for that protocol
    */
    function setProtocolToLogic(bytes32 _protocol, address _logic) onlyOwner external {
        protocolToLogic[_protocol] = _logic;
        emit ProtocolToLogicSet(_protocol, _logic);
    }

    /**
        @notice Set the wrapped token for the underlying deposited in this protocol
        @param _underlying Address of the unerlying token
        @param _protocol Bytes32 key of the protocol
        @param _wrapped Address of the wrapped token
    */
    function setUnderlyingToProtocolWrapped(address _underlying, bytes32 _protocol, address _wrapped) onlyOwner external {
        underlyingToProtocolWrapped[_underlying][_protocol] = _wrapped;
        emit UnderlyingToProtocolWrappedSet(_underlying, _protocol, _wrapped);
    }

    /**
        @notice Get tx data to lend the underlying amount in a specific protocol
        @param _underlying Address of the underlying token
        @param _amount Amount to lend
        @param _protocol Bytes32 key of the protocol
        @return targets Addresses of the contracts to call
        @return data Calldata for the calls
    */
    function getLendTXData(address _underlying, uint256 _amount, bytes32 _protocol) external view returns(address[] memory targets, bytes[] memory data) {
        ILendingLogic lendingLogic = ILendingLogic(protocolToLogic[_protocol]);
        require(address(lendingLogic) != address(0), "NO_LENDING_LOGIC_SET");

        return lendingLogic.lend(_underlying, _amount);
    }

    /**
        @notice Get the tx data to unlend the wrapped amount
        @param _wrapped Address of the wrapped token
        @param _amount Amount of wrapped token to unlend
        @return targets Addresses of the contracts to call
        @return data Calldata for the calls
    */
    function getUnlendTXData(address _wrapped, uint256 _amount) external view returns(address[] memory targets, bytes[] memory data) {
        ILendingLogic lendingLogic = ILendingLogic(protocolToLogic[wrappedToProtocol[_wrapped]]);
        require(address(lendingLogic) != address(0), "NO_LENDING_LOGIC_SET");

        return lendingLogic.unlend(_wrapped, _amount);
    }

    /**
        @notice Get the beste apr for the give protocols
        @dev returns default values if lending logic not found
        @param _underlying Address of the underlying token
        @param _protocols Array of protocols to include
        @return apr The APR
        @return protocol Protocol that provides the APR
    */
    function getBestApr(address _underlying, bytes32[] memory _protocols) external view returns(uint256 apr, bytes32 protocol) {
        uint256 bestApr;
        bytes32 bestProtocol;

        for(uint256 i = 0; i < _protocols.length; i++) {
            bytes32 protocol = _protocols[i];
            ILendingLogic lendingLogic = ILendingLogic(protocolToLogic[protocol]);
            require(address(lendingLogic) != address(0), "NO_LENDING_LOGIC_SET");

            uint256 apr = lendingLogic.getAPRFromUnderlying(_underlying);
            if (apr > bestApr) {
                bestApr = apr;
                bestProtocol = protocol;
            }
        }

        return (bestApr, bestProtocol);
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

interface ICToken {
    function mint(uint _mintAmount) external returns (uint256);
    function redeem(uint _redeemTokens) external returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./LendingRegistry.sol";
import "../../interfaces/IExperiPie.sol";

contract LendingManager is Ownable, ReentrancyGuard {
    using Math for uint256;

    LendingRegistry public lendingRegistry;
    IExperiPie public basket;

    event Lend(address indexed underlying, uint256 amount, bytes32 indexed protocol);
    event UnLend(address indexed wrapped, uint256 amount);
    /**
        @notice Constructor
        @param _lendingRegistry Address of the lendingRegistry contract
        @param _basket Address of the pool/pie/basket to manage
    */
    constructor(address _lendingRegistry, address _basket) public {
        require(_lendingRegistry != address(0), "INVALID_LENDING_REGISTRY");
        require(_basket != address(0), "INVALID_BASKET");
        lendingRegistry = LendingRegistry(_lendingRegistry);
        basket = IExperiPie(_basket);
    }

    /**
        @notice Move underlying to a lending protocol
        @param _underlying Address of the underlying token
        @param _amount Amount of underlying to lend
        @param _protocol Bytes32 protocol key to lend to
    */
    function lend(address _underlying, uint256 _amount, bytes32 _protocol) public onlyOwner nonReentrant {
        // _amount or actual balance, whatever is less
        uint256 amount = _amount.min(IERC20(_underlying).balanceOf(address(basket)));

        //lend token
        (
            address[] memory _targets,
            bytes[] memory _data
        ) = lendingRegistry.getLendTXData(_underlying, amount, _protocol);

        basket.callNoValue(_targets, _data);

        // if needed remove underlying from basket
        removeToken(_underlying);

        // add wrapped token
        addToken(lendingRegistry.underlyingToProtocolWrapped(_underlying, _protocol));

        emit Lend(_underlying, _amount, _protocol);
    }

    /**
        @notice Unlend wrapped token from its lending protocol
        @param _wrapped Address of the wrapped token
        @param _amount Amount of the wrapped token to unlend
    */
    function unlend(address _wrapped, uint256 _amount) public onlyOwner nonReentrant {
        // unlend token
         // _amount or actual balance, whatever is less
        uint256 amount = _amount.min(IERC20(_wrapped).balanceOf(address(basket)));

        //Unlend token
        (
            address[] memory _targets,
            bytes[] memory _data
        ) = lendingRegistry.getUnlendTXData(_wrapped, amount);
        basket.callNoValue(_targets, _data);

        // if needed add underlying
        addToken(lendingRegistry.wrappedToUnderlying(_wrapped));

        // if needed remove wrapped
        removeToken(_wrapped);

        emit UnLend(_wrapped, _amount);
    }

    /**
        @notice Unlend and immediately lend in a different protocol
        @param _wrapped Address of the wrapped token to bounce to another protocol
        @param _amount Amount of the wrapped token to bounce to the other protocol
        @param _toProtocol Protocol to deposit bounced tokens in
        @dev Uses reentrency protection of unlend() and lend()
    */
    function bounce(address _wrapped, uint256 _amount, bytes32 _toProtocol) external {
       unlend(_wrapped, _amount);
       // Bounce all to new protocol
       lend(lendingRegistry.wrappedToUnderlying(_wrapped), uint256(-1), _toProtocol);
    }

    function removeToken(address _token) internal {
        uint256 balance = basket.balance(_token);
        bool inPool = basket.getTokenInPool(_token);
        //if there is a token balance of the token is not in the pool, skip
        if(balance != 0 || !inPool) {
            return;
        }

        // remove token
        basket.singleCall(address(basket), abi.encodeWithSelector(basket.removeToken.selector, _token), 0);
    }

    function addToken(address _token) internal {
        uint256 balance = basket.balance(_token);
        bool inPool = basket.getTokenInPool(_token);
        // If token has no balance or is already in the pool, skip
        if(balance == 0 || inPool) {
            return;
        }

        // add token
        basket.singleCall(address(basket), abi.encodeWithSelector(basket.addToken.selector, _token), 0);
    }
 
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@pie-dao/diamond/contracts/interfaces/IERC173.sol";
import "@pie-dao/diamond/contracts/interfaces/IDiamondLoupe.sol";
import "@pie-dao/diamond/contracts/interfaces/IDiamondCut.sol";
import "./IBasketFacet.sol";
import "./IERC20Facet.sol";
import "./ICallFacet.sol";

/**
    @title ExperiPie Interface
    @dev Combines all ExperiPie facet interfaces into one
*/
interface IExperiPie is IERC20, IBasketFacet, IERC20Facet, IERC173, ICallFacet, IDiamondLoupe, IDiamondCut {
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface IBasketFacet {

    event TokenAdded(address indexed _token);
    event TokenRemoved(address indexed _token);
    event EntryFeeSet(uint256 fee);
    event ExitFeeSet(uint256 fee);
    event AnnualizedFeeSet(uint256 fee);
    event FeeBeneficiarySet(address indexed beneficiary);
    event EntryFeeBeneficiaryShareSet(uint256 share);
    event ExitFeeBeneficiaryShareSet(uint256 share);

    event PoolJoined(address indexed who, uint256 amount);
    event PoolExited(address indexed who, uint256 amount);
    event FeeCharged(uint256 amount);
    event LockSet(uint256 lockBlock);
    event CapSet(uint256 cap);

    /** 
        @notice Sets entry fee paid when minting
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setEntryFee(uint256 _fee) external;

    /**
        @notice Get the entry fee
        @return Current entry fee
    */
    function getEntryFee() external view returns(uint256);

    /**
        @notice Set the exit fee paid when exiting
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setExitFee(uint256 _fee) external;

    /**
        @notice Get the exit fee
        @return Current exit fee
    */
    function getExitFee() external view returns(uint256);

    /**
        @notice Set the annualized fee. Often referred to as streaming fee
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setAnnualizedFee(uint256 _fee) external;

    /**
        @notice Get the annualized fee.
        @return Current annualized fee.
    */
    function getAnnualizedFee() external view returns(uint256);

    /**
        @notice Set the address receiving the fees.
    */
    function setFeeBeneficiary(address _beneficiary) external;

    /**
        @notice Get the fee benificiary
        @return The current fee beneficiary
    */
    function getFeeBeneficiary() external view returns(address);

    /**
        @notice Set the fee beneficiaries share of the entry fee
        @notice _share Share of the fee. 1e18 == 100%. Capped at 100% 
    */
    function setEntryFeeBeneficiaryShare(uint256 _share) external;

    /**
        @notice Get the entry fee beneficiary share
        @return Feeshare amount
    */
    function getEntryFeeBeneficiaryShare() external view returns(uint256);

    /**
        @notice Set the fee beneficiaries share of the exit fee
        @notice _share Share of the fee. 1e18 == 100%. Capped at 100% 
    */
    function setExitFeeBeneficiaryShare(uint256 _share) external;

    /**
        @notice Get the exit fee beneficiary share
        @return Feeshare amount
    */
    function getExitFeeBeneficiaryShare() external view returns(uint256);

    /**
        @notice Calculate the oustanding annualized fee
        @return Amount of pool tokens to be minted to charge the annualized fee
    */
    function calcOutStandingAnnualizedFee() external view returns(uint256);

    /**
        @notice Charges the annualized fee
    */
    function chargeOutstandingAnnualizedFee() external;

    /**
        @notice Pulls underlying from caller and mints the pool token
        @param _amount Amount of pool tokens to mint
    */
    function joinPool(uint256 _amount) external;

    /**
        @notice Burns pool tokens from the caller and returns underlying assets
    */
    function exitPool(uint256 _amount) external;

    /**
        @notice Get if the pool is locked or not. (not accepting exit and entry)
        @return Boolean indicating if the pool is locked
    */
    function getLock() external view returns (bool);

    /**
        @notice Get the block until which the pool is locked
        @return The lock block
    */
    function getLockBlock() external view returns (uint256);

    /**
        @notice Set the lock block
        @param _lock Block height of the lock
    */
    function setLock(uint256 _lock) external;

    /**
        @notice Get the maximum of pool tokens that can be minted
        @return Cap
    */
    function getCap() external view returns (uint256);

    /**
        @notice Set the maximum of pool tokens that can be minted
        @param _maxCap Max cap 
    */
    function setCap(uint256 _maxCap) external;

    /**
        @notice Get the amount of tokens owned by the pool
        @param _token Addres of the token
        @return Amount owned by the contract
    */
    function balance(address _token) external view returns (uint256);

    /**
        @notice Get the tokens in the pool
        @return Array of tokens in the pool
    */
    function getTokens() external view returns (address[] memory);

    /**
        @notice Add a token to the pool. Should have at least a balance of 10**6
        @param _token Address of the token to add
    */
    function addToken(address _token) external;

    /**
        @notice Removes a token from the pool
        @param _token Address of the token to remove
    */
    function removeToken(address _token) external;

    /**
        @notice Checks if a token was added to the pool
        @param _token address of the token
        @return If token is in the pool or not
    */
    function getTokenInPool(address _token) external view returns (bool);

    /**
        @notice Calculate the amounts of underlying needed to mint that pool amount.
        @param _amount Amount of pool tokens to mint
        @return tokens Tokens needed
        @return amounts Amounts of underlying needed
    */
    function calcTokensForAmount(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    /**
        @notice Calculate the amounts of underlying to receive when burning that pool amount
        @param _amount Amount of pool tokens to burn
        @return tokens Tokens returned
        @return amounts Amounts of underlying returned
    */
    function calcTokensForAmountExit(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface IERC20Facet {
    
    /**
        @notice Get the token name
        @return The token name
    */
    function name() external view returns (string memory);

    /**
        @notice Get the token symbol
        @return The token symbol 
    */
    function symbol() external view returns (string memory);

    /**
        @notice Get the amount of decimals
        @return Amount of decimals
    */
    function decimals() external view returns (uint8);

    /**
        @notice Mints tokens. Can only be called by the contract owner or the contract itself
        @param _receiver Address receiving the tokens
        @param _amount Amount to mint
    */
    function mint(address _receiver, uint256 _amount) external;

    /**
        @notice Burns tokens. Can only be called by the contract owner or the contract itself
        @param _from Address to burn from
        @param _amount Amount to burn
    */
    function burn(address _from, uint256 _amount) external;

    /**
        @notice Sets up the metadata and initial supply. Can be called by the contract owner
        @param _initialSupply Initial supply of the token
        @param _name Name of the token
        @param _symbol Symbol of the token
    */
    function initialize(
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol
    ) external;

    /**
        @notice Set the token name of the contract. Can only be called by the contract owner or the contract itself
        @param _name New token name
    */
    function setName(string calldata _name) external;

    /**
        @notice Set the token symbol of the contract. Can only be called by the contract owner or the contract itself
        @param _symbol New token symbol
    */
    function setSymbol(string calldata _symbol) external;
    
    /**
        @notice Increase the amount of tokens another address can spend
        @param _spender Spender
        @param _amount Amount to increase by
    */
    function increaseApproval(address _spender, uint256 _amount) external returns (bool);

    /**
        @notice Decrease the amount of tokens another address can spend
        @param _spender Spender
        @param _amount Amount to decrease by
    */
    function decreaseApproval(address _spender, uint256 _amount) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface ICallFacet {

    event CallerAdded(address indexed caller);
    event CallerRemoved(address indexed caller);
    event Call(address indexed caller, address indexed target, bytes data, uint256 value);

    /**
        @notice Lets whitelisted callers execute a batch of arbitrary calls from the pool. Reverts if one of the calls fails
        @param _targets Array of addresses of targets to call
        @param _calldata Array of calldata for each call
        @param _values Array of amounts of ETH to send with the call
    */
    function call(
        address[] memory _targets,
        bytes[] memory _calldata,
        uint256[] memory _values
    ) external;

    /**
        @notice Lets whitelisted callers execute a batch of arbitrary calls from the pool without sending any Ether. Reverts if one of the calls fail
        @param _targets Array of addresses of targets to call
        @param _calldata Array of calldata for each call
    */
    function callNoValue(
        address[] memory _targets,
        bytes[] memory _calldata
    ) external;

    /**
        @notice Lets whitelisted callers execute a single arbitrary call from the pool. Reverts if the call fails
        @param _target Address of the target to call
        @param _calldata Calldata of the call
        @param _value Amount of ETH to send with the call
    */
    function singleCall(
        address _target,
        bytes calldata _calldata,
        uint256 _value
    ) external;

    /**
        @notice Add a whitelisted caller. Can only be called by the contract owner
        @param _caller Caller to add
    */
    function addCaller(address _caller) external;

    /**
        @notice Remove a whitelisted caller. Can only be called by the contract owner
    */
    function removeCaller(address _caller) external;

    /**
        @notice Checks if an address is a whitelisted caller
        @param _caller Address to check
        @return If the address is whitelisted
    */
    function canCall(address _caller) external view returns (bool);

    /**
        @notice Get all whitelisted callers
        @return Array of whitelisted callers
    */
    function getCallers() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ILendingLogic.sol";
import "./LendingRegistry.sol";
import "../../interfaces/IXSushi.sol";

contract StakingLogicSushi is ILendingLogic {

    LendingRegistry public lendingRegistry;
    bytes32 public immutable protocolKey;

    constructor(address _lendingRegistry, bytes32 _protocolKey) {
        require(_lendingRegistry != address(0), "INVALID_LENDING_REGISTRY");
        lendingRegistry = LendingRegistry(_lendingRegistry);
        protocolKey = _protocolKey;
    }

    function getAPRFromWrapped(address _token) public view override returns(uint256) {
        return uint256(-1);
    }

    function getAPRFromUnderlying(address _token) external view override returns(uint256) {
        return uint256(-1);
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 underlying = IERC20(_underlying);

        targets = new address[](3);
        data = new bytes[](3);


        address SushiBar = lendingRegistry.underlyingToProtocolWrapped(_underlying, protocolKey);

        // zero out approval to be sure
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, SushiBar, 0);

        // Set approval
        targets[1] = _underlying;
        data[1] = abi.encodeWithSelector(underlying.approve.selector, SushiBar, _amount);

        // Stake in Sushi Bar
        targets[2] = SushiBar;

        data[2] =  abi.encodeWithSelector(IXSushi.enter.selector, _amount);

        return(targets, data);
    }
    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _wrapped;
        data[0] = abi.encodeWithSelector(IXSushi.leave.selector, _amount);

        return(targets, data);
    }

    function exchangeRate(address _wrapped) external view override returns(uint256) {
        return _exchangeRate(_wrapped);
    }

    function exchangeRateView(address _wrapped) external view override returns(uint256) {
        return _exchangeRate(_wrapped);
    }

    function _exchangeRate(address _wrapped) internal view returns(uint256) {
        IERC20 xToken = IERC20(_wrapped);
        IERC20 token = IERC20(lendingRegistry.wrappedToUnderlying(_wrapped));
        return token.balanceOf(_wrapped) * 10**18 / xToken.totalSupply();
    }

}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

interface IXSushi {
    function enter(uint256 _amount) external;
    function leave(uint256 _share) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ILendingLogic.sol";
import "./LendingRegistry.sol";
import "../../interfaces/IYVault.sol";

contract StakingLogicYGov is ILendingLogic {

    LendingRegistry public lendingRegistry;
    bytes32 public immutable protocolKey;

    constructor(address _lendingRegistry, bytes32 _protocolKey) {
        require(_lendingRegistry != address(0), "INVALID_LENDING_REGISTRY");
        lendingRegistry = LendingRegistry(_lendingRegistry);
        protocolKey = _protocolKey;
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 underlying = IERC20(_underlying);

        targets = new address[](3);
        data = new bytes[](3);


        address YGov = lendingRegistry.underlyingToProtocolWrapped(_underlying, protocolKey);

        // zero out approval to be sure
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, YGov, 0);

        // Set approval
        targets[1] = _underlying;
        data[1] = abi.encodeWithSelector(underlying.approve.selector, YGov, _amount);

        // Stake in Sushi Bar
        targets[2] = YGov;

        data[2] =  abi.encodeWithSelector(IYVault.deposit.selector, _amount);

        return(targets, data);
    }
    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _wrapped;
        data[0] = abi.encodeWithSelector(IYVault.withdraw.selector, _amount);

        return(targets, data);
    }

    function getAPRFromUnderlying(address _token) external view override returns(uint256) {
        return uint256(-1);
    }

    function getAPRFromWrapped(address _token) external view override returns(uint256) {
        return uint256(-1);
    }
    
    function exchangeRate(address _wrapped) external view override returns(uint256) {
        return IYVault(_wrapped).getPricePerFullShare();
    }

    function exchangeRateView(address _wrapped) external view override returns(uint256) {
        return IYVault(_wrapped).getPricePerFullShare();
    }

}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

interface IYVault {
    function depositAll() external;
    function deposit(uint _amount) external;
    function withdraw(uint _shares) external;
    function getPricePerFullShare() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ISynthetix.sol";
import "../interfaces/IExperiPie.sol";
import "../interfaces/IPriceReferenceFeed.sol";

contract RSISynthetixManager {

    address public immutable assetShort;
    address public immutable assetLong;
    bytes32 public immutable assetShortKey;
    bytes32 public immutable assetLongKey;

    // Value under which to go long (30 * 10**18 == 30)
    int256 public immutable rsiBottom;
    // Value under which to go short
    int256 public immutable rsiTop;

    IPriceReferenceFeed public immutable priceFeed;
    IExperiPie public immutable basket;
    ISynthetix public immutable synthetix;

    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt; 
        uint256 updatedAt; 
        uint80 answeredInRound;
    }

    event Rebalanced(address indexed basket, address indexed fromToken, address indexed toToken);

    constructor(
        address _assetShort,
        address _assetLong,
        bytes32 _assetShortKey,
        bytes32 _assetLongKey,
        int256 _rsiBottom,
        int256 _rsiTop,
        address _priceFeed,
        address _basket,
        address _synthetix
    ) {
        assetShort = _assetShort;
        assetLong = _assetLong;
        assetShortKey = _assetShortKey;
        assetLongKey = _assetLongKey;

        require(_assetShort != address(0), "INVALID_ASSET_SHORT");
        require(_assetLong != address(0), "INVALID_ASSET_LONG");
        require(_assetShortKey != bytes32(0), "INVALID_ASSET_SHORT_KEY");
        require(_assetLongKey != bytes32(0), "INVALID_ASSET_LONG_KEY");

        require(_rsiBottom < _rsiTop, "RSI bottom should be bigger than RSI top");
        require(_rsiBottom > 0, "RSI bottom should be bigger than 0");
        require(_rsiTop < 100 * 10**18, "RSI top should be less than 100");

        require(_priceFeed != address(0), "INVALID_PRICE_FEED");
        require(_basket != address(0), "INVALID_BASKET");
        require(_synthetix != address(0), "INVALID_SYNTHETIX");

        rsiBottom = _rsiBottom;
        rsiTop = _rsiTop;

        priceFeed = IPriceReferenceFeed(_priceFeed);
        basket = IExperiPie(_basket);
        synthetix = ISynthetix(_synthetix);
    }


    function rebalance() external {
        RoundData memory roundData = readLatestRound();
        require(roundData.updatedAt > 0, "Round not complete");

        if(roundData.answer <= rsiBottom) {
            // long
            long();
            return;
        } else if(roundData.answer >= rsiTop) {
            // Short
            short();
            return;
        }
    }

    function long() internal {
        IERC20 currentToken = IERC20(getCurrentToken());
        require(address(currentToken) == assetShort, "Can only long when short");

        uint256 currentTokenBalance = currentToken.balanceOf(address(basket));

        address[] memory targets = new address[](4);
        bytes[] memory data = new bytes[](4);
        uint256[] memory values = new uint256[](4);

        // lock pool
        targets[0] = address(basket);
        // lock for 30
        data[0] = setLockData(block.number + 30);

        // Swap on synthetix
        targets[1] = address(synthetix);
        data[1] = abi.encodeWithSelector(synthetix.exchange.selector, assetShortKey, currentTokenBalance, assetLongKey);


        // Remove current token
        targets[2] = address(basket);
        data[2] = abi.encodeWithSelector(basket.removeToken.selector, assetShort);

        // Add new token
        targets[3] = address(basket);
        data[3] = abi.encodeWithSelector(basket.addToken.selector, assetLong);

        // Do calls
        basket.call(targets, data, values);

        // sanity checks
        require(currentToken.balanceOf(address(basket)) == 0, "Current token balance should be zero");
        require(IERC20(assetLong).balanceOf(address(basket)) >= 10**6, "Amount too small");

        emit Rebalanced(address(basket), assetShort, assetLong);
    }

    function short() internal {
        IERC20 currentToken = IERC20(getCurrentToken());
        require(address(currentToken) == assetLong, "Can only short when long");

        uint256 currentTokenBalance = currentToken.balanceOf(address(basket));

        address[] memory targets = new address[](4);
        bytes[] memory data = new bytes[](4);
        uint256[] memory values = new uint256[](4);

        // lock pool
        targets[0] = address(basket);
        // lock for 30
        data[0] = setLockData(block.number + 30);

        // Swap on synthetix
        targets[1] = address(synthetix);
        data[1] = abi.encodeWithSelector(synthetix.exchange.selector, assetLongKey, currentTokenBalance, assetShortKey);

        // Remove current token
        targets[2] = address(basket);
        data[2] = abi.encodeWithSelector(basket.removeToken.selector, assetLong);

        // Add new token
        targets[3] = address(basket);
        data[3] = abi.encodeWithSelector(basket.addToken.selector, assetShort);

        // Do calls
        basket.call(targets, data, values);

        // sanity checks
        require(currentToken.balanceOf(address(basket)) == 0, "Current token balance should be zero");
        
        // Catched by addToken in the basket itself
        // require(IERC20(assetShort).balanceOf(address(basket)) >= 10**6, "Amount too small");

        emit Rebalanced(address(basket), assetShort, assetLong);
    }

    function getCurrentToken() public view returns(address) {
        address[] memory tokens = basket.getTokens();
        require(tokens.length == 1, "RSI Pie can only have 1 asset at the time");
        return tokens[0];
    }


    function setLockData(uint256 _block) internal returns(bytes memory data) {
        bytes memory data = abi.encodeWithSelector(basket.setLock.selector, _block);
        return data;
    }
    function readRound(uint256 _round) public view returns(RoundData memory data) {
        (
            uint80 roundId, 
            int256 answer, 
            uint256 startedAt, 
            uint256 updatedAt, 
            uint80 answeredInRound
        ) = priceFeed.getRoundData(uint80(_round));

        return RoundData({
            roundId: roundId,
            answer: answer,
            startedAt: startedAt,
            updatedAt: updatedAt,
            answeredInRound: answeredInRound
        });
    }

    function readLatestRound() public view returns(RoundData memory data) {
        (
            uint80 roundId, 
            int256 answer, 
            uint256 startedAt, 
            uint256 updatedAt, 
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return RoundData({
            roundId: roundId,
            answer: answer,
            startedAt: startedAt,
            updatedAt: updatedAt,
            answeredInRound: answeredInRound
        });
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface ISynthetix {
    function exchange(bytes32 sourceCurrencyKey, uint256 sourceAmount, bytes32 destinationCurrencyKey) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;


interface IPriceReferenceFeed {
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId, 
        int256 answer, 
        uint256 startedAt, 
        uint256 updatedAt, 
        uint80 answeredInRound
    );
    function latestRoundData() external view returns (
        uint80 roundId, 
        int256 answer, 
        uint256 startedAt, 
        uint256 updatedAt, 
        uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IExperiPie.sol";

contract TokenListUpdater is Ownable, ReentrancyGuard {

    modifier ownerOrPie(address _pie) {
        require(msg.sender == owner() ||
        msg.sender == _pie, "Not allowed");
        _;
    }

    uint256 public constant MIN_AMOUNT = 10**6;

    function update(address _pie, address[] calldata _tokens) ownerOrPie(_pie) nonReentrant external {
        IExperiPie pie = IExperiPie(_pie);

        for(uint256 i = 0; i < _tokens.length; i ++) {
            uint256 tokenBalance = pie.balance(_tokens[i]);
            
            if(tokenBalance >= MIN_AMOUNT && !pie.getTokenInPool(_tokens[i])) {
                //if min amount reached and not already in pool
                bytes memory data = abi.encodeWithSelector(pie.addToken.selector, _tokens[i]);
                pie.singleCall(address(pie), data, 0);
            } else if(tokenBalance < MIN_AMOUNT && pie.getTokenInPool(_tokens[i])) {
                // if smaller than min amount and in pool
                bytes memory data = abi.encodeWithSelector(pie.removeToken.selector, _tokens[i]);
                pie.singleCall(address(pie), data, 0);
            }
        }        
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/IBasketFacet.sol";
import "../ERC20/LibERC20Storage.sol";
import "../ERC20/LibERC20.sol";
import "../shared/Reentry/ReentryProtection.sol";
import "../shared/Access/CallProtection.sol";
import "./LibBasketStorage.sol";

contract BasketFacet is ReentryProtection, CallProtection, IBasketFacet {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MIN_AMOUNT = 10**6;
    uint256 public constant MAX_ENTRY_FEE = 10**17; // 10%
    uint256 public constant MAX_EXIT_FEE = 10**17; // 10%
    uint256 public constant MAX_ANNUAL_FEE = 10**17; // 10%
    uint256 public constant HUNDRED_PERCENT = 10 ** 18;

    // Assuming a block gas limit of 12M this allows for a gas consumption per token of roughly 333k allowing 2M of overhead for addtional operations
    uint256 public constant MAX_TOKENS = 30;

    function addToken(address _token) external override protectedCall {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        require(!bs.inPool[_token], "TOKEN_ALREADY_IN_POOL");
        require(bs.tokens.length < MAX_TOKENS, "TOKEN_LIMIT_REACHED");
        // Enforce minimum to avoid rounding errors; (Minimum value is the same as in Balancer)
        require(balance(_token) >= MIN_AMOUNT, "BALANCE_TOO_SMALL");

        bs.inPool[_token] = true;
        bs.tokens.push(IERC20(_token));

        emit TokenAdded(_token);
    }

    function removeToken(address _token) external override protectedCall {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();

        require(bs.inPool[_token], "TOKEN_NOT_IN_POOL");

        bs.inPool[_token] = false;

        // remove token from array
        for(uint256 i; i < bs.tokens.length; i ++) {
            if(address(bs.tokens[i]) == _token) {
                bs.tokens[i] = bs.tokens[bs.tokens.length - 1];
                bs.tokens.pop();
                emit TokenRemoved(_token);
                break;
            }
        }
    }

    function setEntryFee(uint256 _fee) external override protectedCall {
        require(_fee <= MAX_ENTRY_FEE, "FEE_TOO_BIG");
        LibBasketStorage.basketStorage().entryFee = _fee;
        emit EntryFeeSet(_fee);
    }

    function getEntryFee() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().entryFee;
    }

    function setExitFee(uint256 _fee) external override protectedCall {
        require(_fee <= MAX_EXIT_FEE, "FEE_TOO_BIG");
        LibBasketStorage.basketStorage().exitFee = _fee;
        emit ExitFeeSet(_fee);
    }

    function getExitFee() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().exitFee;
    }

    function setAnnualizedFee(uint256 _fee) external override protectedCall {
        chargeOutstandingAnnualizedFee();
        require(_fee <= MAX_ANNUAL_FEE, "FEE_TOO_BIG");
        LibBasketStorage.basketStorage().annualizedFee = _fee;
        emit AnnualizedFeeSet(_fee);
    }

    function getAnnualizedFee() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().annualizedFee;
    }

    function setFeeBeneficiary(address _beneficiary) external override protectedCall {
        chargeOutstandingAnnualizedFee();
        LibBasketStorage.basketStorage().feeBeneficiary = _beneficiary;
        emit FeeBeneficiarySet(_beneficiary);
    }

    function getFeeBeneficiary() external view override returns(address) {
        return LibBasketStorage.basketStorage().feeBeneficiary;
    }

    function setEntryFeeBeneficiaryShare(uint256 _share) external override protectedCall {
        require(_share <= HUNDRED_PERCENT, "FEE_SHARE_TOO_BIG");
        LibBasketStorage.basketStorage().entryFeeBeneficiaryShare = _share;
        emit EntryFeeBeneficiaryShareSet(_share);
    }

    function getEntryFeeBeneficiaryShare() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().entryFeeBeneficiaryShare;
    }

    function setExitFeeBeneficiaryShare(uint256 _share) external override protectedCall {
        require(_share <= HUNDRED_PERCENT, "FEE_SHARE_TOO_BIG");
        LibBasketStorage.basketStorage().exitFeeBeneficiaryShare = _share;
        emit ExitFeeBeneficiaryShareSet(_share);
    }

    function getExitFeeBeneficiaryShare() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().exitFeeBeneficiaryShare;
    }


    function joinPool(uint256 _amount) external override noReentry {
        require(!this.getLock(), "POOL_LOCKED");
        chargeOutstandingAnnualizedFee();
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply;
        require(totalSupply.add(_amount) <= this.getCap(), "MAX_POOL_CAP_REACHED");

        uint256 feeAmount = _amount.mul(bs.entryFee).div(10**18);

        for(uint256 i; i < bs.tokens.length; i ++) {
            IERC20 token = bs.tokens[i];
            uint256 tokenAmount = balance(address(token)).mul(_amount.add(feeAmount)).div(totalSupply);
            require(tokenAmount != 0, "AMOUNT_TOO_SMALL");
            token.safeTransferFrom(msg.sender, address(this), tokenAmount);
        }

        // If there is any fee that should go to the beneficiary mint it
        if(
            feeAmount != 0 &&
            bs.entryFeeBeneficiaryShare != 0 &&
            bs.feeBeneficiary != address(0)
        ) {
            uint256 feeBeneficiaryShare = feeAmount.mul(bs.entryFeeBeneficiaryShare).div(10**18);
            if(feeBeneficiaryShare != 0) {
                LibERC20.mint(bs.feeBeneficiary, feeBeneficiaryShare);
            }
        }

        LibERC20.mint(msg.sender, _amount);
        emit PoolJoined(msg.sender, _amount);
    }

    // Must be overwritten to withdraw from strategies
    function exitPool(uint256 _amount) external override virtual noReentry {
        require(!this.getLock(), "POOL_LOCKED");
        chargeOutstandingAnnualizedFee();
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply;

        uint256 feeAmount = _amount.mul(bs.exitFee).div(10**18);

        for(uint256 i; i < bs.tokens.length; i ++) {
            IERC20 token = bs.tokens[i];
            uint256 tokenBalance = balance(address(token));
            // redeem less tokens if there is an exit fee
            uint256 tokenAmount = tokenBalance.mul(_amount.sub(feeAmount)).div(totalSupply);
            require(tokenBalance.sub(tokenAmount) >= MIN_AMOUNT, "TOKEN_BALANCE_TOO_LOW");
            token.safeTransfer(msg.sender, tokenAmount);
        }

         // If there is any fee that should go to the beneficiary mint it
        if(
            feeAmount != 0 &&
            bs.exitFeeBeneficiaryShare != 0 &&
            bs.feeBeneficiary != address(0)
        ) {
            uint256 feeBeneficiaryShare = feeAmount.mul(bs.exitFeeBeneficiaryShare).div(10**18);
            if(feeBeneficiaryShare != 0) {
                LibERC20.mint(bs.feeBeneficiary, feeBeneficiaryShare);
            }
        }

        require(totalSupply.sub(_amount) >= MIN_AMOUNT, "POOL_TOKEN_BALANCE_TOO_LOW");
        LibERC20.burn(msg.sender, _amount);
        emit PoolExited(msg.sender, _amount);
    }


    function calcOutStandingAnnualizedFee() public view override returns(uint256) {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply;

        uint256 lastFeeClaimed = bs.lastAnnualizedFeeClaimed;
        uint256 annualizedFee = bs.annualizedFee;

        if(
            annualizedFee == 0 ||
            bs.feeBeneficiary == address(0) ||
            lastFeeClaimed == 0
        ) {
            return 0;
        }

        uint256 timePassed = block.timestamp.sub(lastFeeClaimed);

        return totalSupply.mul(annualizedFee).div(10**18).mul(timePassed).div(365 days);
    }

    function chargeOutstandingAnnualizedFee() public override {
        uint256 outStandingFee = calcOutStandingAnnualizedFee();
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();

        bs.lastAnnualizedFeeClaimed = block.timestamp;

        // if there is any fee to mint and the beneficiary is set
        // note: feeBeneficiary is already checked in calc function
        if(
            outStandingFee != 0
        ) {
            LibERC20.mint(bs.feeBeneficiary, outStandingFee);
        }

        emit FeeCharged(outStandingFee);
    }

    // returns true when locked
    function getLock() external view override returns(bool) {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        return bs.lockBlock == 0 || bs.lockBlock >= block.number;
    }

    function getTokenInPool(address _token) external view override returns(bool) {
        return LibBasketStorage.basketStorage().inPool[_token];
    }

    function getLockBlock() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().lockBlock;
    }

    // lock up to and including _lock blocknumber
    function setLock(uint256 _lock) external override protectedCall {
        LibBasketStorage.basketStorage().lockBlock = _lock;
        emit LockSet(_lock);
    }

    function setCap(uint256 _maxCap) external override protectedCall {
        LibBasketStorage.basketStorage().maxCap = _maxCap;
        emit CapSet(_maxCap);
    }

    // Seperated balance function to allow yearn like strategies to be hooked up by inheriting from this contract and overriding
    function balance(address _token) public view override returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function getTokens() external view override returns (address[] memory) {
        IERC20[] memory tokens = LibBasketStorage.basketStorage().tokens;
        address[] memory result = new address[](tokens.length);

        for(uint256 i = 0; i < tokens.length; i ++) {
            result[i] = address(tokens[i]);
        }

        return(result);
    }

    function getCap() external view override returns(uint256){
        return LibBasketStorage.basketStorage().maxCap;
    }

    function calcTokensForAmount(uint256 _amount) external view override returns (address[] memory tokens, uint256[] memory amounts) {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply.add(calcOutStandingAnnualizedFee());

        tokens = new address[](bs.tokens.length);
        amounts = new uint256[](bs.tokens.length);

        for(uint256 i; i < bs.tokens.length; i ++) {
            IERC20 token = bs.tokens[i];
            uint256 tokenBalance = balance(address(token));
            uint256 tokenAmount = tokenBalance.mul(_amount).div(totalSupply);
            // Add entry fee
            tokenAmount = tokenAmount.add(tokenAmount.mul(bs.entryFee).div(10**18));

            tokens[i] = address(token);
            amounts[i] = tokenAmount;
        }

        return(tokens, amounts);
    }

    function calcTokensForAmountExit(uint256 _amount) external view override returns (address[] memory tokens, uint256[] memory amounts) {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 feeAmount = _amount.mul(bs.exitFee).div(10**18);
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply.add(calcOutStandingAnnualizedFee());

        tokens = new address[](bs.tokens.length);
        amounts = new uint256[](bs.tokens.length);

        for(uint256 i; i < bs.tokens.length; i ++) {
            IERC20 token = bs.tokens[i];
            uint256 tokenBalance = balance(address(token));
            uint256 tokenAmount = tokenBalance.mul(_amount.sub(feeAmount)).div(totalSupply);

            tokens[i] = address(token);
            amounts[i] = tokenAmount;
        }

        return(tokens, amounts);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

library LibERC20Storage {
  bytes32 constant ERC_20_STORAGE_POSITION = keccak256(
    // Compatible with pie-smart-pools
    "PCToken.storage.location"
  );

  struct ERC20Storage {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
  }

  function erc20Storage() internal pure returns (ERC20Storage storage es) {
    bytes32 position = ERC_20_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./LibERC20Storage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library LibERC20 {
  using SafeMath for uint256;

  // Need to include events locally because `emit Interface.Event(params)` does not work
  event Transfer(address indexed from, address indexed to, uint256 amount);

  function mint(address _to, uint256 _amount) internal {
    require(_to != address(0), "INVALID_TO_ADDRESS");

    LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();

    es.balances[_to] = es.balances[_to].add(_amount);
    es.totalSupply = es.totalSupply.add(_amount);
    emit Transfer(address(0), _to, _amount);
  }

  function burn(address _from, uint256 _amount) internal {
    LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();

    es.balances[_from] = es.balances[_from].sub(_amount);
    es.totalSupply = es.totalSupply.sub(_amount);
    emit Transfer(_from, address(0), _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./LibReentryProtectionStorage.sol";

contract ReentryProtection {
  modifier noReentry {
    // Use counter to only write to storage once
    LibReentryProtectionStorage.RPStorage storage s = LibReentryProtectionStorage.rpStorage();
    s.lockCounter++;
    uint256 lockValue = s.lockCounter;
    _;
    require(
      lockValue == s.lockCounter,
      "ReentryProtectionFacet.noReentry: reentry detected"
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

library LibReentryProtectionStorage {
  bytes32 constant REENTRY_STORAGE_POSITION = keccak256(
    "diamond.standard.reentry.storage"
  );

  struct RPStorage {
    uint256 lockCounter;
  }

  function rpStorage() internal pure returns (RPStorage storage bs) {
    bytes32 position = REENTRY_STORAGE_POSITION;
    assembly {
      bs.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@pie-dao/diamond/contracts/libraries/LibDiamond.sol";

contract CallProtection {
    modifier protectedCall() {
        require(
            msg.sender == LibDiamond.diamondStorage().contractOwner ||
            msg.sender == address(this), "NOT_ALLOWED"
            // TODO consider allowing whitelisted callers from the callFacet
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of Diamond facet.
* This is gas optimized by reducing storage reads and storage writes.
* This code is as complex as it is to reduce gas costs.
/******************************************************************************/

import "../interfaces/IDiamondCut.sol";

library LibDiamond {
        bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.        
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // owner of the contract
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
   
   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() view internal {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    modifier onlyOwner {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
        _;
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount % 8 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount / 8];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount % 8 > 0) {
            ds.selectorSlots[selectorCount / 8] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");        
        if (_action == IDiamondCut.FacetCutAction.Add) {
            require(_newFacetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];                
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector                                
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);                
                uint256 selectorInSlotPosition = (_selectorCount % 8) * 32;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount / 8] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if(_action == IDiamondCut.FacetCutAction.Replace) {
            require(_newFacetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];  
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if(_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            uint256 selectorSlotCount = _selectorCount / 8;
            uint256 selectorInSlotIndex = (_selectorCount % 8) - 1;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex * 32));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount / 8;
                    oldSelectorInSlotPosition = (oldSelectorCount % 8) * 32;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
                selectorInSlotIndex--;
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex + 1;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }       
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibBasketStorage {
  bytes32 constant BASKET_STORAGE_POSITION = keccak256(
    "diamond.standard.basket.storage"
  );

  struct BasketStorage {
    uint256 lockBlock;
    uint256 maxCap;
    IERC20[] tokens;
    mapping(address => bool) inPool;
    uint256 entryFee;
    uint256 entryFeeBeneficiaryShare; // amount of entry fee that goes to feeBeneficiary
    uint256 exitFee;
    uint256 exitFeeBeneficiaryShare; // amount of exit fee that goes to the pool itself
    uint256 annualizedFee;
    uint256 lastAnnualizedFeeClaimed;
    address feeBeneficiary;
  }

  function basketStorage() internal pure returns (BasketStorage storage bs) {
    bytes32 position = BASKET_STORAGE_POSITION;
    assembly {
      bs.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@pie-dao/diamond/contracts/libraries/LibDiamond.sol";
import "../../interfaces/ICallFacet.sol";
import "../shared/Reentry/ReentryProtection.sol";
import "../shared/Access/CallProtection.sol";
import "./LibCallStorage.sol";

contract CallFacet is ReentryProtection, ICallFacet {

  uint256 public constant MAX_CALLERS = 50;

  // uses modified call protection modifier to also allow whitelisted addresses to call
  modifier protectedCall() {
    require(
        msg.sender == LibDiamond.diamondStorage().contractOwner ||
        LibCallStorage.callStorage().canCall[msg.sender] ||
        msg.sender == address(this), "NOT_ALLOWED"
    );
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == LibDiamond.diamondStorage().contractOwner, "NOT_ALLOWED");
    _;
  }

  function addCaller(address _caller) external override onlyOwner {
    LibCallStorage.CallStorage storage callStorage = LibCallStorage.callStorage();

    require(callStorage.callers.length < MAX_CALLERS, "TOO_MANY_CALLERS");
    require(!callStorage.canCall[_caller], "IS_ALREADY_CALLER");
    require(_caller != address(0), "INVALID_CALLER");

    callStorage.callers.push(_caller);
    callStorage.canCall[_caller] = true;

    emit CallerAdded(_caller);
  }

  function removeCaller(address _caller) external override onlyOwner {
    LibCallStorage.CallStorage storage callStorage = LibCallStorage.callStorage();

    require(callStorage.canCall[_caller], "IS_NOT_CALLER");

    callStorage.canCall[_caller] = false;

    for(uint256 i = 0; i < callStorage.callers.length; i ++) {
      address currentCaller = callStorage.callers[i];

      // if found remove it
      if(currentCaller == _caller) {
        callStorage.callers[i] = callStorage.callers[callStorage.callers.length - 1];
        callStorage.callers.pop();
        break;
      }
    }

    emit CallerRemoved(_caller);
  }

  function call(
    address[] memory _targets,
    bytes[] memory _calldata,
    uint256[] memory _values
  ) public override noReentry protectedCall {
    require(
      _targets.length == _calldata.length && _values.length == _calldata.length,
      "ARRAY_LENGTH_MISMATCH"
    );

    for (uint256 i = 0; i < _targets.length; i++) {
      _call(_targets[i], _calldata[i], _values[i]);
    }
  }

  function callNoValue(
    address[] memory _targets,
    bytes[] memory _calldata
  ) public override noReentry protectedCall {
    require(
      _targets.length == _calldata.length,
      "ARRAY_LENGTH_MISMATCH"
    );

    for (uint256 i = 0; i < _targets.length; i++) {
      _call(_targets[i], _calldata[i], 0);
    }
  }

  function singleCall(
    address _target,
    bytes calldata _calldata,
    uint256 _value
  ) external override noReentry protectedCall {
    _call(_target, _calldata, _value);
  }

  function _call(
    address _target,
    bytes memory _calldata,
    uint256 _value
  ) internal {
    require(address(this).balance >= _value, "ETH_BALANCE_TOO_LOW");
    (bool success, ) = _target.call{ value: _value }(_calldata);
    require(success, "CALL_FAILED");
    emit Call(msg.sender, _target, _calldata, _value);
  }

  function canCall(address _caller) external view override returns (bool) {
    return LibCallStorage.callStorage().canCall[_caller];
  }

  function getCallers() external view override returns (address[] memory) {
    return LibCallStorage.callStorage().callers;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

library LibCallStorage {
  bytes32 constant CALL_STORAGE_POSITION = keccak256(
    "diamond.standard.call.storage"
  );

  struct CallStorage {
    mapping(address => bool) canCall;
    address[] callers;
  }

  function callStorage() internal pure returns (CallStorage storage cs) {
    bytes32 position = CALL_STORAGE_POSITION;
    assembly {
      cs.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@pie-dao/diamond/contracts/libraries/LibDiamond.sol";

import "../../interfaces/IERC20Facet.sol";
import "./LibERC20Storage.sol";
import "./LibERC20.sol";
import "../shared/Access/CallProtection.sol";

contract ERC20Facet is IERC20, IERC20Facet, CallProtection {
  using SafeMath for uint256;

  function initialize(
    uint256 _initialSupply,
    string memory _name,
    string memory _symbol
  ) external override {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();

    require(
      bytes(es.name).length == 0 &&
      bytes(es.symbol).length == 0,
      "ALREADY_INITIALIZED"
    );

    require(
      bytes(_name).length != 0 &&
      bytes(_symbol).length != 0,
      "INVALID_PARAMS"
    );

    require(msg.sender == ds.contractOwner, "Must own the contract.");

    LibERC20.mint(msg.sender, _initialSupply);

    es.name = _name;
    es.symbol = _symbol;
  }

  function name() external view override returns (string memory) {
    return LibERC20Storage.erc20Storage().name;
  }

  function setName(string calldata _name) external override protectedCall {
    LibERC20Storage.erc20Storage().name = _name;
  }

  function symbol() external view override returns (string memory) {
    return LibERC20Storage.erc20Storage().symbol;
  }

  function setSymbol(string calldata _symbol) external override protectedCall {
    LibERC20Storage.erc20Storage().symbol = _symbol;
  }

  function decimals() external pure override returns (uint8) {
    return 18;
  }

  function mint(address _receiver, uint256 _amount) external override protectedCall {
    LibERC20.mint(_receiver, _amount);
  }

  function burn(address _from, uint256 _amount) external override protectedCall {
    LibERC20.burn(_from, _amount);
  }

  function approve(address _spender, uint256 _amount)
    external
    override
    returns (bool)
  {
    require(_spender != address(0), "SPENDER_INVALID");
    LibERC20Storage.erc20Storage().allowances[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  function increaseApproval(address _spender, uint256 _amount) external override returns (bool) {
    require(_spender != address(0), "SPENDER_INVALID");
    LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();
    es.allowances[msg.sender][_spender] = es.allowances[msg.sender][_spender].add(_amount);
    emit Approval(msg.sender, _spender, es.allowances[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _amount) external override returns (bool) {
    require(_spender != address(0), "SPENDER_INVALID");
    LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();
    uint256 oldValue = es.allowances[msg.sender][_spender];
    if (_amount > oldValue) {
      es.allowances[msg.sender][_spender] = 0;
    } else {
      es.allowances[msg.sender][_spender] = oldValue.sub(_amount);
    }
    emit Approval(msg.sender, _spender, es.allowances[msg.sender][_spender]);
    return true;
  }

  function transfer(address _to, uint256 _amount)
    external
    override
    returns (bool)
  {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) external override returns (bool) {
    LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();
    require(_from != address(0), "FROM_INVALID");

    // Update approval if not set to max uint256
    if (es.allowances[_from][msg.sender] != uint256(-1)) {
      uint256 newApproval = es.allowances[_from][msg.sender].sub(_amount);
      es.allowances[_from][msg.sender] = newApproval;
      emit Approval(_from, msg.sender, newApproval);
    }

    _transfer(_from, _to, _amount);
    return true;
  }

  function allowance(address _owner, address _spender)
    external
    view
    override
    returns (uint256)
  {
    return LibERC20Storage.erc20Storage().allowances[_owner][_spender];
  }

  function balanceOf(address _of) external view override returns (uint256) {
    return LibERC20Storage.erc20Storage().balances[_of];
  }

  function totalSupply() external view override returns (uint256) {
    return LibERC20Storage.erc20Storage().totalSupply;
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal {
    LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();

    es.balances[_from] = es.balances[_from].sub(_amount);
    es.balances[_to] = es.balances[_to].add(_amount);

    emit Transfer(_from, _to, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "@pie-dao/diamond/contracts/Diamond.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@pie-dao/proxy/contracts/PProxy.sol";

import "../interfaces/IExperiPie.sol";

contract PieFactoryContract is Ownable {
    using SafeERC20 for IERC20;

    address[] public pies;
    mapping(address => bool) public isPie;
    address public defaultController;
    address public diamondImplementation;

    IDiamondCut.FacetCut[] public defaultCut;

    event PieCreated(
        address indexed pieAddress,
        address indexed deployer,
        uint256 indexed index
    );

    event DefaultControllerSet(address indexed controller);
    event FacetAdded(IDiamondCut.FacetCut);
    event FacetRemoved(IDiamondCut.FacetCut);

    constructor() {
        defaultController = msg.sender;
    }

    function setDefaultController(address _controller) external onlyOwner {
        defaultController = _controller;
        emit DefaultControllerSet(_controller);
    }

    function removeFacet(uint256 _index) external onlyOwner {
        require(_index < defaultCut.length, "INVALID_INDEX");
        emit FacetRemoved(defaultCut[_index]);
        defaultCut[_index] = defaultCut[defaultCut.length - 1];
        defaultCut.pop();
    }

    function addFacet(IDiamondCut.FacetCut memory _facet) external onlyOwner {
        defaultCut.push(_facet);
        emit FacetAdded(_facet);
    }

    // Diamond should be Initialized to prevent it from being selfdestructed
    function setDiamondImplementation(address _diamondImplementation) external onlyOwner {
        diamondImplementation = _diamondImplementation;
    }

    function bakePie(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _initialSupply,
        string memory _symbol,
        string memory _name
    ) external {
        PProxy proxy = new PProxy();
        Diamond d = Diamond(address(proxy));

        proxy.setImplementation(diamondImplementation);

        d.initialize(defaultCut, address(this));

        pies.push(address(d));
        isPie[address(d)] = true;

        // emit DiamondCreated(address(d));
        require(_tokens.length != 0, "CANNOT_CREATE_ZERO_TOKEN_LENGTH_PIE");
        require(_tokens.length == _amounts.length, "ARRAY_LENGTH_MISMATCH");

        IExperiPie pie = IExperiPie(address(d));

        // Init erc20 facet
        pie.initialize(_initialSupply, _name, _symbol);

        // Transfer and add tokens
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            token.safeTransferFrom(msg.sender, address(pie), _amounts[i]);
            pie.addToken(_tokens[i]);
        }

        // Unlock pool
        pie.setLock(1);

        // Uncap pool
        pie.setCap(uint256(-1));

        // Send minted pie to msg.sender
        pie.transfer(msg.sender, _initialSupply);
        pie.transferOwnership(defaultController);
        proxy.setProxyOwner(defaultController);

        emit PieCreated(address(d), msg.sender, pies.length - 1);
    }

    function getDefaultCut()
        external
        view
        returns (IDiamondCut.FacetCut[] memory)
    {
        return defaultCut;
    }

    function getDefaultCutCount() external view returns (uint256) {
        return defaultCut.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
*
* Implementation of a diamond.
/******************************************************************************/

import "./libraries/LibDiamond.sol";
import "./libraries/LibDiamondInitialize.sol";
import "./interfaces/IDiamondLoupe.sol";
import "./interfaces/IDiamondCut.sol";
import "./interfaces/IERC173.sol";
import "./interfaces/IERC165.sol";

contract Diamond {
    function initialize(IDiamondCut.FacetCut[] memory _diamondCut, address _owner) external payable {
        require(LibDiamondInitialize.diamondInitializeStorage().initialized == false, "ALREADY_INITIALIZED");
        LibDiamondInitialize.diamondInitializeStorage().initialized = true;
        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));
        LibDiamond.setContractOwner(_owner);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Mick de Graaf
*
* Tracks if the contract is already intialized or not
/******************************************************************************/

import "../interfaces/IDiamondCut.sol";

library LibDiamondInitialize {
    bytes32 constant DIAMOND_INITIALIZE_STORAGE_POSITION = keccak256("diamond.standard.initialize.diamond.storage");

    struct InitializedStorage {
        bool initialized;
    }

    function diamondInitializeStorage() internal pure returns (InitializedStorage storage ids) {
        bytes32 position = DIAMOND_INITIALIZE_STORAGE_POSITION;
        assembly {
            ids.slot := position
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.7.1;

import "./PProxyStorage.sol";

contract PProxy is PProxyStorage {

    bytes32 constant IMPLEMENTATION_SLOT = keccak256(abi.encodePacked("IMPLEMENTATION_SLOT"));
    bytes32 constant OWNER_SLOT = keccak256(abi.encodePacked("OWNER_SLOT"));

    modifier onlyProxyOwner() {
        require(msg.sender == readAddress(OWNER_SLOT), "PProxy.onlyProxyOwner: msg sender not owner");
        _;
    }

    constructor () public {
        setAddress(OWNER_SLOT, msg.sender);
    }

    function getProxyOwner() public view returns (address) {
       return readAddress(OWNER_SLOT);
    }

    function setProxyOwner(address _newOwner) onlyProxyOwner public {
        setAddress(OWNER_SLOT, _newOwner);
    }

    function getImplementation() public view returns (address) {
        return readAddress(IMPLEMENTATION_SLOT);
    }

    function setImplementation(address _newImplementation) onlyProxyOwner public {
        setAddress(IMPLEMENTATION_SLOT, _newImplementation);
    }


    fallback () external payable {
       return internalFallback();
    }

    function internalFallback() internal virtual {
        address contractAddr = readAddress(IMPLEMENTATION_SLOT);
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), contractAddr, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

}

pragma solidity ^0.7.1;

contract PProxyStorage {

    function readBool(bytes32 _key) public view returns(bool) {
        return storageRead(_key) == bytes32(uint256(1));
    }

    function setBool(bytes32 _key, bool _value) internal {
        if(_value) {
            storageSet(_key, bytes32(uint256(1)));
        } else {
            storageSet(_key, bytes32(uint256(0)));
        }
    }

    function readAddress(bytes32 _key) public view returns(address) {
        return bytes32ToAddress(storageRead(_key));
    }

    function setAddress(bytes32 _key, address _value) internal {
        storageSet(_key, addressToBytes32(_value));
    }

    function storageRead(bytes32 _key) public view returns(bytes32) {
        bytes32 value;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            value := sload(_key)
        }
        return value;
    }

    function storageSet(bytes32 _key, bytes32 _value) internal {
        // targetAddress = _address;  // No!
        bytes32 implAddressStorageKey = _key;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(implAddressStorageKey, _value)
        }
    }

    function bytes32ToAddress(bytes32 _value) public pure returns(address) {
        return address(uint160(uint256(_value)));
    }

    function addressToBytes32(address _value) public pure returns(bytes32) {
        return bytes32(uint256(_value));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@pie-dao/diamond/contracts/facets/DiamondCutFacet.sol";
import "@pie-dao/diamond/contracts/facets/DiamondLoupeFacet.sol";
import "@pie-dao/diamond/contracts/facets/OwnershipFacet.sol";


// Get the compiler and typechain to pick up these facets
contract Imports {
    DiamondCutFacet public diamondCutFacet;
    DiamondLoupeFacet public diamondLoupeFacet;
    OwnershipFacet public ownershipFacet;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

import "../interfaces/IDiamondCut.sol";
import "../libraries/LibDiamond.sol";

contract DiamondCutFacet is IDiamondCut {
    // Standard diamondCut external function
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount % 8 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount / 8];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = LibDiamond.addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount % 8 > 0) {
            ds.selectorSlots[selectorCount / 8] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        LibDiamond.initializeDiamondCut(_init, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

import "../libraries/LibDiamond.sol";
import "../interfaces/IDiamondLoupe.sol";
import "../interfaces/IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external override view returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facets_ = new Facet[](ds.selectorCount);
        uint8[] memory numFacetSelectors = new uint8[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex * 32));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop = false;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facets_[facetIndex].facetAddress == facetAddress_) {
                        facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continueLoop = false;
                    continue;
                }
                facets_[numFacets].facetAddress = facetAddress_;
                facets_[numFacets].functionSelectors = new bytes4[](ds.selectorCount);
                facets_[numFacets].functionSelectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return _facetFunctionSelectors The selectors associated with a facet address.
    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory _facetFunctionSelectors) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](ds.selectorCount);
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex * 32));
                address facet = address(bytes20(ds.facets[selector]));
                if (_facet == facet) {
                    _facetFunctionSelectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = new address[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex * 32));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop = false;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facetAddress_ == facetAddresses_[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continueLoop = false;
                    continue;
                }
                facetAddresses_[numFacets] = facetAddress_;
                numFacets++;
            }
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = address(bytes20(ds.facets[_functionSelector]));
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "../libraries/LibDiamond.sol";
import "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "@pie-dao/diamond/contracts/Diamond.sol";

contract DiamondFactoryContract {
    event DiamondCreated(address tokenAddress);

    address[] public diamonds;
    mapping(address => bool) public isDiamond;

    function deployNewDiamond(
        address _owner,
        IDiamondCut.FacetCut[] memory _diamondCut
    ) public returns (address) {
        Diamond d = new Diamond();
        d.initialize(_diamondCut, _owner);

        diamonds.push(address(d));
        isDiamond[address(d)] = true;

        emit DiamondCreated(address(d));
    }

    function getDiamondCount() external view returns (uint256) {
        return diamonds.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./MockToken.sol";

contract ERC20FactoryContract {
    event TokenCreated(address tokenAddress);

    function deployNewToken(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _issuer
    ) public returns (address) {
        MockToken t = new MockToken(_name, _symbol);
        t.mint(_totalSupply, _issuer);
        emit TokenCreated(address(t));
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    function mint(uint256 _amount, address _issuer) external {
        _mint(_issuer, _amount);
    }

    function burn(uint256 _amount, address _from) external {
        _burn(_from, _amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPriceReferenceFeed.sol";

contract ManualPriceReferenceFeed is Ownable, IPriceReferenceFeed {
    uint256 public latestResult;
    uint256 public lastUpdate;

    function update(uint256 _value) external onlyOwner {
        latestResult = _value;
        lastUpdate = block.timestamp;
    }

    function getRoundData(uint80 _roundId) external override view returns (
        uint80 roundId, 
        int256 answer, 
        uint256 startedAt, 
        uint256 updatedAt, 
        uint80 answeredInRound
    ) {
        require(false, "NOT_SUPPORTED");
    }
    function latestRoundData() external override view returns (
        uint80 roundId, 
        int256 answer, 
        uint256 startedAt, 
        uint256 updatedAt, 
        uint80 answeredInRound
    ) {
        updatedAt = lastUpdate;
        answer = int256(latestResult);
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "../interfaces/IAaveLendingPool.sol";
import "./MockToken.sol";

contract MockAaveLendingPool is IAaveLendingPool {
    IERC20 public token;
    MockToken public aToken;

    bool public revertDeposit;

    constructor(address _token, address _aToken) public {
        token = IERC20(_token);
        aToken = MockToken(_aToken);
    }

    function deposit(address _reserve, uint256 _amount, uint16 _refferalCode) external override {
        require(!revertDeposit, "Deposited revert");
        require(token.transferFrom(msg.sender, address(aToken), _amount), "Transfer failed");
        aToken.mint(_amount, msg.sender);
    }

    function setRevertDeposit(bool _doRevert) external {
        revertDeposit = _doRevert;
    }

    function core() external view override returns(address) {
        return address(this);
    }

    function getReserveData(address _reserve)
        external
        override
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            address aTokenAddress,
            uint40 lastUpdateTimestamp
        ) {
            return(
                0,
                0,
                0,
                0,
                10000000000000000000000000, //1%
                0,
                0,
                0,
                0,
                0,
                0,
                address(0),
                0
            );
        }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "../interfaces/IAaveLendingPoolV2.sol";
import "./MockToken.sol";

contract MockAaveLendingPoolV2 is IAaveLendingPoolV2 {
    IERC20 public token;
    MockToken public aToken;

    bool public revertDeposit;
    bool public revertWithdraw;

    constructor(address _token, address _aToken) public {
        token = IERC20(_token);
        aToken = MockToken(_aToken);
    }

    function deposit(
        address _asset,
        uint256 _amount,
        address _onBehalfOf,
        uint16 _referralCode
    ) external override {
        require(!revertDeposit, "Deposited revert");
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        aToken.mint(_amount, msg.sender);
    }

    function withdraw(
        address _asset,
        uint256 _amount,
        address _to
    ) external override {
        require(!revertWithdraw, "Reverted");

        if (_amount == uint256(-1)) {
            _amount = aToken.balanceOf(msg.sender);
        }

        aToken.burn(_amount, msg.sender);
        require(token.transfer(msg.sender, _amount), "Transfer failed");
    }

    function getReserveData(address asset)
        external
        view
        override
        returns (DataTypes.ReserveData memory) {
        return DataTypes.ReserveData({
            configuration: DataTypes.ReserveConfigurationMap(0),
            liquidityIndex: 0,
            variableBorrowIndex: 0,
            currentLiquidityRate: 10000000000000000000000000, //1%
            currentVariableBorrowRate: 0,
            currentStableBorrowRate: 0,
            lastUpdateTimestamp: 0,
            aTokenAddress: address(0),
            stableDebtTokenAddress: address(0),
            variableDebtTokenAddress: address(0),
            interestRateStrategyAddress: address(0),
            id: 0
        });
    }



    function setRevertDeposit(bool _doRevert) external {
        revertDeposit = _doRevert;
    }
    function setRevertWithdraw(bool _doRevert) external {
        revertWithdraw = _doRevert;
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "../interfaces/IAaveLendingPool.sol";
import "./MockToken.sol";

contract MockAToken is MockToken {
    IERC20 public token;

    address public underlyingAssetAddress;
    bool public revertRedeem;

    constructor(address _token) public MockToken("MockAToken", "MATKN") {
        token = IERC20(_token);
        underlyingAssetAddress = _token;
    }

    function redeem(uint256 _amount) external {
        require(!revertRedeem, "Reverted");

        if (_amount == uint256(-1)) {
            _amount = balanceOf(msg.sender);
        }

        _burn(msg.sender, _amount);
        require(token.transfer(msg.sender, _amount), "Transfer failed");
    }

    function setRevertRedeem(bool _doRevert) external {
        revertRedeem = _doRevert;
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "../interfaces/IAaveLendingPool.sol";
import "./MockToken.sol";

contract MockATokenV2 is MockToken {
    IERC20 public token;

    address public UNDERLYING_ASSET_ADDRESS;

    constructor(address _token) public MockToken("MockATokenV2", "MATKNV2") {
        token = IERC20(_token);
        UNDERLYING_ASSET_ADDRESS = _token;
    }

}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "./MockToken.sol";
import "../interfaces/ICToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract MockCToken is MockToken, ICToken {
    using SafeMath for uint256;
    // representable value taken from cEth
    uint256 public exchangeRate = 1 ether / 5;
    MockToken public underlying;
    uint256 someValue;

    uint256 public errorCode;
    constructor(address _underlying) MockToken("cTOKEN", "cToken") public {
        underlying = MockToken(_underlying);
    }

    function mint(uint256 _amount) external override returns(uint256) {
        require(underlying.transferFrom(msg.sender, address(this), _amount), "MockCToken.mint: transferFrom failed");

        uint256 mintAmount = _amount.mul(10**18).div(exchangeRate);
        _mint(msg.sender, mintAmount);

        return errorCode;
    }

    function redeem(uint256 _amount) external override returns(uint256) {
        _burn(msg.sender, _amount);

        uint256 underlyingAmount = _amount.mul(exchangeRate).div(10**18);
        underlying.mint(underlyingAmount, msg.sender);

        return errorCode;
    }

    function redeemUnderlying(uint256 _amount) external returns(uint256) {
        uint256 internalAmount = _amount.mul(10**18).div(exchangeRate);
        _burn(msg.sender, internalAmount);

        underlying.mint(_amount, msg.sender);

        return errorCode;
    }

    function balanceOfUnderlying(address _owner) external returns(uint256) {
        return balanceOf(_owner).mul(exchangeRate).div(10**18);
    }

    function setErrorCode(uint256 _value) public {
        errorCode = _value;
    }

    function supplyRatePerBlock() external override view returns (uint256) {
        return 20000000000;
    }

    function exchangeRateCurrent() external override returns(uint256) {
        // To make function state changing
        someValue ++;
        return exchangeRate;
    }

    function exchangeRateStored() external override view returns(uint256) {
        // To make function non pure;
        someValue;
        return exchangeRate;
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "../interfaces/ILendingLogic.sol";

contract MockLendingLogic is ILendingLogic {
    uint256 private apr;

    function setAPR(uint256 _apr) public {
        apr = _apr;
    }

    function getAPRFromWrapped(address _token) external view override returns(uint256) {
        return apr;
    }

    function getAPRFromUnderlying(address _token) public view override returns(uint256) {
        return apr;
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _underlying;
        data[0] = bytes(abi.encode(_amount));
    }
    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _wrapped;
        data[0] = bytes(abi.encode(_amount));
    }

    function exchangeRate(address) external pure override returns(uint256) {
        return 10**18;
    }

    function exchangeRateView(address) external pure override returns(uint256) {
        return 10**18;
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/ISynthetix.sol";
import "./MockToken.sol";

contract MockSynthetix is ISynthetix {
    using SafeMath for uint256;

    mapping(bytes32=>MockToken) public keyToToken;
    mapping(bytes32=>uint256) public tokenPrice;

    // Mock variables to create edge cases
    uint256 public subtractSourceAmount;
    uint256 public subtractOutputAmount;

    function setSubtractSourceAmount(uint256 _amount) external {
        subtractSourceAmount = _amount;
    }

    function setSubtractOutputAmount(uint256 _amount) external {
        subtractOutputAmount = _amount;
    }

    function exchange(bytes32 _sourceCurrencyKey, uint256 _sourceAmount, bytes32 _destinationCurrencyKey) external override {
        uint256 sourcePrice = tokenPrice[_sourceCurrencyKey];
        uint256 destinationPrice = tokenPrice[_destinationCurrencyKey];
        uint256 outputAmount = _sourceAmount.mul(sourcePrice).div(destinationPrice);

        getOrSetToken(_sourceCurrencyKey).burn(_sourceAmount.sub(subtractSourceAmount), msg.sender);
        getOrSetToken(_destinationCurrencyKey).mint(outputAmount.sub(subtractOutputAmount), msg.sender);
    }

    function getOrSetToken(bytes32 _currencyKey) public returns(MockToken) {
        if(address(keyToToken[_currencyKey]) == address(0)) {
            keyToToken[_currencyKey] = new MockToken(string(abi.encode(_currencyKey)), string(abi.encode(_currencyKey)));
            tokenPrice[_currencyKey] = 1 ether;
        }

        return keyToToken[_currencyKey];
    }

    function setPrice(bytes32 _currencyKey, uint256 _price) external {
        tokenPrice[_currencyKey] = _price;
    }

    function getToken(bytes32 _currencyKey) external view returns(address) {
        return address(keyToToken[_currencyKey]);
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "./MockToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract MockXSushi is MockToken {
    using SafeMath for uint256;
    uint256 public exchangeRate = 1 ether / 5;
    MockToken public underlying;

    uint256 public errorCode;
    constructor(address _underlying) MockToken("xSUSHI", "xSUSHI") public {
        underlying = MockToken(_underlying);
    }

    function mint(uint256 _amount) external {
        require(underlying.transferFrom(msg.sender, address(this), _amount), "MockXSushi.mint: transferFrom failed");

        uint256 mintAmount = _amount.mul(10**18).div(exchangeRate);
        _mint(msg.sender, mintAmount);
    }

    function enter(uint256 _amount) external {
        require(underlying.transferFrom(msg.sender, address(this), _amount), "MockXSushi.enter: transferFrom failed");

        uint256 mintAmount = _amount.mul(10**18).div(exchangeRate);
        _mint(msg.sender, mintAmount);
    }

    function exchangeRateStored() external view returns(uint256) {
        return exchangeRate;
    }

    function leave(uint256 _amount) external{
        _burn(msg.sender, _amount);

        uint256 underlyingAmount = _amount.mul(exchangeRate).div(10**18);
        underlying.mint(underlyingAmount, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "./MockToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract MockYVault is MockToken {
    using SafeMath for uint256;
    uint256 public exchangeRate = 1 ether / 5;
    MockToken public underlying;

    constructor(address _underlying) MockToken("yVAULT", "yVAULT") public {
        underlying = MockToken(_underlying);
    }

    function mint(uint256 _amount) external {
        require(underlying.transferFrom(msg.sender, address(this), _amount), "MockXSushi.mint: transferFrom failed");

        uint256 mintAmount = _amount.mul(10**18).div(exchangeRate);
        _mint(msg.sender, mintAmount);
    }

    function deposit(uint256 _amount) external {
        require(underlying.transferFrom(msg.sender, address(this), _amount), "MockYVault.enter: transferFrom failed");

        uint256 mintAmount = _amount.mul(10**18).div(exchangeRate);
        _mint(msg.sender, mintAmount);
    }

    function getPricePerFullShare() external view returns(uint) {
        return exchangeRate;
    }

    function withdraw(uint256 _amount) external{
        _burn(msg.sender, _amount);

        uint256 underlyingAmount = _amount.mul(exchangeRate).div(10**18);
        underlying.mint(underlyingAmount, msg.sender);
    }
}