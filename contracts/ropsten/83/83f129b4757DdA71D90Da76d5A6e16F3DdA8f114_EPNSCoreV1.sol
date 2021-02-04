pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

//import "hardhat/console.sol";

interface ILendingPoolAddressesProvider {
    function getLendingPoolCore() external view returns (address payable);

    function getLendingPool() external view returns (address);
}

interface ILendingPool {
    function addressesProvider() external view returns (address);

    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;

    function redeemUnderlying(
        address _reserve,
        address _user,
        uint256 _amount
    ) external;

    function borrow(
        address _reserve,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode
    ) external;

    function repay(
        address _reserve,
        uint256 _amount,
        address _onBehalfOf
    ) external payable;

    function swapBorrowRateMode(address _reserve) external;

    function rebalanceFixedBorrowRate(address _reserve, address _user) external;

    function setUserUseReserveAsCollateral(
        address _reserve,
        bool _useAsCollateral
    ) external;

    function liquidationCall(
        address _collateral,
        address _reserve,
        address _user,
        uint256 _purchaseAmount,
        bool _receiveAToken
    ) external payable;

    function flashLoan(
        address _receiver,
        address _reserve,
        uint256 _amount,
        bytes calldata _params
    ) external;

    function getReserveConfigurationData(address _reserve)
        external
        view
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationDiscount,
            address interestRateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool fixedBorrowRateEnabled,
            bool isActive
        );

    function getReserveData(address _reserve)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsFixed,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 fixedBorrowRate,
            uint256 averageFixedBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            address aTokenAddress,
            uint40 lastUpdateTimestamp
        );

    function getUserAccountData(address _user)
        external
        view
        returns (
            uint256 totalLiquidityETH,
            uint256 totalCollateralETH,
            uint256 totalBorrowsETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserReserveData(address _reserve, address _user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentUnderlyingBalance,
            uint256 currentBorrowBalance,
            uint256 principalBorrowBalance,
            uint256 borrowRateMode,
            uint256 borrowRate,
            uint256 liquidityRate,
            uint256 originationFee,
            uint256 variableBorrowIndex,
            uint256 lastUpdateTimestamp,
            bool usageAsCollateralEnabled
        );

    function getReserves() external view;
}

interface IEPNSCore {}

