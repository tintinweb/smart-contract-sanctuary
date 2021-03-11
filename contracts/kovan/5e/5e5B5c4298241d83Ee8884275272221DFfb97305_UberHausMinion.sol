/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 { // interface for erc20 approve/transfer
    function balanceOf(address who) external view returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);
}

library SafeMath { // arithmetic wrapper for unit under/overflow check
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
}


contract ReentrancyGuard { // call wrapper for reentrancy check
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
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


interface IMOLOCH { // brief interface for moloch dao v2

    function cancelProposal(uint256 proposalId) external;
    
    function depositToken() external view returns (address);
    
    function getProposalFlags(uint256 proposalId) external view returns (bool[6] memory);
    
    function getTotalLoot() external view returns (uint256); 
    
    function getTotalShares() external view returns (uint256); 
    
    function getUserTokenBalance(address user, address token) external view returns (uint256);
    
    function members(address user) external view returns (address, uint256, uint256, bool, uint256, uint256);
    
    function ragequit(uint256 sharesToBurn, uint256 lootToBurn) external; 

    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);
    
    function tokenWhitelist(address token) external view returns (bool);

    function updateDelegateKey(address newDelegateKey) external; 
    
    function userTokenBalances(address user, address token) external view returns (uint256);

    function withdrawBalance(address token, uint256 amount) external;
}


