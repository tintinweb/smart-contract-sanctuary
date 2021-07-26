/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity 0.5.14;


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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface ICToken {
    function supplyRatePerBlock() external view returns (uint);
    function borrowRatePerBlock() external view returns (uint);
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function redeem(uint redeemAmount) external returns (uint);
    function exchangeRateStore() external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function balanceOf(address owner) external view returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint);
}

interface ICETH{
    function mint() external payable;
}

interface IController {
    function fastForward(uint blocks) external returns (uint);
    function getBlockNumber() external view returns (uint);
}


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

contract Constant {
    enum ActionType { DepositAction, WithdrawAction, BorrowAction, RepayAction }
    address public constant ETH_ADDR = 0x000000000000000000000000000000000000000E;
    uint256 public constant INT_UNIT = 10 ** uint256(18);
    uint256 public constant ACCURACY = 10 ** 18;
    uint256 public constant BLOCKS_PER_YEAR = 2102400;
}

contract Bank is Constant, Initializable{
    using SafeMath for uint256;

    mapping(address => uint256) public totalLoans;     // amount of lended tokens
    mapping(address => uint256) public totalReserve;   // amount of tokens in reservation
    mapping(address => uint256) public totalCompound;  // amount of tokens in compound
    // Token => block-num => rate
    mapping(address => mapping(uint => uint)) public depositRateIndex; // the index curve of deposit rate
    // Token => block-num => rate
    mapping(address => mapping(uint => uint)) public borrowRateIndex;   // the index curve of borrow rate
    // token address => block number
    mapping(address => uint) public lastCheckpoint;            // last checkpoint on the index curve
    // cToken address => rate
    mapping(address => uint) public lastCTokenExchangeRate;    // last compound cToken exchange rate
    mapping(address => ThirdPartyPool) compoundPool;    // the compound pool

    IGlobalConfig globalConfig;            // global configuration contract address

    mapping(address => mapping(uint => uint)) public depositFINRateIndex;
    mapping(address => mapping(uint => uint)) public borrowFINRateIndex;
    mapping(address => uint) public lastDepositFINRateCheckpoint;
    mapping(address => uint) public lastBorrowFINRateCheckpoint;

    modifier onlyAuthorized() {
        require(msg.sender == address(globalConfig.savingAccount()) || msg.sender == address(globalConfig.accounts()),
            "Only authorized to call from DeFiner internal contracts.");
        _;
    }

    struct ThirdPartyPool {
        bool supported;             // if the token is supported by the third party platforms such as Compound
        uint capitalRatio;          // the ratio of the capital in third party to the total asset
        uint depositRatePerBlock;   // the deposit rate of the token in third party
        uint borrowRatePerBlock;    // the borrow rate of the token in third party
    }

    event UpdateIndex(address indexed token, uint256 depositRateIndex, uint256 borrowRateIndex);
    event UpdateDepositFINIndex(address indexed _token, uint256 depositFINRateIndex);
    event UpdateBorrowFINIndex(address indexed _token, uint256 borrowFINRateIndex);

    /**
     * Initialize the Bank
     * @param _globalConfig the global configuration contract
     */
    function initialize(
        IGlobalConfig _globalConfig
    ) public initializer {
        globalConfig = _globalConfig;
    }

    /**
     * Total amount of the token in Saving account
     * @param _token token address
     */
    function getTotalDepositStore(address _token) public view returns(uint) {
        address cToken = ITokenRegistry(globalConfig.tokenInfoRegistry()).getCToken(_token);
        // totalLoans[_token] = U   totalReserve[_token] = R
        return totalCompound[cToken].add(totalLoans[_token]).add(totalReserve[_token]); // return totalAmount = C + U + R
    }

    /**
     * Update total amount of token in Compound as the cToken price changed
     * @param _token token address
     */
    function updateTotalCompound(address _token) internal {
        address cToken = ITokenRegistry(globalConfig.tokenInfoRegistry()).getCToken(_token);
        if(cToken != address(0)) {
            totalCompound[cToken] = ICToken(cToken).balanceOfUnderlying(address(globalConfig.savingAccount()));
        }
    }

    /**
     * Update the total reservation. Before run this function, make sure that totalCompound has been updated
     * by calling updateTotalCompound. Otherwise, totalCompound may not equal to the exact amount of the
     * token in Compound.
     * @param _token token address
     * @param _action indicate if user's operation is deposit or withdraw, and borrow or repay.
     * @return the actuall amount deposit/withdraw from the saving pool
     */
    function updateTotalReserve(address _token, uint _amount, ActionType _action) internal returns(uint256 compoundAmount){
        address cToken = ITokenRegistry(globalConfig.tokenInfoRegistry()).getCToken(_token);
        uint totalAmount = getTotalDepositStore(_token);
        if (_action == ActionType.DepositAction || _action == ActionType.RepayAction) {
            // Total amount of token after deposit or repay
            if (_action == ActionType.DepositAction)
                totalAmount = totalAmount.add(_amount);
            else
                totalLoans[_token] = totalLoans[_token].sub(_amount);

            // Expected total amount of token in reservation after deposit or repay
            uint totalReserveBeforeAdjust = totalReserve[_token].add(_amount);

            if (cToken != address(0) &&
            totalReserveBeforeAdjust > totalAmount.mul(globalConfig.maxReserveRatio()).div(100)) {
                uint toCompoundAmount = totalReserveBeforeAdjust.sub(totalAmount.mul(globalConfig.midReserveRatio()).div(100));
                //toCompound(_token, toCompoundAmount);
                compoundAmount = toCompoundAmount;
                totalCompound[cToken] = totalCompound[cToken].add(toCompoundAmount);
                totalReserve[_token] = totalReserve[_token].add(_amount).sub(toCompoundAmount);
            }
            else {
                totalReserve[_token] = totalReserve[_token].add(_amount);
            }
        } else {
            // The lack of liquidity exception happens when the pool doesn't have enough tokens for borrow/withdraw
            // It happens when part of the token has lended to the other accounts.
            // However in case of withdrawAll, even if the token has no loan, this requirment may still false because
            // of the precision loss in the rate calcuation. So we put a logic here to deal with this case: in case
            // of withdrawAll and there is no loans for the token, we just adjust the balance in bank contract to the
            // to the balance of that individual account.
            if(_action == ActionType.WithdrawAction) {
                if(totalLoans[_token] != 0)
                    require(getPoolAmount(_token) >= _amount, "Lack of liquidity when withdraw.");
                else if (getPoolAmount(_token) < _amount)
                    totalReserve[_token] = _amount.sub(totalCompound[cToken]);
                totalAmount = getTotalDepositStore(_token);
            }
            else
                require(getPoolAmount(_token) >= _amount, "Lack of liquidity when borrow.");

            // Total amount of token after withdraw or borrow
            if (_action == ActionType.WithdrawAction)
                totalAmount = totalAmount.sub(_amount);
            else
                totalLoans[_token] = totalLoans[_token].add(_amount);

            // Expected total amount of token in reservation after deposit or repay
            uint totalReserveBeforeAdjust = totalReserve[_token] > _amount ? totalReserve[_token].sub(_amount) : 0;

            // Trigger fromCompound if the new reservation ratio is less than 10%
            if(cToken != address(0) &&
            (totalAmount == 0 || totalReserveBeforeAdjust < totalAmount.mul(globalConfig.minReserveRatio()).div(100))) {

                uint totalAvailable = totalReserve[_token].add(totalCompound[cToken]).sub(_amount);
                if (totalAvailable < totalAmount.mul(globalConfig.midReserveRatio()).div(100)){
                    // Withdraw all the tokens from Compound
                    compoundAmount = totalCompound[cToken];
                    totalCompound[cToken] = 0;
                    totalReserve[_token] = totalAvailable;
                } else {
                    // Withdraw partial tokens from Compound
                    uint totalInCompound = totalAvailable.sub(totalAmount.mul(globalConfig.midReserveRatio()).div(100));
                    compoundAmount = totalCompound[cToken].sub(totalInCompound);
                    totalCompound[cToken] = totalInCompound;
                    totalReserve[_token] = totalAvailable.sub(totalInCompound);
                }
            }
            else {
                totalReserve[_token] = totalReserve[_token].sub(_amount);
            }
        }
        return compoundAmount;
    }

     function update(address _token, uint _amount, ActionType _action) public onlyAuthorized returns(uint256 compoundAmount) {
        updateTotalCompound(_token);
        // updateTotalLoan(_token);
        compoundAmount = updateTotalReserve(_token, _amount, _action);
        return compoundAmount;
    }

    /**
     * The function is called in Bank.deposit(), Bank.withdraw() and Accounts.claim() functions.
     * The function should be called AFTER the newRateIndexCheckpoint function so that the account balances are
     * accurate, and BEFORE the account balance acutally updated due to deposit/withdraw activities.
     */
    function updateDepositFINIndex(address _token) public onlyAuthorized{
        uint currentBlock = getBlockNumber();
        uint deltaBlock;
        // If it is the first deposit FIN rate checkpoint, set the deltaBlock value be 0 so that the first
        // point on depositFINRateIndex is zero.
        deltaBlock = lastDepositFINRateCheckpoint[_token] == 0 ? 0 : currentBlock.sub(lastDepositFINRateCheckpoint[_token]);
        // If the totalDeposit of the token is zero, no FIN token should be mined and the FINRateIndex is unchanged.
        depositFINRateIndex[_token][currentBlock] = depositFINRateIndex[_token][lastDepositFINRateCheckpoint[_token]].add(
            getTotalDepositStore(_token) == 0 ? 0 : depositRateIndex[_token][lastCheckpoint[_token]]
                .mul(deltaBlock)
                .mul(ITokenRegistry(globalConfig.tokenInfoRegistry()).depositeMiningSpeeds(_token))
                .div(getTotalDepositStore(_token)));
        lastDepositFINRateCheckpoint[_token] = currentBlock;

        emit UpdateDepositFINIndex(_token, depositFINRateIndex[_token][currentBlock]);
    }

    function updateBorrowFINIndex(address _token) public onlyAuthorized{
        uint currentBlock = getBlockNumber();
        uint deltaBlock;
        // If it is the first borrow FIN rate checkpoint, set the deltaBlock value be 0 so that the first
        // point on borrowFINRateIndex is zero.
        deltaBlock = lastBorrowFINRateCheckpoint[_token] == 0 ? 0 : currentBlock.sub(lastBorrowFINRateCheckpoint[_token]);
        // If the totalBorrow of the token is zero, no FIN token should be mined and the FINRateIndex is unchanged.
        borrowFINRateIndex[_token][currentBlock] = borrowFINRateIndex[_token][lastBorrowFINRateCheckpoint[_token]].add(
            totalLoans[_token] == 0 ? 0 : borrowRateIndex[_token][lastCheckpoint[_token]]
                    .mul(deltaBlock)
                    .mul(ITokenRegistry(globalConfig.tokenInfoRegistry()).borrowMiningSpeeds(_token))
                    .div(totalLoans[_token]));
        lastBorrowFINRateCheckpoint[_token] = currentBlock;

        emit UpdateBorrowFINIndex(_token, borrowFINRateIndex[_token][currentBlock]);
    }

    function updateMining(address _token) public onlyAuthorized{
        newRateIndexCheckpoint(_token);
        updateTotalCompound(_token);
    }

    /**
     * Get the borrowing interest rate Borrowing interest rate.
     * @param _token token address
     * @return the borrow rate for the current block
     */
    function getBorrowRatePerBlock(address _token) public view returns(uint) {
        if(!ITokenRegistry(globalConfig.tokenInfoRegistry()).isSupportedOnCompound(_token))
        // If the token is NOT supported by the third party, borrowing rate = 3% + U * 15%.
            return getCapitalUtilizationRatio(_token).mul(globalConfig.rateCurveSlope()).div(INT_UNIT).add(globalConfig.rateCurveConstant()).div(BLOCKS_PER_YEAR);

        // if the token is suppored in third party, borrowing rate = Compound Supply Rate * 0.4 + Compound Borrow Rate * 0.6
        return (compoundPool[_token].depositRatePerBlock).mul(globalConfig.compoundSupplyRateWeights()).
            add((compoundPool[_token].borrowRatePerBlock).mul(globalConfig.compoundBorrowRateWeights())).div(10);
    }

    /**
    * Get Deposit Rate.  Deposit APR = (Borrow APR * Utilization Rate (U) +  Compound Supply Rate *
    * Capital Compound Ratio (C) )* (1- DeFiner Community Fund Ratio (D)). The scaling is 10 ** 18
    * @param _token token address
    * @return deposite rate of blocks before the current block
    */
    function getDepositRatePerBlock(address _token) public view returns(uint) {
        uint256 borrowRatePerBlock = getBorrowRatePerBlock(_token);
        uint256 capitalUtilRatio = getCapitalUtilizationRatio(_token);
        if(!ITokenRegistry(globalConfig.tokenInfoRegistry()).isSupportedOnCompound(_token))
            return borrowRatePerBlock.mul(capitalUtilRatio).div(INT_UNIT);

        return borrowRatePerBlock.mul(capitalUtilRatio).add(compoundPool[_token].depositRatePerBlock
            .mul(compoundPool[_token].capitalRatio)).div(INT_UNIT);
    }

    /**
     * Get capital utilization. Capital Utilization Rate (U )= total loan outstanding / Total market deposit
     * @param _token token address
     */
    function getCapitalUtilizationRatio(address _token) public view returns(uint) {
        uint256 totalDepositsNow = getTotalDepositStore(_token);
        if(totalDepositsNow == 0) {
            return 0;
        } else {
            return totalLoans[_token].mul(INT_UNIT).div(totalDepositsNow);
        }
    }

    /**
     * Ratio of the capital in Compound
     * @param _token token address
     */
    function getCapitalCompoundRatio(address _token) public view returns(uint) {
        address cToken = ITokenRegistry(globalConfig.tokenInfoRegistry()).getCToken(_token);
        if(totalCompound[cToken] == 0 ) {
            return 0;
        } else {
            return uint(totalCompound[cToken].mul(INT_UNIT).div(getTotalDepositStore(_token)));
        }
    }

    /**
     * It's a utility function. Get the cummulative deposit rate in a block interval ending in current block
     * @param _token token address
     * @param _depositRateRecordStart the start block of the interval
     * @dev This function should always be called after current block is set as a new rateIndex point.
     */
    function getDepositAccruedRate(address _token, uint _depositRateRecordStart) external view returns (uint256) {
        uint256 depositRate = depositRateIndex[_token][_depositRateRecordStart];
        require(depositRate != 0, "_depositRateRecordStart is not a check point on index curve.");
        return depositRateIndexNow(_token).mul(INT_UNIT).div(depositRate);
    }

    /**
     * Get the cummulative borrow rate in a block interval ending in current block
     * @param _token token address
     * @param _borrowRateRecordStart the start block of the interval
     * @dev This function should always be called after current block is set as a new rateIndex point.
     */
    function getBorrowAccruedRate(address _token, uint _borrowRateRecordStart) external view returns (uint256) {
        uint256 borrowRate = borrowRateIndex[_token][_borrowRateRecordStart];
        require(borrowRate != 0, "_borrowRateRecordStart is not a check point on index curve.");
        return borrowRateIndexNow(_token).mul(INT_UNIT).div(borrowRate);
    }

    /**
     * Set a new rate index checkpoint.
     * @param _token token address
     * @dev The rate set at the checkpoint is the rate from the last checkpoint to this checkpoint
     */
    function newRateIndexCheckpoint(address _token) public onlyAuthorized {

        // return if the rate check point already exists
        uint blockNumber = getBlockNumber();
        if (blockNumber == lastCheckpoint[_token])
            return;

        uint256 UNIT = INT_UNIT;
        address cToken = ITokenRegistry(globalConfig.tokenInfoRegistry()).getCToken(_token);

        // If it is the first check point, initialize the rate index
        uint256 previousCheckpoint = lastCheckpoint[_token];
        if (lastCheckpoint[_token] == 0) {
            if(cToken == address(0)) {
                compoundPool[_token].supported = false;
                borrowRateIndex[_token][blockNumber] = UNIT;
                depositRateIndex[_token][blockNumber] = UNIT;
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
            }
            else {
                compoundPool[_token].supported = true;
                uint cTokenExchangeRate = ICToken(cToken).exchangeRateCurrent();
                // Get the curretn cToken exchange rate in Compound, which is need to calculate DeFiner's rate
                compoundPool[_token].capitalRatio = getCapitalCompoundRatio(_token);
                compoundPool[_token].borrowRatePerBlock = ICToken(cToken).borrowRatePerBlock();  // initial value
                compoundPool[_token].depositRatePerBlock = ICToken(cToken).supplyRatePerBlock(); // initial value
                borrowRateIndex[_token][blockNumber] = UNIT;
                depositRateIndex[_token][blockNumber] = UNIT;
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
                lastCTokenExchangeRate[cToken] = cTokenExchangeRate;
            }

        } else {
            if(cToken == address(0)) {
                compoundPool[_token].supported = false;
                borrowRateIndex[_token][blockNumber] = borrowRateIndexNow(_token);
                depositRateIndex[_token][blockNumber] = depositRateIndexNow(_token);
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
            } else {
                compoundPool[_token].supported = true;
                uint cTokenExchangeRate = ICToken(cToken).exchangeRateCurrent();
                // Get the curretn cToken exchange rate in Compound, which is need to calculate DeFiner's rate
                compoundPool[_token].capitalRatio = getCapitalCompoundRatio(_token);
                compoundPool[_token].borrowRatePerBlock = ICToken(cToken).borrowRatePerBlock();
                compoundPool[_token].depositRatePerBlock = cTokenExchangeRate.mul(UNIT).div(lastCTokenExchangeRate[cToken])
                    .sub(UNIT).div(blockNumber.sub(lastCheckpoint[_token]));
                borrowRateIndex[_token][blockNumber] = borrowRateIndexNow(_token);
                depositRateIndex[_token][blockNumber] = depositRateIndexNow(_token);
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
                lastCTokenExchangeRate[cToken] = cTokenExchangeRate;
            }
        }

        // Update the total loan
        if(borrowRateIndex[_token][blockNumber] != UNIT) {
            totalLoans[_token] = totalLoans[_token].mul(borrowRateIndex[_token][blockNumber])
                .div(borrowRateIndex[_token][previousCheckpoint]);
        }

        emit UpdateIndex(_token, depositRateIndex[_token][getBlockNumber()], borrowRateIndex[_token][getBlockNumber()]);
    }

    /**
     * Calculate a token deposite rate of current block
     * @param _token token address
     * @dev This is an looking forward estimation from last checkpoint and not the exactly rate that the user will pay or earn.
     */
    function depositRateIndexNow(address _token) public view returns(uint) {
        uint256 lcp = lastCheckpoint[_token];
        // If this is the first checkpoint, set the index be 1.
        if(lcp == 0)
            return INT_UNIT;

        uint256 lastDepositeRateIndex = depositRateIndex[_token][lcp];
        uint256 depositRatePerBlock = getDepositRatePerBlock(_token);
        // newIndex = oldIndex*(1+r*delta_block). If delta_block = 0, i.e. the last checkpoint is current block, index doesn't change.
        return lastDepositeRateIndex.mul(getBlockNumber().sub(lcp).mul(depositRatePerBlock).add(INT_UNIT)).div(INT_UNIT);
    }

    /**
     * Calculate a token borrow rate of current block
     * @param _token token address
     */
    function borrowRateIndexNow(address _token) public view returns(uint) {
        uint256 lcp = lastCheckpoint[_token];
        // If this is the first checkpoint, set the index be 1.
        if(lcp == 0)
            return INT_UNIT;
        uint256 lastBorrowRateIndex = borrowRateIndex[_token][lcp];
        uint256 borrowRatePerBlock = getBorrowRatePerBlock(_token);
        return lastBorrowRateIndex.mul(getBlockNumber().sub(lcp).mul(borrowRatePerBlock).add(INT_UNIT)).div(INT_UNIT);
    }

    /**
	 * Get the state of the given token
     * @param _token token address
	 */
    function getTokenState(address _token) public view returns (uint256 deposits, uint256 loans, uint256 reserveBalance, uint256 remainingAssets){
        return (
        getTotalDepositStore(_token),
        totalLoans[_token],
        totalReserve[_token],
        totalReserve[_token].add(totalCompound[ITokenRegistry(globalConfig.tokenInfoRegistry()).getCToken(_token)])
        );
    }

    function getPoolAmount(address _token) public view returns(uint) {
        return totalReserve[_token].add(totalCompound[ITokenRegistry(globalConfig.tokenInfoRegistry()).getCToken(_token)]);
    }

    function deposit(address _to, address _token, uint256 _amount) external onlyAuthorized {

        require(_amount != 0, "Amount is zero");

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateDepositFINIndex(_token);

        // Update tokenInfo. Add the _amount to principal, and update the last deposit block in tokenInfo
        IAccount(globalConfig.accounts()).deposit(_to, _token, _amount);

        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint compoundAmount = update(_token, _amount, ActionType.DepositAction);

        if(compoundAmount > 0) {
            ISavingAccount(globalConfig.savingAccount()).toCompound(_token, compoundAmount);
        }
    }

    function borrow(address _from, address _token, uint256 _amount) external onlyAuthorized {

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateBorrowFINIndex(_token);

        // Update tokenInfo for the user
        IAccount(globalConfig.accounts()).borrow(_from, _token, _amount);

        // Update pool balance
        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint compoundAmount = update(_token, _amount, ActionType.BorrowAction);

        if(compoundAmount > 0) {
            ISavingAccount(globalConfig.savingAccount()).fromCompound(_token, compoundAmount);
        }
    }

    function repay(address _to, address _token, uint256 _amount) external onlyAuthorized returns(uint) {

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateBorrowFINIndex(_token);

        // Sanity check
        require(IAccount(globalConfig.accounts()).getBorrowPrincipal(_to, _token) > 0,
            "Token BorrowPrincipal must be greater than 0. To deposit balance, please use deposit button."
        );

        // Update tokenInfo
        uint256 remain = IAccount(globalConfig.accounts()).repay(_to, _token, _amount);

        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint compoundAmount = update(_token, _amount.sub(remain), ActionType.RepayAction);
        if(compoundAmount > 0) {
           ISavingAccount(globalConfig.savingAccount()).toCompound(_token, compoundAmount);
        }

        // Return actual amount repaid
        return _amount.sub(remain);
    }

    /**
     * Withdraw a token from an address
     * @param _from address to be withdrawn from
     * @param _token token address
     * @param _amount amount to be withdrawn
     * @return The actually amount withdrawed, which will be the amount requested minus the commission fee.
     */
    function withdraw(address _from, address _token, uint256 _amount) external onlyAuthorized returns(uint) {

        require(_amount != 0, "Amount is zero");

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateDepositFINIndex(_token);

        // Withdraw from the account
        uint amount = IAccount(globalConfig.accounts()).withdraw(_from, _token, _amount);

        // Update pool balance
        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint compoundAmount = update(_token, amount, ActionType.WithdrawAction);

        // Check if there are enough tokens in the pool.
        if(compoundAmount > 0) {
            ISavingAccount(globalConfig.savingAccount()).fromCompound(_token, compoundAmount);
        }

        return amount;
    }

    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() private view returns (uint) {
        return block.number;
    }
}

