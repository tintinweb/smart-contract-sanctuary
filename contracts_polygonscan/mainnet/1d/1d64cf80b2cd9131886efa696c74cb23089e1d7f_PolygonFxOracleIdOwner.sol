/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

// File: contracts/oracles/dao/PolygonFxOracleIdOwner.sol

pragma solidity 0.5.16;


// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

interface IDaoOracleId {
    function _callback(uint256 _timestamp, uint256 _result) external;
    function transferOwnership(address newOwner) external;
}

contract PolygonFxOracleIdOwner is Ownable, IFxMessageProcessor {
    event MessageProcessed(uint256 stateId, address rootMessageSender, bytes data);
    event ValueProposed(uint256 timestamp, uint256 value);
    
    // FxPortal
    address public constant FX_CHILD = address(0x8397259c983751DAf40400790063935a11afa28a);
    // Optimistic Oracle DAO
    address public constant MASTER = address(0xA71111799909b2bD4E4569BF74832C7b4931092c);
    
    bytes public latestResult;
    
    // Oracle data
    mapping (uint256 => uint256) public proposedValues;
    mapping (uint256 => bool) public isProposed;

    // OracleId
    IDaoOracleId public childOracleId;

    constructor(IDaoOracleId _childOracleId) public {
        childOracleId = _childOracleId;
    }
    
    // Process message from cross-chain bridge and store locally
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external {
        emit MessageProcessed(stateId, rootMessageSender, data);
        
        // Check FxChild is a local sender
        require(msg.sender == address(FX_CHILD), "Not FxChild");
        // Check Master is a remote sender
        require(rootMessageSender == address(MASTER), "Not Master");
        
        latestResult = data;
    }
    
    // Transform received data into oracleId data proposal
    function proposeLatestResult() external {
        (uint256 timestamp, uint256 price) = abi.decode(latestResult, (uint256, uint256));
        proposedValues[timestamp] = price;
        isProposed[timestamp] = true;
        emit ValueProposed(timestamp, price);
    }

    function settleProposedResult(uint256 _timestamp) external {
        require(isProposed[_timestamp], "Not proposed yet");
        childOracleId._callback(_timestamp, proposedValues[_timestamp]);
    }

    // Governor only

    // Override and push value by governor
    function _callback(uint256 _timestamp, uint256 _result) external onlyOwner {
        childOracleId._callback(_timestamp, _result);
    }

    // Transfer child ownership by governor
    function transferChildOwnership(address _newOwner) external onlyOwner {
        childOracleId.transferOwnership(_newOwner);
    }
}