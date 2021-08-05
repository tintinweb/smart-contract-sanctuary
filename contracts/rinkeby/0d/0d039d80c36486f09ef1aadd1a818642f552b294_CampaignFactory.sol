// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/ICampaign.sol";
import "./interfaces/IStakBank.sol";
import "./Campaign.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract CampaignFactory is OwnableUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // Percentage of platform fee
    uint256 public platformFeeRate;

    // Address of platform revenue. Platform fee will transfer to it
    address public platformRevenueAddress;

    // StakBank contract address
    IStakBank public stakBankAddress;

    // Array of created Campaign Address
    address[] public allCampaigns;
    // Mapping from User token. From tokens to array of created Campaign for token
    mapping(IERC20 => address[]) public getCampaigns;

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
    event StakBankChanged(address changer, IStakBank stakBank);

    function initialize(
        uint256 _platformFeeRate,
        address _revenueAddress,
        IStakBank _stakBankAddress
    ) public initializer {
        require(_revenueAddress != address(0), "ICOFactory::ZERO_ADDRESS");
        require(_platformFeeRate < 100, "ICOFactory::OVERFLOW_FEE");
        platformFeeRate = _platformFeeRate;
        platformRevenueAddress = _revenueAddress;
        stakBankAddress = _stakBankAddress;
        __Ownable_init_unchained();
        __Context_init_unchained();
        __Pausable_init_unchained();

        emit PlatformFeeChanged(_msgSender(), _platformFeeRate);
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
     * @param _token Address of token want to query
     * @return Created Campaign Address
     */
    function getCreatedCampaignsByToken(IERC20 _token)
        external
        view
        returns (address[] memory)
    {
        return getCampaigns[_token];
    }

    /**
     * @notice Retrieve number of campaigns created for specific token
     * @param _token Address of token want to query
     * @return Return number of created campaign
     */
    function getCreatedCampaignsLengthByToken(IERC20 _token)
        public
        view
        returns (uint256)
    {
        return getCampaigns[_token].length;
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
     * @notice Owner can set the platform fee
     * @dev Campaign will call function for distribute platform fee
     * @param _fee new fee percentage number
     */
    function setPlatformFeeRate(uint256 _fee) external onlyOwner {
        require(_fee < 100, "ICOFactory::OVERFLOW_FEE");
        platformFeeRate = _fee;

        emit PlatformFeeChanged(_msgSender(), _fee);
    }

    /**
     * @notice Owner can set the platform revenue address
     * @dev Distribution will be transfer to this address
     * @param _revenueAddress new fee percentage number
     */
    function setPlatformRevenueAddress(address _revenueAddress)
        external
        onlyOwner
    {
        require(_revenueAddress != address(0), "ICOFactory::ZERO_ADDRESS");
        platformRevenueAddress = _revenueAddress;

        emit PlatformRevenueAddressChanged(_msgSender(), _revenueAddress);
    }

    /**
     * @notice Owner can set the StakBank contract
     * @param _stakBank Address of the StakBank contract
     */
    function setStakBankContract(IStakBank _stakBank) external onlyOwner {
        stakBankAddress = _stakBank;
        emit StakBankChanged(_msgSender(), _stakBank);
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
     * @param _raiseAmount Amount of tokens to sold out
     * @param _verifyStartTime Timestamp when starts the stake verify whitelist period
     * @param _minStakedTokens Minimum amount of tokens to enter in campaign
     */
    function registerCampaign(
        string memory _name,
        IERC20 _token,
        uint256 _duration,
        uint256 _openTime,
        uint256 _releaseStartDate,
        uint256 _releaseEndDate,
        uint256 _ethRate,
        uint256 _raiseAmount,
        uint256 _verifyStartTime,
        uint256 _minStakedTokens
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
            _openTime >= block.timestamp,
            "ICO_CAMPAIGN::INVALID_OPEN_TIME"
        );
        require(
            _releaseStartDate > _openTime.add(_duration),
            "ICOFactory::RELEASE_TIME_OVERFLOW"
        );
        require(_ethRate != 0, "ICOFactory::ZERO_ETH_RATE");
        bytes memory bytecode = type(Campaign).creationCode;
        uint256 tokenIndex = getCreatedCampaignsLengthByToken(_token);
        bytes32 salt = keccak256(
            abi.encodePacked(_msgSender(), _token, tokenIndex)
        );
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
            _ethRate,
            _raiseAmount,
            _verifyStartTime,
            _minStakedTokens,
            stakBankAddress
        );
        getCampaigns[_token].push(campaign);
        allCampaigns.push(campaign);

        emit IcoCampaignCreated(
            _msgSender(),
            address(_token),
            campaign,
            allCampaigns.length - 1
        );
    }

    /**
     * @dev Called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStakBank.sol";

interface ICampaign {
    function initialize(
        string calldata _name,
        IERC20 _token,
        uint256 _duration,
        uint256 _openTime,
        uint256 _releaseStartDate,
        uint256 _releaseEndDate,
        uint256 _ethRate,
        uint256 _raiseAmount,
        uint256 _verifyStartTime,
        uint256 _minStakedTokens,
        IStakBank _stakBankAddress
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IStakBank {
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/ICampaignFactory.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/IStakBank.sol";
import "./libraries/Whitelist.sol";
import "./libraries/Blacklist.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Campaign is ReentrancyGuard, Pausable, Whitelist, Blacklist {
    using SafeMath for uint256;

    // -----------------------------------------
    // STATE VARIABLES
    // -----------------------------------------

    // Token being sold
    IERC20 public token;

    // Address of factory contract
    address public factory;

    // Address where funds are collected
    address public fundingWallet;

    // Timestamp when token started to sell
    uint256 public openTime;

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
    uint8 liquidityLocking = 10;

    // User struct to store rewards
    struct UserControl {
        uint256 tokensBought;
        uint256 tokensClaimed;
    }

    // Token sold mapping to delivery
    mapping(address => UserControl) private userTokensMapping;

    // -----------------------------------------
    // EVENTS
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
    // CONSTRUCTOR
    // -----------------------------------------

    constructor() {
        factory = _msgSender();

        // Kovan Chainlink Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
        // Rinkeby: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // Mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        EthPriceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
    }

    /**
     * @param _name String name of new campaign
     * @param _token address of ERC20 token
     * @param _duration Number of ICO time in seconds
     * @param _openTime Number of start ICO time in seconds
     * @param _releaseStartDate Timestamp when starts the claim distribution period
     * @param _releaseEndDate Timestamp when ends the claim distribution period
     * @param _ethRate Conversion rate for buy token. tokens = value * rate
     * @param _raiseAmount Amount of tokens to sold out
     * @param _verifyStartTime Timestamp when starts the stake verify whitelist period
     * @param _minStakedTokens Minimum amount of tokens to enter in campaign
     */
    function initialize(
        string calldata _name,
        IERC20 _token,
        uint256 _duration,
        uint256 _openTime,
        uint256 _releaseStartDate,
        uint256 _releaseEndDate,
        uint256 _ethRate,
        uint256 _raiseAmount,
        uint256 _verifyStartTime,
        uint256 _minStakedTokens,
        IStakBank _stakBankAddress
    ) external {
        require(_msgSender() == factory, "ICO_CAMPAIGN::UNAUTHORIZED");

        name = _name;
        token = _token;
        openTime = _openTime;
        closeTime = _openTime.add(_duration);
        releaseStartDate = _releaseStartDate;
        releaseEndDate = _releaseEndDate;
        etherConversionRate = _ethRate;
        raiseAmount = _raiseAmount;
        fundingWallet = tx.origin;
        _setupWhitelist(_stakBankAddress, _verifyStartTime, _minStakedTokens);
        transferOwnership(tx.origin);

        emit CampaignCreated(
            name,
            address(token),
            openTime,
            closeTime,
            releaseStartDate,
            releaseEndDate,
            maxBuyAmount,
            etherConversionRate,
            raiseAmount,
            owner()
        );
    }

    // -----------------------------------------
    // FALLBACK
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

    // -----------------------------------------
    // VIEWS
    // -----------------------------------------

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
                .mul(maxBuyAmount)
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
            uint256 distribution = userTokensMapping[_address].tokensBought.div(
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
     * @notice Allows the contract to get the latest value of the ETH/USD price feed
     * @return Returns the latest ETH/USD price
     */
    function getLatestEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = EthPriceFeed.latestRoundData();
        return uint256(price);
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

    // -----------------------------------------
    // MUTATIVE FUNCTIONS
    // -----------------------------------------

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
        _preValidatePurchase(_msgSender(), weiAmount);
        require(isLoaded, "ICO_CAMPAIGN::NOT_LOADED");
        require(_validPurchase(), "ICO_CAMPAIGN::ENDED");

        // calculate token amount to be created
        uint256 tokens = _getEtherToTokenAmount(weiAmount);

        _updatePurchasingState(_msgSender(), weiAmount, tokens);
        uint256 platformFee = _payPlatformEtherFee();
        _forwardFunds(weiAmount.sub(platformFee));
        emit TokenPurchaseByEther(_msgSender(), weiAmount, tokens);
    }

    function claimTokens()
        public
        whenNotPaused
        onlyWhitelisted
        onlyNonBlacklisted
        nonReentrant
    {
        require(isClaimable(), "ICO_CAMPAIGN::ICO_NOT_ENDED");
        uint256 amount = getAvailableClaimableTokens(_msgSender());
        require(amount > 0, "ICO_CAMPAIGN::EMPTY_BALANCE");

        token.transfer(_msgSender(), amount);
        _updateDeliveryState(_msgSender(), amount);

        emit TokenClaimed(_msgSender(), amount);
    }

    // -----------------------------------------
    // INTERNAL
    // -----------------------------------------

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
        ].tokensBought.add(_tokenAmount);
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
        ].tokensClaimed.add(_tokenAmount);
    }

    // @return true if the transaction can buy tokens
    function _validPurchase() internal view returns (bool) {
        bool withinPeriod = block.timestamp >= openTime &&
            block.timestamp <= closeTime;
        return withinPeriod;
    }

    /**
     * @notice Pay platform fee when a trade executed in eth
     * @dev  Only pay when use Lemonade to register ICO Campaign
     */
    function _payPlatformEtherFee() private returns (uint256) {
        address payable platformRevenueAddress = address(
            uint160(_getPlatformRevenueAddress())
        );
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

    // -----------------------------------------
    // RESTRICTED FUNCTIONS
    // -----------------------------------------

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
     * @notice Owner can set the close time (time in seconds). User can buy before close time.
     * @param _openTime Value in uint256 determine when we allow user to buy tokens
     * @param _duration Value in uint256 determine the duration of user can buy tokens
     * @param _releaseStartDate Value in uint256 determine when starts the claim period
     * @param _releaseEndDate Value in uint256 determine when ends claim period
     */
    function setOpenTimeAndRealeaseDate(
        uint256 _openTime,
        uint256 _duration,
        uint256 _releaseStartDate,
        uint256 _releaseEndDate
    ) external onlyOwner {
        require(
            _openTime >= block.timestamp,
            "ICO_CAMPAIGN::INVALID_OPEN_TIME"
        );
        require(
            _openTime.add(_duration) < _releaseStartDate,
            "ICO_CAMPAIGN::INVALID_OPEN_TIME"
        );
        require(
            _releaseEndDate > _releaseStartDate,
            "ICO_CAMPAIGN::INVALID_RELEASE_END_TMIE"
        );
        openTime = _openTime;
        closeTime = _openTime.add(_duration);
        emit CampaignStatsChanged();
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
     * @dev Called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner {
        _unpause();
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    uint256[49] private __gap;
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

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
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

import "../interfaces/IStakBank.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Whitelist is Ownable {
    using SafeMath for uint256;

    bool public doubleCheck = true;
    IStakBank public stakBank;
    uint256 public minStakedTokens;
    uint256 public verifyStartTime;
    uint256 public verifyEndTime;

    mapping(address => bool) whitelist;

    event MinStakedTokensChanged(uint256 amount);
    event StakedTokensDoubleCheck(bool isActive);
    event StakBankAddressChanged(IStakBank stakBank);

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "ICO_CAMPAIGN::NOT_WHITELISTED");
        _;
    }

    function verifyStake() external {
        require(
            !whitelist[_msgSender()],
            "ICO_CAMPAIGN::USER_ALREADY_VERIFIED"
        );
        require(
            stakBank.balanceOf(_msgSender()) >= minStakedTokens,
            "ICO_CAMPAIGN::NOT_ENOUGH_STAKE"
        );
        require(
            block.timestamp > verifyStartTime,
            "ICO_CAMPAIGN::STAKE_VERIFICATION_NOT_STARTED"
        );
        require(
            block.timestamp < verifyEndTime,
            "ICO_CAMPAIGN::STAKE_VERIFICATION_FINISHED"
        );
        whitelist[_msgSender()] = true;
    }

    function setStakedTokens(uint256 _amount) external onlyOwner {
        minStakedTokens = _amount;
        emit MinStakedTokensChanged(_amount);
    }

    function bypassDoubleCheck(bool _doubleCheck) external onlyOwner {
        doubleCheck = _doubleCheck;
        emit StakedTokensDoubleCheck(doubleCheck);
    }

    function changeStakBankContract(IStakBank _stakBank) public onlyOwner {
        stakBank = _stakBank;
        emit StakBankAddressChanged(_stakBank);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        if (doubleCheck) {
            return
                whitelist[_address] &&
                stakBank.balanceOf(_address) >= minStakedTokens;
        } else {
            return stakBank.balanceOf(_address) >= minStakedTokens;
        }
    }

    function _setupWhitelist(
        IStakBank _stakBank,
        uint256 _verifyStartTime,
        uint256 _minStakedTokens
    ) internal onlyOwner {
        stakBank = _stakBank;
        verifyStartTime = _verifyStartTime;
        verifyEndTime = _verifyStartTime.add(1 days);
        minStakedTokens = _minStakedTokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";

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
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
library SafeMath {
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

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
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