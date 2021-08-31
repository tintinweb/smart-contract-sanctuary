// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
/*
██████╗ ███████╗ █████╗ ██╗     ██╗████████╗██╗   ██╗ ██████╗ █████╗ ██████╗ ██████╗ ███████╗
██╔══██╗██╔════╝██╔══██╗██║     ██║╚══██╔══╝╚██╗ ██╔╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝
██████╔╝█████╗  ███████║██║     ██║   ██║    ╚████╔╝ ██║     ███████║██████╔╝██║  ██║███████╗
██╔══██╗██╔══╝  ██╔══██║██║     ██║   ██║     ╚██╔╝  ██║     ██╔══██║██╔══██╗██║  ██║╚════██║
██║  ██║███████╗██║  ██║███████╗██║   ██║      ██║   ╚██████╗██║  ██║██║  ██║██████╔╝███████║
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝ 
*/
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";
import "./lib/NativeMetaTransaction.sol";
import "./interfaces/IRCTreasury.sol";
import "./interfaces/IRCMarket.sol";
import "./interfaces/IRCOrderbook.sol";
import "./interfaces/IRCNftHubL2.sol";
import "./interfaces/IRCFactory.sol";
import "./interfaces/IRCBridge.sol";

/// @title Reality Cards Treasury
/// @author Andrew Stanger & Daniel Chilvers
/// @notice If you have found a bug, please contact [email protected] no hack pls!!
contract RCTreasury is AccessControl, NativeMetaTransaction, IRCTreasury {
    using SafeERC20 for IERC20;

    /*╔═════════════════════════════════╗
      ║             VARIABLES           ║
      ╚═════════════════════════════════╝*/
    /// @dev orderbook instance, to remove users bids on foreclosure
    IRCOrderbook public override orderbook;
    /// @dev leaderboard instance
    IRCLeaderboard public override leaderboard;
    /// @dev token contract
    IERC20 public override erc20;
    /// @dev the Factory so only the Factory can add new markets
    IRCFactory public override factory;
    /// @dev address of (as yet non existent) Bridge for withdrawals to mainnet
    address public override bridgeAddress;
    /// @dev sum of all deposits
    uint256 public override totalDeposits;
    /// @dev the rental payments made in each market
    mapping(address => uint256) public override marketPot;
    /// @dev sum of all market pots
    uint256 public override totalMarketPots;
    /// @dev rent taken and allocated to a particular market
    uint256 public override marketBalance;
    /// @dev a quick check if a user is foreclosed
    mapping(address => bool) public override isForeclosed;
    /// @dev to keep track of the size of the rounding issue between rent collections
    uint256 public override marketBalanceTopup;

    /// @param deposit the users current deposit in wei
    /// @param rentalRate the daily cost of the cards the user current owns
    /// @param bidRate the sum total of all placed bids
    /// @param lastRentCalc The timestamp of the users last rent calculation
    /// @param lastRentalTime The timestamp the user last made a rental
    struct User {
        uint128 deposit;
        uint128 rentalRate;
        uint128 bidRate;
        uint64 lastRentCalc;
        uint64 lastRentalTime;
    }
    mapping(address => User) public user;

    /*╔═════════════════════════════════╗
      ║      GOVERNANCE VARIABLES       ║
      ╚═════════════════════════════════╝*/
    /// @dev only parameters that need to be are here, the rest are in the Factory
    /// @dev minimum rental duration (1 day divisor: i.e. 24 = 1 hour, 48 = 30 mins)
    uint256 public override minRentalDayDivisor;
    /// @dev max deposit balance, to minimise funds at risk
    uint256 public override maxContractBalance;
    /// @dev whitelist to only allow certain addresses to deposit
    /// @dev intended for beta use only, will be disabled after launch
    mapping(address => bool) public isAllowed;
    bool public whitelistEnabled;
    /// @dev allow markets to be restricted to a certain role
    mapping(address => bytes32) public marketWhitelist;
    /// @dev to test if the uberOwner multisig all still have access they
    /// @dev .. will periodically be asked to update this variable.
    uint256 public override uberOwnerCheckTime;

    /*╔═════════════════════════════════╗
      ║             SAFETY              ║
      ╚═════════════════════════════════╝*/
    /// @dev if true, cannot deposit, withdraw or rent any cards across all events
    bool public override globalPause;
    /// @dev if true, cannot rent, claim or upgrade any cards for specific market
    mapping(address => bool) public override marketPaused;
    /// @dev if true, owner has locked the market pause (Governors are locked out)
    mapping(address => bool) public override lockMarketPaused;

    /*╔═════════════════════════════════╗
      ║          Access Control         ║
      ╚═════════════════════════════════╝*/
    bytes32 public constant UBER_OWNER = keccak256("UBER_OWNER");
    bytes32 public constant OWNER = keccak256("OWNER");
    bytes32 public constant GOVERNOR = keccak256("GOVERNOR");
    bytes32 public constant FACTORY = keccak256("FACTORY");
    bytes32 public constant MARKET = keccak256("MARKET");
    bytes32 public constant TREASURY = keccak256("TREASURY");
    bytes32 public constant ORDERBOOK = keccak256("ORDERBOOK");
    bytes32 public constant WHITELIST = keccak256("WHITELIST");
    bytes32 public constant ARTIST = keccak256("ARTIST");
    bytes32 public constant AFFILIATE = keccak256("AFFILIATE");
    bytes32 public constant CARD_AFFILIATE = keccak256("CARD_AFFILIATE");

    /*╔═════════════════════════════════╗
      ║             EVENTS              ║
      ╚═════════════════════════════════╝*/

    event LogUserForeclosed(address indexed user, bool indexed foreclosed);
    event LogAdjustDeposit(
        address indexed user,
        uint256 indexed amount,
        bool increase
    );
    event LogMarketPaused(address market, bool paused);
    event LogGlobalPause(bool paused);
    event LogMarketWhitelist(address _market, bytes32 role);

    /*╔═════════════════════════════════╗
      ║           CONSTRUCTOR           ║
      ╚═════════════════════════════════╝*/

    constructor(address _tokenAddress) {
        // initialise MetaTransactions
        _initializeEIP712("RealityCardsTreasury", "1");

        /* setup AccessControl

                         UBER_OWNER
            ┌───────────┬────┴─────┬────────────┐
            │           │          │            │ 
          OWNER      FACTORY    ORDERBOOK   TREASURY 
            │           │
         GOVERNOR     MARKET
            │
         WHITELIST | ARTIST | AFFILIATE | CARD_AFFILIATE
        */
        _setupRole(DEFAULT_ADMIN_ROLE, msgSender());
        _setupRole(UBER_OWNER, msgSender());
        _setupRole(OWNER, msgSender());
        _setupRole(GOVERNOR, msgSender());
        _setupRole(WHITELIST, msgSender());
        _setupRole(TREASURY, address(this));
        _setRoleAdmin(UBER_OWNER, UBER_OWNER);
        _setRoleAdmin(OWNER, UBER_OWNER);
        _setRoleAdmin(FACTORY, UBER_OWNER);
        _setRoleAdmin(ORDERBOOK, UBER_OWNER);
        _setRoleAdmin(TREASURY, UBER_OWNER);
        _setRoleAdmin(GOVERNOR, OWNER);
        _setRoleAdmin(WHITELIST, GOVERNOR);
        _setRoleAdmin(ARTIST, GOVERNOR);
        _setRoleAdmin(AFFILIATE, GOVERNOR);
        _setRoleAdmin(CARD_AFFILIATE, GOVERNOR);
        _setRoleAdmin(MARKET, FACTORY);

        // initialise adjustable parameters
        setMinRental(24 * 6); // MinRental is a divisor of 1 day(86400 seconds), 24*6 will set to 10 minutes
        setMaxContractBalance(1_000_000 ether); // 1m
        setTokenAddress(_tokenAddress);
        whitelistEnabled = true;
    }

    /*╔═════════════════════════════════╗
      ║           MODIFIERS             ║
      ╚═════════════════════════════════╝*/

    /// @notice check that funds haven't gone missing during this function call
    modifier balancedBooks() {
        _;
        /// @dev using >= not == in case anyone sends tokens direct to contract
        require(
            erc20.balanceOf(address(this)) >=
                totalDeposits + marketBalance + totalMarketPots,
            "Books are unbalanced!"
        );
    }

    /*╔═════════════════════════════════╗
      ║       GOVERNANCE - OWNER        ║
      ╚═════════════════════════════════╝*/

    /// @dev all functions should be onlyRole(OWNER)
    // min rental event emitted by market. Nothing else need be emitted.

    /*┌────────────────────────────────────┐
      │ CALLED WITHIN CONSTRUCTOR - PUBLIC │
      └────────────────────────────────────┘*/

    /// @notice minimum rental duration (1 day divisor: i.e. 24 = 1 hour, 48 = 30 mins)
    /// @param _newDivisor the divisor to set
    function setMinRental(uint256 _newDivisor) public override onlyRole(OWNER) {
        minRentalDayDivisor = _newDivisor;
    }

    /// @notice set max deposit balance, to minimise funds at risk
    /// @dev this is only a soft check, it is possible to exceed this limit
    /// @param _newBalanceLimit the max balance to set in wei
    function setMaxContractBalance(uint256 _newBalanceLimit)
        public
        override
        onlyRole(OWNER)
    {
        maxContractBalance = _newBalanceLimit;
    }

    /*┌──────────────────────────────────────────┐
      │ NOT CALLED WITHIN CONSTRUCTOR - EXTERNAL │
      └──────────────────────────────────────────┘*/

    /// @notice if true, cannot deposit, withdraw or rent any cards
    function changeGlobalPause() external override onlyRole(OWNER) {
        globalPause = !globalPause;
        emit LogGlobalPause(globalPause);
    }

    /// @notice if true, cannot make a new rental, or claim the NFT for a specific market
    /// @param _market The
    function changePauseMarket(address _market, bool _paused)
        external
        override
        onlyRole(OWNER)
    {
        require(hasRole(MARKET, _market), "This isn't a market");
        marketPaused[_market] = _paused;
        lockMarketPaused[_market] = marketPaused[_market];
        emit LogMarketPaused(_market, marketPaused[_market]);
    }

    /// @notice allow governance (via the factory) to approve and un pause the market if the owner hasn't paused it
    function unPauseMarket(address _market)
        external
        override
        onlyRole(FACTORY)
    {
        require(hasRole(MARKET, _market), "This isn't a market");
        require(!lockMarketPaused[_market], "Owner has paused market");
        marketPaused[_market] = false;
        emit LogMarketPaused(_market, marketPaused[_market]);
    }

    /*╔═════════════════════════════════╗
      ║      WHITELIST FUNCTIONS        ║
      ╚═════════════════════════════════╝*/
    // There are 2 whitelist functionalities here,
    // 1. a whitelist for users to enter the system, restrict deposits.
    // 2. a market specific whitelist, restrict rentals on certain markets to certain users.

    /// @notice if true, users must be on the whitelist to deposit
    function toggleWhitelist() external override onlyRole(OWNER) {
        whitelistEnabled = !whitelistEnabled;
    }

    /// @notice Add/Remove multiple users to the whitelist
    /// @param _users an array of users to add or remove
    /// @param add true to add the users
    function batchWhitelist(address[] calldata _users, bool add)
        external
        override
        onlyRole(GOVERNOR)
    {
        if (add) {
            for (uint256 index = 0; index < _users.length; index++) {
                RCTreasury.grantRole(WHITELIST, _users[index]);
            }
        } else {
            for (uint256 index = 0; index < _users.length; index++) {
                RCTreasury.revokeRole(WHITELIST, _users[index]);
            }
        }
    }

    /// @notice to implement (or remove) a market specific whitelist
    /// @param _market the market to affect
    /// @param _role the role required for this market
    /// @dev it'd be nice to pass the role as a string but then we couldn't reset this
    function updateMarketWhitelist(address _market, bytes32 _role)
        external
        onlyRole(GOVERNOR)
    {
        marketWhitelist[_market] = _role;
        emit LogMarketWhitelist(_market, _role);
    }

    /// @notice Some markets may be restricted to certain roles,
    /// @notice This function checks if the user has the role required for a given market
    /// @dev Used for the markets to check themselves
    /// @param _user The user to check
    function marketWhitelistCheck(address _user)
        external
        view
        override
        returns (bool)
    {
        bytes32 requiredRole = marketWhitelist[msgSender()];
        if (requiredRole == bytes32(0)) {
            return true;
        } else {
            return hasRole(requiredRole, _user);
        }
    }

    /*╔═════════════════════════════════╗
      ║     GOVERNANCE - UBER OWNER     ║
      ╠═════════════════════════════════╣
      ║  ******** DANGER ZONE ********  ║
      ╚═════════════════════════════════╝*/
    /// @dev uber owner required for upgrades
    /// @dev deploying and setting a new factory is effectively an upgrade
    /// @dev this is separate so owner so can be set to multisig, or burn address to relinquish upgrade ability
    /// @dev ... while maintaining governance over other governance functions

    /// @notice Simply updates a variable with the current block.timestamp used
    /// @notice .. to check the uberOwner multisig controllers all still have access.
    function uberOwnerTest() external override onlyRole(UBER_OWNER) {
        uberOwnerCheckTime = block.timestamp;
    }

    function setFactoryAddress(address _newFactory)
        external
        override
        onlyRole(UBER_OWNER)
    {
        require(_newFactory != address(0), "Must set an address");
        // factory is also an OWNER and GOVERNOR to use the proxy functions
        revokeRole(FACTORY, address(factory));
        revokeRole(OWNER, address(factory));
        revokeRole(GOVERNOR, address(factory));
        factory = IRCFactory(_newFactory);
        grantRole(FACTORY, address(factory));
        grantRole(OWNER, address(factory));
        grantRole(GOVERNOR, address(factory));
    }

    /// @notice To set the orderbook address
    /// @dev changing this while markets are active could prove disastrous
    function setOrderbookAddress(address _newOrderbook)
        external
        override
        onlyRole(UBER_OWNER)
    {
        require(_newOrderbook != address(0), "Must set an address");
        revokeRole(ORDERBOOK, address(orderbook));
        orderbook = IRCOrderbook(_newOrderbook);
        grantRole(ORDERBOOK, address(orderbook));
        factory.setOrderbookAddress(orderbook);
    }

    /// @notice To set the leaderboard address
    /// @dev The treasury doesn't need the leaderboard, just setting
    /// @dev .. here to keep the setters in the same place.
    function setLeaderboardAddress(address _newLeaderboard)
        external
        override
        onlyRole(UBER_OWNER)
    {
        require(_newLeaderboard != address(0), "Must set an address");
        leaderboard = IRCLeaderboard(_newLeaderboard);
        factory.setLeaderboardAddress(leaderboard);
    }

    /// @notice To change the ERC20 token.
    /// @dev changing this while tokens have been deposited could prove disastrous
    function setTokenAddress(address _newToken)
        public
        override
        onlyRole(UBER_OWNER)
    {
        require(_newToken != address(0), "Must set an address");
        erc20 = IERC20(_newToken);
    }

    /// @notice To set the bridge address and approve token transfers
    function setBridgeAddress(address _newBridge)
        external
        override
        onlyRole(UBER_OWNER)
    {
        require(_newBridge != address(0), "Must set an address");
        bridgeAddress = _newBridge;
        erc20.approve(_newBridge, type(uint256).max);
    }

    /// @notice Disaster recovery, pulls all funds from the Treasury to the UberOwner
    function globalExit() external onlyRole(UBER_OWNER) {
        uint256 _balance = erc20.balanceOf(address(this));
        /// @dev using msg.sender instead of msgSender as a precaution should Meta-Tx be compromised
        erc20.safeTransfer(msg.sender, _balance);
    }

    /*╔═════════════════════════════════╗
      ║ DEPOSIT AND WITHDRAW FUNCTIONS  ║
      ╚═════════════════════════════════╝*/

    /// @notice deposit tokens into RealityCards
    /// @dev it is passed the user instead of using msg.sender because might be called
    /// @dev ... via contract or Layer1->Layer2 bot
    /// @param _user the user to credit the deposit to
    /// @param _amount the amount to deposit, must be approved
    function deposit(uint256 _amount, address _user)
        external
        override
        balancedBooks
        returns (bool)
    {
        require(!globalPause, "Deposits are disabled");
        require(
            erc20.allowance(msgSender(), address(this)) >= _amount,
            "User not approved to send this amount"
        );
        require(
            (erc20.balanceOf(address(this)) + _amount) <= maxContractBalance,
            "Limit hit"
        );
        require(_amount > 0, "Must deposit something");
        if (whitelistEnabled) {
            require(hasRole(WHITELIST, _user), "Not in whitelist");
        }

        // do some cleaning up, it might help cancel their foreclosure
        orderbook.removeOldBids(_user);

        user[_user].deposit += SafeCast.toUint128(_amount);
        totalDeposits += _amount;

        erc20.safeTransferFrom(msgSender(), address(this), _amount);
        emit LogAdjustDeposit(_user, _amount, true);

        // this deposit could cancel the users foreclosure
        assessForeclosure(_user);
        return true;
    }

    /// @notice withdraw a users deposit either directly or over the bridge to the mainnet
    /// @dev this is the only function where funds leave the contract
    /// @param _amount the amount to withdraw
    /// @param _localWithdrawal if true then withdraw to the users address, otherwise to the bridge
    function withdrawDeposit(uint256 _amount, bool _localWithdrawal)
        external
        override
        balancedBooks
    {
        require(!globalPause, "Withdrawals are disabled");
        address _msgSender = msgSender();
        require(user[_msgSender].deposit > 0, "Nothing to withdraw");
        // only allow withdraw if they have no bids,
        // OR they've had their cards for at least the minimum rental period
        require(
            user[_msgSender].bidRate == 0 ||
                block.timestamp - (user[_msgSender].lastRentalTime) >
                uint256(1 days) / minRentalDayDivisor,
            "Too soon"
        );

        // step 1: collect rent on owned cards
        collectRentUser(_msgSender, block.timestamp);

        // step 2: process withdrawal
        if (_amount > user[_msgSender].deposit) {
            _amount = user[_msgSender].deposit;
        }
        emit LogAdjustDeposit(_msgSender, _amount, false);
        user[_msgSender].deposit -= SafeCast.toUint128(_amount);
        totalDeposits -= _amount;
        if (_localWithdrawal) {
            erc20.safeTransfer(_msgSender, _amount);
        } else {
            IRCBridge bridge = IRCBridge(bridgeAddress);
            bridge.withdrawToMainnet(_msgSender, _amount);
        }

        // step 3: remove bids if insufficient deposit
        // do some cleaning up first, it might help avoid their foreclosure
        orderbook.removeOldBids(_msgSender);
        if (
            user[_msgSender].bidRate != 0 &&
            user[_msgSender].bidRate / (minRentalDayDivisor) >
            user[_msgSender].deposit
        ) {
            // foreclose user, this is requred to remove them from the orderbook
            isForeclosed[_msgSender] = true;
            // remove them from the orderbook
            orderbook.removeUserFromOrderbook(_msgSender);
        }
    }

    /// @notice to increase the market balance
    /// @dev not strictly required but prevents markets being short-changed due to rounding issues
    function topupMarketBalance(uint256 _amount)
        external
        override
        balancedBooks
    {
        marketBalanceTopup += _amount;
        marketBalance += _amount;
        erc20.safeTransferFrom(msgSender(), address(this), _amount);
    }

    /*╔═════════════════════════════════╗
      ║         ERC20 helpers           ║
      ╚═════════════════════════════════╝*/

    /// @notice allow and balance check
    /// @dev used for the Factory to check before spending too much gas
    function checkSponsorship(address sender, uint256 _amount)
        external
        view
        override
    {
        require(
            erc20.allowance(sender, address(this)) >= _amount,
            "Insufficient Allowance"
        );
        require(erc20.balanceOf(sender) >= _amount, "Insufficient Balance");
    }

    /*╔═════════════════════════════════╗
      ║        MARKET CALLABLE          ║
      ╚═════════════════════════════════╝*/
    // only markets can call these functions

    /// @notice a rental payment is equivalent to moving from user's deposit to market pot,
    /// @notice ..called by _collectRent in the market
    /// @param _amount amount of rent to pay in wei
    function payRent(uint256 _amount)
        external
        override
        balancedBooks
        onlyRole(MARKET)
        returns (uint256)
    {
        require(!globalPause, "Rentals are disabled");
        if (marketBalance < _amount) {
            uint256 discrepancy = _amount - marketBalance;
            if (discrepancy > marketBalanceTopup) {
                marketBalanceTopup = 0;
            } else {
                marketBalanceTopup -= discrepancy;
            }
            _amount = marketBalance;
        }
        address _market = msgSender();
        marketBalance -= _amount;
        marketPot[_market] += _amount;
        totalMarketPots += _amount;
        /// @dev return the amount just in case it was adjusted
        return _amount;
    }

    /// @notice a payout is equivalent to moving from market pot to user's deposit (the opposite of payRent)
    /// @param _user the user to query
    /// @param _amount amount to payout in wei
    function payout(address _user, uint256 _amount)
        external
        override
        balancedBooks
        onlyRole(MARKET)
        returns (bool)
    {
        require(!globalPause, "Payouts are disabled");
        user[_user].deposit += SafeCast.toUint128(_amount);
        marketPot[msgSender()] -= _amount;
        totalMarketPots -= _amount;
        totalDeposits += _amount;
        assessForeclosure(_user);
        emit LogAdjustDeposit(_user, _amount, true);
        return true;
    }

    /// @dev called by _collectRentAction() in the market in situations where collectRentUser() collected too much rent
    function refundUser(address _user, uint256 _refund)
        external
        override
        balancedBooks
        onlyRole(MARKET)
    {
        marketBalance -= _refund;
        user[_user].deposit += SafeCast.toUint128(_refund);
        totalDeposits += _refund;
        emit LogAdjustDeposit(_user, _refund, true);
        assessForeclosure(_user);
    }

    /// @notice ability to add liquidity to the pot without being able to win (called by market sponsor function).
    function sponsor(address _sponsor, uint256 _amount)
        external
        override
        balancedBooks
        onlyRole(MARKET)
    {
        require(!globalPause, "Global Pause is Enabled");
        address _market = msgSender();
        require(!lockMarketPaused[_market], "Market is paused");
        require(
            erc20.allowance(_sponsor, address(this)) >= _amount,
            "Not approved to send this amount"
        );
        marketPot[_market] += _amount;
        totalMarketPots += _amount;
        erc20.safeTransferFrom(_sponsor, address(this), _amount);
    }

    /// @notice tracks when the user last rented- so they cannot rent and immediately withdraw,
    /// @notice ..thus bypassing minimum rental duration
    /// @param _user the user to query
    function updateLastRentalTime(address _user)
        external
        override
        onlyRole(MARKET)
    {
        // update the last rental time
        user[_user].lastRentalTime = SafeCast.toUint64(block.timestamp);
        // check if this is their first rental (no previous rental calculation)
        if (user[_user].lastRentCalc == 0) {
            // we need to start their clock ticking, update their last rental calculation time
            user[_user].lastRentCalc = SafeCast.toUint64(block.timestamp);
        }
    }

    /*╔═════════════════════════════════╗
      ║        MARKET HELPERS           ║
      ╚═════════════════════════════════╝*/

    /// @notice Allows the factory to add a new market to AccessControl
    /// @dev Also controls the default paused state
    /// @param _market The market address to add
    /// @param _paused If the market should be paused or not
    function addMarket(address _market, bool _paused) external override {
        require(hasRole(FACTORY, msgSender()), "Not Authorised");
        marketPaused[_market] = _paused;
        AccessControl.grantRole(MARKET, _market);
        emit LogMarketPaused(_market, marketPaused[_market]);
    }

    /// @notice provides the sum total of a users bids across all markets (whether active or not)
    /// @param _user the user address to query
    function userTotalBids(address _user)
        external
        view
        override
        returns (uint256)
    {
        return user[_user].bidRate;
    }

    /// @notice provide the users remaining deposit
    /// @param _user the user address to query
    function userDeposit(address _user)
        external
        view
        override
        returns (uint256)
    {
        return uint256(user[_user].deposit);
    }

    /*╔═════════════════════════════════╗
      ║      ORDERBOOK CALLABLE         ║
      ╚═════════════════════════════════╝*/

    /// @notice updates users rental rates when ownership changes
    /// @dev rentalRate = sum of all active bids
    /// @param _oldOwner the address of the user losing ownership
    /// @param _newOwner the address of the user gaining ownership
    /// @param _oldPrice the price the old owner was paying
    /// @param _newPrice the price the new owner will be paying
    /// @param _timeOwnershipChanged the timestamp of this event
    function updateRentalRate(
        address _oldOwner,
        address _newOwner,
        uint256 _oldPrice,
        uint256 _newPrice,
        uint256 _timeOwnershipChanged
    ) external override onlyRole(ORDERBOOK) {
        if (
            _timeOwnershipChanged != user[_newOwner].lastRentCalc &&
            !hasRole(MARKET, _newOwner)
        ) {
            // The new owners rent must be collected before adjusting their rentalRate
            // See if the new owner has had a rent collection before or after this ownership change
            if (_timeOwnershipChanged < user[_newOwner].lastRentCalc) {
                // the new owner has a more recent rent collection

                uint256 _additionalRentOwed = rentOwedBetweenTimestamps(
                    user[_newOwner].lastRentCalc,
                    _timeOwnershipChanged,
                    _newPrice
                );

                // they have enough funds, just collect the extra
                // we can be sure of this because it was checked they can cover the minimum rental
                _increaseMarketBalance(_additionalRentOwed, _newOwner);
                emit LogAdjustDeposit(_newOwner, _additionalRentOwed, false);
            } else {
                // the new owner has an old rent collection, do they own anything else?
                if (user[_newOwner].rentalRate != 0) {
                    // rent collect up-to ownership change time
                    collectRentUser(_newOwner, _timeOwnershipChanged);
                } else {
                    // first card owned, set start time
                    user[_newOwner].lastRentCalc = SafeCast.toUint64(
                        _timeOwnershipChanged
                    );
                    // send an event for the UI to have a timestamp
                    emit LogAdjustDeposit(_newOwner, 0, false);
                }
            }
        }
        // Must add before subtract, to avoid underflow in the case a user is only updating their price.
        user[_newOwner].rentalRate += SafeCast.toUint128(_newPrice);
        user[_oldOwner].rentalRate -= SafeCast.toUint128(_oldPrice);
    }

    /// @dev increase bidRate when new bid entered
    function increaseBidRate(address _user, uint256 _price)
        external
        override
        onlyRole(ORDERBOOK)
    {
        user[_user].bidRate += SafeCast.toUint128(_price);
    }

    /// @dev decrease bidRate when bid removed
    function decreaseBidRate(address _user, uint256 _price)
        external
        override
        onlyRole(ORDERBOOK)
    {
        user[_user].bidRate -= SafeCast.toUint128(_price);
    }

    /*╔═════════════════════════════════╗
      ║      RENT CALC HELPERS          ║
      ╚═════════════════════════════════╝*/

    /// @notice returns the rent due between the users last rent calculation and
    /// @notice ..the current block.timestamp for all cards a user owns
    /// @param _user the user to query
    /// @param _timeOfCollection calculate up to a given time
    function rentOwedUser(address _user, uint256 _timeOfCollection)
        internal
        view
        returns (uint256 rentDue)
    {
        return
            (user[_user].rentalRate *
                (_timeOfCollection - user[_user].lastRentCalc)) / (1 days);
    }

    /// @notice calculates the rent owed between the given timestamps
    /// @param _time1 one of the timestamps
    /// @param _time2 the second timestamp
    /// @param _price the rental rate for this time period
    /// @return _rent the rent due for this time period
    /// @dev the timestamps can be given in any order
    function rentOwedBetweenTimestamps(
        uint256 _time1,
        uint256 _time2,
        uint256 _price
    ) internal pure returns (uint256 _rent) {
        if (_time1 < _time2) {
            (_time1, _time2) = (_time2, _time1);
        }
        _rent = (_price * (_time1 - _time2)) / (1 days);
    }

    /// @notice returns the current estimate of the users foreclosure time
    /// @param _user the user to query
    /// @param _newBid calculate foreclosure including a new card
    /// @param _timeOfNewBid timestamp of when a new card was gained
    function foreclosureTimeUser(
        address _user,
        uint256 _newBid,
        uint256 _timeOfNewBid
    ) external view override returns (uint256) {
        uint256 totalUserDailyRent = user[_user].rentalRate;
        if (totalUserDailyRent > 0) {
            uint256 timeLeftOfDeposit = (user[_user].deposit * 1 days) /
                totalUserDailyRent;

            uint256 foreclosureTimeWithoutNewCard = user[_user].lastRentCalc +
                timeLeftOfDeposit;

            if (
                foreclosureTimeWithoutNewCard > _timeOfNewBid &&
                _timeOfNewBid != 0
            ) {
                // calculate how long they can own the new card for
                uint256 _rentDifference = rentOwedBetweenTimestamps(
                    user[_user].lastRentCalc,
                    _timeOfNewBid,
                    totalUserDailyRent
                );
                uint256 _depositAtTimeOfNewBid = 0;

                if (user[_user].lastRentCalc < _timeOfNewBid) {
                    // new bid is after user rent calculation
                    _depositAtTimeOfNewBid =
                        user[_user].deposit -
                        _rentDifference;
                } else {
                    // new bid is before user rent calculation
                    _depositAtTimeOfNewBid =
                        user[_user].deposit +
                        _rentDifference;
                }

                uint256 _timeLeftOfDepositWithNewBid = (_depositAtTimeOfNewBid *
                    1 days) / (totalUserDailyRent + _newBid);

                uint256 _foreclosureTimeWithNewCard = _timeOfNewBid +
                    _timeLeftOfDepositWithNewBid;
                if (_foreclosureTimeWithNewCard > user[_user].lastRentCalc) {
                    return _foreclosureTimeWithNewCard;
                } else {
                    // The user couldn't afford to own the new card up to their last
                    // .. rent calculation, we can't rewind their rent calculation because
                    // .. of gas limits (there could be many markets having taken rent).
                    // Therefore unfortunately we can't give any ownership to this user as
                    // .. this could mean getting caught in a loop we may not be able to
                    // .. exit because of gas limits (there could be many users in this
                    // .. situation and we can't leave any unaccounted for).
                    // This means we return 0 to signify that the user can't afford this
                    // .. new ownership.
                    return 0;
                }
            } else {
                return user[_user].lastRentCalc + timeLeftOfDeposit;
            }
        } else {
            if (_newBid == 0) {
                // if no rentals they'll foreclose after the heat death of the universe
                return type(uint256).max;
            } else {
                return
                    _timeOfNewBid + ((user[_user].deposit * 1 days) / _newBid);
            }
        }
    }

    /// @notice call for a rent collection on the given user
    /// @notice IF the user doesn't have enough deposit, returns foreclosure time
    /// @notice ..otherwise returns zero
    /// @param _user the user to query
    /// @param _timeToCollectTo the timestamp to collect rent up-to
    /// @return newTimeLastCollectedOnForeclosure the time the user foreclosed if they foreclosed in this calculation
    function collectRentUser(address _user, uint256 _timeToCollectTo)
        public
        override
        returns (uint256 newTimeLastCollectedOnForeclosure)
    {
        require(!globalPause, "Global pause is enabled");
        require(_timeToCollectTo != 0, "Must set collection time");
        require(
            _timeToCollectTo <= block.timestamp,
            "Can't collect future rent"
        );
        if (user[_user].lastRentCalc < _timeToCollectTo) {
            uint256 rentOwedByUser = rentOwedUser(_user, _timeToCollectTo);

            if (rentOwedByUser > 0 && rentOwedByUser > user[_user].deposit) {
                // The User has run out of deposit already.
                uint256 previousCollectionTime = user[_user].lastRentCalc;

                /*
            timeTheirDepositLasted = timeSinceLastUpdate * (usersDeposit/rentOwed)
                                  = (now - previousCollectionTime) * (usersDeposit/rentOwed)
            */
                uint256 timeUsersDepositLasts = ((_timeToCollectTo -
                    previousCollectionTime) * uint256(user[_user].deposit)) /
                    rentOwedByUser;
                /*
            Users last collection time = previousCollectionTime + timeTheirDepositLasted
            */
                rentOwedByUser = uint256(user[_user].deposit);
                newTimeLastCollectedOnForeclosure =
                    previousCollectionTime +
                    timeUsersDepositLasts;
                _increaseMarketBalance(rentOwedByUser, _user);
                user[_user].lastRentCalc = SafeCast.toUint64(
                    newTimeLastCollectedOnForeclosure
                );
                assert(user[_user].deposit == 0);
                isForeclosed[_user] = true;
                emit LogUserForeclosed(_user, true);
            } else {
                // User has enough deposit to pay rent.
                _increaseMarketBalance(rentOwedByUser, _user);
                user[_user].lastRentCalc = SafeCast.toUint64(_timeToCollectTo);
            }
            emit LogAdjustDeposit(_user, rentOwedByUser, false);
        }
    }

    /// moving from the user deposit to the markets available balance
    function _increaseMarketBalance(uint256 rentCollected, address _user)
        internal
    {
        marketBalance += rentCollected;
        user[_user].deposit -= SafeCast.toUint128(rentCollected);
        totalDeposits -= rentCollected;
    }

    /// @notice checks if the user should still be foreclosed
    function assessForeclosure(address _user) public override {
        if (user[_user].deposit > (user[_user].bidRate / minRentalDayDivisor)) {
            isForeclosed[_user] = false;
            emit LogUserForeclosed(_user, false);
        } else {
            isForeclosed[_user] = true;
            emit LogUserForeclosed(_user, true);
        }
    }

    /// @dev can't be called hasRole also because AccessControl.hasRole isn't virtual
    function checkPermission(bytes32 role, address account)
        external
        view
        override
        returns (bool)
    {
        return AccessControl.hasRole(role, account);
    }

    /// @notice To grant a role (string) to an address
    /// @param role the role to grant, this is a string and will be converted to bytes32
    /// @param account the account to grant the role to
    /// @dev Not necessary but makes granting roles easier
    function grantRole(string memory role, address account) external override {
        bytes32 _role = keccak256(abi.encodePacked(role));
        RCTreasury.grantRole(_role, account);
    }

    /// @notice To grant a role (bytes32) to an address
    /// @param role the role to grant
    /// @param account the account to grant the role to
    function grantRole(bytes32 role, address account)
        public
        override(AccessControl, IRCTreasury)
    {
        AccessControl.grantRole(role, account);
    }

    /// @notice To check is a particular account has a certain role
    /// @param role The role (string) to query about
    /// @param account the address which may have this role
    /// @return Bool, True if the account has role
    /// @dev needed because we can't override hasRole (it's not virtual) and
    /// @dev .. without this the contract wouldn't fully implement the interface
    /// @dev Similar to checkPermissions except using string instead of bytes32
    function checkRole(string memory role, address account)
        external
        view
        override
        returns (bool)
    {
        bytes32 _role = keccak256(abi.encodePacked(role));
        return hasRole(_role, account);
    }

    /// @notice To revoke a role (string) from an address
    /// @param role the role to revoke, this is a string and will be converted to bytes32
    /// @param account the account to revoke the role from
    /// @dev Not necessary but makes revoking roles easier
    function revokeRole(string memory role, address account) external override {
        bytes32 _role = keccak256(abi.encodePacked(role));
        RCTreasury.revokeRole(_role, account);
    }

    /// @notice To revoke a role (bytes32) from an address
    /// @param role the role to revoke
    /// @param account the account to revoke the role from
    function revokeRole(bytes32 role, address account)
        public
        override(AccessControl, IRCTreasury)
    {
        AccessControl.revokeRole(role, account);
    }

    /*
         ▲  
        ▲ ▲ 
              */
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );
    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress] + (1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }

    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRCOrderbook.sol";
