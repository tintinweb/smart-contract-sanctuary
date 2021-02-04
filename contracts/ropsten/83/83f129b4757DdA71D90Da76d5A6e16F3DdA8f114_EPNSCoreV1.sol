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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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