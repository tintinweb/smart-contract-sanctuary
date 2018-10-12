pragma solidity ^0.4.24;

// File: contracts/interfaces/IOwned.sol

/*
    Owned Contract Interface
*/
contract IOwned {
    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
    function transferOwnershipNow(address newContractOwner) public;
}

// File: contracts/utility/Owned.sol

/*
    This is the "owned" utility contract used by bancor with one additional function - transferOwnershipNow()
    
    The original unmodified version can be found here:
    https://github.com/bancorprotocol/contracts/commit/63480ca28534830f184d3c4bf799c1f90d113846
    
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
        @dev constructor
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner
        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    /**
        @dev transfers the contract ownership without needing the new owner to accept ownership
        @param newContractOwner    new contract owner
    */
    function transferOwnershipNow(address newContractOwner) ownerOnly public {
        require(newContractOwner != owner);
        emit OwnerUpdate(owner, newContractOwner);
        owner = newContractOwner;
    }

}

// File: contracts/interfaces/ILogger.sol

/*
    Logger Contract Interface
*/

contract ILogger {
    function addNewLoggerPermission(address addressToPermission) public;
    function emitTaskCreated(uint uuid, uint amount) public;
    function emitProjectCreated(uint uuid, uint amount, address rewardAddress) public;
    function emitNewSmartToken(address token) public;
    function emitIssuance(uint256 amount) public;
    function emitDestruction(uint256 amount) public;
    function emitTransfer(address from, address to, uint256 value) public;
    function emitApproval(address owner, address spender, uint256 value) public;
    function emitGenericLog(string messageType, string message) public;
}

// File: contracts/Logger.sol

/*

Centralized logger allows backend to easily watch all events on all communities without needing to watch each community individually

*/
contract Logger is Owned, ILogger  {

    // Community
    event TaskCreated(address msgSender, uint _uuid, uint _amount);
    event ProjectCreated(address msgSender, uint _uuid, uint _amount, address _address);

    // SmartToken
    // triggered when a smart token is deployed - the _token address is defined for forward compatibility
    //  in case we want to trigger the event from a factory
    event NewSmartToken(address msgSender, address _token);
    // triggered when the total supply is increased
    event Issuance(address msgSender, uint256 _amount);
    // triggered when the total supply is decreased
    event Destruction(address msgSender, uint256 _amount);
    // erc20
    event Transfer(address msgSender, address indexed _from, address indexed _to, uint256 _value);
    event Approval(address msgSender, address indexed _owner, address indexed _spender, uint256 _value);

    // Logger
    event NewCommunityAddress(address msgSender, address _newAddress);

    event GenericLog(address msgSender, string messageType, string message);
    mapping (address => bool) public permissionedAddresses;

    modifier hasLoggerPermissions(address _address) {
        require(permissionedAddresses[_address] == true);
        _;
    }

    function addNewLoggerPermission(address addressToPermission) ownerOnly public {
        permissionedAddresses[addressToPermission] = true;
    }

    function emitTaskCreated(uint uuid, uint amount) public hasLoggerPermissions(msg.sender) {
        emit TaskCreated(msg.sender, uuid, amount);
    }

    function emitProjectCreated(uint uuid, uint amount, address rewardAddress) public hasLoggerPermissions(msg.sender) {
        emit ProjectCreated(msg.sender, uuid, amount, rewardAddress);
    }

    function emitNewSmartToken(address token) public hasLoggerPermissions(msg.sender) {
        emit NewSmartToken(msg.sender, token);
    }

    function emitIssuance(uint256 amount) public hasLoggerPermissions(msg.sender) {
        emit Issuance(msg.sender, amount);
    }

    function emitDestruction(uint256 amount) public hasLoggerPermissions(msg.sender) {
        emit Destruction(msg.sender, amount);
    }

    function emitTransfer(address from, address to, uint256 value) public hasLoggerPermissions(msg.sender) {
        emit Transfer(msg.sender, from, to, value);
    }

    function emitApproval(address owner, address spender, uint256 value) public hasLoggerPermissions(msg.sender) {
        emit Approval(msg.sender, owner, spender, value);
    }

    function emitGenericLog(string messageType, string message) public hasLoggerPermissions(msg.sender) {
        emit GenericLog(msg.sender, messageType, message);
    }
}

