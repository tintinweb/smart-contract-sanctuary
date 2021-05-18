pragma solidity ^0.4.23;

//import "./MintedCrowdsale.sol";
//import "./CappedCrowdsale.sol";
//import "./RefundableCrowdsale.sol";
import "./Token.sol";
import "./ERC20.sol";

contract Vesting {

  function addTokenGrant(address _recipient, uint256 _startTime, uint128 _amount, uint16 _vestingDuration, uint16 _vestingCliff) public;

  /// @notice Terminate token grant transferring all vested tokens to the `_recipient`
  /// and returning all non-vested tokens to the Colony MultiSig
  /// Secured to the Colony MultiSig only
  /// @param _recipient Address of the token grant recipient
  function removeTokenGrant(address _recipient) public;

  /// @notice Allows a grant recipient to claim their vested tokens. Errors if no tokens have vested
  /// It is advised recipients check they are entitled to claim via `calculateGrantClaim` before calling this
  function claimVestedTokens() public;

  /// @notice Calculate the vested and unclaimed months and tokens available for `_recepient` to claim
  /// Due to rounding errors once grant duration is reached, returns the entire left grant amount
  /// Returns (0, 0) if cliff has not been reached
  function calculateGrantClaim(address _recipient) public view returns (uint16, uint128);
}

/**
 * @title ExampleCrowdsale
 * @dev Minted refundable crowdsale with min and max cap, min purchase, pre-sale and sale time and rate
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    address public owner;

    ERC20 public usdt;

    Vesting public vesting;

    uint256 public openingTime = 1621328000; // May 18th 16:30
    uint256 public closingTime = 1621701001; // May 22th 16:31

    uint256 public tokensBaught;
    uint256 public usdtDecimals;

    uint256 public preSaleRate = 12; // 0.12 usd per token
    uint256 public saleRate = 20; // 0.20 usd per token
    uint256 public finalRate = 20; // 0.20 usd per token; // x 1000

    uint256 public immediateRelease = 15; // 15% released immediatly on TGE

    uint256 public preSaleTime = 1621331400; // May 20th 16:30
    uint256 public saleTime = 1621701000; // May 22th 16:30

   // uint256 public minPurchase;

    uint256 public capStage01 = 2500000; // max tokens available for sale
    uint256 public capStage02 = 2500000; // max tokens available for sale

    uint256 public maxInvestStage01 = 6000; // in usd
    uint256 public maxInvestStage02 = 1250; // in usd

    uint256 public oneEth = 1000000000000000000;

    uint256 public usdtPrice = 4100;

    uint256 public usdtRate = oneEth.div(usdtPrice);

    uint256 public usdtRaised;

    mapping(address => bool) public whitelist;

    mapping(address => bool) public whitelist2;

    constructor
    (

        address _wallet,
        Token _token,
        ERC20 _usdt,
        Vesting _vesting
    )
    public

    {
        wallet = _wallet;
        usdt = _usdt;
        vesting = _vesting;
        token = _token;
        token.approve(address(this), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00);
        owner = msg.sender;

    }

      // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

   function setUsdtrate(uint256 _newPrice) public onlyOwner{
     usdtRate = oneEth.div(_newPrice);
   }


  function buyTokensUsdt(uint256 _amountUsdt, address _beneficiary) public {

    if (block.timestamp <= preSaleTime){
        _preValidatePurchase(_beneficiary, _amountUsdt);

    }
    if (block.timestamp > preSaleTime && block.timestamp <= saleTime){
        _preValidatePurchase2(_beneficiary, _amountUsdt);

    }

    usdtRaised = usdtRaised.add(_amountUsdt);
    _amountUsdt = _amountUsdt.mul(10**usdt.decimals());
    usdt.approve(address(this), _amountUsdt);
    usdt.transferFrom(msg.sender, wallet, _amountUsdt);
    // calculate token amount to be created
    uint256 tokens = _getTokenAmountUsdt(_amountUsdt);

    tokensBaught = tokens;
    usdtDecimals = usdt.decimals();

    uint256 released = tokens.mul(immediateRelease).div(100); // 15% TGE release

    token.transferFrom(wallet, msg.sender, released);

    uint256 vested = tokens.sub(released);

    token.transferFrom(wallet, address(vesting), vested);

    vesting.addTokenGrant(_beneficiary, block.timestamp, uint128(vested), uint16(4), uint16(1)); // 4 months vesting

  }

  modifier onlyOwner() {
      require(msg.sender == owner, "not allowed");
      _;
    }

    /**
     * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
     */
    modifier isWhitelisted(address _beneficiary) {
      require(whitelist[_beneficiary]);
      _;
    }

    /**
     * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
     */
    modifier isWhitelisted2(address _beneficiary) {
      require(whitelist2[_beneficiary]);
      _;
    }

    /**
     * @dev Adds single address to whitelist.
     * @param _beneficiary Address to be added to the whitelist
     */
    function addToWhitelist(address _beneficiary) external onlyOwner {
      whitelist[_beneficiary] = true;
    }

    function addToWhitelist2(address _beneficiary) external onlyOwner {
      whitelist2[_beneficiary] = true;
    }

    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
      whitelist[_beneficiary] = false;
    }

    function removeFromWhitelist2(address _beneficiary) external onlyOwner {
      whitelist2[_beneficiary] = false;
    }

    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelist
     */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
      for (uint256 i = 0; i < _beneficiaries.length; i++) {
        whitelist[_beneficiaries[i]] = true;
      }
    }

    function addManyToWhitelist2(address[] _beneficiaries) external onlyOwner {
      for (uint256 i = 0; i < _beneficiaries.length; i++) {
        whitelist2[_beneficiaries[i]] = true;
      }
    }

  /**
   * @dev Income value should be greater than min purchase
   */
    function _preValidatePurchase(
      address _beneficiary,
      uint256 _usdtAmount
    )
    internal
    view
    isWhitelisted(_beneficiary)
    {
        require(_beneficiary != address(0));
        require(_usdtAmount != 0);
        require(_usdtAmount <= maxInvestStage01);
    }

    function _preValidatePurchase2(
      address _beneficiary,
      uint256 _usdtAmount
    )
    internal
    view
    isWhitelisted2(_beneficiary)
    {
        require(_beneficiary != address(0));
        require(_usdtAmount != 0);
        require(_usdtAmount <= maxInvestStage02);
    }

    /**
   * @dev Determines how BNB is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  /**
   * @dev Returns the rate of tokens per wei at the present time.
   * Note that, as price _increases_ with time, the rate _decreases_.
   * @return The number of tokens a buyer gets per wei at a given time
   */
    function getCurrentRate() public view returns (uint256) {
        if (block.timestamp <= preSaleTime){
            return preSaleRate;
        }
        if (block.timestamp <= saleTime){
            return saleRate;
        }
        return finalRate;
    }

  /**
   * @dev Overrides parent method taking into account variable rate.
   * @param _weiAmount The value in wei to be converted into tokens
   * @return The number of tokens _weiAmount wei will buy at present time
   */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentRate = getCurrentRate();
        return currentRate.mul(_weiAmount);

    }

    function _getTokenAmountUsdt(uint256 _usdtAmount) internal view returns (uint256) {
        uint256 currentRate = getCurrentRate();
        return (currentRate.mul(_usdtAmount)).div(100);

    }
}