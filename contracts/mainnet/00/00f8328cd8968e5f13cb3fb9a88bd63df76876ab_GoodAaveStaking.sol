// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
import "../SimpleStaking.sol";
import "../../Interfaces.sol";
import "../../utils/DataTypes.sol";
import "../UniswapV2SwapHelper.sol";

/**
 * @title Staking contract that donates earned interest to the DAO
 * allowing stakers to deposit Token
 * or withdraw their stake in Token
 * the contracts buy cToken and can transfer the daily interest to the  DAO
 */
contract GoodAaveStaking is SimpleStaking {
	using UniswapV2SwapHelper for IHasRouter;

	// Address of the TOKEN/USD oracle from chainlink
	address public tokenUsdOracle;

	//LendingPool of aave
	ILendingPool public lendingPool;

	//Address of the AaveIncentivesController
	IAaveIncentivesController incentiveController;

	//address of the AAVE/USD oracle
	address public aaveUSDOracle;
	// Gas cost to collect interest from this staking contract
	uint32 public collectInterestGasCost = 250000;
	// Gas cost to claim stkAave rewards
	uint32 stkAaveClaimGasCost = 50000;

	address[] public tokenToDaiSwapPath;

	/**
	 * @param _token Token to swap DEFI token
	 * @param _lendingPool LendingPool address
	 * @param _ns Address of the NameService
	 * @param _tokenName Name of the staking token which will be provided to staker for their staking share
	 * @param _tokenSymbol Symbol of the staking token which will be provided to staker for their staking share
	 * @param _tokenSymbol Determines blocks to pass for 1x Multiplier
	 * @param _tokenUsdOracle address of the TOKEN/USD oracle
	 * @param _incentiveController Aave incentive controller which provides AAVE rewards
	 * @param _aaveUSDOracle address of the AAVE/USD oracle
	 */
	function init(
		address _token,
		address _lendingPool,
		INameService _ns,
		string memory _tokenName,
		string memory _tokenSymbol,
		uint64 _maxRewardThreshold,
		address _tokenUsdOracle,
		IAaveIncentivesController _incentiveController,
		address _aaveUSDOracle,
		address[] memory _tokenToDaiSwapPath
	) public {
		lendingPool = ILendingPool(_lendingPool);
		DataTypes.ReserveData memory reserve = lendingPool.getReserveData(_token);
		initialize(
			_token,
			reserve.aTokenAddress,
			_ns,
			_tokenName,
			_tokenSymbol,
			_maxRewardThreshold
		);
		require(
			_tokenToDaiSwapPath[0] == _token &&
				_tokenToDaiSwapPath[_tokenToDaiSwapPath.length - 1] ==
				nameService.getAddress("DAI"),
			"invalid _tokenToDaiSwapPath"
		);
		tokenToDaiSwapPath = _tokenToDaiSwapPath;

		//above  initialize going  to revert on second call, so this is safe
		tokenUsdOracle = _tokenUsdOracle;
		incentiveController = _incentiveController;
		aaveUSDOracle = _aaveUSDOracle;

		_approveTokens();
	}

	/**
	 * @dev stake some Token
	 * @param _amount of Token to stake
	 */
	function mintInterestToken(uint256 _amount) internal override {
		lendingPool.deposit(address(token), _amount, address(this), 0);
	}

	/**
	 * @dev redeem Token from aave
	 * @param _amount of token to redeem in Token
	 */
	function redeem(uint256 _amount) internal override {
		uint256 withdrawnAmount = lendingPool.withdraw(
			address(token),
			_amount,
			address(this)
		);
		require(withdrawnAmount > 0, "Withdrawn amount should be bigger than zero");
	}

	/**
	 * @dev Function to redeem aToken for DAI, so reserve knows how to handle it. (reserve can handle dai or cdai)
	 * also transfers stkaave to reserve
	 * @dev _amount of token in iToken
	 * @dev _recipient recipient of the DAI
	 * @return actualTokenGains amount of token redeemed for dai,
			actualRewardTokenGains amount of reward token earned,
			daiAmount total dai received
	 */
	function redeemUnderlyingToDAI(uint256 _amount, address _recipient)
		internal
		override
		returns (
			uint256 actualTokenGains,
			uint256 actualRewardTokenGains,
			uint256 daiAmount
		)
	{
		//out of requested interests to withdraw how much is it safe to swap
		actualTokenGains = IHasRouter(this).maxSafeTokenAmount(
			address(token),
			tokenToDaiSwapPath[1],
			_amount,
			maxLiquidityPercentageSwap
		);

		lendingPool.withdraw(address(token), actualTokenGains, address(this));
		actualTokenGains = token.balanceOf(address(this));

		address[] memory tokenAddress = new address[](1);
		tokenAddress[0] = address(token);

		actualRewardTokenGains = incentiveController.claimRewards(
			tokenAddress,
			type(uint256).max,
			_recipient
		);

		if (actualTokenGains > 0) {
			daiAmount = IHasRouter(this).swap(
				tokenToDaiSwapPath,
				actualTokenGains,
				0,
				_recipient
			);
		}
	}

	/**
	 * @dev returns decimals of token.
	 */
	function tokenDecimal() internal view override returns (uint256) {
		ERC20 token = ERC20(address(token));
		return uint256(token.decimals());
	}

	/**
	 * @dev returns decimals of interest token.
	 */
	function iTokenDecimal() internal view override returns (uint256) {
		ERC20 aToken = ERC20(address(iToken));
		return uint256(aToken.decimals());
	}

	/**
	 * @dev Function that calculates current interest gains of this staking contract
	 * @param _returnTokenBalanceInUSD determine return token balance of staking contract in USD
	 * @param _returnTokenGainsInUSD determine return token gains of staking contract in USD
	 * @return return gains in itoken,Token and worth of total locked Tokens,token balance in USD,token Gains in USD
	 */
	function currentGains(
		bool _returnTokenBalanceInUSD,
		bool _returnTokenGainsInUSD
	)
		public
		view
		override
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		ERC20 aToken = ERC20(address(iToken));
		uint256 tokenBalance = aToken.balanceOf(address(this));
		uint256 balanceInUSD = _returnTokenBalanceInUSD
			? getTokenValueInUSD(tokenUsdOracle, tokenBalance, token.decimals())
			: 0;
		address[] memory tokenAddress = new address[](1);
		tokenAddress[0] = address(token);
		if (tokenBalance <= totalProductivity) {
			return (0, 0, tokenBalance, balanceInUSD, 0);
		}
		uint256 tokenGains = tokenBalance - totalProductivity;

		uint256 tokenGainsInUSD = _returnTokenGainsInUSD
			? getTokenValueInUSD(tokenUsdOracle, tokenGains, token.decimals())
			: 0;
		return (
			tokenGains, // since token gains = atoken gains
			tokenGains,
			tokenBalance,
			balanceInUSD,
			tokenGainsInUSD
		);
	}

	/**
	 * @dev Function to get interest transfer cost for this particular staking contract
	 */
	function getGasCostForInterestTransfer()
		external
		view
		override
		returns (uint32)
	{
		address[] memory tokenAddress = new address[](1);
		tokenAddress[0] = address(token);
		uint256 stkAaaveBalance = incentiveController.getRewardsBalance(
			tokenAddress,
			address(this)
		);
		if (stkAaaveBalance > 0)
			return collectInterestGasCost + stkAaveClaimGasCost;

		return collectInterestGasCost;
	}

	/**
	 * @dev Set Gas cost to interest collection for this contract
	 * @param _collectInterestGasCost Gas cost to collect interest
	 * @param _rewardTokenCollectCost gas cost to collect reward tokens
	 */
	function setcollectInterestGasCostParams(
		uint32 _collectInterestGasCost,
		uint32 _rewardTokenCollectCost
	) external {
		_onlyAvatar();
		collectInterestGasCost = _collectInterestGasCost;
		stkAaveClaimGasCost = _rewardTokenCollectCost;
	}

	/**
	 * @dev Calculates worth of given amount of iToken in Token
	 * @param _amount Amount of token to calculate worth in Token
	 * @return Worth of given amount of token in Token
	 */
	function iTokenWorthInToken(uint256 _amount)
		public
		view
		override
		returns (uint256)
	{
		return _amount; // since aToken is peg to Token 1:1 return exact amount
	}

	function _approveTokens() internal override {
		address uniswapRouter = nameService.getAddress("UNISWAP_ROUTER");
		token.approve(uniswapRouter, type(uint256).max);
		token.approve(address(lendingPool), type(uint256).max); // approve the transfers to defi protocol as much as possible in order to save gas
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../Interfaces.sol";
import "../DAOStackInterfaces.sol";
import "../utils/NameService.sol";
import "../utils/DAOContract.sol";
import "./GoodFundManager.sol";
import "./BaseShareField.sol";
import "../governance/StakersDistribution.sol";
import "./UniswapV2SwapHelper.sol";

/**
 * @title Staking contract that donates earned interest to the DAO
 * allowing stakers to deposit Tokens
 * or withdraw their stake in Tokens
 * the FundManager can request to receive the interest
 */
abstract contract SimpleStaking is
	ERC20Upgradeable,
	DAOContract,
	BaseShareField,
	ReentrancyGuardUpgradeable,
	IHasRouter
{
	// Token address
	ERC20 public token;
	// Interest Token address
	ERC20 public iToken;

	// emergency pause
	bool public isPaused;

	//max percentage of token/dai pool liquidity to swap to DAI when collecting interest out of 100000
	uint24 public maxLiquidityPercentageSwap = 300; //0.3%

	/**
	 * @dev Emitted when `staker` stake `value` tokens of `token`
	 */
	event Staked(address indexed staker, address token, uint256 value);

	/**
	 * @dev Emitted when `staker` withdraws their stake `value` tokens and contracts balance will
	 * be reduced to`remainingBalance`.
	 */
	event StakeWithdraw(address indexed staker, address token, uint256 value);

	/**
	 * @dev Emitted when fundmanager transfers intrest collected from defi protrocol.
	 * `recipient` will receive `intrestTokenValue` as intrest.
	 */
	event InterestCollected(
		address recipient,
		uint256 iTokenGains, // interest accrued
		uint256 tokenGains, // interest worth in underlying token value
		uint256 actualTokenRedeemed, //actual token redeemed in uniswap (max 0.3% of liquidity) to DAI
		uint256 actualRewardTokenEarned, //actual reward token earned
		uint256 interestCollectedInDAI //actual dai sent to the reserve as interest from converting token and optionally reward token in uniswap
	);

	/**
	 * @dev Constructor
	 * @param _token The address of Token
	 * @param _iToken The address of Interest Token
	 * @param _ns The address of the INameService contract
	 * @param _tokenName The name of the staking token
	 * @param _tokenSymbol The symbol of the staking token
	 * @param _maxRewardThreshold the blocks that should pass to get 1x reward multiplier

	 */
	function initialize(
		address _token,
		address _iToken,
		INameService _ns,
		string memory _tokenName,
		string memory _tokenSymbol,
		uint64 _maxRewardThreshold
	) public virtual initializer {
		setDAO(_ns);
		token = ERC20(_token);
		iToken = ERC20(_iToken);
		__ERC20_init(_tokenName, _tokenSymbol);
		require(
			token.decimals() <= 18,
			"Token decimals should be less than 18 decimals"
		);
		tokenDecimalDifference = 18 - token.decimals();
		maxMultiplierThreshold = _maxRewardThreshold;
	}

	function setMaxLiquidityPercentageSwap(uint24 _maxPercentage) public virtual {
		_onlyAvatar();
		maxLiquidityPercentageSwap = _maxPercentage;
	}

	/**
	 * @dev Calculates worth of given amount of iToken in Token
	 * @param _amount Amount of iToken to calculate worth in Token
	 * @return Worth of given amount of iToken in Token
	 */
	function iTokenWorthInToken(uint256 _amount)
		public
		view
		virtual
		returns (uint256);

	/**
	 * @dev Get gas cost for interest transfer so can be used in the calculation of collectable interest for particular gas amount
	 * @return returns hardcoded gas cost
	 */
	function getGasCostForInterestTransfer()
		external
		view
		virtual
		returns (uint32);

	/**
	 * @dev Returns decimal value for token.
	 */
	function tokenDecimal() internal view virtual returns (uint256);

	/**
	 * @dev Returns decimal value for intrest token.
	 */
	function iTokenDecimal() internal view virtual returns (uint256);

	/**
	 * @dev Redeem invested tokens from defi protocol.
	 * @param _amount tokens to be redeemed.
	 */
	function redeem(uint256 _amount) internal virtual;

	/**
	 * @dev Redeem invested underlying tokens from defi protocol and exchange into DAI
	 * @param _amount tokens to be redeemed
	 * @return amount of token swapped to dai, amount of reward token swapped to dai, total dai
	 */
	function redeemUnderlyingToDAI(uint256 _amount, address _recipient)
		internal
		virtual
		returns (
			uint256,
			uint256,
			uint256
		);

	/**
	 * @dev Invests staked tokens to defi protocol.
	 * @param _amount tokens staked.
	 */
	function mintInterestToken(uint256 _amount) internal virtual;

	/**
	 * @dev Function that calculates current interest gains of this staking contract
	 * @param _returnTokenBalanceInUSD determine return token balance of staking contract in USD
	 * @param _returnTokenGainsInUSD determine return token gains of staking contract in USD
	 * @return return gains in itoken,Token and worth of total locked Tokens,token balance in USD (8 decimals),token Gains in USD (8 decimals)
	 */
	function currentGains(
		bool _returnTokenBalanceInUSD,
		bool _returnTokenGainsInUSD
	)
		public
		view
		virtual
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		);

	/**
	 * @dev Approve infinite tokens to defi protocols in order to save gas
	 */
	function _approveTokens() internal virtual;

	/**
	 * @dev Allows a staker to deposit Tokens. Notice that `approve` is
	 * needed to be executed before the execution of this method.
	 * Can be executed only when the contract is not paused.
	 * @param _amount The amount of Token or iToken to stake (it depends on _inInterestToken parameter)
	 * @param _donationPer The % of interest staker want to donate.
	 * @param _inInterestToken specificy if stake in iToken or Token
	 */
	function stake(
		uint256 _amount,
		uint256 _donationPer,
		bool _inInterestToken
	) external virtual nonReentrant {
		require(isPaused == false, "Staking is paused");
		require(
			_donationPer == 0 || _donationPer == 100,
			"Donation percentage should be 0 or 100"
		);
		require(_amount > 0, "You need to stake a positive token amount");
		require(
			(_inInterestToken ? iToken : token).transferFrom(
				_msgSender(),
				address(this),
				_amount
			),
			"transferFrom failed, make sure you approved token transfer"
		);
		_amount = _inInterestToken ? iTokenWorthInToken(_amount) : _amount;
		if (_inInterestToken == false) {
			mintInterestToken(_amount); //mint iToken
		}
		_mint(_msgSender(), _amount); // mint Staking token for staker
		(
			uint32 rewardsPerBlock,
			uint64 blockStart,
			uint64 blockEnd,

		) = GoodFundManager(nameService.getAddress("FUND_MANAGER"))
				.rewardsForStakingContract(address(this));
		_increaseProductivity(
			_msgSender(),
			_amount,
			rewardsPerBlock,
			blockStart,
			blockEnd,
			_donationPer
		);

		//notify GDAO distrbution for stakers
		StakersDistribution sd = StakersDistribution(
			nameService.getAddress("GDAO_STAKERS")
		);
		if (address(sd) != address(0)) {
			uint256 stakeAmountInEighteenDecimals = token.decimals() == 18
				? _amount
				: _amount * 10**(18 - token.decimals());
			sd.userStaked(_msgSender(), stakeAmountInEighteenDecimals);
		}

		emit Staked(_msgSender(), address(token), _amount);
	}

	/**
	 * @dev Withdraws the sender staked Token.
	 * @param _amount Amount to withdraw in Token or iToken
	 * @param _inInterestToken if true _amount is in iToken and also returned in iToken other wise use Token
	 */
	function withdrawStake(uint256 _amount, bool _inInterestToken)
		external
		virtual
		nonReentrant
	{
		uint256 tokenWithdraw;

		if (_inInterestToken) {
			uint256 tokenWorth = iTokenWorthInToken(_amount);
			require(
				iToken.transfer(_msgSender(), _amount),
				"withdraw transfer failed"
			);
			tokenWithdraw = _amount = tokenWorth;
		} else {
			tokenWithdraw = _amount;
			redeem(tokenWithdraw);

			//this is required for redeem precision loss
			uint256 tokenActual = token.balanceOf(address(this));
			if (tokenActual < tokenWithdraw) {
				tokenWithdraw = tokenActual;
			}
			require(
				token.transfer(_msgSender(), tokenWithdraw),
				"withdraw transfer failed"
			);
		}

		GoodFundManager fm = GoodFundManager(
			nameService.getAddress("FUND_MANAGER")
		);

		//this will revert in case user doesnt have enough productivity to withdraw _amount, as productivity=staking tokens amount
		_burn(msg.sender, _amount); // burn their staking tokens

		(uint32 rewardsPerBlock, uint64 blockStart, uint64 blockEnd, ) = fm
			.rewardsForStakingContract(address(this));

		_decreaseProductivity(
			_msgSender(),
			_amount,
			rewardsPerBlock,
			blockStart,
			blockEnd
		);
		fm.mintReward(nameService.getAddress("CDAI"), _msgSender()); // send rewards to user and use cDAI address since reserve in cDAI

		//notify GDAO distrbution for stakers
		StakersDistribution sd = StakersDistribution(
			nameService.getAddress("GDAO_STAKERS")
		);
		if (address(sd) != address(0)) {
			uint256 withdrawAmountInEighteenDecimals = token.decimals() == 18
				? _amount
				: _amount * 10**(18 - token.decimals());
			sd.userWithdraw(_msgSender(), withdrawAmountInEighteenDecimals);
		}

		emit StakeWithdraw(msg.sender, address(token), tokenWithdraw);
	}

	/**
	 * @dev withdraw staker G$ rewards + GDAO rewards
	 * withdrawing rewards resets the multiplier! so if user just want GDAO he should use claimReputation()
	 */
	function withdrawRewards() external nonReentrant {
		GoodFundManager(nameService.getAddress("FUND_MANAGER")).mintReward(
			nameService.getAddress("CDAI"),
			_msgSender()
		); // send rewards to user and use cDAI address since reserve in cDAI
		claimReputation();
	}

	/**
	 * @dev withdraw staker GDAO rewards
	 */
	function claimReputation() public {
		//claim reputation rewards
		StakersDistribution sd = StakersDistribution(
			nameService.getAddress("GDAO_STAKERS")
		);
		if (address(sd) != address(0)) {
			address[] memory contracts = new address[](1);
			contracts[0] = (address(this));
			sd.claimReputation(_msgSender(), contracts);
		}
	}

	/**
	 * @dev notify stakersdistribution when user performs transfer operation
	 */
	function _transfer(
		address _from,
		address _to,
		uint256 _value
	) internal override {
		super._transfer(_from, _to, _value);

		StakersDistribution sd = StakersDistribution(
			nameService.getAddress("GDAO_STAKERS")
		);
		(
			uint32 rewardsPerBlock,
			uint64 blockStart,
			uint64 blockEnd,

		) = GoodFundManager(nameService.getAddress("FUND_MANAGER"))
				.rewardsForStakingContract(address(this));

		_decreaseProductivity(_from, _value, rewardsPerBlock, blockStart, blockEnd);

		_increaseProductivity(
			_to,
			_value,
			rewardsPerBlock,
			blockStart,
			blockEnd,
			0
		);

		if (address(sd) != address(0)) {
			address[] memory contracts;
			contracts[0] = (address(this));
			sd.userWithdraw(_from, _value);
			sd.userStaked(_to, _value);
		}
	}

	// @dev To find difference in token's decimal and iToken's decimal
	// @return difference in decimals.
	// @return true if token's decimal is more than iToken's
	function tokenDecimalPrecision() internal view returns (uint256, bool) {
		uint256 _tokenDecimal = tokenDecimal();
		uint256 _iTokenDecimal = iTokenDecimal();
		uint256 decimalDifference = _tokenDecimal > _iTokenDecimal
			? _tokenDecimal - _iTokenDecimal
			: _iTokenDecimal - _tokenDecimal;
		return (decimalDifference, _tokenDecimal > _iTokenDecimal);
	}

	/**
	 * @dev Collects gained interest by fundmanager.
	 * @param _recipient The recipient of cDAI gains
	 * @return actualTokenRedeemed  actualRewardTokenRedeemed actualDai collected interest from token,
	 * collected interest from reward token, total DAI received from swapping token+reward token
	 */
	function collectUBIInterest(address _recipient)
		public
		virtual
		returns (
			uint256 actualTokenRedeemed,
			uint256 actualRewardTokenRedeemed,
			uint256 actualDai
		)
	{
		_canMintRewards();
		// otherwise fund manager has to wait for the next interval
		require(
			_recipient != address(this),
			"Recipient cannot be the staking contract"
		);

		(uint256 iTokenGains, uint256 tokenGains, , , ) = currentGains(
			false,
			false
		);

		(
			actualTokenRedeemed,
			actualRewardTokenRedeemed,
			actualDai
		) = redeemUnderlyingToDAI(iTokenGains, _recipient);

		emit InterestCollected(
			_recipient,
			iTokenGains,
			tokenGains,
			actualTokenRedeemed,
			actualRewardTokenRedeemed,
			actualDai
		);
	}

	/**
	 * @dev making the contract inactive
	 * NOTICE: this could theoretically result in future interest earned in cdai to remain locked
	 */
	function pause(bool _isPaused) public {
		_onlyAvatar();
		isPaused = _isPaused;
	}

	/**
	 * @dev method to recover any stuck ERC20 tokens (ie  compound COMP)
	 * @param _token the ERC20 token to recover
	 */
	function recover(ERC20 _token) public {
		_onlyAvatar();
		uint256 toWithdraw = _token.balanceOf(address(this));

		// recover left iToken(stakers token) only when all stakes have been withdrawn
		if (address(_token) == address(iToken)) {
			require(
				totalProductivity == 0 && isPaused,
				"can recover iToken only when stakes have been withdrawn"
			);
		}
		require(
			_token.transfer(address(avatar), toWithdraw),
			"recover transfer failed"
		);
	}

	/**
	 @dev function calculate Token price in USD 
 	 @param _oracle chainlink oracle usd/token oralce
	 @param _amount Amount of Token to calculate worth of it
	 @param _decimals decimals of Token 
	 @return Returns worth of Tokens in USD
	 */
	function getTokenValueInUSD(
		address _oracle,
		uint256 _amount,
		uint256 _decimals
	) public view returns (uint256) {
		AggregatorV3Interface tokenPriceOracle = AggregatorV3Interface(_oracle);
		int256 tokenPriceinUSD = tokenPriceOracle.latestAnswer();
		return (uint256(tokenPriceinUSD) * _amount) / (10**_decimals); // tokenPriceinUSD in 8 decimals and _amount is in Token's decimals so we divide it to Token's decimal at the end to reduce 8 decimals back
	}

	function _canMintRewards() internal view override {
		require(
			_msgSender() == nameService.getAddress("FUND_MANAGER"),
			"Only FundManager can call this method"
		);
	}

	function decimals() public view virtual override returns (uint8) {
		return token.decimals();
	}

	/**
	 * @param _staker account to get rewards status for
	 * @return (minted, pending) in G$ 2 decimals
	 */
	function getUserMintedAndPending(address _staker)
		external
		view
		returns (uint256, uint256)
	{
		(
			uint32 rewardsPerBlock,
			uint64 blockStart,
			uint64 blockEnd,

		) = GoodFundManager(nameService.getAddress("FUND_MANAGER"))
				.rewardsForStakingContract(address(this));

		uint256 pending = getUserPendingReward(
			_staker,
			rewardsPerBlock,
			blockStart,
			blockEnd
		);

		//divide by 1e16 to return in 2 decimals
		return (users[_staker].rewardMinted / 1e16, pending / 1e16);
	}

	function getRouter() public view override returns (Uniswap) {
		return Uniswap(nameService.getAddress("UNISWAP_ROUTER"));
	}
}

// SPDX-License-Identifier: MIT
import { DataTypes } from "./utils/DataTypes.sol";
pragma solidity >=0.8.0;

pragma experimental ABIEncoderV2;

interface ERC20 {
	function balanceOf(address addr) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function approve(address spender, uint256 amount) external returns (bool);

	function decimals() external view returns (uint8);

	function mint(address to, uint256 mintAmount) external returns (uint256);

	function totalSupply() external view returns (uint256);

	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Transfer(
		address indexed from,
		address indexed to,
		uint256 amount,
		bytes data
	);
}

interface cERC20 is ERC20 {
	function mint(uint256 mintAmount) external returns (uint256);

	function redeemUnderlying(uint256 mintAmount) external returns (uint256);

	function redeem(uint256 mintAmount) external returns (uint256);

	function exchangeRateCurrent() external returns (uint256);

	function exchangeRateStored() external view returns (uint256);

	function underlying() external returns (address);
}

