/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.6;



// Part: Context

/**
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
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: IAgentManager

interface IAgentManager {
    event userAgentRegistered(
        address indexed user,
        string indexed agentId
    );

    event agentUpdated(
        string indexed agentId,
        address indexed _coldAddress,
        address indexed _hotAddress
    );

    function registerAgentForUser(
        string calldata agentId,
        address _coldAddress,
        address _hotAddress
    ) external returns (bool);

    function updateAgentColdAddress(string calldata agentId, address _coldAddress)
        external
        returns (bool);

    function updateAgentHotAddress(string calldata agentId, address _hotAddress)
        external
        returns (bool);

    function veryifyAgentAddress(
        string calldata agentId,
        address senderAddress,
        address userAddress
    ) external view returns (bool);
}

// Part: Ownable

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: AgentManager.sol

/**
 * @title Agent manager
 * @notice This contract is responsible for managing one to many user agents
 * and also verifies if an agent is authorized to transact on behalf of a user
 * @dev Can be used as a standalone in multiple agent management systems
 */
contract AgentManager is IAgentManager, Ownable {
    mapping(address => mapping(string => bool)) public userAgents;

    struct AgentKeys {
        address coldAddress;
        address hotAddress;
        address previousHotAddress;
        uint256 lastUpdatedBlock;
    }

    mapping(string => AgentKeys) public agents;

    uint256 public PREVIOUS_HOT_ADDRESS_BLOCK_LIFE;
    uint256 public HOT_ADDRESS_BLOCK_LIFE;

    /**
     * @param _previousHotAddressBlocks: the value to set for PREVIOUS_HOT_ADDRESS_BLOCK_LIFE
     * which signifies the number of blocks after which the previous hot address for the agent
     * becomes invalid after updating the hot address
     * @param _hotAddressBlocks: the value to set for HOT_ADDRESS_BLOCK_LIFE which signifies
     * the number of blocks after which a current hot address of an agent becomes invalid
     */
    constructor(uint256 _previousHotAddressBlocks, uint256 _hotAddressBlocks) {
        PREVIOUS_HOT_ADDRESS_BLOCK_LIFE = _previousHotAddressBlocks;
        HOT_ADDRESS_BLOCK_LIFE = _hotAddressBlocks;
    }

    /**
     * @notice Registers an agent corresponding to the message sender (user)
     * @param agentId: unique id of the agent to register
     * @param _coldAddress: cold address of the agent
     * @param _hotAddress: Initial hot address of the agent
     */
    function registerAgentForUser(
        string calldata agentId,
        address _coldAddress,
        address _hotAddress
    ) external override returns (bool) {
        require(
            !userAgents[msg.sender][agentId],
            "Agent id already registered for this user"
        );

        // Checks the mapping to ensure the agentId is not already registered
        require(
            agents[agentId].coldAddress == address(0),
            "AgentId already registered for another user"
        );

        require(
            _coldAddress != address(0) && _hotAddress != address(0),
            "Addresses can't be zero address"
        );

        agents[agentId] = AgentKeys({
            coldAddress: _coldAddress,
            hotAddress: _hotAddress,
            previousHotAddress: address(0),
            lastUpdatedBlock: block.number
        });

        emit agentUpdated(agentId, _coldAddress, _hotAddress);

        userAgents[msg.sender][agentId] = true;

        emit userAgentRegistered(msg.sender, agentId);

        return true;
    }

    /**
     * @notice Verifies if an agentId is authorised to transact on behalf of a userAddress
     * @dev Internal function. Can only be called by inheriting contracts
     * @param agentId: unique id of the agent
     * @param senderAddress: address of the sender (agent in this case)
     * @param userAddress: address of the user to authorise for
     */
    function veryifyAgentAddress(
        string calldata agentId,
        address senderAddress,
        address userAddress
    ) external view override returns (bool) {
        AgentKeys memory keys = agents[agentId];
        if (keys.hotAddress == senderAddress) {
            if (HOT_ADDRESS_BLOCK_LIFE == 0) {
                return userAgents[userAddress][agentId];
            }

            return
                (block.number <=
                    keys.lastUpdatedBlock + HOT_ADDRESS_BLOCK_LIFE) &&
                userAgents[userAddress][agentId];
        }

        if (keys.previousHotAddress == senderAddress) {
            return
                (block.number <=
                    keys.lastUpdatedBlock + PREVIOUS_HOT_ADDRESS_BLOCK_LIFE) &&
                userAgents[userAddress][agentId];
        }

        return keys.coldAddress == senderAddress;
    }

    /**
     * @notice Updates agent cold address, sender needs to be the previous cold address itself
     * @param agentId: unique id of the agent
     * @param _coldAddress: new cold address to set
     */
    function updateAgentColdAddress(
        string calldata agentId,
        address _coldAddress
    ) external override returns (bool) {
        require(
            msg.sender == agents[agentId].coldAddress &&
                _coldAddress != address(0),
            "Cold address can't be updated"
        );
        agents[agentId].coldAddress = _coldAddress;

        emit agentUpdated(agentId, _coldAddress, agents[agentId].hotAddress);

        return true;
    }

    /**
     * @notice Updates agent hot address, sender needs to be the cold address or previous hot address
     * @param agentId: unique id of the agent
     * @param _hotAddress: new hot address to set
     */
    function updateAgentHotAddress(string calldata agentId, address _hotAddress)
        external
        override
        returns (bool)
    {
        require(
            _hotAddress != address(0) &&
                (msg.sender == agents[agentId].coldAddress ||
                    msg.sender == agents[agentId].hotAddress),
            "Hot address can't be updated"
        );
        agents[agentId].previousHotAddress = agents[agentId].hotAddress;
        agents[agentId].hotAddress = _hotAddress;
        agents[agentId].lastUpdatedBlock = block.number;

        emit agentUpdated(agentId, agents[agentId].coldAddress, _hotAddress);

        return true;
    }

    /**
     * @notice Updates PREVIOUS_HOT_ADDRESS_BLOCK_LIFE, can only be called by owner of the contract
     * @param newBlockDifference: new value for PREVIOUS_HOT_ADDRESS_BLOCK_LIFE
     */
    function updatePreviousHotAddressBlockDifference(uint256 newBlockDifference)
        external
        onlyOwner
    {
        PREVIOUS_HOT_ADDRESS_BLOCK_LIFE = newBlockDifference;
    }

    /**
     * @notice Updates HOT_ADDRESS_BLOCK_LIFE, can only be called by owner of the contract
     * @param newBlockDifference: new value for HOT_ADDRESS_BLOCK_LIFE
     */
    function updateHotAddressBlockDifference(uint256 newBlockDifference)
        external
        onlyOwner
    {
        HOT_ADDRESS_BLOCK_LIFE = newBlockDifference;
    }
}