// File: contracts/interfaces/IERC20.sol

/*
    Smart Token Interface
*/
contract IERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/interfaces/ICommunityAccount.sol

/*
    Community Account Interface
*/
contract ICommunityAccount is IOwned {
    function setStakedBalances(uint _amount, address msgSender) public;
    function setTotalStaked(uint _totalStaked) public;
    function setTimeStaked(uint _timeStaked, address msgSender) public;
    function setEscrowedTaskBalances(uint uuid, uint balance) public;
    function setEscrowedProjectBalances(uint uuid, uint balance) public;
    function setEscrowedProjectPayees(uint uuid, address payeeAddress) public;
    function setTotalTaskEscrow(uint balance) public;
    function setTotalProjectEscrow(uint balance) public;
}

// File: contracts/CommunityAccount.sol

/**
@title Tribe Account
@notice This contract is used as a community&#39;s data store.
@notice Advantages:
@notice 1) Decouple logic contract from data contract
@notice 2) Safely upgrade logic contract without compromising stored data
*/
contract CommunityAccount is Owned, ICommunityAccount {

    // Staking Variables.  In community token
    mapping (address => uint256) public stakedBalances;
    mapping (address => uint256) public timeStaked;
    uint public totalStaked;

    // Escrow variables.  In native token
    uint public totalTaskEscrow;
    uint public totalProjectEscrow;
    mapping (uint256 => uint256) public escrowedTaskBalances;
    mapping (uint256 => uint256) public escrowedProjectBalances;
    mapping (uint256 => address) public escrowedProjectPayees;
    
    /**
    @notice This function allows the community to transfer tokens out of the contract.
    @param tokenContractAddress Address of community contract
    @param destination Destination address of user looking to remove tokens from contract
    @param amount Amount to transfer out of community
    */
    function transferTokensOut(address tokenContractAddress, address destination, uint amount) public ownerOnly returns(bool result) {
        IERC20 token = IERC20(tokenContractAddress);
        return token.transfer(destination, amount);
    }

    /**
    @notice This is the community staking method
    @param _amount Amount to be staked
    @param msgSender Address of the staker
    */
    function setStakedBalances(uint _amount, address msgSender) public ownerOnly {
        stakedBalances[msgSender] = _amount;
    }

    /**
    @param _totalStaked Set total amount staked in community
     */
    function setTotalStaked(uint _totalStaked) public ownerOnly {
        totalStaked = _totalStaked;
    }

    /**
    @param _timeStaked Time of user staking into community
    @param msgSender Staker address
     */
    function setTimeStaked(uint _timeStaked, address msgSender) public ownerOnly {
        timeStaked[msgSender] = _timeStaked;
    }

    /**
    @param uuid id of escrowed task
    @param balance Balance to be set of escrowed task
     */
    function setEscrowedTaskBalances(uint uuid, uint balance) public ownerOnly {
        escrowedTaskBalances[uuid] = balance;
    }

    /**
    @param uuid id of escrowed project
    @param balance Balance to be set of escrowed project
     */
    function setEscrowedProjectBalances(uint uuid, uint balance) public ownerOnly {
        escrowedProjectBalances[uuid] = balance;
    }

    /**
    @param uuid id of escrowed project
    @param payeeAddress Address funds will go to once project completed
     */
    function setEscrowedProjectPayees(uint uuid, address payeeAddress) public ownerOnly {
        escrowedProjectPayees[uuid] = payeeAddress;
    }

    /**
    @param balance Balance which to set total task escrow to
     */
    function setTotalTaskEscrow(uint balance) public ownerOnly {
        totalTaskEscrow = balance;
    }

    /**
    @param balance Balance which to set total project to
     */
    function setTotalProjectEscrow(uint balance) public ownerOnly {
        totalProjectEscrow = balance;
    }
}