interface IGlobalConfig {
    function constants() external view returns (address);
    function tokenInfoRegistry() external view returns (address);
    function chainLink() external view returns (address);
    function bank() external view returns (address);
    function savingAccount() external view returns (address);
    function accounts() external view returns (address);
    function maxReserveRatio() external view returns (uint256);
    function midReserveRatio() external view returns (uint256);
    function minReserveRatio() external view returns (uint256);
    function rateCurveSlope() external view returns (uint256);
    function rateCurveConstant() external view returns (uint256);
    function compoundSupplyRateWeights() external view returns (uint256);
    function compoundBorrowRateWeights() external view returns (uint256);
}

interface ITokenRegistry {
    function getTokenDecimals(address) external view returns (uint8);
    function getCToken(address) external view returns (address);
    function depositeMiningSpeeds(address) external view returns (uint256);
    function borrowMiningSpeeds(address) external view returns (uint256);
    function isSupportedOnCompound(address) external view returns (bool);
}

interface IAccount {
    function deposit(address, address, uint256) external;
    function borrow(address, address, uint256) external;
    function getBorrowPrincipal(address, address) external view returns (uint256);
    function withdraw(address, address, uint256) external returns (uint256);
    function repay(address, address, uint256) external returns (uint256);
}

interface ISavingAccount {
    function toCompound(address, uint256) external;
    function fromCompound(address, uint256) external;
}