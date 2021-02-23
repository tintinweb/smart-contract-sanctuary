// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./modules/Configable.sol";
import "./modules/ConfigNames.sol";
import "./libraries/SafeMath.sol";
import "./libraries/TransferHelper.sol";

interface IONXSupplyToken {
	function mint(address account, uint256 amount) external;
	function burn(address account, uint256 amount) external;
	function approve(address spender, uint256 amount) external;
}

interface IWETH {
	function deposit() external payable;
	function withdraw(uint256) external;
}

interface IONXPool {
	function deposit(uint _amountDeposit, address _from) external;
	function withdraw(uint _amountWithdraw, address _from) external returns(uint, uint);
	function borrow(uint _amountCollateral, uint _repayAmount, uint _expectBorrow, address _from) external;
	function repay(uint _amountCollateral, address _from) external returns(uint, uint);
	function liquidation(address _user, address _from) external returns (uint);
	function reinvest(address _from) external returns(uint);

	function setCollateralStrategy(address _collateralStrategy, address _supplyStrategy) external;
	function supplys(address user) external view returns(uint,uint,uint,uint,uint);
	function borrows(address user) external view returns(uint,uint,uint,uint,uint);
	function getPoolCapacity() external view returns (uint);
	function supplyToken() external view returns (address);
	function interestPerBorrow() external view returns(uint);
	function interestPerSupply() external view returns(uint);
	function lastInterestUpdate() external view returns(uint);
	function getInterests() external view returns(uint, uint);
	function totalBorrow() external view returns(uint);
	function remainSupply() external view returns(uint);
	function liquidationPerSupply() external view returns(uint);
	function totalLiquidationSupplyAmount() external view returns(uint);
	function totalLiquidation() external view returns(uint);
}

interface IONXFactory {
    function getPool(address _lendToken, address _collateralToken) external view returns (address);
    function countPools() external view returns(uint);
    function allPools(uint index) external view returns (address);
}