import "./IRCLeaderboard.sol";
import "./IRCFactory.sol";

interface IRCTreasury {
    function setTokenAddress(address _newToken) external;

    function grantRole(string memory role, address account) external;

    function grantRole(bytes32, address) external;

    function revokeRole(string memory role, address account) external;

    function revokeRole(bytes32, address) external;

    function collectRentUser(address _user, uint256 _timeToCollectTo)
        external
        returns (uint256 newTimeLastCollectedOnForeclosure);

    function topupMarketBalance(uint256 _amount) external;

    function assessForeclosure(address _user) external;

    // view functions
    function foreclosureTimeUser(
        address _user,
        uint256 _newBid,
        uint256 _timeOfNewBid
    ) external view returns (uint256);

    function checkRole(string memory role, address account)
        external
        view
        returns (bool);

    function uberOwnerCheckTime() external view returns (uint256);

    function bridgeAddress() external view returns (address);

    function checkPermission(bytes32, address) external view returns (bool);

    function erc20() external view returns (IERC20);

    function factory() external view returns (IRCFactory);

    function orderbook() external view returns (IRCOrderbook);

    function leaderboard() external view returns (IRCLeaderboard);

    function isForeclosed(address) external view returns (bool);

    function userTotalBids(address) external view returns (uint256);

