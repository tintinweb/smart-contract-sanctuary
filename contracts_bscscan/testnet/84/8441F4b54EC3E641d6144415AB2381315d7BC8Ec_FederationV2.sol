/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// Dependency file: contracts/zeppelin/upgradable/Initializable.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.7.0;

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
    require(initializing || !initialized, "Contract instance is already initialized");

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

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// Dependency file: contracts/zeppelin/GSN/Context.sol


// pragma solidity ^0.7.0;

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
abstract contract  Context {

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// Dependency file: contracts/zeppelin/upgradable/ownership/UpgradableOwnable.sol


// pragma solidity ^0.7.0;

// import "contracts/zeppelin/upgradable/Initializable.sol";

// import "contracts/zeppelin/GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract UpgradableOwnable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
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
     * > Note: Renouncing ownership will leave the contract without an owner,
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
        require(newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}


// Dependency file: contracts/interface/IBridge.sol


// pragma solidity ^0.7.0;
interface IBridge {

    struct ClaimData {
        address payable to;
        uint256 amount;
        bytes32 blockHash;
        bytes32 transactionHash;
        uint32 logIndex;
    }

    function version() external pure returns (string memory);

    function getFeePercentage() external view returns(uint);

    /**
     * ERC-20 tokens approve and transferFrom pattern
     * See https://eips.ethereum.org/EIPS/eip-20#transferfrom
     */
    function receiveTokensTo(address tokenToUse, address to, uint256 amount) external;

    /**
     * Use network currency and cross it.
     */
    function depositTo(address to) external payable;

    /**
     * ERC-777 tokensReceived hook allows to send tokens to a contract and notify it in a single transaction
     * See https://eips.ethereum.org/EIPS/eip-777#motivation for details
     */
    function tokensReceived (
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;

    /**
     * Accepts the transaction from the other chain that was voted and sent by the Federation contract
     */
    function acceptTransfer(
        address _originalTokenAddress,
        address payable _from,
        address payable _to,
        uint256 _amount,
        bytes32 _blockHash,
        bytes32 _transactionHash,
        uint32 _logIndex
    ) external;

    /**
     * Claims the crossed transaction using the hash, this sends the funds to the address indicated in
     */
    function claim(ClaimData calldata _claimData) external returns (uint256 receivedAmount);

    function claimFallback(ClaimData calldata _claimData) external returns (uint256 receivedAmount);

    function claimGasless(
        ClaimData calldata _claimData,
        address payable _relayer,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 receivedAmount);

    function getTransactionDataHash(
        address _to,
        uint256 _amount,
        bytes32 _blockHash,
        bytes32 _transactionHash,
        uint32 _logIndex
    ) external returns(bytes32);

    event Cross(
        address indexed _tokenAddress,
        address indexed _from,
        address indexed _to,
        uint256 _amount,
        bytes _userData
    );
    event NewSideToken(
        address indexed _newSideTokenAddress,
        address indexed _originalTokenAddress,
        string _newSymbol,
        uint256 _granularity
    );
    event AcceptedCrossTransfer(
        bytes32 indexed _transactionHash,
        address indexed _originalTokenAddress,
        address indexed _to,
        address  _from,
        uint256 _amount,
        bytes32 _blockHash,
        uint256 _logIndex
    );
    event FeePercentageChanged(uint256 _amount);
    event Claimed(
        bytes32 indexed _transactionHash,
        address indexed _originalTokenAddress,
        address indexed _to,
        address _sender,
        uint256 _amount,
        bytes32 _blockHash,
        uint256 _logIndex,
        address _reciever,
        address _relayer,
        uint256 _fee
    );
}

// Root file: contracts/Federation/FederationV2.sol


pragma solidity ^0.7.0;
pragma abicoder v2;

// Upgradables
// import "contracts/zeppelin/upgradable/Initializable.sol";
// import "contracts/zeppelin/upgradable/ownership/UpgradableOwnable.sol";

// import "contracts/interface/IBridge.sol";

contract FederationV2 is Initializable, UpgradableOwnable {
    uint constant public MAX_MEMBER_COUNT = 50;
    address constant private NULL_ADDRESS = address(0);

    IBridge public bridge;
    address[] public members;
    uint public required;

    mapping (address => bool) public isMember;
    mapping (bytes32 => mapping (address => bool)) public votes;
    mapping(bytes32 => bool) public processed;

    event Executed(
        address indexed federator,
        bytes32 indexed transactionHash,
        bytes32 indexed transactionId,
        address originalTokenAddress,
        address sender,
        address receiver,
        uint256 amount,
        bytes32 blockHash,
        uint32 logIndex
    );
    event MemberAddition(address indexed member);
    event MemberRemoval(address indexed member);
    event RequirementChange(uint required);
    event BridgeChanged(address bridge);
    event Voted(
        address indexed federator,
        bytes32 indexed transactionHash,
        bytes32 indexed transactionId,
        address originalTokenAddress,
        address sender,
        address receiver,
        uint256 amount,
        bytes32 blockHash,
        uint32 logIndex
    );
    event HeartBeat(
        address indexed sender,
        uint256 fedRskBlock,
        uint256 fedEthBlock,
        string federatorVersion,
        string nodeRskInfo,
        string nodeEthInfo
    );

    modifier onlyMember() {
        require(isMember[_msgSender()], "Federation: Not Federator");
        _;
    }

    modifier validRequirement(uint membersCount, uint _required) {
        // solium-disable-next-line max-len
        require(_required <= membersCount && _required != 0 && membersCount != 0, "Federation: Invalid requirements");
        _;
    }

    function initialize(address[] memory _members, uint _required, address _bridge, address owner)
    public validRequirement(_members.length, _required) initializer {
        UpgradableOwnable.initialize(owner);
        require(_members.length <= MAX_MEMBER_COUNT, "Federation: Too many members");
        members = _members;
        for (uint i = 0; i < _members.length; i++) {
            require(!isMember[_members[i]] && _members[i] != NULL_ADDRESS, "Federation: Invalid members");
            isMember[_members[i]] = true;
            emit MemberAddition(_members[i]);
        }
        required = _required;
        emit RequirementChange(required);
        _setBridge(_bridge);
    }

    function version() external pure returns (string memory) {
        return "v2";
    }

    function setBridge(address _bridge) external onlyOwner {
        _setBridge(_bridge);
    }

    function _setBridge(address _bridge) internal {
        require(_bridge != NULL_ADDRESS, "Federation: Empty bridge");
        bridge = IBridge(_bridge);
        emit BridgeChanged(_bridge);
    }

    function voteTransaction(
        address originalTokenAddress,
        address payable sender,
        address payable receiver,
        uint256 amount,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex
    )
    public onlyMember returns(bool)
    {
        bytes32 transactionId = getTransactionId(
            originalTokenAddress,
            sender,
            receiver,
            amount,
            blockHash,
            transactionHash,
            logIndex
        );
        if (processed[transactionId])
            return true;

        if (votes[transactionId][_msgSender()])
            return true;

        votes[transactionId][_msgSender()] = true;
        emit Voted(
            _msgSender(),
            transactionHash,
            transactionId,
            originalTokenAddress,
            sender,
            receiver,
            amount,
            blockHash,
            logIndex
        );

        uint transactionCount = getTransactionCount(transactionId);
        if (transactionCount >= required && transactionCount >= members.length / 2 + 1) {
            processed[transactionId] = true;
            bridge.acceptTransfer(
                originalTokenAddress,
                sender,
                receiver,
                amount,
                blockHash,
                transactionHash,
                logIndex
            );
            emit Executed(
                _msgSender(),
                transactionHash,
                transactionId,
                originalTokenAddress,
                sender,
                receiver,
                amount,
                blockHash,
                logIndex
            );
            return true;
        }

        return true;
    }

    function getTransactionCount(bytes32 transactionId) public view returns(uint) {
        uint count = 0;
        for (uint i = 0; i < members.length; i++) {
            if (votes[transactionId][members[i]])
                count += 1;
        }
        return count;
    }

    function hasVoted(bytes32 transactionId) external view returns(bool)
    {
        return votes[transactionId][_msgSender()];
    }

    function transactionWasProcessed(bytes32 transactionId) external view returns(bool)
    {
        return processed[transactionId];
    }

    function getTransactionId(
        address originalTokenAddress,
        address sender,
        address receiver,
        uint256 amount,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex
    ) public pure returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
            originalTokenAddress,
            sender,
            receiver,
            amount,
            blockHash,
            transactionHash,
            logIndex
            )
        );
    }

    function addMember(address _newMember) external onlyOwner
    {
        require(_newMember != NULL_ADDRESS, "Federation: Empty member");
        require(!isMember[_newMember], "Federation: Member already exists");
        require(members.length < MAX_MEMBER_COUNT, "Federation: Max members reached");

        isMember[_newMember] = true;
        members.push(_newMember);
        emit MemberAddition(_newMember);
    }

    function removeMember(address _oldMember) external onlyOwner
    {
        require(_oldMember != NULL_ADDRESS, "Federation: Empty member");
        require(isMember[_oldMember], "Federation: Member doesn't exists");
        require(members.length > 1, "Federation: Can't remove all the members");
        require(members.length - 1 >= required, "Federation: Can't have less than required members");

        isMember[_oldMember] = false;
        for (uint i = 0; i < members.length - 1; i++) {
            if (members[i] == _oldMember) {
                members[i] = members[members.length - 1];
                break;
            }
        }
        members.pop(); // remove an element from the end of the array.
        emit MemberRemoval(_oldMember);
    }

    function getMembers() external view returns (address[] memory)
    {
        return members;
    }

    function changeRequirement(uint _required) external onlyOwner validRequirement(members.length, _required)
    {
        require(_required >= 2, "Federation: Requires at least 2");
        required = _required;
        emit RequirementChange(_required);
    }

    function emitHeartbeat(
        uint256 fedRskBlock,
        uint256 fedEthBlock,
        string calldata federatorVersion,
        string calldata nodeRskInfo,
        string calldata nodeEthInfo
    ) external onlyMember {
        emit HeartBeat(
            _msgSender(),
            fedRskBlock,
            fedEthBlock,
            federatorVersion,
            nodeRskInfo,
            nodeEthInfo
        );
    }
}