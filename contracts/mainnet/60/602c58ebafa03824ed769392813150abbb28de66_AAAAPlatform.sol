/**
 *Submitted for verification at Etherscan.io on 2020-12-02
*/

// Dependency file: contracts/modules/Configable.sol

// SPDX-License-Identifier: MIT
// pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

interface IConfig {
    function developer() external view returns (address);
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
    function getParams(bytes32 key) external view returns(uint, uint, uint, uint); 
    function getPoolParams(address pool, bytes32 key) external view returns(uint, uint, uint, uint); 
    function wallets(bytes32 key) external view returns(address);
    function setValue(bytes32 key, uint value) external;
    function setPoolValue(address pool, bytes32 key, uint value) external;
    function setParams(bytes32 _key, uint _min, uint _max, uint _span, uint _value) external;
    function setPoolParams(bytes32 _key, uint _min, uint _max, uint _span, uint _value) external;
    function initPoolParams(address _pool) external;
    function isMintToken(address _token) external returns (bool);
    function prices(address _token) external returns (uint);
    function convertTokenAmount(address _fromToken, address _toToken, uint _fromAmount) external view returns (uint);
    function DAY() external view returns (uint);
    function WETH() external view returns (address);
}

contract Configable {
    address public config;
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }
    
    function setupConfig(address _config) external onlyOwner {
        config = _config;
        owner = IConfig(config).developer();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }
    
    modifier onlyDeveloper() {
        require(msg.sender == IConfig(config).developer(), 'DEVELOPER FORBIDDEN');
        _;
    }
    
    modifier onlyPlatform() {
        require(msg.sender == IConfig(config).platform(), 'PLATFORM FORBIDDEN');
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == IConfig(config).factory(), 'FACTORY FORBIDDEN');
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == IConfig(config).governor(), 'Governor FORBIDDEN');
        _;
    }
}

// Dependency file: contracts/modules/ConfigNames.sol

// pragma solidity >=0.5.16;

library ConfigNames {
    //GOVERNANCE
    bytes32 public constant PROPOSAL_VOTE_DURATION = bytes32('PROPOSAL_VOTE_DURATION');
    bytes32 public constant PROPOSAL_EXECUTE_DURATION = bytes32('PROPOSAL_EXECUTE_DURATION');
    bytes32 public constant PROPOSAL_CREATE_COST = bytes32('PROPOSAL_CREATE_COST');
    bytes32 public constant STAKE_LOCK_TIME = bytes32('STAKE_LOCK_TIME');
    bytes32 public constant MINT_AMOUNT_PER_BLOCK =  bytes32('MINT_AMOUNT_PER_BLOCK');
    bytes32 public constant INTEREST_PLATFORM_SHARE =  bytes32('INTEREST_PLATFORM_SHARE');
    bytes32 public constant CHANGE_PRICE_DURATION =  bytes32('CHANGE_PRICE_DURATION');
    bytes32 public constant CHANGE_PRICE_PERCENT =  bytes32('CHANGE_PRICE_PERCENT');

    // POOL
    bytes32 public constant POOL_BASE_INTERESTS = bytes32('POOL_BASE_INTERESTS');
    bytes32 public constant POOL_MARKET_FRENZY = bytes32('POOL_MARKET_FRENZY');
    bytes32 public constant POOL_PLEDGE_RATE = bytes32('POOL_PLEDGE_RATE');
    bytes32 public constant POOL_LIQUIDATION_RATE = bytes32('POOL_LIQUIDATION_RATE');
    bytes32 public constant POOL_MINT_BORROW_PERCENT = bytes32('POOL_MINT_BORROW_PERCENT');
    bytes32 public constant POOL_MINT_POWER = bytes32('POOL_MINT_POWER');
    
    //NOT GOVERNANCE
    bytes32 public constant AAAA_USER_MINT = bytes32('AAAA_USER_MINT');
    bytes32 public constant AAAA_TEAM_MINT = bytes32('AAAA_TEAM_MINT');
    bytes32 public constant AAAA_REWAED_MINT = bytes32('AAAA_REWAED_MINT');
    bytes32 public constant DEPOSIT_ENABLE = bytes32('DEPOSIT_ENABLE');
    bytes32 public constant WITHDRAW_ENABLE = bytes32('WITHDRAW_ENABLE');
    bytes32 public constant BORROW_ENABLE = bytes32('BORROW_ENABLE');
    bytes32 public constant REPAY_ENABLE = bytes32('REPAY_ENABLE');
    bytes32 public constant LIQUIDATION_ENABLE = bytes32('LIQUIDATION_ENABLE');
    bytes32 public constant REINVEST_ENABLE = bytes32('REINVEST_ENABLE');
    bytes32 public constant INTEREST_BUYBACK_SHARE =  bytes32('INTEREST_BUYBACK_SHARE');

    //POOL
    bytes32 public constant POOL_PRICE = bytes32('POOL_PRICE');

    //wallet
    bytes32 public constant TEAM = bytes32('team'); 
    bytes32 public constant SPARE = bytes32('spare');
    bytes32 public constant REWARD = bytes32('reward');
}

