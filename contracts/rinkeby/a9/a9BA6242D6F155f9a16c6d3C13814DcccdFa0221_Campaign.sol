// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;

import "./interfaces/ICampaignFactory.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./libraries/Whitelist.sol";
import "./libraries/Blacklist.sol";
import "./libraries/ReentrancyGuard.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Pausable.sol";

contract Campaign is ReentrancyGuard, Pausable, Whitelist, Blacklist {
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

    // Token sold mapping to delivery
    mapping(address => uint256) private tokenSoldMapping;

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
        uint256 raiseAmount,
        uint8 liquidityLocking,
        address wallet,
        address owner
    );
    event AllowTokenToTradeWithRate(address token, uint256 rate);
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
        buyTokenByEther();
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
        uint256 _raiseAmount,
        uint8 _liquidityLocking,
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
        raiseAmount = _raiseAmount;
        liquidityLocking = _liquidityLocking;
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
            raiseAmount,
            liquidityLocking,
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
     * @notice Returns the percentage of tokens will be locked on Unicrypt
     * @return Returns only a fixed number of liquidity lock percentage.
     */
    function getLiquidityLockingPercentage() public view returns (uint8) {
        return liquidityLocking;
    }

    /**
     * @notice Returns the conversion rate decimals when user buy by eth
     * @return Returns only a fixed number of decimals.
     */
    function getEtherConversionRateDecimals() public view returns (uint256) {
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
        return raiseAmount.sub(tokenSold);
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
        require(_closeTime > releaseTime, "ICO_CAMPAIGN::INVALID_TIME");
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
            tokenSoldMapping[_beneficiary] + _tokenAmount <=
                etherConversionRate
                    .mul(1 ether)
                    .mul(100000000000)
                    .div(getLatestEthPrice())
                    .div(10**etherConversionRateDecimals),
            "ICO_CAMPAIGN::MAX_1000_USD_TOTAL"
        );
        require(
            getAvailableTokens() >= _tokenAmount,
            "ICO_CAMPAIGN::TOKEN_NOT_ENOUGH"
        );
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.1;

interface ICampaignFactory {
    function getPlatformFeeRate() external view returns (uint256);
    function getplatformRevenueAddress() external view returns (address);
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

    function addToBlacklist(address _address) public onlyOwner {
        require(_address != address(0), "ICO_CAMPAIGN::INVALID_WALLET");
        blacklist[_address] = true;
        emit AddedToBlacklist(_address);
    }

    function addToBlacklistBatch(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklist[_addresses[i]] = true;
        }
        emit AddedToBlacklistInBatch(_addresses);
    }

    function removeFromBlacklist(address _address) public onlyOwner {
        require(_address != address(0), "ICO_CAMPAIGN::INVALID_WALLET");
        blacklist[_address] = false;
        emit RemovedFromBlacklist(_address);
    }

    function removeFromBlacklistBatch(address[] memory _addresses)
        public
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
    uint256 public minHeldTokens = 100 ether;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "ICO_CAMPAIGN::NOT_WHITELISTED");
        _;
    }

    function addToWhitelist(address _address) public onlyOwner {
        require(_address != address(0), "ICO_CAMPAIGN::INVALID_WALLET");
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function addToWhitelistBatch(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
        emit AddedToWhitelistInBatch(_addresses);
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        require(_address != address(0), "ICO_CAMPAIGN::INVALID_WALLET");
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function removeFromWhitelistBatch(address[] memory _addresses)
        public
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

    function isWhitelisted(address _address) public view returns (bool) {
        if (doubleCheck) {
            return
            whitelist[_address] &&
            jigStack.balanceOf(_address) >= minHeldTokens;
        }
        else {
            return
            whitelist[_address] ||
            jigStack.balanceOf(_address) >= minHeldTokens;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}