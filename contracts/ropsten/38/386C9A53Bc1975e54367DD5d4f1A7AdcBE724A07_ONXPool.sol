// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./libraries/TransferHelper.sol";
import "./libraries/SafeMath.sol";
import "./modules/Configable.sol";
import "./modules/ConfigNames.sol";
import "./modules/BaseMintField.sol";
import "./libraries/Configurable.sol";

interface IONXStrategy {
	function invest(address user, uint256 amount) external;
	function withdraw(address user, uint256 amount) external;
	function liquidation(address user) external;
	function claim(address user, uint256 amount, uint256 total) external;
	function query() external view returns (uint256);
	function mint() external;
	function interestToken() external view returns (address);
	function farmToken() external view returns (address);
}

contract ONXPool is BaseMintField, Configurable {
	using SafeMath for uint256;

	address public factory;
	address public supplyToken;
	address public collateralToken;

	// SupplyStruct
	bytes32 constant _amountSupply_SS = "SS#amountSupply";
	bytes32 constant _interestSettled_SS = "SS#interestSettled";
	bytes32 constant _liquidationSettled_SS = "SS#liquidationSettled";
	bytes32 constant _interests_SS = "SS#interests";
	bytes32 constant _liquidation_SS = "SS#liquidation";

	// BorrowStruct
	bytes32 constant _index_BS = "BS#index";
	bytes32 constant _amountCollateral_BS = "BS#amountCollateral";
	bytes32 constant _interestSettled_BS = "BS#interestSettled";
	bytes32 constant _amountBorrow_BS = "BS#amountBorrow";
	bytes32 constant _interests_BS = "BS#interests";

	// LiquidationStruct
	bytes32 constant _amountCollateral_LS = "LS#amountCollateral";
	bytes32 constant _liquidationAmount_LS = "LS#liquidationAmount";
	bytes32 constant _timestamp_LS = "LS#timestamp";
	bytes32 constant _length_LS = "LS#length";

	address[] public borrowerList;
	uint256 public numberBorrowers;

	mapping(address => uint256) public liquidationHistoryLength;

	uint256 public interestPerSupply;
	uint256 public liquidationPerSupply;
	uint256 public interestPerBorrow;

	uint256 public totalLiquidation;
	uint256 public totalLiquidationSupplyAmount;

	uint256 public totalStake;
	uint256 public totalBorrow;
	uint256 public totalPledge;

	uint256 public remainSupply;

	uint256 public lastInterestUpdate;

	address public collateralStrategy;
	address public supplyStrategy;

	uint256 public payoutRatio;

	event Deposit(address indexed _user, uint256 _amount, uint256 _collateralAmount);
	event Withdraw(address indexed _user, uint256 _supplyAmount, uint256 _collateralAmount, uint256 _interestAmount);
	event Borrow(address indexed _user, uint256 _supplyAmount, uint256 _collateralAmount);
	event Repay(address indexed _user, uint256 _supplyAmount, uint256 _collateralAmount, uint256 _interestAmount);
	event Liquidation(
		address indexed _liquidator,
		address indexed _user,
		uint256 _supplyAmount,
		uint256 _collateralAmount
	);
	event Reinvest(address indexed _user, uint256 _reinvestAmount);

	function initialize(address _factory) external initializer
	{
		owner = _factory;
		factory = _factory;
	}

	function setCollateralStrategy(address _collateralStrategy, address _supplyStrategy) external onlyPlatform
	{
		collateralStrategy = _collateralStrategy;
		supplyStrategy = _supplyStrategy;
	}

	function init(address _supplyToken, address _collateralToken) external onlyFactory {
		supplyToken = _supplyToken;
		collateralToken = _collateralToken;

		lastInterestUpdate = block.number;
	}

	function updateInterests(bool isPayout) internal {
		uint256 totalSupply = totalBorrow + remainSupply;
		(uint256 supplyInterestPerBlock, uint256 borrowInterestPerBlock) = getInterests();

		interestPerSupply = interestPerSupply.add(
			totalSupply == 0
			? 0
			: supplyInterestPerBlock.mul(block.number - lastInterestUpdate).mul(totalBorrow).div(totalSupply)
		);
		interestPerBorrow = interestPerBorrow.add(borrowInterestPerBlock.mul(block.number - lastInterestUpdate));
		lastInterestUpdate = block.number;

		if (isPayout == true) {
			payoutRatio = borrowInterestPerBlock == 0
				? 0
				: (borrowInterestPerBlock.sub(supplyInterestPerBlock)).mul(1e18).div(borrowInterestPerBlock);
		}
	}

	function getInterests() public view returns (uint256 supplyInterestPerBlock, uint256 borrowInterestPerBlock) {
		uint256 totalSupply = totalBorrow + remainSupply;
		uint256 baseInterests = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_BASE_INTERESTS);
		uint256 marketFrenzy = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MARKET_FRENZY);
		uint256 aDay = IConfig(config).DAY();
		borrowInterestPerBlock = totalSupply == 0
		? 0
		: baseInterests.add(totalBorrow.mul(marketFrenzy).div(totalSupply)).div(365 * aDay);

		if (supplyToken == IConfig(config).WETH()) {
			baseInterests = 0;
		}
		
		supplyInterestPerBlock = totalSupply == 0
		? 0
		: baseInterests.add(totalBorrow.mul(marketFrenzy).div(totalSupply)).div(365 * aDay);
	}

	function updateLiquidation(uint256 _liquidation) internal {
		uint256 totalSupply = totalBorrow + remainSupply;
		liquidationPerSupply = liquidationPerSupply.add(totalSupply == 0 ? 0 : _liquidation.mul(1e18).div(totalSupply));
	}

	function deposit(uint256 amountDeposit, address from) public onlyPlatform {
		require(amountDeposit > 0, "ONX: INVALID AMOUNT");
		uint256 amountIn = IERC20(supplyToken).balanceOf(address(this)).sub(remainSupply);
		require(amountIn >= amountDeposit, "ONX: INVALID AMOUNT");

		updateInterests(false);

		uint256 addLiquidation =
		liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_liquidationSettled_SS, from));

		_setConfig(_interests_SS, from, getConfig(_interests_SS, from).add(
				interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_interestSettled_SS, from))
			));

		_setConfig(_liquidation_SS, from, getConfig(_liquidation_SS, from).add(addLiquidation));

		_setConfig(_amountSupply_SS, from, getConfig(_amountSupply_SS, from).add(amountDeposit));
		remainSupply = remainSupply.add(amountDeposit);

		totalStake = totalStake.add(amountDeposit);

		if(supplyStrategy != address(0) &&
			address(IERC20(IONXStrategy(supplyStrategy).farmToken())) != address(0) &&
			amountDeposit > 0)
		{
			IERC20(IONXStrategy(supplyStrategy).farmToken()).approve(supplyStrategy, amountDeposit);
			IONXStrategy(supplyStrategy).invest(from, amountDeposit);
		}

		_increaseLenderProductivity(from, amountDeposit);

		_setConfig(_interestSettled_SS, from, interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));
		_setConfig(_liquidationSettled_SS, from, liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));
		emit Deposit(from, amountDeposit, addLiquidation);
	}

	function reinvest(address from) public onlyPlatform returns (uint256 reinvestAmount) {
		updateInterests(false);

		uint256 addLiquidation =
		liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_liquidationSettled_SS, from));

		_setConfig(_interests_SS, from, getConfig(_interests_SS, from).add(
				interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_interestSettled_SS, from))
			));

		_setConfig(_liquidation_SS, from, getConfig(_liquidation_SS, from).add(addLiquidation));

		reinvestAmount = getConfig(_interests_SS, from);

		_setConfig(_amountSupply_SS, from, getConfig(_amountSupply_SS, from).add(reinvestAmount));

		totalStake = totalStake.add(reinvestAmount);

		_setConfig(_interests_SS, from, 0);

		_setConfig(_interestSettled_SS, from, getConfig(_amountSupply_SS, from) == 0
			? 0
			: interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));

		_setConfig(_liquidationSettled_SS, from, getConfig(_amountSupply_SS, from) == 0
			? 0
			: liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));

		if (reinvestAmount > 0) {
			_increaseLenderProductivity(from, reinvestAmount);
		}

		emit Reinvest(from, reinvestAmount);
	}

	function withdraw(uint256 amountWithdraw, address from)
	public
	onlyPlatform
	returns (uint256 withdrawSupplyAmount, uint256 withdrawLiquidation)
	{
		require(amountWithdraw > 0, "ONX: INVALID AMOUNT TO WITHDRAW");
		require(amountWithdraw <= getConfig(_amountSupply_SS, from), "ONX: NOT ENOUGH BALANCE");

		updateInterests(false);

		uint256 addLiquidation =
		liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_liquidationSettled_SS, from));

		_setConfig(_interests_SS, from, getConfig(_interests_SS, from).add(
				interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_interestSettled_SS, from))
			));

		_setConfig(_liquidation_SS, from, getConfig(_liquidation_SS, from).add(addLiquidation));

		withdrawLiquidation = getConfig(_liquidation_SS, from).mul(amountWithdraw).div(getConfig(_amountSupply_SS, from));
		uint256 withdrawInterest = getConfig(_interests_SS, from).mul(amountWithdraw).div(getConfig(_amountSupply_SS, from));

		uint256 withdrawLiquidationSupplyAmount =
		totalLiquidation == 0 ? 0 : withdrawLiquidation.mul(totalLiquidationSupplyAmount).div(totalLiquidation);

		if (withdrawLiquidationSupplyAmount < amountWithdraw.add(withdrawInterest))
			withdrawSupplyAmount = amountWithdraw.add(withdrawInterest).sub(withdrawLiquidationSupplyAmount);

		require(withdrawSupplyAmount <= remainSupply, "ONX: NOT ENOUGH POOL BALANCE");
		require(withdrawLiquidation <= totalLiquidation, "ONX: NOT ENOUGH LIQUIDATION");

		remainSupply = remainSupply.sub(withdrawSupplyAmount);
		totalLiquidation = totalLiquidation.sub(withdrawLiquidation);
		totalLiquidationSupplyAmount = totalLiquidationSupplyAmount.sub(withdrawLiquidationSupplyAmount);
		totalPledge = totalPledge.sub(withdrawLiquidation);

		if(supplyStrategy != address(0) &&
		address(IERC20(IONXStrategy(supplyStrategy).farmToken())) != address(0) &&
		amountWithdraw > 0)
		{			
			IONXStrategy(supplyStrategy).withdraw(from, amountWithdraw);
			TransferHelper.safeTransfer(IONXStrategy(supplyStrategy).farmToken(), msg.sender, amountWithdraw);
		}

		_setConfig(_interests_SS, from, getConfig(_interests_SS, from).sub(withdrawInterest));
		_setConfig(_liquidation_SS, from, getConfig(_liquidation_SS, from).sub(withdrawLiquidation));
		_setConfig(_amountSupply_SS, from, getConfig(_amountSupply_SS, from).sub(amountWithdraw));

		totalStake = totalStake.sub(amountWithdraw);

		_setConfig(_interestSettled_SS, from, getConfig(_amountSupply_SS, from) == 0
			? 0
			: interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));

		_setConfig(_liquidationSettled_SS, from, getConfig(_amountSupply_SS, from) == 0
			? 0
			: liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));

		if (withdrawSupplyAmount > 0) {
			TransferHelper.safeTransfer(supplyToken, msg.sender, withdrawSupplyAmount);
		}

		_decreaseLenderProductivity(from, amountWithdraw);

		if (withdrawLiquidation > 0) {
			if(collateralStrategy != address(0))
			{
				IONXStrategy(collateralStrategy).claim(from, withdrawLiquidation, totalLiquidation.add(withdrawLiquidation));
			}
			TransferHelper.safeTransfer(collateralToken, msg.sender, withdrawLiquidation);
		}

		emit Withdraw(from, withdrawSupplyAmount, withdrawLiquidation, withdrawInterest);
	}

	function borrow(
		uint256 amountCollateral,
		uint256 repayAmount,
		uint256 expectBorrow,
		address from
	) public onlyPlatform {
		uint256 amountIn = IERC20(collateralToken).balanceOf(address(this));
		if(collateralStrategy == address(0))
		{
			amountIn = amountIn.sub(totalPledge);
		}

		require(amountCollateral <= amountIn , "ONX: INVALID AMOUNT");

		updateInterests(false);

		uint256 pledgeRate = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_PLEDGE_RATE);
		uint256 maxAmount =
		IConfig(config).convertTokenAmount(
			collateralToken,
			supplyToken,
			getConfig(_amountCollateral_BS, from).add(amountCollateral)
		);

		uint256 maximumBorrow = maxAmount.mul(pledgeRate).div(1e18);
		// uint repayAmount = getRepayAmount(getConfig(_amountCollateral_BS, from), from);

		require(repayAmount + expectBorrow <= maximumBorrow, "ONX: EXCEED MAX ALLOWED");
		require(expectBorrow <= remainSupply, "ONX: INVALID BORROW");

		totalBorrow = totalBorrow.add(expectBorrow);
		totalPledge = totalPledge.add(amountCollateral);
		remainSupply = remainSupply.sub(expectBorrow);

		if(collateralStrategy != address(0) && amountCollateral > 0)
		{
			IERC20(IONXStrategy(collateralStrategy).farmToken()).approve(collateralStrategy, amountCollateral);
			IONXStrategy(collateralStrategy).invest(from, amountCollateral);
		}

		if (getConfig(_index_BS, from) == 0) {
			borrowerList.push(from);
			_setConfig(_index_BS, from, borrowerList.length);
			numberBorrowers++;
		}

		_setConfig(_interests_BS, from, getConfig(_interests_BS, from).add(
				interestPerBorrow.mul(getConfig(_amountBorrow_BS, from)).div(1e18).sub(getConfig(_interestSettled_BS, from))
			));
		_setConfig(_amountCollateral_BS, from, getConfig(_amountCollateral_BS, from).add(amountCollateral));
		_setConfig(_amountBorrow_BS, from, getConfig(_amountBorrow_BS, from).add(expectBorrow));
		_setConfig(_interestSettled_BS, from, interestPerBorrow.mul(getConfig(_amountBorrow_BS, from)).div(1e18));

		if (expectBorrow > 0) {
			TransferHelper.safeTransfer(supplyToken, msg.sender, expectBorrow);
			_increaseBorrowerProductivity(from, expectBorrow);
		}

		emit Borrow(from, expectBorrow, amountCollateral);
	}

	function repay(uint256 amountCollateral, address from)
	public
	onlyPlatform
	returns (uint256 repayAmount, uint256 payoutInterest)
	{
		require(amountCollateral <= getConfig(_amountCollateral_BS, from), "ONX: NOT ENOUGH COLLATERAL");
		require(amountCollateral > 0, "ONX: INVALID AMOUNT TO REPAY");

		uint256 amountIn = IERC20(supplyToken).balanceOf(address(this)).sub(remainSupply);

		updateInterests(true);

		_setConfig(_interests_BS, from, getConfig(_interests_BS, from).add(
				interestPerBorrow.mul(getConfig(_amountBorrow_BS, from)).div(1e18).sub(getConfig(_interestSettled_BS, from))
			));

		repayAmount = getConfig(_amountBorrow_BS, from).mul(amountCollateral).div(getConfig(_amountCollateral_BS, from));
		uint256 repayInterest = getConfig(_interests_BS, from).mul(amountCollateral).div(getConfig(_amountCollateral_BS, from));

		payoutInterest = 0;
		if (supplyToken == IConfig(config).WETH()) {
			payoutInterest = repayInterest.mul(payoutRatio).div(1e18);
		}		

		totalPledge = totalPledge.sub(amountCollateral);
		totalBorrow = totalBorrow.sub(repayAmount);

		_setConfig(_amountCollateral_BS, from, getConfig(_amountCollateral_BS, from).sub(amountCollateral));
		_setConfig(_amountBorrow_BS, from, getConfig(_amountBorrow_BS, from).sub(repayAmount));
		_setConfig(_interests_BS, from, getConfig(_interests_BS, from).sub(repayInterest));
		_setConfig(_interestSettled_BS, from, getConfig(_amountBorrow_BS, from) == 0
			? 0
			: interestPerBorrow.mul(getConfig(_amountBorrow_BS, from)).div(1e18));

		remainSupply = remainSupply.add(repayAmount.add(repayInterest.sub(payoutInterest)));

		if(collateralStrategy != address(0))
		{
			IONXStrategy(collateralStrategy).withdraw(from, amountCollateral);
		}
		TransferHelper.safeTransfer(collateralToken, msg.sender, amountCollateral);
		require(amountIn >= repayAmount.add(repayInterest), "ONX: INVALID AMOUNT TO REPAY");

		if (payoutInterest > 0) {
			TransferHelper.safeTransfer(supplyToken, msg.sender, payoutInterest);
		}

		if (repayAmount > 0) {
			_decreaseBorrowerProductivity(from, repayAmount);
		}

		emit Repay(from, repayAmount, amountCollateral, repayInterest);
	}

	function liquidation(address _user, address from) public onlyPlatform returns (uint256 borrowAmount) {
		require(getConfig(_amountSupply_SS, from) > 0, "ONX: ONLY SUPPLIER");

		updateInterests(false);

		_setConfig(_interests_BS, _user, getConfig(_interests_BS, _user).add(
				interestPerBorrow.mul(getConfig(_amountBorrow_BS, _user)).div(1e18).sub(getConfig(_interestSettled_BS, _user))
			));

		uint256 liquidationRate = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_LIQUIDATION_RATE);

		////// Used pool price for liquidation limit check
		////// uint pledgePrice = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_PRICE);
		////// uint collateralValue = getConfig(_amountCollateral_BS, _user).mul(pledgePrice).div(1e18);

		////// Need to set token price for liquidation
		uint256 collateralValue =
		IConfig(config).convertTokenAmount(collateralToken, supplyToken, getConfig(_amountCollateral_BS, _user));

		uint256 expectedRepay = getConfig(_amountBorrow_BS, _user).add(getConfig(_interests_BS, _user));

		require(expectedRepay >= collateralValue.mul(liquidationRate).div(1e18), "ONX: NOT LIQUIDABLE");

		updateLiquidation(getConfig(_amountCollateral_BS, _user));

		totalLiquidation = totalLiquidation.add(getConfig(_amountCollateral_BS, _user));
		totalLiquidationSupplyAmount = totalLiquidationSupplyAmount.add(expectedRepay);
		totalBorrow = totalBorrow.sub(getConfig(_amountBorrow_BS, _user));

		borrowAmount = getConfig(_amountBorrow_BS, _user);

		uint256 length = getConfig(_length_LS, _user);
		uint256 id = uint256(_user) ^ length;

		_setConfig(_amountCollateral_LS, id, getConfig(_amountCollateral_BS, _user));
		_setConfig(_liquidationAmount_LS, id, expectedRepay);
		_setConfig(_timestamp_LS, id, block.timestamp);

		_setConfig(_length_LS, _user, length + 1);

		liquidationHistoryLength[_user]++;
		if(collateralStrategy != address(0))
		{
			IONXStrategy(collateralStrategy).liquidation(_user);
		}

		emit Liquidation(from, _user, getConfig(_amountBorrow_BS, _user), getConfig(_amountCollateral_BS, _user));

		_setConfig(_amountCollateral_BS, _user, 0);
		_setConfig(_amountBorrow_BS, _user, 0);
		_setConfig(_interests_BS, _user, 0);
		_setConfig(_interestSettled_BS, _user, 0);

		if (borrowAmount > 0) {
			_decreaseBorrowerProductivity(_user, borrowAmount);
		}
	}

	function getPoolCapacity() external view returns (uint256) {
		return totalStake.add(totalBorrow);
	}

	function supplys(address user) external view returns (
		uint256 amountSupply,
		uint256 interestSettled,
		uint256 liquidationSettled,
		uint256 interests,
		uint256 _liquidation
	) {
		amountSupply = getConfig(_amountSupply_SS, user);
		interestSettled = getConfig(_interestSettled_SS, user);
		liquidationSettled = getConfig(_liquidationSettled_SS, user);
		interests = getConfig(_interests_SS, user);
		_liquidation = getConfig(_liquidation_SS, user);
	}

	function borrows(address user) external view returns(
		uint256 index,
		uint256 amountCollateral,
		uint256 interestSettled,
		uint256 amountBorrow,
		uint256 interests
	) {
		index = getConfig(_index_BS, user);
		amountCollateral = getConfig(_amountCollateral_BS, user);
		interestSettled = getConfig(_interestSettled_BS, user);
		amountBorrow = getConfig(_amountBorrow_BS, user);
		interests = getConfig(_interests_BS, user);
	}

	function liquidationHistory(address user, uint256 index) external view returns (
		uint256 amountCollateral,
		uint256 liquidationAmount,
		uint256 timestamp
	) {
		uint256 id = uint256(user) ^ index;

		amountCollateral = getConfig(_amountCollateral_LS, id);
		liquidationAmount = getConfig(_liquidationAmount_LS, id);
		timestamp = getConfig(_timestamp_LS, id);
	}

	function mint() external {
		_mintLender();
		_mintBorrower();
	}
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library TransferHelper {
	function safeApprove(
		address token,
		address to,
		uint256 value
	) internal {
		// bytes4(keccak256(bytes('approve(address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
	}

	function safeTransfer(
		address token,
		address to,
		uint256 value
	) internal {
		// bytes4(keccak256(bytes('transfer(address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
	}

	function safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) internal {
		// bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
	}

	function safeTransferETH(address to, uint256 value) internal {
		(bool success, ) = to.call{value: value}(new bytes(0));
		require(success, "TransferHelper: ETH_TRANSFER_FAILED");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
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
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
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
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

interface IConfig {
		function owner() external view returns (address);
    function platform() external view returns (address);
    function factory() external view returns (address);
    function mint() external view returns (address);
    function token() external view returns (address);
    function developPercent() external view returns (uint);
    function share() external view returns (address);
    function base() external view returns (address); 
    function governor() external view returns (address);
    function getPoolValue(address pool, bytes32 key) external view returns (uint);
    function getValue(bytes32 key) external view returns(uint);
    function getParams(bytes32 key) external view returns(uint, uint, uint); 
    function getPoolParams(address pool, bytes32 key) external view returns(uint, uint, uint); 
    function wallets(bytes32 key) external view returns(address);
    function setValue(bytes32 key, uint value) external;
    function setPoolValue(address pool, bytes32 key, uint value) external;
    function initPoolParams(address _pool) external;
    function isMintToken(address _token) external returns (bool);
    function prices(address _token) external returns (uint);
    function convertTokenAmount(address _fromToken, address _toToken, uint _fromAmount) external view returns (uint);
    function DAY() external view returns (uint);
    function WETH() external view returns (address);
}

contract Configable is Initializable {
	address public config;
	address public owner;
	event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

	function __config_initialize() internal initializer {
		owner = msg.sender;
	}

	function setupConfig(address _config) external onlyOwner {
		config = _config;
		owner = IConfig(config).owner();
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "OWNER FORBIDDEN");
		_;
	}

	modifier onlyPlatform() {
		require(msg.sender == IConfig(config).platform(), "PLATFORM FORBIDDEN");
		_;
	}

	modifier onlyFactory() {
			require(msg.sender == IConfig(config).factory(), 'FACTORY FORBIDDEN');
			_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

library ConfigNames {
	//GOVERNANCE
	bytes32 public constant STAKE_LOCK_TIME = bytes32("STAKE_LOCK_TIME");
	bytes32 public constant CHANGE_PRICE_DURATION = bytes32("CHANGE_PRICE_DURATION");
	bytes32 public constant CHANGE_PRICE_PERCENT = bytes32("CHANGE_PRICE_PERCENT"); // POOL
	bytes32 public constant POOL_BASE_INTERESTS = bytes32("POOL_BASE_INTERESTS");
	bytes32 public constant POOL_MARKET_FRENZY = bytes32("POOL_MARKET_FRENZY");
	bytes32 public constant POOL_PLEDGE_RATE = bytes32("POOL_PLEDGE_RATE");
	bytes32 public constant POOL_LIQUIDATION_RATE = bytes32("POOL_LIQUIDATION_RATE");
	bytes32 public constant POOL_MINT_BORROW_PERCENT = bytes32("POOL_MINT_BORROW_PERCENT");
	bytes32 public constant POOL_MINT_POWER = bytes32("POOL_MINT_POWER");
	bytes32 public constant POOL_REWARD_RATE = bytes32("POOL_REWARD_RATE");
	bytes32 public constant POOL_ARBITRARY_RATE = bytes32("POOL_ARBITRARY_RATE");

	//NOT GOVERNANCE
	bytes32 public constant DEPOSIT_ENABLE = bytes32("DEPOSIT_ENABLE");
	bytes32 public constant WITHDRAW_ENABLE = bytes32("WITHDRAW_ENABLE");
	bytes32 public constant BORROW_ENABLE = bytes32("BORROW_ENABLE");
	bytes32 public constant REPAY_ENABLE = bytes32("REPAY_ENABLE");
	bytes32 public constant LIQUIDATION_ENABLE = bytes32("LIQUIDATION_ENABLE");
	bytes32 public constant REINVEST_ENABLE = bytes32("REINVEST_ENABLE");
	bytes32 public constant POOL_PRICE = bytes32("POOL_PRICE"); //wallet
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "../libraries/SafeMath.sol";
import "../libraries/TransferHelper.sol";
import "../modules/Configable.sol";
import "../modules/ConfigNames.sol";

interface IERC20 {
	function approve(address spender, uint256 value) external returns (bool);

	function balanceOf(address owner) external view returns (uint256);
}

contract BaseMintField is Configable {
	using SafeMath for uint256;

	uint256 public mintCumulation;

	uint256 public totalLendProductivity;
	uint256 public totalBorrowProducitivity;
	uint256 public accAmountPerLend;
	uint256 public accAmountPerBorrow;

	uint256 public totalBorrowSupply;
	uint256 public totalLendSupply;

	struct UserInfo {
		uint256 amount; // How many tokens the user has provided.
		uint256 rewardDebt; // Reward debt.
		uint256 rewardEarn; // Reward earn and not minted
		uint256 index;
	}

	mapping(address => UserInfo) public lenders;
	mapping(address => UserInfo) public borrowers;

	uint256 public totalShare;
	uint256 public mintedShare;
	event BorrowPowerChange(uint256 oldValue, uint256 newValue);
	event InterestRatePerBlockChanged(uint256 oldValue, uint256 newValue);
	event BorrowerProductivityIncreased(address indexed user, uint256 value);
	event BorrowerProductivityDecreased(address indexed user, uint256 value);
	event LenderProductivityIncreased(address indexed user, uint256 value);
	event LenderProductivityDecreased(address indexed user, uint256 value);
	event MintLender(address indexed user, uint256 userAmount);
	event MintBorrower(address indexed user, uint256 userAmount); // Update reward variables of the given pool to be up-to-date.

	function _update() internal virtual {
		uint256 reward = _currentReward();
		totalShare += reward;
		if (totalLendProductivity.add(totalBorrowProducitivity) == 0 || reward == 0) {
			return;
		}

		uint256 borrowReward =
			reward.mul(IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MINT_BORROW_PERCENT)).div(10000);
		uint256 lendReward = reward.sub(borrowReward);

		if (totalLendProductivity != 0 && lendReward > 0) {
			totalLendSupply = totalLendSupply.add(lendReward);
			accAmountPerLend = accAmountPerLend.add(lendReward.mul(1e12).div(totalLendProductivity));
		}

		if (totalBorrowProducitivity != 0 && borrowReward > 0) {
			totalBorrowSupply = totalBorrowSupply.add(borrowReward);
			accAmountPerBorrow = accAmountPerBorrow.add(borrowReward.mul(1e12).div(totalBorrowProducitivity));
		}
	}

	function _currentReward() internal view virtual returns (uint256) {
		return mintedShare.add(IERC20(IConfig(config).token()).balanceOf(address(this))).sub(totalShare);
	}

	// Audit borrowers's reward to be up-to-date
	function _auditBorrower(address user) internal {
		UserInfo storage userInfo = borrowers[user];
		if (userInfo.amount > 0) {
			uint256 pending = userInfo.amount.mul(accAmountPerBorrow).div(1e12).sub(userInfo.rewardDebt);
			userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
			mintCumulation = mintCumulation.add(pending);
			userInfo.rewardDebt = userInfo.amount.mul(accAmountPerBorrow).div(1e12);
		}
	}

	// Audit lender's reward to be up-to-date
	function _auditLender(address user) internal {
		UserInfo storage userInfo = lenders[user];
		if (userInfo.amount > 0) {
			uint256 pending = userInfo.amount.mul(accAmountPerLend).div(1e12).sub(userInfo.rewardDebt);
			userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
			mintCumulation = mintCumulation.add(pending);
			userInfo.rewardDebt = userInfo.amount.mul(accAmountPerLend).div(1e12);
		}
	}

	function _increaseBorrowerProductivity(address user, uint256 value) internal returns (bool) {
		require(value > 0, "PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO");
		UserInfo storage userInfo = borrowers[user];
		_update();
		_auditBorrower(user);
		totalBorrowProducitivity = totalBorrowProducitivity.add(value);
		userInfo.amount = userInfo.amount.add(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerBorrow).div(1e12);
		emit BorrowerProductivityIncreased(user, value);
		return true;
	}

	function _decreaseBorrowerProductivity(address user, uint256 value) internal returns (bool) {
		require(value > 0, "INSUFFICIENT_PRODUCTIVITY");

		UserInfo storage userInfo = borrowers[user];
		require(userInfo.amount >= value, "FORBIDDEN");
		_update();
		_auditBorrower(user);

		userInfo.amount = userInfo.amount.sub(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerBorrow).div(1e12);
		totalBorrowProducitivity = totalBorrowProducitivity.sub(value);
		emit BorrowerProductivityDecreased(user, value);
		return true;
	}

	function _increaseLenderProductivity(address user, uint256 value) internal returns (bool) {
		require(value > 0, "PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO");
		UserInfo storage userInfo = lenders[user];
		_update();
		_auditLender(user);
		totalLendProductivity = totalLendProductivity.add(value);
		userInfo.amount = userInfo.amount.add(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerLend).div(1e12);
		emit LenderProductivityIncreased(user, value);
		return true;
	}

	// External function call
	// This function will decreases user's productivity by value, and updates the global productivity
	// it will record which block this is happenning and accumulates the area of (productivity * time)
	function _decreaseLenderProductivity(address user, uint256 value) internal returns (bool) {
		require(value > 0, "INSUFFICIENT_PRODUCTIVITY");

		UserInfo storage userInfo = lenders[user];
		require(userInfo.amount >= value, "FORBIDDEN");
		_update();
		_auditLender(user);

		userInfo.amount = userInfo.amount.sub(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerLend).div(1e12);
		totalLendProductivity = totalLendProductivity.sub(value);
		emit LenderProductivityDecreased(user, value);
		return true;
	}

	function takeBorrowWithAddress(address user) public view returns (uint256) {
		UserInfo storage userInfo = borrowers[user];
		uint256 _accAmountPerBorrow = accAmountPerBorrow;
		if (totalBorrowProducitivity != 0) {
			uint256 reward = _currentReward();
			uint256 borrowReward =
				reward.mul(IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MINT_BORROW_PERCENT)).div(10000);

			_accAmountPerBorrow = accAmountPerBorrow.add(borrowReward.mul(1e12).div(totalBorrowProducitivity));
		}

		return userInfo.amount.mul(_accAmountPerBorrow).div(1e12).sub(userInfo.rewardDebt).add(userInfo.rewardEarn);
	}

	function takeLendWithAddress(address user) public view returns (uint256) {
		UserInfo storage userInfo = lenders[user];
		uint256 _accAmountPerLend = accAmountPerLend;
		if (totalLendProductivity != 0) {
			uint256 reward = _currentReward();
			uint256 lendReward =
				reward.sub(reward.mul(IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MINT_BORROW_PERCENT)).div(10000));
			_accAmountPerLend = accAmountPerLend.add(lendReward.mul(1e12).div(totalLendProductivity));
		}
		return userInfo.amount.mul(_accAmountPerLend).div(1e12).sub(userInfo.rewardDebt).add(userInfo.rewardEarn);
	}

	function takeBorrowWithBlock() external view returns (uint256, uint256) {
		uint256 earn = takeBorrowWithAddress(msg.sender);
		return (earn, block.number);
	}

	function takeLendWithBlock() external view returns (uint256, uint256) {
		uint256 earn = takeLendWithAddress(msg.sender);
		return (earn, block.number);
	}

	function takeAll() public view returns (uint256) {
		return takeBorrowWithAddress(msg.sender).add(takeLendWithAddress(msg.sender));
	}

	function takeAllWithBlock() external view returns (uint256, uint256) {
		return (takeAll(), block.number);
	}

	function _mintBorrower() internal returns (uint256) {
		_update();
		_auditBorrower(msg.sender);
		if (borrowers[msg.sender].rewardEarn > 0) {
			uint256 amount = borrowers[msg.sender].rewardEarn;
			_mintDistribution(msg.sender, amount);
			borrowers[msg.sender].rewardEarn = 0;
			emit MintBorrower(msg.sender, amount);
			return amount;
		}
	}

	function _mintLender() internal returns (uint256) {
		_update();
		_auditLender(msg.sender);
		if (lenders[msg.sender].rewardEarn > 0) {
			uint256 amount = lenders[msg.sender].rewardEarn;
			_mintDistribution(msg.sender, amount);
			lenders[msg.sender].rewardEarn = 0;
			emit MintLender(msg.sender, amount);
			return amount;
		}
	}

	// Returns how many productivity a user has and global has.
	function getBorrowerProductivity(address user) external view returns (uint256, uint256) {
		return (borrowers[user].amount, totalBorrowProducitivity);
	}

	function getLenderProductivity(address user) external view returns (uint256, uint256) {
		return (lenders[user].amount, totalLendProductivity);
	}

	// Returns the current gorss product rate.
	function interestsPerBlock() external view returns (uint256, uint256) {
		return (accAmountPerBorrow, accAmountPerLend);
	}

	function _mintDistribution(address user, uint256 amount) internal {
		if (amount > 0) {
			mintedShare += amount;
			TransferHelper.safeTransfer(IConfig(config).token(), user, amount);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

contract Configurable {
    mapping (bytes32 => uint) internal _config;

    function getConfig(bytes32 key) public view returns (uint) {
        return _config[key];
    }
    function getConfig(bytes32 key, uint index) public view returns (uint) {
        return _config[bytes32(uint(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint) {
        return _config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(_config[key] != value)
            _config[key] = value;
    }

    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }

    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


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