contract EPNSCoreV1 is Initializable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ***************
     * DEFINE ENUMS AND CONSTANTS
     *************** */
    // For Message Type
    enum ChannelType {
        ProtocolNonInterest,
        ProtocolPromotion,
        InterestBearingOpen,
        InterestBearingMutual
    }
    enum ChannelAction {ChannelRemoved, ChannelAdded, ChannelUpdated}
    enum SubscriberAction {
        SubscriberRemoved,
        SubscriberAdded,
        SubscriberUpdated
    }

    /* ***************
    // DEFINE STRUCTURES AND VARIABLES
    *************** */

    /* Users are everyone in the EPNS Ecosystem
     * the struct creates a registry for public key signing and maintains the users subscribed channels
     */
    struct User {
        bool userActivated; // Whether a user is activated or not
        bool publicKeyRegistered; // Will be false until public key is emitted
        bool channellized; // Marks if a user has opened a channel
        uint256 userStartBlock; // Events should not be polled before this block as user doesn't exist
        uint256 subscribedCount; // Keep track of subscribers
        uint256 timeWeightedBalance;
        // keep track of all subscribed channels
        mapping(address => uint256) subscribed;
        mapping(uint256 => address) mapAddressSubscribed;
        // keep track of greylist, useful for unsubscribe so the channel can't subscribe you back
        mapping(address => bool) graylistedChannels;
    }

    /* Channels are addresses who have wants their broadcasting network,
     * the channel can never go back to being a plain user but can be marked inactive
     */
    struct Channel {
        // Channel Type
        ChannelType channelType;
        // Flag to deactive channel
        bool deactivated;
        // Channel Pool Contribution
        uint256 poolContribution;
        uint256 memberCount;
        uint256 channelHistoricalZ;
        uint256 channelFairShareCount;
        uint256 channelLastUpdate; // The last update block number, used to calculate fair share
        // To calculate fair share of profit from the pool of channels generating interest
        uint256 channelStartBlock; // Helps in defining when channel started for pool and profit calculation
        uint256 channelUpdateBlock; // Helps in outlining when channel was updated
        uint256 channelWeight; // The individual weight to be applied as per pool contribution
        // To keep track of subscribers info
        mapping(address => bool) memberExists;
        // For iterable mapping
        mapping(address => uint256) members;
        mapping(uint256 => address) mapAddressMember; // This maps to the user
        // To calculate fair share of profit for a subscriber
        // The historical constant that is applied with (wnx0 + wnx1 + .... + wnxZ)
        // Read more in the repo: https://github.com/ethereum-push-notification-system
        mapping(address => uint256) memberLastUpdate;
    }

    /* Create for testnet strict owner only channel whitelist
     * Will not be available on mainnet since that has real defi involed, use staging contract
     * for developers looking to try on hand
     */
    mapping(address => bool) channelizationWhitelist;

    // To keep track of channels
    mapping(address => Channel) public channels;
    mapping(uint256 => address) public mapAddressChannels;

    // To keep a track of all users
    mapping(address => User) public users;
    mapping(uint256 => address) public mapAddressUsers;

    // To keep track of interest claimed and interest in wallet
    mapping(address => uint256) public usersInterestClaimed;
    mapping(address => uint256) public usersInterestInWallet;

    /**
        Address Lists
    */
    address public lendingPoolProviderAddress;
    address public daiAddress;
    address public aDaiAddress;
    address public governance;

    // Track assetCounts
    uint256 public channelsCount;
    uint256 public usersCount;

    // Helper for calculating fair share of pool, group are all channels, renamed to avoid confusion
    uint256 public groupNormalizedWeight;
    uint256 public groupHistoricalZ;
    uint256 public groupLastUpdate;
    uint256 public groupFairShareCount;

    /*
        For maintaining the #DeFi finances
    */
    uint256 public poolFunds;
    uint256 public ownerDaiFunds;

    uint256 public REFERRAL_CODE;

    uint256 ADD_CHANNEL_MAX_POOL_CONTRIBUTION;

    uint256 DELEGATED_CONTRACT_FEES;

    uint256 ADJUST_FOR_FLOAT;
    uint256 ADD_CHANNEL_MIN_POOL_CONTRIBUTION;

    /* ***************
     * Events
     *************** */
    // For Public Key Registration Emit
    event PublicKeyRegistered(address indexed owner, bytes publickey);

    // Channel Related | // This Event is listened by on All Infra Services
    event AddChannel(
        address indexed channel,
        ChannelType indexed channelType,
        bytes identity
    );
    event UpdateChannel(address indexed channel, bytes identity);
    event DeactivateChannel(address indexed channel);

    // Subscribe / Unsubscribe | This Event is listened by on All Infra Services
    event Subscribe(address indexed channel, address indexed user);
    event Unsubscribe(address indexed channel, address indexed user);

    // Send Notification | This Event is listened by on All Infra Services
    event SendNotification(
        address indexed channel,
        address indexed recipient,
        bytes identity
    );

    // Emit Claimed Interest
    event InterestClaimed(address indexed user, uint256 indexed amount);

    // Withdrawl Related
    event Donation(address indexed donator, uint256 amt);
    event Withdrawal(address indexed to, address token, uint256 amount);

    //    function getRevision() internal override pure returns (uint256) {
    //        return 1;
    //    }

    /* ***************
     * INITIALIZER,
     *************** */

    function initialize(
        address _governance,
        address _lendingPoolProviderAddress,
        address _daiAddress,
        address _aDaiAddress,
        uint256 _referralCode
    ) public initializer returns (bool success) {
        // setup addresses
        governance = _governance; // multisig/timelock, also controls the proxy
        lendingPoolProviderAddress = _lendingPoolProviderAddress;
        daiAddress = _daiAddress;
        aDaiAddress = _aDaiAddress;
        REFERRAL_CODE = _referralCode;

        DELEGATED_CONTRACT_FEES = 1 * 10**17; // 0.1 DAI to perform any delegate call

        ADD_CHANNEL_MIN_POOL_CONTRIBUTION = 50 * 10**18; // 50 DAI or above to create the channel
        ADD_CHANNEL_MAX_POOL_CONTRIBUTION = 250000 * 50 * 10**18; // 250k DAI or below, we don't want channel to make a costly mistake as well

        groupLastUpdate = block.number;
        groupNormalizedWeight = ADJUST_FOR_FLOAT; // Always Starts with 1 * ADJUST FOR FLOAT

        ADJUST_FOR_FLOAT = 10**7; // TODO: checkout dsmath
        channelsCount = 0;
        usersCount = 0;

        // Helper for calculating fair share of pool, group are all channels, renamed to avoid confusion
        groupNormalizedWeight = 0;
        groupHistoricalZ = 0; // Abbre
        groupLastUpdate = 0; // The last update block number, used to calculate fair share
        groupFairShareCount = 0; // They are alias to channels count but seperating them for brevity

        /*
        For maintaining the #DeFi finances
        */
        poolFunds = 0; // Always in DAI
        ownerDaiFunds = 0;

        // Add EPNS Channels
        // First is for all users
        // Second is all channel alerter, amount deposited for both is 0
        // to save gas, emit both the events out
        // identity = payloadtype + payloadhash

        // EPNS ALL USERS
        emit AddChannel(
            governance,
            ChannelType.ProtocolNonInterest,
            "1+QmSbRT16JVF922yAB26YxWFD6DmGsnSHm8VBrGUQnXTS74"
        );
        _createChannel(governance, ChannelType.ProtocolNonInterest, 0); // should the owner of the contract be the channel? should it be governance in this case?

        // EPNS ALERTER CHANNEL
        emit AddChannel(
            0x0000000000000000000000000000000000000000,
            ChannelType.ProtocolNonInterest,
            "1+QmTCKYL2HRbwD6nGNvFLe4wPvDNuaYGr6RiVeCvWjVpn5s"
        );
        _createChannel(
            0x0000000000000000000000000000000000000000,
            ChannelType.ProtocolNonInterest,
            0
        );

        // Create Channel
        success = true;
    }

    receive() external payable {}

    fallback() external {
        //console.logString("in fallback of core");
    }

    // Modifiers

    modifier onlyGov() {
        require(
            msg.sender == governance,
            "EPNSCore::onlyGov, user is not governance"
        );
        _;
    }

    /// @dev Testnet only function to check permission from owner
    modifier onlyChannelizationWhitelist(address _addr) {
        require(
            (msg.sender == governance ||
                channelizationWhitelist[_addr] == true),
            "User not in Channelization Whitelist"
        );
        _;
    }

    modifier onlyValidUser(address _addr) {
        require(users[_addr].userActivated == true, "User not activated yet");
        _;
    }

    modifier onlyUserWithNoChannel() {
        require(
            users[msg.sender].channellized == false,
            "User already a Channel Owner"
        );
        _;
    }

    modifier onlyValidChannel(address _channel) {
        require(users[_channel].channellized == true, "Channel doesn't Exists");
        _;
    }

    modifier onlyActivatedChannels(address _channel) {
        require(
            users[_channel].channellized == true &&
                channels[_channel].deactivated == false,
            "Channel deactivated or doesn't exists"
        );
        _;
    }

    modifier onlyChannelOwner(address _channel) {
        require(
            ((users[_channel].channellized == true && msg.sender == _channel) ||
                (msg.sender == governance &&
                    _channel == 0x0000000000000000000000000000000000000000)),
            "Channel doesn't Exists"
        );
        _;
    }

    modifier onlyUserAllowedChannelType(ChannelType _channelType) {
        require(
            (_channelType == ChannelType.InterestBearingOpen ||
                _channelType == ChannelType.InterestBearingMutual),
            "Channel Type Invalid"
        );

        _;
    }

    modifier onlySubscribed(address _channel, address _subscriber) {
        require(
            channels[_channel].memberExists[_subscriber] == true,
            "Subscriber doesn't Exists"
        );
        _;
    }

    modifier onlyNonOwnerSubscribed(address _channel, address _subscriber) {
        require(
            _channel != _subscriber &&
                channels[_channel].memberExists[_subscriber] == true,
            "Either Channel Owner or Not Subscribed"
        );
        _;
    }

    modifier onlyNonSubscribed(address _channel, address _subscriber) {
        require(
            channels[_channel].memberExists[_subscriber] == false,
            "Subscriber already Exists"
        );
        _;
    }

    modifier onlyNonGraylistedChannel(address _channel, address _user) {
        require(
            users[_user].graylistedChannels[_channel] == false,
            "Channel is graylisted"
        );
        _;
    }

    function transferGovernance(address _newGovernance) public onlyGov {
        require(
            _newGovernance != address(0),
            "EPNSCore::transferGovernance, new governance can't be none"
        );
        require(
            _newGovernance != governance,
            "EPNSCore::transferGovernance, new governance can't be current governance"
        );
        governance = _newGovernance;
    }

    /// @dev Testnet only function to enable owner permission for channelizationWhitelist addition
    function addToChannelizationWhitelist(address _addr) external onlyGov {
        channelizationWhitelist[_addr] = true;
    }

    /// @dev Testnet only function  to enable owner permission for channelizationWhitelist removal
    function removeFromChannelizationWhitelist(address _addr) external onlyGov {
        channelizationWhitelist[_addr] = false;
    }

    /// @dev Performs action by the user themself to broadcast their public key
    function broadcastUserPublicKey(bytes calldata _publicKey) external {
        // Will save gas
        if (users[msg.sender].publicKeyRegistered == true) {
            // Nothing to do, user already registered
            return;
        }

        // broadcast it
        _broadcastPublicKey(msg.sender, _publicKey);
    }

    /// @dev Create channel with fees and public key
    function createChannelWithFeesAndPublicKey(
        ChannelType _channelType,
        bytes calldata _identity,
        bytes calldata _publickey
    )
        external
        onlyUserWithNoChannel
        onlyUserAllowedChannelType(_channelType)
        onlyChannelizationWhitelist(msg.sender)
    {
        // Save gas, Emit the event out
        emit AddChannel(msg.sender, _channelType, _identity);

        // Broadcast public key
        // @TODO Find a way to save cost

        // Will save gas
        if (users[msg.sender].publicKeyRegistered == false) {
            _broadcastPublicKey(msg.sender, _publickey);
        }

        // Bubble down to create channel
        _createChannelWithFees(msg.sender, _channelType);
    }

    /// @dev Create channel with fees
    function createChannelWithFees(
        ChannelType _channelType,
        bytes calldata _identity
    )
        external
        onlyUserWithNoChannel
        onlyUserAllowedChannelType(_channelType)
        onlyChannelizationWhitelist(msg.sender)
    {
        // Save gas, Emit the event out
        emit AddChannel(msg.sender, _channelType, _identity);

        // Bubble down to create channel
        _createChannelWithFees(msg.sender, _channelType);
    }

    /// @dev One time, Create Promoter Channel
    function createPromoterChannel() external {
        // EPNS PROMOTER CHANNEL
        require(
            users[address(this)].channellized == false,
            "Contract has Promoter"
        );

        // NEED TO HAVE ALLOWANCE OF MINIMUM DAI
        IERC20Upgradeable(daiAddress).approve(
            address(this),
            ADD_CHANNEL_MIN_POOL_CONTRIBUTION
        );

        // Check if it's equal or above Channel Pool Contribution
        require(
            IERC20Upgradeable(daiAddress).allowance(
                msg.sender,
                address(this)
            ) >= ADD_CHANNEL_MIN_POOL_CONTRIBUTION,
            "Insufficient Funds"
        );

        // Check and transfer funds
        IERC20Upgradeable(daiAddress).transferFrom(
            msg.sender,
            address(this),
            ADD_CHANNEL_MIN_POOL_CONTRIBUTION
        );

        // Then Add Promoter Channel
        emit AddChannel(
            address(this),
            ChannelType.ProtocolPromotion,
            "1+QmRcewnNpdt2DWYuud3LxHTwox2RqQ8uyZWDJ6eY6iHkfn"
        );

        // Call create channel after fees transfer
        _createChannelAfterTransferOfFees(
            address(this),
            ChannelType.ProtocolPromotion,
            ADD_CHANNEL_MIN_POOL_CONTRIBUTION
        );
    }

    /// @dev To update channel, only possible if 1 subscriber is present or this is governance
    function updateChannelMeta(address _channel, bytes calldata _identity)
        external
    {
        emit UpdateChannel(_channel, _identity);

        _updateChannelMeta(_channel);
    }

    /// @dev Deactivate channel
    function deactivateChannel() external onlyActivatedChannels(msg.sender) {
        channels[msg.sender].deactivated = true;
    }

    /// @dev delegate subscription to channel
    function subscribeWithPublicKeyDelegated(
        address _channel,
        address _user,
        bytes calldata _publicKey
    )
        external
        onlyActivatedChannels(_channel)
        onlyNonGraylistedChannel(_channel, _user)
    {
        // Take delegation fees
        _takeDelegationFees();

        // Will save gas as it prevents calldata to be copied unless need be
        if (users[_user].publicKeyRegistered == false) {
            // broadcast it
            _broadcastPublicKey(msg.sender, _publicKey);
        }

        // Call actual subscribe
        _subscribe(_channel, _user);
    }

    /// @dev subscribe to channel delegated
    function subscribeDelegated(address _channel, address _user)
        external
        onlyActivatedChannels(_channel)
        onlyNonGraylistedChannel(_channel, _user)
    {
        // Take delegation fees
        _takeDelegationFees();

        // Call actual subscribe
        _subscribe(_channel, _user);
    }

    function myMood() public pure returns (string memory) {
        return ("am happy");
    }

    /// @dev subscribe to channel with public key
    function subscribeWithPublicKey(address _channel, bytes calldata _publicKey)
        external
        onlyActivatedChannels(_channel)
    {
        // Will save gas as it prevents calldata to be copied unless need be
        if (users[msg.sender].publicKeyRegistered == false) {
            // broadcast it
            _broadcastPublicKey(msg.sender, _publicKey);
        }

        // Call actual subscribe
        _subscribe(_channel, msg.sender);
    }

    /// @dev subscribe to channel
    function subscribe(address _channel)
        external
        onlyActivatedChannels(_channel)
    {
        // Call actual subscribe
        _subscribe(_channel, msg.sender);
    }

    /// @dev to unsubscribe from channel
    function unsubscribe(address _channel)
        external
        onlyValidChannel(_channel)
        onlyNonOwnerSubscribed(_channel, msg.sender)
        returns (uint256 ratio)
    {
        // Add the channel to gray list so that it can't subscriber the user again as delegated
        User storage user = users[msg.sender];

        // Treat it as graylisting
        user.graylistedChannels[_channel] = true;

        // first get ratio of earning
        ratio = 0;
        ratio = calcSingleChannelEarnRatio(_channel, msg.sender, block.number);

        // Take the fair share out

        // Remove the mappings and cleanup
        // a bit tricky, swap and delete to maintain mapping
        // Remove From Users mapping
        // Find the id of the channel and swap it with the last id, use channel.memberCount as index
        // Slack too deep fix
        // address usrSubToSwapAdrr = user.mapAddressSubscribed[user.subscribedCount];
        // uint usrSubSwapID = user.subscribed[_channel];

        // // swap to last one and then
        // user.subscribed[usrSubToSwapAdrr] = usrSubSwapID;
        // user.mapAddressSubscribed[usrSubSwapID] = usrSubToSwapAdrr;

        user.subscribed[user.mapAddressSubscribed[user.subscribedCount]] = user
            .subscribed[_channel];
        user.mapAddressSubscribed[user.subscribed[_channel]] = user
            .mapAddressSubscribed[user.subscribedCount];

        // delete the last one and substract
        delete (user.subscribed[_channel]);
        delete (user.mapAddressSubscribed[user.subscribedCount]);
        user.subscribedCount = user.subscribedCount.sub(1);

        // Remove from Channels mapping
        Channel storage channel = channels[_channel];

        // Set additional flag to false
        channel.memberExists[msg.sender] = false;

        // Find the id of the channel and swap it with the last id, use channel.memberCount as index
        // Slack too deep fix
        // address chnMemToSwapAdrr = channel.mapAddressMember[channel.memberCount];
        // uint chnMemSwapID = channel.members[msg.sender];

        // swap to last one and then
        channel.members[channel.mapAddressMember[channel.memberCount]] = channel
            .members[msg.sender];
        channel.mapAddressMember[channel.members[msg.sender]] = channel
            .mapAddressMember[channel.memberCount];

        // delete the last one and substract
        delete (channel.members[msg.sender]);
        delete (channel.mapAddressMember[channel.memberCount]);
        channel.memberCount = channel.memberCount.sub(1);

        // Next readjust fair share
        (
            channels[_channel].channelFairShareCount,
            channels[_channel].channelHistoricalZ,
            channels[_channel].channelLastUpdate
        ) = _readjustFairShareOfSubscribers(
            SubscriberAction.SubscriberRemoved,
            channels[_channel].channelFairShareCount,
            channels[_channel].channelHistoricalZ,
            channels[_channel].channelLastUpdate
        );

        // Next calculate and send the fair share earning of the user from this channel
        if (
            channel.channelType == ChannelType.ProtocolPromotion ||
            channel.channelType == ChannelType.InterestBearingOpen ||
            channel.channelType == ChannelType.InterestBearingMutual
        ) {
            _withdrawFundsFromPool(ratio);
        }

        // Emit it
        emit Unsubscribe(_channel, msg.sender);
    }

    /// @dev to claim fair share of all earnings
    function claimFairShare()
        external
        onlyValidUser(msg.sender)
        returns (uint256 ratio)
    {
        // Calculate entire FS Share, since we are looping for reset... let's calculate over there
        ratio = 0;

        // Reset member last update for every channel that are interest bearing
        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = 0; i < users[msg.sender].subscribedCount; i++) {
            address channel = users[msg.sender].mapAddressSubscribed[i];

            if (
                channels[channel].channelType ==
                ChannelType.ProtocolPromotion ||
                channels[channel].channelType ==
                ChannelType.InterestBearingOpen ||
                channels[channel].channelType ==
                ChannelType.InterestBearingMutual
            ) {
                // Reset last updated block
                channels[channel].memberLastUpdate[msg.sender] = block.number;

                // Next readjust fair share and that's it
                (
                    channels[channel].channelFairShareCount,
                    channels[channel].channelHistoricalZ,
                    channels[channel].channelLastUpdate
                ) = _readjustFairShareOfSubscribers(
                    SubscriberAction.SubscriberUpdated,
                    channels[channel].channelFairShareCount,
                    channels[channel].channelHistoricalZ,
                    channels[channel].channelLastUpdate
                );

                // Calculate share
                uint256 individualChannelShare =
                    calcSingleChannelEarnRatio(
                        channel,
                        msg.sender,
                        block.number
                    );
                ratio = ratio.add(individualChannelShare);
            }
        }
        // Finally, withdraw for user
        _withdrawFundsFromPool(ratio);
    }

    /* @dev to send message to reciepient of a group, the first digit of msg type contains rhe push server flag
     ** So msg type 1 with using push is 11, without push is 10, in the future this can also be 12 (silent push)
     */
    function sendNotification(address _recipient, bytes calldata _identity)
        external
        onlyChannelOwner(msg.sender)
    {
        // Just check if the msg is a secret, if so the user public key should be in the system
        // On second thought, leave it upon the channel, they might have used an alternate way to
        // encrypt the message using the public key

        // Emit the message out
        emit SendNotification(msg.sender, _recipient, _identity);
    }

    /// @dev to send message to reciepient of a group
    function sendNotificationOverrideChannel(
        address _channel,
        address _recipient,
        bytes calldata _identity
    ) external onlyChannelOwner(msg.sender) onlyGov {
        // Emit the message out
        emit SendNotification(_channel, _recipient, _identity);
    }

    /// @dev to withraw funds coming from delegate fees
    function withdrawDaiFunds() external onlyGov {
        // Get and transfer funds
        uint256 funds = ownerDaiFunds;
        IERC20Upgradeable(daiAddress).safeTransferFrom(
            address(this),
            msg.sender,
            funds
        );

        // Rest funds to 0
        ownerDaiFunds = 0;

        // Emit Evenet
        emit Withdrawal(msg.sender, daiAddress, funds);
    }

    /// @dev to withraw funds coming from donate
    function withdrawEthFunds() external onlyGov {
        uint256 bal = address(this).balance;

        payable(governance).transfer(bal);

        // Emit Event
        emit Withdrawal(msg.sender, daiAddress, bal);
    }

    /// @dev To check if member exists
    function memberExists(address _user, address _channel)
        external
        view
        returns (bool subscribed)
    {
        subscribed = channels[_channel].memberExists[_user];
    }

    /// @dev To fetch subscriber address for a channel
    function getChannelSubscriberAddress(
        address _channel,
        uint256 _subscriberId
    ) external view returns (address subscriber) {
        subscriber = channels[_channel].mapAddressMember[_subscriberId];
    }

    /// @dev To fetch user id for a subscriber of a channel
    function getChannelSubscriberUserID(address _channel, uint256 _subscriberId)
        external
        view
        returns (uint256 userId)
    {
        userId = channels[_channel].members[
            channels[_channel].mapAddressMember[_subscriberId]
        ];
    }

    /// @dev donate functionality for the smart contract
    function donate() public payable {
        require(
            msg.value >= 0.001 ether,
            "Minimum Donation amount is 0.001 ether"
        );

        // Emit Event
        emit Donation(msg.sender, msg.value);
    }

    /// @dev to get channel fair share ratio for a given block
    function getChannelFSRatio(address _channel, uint256 _block)
        public
        view
        returns (uint256 ratio)
    {
        // formula is ratio = da / z + (nxw)
        // d is the difference of blocks from given block and the last update block of the entire group
        // a is the actual weight of that specific group
        // z is the historical constant
        // n is the number of channels
        // x is the difference of blocks from given block and the last changed start block of group
        // w is the normalized weight of the groups
        uint256 d = _block.sub(channels[_channel].channelStartBlock); // _block.sub(groupLastUpdate);
        uint256 a = channels[_channel].channelWeight;
        uint256 z = groupHistoricalZ;
        uint256 n = groupFairShareCount;
        uint256 x = _block.sub(groupLastUpdate);
        uint256 w = groupNormalizedWeight;

        uint256 nxw = n.mul(x.mul(w));
        uint256 z_nxw = z.add(nxw);
        uint256 da = d.mul(a);

        ratio = (da.mul(ADJUST_FOR_FLOAT)).div(z_nxw);
    }

    /// @dev to get subscriber fair share ratio for a given channel at a block
    function getSubscriberFSRatio(
        address _channel,
        address _user,
        uint256 _block
    ) public view onlySubscribed(_channel, _user) returns (uint256 ratio) {
        // formula is ratio = d / z + (nx)
        // d is the difference of blocks from given block and the start block of subscriber
        // z is the historical constant
        // n is the number of subscribers of channel
        // x is the difference of blocks from given block and the last changed start block of channel

        uint256 d = _block.sub(channels[_channel].memberLastUpdate[_user]);
        uint256 z = channels[_channel].channelHistoricalZ;
        uint256 x = _block.sub(channels[_channel].channelLastUpdate);

        uint256 nx = channels[_channel].channelFairShareCount.mul(x);

        ratio = (d.mul(ADJUST_FOR_FLOAT)).div(z.add(nx)); // == d / z + n * x
    }

    /* @dev to get the fair share of user for a single channel, different from subscriber fair share
     * as it's multiplication of channel fair share with subscriber fair share
     */
    function calcSingleChannelEarnRatio(
        address _channel,
        address _user,
        uint256 _block
    ) public view onlySubscribed(_channel, _user) returns (uint256 ratio) {
        // First get the channel fair share
        if (
            channels[_channel].channelType == ChannelType.ProtocolPromotion ||
            channels[_channel].channelType == ChannelType.InterestBearingOpen ||
            channels[_channel].channelType == ChannelType.InterestBearingMutual
        ) {
            uint256 channelFS = getChannelFSRatio(_channel, _block);
            uint256 subscriberFS =
                getSubscriberFSRatio(_channel, _user, _block);

            ratio = channelFS.mul(subscriberFS).div(ADJUST_FOR_FLOAT);
        }
    }

    /// @dev to get the fair share of user overall
    function calcAllChannelsRatio(address _user, uint256 _block)
        public
        view
        onlyValidUser(_user)
        returns (uint256 ratio)
    {
        // loop all channels for the user
        uint256 subscribedCount = users[_user].subscribedCount;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = 0; i < subscribedCount; i++) {
            if (
                channels[users[_user].mapAddressSubscribed[i]].channelType ==
                ChannelType.ProtocolPromotion ||
                channels[users[_user].mapAddressSubscribed[i]].channelType ==
                ChannelType.InterestBearingOpen ||
                channels[users[_user].mapAddressSubscribed[i]].channelType ==
                ChannelType.InterestBearingMutual
            ) {
                uint256 individualChannelShare =
                    calcSingleChannelEarnRatio(
                        users[_user].mapAddressSubscribed[i],
                        _user,
                        _block
                    );
                ratio = ratio.add(individualChannelShare);
            }
        }
    }

    /// @dev Add the user to the ecosystem if they don't exists, the returned response is used to deliver a message to the user if they are recently added
    function _addUser(address _addr) private returns (bool userAlreadyAdded) {
        if (users[_addr].userActivated) {
            userAlreadyAdded = true;
        } else {
            // Activates the user
            users[_addr].userStartBlock = block.number;
            users[_addr].userActivated = true;
            mapAddressUsers[usersCount] = _addr;

            usersCount = usersCount.add(1);

            // Send Welcome Message, Deprecated
            // emit SendNotification(governance, _addr, EPNS_FIRST_MESSAGE_HASH);
        }
    }

    /* @dev Internal system to handle broadcasting of public key,
     * is a entry point for subscribe, or create channel but is option
     */
    function _broadcastPublicKey(address _userAddr, bytes memory _publicKey)
        private
    {
        // Add the user, will do nothing if added already, but is needed before broadcast
        _addUser(_userAddr);

        // get address from public key
        address userAddr = getWalletFromPublicKey(_publicKey);

        if (_userAddr == userAddr) {
            // Only change it when verification suceeds, else assume the channel just wants to send group message
            users[userAddr].publicKeyRegistered = true;

            // Emit the event out
            emit PublicKeyRegistered(userAddr, _publicKey);
        } else {
            revert("Public Key Validation Failed");
        }
    }

    /// @dev Don't forget to add 0x into it
    function getWalletFromPublicKey(bytes memory _publicKey)
        public
        pure
        returns (address wallet)
    {
        if (_publicKey.length == 64) {
            wallet = address(uint160(uint256(keccak256(_publicKey))));
        } else {
            wallet = 0x0000000000000000000000000000000000000000;
        }
    }

    /// @dev add channel with fees
    function _createChannelWithFees(address _channel, ChannelType _channelType)
        private
    {
        // This module should be completely independent from the private _createChannel() so constructor can do it's magic
        // Get the approved allowance
        uint256 allowedAllowance =
            IERC20Upgradeable(daiAddress).allowance(_channel, address(this));

        // Check if it's equal or above Channel Pool Contribution
        require(
            allowedAllowance >= ADD_CHANNEL_MIN_POOL_CONTRIBUTION &&
                allowedAllowance <= ADD_CHANNEL_MAX_POOL_CONTRIBUTION,
            "Insufficient Funds or max ceiling reached"
        );

        // Check and transfer funds
        IERC20Upgradeable(daiAddress).safeTransferFrom(
            _channel,
            address(this),
            allowedAllowance
        );

        // Call create channel after fees transfer
        _createChannelAfterTransferOfFees(
            _channel,
            _channelType,
            allowedAllowance
        );
    }

    function _createChannelAfterTransferOfFees(
        address _channel,
        ChannelType _channelType,
        uint256 _allowedAllowance
    ) private {
        // Deposit funds to pool
        _depositFundsToPool(_allowedAllowance);

        // Call Create Channel
        _createChannel(_channel, _channelType, _allowedAllowance);
    }

    /// @dev Create channel internal method that runs
    function _createChannel(
        address _channel,
        ChannelType _channelType,
        uint256 _amountDeposited
    ) private {
        // Add the user, will do nothing if added already, but is needed for all outpoints
        bool userAlreadyAdded = _addUser(_channel);

        // Calculate channel weight
        uint256 _channelWeight =
            _amountDeposited.mul(ADJUST_FOR_FLOAT).div(
                ADD_CHANNEL_MIN_POOL_CONTRIBUTION
            );

        // Next create the channel and mark user as channellized
        users[_channel].channellized = true;

        channels[_channel].poolContribution = _amountDeposited;
        channels[_channel].channelType = _channelType;
        channels[_channel].channelStartBlock = block.number;
        channels[_channel].channelUpdateBlock = block.number;
        channels[_channel].channelWeight = _channelWeight;

        // Add to map of addresses and increment channel count
        mapAddressChannels[channelsCount] = _channel;
        channelsCount = channelsCount.add(1);

        // Readjust fair share if interest bearing
        if (
            _channelType == ChannelType.ProtocolPromotion ||
            _channelType == ChannelType.InterestBearingOpen ||
            _channelType == ChannelType.InterestBearingMutual
        ) {
            (
                groupFairShareCount,
                groupNormalizedWeight,
                groupHistoricalZ,
                groupLastUpdate
            ) = _readjustFairShareOfChannels(
                ChannelAction.ChannelAdded,
                _channelWeight,
                groupFairShareCount,
                groupNormalizedWeight,
                groupHistoricalZ,
                groupLastUpdate
            );
        }

        // If this is a new user than subscribe them to EPNS Channel
        if (
            userAlreadyAdded == false &&
            _channel != 0x0000000000000000000000000000000000000000
        ) {
            // Call actual subscribe, owner channel
            _subscribe(governance, _channel);
        }

        // All Channels are subscribed to EPNS Alerter as well, unless it's the EPNS Alerter channel iteself
        if (_channel != 0x0000000000000000000000000000000000000000) {
            _subscribe(0x0000000000000000000000000000000000000000, _channel);
        }

        // Subscribe them to their own channel as well
        if (_channel != governance) {
            _subscribe(_channel, _channel);
        }
    }

    /// @dev private function to update channel meta
    function _updateChannelMeta(address _channel)
        internal
        onlyChannelOwner(_channel)
        onlyActivatedChannels(_channel)
    {
        // check if special channel
        if (
            msg.sender == governance &&
            (_channel == governance ||
                _channel == 0x0000000000000000000000000000000000000000 ||
                _channel == address(this))
        ) {
            // don't do check for 1 as these are special channels
        } else {
            // do check for 1
            require(
                channels[_channel].memberCount == 1,
                "Channel has external subscribers"
            );
        }

        channels[msg.sender].channelUpdateBlock = block.number;
    }

    /// @dev private function that eventually handles the subscribing onlyValidChannel(_channel)
    function _subscribe(address _channel, address _user)
        private
        onlyNonSubscribed(_channel, _user)
    {
        // Add the user, will do nothing if added already, but is needed for all outpoints
        _addUser(_user);

        User storage user = users[_user];
        Channel storage channel = channels[_channel];

        // treat the count as index and update user struct
        user.subscribed[_channel] = user.subscribedCount;
        user.mapAddressSubscribed[user.subscribedCount] = _channel;
        user.subscribedCount = user.subscribedCount.add(1); // Finally increment the subscribed count

        // Do the same for the channel to maintain sync, treat member count as index
        channel.members[_user] = channel.memberCount;
        channel.mapAddressMember[channel.memberCount] = _user;
        channel.memberCount = channel.memberCount.add(1); // Finally increment the member count

        // Set Additional flag for some conditions and set last update of member
        channel.memberLastUpdate[_user] = block.number;
        channel.memberExists[_user] = true;

        // Next readjust fair share and that's it
        (
            channels[_channel].channelFairShareCount,
            channels[_channel].channelHistoricalZ,
            channels[_channel].channelLastUpdate
        ) = _readjustFairShareOfSubscribers(
            SubscriberAction.SubscriberAdded,
            channels[_channel].channelFairShareCount,
            channels[_channel].channelHistoricalZ,
            channels[_channel].channelLastUpdate
        );

        // Emit it
        emit Subscribe(_channel, _user);
    }

    /// @dev charge delegation fee, small enough for serious players but thwarts bad actors
    function _takeDelegationFees() private {
        // Check and transfer funds
        // require( IERC20(daiAddress).safeTransferFrom(msg.sender, address(this), DELEGATED_CONTRACT_FEES), "Insufficient Funds");
        IERC20Upgradeable(daiAddress).safeTransferFrom(
            msg.sender,
            address(this),
            DELEGATED_CONTRACT_FEES
        );

        // Add it to owner kitty
        ownerDaiFunds.add(DELEGATED_CONTRACT_FEES);
    }

    /// @dev deposit funds to pool
    function _depositFundsToPool(uint256 amount) private {
        // Got the funds, add it to the channels dai pool
        poolFunds = poolFunds.add(amount);

        // Next swap it via AAVE for aDAI
        // mainnet address, for other addresses: https://docs.aave.com/developers/developing-on-aave/deployed-contract-instances
        ILendingPoolAddressesProvider provider =
            ILendingPoolAddressesProvider(lendingPoolProviderAddress);
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        IERC20Upgradeable(daiAddress).approve(
            provider.getLendingPoolCore(),
            amount
        );

        // Deposit to AAVE
        lendingPool.deposit(daiAddress, amount, uint16(REFERRAL_CODE)); // set to 0 in constructor presently
    }

    /// @dev withdraw funds from pool
    function _withdrawFundsFromPool(uint256 ratio) private nonReentrant {
        uint256 totalBalanceWithProfit =
            IERC20Upgradeable(aDaiAddress).balanceOf(address(this));

        // // Random for testing
        // uint totalBalanceWithProfit = ((uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 24950) + 50) * 10 ** 19; // 10 times
        // // End Testing

        uint256 totalProfit = totalBalanceWithProfit.sub(poolFunds);
        uint256 userAmount = totalProfit.mul(ratio);

        // adjust poolFunds first
        uint256 userAmountAdjusted = userAmount.div(ADJUST_FOR_FLOAT);
        poolFunds = poolFunds.sub(userAmountAdjusted);

        // Add to interest claimed
        usersInterestClaimed[msg.sender] = usersInterestClaimed[msg.sender].add(
            userAmountAdjusted
        );

        // Finally transfer
        IERC20Upgradeable(aDaiAddress).transfer(msg.sender, userAmountAdjusted);

        // Emit Event
        emit InterestClaimed(msg.sender, userAmountAdjusted);
    }

    /// @dev readjust fair share runs on channel addition, removal or update of channel
    function _readjustFairShareOfChannels(
        ChannelAction _action,
        uint256 _channelWeight,
        uint256 _groupFairShareCount,
        uint256 _groupNormalizedWeight,
        uint256 _groupHistoricalZ,
        uint256 _groupLastUpdate
    )
        private
        view
        returns (
            uint256 groupNewCount,
            uint256 groupNewNormalizedWeight,
            uint256 groupNewHistoricalZ,
            uint256 groupNewLastUpdate
        )
    {
        // readjusts the group count and do deconstruction of weight
        uint256 groupModCount = _groupFairShareCount;
        uint256 prevGroupCount = groupModCount;

        uint256 totalWeight;
        uint256 adjustedNormalizedWeight = _groupNormalizedWeight; //_groupNormalizedWeight;

        // Increment or decrement count based on flag
        if (_action == ChannelAction.ChannelAdded) {
            groupModCount = groupModCount.add(1);

            totalWeight = adjustedNormalizedWeight.mul(prevGroupCount);
            totalWeight = totalWeight.add(_channelWeight);
        } else if (_action == ChannelAction.ChannelRemoved) {
            groupModCount = groupModCount.sub(1);

            totalWeight = adjustedNormalizedWeight.mul(prevGroupCount);
            totalWeight = totalWeight.sub(_channelWeight);
        } else if (_action == ChannelAction.ChannelUpdated) {
            totalWeight = adjustedNormalizedWeight.mul(prevGroupCount.sub(1));
            totalWeight = totalWeight.add(_channelWeight);
        } else {
            revert("Invalid Channel Action");
        }

        // now calculate the historical constant
        // z = z + nxw
        // z is the historical constant
        // n is the previous count of group fair share
        // x is the differential between the latest block and the last update block of the group
        // w is the normalized average of the group (ie, groupA weight is 1 and groupB is 2 then w is (1+2)/2 = 1.5)
        uint256 n = groupModCount;
        uint256 x = block.number.sub(_groupLastUpdate);
        uint256 w = totalWeight.div(groupModCount);
        uint256 z = _groupHistoricalZ;

        uint256 nx = n.mul(x);
        uint256 nxw = nx.mul(w);

        // Save Historical Constant and Update Last Change Block
        z = z.add(nxw);

        if (n == 1) {
            // z should start from here as this is first channel
            z = 0;
        }

        // Update return variables
        groupNewCount = groupModCount;
        groupNewNormalizedWeight = w;
        groupNewHistoricalZ = z;
        groupNewLastUpdate = block.number;
    }

    /// @dev readjust fair share runs on user addition or removal
    function _readjustFairShareOfSubscribers(
        SubscriberAction action,
        uint256 _channelFairShareCount,
        uint256 _channelHistoricalZ,
        uint256 _channelLastUpdate
    )
        private
        view
        returns (
            uint256 channelNewFairShareCount,
            uint256 channelNewHistoricalZ,
            uint256 channelNewLastUpdate
        )
    {
        uint256 channelModCount = _channelFairShareCount;
        uint256 prevChannelCount = channelModCount;

        // Increment or decrement count based on flag
        if (action == SubscriberAction.SubscriberAdded) {
            channelModCount = channelModCount.add(1);
        } else if (action == SubscriberAction.SubscriberRemoved) {
            channelModCount = channelModCount.sub(1);
        } else if (action == SubscriberAction.SubscriberUpdated) {
            // do nothing, it's happening after a reset of subscriber last update count
        } else {
            revert("Invalid Channel Action");
        }

        // to calculate the historical constant
        // z = z + nx
        // z is the historical constant
        // n is the total prevoius subscriber count
        // x is the difference bewtween the last changed block and the current block
        uint256 x = block.number.sub(_channelLastUpdate);
        uint256 nx = prevChannelCount.mul(x);
        uint256 z = _channelHistoricalZ.add(nx);

        // Define Values
        channelNewFairShareCount = channelModCount;
        channelNewHistoricalZ = z;
        channelNewLastUpdate = block.number;
    }
}