// Dependency file: contracts/libraries/SafeMath.sol


// pragma solidity >=0.6.0;

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

// Dependency file: contracts/libraries/TransferHelper.sol


// pragma solidity >=0.6.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Root file: contracts/AAAAPlatform.sol

pragma solidity >=0.5.16;

// import "contracts/modules/Configable.sol";
// import "contracts/modules/ConfigNames.sol";
// import "contracts/libraries/SafeMath.sol";
// import "contracts/libraries/TransferHelper.sol";

interface IAAAAMint {
    function increaseProductivity(address user, uint value) external returns (bool);
    function decreaseProductivity(address user, uint value) external returns (bool);
    function getProductivity(address user) external view returns (uint, uint);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IAAAAPool {
    function deposit(uint _amountDeposit, address _from) external;
    function withdraw(uint _amountWithdraw, address _from) external returns(uint, uint);
    function borrow(uint _amountCollateral, uint _repayAmount, uint _expectBorrow, address _from) external;
    function repay(uint _amountCollateral, address _from) external returns(uint, uint);
    function liquidation(address _user, address _from) external returns (uint);
    function reinvest(address _from) external returns(uint);

    function switchStrategy(address _collateralStrategy) external;
    function supplys(address user) external view returns(uint,uint,uint,uint,uint);
    function borrows(address user) external view returns(uint,uint,uint,uint,uint);
    function getTotalAmount() external view returns (uint);
    function supplyToken() external view returns (address);
    function interestPerBorrow() external view returns(uint);
    function interestPerSupply() external view returns(uint);
    function lastInterestUpdate() external view returns(uint);
    function getInterests() external view returns(uint);
    function totalBorrow() external view returns(uint);
    function remainSupply() external view returns(uint);
    function liquidationPerSupply() external view returns(uint);
    function totalLiquidationSupplyAmount() external view returns(uint);
    function totalLiquidation() external view returns(uint);
}

interface IAAAAFactory {
    function getPool(address _lendToken, address _collateralToken) external view returns (address);
    function countPools() external view returns(uint);
    function allPools(uint index) external view returns (address);
}

contract AAAAPlatform is Configable {

    using SafeMath for uint;
    
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    receive() external payable {
    }

    function deposit(address _lendToken, address _collateralToken, uint _amountDeposit) external lock {
        require(IConfig(config).getValue(ConfigNames.DEPOSIT_ENABLE) == 1, "NOT ENABLE NOW");
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");
        TransferHelper.safeTransferFrom(_lendToken, msg.sender, pool, _amountDeposit);
        IAAAAPool(pool).deposit(_amountDeposit, msg.sender);
        _updateProdutivity(pool);
    }
    
    function depositETH(address _lendToken, address _collateralToken) external payable lock {
        require(_lendToken == IConfig(config).WETH(), "INVALID WETH POOL");
        require(IConfig(config).getValue(ConfigNames.DEPOSIT_ENABLE) == 1, "NOT ENABLE NOW");
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");
        
        IWETH(IConfig(config).WETH()).deposit{value:msg.value}();
        TransferHelper.safeTransfer(_lendToken, pool, msg.value);
        IAAAAPool(pool).deposit(msg.value, msg.sender);
        _updateProdutivity(pool);
    }
    
    function withdraw(address _lendToken, address _collateralToken, uint _amountWithdraw) external lock {
        require(IConfig(config).getValue(ConfigNames.WITHDRAW_ENABLE) == 1, "NOT ENABLE NOW");
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");
        (uint withdrawSupplyAmount, uint withdrawLiquidationAmount) = IAAAAPool(pool).withdraw(_amountWithdraw, msg.sender);

        if(withdrawSupplyAmount > 0) _innerTransfer(_lendToken, msg.sender, withdrawSupplyAmount);
        if(withdrawLiquidationAmount > 0) _innerTransfer(_collateralToken, msg.sender, withdrawLiquidationAmount);

        _updateProdutivity(pool);
    }
    
    function borrow(address _lendToken, address _collateralToken, uint _amountCollateral, uint _expectBorrow) external lock {
        require(IConfig(config).getValue(ConfigNames.BORROW_ENABLE) == 1, "NOT ENABLE NOW");
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");
        if(_amountCollateral > 0) {
            TransferHelper.safeTransferFrom(_collateralToken, msg.sender, pool, _amountCollateral);
        }
        
        (, uint borrowAmountCollateral, , , ) = IAAAAPool(pool).borrows(msg.sender);
        uint repayAmount = getRepayAmount(_lendToken, _collateralToken, borrowAmountCollateral, msg.sender);
        IAAAAPool(pool).borrow(_amountCollateral, repayAmount, _expectBorrow, msg.sender);
        if(_expectBorrow > 0) _innerTransfer(_lendToken, msg.sender, _expectBorrow);
        _updateProdutivity(pool);
    }
    
    function borrowTokenWithETH(address _lendToken, address _collateralToken, uint _expectBorrow) external payable lock {
        require(_collateralToken == IConfig(config).WETH(), "INVALID WETH POOL");
        require(IConfig(config).getValue(ConfigNames.BORROW_ENABLE) == 1, "NOT ENABLE NOW");
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");
        
        if(msg.value > 0) {
            IWETH(IConfig(config).WETH()).deposit{value:msg.value}();
            TransferHelper.safeTransfer(_collateralToken, pool, msg.value);
        }
        
        (, uint borrowAmountCollateral, , , ) = IAAAAPool(pool).borrows(msg.sender);
        uint repayAmount = getRepayAmount(_lendToken, _collateralToken, borrowAmountCollateral, msg.sender);
        IAAAAPool(pool).borrow(msg.value, repayAmount, _expectBorrow, msg.sender);
        if(_expectBorrow > 0) _innerTransfer(_lendToken, msg.sender, _expectBorrow);
        _updateProdutivity(pool);
    }
    
    function repay(address _lendToken, address _collateralToken, uint _amountCollateral) external lock {
        require(IConfig(config).getValue(ConfigNames.REPAY_ENABLE) == 1, "NOT ENABLE NOW");
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");
        uint repayAmount = getRepayAmount(_lendToken, _collateralToken, _amountCollateral, msg.sender);
        
        if(repayAmount > 0) {
            TransferHelper.safeTransferFrom(_lendToken, msg.sender, pool, repayAmount);
        }
        
        IAAAAPool(pool).repay(_amountCollateral, msg.sender);
        _innerTransfer(_collateralToken, msg.sender, _amountCollateral);
        _updateProdutivity(pool);
    }

    function repayETH(address _lendToken, address _collateralToken, uint _amountCollateral) payable lock external {
        require(IConfig(config).getValue(ConfigNames.REPAY_ENABLE) == 1, "NOT ENABLE NOW");
        require(_lendToken == IConfig(config).WETH(), "INVALID WETH POOL");

        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");
        uint repayAmount = getRepayAmount(_lendToken, _collateralToken, _amountCollateral, msg.sender);

        require(repayAmount <= msg.value, "INVALID VALUE");

        if(repayAmount > 0) {
            IWETH(IConfig(config).WETH()).deposit{value:repayAmount}();
            TransferHelper.safeTransfer(_lendToken, pool, repayAmount);
        }
        
        IAAAAPool(pool).repay(_amountCollateral, msg.sender);
        _innerTransfer(_collateralToken, msg.sender, _amountCollateral);
        if(msg.value > repayAmount) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(repayAmount));

        _updateProdutivity(pool);
    }
    
