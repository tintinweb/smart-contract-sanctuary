// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "../interfaces/ILosslessV2Pool.sol";
import "../interfaces/ILosslessV2Factory.sol";
import "../interfaces/ILosslessV2Token.sol";

import "../interfaces/IPriceOracleGetter.sol";
import "../interfaces/ILendingPoolAddressesProvider.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/IProtocolDataProvider.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/interfaces/KeeperCompatibleInterface.sol";

contract LosslessV2Pool is ILosslessV2Pool, KeeperCompatibleInterface{
	using SafeMath for uint256;

	// basic info for initializing a pool
	address public override factory;
	address public override bidToken;
	address public override principalToken;
	address public override aToken;
	address public override addressProvider;

	AggregatorV3Interface private priceFeed;

	// used for calculating share price, define the precision is 0.0001
	uint256 public constant PRECISION = 10**4;

	///@dev the actual share value is valuePerShortToken /  PRECISION (constant = 10000)
	uint256 public valuePerShortToken = PRECISION; // the value of a single share - short
	uint256 public valuePerLongToken = PRECISION; // the value of a single share - long
	uint256 public constant valuePerSponsorToken = PRECISION; // the value of sponsor share should be fixed to PRECISION

	uint256 private totalInterest;

	GameStatus public status;
	PoolTokensInfo public poolTokensInfo;
	// mapping(address => uint256) public override inPoolTimestamp;

	ILosslessV2Token private _shortToken;
	ILosslessV2Token private _longToken;
	ILosslessV2Token private _sponsorToken;

	// lock modifier
	bool private accepting = true;
	modifier lock() {
		require(accepting == true, "LosslessV2Pool: LOCKED");
		accepting = false;
		_;
		accepting = true;
	}

	modifier onlyFactory() {
		require(msg.sender == factory, "LosslessV2Factory: FACTORY ONLY");
		_;
	}

	modifier onlyAfter(uint256 _time) {
		require(block.timestamp > _time, "LosslessV2Pool: INVALID TIMESTAMP AFTER");
		_;
	}

	constructor(
		address _bidToken,
		address _principalToken,
		address _addressProvider,
		address _aggregator,
		uint256 _biddingDuration,
		uint256 _gamingDuration
	) public {
		factory = msg.sender;
		bidToken = _bidToken;
		principalToken = _principalToken;
		
		addressProvider = _addressProvider;
		aToken = _getATokenAddress(principalToken);

		priceFeed = AggregatorV3Interface(_aggregator);

		// modify status variable
		status.gameRound = 1;
		status.durationOfBidding = _biddingDuration;
		status.durationOfGame = _gamingDuration;
		status.lastUpdateTimestamp = block.timestamp;
		// status.initialPrice - unchange for now
		// status.endPrice - unchange for now
		// status.isShortLastRoundWinner - default to false
		status.isFirstRound = true;
		status.isFirstUser = true;
		status.currState = PoolStatus.FirstGame;
	}

	/**
	 * @dev initialize pool
	 **/
	function initialize(
		address shortToken_,
		address longToken_,
		address sponsorToken_
	) external override onlyFactory {
		poolTokensInfo.shortToken = shortToken_;
		poolTokensInfo.longToken = longToken_;
		poolTokensInfo.sponsorToken = sponsorToken_;

		_shortToken = ILosslessV2Token(shortToken_);
		_longToken = ILosslessV2Token(longToken_);
		_sponsorToken = ILosslessV2Token(sponsorToken_);
	}

	/**
	 * @dev only be called once, after initalize
	 **/
	function startFirstRound() external override {
		require(status.isFirstRound == true, "LosslessV2Pool: NOT FIRST ROUND!");
		require(status.currState == PoolStatus.FirstGame, "LosslessV2Pool: WRONG STATUS");
		// modify status variable
		// status.gameRound = 1;
		status.lastUpdateTimestamp = block.timestamp;
		// status.initialPrice - unchange for now
		// status.endPrice - unchange for now
		// status.isShortLastRoundWinner - unchange for now
		status.isFirstRound = false;
		// status.isFirstUser = true;
		status.currState = PoolStatus.Accepting;
	}

	/**
	 * @dev start the gaming, lock pool and transfer asset to defi lending
	 **/
	function startGame() public override lock onlyAfter(status.lastUpdateTimestamp.add(status.durationOfBidding)) {
		require(status.currState == PoolStatus.Accepting, "LosslessV2Pool: WRONG STATUS");
		require(_shortToken.totalSupply() != 0 && _longToken.totalSupply() != 0, "LosslessV2Pool: NO FUND IN POOL");
		// modify status variable
		// status.gameRound = 1;
		status.lastUpdateTimestamp = block.timestamp;
		// fisrt user can set the inital price
		if (status.isFirstUser == true) {
			status.initialPrice = _getPrice();
			status.isFirstUser = false;
		}
		// status.endPrice - unchange for now
		// status.isShortLastRoundWinner - unchange for now
		// status.isFirstRound = false;
		// status.isFirstUser = true;
		status.currState = PoolStatus.Locked;

		// transfer to aave
		_supplyToAAVE(principalToken, IERC20(principalToken).balanceOf(address(this)));
	}

	/**
	 * @dev end the gaming, redeem assets from aave and get end price
	 **/
	function endGame() public override lock onlyAfter(status.lastUpdateTimestamp.add(status.durationOfGame)) {
		require(status.currState == PoolStatus.Locked, "LosslessV2Pool: WRONG STATUS");

		// modify status variable
		status.gameRound = status.gameRound.add(1);
		status.lastUpdateTimestamp = block.timestamp;
		// status.initialPrice - unchange for now
		// status.endPrice - unchange for now
		// status.isShortLastRoundWinner - unchange for now
		// status.isFirstRound = false;
		status.isFirstUser = true;
		status.currState = PoolStatus.Accepting;

		// redeem from AAVE
		_redeemFromAAVE(principalToken, 0); // redeem all
		// get end price
		status.endPrice = _getPrice();

		// if end price higher than inital price -> long users win !
		if (status.endPrice >= status.initialPrice) {
			status.isShortLastRoundWinner = false;
		} else {
			status.isShortLastRoundWinner = true;
		}

		// update interest and principal amount
		uint256 totalShortPrincipal = _shortToken.totalSupply().mul(valuePerShortToken).div(PRECISION);
		uint256 totalLongPrincipal = _longToken.totalSupply().mul(valuePerLongToken).div(PRECISION);
		uint256 totalSponsorPrincipal = _sponsorToken.totalSupply().mul(valuePerSponsorToken).div(PRECISION);
		uint256 totalPrincipal = totalShortPrincipal.add(totalLongPrincipal.add(totalSponsorPrincipal));
		if (IERC20(principalToken).balanceOf(address(this)) < totalPrincipal) {
			totalInterest = 0;	// in case kovan testnet give us aToken slightly less than deposit amount
		} else {
			totalInterest = IERC20(principalToken).balanceOf(address(this)).sub(totalPrincipal);
		}
		

		// update share value
		_updateTokenValue(totalShortPrincipal, totalLongPrincipal);

		emit AnnounceWinner(status.isShortLastRoundWinner, status.initialPrice, status.endPrice);
	}

	/**
	 * @dev chainlink keeper checkUpkeep function to constantly check whether we need function call
	 **/
	function checkUpkeep(bytes calldata checkData) external override returns (bool upkeepNeeded, bytes memory performData) {
		PoolStatus currState = status.currState;
		uint256 lastUpdateTimestamp = status.lastUpdateTimestamp;
		uint256 durationOfGame = status.durationOfGame;
		uint256 durationOfBidding = status.durationOfBidding;

		if (currState == PoolStatus.Accepting && block.timestamp > lastUpdateTimestamp.add(durationOfBidding)) {
			upkeepNeeded = true;
		}
		else if (currState == PoolStatus.Locked && block.timestamp > lastUpdateTimestamp.add(durationOfGame)) {
			upkeepNeeded = true;
		}
		else {
			upkeepNeeded = false;
		}
		performData = checkData;
	}

	/**
	 * @dev once checkUpKeep been trigered, keeper will call performUpKeep
	 **/
	function performUpkeep(bytes calldata performData) external override {
		PoolStatus currState = status.currState;
		uint256 lastUpdateTimestamp = status.lastUpdateTimestamp;
		uint256 durationOfGame = status.durationOfGame;
		uint256 durationOfBidding = status.durationOfBidding;

		if (currState == PoolStatus.Accepting && block.timestamp > lastUpdateTimestamp.add(durationOfBidding)) {
			startGame();
		}
		if (currState == PoolStatus.Locked && block.timestamp > lastUpdateTimestamp.add(durationOfGame)) {
			endGame();
		}
		performData;
	}

	/**
	 * @dev termination function, use this to terminate the game
	 **/
	function poolTermination() external override onlyFactory {
		// only when pool status is at Accepting
		require(status.currState == PoolStatus.Accepting, "LosslessV2Pool: WRONG STATUS");

		// modify status variable
		// status.gameRound = status.gameRound.add(1);
		// status.durationOfGame = 6 days;
		// status.durationOfBidding = 1 days;
		// status.lastUpdateTimestamp = block.timestamp;
		// status.initialPrice - unchange for now
		// status.endPrice - unchange for now
		// status.isShortLastRoundWinner - unchange for now
		// status.isFirstRound = false;
		// status.isFirstUser = true;
		status.currState = PoolStatus.Terminated;
	}

	/**
	 * @dev users can add principal as long as the status is accpeting
	 * @param shortPrincipalAmount how many principal in short pool does user want to deposit
	 * @param longPrincipalAmount how many principal in long pool does user want to deposit
	 **/
	function deposit(uint256 shortPrincipalAmount, uint256 longPrincipalAmount) external override lock {
		require(status.currState == PoolStatus.Accepting, "LosslessV2Pool: WRONG STATUS");
		require(shortPrincipalAmount > 0 || longPrincipalAmount > 0, "LosslessV2Pool: INVALID AMOUNT");

		// fisrt user can set the inital price
		if (status.isFirstUser == true) {
			status.initialPrice = _getPrice();
			status.isFirstUser = false;
		}
		// // if user's balance is zero record user's join timestamp for reward
		// if (_shortToken.balanceOf(msg.sender) == 0 && _longToken.balanceOf(msg.sender) == 0) {
		// 	inPoolTimestamp[msg.sender] = block.timestamp;
		// }
		// transfer principal to pool contract
		SafeERC20.safeTransferFrom(IERC20(principalToken), msg.sender, address(this), shortPrincipalAmount.add(longPrincipalAmount));
		_mintTokens(true, msg.sender, shortPrincipalAmount, longPrincipalAmount);

		emit Deposit(shortPrincipalAmount, longPrincipalAmount);
	}

	/**
	 * @dev user can call it to redeem pool tokens to principal tokens
	 * @param shortTokenAmount 	how many short token in short pool does user want to redeem
	 * @param longTokenAmount 	how many long token in long pool does user want to redeem
	 **/
	function withdraw(
		bool isAToken,
		uint256 shortTokenAmount,
		uint256 longTokenAmount
	) external override lock {
		// withdraw should have no limitation in pool status
		require(shortTokenAmount > 0 || longTokenAmount > 0, "LosslessV2Pool: INVALID AMOUNT");

		// check user token balance
		uint256 userShortTokenBalance = _shortToken.balanceOf(msg.sender);
		uint256 userLongTokenBalance = _longToken.balanceOf(msg.sender);
		require(userShortTokenBalance >= shortTokenAmount && userLongTokenBalance >= longTokenAmount, "LosslessV2Pool: INSUFFICIENT BALANCE");

		// calculate withdraw principal amount
		uint256 shortPrincipalAmount = shortTokenAmount.mul(valuePerShortToken).div(PRECISION);
		uint256 longPrincipalAmount = longTokenAmount.mul(valuePerLongToken).div(PRECISION);

		// user withdraw will cause timestamp update -> reduce their goverance reward
		// inPoolTimestamp[msg.sender] = block.timestamp;

		// burn user withdraw token
		_burnTokens(false, msg.sender, shortTokenAmount, longTokenAmount);

		/*  pool status | isAToken | Operation
				lock	     T       transfer aToken
				lock 		 F		 redeem then transfer principal Token
			  unlock  		 T 		 supply to aave then transfer aToken
			  unlock         F       transfer principal token
		 */
		if (isAToken == false) {
			if (status.currState == PoolStatus.Locked) {
				_redeemFromAAVE(principalToken, shortPrincipalAmount.add(longPrincipalAmount));
			}
			SafeERC20.safeTransfer(IERC20(principalToken), msg.sender, shortPrincipalAmount.add(longPrincipalAmount));
		} else {
			if (status.currState == PoolStatus.Accepting) {
				_supplyToAAVE(principalToken, shortPrincipalAmount.add(longPrincipalAmount));
			}
			SafeERC20.safeTransfer(IERC20(aToken), msg.sender, shortPrincipalAmount.add(longPrincipalAmount));
		}

		emit Withdraw(isAToken, shortTokenAmount, longTokenAmount);
	}

	/**
	 * @dev user can call this to shift share from long -> short, short -> long without withdrawing assets
	 * @param fromLongToShort is user choosing to shift from long to short
	 * @param swapTokenAmount the amount of token that user wishes to swap
	 **/
	function swap(bool fromLongToShort, uint256 swapTokenAmount) external override lock {
		require(status.currState == PoolStatus.Accepting, "LosslessV2Pool: WRONG STATUS");
		uint256 shortTokenBalance = _shortToken.balanceOf(msg.sender);
		uint256 longTokenBalance = _longToken.balanceOf(msg.sender);
		uint256 tokenBalanceOfTargetPosition = fromLongToShort ? longTokenBalance : shortTokenBalance;
		// check user balance
		require(swapTokenAmount > 0 && swapTokenAmount <= tokenBalanceOfTargetPosition, "LosslessV2Pool: INSUFFICIENT BALANCE");

		// reallocate user's share balance
		if (fromLongToShort == true) {
			// user wants to shift from long to short, so burn long share and increase short share
			_burnTokens(false, msg.sender, 0, swapTokenAmount);
			_mintTokens(false, msg.sender, swapTokenAmount.mul(valuePerLongToken).div(valuePerShortToken), 0);
		} else {
			// user wants to shift from short to long, so burn short share and increase long share
			_burnTokens(false, msg.sender, swapTokenAmount, 0);
			_mintTokens(false, msg.sender, 0, swapTokenAmount.mul(valuePerShortToken).div(valuePerLongToken));
		}
	}

	/**
	 * @dev sponsr can deposit and withdraw principals to the game
	 * @param principalAmount amount of principal token
	 **/
	function sponsorDeposit(uint256 principalAmount) external override lock {
		require(status.currState != PoolStatus.Terminated, "LosslessV2Pool: POOL TERMINATED");
		require(principalAmount > 0, "LosslessV2Pool: INVALID AMOUNT");
		require(IERC20(principalToken).balanceOf(msg.sender) >= principalAmount, "LosslessV2Pool: INSUFFICIENT BALANCE");

		// transfer asset first
		SafeERC20.safeTransferFrom(IERC20(principalToken), msg.sender, address(this), principalAmount);

		// check current game state
		if (status.currState == PoolStatus.Locked) {
			// if during the lock time
			// interact with AAVE to get the principal back
			_supplyToAAVE(principalToken, principalAmount);
		}

		// mint sponsor token
		_sponsorToken.mint(msg.sender, principalAmount);

		emit SponsorDeposit(principalAmount);
	}

	/**
	 * @dev sponsr can deposit and withdraw principals to the game
	 * @param sponsorTokenAmount amount of zero token
	 **/
	function sponsorWithdraw(uint256 sponsorTokenAmount) external override lock {
		require(sponsorTokenAmount > 0, "LosslessV2Pool: INVALID AMOUNT");
		// burn user sponsor token
		_sponsorToken.burn(msg.sender, sponsorTokenAmount);

		// check current game state
		if (status.currState == PoolStatus.Locked) {
			// if during the lock time
			// interact with AAVE to get the principal back
			_redeemFromAAVE(principalToken, sponsorTokenAmount);
		}

		// transfer principal token
		SafeERC20.safeTransfer(IERC20(principalToken), msg.sender, sponsorTokenAmount);

		emit SponsorWithdraw(sponsorTokenAmount);
	}

	/**
	 * @dev calculate each token's value
	 * @param _totalShortPrincipal 	the total amount of short principal
	 * @param _totalLongPrincipal	the total amount of long principal
	 **/
	function _updateTokenValue(uint256 _totalShortPrincipal, uint256 _totalLongPrincipal) private {
		address feeTo = ILosslessV2Factory(factory).feeTo();
		uint256 feePercent = ILosslessV2Factory(factory).feePercent();
		uint256 fee = totalInterest.mul(feePercent).div(PRECISION);

		// if fee is on and feeTo been set
		if (feePercent != 0 && feeTo != address(0)) {
			totalInterest = totalInterest.sub(fee);
			SafeERC20.safeTransfer(IERC20(principalToken), feeTo, fee);
		}

		// update short/long token value
		if (status.isShortLastRoundWinner == true) {
			// short win
			_totalShortPrincipal = _totalShortPrincipal.add(totalInterest);
			valuePerShortToken = _totalShortPrincipal.mul(PRECISION).div(_shortToken.totalSupply());
		} else if (status.isShortLastRoundWinner == false) {
			// long win
			_totalLongPrincipal = _totalLongPrincipal.add(totalInterest);
			valuePerLongToken = _totalLongPrincipal.mul(PRECISION).div(_longToken.totalSupply());
		}

		emit UpdateTokenValue(valuePerShortToken, valuePerLongToken);
	}

	/**
	 * @dev supply to aave protocol
	 * @param _asset 	the address of the principal token
	 * @param _amount	the amount of the principal token wish to supply to AAVE
	 **/
	function _supplyToAAVE(address _asset, uint256 _amount) private {
		address lendingPoolAddress = ILendingPoolAddressesProvider(addressProvider).getLendingPool();
		ILendingPool lendingPool = ILendingPool(lendingPoolAddress);
		SafeERC20.safeApprove(IERC20(_asset), address(lendingPool), _amount);
		lendingPool.deposit(_asset, _amount, address(this), 0);
	}

	/**
	 * @dev redeem from aave protocol
	 * @param _asset 	the address of the principal token
	 * @param _amount	the amount of the principal token wish to withdraw from AAVE
	 **/
	function _redeemFromAAVE(address _asset, uint256 _amount) private {
		// lendingPool
		address lendingPoolAddress = ILendingPoolAddressesProvider(addressProvider).getLendingPool();
		ILendingPool lendingPool = ILendingPool(lendingPoolAddress);
		// protocol data provider
		aToken = _getATokenAddress(_asset);
		if (_amount == 0) {
			_amount = IERC20(aToken).balanceOf(address(this));
		}
		lendingPool.withdraw(_asset, _amount, address(this));
	}

	/**
	 * @dev get atoken address
	 * @param _asset 	the address of the principal token
	 **/
	function _getATokenAddress(address _asset) private view returns (address _aToken) {
		// protocol data provider
		uint8 number = 1;
		bytes32 id = bytes32(bytes1(number));
		address dataProviderAddress = ILendingPoolAddressesProvider(addressProvider).getAddress(id);
		IProtocolDataProvider protocolDataProvider = IProtocolDataProvider(dataProviderAddress);
		(_aToken, , ) = protocolDataProvider.getReserveTokensAddresses(_asset);
	}

	/**
	 * @dev mint token function to mint long and short token
	 * @param _isPrincipal 	true: principal, false:long/short token amount
	 * @param _to			the destination account token got burned
	 * @param _shortAmount 	the amount of the token to short
	 * @param _longAmount 	the amount of the token to long
	 **/
	function _mintTokens(
		bool _isPrincipal,
		address _to,
		uint256 _shortAmount,
		uint256 _longAmount
	) private {
		if (_isPrincipal == true) {
			// convert principal token amount to long/short token amount
			_shortAmount = _shortAmount.mul(PRECISION).div(valuePerShortToken);
			_longAmount = _longAmount.mul(PRECISION).div(valuePerLongToken);
		}
		if (_shortAmount != 0) {
			_shortToken.mint(_to, _shortAmount);
		}
		if (_longAmount != 0) {
			_longToken.mint(_to, _longAmount);
		}
	}

	/**
	 * @dev burn token function to burn long and short token
	 * @param _isPrincipal 	true: principal, false:long/short token amount
	 * @param _from			the destination account token got burned
	 * @param _shortAmount 	the amount of the token to short
	 * @param _longAmount 	the amount of the token to long
	 **/
	function _burnTokens(
		bool _isPrincipal,
		address _from,
		uint256 _shortAmount,
		uint256 _longAmount
	) private {
		if (_isPrincipal == true) {
			// convert principal token amount to long/short token amount
			_shortAmount = _shortAmount.mul(PRECISION).div(valuePerShortToken);
			_longAmount = _longAmount.mul(PRECISION).div(valuePerLongToken);
		}
		if (_shortAmount != 0) {
			_shortToken.burn(_from, _shortAmount);
		}
		if (_longAmount != 0) {
			_longToken.burn(_from, _longAmount);
		}
	}

	/**
	 * @dev communicate with oracle to get current trusted price
	 * @return price ratio of bidToken * PRECISION / principalToken -> the result comes with precision
	 **/
	function _getPrice() private view returns (int256) {
		(uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
		return price;
	}

	/**
	 * @dev return user's long token equivalent principal token amount
	 **/
	function userLongPrincipalBalance() external view override returns (uint256 userLongAmount) {
		userLongAmount = _longToken.balanceOf(msg.sender).mul(valuePerLongToken).div(PRECISION);
	}

	/**
	 * @dev return user's short token equivalent principal token amount
	 **/
	function userShortPrincipalBalance() external view override returns (uint256 userShortAmount) {
		userShortAmount = _shortToken.balanceOf(msg.sender).mul(valuePerShortToken).div(PRECISION);
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface ILosslessV2Pool {
	// defined and controls all game logic related variables
	struct GameStatus {
		bool isShortLastRoundWinner; // record whether last round winner
		bool isFirstUser; // check if the user is the first one to enter the game or not
		bool isFirstRound; // is this game the first round of the entire pool?
		uint256 gameRound; // count for showing current game round
		uint256 durationOfGame; // which should be 6 days in default
		uint256 durationOfBidding; // which should be 1 days in default
		uint256 lastUpdateTimestamp; // the timestamp when last game logic function been called
		int256 initialPrice; // game initial price
		int256 endPrice; // game end price
		PoolStatus currState; // current pool status
	}

	// token info for current pool
	struct PoolTokensInfo {
		address longToken;
		address shortToken;
		address sponsorToken;
	}

	// # ENUM FOR POOL STATUS
	/*  
      PoolStatus Explaination
      *****
        Locked ------ game period. interacting with compound
        Accepting --- users can adding or reducing the bet
        FirstGame --- only been used for the first round
		Terminated -- only when special cases admin decided to close the pool

      Notation
      ******
        /name/ - status name
        [name] - function call name

      Workflow
      *******  

                                    
                     /Accepting/            /Locked/         /Accepting/				/Terminated/
                          |                     |                | 							 |
    [startFirstRound] ---------> [startGame] -------> [endGame] ---> [poolTermination] --------------->
                                      ^                    | |
                                      |                    | record time
                                       --------------------
                                                 |
                                            /Accepting/
    */
	enum PoolStatus { FirstGame, Locked, Accepting, Terminated }

	// ## DEFINE USER OPERATION EVENTS
	event Deposit			(uint256 shortPrincipalAmount, uint256 longPrincipalAmount);
	event Withdraw			(bool isAToken, uint256 shortTokenAmount, uint256 longTokenAmount);
	event SponsorDeposit	(uint256 principalAmount);
	event SponsorWithdraw	(uint256 sponsorTokenAmount);
	// ## DEFINE GAME OPERATION EVENTS
	event UpdateTokenValue	(uint256 valuePerShortToken, uint256 valuePerLongToken);
	event AnnounceWinner	(bool isShortLastRoundWinner, int256 initialPrice, int256 endPrice);

	// ## PUBLIC VARIABLES
	function factory() external view returns (address);
	function bidToken() external view returns (address);
	function principalToken() external view returns (address);
	function aToken() external view returns (address);
	function addressProvider() external view returns (address);

	// ### GAME SETTING VARIABLES
	// function inPoolTimestamp(address userAddress) external view returns (uint256);

	// ## STATE-CHANGING FUNCTION
	/* 
		initialize: 		initialize the game
		startFirstRound: 	start the frist round logic
		startGame: 			start game -> pool lock supply principal to AAVE, get start game price
		endGame: 			end game -> pool unlock redeem fund to AAVE, get end game price
		poolTermination:	terminate the pool, no more game, but user can still withdraw fund
    */
	function initialize(
		address shortToken_,
		address longToken_,
		address sponsorToken_
	) external;

	function startFirstRound() external; // only be called to start the first Round
	function startGame() external; // called after bidding duration
	function endGame() external; // called after game duraion

	///@dev admin only
	function poolTermination() external; // called after selectWinner only by admin

	// user actions in below, join game, add, reduce or withDraw all fund
	/* 
		deposit: 			adding funds can be either just long or short or both
		withdraw: 			reduce funds can be either just long or short or both
		swap: 				change amount of tokens from long -> short / short -> long
		sponsorDeposit:		deposit principal to the pool as interest sponsor
		sponsorWithdraw:	withdraw sponsor donation from the pool
    */
	function deposit(uint256 shortPrincipalAmount, uint256 longPrincipalAmount) external;
	function withdraw(bool isAToken, uint256 shortTokenAmount, uint256 longTokenAmount) external;
	function swap(bool fromLongToShort, uint256 swapTokenAmount) external;
	
	function sponsorDeposit(uint256 principalAmount) external;
	function sponsorWithdraw(uint256 sponsorTokenAmount) external;

	// view functions to return user balance
	function userLongPrincipalBalance() external view returns (uint256);
	function userShortPrincipalBalance() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface ILosslessV2Factory {
	// event related
	event PoolCreated(address indexed bidToken, address indexed principalToken, address pool, uint256 allPoolLength);
	event PoolTerminated(address pool);
	event FeeToChanged(address feeTo);
	event FeePercentChanged(uint256 feePercent);
	event FeeToSetterChanged(address feeToSetter);

	function allPools(uint256) external view returns (address pool);
	function allPoolsLength() external view returns (uint256);
	function getPool(address bidToken, address principalToken) external view returns (address pool);
	function isPoolActive(address) external view returns (bool);

	function getPoolShortToken(address) external view returns (address);
	function getPoolLongToken(address) external view returns (address);
	function getPoolSponsorToken(address) external view returns (address);

	function createPool(
		address bidToken,
		address principalToken,
		address addressProvider,
		address aggregator,
		uint256 biddingDuration,
		uint256 gamingDuration,
		string memory tokenName,
		string memory tokenSymbol
	) external;

	// all fee related getter functions
	function feeTo() external view returns (address);
	function feeToSetter() external view returns (address);
	function feePercent() external view returns (uint256);

	// only admin functions
	// The default FeeToSetter is admin but admin can assign this role to others by calling `setFeeToSetter`
	function setFeeTo(address) external;
	function setFeePercent(uint256 _feePercent) external;
	function setFeeToSetter(address _feeToSetter) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILosslessV2Token is IERC20{
    function mint (address to, uint256 amount) external returns (bool);
    function burn (address from, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IPriceOracleGetter {
	function getAssetPrice(address _asset) external view returns (uint256);

	function getAssetsPrices(address[] calldata _assets) external view returns (uint256[] memory);

	function getSourceOfAsset(address _asset) external view returns (address);

	function getFallbackOracle() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {DataTypes} from '../core/libraries/DataTypes.sol';

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

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
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { ILendingPoolAddressesProvider } from "./ILendingPoolAddressesProvider.sol";

interface IProtocolDataProvider {
	struct TokenData {
		string symbol;
		address tokenAddress;
	}

	function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

	function getAllReservesTokens() external view returns (TokenData[] memory);

	function getAllATokens() external view returns (TokenData[] memory);

	function getReserveConfigurationData(address asset)
		external
		view
		returns (
			uint256 decimals,
			uint256 ltv,
			uint256 liquidationThreshold,
			uint256 liquidationBonus,
			uint256 reserveFactor,
			bool usageAsCollateralEnabled,
			bool borrowingEnabled,
			bool stableBorrowRateEnabled,
			bool isActive,
			bool isFrozen
		);

	function getReserveData(address asset)
		external
		view
		returns (
			uint256 availableLiquidity,
			uint256 totalStableDebt,
			uint256 totalVariableDebt,
			uint256 liquidityRate,
			uint256 variableBorrowRate,
			uint256 stableBorrowRate,
			uint256 averageStableBorrowRate,
			uint256 liquidityIndex,
			uint256 variableBorrowIndex,
			uint40 lastUpdateTimestamp
		);

	function getUserReserveData(address asset, address user)
		external
		view
		returns (
			uint256 currentATokenBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableBorrowRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool usageAsCollateralEnabled
		);

	function getReserveTokensAddresses(address asset)
		external
		view
		returns (
			address aTokenAddress,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		);
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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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
pragma solidity ^0.6.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

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

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

