// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface HodlerBridgeClaim {
    function updateState(uint256 blockNumber, bytes32 roothash) external;
}

/// @title A heavily modified version of a multisignature wallet. Credit goes to https://github.com/gnosis/MultiSigWallet
/// @author Daniel Hazlewood - <twitter: @alphasoups>
contract HodlerBridgeMerkleSubmitter {

    /*
     *  Events
     */
    event Confirmation(address indexed sender, bytes32 indexed hash, bytes32 indexed epochKey);
    event Revocation(address indexed sender,  bytes32 indexed hash, bytes32 indexed epochKey);
    event Submission(bytes32 indexed epochKey);
    event Execution(bytes32 indexed epochKey);
    event ExecutionFailure(bytes32 indexed epochKey);
    event DelegateAddition(address indexed delegate);
    event DelegateRemoval(address indexed delegate);
    event RequirementChange(uint256 required);

    /*
     *  Constants
     */
    uint256 constant public MAX_DELEGATE_COUNT = 25;

    /*
     *  Storage
     */
    mapping (bytes32 => bool) public epochs;
    mapping (bytes32 => mapping(address => bool)) public confirmations;
    
    mapping (address => bool) public isDelegate;
    address[] public delegates;

    address public delegator;
    uint256 public required;
    uint256 public epochCount;
    uint256 public lastBlockSubmitted;

    HodlerBridgeClaim public claimContract;

    /*
     *  Modifiers
     */
    modifier onlyDelegator() {
        require(msg.sender == delegator, "Delegators only");
        _;
    }

    modifier delegateDoesNotExist(address delegate) {
        require(!isDelegate[delegate], "Delegate exists");
        _;
    }

    modifier delegateExists(address delegate) {
        require(isDelegate[delegate], "Delegate does not exist");
        _;
    }

    modifier confirmed(bytes32 epochKey, address delegate) {
        require(confirmations[epochKey][delegate]);
        _;
    }

    modifier notConfirmed(bytes32 epochKey, address delegate) {
        require(!confirmations[epochKey][delegate]);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(uint256 delegateCount, uint256 _required) {
        require(delegateCount <= MAX_DELEGATE_COUNT
            && _required <= delegateCount
            && _required != 0
            && delegateCount != 0);
        _;
    }

    /// @dev This contract doesn't accept ether
    fallback() external payable
    {
        revert("");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        revert("");
    }
    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial delegates and required number of confirmations.
    /// @param _delegates List of initial delegates.
    /// @param _required Number of required confirmations.
    constructor(address claimContractAddress, address _delegator, uint256 _required, address[] memory _delegates)
        validRequirement(_delegates.length, _required)
    {
        for (uint256 i=0; i<_delegates.length; i++) {
            require(!isDelegate[_delegates[i]] && _delegates[i] != address(0), "Delegate already exists");
            isDelegate[_delegates[i]] = true;
        }
        claimContract = HodlerBridgeClaim(claimContractAddress);
        delegates = _delegates;
        required = _required;
        delegator = _delegator;
    }

    /// @dev Allows to add a new delegate
    /// @param delegate Address of new delegate.
    function addDelegate(address delegate)
        external
        onlyDelegator
        delegateDoesNotExist(delegate)
        notNull(delegate)
        validRequirement(delegates.length + 1, required)
    {
        isDelegate[delegate] = true;
        delegates.push(delegate);
        emit DelegateAddition(delegate);
    }

    /// @dev Allows to remove an delegate.
    /// @param delegate Address of delegate.
    function removeDelegate(address delegate)
        external
        onlyDelegator
        delegateExists(delegate)
    {
        isDelegate[delegate] = false;
        for (uint256 i=0; i<delegates.length - 1; i++) {
            if (delegates[i] == delegate) {
                delegates[i] = delegates[delegates.length - 1];
                break;
            }
        }
        if (required > delegates.length)
            changeRequirement(delegates.length);
        emit DelegateRemoval(delegate);
    }

    /// @dev Allows to change the number of required confirmations.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint256 _required)
        public
        onlyDelegator
        validRequirement(delegates.length, _required)
    {
        required = _required;
        emit  RequirementChange(_required);
    }

    /// @dev Allows an delegate to submit and confirm a epoch.
    /// @param blockNumber Block number this merkle root submission is for
    /// @param hash The root hash for this merkle root
    function submitEpoch(uint256 blockNumber, bytes32 hash)
        external
        returns (bytes32 epochKey)
    {
        epochKey = getKey(blockNumber, hash);
        _submitEpoch(blockNumber, hash, epochKey);
    }

    /// @dev Allows an delegate to submit and confirm a epoch.
    /// @param blockNumber Block number this merkle root submission is for
    /// @param hash The root hash for this merkle root
    function _submitEpoch(uint256 blockNumber, bytes32 hash, bytes32 epochKey)
        internal
    {
        require(blockNumber > lastBlockSubmitted, "Block number is not within the range");
        require(hash != 0, "Merkle root hash should exist");
        if(confirmations[epochKey][msg.sender] == false) {
            emit Confirmation(msg.sender, hash, epochKey);
        }
        confirmations[epochKey][msg.sender] = true;
        _executeEpoch(blockNumber, hash, epochKey);
    }

    /// @dev Allows anyone to execute a confirmed epoch.
    function _executeEpoch(uint256 blockNumber, bytes32 hash, bytes32 epochKey)
        internal
        delegateExists(msg.sender)
    {
        if (isConfirmed(epochKey) && epochs[epochKey] == false) {
            epochs[epochKey] = true;
            try claimContract.updateState(blockNumber, hash) {
                lastBlockSubmitted = blockNumber;
                emit Execution(epochKey);
            } catch {
                emit ExecutionFailure(epochKey);
                epochs[epochKey] = false;
            }
        }
    }

    /// @dev Returns the confirmation status of a epoch.
    /// @param epochKey The hash (blocknumber and merkle hash)
    /// @return txConfirmed Confirmation status.
    function isConfirmed(bytes32 epochKey)
        public
        view
        returns (bool txConfirmed)
    {
        uint256 count = 0;
        for (uint256 i=0; i<delegates.length; i++) {
            if (confirmations[epochKey][delegates[i]])
                count += 1;
            if (count == required)
                txConfirmed = true;
        }
    }
    
    /*
     * Web3 call functions
     */

    /// @dev Returns number of confirmations of a epoch.
    /// @return count Number of confirmations.
    function getConfirmationCount(bytes32 epochKey)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i=0; i<delegates.length; i++)
            if (confirmations[epochKey][delegates[i]])
                count += 1;
    }

    /// @dev Returns list of delegates.
    /// @return delegatelist List of delegate addresses.
    // This is external, we don't want anyone else calling it from within as it's not gas optimized.
    function getdelegates()
        external
        view
        returns (address[] memory delegatelist)
    {
        return delegates;
    }

    /// @dev Returns array with delegate addresses, which confirmed epoch.
    /// @param epochKey Epoch ID.
    /// @return _confirmations Returns array of delegate addresses.
    function getConfirmations(bytes32 epochKey)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](delegates.length);
        uint256 count = 0;
        uint256 i;
        for (i=0; i<delegates.length; i++)
            if (confirmations[epochKey][delegates[i]]) {
                confirmationsTemp[count] = delegates[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    function getKey(uint256 blockNumber, bytes32 hash) public pure returns(bytes32 epochKey)
    {
        return keccak256(abi.encode(blockNumber, hash));
    }
}