contract ONXPlatform is Configable {
	using SafeMath for uint256;
	uint256 private unlocked;
	address public payoutAddress;
	address public onxSupplyToken;
	modifier lock() {
		require(unlocked == 1, "Locked");
		unlocked = 0;
		_;
		unlocked = 1;
	}

	receive() external payable {}

	function initialize(address _payoutAddress, address _onxSupplyToken) external initializer {
		Configable.__config_initialize();
		unlocked = 1;
		payoutAddress = _payoutAddress;
		onxSupplyToken = _onxSupplyToken;
	}

	function deposit(address _lendToken, address _collateralToken, uint256 _amountDeposit) external lock {
		require(IConfig(config).getValue(ConfigNames.DEPOSIT_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		TransferHelper.safeTransferFrom(_lendToken, msg.sender, pool, _amountDeposit);
		if(onxSupplyToken != address(0) && _amountDeposit > 0)
		{
			IONXSupplyToken(onxSupplyToken).mint(address(this), _amountDeposit);
			TransferHelper.safeTransfer(onxSupplyToken, pool, _amountDeposit);
		}
		IONXPool(pool).deposit(_amountDeposit, msg.sender);
	}

	function depositETH(address _lendToken, address _collateralToken) external payable lock {
		require(_lendToken == IConfig(config).WETH(), "INVALID WETH POOL");
		require(IConfig(config).getValue(ConfigNames.DEPOSIT_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		IWETH(IConfig(config).WETH()).deposit{value: msg.value}();
		TransferHelper.safeTransfer(_lendToken, pool, msg.value);
		if(onxSupplyToken != address(0) && msg.value > 0)
		{
			IONXSupplyToken(onxSupplyToken).mint(address(this), msg.value);
			TransferHelper.safeTransfer(onxSupplyToken, pool, msg.value);
		}
		IONXPool(pool).deposit(msg.value, msg.sender);
	}

	function withdraw(address _lendToken, address _collateralToken, uint256 _amountWithdraw) external lock {
		require(IConfig(config).getValue(ConfigNames.WITHDRAW_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		(uint256 withdrawSupplyAmount, uint256 withdrawLiquidationAmount) =
			IONXPool(pool).withdraw(_amountWithdraw, msg.sender);
		if (withdrawSupplyAmount > 0) {
			_innerTransfer(_lendToken, msg.sender, withdrawSupplyAmount);
			if(onxSupplyToken != address(0) && _amountWithdraw > 0) {
				IONXSupplyToken(onxSupplyToken).burn(address(this), _amountWithdraw);
			}
		}
		if (withdrawLiquidationAmount > 0) _innerTransfer(_collateralToken, msg.sender, withdrawLiquidationAmount);
	}

	function borrow(address _lendToken, address _collateralToken, uint256 _amountCollateral, uint256 _expectBorrow) external lock {
		require(IConfig(config).getValue(ConfigNames.BORROW_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		if (_amountCollateral > 0) {
			TransferHelper.safeTransferFrom(_collateralToken, msg.sender, pool, _amountCollateral);
		}

		(, uint256 borrowAmountCollateral, , , ) = IONXPool(pool).borrows(msg.sender);
		uint256 repayAmount = getRepayAmount(_lendToken, _collateralToken, borrowAmountCollateral, msg.sender);
		IONXPool(pool).borrow(_amountCollateral, repayAmount, _expectBorrow, msg.sender);
		if (_expectBorrow > 0) _innerTransfer(_lendToken, msg.sender, _expectBorrow);
	}

	function borrowTokenWithETH(address _lendToken, address _collateralToken, uint256 _expectBorrow) external payable lock {
		require(_collateralToken == IConfig(config).WETH(), "INVALID WETH POOL");
		require(IConfig(config).getValue(ConfigNames.BORROW_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
        
		if (msg.value > 0) {
			IWETH(IConfig(config).WETH()).deposit{value: msg.value}();
			TransferHelper.safeTransfer(_collateralToken, pool, msg.value);
		}

		(, uint256 borrowAmountCollateral, , , ) = IONXPool(pool).borrows(msg.sender);
		uint256 repayAmount = getRepayAmount(_lendToken, _collateralToken, borrowAmountCollateral, msg.sender);
		IONXPool(pool).borrow(msg.value, repayAmount, _expectBorrow, msg.sender);
		if (_expectBorrow > 0) _innerTransfer(_lendToken, msg.sender, _expectBorrow);
	}

	function repay(address _lendToken, address _collateralToken, uint256 _amountCollateral) external lock {
		require(IConfig(config).getValue(ConfigNames.REPAY_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		uint256 repayAmount = getRepayAmount(_lendToken, _collateralToken, _amountCollateral, msg.sender);
		if (repayAmount > 0) {
			TransferHelper.safeTransferFrom(_lendToken, msg.sender, pool, repayAmount);
		}

		(, uint256 payoutInterest) = IONXPool(pool).repay(_amountCollateral, msg.sender);
		if (payoutInterest > 0) {
			_innerTransfer(_lendToken, payoutAddress, payoutInterest);
		}
		_innerTransfer(_collateralToken, msg.sender, _amountCollateral);
	}

	function repayETH(address _lendToken, address _collateralToken, uint256 _amountCollateral) external payable lock {
		require(IConfig(config).getValue(ConfigNames.REPAY_ENABLE) == 1, "NOT ENABLE NOW");
		require(_lendToken == IConfig(config).WETH(), "INVALID WETH POOL");

		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		uint256 repayAmount = getRepayAmount(_lendToken, _collateralToken, _amountCollateral, msg.sender);
		require(repayAmount <= msg.value, "INVALID VALUE");
		if (repayAmount > 0) {
			IWETH(IConfig(config).WETH()).deposit{value: repayAmount}();
			TransferHelper.safeTransfer(_lendToken, pool, repayAmount);
		}

		(, uint256 payoutInterest) = IONXPool(pool).repay(_amountCollateral, msg.sender);
		if (payoutInterest > 0) {
			_innerTransfer(_lendToken, payoutAddress, payoutInterest);
		}
		_innerTransfer(_collateralToken, msg.sender, _amountCollateral);
		if (msg.value > repayAmount) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(repayAmount));
	}

	function liquidation(address _lendToken, address _collateralToken, address _user) external lock {
		require(IConfig(config).getValue(ConfigNames.LIQUIDATION_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		IONXPool(pool).liquidation(_user, msg.sender);
	}

	function reinvest(address _lendToken, address _collateralToken) external lock {
		require(IConfig(config).getValue(ConfigNames.REINVEST_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		IONXPool(pool).reinvest(msg.sender);
	}

	function _innerTransfer(
		address _token,
		address _to,
		uint256 _amount
	) internal {
		if (_token == IConfig(config).WETH()) {
			IWETH(_token).withdraw(_amount);
			TransferHelper.safeTransferETH(_to, _amount);
		} else {
			TransferHelper.safeTransfer(_token, _to, _amount);
		}
	}

	function getRepayAmount(address _lendToken, address _collateralToken, uint256 amountCollateral, address from) public view returns (uint256 repayAmount) {
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");

		(, uint256 borrowAmountCollateral, uint256 interestSettled, uint256 amountBorrow, uint256 borrowInterests) =
			IONXPool(pool).borrows(from);
		(, uint256 borrowInterestPerBlock) = IONXPool(pool).getInterests();
		uint256 _interestPerBorrow =
			IONXPool(pool).interestPerBorrow().add(
				borrowInterestPerBlock.mul(block.number - IONXPool(pool).lastInterestUpdate())
			);
		uint256 repayInterest =
			borrowAmountCollateral == 0 
			? 0 
			: borrowInterests.add(_interestPerBorrow.mul(amountBorrow).div(1e18).sub(interestSettled)).mul(amountCollateral).div(borrowAmountCollateral);
		repayAmount = borrowAmountCollateral == 0
			? 0
			: amountBorrow.mul(amountCollateral).div(borrowAmountCollateral).add(repayInterest);
	}

	function getMaximumBorrowAmount(address _lendToken, address _collateralToken, uint256 amountCollateral) external view returns (uint256 amountBorrow) {
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");

		uint256 pledgeAmount = IConfig(config).convertTokenAmount(_collateralToken, _lendToken, amountCollateral);
		uint256 pledgeRate = IConfig(config).getPoolValue(pool, ConfigNames.POOL_PLEDGE_RATE);
		amountBorrow = pledgeAmount.mul(pledgeRate).div(1e18);
	}

	function getLiquidationAmount(address _lendToken, address _collateralToken, address from) public view returns (uint256 liquidationAmount) {
        	address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
	        require(pool != address(0), "POOL NOT EXIST");

		(uint256 amountSupply, , uint256 liquidationSettled, , uint256 supplyLiquidation) =
			IONXPool(pool).supplys(from);
		liquidationAmount = supplyLiquidation.add(
			IONXPool(pool).liquidationPerSupply().mul(amountSupply).div(1e18).sub(liquidationSettled)
		);
	}

	function getInterestAmount(address _lendToken, address _collateralToken, address from) public view returns (uint256 interestAmount) {
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");

		uint256 totalBorrow = IONXPool(pool).totalBorrow();
		uint256 totalSupply = totalBorrow + IONXPool(pool).remainSupply();
		(uint256 amountSupply, uint256 interestSettled, , uint256 interests, ) = IONXPool(pool).supplys(from);
		(uint256 supplyInterestPerBlock,) = IONXPool(pool).getInterests();
		uint256 _interestPerSupply =
			IONXPool(pool).interestPerSupply().add(
				totalSupply == 0
					? 0
					: supplyInterestPerBlock
						.mul(block.number - IONXPool(pool).lastInterestUpdate())
						.mul(IONXPool(pool).totalBorrow())
						.div(totalSupply)
			);
		interestAmount = interests.add(_interestPerSupply.mul(amountSupply).div(1e18).sub(interestSettled));
	}

	function getWithdrawAmount(address _lendToken, address _collateralToken, address from)
		external
		view
		returns (
			uint256 withdrawAmount,
			uint256 interestAmount,
			uint256 liquidationAmount
		)
	{
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");

		uint256 _totalInterest = getInterestAmount(_lendToken, _collateralToken, from);
		liquidationAmount = getLiquidationAmount(_lendToken, _collateralToken, from);
		interestAmount = _totalInterest;
		uint256 totalLiquidation = IONXPool(pool).totalLiquidation();
		uint256 withdrawLiquidationSupplyAmount =
			totalLiquidation == 0
				? 0
				: liquidationAmount.mul(IONXPool(pool).totalLiquidationSupplyAmount()).div(totalLiquidation);
		(uint256 amountSupply, , , , ) = IONXPool(pool).supplys(from);
		if (withdrawLiquidationSupplyAmount > amountSupply.add(interestAmount)) withdrawAmount = 0;
		else withdrawAmount = amountSupply.add(interestAmount).sub(withdrawLiquidationSupplyAmount);
	}

	function updatePoolParameter(address _lendToken, address _collateralToken, bytes32 _key, uint256 _value) external onlyOwner {
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		IConfig(config).setPoolValue(pool, _key, _value);
	}

	function setCollateralStrategy(address _lendToken, address _collateralToken, address _collateralStrategy, address _supplyStrategy) external onlyOwner
	{
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		IONXPool(pool).setCollateralStrategy(_collateralStrategy, _supplyStrategy);
	}

	function setPayoutAddress(address _payoutAddress) external onlyOwner {
		payoutAddress = _payoutAddress;
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