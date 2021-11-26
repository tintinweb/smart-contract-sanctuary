// Copyright (c) 2020 The UNION Protocol Foundation
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "hardhat/console.sol";

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Context } from "@openzeppelin/contracts/GSN/Context.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { UnionGovernanceToken } from "./UnionGovernanceToken.sol";
import { DateTime } from "./util/DateTime.sol";

/**
 * @title UNION Protocol Token Sale Contract
 */
contract UnionProtocolTokenSale is Context, AccessControl {

  using Address for address;
  using SafeMath for uint256;

  address private immutable unnGovernanceTokenAddress;

  bytes32 public constant ROLE_ADMIN = DEFAULT_ADMIN_ROLE; // default admin role from AccessControl
  bytes32 public constant ROLE_GOVERN = keccak256("ROLE_GOVERN");
  bytes32 public constant ROLE_MINT = keccak256("ROLE_MINT");

  address private constant BURN_ADDRESS = address(0);

  // These values are needed for calculation of token price where price is the function of token number x:
  // price(x) = uint256_tokenPriceFormulaSlope * x - uint256_tokenPriceFormulaIntercept
  uint256 private constant uint256_tokenPriceFormulaSlope = 9300000186;
  uint256 private constant uint256_tokenPriceFormulaIntercept = 8800000186000000000;

  address private immutable a_owner;

  // minimum and maximum USD contribution that buyer can make
  uint256 private constant MIN_PURCHASE_USD = 100;
  uint256 private constant MAX_PURCHASE_USD = 87000;

  //contract wallet addresses
  address private a_seedRoundAddress;
  address private a_privateRound1Address;
  address private a_privateRound2Address;
  address private a_publicSaleAddress;
  address private a_publicSaleBonusAddress;
  address private a_ecosystemPartnersTeamAddress;
  address private a_miningIncentivesPoolAddress;
  address private a_marketLiquidityPoolAddress;
  address private a_supplyReservePoolAddress;


  bool private b_saleStarted = false;
  bool private b_tokenGenerationPerformed = false;
  bool private b_tokenAllocationPerformed = false;
  uint256 private constant uint256_tokenSupplyScale = 10**18;
  address private immutable a_precheckContributionWallet;
  address private immutable a_saleContributionWallet;
  uint256 private uint256_currentTokenNumber = 950000001;
  uint256 private constant uint256_publicSaleFirstTokenNumber = 950000001;
  uint256 private constant uint256_publicSaleLastTokenNumber = 1000000000;
  uint256 private uint256_minNumberOfIntegerTokensToBePurchased = 1;
  uint256 private uint256_maxNumberOfIntegerTokensToBePurchased = 50000000;

  //token sale lock parameters
  uint256 private uint256_bonusTokenFactor = 20;
  uint256 private uint256_bonusTokenLockPeriodInMonths = 12;

  /**
   * @notice Struct for permitted account
   * @member permittedAddress
   * @member isApproved
   * @member isPrecheck
   * @member amount
   */
  struct PermittedAccount {
    bool isApproved;
    bool isPrecheck;
    uint256 amount;
  }

  /**
  * @notice Struct for storing allowed stablecoin tokens
  */
  struct PermittedToken {
    address tokenAddress;
    uint256 tokenDecimals;
  }

  /**
   * @notice Struct for tracing token transfer transactions
   * @member transactionTimestamp
   * @member tokenRecipient
   * @member tokenReceived
   * @member tokenAmountReceived
   * @member amountUNNSent
   * @member success
   */
  struct TokenTransferRecord {
    uint256 transactionTimestamp;
    address tokenRecipient;
    bytes32 tokenReceived;
    uint256 tokenAmountReceived;
    uint256 amountUNNSent;
    uint256 amountBonusUNNSent;
    bool success;
  }

  /**
   * @dev mapping from a transaction id to initiating senders
   */
  mapping(address => uint[]) public m_transactionIndexesToSender;

  /**
   * @dev a list of all successful/unsuccessful token transfers
   */
  TokenTransferRecord[] public l_tokenTransactions;

  /**
   * @dev mapping of supported tokens for receipt
   */
  mapping(bytes32 => PermittedToken) public m_permittedStablecoins;

  /**
   * @dev mapping of accounts permitted to purchase
   */
  mapping(address => PermittedAccount) private m_permittedAccounts;

  /**
   * @dev mapping of initial balances of wallets needed for preallocation
   */
  mapping(address => uint256) private m_saleWalletBalances;

  /**
   * @dev mapping containing user's total contribution during sale process
   */
  mapping(address => uint256) private m_purchasedTokensInUsd;


  /**
 * @dev constructor
 * @param _unnGovernanceTokenAddress Union Governance Token address
 * @param _precheckContributionWallet wallet for funds received from participants who have been prechecked
 * @param _saleContributionWallet wallet for funds received from participants who KYC during sale
 * @param _seedWallet seed wallet
 * @param _privateSale1Wallet private sale 1 wallet
 * @param _privateSale2Wallet private sale 2 wallet
 * @param _publicSaleWallet public sale wallet
 * @param _publicSaleBonusWallet public sale bonus wallet
 * @param _ecosystemPartnersTeamWallet ecosystem, partners, team wallet
 * @param _miningIncentivesWallet mining incentives wallet
 * @param _marketLiquidityWallet market liquidity wallet
 * @param _supplyReservePoolWallet supply reserve pool wallet
 */
  constructor(
    address _unnGovernanceTokenAddress,
    address _precheckContributionWallet,
    address _saleContributionWallet,
    address _seedWallet,
    address _privateSale1Wallet,
    address _privateSale2Wallet,
    address _publicSaleWallet,
    address _publicSaleBonusWallet,
    address _ecosystemPartnersTeamWallet,
    address _miningIncentivesWallet,
    address _marketLiquidityWallet,
    address _supplyReservePoolWallet
  ) public {
    a_owner = _msgSender();
    _setupRole(ROLE_ADMIN, _msgSender());
    unnGovernanceTokenAddress = _unnGovernanceTokenAddress;
    // wallets setup
    a_precheckContributionWallet = _precheckContributionWallet;
    a_saleContributionWallet = _saleContributionWallet;
    a_seedRoundAddress = _seedWallet;
    a_privateRound1Address = _privateSale1Wallet;
    a_privateRound2Address = _privateSale2Wallet;
    a_publicSaleAddress = _publicSaleWallet;
    a_publicSaleBonusAddress = _publicSaleBonusWallet;
    a_ecosystemPartnersTeamAddress = _ecosystemPartnersTeamWallet;
    a_miningIncentivesPoolAddress = _miningIncentivesWallet;
    a_marketLiquidityPoolAddress = _marketLiquidityWallet;
    a_supplyReservePoolAddress = _supplyReservePoolWallet;

    emit UnionProtocolTokenSaleContractInstalled(true);
  }


  /**
   * @dev add token to list of supported tokens
   * @param _tokenSymbol symbol of token supported as identifier in mapping
   * @param _tokenAddress address of token supported as value in mapping
   */
  function addSupportedToken(bytes32 _tokenSymbol, address _tokenAddress, uint256 _decimals) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(
      _tokenAddress != BURN_ADDRESS,
      "UPTS_ERROR: given address not allowed to be address zero"
    );
    require(
      _decimals > 0 && _decimals <= 18,
      "UPTS_ERROR: wrong number of decimals provided. Should be >0 and <=18"
    );
    require(
      getSupportedTokenAddress(_tokenSymbol) == BURN_ADDRESS
      && getSupportedTokenDecimals(_tokenSymbol) == 0,
      "UPTS_ERROR: Token already exists. Remove it before modifying"
    );

    PermittedToken storage permittedToken = m_permittedStablecoins[_tokenSymbol];
    permittedToken.tokenAddress = _tokenAddress;
    permittedToken.tokenDecimals = _decimals;
    m_permittedStablecoins[_tokenSymbol] = permittedToken;
  }

  /**
   * @dev remove token from list of supported tokens
   * @param _tokenSymbol symbol of token being removed
   */
  function removeSupportedToken(bytes32 _tokenSymbol) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    delete(m_permittedStablecoins[_tokenSymbol]);
  }


  /**
   * @dev get the address for a supported, given token symbol
   * @param _tokenSymbol symbol of token address being queried
   */
  function getSupportedTokenAddress(bytes32 _tokenSymbol) public view returns (address) {
    return m_permittedStablecoins[_tokenSymbol].tokenAddress;
  }

  /**
   * @dev get the decimal number for a supported, given token symbol
   * @param _tokenSymbol symbol of token address being queried
   */
  function getSupportedTokenDecimals(bytes32 _tokenSymbol) public view returns (uint256) {
    return m_permittedStablecoins[_tokenSymbol].tokenDecimals;
  }

  /**
  * @dev set the bonus token percentage
  * @param _newFactor new percentage value of tokens bought for bonus token amount
  */
  function setBonusTokenFactor(uint256 _newFactor) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(
      _newFactor >= 1 && _newFactor <= 500,
      "UPTS_ERROR: illegal bonus token factor value"
    );

    uint256_bonusTokenFactor = _newFactor;
    emit BonusTokenFactorChanged(_newFactor);
  }

  /**
  * @dev returns the bonus token factor
  */
  function getBonusTokenFactor() public view returns (uint256) {
    return uint256_bonusTokenFactor;
  }

  /**
  * @dev sets the bonus token lock period
  * @param _newPeriod new period to be set in months
  */
  function setBonusTokenLockPeriod(uint256 _newPeriod) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_newPeriod >= 1 && _newPeriod <= 60, "UPTS_ERROR: illegal lock period value");

    uint256_bonusTokenLockPeriodInMonths = _newPeriod;
    emit BonusTokenLockPeriodChanged(_newPeriod);
  }

  function getBonusTokenLockPeriod() public view returns (uint256) {
    return uint256_bonusTokenLockPeriodInMonths;
  }

  /**
   * @dev Add a user wallet to the permitted list to allow for purchasing
   * @param _address address being added to the permitted participant list
   * @param _isApproved whether address has been approved
   * @param _isPrecheck whether address was part of earlier KYC independent of sale period
   * @param _amount amount for which the user has been approved
   */
  function addToPermittedList(address _address, bool _isApproved, bool _isPrecheck, uint256 _amount) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_address != BURN_ADDRESS, "UPTS_ERROR: address cannot be address zero");
    PermittedAccount storage account = m_permittedAccounts[_address];
    account.isApproved = _isApproved;
    account.isPrecheck = _isPrecheck;
    account.amount = _amount;

    emit UnionProtocolTokenSaleNewAccountPermittedListModification(_address, _isApproved, _isPrecheck, _amount);
  }

  /**
  *
  */
  function _calculateBonusTokenAmount(uint256 _tokenAmount) private view returns (uint256) {
    return _tokenAmount.mul(uint256_tokenSupplyScale).mul(uint256_bonusTokenFactor).div(100);
  }


  /**
   * @dev Check whether address is approved for purchase
   * @param _address Address being checked for approval
   * @return bool whether address is approved for purchase
   */
  function getAddressPermittedApprovalStatus(address _address) public view returns (bool) {
   return m_permittedAccounts[_address].isApproved;
}

  /**
  * @dev Check whether address is prechecked before proper KYC
  * @param _address Address being checked
  * @return bool whether address was prechecked
  */
  function getAddressPermittedPrecheck(address _address) public view returns (bool) {
    return m_permittedAccounts[_address].isPrecheck;
  }

  /**
   * @dev Provides remaining allowance for a permitted address -- addresses that are not permitted return 0
   * @param _address Address being verified for remaining balance at approved kyc, addresses that have not been approved will have amounts of 0.
   */
  function getAddressRemainingPermittedAmount(address _address) public view returns (uint256) {
    return m_permittedAccounts[_address].amount;
  }


  /**
   * @dev removes account from permitted accounts map
   * @param _address address being removed from permitted account map
   */
  function removeFromPermittedList(address _address) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_address != BURN_ADDRESS, "UPTS_ERROR: address cannot be address zero");

    delete(m_permittedAccounts[_address]);
  }

  /**
  * @dev configure wallet preallocation
  */
  function performTokenGeneration() public {
    require(
      hasRole(ROLE_ADMIN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(
      a_seedRoundAddress != BURN_ADDRESS &&
      a_privateRound1Address != BURN_ADDRESS &&
      a_privateRound2Address != BURN_ADDRESS &&
      a_publicSaleAddress != BURN_ADDRESS &&
      a_ecosystemPartnersTeamAddress != BURN_ADDRESS &&
      a_miningIncentivesPoolAddress != BURN_ADDRESS &&
      a_marketLiquidityPoolAddress != BURN_ADDRESS &&
      a_supplyReservePoolAddress != BURN_ADDRESS,
        "UPTS_ERROR: token generation failed because one of the preallocation wallets address is set to address zero"
    );
    require(
      !isTokenGenerationPerformed(),
      "UPTS_ERROR: token generation has already been performed"
    );

    m_saleWalletBalances[a_ecosystemPartnersTeamAddress] = 100000000 * uint256_tokenSupplyScale; // * uint256_tokenSupplyScale;
    m_saleWalletBalances[a_miningIncentivesPoolAddress] =  150000000 * uint256_tokenSupplyScale; // * uint256_tokenSupplyScale;
    m_saleWalletBalances[a_marketLiquidityPoolAddress] =   100000000 * uint256_tokenSupplyScale; // * uint256_tokenSupplyScale;
    m_saleWalletBalances[a_supplyReservePoolAddress] =     250000000 * uint256_tokenSupplyScale; // * uint256_tokenSupplyScale;
    m_saleWalletBalances[a_seedRoundAddress] =     100000000 * uint256_tokenSupplyScale; // * uint256_tokenSupplyScale;
    m_saleWalletBalances[a_privateRound1Address] = 200000000 * uint256_tokenSupplyScale; // * uint256_tokenSupplyScale;
    m_saleWalletBalances[a_privateRound2Address] = 50000000 * uint256_tokenSupplyScale; // * uint256_tokenSupplyScale;
    m_saleWalletBalances[a_publicSaleAddress] =    50000000 * uint256_tokenSupplyScale; // * uint256_tokenSupplyScale;

    b_tokenGenerationPerformed = true;
    emit UnionProtocolTokenSaleTokenGenerationComplete(true);
  }

  function isTokenGenerationPerformed() public view returns (bool) {
    return b_tokenGenerationPerformed;
  }

  function isTokenAllocationPerformed() public view returns (bool) {
    return b_tokenAllocationPerformed;
  }


  /**
   * @dev Transfers tokens to predefined addresses
   */
  function transferTokensToPredefinedAddresses() public {
    require(hasRole(ROLE_ADMIN, _msgSender()), "UPTS_ERROR: operation not allowed for current user");
    require(isTokenGenerationPerformed(), "UPTS_ERROR: token generation has not been performed");
    require(!isTokenAllocationPerformed(), "UPTS_ERROR: token allocation has already been performed");

    UnionGovernanceToken unnGovernanceToken = getGovernanceToken();

    unnGovernanceToken.transferFrom(
      a_owner,
      a_seedRoundAddress,
      m_saleWalletBalances[a_seedRoundAddress]
    );
    emit TokenTransferSuccess(address(this), a_seedRoundAddress, m_saleWalletBalances[a_seedRoundAddress]);

    unnGovernanceToken.transferFrom(
      a_owner,
      a_publicSaleAddress,
      m_saleWalletBalances[a_publicSaleAddress]
    );

    unnGovernanceToken.transferFrom(
      a_owner,
      a_privateRound1Address,
      m_saleWalletBalances[a_privateRound1Address]
    );
    emit TokenTransferSuccess(address(this), a_privateRound1Address, m_saleWalletBalances[a_privateRound1Address]);

    unnGovernanceToken.transferFrom(
      a_owner,
      a_privateRound2Address,
      m_saleWalletBalances[a_privateRound2Address]
    );
    emit TokenTransferSuccess(address(this), a_privateRound2Address, m_saleWalletBalances[a_privateRound2Address]);

    unnGovernanceToken.transferFrom(
      a_owner,
      a_supplyReservePoolAddress,
      m_saleWalletBalances[a_supplyReservePoolAddress]
    );
    emit TokenTransferSuccess(address(this), a_supplyReservePoolAddress, m_saleWalletBalances[a_supplyReservePoolAddress]);

    unnGovernanceToken.transferFrom(
      a_owner,
      a_miningIncentivesPoolAddress,
      m_saleWalletBalances[a_miningIncentivesPoolAddress]
    );
    emit TokenTransferSuccess(address(this), a_miningIncentivesPoolAddress, m_saleWalletBalances[a_miningIncentivesPoolAddress]);

    unnGovernanceToken.transferFrom(
      a_owner,
      a_marketLiquidityPoolAddress,
      m_saleWalletBalances[a_marketLiquidityPoolAddress]
    );
    emit TokenTransferSuccess(address(this), a_marketLiquidityPoolAddress, m_saleWalletBalances[a_marketLiquidityPoolAddress]);

    unnGovernanceToken.transferFrom(
      a_owner,
      a_ecosystemPartnersTeamAddress,
      m_saleWalletBalances[a_ecosystemPartnersTeamAddress]
    );
    emit TokenTransferSuccess(address(this), a_ecosystemPartnersTeamAddress, m_saleWalletBalances[a_ecosystemPartnersTeamAddress]);

    b_tokenAllocationPerformed = true;
  }

  /**
   * @dev Called by contract owner to start token sale
   */
  function startSale() public {
    require(hasRole(ROLE_ADMIN, _msgSender()), "UPTS_ERROR: operation not allowed for current user");
    require(isTokenGenerationPerformed(), "UPTS_ERROR: token generation was not performed");
    require(!isSaleStarted(), "UPTS_ERROR: the sale has already started");

    b_saleStarted = true;
    emit UnionProtocolTokenSaleStarted(true);
  }

  /**
   * @dev Called by contract owner to end or suspend token sale
   */
  function endSale() public {
    require(hasRole(ROLE_ADMIN, _msgSender()), "UPTS_ERROR: operation not allowed for current user");
    require(isTokenGenerationPerformed(), "UPTS_ERROR: token generation was not performed");
    require(isSaleStarted(), "UPTS_ERROR: the sale hasn't started yet");

    b_saleStarted = false;
    emit UnionProtocolTokenSaleStarted(false);
  }

  /**
  * @dev Returns the sale status
  */
  function isSaleStarted() public view returns (bool) {
    return b_saleStarted;
  }

  /**
   * @dev Retrieves the number of the next token available for purchase
   */
  function getCurrentTokenNumber() public view returns (uint256) {
    return uint256_currentTokenNumber;
  }

  /**
   * @dev Sets seed round wallet address
   * @param _address Address of seed round token wallet
   */
  function setSeedRoundAddress(address _address) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_address != BURN_ADDRESS, "UPTS_ERROR: address cannot be address zero");
    a_seedRoundAddress = _address;
  }

  /**
  * @dev returns the seed round wallet address
  */
  function getSeedRoundAddress()  public view returns (address){
    return a_seedRoundAddress;
  }


  /**
   * @dev Sets private round 1 wallet address
   * @param _address Address of private round 1 token wallet
   */
  function setPrivateRound1Address(address _address) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_address != BURN_ADDRESS, "UPTS_ERROR: address cannot be address zero");
    a_privateRound1Address = _address;
  }

  /**
  * @dev returns the private round 1 wallet address
  */
  function getPrivateRound1Address()  public view returns (address){
    return a_privateRound1Address;
  }


  /**
   * @dev Sets private round 2 wallet address
   * @param _address Address of private round 2 token wallet
   */
  function setPrivateRound2Address(address _address) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_address != BURN_ADDRESS, "UPTS_ERROR: address cannot be address zero");
    a_privateRound2Address = _address;
  }

  /**
  * @dev returns the private round 2 wallet address
  */
  function getPrivateRound2Address()  public view returns (address){
    return a_privateRound2Address;
  }


  /**
   * @dev Sets public sale wallet address
   * @param _address Address of public sale token wallet
   */
  function setPublicSaleAddress(address _address) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_address != BURN_ADDRESS, "UPTS_ERROR: address cannot be address zero");
    a_publicSaleAddress = _address;
  }

  /**
  * @dev returns the public sale wallet address
  */
  function getPublicSaleAddress()  public view returns (address){
    return a_publicSaleAddress;
  }


  /**
   * @dev Sets ecosystem, partners, and team wallet address
   * @param _address Address of ecosystem, partners, and team token wallet
   */
  function setEcosystemPartnersTeamAddress(address _address) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_address != BURN_ADDRESS, "UPTS_ERROR: address cannot be address zero");
    a_ecosystemPartnersTeamAddress = _address;
  }

  /**
  * @dev returns the ecosystem, partners and team wallet address
  */
  function getEcosystemPartnersTeamAddress()  public view returns (address){
    return a_ecosystemPartnersTeamAddress;
  }


  /**
   * @dev Sets mining incentives pool wallet address
   * @param _address Address of mining incentives pool token wallet
   */
  function setMiningIncentivesPoolAddress(address _address) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_address != BURN_ADDRESS, "UPTS_ERROR: address cannot be address zero");
    a_miningIncentivesPoolAddress = _address;
  }

  /**
  * @dev returns the mining incentives pool wallet address
  */
  function getMiningIncentivesPoolAddress()  public view returns (address){
    return a_miningIncentivesPoolAddress;
  }


  /**
   * @dev Sets market liquidity pool wallet address
   * @param _address Address of market liquidity pool token wallet
   */
  function setMarketLiquidityPoolAddress(address _address) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_address != BURN_ADDRESS, "UPTS_ERROR: address cannot be address zero");
    a_marketLiquidityPoolAddress = _address;
  }

  /**
  * @dev returns the market liquidity pool wallet address
  */
  function getMarketLiquidityPoolAddress()  public view returns (address){
    return a_marketLiquidityPoolAddress;
  }


  /**
   * @dev Sets supply reserve pool wallet address
   * @param _address Address of supply reserve pool token wallet
   */
  function setSupplyReservePoolAddress(address _address) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_address != BURN_ADDRESS, "UPTS_ERROR: address cannot be address zero");
    a_supplyReservePoolAddress = _address;
  }

  /**
  * @dev returns the supply reserve pool wallet address
  */
  function getSupplyReservePoolAddress()  public view returns (address){
    return a_supplyReservePoolAddress;
  }

  /**
  * @dev sets the minimum value of tokens to be purchased in public sale
  */
  function setMinimumTokenPurchaseAmount(uint256 _amount) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_amount > 0, "UPTS_ERROR: token amount too small");
    require(_amount <= uint256_maxNumberOfIntegerTokensToBePurchased, "UPTS_ERROR: token amount cannot exceed maximum token number");
    uint256_minNumberOfIntegerTokensToBePurchased = _amount;
  }

  /**
  * @dev sets the maximum value of tokens to be purchased in public sale
  */
  function setMaximumTokenPurchaseAmount(uint256 _amount) public {
    require(
      hasRole(ROLE_ADMIN, _msgSender())
      || hasRole(ROLE_GOVERN, _msgSender()),
      "UPTS_ERROR: operation not allowed for current user"
    );
    require(_amount >= uint256_minNumberOfIntegerTokensToBePurchased);
    uint256_maxNumberOfIntegerTokensToBePurchased = _amount;
  }


  /**
   * @dev calculate the price for a specific token number which is a linear function of the token number
   * @param _number number (in whole tokens, not Wei) of the token for which the price is being calculated
   * @return token price for specifed token number
   */
  function getTokenPrice(uint256 _number) public pure returns (uint256) {
    require(
      _number >= uint256_publicSaleFirstTokenNumber && _number <= uint256_publicSaleLastTokenNumber,
        "UPTS_ERROR: token number is out of sale bounds"
    );

    return uint256_tokenPriceFormulaSlope.mul(_number).sub(uint256_tokenPriceFormulaIntercept);
  }


  /**
   * @dev calculate the price in USD for a specific quantity of tokens
   * @param _integerAmount number of integer tokens for which the price is being calculated
   * @return price for specified number of tokens
   */
  function getBuyPriceInUSD(uint256 _integerAmount) public view returns (uint256) {
    require(
      _integerAmount >= uint256_minNumberOfIntegerTokensToBePurchased,
      "UPTS_ERROR: number of tokens for purchase is below minimum"
    );
    require(
      _integerAmount <= uint256_maxNumberOfIntegerTokensToBePurchased,
      "UPTS_ERROR: number of tokens for purchase is above maximum"
    );
    require(
      (uint256_currentTokenNumber + _integerAmount) <= uint256_publicSaleLastTokenNumber,
      "UPTS_ERROR: number of tokens to buy exceeds the sale pool"
    );

    uint256 lastTokenPrice = getTokenPrice(_integerAmount.add(uint256_currentTokenNumber).sub(1));
    uint256 firstTokenPrice = getTokenPrice(uint256_currentTokenNumber);
    // calculate the sum of arithmetic sequence
    return(firstTokenPrice.add(lastTokenPrice)).mul(_integerAmount).div(2);
  }

  /**
  * @dev returns the interface for the stablecoin token required for payments
  */
  function getERC20Token(address _address) private pure returns (IERC20) {
    return IERC20(_address);
  }

  /**
   * @dev returns the governance token instance
   */
  function getGovernanceToken() private view returns (UnionGovernanceToken){
    return UnionGovernanceToken(unnGovernanceTokenAddress);
  }

  /**
   * @dev returns value in the given stablecoin
   */
  function getBuyPriceInPermittedStablecoin(bytes32 _tokenSymbol, uint256 _amount) public view returns (uint256) {
    require(
      getSupportedTokenDecimals(_tokenSymbol) > 0,
      "UPTS_ERROR: stablecoin token with the given symbol is not allowed"
    );
    uint256 usdValue = getBuyPriceInUSD(_amount);
    if (getSupportedTokenDecimals(_tokenSymbol) < 18) {
      return usdValue.div(10 ** (18 - getSupportedTokenDecimals(_tokenSymbol)));
    } else {
      return usdValue;
    }
  }

  /**
   * @dev helper function for calculating square root
   */
  function sqrt(uint y) public pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  /**
   * @dev calculates maximum number of integer tokens to be bought for the given USD contribution
   * @param _USDContribution contribution in USD in Wei
   */
  function getTokenAmountForUSDContribution(int256 _USDContribution) public view returns (int256) {
    int256 int256_currentTokenNumber = int256(uint256_currentTokenNumber);
    int256 preSqrt = (86490003459600034596 * (int256_currentTokenNumber ** 2)) - (163680006819690072651600034596 * int256_currentTokenNumber) + (18600000372 * _USDContribution) + 77440003355440037984222535460900008649;
    int256 postSqrt = int256(sqrt(uint256(preSqrt)));
    int256 result = (postSqrt - (9300000186 * int256_currentTokenNumber) + 8800000190650000093) / 9300000186;
    return result;
  }

  /**
   * @dev public mechanism for buying tokens from smart contract. It needs the purchaser to previously approve his
   * ERC20 token amount in which he wishes to do payment.
   * Payments in tokens are not currently supported (Look EIP-1958)
   * @param _contributedTokenSymbol the token symbol in which payment will be performed
   * @param _contributionInUSD USD contribution in Wei
   */
  function purchaseTokens(bytes32 _contributedTokenSymbol, uint256 _contributionInUSD) public {
    require(isSaleStarted(), "UPTS_ERROR: sale has not started yet");
    require(getAddressPermittedApprovalStatus(_msgSender()), "UPTS_ERROR: user not authorised for purchase");

    uint256 _numberOfIntegerTokens = uint256(getTokenAmountForUSDContribution(int256(_contributionInUSD)));
    require(
      m_permittedAccounts[_msgSender()].amount >= _numberOfIntegerTokens,
        "UPTS_ERROR: insufficient number of tokens allowed for user to purchase"
    );

    address tokenAddress = getSupportedTokenAddress(_contributedTokenSymbol);
    require(
      tokenAddress != BURN_ADDRESS,
      "UPTS_ERROR: stablecoin token with the given symbol is not allowed for making payments"
    );

    IERC20 stablecoinToken = getERC20Token(tokenAddress);
    uint256 buyPriceInStablecoin = getBuyPriceInPermittedStablecoin(_contributedTokenSymbol, _numberOfIntegerTokens);
    uint256 buyPriceInUSD = buyPriceInStablecoin.div(10**getSupportedTokenDecimals(_contributedTokenSymbol));
    require(
      checkUserPurchaseTokenLimits(_msgSender(), buyPriceInUSD),
      "UPTS_ERROR: requested amount exceeds purchase limits"
    );

    // COLLECTING PAYMENT
    bool paymentCollected = _collectPaymentInStablecoin(_msgSender(), stablecoinToken, buyPriceInStablecoin);
    if (!paymentCollected) {
      revert("error with stablecoin payment");
    }

    // TRANSFER
    bool tokenTransferSuccess = _transferTokens(_msgSender(), _numberOfIntegerTokens);
    if (!tokenTransferSuccess) {
      revert("error with token transfer");
    }
    m_permittedAccounts[_msgSender()].amount = m_permittedAccounts[_msgSender()].amount.sub(_numberOfIntegerTokens);

    // BONUS TOKEN TRANSFER
    uint256 lockedTokenAmount = _calculateBonusTokenAmount(_numberOfIntegerTokens);
    bool bonusTokenTransferSuccess = _transferLockedTokens(_msgSender(), lockedTokenAmount);
    if (!bonusTokenTransferSuccess) {
      revert("error with bonus token transfer");
    }

    bool success = false;
    if(paymentCollected && tokenTransferSuccess && bonusTokenTransferSuccess) {
      success = true;
      m_purchasedTokensInUsd[_msgSender()] = m_purchasedTokensInUsd[_msgSender()].add(buyPriceInUSD);
    }

    TokenTransferRecord memory record;
    record.transactionTimestamp = now;
    record.tokenRecipient = _msgSender();
    record.tokenReceived = _contributedTokenSymbol;
    record.tokenAmountReceived = buyPriceInStablecoin;
    record.amountUNNSent = _numberOfIntegerTokens.mul(uint256_tokenSupplyScale);
    record.amountBonusUNNSent = lockedTokenAmount;
    record.success = success;

    l_tokenTransactions.push(record);

    emit TokensPurchased(_msgSender(), _numberOfIntegerTokens);
  }

  /**
   * @dev returns if user fits the limits for purchase
   */
  function checkUserPurchaseTokenLimits(address _buyer, uint256 _requestedAmountInUsd) public view returns (bool){
    return !((m_purchasedTokensInUsd[_buyer].add(_requestedAmountInUsd) > MAX_PURCHASE_USD) ||
      (_requestedAmountInUsd < MIN_PURCHASE_USD.sub(1)));
  }

  /**
  * @dev calls a TransferFrom method from the given stableoin token on the payer
  * @param _payer payer address
  * @param _stablecoinToken ERC20 instance of payment stablecoin
  * @param _amount payment amount
  */
  function _collectPaymentInStablecoin(address _payer, IERC20 _stablecoinToken, uint256 _amount) private returns (bool){
    require(
      _stablecoinToken.allowance(_payer, address(this)) >= _amount,
      "UPTS_ERROR: insuficient funds allowed for contract to perform purchase"
    );
    UnionGovernanceToken unnGovernanceToken = getGovernanceToken();
    require(
      unnGovernanceToken.allowance(a_publicSaleAddress, address(this)) >= _amount,
      "UPTS_ERROR: public sale wallet owner has not allowed requested UNN Token amount"
    );

    address incomingPaymentWallet;
    if (getAddressPermittedPrecheck(_payer)) {
      incomingPaymentWallet = a_precheckContributionWallet;
    } else {
      incomingPaymentWallet = a_saleContributionWallet;
    }
    return _stablecoinToken.transferFrom(_payer, incomingPaymentWallet, _amount);
  }

  /**
   * @dev handles the transfer of tokens to intended recipients-- requires that the sales contract is assumed to have
   * approval from the sender for designated amounts.  Uses transferFrom on ERC20 interface to send tokens to recipient
   */
 function _transferTokens(
     address _recipient,
     uint256 _integerAmount
 ) private returns (bool) {
   UnionGovernanceToken unnGovernanceToken = getGovernanceToken();
    bool success = unnGovernanceToken.transferFrom(
      a_publicSaleAddress,
      _recipient,
      _integerAmount.mul(uint256_tokenSupplyScale)
    );
    uint256_currentTokenNumber = uint256_currentTokenNumber.add(_integerAmount);

    emit TokenTransferSuccess(a_publicSaleAddress, _recipient, _integerAmount.mul(uint256_tokenSupplyScale));
    return success;
  }

  /**
  * @dev handles the transfer of bonus tokens to intended recipients
  */
  function _transferLockedTokens(
    address _recipient,
    uint256 _amount
  ) private returns (bool) {
    UnionGovernanceToken unnGovernanceToken = getGovernanceToken();
    require(
      unnGovernanceToken.allowance(a_publicSaleBonusAddress, address(this)) >= _amount,
      "UPTS_ERROR: public sale bonus tokens wallet owner has not allowed requested UNN Token amount"
    );
    uint256 releaseTime = _calculateReleaseTime();

    bool success = unnGovernanceToken.transferFromAndLock(
      a_publicSaleBonusAddress,
      _recipient,
      _amount,
      releaseTime,
      false
    );
    emit TokenTransferSuccess(a_publicSaleBonusAddress, _recipient, _amount);
    return success;
  }

  /**
  * @dev calculates the token release time timestamp based on current timestamp and lock period
  */
  function _calculateReleaseTime() private view returns (uint256) {
    uint256 timestamp = block.timestamp;
    uint16 year = DateTime.getYear(timestamp);
    uint8 month = DateTime.getMonth(timestamp);
    uint8 day = DateTime.getDay(timestamp);
    uint8 hour = DateTime.getHour(timestamp);
    uint8 minute = DateTime.getMinute(timestamp);
    uint8 second = DateTime.getSecond(timestamp);

    uint8 newPrecalculatedMonth = uint8(uint256(month).add(uint256_bonusTokenLockPeriodInMonths));
    uint16 yearAddition = uint16(uint256(newPrecalculatedMonth).div(12));
    uint16 newYear = year + yearAddition;
    uint8 newMonth = uint8(uint256(newPrecalculatedMonth).mod(12));
    uint8 daysInMonth = DateTime.getDaysInMonth(newMonth, newYear);
    if ( daysInMonth < day) {
      day = 1;
      newMonth = newMonth + 1;
    }
    uint256 lockTimestamp = DateTime.toTimestamp(newYear, newMonth, day, hour, minute, second);

    return lockTimestamp;
  }

  /**
   * @dev Called by contract owner to destroy the token sale contract and revert generated tokens to contract
   *   owner.  The sale must be stopped or paused prior to being killed.
   */
  function performContractKill() public {
    require(hasRole(ROLE_ADMIN, _msgSender()), "UPTS_ERROR: operation not allowed for current user");
    require(!isSaleStarted(), "UPTS_ERROR: sale is in progress. End the sale before killing contract");
    selfdestruct(_msgSender());
    emit UnionProtocolTokenSaleContractInstalled(false);
  }

  //Transfer-Related Events
  /**
   * @dev event emited when tokens are purchased
   */
  event TokensPurchased(address indexed _from, uint256 _amount);


  /**
   * @dev Event to notify of successful token transfer to recipients
   */
  event TokenTransferSuccess(address indexed _from, address indexed _to, uint256 _amount);

  /**
   * @dev Event to notify of failed token transfer to recipients
   */
  event TokenTransferFailed(address indexed _from, address indexed _to, uint256 _amount);

  /**
   * @dev Announces installation and deinstallation of the sale contract
   */
  event UnionProtocolTokenSaleContractInstalled(bool _installed);

  /**
   * @dev Announces token generation event completed
   */
  event UnionProtocolTokenSaleTokenGenerationComplete(bool _isComplete);

  /**
   * @dev Announces start/end of token sale
   */
  event UnionProtocolTokenSaleStarted(bool _status);

  /**
   * @dev Emits event when bonus token factor is changed
   */
  event BonusTokenFactorChanged(uint256 _tokenFactor);

  /**
   * @dev Emits event when bonus token lock period is changed
   */
  event BonusTokenLockPeriodChanged(uint256 _lockPeriod);

  /**
   * @dev Announces when a new account is added to permitted list of accounts for token sale
   */
  event UnionProtocolTokenSaleNewAccountPermittedListModification(address indexed _address, bool _isApproved, bool _isPrecheck, uint256 _amount);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.8.0;

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

	function logByte(byte p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(byte)", p0));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// Copyright (c) 2020 The UNION Protocol Foundation
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

/**
 * @title UNION Protocol Governance Token
 * @dev Implementation of the basic standard token.
 */
contract UnionGovernanceToken is AccessControl, IERC20 {

  using Address for address;
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @notice Struct for marking number of votes from a given block
   * @member from
   * @member votes
   */
  struct VotingCheckpoint {
    uint256 from;
    uint256 votes;
  }
 
  /**
   * @notice Struct for locked tokens
   * @member amount
   * @member releaseTime
   * @member votable
   */
  struct LockedTokens{
    uint amount;
    uint releaseTime;
    bool votable;
  }

  /**
  * @notice Struct for EIP712 Domain
  * @member name
  * @member version
  * @member chainId
  * @member verifyingContract
  * @member salt
  */
  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
    bytes32 salt;
  }

  /**
  * @notice Struct for EIP712 VotingDelegate call
  * @member owner
  * @member delegate
  * @member nonce
  * @member expirationTime
  */
  struct VotingDelegate {
    address owner;
    address delegate;
    uint256 nonce;
    uint256 expirationTime;
  }

  /**
  * @notice Struct for EIP712 Permit call
  * @member owner
  * @member spender
  * @member value
  * @member nonce
  * @member deadline
  */
  struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
  }

  /**
   * @notice Vote Delegation Events
   */
  event VotingDelegateChanged(address indexed _owner, address indexed _fromDelegate, address indexed _toDelegate);
  event VotingDelegateRemoved(address indexed _owner);
  
  /**
   * @notice Vote Balance Events
   * Emmitted when a delegate account's vote balance changes at the time of a written checkpoint
   */
  event VoteBalanceChanged(address indexed _account, uint256 _oldBalance, uint256 _newBalance);

  /**
   * @notice Transfer/Allocator Events
   */
  event TransferStatusChanged(bool _newTransferStatus);

  /**
   * @notice Reversion Events
   */
  event ReversionStatusChanged(bool _newReversionSetting);

  /**
   * @notice EIP-20 Approval event
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
  /**
   * @notice EIP-20 Transfer event
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Burn(address indexed _from, uint256 _value);
  event AddressPermitted(address indexed _account);
  event AddressRestricted(address indexed _account);

  /**
   * @dev AccessControl recognized roles
   */
  bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
  bytes32 public constant ROLE_ALLOCATE = keccak256("ROLE_ALLOCATE");
  bytes32 public constant ROLE_GOVERN = keccak256("ROLE_GOVERN");
  bytes32 public constant ROLE_MINT = keccak256("ROLE_MINT");
  bytes32 public constant ROLE_LOCK = keccak256("ROLE_LOCK");
  bytes32 public constant ROLE_TRUSTED = keccak256("ROLE_TRUSTED");
  bytes32 public constant ROLE_TEST = keccak256("ROLE_TEST");
   
  bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
  );
  bytes32 public constant DELEGATE_TYPEHASH = keccak256(
    "DelegateVote(address owner,address delegate,uint256 nonce,uint256 expirationTime)"
  );

  //keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  address private constant BURN_ADDRESS = address(0);
  address public UPGT_CONTRACT_ADDRESS;

  /**
   * @dev hashes to support EIP-712 signing and validating, EIP712DOMAIN_SEPARATOR is set at time of contract instantiation and token minting.
   */
  bytes32 public immutable EIP712DOMAIN_SEPARATOR;

  /**
   * @dev EIP-20 token name
   */
  string public name = "UNION Protocol Governance Token";

  /**
   * @dev EIP-20 token symbol
   */
  string public symbol = "UNN";

  /**
   * @dev EIP-20 token decimals
   */
  uint8 public decimals = 18;

  /**
   * @dev Contract version
   */
  string public constant version = '0.0.1';

  /**
   * @dev Initial amount of tokens
   */
  uint256 private uint256_initialSupply = 100000000000 * 10**18;

  /**
   * @dev Total amount of tokens
   */
  uint256 private uint256_totalSupply;

  /**
   * @dev Chain id
   */
  uint256 private uint256_chain_id;

  /**
   * @dev general transfer restricted as function of public sale not complete
   */
  bool private b_canTransfer = false;

  /**
   * @dev private variable that determines if failed EIP-20 functions revert() or return false.  Reversion short-circuits the return from these functions.
   */
  bool private b_revert = false; //false allows false return values

  /**
   * @dev Locked destinations list
   */
  mapping(address => bool) private m_lockedDestinations;

  /**
   * @dev EIP-20 allowance and balance maps
   */
  mapping(address => mapping(address => uint256)) private m_allowances;
  mapping(address => uint256) private m_balances;
  mapping(address => LockedTokens[]) private m_lockedBalances;

  /**
   * @dev nonces used by accounts to this contract for signing and validating signatures under EIP-712
   */
  mapping(address => uint256) private m_nonces;

  /**
   * @dev delegated account may for off-line vote delegation
   */
  mapping(address => address) private m_delegatedAccounts;

  /**
   * @dev delegated account inverse map is needed to live calculate voting power
   */
  mapping(address => EnumerableSet.AddressSet) private m_delegatedAccountsInverseMap;


  /**
   * @dev indexed mapping of vote checkpoints for each account
   */
  mapping(address => mapping(uint256 => VotingCheckpoint)) private m_votingCheckpoints;

  /**
   * @dev mapping of account addrresses to voting checkpoints
   */
  mapping(address => uint256) private m_accountVotingCheckpoints;

  /**
   * @dev Contructor for the token
   * @param _owner address of token contract owner
   * @param _initialSupply of tokens generated by this contract
   * Sets Transfer the total suppply to the owner.
   * Sets default admin role to the owner.
   * Sets ROLE_ALLOCATE to the owner.
   * Sets ROLE_GOVERN to the owner.
   * Sets ROLE_MINT to the owner.
   * Sets EIP 712 Domain Separator.
   */
  constructor(address _owner, uint256 _initialSupply) public {
    
    //set internal contract references
    UPGT_CONTRACT_ADDRESS = address(this);

    //setup roles using AccessControl
    _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    _setupRole(ROLE_ADMIN, _owner);
    _setupRole(ROLE_ADMIN, _msgSender());
    _setupRole(ROLE_ALLOCATE, _owner);
    _setupRole(ROLE_ALLOCATE, _msgSender());
    _setupRole(ROLE_TRUSTED, _owner);
    _setupRole(ROLE_TRUSTED, _msgSender());
    _setupRole(ROLE_GOVERN, _owner);
    _setupRole(ROLE_MINT, _owner);
    _setupRole(ROLE_LOCK, _owner);
    _setupRole(ROLE_TEST, _owner);

    m_balances[_owner] = _initialSupply;
    uint256_totalSupply = _initialSupply;
    b_canTransfer = false;
    uint256_chain_id = _getChainId();

    EIP712DOMAIN_SEPARATOR = _hash(EIP712Domain({
        name : name,
        version : version,
        chainId : uint256_chain_id,
        verifyingContract : address(this),
        salt : keccak256(abi.encodePacked(name))
      }
    ));
   
    emit Transfer(BURN_ADDRESS, _owner, uint256_totalSupply);
  }

    /**
   * @dev Sets transfer status to lock token transfer
   * @param _canTransfer value can be true or false.
   * disables transfer when set to false and enables transfer when true
   * Only a member of ADMIN role can call to change transfer status
   */
  function setCanTransfer(bool _canTransfer) public {
    if(hasRole(ROLE_ADMIN, _msgSender())){
      b_canTransfer = _canTransfer;
      emit TransferStatusChanged(_canTransfer);
    }
  }

  /**
   * @dev Gets status of token transfer lock
   * @return true or false status of whether the token can be transfered
   */
  function getCanTransfer() public view returns (bool) {
    return b_canTransfer;
  }

  /**
   * @dev Sets transfer reversion status to either return false or throw on error
   * @param _reversion value can be true or false.
   * disables return of false values for transfer failures when set to false and enables transfer-related exceptions when true
   * Only a member of ADMIN role can call to change transfer reversion status
   */
  function setReversion(bool _reversion) public {
    if(hasRole(ROLE_ADMIN, _msgSender()) || 
       hasRole(ROLE_TEST, _msgSender())
    ) {
      b_revert = _reversion;
      emit ReversionStatusChanged(_reversion);
    }
  }

  /**
   * @dev Gets status of token transfer reversion
   * @return true or false status of whether the token transfer failures return false or are reverted
   */
  function getReversion() public view returns (bool) {
    return b_revert;
  }

  /**
   * @dev retrieve current chain id
   * @return chain id
   */
  function getChainId() public pure returns (uint256) {
    return _getChainId();
  }

  /**
   * @dev Retrieve current chain id
   * @return chain id
   */
  function _getChainId() internal pure returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
   * @dev Retrieve total supply of tokens
   * @return uint256 total supply of tokens
   */
  function totalSupply() public view override returns (uint256) {
    return uint256_totalSupply;
  }

  /**
   * Balance related functions
   */

  /**
   * @dev Retrieve balance of a specified account
   * @param _account address of account holding balance
   * @return uint256 balance of the specified account address
   */
  function balanceOf(address _account) public view override returns (uint256) {
    return m_balances[_account].add(_calculateReleasedBalance(_account));
  }

  /**
   * @dev Retrieve locked balance of a specified account
   * @param _account address of account holding locked balance
   * @return uint256 locked balance of the specified account address
   */
  function lockedBalanceOf(address _account) public view returns (uint256) {
    return _calculateLockedBalance(_account);
  }

  /**
   * @dev Retrieve lenght of locked balance array for specific address
   * @param _account address of account holding locked balance
   * @return uint256 locked balance array lenght
   */
  function getLockedTokensListSize(address _account) public view returns (uint256){
    require(_msgSender() == _account || hasRole(ROLE_ADMIN, _msgSender()) || hasRole(ROLE_TRUSTED, _msgSender()), "UPGT_ERROR: insufficient permissions");
    return m_lockedBalances[_account].length;
  }

  /**
   * @dev Retrieve locked tokens struct from locked balance array for specific address
   * @param _account address of account holding locked tokens
   * @param _index index in array with locked tokens position
   * @return amount of locked tokens
   * @return releaseTime descibes time when tokens will be unlocked
   * @return votable flag is describing votability of tokens
   */
  function getLockedTokens(address _account, uint256 _index) public view returns (uint256 amount, uint256 releaseTime, bool votable){
    require(_msgSender() == _account || hasRole(ROLE_ADMIN, _msgSender()) || hasRole(ROLE_TRUSTED, _msgSender()), "UPGT_ERROR: insufficient permissions");
    require(_index < m_lockedBalances[_account].length, "UPGT_ERROR: LockedTokens position doesn't exist on given index");
    LockedTokens storage lockedTokens = m_lockedBalances[_account][_index];
    return (lockedTokens.amount, lockedTokens.releaseTime, lockedTokens.votable);
  }

  /**
   * @dev Calculates locked balance of a specified account
   * @param _account address of account holding locked balance
   * @return uint256 locked balance of the specified account address
   */
  function _calculateLockedBalance(address _account) private view returns (uint256) {
    uint256 lockedBalance = 0;
    for (uint i=0; i<m_lockedBalances[_account].length; i++) {
      if(m_lockedBalances[_account][i].releaseTime > block.timestamp){
        lockedBalance = lockedBalance.add(m_lockedBalances[_account][i].amount);
      }
    }
    return lockedBalance;
  }

  /**
   * @dev Calculates released balance of a specified account
   * @param _account address of account holding released balance
   * @return uint256 released balance of the specified account address
   */
  function _calculateReleasedBalance(address _account) private view returns (uint256) {
    uint256 releasedBalance = 0;
    for (uint i=0; i<m_lockedBalances[_account].length; i++) {
      if(m_lockedBalances[_account][i].releaseTime <= block.timestamp){
          releasedBalance = releasedBalance.add(m_lockedBalances[_account][i].amount);
      }
    }
    return releasedBalance;
  }

  /**
   * @dev Calculates locked votable balance of a specified account
   * @param _account address of account holding locked votable balance
   * @return uint256 locked votable balance of the specified account address
   */
  function _calculateLockedVotableBalance(address _account) private view returns (uint256) {
    uint256 lockedVotableBalance = 0;
    for (uint i=0; i<m_lockedBalances[_account].length; i++) {
      if(m_lockedBalances[_account][i].votable == true){
        lockedVotableBalance = lockedVotableBalance.add(m_lockedBalances[_account][i].amount);
      }
    }
    return lockedVotableBalance;
  }

  /**
   * @dev Moves released balance to normal balance for a specified account
   * @param _account address of account holding released balance
   */
  function _moveReleasedBalance(address _account) internal virtual{
    uint256 releasedToMove = 0;
    for (uint i=0; i<m_lockedBalances[_account].length; i++) {
      if(m_lockedBalances[_account][i].releaseTime <= block.timestamp){
        releasedToMove = releasedToMove.add(m_lockedBalances[_account][i].amount);
        m_lockedBalances[_account][i] = m_lockedBalances[_account][m_lockedBalances[_account].length - 1];
        m_lockedBalances[_account].pop();
      }
    }
    m_balances[_account] = m_balances[_account].add(releasedToMove);
  }

  /**
   * Allowance related functinons
   */

  /**
   * @dev Retrieve the spending allowance for a token holder by a specified account
   * @param _owner Token account holder
   * @param _spender Account given allowance
   * @return uint256 allowance value
   */
  function allowance(address _owner, address _spender) public override virtual view returns (uint256) {
    return m_allowances[_owner][_spender];
  }

  /**
   * @dev Message sender approval to spend for a specified amount
   * @param _spender address of party approved to spend
   * @param _value amount of the approval 
   * @return boolean success status 
   * public wrapper for _approve, _owner is msg.sender
   */
  function approve(address _spender, uint256 _value) public override returns (bool) {
    bool success = _approveUNN(_msgSender(), _spender, _value);
    if(!success && b_revert){
      revert("UPGT_ERROR: APPROVE ERROR");
    }
    return success;
  }
  
  /**
   * @dev Token owner approval of amount for specified spender
   * @param _owner address of party that owns the tokens being granted approval for spending
   * @param _spender address of party that is granted approval for spending
   * @param _value amount approved for spending
   * @return boolean approval status
   * if _spender allownace for a given _owner is greater than 0, 
   * increaseAllowance/decreaseAllowance should be used to prevent a race condition whereby the spender is able to spend the total value of both the old and new allowance.  _spender cannot be burn or this governance token contract address.  Addresses github.com/ethereum/EIPs/issues738
   */
  function _approveUNN(address _owner, address _spender, uint256 _value) internal returns (bool) {
    bool retval = false;
    if(_spender != BURN_ADDRESS &&
      _spender != UPGT_CONTRACT_ADDRESS &&
      (m_allowances[_owner][_spender] == 0 || _value == 0)
    ){
      m_allowances[_owner][_spender] = _value;
      emit Approval(_owner, _spender, _value);
      retval = true;
    }
    return retval;
  }

  /**
   * @dev Increase spender allowance by specified incremental value
   * @param _spender address of party that is granted approval for spending
   * @param _addedValue specified incremental increase
   * @return boolean increaseAllowance status
   * public wrapper for _increaseAllowance, _owner restricted to msg.sender
   */
  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    bool success = _increaseAllowanceUNN(_msgSender(), _spender, _addedValue);
    if(!success && b_revert){
      revert("UPGT_ERROR: INCREASE ALLOWANCE ERROR");
    }
    return success;
  }

  /**
   * @dev Allow owner to increase spender allowance by specified incremental value
   * @param _owner address of the token owner
   * @param _spender address of the token spender
   * @param _addedValue specified incremental increase
   * @return boolean return value status
   * increase the number of tokens that an _owner provides as allowance to a _spender-- does not requrire the number of tokens allowed to be set first to 0.  _spender cannot be either burn or this goverance token contract address.
   */
  function _increaseAllowanceUNN(address _owner, address _spender, uint256 _addedValue) internal returns (bool) {
    bool retval = false;
    if(_spender != BURN_ADDRESS &&
      _spender != UPGT_CONTRACT_ADDRESS &&
      _addedValue > 0
    ){
      m_allowances[_owner][_spender] = m_allowances[_owner][_spender].add(_addedValue);
      retval = true;
      emit Approval(_owner, _spender, m_allowances[_owner][_spender]);
    }
    return retval;
  }

  /**
   * @dev Decrease spender allowance by specified incremental value
   * @param _spender address of party that is granted approval for spending
   * @param _subtractedValue specified incremental decrease
   * @return boolean success status
   * public wrapper for _decreaseAllowance, _owner restricted to msg.sender
   */
  //public wrapper for _decreaseAllowance, _owner restricted to msg.sender
  function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
    bool success = _decreaseAllowanceUNN(_msgSender(), _spender, _subtractedValue);
    if(!success && b_revert){
      revert("UPGT_ERROR: DECREASE ALLOWANCE ERROR");
    }
    return success;
  } 

  /**
   * @dev Allow owner to decrease spender allowance by specified incremental value
   * @param _owner address of the token owner
   * @param _spender address of the token spender
   * @param _subtractedValue specified incremental decrease
   * @return boolean return value status
   * decrease the number of tokens than an _owner provdes as allowance to a _spender.  A _spender cannot have a negative allowance.  Does not require existing allowance to be set first to 0.  _spender cannot be burn or this governance token contract address.
   */
  function _decreaseAllowanceUNN(address _owner, address _spender, uint256 _subtractedValue) internal returns (bool) {
    bool retval = false;
    if(_spender != BURN_ADDRESS &&
       _spender != UPGT_CONTRACT_ADDRESS &&
      _subtractedValue > 0 &&
      m_allowances[_owner][_spender] >= _subtractedValue
    ){
      m_allowances[_owner][_spender] = m_allowances[_owner][_spender].sub(_subtractedValue);
      retval = true;
      emit Approval(_owner, _spender, m_allowances[_owner][_spender]);
    }
    return retval;
  }

  /**
   * LockedDestination related functions
   */

  /**
   * @dev Adds address as a designated destination for tokens when locked for allocation only
   * @param _address Address of approved desitnation for movement during lock
   * @return success in setting address as eligible for transfer independent of token lock status
   */
  function setAsEligibleLockedDestination(address _address) public returns (bool) {
    bool retVal = false;
    if(hasRole(ROLE_ADMIN, _msgSender())){
      m_lockedDestinations[_address] = true;
      retVal = true;
    }
    return retVal;
  }

  /**
   * @dev removes desitnation as eligible for transfer
   * @param _address address being removed
   */
  function removeEligibleLockedDestination(address _address) public {
    if(hasRole(ROLE_ADMIN, _msgSender())){
      require(_address != BURN_ADDRESS, "UPGT_ERROR: address cannot be burn address");
      delete(m_lockedDestinations[_address]);
    }
  }

  /**
   * @dev checks whether a destination is eligible as recipient of transfer independent of token lock status
   * @param _address address being checked
   * @return whether desitnation is locked
   */
  function checkEligibleLockedDesination(address _address) public view returns (bool) {
    return m_lockedDestinations[_address];
  }

  /**
   * @dev Adds address as a designated allocator that can move tokens when they are locked
   * @param _address Address receiving the role of ROLE_ALLOCATE
   * @return success as true or false
   */
  function setAsAllocator(address _address) public returns (bool) {
    bool retVal = false;
    if(hasRole(ROLE_ADMIN, _msgSender())){
      grantRole(ROLE_ALLOCATE, _address);
      retVal = true;
    }
    return retVal;
  }
  
  /**
   * @dev Removes address as a designated allocator that can move tokens when they are locked
   * @param _address Address being removed from the ROLE_ALLOCATE
   * @return success as true or false
   */
  function removeAsAllocator(address _address) public returns (bool) {
    bool retVal = false;
    if(hasRole(ROLE_ADMIN, _msgSender())){
      if(hasRole(ROLE_ALLOCATE, _address)){
        revokeRole(ROLE_ALLOCATE, _address);
        retVal = true;
      }
    }
    return retVal;
  }

  /**
   * @dev Checks to see if an address has the role of being an allocator
   * @param _address Address being checked for ROLE_ALLOCATE
   * @return true or false whether the address has ROLE_ALLOCATE assigned
   */
  function checkAsAllocator(address _address) public view returns (bool) {
    return hasRole(ROLE_ALLOCATE, _address);
  }

  /**
   * Transfer related functions
   */

  /**
   * @dev Public wrapper for transfer function to move tokens of specified value to a given address
   * @param _to specified recipient
   * @param _value amount being transfered to recipient
   * @return status of transfer success
   */
  function transfer(address _to, uint256 _value) external override returns (bool) {
    bool success = _transferUNN(_msgSender(), _to, _value);
    if(!success && b_revert){
      revert("UPGT_ERROR: ERROR ON TRANSFER");
    }
    return success;
  }

  /**
   * @dev Transfer token for a specified address, but cannot transfer tokens to either the burn or this governance contract address.  Also moves voting delegates as required.
   * @param _owner The address owner where transfer originates
   * @param _to The address to transfer to
   * @param _value The amount to be transferred
   * @return status of transfer success
   */
  function _transferUNN(address _owner, address _to, uint256 _value) internal returns (bool) {
    bool retval = false;
    if(b_canTransfer || hasRole(ROLE_ALLOCATE, _msgSender()) || checkEligibleLockedDesination(_to)) {
      if(
         _to != BURN_ADDRESS &&
         _to != UPGT_CONTRACT_ADDRESS &&
         (balanceOf(_owner) >= _value) &&
         (_value >= 0)
      ){
        _moveReleasedBalance(_owner);
        m_balances[_owner] = m_balances[_owner].sub(_value);
        m_balances[_to] = m_balances[_to].add(_value);
        retval = true;
        //need to move voting delegates with transfer of tokens
        retval = retval && _moveVotingDelegates(m_delegatedAccounts[_owner], m_delegatedAccounts[_to], _value);
        emit Transfer(_owner, _to, _value);
      }
    }
    return retval;
  }

  /**
   * @dev Public wrapper for transferAndLock function to move tokens of specified value to a given address and lock them for a period of time
   * @param _to specified recipient
   * @param _value amount being transfered to recipient
   * @param _releaseTime time in seconds after amount will be released
   * @param _votable flag which describes if locked tokens are votable or not
   * @return status of transfer success
   * Requires ROLE_LOCK
   */
  function transferAndLock(address _to, uint256 _value, uint256 _releaseTime, bool _votable) public virtual returns (bool) {
    bool retval = false;
    if(hasRole(ROLE_LOCK, _msgSender())){
      retval = _transferAndLock(msg.sender, _to, _value, _releaseTime, _votable);
    }
   
    if(!retval && b_revert){
      revert("UPGT_ERROR: ERROR ON TRANSFER AND LOCK");
    }
    return retval;
  }

  /**
   * @dev Transfers tokens of specified value to a given address and lock them for a period of time
   * @param _owner The address owner where transfer originates
   * @param _to specified recipient
   * @param _value amount being transfered to recipient
   * @param _releaseTime time in seconds after amount will be released
   * @param _votable flag which describes if locked tokens are votable or not
   * @return status of transfer success
   */
  function _transferAndLock(address _owner, address _to, uint256 _value, uint256 _releaseTime, bool _votable) internal virtual returns (bool){
    bool retval = false;
    if(b_canTransfer || hasRole(ROLE_ALLOCATE, _msgSender()) || checkEligibleLockedDesination(_to)) {
      if(
         _to != BURN_ADDRESS &&
         _to != UPGT_CONTRACT_ADDRESS &&
         (balanceOf(_owner) >= _value) &&
         (_value >= 0)
      ){
        _moveReleasedBalance(_owner);
        m_balances[_owner] = m_balances[_owner].sub(_value);
        m_lockedBalances[_to].push(LockedTokens(_value, _releaseTime, _votable));
        retval = true;
        //need to move voting delegates with transfer of tokens
        // retval = retval && _moveVotingDelegates(m_delegatedAccounts[_owner], m_delegatedAccounts[_to], _value);  
        emit Transfer(_owner, _to, _value);
      }
    }
    return retval;
  }

  /**
   * @dev Public wrapper for transferFrom function
   * @param _owner The address to transfer from
   * @param _spender cannot be the burn address
   * @param _value The amount to be transferred
   * @return status of transferFrom success
   * _spender cannot be either this goverance token contract or burn
   */
  function transferFrom(address _owner, address _spender, uint256 _value) external override returns (bool) {
    bool success = _transferFromUNN(_owner, _spender, _value);
    if(!success && b_revert){
      revert("UPGT_ERROR: ERROR ON TRANSFER FROM");
    }
    return success;
  }

  /**
   * @dev Transfer token for a specified address.  _spender cannot be either this goverance token contract or burn
   * @param _owner The address to transfer from
   * @param _spender cannot be the burn address
   * @param _value The amount to be transferred
   * @return status of transferFrom success
   * _spender cannot be either this goverance token contract or burn
   */
  function _transferFromUNN(address _owner, address _spender, uint256 _value) internal returns (bool) {
    bool retval = false;
    if(b_canTransfer || hasRole(ROLE_ALLOCATE, _msgSender()) || checkEligibleLockedDesination(_spender)) {
      if(
        _spender != BURN_ADDRESS &&
        _spender != UPGT_CONTRACT_ADDRESS &&
        (balanceOf(_owner) >= _value) &&
        (_value > 0) &&
        (m_allowances[_owner][_msgSender()] >= _value)
      ){
        _moveReleasedBalance(_owner);
        m_balances[_owner] = m_balances[_owner].sub(_value);
        m_balances[_spender] = m_balances[_spender].add(_value);
        m_allowances[_owner][_msgSender()] = m_allowances[_owner][_msgSender()].sub(_value);
        retval = true;
        //need to move delegates that exist for this owner in line with transfer
        retval = retval && _moveVotingDelegates(_owner, _spender, _value); 
        emit Transfer(_owner, _spender, _value);
      }
    }
    return retval;
  }

  /**
   * @dev Public wrapper for transferFromAndLock function to move tokens of specified value from given address to another address and lock them for a period of time
   * @param _owner The address owner where transfer originates
   * @param _to specified recipient
   * @param _value amount being transfered to recipient
   * @param _releaseTime time in seconds after amount will be released
   * @param _votable flag which describes if locked tokens are votable or not
   * @return status of transfer success
   * Requires ROLE_LOCK
   */
  function transferFromAndLock(address _owner, address _to, uint256 _value, uint256 _releaseTime, bool _votable) public virtual returns (bool) {
     bool retval = false;
    if(hasRole(ROLE_LOCK, _msgSender())){
      retval = _transferFromAndLock(_owner, _to, _value, _releaseTime, _votable);
    }
   
    if(!retval && b_revert){
      revert("UPGT_ERROR: ERROR ON TRANSFER FROM AND LOCK");
    }
    return retval;
  }

  /**
   * @dev Transfers tokens of specified value from a given address to another address and lock them for a period of time
   * @param _owner The address owner where transfer originates
   * @param _to specified recipient
   * @param _value amount being transfered to recipient
   * @param _releaseTime time in seconds after amount will be released
   * @param _votable flag which describes if locked tokens are votable or not
   * @return status of transfer success
   */
  function _transferFromAndLock(address _owner, address _to, uint256 _value, uint256 _releaseTime, bool _votable) internal returns (bool) {
    bool retval = false;
    if(b_canTransfer || hasRole(ROLE_ALLOCATE, _msgSender()) || checkEligibleLockedDesination(_to)) {
      if(
        _to != BURN_ADDRESS &&
        _to != UPGT_CONTRACT_ADDRESS &&
        (balanceOf(_owner) >= _value) &&
        (_value > 0) &&
        (m_allowances[_owner][_msgSender()] >= _value)
      ){
        _moveReleasedBalance(_owner);
        m_balances[_owner] = m_balances[_owner].sub(_value);
        m_lockedBalances[_to].push(LockedTokens(_value, _releaseTime, _votable));
        m_allowances[_owner][_msgSender()] = m_allowances[_owner][_msgSender()].sub(_value);
        retval = true;
        //need to move delegates that exist for this owner in line with transfer
        // retval = retval && _moveVotingDelegates(_owner, _to, _value); 
        emit Transfer(_owner, _to, _value);
      }
    }
    return retval;
  }

  /**
   * @dev Public function to burn tokens
   * @param _value number of tokens to be burned
   * @return whether tokens were burned
   * Only ROLE_MINTER may burn tokens
   */
  function burn(uint256 _value) external returns (bool) {
    bool success = _burn(_value);
    if(!success && b_revert){
      revert("UPGT_ERROR: FAILED TO BURN");
    }
    return success;
  } 

  /**
   * @dev Private function Burn tokens
   * @param _value number of tokens to be burned
   * @return bool whether the tokens were burned
   * only a minter may burn tokens, meaning that tokens being burned must be previously send to a ROLE_MINTER wallet.
   */
  function _burn(uint256 _value) internal returns (bool) {
    bool retval = false;
    if(hasRole(ROLE_MINT, _msgSender()) &&
       (m_balances[_msgSender()] >= _value)
    ){
      m_balances[_msgSender()] -= _value;
      uint256_totalSupply = uint256_totalSupply.sub(_value);
      retval = true;
      emit Burn(_msgSender(), _value);
    }
    return retval;
  }

  /** 
  * Voting related functions
  */

  /**
   * @dev Public wrapper for _calculateVotingPower function which calulates voting power
   * @dev voting power = balance + locked votable balance + delegations
   * @return uint256 voting power
   */
  function calculateVotingPower() public view returns (uint256) {
    return _calculateVotingPower(_msgSender());
  }

  /**
   * @dev Calulates voting power of specified address
   * @param _account address of token holder
   * @return uint256 voting power
   */
  function _calculateVotingPower(address _account) private view returns (uint256) {
    uint256 votingPower = m_balances[_account].add(_calculateLockedVotableBalance(_account));
    for (uint i=0; i<m_delegatedAccountsInverseMap[_account].length(); i++) {
      if(m_delegatedAccountsInverseMap[_account].at(i) != address(0)){
        address delegatedAccount = m_delegatedAccountsInverseMap[_account].at(i);
        votingPower = votingPower.add(m_balances[delegatedAccount]).add(_calculateLockedVotableBalance(delegatedAccount));
      }
    }
    return votingPower;
  }

  /**
   * @dev Moves a number of votes from a token holder to a designated representative
   * @param _source address of token holder
   * @param _destination address of voting delegate
   * @param _amount of voting delegation transfered to designated representative
   * @return bool whether move was successful
   * Requires ROLE_TEST
   */
  function moveVotingDelegates(
    address _source,
    address _destination,
    uint256 _amount) public returns (bool) {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    return _moveVotingDelegates(_source, _destination, _amount);
  }

  /**
   * @dev Moves a number of votes from a token holder to a designated representative
   * @param _source address of token holder
   * @param _destination address of voting delegate
   * @param _amount of voting delegation transfered to designated representative
   * @return bool whether move was successful
   */
  function _moveVotingDelegates(
      address _source, 
      address _destination, 
      uint256 _amount
  ) internal returns (bool) {
    if(_source != _destination && _amount > 0) {
      if(_source != BURN_ADDRESS) {
        uint256 sourceNumberOfVotingCheckpoints = m_accountVotingCheckpoints[_source];
        uint256 sourceNumberOfVotingCheckpointsOriginal = (sourceNumberOfVotingCheckpoints > 0)? m_votingCheckpoints[_source][sourceNumberOfVotingCheckpoints.sub(1)].votes : 0;
        if(sourceNumberOfVotingCheckpointsOriginal >= _amount) {
          uint256 sourceNumberOfVotingCheckpointsNew = sourceNumberOfVotingCheckpointsOriginal.sub(_amount);
          _writeVotingCheckpoint(_source, sourceNumberOfVotingCheckpoints, sourceNumberOfVotingCheckpointsOriginal, sourceNumberOfVotingCheckpointsNew);
        }
      }

      if(_destination != BURN_ADDRESS) {
        uint256 destinationNumberOfVotingCheckpoints = m_accountVotingCheckpoints[_destination];
        uint256 destinationNumberOfVotingCheckpointsOriginal = (destinationNumberOfVotingCheckpoints > 0)? m_votingCheckpoints[_source][destinationNumberOfVotingCheckpoints.sub(1)].votes : 0;
        uint256 destinationNumberOfVotingCheckpointsNew = destinationNumberOfVotingCheckpointsOriginal.add(_amount);
        _writeVotingCheckpoint(_destination, destinationNumberOfVotingCheckpoints, destinationNumberOfVotingCheckpointsOriginal, destinationNumberOfVotingCheckpointsNew);
      }
    }
    
    return true; 
  }

  /**
   * @dev Writes voting checkpoint for a given voting delegate
   * @param _votingDelegate exercising votes
   * @param _numberOfVotingCheckpoints number of voting checkpoints for current vote
   * @param _oldVotes previous number of votes
   * @param _newVotes new number of votes
   * Public function for writing voting checkpoint
   * Requires ROLE_TEST
   */
  function writeVotingCheckpoint(
    address _votingDelegate,
    uint256 _numberOfVotingCheckpoints,
    uint256 _oldVotes,
    uint256 _newVotes) public {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    _writeVotingCheckpoint(_votingDelegate, _numberOfVotingCheckpoints, _oldVotes, _newVotes);
  }

  /**
   * @dev Writes voting checkpoint for a given voting delegate
   * @param _votingDelegate exercising votes
   * @param _numberOfVotingCheckpoints number of voting checkpoints for current vote
   * @param _oldVotes previous number of votes
   * @param _newVotes new number of votes
   * Private function for writing voting checkpoint
   */
  function _writeVotingCheckpoint(
    address _votingDelegate, 
    uint256 _numberOfVotingCheckpoints, 
    uint256 _oldVotes, 
    uint256 _newVotes) internal {
    if(_numberOfVotingCheckpoints > 0 && m_votingCheckpoints[_votingDelegate][_numberOfVotingCheckpoints.sub(1)].from == block.number) {
      m_votingCheckpoints[_votingDelegate][_numberOfVotingCheckpoints-1].votes = _newVotes;
    }
    else {
      m_votingCheckpoints[_votingDelegate][_numberOfVotingCheckpoints] = VotingCheckpoint(block.number, _newVotes);
      _numberOfVotingCheckpoints = _numberOfVotingCheckpoints.add(1);
    }
    emit VoteBalanceChanged(_votingDelegate, _oldVotes, _newVotes);
  }

  /**
   * @dev Calculate account votes as of a specific block
   * @param _account address whose votes are counted
   * @param _blockNumber from which votes are being counted
   * @return number of votes counted
   */
  function getVoteCountAtBlock(
    address _account, 
    uint256 _blockNumber) public view returns (uint256) {
    uint256 voteCount = 0;
    if(_blockNumber < block.number) {
      if(m_accountVotingCheckpoints[_account] != 0) {
        if(m_votingCheckpoints[_account][m_accountVotingCheckpoints[_account].sub(1)].from <= _blockNumber) {
          voteCount = m_votingCheckpoints[_account][m_accountVotingCheckpoints[_account].sub(1)].votes;
        }
        else if(m_votingCheckpoints[_account][0].from > _blockNumber) {
          voteCount = 0;
        }
        else {
          uint256 lower = 0;
          uint256 upper = m_accountVotingCheckpoints[_account].sub(1);
          
          while(upper > lower) {
            uint256 center = upper.sub((upper.sub(lower).div(2)));
            VotingCheckpoint memory votingCheckpoint = m_votingCheckpoints[_account][center];
            if(votingCheckpoint.from == _blockNumber) {
              voteCount = votingCheckpoint.votes;
              break;
            }
            else if(votingCheckpoint.from < _blockNumber) {
              lower = center;
            }
            else {
              upper = center.sub(1);
            }
          
          }
        }
      }
    }
    return voteCount;
  }

  /**
   * @dev Vote Delegation Functions
   * @param _to address where message sender is assigning votes
   * @return success of message sender delegating vote
   * delegate function does not allow assignment to burn
   */
  function delegateVote(address _to) public returns (bool) {
    return _delegateVote(_msgSender(), _to);
  }

  /**
   * @dev Delegate votes from token holder to another address
   * @param _from Token holder 
   * @param _toDelegate Address that will be delegated to for purpose of voting
   * @return success as to whether delegation has been a success
   */
  function _delegateVote(
    address _from, 
    address _toDelegate) internal returns (bool) {
    bool retval = false;
    if(_toDelegate != BURN_ADDRESS) {
      address currentDelegate = m_delegatedAccounts[_from];
      uint256 fromAccountBalance = m_balances[_from].add(_calculateLockedVotableBalance(_from));
      address oldToDelegate = m_delegatedAccounts[_from];
      m_delegatedAccounts[_from] = _toDelegate;

      m_delegatedAccountsInverseMap[oldToDelegate].remove(_from);
      if(_from != _toDelegate){
        m_delegatedAccountsInverseMap[_toDelegate].add(_from);
      }

      retval = true;
      retval = retval && _moveVotingDelegates(currentDelegate, _toDelegate, fromAccountBalance);
      if(retval) {
        if(_from == _toDelegate){
          emit VotingDelegateRemoved(_from);
        }
        else{
          emit VotingDelegateChanged(_from, currentDelegate, _toDelegate);
        }
      }
    }
    return retval;
  }

  /**
   * @dev Revert voting delegate control to owner account
   * @param _account  The account that has delegated its vote
   * @return success of reverting delegation to owner
   */
  function _revertVotingDelegationToOwner(address _account) internal returns (bool) {
    return _delegateVote(_account, _account);
  }

  /**
   * @dev Used by an message sending account to recall its voting delegates
   * @return success of reverting delegation to owner
   */
  function recallVotingDelegate() public returns (bool) {
    return _revertVotingDelegationToOwner(_msgSender());
  }
  
  /**
   * @dev Retrieve the voting delegate for a specified account
   * @param _account  The account that has delegated its vote
   */ 
  function getVotingDelegate(address _account) public view returns (address) {
    return m_delegatedAccounts[_account];
  }

  /** 
  * EIP-712 related functions
  */

  /**
   * @dev EIP-712 Ethereum Typed Structured Data Hashing and Signing for Allocation Permit
   * @param _owner address of token owner
   * @param _spender address of designated spender
   * @param _value value permitted for spend
   * @param _deadline expiration of signature
   * @param _ecv ECDSA v parameter
   * @param _ecr ECDSA r parameter
   * @param _ecs ECDSA s parameter
   */
  function permit(
    address _owner, 
    address _spender, 
    uint256 _value, 
    uint256 _deadline, 
    uint8 _ecv, 
    bytes32 _ecr, 
    bytes32 _ecs
  ) external returns (bool) {
    require(block.timestamp <= _deadline, "UPGT_ERROR: wrong timestamp");
    require(uint256_chain_id == _getChainId(), "UPGT_ERROR: chain_id is incorrect");
    bytes32 digest = keccak256(abi.encodePacked(
        "\x19\x01",
        EIP712DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, m_nonces[_owner]++, _deadline))
      )
    );
    require(_owner == _recoverSigner(digest, _ecv, _ecr, _ecs), "UPGT_ERROR: sign does not match user");
    require(_owner != BURN_ADDRESS, "UPGT_ERROR: address cannot be burn address");

    return _approveUNN(_owner, _spender, _value);
  }

  /**
   * @dev EIP-712 ETH Typed Structured Data Hashing and Signing for Delegate Vote
   * @param _owner address of token owner
   * @param _delegate address of voting delegate
   * @param _expiretimestamp expiration of delegation signature
   * @param _ecv ECDSA v parameter
   * @param _ecr ECDSA r parameter
   * @param _ecs ECDSA s parameter
   * @ @return bool true or false depedening on whether vote was successfully delegated
   */
  function delegateVoteBySignature(
    address _owner, 
    address _delegate, 
    uint256 _expiretimestamp, 
    uint8 _ecv, 
    bytes32 _ecr, 
    bytes32 _ecs
  ) external returns (bool) {
    require(block.timestamp <= _expiretimestamp, "UPGT_ERROR: wrong timestamp");
    require(uint256_chain_id == _getChainId(), "UPGT_ERROR: chain_id is incorrect");
    bytes32 digest = keccak256(abi.encodePacked(
        "\x19\x01",
        EIP712DOMAIN_SEPARATOR,
        _hash(VotingDelegate(
          {
            owner : _owner,
            delegate : _delegate,
            nonce : m_nonces[_owner]++,
            expirationTime : _expiretimestamp
          })
        )
      )
    );
    require(_owner == _recoverSigner(digest, _ecv, _ecr, _ecs), "UPGT_ERROR: sign does not match user");
    require(_owner!= BURN_ADDRESS, "UPGT_ERROR: address cannot be burn address");

    return _delegateVote(_owner, _delegate);
  }

  /**
   * @dev Public hash EIP712Domain struct for EIP-712
   * @param _eip712Domain EIP712Domain struct
   * @return bytes32 hash of _eip712Domain
   * Requires ROLE_TEST
   */
  function hashEIP712Domain(EIP712Domain memory _eip712Domain) public view returns (bytes32) {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    return _hash(_eip712Domain);
  }

  /**
   * @dev Hash Delegate struct for EIP-712
   * @param _delegate VotingDelegate struct
   * @return bytes32 hash of _delegate
   * Requires ROLE_TEST
   */
  function hashDelegate(VotingDelegate memory _delegate) public view returns (bytes32) {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    return _hash(_delegate);
  }

  /**
   * @dev Public hash Permit struct for EIP-712
   * @param _permit Permit struct
   * @return bytes32 hash of _permit
   * Requires ROLE_TEST
   */
  function hashPermit(Permit memory _permit) public view returns (bytes32) {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    return _hash(_permit);
  }

  /**
   * @param _digest signed, hashed message
   * @param _ecv ECDSA v parameter
   * @param _ecr ECDSA r parameter
   * @param _ecs ECDSA s parameter
   * @return address of the validated signer
   * based on openzeppelin/contracts/cryptography/ECDSA.sol recover() function
   * Requires ROLE_TEST
   */
  function recoverSigner(bytes32 _digest, uint8 _ecv, bytes32 _ecr, bytes32 _ecs) public view returns (address) {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    return _recoverSigner(_digest, _ecv, _ecr, _ecs);
  }

  /**
  * @dev Private hash EIP712Domain struct for EIP-712
  * @param _eip712Domain EIP712Domain struct
  * @return bytes32 hash of _eip712Domain
  */
  function _hash(EIP712Domain memory _eip712Domain) internal pure returns (bytes32) {
      return keccak256(
          abi.encode(
              EIP712DOMAIN_TYPEHASH,
              keccak256(bytes(_eip712Domain.name)),
              keccak256(bytes(_eip712Domain.version)),
              _eip712Domain.chainId,
              _eip712Domain.verifyingContract,
              _eip712Domain.salt
          )
      );
  }

  /**
  * @dev Private hash Delegate struct for EIP-712
  * @param _delegate VotingDelegate struct
  * @return bytes32 hash of _delegate
  */
  function _hash(VotingDelegate memory _delegate) internal pure returns (bytes32) {
      return keccak256(
          abi.encode(
              DELEGATE_TYPEHASH,
              _delegate.owner,
              _delegate.delegate,
              _delegate.nonce,
              _delegate.expirationTime
          )
      );
  }

  /** 
  * @dev Private hash Permit struct for EIP-712
  * @param _permit Permit struct
  * @return bytes32 hash of _permit
  */
  function _hash(Permit memory _permit) internal pure returns (bytes32) {
      return keccak256(abi.encode(
      PERMIT_TYPEHASH,
      _permit.owner,
      _permit.spender,
      _permit.value,
      _permit.nonce,
      _permit.deadline
      ));
  }

  /**
  * @dev Recover signer information from provided digest
  * @param _digest signed, hashed message
  * @param _ecv ECDSA v parameter
  * @param _ecr ECDSA r parameter
  * @param _ecs ECDSA s parameter
  * @return address of the validated signer
  * based on openzeppelin/contracts/cryptography/ECDSA.sol recover() function
  */
  function _recoverSigner(bytes32 _digest, uint8 _ecv, bytes32 _ecr, bytes32 _ecs) internal pure returns (address) {
      // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
      // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
      // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
      // signatures from current libraries generate a unique signature with an s-value in the lower half order.
      //
      // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
      // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
      // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
      // these malleable signatures as well.
      if(uint256(_ecs) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
          revert("ECDSA: invalid signature 's' value");
      }

      if(_ecv != 27 && _ecv != 28) {
          revert("ECDSA: invalid signature 'v' value");
      }

      // If the signature is valid (and not malleable), return the signer address
      address signer = ecrecover(_digest, _ecv, _ecr, _ecs);
      require(signer != BURN_ADDRESS, "ECDSA: invalid signature");

      return signer;
  }
}

// Copyright (c) 2020 The UNION Protocol Foundation
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title UNION Protocol date/time utility
 * Inspired by https://github.com/pipermerriam/ethereum-datetime/blob/master/contracts/DateTime.sol
 */
library DateTime {
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year)
    public
    pure
    returns (uint8)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTimestamp(uint256 timestamp)
    internal
    pure
    returns (_DateTime memory dt)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint256 timestamp) public pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
        YEAR_IN_SECONDS *
        (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint256 timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) public pure returns (uint256 timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            } else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        } else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}