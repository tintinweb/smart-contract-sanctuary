// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;

import "./ICampaignFactory.sol";
import "./AggregatorV3Interface.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Pausable.sol";

contract Campaign is Ownable, ReentrancyGuard, Pausable {
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

    // Timestamp when token release is enabled
    uint256 public releaseTime;

    // Amount of wei raised
    uint256 public weiRaised = 0;

    // Amount of tokens sold
    uint256 public tokenSold = 0;

    // Amount of tokens claimed
    uint256 public tokenClaimed = 0;

    // Name of IDO Campaign
    string public name;

    // Ether to token conversion rate
    uint256 private etherConversionRate;

    // Ether to token conversion rate decimals
    uint256 private etherConversionRateDecimals = 0;

    // Chainlink Price Feed
    AggregatorV3Interface internal EthPriceFeed;

    // Token to token conversion rate
    mapping(IERC20 => uint256) private erc20TokenConversionRate;

    // Token sold mapping to delivery
    mapping(address => uint256) private tokenSoldMapping;

    modifier tokenRateSet(IERC20 _token) {
        require(
            erc20TokenConversionRate[_token] != 0,
            "ICO_CAMPAIGN::TOKEN_NOT_ALLOWED"
        );
        _;
    }

    // -----------------------------------------
    // Lemonade's events
    // -----------------------------------------
    event CampaignCreated(
        string name,
        address token,
        uint256 openTime,
        uint256 closeTime,
        uint256 releaseTime,
        uint256 ethRate,
        uint256 ethRateDecimals,
        address wallet,
        address owner
    );
    event AllowTokenToTradeWithRate(address token, uint256 rate);
    event TokenPurchaseByEther(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );
    event TokenPurchaseByToken(
        address indexed purchaser,
        address indexed beneficiary,
        address token,
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

        // Kovan Chainlink Address:
        // Main net: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        EthPriceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
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
        buyTokenByEther(msg.sender);
    }

    /**
     * @param _name Name of ICO Campaign
     * @param _token Address of the token being sold
     * @param _duration Duration of ICO Campaign
     * @param _openTime When ICO Started
     * @param _ethRate Number of token units a buyer gets per wei
     * @param _wallet Address where collected funds will be forwarded to
     */
    function initialize(
        string calldata _name,
        IERC20 _token,
        uint256 _duration,
        uint256 _openTime,
        uint256 _releaseTime,
        uint256 _ethRate,
        uint256 _ethRateDecimals,
        address _wallet
    ) external {
        require(msg.sender == factory, "ICO_CAMPAIGN::UNAUTHORIZED");

        name = _name;
        token = _token;
        openTime = _openTime;
        closeTime = _openTime.add(_duration);
        releaseTime = _releaseTime;
        etherConversionRate = _ethRate;
        etherConversionRateDecimals = _ethRateDecimals;
        fundingWallet = _wallet;
        owner = tx.origin;
        paused = false;

        emit CampaignCreated(
            name,
            address(token),
            openTime,
            closeTime,
            releaseTime,
            etherConversionRate,
            etherConversionRateDecimals,
            fundingWallet,
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
     * @notice Returns the conversion rate decimals when user buy by eth
     * @return Returns only a fixed number of decimals.
     */
    function getEtherConversionRateDecimals() public view returns (uint256) {
        return etherConversionRateDecimals;
    }

    /**
     * @notice Returns the conversion rate when user buy by eth
     * @return Returns only a fixed number of token rate.
     * @param _token address of token to query token exchange rate
     */
    function getErc20TokenConversionRate(IERC20 _token)
        public
        view
        returns (uint256)
    {
        return erc20TokenConversionRate[_token];
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
                .mul(100000000000)
                .div(getLatestEthPrice())
                .div(10**etherConversionRateDecimals)
                .sub(tokenSoldMapping[_address]);
    }

    /**
     * @notice Returns the available tokens of Campaign
     * @return Returns amount of tokens available to buy in the Campaign
     */
    function getAvailableTokens() public view returns (uint256) {
        return token.balanceOf(address(this)).add(tokenClaimed).sub(tokenSold);
    }

    /**
     * @notice Returns the total tokens of Campaign
     * @return Returns amount of tokens need to sold out the Campaign
     */
    function totalRaisedTokens() public view returns (uint256) {
        return token.balanceOf(address(this)).add(tokenClaimed);
    }

    /**
     * @notice Returns the Claimable tokens of an address
     * @return Returns amount of tokens the user can calain
     * @param _address Address to find the amount of tokens
     */
    function getClaimableTokens(address _address)
        public
        view
        returns (uint256)
    {
        return tokenSoldMapping[_address];
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
     * @notice Owner can set the eth conversion rate with decimals
     * @param _rate Fixed number of ether rate
     * @param _rateDecimals Fixed number of ether rate decimals
     */
    function setEtherConversionRateAndDecimals(uint256 _rate, uint256 _rateDecimals) external onlyOwner {
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
     * @notice Owner can set the token conversion rate. Receiver tokens = tradeTokens * tokenRate
     * @param _token address of token to query token exchange rate
     */
    function setErc20TokenConversionRate(IERC20 _token, uint256 _rate)
        external
        onlyOwner
    {
        require(
            erc20TokenConversionRate[_token] != _rate,
            "ICO_CAMPAIGN::RATE_INVALID"
        );
        erc20TokenConversionRate[_token] = _rate;
        emit AllowTokenToTradeWithRate(address(_token), _rate);
        emit CampaignStatsChanged();
    }

    /**
     * @notice Owner can set the release time (time in seconds) for claim functionality.
     * @param _releaseTime Value in uint256 determine when we allow claim to function
     */
    function setReleaseTime(uint256 _releaseTime) external onlyOwner() {
        require(_releaseTime >= block.timestamp, "ICO_CAMPAIGN::INVALID_TIME");
        require(
            _releaseTime >= closeTime,
            "ICO_CAMPAIGN::INVALID_TIME_COMPATIBILITY"
        );
        releaseTime = _releaseTime;
        emit CampaignStatsChanged();
    }

    /**
     * @notice Owner can set the close time (time in seconds). User can buy before close time.
     * @param _closeTime Value in uint256 determine when we stop user to by tokens
     */
    function setCloseTime(uint256 _closeTime) external onlyOwner() {
        require(_closeTime >= block.timestamp, "ICO_CAMPAIGN::INVALID_TIME");
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
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokenByEther(address _beneficiary)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);
        require(_validPurchase(), "ICO_CAMPAIGN::ENDED");

        // calculate token amount to be created
        uint256 tokens = _getEtherToTokenAmount(weiAmount);
        require(
            tokenSoldMapping[_beneficiary] + tokens <=
                etherConversionRate
                    .mul(1 ether)
                    .mul(100000000000)
                    .div(getLatestEthPrice())
                    .div(10**etherConversionRateDecimals),
            "ICO_CAMPAIGN::MAX_1000_USD_TOTAL"
        );

        uint256 platformFee = _payPlatformEtherFee();
        _forwardFunds(weiAmount.sub(platformFee));
        _updatePurchasingState(_beneficiary, weiAmount, tokens);
        emit TokenPurchaseByEther(msg.sender, _beneficiary, weiAmount, tokens);
    }

    /**
     * @notice Calculate the tokens user can receive. Receive User's trade tokens and transfer tokens
     * @dev tokens = _token * token Conversion Rate Of _token
     * @param _beneficiary Address performing the token purchase
     * @param _token Address of willing to exchange to ke performing the token purchase
     * @param _amount Value of amount will exchange of tokens
     */
    function buyTokenByToken(
        address _beneficiary,
        IERC20 _token,
        uint256 _amount
    ) public whenNotPaused nonReentrant {
        require(_token != IERC20(address(0)), "ICO_CAMPAIGN::TOKEN_ADDRESS_0");
        require(_token != token, "ICO_CAMPAIGN::TOKEN_INVALID");
        require(_validPurchase(), "ICO_CAMPAIGN::ENDED");
        _preValidatePurchase(_beneficiary, _amount);
        require(
            getErc20TokenConversionRate(_token) != 0,
            "ICO_CAMPAIGN::TOKEN_NOT_ALLOWED"
        );

        IERC20 tradeToken = _token;
        uint256 allowance = tradeToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "ICO_CAMPAIGN::TOKEN_NOT_APPROVED");

        uint256 tokens = _getTokenToTokenAmount(_token, _amount);
        require(
            tokenSoldMapping[_beneficiary] + tokens <=
                erc20TokenConversionRate[_token]
                    .mul(1 ether)
                    .mul(100000000000)
                    .div(getLatestEthPrice()),
            "ICO_CAMPAIGN::MAX_1000_USD_TOTAL"
        );

        uint256 platformFee = _payPlatformTokenFee(_token, _amount);
        _forwardTokenFunds(_token, _amount.sub(platformFee));
        _updatePurchasingState(_beneficiary, 0, tokens);

        emit TokenPurchaseByToken(
            msg.sender,
            _beneficiary,
            address(_token),
            _amount,
            tokens
        );
    }

    function claimTokens() public whenNotPaused nonReentrant {
        require(isClaimable(), "ICO_CAMPAIGN::ICO_NOT_ENDED");

        uint256 amount = tokenSoldMapping[msg.sender];
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
    function isFinalized() public view returns (bool) {
        return block.timestamp >= closeTime;
    }

    /**
     * @notice Return true if campaign has ended and is eneable to claim
     * @dev User cannot claim tokens when isClaimable == false
     * @return true if the release time < now.
     */
    function isClaimable() public view returns (bool) {
        return block.timestamp >= releaseTime;
    }

    /**
     * @notice Return true if campaign is open
     * @dev User can purchase / trade tokens when isOpen == true
     * @return true if the ICO is open.
     */
    function isOpen() public view returns (bool) {
        return (block.timestamp < closeTime) && (block.timestamp > openTime);
    }

    /**
     * @notice Owner can receive their remaining tokens when ICO Ended
     * @dev  Can refund remainning token if the ico ended
     * @param _wallet Address wallet who receive the remainning tokens when Ico end
     * @param _amount Value of amount will exchange of tokens
     */
    function refundTokenForIcoOwner(address _wallet, uint256 _amount)
        external
        onlyOwner
    {
        require(isClaimable(), "ICO_CAMPAIGN::ICO_NOT_ENDED");
        require(getAvailableTokens() > 0, "ICO_CAMPAIGN::EMPTY_BALANCE");
        _deliverTokens(_wallet, _amount);
        emit RefundedTokenForIcoWhenEndIco(_wallet, _amount);
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
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _token Address of exchange token
     * @param _amount Value of exchange tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenToTokenAmount(IERC20 _token, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 rate = getErc20TokenConversionRate(_token);
        return _amount.mul(rate);
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
     * @dev Determines how Token is stored/forwarded on purchases.
     */
    function _forwardTokenFunds(IERC20 _token, uint256 _amount) internal {
        _token.transferFrom(msg.sender, fundingWallet, _amount);
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
        require(getAvailableTokens() >= _tokenAmount, "ICO_CAMPAIGN::TOKEN_NOT_ENOUGH");
        weiRaised = weiRaised.add(_weiAmount);
        tokenSold = tokenSold.add(_tokenAmount);
        tokenSoldMapping[_beneficiary] = tokenSoldMapping[_beneficiary].add(
            _tokenAmount
        );
    }

    /**
     * @param _beneficiary Address performing the token delivery
     * @param _tokenAmount Value of delivery tokens
     */
    function _updateDeliveryState(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        tokenClaimed = tokenClaimed.add(_tokenAmount);
        tokenSoldMapping[_beneficiary] = tokenSoldMapping[_beneficiary].sub(
            _tokenAmount
        );
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
     * @notice Pay platform fee when a trade executed in tokens
     * @dev  Only pay when use Lemonade to register ICO Campaign
     */
    function _payPlatformTokenFee(IERC20 _token, uint256 _amount)
        private
        returns (uint256)
    {
        address payable platformRevenueAddress =
            address(uint160(_getPlatformRevenueAddress()));
        uint256 platformFeeRate = _getPlatformFeeRate();
        uint256 payment = _amount;
        uint256 platformFee = payment.mul(platformFeeRate).div(100);
        _token.transferFrom(msg.sender, platformRevenueAddress, platformFee);
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

    /**
     * @dev Transfer eth to an address
     * @param _to Address receiving the eth
     * @param _amount Amount of wei to transfer
     */
    function _transfer(address _to, uint256 _amount) private {
        address payable payableAddress = address(uint160(_to));
        (bool success, ) = payableAddress.call{value: _amount}("");
        require(success, "ICO_CAMPAIGN::TRANSFER_FEE_FAILED");
    }

    /**
     * @dev Transfer token to an address
     * @param _to Address receiving the eth
     * @param _amount Amount of wei to transfer
     */
    function _transferToken(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) private {
        _token.transferFrom(msg.sender, _to, _amount);
    }
}