/**
 *Submitted for verification at polygonscan.com on 2021-08-29
*/

// File: Interfaces/ICToken.sol

pragma solidity ^0.7.1;

interface ICToken {
    function mint(uint _mintAmount) external returns (uint256);
    function redeem(uint _redeemTokens) external returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns(uint256);
}

// File: OpenZeppelin/Context.sol



pragma solidity ^0.7.0;

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

// File: OpenZeppelin/Ownable.sol



pragma solidity ^0.7.0;

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
    constructor () {
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

// File: LendingRegistry.sol


pragma solidity ^0.7.1;



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
        @param _protocol Bytes32 key of the protocol
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
    function getLendTXData(address _underlying, uint256 _amount, address _tokenHolder, bytes32 _protocol) external view returns(address[] memory targets, bytes[] memory data) {
        ILendingLogic lendingLogic = ILendingLogic(protocolToLogic[_protocol]);
        require(address(lendingLogic) != address(0), "NO_LENDING_LOGIC_SET");

        return lendingLogic.lend(_underlying, _amount, _tokenHolder);
    }

    /**
        @notice Get the tx data to unlend the wrapped amount
        @param _wrapped Address of the wrapped token
        @param _amount Amount of wrapped token to unlend
        @return targets Addresses of the contracts to call
        @return data Calldata for the calls
    */
    function getUnlendTXData(address _wrapped, uint256 _amount, address _tokenHolder) external view returns(address[] memory targets, bytes[] memory data) {
        ILendingLogic lendingLogic = ILendingLogic(protocolToLogic[wrappedToProtocol[_wrapped]]);
        require(address(lendingLogic) != address(0), "NO_LENDING_LOGIC_SET");

        return lendingLogic.unlend(_wrapped, _amount, _tokenHolder);
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
// File: Interfaces/ILendingLogic.sol


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
    function lend(address _underlying, uint256 _amount, address _tokenHolder) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the calls needed to unlend
        @param _wrapped Address of the wrapped token
        @param _amount Amount of the underlying tokens
        @return targets Addresses of the contracts to call
        @return data Calldata of the calls
    */
    function unlend(address _wrapped, uint256 _amount, address _tokenHolder) external view returns(address[] memory targets, bytes[] memory data);

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
// File: Interfaces/IERC20.sol



pragma solidity ^0.7.0;

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
// File: OpenZeppelin/SafeMath.sol



pragma solidity ^0.7.0;

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


// File: LendingLogicCream.sol



pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;






contract LendingLogicCream is Ownable, ILendingLogic {
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

    function lend(address _underlying, uint256 _amount, address _tokenHolder) external view override returns(address[] memory targets, bytes[] memory data) {
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

    function unlend(address _wrapped, uint256 _amount, address _tokenHolder) external view override returns(address[] memory targets, bytes[] memory data) {
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