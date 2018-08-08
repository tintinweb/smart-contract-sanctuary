pragma solidity ^0.4.18;

/************************************************** */
/* WhenHub Token Smart Contract                     */
/* Author: Nik Kalyani  <span class="__cf_email__" data-cfemail="b2dcdbd9f2c5dad7dcdac7d09cd1dddf">[email&#160;protected]</span>             */
/* Copyright (c) 2018 CalendarTree, Inc.            */
/* https://interface.whenhub.com                    */
/************************************************** */
contract WHENToken {
    using SafeMath for uint256;

    mapping(address => uint256) balances;                               // Token balance for each address
    mapping (address => mapping (address => uint256)) internal allowed; // Approval granted to transfer tokens by one address to another address

    /* ERC20 fields */
    string public name;
    string public symbol;
    uint public decimals = 18;
    string public sign = "￦";
    string public logoPng = "https://github.com/WhenHub/WHEN/raw/master/assets/when-token-icon.png";


    /* Each registered user on WhenHub Interface Network has a record in this contract */
    struct User {
        bool isRegistered;                                              // Flag to indicate user was registered 
        uint256 seedJiffys;                                             // Tracks free tokens granted to user       
        uint256 interfaceEscrowJiffys;                                  // Tracks escrow tokens used in Interfaces      
        address referrer;                                               // Tracks who referred this user
    }
 
    // IcoBurnAuthorized is used to determine when remaining ICO tokens should be burned
    struct IcoBurnAuthorized {
        bool contractOwner;                                              // Flag to indicate ContractOwner has authorized
        bool platformManager;                                            // Flag to indicate PlatformManager has authorized
        bool icoOwner;                                                   // Flag to indicate SupportManager has authorized
    }

    // PurchaseCredit is used to track purchases made by USD when user isn&#39;t already registered
    struct PurchaseCredit {
        uint256 jiffys;                                                  // Number of jiffys purchased
        uint256 purchaseTimestamp;                                       // Date/time of original purchase
    }

    mapping(address => PurchaseCredit) purchaseCredits;                  // Temporary store for USD-purchased tokens

    uint private constant ONE_WEEK = 604800;
    uint private constant SECONDS_IN_MONTH = 2629743;
    uint256 private constant ICO_START_TIMESTAMP = 1521471600; // 3/19/2018 08:00:00 PDT

    uint private constant BASIS_POINTS_TO_PERCENTAGE = 10000;                         // All fees are expressed in basis points. This makes conversion easier

    /* Token allocations per published WhenHub token economics */
    uint private constant ICO_TOKENS = 350000000;                              // Tokens available for public purchase
    uint private constant PLATFORM_TOKENS = 227500000;                         // Tokens available for network seeding
    uint private constant COMPANY_TOKENS = 262500000;                          // Tokens available to WhenHub for employees and future expansion
    uint private constant PARTNER_TOKENS = 17500000;                           // Tokens available for WhenHub partner inventives
    uint private constant FOUNDATION_TOKENS = 17500000;                        // Tokens available for WhenHub Foundationn charity

    /* Network seeding tokens */
    uint constant INCENTIVE_TOKENS = 150000000;                         // Total pool of seed tokens for incentives
    uint constant REFERRAL_TOKENS = 77500000;                           // Total pool of seed tokens for referral
    uint256 private userSignupJiffys = 0;                                // Number of Jiffys per user who signs up
    uint256 private referralSignupJiffys = 0;                            // Number of Jiffys per user(x2) referrer + referree
   
    uint256 private jiffysMultiplier;                                   // 10 ** decimals
    uint256 private incentiveJiffysBalance;                             // Available balance of Jiffys for incentives
    uint256 private referralJiffysBalance;                              // Available balance of Jiffys for referrals

    /* ICO variables */
    uint256 private bonus20EndTimestamp = 0;                             // End of 20% ICO token bonus timestamp
    uint256 private bonus10EndTimestamp = 0;                             // End of 10% ICO token bonus timestamp
    uint256 private bonus5EndTimestamp = 0;                              // End of 5% ICO token bonus timestamp
    uint private constant BUYER_REFERRER_BOUNTY = 3;                     // Referral bounty percentage

    IcoBurnAuthorized icoBurnAuthorized = IcoBurnAuthorized(false, false, false);

    /* Interface transaction settings */
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
                                                                        // Change using setOperatingStatus()

    uint256 public winNetworkFeeBasisPoints = 0;                       // Per transaction fee deducted from payment to Expert
                                                                        // Change using setWinNetworkFeeBasisPoints()

    uint256 public weiExchangeRate = 500000000000000;                  // Exchange rate for 1 WHEN Token in Wei ($0.25/￦)
                                                                        // Change using setWeiExchangeRate()

    uint256 public centsExchangeRate = 25;                             // Exchange rate for 1 WHEN Token in cents
                                                                        // Change using setCentsExchangeRate()

    /* State variables */
    address private contractOwner;                                      // Account used to deploy contract
    address private platformManager;                                    // Account used by API for Interface app
    address private icoOwner;                                           // Account from which ICO funds are disbursed
    address private supportManager;                                     // Account used by support team to reimburse users
    address private icoWallet;                                          // Account to which ICO ETH is sent

    mapping(address => User) private users;                             // All registered users   
    mapping(address => uint256) private vestingEscrows;                 // Unvested tokens held in escrow

    mapping(address => uint256) private authorizedContracts;            // Contracts authorized to call this one           

    address[] private registeredUserLookup;                             // Lookup table of registered users     

    /* ERC-20 Contract Events */
    event Approval          // Fired when an account authorizes another account to spend tokens on its behalf
                            (
                                address indexed owner, 
                                address indexed spender, 
                                uint256 value
                            );

    event Transfer          // Fired when tokens are transferred from one account to another
                            (
                                address indexed from, 
                                address indexed to, 
                                uint256 value
                            );


    /* Interface app-specific Events */
    event UserRegister      // Fired when a new user account (wallet) is registered
                            (
                                address indexed user, 
                                uint256 value,
                                uint256 seedJiffys
                            );                                 

    event UserRefer         // Fired when tokens are granted to a user for referring a new user
                            (
                                address indexed user, 
                                address indexed referrer, 
                                uint256 value
                            );                             

    event UserLink          // Fired when a previously existing user is linked to an account in the Interface DB
                            (
                                address indexed user
                            );


    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational);
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner);
        _;
    }

    /**
    * @dev Modifier that requires the "PlatformManager" account to be the function caller
    */
    modifier requirePlatformManager()
    {
        require(isPlatformManager(msg.sender));
        _;
    }


    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    * @param tokenName ERC-20 token name
    * @param tokenSymbol ERC-20 token symbol
    * @param platformAccount Account for making calls from Interface API (i.e. PlatformManager)
    * @param icoAccount Account that holds ICO tokens (i.e. IcoOwner)
    * @param supportAccount Account with limited access to manage Interface user support (i.e. SupportManager)
    *
    */
    function WHENToken
                            ( 
                                string tokenName, 
                                string tokenSymbol, 
                                address platformAccount, 
                                address icoAccount,
                                address supportAccount
                            ) 
                            public 
    {

        name = tokenName;
        symbol = tokenSymbol;

        jiffysMultiplier = 10 ** uint256(decimals);                             // Multiplier used throughout contract
        incentiveJiffysBalance = INCENTIVE_TOKENS.mul(jiffysMultiplier);        // Network seeding tokens
        referralJiffysBalance = REFERRAL_TOKENS.mul(jiffysMultiplier);          // User referral tokens


        contractOwner = msg.sender;                                     // Owner of the contract
        platformManager = platformAccount;                              // API account for Interface
        icoOwner = icoAccount;                                          // Account with ICO tokens for settling Interface transactions
        icoWallet = icoOwner;                                           // Account to which ICO ETH is sent
        supportManager = supportAccount;                                // Support account with limited permissions

                
        // Create user records for accounts
        users[contractOwner] = User(true, 0, 0, address(0));       
        registeredUserLookup.push(contractOwner);

        users[platformManager] = User(true, 0, 0, address(0));   
        registeredUserLookup.push(platformManager);

        users[icoOwner] = User(true, 0, 0, address(0));   
        registeredUserLookup.push(icoOwner);

        users[supportManager] = User(true, 0, 0, address(0));   
        registeredUserLookup.push(supportManager);

    }    

    /**
    * @dev Contract constructor
    *
    * Initialize is to be called immediately after the supporting contracts are deployed.
    *
    * @param dataContract Address of the deployed InterfaceData contract
    * @param appContract Address of the deployed InterfaceApp contract
    * @param vestingContract Address of the deployed TokenVesting contract
    *
    */
    function initialize
                            (
                                address dataContract,
                                address appContract,
                                address vestingContract
                            )
                            external
                            requireContractOwner
    {        
        require(bonus20EndTimestamp == 0);      // Ensures function cannot be called twice
        authorizeContract(dataContract);        // Authorizes InterfaceData contract to make calls to this contract
        authorizeContract(appContract);         // Authorizes InterfaceApp contract to make calls to this contract
        authorizeContract(vestingContract);     // Authorizes TokenVesting contract to make calls to this contract
        
        bonus20EndTimestamp = ICO_START_TIMESTAMP.add(ONE_WEEK);
        bonus10EndTimestamp = bonus20EndTimestamp.add(ONE_WEEK);
        bonus5EndTimestamp = bonus10EndTimestamp.add(ONE_WEEK);

        // ICO tokens are allocated without vesting to ICO account for distribution during sale
        balances[icoOwner] = ICO_TOKENS.mul(jiffysMultiplier);        

        // Platform tokens (a.k.a. network seeding tokens) are allocated without vesting
        balances[platformManager] = balances[platformManager].add(PLATFORM_TOKENS.mul(jiffysMultiplier));        

        // Allocate all other tokens to contract owner without vesting
        // These will be disbursed in initialize()
        balances[contractOwner] = balances[contractOwner].add((COMPANY_TOKENS + PARTNER_TOKENS + FOUNDATION_TOKENS).mul(jiffysMultiplier));

        userSignupJiffys = jiffysMultiplier.mul(500);       // Initial signup incentive
        referralSignupJiffys = jiffysMultiplier.mul(100);   // Initial referral incentive
       
    }

    /**
    * @dev Token allocations for various accounts
    *
    * Called from TokenVesting to grant tokens to each account
    *
    */
    function getTokenAllocations()
                                external
                                view
                                returns(uint256, uint256, uint256)
    {
        return (COMPANY_TOKENS.mul(jiffysMultiplier), PARTNER_TOKENS.mul(jiffysMultiplier), FOUNDATION_TOKENS.mul(jiffysMultiplier));
    }

    /********************************************************************************************/
    /*                                       ERC20 TOKEN                                        */
    /********************************************************************************************/

    /**
    * @dev Total supply of tokens
    */
    function totalSupply() 
                            external 
                            view 
                            returns (uint) 
    {
        uint256 total = ICO_TOKENS.add(PLATFORM_TOKENS).add(COMPANY_TOKENS).add(PARTNER_TOKENS).add(FOUNDATION_TOKENS);
        return total.mul(jiffysMultiplier);
    }

    /**
    * @dev Gets the balance of the calling address.
    *
    * @return An uint256 representing the amount owned by the calling address
    */
    function balance()
                            public 
                            view 
                            returns (uint256) 
    {
        return balanceOf(msg.sender);
    }

    /**
    * @dev Gets the balance of the specified address.
    *
    * @param owner The address to query the balance of
    * @return An uint256 representing the amount owned by the passed address
    */
    function balanceOf
                            (
                                address owner
                            ) 
                            public 
                            view 
                            returns (uint256) 
    {
        return balances[owner];
    }

    /**
    * @dev Transfers token for a specified address
    *
    * Constraints are added to ensure that tokens granted for network
    * seeding and tokens in escrow are not transferable
    *
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @return A bool indicating if the transfer was successful.
    */
    function transfer
                            (
                                address to, 
                                uint256 value
                            ) 
                            public 
                            requireIsOperational 
                            returns (bool) 
    {
        require(to != address(0));
        require(to != msg.sender);
        require(value <= transferableBalanceOf(msg.sender));                                         

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Transfers tokens from one address to another
    *
    * Constraints are added to ensure that tokens granted for network
    * seeding and tokens in escrow are not transferable
    *
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    * @return A bool indicating if the transfer was successful.
    */
    function transferFrom
                            (
                                address from, 
                                address to, 
                                uint256 value
                            ) 
                            public 
                            requireIsOperational 
                            returns (bool) 
    {
        require(from != address(0));
        require(value <= allowed[from][msg.sender]);
        require(value <= transferableBalanceOf(from));                                         
        require(to != address(0));
        require(from != to);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

    /**
    * @dev Checks the amount of tokens that an owner allowed to a spender.
    *
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance
                            (
                                address owner, 
                                address spender
                            ) 
                            public 
                            view 
                            returns (uint256) 
    {
        return allowed[owner][spender];
    }

    /**
    * @dev Approves the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    * @return A bool indicating success (always returns true)
    */
    function approve
                            (
                                address spender, 
                                uint256 value
                            ) 
                            public 
                            requireIsOperational 
                            returns (bool) 
    {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address less greater of escrow tokens and free signup tokens.
    *
    * @param account The address to query the the balance of.
    * @return An uint256 representing the transferable amount owned by the passed address.
    */
    function transferableBalanceOf
                            (
                                address account
                            ) 
                            public 
                            view 
                            returns (uint256) 
    {
        require(account != address(0));

        if (users[account].isRegistered) {
            uint256 restrictedJiffys = users[account].interfaceEscrowJiffys >= users[account].seedJiffys ? users[account].interfaceEscrowJiffys : users[account].seedJiffys;
            return balances[account].sub(restrictedJiffys);
        }
        return balances[account];
    }

   /**
    * @dev Gets the balance of the specified address less escrow tokens
    *
    * Since seed tokens can be used to pay for Interface transactions
    * this balance indicates what the user can afford to spend for such
    * "internal" transactions ignoring distinction between paid and signup tokens
    *
    * @param account The address to query the balance of.
    * @return An uint256 representing the spendable amount owned by the passed address.
    */ 
    function spendableBalanceOf
                            (
                                address account
                            ) 
                            public 
                            view 
                            returns(uint256) 
    {

        require(account != address(0));

        if (users[account].isRegistered) {
            return balances[account].sub(users[account].interfaceEscrowJiffys);
        }
        return balances[account];
    }

    /********************************************************************************************/
    /*                                  WHENHUB INTERFACE                                       */
    /********************************************************************************************/


   /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }

   /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this
    * one will fail
    * @return A bool that is the new operational mode
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

   /**
    * @dev Authorizes ICO end and burn of remaining tokens
    *
    * ContractOwner, PlatformManager and IcoOwner must each call this function
    * in any order. The third entity calling the function will cause the
    * icoOwner account balance to be reset to 0.
    */ 
    function authorizeIcoBurn() 
                            external
    {
        require(balances[icoOwner] > 0);
        require((msg.sender == contractOwner) || (msg.sender == platformManager) || (msg.sender == icoOwner));

        if (msg.sender == contractOwner) {
            icoBurnAuthorized.contractOwner = true;
        } else if (msg.sender == platformManager) {
            icoBurnAuthorized.platformManager = true;
        } else if (msg.sender == icoOwner) {
            icoBurnAuthorized.icoOwner = true;
        }

        if (icoBurnAuthorized.contractOwner && icoBurnAuthorized.platformManager && icoBurnAuthorized.icoOwner) {
            balances[icoOwner] = 0;
        }
    }

   /**
    * @dev Sets fee used in Interface transactions
    *
    * A network fee is charged for each transaction represented
    * as a percentage of the total fee payable to Experts. This fee
    * is deducted from the amount paid by Callers to Experts.
    * @param basisPoints The fee percentage expressed as basis points
    */    
    function setWinNetworkFee
                            (
                                uint256 basisPoints
                            ) 
                            external 
                            requireIsOperational 
                            requireContractOwner
    {
        require(basisPoints >= 0);

        winNetworkFeeBasisPoints = basisPoints;
    }

    /**
    * @dev Sets signup tokens allocated for each user (based on availability)
    *
    * @param tokens The number of tokens each user gets
    */    
    function setUserSignupTokens
                            (
                                uint256 tokens
                            ) 
                            external 
                            requireIsOperational 
                            requireContractOwner
    {
        require(tokens <= 10000);

        userSignupJiffys = jiffysMultiplier.mul(tokens);
    }

    /**
    * @dev Sets signup tokens allocated for each user (based on availability)
    *
    * @param tokens The number of tokens each referrer and referree get
    */    
    function setReferralSignupTokens
                            (
                                uint256 tokens
                            ) 
                            external 
                            requireIsOperational 
                            requireContractOwner
    {
        require(tokens <= 10000);

        referralSignupJiffys = jiffysMultiplier.mul(tokens);
    }

    /**
    * @dev Sets wallet to which ICO ETH funds are sent
    *
    * @param account The address to which ETH funds are sent
    */    
    function setIcoWallet
                            (
                                address account
                            ) 
                            external 
                            requireIsOperational 
                            requireContractOwner
    {
        require(account != address(0));

        icoWallet = account;
    }

    /**
    * @dev Authorizes a smart contract to call this contract
    *
    * @param account Address of the calling smart contract
    */
    function authorizeContract
                            (
                                address account
                            ) 
                            public 
                            requireIsOperational 
                            requireContractOwner
    {
        require(account != address(0));

        authorizedContracts[account] = 1;
    }

    /**
    * @dev Deauthorizes a previously authorized smart contract from calling this contract
    *
    * @param account Address of the calling smart contract
    */
    function deauthorizeContract
                            (
                                address account
                            ) 
                            external 
                            requireIsOperational
                            requireContractOwner 
    {
        require(account != address(0));

        delete authorizedContracts[account];
    }

    /**
    * @dev Checks if a contract is authorized to call this contract
    *
    * @param account Address of the calling smart contract
    */
    function isContractAuthorized
                            (
                                address account
                            ) 
                            public 
                            view
                            returns(bool) 
    {
        return authorizedContracts[account] == 1;
    }

    /**
    * @dev Sets the Wei to WHEN exchange rate 
    *
    * @param rate Number of Wei for one WHEN token
    */
    function setWeiExchangeRate
                            (
                                uint256 rate
                            ) 
                            external 
                            requireIsOperational
                            requireContractOwner
    {
        require(rate >= 0); // Cannot set to less than 0.0001 ETH/￦

        weiExchangeRate = rate;
    }

    /**
    * @dev Sets the U.S. cents to WHEN exchange rate 
    *
    * @param rate Number of cents for one WHEN token
    */
    function setCentsExchangeRate
                            (
                                uint256 rate
                            ) 
                            external 
                            requireIsOperational
                            requireContractOwner
    {
        require(rate >= 1);

        centsExchangeRate = rate;
    }

    /**
    * @dev Sets the account that will be used for Platform Manager functions 
    *
    * @param account Account to replace existing Platform Manager
    */
    function setPlatformManager
                            (
                                address account
                            ) 
                            external 
                            requireIsOperational
                            requireContractOwner
    {
        require(account != address(0));
        require(account != platformManager);

        balances[account] = balances[account].add(balances[platformManager]);
        balances[platformManager] = 0;

        if (!users[account].isRegistered) {
            users[account] = User(true, 0, 0, address(0)); 
            registeredUserLookup.push(account);
        }

        platformManager = account; 
    }

    /**
    * @dev Checks if an account is the PlatformManager 
    *
    * @param account Account to check
    */
    function isPlatformManager
                            (
                                address account
                            ) 
                            public
                            view 
                            returns(bool) 
    {
        return account == platformManager;
    }

    /**
    * @dev Checks if an account is the PlatformManager or SupportManager
    *
    * @param account Account to check
    */
    function isPlatformOrSupportManager
                            (
                                address account
                            ) 
                            public
                            view 
                            returns(bool) 
    {
        return (account == platformManager) || (account == supportManager);
    }

    /**
    * @dev Gets address of SupportManager
    *
    */
    function getSupportManager()
                            public
                            view 
                            returns(address) 
    {
        return supportManager;
    }


    /**
    * @dev Checks if referral tokens are available
    *
    * referralSignupTokens is doubled because both referrer
    * and recipient get referral tokens
    *
    * @return A bool indicating if referral tokens are available
    */    
    function isReferralSupported() 
                            public 
                            view 
                            returns(bool) 
    {
        uint256 requiredJiffys = referralSignupJiffys.mul(2);
        return (referralJiffysBalance >= requiredJiffys) && (balances[platformManager] >= requiredJiffys);
    }

    /**
    * @dev Checks if user is a registered user
    *
    * @param account The address which owns the funds.
    * @return A bool indicating if user is a registered user.
    */
    function isUserRegistered
                            (
                                address account
                            ) 
                            public 
                            view 
                            returns(bool) 
    {
        return (account != address(0)) && users[account].isRegistered;
    }

    /**
    * @dev Checks pre-reqs and handles user registration
    *
    * @param account The address which is to be registered
    * @param creditAccount The address which contains token credits from CC purchase
    * @param referrer The address referred the account
    */
    function processRegisterUser
                            (
                                address account, 
                                address creditAccount,
                                address referrer
                            ) 
                            private
    {
        require(account != address(0));                                             // No invalid account
        require(!users[account].isRegistered);                                      // No double registration
        require(referrer == address(0) ? true : users[referrer].isRegistered);      // Referrer, if present, must be a registered user
        require(referrer != account);                                               // User can&#39;t refer her/himself

        // Initialize user with restricted jiffys
        users[account] = User(true, 0, 0, referrer);
        registeredUserLookup.push(account);


        if (purchaseCredits[creditAccount].jiffys > 0) {
            processPurchase(creditAccount, account, purchaseCredits[creditAccount].jiffys, purchaseCredits[creditAccount].purchaseTimestamp);
            purchaseCredits[creditAccount].jiffys = 0;
            delete purchaseCredits[creditAccount];
        }

    }

    /**
    * @dev Registers a user wallet with a referrer and deposits any applicable signup tokens
    *
    * @param account The wallet address
    * @param creditAccount The address containing any tokens purchased with USD
    * @param referrer The referring user address
    * @return A uint256 with the user&#39;s token balance
    */ 
    function registerUser
                            (
                                address account, 
                                address creditAccount,
                                address referrer
                            ) 
                            public 
                            requireIsOperational 
                            requirePlatformManager 
                            returns(uint256) 
    {
                                    
        processRegisterUser(account, creditAccount, referrer);
        UserRegister(account, balanceOf(account), 0);          // Fire event

        return balanceOf(account);
    }

    /**
    * @dev Registers a user wallet with a referrer and deposits any applicable bonus tokens
    *
    * @param account The wallet address
    * @param creditAccount The address containing any tokens purchased with USD
    * @param referrer The referring user address
    * @return A uint256 with the user&#39;s token balance
    */
    function registerUserBonus
                            (
                                address account, 
                                address creditAccount,
                                address referrer
                            ) 
                            external 
                            requireIsOperational 
                            requirePlatformManager 
                            returns(uint256) 
    {
        
        processRegisterUser(account, creditAccount, referrer);

        
        // Allocate if there are any remaining signup tokens
        uint256 jiffys = 0;
        if ((incentiveJiffysBalance >= userSignupJiffys) && (balances[platformManager] >= userSignupJiffys)) {
            incentiveJiffysBalance = incentiveJiffysBalance.sub(userSignupJiffys);
            users[account].seedJiffys = users[account].seedJiffys.add(userSignupJiffys);
            transfer(account, userSignupJiffys);
            jiffys = userSignupJiffys;
        }

        UserRegister(account, balanceOf(account), jiffys);          // Fire event

       // Allocate referral tokens for both user and referrer if available       
       if ((referrer != address(0)) && isReferralSupported()) {
            referralJiffysBalance = referralJiffysBalance.sub(referralSignupJiffys.mul(2));

            // Referal tokens are restricted so it is necessary to update user&#39;s account
            transfer(referrer, referralSignupJiffys);
            users[referrer].seedJiffys = users[referrer].seedJiffys.add(referralSignupJiffys);

            transfer(account, referralSignupJiffys);
            users[account].seedJiffys = users[account].seedJiffys.add(referralSignupJiffys);

            UserRefer(account, referrer, referralSignupJiffys);     // Fire event
        }

        return balanceOf(account);
    }

    /**
    * @dev Adds Jiffys to escrow for a user
    *
    * Escrows track the number of Jiffys that the user may owe another user.
    * This function is called by the InterfaceData contract when a caller
    * subscribes to a call.
    *
    * @param account The wallet address
    * @param jiffys The number of Jiffys to put into escrow
    */ 
    function depositEscrow
                            (
                                address account, 
                                uint256 jiffys
                            ) 
                            external 
                            requireIsOperational 
    {
        if (jiffys > 0) {
            require(isContractAuthorized(msg.sender) || isPlatformManager(msg.sender));   
            require(isUserRegistered(account));                                                     
            require(spendableBalanceOf(account) >= jiffys);

            users[account].interfaceEscrowJiffys = users[account].interfaceEscrowJiffys.add(jiffys);
        }
    }

    /**
    * @dev Refunds Jiffys from escrow for a user
    *
    * This function is called by the InterfaceData contract when a caller
    * unsubscribes from a call.
    *
    * @param account The wallet address
    * @param jiffys The number of Jiffys to remove from escrow
    */ 
    function refundEscrow
                            (
                                address account, 
                                uint256 jiffys
                            ) 
                            external 
                            requireIsOperational 
    {
        if (jiffys > 0) {
            require(isContractAuthorized(msg.sender) || isPlatformManager(msg.sender));   
            require(isUserRegistered(account));                                                     
            require(users[account].interfaceEscrowJiffys >= jiffys);

            users[account].interfaceEscrowJiffys = users[account].interfaceEscrowJiffys.sub(jiffys);
        }
    }

    /**
    * @dev Handles payment for an Interface transaction
    *
    * This function is called by the InterfaceData contract when the front-end
    * application makes a settle() call indicating that the transaction is
    * complete and it&#39;s time to pay the Expert. To prevent unauthorized use
    * the function is only callable by a previously authorized contract and
    * is limited to paying out funds previously escrowed.
    *
    * @param payer The account paying (i.e. a caller)
    * @param payee The account being paid (i.e. the Expert)
    * @param referrer The account that referred payer to payee
    * @param referralFeeBasisPoints The referral fee payable to referrer
    * @param billableJiffys The number of Jiffys for payment
    * @param escrowJiffys The number of Jiffys held in escrow for Interface being paid
    */ 
    function pay
                            (
                                address payer, 
                                address payee, 
                                address referrer, 
                                uint256 referralFeeBasisPoints, 
                                uint256 billableJiffys,
                                uint256 escrowJiffys
                            ) 
                            external 
                            requireIsOperational 
                            returns(uint256, uint256)
    {
        require(isContractAuthorized(msg.sender));   
        require(billableJiffys >= 0);
        require(users[payer].interfaceEscrowJiffys >= billableJiffys);  // Only payment of Interface escrowed funds is allowed
        require(users[payee].isRegistered);

        // This function may be called if the Expert&#39;s surety is
        // being forfeited. In that case, the payment is made to the 
        // Support and then funds will be distributed as appropriate
        // to parties following a grievance process. Since the rules 
        // for forfeiture can get very complex, they are best handled 
        // off-contract. payee == supportManager indicates a forfeiture.


        // First, release Payer escrow
        users[payer].interfaceEscrowJiffys = users[payer].interfaceEscrowJiffys.sub(escrowJiffys);
        uint256 referralFeeJiffys = 0;
        uint256 winNetworkFeeJiffys = 0;

        if (billableJiffys > 0) {

            // Second, pay the payee
            processPayment(payer, payee, billableJiffys);

            // Payee is SupportManager if Expert surety is being forfeited, so skip referral and network fees
            if (payee != supportManager) {

                // Third, Payee pays Referrer and referral fees due
                if ((referralFeeBasisPoints > 0) && (referrer != address(0)) && (users[referrer].isRegistered)) {
                    referralFeeJiffys = billableJiffys.mul(referralFeeBasisPoints).div(BASIS_POINTS_TO_PERCENTAGE); // Basis points to percentage conversion
                    processPayment(payee, referrer, referralFeeJiffys);
                }

                // Finally, Payee pays contract owner WIN network fee
                if (winNetworkFeeBasisPoints > 0) {
                    winNetworkFeeJiffys = billableJiffys.mul(winNetworkFeeBasisPoints).div(BASIS_POINTS_TO_PERCENTAGE); // Basis points to percentage conversion
                    processPayment(payee, contractOwner, winNetworkFeeJiffys);
                }                    
            }
        }

        return(referralFeeJiffys, winNetworkFeeJiffys);
    }
    
    /**
    * @dev Handles actual token transfer for payment
    *
    * @param payer The account paying
    * @param payee The account being paid
    * @param jiffys The number of Jiffys for payment
    */     
    function processPayment
                               (
                                   address payer,
                                   address payee,
                                   uint256 jiffys
                               )
                               private
    {
        require(isUserRegistered(payer));
        require(isUserRegistered(payee));
        require(spendableBalanceOf(payer) >= jiffys);

        balances[payer] = balances[payer].sub(jiffys); 
        balances[payee] = balances[payee].add(jiffys);
        Transfer(payer, payee, jiffys);

        // In the event the payer had received any signup tokens, their value
        // would be stored in the seedJiffys property. When any contract payment
        // is made, we reduce the seedJiffys number. seedJiffys tracks how many
        // tokens are not allowed to be transferred out of an account. As a user
        // makes payments to other users, those tokens have served their purpose
        // of encouraging use of the network and are no longer are restricted.
        if (users[payer].seedJiffys >= jiffys) {
            users[payer].seedJiffys = users[payer].seedJiffys.sub(jiffys);
        } else {
            users[payer].seedJiffys = 0;
        }
           
    }

    /**
    * @dev Handles transfer of tokens for vesting grants
    *
    * This function is called by the TokenVesting contract. To prevent unauthorized 
    * use the function is only callable by a previously authorized contract.
    *
    * @param issuer The account granting tokens
    * @param beneficiary The account being granted tokens
    * @param vestedJiffys The number of vested Jiffys for immediate payment
    * @param unvestedJiffys The number of unvested Jiffys to be placed in escrow
    */     
    function vestingGrant
                            (
                                address issuer, 
                                address beneficiary, 
                                uint256 vestedJiffys,
                                uint256 unvestedJiffys
                            ) 
                            external 
                            requireIsOperational 
    {
        require(isContractAuthorized(msg.sender));   
        require(spendableBalanceOf(issuer) >= unvestedJiffys.add(vestedJiffys));


        // Any vestedJiffys are transferred immediately to the beneficiary
        if (vestedJiffys > 0) {
            balances[issuer] = balances[issuer].sub(vestedJiffys);
            balances[beneficiary] = balances[beneficiary].add(vestedJiffys);
            Transfer(issuer, beneficiary, vestedJiffys);
        }

        // Any unvestedJiffys are removed from the granting account balance
        // A corresponding number of Jiffys is added to the granting account&#39;s
        // vesting escrow balance.
        balances[issuer] = balances[issuer].sub(unvestedJiffys);
        vestingEscrows[issuer] = vestingEscrows[issuer].add(unvestedJiffys);
    }


    /**
    * @dev Handles transfer of tokens for vesting revokes and releases
    *
    * This function is called by the TokenVesting contract. To prevent unauthorized 
    * use the function is only callable by a previously authorized contract.
    *
    * @param issuer The account granting tokens
    * @param beneficiary The account being granted tokens
    * @param jiffys The number of Jiffys for release or revoke
    */     
    function vestingTransfer
                            (
                                address issuer, 
                                address beneficiary, 
                                uint256 jiffys
                            ) 
                            external 
                            requireIsOperational 
    {
        require(isContractAuthorized(msg.sender));   
        require(vestingEscrows[issuer] >= jiffys);

        vestingEscrows[issuer] = vestingEscrows[issuer].sub(jiffys);
        balances[beneficiary] = balances[beneficiary].add(jiffys);
        Transfer(issuer, beneficiary, jiffys);
    }


    /**
    * @dev Gets an array of addresses registered with contract
    *
    * This can be used by API to enumerate all users
    */   
    function getRegisteredUsers() 
                                external 
                                view 
                                requirePlatformManager 
                                returns(address[]) 
    {
        return registeredUserLookup;
    }


    /**
    * @dev Gets an array of addresses registered with contract
    *
    * This can be used by API to enumerate all users
    */   
    function getRegisteredUser
                                (
                                    address account
                                ) 
                                external 
                                view 
                                requirePlatformManager                                
                                returns(uint256, uint256, uint256, address) 
    {
        require(users[account].isRegistered);

        return (balances[account], users[account].seedJiffys, users[account].interfaceEscrowJiffys, users[account].referrer);
    }


    /**
    * @dev Returns ICO-related state information for use by API
    */ 
    function getIcoInfo()
                                  public
                                  view
                                  returns(bool, uint256, uint256, uint256, uint256, uint256)
    {
        return (
                    balances[icoOwner] > 0, 
                    weiExchangeRate, 
                    centsExchangeRate, 
                    bonus20EndTimestamp, 
                    bonus10EndTimestamp, 
                    bonus5EndTimestamp
                );
    }

    /********************************************************************************************/
    /*                                       TOKEN SALE                                         */
    /********************************************************************************************/

    /**
    * @dev Fallback function for buying ICO tokens. This is not expected to be called with
    *      default gas as it will most certainly fail.
    *
    */
    function() 
                            external 
                            payable 
    {
        buy(msg.sender);
    }


    /**
    * @dev Buy ICO tokens
    *
    * @param account Account that is buying tokens
    *
    */
    function buy
                            (
                                address account
                            ) 
                            public 
                            payable 
                            requireIsOperational 
    {
        require(balances[icoOwner] > 0);
        require(account != address(0));        
        require(msg.value >= weiExchangeRate);    // Minimum 1 token

        uint256 weiReceived = msg.value;

        // Convert Wei to Jiffys based on the exchange rate
        uint256 buyJiffys = weiReceived.mul(jiffysMultiplier).div(weiExchangeRate);
        processPurchase(icoOwner, account, buyJiffys, now);
        icoWallet.transfer(msg.value);
    }


    /**
    * @dev Buy ICO tokens with USD
    *
    * @param account Account that is buying tokens
    * @param cents Purchase amount in cents
    *
    */    
    function buyUSD
                            (
                                address account,
                                uint256 cents
                            ) 
                            public 
                            requireIsOperational 
                            requirePlatformManager
    {
        require(balances[icoOwner] > 0);
        require(account != address(0));        
        require(cents >= centsExchangeRate);    // Minimum 1 token



        // Convert Cents to Jiffys based on the exchange rate
        uint256 buyJiffys = cents.mul(jiffysMultiplier).div(centsExchangeRate);

        if (users[account].isRegistered) {
            processPurchase(icoOwner, account, buyJiffys, now);
        } else {
            // Purchased credits will be transferred to account when user registers
            // They are kept in a holding area until then. We deduct buy+bonus from 
            // icoOwner because that is the amount that will eventually be credited.
            // However, we store the credit as buyJiffys so that the referral calculation
            // will be against the buy amount and not the buy+bonus amount
            uint256 totalJiffys = buyJiffys.add(calculatePurchaseBonus(buyJiffys, now));
            balances[icoOwner] = balances[icoOwner].sub(totalJiffys);
            balances[account] = balances[account].add(totalJiffys);
            purchaseCredits[account] = PurchaseCredit(buyJiffys, now);
            Transfer(icoOwner, account, buyJiffys);
        }

    }

    /**
    * @dev Process token purchase
    *
    * @param account Account that is buying tokens
    * @param buyJiffys Number of Jiffys purchased
    *
    */    
    function processPurchase
                            (
                                address source,
                                address account,
                                uint256 buyJiffys,
                                uint256 purchaseTimestamp
                            ) 
                            private 
    {

        uint256 totalJiffys = buyJiffys.add(calculatePurchaseBonus(buyJiffys, purchaseTimestamp));


        // Transfer purchased Jiffys to buyer
        require(transferableBalanceOf(source) >= totalJiffys);        
        balances[source] = balances[source].sub(totalJiffys);
        balances[account] = balances[account].add(totalJiffys);            
        Transfer(source, account, totalJiffys);

        // If the buyer has a referrer attached to their profile, then
        // transfer 3% of the purchased Jiffys to the referrer&#39;s account
        if (users[account].isRegistered && (users[account].referrer != address(0))) {
            address referrer = users[account].referrer;
            uint256 referralJiffys = (buyJiffys.mul(BUYER_REFERRER_BOUNTY)).div(100);
            if ((referralJiffys > 0) && (transferableBalanceOf(icoOwner) >= referralJiffys)) {
                balances[icoOwner] = balances[icoOwner].sub(referralJiffys);
                balances[referrer] = balances[referrer].add(referralJiffys);  
                Transfer(icoOwner, referrer, referralJiffys);
            }            
        }
    }

    /**
    * @dev Calculates ICO bonus tokens
    *
    * @param buyJiffys Number of Jiffys purchased
    *
    */    
    function calculatePurchaseBonus
                            (
                                uint256 buyJiffys,
                                uint256 purchaseTimestamp
                            ) 
                            private 
                            view
                            returns(uint256)
    {
        uint256 bonusPercentage = 0;

        // Time-based bonus
        if (purchaseTimestamp <= bonus5EndTimestamp) {
            if (purchaseTimestamp <= bonus10EndTimestamp) {
                if (purchaseTimestamp <= bonus20EndTimestamp) {
                    bonusPercentage = 20;
                } else {
                    bonusPercentage = 10;
                }
            } else {
                bonusPercentage = 5;
            }
        }

        return (buyJiffys.mul(bonusPercentage)).div(100);
    }
    

}   

/*
LICENSE FOR SafeMath and TokenVesting

The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


library SafeMath {
/* Copyright (c) 2016 Smart Contract Solutions, Inc. */
/* See License at end of file                        */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}