interface IGoodDollar is ERC20 {
	function getFees(uint256 value) external view returns (uint256, bool);

	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;

	function renounceMinter() external;

	function addMinter(address minter) external;

	function isMinter(address minter) external view returns (bool);

	function transferAndCall(
		address to,
		uint256 value,
		bytes calldata data
	) external returns (bool);

	function formula() external view returns (address);
}

interface IERC2917 is ERC20 {
	/// @dev This emit when interests amount per block is changed by the owner of the contract.
	/// It emits with the old interests amount and the new interests amount.
	event InterestRatePerBlockChanged(uint256 oldValue, uint256 newValue);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityIncreased(address indexed user, uint256 value);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityDecreased(address indexed user, uint256 value);

	/// @dev Return the current contract's interests rate per block.
	/// @return The amount of interests currently producing per each block.
	function interestsPerBlock() external view returns (uint256);

	/// @notice Change the current contract's interests rate.
	/// @dev Note the best practice will be restrict the gross product provider's contract address to call this.
	/// @return The true/fase to notice that the value has successfully changed or not, when it succeed, it will emite the InterestRatePerBlockChanged event.
	function changeInterestRatePerBlock(uint256 value) external returns (bool);

	/// @notice It will get the productivity of given user.
	/// @dev it will return 0 if user has no productivity proved in the contract.
	/// @return user's productivity and overall productivity.
	function getProductivity(address user)
		external
		view
		returns (uint256, uint256);

	/// @notice increase a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity added success.
	function increaseProductivity(address user, uint256 value)
		external
		returns (bool);

	/// @notice decrease a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity removed success.
	function decreaseProductivity(address user, uint256 value)
		external
		returns (bool);

	/// @notice take() will return the interests that callee will get at current block height.
	/// @dev it will always calculated by block.number, so it will change when block height changes.
	/// @return amount of the interests that user are able to mint() at current block height.
	function take() external view returns (uint256);

	/// @notice similar to take(), but with the block height joined to calculate return.
	/// @dev for instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interests.
	/// @return amount of interests and the block height.
	function takeWithBlock() external view returns (uint256, uint256);

	/// @notice mint the avaiable interests to callee.
	/// @dev once it mint, the amount of interests will transfer to callee's address.
	/// @return the amount of interests minted.
	function mint() external returns (uint256);
}

interface Staking {
	struct Staker {
		// The staked DAI amount
		uint256 stakedDAI;
		// The latest block number which the
		// staker has staked tokens
		uint256 lastStake;
	}

	function stakeDAI(uint256 amount) external;

	function withdrawStake() external;

	function stakers(address staker) external view returns (Staker memory);
}

interface Uniswap {
	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function WETH() external pure returns (address);

	function factory() external pure returns (address);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountOut(
		uint256 amountI,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountsOut(uint256 amountIn, address[] memory path)
		external
		pure
		returns (uint256[] memory amounts);
}

interface UniswapFactory {
	function getPair(address tokenA, address tokenB)
		external
		view
		returns (address);
}

interface UniswapPair {
	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast
		);

	function kLast() external view returns (uint256);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);
}

interface Reserve {
	function buy(
		address _buyWith,
		uint256 _tokenAmount,
		uint256 _minReturn
	) external returns (uint256);
}

interface IIdentity {
	function isWhitelisted(address user) external view returns (bool);

	function addWhitelistedWithDID(address account, string memory did) external;

	function removeWhitelisted(address account) external;

	function addIdentityAdmin(address account) external returns (bool);

	function setAvatar(address _avatar) external;

	function isIdentityAdmin(address account) external view returns (bool);

	function owner() external view returns (address);

	event WhitelistedAdded(address user);
}

interface IUBIScheme {
	function currentDay() external view returns (uint256);

	function periodStart() external view returns (uint256);

	function hasClaimed(address claimer) external view returns (bool);
}

interface IFirstClaimPool {
	function awardUser(address user) external returns (uint256);

	function claimAmount() external view returns (uint256);
}

interface ProxyAdmin {
	function getProxyImplementation(address proxy)
		external
		view
		returns (address);

	function getProxyAdmin(address proxy) external view returns (address);

	function upgrade(address proxy, address implementation) external;

	function owner() external view returns (address);

	function transferOwnership(address newOwner) external;
}

/**
 * @dev Interface for chainlink oracles to obtain price datas
 */
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

	function latestAnswer() external view returns (int256);
}

/**
	@dev interface for AAVE lending Pool
 */
interface ILendingPool {
	/**
	 * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
	 * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
	 * @param asset The address of the underlying asset to deposit
	 * @param amount The amount to be deposited
	 * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
	 *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
	 *   is a different wallet
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	/**
	 * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
	 * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
	 * @param asset The address of the underlying asset to withdraw
	 * @param amount The underlying amount to be withdrawn
	 *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
	 * @param to Address that will receive the underlying, same as msg.sender if the user
	 *   wants to receive it on his own wallet, or a different address if the beneficiary is a
	 *   different wallet
	 * @return The final amount withdrawn
	 **/
	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	/**
	 * @dev Returns the state and configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The state of the reserve
	 **/
	function getReserveData(address asset)
		external
		view
		returns (DataTypes.ReserveData memory);
}

interface IDonationStaking {
	function stakeDonations() external payable;
}

interface INameService {
	function getAddress(string memory _name) external view returns (address);
}

interface IAaveIncentivesController {
	/**
	 * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
	 * @param amount Amount of rewards to claim
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewards(
		address[] calldata assets,
		uint256 amount,
		address to
	) external returns (uint256);

	/**
	 * @dev Returns the total of rewards of an user, already accrued + not yet accrued
	 * @param user The address of the user
	 * @return The rewards
	 **/
	function getRewardsBalance(address[] calldata assets, address user)
		external
		view
		returns (uint256);
}

interface IGoodStaking {
	function collectUBIInterest(address recipient)
		external
		returns (
			uint256,
			uint256,
			uint256
		);

	function iToken() external view returns (address);

	function currentGains(
		bool _returnTokenBalanceInUSD,
		bool _returnTokenGainsInUSD
	)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		);

	function getRewardEarned(address user) external view returns (uint256);

	function getGasCostForInterestTransfer() external view returns (uint256);

	function rewardsMinted(
		address user,
		uint256 rewardsPerBlock,
		uint256 blockStart,
		uint256 blockEnd
	) external returns (uint256);
}

interface IHasRouter {
	function getRouter() external view returns (Uniswap);
}

interface IAdminWallet {
	function addAdmins(address payable[] memory _admins) external;

	function removeAdmins(address[] memory _admins) external;

	function owner() external view returns (address);

