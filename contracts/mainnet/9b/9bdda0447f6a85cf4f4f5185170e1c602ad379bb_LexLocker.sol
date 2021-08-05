/**
 *Submitted for verification at Etherscan.io on 2020-11-16
*/

/*
██╗     ███████╗██╗  ██╗    
██║     ██╔════╝╚██╗██╔╝    
██║     █████╗   ╚███╔╝     
██║     ██╔══╝   ██╔██╗     
███████╗███████╗██╔╝ ██╗    
╚══════╝╚══════╝╚═╝  ╚═╝                                                                             
██╗      ██████╗  ██████╗██╗  ██╗███████╗██████╗     
██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗    
██║     ██║   ██║██║     █████╔╝ █████╗  ██████╔╝    
██║     ██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗    
███████╗╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║    
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
DEAR MSG.SENDER(S):
/ LXL is a project in beta
// Please audit & use at your own risk
/// Entry into LXL shall not create an attorney/client relationship
//// Likewise, LXL should not be construed as legal advice or replacement for professional counsel
///// STEAL THIS C0D3SL4W 
~presented by LexDAO LLC \+|+/ 
*/
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.4;

interface IERC20 { // brief interface for erc20 token tx
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

library Address { // helper for address type - see openzeppelin-contracts/blob/master/contracts/utils/Address.sol
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}

library SafeERC20 { // wrapper around erc20 token tx for non-standard contract - see openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
    using Address for address;
    
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returnData) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returnData.length > 0) { // return data is optional
            require(abi.decode(returnData, (bool)), "SafeERC20: erc20 operation did not succeed");
        }
    }
}

library SafeMath { // arithmetic wrapper for unit under/overflow check
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }
}

