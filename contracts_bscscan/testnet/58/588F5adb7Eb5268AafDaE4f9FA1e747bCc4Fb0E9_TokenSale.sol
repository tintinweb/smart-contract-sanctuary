// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ITokenLocker.sol";

/// @title Tokensale contract for sale token to public user
/// @dev Using proxy pattern be careful to use when need to improve contract to next version
contract TokenSale is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    struct TokenBuy {
        address tokenBuyAddress;
        uint256 rate;
        uint256 min;
        uint256 max;
    }

    struct EtherBuy {
        uint256 rate;
        uint256 min;
        uint256 max;
    }
    
    enum saleMethod{ ETHER, TOKEN, DISTRIBUTOR, ADD_LOCK }
    
    // use from ICO TOKEN Contract
    IERC20MetadataUpgradeable public token;
    // Token Locker 
    ITokenLocker public tokenLocker;

    EtherBuy public etherBuy;          
    
    uint256 public RATE_DECIMALS;
    
    uint256 public FUNDING_GOAL;
    
    uint256 public tokenRaised;
    
    uint256 public etherRaised;
    
    uint256 public totalTokenLock;
    // user limit tokensale token receive
    uint256 public limitTokenReceivePerUser;    
    
    uint48 public whitelistEndTime;

    uint48 public tokenSaleStartTime;

    uint48 public tokenSaleEndTime;    

    bool public isPauseSaleWithEther;

    bool public isPauseSaleWithToken;    

    bool public isPauseSaleWithDistributor;                
    // for check limit token per user can receive
    bool public isCheckLimitPerUser;

    // token buy address list
    address[] public tokenBuyAddresses;
    // keep track balance token buy raisd in separate method
    mapping(address => uint256) public tokenBuyRaised;
    // keep token buy data
    mapping(address => TokenBuy) public tokenBuys;
    // keep user tokensale token receive balance 
    mapping(address => uint256) public userTokenReceiveBalance;    
    // user native buy balance
    mapping(address => uint256) public userNativeBuyBalance;
    // user seperate token buy balance
    mapping(address => mapping(address => uint256)) public userTokenBuyBalance;
    
    mapping(address => bool) public whitelistUsers;
    // set token exchange rate for token
    mapping(address => uint256) public tokenRateTokenBuys;    
    // keep token receive per method
    mapping(saleMethod => uint256) public totalTokenReceivePerMethod;    

    // setup role
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant FUND_OWNER_ROLE = keccak256("FUND_OWNER_ROLE");
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    // event
    event BuyToken(address indexed buyer, uint256 ethPaid, uint256 tokenReceived, uint256 timestamp);    
    event BuyTokenWithToken(address indexed buyer, uint256 tokenPaid, uint256 tokenReceived, address tokenBuyAddress, uint256 timestamp);
    event BuyTokenWithDistributor(address indexed receiver, uint256 tokenReceived, string indexed referenceTx); 
    event ExtractEther(address indexed receiver, uint256 ethReceived);    
    event ExtractToken(address indexed receiver, uint256 tokenBuyReceived);    
    event ClaimLockToken(address indexed receiver, uint256 claimableToken, uint256 chunkClaimed);
    event AddClaimLockToken(address indexed receiver, uint256 lockTokenAmount);
    

    modifier whenTokenSaleCompleted {
        require(block.timestamp > tokenSaleEndTime || tokenRaised >= FUNDING_GOAL, "TOKENSALE: NOT_COMPLETE_YET");
        _;
    }

    modifier whenSaleWithEtherNotPause {
        require(!isPauseSaleWithEther, "TOKENSALE: ETHER_PAUSE");
        _;
    }

    modifier whenSaleWithTokenNotPause {
        require(!isPauseSaleWithToken, "TOKENSALE: TOKEN_PAUSE");
        _;
    }

     modifier whenSaleWithDistributorNotPause {
        require(!isPauseSaleWithDistributor, "TOKENSALE: DISTRIBUTOR_PAUSE");
        _;
    }

    /// @dev initial function for contract after deploy
    /// @param _tokenSaleStartTime use for set sale start time
    /// @param _tokenSaleEndTime use for set sale end time
    /// @param _token address of token and will set as token sale instance
    /// @param _tokenLocker address of token locker for lock token
    /// @param _fundingGoal goal of this raise fund in term of token amount
    /// @param _distributor address of EOA use for another channel of sale    
    /// @param _keepRateDecimals decimals for keep in calculate exchange rate
    /// @param _etherBuy set rate for native buy    
    function initialize(
        uint48 _tokenSaleStartTime,
        uint48 _tokenSaleEndTime,
        IERC20MetadataUpgradeable _token,
        ITokenLocker _tokenLocker,
        uint256 _fundingGoal,        
        address _distributor,         
        uint256 _keepRateDecimals,
        EtherBuy memory _etherBuy,
        TokenBuy[] memory _tokenBuys
    ) public initializer {

        require (
            _tokenSaleStartTime != 0 &&
            
            _tokenSaleEndTime != 0 &&

            _tokenSaleStartTime < _tokenSaleEndTime &&                        
            
            _fundingGoal != 0 &&

            _keepRateDecimals != 0

        , "TOKENSALE: INITIAL_INVALID_VALUE");   

        __AccessControl_init();
        __ReentrancyGuard_init();

        tokenSaleStartTime = _tokenSaleStartTime;
        
        tokenSaleEndTime = _tokenSaleEndTime;
        
        token = _token;

        tokenLocker = _tokenLocker;

        FUNDING_GOAL = _fundingGoal;

        RATE_DECIMALS = 10 ** _keepRateDecimals; 

        // set ether buy data
        etherBuy = _etherBuy;

        // set allow token to buy
        /// double check rate before set for correct exchange rate
        for (uint256 i = 0; i < _tokenBuys.length; i++) {
            TokenBuy memory tokenBuy = _tokenBuys[i];
            // mapping token buy data
            tokenBuys[tokenBuy.tokenBuyAddress] = tokenBuy;
            // keep address in array for use when extract fund
            tokenBuyAddresses.push(tokenBuy.tokenBuyAddress);
        }

        // set up role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DISTRIBUTOR_ROLE, _distributor);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(FUND_OWNER_ROLE, msg.sender);
        _setupRole(CONFIG_ROLE, msg.sender);
    }

    /// @notice Add whitelist user to allow buy in whitelist period
    /// @param _whitelistUsersAddress array of allow address for use in whitelist period
    function addWhitelistUser(address[] calldata _whitelistUsersAddress) external onlyRole(CONFIG_ROLE) {
        for (uint256 i = 0; i < _whitelistUsersAddress.length; i++) {
            whitelistUsers[_whitelistUsersAddress[i]] = true;
        }
    }
    
    /// @notice Set period of this sale
    /// @dev Use this for extend or change sale period
    /// @param _tokenSaleStartTime start time of this sale
    /// @param _tokenSaleEndTime end time of this sale
    function setSalePeriod(uint48 _tokenSaleStartTime, uint48 _tokenSaleEndTime) external onlyRole(CONFIG_ROLE) {
        require(_tokenSaleStartTime != 0, "TOKENSALE: INPUT_ZERO_AMOUNT");
        require(_tokenSaleEndTime != 0, "TOKENSALE: INPUT_ZERO_AMOUNT");
        require(_tokenSaleStartTime < _tokenSaleEndTime, "TOKENSALE: CONFIG_INVALID_SALE_TIME");
        // set sale period
        tokenSaleStartTime = _tokenSaleStartTime;
        tokenSaleEndTime = _tokenSaleEndTime;
    }

    /// @notice Set period of whitelist
    /// @dev Start whitelist time will equal tokenSaleStartTime
    /// If not have whitelist period just set _whitelistEndTime equal tokenSaleStartTime
    /// @param _whitelistEndTime end time of this whitelist period
    function setWhitelistPeriod(uint48 _whitelistEndTime) external onlyRole(CONFIG_ROLE) {
        require(_whitelistEndTime >= tokenSaleStartTime && _whitelistEndTime <= tokenSaleEndTime, "TOKENSALE: CONFIG_INVALID_WHITELIST_ENDTIME");        
        // set whitelist period
        // if set whitelistEndTime == tokenSaleStartTime mean no whitelist
        whitelistEndTime = _whitelistEndTime;
    }
    
    /// @notice Check if this time in whitelist period or not
    /// @dev If not have whitelist period will return false at first condition    
    function isWhitelistPeriod() public view returns (bool) {
        return whitelistEndTime != tokenSaleStartTime && block.timestamp >= tokenSaleStartTime && block.timestamp <= whitelistEndTime;
    }

    /// @notice Check if this sale complete
    function isTokenSaleCompleted() external view returns (bool) {
        return block.timestamp > tokenSaleEndTime || tokenRaised >= FUNDING_GOAL;
    }

    /// @notice Set token limit per user
    /// @dev If not have token limit just set _isCheckLimitPerUser to false
    /// @param _isCheckLimitPerUser boolean for check this sale have token limit per user
    /// @param _limitTokenReceivePerUser amount of limit token can receive per user
    function setLimitTokenReceivePerUser(bool _isCheckLimitPerUser, uint256 _limitTokenReceivePerUser) external onlyRole(CONFIG_ROLE) {
        require(_limitTokenReceivePerUser != 0, "TOKENSALE: INPUT_ZERO_AMOUNT");
        limitTokenReceivePerUser = _limitTokenReceivePerUser;
        isCheckLimitPerUser = _isCheckLimitPerUser;
    }

    /// @notice Pause sale for channel ether, token and distributor
    /// @dev Set to ALL will pause all channel
    /// @param _saleChannel string channel for sale type
    /// @param _isPauseSale boolean for indicate this sale will pause or not
    function setPauseSale(bytes32 _saleChannel, bool _isPauseSale) external onlyRole(PAUSER_ROLE) {
        if (_saleChannel == keccak256("ETHER")) {
            isPauseSaleWithEther = _isPauseSale;
        } else if (_saleChannel == keccak256("TOKEN")) {
            isPauseSaleWithToken = _isPauseSale;
        } else if (_saleChannel == keccak256("DISTRIBUTOR")) {
            isPauseSaleWithDistributor = _isPauseSale;
        } else if (_saleChannel == keccak256("ALL")) {
            isPauseSaleWithEther = _isPauseSale;
            isPauseSaleWithToken = _isPauseSale;
            isPauseSaleWithDistributor = _isPauseSale;
        }
    }

    /// @notice Sale with native coin, e.g. ETH on ETHEREUM or BNB on BSC
    /// @dev This use for buy token sale with coin, e.g. ETH on ETHEREUM or BNB on BSC and fallback and receive will trigger this buy
    function buy() external payable nonReentrant whenSaleWithEtherNotPause {
        
        require(block.timestamp >= tokenSaleStartTime && block.timestamp <= tokenSaleEndTime, "TOKENSALE: END_TIME");                   
        
        require(tokenRaised < FUNDING_GOAL, "TOKENSALE: CAP_REACH");

        // check and allow whitelist user to buy first
        // after whitelist period will allow any user to buy
        if (isWhitelistPeriod()) {
            require(whitelistUsers[msg.sender], "TOKENSALE: ALLOW_ONLY_WHITELIST_ADDRESS");    
        }        

        
        require(msg.value >= etherBuy.min, "TOKENSALE: AMOUNT_LEES_THAN_MIN");
        require(msg.value <= etherBuy.max, "TOKENSALE: AMOUNT_MORE_THAN_MAX");

        uint256 tokensToReceived;
        
        uint256 etherUsed = msg.value;
        
        address payable sender = payable(msg.sender);
        
        uint256 etherExceed;
        
        uint256 etherUnit = 1 ether;

        uint256 tokenReceivedUnit = 10 ** token.decimals();        

        // calculate receive token and have convert unit receive token
        // which support token with decimals is not 18
        tokensToReceived = etherUsed * tokenReceivedUnit / etherUnit * etherBuy.rate / RATE_DECIMALS;
        
        // Check if we have reached and exceeded the funding goal to refund the exceeding tokens and ether
        if (tokenRaised + tokensToReceived > FUNDING_GOAL) {
            
            uint256 tokensToReceivedExceed = tokenRaised + tokensToReceived - FUNDING_GOAL;
            // formular
            // convert exceed token back to ether exceed
            etherExceed = tokensToReceivedExceed * etherUnit / tokenReceivedUnit * RATE_DECIMALS / etherBuy.rate;
            // reduce etherExceed exceed from etherUsed receive
            etherUsed -= etherExceed;
            // reduce token exceed from total receive
            tokensToReceived -= tokensToReceivedExceed;
            // send exceed ether back to user
            sender.transfer(etherExceed);
        }

        // check limit per user
        if (isCheckLimitPerUser) {
            require(userTokenReceiveBalance[sender] + tokensToReceived <= limitTokenReceivePerUser, "TOKENSALE: EXCEED_LIMIT");
        }
            
        tokenRaised += tokensToReceived;
                
        etherRaised += etherUsed;

        // count each user for native buy balance
        userNativeBuyBalance[sender] += etherUsed;

        // count each user tokensale token receive balance
        userTokenReceiveBalance[sender] += tokensToReceived;

        // count total token receive per method
        totalTokenReceivePerMethod[saleMethod.ETHER] += tokensToReceived;

        // lock token user
        tokenLocker.lock(sender, tokensToReceived);

        emit BuyToken(sender, etherUsed, tokensToReceived, block.timestamp);
    }
    
    /// @notice Sale with token, e.g. USDT, BUSD and wBTC
    /// @dev This use for buy token sale with token, e.g. USDT, BUSD and wBTC
    /// can support decimals token with is not default like 6 in USDC 
    /// and exchage rate for each token max is 18 decimal    
    /// @param _amount amount for token that want to buy in this token sale
    /// @param _tokenBuyAddress address of token and allow only whitelist token address
    function buyWithToken(uint256 _amount, address _tokenBuyAddress) external nonReentrant whenSaleWithTokenNotPause {
        
        require(block.timestamp >= tokenSaleStartTime && block.timestamp <= tokenSaleEndTime, "TOKENSALE: END_TIME");   
        
        require(tokenRaised < FUNDING_GOAL, "TOKENSALE: CAP_REACH");
        
        TokenBuy memory tokenBuyData = tokenBuys[_tokenBuyAddress];
        // check whitelist token buy
        require(tokenBuyData.tokenBuyAddress != address(0), "TOKENSALE: ALLOW_ONLY_WHITELIST_TOKEN");

        // check and allow whitelist user to buy first
        // after whitelist period will allow any user to buy
        if (isWhitelistPeriod()) {
            require(whitelistUsers[msg.sender], "TOKENSALE: ALLOW_ONLY_WHITELIST_ADDRESS");    
        }

        // check min max
        require(_amount >= tokenBuyData.min, "TOKENSALE: AMOUNT_LEES_THAN_MIN");
        require(_amount <= tokenBuyData.max, "TOKENSALE: AMOUNT_MORE_THAN_MAX");
    
        // set token buy instance
        IERC20MetadataUpgradeable tokenBuy = IERC20MetadataUpgradeable(_tokenBuyAddress);
        
        uint256 tokensToReceived;
        
        uint256 tokenBuyUsed = _amount;
        
        address sender = msg.sender;
        
        uint256 tokenBuyExceed;
        
        uint256 tokenBuyUnit = 10 ** tokenBuy.decimals();
        
        uint256 tokenReceivedUnit = 10 ** token.decimals();        

        uint256 tokenRateTokenBuy = tokenBuyData.rate;
 
        // trasfer token buy to tokensale
        tokenBuy.safeTransferFrom(sender, address(this), tokenBuyUsed);
        
        // calculate receive token and have convert unit receive token
        // which support sale token with decimals is not 18
        // and decimals for token buy is not 18

        tokensToReceived = tokenBuyUsed * tokenReceivedUnit / tokenBuyUnit * tokenRateTokenBuy / RATE_DECIMALS;
        
        // Check if we have reached and exceeded the funding goal to refund the exceeding tokens and ether
        if (tokenRaised + tokensToReceived > FUNDING_GOAL) {
            
            uint256 tokensToReceivedExceed = tokenRaised + tokensToReceived - FUNDING_GOAL;
            
            // formular
            // convert exceed token back to token buy exceed;
            tokenBuyExceed = tokensToReceivedExceed * tokenBuyUnit / tokenReceivedUnit * RATE_DECIMALS / tokenRateTokenBuy;
                                        
            tokenBuyUsed -= tokenBuyExceed;
            
            tokensToReceived -= tokensToReceivedExceed;
            // transfer exceed token buy to user
            tokenBuy.safeTransfer(sender, tokenBuyExceed);
        }

        // check limit per user
        if (isCheckLimitPerUser) {
            require(userTokenReceiveBalance[sender] + tokensToReceived <= limitTokenReceivePerUser, "TOKENSALE: EXCEED_LIMIT");
        }    

        tokenRaised += tokensToReceived;
            
        // count raised token buy raised
        tokenBuyRaised[_tokenBuyAddress] += tokenBuyUsed;

        // count each user for token buy balance
        userTokenBuyBalance[sender][_tokenBuyAddress] += tokenBuyUsed;

        // count each user tokensale token receive balance
        userTokenReceiveBalance[sender] += tokensToReceived;

        // count total token receive per method
        totalTokenReceivePerMethod[saleMethod.TOKEN] += tokensToReceived;                
        
        // lock token user
        tokenLocker.lock(sender, tokensToReceived);
        
        emit BuyTokenWithToken(sender, tokenBuyUsed, tokensToReceived, _tokenBuyAddress, block.timestamp);
    }

    /// @notice Sale with distributor, e.g. CCP
    /// @dev Must send reference for keep track and reconcile each transaction
    /// @param _receiver address of user who will receive token
    /// @param _amount amount of token of this sale that user will receive
    /// @param _reference reference string for keep track and reconcile each transaction
    function buyTokenWithDistributor(address _receiver, uint256 _amount, string memory _reference) external nonReentrant onlyRole(DISTRIBUTOR_ROLE) whenSaleWithDistributorNotPause {            
        
        require(_receiver != address(0), "TOKENSALE: INPUT_ZERO_ADDRESS");
        
        require(_amount != 0, "TOKENSALE: INPUT_ZERO_AMOUNT");

        require(tokenRaised < FUNDING_GOAL, "TOKENSALE: CAP_REACH");

        require(tokenRaised + _amount <= FUNDING_GOAL, "TOKENSALE: INSUFFICIENT_TOKEN");   
        
        require(block.timestamp >= tokenSaleStartTime && block.timestamp <= tokenSaleEndTime, "TOKENSALE: END_TIME");

        // check and allow whitelist user to buy first
        // after whitelist period will allow any user to buy
        if (isWhitelistPeriod()) {
            require(whitelistUsers[_receiver], "TOKENSALE: ALLOW_ONLY_WHITELIST_ADDRESS");    
        }
        
        // check limit per user
        if (isCheckLimitPerUser) {
            require(userTokenReceiveBalance[_receiver] + _amount <= limitTokenReceivePerUser, "TOKENSALE: EXCEED_LIMIT");
        }

        uint256 tokensToReceived = _amount;                                                                
                
        tokenRaised += tokensToReceived;

        // count total token receive per method
        totalTokenReceivePerMethod[saleMethod.DISTRIBUTOR] += tokensToReceived;

        // count each user tokensale token receive balance
        userTokenReceiveBalance[_receiver] += tokensToReceived;

        // lock token user
        tokenLocker.lock(_receiver, tokensToReceived);
        
        // emit actual token receive and lock token
        emit BuyTokenWithDistributor(_receiver, tokensToReceived, _reference);
    }
    
    /// @notice Extract fund only ether
    /// @dev Only FUND_OWNER_ROLE can extract this fund
    function extractEther() external nonReentrant onlyRole(FUND_OWNER_ROLE) whenTokenSaleCompleted {
        address payable fundOwner = payable(msg.sender);
        uint256 amount = address(this).balance;        
        // send ether to fund owner with amount more than zero
        if (amount != 0) {
            fundOwner.transfer(amount);
            emit ExtractEther(msg.sender, amount);
        }
    }
    
    /// @notice Extract fund only token, e.g. USDT, BUSD, wBTC
    /// @dev Only FUND_OWNER_ROLE can extract this fund
    function extractTokenBuy() external nonReentrant onlyRole(FUND_OWNER_ROLE) whenTokenSaleCompleted {
        for (uint256 i = 0; i < tokenBuyAddresses.length; i++) {
            // set token buy
            IERC20MetadataUpgradeable tokenBuy = IERC20MetadataUpgradeable(tokenBuyAddresses[i]);
            uint256 amount = tokenBuy.balanceOf(address(this));
            // send token buy to fund owner with amount more than zero
            if (amount != 0) {
                tokenBuy.safeTransfer(msg.sender, amount);
                emit ExtractToken(msg.sender, amount);
            }           
        }        
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenLocker {
    struct UserInfo {
        uint256 totalReceiveToken;
        uint256 totalClaimedToken;
        uint256 initialChunkToken;
        uint256 lastClaimChunk;
    }

    event Lock(address indexed receiver, uint256 amount);
    event Deposit(uint256 amount, uint256 totalToken);
    event Withdraw(uint256 amount, uint256 totalToken, address to);
    event Claim(address indexed receiver, uint256 totenToClaim);
    event ExtractToken(address indexed token, uint256 amount, address to);

    function lock(address _receiver, uint256 _totalReceive) external;

    function pendingToken(address _receiver)
        external
        view
        returns (uint256 pending);

    function usersLength() external view returns (uint256);

    function claim(address _receiver) external;

    function claimMultiple(address[] calldata _receivers) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount, address to) external;

    function extractToken(
        IERC20 _token,
        uint256 amount,
        address to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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