    function liquidation(address _lendToken, address _collateralToken, address _user) external lock {
        require(IConfig(config).getValue(ConfigNames.LIQUIDATION_ENABLE) == 1, "NOT ENABLE NOW");
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");
        IAAAAPool(pool).liquidation(_user, msg.sender);
        _updateProdutivity(pool);
    }

    function reinvest(address _lendToken, address _collateralToken) external lock {
        require(IConfig(config).getValue(ConfigNames.REINVEST_ENABLE) == 1, "NOT ENABLE NOW");
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");
        IAAAAPool(pool).reinvest(msg.sender);
        _updateProdutivity(pool);
    }
    
    function _innerTransfer(address _token, address _to, uint _amount) internal {
        if(_token == IConfig(config).WETH()) {
            IWETH(_token).withdraw(_amount);
            TransferHelper.safeTransferETH(_to, _amount);
        } else {
            TransferHelper.safeTransfer(_token, _to, _amount);
        }
    }

    function _updateProdutivity(address _pool) internal {
        uint power = IConfig(config).getPoolValue(_pool, ConfigNames.POOL_MINT_POWER);
        uint amount = IAAAAPool(_pool).getTotalAmount().mul(power).div(10000);
        (uint old, ) = IAAAAMint(IConfig(config).mint()).getProductivity(_pool);
        if(old > 0) {
            IAAAAMint(IConfig(config).mint()).decreaseProductivity(_pool, old);
        }
        
        address token = IAAAAPool(_pool).supplyToken();
        uint baseAmount = IConfig(config).convertTokenAmount(token, IConfig(config).base(), amount);
        if(baseAmount > 0) {
            IAAAAMint(IConfig(config).mint()).increaseProductivity(_pool, baseAmount);
        }
    }