    function userDeposit(address) external view returns (uint256);

    function totalDeposits() external view returns (uint256);

    function marketPot(address) external view returns (uint256);

    function totalMarketPots() external view returns (uint256);

    function marketBalance() external view returns (uint256);

    function marketBalanceTopup() external view returns (uint256);

    function minRentalDayDivisor() external view returns (uint256);

    function maxContractBalance() external view returns (uint256);

    function globalPause() external view returns (bool);

    function addMarket(address _market, bool paused) external;

    function marketPaused(address) external view returns (bool);

    function batchWhitelist(address[] calldata _users, bool add) external;

    function marketWhitelistCheck(address _user) external returns (bool);

    function lockMarketPaused(address _market) external view returns (bool);

    function setBridgeAddress(address _newAddress) external;

    function setOrderbookAddress(address _newAddress) external;

    function setLeaderboardAddress(address _newAddress) external;

    function setFactoryAddress(address _newFactory) external;

    function uberOwnerTest() external;

    function deposit(uint256 _amount, address _user) external returns (bool);

    function withdrawDeposit(uint256 _amount, bool _localWithdrawal) external;

    function checkSponsorship(address sender, uint256 _amount) external view;

    //only orderbook
    function increaseBidRate(address _user, uint256 _price) external;

    function decreaseBidRate(address _user, uint256 _price) external;