// File: contracts/interfaces/ISmartToken.sol

/**
    @notice Smart Token Interface
*/
contract ISmartToken is IOwned, IERC20 {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

// File: contracts/interfaces/ICommunity.sol

/*
    Community Interface
*/
contract ICommunity {
    function transferCurator(address _curator) public;
    function transferVoteController(address _voteController) public;
    function setMinimumStakingRequirement(uint _minimumStakingRequirement) public;
    function setLockupPeriodSeconds(uint _lockupPeriodSeconds) public;
    function setLogger(address newLoggerAddress) public;
    function setTokenAddresses(address newNativeTokenAddress, address newCommunityTokenAddress) public;
    function setCommunityAccount(address newCommunityAccountAddress) public;
    function setCommunityAccountOwner(address newOwner) public;
    function getAvailableDevFund() public view returns (uint);
    function getLockedDevFundAmount() public view returns (uint);
    function createNewTask(uint uuid, uint amount) public;
    function cancelTask(uint uuid) public;
    function rewardTaskCompletion(uint uuid, address user) public;
    function createNewProject(uint uuid, uint amount, address projectPayee) public;
    function cancelProject(uint uuid) public;
    function rewardProjectCompletion(uint uuid) public;
    function stakeCommunityTokens() public;
    function unstakeCommunityTokens() public;
    function isMember(address memberAddress)public view returns (bool);
}

// File: contracts/utility/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 * From https://github.com/OpenZeppelin/openzeppelin-solidity/commit/a2e710386933d3002062888b35aae8ac0401a7b3
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }
}

// File: contracts/Community.sol

/**
@notice Main community logic contract.
@notice functionality:
@notice 1) Stake / Unstake community tokens.  This is how user joins or leaves community.
@notice 2) Create Projects and Tasks by escrowing NTV token until curator or voteController determines task complete
@notice 3) Log all events to singleton Logger contract
@notice 4) Own communityAccount contract which holds all staking- and escrow-related funds and variables
@notice --- This abstraction of funds allows for easy upgrade process; launch new community -> transfer ownership of the existing communityAccount
@notice --- View test/integration-test-upgrades.js to demonstrate this process
 */