	function transferOwnership(address _owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library DataTypes {
	// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
	struct ReserveData {
		//stores the reserve configuration
		ReserveConfigurationMap configuration;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//variable borrow index. Expressed in ray
		uint128 variableBorrowIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//the current variable borrow rate. Expressed in ray
		uint128 currentVariableBorrowRate;
		//the current stable borrow rate. Expressed in ray
		uint128 currentStableBorrowRate;
		uint40 lastUpdateTimestamp;
		//tokens addresses
		address aTokenAddress;
		address stableDebtTokenAddress;
		address variableDebtTokenAddress;
		//address of the interest rate strategy
		address interestRateStrategyAddress;
		//the id of the reserve. Represents the position in the list of the active reserves
		uint8 id;
	}

	struct ReserveConfigurationMap {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: Reserve is active
		//bit 57: reserve is frozen
		//bit 58: borrowing is enabled
		//bit 59: stable rate borrowing enabled
		//bit 60-63: reserved
		//bit 64-79: reserve factor
		uint256 data;
	}
	enum InterestRateMode { NONE, STABLE, VARIABLE }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
import "../utils/DAOContract.sol";
import "../Interfaces.sol";

library UniswapV2SwapHelper {
	/**
	 *@dev Helper to calculate percentage out of token liquidity in pool that is safe to exchange against sandwich attack.
	 * also checks if token->eth has better safe limit, so perhaps doing tokenA->eth->tokenB is better than tokenA->tokenB
	 * in that case it could be that eth->tokenB can be attacked because we dont know if eth received for tokenA->eth is less than _maxPercentage of the liquidity in
	 * eth->tokenB. In our use case it is always eth->dai so either it will be safe or very minimal
	 *@param _inToken address of token we are swapping
	 *@param _outToken address of swap result token
	 *@param _inTokenAmount amount of in token required to swap
	 *@param _maxLiquidityPercentageSwap max percentage of liquidity to swap to token
	 * when swapping tokens and this value is out of 100000 so for example if you want to set it to 0.3 you need set it to 300
	 */
	function maxSafeTokenAmount(
		IHasRouter _iHasRouter,
		address _inToken,
		address _outToken,
		uint256 _inTokenAmount,
		uint256 _maxLiquidityPercentageSwap
	) public view returns (uint256 safeAmount) {
		Uniswap uniswap = _iHasRouter.getRouter();
		address wETH = uniswap.WETH();
		_inToken = _inToken == address(0x0) ? wETH : _inToken;
		_outToken = _outToken == address(0x0) ? wETH : _outToken;
		UniswapPair pair = UniswapPair(
			UniswapFactory(uniswap.factory()).getPair(_inToken, _outToken)
		);
		(uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
		uint112 reserve = reserve0;
		if (_inToken == pair.token1()) {
			reserve = reserve1;
		}

		safeAmount = (reserve * _maxLiquidityPercentageSwap) / 100000;

		return safeAmount < _inTokenAmount ? safeAmount : _inTokenAmount;
	}

	/**
	@dev Helper to swap tokens in the Uniswap
	*@param _path the buy path
	*@param _tokenAmount token amount to swap
	*@param _minTokenReturn minimum token amount to get in swap transaction
	*@param _receiver receiver of tokens after swap transaction
    *
	 */
	function swap(
		IHasRouter _iHasRouter,
		address[] memory _path,
		uint256 _tokenAmount,
		uint256 _minTokenReturn,
		address _receiver
	) internal returns (uint256 swapResult) {
		Uniswap uniswapContract = _iHasRouter.getRouter();
		uint256[] memory result;

		if (_path[0] == address(0x0)) {
			_path[0] = uniswapContract.WETH();
			result = uniswapContract.swapExactETHForTokens{ value: _tokenAmount }(
				_minTokenReturn,
				_path,
				_receiver,
				block.timestamp
			);
		} else if (_path[_path.length - 1] == address(0x0)) {
			_path[_path.length - 1] = uniswapContract.WETH();
			result = uniswapContract.swapExactTokensForETH(
				_tokenAmount,
				_minTokenReturn,
				_path,
				_receiver,
				block.timestamp
			);
		} else {
			result = uniswapContract.swapExactTokensForTokens(
				_tokenAmount,
				_minTokenReturn,
				_path,
				_receiver,
				block.timestamp
			);
		}
		return result[result.length - 1];
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

pragma solidity >=0.8.0;

interface Avatar {
	function nativeToken() external view returns (address);

	function nativeReputation() external view returns (address);

	function owner() external view returns (address);
}

interface Controller {
	event RegisterScheme(address indexed _sender, address indexed _scheme);
	event UnregisterScheme(address indexed _sender, address indexed _scheme);

	function genericCall(
		address _contract,
		bytes calldata _data,
		address _avatar,
		uint256 _value
	) external returns (bool, bytes memory);

	function avatar() external view returns (address);

	function unregisterScheme(address _scheme, address _avatar)
		external
		returns (bool);

	function unregisterSelf(address _avatar) external returns (bool);

	function registerScheme(
		address _scheme,
		bytes32 _paramsHash,
		bytes4 _permissions,
		address _avatar
	) external returns (bool);

	function isSchemeRegistered(address _scheme, address _avatar)
		external
		view
		returns (bool);

	function getSchemePermissions(address _scheme, address _avatar)
		external
		view
		returns (bytes4);

	function addGlobalConstraint(
		address _constraint,
		bytes32 _paramHash,
		address _avatar
	) external returns (bool);

	function mintTokens(
		uint256 _amount,
		address _beneficiary,
		address _avatar
	) external returns (bool);

	function externalTokenTransfer(
		address _token,
		address _recipient,
		uint256 _amount,
		address _avatar
	) external returns (bool);

	function sendEther(
		uint256 _amountInWei,
		address payable _to,
		address _avatar
	) external returns (bool);
}

interface GlobalConstraintInterface {
	enum CallPhase {
		Pre,
		Post,
		PreAndPost
	}

	function pre(
		address _scheme,
		bytes32 _params,
		bytes32 _method
	) external returns (bool);

	/**
	 * @dev when return if this globalConstraints is pre, post or both.
	 * @return CallPhase enum indication  Pre, Post or PreAndPost.
	 */
	function when() external returns (CallPhase);
}

interface ReputationInterface {
	function balanceOf(address _user) external view returns (uint256);

	function balanceOfAt(address _user, uint256 _blockNumber)
		external
		view
		returns (uint256);

	function getVotes(address _user) external view returns (uint256);

	function getVotesAt(
		address _user,
		bool _global,
		uint256 _blockNumber
	) external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function totalSupplyAt(uint256 _blockNumber)
		external
		view
		returns (uint256);

	function delegateOf(address _user) external returns (address);
}

interface SchemeRegistrar {
	function proposeScheme(
		Avatar _avatar,
		address _scheme,
		bytes32 _parametersHash,
		bytes4 _permissions,
		string memory _descriptionHash
	) external returns (bytes32);

	event NewSchemeProposal(
		address indexed _avatar,
		bytes32 indexed _proposalId,
		address indexed _intVoteInterface,
		address _scheme,
		bytes32 _parametersHash,
		bytes4 _permissions,
		string _descriptionHash
	);
}

interface IntVoteInterface {
	event NewProposal(
		bytes32 indexed _proposalId,
		address indexed _organization,
		uint256 _numOfChoices,
		address _proposer,
		bytes32 _paramsHash
	);

	event ExecuteProposal(
		bytes32 indexed _proposalId,
		address indexed _organization,
		uint256 _decision,
		uint256 _totalReputation
	);

	event VoteProposal(
		bytes32 indexed _proposalId,
		address indexed _organization,
		address indexed _voter,
		uint256 _vote,
		uint256 _reputation
	);

	event CancelProposal(
		bytes32 indexed _proposalId,
		address indexed _organization
	);
	event CancelVoting(
		bytes32 indexed _proposalId,
		address indexed _organization,
		address indexed _voter
	);

	/**
	 * @dev register a new proposal with the given parameters. Every proposal has a unique ID which is being
	 * generated by calculating keccak256 of a incremented counter.
	 * @param _numOfChoices number of voting choices
	 * @param _proposalParameters defines the parameters of the voting machine used for this proposal
	 * @param _proposer address
	 * @param _organization address - if this address is zero the msg.sender will be used as the organization address.
	 * @return proposal's id.
	 */
	function propose(
		uint256 _numOfChoices,
		bytes32 _proposalParameters,
		address _proposer,
		address _organization
	) external returns (bytes32);

	function vote(
		bytes32 _proposalId,
		uint256 _vote,
		uint256 _rep,
		address _voter
	) external returns (bool);

	function cancelVote(bytes32 _proposalId) external;

	function getNumberOfChoices(bytes32 _proposalId)
		external
		view
		returns (uint256);

	function isVotable(bytes32 _proposalId) external view returns (bool);

	/**
	 * @dev voteStatus returns the reputation voted for a proposal for a specific voting choice.
	 * @param _proposalId the ID of the proposal
	 * @param _choice the index in the
	 * @return voted reputation for the given choice
	 */
	function voteStatus(bytes32 _proposalId, uint256 _choice)
		external
		view
		returns (uint256);

	/**
	 * @dev isAbstainAllow returns if the voting machine allow abstain (0)
	 * @return bool true or false
	 */
	function isAbstainAllow() external pure returns (bool);

	/**
     * @dev getAllowedRangeOfChoices returns the allowed range of choices for a voting machine.
     * @return min - minimum number of choices
               max - maximum number of choices
     */
	function getAllowedRangeOfChoices()
		external
		pure
		returns (uint256 min, uint256 max);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../DAOStackInterfaces.sol";

/**
@title Simple name to address resolver
*/

contract NameService is Initializable, UUPSUpgradeable {
	mapping(bytes32 => address) public addresses;

	Controller public dao;
	event AddressChanged(string name ,address addr);
	function initialize(
		Controller _dao,
		bytes32[] memory _nameHashes,
		address[] memory _addresses
	) public virtual initializer {
		dao = _dao;
		for (uint256 i = 0; i < _nameHashes.length; i++) {
			addresses[_nameHashes[i]] = _addresses[i];
		}
		addresses[keccak256(bytes("CONTROLLER"))] = address(_dao);
		addresses[keccak256(bytes("AVATAR"))] = address(_dao.avatar());
	}

	function _authorizeUpgrade(address) internal override {
		_onlyAvatar();
	}

	function _onlyAvatar() internal view {
		require(
			address(dao.avatar()) == msg.sender,
			"only avatar can call this method"
		);
	}

	function setAddress(string memory name, address addr) external {
		_onlyAvatar();
		addresses[keccak256(bytes(name))] = addr;
		emit AddressChanged(name, addr);
	}

	function setAddresses(bytes32[] calldata hash, address[] calldata addrs)
		external
	{
		_onlyAvatar();
		for (uint256 i = 0; i < hash.length; i++) {
			addresses[hash[i]] = addrs[i];
		}
	}

	function getAddress(string memory name) external view returns (address) {
		return addresses[keccak256(bytes(name))];
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../DAOStackInterfaces.sol";
import "../Interfaces.sol";

/**
@title Simple contract that keeps DAO contracts registery
*/

contract DAOContract {
	Controller public dao;

	address public avatar;

	INameService public nameService;

	function _onlyAvatar() internal view {
		require(
			address(dao.avatar()) == msg.sender,
			"only avatar can call this method"
		);
	}

	function setDAO(INameService _ns) internal {
		nameService = _ns;
		updateAvatar();
	}

	function updateAvatar() public {
		dao = Controller(nameService.getAddress("CONTROLLER"));
		avatar = dao.avatar();
	}

	function nativeToken() public view returns (IGoodDollar) {
		return IGoodDollar(nameService.getAddress("GOODDOLLAR"));
	}

	uint256[50] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../reserve/GoodReserveCDai.sol";
import "../Interfaces.sol";
import "../utils/DSMath.sol";
import "../utils/DAOUpgradeableContract.sol";

/**
 * @title GoodFundManager contract that transfer interest from the staking contract
 * to the reserve contract and transfer the return mintable tokens to the staking
 * contract
 * cDAI support only
 */
contract GoodFundManager is DAOUpgradeableContract, DSMath {
	// timestamp that indicates last time that interests collected
	uint256 public lastCollectedInterest;
	//just for UI to easily find last event
	uint256 public lastCollectedInterestBlock;

	// Gas cost for mint ubi+bridge ubi+mint rewards
	uint256 public gasCostExceptInterestCollect;
	// Gas cost for minting GD for keeper
	uint256 public gdMintGasCost;
	// how much time since last collectInterest should pass in order to cancel gas cost multiplier requirement for next collectInterest
	uint256 public collectInterestTimeThreshold;
	// to allow keeper to collect interest, total interest collected should be interestMultiplier*gas costs
	uint8 public interestMultiplier;
	//min amount of days between interest collection
	uint8 public minCollectInterestIntervalDays;
	//address of the active staking contracts
	address[] public activeContracts;

	event GasCostSet(uint256 newGasCost);
	event CollectInterestTimeThresholdSet(
		uint256 newCollectInterestTimeThreshold
	);
	event InterestMultiplierSet(uint8 newInterestMultiplier);
	event GasCostExceptInterestCollectSet(
		uint256 newGasCostExceptInterestCollect
	);
	event StakingRewardSet(
		uint32 _rewardsPerBlock,
		address _stakingAddress,
		uint32 _blockStart,
		uint32 _blockEnd,
		bool _isBlackListed
	);
	//Structure that hold reward information and if its blacklicksted or not for particular staking Contract
	struct Reward {
		uint32 blockReward; //in G$
		uint64 blockStart; // # of the start block to distribute rewards
		uint64 blockEnd; // # of the end block to distribute rewards
		bool isBlackListed; // If staking contract is blacklisted or not
	}
	struct InterestInfo {
		address contractAddress; // staking contract address which interest will be collected
		uint256 interestBalance; // Interest amount that staking contract has
		uint256 collectedInterestSoFar; // Collected interest amount so far including this contract
		uint256 gasCostSoFar; // Spent gas amount so far including this contract
		uint256 maxGasAmountSoFar; //  Max gas amount that can spend to collect this interest according to interest amount
		bool maxGasLargerOrEqualRequired; // Bool that indicates if max gas amount larger or equal to actual gas needed
	}
	// Rewards per block for particular Staking contract
	mapping(address => Reward) public rewardsForStakingContract;
	// Emits when `transferInterest` transfers
	// funds to the staking contract and to
	// the bridge
	event FundsTransferred(
		// The caller address
		address indexed caller,
		// The staking contract address
		//address indexed staking,
		// The reserve contract address
		address reserve,
		//addresses of the staking contracts
		address[] stakings,
		// Amount of cDai that was transferred
		// from the staking contract to the
		// reserve contract
		uint256 cDAIinterestEarned,
		// The number of tokens that have been minted
		// by the reserve to the staking contract
		//uint256 gdInterest,
		// The number of tokens that have been minted
		// by the reserve to the bridge which in his
		// turn should transfer those funds to the
		// sidechain
		uint256 gdUBI,
		// Amount of GD to be minted as reward
		//to the keeper which collect interests
		uint256 gdReward
	);

	event StakingRewardMinted(
		address stakingContract,
		address staker,
		uint256 gdReward
	);

	/**
	 * @dev Constructor
	 * @param _ns The address of the name Service
	 */
	function initialize(INameService _ns) public virtual initializer {
		setDAO(_ns);
		gdMintGasCost = 250000; // While testing highest amount was 240k so put 250k to be safe
		collectInterestTimeThreshold = 60 days;
		interestMultiplier = 4;
		gasCostExceptInterestCollect = 850000; //while testing highest amount was 800k so put 850k to be safe
		minCollectInterestIntervalDays = 7;
	}

	/**
	 * @dev Set gas cost to mint GD rewards for keeper
	 * @param _gasAmount amount of gas it costs for minting gd reward
	 */
	function setGasCost(uint256 _gasAmount) public {
		_onlyAvatar();
		gdMintGasCost = _gasAmount;
		emit GasCostSet(_gasAmount);
	}

	/**
	 * @dev Set collectInterestTimeThreshold to determine how much time should pass after collectInterest called
	 * after which we ignore the interest>=multiplier*gas costs limit
	 * @param _timeThreshold new threshold in seconds
	 */
	function setCollectInterestTimeThreshold(uint256 _timeThreshold) public {
		_onlyAvatar();
		collectInterestTimeThreshold = _timeThreshold;
		emit CollectInterestTimeThresholdSet(_timeThreshold);
	}

	/**
	 * @dev Set multiplier to determine how much times larger should be collected interest than spent gas when collectInterestTimeThreshold did not pass
	 */
	function setInterestMultiplier(uint8 _newMultiplier) public {
		_onlyAvatar();
		interestMultiplier = _newMultiplier;
		emit InterestMultiplierSet(_newMultiplier);
	}

	/**
	 * @dev Set Gas cost for required transactions after collecting interest in collectInterest function
	 * we need this to know if caller has enough gas left to keep collecting interest
	 * @dev _gasAmount The gas amount that needed for transactions
	 */
	function setGasCostExceptInterestCollect(uint256 _gasAmount) public {
		_onlyAvatar();
		gasCostExceptInterestCollect = _gasAmount;
		emit GasCostExceptInterestCollectSet(_gasAmount);
	}

	/**
	 * @dev Sets the Reward for particular Staking contract
	 * @param _rewardsPerBlock reward for per block
	 * @param _stakingAddress address of the staking contract
	 * @param _blockStart block number for start reward distrubution
	 * @param _blockEnd block number for end reward distrubition
	 * @param _isBlackListed set staking contract blacklisted or not to prevent minting
	 */
	function setStakingReward(
		uint32 _rewardsPerBlock,
		address _stakingAddress,
		uint32 _blockStart,
		uint32 _blockEnd,
		bool _isBlackListed
	) public {
		_onlyAvatar();

		//we dont allow to undo blacklisting as it will mess up rewards accounting.
		//staking contracts are assumed immutable and thus non fixable
		require(
			(_isBlackListed ||
				!rewardsForStakingContract[_stakingAddress].isBlackListed),
			"can't undo blacklisting"
		);
		Reward memory reward = Reward(
			_rewardsPerBlock,
			_blockStart > 0 ? _blockStart : uint32(block.number),
			_blockEnd > 0 ? _blockEnd : 0xFFFFFFFF,
			_isBlackListed
		);
		rewardsForStakingContract[_stakingAddress] = reward;

		bool exist;
		uint8 i;
		for (i = 0; i < activeContracts.length; i++) {
			if (activeContracts[i] == _stakingAddress) {
				exist = true;
				break;
			}
		}

		if (exist && (_isBlackListed || _rewardsPerBlock == 0)) {
			activeContracts[i] = activeContracts[activeContracts.length - 1];
			activeContracts.pop();
		} else if (!exist && !(_isBlackListed || _rewardsPerBlock == 0)) {
			activeContracts.push(_stakingAddress);
		}
		emit StakingRewardSet(
			_rewardsPerBlock,
			_stakingAddress,
			_blockStart,
			_blockEnd,
			_isBlackListed
		);
	}

	/**
	 * @dev Collects UBI interest in iToken from a given staking contract and transfers
	 * that interest to the reserve contract. Then transfers the given gd which
	 * received from the reserve contract back to the staking contract and to the
	 * bridge, which locks the funds and then the GD tokens are been minted to the
	 * given address on the sidechain
	 * @param _stakingContracts from which contracts to collect interest
	 * @param _forceAndWaiverRewards if set to true, it will collect interest even if not passed thershold, but will not reward caller with gas refund + reward
	 */
	function collectInterest(
		address[] calldata _stakingContracts,
		bool _forceAndWaiverRewards
	) external {
		uint256 initialGas = gasleft();
		uint256 gdUBI;
		uint256 interestInCdai;
		address reserveAddress;
		{
			// require(
			// 	block.timestamp >= lastCollectedInterest + minCollectedInterestIntervalDays * days,
			// 	"collectInterest: collect interval not passed"
			// );
			//prevent stack too deep
			cERC20 iToken = cERC20(nameService.getAddress("CDAI"));
			ERC20 daiToken = ERC20(nameService.getAddress("DAI"));
			reserveAddress = nameService.getAddress("RESERVE");
			// DAI balance of the reserve contract
			uint256 currentBalance = daiToken.balanceOf(reserveAddress);
			uint256 startingCDAIBalance = iToken.balanceOf(reserveAddress);
			for (uint256 i = _stakingContracts.length - 1; i >= 0; i--) {
				// elements are sorted by balances from lowest to highest

				if (_stakingContracts[i] != address(0x0)) {
					IGoodStaking(_stakingContracts[i]).collectUBIInterest(reserveAddress);
				}

				if (i == 0) break; // when active contracts length is 1 then gives error
			}
			// Finds the actual transferred DAI
			uint256 daiToConvert = daiToken.balanceOf(reserveAddress) -
				currentBalance;

			// Mints gd while the interest amount is equal to the transferred amount
			(gdUBI, interestInCdai) = GoodReserveCDai(reserveAddress).mintUBI(
				daiToConvert,
				startingCDAIBalance,
				iToken
			);

			IGoodDollar token = IGoodDollar(nameService.getAddress("GOODDOLLAR"));
			if (gdUBI > 0) {
				//transfer ubi to avatar on sidechain via bridge
				require(
					token.transferAndCall(
						nameService.getAddress("BRIDGE_CONTRACT"),
						gdUBI,
						abi.encodePacked(nameService.getAddress("UBI_RECIPIENT"))
					),
					"ubi bridge transfer failed"
				);
			}
		}

		uint256 gdRewardToMint;

		if (_forceAndWaiverRewards == false) {
			uint256 totalUsedGas = ((initialGas - gasleft() + gdMintGasCost) * 110) /
				100; // We will return as reward 1.1x of used gas in GD
			gdRewardToMint = getGasPriceInGD(totalUsedGas);

			GoodReserveCDai(reserveAddress).mintRewardFromRR(
				nameService.getAddress("CDAI"),
				msg.sender,
				gdRewardToMint
			);

			uint256 gasPriceIncDAI = getGasPriceIncDAIorDAI(
				initialGas - gasleft(),
				false
			);

			if (
				block.timestamp >= lastCollectedInterest + collectInterestTimeThreshold
			) {
				require(
					interestInCdai >= gasPriceIncDAI,
					"Collected interest value should be larger than spent gas costs"
				); // This require is necessary to keeper can not abuse this function
			} else {
				require(
					interestInCdai >= interestMultiplier * gasPriceIncDAI,
					"Collected interest value should be interestMultiplier x gas costs"
				);
			}
		}
		emit FundsTransferred(
			msg.sender,
			reserveAddress,
			_stakingContracts,
			interestInCdai,
			gdUBI,
			gdRewardToMint
		);

		lastCollectedInterest = block.timestamp;
		lastCollectedInterestBlock = block.number;
	}

	/**
	 * @dev  Function that get interest informations of staking contracts in the sorted array by highest interest to lowest interest amount
	 * @return array of interestInfo struct
	 */
	function calcSortedContracts() public view returns (InterestInfo[] memory) {
		address[] memory addresses = new address[](activeContracts.length);
		uint256[] memory balances = new uint256[](activeContracts.length);
		InterestInfo[] memory interestInfos = new InterestInfo[](
			activeContracts.length
		);
		uint256 tempInterest;
		int256 i;
		for (i = 0; i < int256(activeContracts.length); i++) {
			(, , , , tempInterest) = IGoodStaking(activeContracts[uint256(i)])
				.currentGains(false, true);
			if (tempInterest != 0) {
				addresses[uint256(i)] = activeContracts[uint256(i)];
				balances[uint256(i)] = tempInterest;
			}
		}
		uint256 usedGasAmount = gasCostExceptInterestCollect;
		quick(balances, addresses); // sort the values according to interest balance
		uint256 gasCost;
		uint256 possibleCollected;
		uint256 maxGasAmount;
		for (i = int256(activeContracts.length) - 1; i >= 0; i--) {
			// elements are sorted by balances from lowest to highest

			if (addresses[uint256(i)] != address(0x0)) {
				gasCost = IGoodStaking(addresses[uint256(i)])
					.getGasCostForInterestTransfer();

				// collects the interest from the staking contract and transfer it directly to the reserve contract
				//`collectUBIInterest` returns (iTokengains, tokengains, precission loss, donation ratio)
				possibleCollected += balances[uint256(i)];
				usedGasAmount += gasCost;
				maxGasAmount = block.timestamp >=
					lastCollectedInterest + collectInterestTimeThreshold
					? (possibleCollected * 1e10) / getGasPriceIncDAIorDAI(1, true)
					: (possibleCollected * 1e10) /
						(interestMultiplier * getGasPriceIncDAIorDAI(1, true));
				interestInfos[uint256(i)] = InterestInfo({
					contractAddress: addresses[uint256(i)],
					interestBalance: balances[uint256(i)],
					collectedInterestSoFar: possibleCollected,
					gasCostSoFar: usedGasAmount,
					maxGasAmountSoFar: maxGasAmount,
					maxGasLargerOrEqualRequired: maxGasAmount >= usedGasAmount
				});
			} else {
				break; // if addresses are null after this element then break because we initialize array in size activecontracts but if their interest balance is zero then we dont put it in this array
			}
		}

		return interestInfos;
	}

	/**
	 * @dev Mint to users reward tokens which they earned by staking contract
	 * @param _token reserve token (currently can be just cDAI)
	 * @param _user user to get rewards
	 */
	function mintReward(address _token, address _user) public {
		Reward memory staking = rewardsForStakingContract[address(msg.sender)];
		require(staking.blockStart > 0, "Staking contract not registered");
		uint256 amount = IGoodStaking(address(msg.sender)).rewardsMinted(
			_user,
			staking.blockReward,
			staking.blockStart,
			staking.blockEnd
		);
		if (amount > 0 && staking.isBlackListed == false) {
			GoodReserveCDai(nameService.getAddress("RESERVE")).mintRewardFromRR(
				_token,
				_user,
				amount
			);

			emit StakingRewardMinted(msg.sender, _user, amount);
		}
	}

	/// quick sort
	function quick(uint256[] memory data, address[] memory addresses)
		internal
		pure
	{
		if (data.length > 1) {
			quickPart(data, addresses, 0, data.length - 1);
		}
	}

	/**
     @dev quicksort algorithm to sort array
     */
	function quickPart(
		uint256[] memory data,
		address[] memory addresses,
		uint256 low,
		uint256 high
	) internal pure {
		if (low < high) {
			uint256 pivotVal = data[(low + high) / 2];

			uint256 low1 = low;
			uint256 high1 = high;
			for (;;) {
				while (data[low1] < pivotVal) low1++;
				while (data[high1] > pivotVal) high1--;
				if (low1 >= high1) break;
				(data[low1], data[high1]) = (data[high1], data[low1]);
				(addresses[low1], addresses[high1]) = (
					addresses[high1],
					addresses[low1]
				);
				low1++;
				high1--;
			}
			if (low < high1) quickPart(data, addresses, low, high1);
			high1++;
			if (high1 < high) quickPart(data, addresses, high1, high);
		}
	}

	/**
     @dev Helper function to get gasPrice in GWEI then change it to cDAI/DAI
     @param _gasAmount gas amount to get its value
	 @param _inDAI indicates if result should return in DAI
     @return Price of the gas in DAI/cDAI
     */
	function getGasPriceIncDAIorDAI(uint256 _gasAmount, bool _inDAI)
		public
		view
		returns (uint256)
	{
		AggregatorV3Interface gasPriceOracle = AggregatorV3Interface(
			nameService.getAddress("GAS_PRICE_ORACLE")
		);
		int256 gasPrice = gasPriceOracle.latestAnswer(); // returns gas price in 0 decimal as GWEI so 1eth / 1e9 eth

		AggregatorV3Interface daiETHOracle = AggregatorV3Interface(
			nameService.getAddress("DAI_ETH_ORACLE")
		);
		int256 daiInETH = daiETHOracle.latestAnswer(); // returns DAI price in ETH

		uint256 result = ((uint256(gasPrice) * 1e18) / uint256(daiInETH)); // Gasprice in GWEI and daiInETH is 18 decimals so we multiply gasprice with 1e18 in order to get result in 18 decimals
		if (_inDAI) return result * _gasAmount;
		result =
			(((result / 1e10) * 1e28) /
				cERC20(nameService.getAddress("CDAI")).exchangeRateStored()) *
			_gasAmount; // based on https://compound.finance/docs#protocol-math
		return result;
	}

	/**
     @dev Helper function to get gasPrice in G$, used to calculate the rewards for collectInterest KEEPER
     @param _gasAmount gas amount to get its value
     @return Price of the gas in G$
     */
	function getGasPriceInGD(uint256 _gasAmount) public view returns (uint256) {
		uint256 priceInCdai = getGasPriceIncDAIorDAI(_gasAmount, false);
		uint256 gdPriceIncDAI = GoodReserveCDai(nameService.getAddress("RESERVE"))
			.currentPrice();
		return ((priceInCdai * 1e27) / gdPriceIncDAI) / 1e25; // rdiv returns result in 27 decimals since GD$ in 2 decimals then divide 1e25
	}

	function getActiveContractsCount() public view returns (uint256) {
		return activeContracts.length;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "../Interfaces.sol";
import "openzeppelin-solidity/contracts/utils/math/Math.sol";
import "../utils/DSMath.sol";

contract BaseShareField is DSMath {
	// total staked for shares calculation
	uint256 public totalProductivity;
	// total staked that earns rewards (some stakers can donate their rewards)
	uint256 public totalEffectiveStakes;
	// accumulated rewards per share in 27 decimals precision
	uint256 public accAmountPerShare;
	// rewards claimed by users
	uint256 public mintedRewards;
	// rewards accumulated for distribution
	uint256 public accumulatedRewards;
	// number of blocks before reaching the max rewards multiplier (starting at 0.5 reaching 1 after maxMultiplierThreshold)
	uint64 public maxMultiplierThreshold;
	// block of last rewards accumulation
	uint256 public lastRewardBlock;
	// Staking contracts accepts Tokens with max 18 decimals so this variable holds decimal difference between 18 and Token's decimal in order to make calculations
	uint8 public tokenDecimalDifference;

	//status of user rewards. everything is in 18 decimals
	struct UserInfo {
		uint256 amount; // How many tokens the user has provided.
		uint256 effectiveStakes; // stakes not including stakes that donate their rewards
		uint256 rewardDebt; // Reward debt.
		uint256 rewardEarn; // Reward earn and not minted
		uint256 rewardMinted; //Rewards minted to user so far
		uint64 lastRewardTime; // Last time that user got rewards
		uint64 multiplierResetTime; // Reset time of multiplier
	}
	mapping(address => UserInfo) public users;

	/**
	 * @dev Helper function to check if caller is fund manager
	 */
	function _canMintRewards() internal view virtual {}

	/**
	 * @dev Update reward variables of the given pool to be up-to-date.
	 * Calculates passed blocks and adding to the reward pool
	 * @param rewardsPerBlock how much rewards does this contract earns per block
	 * @param blockStart block from which contract starts earning rewards
	 * @param blockEnd block from which contract stops earning rewards
	 */
	function _update(
		uint256 rewardsPerBlock,
		uint256 blockStart,
		uint256 blockEnd
	) internal virtual {
		if (totalEffectiveStakes == 0) {
			lastRewardBlock = block.number;
			return;
		}
		if (block.number >= blockStart && lastRewardBlock < blockStart) {
			lastRewardBlock = blockStart;
		}

		uint256 _lastRewardBlock = lastRewardBlock < blockStart &&
			block.number >= blockStart
			? blockStart
			: lastRewardBlock;
		uint256 curRewardBlock = block.number > blockEnd ? blockEnd : block.number;
		if (curRewardBlock < blockStart || _lastRewardBlock >= blockEnd) return;

		uint256 multiplier = curRewardBlock - _lastRewardBlock; // Blocks passed since last reward block
		uint256 reward = multiplier * (rewardsPerBlock * 1e16); // rewardsPerBlock is in G$ which is only 2 decimals, we turn it into 18 decimals by multiplying 1e16

		accAmountPerShare =
			accAmountPerShare +
			(reward * 1e27) /
			(totalEffectiveStakes * (10**tokenDecimalDifference)); // Increase totalEffectiveStakes decimals if it is less than 18 decimals then accAmountPerShare in 27 decimals

		lastRewardBlock = curRewardBlock;
	}

	/**
	 * @dev Audit user's rewards and calculate their earned rewards
	 * For the first month rewards calculated with 0.5x
	 * multiplier therefore they just gets half of the rewards which they earned in the first month
	 * after first month they get full amount of rewards for the part that they earned after one month
	 * @param user the user to audit
	 * @param updatedAmount the new stake of the user after deposit/withdraw
	 * @param donationPer percentage user is donating from his rewards. (currently just 0 or 100 in SimpleStaking)
	 */
	function _audit(
		address user,
		uint256 updatedAmount,
		uint256 donationPer
	) internal virtual {
		UserInfo storage userInfo = users[user];
		uint256 _amount = userInfo.amount;
		uint256 userEffectiveStake = userInfo.effectiveStakes;
		if (userEffectiveStake > 0) {
			(
				uint256 blocksToPay,
				uint256 firstMonthBlocksToPay,
				uint256 fullBlocksToPay
			) = _auditCalcs(userInfo);

			if (blocksToPay != 0) {
				uint256 pending = (userEffectiveStake *
					(10**tokenDecimalDifference) *
					accAmountPerShare) /
					1e27 -
					userInfo.rewardDebt; // Turn userInfo.amount to 18 decimals by multiplying tokenDecimalDifference if it's not and multiply with accAmountPerShare which is 27 decimals then divide it 1e27 bring it down to 18 decimals
				uint256 rewardPerBlock = (pending * 1e27) / (blocksToPay * 1e18); // bring both variable to 18 decimals and multiply pending by 1e27 so when we divide them to each other result would be in 1e27
				pending =
					((((firstMonthBlocksToPay * 1e2 * 5) / 10) + fullBlocksToPay * 1e2) * // multiply first month by 0.5x (5/10) since rewards in first month with multiplier 0.5 and multiply it with 1e2 to get it 2decimals so we could get more precision
						rewardPerBlock) / // Multiply fullBlocksToPay with 1e2 to bring it to 2 decimals // rewardPerBlock is in 27decimals
					1e11; // Pending in 18 decimals so we divide 1e11 to bring it down to 18 decimals
				userInfo.rewardEarn = userInfo.rewardEarn + pending; // Add user's earned rewards to user's account so it can be minted later
				accumulatedRewards = accumulatedRewards + pending;
			}
		} else {
			userInfo.multiplierResetTime = uint64(block.number); // Should set user's multiplierResetTime when they stake for the first time
		}

		//if withdrawing rewards/stake we reset multiplier, only in case of increasinig productivity we dont reset multiplier
		if (updatedAmount <= _amount) {
			userInfo.multiplierResetTime = uint64(block.number);
			if (_amount > 0) {
				uint256 withdrawFromEffectiveStake = ((_amount - updatedAmount) *
					userInfo.effectiveStakes) / _amount;
				userInfo.effectiveStakes -= withdrawFromEffectiveStake;
				totalEffectiveStakes -= withdrawFromEffectiveStake;
			}
		} else if (donationPer == 0) {
			userInfo.effectiveStakes += (updatedAmount - _amount);
			totalEffectiveStakes += (updatedAmount - _amount);
		}
		userInfo.lastRewardTime = uint64(block.number);
		userInfo.amount = updatedAmount;
		userInfo.rewardDebt =
			(userInfo.effectiveStakes *
				(10**tokenDecimalDifference) *
				accAmountPerShare) /
			1e27; // Divide to 1e27 to keep rewardDebt in 18 decimals since accAmountPerShare is 27 decimals
	}

	/**
	 * @dev Helper function to make calculations in audit and getUserPendingReward methods
	 */
	function _auditCalcs(UserInfo memory _userInfo)
		internal
		view
		returns (
			uint256,
			uint256,
			uint256
		)
	{
		uint256 blocksPaid = _userInfo.lastRewardTime -
			_userInfo.multiplierResetTime; // lastRewardTime is always >= multiplierResetTime
		uint256 blocksPassedFirstMonth = Math.min(
			maxMultiplierThreshold,
			block.number - _userInfo.multiplierResetTime
		); // blocks which is after first month
		uint256 blocksToPay = block.number - _userInfo.lastRewardTime; // blocks passed since last payment
		uint256 firstMonthBlocksToPay = blocksPaid >= maxMultiplierThreshold
			? 0
			: blocksPassedFirstMonth - blocksPaid; // block which is in the first month so pays with 0.5x multiplier
		uint256 fullBlocksToPay = blocksToPay - firstMonthBlocksToPay; // blocks to pay in full amount which means with 1x multiplier
		return (blocksToPay, firstMonthBlocksToPay, fullBlocksToPay);
	}

	/**
	 * @dev This function increase user's productivity and updates the global productivity.
	 * This function increase user's productivity and updates the global productivity.
	 * the users' actual share percentage will calculated by:
	 * Formula:     user_productivity / global_productivity
	 * @param user the user to update
	 * @param value the increase in user stake
	 * @param rewardsPerBlock how much rewards does this contract earns per block
	 * @param blockStart block from which contract starts earning rewards
	 * @param blockEnd block from which contract stops earning rewards
	 * @param donationPer percentage user is donating from his rewards. (currently just 0 or 100 in SimpleStaking)
	 */
	function _increaseProductivity(
		address user,
		uint256 value,
		uint256 rewardsPerBlock,
		uint256 blockStart,
		uint256 blockEnd,
		uint256 donationPer
	) internal virtual returns (bool) {
		_update(rewardsPerBlock, blockStart, blockEnd);
		_audit(user, users[user].amount + value, donationPer);

		totalProductivity = totalProductivity + value;
		return true;
	}

	/**
	 * @dev This function will decreases user's productivity by value, and updates the global productivity
	 * it will record which block this is happenning and accumulates the area of (productivity * time)
	 * @param user the user to update
	 * @param value the increase in user stake
	 * @param rewardsPerBlock how much rewards does this contract earns per block
	 * @param blockStart block from which contract starts earning rewards
	 * @param blockEnd block from which contract stops earning rewards
	 */

	function _decreaseProductivity(
		address user,
		uint256 value,
		uint256 rewardsPerBlock,
		uint256 blockStart,
		uint256 blockEnd
	) internal virtual returns (bool) {
		_update(rewardsPerBlock, blockStart, blockEnd);
		_audit(user, users[user].amount - value, 1); // donationPer variable should be something different than zero so called with 1
		totalProductivity = totalProductivity - value;

		return true;
	}

	/**
	 * @dev Query user's pending reward with updated variables
	 * @param user the user to update
	 * @param rewardsPerBlock how much rewards does this contract earns per block
	 * @param blockStart block from which contract starts earning rewards
	 * @param blockEnd block from which contract stops earning rewards
	 * @return returns  amount of user's earned but not minted rewards
	 */
	function getUserPendingReward(
		address user,
		uint256 rewardsPerBlock,
		uint256 blockStart,
		uint256 blockEnd
	) public view returns (uint256) {
		UserInfo memory userInfo = users[user];
		uint256 _accAmountPerShare = accAmountPerShare;

		uint256 pending = 0;
		if (
			totalEffectiveStakes != 0 &&
			block.number >= blockStart &&
			blockEnd >= block.number
		) {
			uint256 multiplier = block.number - lastRewardBlock;
			uint256 reward = multiplier * (rewardsPerBlock * 1e16); // turn it to 18 decimals since rewardsPerBlock in 2 decimals
			(
				uint256 blocksToPay,
				uint256 firstMonthBlocksToPay,
				uint256 fullBlocksToPay
			) = _auditCalcs(userInfo);

			_accAmountPerShare =
				_accAmountPerShare +
				(reward * 1e27) /
				(totalEffectiveStakes * 10**tokenDecimalDifference); // Increase totalEffectiveStakes decimals if it is less than 18 decimals then accAmountPerShare in 27 decimals
			UserInfo memory tempUserInfo = userInfo; // to prevent stack too deep error any other recommendation?
			if (blocksToPay != 0) {
				pending =
					(tempUserInfo.effectiveStakes *
						(10**tokenDecimalDifference) *
						_accAmountPerShare) /
					1e27 -
					tempUserInfo.rewardDebt; // Turn userInfo.amount to 18 decimals by multiplying tokenDecimalDifference if it's not and multiply with accAmountPerShare which is 27 decimals then divide it 1e27 bring it down to 18 decimals
				uint256 rewardPerBlock = (pending * 1e27) / (blocksToPay * 1e18); // bring both variable to 18 decimals and multiply pending by 1e27 so when we divide them to each other result would be in 1e27
				pending =
					((((firstMonthBlocksToPay * 1e2 * 5) / 10) + fullBlocksToPay * 1e2) * // multiply first month by 0.5x (5/10) since rewards in first month with multiplier 0.5 and multiply it with 1e2 to get it 2decimals so we could get more precision
						rewardPerBlock) / // Multiply fullBlocksToPay with 1e2 to bring it to 2decimals // rewardPerBlock is in 27decimals
					1e11; // Pending in 18 decimals so we divide 1e11 to bring it down to 18 decimals
			}
		}
		return userInfo.rewardEarn + pending; // rewardEarn is in 18 decimals
	}

	/**
	 * @dev When the fundmanager calls this function it will updates the user records
	 * get the user rewards which they earned but not minted and mark it as minted
	 * @param user the user to update
	 * @param rewardsPerBlock how much rewards does this contract earns per block
	 * @param blockStart block from which contract starts earning rewards
	 * @param blockEnd block from which contract stops earning rewards
	 * @return returns amount to mint as reward to the user
	 */

	function rewardsMinted(
		address user,
		uint256 rewardsPerBlock,
		uint256 blockStart,
		uint256 blockEnd
	) public returns (uint256) {
		UserInfo storage userInfo = users[user];
		_canMintRewards();
		_update(rewardsPerBlock, blockStart, blockEnd);
		_audit(user, userInfo.amount, 1); // donationPer variable should be something different than zero so called with 1
		uint256 amount = userInfo.rewardEarn;
		userInfo.rewardEarn = 0;
		userInfo.rewardMinted += amount;
		mintedRewards = mintedRewards + amount;
		amount = amount / 1e16; // change decimal of mint amount to GD decimals
		return amount;
	}

	/**
	 * @return Returns how many productivity a user has and global has.
	 */

	function getProductivity(address user)
		public
		view
		virtual
		returns (uint256, uint256)
	{
		return (users[user].amount, totalProductivity);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../utils/DAOContract.sol";
import "../utils/NameService.sol";
import "../Interfaces.sol";
import "../governance/GReputation.sol";
import "../governance/MultiBaseGovernanceShareField.sol";
import "../staking/GoodFundManager.sol";
import "../staking/SimpleStaking.sol";

/**
 * Staking contracts will update this contract with staker token stake amount
 * This contract will be able to mint GDAO. 2M GDAO that will be allocated between staking contracts each month pro-rate based on $ value staked.
 * Each staker will receive his share pro rata per staking contract he participates in
 * NOTICE: a contract will start earning GDAO rewards only after first month
 */
contract StakersDistribution is
	DAOUpgradeableContract,
	MultiBaseGovernanceShareField
{
	///@notice reputation to distribute each month, will effect next month when set
	uint256 public monthlyReputationDistribution;

	///@notice month number since epoch
	uint256 public currentMonth;

	event ReputationEarned(
		address staker,
		address[] stakingContracts,
		uint256 reputation
	);

	function initialize(INameService _ns) public initializer {
		monthlyReputationDistribution = 2000000 ether; //2M as specified in specs
		setDAO(_ns);
		_updateMonth();
	}

	/**
	 * @dev this contract runs on ethereum
	 */
	function getChainBlocksPerMonth() public pure override returns (uint256) {
		return 172800; //4 * 60 * 24 * 30
	}

	/**
	 * @dev update the monthly reputation distribution. only avatar can do that.
	 * @param newMonthlyReputationDistribution the new reputation amount to distribute
	 */
	function setMonthlyReputationDistribution(
		uint256 newMonthlyReputationDistribution
	) external {
		_onlyAvatar();
		monthlyReputationDistribution = newMonthlyReputationDistribution;
	}

	/**
	 * @dev internal function to switch to new month. records for new month the current monthlyReputationDistribution
	 */
	function _updateMonth() internal {
		uint256 month = block.timestamp / 30 days;
		if (
			nameService.getAddress("FUND_MANAGER") != address(0) &&
			month != currentMonth
		) {
			//read active staking contracts set pro rate monthly share
			GoodFundManager gfm = GoodFundManager(
				nameService.getAddress("FUND_MANAGER")
			);

			uint256 activeContractsCount = gfm.getActiveContractsCount();
			address payable[] memory activeStakingList = new address payable[](
				activeContractsCount
			);
			uint256[] memory contractLockedValue = new uint256[](
				activeContractsCount
			);

			uint256 totalLockedValue;
			for (uint256 i = 0; i < activeContractsCount; i++) {
				activeStakingList[i] = payable(gfm.activeContracts(i));
				(, uint64 blockStart, uint64 blockEnd, ) = gfm
					.rewardsForStakingContract(activeStakingList[i]);
				if (blockStart <= block.number && blockEnd > block.number) {
					(, , , uint256 lockedValueInUSD, ) = SimpleStaking(
						activeStakingList[i]
					).currentGains(true, false);
					contractLockedValue[i] = lockedValueInUSD;
					totalLockedValue += contractLockedValue[i];
				}
			}

			//set each contract relative monthly rewards
			for (uint256 i = 0; i < activeContractsCount; i++) {
				uint256 contractShare = totalLockedValue > 0
					? (monthlyReputationDistribution * contractLockedValue[i]) /
						totalLockedValue
					: monthlyReputationDistribution / activeContractsCount;
				if (contractLockedValue[i] > 0) {
					_setMonthlyRewards(activeStakingList[i], contractShare);
				}
			}

			//update new month
			currentMonth = month;
		}
	}

	/**
	 * @dev staking contract can call this to increase user current contribution
	 * @param _staker the user to update
	 * @param _value the value to increase by
	 */
	function userStaked(address _staker, uint256 _value) external {
		address stakingContract = msg.sender;
		(
			,
			uint64 blockStart,
			uint64 blockEnd,
			bool isBlackListed
		) = GoodFundManager(nameService.getAddress("FUND_MANAGER"))
				.rewardsForStakingContract(stakingContract);

		if (isBlackListed) return; //dont do anything if staking contract has been blacklisted;

		_increaseProductivity(
			stakingContract,
			_staker,
			_value,
			blockStart,
			blockEnd
		);

		address[] memory contracts = new address[](1);
		contracts[0] = stakingContract;

		_claimReputation(_staker, contracts);

		_updateMonth(); //previous calls will use previous month reputation
	}

	/**
	 * @dev staking contract can call this to decrease user current contribution
	 * @param _staker the user to update
	 * @param _value the value to decrease by
	 */
	function userWithdraw(address _staker, uint256 _value) external {
		address stakingContract = msg.sender;
		(
			,
			uint64 blockStart,
			uint64 blockEnd,
			bool isBlackListed
		) = GoodFundManager(nameService.getAddress("FUND_MANAGER"))
				.rewardsForStakingContract(stakingContract);

		if (isBlackListed) return; //dont do anything if staking contract has been blacklisted;

		_decreaseProductivity(
			stakingContract,
			_staker,
			_value,
			blockStart,
			blockEnd
		);

		address[] memory contracts = new address[](1);
		contracts[0] = stakingContract;
		_claimReputation(_staker, contracts);
		_updateMonth(); //previous calls will use previous month reputation
	}

	/**
	 * @dev mints reputation to user according to his share in the different staking contracts
	 * @param _staker the user to distribute reputation to
	 * @param _stakingContracts the user to distribute reputation to
	 */
	function claimReputation(
		address _staker,
		address[] calldata _stakingContracts
	) external {
		_claimReputation(_staker, _stakingContracts);
		_updateMonth(); //previous calls will use previous month reputation
	}

	function _claimReputation(
		address _staker,
		address[] memory _stakingContracts
	) internal {
		uint256 totalRep;
		GoodFundManager gfm = GoodFundManager(
			nameService.getAddress("FUND_MANAGER")
		);

		for (uint256 i = 0; i < _stakingContracts.length; i++) {
			(, uint64 blockStart, uint64 blockEnd, bool isBlackListed) = gfm
				.rewardsForStakingContract(_stakingContracts[i]);

			if (isBlackListed == false)
				totalRep += _issueEarnedRewards(
					_stakingContracts[i],
					_staker,
					blockStart,
					blockEnd
				);
		}
		if (totalRep > 0) {
			GReputation(nameService.getAddress("REPUTATION")).mint(
				_staker,
				totalRep
			);
			emit ReputationEarned(_staker, _stakingContracts, totalRep);
		}
	}

	/**
	 * @dev get user reputation rewards accrued in goodstaking contracts
	 * @param _contracts list of contracts to check for rewards
	 * @param _user the user to check rewards for
	 * @return reputation rewards pending for user
	 */
	function getUserPendingRewards(address[] memory _contracts, address _user)
		public
		view
		returns (uint256)
	{
		uint256 pending;
		for (uint256 i = 0; i < _contracts.length; i++) {
			(
				,
				uint64 blockStart,
				uint64 blockEnd,
				bool isBlackListed
			) = GoodFundManager(nameService.getAddress("FUND_MANAGER"))
					.rewardsForStakingContract(_contracts[i]);

			if (isBlackListed == false) {
				pending += getUserPendingReward(
					_contracts[i],
					blockStart,
					blockEnd,
					_user
				);
			}
		}

		return pending;
	}

	/**
	 * @param _contracts staking contracts to sum _user minted and pending
	 * @param _user account to get rewards status for
	 * @return (minted, pending) in GDAO 18 decimals
	 */
	function getUserMintedAndPending(address[] memory _contracts, address _user)
		public
		view
		returns (uint256, uint256)
	{
		uint256 pending = getUserPendingRewards(_contracts, _user);
		uint256 minted;
		for (uint256 i = 0; i < _contracts.length; i++) {
			minted += contractToUsers[_contracts[i]][_user].rewardMinted;
		}
		return (minted, pending);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../utils/DAOUpgradeableContract.sol";
import "../utils/NameService.sol";
import "../DAOStackInterfaces.sol";
import "../Interfaces.sol";
import "./GoodMarketMaker.sol";

interface ContributionCalc {
	function calculateContribution(
		GoodMarketMaker _marketMaker,
		GoodReserveCDai _reserve,
		address _contributer,
		ERC20 _token,
		uint256 _gdAmount
	) external view returns (uint256);

	function setContributionRatio(uint256 _nom, uint256 _denom) external;
}

/**
@title Reserve based on cDAI and dynamic reserve ratio market maker
*/
contract GoodReserveCDai is
	DAOUpgradeableContract,
	ERC20PresetMinterPauserUpgradeable,
	GlobalConstraintInterface
{
	bytes32 public constant RESERVE_MINTER_ROLE =
		keccak256("RESERVE_MINTER_ROLE");

	/// @dev G$ minting cap;
	uint256 public cap;

	// The last block number which
	// `mintUBI` has been executed in
	uint256 public lastMinted;

	address public daiAddress;
	address public cDaiAddress;

	/// @dev merkleroot for GDX airdrop
	bytes32 public gdxAirdrop;

	/// @dev mark if user claimed his GDX
	mapping(address => bool) public isClaimedGDX;

	// Emits when new GD tokens minted
	event UBIMinted(
		//epoch of UBI
		uint256 indexed day,
		//the token paid as interest
		address indexed interestToken,
		//wei amount of interest paid in interestToken
		uint256 interestReceived,
		// Amount of GD tokens that was
		// added to the supply as a result
		// of `mintInterest`
		uint256 gdInterestMinted,
		// Amount of GD tokens that was
		// added to the supply as a result
		// of `mintExpansion`
		uint256 gdExpansionMinted,
		// Amount of GD tokens that was
		// minted to the `ubiCollector`
		uint256 gdUbiTransferred
	);

	// Emits when GD tokens are purchased
	event TokenPurchased(
		// The initiate of the action
		address indexed caller,
		// The convertible token address
		// which the GD tokens were
		// purchased with
		address indexed inputToken,
		// Reserve tokens amount
		uint256 inputAmount,
		// Actual return after the
		// conversion
		uint256 actualReturn,
		// Address of the receiver of tokens
		address indexed receiverAddress
	);
	// Emits when GD tokens are sold
	event TokenSold(
		// The initiate of the action
		address indexed caller,
		// The convertible token address
		// which the GD tokens were
		// sold to
		address indexed outputToken,
		// GD tokens amount
		uint256 gdAmount,
		// The amount of GD tokens that
		// was contributed during the
		// conversion
		uint256 contributionAmount,
		// Actual return after the
		// conversion
		uint256 actualReturn,
		// Address of the receiver of tokens
		address indexed receiverAddress
	);

	function initialize(INameService _ns, bytes32 _gdxAirdrop)
		public
		virtual
		initializer
	{
		__ERC20PresetMinterPauser_init("GDX", "G$X");
		setDAO(_ns);

		//fixed cdai/dai
		setAddresses();

		//gdx roles
		renounceRole(MINTER_ROLE, _msgSender());
		renounceRole(PAUSER_ROLE, _msgSender());
		renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(DEFAULT_ADMIN_ROLE, address(avatar));

		//mint access through reserve
		_setupRole(RESERVE_MINTER_ROLE, address(avatar)); //only Avatar can manage minters

		cap = 22 * 1e14; //22 trillion G$ cents

		gdxAirdrop = _gdxAirdrop;
	}

	/// @dev GDX decimals
	function decimals() public pure override returns (uint8) {
		return 2;
	}

	function setAddresses() public {
		daiAddress = nameService.getAddress("DAI");
		cDaiAddress = nameService.getAddress("CDAI");
		// Approve transfer to cDAI contract
		ERC20(daiAddress).approve(cDaiAddress, type(uint256).max);
	}

	/**
	 * @dev get current MarketMaker from name service
	 * The address of the market maker contract
	 * which makes the calculations and holds
	 * the token and accounts info (should be owned by the reserve)
	 */
	function getMarketMaker() public view returns (GoodMarketMaker) {
		return GoodMarketMaker(nameService.getAddress("MARKET_MAKER"));
	}

	/**
	 * @dev Converts cDai tokens to GD tokens and updates the bonding curve params.
	 * `buy` occurs only if the GD return is above the given minimum. It is possible
	 * to buy only with cDAI and when the contract is set to active. MUST call to
	 * cDAI `approve` prior this action to allow this contract to accomplish the
	 * conversion.
	 * @param _tokenAmount The amount of cDAI tokens that should be converted to GD tokens
	 * @param _minReturn The minimum allowed return in GD tokens
	 * @param _targetAddress address of g$ and gdx recipient if different than msg.sender
	 * @return (gdReturn) How much GD tokens were transferred
	 */
	function buy(
		uint256 _tokenAmount,
		uint256 _minReturn,
		address _targetAddress
	) external returns (uint256) {
		ERC20 buyWith = ERC20(cDaiAddress);
		uint256 gdReturn = getMarketMaker().buy(buyWith, _tokenAmount);
		_targetAddress = _targetAddress == address(0x0)
			? msg.sender
			: _targetAddress;
		address exchangeHelper = nameService.getAddress("EXCHANGE_HELPER");
		if (msg.sender != exchangeHelper)
			require(
				buyWith.transferFrom(msg.sender, address(this), _tokenAmount) ==
					true,
				"transferFrom failed, make sure you approved input token transfer"
			);
		require(
			gdReturn >= _minReturn,
			"GD return must be above the minReturn"
		);
		_mintGoodDollars(_targetAddress, gdReturn, true);
		//mint GDX
		_mintGDX(_targetAddress, gdReturn);
		if (msg.sender != exchangeHelper)
			emit TokenPurchased(
				msg.sender,
				cDaiAddress,
				_tokenAmount,
				gdReturn,
				_targetAddress
			);
		return gdReturn;
	}

	/**
	 * @dev Mint rewards for staking contracts in G$ and update RR
	 * requires minting permissions which is enforced by _mintGoodDollars
	 * @param _to Receipent address for rewards
	 * @param _amount G$ amount to mint for rewards
	 */
	function mintRewardFromRR(
		address _token,
		address _to,
		uint256 _amount
	) public {
		getMarketMaker().mintFromReserveRatio(ERC20(_token), _amount);
		_mintGoodDollars(_to, _amount, false);
		//mint GDX
		_mintGDX(_to, _amount);
	}

	/**
	 * @dev sell helper function burns GD tokens and update the bonding curve params.
	 * `sell` occurs only if the token return is above the given minimum. Notice that
	 * there is a contribution amount from the given GD that remains in the reserve.
	 * @param _gdAmount The amount of GD tokens that should be converted to cDAI tokens
	 * @param _minReturn The minimum allowed `sellTo` tokens return
	 * @param _target address of the receiver of cDAI when sell G$
	 * @param _seller address of the seller when using helper contract
	 * @return (tokenReturn, contribution) (cDAI received, G$ exit contribution)
	 */
	function sell(
		uint256 _gdAmount,
		uint256 _minReturn,
		address _target,
		address _seller
	) external returns (uint256, uint256) {
		GoodMarketMaker mm = getMarketMaker();
		if (msg.sender != nameService.getAddress("EXCHANGE_HELPER")) {
			IGoodDollar(nameService.getAddress("GOODDOLLAR")).burnFrom(
				msg.sender,
				_gdAmount
			);
			_seller = msg.sender;
		}
		_target = _target == address(0x0) ? msg.sender : _target;
		//discount on exit contribution based on gdx
		uint256 gdx = balanceOf(_seller);
		uint256 discount = gdx <= _gdAmount ? gdx : _gdAmount;

		//burn gdx used for discount
		_burn(_seller, discount);

		uint256 contributionAmount = 0;
		uint256 gdAmountTemp = _gdAmount; // to prevent stack too deep errors
		if (discount < gdAmountTemp)
			contributionAmount = ContributionCalc(
				nameService.getAddress("CONTRIBUTION_CALCULATION")
			).calculateContribution(
				mm,
				this,
				_seller,
				ERC20(cDaiAddress),
				gdAmountTemp - discount
			);

		uint256 tokenReturn = mm.sellWithContribution(
			ERC20(cDaiAddress),
			gdAmountTemp,
			contributionAmount
		);
		require(
			tokenReturn >= _minReturn,
			"Token return must be above the minReturn"
		);
		cERC20(cDaiAddress).transfer(_target, tokenReturn);
		if (_seller == msg.sender)
			emit TokenSold(
				msg.sender,
				cDaiAddress,
				_gdAmount,
				contributionAmount,
				tokenReturn,
				_target
			);
		return (tokenReturn, contributionAmount);
	}

	function currentPrice() public view returns (uint256) {
		return getMarketMaker().currentPrice(ERC20(cDaiAddress));
	}

	function currentPriceDAI() public view returns (uint256) {
		cERC20 cDai = cERC20(cDaiAddress);

		return (((currentPrice() * 1e10) * cDai.exchangeRateStored()) / 1e28); // based on https://compound.finance/docs#protocol-math
	}

	/**
	 * @dev helper to mint G$s
	 * @param _to the recipient of newly minted G$s
	 * @param _gdToMint how much G$ to mint
	 * @param _internalCall skip minting role validation for internal calls, used when "buying G$" to "allow" buyer to mint G$ in exchange for his cDAI
	 */
	function _mintGoodDollars(
		address _to,
		uint256 _gdToMint,
		bool _internalCall
	) internal {
		//enforce minting rules
		require(
			_internalCall ||
				_msgSender() == nameService.getAddress("FUND_MANAGER") ||
				hasRole(RESERVE_MINTER_ROLE, _msgSender()),
			"GoodReserve: not a minter"
		);

		require(
			IGoodDollar(nameService.getAddress("GOODDOLLAR")).totalSupply() +
				_gdToMint <=
				cap,
			"GoodReserve: cap enforced"
		);

		IGoodDollar(nameService.getAddress("GOODDOLLAR")).mint(_to, _gdToMint);
	}

	/// @dev helper to mint GDX to make _mint more verbose
	function _mintGDX(address _to, uint256 _gdx) internal {
		_mint(_to, _gdx);
	}

	/**
	 * @dev only FundManager or other with mint G$ permission can call this to trigger minting.
	 * Reserve sends UBI + interest to FundManager.
	 * @param _daiToConvert DAI amount to convert cDAI
	 * @param _startingCDAIBalance Initial cDAI balance before staking collect process start
	 * @param _interestToken The token that was transfered to the reserve
	 * @return gdUBI,interestInCdai how much GD UBI was minted and how much cDAI collected from staking contracts
	 */
	function mintUBI(
		uint256 _daiToConvert,
		uint256 _startingCDAIBalance,
		ERC20 _interestToken
	) public returns (uint256, uint256) {
		cERC20(cDaiAddress).mint(_daiToConvert);
		uint256 interestInCdai = _interestToken.balanceOf(address(this)) -
			_startingCDAIBalance;
		uint256 gdInterestToMint = getMarketMaker().mintInterest(
			_interestToken,
			interestInCdai
		);
		uint256 gdExpansionToMint = getMarketMaker().mintExpansion(
			_interestToken
		);
		uint256 gdUBI = gdInterestToMint + gdExpansionToMint;
		//this enforces who can call the public mintUBI method. only an address with permissions at reserve of  RESERVE_MINTER_ROLE
		_mintGoodDollars(nameService.getAddress("FUND_MANAGER"), gdUBI, false);
		lastMinted = block.number;
		emit UBIMinted(
			lastMinted,
			address(_interestToken),
			interestInCdai,
			gdInterestToMint,
			gdExpansionToMint,
			gdUBI
		);
		return (gdUBI, interestInCdai);
	}

	/**
	 * @dev Allows the DAO to change the daily expansion rate
	 * it is calculated by _nom/_denom with e27 precision. Emits
	 * `ReserveRatioUpdated` event after the ratio has changed.
	 * Only Avatar can call this method.
	 * @param _nom The numerator to calculate the global `reserveRatioDailyExpansion` from
	 * @param _denom The denominator to calculate the global `reserveRatioDailyExpansion` from
	 */
	function setReserveRatioDailyExpansion(uint256 _nom, uint256 _denom)
		public
	{
		_onlyAvatar();
		getMarketMaker().setReserveRatioDailyExpansion(_nom, _denom);
	}

	/**
	 * @dev Remove minting rights after it has transferred the cDAI funds to `_avatar`
	 * Only the Avatar can execute this method
	 */
	function end() public {
		_onlyAvatar();
		// remaining cDAI tokens in the current reserve contract
		recover(ERC20(cDaiAddress));

		//restore minting to avatar, so he can re-delegate it
		IGoodDollar gd = IGoodDollar(nameService.getAddress("GOODDOLLAR"));
		if (gd.isMinter(address(avatar)) == false)
			gd.addMinter(address(avatar));

		IGoodDollar(nameService.getAddress("GOODDOLLAR")).renounceMinter();
	}

	/**
	 * @dev method to recover any stuck erc20 tokens (ie compound COMP)
	 * @param _token the ERC20 token to recover
	 */
	function recover(ERC20 _token) public {
		_onlyAvatar();
		require(
			_token.transfer(address(avatar), _token.balanceOf(address(this))),
			"recover transfer failed"
		);
	}

	/**
	 * @notice prove user balance in a specific blockchain state hash
	 * @dev "rootState" is a special state that can be supplied once, and actually mints reputation on the current blockchain
	 * @param _user the user to prove his balance
	 * @param _gdx the balance we are prooving
	 * @param _proof array of byte32 with proof data (currently merkle tree path)
	 * @return true if proof is valid
	 */
	function claimGDX(
		address _user,
		uint256 _gdx,
		bytes32[] memory _proof
	) public returns (bool) {
		require(isClaimedGDX[_user] == false, "already claimed gdx");
		bytes32 leafHash = keccak256(abi.encode(_user, _gdx));
		bool isProofValid = MerkleProofUpgradeable.verify(
			_proof,
			gdxAirdrop,
			leafHash
		);

		require(isProofValid, "invalid merkle proof");

		_mintGDX(_user, _gdx);

		isClaimedGDX[_user] = true;
		return true;
	}

	// implement minting constraints through the GlobalConstraintInterface interface. prevent any minting not through reserve
	function pre(
		address _scheme,
		bytes32 _hash,
		bytes32 _method
	) public pure override returns (bool) {
		_scheme;
		_hash;
		_method;
		if (_method == "mintTokens") return false;

		return true;
	}

	function when() public pure override returns (CallPhase) {
		return CallPhase.Pre;
	}
}

// SPDX-License-Identifier: MIT

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

contract DSMath {
	function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = (x * y) / 10**27;
	}

	function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = (x * (10**27)) / y;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./DAOContract.sol";

/**
@title Simple contract that adds upgradability to DAOContract
*/

contract DAOUpgradeableContract is Initializable, UUPSUpgradeable, DAOContract {
	function _authorizeUpgrade(address) internal virtual override {
		_onlyAvatar();
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../extensions/ERC20BurnableUpgradeable.sol";
import "../extensions/ERC20PausableUpgradeable.sol";
import "../../../access/AccessControlEnumerableUpgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauserUpgradeable is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable {
    function initialize(string memory name, string memory symbol) public virtual initializer {
        __ERC20PresetMinterPauser_init(name, symbol);
    }
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    function __ERC20PresetMinterPauser_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        __ERC20PresetMinterPauser_init_unchained(name, symbol);
    }

    function __ERC20PresetMinterPauser_init_unchained(string memory name, string memory symbol) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../utils/DSMath.sol";
import "../utils/BancorFormula.sol";
import "../DAOStackInterfaces.sol";
import "../Interfaces.sol";
import "../utils/DAOUpgradeableContract.sol";

/**
@title Dynamic reserve ratio market maker
*/
contract GoodMarketMaker is DAOUpgradeableContract, DSMath {
	// Entity that holds a reserve token
	struct ReserveToken {
		// Determines the reserve token balance
		// that the reserve contract holds
		uint256 reserveSupply;
		// Determines the current ratio between
		// the reserve token and the GD token
		uint32 reserveRatio;
		// How many GD tokens have been minted
		// against that reserve token
		uint256 gdSupply;
		//last time reserve ratio was expanded
		uint256 lastExpansion;
	}

	// The map which holds the reserve token entities
	mapping(address => ReserveToken) public reserveTokens;

	// Emits when a change has occurred in a
	// reserve balance, i.e. buy / sell will
	// change the balance
	event BalancesUpdated(
		// The account who initiated the action
		address indexed caller,
		// The address of the reserve token
		address indexed reserveToken,
		// The incoming amount
		uint256 amount,
		// The return value
		uint256 returnAmount,
		// The updated total supply
		uint256 totalSupply,
		// The updated reserve balance
		uint256 reserveBalance
	);

	// Emits when the ratio changed. The caller should be the Avatar by definition
	event ReserveRatioUpdated(address indexed caller, uint256 nom, uint256 denom);

	// Defines the daily change in the reserve ratio in RAY precision.
	// In the current release, only global ratio expansion is supported.
	// That will be a part of each reserve token entity in the future.
	uint256 public reserveRatioDailyExpansion;

	//goodDollar token decimals
	uint256 decimals;

	/**
	 * @dev Constructor
	 * @param _nom The numerator to calculate the global `reserveRatioDailyExpansion` from
	 * @param _denom The denominator to calculate the global `reserveRatioDailyExpansion` from
	 */
	function initialize(
		INameService _ns,
		uint256 _nom,
		uint256 _denom
	) public virtual initializer {
		reserveRatioDailyExpansion = (_nom * 1e27) / _denom;
		decimals = 2;
		setDAO(_ns);
	}

	function _onlyActiveToken(ERC20 _token) internal view {
		ReserveToken storage rtoken = reserveTokens[address(_token)];
		require(rtoken.gdSupply > 0, "Reserve token not initialized");
	}

	function _onlyReserveOrAvatar() internal view {
		require(
			nameService.getAddress("RESERVE") == msg.sender ||
				nameService.getAddress("AVATAR") == msg.sender,
			"GoodMarketMaker: not Reserve or Avatar"
		);
	}

	function getBancor() public view returns (BancorFormula) {
		return BancorFormula(nameService.getAddress("BANCOR_FORMULA"));
	}

	/**
	 * @dev Allows the DAO to change the daily expansion rate
	 * it is calculated by _nom/_denom with e27 precision. Emits
	 * `ReserveRatioUpdated` event after the ratio has changed.
	 * Only Avatar can call this method.
	 * @param _nom The numerator to calculate the global `reserveRatioDailyExpansion` from
	 * @param _denom The denominator to calculate the global `reserveRatioDailyExpansion` from
	 */
	function setReserveRatioDailyExpansion(uint256 _nom, uint256 _denom) public {
		_onlyReserveOrAvatar();
		require(_denom > 0, "denominator must be above 0");
		reserveRatioDailyExpansion = (_nom * 1e27) / _denom;
		require(reserveRatioDailyExpansion < 1e27, "Invalid nom or denom value");
		emit ReserveRatioUpdated(msg.sender, _nom, _denom);
	}

	// NOTICE: In the current release, if there is a wish to add another reserve token,
	//  `end` method in the reserve contract should be called first. Then, the DAO have
	//  to deploy a new reserve contract that will own the market maker. A scheme for
	// updating the new reserve must be deployed too.

	/**
	 * @dev Initialize a reserve token entity with the given parameters
	 * @param _token The reserve token
	 * @param _gdSupply Initial supply of GD to set the price
	 * @param _tokenSupply Initial supply of reserve token to set the price
	 * @param _reserveRatio The starting reserve ratio
	 */
	function initializeToken(
		ERC20 _token,
		uint256 _gdSupply,
		uint256 _tokenSupply,
		uint32 _reserveRatio
	) public {
		_onlyReserveOrAvatar();
		reserveTokens[address(_token)] = ReserveToken({
			gdSupply: _gdSupply,
			reserveSupply: _tokenSupply,
			reserveRatio: _reserveRatio,
			lastExpansion: block.timestamp
		});
	}

	/**
	 * @dev Calculates how much to decrease the reserve ratio for _token by
	 * the `reserveRatioDailyExpansion`
	 * @param _token The reserve token to calculate the reserve ratio for
	 * @return The new reserve ratio
	 */
	function calculateNewReserveRatio(ERC20 _token) public view returns (uint32) {
		ReserveToken memory reserveToken = reserveTokens[address(_token)];
		uint256 ratio = uint256(reserveToken.reserveRatio);
		if (ratio == 0) {
			ratio = 1e6;
		}
		ratio *= 1e21; //expand to e27 precision

		uint256 daysPassed = (block.timestamp - reserveToken.lastExpansion) /
			1 days;
		for (uint256 i = 0; i < daysPassed; i++) {
			ratio = (ratio * reserveRatioDailyExpansion) / 1e27;
		}

		return uint32(ratio / 1e21); // return to e6 precision
	}

	/**
	 * @dev Decreases the reserve ratio for _token by the `reserveRatioDailyExpansion`
	 * @param _token The token to change the reserve ratio for
	 * @return The new reserve ratio
	 */
	function expandReserveRatio(ERC20 _token) public returns (uint32) {
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);
		ReserveToken storage reserveToken = reserveTokens[address(_token)];
		uint32 ratio = reserveToken.reserveRatio;
		if (ratio == 0) {
			ratio = 1e6;
		}
		reserveToken.reserveRatio = calculateNewReserveRatio(_token);

		//set last expansion to begining of expansion day
		reserveToken.lastExpansion =
			block.timestamp -
			((block.timestamp - reserveToken.lastExpansion) % 1 days);
		return reserveToken.reserveRatio;
	}

	/**
	 * @dev Calculates the buy return in GD according to the given _tokenAmount
	 * @param _token The reserve token buying with
	 * @param _tokenAmount The amount of reserve token buying with
	 * @return Number of GD that should be given in exchange as calculated by the bonding curve
	 */
	function buyReturn(ERC20 _token, uint256 _tokenAmount)
		public
		view
		returns (uint256)
	{
		ReserveToken memory rtoken = reserveTokens[address(_token)];
		return
			getBancor().calculatePurchaseReturn(
				rtoken.gdSupply,
				rtoken.reserveSupply,
				rtoken.reserveRatio,
				_tokenAmount
			);
	}

	/**
	 * @dev Calculates the sell return in _token according to the given _gdAmount
	 * @param _token The desired reserve token to have
	 * @param _gdAmount The amount of GD that are sold
	 * @return Number of tokens that should be given in exchange as calculated by the bonding curve
	 */
	function sellReturn(ERC20 _token, uint256 _gdAmount)
		public
		view
		returns (uint256)
	{
		ReserveToken memory rtoken = reserveTokens[address(_token)];
		return
			getBancor().calculateSaleReturn(
				rtoken.gdSupply,
				rtoken.reserveSupply,
				rtoken.reserveRatio,
				_gdAmount
			);
	}

	/**
	 * @dev Updates the _token bonding curve params. Emits `BalancesUpdated` with the
	 * new reserve token information.
	 * @param _token The reserve token buying with
	 * @param _tokenAmount The amount of reserve token buying with
	 * @return (gdReturn) Number of GD that will be given in exchange as calculated by the bonding curve
	 */
	function buy(ERC20 _token, uint256 _tokenAmount) public returns (uint256) {
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);

		uint256 gdReturn = buyReturn(_token, _tokenAmount);
		ReserveToken storage rtoken = reserveTokens[address(_token)];
		rtoken.gdSupply += gdReturn;
		rtoken.reserveSupply += _tokenAmount;
		emit BalancesUpdated(
			msg.sender,
			address(_token),
			_tokenAmount,
			gdReturn,
			rtoken.gdSupply,
			rtoken.reserveSupply
		);
		return gdReturn;
	}

	/**
	 * @dev Updates the bonding curve params. Decrease RR to in order to mint gd in the amount of provided
	 * new RR = Reserve supply / ((gd supply + gd mint amount) * price)
	 * @param _gdAmount Amount of gd to add reserveParams
	 * @param _token The reserve token which is currently active
	 */
	function mintFromReserveRatio(ERC20 _token, uint256 _gdAmount) public {
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);
		uint256 reserveDecimalsDiff = uint256(27) - _token.decimals(); // //result is in RAY precision
		ReserveToken storage rtoken = reserveTokens[address(_token)];
		uint256 priceBeforeGdSupplyChange = currentPrice(_token);
		rtoken.gdSupply += _gdAmount;
		rtoken.reserveRatio = uint32(
			((rtoken.reserveSupply * 1e27) /
				(rtoken.gdSupply * priceBeforeGdSupplyChange)) / 10**reserveDecimalsDiff
		); // Divide it decimal diff to bring it proper decimal
	}

	/**
	 * @dev Calculates the sell return with contribution in _token and update the bonding curve params.
	 * Emits `BalancesUpdated` with the new reserve token information.
	 * @param _token The desired reserve token to have
	 * @param _gdAmount The amount of GD that are sold
	 * @param _contributionGdAmount The number of GD tokens that will not be traded for the reserve token
	 * @return Number of tokens that will be given in exchange as calculated by the bonding curve
	 */
	function sellWithContribution(
		ERC20 _token,
		uint256 _gdAmount,
		uint256 _contributionGdAmount
	) public returns (uint256) {
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);

		require(
			_gdAmount >= _contributionGdAmount,
			"GD amount is lower than the contribution amount"
		);
		ReserveToken storage rtoken = reserveTokens[address(_token)];
		require(
			rtoken.gdSupply >= _gdAmount,
			"GD amount is higher than the total supply"
		);

		// Deduces the convertible amount of GD tokens by the given contribution amount
		uint256 amountAfterContribution = _gdAmount - _contributionGdAmount;

		// The return value after the deduction
		uint256 tokenReturn = sellReturn(_token, amountAfterContribution);
		rtoken.gdSupply -= _gdAmount;
		rtoken.reserveSupply -= tokenReturn;
		emit BalancesUpdated(
			msg.sender,
			address(_token),
			_contributionGdAmount,
			tokenReturn,
			rtoken.gdSupply,
			rtoken.reserveSupply
		);
		return tokenReturn;
	}

	/**
	 * @dev Current price of GD in `token`. currently only cDAI is supported.
	 * @param _token The desired reserve token to have
	 * @return price of GD
	 */
	function currentPrice(ERC20 _token) public view returns (uint256) {
		ReserveToken memory rtoken = reserveTokens[address(_token)];
		return
			getBancor().calculateSaleReturn(
				rtoken.gdSupply,
				rtoken.reserveSupply,
				rtoken.reserveRatio,
				(10**decimals)
			);
	}

	//TODO: need real calculation and tests
	/**
	 * @dev Calculates how much G$ to mint based on added token supply (from interest)
	 * and on current reserve ratio, in order to keep G$ price the same at the bonding curve
	 * formula to calculate the gd to mint: gd to mint =
	 * addreservebalance * (gdsupply / (reservebalance * reserveratio))
	 * @param _token the reserve token
	 * @param _addTokenSupply amount of token added to supply
	 * @return how much to mint in order to keep price in bonding curve the same
	 */
	function calculateMintInterest(ERC20 _token, uint256 _addTokenSupply)
		public
		view
		returns (uint256)
	{
		uint256 decimalsDiff = uint256(27) - decimals;
		//resulting amount is in RAY precision
		//we divide by decimalsdiff to get precision in GD (2 decimals)
		return
			((_addTokenSupply * 1e27) / currentPrice(_token)) / (10**decimalsDiff);
	}

	/**
	 * @dev Updates bonding curve based on _addTokenSupply and new minted amount
	 * @param _token The reserve token
	 * @param _addTokenSupply Amount of token added to supply
	 * @return How much to mint in order to keep price in bonding curve the same
	 */
	function mintInterest(ERC20 _token, uint256 _addTokenSupply)
		public
		returns (uint256)
	{
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);
		if (_addTokenSupply == 0) {
			return 0;
		}
		uint256 toMint = calculateMintInterest(_token, _addTokenSupply);
		ReserveToken storage reserveToken = reserveTokens[address(_token)];
		reserveToken.gdSupply += toMint;
		reserveToken.reserveSupply += _addTokenSupply;

		return toMint;
	}

	/**
	 * @dev Calculate how much G$ to mint based on expansion change (new reserve
	 * ratio), in order to keep G$ price the same at the bonding curve. the
	 * formula to calculate the gd to mint: gd to mint =
	 * (reservebalance / (newreserveratio * currentprice)) - gdsupply
	 * @param _token The reserve token
	 * @return How much to mint in order to keep price in bonding curve the same
	 */
	function calculateMintExpansion(ERC20 _token) public view returns (uint256) {
		ReserveToken memory reserveToken = reserveTokens[address(_token)];
		uint32 newReserveRatio = calculateNewReserveRatio(_token); // new reserve ratio
		uint256 reserveDecimalsDiff = uint256(27) - _token.decimals(); // //result is in RAY precision
		uint256 denom = (uint256(newReserveRatio) *
			1e21 *
			currentPrice(_token) *
			(10**reserveDecimalsDiff)) / 1e27; // (newreserveratio * currentprice) in RAY precision
		uint256 gdDecimalsDiff = uint256(27) - decimals;
		uint256 toMint = ((reserveToken.reserveSupply *
			(10**reserveDecimalsDiff) *
			1e27) / denom) / (10**gdDecimalsDiff); // reservebalance in RAY precision // return to gd precision
		return toMint - reserveToken.gdSupply;
	}

	/**
	 * @dev Updates bonding curve based on expansion change and new minted amount
	 * @param _token The reserve token
	 * @return How much to mint in order to keep price in bonding curve the same
	 */
	function mintExpansion(ERC20 _token) public returns (uint256) {
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);
		uint256 toMint = calculateMintExpansion(_token);
		reserveTokens[address(_token)].gdSupply += toMint;
		expandReserveRatio(_token);

		return toMint;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract BancorFormula {
	using SafeMathUpgradeable for uint256;

	uint256 private constant ONE = 1;
	uint32 private constant MAX_WEIGHT = 1000000;
	uint8 private constant MIN_PRECISION = 32;
	uint8 private constant MAX_PRECISION = 127;

	// Auto-generated via 'PrintIntScalingFactors.py'
	uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
	uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
	uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

	// Auto-generated via 'PrintLn2ScalingFactors.py'
	uint256 private constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
	uint256 private constant LN2_DENOMINATOR =
		0x5b9de1d10bf4103d647b0955897ba80;

	// Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
	uint256 private constant OPT_LOG_MAX_VAL =
		0x15bf0a8b1457695355fb8ac404e7a79e3;
	uint256 private constant OPT_EXP_MAX_VAL =
		0x800000000000000000000000000000000;

	// Auto-generated via 'PrintLambertFactors.py'
	uint256 private constant LAMBERT_CONV_RADIUS =
		0x002f16ac6c59de6f8d5d6f63c1482a7c86;
	uint256 private constant LAMBERT_POS2_SAMPLE =
		0x0003060c183060c183060c183060c18306;
	uint256 private constant LAMBERT_POS2_MAXVAL =
		0x01af16ac6c59de6f8d5d6f63c1482a7c80;
	uint256 private constant LAMBERT_POS3_MAXVAL =
		0x6b22d43e72c326539cceeef8bb48f255ff;

	// Auto-generated via 'PrintWeightFactors.py'
	uint256 private constant MAX_UNF_WEIGHT =
		0x10c6f7a0b5ed8d36b4c7f34938583621fafc8b0079a2834d26fa3fcc9ea9;

	// Auto-generated via 'PrintMaxExpArray.py'
	uint256[128] private maxExpArray;

	function initMaxExpArray() private {
		//  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
		//  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
		//  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
		//  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
		//  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
		//  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
		//  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
		//  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
		//  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
		//  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
		//  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
		//  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
		//  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
		//  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
		//  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
		//  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
		//  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
		//  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
		//  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
		//  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
		//  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
		//  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
		//  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
		//  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
		//  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
		//  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
		//  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
		//  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
		//  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
		//  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
		//  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
		//  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
		maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
		maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
		maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
		maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
		maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
		maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
		maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
		maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
		maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
		maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
		maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
		maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
		maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
		maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
		maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
		maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
		maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
		maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
		maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
		maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
		maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
		maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
		maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
		maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
		maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
		maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
		maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
		maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
		maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
		maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
		maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
		maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
		maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
		maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
		maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
		maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
		maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
		maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
		maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
		maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
		maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
		maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
		maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
		maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
		maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
		maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
		maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
		maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
		maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
		maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
		maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
		maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
		maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
		maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
		maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
		maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
		maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
		maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
		maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
		maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
		maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
		maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
		maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
		maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
		maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
		maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
		maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
		maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
		maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
		maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
		maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
		maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
		maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
		maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
		maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
		maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
		maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
		maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
		maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
		maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
		maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
		maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
		maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
		maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
		maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
		maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
		maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
		maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
		maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
		maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
		maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
		maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
		maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
		maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
		maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
		maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
	}

	// Auto-generated via 'PrintLambertArray.py'
	uint256[128] private lambertArray;

	function initLambertArray() private {
		lambertArray[0] = 0x60e393c68d20b1bd09deaabc0373b9c5;
		lambertArray[1] = 0x5f8f46e4854120989ed94719fb4c2011;
		lambertArray[2] = 0x5e479ebb9129fb1b7e72a648f992b606;
		lambertArray[3] = 0x5d0bd23fe42dfedde2e9586be12b85fe;
		lambertArray[4] = 0x5bdb29ddee979308ddfca81aeeb8095a;
		lambertArray[5] = 0x5ab4fd8a260d2c7e2c0d2afcf0009dad;
		lambertArray[6] = 0x5998b31359a55d48724c65cf09001221;
		lambertArray[7] = 0x5885bcad2b322dfc43e8860f9c018cf5;
		lambertArray[8] = 0x577b97aa1fe222bb452fdf111b1f0be2;
		lambertArray[9] = 0x5679cb5e3575632e5baa27e2b949f704;
		lambertArray[10] = 0x557fe8241b3a31c83c732f1cdff4a1c5;
		lambertArray[11] = 0x548d868026504875d6e59bbe95fc2a6b;
		lambertArray[12] = 0x53a2465ce347cf34d05a867c17dd3088;
		lambertArray[13] = 0x52bdce5dcd4faed59c7f5511cf8f8acc;
		lambertArray[14] = 0x51dfcb453c07f8da817606e7885f7c3e;
		lambertArray[15] = 0x5107ef6b0a5a2be8f8ff15590daa3cce;
		lambertArray[16] = 0x5035f241d6eae0cd7bacba119993de7b;
		lambertArray[17] = 0x4f698fe90d5b53d532171e1210164c66;
		lambertArray[18] = 0x4ea288ca297a0e6a09a0eee240e16c85;
		lambertArray[19] = 0x4de0a13fdcf5d4213fc398ba6e3becde;
		lambertArray[20] = 0x4d23a145eef91fec06b06140804c4808;
		lambertArray[21] = 0x4c6b5430d4c1ee5526473db4ae0f11de;
		lambertArray[22] = 0x4bb7886c240562eba11f4963a53b4240;
		lambertArray[23] = 0x4b080f3f1cb491d2d521e0ea4583521e;
		lambertArray[24] = 0x4a5cbc96a05589cb4d86be1db3168364;
		lambertArray[25] = 0x49b566d40243517658d78c33162d6ece;
		lambertArray[26] = 0x4911e6a02e5507a30f947383fd9a3276;
		lambertArray[27] = 0x487216c2b31be4adc41db8a8d5cc0c88;
		lambertArray[28] = 0x47d5d3fc4a7a1b188cd3d788b5c5e9fc;
		lambertArray[29] = 0x473cfce4871a2c40bc4f9e1c32b955d0;
		lambertArray[30] = 0x46a771ca578ab878485810e285e31c67;
		lambertArray[31] = 0x4615149718aed4c258c373dc676aa72d;
		lambertArray[32] = 0x4585c8b3f8fe489c6e1833ca47871384;
		lambertArray[33] = 0x44f972f174e41e5efb7e9d63c29ce735;
		lambertArray[34] = 0x446ff970ba86d8b00beb05ecebf3c4dc;
		lambertArray[35] = 0x43e9438ec88971812d6f198b5ccaad96;
		lambertArray[36] = 0x436539d11ff7bea657aeddb394e809ef;
		lambertArray[37] = 0x42e3c5d3e5a913401d86f66db5d81c2c;
		lambertArray[38] = 0x4264d2395303070ea726cbe98df62174;
		lambertArray[39] = 0x41e84a9a593bb7194c3a6349ecae4eea;
		lambertArray[40] = 0x416e1b785d13eba07a08f3f18876a5ab;
		lambertArray[41] = 0x40f6322ff389d423ba9dd7e7e7b7e809;
		lambertArray[42] = 0x40807cec8a466880ecf4184545d240a4;
		lambertArray[43] = 0x400cea9ce88a8d3ae668e8ea0d9bf07f;
		lambertArray[44] = 0x3f9b6ae8772d4c55091e0ed7dfea0ac1;
		lambertArray[45] = 0x3f2bee253fd84594f54bcaafac383a13;
		lambertArray[46] = 0x3ebe654e95208bb9210c575c081c5958;
		lambertArray[47] = 0x3e52c1fc5665635b78ce1f05ad53c086;
		lambertArray[48] = 0x3de8f65ac388101ddf718a6f5c1eff65;
		lambertArray[49] = 0x3d80f522d59bd0b328ca012df4cd2d49;
		lambertArray[50] = 0x3d1ab193129ea72b23648a161163a85a;
		lambertArray[51] = 0x3cb61f68d32576c135b95cfb53f76d75;
		lambertArray[52] = 0x3c5332d9f1aae851a3619e77e4cc8473;
		lambertArray[53] = 0x3bf1e08edbe2aa109e1525f65759ef73;
		lambertArray[54] = 0x3b921d9cff13fa2c197746a3dfc4918f;
		lambertArray[55] = 0x3b33df818910bfc1a5aefb8f63ae2ac4;
		lambertArray[56] = 0x3ad71c1c77e34fa32a9f184967eccbf6;
		lambertArray[57] = 0x3a7bc9abf2c5bb53e2f7384a8a16521a;
		lambertArray[58] = 0x3a21dec7e76369783a68a0c6385a1c57;
		lambertArray[59] = 0x39c9525de6c9cdf7c1c157ca4a7a6ee3;
		lambertArray[60] = 0x39721bad3dc85d1240ff0190e0adaac3;
		lambertArray[61] = 0x391c324344d3248f0469eb28dd3d77e0;
		lambertArray[62] = 0x38c78df7e3c796279fb4ff84394ab3da;
		lambertArray[63] = 0x387426ea4638ae9aae08049d3554c20a;
		lambertArray[64] = 0x3821f57dbd2763256c1a99bbd2051378;
		lambertArray[65] = 0x37d0f256cb46a8c92ff62fbbef289698;
		lambertArray[66] = 0x37811658591ffc7abdd1feaf3cef9b73;
		lambertArray[67] = 0x37325aa10e9e82f7df0f380f7997154b;
		lambertArray[68] = 0x36e4b888cfb408d873b9a80d439311c6;
		lambertArray[69] = 0x3698299e59f4bb9de645fc9b08c64cca;
		lambertArray[70] = 0x364ca7a5012cb603023b57dd3ebfd50d;
		lambertArray[71] = 0x36022c928915b778ab1b06aaee7e61d4;
		lambertArray[72] = 0x35b8b28d1a73dc27500ffe35559cc028;
		lambertArray[73] = 0x357033e951fe250ec5eb4e60955132d7;
		lambertArray[74] = 0x3528ab2867934e3a21b5412e4c4f8881;
		lambertArray[75] = 0x34e212f66c55057f9676c80094a61d59;
		lambertArray[76] = 0x349c66289e5b3c4b540c24f42fa4b9bb;
		lambertArray[77] = 0x34579fbbd0c733a9c8d6af6b0f7d00f7;
		lambertArray[78] = 0x3413bad2e712288b924b5882b5b369bf;
		lambertArray[79] = 0x33d0b2b56286510ef730e213f71f12e9;
		lambertArray[80] = 0x338e82ce00e2496262c64457535ba1a1;
		lambertArray[81] = 0x334d26a96b373bb7c2f8ea1827f27a92;
		lambertArray[82] = 0x330c99f4f4211469e00b3e18c31475ea;
		lambertArray[83] = 0x32ccd87d6486094999c7d5e6f33237d8;
		lambertArray[84] = 0x328dde2dd617b6665a2e8556f250c1af;
		lambertArray[85] = 0x324fa70e9adc270f8262755af5a99af9;
		lambertArray[86] = 0x32122f443110611ca51040f41fa6e1e3;
		lambertArray[87] = 0x31d5730e42c0831482f0f1485c4263d8;
		lambertArray[88] = 0x31996ec6b07b4a83421b5ebc4ab4e1f1;
		lambertArray[89] = 0x315e1ee0a68ff46bb43ec2b85032e876;
		lambertArray[90] = 0x31237fe7bc4deacf6775b9efa1a145f8;
		lambertArray[91] = 0x30e98e7f1cc5a356e44627a6972ea2ff;
		lambertArray[92] = 0x30b04760b8917ec74205a3002650ec05;
		lambertArray[93] = 0x3077a75c803468e9132ce0cf3224241d;
		lambertArray[94] = 0x303fab57a6a275c36f19cda9bace667a;
		lambertArray[95] = 0x3008504beb8dcbd2cf3bc1f6d5a064f0;
		lambertArray[96] = 0x2fd19346ed17dac61219ce0c2c5ac4b0;
		lambertArray[97] = 0x2f9b7169808c324b5852fd3d54ba9714;
		lambertArray[98] = 0x2f65e7e711cf4b064eea9c08cbdad574;
		lambertArray[99] = 0x2f30f405093042ddff8a251b6bf6d103;
		lambertArray[100] = 0x2efc931a3750f2e8bfe323edfe037574;
		lambertArray[101] = 0x2ec8c28e46dbe56d98685278339400cb;
		lambertArray[102] = 0x2e957fd933c3926d8a599b602379b851;
		lambertArray[103] = 0x2e62c882c7c9ed4473412702f08ba0e5;
		lambertArray[104] = 0x2e309a221c12ba361e3ed695167feee2;
		lambertArray[105] = 0x2dfef25d1f865ae18dd07cfea4bcea10;
		lambertArray[106] = 0x2dcdcee821cdc80decc02c44344aeb31;
		lambertArray[107] = 0x2d9d2d8562b34944d0b201bb87260c83;
		lambertArray[108] = 0x2d6d0c04a5b62a2c42636308669b729a;
		lambertArray[109] = 0x2d3d6842c9a235517fc5a0332691528f;
		lambertArray[110] = 0x2d0e402963fe1ea2834abc408c437c10;
		lambertArray[111] = 0x2cdf91ae602647908aff975e4d6a2a8c;
		lambertArray[112] = 0x2cb15ad3a1eb65f6d74a75da09a1b6c5;
		lambertArray[113] = 0x2c8399a6ab8e9774d6fcff373d210727;
		lambertArray[114] = 0x2c564c4046f64edba6883ca06bbc4535;
		lambertArray[115] = 0x2c2970c431f952641e05cb493e23eed3;
		lambertArray[116] = 0x2bfd0560cd9eb14563bc7c0732856c18;
		lambertArray[117] = 0x2bd1084ed0332f7ff4150f9d0ef41a2c;
		lambertArray[118] = 0x2ba577d0fa1628b76d040b12a82492fb;
		lambertArray[119] = 0x2b7a5233cd21581e855e89dc2f1e8a92;
		lambertArray[120] = 0x2b4f95cd46904d05d72bdcde337d9cc7;
		lambertArray[121] = 0x2b2540fc9b4d9abba3faca6691914675;
		lambertArray[122] = 0x2afb5229f68d0830d8be8adb0a0db70f;
		lambertArray[123] = 0x2ad1c7c63a9b294c5bc73a3ba3ab7a2b;
		lambertArray[124] = 0x2aa8a04ac3cbe1ee1c9c86361465dbb8;
		lambertArray[125] = 0x2a7fda392d725a44a2c8aeb9ab35430d;
		lambertArray[126] = 0x2a57741b18cde618717792b4faa216db;
		lambertArray[127] = 0x2a2f6c81f5d84dd950a35626d6d5503a;
	}

	/**
	 * @dev should be executed after construction (too large for the constructor)
	 */
	function init() public {
		initMaxExpArray();
		initLambertArray();
	}

	/**
	 * @dev given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
	 * calculates the target amount for a given conversion (in the main token)
	 *
	 * Formula:
	 * return = _supply * ((1 + _amount / _reserveBalance) ^ (_reserveWeight / 1000000) - 1)
	 *
	 * @param _supply          liquid token supply
	 * @param _reserveBalance  reserve balance
	 * @param _reserveWeight   reserve weight, represented in ppm (1-1000000)
	 * @param _amount          amount of reserve tokens to get the target amount for
	 *
	 * @return target
	 */
	function purchaseTargetAmount(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveWeight,
		uint256 _amount
	) public view returns (uint256) {
		// validate input
		require(_supply > 0, "ERR_INVALID_SUPPLY");
		require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
		require(
			_reserveWeight > 0 && _reserveWeight <= MAX_WEIGHT,
			"ERR_INVALID_RESERVE_WEIGHT"
		);

		// special case for 0 deposit amount
		if (_amount == 0) return 0;

		// special case if the weight = 100%
		if (_reserveWeight == MAX_WEIGHT)
			return _supply.mul(_amount) / _reserveBalance;

		uint256 result;
		uint8 precision;
		uint256 baseN = _amount.add(_reserveBalance);
		(result, precision) = power(
			baseN,
			_reserveBalance,
			_reserveWeight,
			MAX_WEIGHT
		);
		uint256 temp = _supply.mul(result) >> precision;
		return temp - _supply;
	}

	/**
	 * @dev given a token supply, reserve balance, weight and a sell amount (in the main token),
	 * calculates the target amount for a given conversion (in the reserve token)
	 *
	 * Formula:
	 * return = _reserveBalance * (1 - (1 - _amount / _supply) ^ (1000000 / _reserveWeight))
	 *
	 * @param _supply          liquid token supply
	 * @param _reserveBalance  reserve balance
	 * @param _reserveWeight   reserve weight, represented in ppm (1-1000000)
	 * @param _amount          amount of liquid tokens to get the target amount for
	 *
	 * @return reserve token amount
	 */
	function saleTargetAmount(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveWeight,
		uint256 _amount
	) public view returns (uint256) {
		// validate input
		require(_supply > 0, "ERR_INVALID_SUPPLY");
		require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
		require(
			_reserveWeight > 0 && _reserveWeight <= MAX_WEIGHT,
			"ERR_INVALID_RESERVE_WEIGHT"
		);
		require(_amount <= _supply, "ERR_INVALID_AMOUNT");

		// special case for 0 sell amount
		if (_amount == 0) return 0;

		// special case for selling the entire supply
		if (_amount == _supply) return _reserveBalance;

		// special case if the weight = 100%
		if (_reserveWeight == MAX_WEIGHT)
			return _reserveBalance.mul(_amount) / _supply;

		uint256 result;
		uint8 precision;
		uint256 baseD = _supply - _amount;
		(result, precision) = power(_supply, baseD, MAX_WEIGHT, _reserveWeight);
		uint256 temp1 = _reserveBalance.mul(result);
		uint256 temp2 = _reserveBalance << precision;
		return (temp1 - temp2) / result;
	}

	/**
	 * @dev given two reserve balances/weights and a sell amount (in the first reserve token),
	 * calculates the target amount for a conversion from the source reserve token to the target reserve token
	 *
	 * Formula:
	 * return = _targetReserveBalance * (1 - (_sourceReserveBalance / (_sourceReserveBalance + _amount)) ^ (_sourceReserveWeight / _targetReserveWeight))
	 *
	 * @param _sourceReserveBalance    source reserve balance
	 * @param _sourceReserveWeight     source reserve weight, represented in ppm (1-1000000)
	 * @param _targetReserveBalance    target reserve balance
	 * @param _targetReserveWeight     target reserve weight, represented in ppm (1-1000000)
	 * @param _amount                  source reserve amount
	 *
	 * @return target reserve amount
	 */
	function crossReserveTargetAmount(
		uint256 _sourceReserveBalance,
		uint32 _sourceReserveWeight,
		uint256 _targetReserveBalance,
		uint32 _targetReserveWeight,
		uint256 _amount
	) public view returns (uint256) {
		// validate input
		require(
			_sourceReserveBalance > 0 && _targetReserveBalance > 0,
			"ERR_INVALID_RESERVE_BALANCE"
		);
		require(
			_sourceReserveWeight > 0 &&
				_sourceReserveWeight <= MAX_WEIGHT &&
				_targetReserveWeight > 0 &&
				_targetReserveWeight <= MAX_WEIGHT,
			"ERR_INVALID_RESERVE_WEIGHT"
		);

		// special case for equal weights
		if (_sourceReserveWeight == _targetReserveWeight)
			return
				_targetReserveBalance.mul(_amount) /
				_sourceReserveBalance.add(_amount);

		uint256 result;
		uint8 precision;
		uint256 baseN = _sourceReserveBalance.add(_amount);
		(result, precision) = power(
			baseN,
			_sourceReserveBalance,
			_sourceReserveWeight,
			_targetReserveWeight
		);
		uint256 temp1 = _targetReserveBalance.mul(result);
		uint256 temp2 = _targetReserveBalance << precision;
		return (temp1 - temp2) / result;
	}

	/**
	 * @dev given a pool token supply, reserve balance, reserve ratio and an amount of requested pool tokens,
	 * calculates the amount of reserve tokens required for purchasing the given amount of pool tokens
	 *
	 * Formula:
	 * return = _reserveBalance * (((_supply + _amount) / _supply) ^ (MAX_WEIGHT / _reserveRatio) - 1)
	 *
	 * @param _supply          pool token supply
	 * @param _reserveBalance  reserve balance
	 * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
	 * @param _amount          requested amount of pool tokens
	 *
	 * @return reserve token amount
	 */
	function fundCost(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveRatio,
		uint256 _amount
	) public view returns (uint256) {
		// validate input
		require(_supply > 0, "ERR_INVALID_SUPPLY");
		require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
		require(
			_reserveRatio > 1 && _reserveRatio <= MAX_WEIGHT * 2,
			"ERR_INVALID_RESERVE_RATIO"
		);

		// special case for 0 amount
		if (_amount == 0) return 0;

		// special case if the reserve ratio = 100%
		if (_reserveRatio == MAX_WEIGHT)
			return (_amount.mul(_reserveBalance) - 1) / _supply + 1;

		uint256 result;
		uint8 precision;
		uint256 baseN = _supply.add(_amount);
		(result, precision) = power(baseN, _supply, MAX_WEIGHT, _reserveRatio);
		uint256 temp = ((_reserveBalance.mul(result) - 1) >> precision) + 1;
		return temp - _reserveBalance;
	}

	/**
	 * @dev given a pool token supply, reserve balance, reserve ratio and an amount of reserve tokens to fund with,
	 * calculates the amount of pool tokens received for purchasing with the given amount of reserve tokens
	 *
	 * Formula:
	 * return = _supply * ((_amount / _reserveBalance + 1) ^ (_reserveRatio / MAX_WEIGHT) - 1)
	 *
	 * @param _supply          pool token supply
	 * @param _reserveBalance  reserve balance
	 * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
	 * @param _amount          amount of reserve tokens to fund with
	 *
	 * @return pool token amount
	 */
	function fundSupplyAmount(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveRatio,
		uint256 _amount
	) public view returns (uint256) {
		// validate input
		require(_supply > 0, "ERR_INVALID_SUPPLY");
		require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
		require(
			_reserveRatio > 1 && _reserveRatio <= MAX_WEIGHT * 2,
			"ERR_INVALID_RESERVE_RATIO"
		);

		// special case for 0 amount
		if (_amount == 0) return 0;

		// special case if the reserve ratio = 100%
		if (_reserveRatio == MAX_WEIGHT)
			return _amount.mul(_supply) / _reserveBalance;

		uint256 result;
		uint8 precision;
		uint256 baseN = _reserveBalance.add(_amount);
		(result, precision) = power(
			baseN,
			_reserveBalance,
			_reserveRatio,
			MAX_WEIGHT
		);
		uint256 temp = _supply.mul(result) >> precision;
		return temp - _supply;
	}

	/**
	 * @dev given a pool token supply, reserve balance, reserve ratio and an amount of pool tokens to liquidate,
	 * calculates the amount of reserve tokens received for selling the given amount of pool tokens
	 *
	 * Formula:
	 * return = _reserveBalance * (1 - ((_supply - _amount) / _supply) ^ (MAX_WEIGHT / _reserveRatio))
	 *
	 * @param _supply          pool token supply
	 * @param _reserveBalance  reserve balance
	 * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
	 * @param _amount          amount of pool tokens to liquidate
	 *
	 * @return reserve token amount
	 */
	function liquidateReserveAmount(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveRatio,
		uint256 _amount
	) public view returns (uint256) {
		// validate input
		require(_supply > 0, "ERR_INVALID_SUPPLY");
		require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
		require(
			_reserveRatio > 1 && _reserveRatio <= MAX_WEIGHT * 2,
			"ERR_INVALID_RESERVE_RATIO"
		);
		require(_amount <= _supply, "ERR_INVALID_AMOUNT");

		// special case for 0 amount
		if (_amount == 0) return 0;

		// special case for liquidating the entire supply
		if (_amount == _supply) return _reserveBalance;

		// special case if the reserve ratio = 100%
		if (_reserveRatio == MAX_WEIGHT)
			return _amount.mul(_reserveBalance) / _supply;

		uint256 result;
		uint8 precision;
		uint256 baseD = _supply - _amount;
		(result, precision) = power(_supply, baseD, MAX_WEIGHT, _reserveRatio);
		uint256 temp1 = _reserveBalance.mul(result);
		uint256 temp2 = _reserveBalance << precision;
		return (temp1 - temp2) / result;
	}

	/**
	 * @dev The arbitrage incentive is to convert to the point where the on-chain price is equal to the off-chain price.
	 * We want this operation to also impact the primary reserve balance becoming equal to the primary reserve staked balance.
	 * In other words, we want the arbitrager to convert the difference between the reserve balance and the reserve staked balance.
	 *
	 * Formula input:
	 * - let t denote the primary reserve token staked balance
	 * - let s denote the primary reserve token balance
	 * - let r denote the secondary reserve token balance
	 * - let q denote the numerator of the rate between the tokens
	 * - let p denote the denominator of the rate between the tokens
	 * Where p primary tokens are equal to q secondary tokens
	 *
	 * Formula output:
	 * - compute x = W(t / r * q / p * log(s / t)) / log(s / t)
	 * - return x / (1 + x) as the weight of the primary reserve token
	 * - return 1 / (1 + x) as the weight of the secondary reserve token
	 * Where W is the Lambert W Function
	 *
	 * If the rate-provider provides the rates for a common unit, for example:
	 * - P = 2 ==> 2 primary reserve tokens = 1 ether
	 * - Q = 3 ==> 3 secondary reserve tokens = 1 ether
	 * Then you can simply use p = P and q = Q
	 *
	 * If the rate-provider provides the rates for a single unit, for example:
	 * - P = 2 ==> 1 primary reserve token = 2 ethers
	 * - Q = 3 ==> 1 secondary reserve token = 3 ethers
	 * Then you can simply use p = Q and q = P
	 *
	 * @param _primaryReserveStakedBalance the primary reserve token staked balance
	 * @param _primaryReserveBalance       the primary reserve token balance
	 * @param _secondaryReserveBalance     the secondary reserve token balance
	 * @param _reserveRateNumerator        the numerator of the rate between the tokens
	 * @param _reserveRateDenominator      the denominator of the rate between the tokens
	 *
	 * Note that `numerator / denominator` should represent the amount of secondary tokens equal to one primary token
	 *
	 * @return the weight of the primary reserve token and the weight of the secondary reserve token, both in ppm (0-1000000)
	 */
	function balancedWeights(
		uint256 _primaryReserveStakedBalance,
		uint256 _primaryReserveBalance,
		uint256 _secondaryReserveBalance,
		uint256 _reserveRateNumerator,
		uint256 _reserveRateDenominator
	) public view returns (uint32, uint32) {
		if (_primaryReserveStakedBalance == _primaryReserveBalance)
			require(
				_primaryReserveStakedBalance > 0 ||
					_secondaryReserveBalance > 0,
				"ERR_INVALID_RESERVE_BALANCE"
			);
		else
			require(
				_primaryReserveStakedBalance > 0 &&
					_primaryReserveBalance > 0 &&
					_secondaryReserveBalance > 0,
				"ERR_INVALID_RESERVE_BALANCE"
			);
		require(
			_reserveRateNumerator > 0 && _reserveRateDenominator > 0,
			"ERR_INVALID_RESERVE_RATE"
		);

		uint256 tq = _primaryReserveStakedBalance.mul(_reserveRateNumerator);
		uint256 rp = _secondaryReserveBalance.mul(_reserveRateDenominator);

		if (_primaryReserveStakedBalance < _primaryReserveBalance)
			return
				balancedWeightsByStake(
					_primaryReserveBalance,
					_primaryReserveStakedBalance,
					tq,
					rp,
					true
				);

		if (_primaryReserveStakedBalance > _primaryReserveBalance)
			return
				balancedWeightsByStake(
					_primaryReserveStakedBalance,
					_primaryReserveBalance,
					tq,
					rp,
					false
				);

		return normalizedWeights(tq, rp);
	}

	/**
	 * @dev General Description:
	 *     Determine a value of precision.
	 *     Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
	 *     Return the result along with the precision used.
	 *
	 * Detailed Description:
	 *     Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
	 *     The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
	 *     The larger "precision" is, the more accurately this value represents the real value.
	 *     However, the larger "precision" is, the more bits are required in order to store this value.
	 *     And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
	 *     This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
	 *     Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
	 *     This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
	 *     This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
	 *     Since we rely on unsigned-integer arithmetic and "base < 1" ==> "log(base) < 0", this function does not support "_baseN < _baseD".
	 */
	function power(
		uint256 _baseN,
		uint256 _baseD,
		uint32 _expN,
		uint32 _expD
	) internal view returns (uint256, uint8) {
		require(_baseN < MAX_NUM);

		uint256 baseLog;
		uint256 base = (_baseN * FIXED_1) / _baseD;
		if (base < OPT_LOG_MAX_VAL) {
			baseLog = optimalLog(base);
		} else {
			baseLog = generalLog(base);
		}

		uint256 baseLogTimesExp = (baseLog * _expN) / _expD;
		if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
			return (optimalExp(baseLogTimesExp), MAX_PRECISION);
		} else {
			uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
			return (
				generalExp(
					baseLogTimesExp >> (MAX_PRECISION - precision),
					precision
				),
				precision
			);
		}
	}

	/**
	 * @dev computes log(x / FIXED_1) * FIXED_1.
	 * This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
	 */
	function generalLog(uint256 x) internal pure returns (uint256) {
		uint256 res = 0;

		// If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
		if (x >= FIXED_2) {
			uint8 count = floorLog2(x / FIXED_1);
			x >>= count; // now x < 2
			res = count * FIXED_1;
		}

		// If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
		if (x > FIXED_1) {
			for (uint8 i = MAX_PRECISION; i > 0; --i) {
				x = (x * x) / FIXED_1; // now 1 < x < 4
				if (x >= FIXED_2) {
					x >>= 1; // now 1 < x < 2
					res += ONE << (i - 1);
				}
			}
		}

		return (res * LN2_NUMERATOR) / LN2_DENOMINATOR;
	}

	/**
	 * @dev computes the largest integer smaller than or equal to the binary logarithm of the input.
	 */
	function floorLog2(uint256 _n) internal pure returns (uint8) {
		uint8 res = 0;

		if (_n < 256) {
			// At most 8 iterations
			while (_n > 1) {
				_n >>= 1;
				res += 1;
			}
		} else {
			// Exactly 8 iterations
			for (uint8 s = 128; s > 0; s >>= 1) {
				if (_n >= (ONE << s)) {
					_n >>= s;
					res |= s;
				}
			}
		}

		return res;
	}

	/**
	 * @dev the global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
	 * - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
	 * - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
	 */
	function findPositionInMaxExpArray(uint256 _x)
		internal
		view
		returns (uint8)
	{
		uint8 lo = MIN_PRECISION;
		uint8 hi = MAX_PRECISION;

		while (lo + 1 < hi) {
			uint8 mid = (lo + hi) / 2;
			if (maxExpArray[mid] >= _x) lo = mid;
			else hi = mid;
		}

		if (maxExpArray[hi] >= _x) return hi;
		if (maxExpArray[lo] >= _x) return lo;

		require(false);
	}

	/**
	 * @dev this function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
	 * it approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
	 * it returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
	 * the global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
	 * the maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
	 */
	function generalExp(uint256 _x, uint8 _precision)
		internal
		pure
		returns (uint256)
	{
		uint256 xi = _x;
		uint256 res = 0;

		xi = (xi * _x) >> _precision;
		res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
		xi = (xi * _x) >> _precision;
		res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

		return
			res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
	}

	/**
	 * @dev computes log(x / FIXED_1) * FIXED_1
	 * Input range: FIXED_1 <= x <= OPT_LOG_MAX_VAL - 1
	 * Auto-generated via 'PrintFunctionOptimalLog.py'
	 * Detailed description:
	 * - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
	 * - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
	 * - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
	 * - The natural logarithm of the input is calculated by summing up the intermediate results above
	 * - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
	 */
	function optimalLog(uint256 x) internal pure returns (uint256) {
		uint256 res = 0;

		uint256 y;
		uint256 z;
		uint256 w;

		if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {
			res += 0x40000000000000000000000000000000;
			x = (x * FIXED_1) / 0xd3094c70f034de4b96ff7d5b6f99fcd8;
		} // add 1 / 2^1
		if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {
			res += 0x20000000000000000000000000000000;
			x = (x * FIXED_1) / 0xa45af1e1f40c333b3de1db4dd55f29a7;
		} // add 1 / 2^2
		if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {
			res += 0x10000000000000000000000000000000;
			x = (x * FIXED_1) / 0x910b022db7ae67ce76b441c27035c6a1;
		} // add 1 / 2^3
		if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {
			res += 0x08000000000000000000000000000000;
			x = (x * FIXED_1) / 0x88415abbe9a76bead8d00cf112e4d4a8;
		} // add 1 / 2^4
		if (x >= 0x84102b00893f64c705e841d5d4064bd3) {
			res += 0x04000000000000000000000000000000;
			x = (x * FIXED_1) / 0x84102b00893f64c705e841d5d4064bd3;
		} // add 1 / 2^5
		if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {
			res += 0x02000000000000000000000000000000;
			x = (x * FIXED_1) / 0x8204055aaef1c8bd5c3259f4822735a2;
		} // add 1 / 2^6
		if (x >= 0x810100ab00222d861931c15e39b44e99) {
			res += 0x01000000000000000000000000000000;
			x = (x * FIXED_1) / 0x810100ab00222d861931c15e39b44e99;
		} // add 1 / 2^7
		if (x >= 0x808040155aabbbe9451521693554f733) {
			res += 0x00800000000000000000000000000000;
			x = (x * FIXED_1) / 0x808040155aabbbe9451521693554f733;
		} // add 1 / 2^8

		z = y = x - FIXED_1;
		w = (y * y) / FIXED_1;
		res +=
			(z * (0x100000000000000000000000000000000 - y)) /
			0x100000000000000000000000000000000;
		z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
		res +=
			(z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) /
			0x200000000000000000000000000000000;
		z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
		res +=
			(z * (0x099999999999999999999999999999999 - y)) /
			0x300000000000000000000000000000000;
		z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
		res +=
			(z * (0x092492492492492492492492492492492 - y)) /
			0x400000000000000000000000000000000;
		z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
		res +=
			(z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) /
			0x500000000000000000000000000000000;
		z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
		res +=
			(z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) /
			0x600000000000000000000000000000000;
		z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
		res +=
			(z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) /
			0x700000000000000000000000000000000;
		z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
		res +=
			(z * (0x088888888888888888888888888888888 - y)) /
			0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

		return res;
	}

	/**
	 * @dev computes e ^ (x / FIXED_1) * FIXED_1
	 * input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
	 * auto-generated via 'PrintFunctionOptimalExp.py'
	 * Detailed description:
	 * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
	 * - The exponentiation of each binary exponent is given (pre-calculated)
	 * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
	 * - The exponentiation of the input is calculated by multiplying the intermediate results above
	 * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
	 */
	function optimalExp(uint256 x) internal pure returns (uint256) {
		uint256 res = 0;

		uint256 y;
		uint256 z;

		z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
		z = (z * y) / FIXED_1;
		res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
		z = (z * y) / FIXED_1;
		res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
		z = (z * y) / FIXED_1;
		res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
		z = (z * y) / FIXED_1;
		res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
		z = (z * y) / FIXED_1;
		res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
		z = (z * y) / FIXED_1;
		res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
		z = (z * y) / FIXED_1;
		res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
		z = (z * y) / FIXED_1;
		res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
		z = (z * y) / FIXED_1;
		res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
		z = (z * y) / FIXED_1;
		res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
		z = (z * y) / FIXED_1;
		res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
		z = (z * y) / FIXED_1;
		res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
		z = (z * y) / FIXED_1;
		res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
		z = (z * y) / FIXED_1;
		res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
		z = (z * y) / FIXED_1;
		res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
		z = (z * y) / FIXED_1;
		res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
		z = (z * y) / FIXED_1;
		res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
		z = (z * y) / FIXED_1;
		res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
		z = (z * y) / FIXED_1;
		res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
		res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

		if ((x & 0x010000000000000000000000000000000) != 0)
			res =
				(res * 0x1c3d6a24ed82218787d624d3e5eba95f9) /
				0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
		if ((x & 0x020000000000000000000000000000000) != 0)
			res =
				(res * 0x18ebef9eac820ae8682b9793ac6d1e778) /
				0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
		if ((x & 0x040000000000000000000000000000000) != 0)
			res =
				(res * 0x1368b2fc6f9609fe7aceb46aa619baed5) /
				0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
		if ((x & 0x080000000000000000000000000000000) != 0)
			res =
				(res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) /
				0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
		if ((x & 0x100000000000000000000000000000000) != 0)
			res =
				(res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) /
				0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
		if ((x & 0x200000000000000000000000000000000) != 0)
			res =
				(res * 0x00960aadc109e7a3bf4578099615711d7) /
				0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
		if ((x & 0x400000000000000000000000000000000) != 0)
			res =
				(res * 0x0002bf84208204f5977f9a8cf01fdc307) /
				0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

		return res;
	}

	/**
	 * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
	 */
	function lowerStake(uint256 _x) internal view returns (uint256) {
		if (_x <= LAMBERT_CONV_RADIUS) return lambertPos1(_x);
		if (_x <= LAMBERT_POS2_MAXVAL) return lambertPos2(_x);
		if (_x <= LAMBERT_POS3_MAXVAL) return lambertPos3(_x);
		require(false);
	}

	/**
	 * @dev computes W(-x / FIXED_1) / (-x / FIXED_1) * FIXED_1
	 */
	function higherStake(uint256 _x) internal pure returns (uint256) {
		if (_x <= LAMBERT_CONV_RADIUS) return lambertNeg1(_x);
		return (FIXED_1 * FIXED_1) / _x;
	}

	/**
	 * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
	 * input range: 1 <= x <= 1 / e * FIXED_1
	 * auto-generated via 'PrintFunctionLambertPos1.py'
	 */
	function lambertPos1(uint256 _x) internal pure returns (uint256) {
		uint256 xi = _x;
		uint256 res = (FIXED_1 - _x) * 0xde1bc4d19efcac82445da75b00000000; // x^(1-1) * (34! * 1^(1-1) / 1!) - x^(2-1) * (34! * 2^(2-1) / 2!)

		xi = (xi * _x) / FIXED_1;
		res += xi * 0x00000000014d29a73a6e7b02c3668c7b0880000000; // add x^(03-1) * (34! * 03^(03-1) / 03!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x0000000002504a0cd9a7f7215b60f9be4800000000; // sub x^(04-1) * (34! * 04^(04-1) / 04!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000000000484d0a1191c0ead267967c7a4a0000000; // add x^(05-1) * (34! * 05^(05-1) / 05!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x00000000095ec580d7e8427a4baf26a90a00000000; // sub x^(06-1) * (34! * 06^(06-1) / 06!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000000001440b0be1615a47dba6e5b3b1f10000000; // add x^(07-1) * (34! * 07^(07-1) / 07!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x000000002d207601f46a99b4112418400000000000; // sub x^(08-1) * (34! * 08^(08-1) / 08!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000000066ebaac4c37c622dd8288a7eb1b2000000; // add x^(09-1) * (34! * 09^(09-1) / 09!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x00000000ef17240135f7dbd43a1ba10cf200000000; // sub x^(10-1) * (34! * 10^(10-1) / 10!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000000233c33c676a5eb2416094a87b3657000000; // add x^(11-1) * (34! * 11^(11-1) / 11!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x0000000541cde48bc0254bed49a9f8700000000000; // sub x^(12-1) * (34! * 12^(12-1) / 12!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000000cae1fad2cdd4d4cb8d73abca0d19a400000; // add x^(13-1) * (34! * 13^(13-1) / 13!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x0000001edb2aa2f760d15c41ceedba956400000000; // sub x^(14-1) * (34! * 14^(14-1) / 14!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000004ba8d20d2dabd386c9529659841a2e200000; // add x^(15-1) * (34! * 15^(15-1) / 15!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x000000bac08546b867cdaa20000000000000000000; // sub x^(16-1) * (34! * 16^(16-1) / 16!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000001cfa8e70c03625b9db76c8ebf5bbf24820000; // add x^(17-1) * (34! * 17^(17-1) / 17!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x000004851d99f82060df265f3309b26f8200000000; // sub x^(18-1) * (34! * 18^(18-1) / 18!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x00000b550d19b129d270c44f6f55f027723cbb0000; // add x^(19-1) * (34! * 19^(19-1) / 19!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x00001c877dadc761dc272deb65d4b0000000000000; // sub x^(20-1) * (34! * 20^(20-1) / 20!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000048178ece97479f33a77f2ad22a81b64406c000; // add x^(21-1) * (34! * 21^(21-1) / 21!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x0000b6ca8268b9d810fedf6695ef2f8a6c00000000; // sub x^(22-1) * (34! * 22^(22-1) / 22!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0001d0e76631a5b05d007b8cb72a7c7f11ec36e000; // add x^(23-1) * (34! * 23^(23-1) / 23!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x0004a1c37bd9f85fd9c6c780000000000000000000; // sub x^(24-1) * (34! * 24^(24-1) / 24!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000bd8369f1b702bf491e2ebfcee08250313b65400; // add x^(25-1) * (34! * 25^(25-1) / 25!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x001e5c7c32a9f6c70ab2cb59d9225764d400000000; // sub x^(26-1) * (34! * 26^(26-1) / 26!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x004dff5820e165e910f95120a708e742496221e600; // add x^(27-1) * (34! * 27^(27-1) / 27!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x00c8c8f66db1fced378ee50e536000000000000000; // sub x^(28-1) * (34! * 28^(28-1) / 28!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0205db8dffff45bfa2938f128f599dbf16eb11d880; // add x^(29-1) * (34! * 29^(29-1) / 29!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x053a044ebd984351493e1786af38d39a0800000000; // sub x^(30-1) * (34! * 30^(30-1) / 30!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0d86dae2a4cc0f47633a544479735869b487b59c40; // add x^(31-1) * (34! * 31^(31-1) / 31!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0x231000000000000000000000000000000000000000; // sub x^(32-1) * (34! * 32^(32-1) / 32!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x5b0485a76f6646c2039db1507cdd51b08649680822; // add x^(33-1) * (34! * 33^(33-1) / 33!)
		xi = (xi * _x) / FIXED_1;
		res -= xi * 0xec983c46c49545bc17efa6b5b0055e242200000000; // sub x^(34-1) * (34! * 34^(34-1) / 34!)

		return res / 0xde1bc4d19efcac82445da75b00000000; // divide by 34!
	}

	/**
	 * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
	 * input range: LAMBERT_CONV_RADIUS + 1 <= x <= LAMBERT_POS2_MAXVAL
	 */
	function lambertPos2(uint256 _x) internal view returns (uint256) {
		uint256 x = _x - LAMBERT_CONV_RADIUS - 1;
		uint256 i = x / LAMBERT_POS2_SAMPLE;
		uint256 a = LAMBERT_POS2_SAMPLE * i;
		uint256 b = LAMBERT_POS2_SAMPLE * (i + 1);
		uint256 c = lambertArray[i];
		uint256 d = lambertArray[i + 1];
		return (c * (b - x) + d * (x - a)) / LAMBERT_POS2_SAMPLE;
	}

	/**
	 * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
	 * input range: LAMBERT_POS2_MAXVAL + 1 <= x <= LAMBERT_POS3_MAXVAL
	 */
	function lambertPos3(uint256 _x) internal pure returns (uint256) {
		uint256 l1 = _x < OPT_LOG_MAX_VAL ? optimalLog(_x) : generalLog(_x);
		uint256 l2 = l1 < OPT_LOG_MAX_VAL ? optimalLog(l1) : generalLog(l1);
		return ((l1 - l2 + (l2 * FIXED_1) / l1) * FIXED_1) / _x;
	}

	/**
	 * @dev computes W(-x / FIXED_1) / (-x / FIXED_1) * FIXED_1
	 * input range: 1 <= x <= 1 / e * FIXED_1
	 * auto-generated via 'PrintFunctionLambertNeg1.py'
	 */
	function lambertNeg1(uint256 _x) internal pure returns (uint256) {
		uint256 xi = _x;
		uint256 res = 0;

		xi = (xi * _x) / FIXED_1;
		res += xi * 0x00000000014d29a73a6e7b02c3668c7b0880000000; // add x^(03-1) * (34! * 03^(03-1) / 03!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000000002504a0cd9a7f7215b60f9be4800000000; // add x^(04-1) * (34! * 04^(04-1) / 04!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000000000484d0a1191c0ead267967c7a4a0000000; // add x^(05-1) * (34! * 05^(05-1) / 05!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x00000000095ec580d7e8427a4baf26a90a00000000; // add x^(06-1) * (34! * 06^(06-1) / 06!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000000001440b0be1615a47dba6e5b3b1f10000000; // add x^(07-1) * (34! * 07^(07-1) / 07!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000000002d207601f46a99b4112418400000000000; // add x^(08-1) * (34! * 08^(08-1) / 08!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000000066ebaac4c37c622dd8288a7eb1b2000000; // add x^(09-1) * (34! * 09^(09-1) / 09!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x00000000ef17240135f7dbd43a1ba10cf200000000; // add x^(10-1) * (34! * 10^(10-1) / 10!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000000233c33c676a5eb2416094a87b3657000000; // add x^(11-1) * (34! * 11^(11-1) / 11!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000000541cde48bc0254bed49a9f8700000000000; // add x^(12-1) * (34! * 12^(12-1) / 12!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000000cae1fad2cdd4d4cb8d73abca0d19a400000; // add x^(13-1) * (34! * 13^(13-1) / 13!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000001edb2aa2f760d15c41ceedba956400000000; // add x^(14-1) * (34! * 14^(14-1) / 14!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000004ba8d20d2dabd386c9529659841a2e200000; // add x^(15-1) * (34! * 15^(15-1) / 15!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000000bac08546b867cdaa20000000000000000000; // add x^(16-1) * (34! * 16^(16-1) / 16!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000001cfa8e70c03625b9db76c8ebf5bbf24820000; // add x^(17-1) * (34! * 17^(17-1) / 17!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000004851d99f82060df265f3309b26f8200000000; // add x^(18-1) * (34! * 18^(18-1) / 18!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x00000b550d19b129d270c44f6f55f027723cbb0000; // add x^(19-1) * (34! * 19^(19-1) / 19!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x00001c877dadc761dc272deb65d4b0000000000000; // add x^(20-1) * (34! * 20^(20-1) / 20!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000048178ece97479f33a77f2ad22a81b64406c000; // add x^(21-1) * (34! * 21^(21-1) / 21!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0000b6ca8268b9d810fedf6695ef2f8a6c00000000; // add x^(22-1) * (34! * 22^(22-1) / 22!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0001d0e76631a5b05d007b8cb72a7c7f11ec36e000; // add x^(23-1) * (34! * 23^(23-1) / 23!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0004a1c37bd9f85fd9c6c780000000000000000000; // add x^(24-1) * (34! * 24^(24-1) / 24!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x000bd8369f1b702bf491e2ebfcee08250313b65400; // add x^(25-1) * (34! * 25^(25-1) / 25!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x001e5c7c32a9f6c70ab2cb59d9225764d400000000; // add x^(26-1) * (34! * 26^(26-1) / 26!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x004dff5820e165e910f95120a708e742496221e600; // add x^(27-1) * (34! * 27^(27-1) / 27!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x00c8c8f66db1fced378ee50e536000000000000000; // add x^(28-1) * (34! * 28^(28-1) / 28!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0205db8dffff45bfa2938f128f599dbf16eb11d880; // add x^(29-1) * (34! * 29^(29-1) / 29!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x053a044ebd984351493e1786af38d39a0800000000; // add x^(30-1) * (34! * 30^(30-1) / 30!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x0d86dae2a4cc0f47633a544479735869b487b59c40; // add x^(31-1) * (34! * 31^(31-1) / 31!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x231000000000000000000000000000000000000000; // add x^(32-1) * (34! * 32^(32-1) / 32!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0x5b0485a76f6646c2039db1507cdd51b08649680822; // add x^(33-1) * (34! * 33^(33-1) / 33!)
		xi = (xi * _x) / FIXED_1;
		res += xi * 0xec983c46c49545bc17efa6b5b0055e242200000000; // add x^(34-1) * (34! * 34^(34-1) / 34!)

		return res / 0xde1bc4d19efcac82445da75b00000000 + _x + FIXED_1; // divide by 34! and then add x^(2-1) * (34! * 2^(2-1) / 2!) + x^(1-1) * (34! * 1^(1-1) / 1!)
	}

	/**
	 * @dev computes the weights based on "W(log(hi / lo) * tq / rp) * tq / rp", where "W" is a variation of the Lambert W function.
	 */
	function balancedWeightsByStake(
		uint256 _hi,
		uint256 _lo,
		uint256 _tq,
		uint256 _rp,
		bool _lowerStake
	) internal view returns (uint32, uint32) {
		(_tq, _rp) = safeFactors(_tq, _rp);
		uint256 f = _hi.mul(FIXED_1) / _lo;
		uint256 g = f < OPT_LOG_MAX_VAL ? optimalLog(f) : generalLog(f);
		uint256 x = g.mul(_tq) / _rp;
		uint256 y = _lowerStake ? lowerStake(x) : higherStake(x);
		return normalizedWeights(y.mul(_tq), _rp.mul(FIXED_1));
	}

	/**
	 * @dev reduces "a" and "b" while maintaining their ratio.
	 */
	function safeFactors(uint256 _a, uint256 _b)
		internal
		pure
		returns (uint256, uint256)
	{
		if (_a <= FIXED_2 && _b <= FIXED_2) return (_a, _b);
		if (_a < FIXED_2) return ((_a * FIXED_2) / _b, FIXED_2);
		if (_b < FIXED_2) return (FIXED_2, (_b * FIXED_2) / _a);
		uint256 c = _a > _b ? _a : _b;
		uint256 n = floorLog2(c / FIXED_1);
		return (_a >> n, _b >> n);
	}

	/**
	 * @dev computes "MAX_WEIGHT * a / (a + b)" and "MAX_WEIGHT * b / (a + b)".
	 */
	function normalizedWeights(uint256 _a, uint256 _b)
		internal
		pure
		returns (uint32, uint32)
	{
		if (_a <= _b) return accurateWeights(_a, _b);
		(uint32 y, uint32 x) = accurateWeights(_b, _a);
		return (x, y);
	}

	/**
	 * @dev computes "MAX_WEIGHT * a / (a + b)" and "MAX_WEIGHT * b / (a + b)", assuming that "a <= b".
	 */
	function accurateWeights(uint256 _a, uint256 _b)
		internal
		pure
		returns (uint32, uint32)
	{
		if (_a > MAX_UNF_WEIGHT) {
			uint256 c = _a / (MAX_UNF_WEIGHT + 1) + 1;
			_a /= c;
			_b /= c;
		}
		uint256 x = roundDiv(_a * MAX_WEIGHT, _a.add(_b));
		uint256 y = MAX_WEIGHT - x;
		return (uint32(x), uint32(y));
	}

	/**
	 * @dev computes the nearest integer to a given quotient without overflowing or underflowing.
	 */
	function roundDiv(uint256 _n, uint256 _d) internal pure returns (uint256) {
		return _n / _d + (_n % _d) / (_d - _d / 2);
	}

	/**
	 * @dev deprecated, backward compatibility
	 */
	function calculatePurchaseReturn(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveWeight,
		uint256 _amount
	) public view returns (uint256) {
		return
			purchaseTargetAmount(
				_supply,
				_reserveBalance,
				_reserveWeight,
				_amount
			);
	}

	/**
	 * @dev deprecated, backward compatibility
	 */
	function calculateSaleReturn(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveWeight,
		uint256 _amount
	) public view returns (uint256) {
		return
			saleTargetAmount(_supply, _reserveBalance, _reserveWeight, _amount);
	}

	/**
	 * @dev deprecated, backward compatibility
	 */
	function calculateCrossReserveReturn(
		uint256 _sourceReserveBalance,
		uint32 _sourceReserveWeight,
		uint256 _targetReserveBalance,
		uint32 _targetReserveWeight,
		uint256 _amount
	) public view returns (uint256) {
		return
			crossReserveTargetAmount(
				_sourceReserveBalance,
				_sourceReserveWeight,
				_targetReserveBalance,
				_targetReserveWeight,
				_amount
			);
	}

	/**
	 * @dev deprecated, backward compatibility
	 */
	function calculateCrossConnectorReturn(
		uint256 _sourceReserveBalance,
		uint32 _sourceReserveWeight,
		uint256 _targetReserveBalance,
		uint32 _targetReserveWeight,
		uint256 _amount
	) public view returns (uint256) {
		return
			crossReserveTargetAmount(
				_sourceReserveBalance,
				_sourceReserveWeight,
				_targetReserveBalance,
				_targetReserveWeight,
				_amount
			);
	}

	/**
	 * @dev deprecated, backward compatibility
	 */
	function calculateFundCost(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveRatio,
		uint256 _amount
	) public view returns (uint256) {
		return fundCost(_supply, _reserveBalance, _reserveRatio, _amount);
	}

	/**
	 * @dev deprecated, backward compatibility
	 */
	function calculateLiquidateReturn(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveRatio,
		uint256 _amount
	) public view returns (uint256) {
		return
			liquidateReserveAmount(
				_supply,
				_reserveBalance,
				_reserveRatio,
				_amount
			);
	}

	/**
	 * @dev deprecated, backward compatibility
	 */
	function purchaseRate(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveWeight,
		uint256 _amount
	) public view returns (uint256) {
		return
			purchaseTargetAmount(
				_supply,
				_reserveBalance,
				_reserveWeight,
				_amount
			);
	}

	/**
	 * @dev deprecated, backward compatibility
	 */
	function saleRate(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveWeight,
		uint256 _amount
	) public view returns (uint256) {
		return
			saleTargetAmount(_supply, _reserveBalance, _reserveWeight, _amount);
	}

	/**
	 * @dev deprecated, backward compatibility
	 */
	function crossReserveRate(
		uint256 _sourceReserveBalance,
		uint32 _sourceReserveWeight,
		uint256 _targetReserveBalance,
		uint32 _targetReserveWeight,
		uint256 _amount
	) public view returns (uint256) {
		return
			crossReserveTargetAmount(
				_sourceReserveBalance,
				_sourceReserveWeight,
				_targetReserveBalance,
				_targetReserveWeight,
				_amount
			);
	}

	/**
	 * @dev deprecated, backward compatibility
	 */
	function liquidateRate(
		uint256 _supply,
		uint256 _reserveBalance,
		uint32 _reserveRatio,
		uint256 _amount
	) public view returns (uint256) {
		return
			liquidateReserveAmount(
				_supply,
				_reserveBalance,
				_reserveRatio,
				_amount
			);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Reputation.sol";
import "../Interfaces.sol";

/**
 * @title GReputation extends Reputation with delegation and cross blockchain merkle states
 * @dev NOTICE: this breaks DAOStack nativeReputation usage, since it is not possiible to upgrade
 * the original nativeReputation token. it means you can no longer rely on avatar.nativeReputation() or controller.nativeReputation()
 * to return the current reputation token.
 * The DAO avatar will be the owner of this reputation token and not the Controller.
 * Minting by the DAO will be done using controller.genericCall and not via controller.mintReputation
 */
contract GReputation is Reputation {
	bytes32 public constant ROOT_STATE = keccak256("rootState");

	/// @notice The EIP-712 typehash for the contract's domain
	bytes32 public constant DOMAIN_TYPEHASH =
		keccak256(
			"EIP712Domain(string name,uint256 chainId,address verifyingContract)"
		);

	/// @notice The EIP-712 typehash for the delegation struct used by the contract
	bytes32 public constant DELEGATION_TYPEHASH =
		keccak256("Delegation(address delegate,uint256 nonce,uint256 expiry)");

	/// @notice describe a single blockchain states
	/// @param stateHash the hash with the reputation state
	/// @param hashType the type of hash. currently just 0 = merkle tree root hash
	/// @param totalSupply the totalSupply at the blockchain
	/// @param blockNumber the effective blocknumber
	struct BlockchainState {
		bytes32 stateHash;
		uint256 hashType;
		uint256 totalSupply;
		uint256 blockNumber;
		uint256[5] __reserevedSpace;
	}

	/// @notice A record of states for signing / validating signatures
	mapping(address => uint256) public nonces;

	/// @notice mapping from blockchain id hash to list of states
	mapping(bytes32 => BlockchainState[]) public blockchainStates;

	/// @notice mapping from stateHash to the user balance can be >0 only after supplying state proof
	mapping(bytes32 => mapping(address => uint256)) public stateHashBalances;

	/// @notice list of blockchains having a statehash for easy iteration
	bytes32[] public activeBlockchains;

	/// @notice keep map of user -> delegate
	mapping(address => address) public delegates;

	/// @notice map of user non delegated + delegated votes to user. this is used for actual voting
	mapping(address => uint256[]) public activeVotes;

	/// @notice keep map of address -> reputation recipient, an address can set that its earned rep will go to another address
	mapping(address => address) public reputationRecipients;

	/// @notice An event thats emitted when a delegate account's vote balance changes
	event DelegateVotesChanged(
		address indexed delegate,
		address indexed delegator,
		uint256 previousBalance,
		uint256 newBalance
	);

	event StateHash(string blockchain, bytes32 merkleRoot, uint256 totalSupply);

	event StateHashProof(string blockchain, address user, uint256 repBalance);

	/**
	 * @dev initialize
	 */
	function initialize(
		INameService _ns,
		string calldata stateId,
		bytes32 stateHash,
		uint256 totalSupply
	) external initializer {
		__Reputation_init(_ns);
		if (totalSupply > 0)
			_setBlockchainStateHash(stateId, stateHash, totalSupply);
	}

	function _canMint() internal view override {
		require(
			_msgSender() == nameService.getAddress("GDAO_CLAIMERS") ||
				_msgSender() == nameService.getAddress("GDAO_STAKING") ||
				_msgSender() == nameService.getAddress("GDAO_STAKERS") ||
				hasRole(MINTER_ROLE, _msgSender()),
			"GReputation: need minter role or be GDAO contract"
		);
	}

	/// @notice internal function that overrides Reputation.sol with consideration to delegation
	/// @param _user the address to mint for
	/// @param _amount the amount of rep to mint
	/// @return the actual amount minted
	function _mint(address _user, uint256 _amount)
		internal
		override
		returns (uint256)
	{
		address repTarget = reputationRecipients[_user];
		repTarget = repTarget != address(0) ? repTarget : _user;

		super._mint(repTarget, _amount);

		//set self as initial delegator
		address delegator = delegates[repTarget];
		if (delegator == address(0)) {
			delegates[repTarget] = repTarget;
			delegator = repTarget;
		}
		uint256 previousVotes = getVotes(delegator);

		_updateDelegateVotes(
			delegator,
			repTarget,
			previousVotes,
			previousVotes + _amount
		);
		return _amount;
	}

	/// @notice internal function that overrides Reputation.sol with consideration to delegation
	/// @param _user the address to burn from
	/// @param _amount the amount of rep to mint
	/// @return the actual amount burned
	function _burn(address _user, uint256 _amount)
		internal
		override
		returns (uint256)
	{
		uint256 amountBurned = super._burn(_user, _amount);
		address delegator = delegates[_user];
		delegator = delegator != address(0) ? delegator : _user;
		delegates[_user] = delegator;
		uint256 previousVotes = getVotes(delegator);

		_updateDelegateVotes(
			delegator,
			_user,
			previousVotes,
			previousVotes - amountBurned
		);

		return amountBurned;
	}

	/// @notice sets the state hash of a blockchain, can only be called by owner
	/// @param _id the string name of the blockchain (will be hashed to produce byte32 id)
	/// @param _hash the state hash
	/// @param _totalSupply total supply of reputation on the specific blockchain
	function setBlockchainStateHash(
		string memory _id,
		bytes32 _hash,
		uint256 _totalSupply
	) public {
		_onlyAvatar();
		_setBlockchainStateHash(_id, _hash, _totalSupply);
	}

	/// @notice sets the state hash of a blockchain, can only be called by owner
	/// @param _id the string name of the blockchain (will be hashed to produce byte32 id)
	/// @param _hash the state hash
	/// @param _totalSupply total supply of reputation on the specific blockchain
	function _setBlockchainStateHash(
		string memory _id,
		bytes32 _hash,
		uint256 _totalSupply
	) internal {
		bytes32 idHash = keccak256(bytes(_id));

		//dont consider rootState as blockchain,  it is a special state hash
		bool isRootState = idHash == ROOT_STATE;
		require(
			!isRootState || super.totalSupplyAt(block.number) == 0,
			"rootState already created"
		);
		uint256 i = 0;
		for (; !isRootState && i < activeBlockchains.length; i++) {
			if (activeBlockchains[i] == idHash) break;
		}

		//if new blockchain
		if (!isRootState && i == activeBlockchains.length) {
			activeBlockchains.push(idHash);
		}

		BlockchainState memory state;
		state.stateHash = _hash;
		state.totalSupply = _totalSupply;
		state.blockNumber = block.number;
		blockchainStates[idHash].push(state);

		emit StateHash(_id, _hash, _totalSupply);
	}

	/// @notice get the number of active votes a user holds after delegation (vs the basic balance of reputation he holds)
	/// @param _user the user to get active votes for
	/// @param _global wether to include reputation from other blockchains
	/// @param _blockNumber get votes state at specific block
	/// @return the number of votes
	function getVotesAt(
		address _user,
		bool _global,
		uint256 _blockNumber
	) public view returns (uint256) {
		uint256 startingBalance = getValueAt(activeVotes[_user], _blockNumber);

		if (_global) {
			for (uint256 i = 0; i < activeBlockchains.length; i++) {
				startingBalance += getVotesAtBlockchain(
					activeBlockchains[i],
					_user,
					_blockNumber
				);
			}
		}

		return startingBalance;
	}

	/**
	 * @notice returns aggregated active votes in all blockchains and delegated
	 * @param _user the user to get active votes for
	 * @return the number of votes
	 */
	function getVotes(address _user) public view returns (uint256) {
		return getVotesAt(_user, true, block.number);
	}

	/**
	 be compatible with compound 
	 */
	function getCurrentVotes(address _user) public view returns (uint256) {
		return getVotesAt(_user, true, block.number);
	}

	function getPriorVotes(address _user, uint256 _block)
		public
		view
		returns (uint256)
	{
		return getVotesAt(_user, true, _block);
	}

	/**
	 * @notice returns aggregated active votes in all blockchains and delegated at specific block
	 * @param _user user to get active votes for
	 * @param _blockNumber get votes state at specific block
	 * @return the number of votes
	 */
	function getVotesAt(address _user, uint256 _blockNumber)
		public
		view
		returns (uint256)
	{
		return getVotesAt(_user, true, _blockNumber);
	}

	/**
	 * @notice returns total supply in current blockchain (super.balanceOfAt)
	 * @param _blockNumber get total supply at specific block
	 * @return the totaly supply
	 */
	function totalSupplyLocal(uint256 _blockNumber)
		public
		view
		returns (uint256)
	{
		return super.totalSupplyAt(_blockNumber);
	}

	/**
	 * @notice returns total supply in all blockchain aggregated
	 * @param _blockNumber get total supply at specific block
	 * @return the totaly supply
	 */
	function totalSupplyAt(uint256 _blockNumber)
		public
		view
		override
		returns (uint256)
	{
		uint256 startingSupply = super.totalSupplyAt(_blockNumber);
		for (uint256 i = 0; i < activeBlockchains.length; i++) {
			startingSupply += totalSupplyAtBlockchain(
				activeBlockchains[i],
				_blockNumber
			);
		}
		return startingSupply;
	}

	/// @notice get the number of active votes a user holds after delegation in specific blockchain
	/// @param _id the keccak hash of the blockchain string id
	/// @param _user the user to get active votes for
	/// @param _blockNumber get votes state at specific block
	/// @return the number of votes
	function getVotesAtBlockchain(
		bytes32 _id,
		address _user,
		uint256 _blockNumber
	) public view returns (uint256) {
		BlockchainState[] storage states = blockchainStates[_id];
		int256 i = int256(states.length);

		if (i == 0) return 0;
		BlockchainState storage state = states[uint256(i - 1)];
		for (i = i - 1; i >= 0; i--) {
			if (state.blockNumber <= _blockNumber) break;
			state = states[uint256(i - 1)];
		}
		if (i < 0) return 0;

		return stateHashBalances[state.stateHash][_user];
	}

	/**
	 * @notice returns total supply in a specific blockchain
	 * @param _blockNumber get total supply at specific block
	 * @return the totaly supply
	 */
	function totalSupplyAtBlockchain(bytes32 _id, uint256 _blockNumber)
		public
		view
		returns (uint256)
	{
		BlockchainState[] storage states = blockchainStates[_id];
		int256 i;
		if (states.length == 0) return 0;
		for (i = int256(states.length - 1); i >= 0; i--) {
			if (states[uint256(i)].blockNumber <= _blockNumber) break;
		}
		if (i < 0) return 0;

		BlockchainState storage state = states[uint256(i)];
		return state.totalSupply;
	}

	/**
	 * @notice prove user balance in a specific blockchain state hash
	 * @dev "rootState" is a special state that can be supplied once, and actually mints reputation on the current blockchain
	 * we use non sorted merkle tree, as sorting while preparing merkle tree is heavy
	 * @param _id the string id of the blockchain we supply proof for
	 * @param _user the user to prove his balance
	 * @param _balance the balance we are prooving
	 * @param _proof array of byte32 with proof data (currently merkle tree path)
 	 * @param _nodeIndex index of node in the tree (for unsorted merkle tree proof)

	 * @return true if proof is valid
	 */
	function proveBalanceOfAtBlockchain(
		string memory _id,
		address _user,
		uint256 _balance,
		bytes32[] memory _proof,
		uint256 _nodeIndex
	) public returns (bool) {
		bytes32 idHash = keccak256(bytes(_id));
		require(
			blockchainStates[idHash].length > 0,
			"no state found for given _id"
		);
		bytes32 stateHash = blockchainStates[idHash][
			blockchainStates[idHash].length - 1
		].stateHash;

		//this is specifically important for rootState that should update real balance only once
		require(
			stateHashBalances[stateHash][_user] == 0,
			"stateHash already proved"
		);

		bytes32 leafHash = keccak256(abi.encode(_user, _balance));
		bool isProofValid = checkProofOrdered(
			_proof,
			stateHash,
			leafHash,
			_nodeIndex
		);

		require(isProofValid, "invalid merkle proof");

		//if initiial state then set real balance
		if (idHash == ROOT_STATE) {
			_mint(_user, _balance);
		}

		//if proof is valid then set balances
		stateHashBalances[stateHash][_user] = _balance;

		emit StateHashProof(_id, _user, _balance);
		return true;
	}

	/// @notice returns current delegate of _user
	/// @param _user the delegatee
	/// @return the address of the delegate (can be _user  if no delegate or 0x0 if _user doesnt exists)
	function delegateOf(address _user) public view returns (address) {
		return delegates[_user];
	}

	/// @notice delegate votes to another user
	/// @param _delegate the recipient of votes
	function delegateTo(address _delegate) public {
		return _delegateTo(_msgSender(), _delegate);
	}

	/// @notice cancel user delegation
	/// @dev makes user his own delegate
	function undelegate() public {
		return _delegateTo(_msgSender(), _msgSender());
	}

	/**
	 * @notice Delegates votes from signatory to `delegate`
	 * @param _delegate The address to delegate votes to
	 * @param _nonce The contract state required to match the signature
	 * @param _expiry The time at which to expire the signature
	 * @param _v The recovery byte of the signature
	 * @param _r Half of the ECDSA signature pair
	 * @param _s Half of the ECDSA signature pair
	 */
	function delegateBySig(
		address _delegate,
		uint256 _nonce,
		uint256 _expiry,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) public {
		bytes32 domainSeparator = keccak256(
			abi.encode(
				DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				getChainId(),
				address(this)
			)
		);
		bytes32 structHash = keccak256(
			abi.encode(DELEGATION_TYPEHASH, _delegate, _nonce, _expiry)
		);
		bytes32 digest = keccak256(
			abi.encodePacked("\x19\x01", domainSeparator, structHash)
		);
		address signatory = ecrecover(digest, _v, _r, _s);
		require(
			signatory != address(0),
			"GReputation::delegateBySig: invalid signature"
		);
		require(
			_nonce == nonces[signatory]++,
			"GReputation::delegateBySig: invalid nonce"
		);
		require(
			block.timestamp <= _expiry,
			"GReputation::delegateBySig: signature expired"
		);
		return _delegateTo(signatory, _delegate);
	}

	/// @notice internal function to delegate votes to another user
	/// @param _user the source of votes (delegator)
	/// @param _delegate the recipient of votes
	function _delegateTo(address _user, address _delegate) internal {
		require(
			_delegate != address(0),
			"GReputation::delegate can't delegate to null address"
		);

		address curDelegator = delegates[_user];
		require(curDelegator != _delegate, "already delegating to delegator");

		delegates[_user] = _delegate;

		// remove votes from current delegator
		uint256 coreBalance = balanceOf(_user);
		//redundant check - should not be possible to have address 0 as delegator
		if (curDelegator != address(0)) {
			uint256 removeVotes = getVotesAt(curDelegator, false, block.number);
			_updateDelegateVotes(
				curDelegator,
				_user,
				removeVotes,
				removeVotes - coreBalance
			);
		}

		//move votes to new delegator
		uint256 addVotes = getVotesAt(_delegate, false, block.number);
		_updateDelegateVotes(_delegate, _user, addVotes, addVotes + coreBalance);
	}

	/// @notice internal function to update delegated votes, emits event with changes
	/// @param _delegate the delegate whose record we are updating
	/// @param _delegator the delegator
	/// @param _oldVotes the delegate previous votes
	/// @param _newVotes the delegate votes after the change
	function _updateDelegateVotes(
		address _delegate,
		address _delegator,
		uint256 _oldVotes,
		uint256 _newVotes
	) internal {
		updateValueAtNow(activeVotes[_delegate], _newVotes);
		emit DelegateVotesChanged(_delegate, _delegator, _oldVotes, _newVotes);
	}

	// from StorJ -- https://github.com/nginnever/storj-audit-verifier/blob/master/contracts/MerkleVerifyv3.sol
	/**
	 * @dev non sorted merkle tree proof check
	 */
	function checkProofOrdered(
		bytes32[] memory _proof,
		bytes32 _root,
		bytes32 _hash,
		uint256 _index
	) public pure returns (bool) {
		// use the index to determine the node ordering
		// index ranges 1 to n

		bytes32 proofElement;
		bytes32 computedHash = _hash;
		uint256 remaining;

		for (uint256 j = 0; j < _proof.length; j++) {
			proofElement = _proof[j];

			// calculate remaining elements in proof
			remaining = _proof.length - j;

			// we don't assume that the tree is padded to a power of 2
			// if the index is odd then the proof will start with a hash at a higher
			// layer, so we have to adjust the index to be the index at that layer
			while (remaining > 0 && _index % 2 == 1 && _index > 2**remaining) {
				_index = _index / 2 + 1;
			}

			if (_index % 2 == 0) {
				computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
				_index = _index / 2;
			} else {
				computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
				_index = _index / 2 + 1;
			}
		}

		return computedHash == _root;
	}

	/// @notice helper function to get current chain id
	/// @return chain id
	function getChainId() internal view returns (uint256) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}
		return chainId;
	}

	function setReputationRecipient(address _target) public {
		reputationRecipients[msg.sender] = _target;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "../Interfaces.sol";
import "../utils/DSMath.sol";

/***
 * supports accounting for multiple staking contracts to calculate GDAO rewards
 */
abstract contract MultiBaseGovernanceShareField is DSMath {
	// Total Amount of stakes
	mapping(address => uint256) totalProductivity;
	// Reward amount of the each share
	mapping(address => uint256) accAmountPerShare;
	// Amount of the rewards which minted so far
	mapping(address => uint256) public rewardsMintedSoFar;
	// Amount of the rewards with pending and minted ones together
	mapping(address => uint256) public totalRewardsAccumulated;

	// Block number of last reward calculation made
	mapping(address => uint256) public lastRewardBlock;
	// Rewards amount that will be provided each block
	mapping(address => uint256) public rewardsPerBlock;

	struct UserInfo {
		uint256 amount; // How many tokens the user has staked.
		uint256 rewardDebt; // Rewards that accounted already so should be substracted while calculating rewards of staker
		uint256 rewardEarn; // Reward earn and not minted
		uint256 rewardMinted; // rewards sent to the user
	}

	mapping(address => mapping(address => UserInfo)) public contractToUsers;

	function getChainBlocksPerMonth() public virtual returns (uint256);

	/**
	 * @dev Calculate rewards per block from monthly amount of rewards and set it
	 * @param _monthlyAmount total rewards which will distribute monthly
	 */
	function _setMonthlyRewards(address _contract, uint256 _monthlyAmount)
		internal
	{
		rewardsPerBlock[_contract] = _monthlyAmount / getChainBlocksPerMonth();
	}

	/**
	 * @dev Update reward variables of the given pool to be up-to-date.
	 * Make reward calculations according to passed blocks and updates rewards by
	 * multiplying passed blocks since last calculation with rewards per block value
	 * and add it to accumalated amount per share by dividing total productivity
	 */
	function _update(
		address _contract,
		uint256 _blockStart,
		uint256 _blockEnd
	) internal virtual {
		if (totalProductivity[_contract] == 0) {
			lastRewardBlock[_contract] = block.number;
			return;
		}

		(uint256 _lastRewardBlock, uint256 _accAmountPerShare) = _calcUpdate(
			_contract,
			_blockStart,
			_blockEnd
		);

		accAmountPerShare[_contract] = _accAmountPerShare;
		lastRewardBlock[_contract] = _lastRewardBlock;
	}

	/**
	 * @dev helper to calculate global rewards accumulated per block so far
	 * @param _contract the contract to calcualte the rewards for
	 * @param _blockStart the block from which the contract is eligble for rewards
	 * @param _blockEnd the block from which the contract is no longer eligble for rewards
	 */
	function _calcUpdate(
		address _contract,
		uint256 _blockStart,
		uint256 _blockEnd
	)
		internal
		view
		returns (uint256 _lastRewardBlock, uint256 _accAmountPerShare)
	{
		_accAmountPerShare = accAmountPerShare[_contract];
		_lastRewardBlock = lastRewardBlock[_contract];
		_lastRewardBlock = _lastRewardBlock < _blockStart &&
			block.number >= _blockStart
			? _blockStart
			: _lastRewardBlock;
		uint256 curRewardBlock = block.number > _blockEnd
			? _blockEnd
			: block.number;
		if (curRewardBlock < _blockStart || _lastRewardBlock >= _blockEnd)
			return (_lastRewardBlock, _accAmountPerShare);

		uint256 multiplier = curRewardBlock - _lastRewardBlock; // Blocks passed since last reward block
		uint256 reward = multiplier * rewardsPerBlock[_contract]; // rewardsPerBlock is in GDAO which is in 18 decimals

		_accAmountPerShare += (reward * 1e27) / totalProductivity[_contract]; // totalProductivity in 18decimals  and reward in 18 decimals so rdiv result in 27decimals
		_lastRewardBlock = curRewardBlock;
	}

	/**
	 * @dev Audit user's rewards and calculate their earned rewards based on stake_amount * accAmountPerShare
	 */
	function _audit(
		address _contract,
		address _user,
		uint256 _updatedAmount
	) internal virtual {
		UserInfo storage userInfo = contractToUsers[_contract][_user];
		if (userInfo.amount > 0) {
			uint256 pending = (userInfo.amount * accAmountPerShare[_contract]) /
				1e27 -
				userInfo.rewardDebt; // Divide 1e27(because userinfo.amount in 18 decimals and accAmountPerShare is in 27decimals) since rewardDebt in 18 decimals so we can calculate how much reward earned in that cycle
			userInfo.rewardEarn = userInfo.rewardEarn + pending; // Add user's earned rewards to user's account so it can be minted later
			totalRewardsAccumulated[_contract] =
				totalRewardsAccumulated[_contract] +
				pending;
		}
		userInfo.amount = _updatedAmount;
		userInfo.rewardDebt =
			(_updatedAmount * accAmountPerShare[_contract]) /
			1e27; // Divide to 1e27 to keep rewardDebt in 18 decimals since accAmountPerShare is in 27 decimals and amount is 18 decimals
	}

	/**
	 * @dev This function increase user's productivity and updates the global productivity.
	 * This function increase user's productivity and updates the global productivity.
	 * the users' actual share percentage will calculated by:
	 * Formula:     user_productivity / global_productivity
	 */
	function _increaseProductivity(
		address _contract,
		address _user,
		uint256 _value,
		uint256 _blockStart,
		uint256 _blockEnd
	) internal virtual returns (bool) {
		_update(_contract, _blockStart, _blockEnd);
		_audit(_contract, _user, contractToUsers[_contract][_user].amount + _value);

		totalProductivity[_contract] = totalProductivity[_contract] + _value;
		return true;
	}

	/**
	 * @dev This function will decreases user's productivity by value, and updates the global productivity
	 * it will record which block this is happenning and accumulates the area of (productivity * time)
	 */

	function _decreaseProductivity(
		address _contract,
		address _user,
		uint256 _value,
		uint256 _blockStart,
		uint256 _blockEnd
	) internal virtual returns (bool) {
		_update(_contract, _blockStart, _blockEnd);
		_audit(_contract, _user, contractToUsers[_contract][_user].amount - _value);

		totalProductivity[_contract] = totalProductivity[_contract] - _value;

		return true;
	}

	/**
	 * @dev Query user's pending reward with updated variables
	 * @param _contract the contract to calcualte the rewards for
	 * @param _blockStart the block from which the contract is eligble for rewards
	 * @param _blockEnd the block from which the contract is no longer eligble for rewards
	 * @param _user the user to calculate rewards for
	 * @return returns  amount of user's earned but not minted rewards
	 */
	function getUserPendingReward(
		address _contract,
		uint256 _blockStart,
		uint256 _blockEnd,
		address _user
	) public view returns (uint256) {
		UserInfo memory userInfo = contractToUsers[_contract][_user];
		uint256 pending = 0;
		if (totalProductivity[_contract] != 0) {
			(, uint256 _accAmountPerShare) = _calcUpdate(
				_contract,
				_blockStart,
				_blockEnd
			);

			pending = userInfo.rewardEarn;
			pending +=
				(userInfo.amount * _accAmountPerShare) /
				1e27 -
				userInfo.rewardDebt; // Divide 1e27(because userinfo.amount in 18 decimals and accAmountPerShare is in 27decimals) since rewardDebt in 18 decimals so we can calculate how much reward earned in that cycle
		}

		return pending;
	}

	/** 
    @dev Calculate earned rewards of the user and update their reward info
	* @param _contract address of the contract for accounting
    * @param _user address of the user that will be accounted
	* @param _blockStart the block from which the contract is eligble for rewards
	* @param _blockEnd the block from which the contract is no longer eligble for rewards
    * @return returns minted amount
    */

	function _issueEarnedRewards(
		address _contract,
		address _user,
		uint256 _blockStart,
		uint256 _blockEnd
	) internal returns (uint256) {
		_update(_contract, _blockStart, _blockEnd);
		_audit(_contract, _user, contractToUsers[_contract][_user].amount);
		UserInfo storage userInfo = contractToUsers[_contract][_user];
		uint256 amount = userInfo.rewardEarn;
		userInfo.rewardEarn = 0;
		userInfo.rewardMinted += amount;
		rewardsMintedSoFar[_contract] = rewardsMintedSoFar[_contract] + amount;
		return amount;
	}

	/**
	 * @return Returns how much productivity a user has and total productivity.
	 */

	function getProductivity(address _contract, address _user)
		public
		view
		virtual
		returns (uint256, uint256)
	{
		return (
			contractToUsers[_contract][_user].amount,
			totalProductivity[_contract]
		);
	}

	/**
	 * @return Returns the current gross product rate.
	 */
	function totalRewardsPerShare(address _contract)
		public
		view
		virtual
		returns (uint256)
	{
		return accAmountPerShare[_contract];
	}

	// for upgrades
	uint256[50] private _gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../utils/DAOUpgradeableContract.sol";

/**
 * based on https://github.com/daostack/infra/blob/60a79a1be02942174e21156c3c9655a7f0695dbd/contracts/Reputation.sol
 * @title Reputation system
 * @dev A DAO has Reputation System which allows peers to rate other peers in order to build trust .
 * A reputation is used to assign influence measure to a DAO'S peers.
 * Reputation is similar to regular tokens but with one crucial difference: It is non-transferable.
 * The Reputation contract maintain a map of address to reputation value.
 * It provides an only minter role functions to mint and burn reputation _to (or _from) a specific address.
 */
contract Reputation is DAOUpgradeableContract, AccessControlUpgradeable {
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

	string public name;
	string public symbol;

	uint8 public decimals; //Number of decimals of the smallest unit
	// Event indicating minting of reputation to an address.
	event Mint(address indexed _to, uint256 _amount);
	// Event indicating burning of reputation for an address.
	event Burn(address indexed _from, uint256 _amount);
	uint256 private constant ZERO_HALF_256 = 0xffffffffffffffffffffffffffffffff;

	/// @dev `Checkpoint` is the structure that attaches a block number to a
	///  given value, the block number attached is the one that last changed the
	///  value
	//Checkpoint is uint256 :
	// bits 0-127 `fromBlock` is the block number that the value was generated from
	// bits 128-255 `value` is the amount of reputation at a specific block number

	// `balances` is the map that tracks the balance of each address, in this
	//  contract when the balance changes the block number that the change
	//  occurred is also included in the map
	mapping(address => uint256[]) public balances;

	// Tracks the history of the `totalSupply` of the reputation
	uint256[] public totalSupplyHistory;

	/**
	 * @dev initialize
	 */
	function initialize(INameService _ns) public initializer {
		__Reputation_init(_ns);
	}

	function __Reputation_init(INameService _ns) internal {
		decimals = 18;
		name = "GoodDAO";
		symbol = "GOOD";
		__Context_init_unchained();
		__ERC165_init_unchained();
		__AccessControl_init_unchained();

		setDAO(_ns);
		_setupRole(DEFAULT_ADMIN_ROLE, address(avatar));
		_setupRole(MINTER_ROLE, address(avatar));
	}

	function _canMint() internal view virtual {
		require(
			hasRole(MINTER_ROLE, _msgSender()),
			"Reputation: need minter role"
		);
	}

	/// @notice Generates `_amount` reputation that are assigned to `_owner`
	/// @param _user The address that will be assigned the new reputation
	/// @param _amount The quantity of reputation generated
	/// @return True if the reputation are generated correctly
	function mint(address _user, uint256 _amount) public returns (bool) {
		_canMint();
		_mint(_user, _amount);
		return true;
	}

	function _mint(address _user, uint256 _amount)
		internal
		virtual
		returns (uint256)
	{
		uint256 curTotalSupply = totalSupply();
		uint256 previousBalanceTo = balanceOf(_user);

		updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
		updateValueAtNow(balances[_user], previousBalanceTo + _amount);
		emit Mint(_user, _amount);
		return _amount;
	}

	/// @notice Burns `_amount` reputation from `_owner`
	/// @param _user The address that will lose the reputation
	/// @param _amount The quantity of reputation to burn
	/// @return True if the reputation are burned correctly
	function burn(address _user, uint256 _amount) public returns (bool) {
		//user can burn his own rep other wise we check _canMint
		if (_user != _msgSender()) _canMint();
		_burn(_user, _amount);
		return true;
	}

	function _burn(address _user, uint256 _amount)
		internal
		virtual
		returns (uint256)
	{
		uint256 curTotalSupply = totalSupply();
		uint256 amountBurned = _amount;
		uint256 previousBalanceFrom = balanceOf(_user);
		if (previousBalanceFrom < amountBurned) {
			amountBurned = previousBalanceFrom;
		}
		updateValueAtNow(totalSupplyHistory, curTotalSupply - amountBurned);
		updateValueAtNow(balances[_user], previousBalanceFrom - amountBurned);
		emit Burn(_user, amountBurned);
		return amountBurned;
	}

	/// @dev This function makes it easy to get the total number of reputation
	/// @return The total number of reputation
	function totalSupply() public view returns (uint256) {
		return totalSupplyAt(block.number);
	}

	////////////////
	// Query balance and totalSupply in History
	////////////////
	/**
	 * @dev return the reputation amount of a given owner
	 * @param _owner an address of the owner which we want to get his reputation
	 */
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balanceOfAt(_owner, block.number);
	}

	/// @dev Queries the balance of `_owner` at a specific `_blockNumber`
	/// @param _owner The address from which the balance will be retrieved
	/// @param _blockNumber The block number when the balance is queried
	/// @return The balance at `_blockNumber`
	function balanceOfAt(address _owner, uint256 _blockNumber)
		public
		view
		virtual
		returns (uint256)
	{
		if (
			(balances[_owner].length == 0) ||
			(uint128(balances[_owner][0]) > _blockNumber)
		) {
			return 0;
			// This will return the expected balance during normal situations
		} else {
			return getValueAt(balances[_owner], _blockNumber);
		}
	}

	/// @notice Total amount of reputation at a specific `_blockNumber`.
	/// @param _blockNumber The block number when the totalSupply is queried
	/// @return The total amount of reputation at `_blockNumber`
	function totalSupplyAt(uint256 _blockNumber)
		public
		view
		virtual
		returns (uint256)
	{
		if (
			(totalSupplyHistory.length == 0) ||
			(uint128(totalSupplyHistory[0]) > _blockNumber)
		) {
			return 0;
			// This will return the expected totalSupply during normal situations
		} else {
			return getValueAt(totalSupplyHistory, _blockNumber);
		}
	}

	////////////////
	// Internal helper functions to query and set a value in a snapshot array
	////////////////
	/// @dev `getValueAt` retrieves the number of reputation at a given block number
	/// @param checkpoints The history of values being queried
	/// @param _block The block number to retrieve the value at
	/// @return The number of reputation being queried
	function getValueAt(uint256[] storage checkpoints, uint256 _block)
		internal
		view
		returns (uint256)
	{
		uint256 len = checkpoints.length;
		if (len == 0) {
			return 0;
		}
		// Shortcut for the actual value
		uint256 cur = checkpoints[len - 1];
		if (_block >= uint128(cur)) {
			return cur >> 128;
		}

		if (_block < uint128(checkpoints[0])) {
			return 0;
		}

		// Binary search of the value in the array
		uint256 min = 0;
		uint256 max = len - 1;
		while (max > min) {
			uint256 mid = (max + min + 1) / 2;
			if (uint128(checkpoints[mid]) <= _block) {
				min = mid;
			} else {
				max = mid - 1;
			}
		}
		return checkpoints[min] >> 128;
	}

	/// @dev `updateValueAtNow` used to update the `balances` map and the
	///  `totalSupplyHistory`
	/// @param checkpoints The history of data being updated
	/// @param _value The new number of reputation
	function updateValueAtNow(uint256[] storage checkpoints, uint256 _value)
		internal
	{
		require(uint128(_value) == _value, "reputation overflow"); //check value is in the 128 bits bounderies
		if (
			(checkpoints.length == 0) ||
			(uint128(checkpoints[checkpoints.length - 1]) < block.number)
		) {
			checkpoints.push(uint256(uint128(block.number)) | (_value << 128));
		} else {
			checkpoints[checkpoints.length - 1] = uint256(
				(checkpoints[checkpoints.length - 1] & uint256(ZERO_HALF_256)) |
					(_value << 128)
			);
		}
	}
}