    function updateRentalRate(
        address _oldOwner,
        address _newOwner,
        uint256 _oldPrice,
        uint256 _newPrice,
        uint256 _timeOwnershipChanged
    ) external;

    // only owner
    function setMinRental(uint256 _newDivisor) external;

    function setMaxContractBalance(uint256) external;

    function changeGlobalPause() external;

    function changePauseMarket(address _market, bool _paused) external;

    function toggleWhitelist() external;

    // only factory
    function unPauseMarket(address _market) external;

    // only markets
    function payRent(uint256) external returns (uint256);

    function payout(address, uint256) external returns (bool);

    function refundUser(address _user, uint256 _refund) external;

    function sponsor(address _sponsor, uint256 _amount) external;

    function updateLastRentalTime(address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./IRCNftHubL2.sol";
import "./IRCTreasury.sol";
import "./IRCFactory.sol";
import "./IRCLeaderboard.sol";
import "./IRealitio.sol";
import "./IRCOrderbook.sol";

interface IRCMarket {
    enum States {
        CLOSED,
        OPEN,
        LOCKED,
        WITHDRAW
    }
    enum Mode {
        CLASSIC,
        WINNER_TAKES_ALL,
        SAFE_MODE
    }

    function getWinnerFromOracle() external;

    function setAmicableResolution(uint256 _winningOutcome) external;

    function lockMarket() external;

    function claimCard(uint256 _card) external;

    function rentAllCards(uint256 _maxSumOfPrices) external;

    function newRental(
        uint256 _newPrice,
        uint256 _timeHeldLimit,
        address _startingPosition,
        uint256 _card
    ) external;

    function updateTimeHeldLimit(uint256 _timeHeldLimit, uint256 _card)
        external;

    function collectRent(uint256 _cardId) external returns (bool);

    function exitAll() external;

    function exit(uint256) external;

    function sponsor(address _sponsor, uint256 _amount) external;

    function sponsor(uint256 _amount) external;

    // payouts
    function withdraw() external;

    function payArtist() external;

    function payMarketCreator() external;

    function payAffiliate() external;

    function payCardAffiliate(uint256) external;

    // view functions
    function nfthub() external view returns (IRCNftHubL2);

    function treasury() external view returns (IRCTreasury);

    function factory() external view returns (IRCFactory);

    function leaderboard() external view returns (IRCLeaderboard);

    function orderbook() external view returns (IRCOrderbook);

    function realitio() external view returns (IRealitio);

    function mode() external view returns (Mode);

    function isMarket() external view returns (bool);

    function numberOfCards() external view returns (uint256);

    function nftsToAward() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function state() external view returns (States);

    function getTokenId(uint256 _card) external view returns (uint256 _tokenId);

    function cardAccountingIndex() external view returns (uint256);

    function accountingComplete() external view returns (bool);

    // prices, deposits, rent

    function rentCollectedPerUser(address) external view returns (uint256);

    function rentCollectedPerUserPerCard(address, uint256)
        external
        view
        returns (uint256);

    function totalRentCollected() external view returns (uint256);

    function exitedTimestamp(address) external view returns (uint256);

    //parameters

    function minimumPriceIncreasePercent() external view returns (uint256);

    function minRentalDayDivisor() external view returns (uint256);

    function maxRentIterations() external view returns (uint256);

    // time
    function timeHeld(uint256 _card, address _user)
        external
        view
        returns (uint256);

    function timeLastCollected(uint256 _card) external view returns (uint256);

    function longestOwner(uint256 _card) external view returns (address);

    function marketOpeningTime() external view returns (uint32);

    function marketLockingTime() external view returns (uint32);

    function oracleResolutionTime() external view returns (uint32);

    // payout settings
    function winningOutcome() external view returns (uint256);

    function userAlreadyWithdrawn(address) external view returns (bool);

    function artistAddress() external view returns (address);

    function artistCut() external view returns (uint256);

    function artistPaid() external view returns (bool);

    function affiliateAddress() external view returns (address);

    function affiliateCut() external view returns (uint256);

    function affiliatePaid() external view returns (bool);

    function winnerCut() external view returns (uint256);

    function marketCreatorAddress() external view returns (address);

    function creatorCut() external view returns (uint256);

    function creatorPaid() external view returns (bool);

    function cardAffiliateAddresses(uint256) external view returns (address);

    function cardAffiliateCut() external view returns (uint256);

    // oracle

    function questionId() external view returns (bytes32);

    function arbitrator() external view returns (address);

    function timeout() external view returns (uint32);

    function isFinalized() external view returns (bool);

    // setup
    function initialize(
        Mode _mode,
        uint32[] calldata _timestamps,
        uint256 _numberOfCards,
        address _artistAddress,
        address _affiliateAddress,
        address[] calldata _cardAffiliateAddresses,
        address _marketCreatorAddress,
        string calldata _realitioQuestion,
        uint256 _nftsToAward
    ) external;

    function transferCard(
        address _oldOwner,
        address _newOwner,
        uint256 _token,
        uint256 _price,
        uint256 _timeLimit
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./IRCTreasury.sol";

interface IRCOrderbook {
    struct Bid {
        address market;
        address next;
        address prev;
        uint64 card;
        uint128 price;
        uint64 timeHeldLimit;
    }

    function index(
        address _market,
        address _user,
        uint256 _token
    ) external view returns (uint256);

    function ownerOf(address, uint256) external view returns (address);

    function closedMarkets(uint256) external view returns (address);

    function userClosedMarketIndex(address) external view returns (uint256);

    function treasury() external view returns (IRCTreasury);

    function maxSearchIterations() external view returns (uint256);

    function maxDeletions() external view returns (uint256);

    function cleaningLoops() external view returns (uint256);

    function marketCloseLimit() external view returns (uint256);

    function nonce() external view returns (uint256);

    function cleanWastePile() external;

    function getBid(
        address _market,
        address _user,
        uint256 _card
    ) external view returns (Bid memory);

    function setTreasuryAddress(address _newTreasury) external;

    function addBidToOrderbook(
        address _user,
        uint256 _token,
        uint256 _price,
        uint256 _timeHeldLimit,
        address _prevUserAddress
    ) external;

    function removeBidFromOrderbook(address _user, uint256 _token) external;

    function closeMarket() external returns (bool);

    function findNewOwner(uint256 _token, uint256 _timeOwnershipChanged)
        external;

    function getBidValue(address _user, uint256 _token)
        external
        view
        returns (uint256);

    function getTimeHeldlimit(address _user, uint256 _token)
        external
        returns (uint256);

    function bidExists(
        address _user,
        address _market,
        uint256 _card
    ) external view returns (bool);

    function setTimeHeldlimit(
        address _user,
        uint256 _token,
        uint256 _timeHeldLimit
    ) external;

    function removeUserFromOrderbook(address _user) external;

    function removeOldBids(address _user) external;

    function reduceTimeHeldLimit(
        address _user,
        uint256 _token,
        uint256 _timeToReduce
    ) external;

    function setDeletionLimit(uint256 _deletionLimit) external;

    function setCleaningLimit(uint256 _cleaningLimit) external;

    function setSearchLimit(uint256 _searchLimit) external;

    function setMarketCloseLimit(uint256 _marketCloseLimit) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IRCNftHubL2 {
    function marketTracker(uint256) external view returns (address);

    function ownerOf(uint256) external view returns (address);

    function tokenURI(uint256) external view returns (string memory);

    function totalSupply() external view returns (uint256 nftCount);

    function mint(
        address,
        uint256,
        string calldata
    ) external;

    function transferNft(
        address,
        address,
        uint256
    ) external;

    function deposit(address user, bytes calldata depositData) external;

    function withdraw(uint256 tokenId) external;

    function withdrawWithMetadata(uint256 tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./IRealitio.sol";
import "./IRCTreasury.sol";
import "./IRCMarket.sol";
import "./IRCNftHubL2.sol";
import "./IRCOrderbook.sol";
import "./IRCLeaderboard.sol";

interface IRCFactory {
    function createMarket(
        uint32 _mode,
        string memory _ipfsHash,
        string memory _slug,
        uint32[] memory _timestamps,
        string[] memory _tokenURIs,
        address _artistAddress,
        address _affiliateAddress,
        address[] memory _cardAffiliateAddresses,
        string calldata _realitioQuestion,
        uint256 _sponsorship
    ) external returns (address);

    function mintCopyOfNFT(address _user, uint256 _tokenId) external;

    // view functions

    function getMarketSettings()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        );

    function nfthub() external view returns (IRCNftHubL2);

    function ipfsHash(address) external view returns (string memory);

    function slugToAddress(string memory) external view returns (address);

    function addressToSlug(address) external view returns (string memory);

    function treasury() external view returns (IRCTreasury);

    function orderbook() external view returns (IRCOrderbook);

    function leaderboard() external view returns (IRCLeaderboard);

    function realitio() external view returns (IRealitio);

    function getAllMarkets(IRCMarket.Mode _mode)
        external
        view
        returns (address[] memory);

    function getMostRecentMarket(IRCMarket.Mode _mode)
        external
        view
        returns (address);

    function referenceContractAddress() external view returns (address);

    function referenceContractVersion() external view returns (uint256);

    function sponsorshipRequired() external view returns (uint256);

    function advancedWarning() external view returns (uint32);

    function maximumDuration() external view returns (uint32);

    function minimumDuration() external view returns (uint32);

    function marketCreationGovernorsOnly() external view returns (bool);

    function approvedAffiliatesOnly() external view returns (bool);

    function approvedArtistsOnly() external view returns (bool);

    function arbitrator() external view returns (address);

    function timeout() external view returns (uint32);

    function cardLimit() external view returns (uint256);

    function getPotDistribution() external view returns (uint256[5] memory);

    function minimumPriceIncreasePercent() external view returns (uint256);

    function nftsToAward() external view returns (uint256);

    function isMarketApproved(address) external view returns (bool);

    function marketPausedDefaultState() external view returns (bool);

    function mintMarketNFT(uint256 _card) external;

    function getOracleSettings()
        external
        view
        returns (
            IRealitio oracle,
            address arbitratorAddress,
            uint32 _timeout
        );

    // only Governors
    function changeMarketApproval(address _market) external;

    function addArtist(address _newArtist) external;

    function removeArtist(address _oldArtist) external;

    function addAffiliate(address _newAffiliate) external;

    function removeAffiliate(address _oldAffiliate) external;

    // only Owner
    function setLimitNFTsToWinners(bool _limitEnabled) external;

    function setMarketPausedDefaultState(bool _state) external;

    function setTimeout(uint32 _newTimeout) external;

    function setMaxRentIterations(uint256 _rentLimit, uint256 _rentLimitLocking)
        external;

    function setArbitrator(address _newAddress) external;

    function setRealitioAddress(address _newAddress) external;

    function maxRentIterations() external view returns (uint256);

    function maxRentIterationsToLockMarket() external view returns (uint256);

    function setCardLimit(uint256 _cardLimit) external;

    function setMinimumPriceIncreasePercent(uint256 _percentIncrease) external;

    function setNumberOfNFTsToAward(uint256 _NFTsToAward) external;

    function updateTokenURI(
        address _market,
        uint256 _cardId,
        string calldata _newTokenURI,
        string calldata _newCopyTokenURI
    ) external;

    function setPotDistribution(
        uint256 _artistCut,
        uint256 _winnerCut,
        uint256 _creatorCut,
        uint256 _affiliateCut,
        uint256 _cardAffiliateCut
    ) external;

    function changeMarketCreationGovernorsOnly() external;

    function changeApprovedArtistsOnly() external;

    function changeApprovedAffiliatesOnly() external;

    function setSponsorshipRequired(uint256 _amount) external;

    function setMarketTimeRestrictions(
        uint32 _newAdvancedWarning,
        uint32 _newMinimumDuration,
        uint32 _newMaximumDuration
    ) external;

    // only UberOwner
    function setReferenceContractAddress(address _newAddress) external;

    function setOrderbookAddress(IRCOrderbook _newAddress) external;

    function setLeaderboardAddress(IRCLeaderboard _newAddress) external;

    function setNftHubAddress(IRCNftHubL2 _newAddress) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IRCBridge {
    function withdrawToMainnet(address _user, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;
    uint256 private cachedChainId;
    string private cachedName;
    string private cachedVersion;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name, string memory version)
        internal
        initializer
    {
        cachedChainId = getChainId();
        cachedName = name;
        cachedVersion = version;
        _setDomainSeperator(name, version);
    }

    function _setDomainSeperator(string memory name, string memory version)
        internal
    {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        if (getChainId() == cachedChainId) {
            return domainSeperator;
        } else {
            return
                keccak256(
                    abi.encode(
                        EIP712_DOMAIN_TYPEHASH,
                        keccak256(bytes(cachedName)),
                        keccak256(bytes(cachedVersion)),
                        address(this),
                        bytes32(getChainId())
                    )
                );
        }
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./IRCTreasury.sol";
import "./IRCMarket.sol";

interface IRCLeaderboard {
    function treasury() external view returns (IRCTreasury);

    function NFTsToAward(address _market) external view returns (uint256);

    function setTreasuryAddress(address _newTreasury) external;

    function updateLeaderboard(
        address _user,
        uint256 _card,
        uint256 _timeHeld
    ) external;

    function claimNFT(address _user, uint256 _card) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

/// @title Realit.io contract interface
interface IRealitio {
    function askQuestion(
        uint256 template_id,
        string calldata question,
        address arbitrator,
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce
    ) external payable returns (bytes32);

    function resultFor(bytes32 question_id) external view returns (bytes32);

    function isFinalized(bytes32 question_id) external view returns (bool);

    function getContentHash(bytes32 question_id)
        external
        view
        returns (bytes32);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}