contract Community is ICommunity {

    address public curator;
    address public voteController;
    uint public minimumStakingRequirement;
    uint public lockupPeriodSeconds;
    ISmartToken public nativeTokenInstance;
    ISmartToken public communityTokenInstance;
    Logger public logger;
    CommunityAccount public communityAccount;

    modifier onlyCurator {
        require(msg.sender == curator);
        _;
    }

    modifier onlyVoteController {
        require(msg.sender == voteController);
        _;
    }

    modifier sufficientDevFundBalance (uint amount) {
        require(amount <= getAvailableDevFund());
        _;
    }

    /**
    @param _minimumStakingRequirement Minimum stake amount to join community
    @param _lockupPeriodSeconds Required minimum holding time, in seconds, after joining for staker to leave
    @param _curator Address of community curator
    @param _communityTokenContractAddress Address of community token contract
    @param _nativeTokenContractAddress Address of ontract
    @param _voteController Address of vote controller
    @param _loggerContractAddress Address of logger contract
    @param _communityAccountContractAddress Address of community account
     */
    constructor(uint _minimumStakingRequirement,
        uint _lockupPeriodSeconds,
        address _curator,
        address _communityTokenContractAddress,
        address _nativeTokenContractAddress,
        address _voteController,
        address _loggerContractAddress,
        address _communityAccountContractAddress) public {
        communityAccount = CommunityAccount(_communityAccountContractAddress);
        curator = _curator;
        minimumStakingRequirement = _minimumStakingRequirement;
        lockupPeriodSeconds = _lockupPeriodSeconds;
        logger = Logger(_loggerContractAddress);
        voteController = _voteController;
        nativeTokenInstance = ISmartToken(_nativeTokenContractAddress);
        communityTokenInstance = ISmartToken(_communityTokenContractAddress);
    }

    // TODO add events to each of these
    /**
    @notice Sets curator to input curator address
    @param _curator Address of new community curator
     */
    function transferCurator(address _curator) public onlyCurator {
        curator = _curator;
        logger.emitGenericLog("transferCurator", "");
    }

    /**
    @notice Sets vote controller to input vote controller address
    @param _voteController Address of new vote controller
     */
    function transferVoteController(address _voteController) public onlyCurator {
        voteController = _voteController;
        logger.emitGenericLog("transferVoteController", "");
    }

    /**
    @notice Sets the minimum community staking requirement
    @param _minimumStakingRequirement Minimum community staking requirement to be set
     */
    function setMinimumStakingRequirement(uint _minimumStakingRequirement) public onlyCurator {
        minimumStakingRequirement = _minimumStakingRequirement;
        logger.emitGenericLog("setMinimumStakingRequirement", "");
    }

    /**
    @notice Sets lockup period for community staking
    @param _lockupPeriodSeconds Community staking lockup period, in seconds
    */
    function setLockupPeriodSeconds(uint _lockupPeriodSeconds) public onlyCurator {
        lockupPeriodSeconds = _lockupPeriodSeconds;
        logger.emitGenericLog("setLockupPeriodSeconds", "");
    }

    /**
    @notice Updates Logger contract address to be used
    @param newLoggerAddress Address of new Logger contract
     */
    function setLogger(address newLoggerAddress) public onlyCurator {
        logger = Logger(newLoggerAddress);
        logger.emitGenericLog("setLogger", "");
    }

    /**
    @param newNativeTokenAddress New Native token address
    @param newCommunityTokenAddress New community token address
     */
    function setTokenAddresses(address newNativeTokenAddress, address newCommunityTokenAddress) public onlyCurator {
        nativeTokenInstance = ISmartToken(newNativeTokenAddress);
        communityTokenInstance = ISmartToken(newCommunityTokenAddress);
        logger.emitGenericLog("setTokenAddresses", "");
    }

    /**
    @param newCommunityAccountAddress Address of new community account
     */
    function setCommunityAccount(address newCommunityAccountAddress) public onlyCurator {
        communityAccount = CommunityAccount(newCommunityAccountAddress);
        logger.emitGenericLog("setCommunityAccount", "");
    }

    /**
    @param newOwner New community account owner address
     */
    function setCommunityAccountOwner(address newOwner) public onlyCurator {
        communityAccount.transferOwnershipNow(newOwner);
        logger.emitGenericLog("setCommunityAccountOwner", "");
    }

    /// @return Amount in the dev fund not locked up by project or task stake
    function getAvailableDevFund() public view returns (uint) {
        uint devFundBalance = nativeTokenInstance.balanceOf(address(communityAccount));
        return SafeMath.sub(devFundBalance, getLockedDevFundAmount());
    }

    /// @return Amount locked up in escrow
    function getLockedDevFundAmount() public view returns (uint) {
        return SafeMath.add(communityAccount.totalTaskEscrow(), communityAccount.totalProjectEscrow());
    }

    /* Task escrow code below (in community tokens) */

    /// @notice Updates the escrow values for a new task
    function createNewTask(uint uuid, uint amount) public onlyCurator sufficientDevFundBalance (amount) {
        communityAccount.setEscrowedTaskBalances(uuid, amount);
        communityAccount.setTotalTaskEscrow(SafeMath.add(communityAccount.totalTaskEscrow(), amount));
        logger.emitTaskCreated(uuid, amount);
        logger.emitGenericLog("createNewTask", "");
    }

    /// @notice Subtracts the tasks escrow and sets tasks escrow balance to 0
    function cancelTask(uint uuid) public onlyCurator {
        communityAccount.setTotalTaskEscrow(SafeMath.sub(communityAccount.totalTaskEscrow(), communityAccount.escrowedTaskBalances(uuid)));
        communityAccount.setEscrowedTaskBalances(uuid, 0);
        logger.emitGenericLog("cancelTask", "");
    }

    /// @notice Pays task completer and updates escrow balances
    function rewardTaskCompletion(uint uuid, address user) public onlyVoteController {
        communityAccount.transferTokensOut(address(nativeTokenInstance), user, communityAccount.escrowedTaskBalances(uuid));
        communityAccount.setTotalTaskEscrow(SafeMath.sub(communityAccount.totalTaskEscrow(), communityAccount.escrowedTaskBalances(uuid)));
        communityAccount.setEscrowedTaskBalances(uuid, 0);
        logger.emitGenericLog("rewardTaskCompletion", "");
    }

    /* Project escrow code below (in community tokens) */

    /// @notice updates the escrow values along with the project payee for a new project
    function createNewProject(uint uuid, uint amount, address projectPayee) public onlyCurator sufficientDevFundBalance (amount) {
        communityAccount.setEscrowedProjectBalances(uuid, amount);
        communityAccount.setEscrowedProjectPayees(uuid, projectPayee);
        communityAccount.setTotalProjectEscrow(SafeMath.add(communityAccount.totalProjectEscrow(), amount));
        logger.emitProjectCreated(uuid, amount, projectPayee);
        logger.emitGenericLog("createNewProject", "");
    }

    /// @notice Subtracts tasks escrow and sets tasks escrow balance to 0
    function cancelProject(uint uuid) public onlyCurator {
        communityAccount.setTotalProjectEscrow(SafeMath.sub(communityAccount.totalProjectEscrow(), communityAccount.escrowedProjectBalances(uuid)));
        communityAccount.setEscrowedProjectBalances(uuid, 0);
        logger.emitGenericLog("cancelProject", "");
    }

    /// @notice Pays out upon project completion
    /// @notice Updates escrow balances
    function rewardProjectCompletion(uint uuid) public onlyVoteController {
        communityAccount.transferTokensOut(
            address(nativeTokenInstance),
            communityAccount.escrowedProjectPayees(uuid),
            communityAccount.escrowedProjectBalances(uuid));
        communityAccount.setTotalProjectEscrow(SafeMath.sub(communityAccount.totalProjectEscrow(), communityAccount.escrowedProjectBalances(uuid)));
        communityAccount.setEscrowedProjectBalances(uuid, 0);
        logger.emitGenericLog("rewardProjectCompletion", "");
    }

    /// @notice Stake code (in community tokens)
    function stakeCommunityTokens() public {

        require(minimumStakingRequirement >= communityAccount.stakedBalances(msg.sender));

        uint amount = minimumStakingRequirement - communityAccount.stakedBalances(msg.sender);
        require(amount > 0);
        require(communityTokenInstance.transferFrom(msg.sender, address(communityAccount), amount));

        communityAccount.setStakedBalances(SafeMath.add(communityAccount.stakedBalances(msg.sender), amount), msg.sender);
        communityAccount.setTotalStaked(SafeMath.add(communityAccount.totalStaked(), amount));
        communityAccount.setTimeStaked(now, msg.sender);
        logger.emitGenericLog("stakeCommunityTokens", "");
    }

    /// @notice Unstakes user from community and sends funds back to user
    /// @notice Checks lockup period and balance before unstaking
    function unstakeCommunityTokens() public {
        uint amount = communityAccount.stakedBalances(msg.sender);

        require(now - communityAccount.timeStaked(msg.sender) >= lockupPeriodSeconds);

        communityAccount.setStakedBalances(0, msg.sender);
        communityAccount.setTotalStaked(SafeMath.sub(communityAccount.totalStaked(), amount));
        require(communityAccount.transferTokensOut(address(communityTokenInstance), msg.sender, amount));
        logger.emitGenericLog("unstakeCommunityTokens", "");
    }

    /// @notice Checks that the user is fully staked
    function isMember(address memberAddress) public view returns (bool) {
        return (communityAccount.stakedBalances(memberAddress) >= minimumStakingRequirement);
    }
}