contract Context { // describe current contract execution context (metaTX support) - see openzeppelin-contracts/blob/master/contracts/GSN/Context.sol
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ReentrancyGuard { // call wrapper for reentrancy check - see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
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

/**
 * @title LexLocker.
 * @author LexDAO LLC.
 * @notice Milestone token locker registry with resolution. 
 */
contract LexLocker is Context, ReentrancyGuard { 
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /*$<⚖️️> LXL <⚔️>$*/
    address public manager; // account managing LXL settings - see 'Manager Functions' - updateable by manager
    address public swiftResolverToken; // token required to participate as swift resolver - updateable by manager
    address public wETH; // ether token wrapper contract reference - updateable by manager
    uint256 private lockerCount; // lockers counted into LXL registry
    uint256 public MAX_DURATION; // time limit in seconds on token lockup - default 63113904 (2-year) - updateable by manager
    uint256 public resolutionRate; // rate to determine resolution fee for disputed locker (e.g., 20 = 5% of remainder) - updateable by manager
    uint256 public swiftResolverTokenBalance; // balance required in `swiftResolverToken` to participate as swift resolver - updateable by manager
    string public lockerTerms; // general terms wrapping LXL - updateable by manager
    string[] public marketTerms; // market terms stamped by manager
    string[] public resolutions; // locker resolutions stamped by LXL resolver
    
    mapping(address => uint256[]) private clientRegistrations; // tracks registered lockers per client account
    mapping(address => uint256[]) private providerRegistrations; // tracks registered lockers per provider account
    mapping(address => bool) public swiftResolverConfirmed; // tracks registered swift resolver status
    mapping(uint256 => ADR) public adrs; // tracks ADR details for registered LXL
    mapping(uint256 => Locker) public lockers; // tracks registered LXL details
    
    event DepositLocker(address indexed client, address clientOracle, address indexed provider, address indexed resolver, address token, uint256[] amount, uint256 registration, uint256 sum, uint256 termination, string details, bool swiftResolver);
    event RegisterLocker(address indexed client, address clientOracle, address indexed provider, address indexed resolver, address token, uint256[] amount, uint256 registration, uint256 sum, uint256 termination, string details, bool swiftResolver);
    event ConfirmLocker(uint256 registration); 
    event RequestLockerResolution(address indexed client, address indexed counterparty, address indexed resolver, address token, uint256 deposit, uint256 registration, string details, bool swiftResolver); 
    event Release(uint256 milestone, uint256 registration); 
    event Withdraw(uint256 registration);
    event AssignClientOracle(address indexed clientOracle, uint256 registration);
    event ClientProposeResolver(address indexed proposedResolver, uint256 registration, string details);
    event ProviderProposeResolver(address indexed proposedResolver, uint256 registration, string details);
    event Lock(address indexed caller, uint256 registration, string details);
    event Resolve(address indexed resolver, uint256 clientAward, uint256 providerAward, uint256 registration, uint256 resolutionFee, string resolution); 
    event AddMarketTerms(uint256 index, string terms);
    event AmendMarketTerms(uint256 index, string terms);
    event UpdateLockerSettings(address indexed manager, address indexed swiftResolverToken, address wETH, uint256 MAX_DURATION, uint256 resolutionRate, uint256 swiftResolverTokenBalance, string lockerTerms);
    event TributeToManager(uint256 amount, string details);
    event UpdateSwiftResolverStatus(address indexed swiftResolver, string details, bool confirmed);

    struct ADR {  
        address proposedResolver;
        address resolver;
        uint8 clientProposedResolver;
        uint8 providerProposedResolver;
	    uint256 resolutionRate;
	    string resolution;
	    bool swiftResolver;
    }
    
    struct Locker {  
        address client; 
        address clientOracle;
        address provider;
        address token;
        uint8 confirmed;
        uint8 locked;
        uint256[] amount;
        uint256 currentMilestone;
        uint256 milestones;
        uint256 released;
        uint256 sum;
        uint256 termination;
        string details; 
    }
    
    constructor(
        address _manager, 
        address _swiftResolverToken, 
        address _wETH,
        uint256 _MAX_DURATION,
        uint256 _resolutionRate, 
        uint256 _swiftResolverTokenBalance, 
        string memory _lockerTerms
    ) {
        manager = _manager;
        swiftResolverToken = _swiftResolverToken;
        wETH = _wETH;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
        swiftResolverTokenBalance = _swiftResolverTokenBalance;
        lockerTerms = _lockerTerms;
    }

    /***************
    LOCKER FUNCTIONS
    ***************/
    // ************
    // REGISTRATION
    // ************
    /**
     * @notice LXL can be registered as deposit from `client` for benefit of `provider`.
     * @dev If LXL `token` is wETH, msg.value can be wrapped into wETH in single call.
     * @param clientOracle Account that can help call `release()` and `withdraw()` (default to `client` if unsure).
     * @param provider Account to receive registered `amount`s.
     * @param resolver Account that can call `resolve()` to award `sum` remainder between LXL parties.
     * @param token Token address for `amount` deposit.
     * @param amount Lump `sum` or array of milestone `amount`s to be sent to `provider` on call of `release()`.
     * @param termination Exact `termination` date in seconds since epoch.
     * @param details Context re: LXL.
     * @param swiftResolver If `true`, `sum` remainder can be resolved by holders of `swiftResolverToken`.
     */
    function depositLocker( // CLIENT-TRACK
        address clientOracle, 
        address provider,
        address resolver,
        address token,
        uint256[] memory amount, 
        uint256 termination, 
        string memory details,
        bool swiftResolver 
    ) external nonReentrant payable returns (uint256) {
        require(_msgSender() != resolver && clientOracle != resolver && provider != resolver, "client/clientOracle/provider = resolver");
        require(termination <= block.timestamp.add(MAX_DURATION), "duration maxed");
        
        uint256 sum;
        for (uint256 i = 0; i < amount.length; i++) {
            sum = sum.add(amount[i]);
        }

        if (msg.value > 0) {
            require(token == wETH && msg.value == sum, "!ethBalance");
            (bool success, ) = wETH.call{value: msg.value}("");
            require(success, "!ethCall");
            IERC20(wETH).safeTransfer(address(this), msg.value);
        } else {
            IERC20(token).safeTransferFrom(_msgSender(), address(this), sum);
        }
        
        lockerCount++;
        uint256 registration = lockerCount;
       
        clientRegistrations[_msgSender()].push(registration);
        providerRegistrations[provider].push(registration);
        
        adrs[registration] = ADR( 
            address(0),
            resolver,
            0,
            0,
	        resolutionRate, 
	        "",
	        swiftResolver);

        lockers[registration] = Locker( 
            _msgSender(), 
            clientOracle,
            provider,
            token,
            1,
            0,
            amount,
            1,
            amount.length,
            0,
            sum,
            termination,
            details);

        emit DepositLocker(_msgSender(), clientOracle, provider, resolver, token, amount, registration, sum, termination, details, swiftResolver); 
        
	    return registration;
    }
    
    /**
     * @notice LXL can be registered as `provider` request for `client` deposit (by calling `confirmLocker()`).
     * @param client Account to provide `sum` deposit and call `release()` of registered `amount`s.
     * @param clientOracle Account that can help call `release()` and `withdraw()` (default to `client` if unsure).
     * @param provider Account to receive registered `amount`s.
     * @param resolver Account that can call `resolve()` to award `sum` remainder between LXL parties.
     * @param token Token address for `amount` deposit.
     * @param amount Lump `sum` or array of milestone `amount`s to be sent to `provider` on call of `release()`.
     * @param termination Exact `termination` date in seconds since epoch.
     * @param details Context re: LXL.
     * @param swiftResolver If `true`, `sum` remainder can be resolved by holders of `swiftResolverToken`.
     */
    function registerLocker( // PROVIDER-TRACK
        address client,
        address clientOracle, 
        address provider,
        address resolver,
        address token,
        uint256[] memory amount, 
        uint256 termination, 
        string memory details,
        bool swiftResolver 
    ) external nonReentrant returns (uint256) {
        require(client != resolver && clientOracle != resolver && provider != resolver, "client/clientOracle/provider = resolver");
        require(termination <= block.timestamp.add(MAX_DURATION), "duration maxed");
        
        uint256 sum;
        for (uint256 i = 0; i < amount.length; i++) {
            sum = sum.add(amount[i]);
        }
 
        lockerCount++;
        uint256 registration = lockerCount;
        
        clientRegistrations[client].push(registration);
        providerRegistrations[provider].push(registration);
       
        adrs[registration] = ADR( 
            address(0),
            resolver,
            0,
            0,
	        resolutionRate, 
	        "",
	        swiftResolver);

        lockers[registration] = Locker( 
            client, 
            clientOracle,
            provider,
            token,
            0,
            0,
            amount,
            1,
            amount.length,
            0,
            sum,
            termination,
            details);

        emit RegisterLocker(client, clientOracle, provider, resolver, token, amount, registration, sum, termination, details, swiftResolver); 
        
	    return registration;
    }
    
    /**
     * @notice LXL `client` can confirm after `registerLocker()` is called to deposit `sum` for `provider`.
     * @dev If LXL `token` is wETH, msg.value can be wrapped into wETH in single call.
     * @param registration Registered LXL number.
     */
    function confirmLocker(uint256 registration) external nonReentrant payable { // PROVIDER-TRACK
        Locker storage locker = lockers[registration];
        
        require(_msgSender() == locker.client, "!client");
        require(locker.confirmed == 0, "confirmed");
        
        address token = locker.token;
        uint256 sum = locker.sum;
        
        if (msg.value > 0) {
            require(token == wETH && msg.value == sum, "!ethBalance");
            (bool success, ) = wETH.call{value: msg.value}("");
            require(success, "!ethCall");
            IERC20(wETH).safeTransfer(address(this), msg.value);
        } else {
            IERC20(token).safeTransferFrom(_msgSender(), address(this), sum);
        }
        
        locker.confirmed = 1;
        
        emit ConfirmLocker(registration); 
    }
    
    /**
     * @notice LXL depositor (`client`) can request direct resolution between selected `counterparty` over `deposit`. E.g., staked wager to benefit charity as `counterparty`.
     * @dev If LXL `token` is wETH, msg.value can be wrapped into wETH in single call. 
     * @param counterparty Other account (`provider`) that can receive award from `resolver`.
     * @param resolver Account that can call `resolve()` to award `deposit` between LXL parties.
     * @param token Token address for `deposit`.
     * @param deposit Lump sum amount for `deposit`.
     * @param details Context re: resolution request.
     * @param swiftResolver If `true`, `deposit` can be resolved by holders of `swiftResolverToken`.
     */
    function requestLockerResolution(address counterparty, address resolver, address token, uint256 deposit, string memory details, bool swiftResolver) external nonReentrant payable returns (uint256) {
        require(_msgSender() != resolver && counterparty != resolver, "client/counterparty = resolver");
        
        if (msg.value > 0) {
            require(token == wETH && msg.value == deposit, "!ethBalance");
            (bool success, ) = wETH.call{value: msg.value}("");
            require(success, "!ethCall");
            IERC20(wETH).safeTransfer(address(this), msg.value);
        } else {
            IERC20(token).safeTransferFrom(_msgSender(), address(this), deposit);
        }
        
        uint256[] memory amount = new uint256[](1);
        amount[0] = deposit;
        lockerCount++;
        uint256 registration = lockerCount;
        
        clientRegistrations[_msgSender()].push(registration);
        providerRegistrations[counterparty].push(registration);
        
        adrs[registration] = ADR( 
            address(0),
            resolver,
            0,
            0,
	        resolutionRate, 
	        "",
	        swiftResolver);
     
        lockers[registration] = Locker( 
            _msgSender(), 
            address(0),
            counterparty,
            token,
            1,
            1,
            amount,
            0,
            0,
            0,
            deposit,
            0,
            details);

        emit RequestLockerResolution(_msgSender(), counterparty, resolver, token, deposit, registration, details, swiftResolver); 
        
	    return registration;
    }
    
    // ***********
    // CLIENT MGMT
    // ***********
    /**
     * @notice LXL `client` can assign account as `clientOracle` to help call `release()` and `withdraw()`.
     * @param clientOracle Account that can help call `release()` and `withdraw()` (default to `client` if unsure).
     * @param registration Registered LXL number.
     */
    function assignClientOracle(address clientOracle, uint256 registration) external nonReentrant {
        Locker storage locker = lockers[registration];
        
        require(_msgSender() == locker.client, "!client");
        require(locker.locked == 0, "locked");
	    require(locker.released < locker.sum, "released");
        
        locker.clientOracle = clientOracle;
        
        emit AssignClientOracle(clientOracle, registration);
    }
    
    /**
     * @notice LXL `client` or `clientOracle` can release milestone `amount` to `provider`. 
     * @param registration Registered LXL number.
     */
    function release(uint256 registration) external nonReentrant {
    	Locker storage locker = lockers[registration];
	    
	    require(_msgSender() == locker.client || _msgSender() == locker.clientOracle, "!client/oracle");
	    require(locker.confirmed == 1, "!confirmed");
	    require(locker.locked == 0, "locked");
	    require(locker.released < locker.sum, "released");
        
        uint256 milestone = locker.currentMilestone-1;
        uint256 payment = locker.amount[milestone];
        
        IERC20(locker.token).safeTransfer(locker.provider, payment);
        locker.released = locker.released.add(payment);
        if (locker.released < locker.sum) {locker.currentMilestone++;}
        
	    emit Release(milestone+1, registration); 
    }
    
    /**
     * @notice LXL `client` or `clientOracle` can withdraw `sum` remainder after `termination`. 
     * @dev `release()` can still be called by `client` or `clientOracle` after `termination` to preserve extension option. 
     * @param registration Registered LXL number.
     */
    function withdraw(uint256 registration) external nonReentrant {
    	Locker storage locker = lockers[registration];
        
        require(_msgSender() == locker.client || _msgSender() == locker.clientOracle, "!client/oracle");
        require(locker.confirmed == 1, "!confirmed");
        require(locker.locked == 0, "locked");
        require(locker.released < locker.sum, "released");
        require(locker.termination < block.timestamp, "!terminated");
        
        uint256 remainder = locker.sum.sub(locker.released); 
        IERC20(locker.token).safeTransfer(locker.client, remainder);
        locker.released = locker.sum; 
        
	    emit Withdraw(registration); 
    }
    
    // **********
    // RESOLUTION
    // **********
    /**
     * @notice LXL `client` or `provider` can lock to freeze release and withdrawal of `sum` remainder until `resolver` calls `resolve()`. 
     * @dev `lock()` can be called repeatedly to allow LXL parties to continue to provide context until resolution. 
     * @param registration Registered LXL number.
     * @param details Context re: lock / dispute.
     */
    function lock(uint256 registration, string calldata details) external nonReentrant {
        Locker storage locker = lockers[registration]; 
        
        require(_msgSender() == locker.client || _msgSender() == locker.provider, "!party"); 
        require(locker.confirmed == 1, "!confirmed");
        require(locker.released < locker.sum, "released");

	    locker.locked = 1; 
	    
	    emit Lock(_msgSender(), registration, details);
    }
    
    /**
     * @notice After LXL is locked, selected `resolver` calls to distribute `sum` remainder between `client` and `provider` minus fee.
     * @param registration Registered LXL number.
     * @param clientAward Remainder awarded to `client`.
     * @param providerAward Remainder awarded to `provider`.
     * @param resolution Context re: resolution.
     */
    function resolve(uint256 clientAward, uint256 providerAward, uint256 registration, string calldata resolution) external nonReentrant {
        ADR storage adr = adrs[registration];
        Locker storage locker = lockers[registration];
        
        uint256 remainder = locker.sum.sub(locker.released); 
	    uint256 resolutionFee = remainder.div(adr.resolutionRate); // calculate dispute resolution fee as set on registration
	    
	    require(_msgSender() != locker.client && _msgSender() != locker.clientOracle && _msgSender() != locker.provider, "client/clientOracle/provider = resolver");
	    require(locker.locked == 1, "!locked"); 
	    require(locker.released < locker.sum, "released");
	    require(clientAward.add(providerAward) == remainder.sub(resolutionFee), "awards != remainder - fee");
	    
	    if (adr.swiftResolver) {
	        require(IERC20(swiftResolverToken).balanceOf(_msgSender()) >= swiftResolverTokenBalance && swiftResolverConfirmed[_msgSender()], "!swiftResolverTokenBalance/confirmed");
        } else {
            require(_msgSender() == adr.resolver, "!resolver");
        }

        IERC20(locker.token).safeTransfer(locker.client, clientAward);
        IERC20(locker.token).safeTransfer(locker.provider, providerAward);
        IERC20(locker.token).safeTransfer(adr.resolver, resolutionFee);
	    
	    adr.resolution = resolution;
	    locker.released = locker.sum; 
	    resolutions.push(resolution);
	    
	    emit Resolve(_msgSender(), clientAward, providerAward, registration, resolutionFee, resolution);
    }
    
    /**
     * @notice 1-time, fallback to allow LXL party to suggest new `resolver` to counterparty.
     * @dev LXL `client` calls to update `resolver` selection - if matches `provider` suggestion or confirmed, `resolver` updates. 
     * @param proposedResolver Proposed account to resolve LXL.
     * @param registration Registered LXL number.
     * @param details Context re: proposed `resolver`.
     */
    function clientProposeResolver(address proposedResolver, uint256 registration, string calldata details) external nonReentrant { 
        ADR storage adr = adrs[registration];
        Locker storage locker = lockers[registration]; 
        
        require(_msgSender() == locker.client, "!client"); 
        require(adr.clientProposedResolver == 0, "pending");
	    require(locker.released < locker.sum, "released");
        
        if (adr.proposedResolver == proposedResolver) {
            adr.resolver = proposedResolver;
        } else {
            adr.clientProposedResolver = 0;
            adr.providerProposedResolver = 0;
        }

	    adr.proposedResolver = proposedResolver; 
	    adr.clientProposedResolver = 1;
	    
	    emit ClientProposeResolver(proposedResolver, registration, details);
    }
    
    /**
     * @notice 1-time, fallback to allow LXL party to suggest new `resolver` to counterparty.
     * @dev LXL `provider` calls to update `resolver` selection. If matches `client` suggestion or confirmed, `resolver` updates. 
     * @param proposedResolver Proposed account to resolve LXL.
     * @param registration Registered LXL number.
     * @param details Context re: proposed `resolver`.
     */
    function providerProposeResolver(address proposedResolver, uint256 registration, string calldata details) external nonReentrant { 
        ADR storage adr = adrs[registration];
        Locker storage locker = lockers[registration]; 
        
        require(_msgSender() == locker.provider, "!provider"); 
        require(adr.providerProposedResolver == 0, "pending");
	    require(locker.released < locker.sum, "released");

	    if (adr.proposedResolver == proposedResolver) {
            adr.resolver = proposedResolver;
        } else {
            adr.clientProposedResolver = 0;
            adr.providerProposedResolver = 0;
        }
	    
	    adr.proposedResolver = proposedResolver;
	    adr.providerProposedResolver = 1;
	    
	    emit ProviderProposeResolver(proposedResolver, registration, details);
    }
    
    /**
     * @notice Swift resolvers can call to update service status.
     * @dev Swift resolvers must first confirm and can continue with details / cancel service.  
     * @param details Context re: status update.
     * @param confirmed If `true`, swift resolver can participate in LXL resolution.
     */
    function updateSwiftResolverStatus(string calldata details, bool confirmed) external nonReentrant {
        require(IERC20(swiftResolverToken).balanceOf(_msgSender()) >= swiftResolverTokenBalance, "!swiftResolverTokenBalance");
        swiftResolverConfirmed[_msgSender()] = confirmed;
        emit UpdateSwiftResolverStatus(_msgSender(), details, confirmed);
    }
    
    // *******
    // GETTERS
    // *******
    function getClientRegistrations(address account) external view returns (uint256[] memory) { // get set of `client` registered lockers 
        return clientRegistrations[account];
    }
    
    function getLockerCount() external view returns (uint256) { // helper to make it easier to track total lockers
        return lockerCount;
    }
    
    function getLockerMilestones(uint256 registration) external view returns (address, uint256[] memory) { // returns `token` and batch of milestone amounts for `provider`
        return (lockers[registration].token, lockers[registration].amount);
    }
    
    function getMarketTermsCount() external view returns (uint256) { // helper to make it easier to track total market terms stamped by `manager`
        return marketTerms.length;
    }
    
    function getProviderRegistrations(address account) external view returns (uint256[] memory) { // get set of `provider` registered lockers
        return providerRegistrations[account];
    }
    
    function getResolutionCount() external view returns (uint256) { // helper to make it easier to track total resolutions passed by LXL `resolver`s
        return resolutions.length;
    }
   
    /****************
    MANAGER FUNCTIONS
    ****************/
    /**
     * @dev Throws if caller is not LXL `manager`.
     */
    modifier onlyManager {
        require(msg.sender == manager, "!manager");
        _;
    }
    
    /**
     * @notice Updates LXL with new market `terms`. 
     * @param terms New `terms` to add to LXL market. 
     */
    function addMarketTerms(string calldata terms) external nonReentrant onlyManager {
        marketTerms.push(terms);
        emit AddMarketTerms(marketTerms.length-1, terms);
    }
    
    /**
     * @notice Updates LXL with amended market `terms`. 
     * @param index Targeted location in `marketTerms` array.
     * @param terms Amended `terms` to add to LXL market. 
     */
    function amendMarketTerms(uint256 index, string calldata terms) external nonReentrant onlyManager {
        marketTerms[index] = terms;
        emit AmendMarketTerms(index, terms);
    }
    
    /**
     * @notice General payment function for `manager` of LXL contract. 
     * @param details Describes context for ether transfer.
     */
    function tributeToManager(string calldata details) external nonReentrant payable { 
        (bool success, ) = manager.call{value: msg.value}("");
        require(success, "!ethCall");
        emit TributeToManager(msg.value, details);
    }
    
    /**
     * @notice Updates LXL management settings.
     * @param _manager Account that governs LXL contract settings.
     * @param _swiftResolverToken Token to mark participants in swift resolution.
     * @param _wETH Standard contract reference to wrap ether. 
     * @param _MAX_DURATION Time limit in seconds on token lockup - default 63113904 (2-year).
     * @param _resolutionRate Rate to determine resolution fee for disputed locker (e.g., 20 = 5% of remainder).
     * @param _swiftResolverTokenBalance Token balance required to perform swift resolution. 
     * @param _lockerTerms General terms wrapping LXL.  
     */
    function updateLockerSettings(
        address _manager, 
        address _swiftResolverToken, 
        address _wETH, 
        uint256 _MAX_DURATION, 
        uint256 _resolutionRate, 
        uint256 _swiftResolverTokenBalance, 
        string calldata _lockerTerms
    ) external nonReentrant onlyManager { 
        manager = _manager;
        swiftResolverToken = _swiftResolverToken;
        wETH = _wETH;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
        swiftResolverTokenBalance = _swiftResolverTokenBalance;
        lockerTerms = _lockerTerms;
	    
	    emit UpdateLockerSettings(_manager, _swiftResolverToken, _wETH, _MAX_DURATION, _resolutionRate, _swiftResolverTokenBalance, _lockerTerms);
    }
}