contract UberHausMinion is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    IMOLOCH public moloch;
    IERC20 public haus;
    
    address public dao; // dao that manages minion 
    address public uberHaus; // address of uberHaus 
    address public controller; // address of person who can update uberHaus (for pre-UH minions)
    address[] public delegateList; // list of child dao delegates
    address public currentDelegate; // current delegate 
    address public initialDelegate; // initial delegate if set at summoning
    uint256 public delegateRewardsFactor; // percent of HAUS given to delegates 
    uint256 public minionId; // ID to keep minions straight
    string public desc; //description of minion
    bool private initialized; // internally tracks deployment under eip-1167 proxy pattern
    bool private initialDelegation; // tracks whether initial delegate has been appointed
    
    address public constant REWARDS = address(0xfeed);
    address public constant HAUS = 0xAb5cC910998Ab6285B4618562F1e17f3728af662; //0xb0C5f3100A4d9d9532a4CfD68c55F1AE8da987Eb; xDAI HAUS token address 
    uint256 public constant DIVIDER = 1000;

    mapping(uint256 => Action) public actions; // proposalId => Action
    mapping(uint256 => Appointment) public appointments; // proposalId => Appointment
    mapping(address => Delegate) public delegates; // delegates of child dao
    mapping(address => mapping(address => uint256)) public userTokenBalances;

    
    struct Action {
        address dao;
        uint256 value;
        address token;
        address to;
        address proposer;
        bool executed;
        bytes data;
    }
    
    struct Appointment {
        address dao;
        address nominee;
        uint256 retireTime;
        address proposer;
        bool executed;
    }
    
    struct Delegate {
        bool rewarded;
        bool serving; 
        bool impeached; 
    }
    

    event ProposeAction(uint256 proposalId, address proposer);
    event ProposeAppointment(uint256 proposalId, address proposer, address nominee, uint256 retireTime);
    event ExecuteAction(uint256 proposalId, address executor);
    event DelegateAppointed(uint256 proposalId, address executor, address currentDelegate);
    event Impeachment(address delegate, address impeacher);
    event DoWithdraw(address targetDao, address token, uint256 amount);
    event HausWithdraw(address token, uint256 amount);
    event PulledFunds(address token, uint256 amount);
    event RewardsClaimed(address currentDelegate, uint256 amount);
    event Canceled(uint256 proposalId, uint8 proposalType);
    event SetUberHaus(address uberHaus);

    
    modifier memberOnly() {
        require(isMember(msg.sender), "Minion::not member");
        _;
    }
    
    modifier delegateOnly() {
        require(delegates[msg.sender].serving == true, "Minion::not delegate");
        _;
    }
    
    
    /*
     * @param _dao The address of the child dao joining UberHaus
     * @param _uberHaus The address of UberHaus dao
     * @param _Haus The address of the HAUS token
     * @param _delegateRewardFactor The percentage out of 10,000 that the delegate will recieve as a reward
     * @param _DESC Name or description of the minion
     */  
    
    function init(
        address _dao, 
        address _uberHaus, 
        address _controller,
        address _initialDelegate,
        uint256 _delegateRewardFactor,
        uint256 _minionId,
        string memory _desc
    )  public {
        require(_dao != address(0), "no 0x address");
        require(!initialized, "already initialized");
        
        moloch = IMOLOCH(_dao);
        haus = IERC20(HAUS);
        dao = _dao;
        uberHaus = _uberHaus;
        controller = _controller;
        currentDelegate = _initialDelegate;
        initialDelegate = _initialDelegate;
        delegateRewardsFactor = _delegateRewardFactor;
        minionId = _minionId;
        desc = _desc;
        initialized = true; 
        
        require(isMember(_initialDelegate), "delegate !member");

        delegates[_initialDelegate] = Delegate(false, true, false);
        delegateList.push(_initialDelegate);
        
        // Approve HAUS if UberHaus has been summonned
        if(uberHaus != address(0)){
            haus.approve(uberHaus, uint256(-1));
        }
        
        initialized = true;
    }
    
    //  -- Withdraw Functions --

    function doWithdraw(address targetDao, address token, uint256 amount) external memberOnly {
        // Withdraws funds from any Moloch (incl. UberHaus or the minion owner DAO) into this Minion
        require(IMOLOCH(targetDao).getUserTokenBalance(address(this), token) >= amount, "user balance < amount");
        IMOLOCH(targetDao).withdrawBalance(token, amount); // withdraw funds from DAO
        emit DoWithdraw(targetDao, token, amount);
    }
    
    
    function pullGuildFunds(address token, uint256 amount) external delegateOnly {
        // Pulls tokens from the Minion into its master moloch 
        require(moloch.tokenWhitelist(token), "token !whitelisted by master dao");
        require(IERC20(token).balanceOf(address(this)) >= amount, "amount > balance");
        IERC20(token).transfer(address(moloch), amount);
        emit PulledFunds(token, amount);
    }
    
    function claimDelegateReward() external delegateOnly nonReentrant {
        // Allows delegate to claim rewards once during term
        Delegate memory del = delegates[currentDelegate];
        
        require(!del.impeached, "delegate impeached");
        require(del.serving, "delegate not serving");
        require(!del.rewarded, "delegate already rewarded");
        
        uint256 hausBalance = haus.balanceOf(address(this));
        uint256 rewards = hausBalance.mul(delegateRewardsFactor).div(DIVIDER);
        
        haus.transfer(address(currentDelegate), rewards);
        delegates[currentDelegate].rewarded = true;

        emit RewardsClaimed(currentDelegate, rewards);
    }
    
    //  -- Proposal Functions --
    
    function proposeAction(
        address targetDao, // defaults to childDAO
        address actionTo,
        address token,
        uint256 actionValue,
        bytes calldata actionData,
        string calldata details
    ) external memberOnly returns (uint256) {
        // No calls to zero address allows us to check that proxy submitted
        // the proposal without getting the proposal struct from parent moloch
        require(actionTo != address(0), "invalid actionTo");

        uint256 proposalId = IMOLOCH(targetDao).submitProposal(
            address(this),
            0,
            0,
            0,
            token,
            0,
            token,
            details
        );

        Action memory action = Action({
            dao: targetDao,
            value: actionValue,
            token: token,
            to: actionTo,
            proposer: msg.sender,
            executed: false,
            data: actionData
        });

        actions[proposalId] = action;
        
        // add more info to the event. 

        emit ProposeAction(proposalId, msg.sender);
        return proposalId;
    }

    function executeAction(uint256 proposalId) external returns (bytes memory) {
        Action storage action = actions[proposalId];
        bool[6] memory flags = IMOLOCH(action.dao).getProposalFlags(proposalId);

        require(action.to != address(0), "invalid proposalId");
        require(!action.executed, "action executed");
        require(flags[2], "proposal not passed");

        // execute call
        actions[proposalId].executed = true;
        (bool success, bytes memory retData) = action.to.call{value: action.value}(action.data);
        require(success, "call failure");
        emit ExecuteAction(proposalId, msg.sender);
        return retData;
    }
    
    function nominateDelegate(
        address targetDao, //default would be UberHaus  
        address nominee,
        uint256 retireTime,
        string calldata details
    ) external memberOnly returns (uint256) {
        // No calls to zero address allows us to check that proxy submitted
        // the proposal without getting the proposal struct from parent moloch
        require(targetDao != address(0), "invalid actionTo");

        uint256 proposalId = IMOLOCH(moloch).submitProposal(
            address(this),
            0,
            0,
            0,
            HAUS, // includes whitelisted token to avoid errors on DAO end
            0,
            HAUS,
            details
        );

        Appointment memory appointment = Appointment({
            dao: targetDao, 
            nominee: nominee,
            retireTime: retireTime,
            proposer: msg.sender,
            executed: false
        });

        appointments[proposalId] = appointment;

        emit ProposeAppointment(proposalId, msg.sender, nominee, retireTime);
        return proposalId;
    }

    function executeAppointment(uint256 proposalId) external returns (address) {
        Appointment storage appointment = appointments[proposalId];
        bool[6] memory flags = IMOLOCH(moloch).getProposalFlags(proposalId);

        require(appointment.dao != address(0), "invalid delegation address");
        require(!appointment.executed, "appointment already executed");
        require(flags[2], "proposal not passed");

        // execute call
        appointment.executed = true;
        IMOLOCH(appointment.dao).updateDelegateKey(appointment.nominee);
        delegates[appointment.nominee] = Delegate(false, true, false);
        delegateList.push(appointment.nominee);
        currentDelegate = appointment.nominee;
        
        emit DelegateAppointed(proposalId, msg.sender, appointment.nominee);
        return appointment.nominee;
    }
    
    function cancelAction(uint256 _proposalId, uint8 _type) external {
        if(_type == 1){
            Action storage action = actions[_proposalId];
            require(msg.sender == action.proposer, "not proposer");
            delete actions[_proposalId];
        } else if (_type == 2){
            Appointment storage appointment = appointments[_proposalId];
            require(msg.sender == appointment.proposer, "not proposer");
            delete appointments[_proposalId];
        } 
        
        emit Canceled(_proposalId, _type);
        moloch.cancelProposal(_proposalId);
    }

    
    //  -- Emergency Functions --
    
    function impeachDelegate(address delegate) external memberOnly {
        require(!delegates[currentDelegate].impeached, "already impeached");
        delegates[currentDelegate].impeached = true; 
        IMOLOCH(uberHaus).updateDelegateKey(address(this));
        
        emit Impeachment(delegate, msg.sender);
    }
    
    
    //  -- Helper Functions --
    
    function approveUberHaus() external memberOnly {
        // function to make it easier for DAOs to join uberHaus without having to first do a proposal to approve uberHaus to spend HAUS
        require(uberHaus != address(0), "no uberhaus set");
        uint256 wad = haus.balanceOf(address(this));
        haus.approve(uberHaus, wad);
    }
    
    
    function isMember(address user) public view returns (bool) {
        (, uint shares,,,,) = moloch.members(user);
        return shares > 0;
    }
    
    function updateUberHaus(address _uberHaus) external returns (address) {
        // limited admin function to update uberHaus address once
        // @Dev meant for setting up genesis members
        require(msg.sender == controller, "only controller");
        require(uberHaus == address(0), "already updated");
        uberHaus = _uberHaus;
        
        emit SetUberHaus(uberHaus);
        return uberHaus;
    }
    
    function setInitialDelegate() public {
        require(uberHaus != address(0), "uberHaus !set");
        require(!initialDelegation, "already set");
        require(initialDelegate == currentDelegate, "new delegate"); 
        IMOLOCH(uberHaus).updateDelegateKey(initialDelegate);
        initialDelegation == true;
    }
}