// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;

import "./interfaces/ICampaign.sol";
import "./Campaign.sol";
import "./libraries/Ownable.sol";
import "./libraries/Pausable.sol";
import "./libraries/Initializable.sol";
import "./libraries/SafeMath.sol";

contract CampaignFactory is Ownable, Pausable, Initializable {
    using SafeMath for uint256;

    // Percentage of platform fee
    uint256 public platformFeeRate;
    // Address of platform revenue. Platform fee will transfer to it
    address public platformRevenueAddress;
    // Array of created Campaign Address
    address[] public allCampaigns;
    // Mapping from User token. From tokens to array of created Campaign for token
    mapping(address => mapping(IERC20 => address[])) public getCampaigns;

    event IcoCampaignCreated(
        address registedBy,
        address indexed token,
        address indexed campaign,
        uint256 campaignId
    );
    event PlatformFeeChanged(address changer, uint256 fee);
    event PlatformRevenueAddressChanged(
        address changer,
        address newRevenueAddress
    );

    function initialize(uint256 _platformFeeRate, address _revenueAddress)
        public
        initializer
    {
        require(_revenueAddress != address(0), "ICOFactory::ZERO_ADDRESS");
        require(_platformFeeRate < 100, "ICOFactory::OVERFLOW_FEE");
        platformFeeRate = _platformFeeRate;
        platformRevenueAddress = _revenueAddress;
        paused = false;
        owner = msg.sender;

        emit PlatformFeeChanged(msg.sender, _platformFeeRate);
    }

    /**
     * @notice Get platform fee in percent
     * @dev Created campaign call this function for get platform fee
     * @return Return number of platform fee
     */
    function getPlatformFeeRate() external view returns (uint256) {
        return platformFeeRate;
    }

    /**
     * @notice Get platform revenue address
     * @dev All of platform fee will transfer to this address
     * @return Address of Platform Vault
     */
    function getplatformRevenueAddress() external view returns (address) {
        return platformRevenueAddress;
    }

    /**
     * @notice Get the number of all created campaigns
     * @return Return number of created campaigns
     */
    function allCampaignsLength() external view returns (uint256) {
        return allCampaigns.length;
    }

    /**
     * @notice Get the created campaigns by token address
     * @dev User can retrieve their created campaign by address of tokens
     * @param _creator Address of created campaign user
     * @param _token Address of token want to query
     * @return Created Campaign Address
     */
    function getCreatedCampaignsByToken(address _creator, IERC20 _token)
        external
        view
        returns (address[] memory)
    {
        return getCampaigns[_creator][_token];
    }

    /**
     * @notice Retrieve number of campaigns created for specific token
     * @param _creator Address of created campaign user
     * @param _token Address of token want to query
     * @return Return number of created campaign
     */
    function getCreatedCampaignsLengthByToken(address _creator, IERC20 _token)
        public
        view
        returns (uint256)
    {
        return getCampaigns[_creator][_token].length;
    }

    /**
     * @notice Owner can set the platform fee
     * @dev Campaign will call function for distribute platform fee
     * @param _fee new fee percentage number
     */
    function setPlatformFeeRate(uint256 _fee)
        external
        onlyOwner
        returns (uint256)
    {
        require(_fee < 100, "ICOFactory::OVERFLOW_FEE");
        platformFeeRate = _fee;

        emit PlatformFeeChanged(msg.sender, _fee);
    }

    /**
     * @notice Owner can set the platform revenue address
     * @dev Distribution will be transfer to this address
     * @param _revenueAddress new fee percentage number
     */
    function setPlatformRevenueAddress(address _revenueAddress)
        external
        onlyOwner
        returns (uint256)
    {
        require(_revenueAddress != address(0), "ICOFactory::ZERO_ADDRESS");
        platformRevenueAddress = _revenueAddress;

        emit PlatformRevenueAddressChanged(msg.sender, _revenueAddress);
    }

    /**
     * @notice Register ICO Campaign for tokens
     * @dev To register, you MUST have an ERC20 token
     * @param _name String name of new campaign
     * @param _token address of ERC20 token
     * @param _duration Number of ICO time in seconds
     * @param _openTime Number of start ICO time in seconds
     * @param _releaseStartDate Timestamp when starts the claim distribution period
     * @param _releaseEndDate Timestamp when ends the claim distribution period
     * @param _ethRate Conversion rate for buy token. tokens = value * rate
     * @param _ethRateDecimals Ether to token conversion rate decimals
     * @param _raiseAmount Amount of tokens to sold out
     */
    function registerCampaign(
        string memory _name,
        IERC20 _token,
        uint256 _duration,
        uint256 _openTime,
        uint256 _releaseStartDate,
        uint256 _releaseEndDate,
        uint256 _maxBuyAmount,
        uint256 _ethRate,
        uint256 _ethRateDecimals,
        uint256 _raiseAmount
    ) external onlyOwner whenNotPaused returns (address campaign) {
        require(_token != IERC20(address(0)), "ICOFactory::ZERO_ADDRESS");
        require(_duration != 0, "ICOFactory::ZERO_DURATION");
        require(
            _releaseStartDate < _releaseEndDate,
            "ICOFactory::INVALID_RELEASE_END_TMIE"
        );
        require(
            _releaseStartDate >= block.timestamp,
            "ICOFactory::INVALID_RELEASE_TIME"
        );
        require(
            _releaseStartDate > _openTime.add(_duration),
            "ICOFactory::RELEASE_TIME_OVERFLOW"
        );
        require(_ethRate != 0, "ICOFactory::ZERO_ETH_RATE");
        bytes memory bytecode = type(Campaign).creationCode;
        uint256 tokenIndex =
            getCreatedCampaignsLengthByToken(msg.sender, _token);
        bytes32 salt =
            keccak256(abi.encodePacked(msg.sender, _token, tokenIndex));
        assembly {
            campaign := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ICampaign(campaign).initialize(
            _name,
            _token,
            _duration,
            _openTime,
            _releaseStartDate,
            _releaseEndDate,
            _maxBuyAmount,
            _ethRate,
            _ethRateDecimals,
            _raiseAmount
        );
        getCampaigns[msg.sender][_token].push(campaign);
        allCampaigns.push(campaign);

        emit IcoCampaignCreated(
            msg.sender,
            address(_token),
            campaign,
            allCampaigns.length - 1
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.1;

import "../libraries/IERC20.sol";

interface ICampaign {
    function initialize(
        string calldata _name,
        IERC20 _token,
        uint256 _duration,
        uint256 _openTime,
        uint256 _releaseStartDate,
        uint256 _releaseEndDate,
        uint256 _maxBuyAmount,
        uint256 _ethRate,
        uint256 _ethRateDecimals,
        uint256 _raiseAmount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;

import "./interfaces/ICampaignFactory.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./libraries/Whitelist.sol";
import "./libraries/Blacklist.sol";
import "./libraries/Math.sol";
import "./libraries/ReentrancyGuard.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Pausable.sol";
import "./libraries/AllocatedWhitelist.sol";

contract Campaign is
    ReentrancyGuard,
    Pausable,
    Whitelist,
    Blacklist,
    AllocatedWhitelist
{
    using SafeMath for uint256;

    // Token being sold
    IERC20 public token;

    // Address of factory contract
    address public factory;

    // Address where funds are collected
    address public fundingWallet;

    // Timestamp when token started to sell
    uint256 public openTime = block.timestamp;

    // Timestamp when token stopped to sell
    uint256 public closeTime;

    // Timestamp when starts the claim distribution period
    uint256 public releaseStartDate;

    // Timestamp when ends the claim distribution period
    uint256 public releaseEndDate;

    // Max amount in USD of tokens an user can buy
    uint256 public maxBuyAmount = 1000;

    // Amount of wei raised
    uint256 public weiRaised;

    // Amount of tokens sold
    uint256 public tokenSold;

    // Amount of tokens claimed
    uint256 public tokenClaimed;

    // Amount of tokens to sold out
    uint256 public raiseAmount;

    // Name of IDO Campaign
    string public name;

    // Ether to token conversion rate
    uint256 private etherConversionRate;

    // Ether to token conversion rate decimals
    uint256 private etherConversionRateDecimals = 0;

    // Chainlink Price Feed
    AggregatorV3Interface internal EthPriceFeed;

    // If tokens was sent for the contract
    bool isLoaded = false;

    // Percentage of tokens will be locked on Unicrypt
    uint8 liquidityLocking;

    // User struct to store rewards
    struct UserControl {
        uint256 tokensBought;
        uint256 tokensClaimed;
    }

    // Token sold mapping to delivery
    mapping(address => UserControl) private userTokensMapping;

    // -----------------------------------------
    // Lemonade's events
    // -----------------------------------------
    event CampaignCreated(
        string name,
        address token,
        uint256 openTime,
        uint256 closeTime,
        uint256 releaseStartDate,
        uint256 releaseEndDate,
        uint256 maxBuyAmount,
        uint256 ethRate,
        uint256 ethRateDecimals,
        uint256 raiseAmount,
        address owner
    );
    event TokenPurchaseByEther(
        address indexed purchaser,
        uint256 value,
        uint256 amount
    );
    event RefundedTokenForIcoWhenEndIco(address wallet, uint256 amount);
    event TokenClaimed(address wallet, uint256 amount);
    event CampaignStatsChanged();

    // -----------------------------------------
    // Constructor
    // -----------------------------------------
    constructor() {
        factory = msg.sender;

        // Kovan Chainlink Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
        // Rinkeby: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // Mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        EthPriceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
    }

    // -----------------------------------------
    // Lemonade external interface
    // -----------------------------------------

    /**
     * @dev fallback function
     */
    fallback() external {
        revert();
    }

    /**
     * @dev fallback function
     */
    receive() external payable {
        buyTokenByEther();
    }

    /**
     * @param _name String name of new campaign
     * @param _token address of ERC20 token
     * @param _duration Number of ICO time in seconds
     * @param _openTime Number of start ICO time in seconds
     * @param _releaseStartDate Timestamp when starts the claim distribution period
     * @param _releaseEndDate Timestamp when ends the claim distribution period
     * @param _ethRate Conversion rate for buy token. tokens = value * rate
     * @param _ethRateDecimals Ether to token conversion rate decimals
     * @param _raiseAmount Amount of tokens to sold out
     */
    function initialize(
        string calldata _name,
        IERC20 _token,
        uint256 _duration,
        uint256 _openTime,
        uint256 _releaseStartDate,
        uint256 _releaseEndDate,
        uint256 _maxBuyAmount,
        uint256 _ethRate,
        uint256 _ethRateDecimals,
        uint256 _raiseAmount // uint8 _liquidityLocking, // address _wallet
    ) external {
        require(msg.sender == factory, "ICO_CAMPAIGN::UNAUTHORIZED");

        name = _name;
        token = _token;
        openTime = _openTime;
        closeTime = _openTime.add(_duration);
        releaseStartDate = _releaseStartDate;
        releaseEndDate = _releaseEndDate;
        maxBuyAmount = _maxBuyAmount;
        etherConversionRate = _ethRate;
        etherConversionRateDecimals = _ethRateDecimals;
        raiseAmount = _raiseAmount;
        fundingWallet = tx.origin;
        owner = tx.origin;
        paused = false;

        emit CampaignCreated(
            name,
            address(token),
            openTime,
            closeTime,
            releaseStartDate,
            releaseEndDate,
            maxBuyAmount,
            etherConversionRate,
            etherConversionRateDecimals,
            raiseAmount,
            owner
        );
    }

    /**
     * @notice Returns the conversion rate when user buy by eth
     * @return Returns only a fixed number of rate.
     */
    function getEtherConversionRate() public view returns (uint256) {
        return etherConversionRate;
    }

    /**
     * @notice Returns the percentage of tokens will be locked on Unicrypt
     * @return Returns only a fixed number of liquidity lock percentage.
     */
    function getLiquidityLockingPercentage() external view returns (uint8) {
        return liquidityLocking;
    }

    /**
     * @notice Returns the conversion rate decimals when user buy by eth
     * @return Returns only a fixed number of decimals.
     */
    function getEtherConversionRateDecimals() external view returns (uint256) {
        return etherConversionRateDecimals;
    }

    /**
     * @notice Returns the Buyable tokens of an address
     * @return Returns amount of tokens the user can buy
     * @param _address Address to find the amount of tokens
     */
    function getBuyableTokens(address _address) public view returns (uint256) {
        return
            etherConversionRate
                .mul(1 ether)
                .mul(
                Math.max(maxBuyAmount, getAllocatedUserAmountInUSD(_address))
            )
                .mul(1e8)
                .div(getLatestEthPrice())
                .div(10**etherConversionRateDecimals)
                .sub(userTokensMapping[_address].tokensBought);
    }

    /**
     * @notice Returns the available tokens of Campaign
     * @return Returns amount of tokens available to buy in the Campaign
     */
    function getAvailableTokens() public view returns (uint256) {
        return raiseAmount.sub(tokenSold);
    }

    /**
     * @notice Returns the Total Claimable tokens of an address
     * @return Returns amount of tokens the user calaim at final of release period
     * @param _address Address to find the amount of tokens
     */
    function getTotalClaimableTokens(address _address)
        external
        view
        returns (uint256)
    {
        return userTokensMapping[_address].tokensBought;
    }

    /**
     * @notice Returns the last latest timestamp of release applicable
     * @return Returns blocktimestamp if < periodFinish
     */
    function _lastTimeRewardApplicable() internal view returns (uint256) {
        return Math.min(block.timestamp, releaseEndDate);
    }

    /**
     * @notice Returns the Available Claimable tokens of an address
     * @return Returns amount of tokens the user can calain at this moment
     * @param _address Address to find the amount of tokens
     */
    function getAvailableClaimableTokens(address _address)
        public
        view
        returns (uint256)
    {
        if (block.timestamp < releaseStartDate) {
            return 0;
        } else {
            uint256 distribution =
                userTokensMapping[_address].tokensBought.div(
                    releaseEndDate.sub(releaseStartDate)
                );
            uint256 reimain = _lastTimeRewardApplicable().sub(releaseStartDate);
            return
                distribution.mul(reimain).sub(
                    userTokensMapping[_address].tokensClaimed
                );
        }
    }

    /**
     * @notice Check the amount of tokens is bigger than raiseAmount and enable to buy
     */
    function loadCampaign() external onlyOwner {
        require(!isLoaded, "ICO_CAMPAIGN::LOAD_ALREADY_VERIFIED");
        require(
            block.timestamp < openTime,
            "ICO_CAMPAIGN::CAMPAIGN_ALREADY_STARTED"
        );
        require(
            token.balanceOf(address(this)) >= raiseAmount,
            "ICO_CAMPAIGN::INVALID_BALANCE"
        );
        isLoaded = true;
    }

    /**
     * @notice Allows the contract to get the latest value of the ETH/USD price feed
     * @return Returns the latest ETH/USD price
     */
    function getLatestEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = EthPriceFeed.latestRoundData();
        return uint256(price);
    }

    /**
     * @notice Owner can set the eth conversion rate. Receiver tokens = wei * etherConversionRate / 10 ** etherConversionRateDecimals
     * @param _rate Fixed number of ether rate
     */
    function setEtherConversionRate(uint256 _rate) external onlyOwner {
        require(etherConversionRate != _rate, "ICO_CAMPAIGN::RATE_INVALID");
        etherConversionRate = _rate;
        emit CampaignStatsChanged();
    }

    /**
     * @notice Owner can set the campaign token
     * @param _token address of ERC20 token to be sold
     */
    function setCampaignToken(IERC20 _token) external onlyOwner {
        token = _token;
    }

    /**
     * @notice Owner can set max of tokens of an user can buy
     * @param _rate Fixed number of ether rate
     */
    function setMaxBuyAmountRate(uint256 _rate) external onlyOwner {
        require(maxBuyAmount != _rate, "ICO_CAMPAIGN::RATE_INVALID");
        maxBuyAmount = _rate;
        emit CampaignStatsChanged();
    }

    /**
     * @notice Owner can set the liquidity locking of tokens will be locked on Unicrypt
     * @param _percentage Fixed number of percentage
     */
    function setLiquidityLockingPercentage(uint8 _percentage)
        external
        onlyOwner
    {
        require(_percentage <= 100, "ICO_CAMPAIGN::OVERFLOW_LOCKING");
        liquidityLocking = _percentage;
    }

    /**
     * @notice Owner can set the fundingWallet where funds are collected
     * @param _address Address of funding ICO wallets. Sold tokens in eth will transfer to this address
     */
    function setFundingWallet(address _address) external onlyOwner {
        require(_address != address(0), "ICO_CAMPAIGN::ZERO_ADDRESS");
        fundingWallet = _address;
    }

    /**
     * @notice Owner can set the eth conversion rate with decimals
     * @param _rate Fixed number of ether rate
     * @param _rateDecimals Fixed number of ether rate decimals
     */
    function setEtherConversionRateAndDecimals(
        uint256 _rate,
        uint256 _rateDecimals
    ) external onlyOwner {
        etherConversionRate = _rate;
        etherConversionRateDecimals = _rateDecimals;
        emit CampaignStatsChanged();
    }

    /**
     * @notice Owner can set the eth conversion rate decimals. Receiver tokens = wei * etherConversionRate / 10 ** etherConversionRateDecimals
     * @param _rateDecimals Fixed number of ether rate decimals
     */
    function setEtherConversionRateDecimals(uint256 _rateDecimals)
        external
        onlyOwner
    {
        etherConversionRateDecimals = _rateDecimals;
        emit CampaignStatsChanged();
    }

    /**
     * @notice Owner can set the new Chainlink Price Feed smart contract by address
     * @param _chainlinkContract Chainlink Price Feed smart contract address
     */
    function setChainlinkContract(AggregatorV3Interface _chainlinkContract)
        external
        onlyOwner
    {
        EthPriceFeed = _chainlinkContract;
        emit CampaignStatsChanged();
    }

    /**
     * @notice Owner can set the releases time (time in seconds) for claim functionality.
     * @param _releaseStartDate Value in uint256 determine when starts the claim period
     * @param _releaseEndDate Value in uint256 determine when ends claim period
     */
    function setReleaseTime(uint256 _releaseStartDate, uint256 _releaseEndDate)
        external
        onlyOwner()
    {
        require(
            _releaseStartDate >= block.timestamp,
            "ICO_CAMPAIGN::INVALID_RELEASE_START_TMIE"
        );
        require(
            _releaseEndDate > _releaseStartDate,
            "ICO_CAMPAIGN::INVALID_RELEASE_END_TMIE"
        );
        require(
            _releaseStartDate >= closeTime,
            "ICO_CAMPAIGN::INVALID_RELEASE_START_TMIE"
        );
        releaseStartDate = _releaseStartDate;
        releaseEndDate = _releaseEndDate;
        emit CampaignStatsChanged();
    }

    /**
     * @notice Owner can set the close time (time in seconds). User can buy before close time.
     * @param _closeTime Value in uint256 determine when we stop user to by tokens
     */
    function setCloseTime(uint256 _closeTime) external onlyOwner() {
        require(_closeTime >= block.timestamp, "ICO_CAMPAIGN::INVALID_TIME");
        require(_closeTime > releaseStartDate, "ICO_CAMPAIGN::INVALID_TIME");
        closeTime = _closeTime;
        emit CampaignStatsChanged();
    }

    /**
     * @notice Owner can set the open time (time in seconds). User can buy after open time.
     * @param _openTime Value in uint256 determine when we allow user to by tokens
     */
    function setOpenTime(uint256 _openTime) external onlyOwner() {
        openTime = _openTime;
        emit CampaignStatsChanged();
    }

    /**
     * @notice User can buy token by this function when available. tokens = wei * etherConversionRate / 10 ** etherConversionRateDecimals
     * @dev low level token purchase ***DO NOT OVERRIDE***
     */
    function buyTokenByEther()
        public
        payable
        whenNotPaused
        onlyWhitelisted
        onlyNonBlacklisted
        nonReentrant
    {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(msg.sender, weiAmount);
        require(isLoaded, "ICO_CAMPAIGN::NOT_LOADED");
        require(_validPurchase(), "ICO_CAMPAIGN::ENDED");

        // calculate token amount to be created
        uint256 tokens = _getEtherToTokenAmount(weiAmount);

        _updatePurchasingState(msg.sender, weiAmount, tokens);
        uint256 platformFee = _payPlatformEtherFee();
        _forwardFunds(weiAmount.sub(platformFee));
        emit TokenPurchaseByEther(msg.sender, weiAmount, tokens);
    }

    function claimTokens()
        public
        whenNotPaused
        onlyWhitelisted
        onlyNonBlacklisted
        nonReentrant
    {
        require(isClaimable(), "ICO_CAMPAIGN::ICO_NOT_ENDED");
        uint256 amount = getAvailableClaimableTokens(msg.sender);
        require(amount > 0, "ICO_CAMPAIGN::EMPTY_BALANCE");

        token.transfer(msg.sender, amount);
        _updateDeliveryState(msg.sender, amount);

        emit TokenClaimed(msg.sender, amount);
    }

    /**
     * @notice Return true if campaign has ended
     * @dev User cannot purchase / trade tokens when isFinalized == true
     * @return true if the ICO ended.
     */
    function isFinalized() external view returns (bool) {
        return block.timestamp >= closeTime;
    }

    /**
     * @notice Return true if campaign has ended and is eneable to claim
     * @dev User cannot claim tokens when isClaimable == false
     * @return true if the release time < now.
     */
    function isClaimable() public view returns (bool) {
        return block.timestamp >= releaseStartDate;
    }

    /**
     * @notice Return true if campaign is open
     * @dev User can purchase / trade tokens when isOpen == true
     * @return true if the ICO is open.
     */
    function isOpen() external view returns (bool) {
        return (block.timestamp < closeTime) && (block.timestamp > openTime);
    }

    /**
     * @notice Owner can receive their remaining tokens when ICO Ended
     * @dev  Can refund remainning token if the ico ended
     * @param _wallet Address wallet who receive the remainning tokens when Ico end
     */
    function refundTokenForIcoOwner(address _wallet) external onlyOwner {
        require(isClaimable(), "ICO_CAMPAIGN::ICO_NOT_ENDED");
        require(getAvailableTokens() > 0, "ICO_CAMPAIGN::EMPTY_BALANCE");
        uint256 availableToken = getAvailableTokens();
        _deliverTokens(_wallet, availableToken);
        emit RefundedTokenForIcoWhenEndIco(_wallet, availableToken);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        pure
    {
        require(
            _beneficiary != address(0),
            "ICO_CAMPAIGN::INVALID_BENEFICIARY"
        );
        require(_weiAmount != 0, "ICO_CAMPAIGN::INVALID_WEI_AMOUNT");
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getEtherToTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        uint256 rate = getEtherConversionRate();
        return _weiAmount.mul(rate).div(10**etherConversionRateDecimals);
    }

    /**
     * @dev Source of tokens. Transfer / mint
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(uint256 _value) internal {
        address payable wallet = address(uint160(fundingWallet));
        (bool success, ) = wallet.call{value: _value}("");
        require(success, "ICO_CAMPAIGN::WALLET_TRANSFER_FAILED");
    }

    /**
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Value of sold tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    ) internal {
        require(
            _tokenAmount <= getBuyableTokens(_beneficiary),
            "ICO_CAMPAIGN::MAX_BUY_AMOUNT_EXEDED"
        );
        require(
            getAvailableTokens() >= _tokenAmount,
            "ICO_CAMPAIGN::AVAILABLE_TOKENS_NOT_ENOUGH"
        );
        weiRaised = weiRaised.add(_weiAmount);
        tokenSold = tokenSold.add(_tokenAmount);
        userTokensMapping[_beneficiary].tokensBought = userTokensMapping[
            _beneficiary
        ]
            .tokensBought
            .add(_tokenAmount);
    }

    /**
     * @param _beneficiary Address performing the token delivery
     * @param _tokenAmount Value of delivery tokens
     */
    function _updateDeliveryState(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        tokenClaimed = tokenClaimed.add(_tokenAmount);
        userTokensMapping[_beneficiary].tokensClaimed = userTokensMapping[
            _beneficiary
        ]
            .tokensClaimed
            .add(_tokenAmount);
    }

    // @return true if the transaction can buy tokens
    function _validPurchase() internal view returns (bool) {
        bool withinPeriod =
            block.timestamp >= openTime && block.timestamp <= closeTime;
        return withinPeriod;
    }

    /**
     * @notice Pay platform fee when a trade executed in eth
     * @dev  Only pay when use Lemonade to register ICO Campaign
     */
    function _payPlatformEtherFee() private returns (uint256) {
        address payable platformRevenueAddress =
            address(uint160(_getPlatformRevenueAddress()));
        uint256 platformFeeRate = _getPlatformFeeRate();
        uint256 payment = msg.value;
        uint256 platformFee = payment.mul(platformFeeRate).div(100);

        (bool success, ) = platformRevenueAddress.call{value: platformFee}("");
        require(success, "ICO_CAMPAIGN::PAY_PLATFORM_FEE_FAILED");
        return platformFee;
    }

    /**
     * @notice Call to factory contract to get Platform Fee
     * @dev  return a fixed number fee of Platform
     */
    function _getPlatformFeeRate() private view returns (uint256) {
        return ICampaignFactory(factory).getPlatformFeeRate();
    }

    /**
     * @notice Call to factory contract to get revenue address
     * @dev  return address of factory vault
     */
    function _getPlatformRevenueAddress() private view returns (address) {
        return ICampaignFactory(factory).getplatformRevenueAddress();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.1;


import "./Ownable.sol";


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused, "CONTRACT_PAUSED");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused, "CONTRACT_NOT_PAUSED");
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.7.1 <0.8.0;


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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.1;

interface ICampaignFactory {
    function getPlatformFeeRate() external view returns (uint256);
    function getplatformRevenueAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract Whitelist is Ownable {
    mapping(address => bool) whitelist;
    bool public doubleCheck = true;
    IERC20 jigStack = IERC20(0x1F8A626883d7724DBd59eF51CBD4BF1Cf2016D13);
    event AddedToWhitelist(address indexed account);
    event AddedToWhitelistInBatch(address[] indexed accounts);
    event RemovedFromWhitelist(address indexed account);
    event RemovedFromWhitelistInBatch(address[] indexed accounts);
    event MinHeldTokensChanged(uint256 amount);
    event HeldTokensDoubleCheck(bool isActive);
    event TokenChanged(IERC20 _token);
    uint256 public minHeldTokens = 100 ether;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "ICO_CAMPAIGN::NOT_WHITELISTED");
        _;
    }

    function addToWhitelist(address _address) external onlyOwner {
        require(_address != address(0), "ICO_CAMPAIGN::INVALID_WALLET");
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function addToWhitelistBatch(address[] memory _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
        emit AddedToWhitelistInBatch(_addresses);
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        require(_address != address(0), "ICO_CAMPAIGN::INVALID_WALLET");
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function removeFromWhitelistBatch(address[] memory _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
        emit RemovedFromWhitelistInBatch(_addresses);
    }

    function setHeldTokens(uint256 _amount) external onlyOwner {
        minHeldTokens = _amount;
        emit MinHeldTokensChanged(_amount);
    }

    function bypassDoubleCheck(bool _doubleCheck) external onlyOwner {
        doubleCheck = _doubleCheck;
        emit HeldTokensDoubleCheck(doubleCheck);
    }

    function changeWhitelistToken(IERC20 _contract) external onlyOwner {
        jigStack = _contract;
        emit TokenChanged(_contract);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        if (doubleCheck) {
            return
                whitelist[_address] &&
                jigStack.balanceOf(_address) >= minHeldTokens;
        } else {
            return
                whitelist[_address] ||
                jigStack.balanceOf(_address) >= minHeldTokens;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Ownable.sol";

contract Blacklist is Ownable {
    mapping(address => bool) blacklist;
    event AddedToBlacklist(address indexed account);
    event AddedToBlacklistInBatch(address[] indexed accounts);
    event RemovedFromBlacklist(address indexed account);
    event RemovedFromBlacklistInBatch(address[] indexed accounts);

    modifier onlyNonBlacklisted() {
        require(
            !isBlacklisted(msg.sender),
            "ICO_CAMPAIGN::ADDRESS_BLACKLISTED"
        );
        _;
    }

    function addToBlacklist(address _address) external onlyOwner {
        require(_address != address(0), "ICO_CAMPAIGN::INVALID_WALLET");
        blacklist[_address] = true;
        emit AddedToBlacklist(_address);
    }

    function addToBlacklistBatch(address[] memory _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklist[_addresses[i]] = true;
        }
        emit AddedToBlacklistInBatch(_addresses);
    }

    function removeFromBlacklist(address _address) external onlyOwner {
        require(_address != address(0), "ICO_CAMPAIGN::INVALID_WALLET");
        blacklist[_address] = false;
        emit RemovedFromBlacklist(_address);
    }

    function removeFromBlacklistBatch(address[] memory _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklist[_addresses[i]] = false;
        }
        emit RemovedFromBlacklistInBatch(_addresses);
    }

    function isBlacklisted(address _address) public view returns (bool) {
        return blacklist[_address];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract AllocatedWhitelist is Ownable {
    using SafeMath for uint256;
    IERC20 public usd = IERC20(0xe527Af9fbDa1D44e02C425455E33fc2A0C2f9B33);
    uint256 constant TIMELOCK = 7200;
    uint256 MIN_DEPOSIT = 100;
    uint256 MAX_DEPOSIT = 1000;
    bool public isOpenAllocatedWhitelist = true;

    struct UserInfoMap {
        uint256 amount;
        bool release;
        uint256 releaseTimestamp;
    }
    struct UserInfoArray {
        address user;
        uint256 amount;
    }

    mapping(address => UserInfoMap) userMapping;
    UserInfoArray[] userArray;

    event AllocateAddress(address indexed account, uint256 amount);
    event Release(address indexed accounts, uint256 amount);
    event USDTokenChanged(IERC20 _usd);
    event minChanged(uint amount);
    event maxChanged(uint amount);
    event allocatedWhitelistIsOpen(bool status);

    function allocate(uint256 _amount) external {
        require(
            isOpenAllocatedWhitelist,
            "ALLOCATED_WHITELIST::WHITELIST_CLOSED"
        );
        require(
            _amount >= MIN_DEPOSIT * 10**usd.decimals(),
            "ALLOCATED_WHITELIST::INVALID_AMOUNT_MIN"
        );
        require(
            _amount <= MAX_DEPOSIT * 10**usd.decimals(),
            "ALLOCATED_WHITELIST::INVALID_AMOUNT_MAX"
        );
        require(
            !userMapping[msg.sender].release,
            "ALLOCATED_WHITELIST::USER_ALREADY_ALLOCATED"
        );
        usd.transferFrom(msg.sender, address(this), _amount);
        userMapping[msg.sender].amount = _amount;
        userMapping[msg.sender].releaseTimestamp = block.timestamp.add(
            TIMELOCK
        );
        userMapping[msg.sender].release = true;
        userArray.push(UserInfoArray(msg.sender, _amount));
        emit AllocateAddress(msg.sender, _amount);
    }

    function releaseAllocation() external {
        uint256 amount = userMapping[msg.sender].amount;
        require(
            userMapping[msg.sender].releaseTimestamp <= block.timestamp,
            "ALLOCATED_WHITELIST::RELEASE_TIME_NOT_COMPLETED"
        );
        require(amount >= 0, "ALLOCATED_WHITELIST::EMPTY_BALANCE");
        usd.transfer(msg.sender, amount);
        userMapping[msg.sender].amount = userMapping[msg.sender].amount.sub(
            amount
        );
        emit Release(msg.sender, amount);
    }

    function getAllocationsLength() external view returns (uint256) {
        return userArray.length;
    }

    function getAllocatedUserAmountInUSD(address _address)
        public
        view
        returns (uint256)
    {
        return userMapping[_address].amount.div(10**usd.decimals());
    }

    function getAllocatedByIndex(uint256 _index)
        external
        view
        returns (address, uint256)
    {
        return (userArray[_index].user, userArray[_index].amount);
    }

    function changeAllocationUSDToken(IERC20 _contract) external onlyOwner {
        usd = _contract;
        emit USDTokenChanged(_contract);
    }

    function changeMinAmount(uint256 _min) external onlyOwner {
        MIN_DEPOSIT = _min;
        emit minChanged(_min);
    }

    function changeMaxAmount(uint256 _max) external onlyOwner {
        MAX_DEPOSIT = _max;
        emit maxChanged(_max);
    }
    
    function toggleAllocatedWhitelist(bool _status) external onlyOwner {
        isOpenAllocatedWhitelist = _status;
        emit allocatedWhitelistIsOpen(_status);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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