/**
 *Submitted for verification at polygonscan.com on 2021-08-29
*/

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
        return payable(msg.sender);
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


pragma experimental ABIEncoderV2;
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