    function getRepayAmount(address _lendToken, address _collateralToken, uint amountCollateral, address from) public view returns(uint repayAmount)
    {
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");

        (, uint borrowAmountCollateral, uint interestSettled, uint amountBorrow, uint borrowInterests) = IAAAAPool(pool).borrows(from);

        uint _interestPerBorrow = IAAAAPool(pool).interestPerBorrow().add(IAAAAPool(pool).getInterests().mul(block.number - IAAAAPool(pool).lastInterestUpdate()));
        uint _totalInterest = borrowInterests.add(_interestPerBorrow.mul(amountBorrow).div(1e18).sub(interestSettled));

        uint repayInterest = borrowAmountCollateral == 0 ? 0 : _totalInterest.mul(amountCollateral).div(borrowAmountCollateral);
        repayAmount = borrowAmountCollateral == 0 ? 0 : amountBorrow.mul(amountCollateral).div(borrowAmountCollateral).add(repayInterest);
    }

    function getMaximumBorrowAmount(address _lendToken, address _collateralToken, uint amountCollateral) external view returns(uint amountBorrow)
    {
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");

        uint pledgeAmount = IConfig(config).convertTokenAmount(_collateralToken, _lendToken, amountCollateral);
        uint pledgeRate = IConfig(config).getPoolValue(address(pool), ConfigNames.POOL_PLEDGE_RATE);

        amountBorrow = pledgeAmount.mul(pledgeRate).div(1e18);
    }

    function getLiquidationAmount(address _lendToken, address _collateralToken, address from) public view returns(uint liquidationAmount)
    {
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");

        (uint amountSupply, , uint liquidationSettled, , uint supplyLiquidation) = IAAAAPool(pool).supplys(from);

        liquidationAmount = supplyLiquidation.add(IAAAAPool(pool).liquidationPerSupply().mul(amountSupply).div(1e18).sub(liquidationSettled));
    }

    function getInterestAmount(address _lendToken, address _collateralToken, address from) public view returns(uint interestAmount)
    {
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");

        uint totalBorrow = IAAAAPool(pool).totalBorrow();
        uint totalSupply = totalBorrow + IAAAAPool(pool).remainSupply();
        (uint amountSupply, uint interestSettled, , uint interests, ) = IAAAAPool(pool).supplys(from);
        uint _interestPerSupply = IAAAAPool(pool).interestPerSupply().add(
            totalSupply == 0 ? 0 : IAAAAPool(pool).getInterests().mul(block.number - IAAAAPool(pool).lastInterestUpdate()).mul(totalBorrow).div(totalSupply));

        interestAmount = interests.add(_interestPerSupply.mul(amountSupply).div(1e18).sub(interestSettled));
    }

    function getWithdrawAmount(address _lendToken, address _collateralToken, address from) external view returns 
        (uint withdrawAmount, uint interestAmount, uint liquidationAmount)
    {
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");

        uint _totalInterest = getInterestAmount(_lendToken, _collateralToken, from);
        liquidationAmount = getLiquidationAmount(_lendToken, _collateralToken, from);

        uint platformShare = _totalInterest.mul(IConfig(config).getValue(ConfigNames.INTEREST_PLATFORM_SHARE)).div(1e18);
        interestAmount = _totalInterest.sub(platformShare);

        uint totalLiquidation = IAAAAPool(pool).totalLiquidation();

        uint withdrawLiquidationSupplyAmount = totalLiquidation == 0 ? 0 : 
            liquidationAmount.mul(IAAAAPool(pool).totalLiquidationSupplyAmount()).div(totalLiquidation);

        (uint amountSupply, , , , ) = IAAAAPool(pool).supplys(from);            

        if(withdrawLiquidationSupplyAmount > amountSupply.add(interestAmount))
            withdrawAmount = 0;
        else 
            withdrawAmount = amountSupply.add(interestAmount).sub(withdrawLiquidationSupplyAmount);
    }

    function switchStrategy(address _lendToken, address _collateralToken, address _collateralStrategy) external onlyDeveloper
    {
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");
        IAAAAPool(pool).switchStrategy(_collateralStrategy);
    }

    function updatePoolParameter(address _lendToken, address _collateralToken, bytes32 _key, uint _value) external onlyDeveloper
    {
        address pool = IAAAAFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
        require(pool != address(0), "POOL NOT EXIST");
        IConfig(config).setPoolValue(pool, _key, _value);
    }
}