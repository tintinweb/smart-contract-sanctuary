/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: contracts/mocks/lending/MockConvexCompoundGauge.sol



pragma solidity =0.6.12;


interface ILendingInterest {
    function getBorrowInterestRate(uint256 _utilizationRate, uint256 _pid)
        external
        view
        returns (uint256);

    function scaledMantissa() external view returns (uint256);
}

// interface IGaugeManager {
//     function addBorrow(
//         address _gauge,
//         uint256 _borrowAmount,
//         uint256 _supplyAmount
//     ) external;
//     function removeBorrow(
//         address _gauge,
//         uint256 _borrowAmount,
//         uint256 _supplyAmount
//     ) external;
//     function getBorrow(address _gauge) external view returns (uint256, uint256);
// }

interface IBooster {
    function checkPool(uint256 _pid) external view returns (bool);

    function totalSupplyOf(uint256 _pid) external view returns (uint256);

    function lockToken(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external;

    function kill(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external returns (address);

   function batchKill( uint256 _pid, address[] memory _users, uint256 _totalToken ) external returns(address);

    function unLockToken(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external payable;

    function unLockTokenErc20(
        uint256 _pid,
        address _user,
        uint256 _unlockAmount,
        uint256 _repayAmount
    ) external;
}

contract MockConvexCompoundGauge {
    using SafeMath for uint256;

    address immutable convexBooster;
    address immutable compoundBooster;
    // address public liquidate;
    // address public gaugeManager;

    struct PoolInfo {
        uint256 convexPid;
        uint256 compoundPid;
        address liquidate; // lending liquidate
        address interest; // pairToken1 interest
        // address amountOracle; // 定价预言
        address[] supportTokens; // 可借出的token
        uint256 lendingThreshold; // 借款阀值
        uint256 borrowIndex;
    }

    struct UserLending {
        bytes16 lendingId;
        uint256 pid; // pool id
        uint256 token0Value;
        uint256 token1Value;
        uint256 lendingAmount;
        uint256 lendingThreshold;
        address supportToken;
        uint256 utilizationRate; // 使用率
        uint256 interestRate; // 利率
        uint256 interestValue; // 利息
        address liquidate;
        uint256 borrowNumbers; // 借款周期 区块长度
        uint256 startedBlock; // 创建借贷的区块
        bool expired;
    }

    struct LendingInfo {
        address user;
        uint256 pid;
        uint256 userLendingId;
        uint256 borrowIndex;
    }

    struct BorrowInfo {
        uint256 borrowAmount;
        uint256 supplyAmount;
    }

    struct Statistic {
        uint256 totalCollateral;
        uint256 totalBorrow;
        uint256 recentRepayAt;
    }

    PoolInfo[] public poolInfo;

    mapping(address => UserLending[]) public userLendings; // user address => container
    mapping(bytes16 => LendingInfo) public lendings; // lending id => user address
    mapping(uint256 => mapping(uint256 => bytes16)) public poolLending; // pool id => (borrowIndex => user lendingId)
    mapping(uint256 => BorrowInfo) public borrowInfos;
    mapping(address => Statistic) public myStatistics;

    address[] public transformer;

    function transformersLength() external view returns (uint256) {
        return transformer.length;
    }

    function addTransformer(address _transformer) external returns (bool) {
        require(_transformer != address(0), "!transformer setting");

        transformer.push(_transformer);

        return true;
    }

    function clearTransformers() external {
        delete transformer;
    }

    constructor(
        address _convexBooster,
        address _compoundBooster
        // address _liquidate
        // address _gaugeManager
    ) public {
        convexBooster = _convexBooster;
        compoundBooster = _compoundBooster;
        // liquidate = _liquidate;
        // gaugeManager = _gaugeManager;
    }

    function getToken0AveragePrice(uint256 _token)
        public
        view
        returns (uint256)
    {
        return _token.mul(1);
    }

    function getToken1Amount(uint256 _token) public view returns (uint256) {
        return _token.mul(1);
    }

    function getToken1AveragePrice(uint256 _token)
        public
        view
        returns (uint256)
    {
        return _token.mul(1);
    }

    function getToken0Amount(uint256 _token) public view returns (uint256) {
        return _token.mul(1);
    }

    function getAmount(
        uint256 _pid,
        uint256 _token0,
        uint256 _token1
    ) public view returns (uint256, uint256) {
        if (_token0 > 0) {
            // token0 值多少钱
            // 多少钱能换多少token1
            uint256 token0Price = getToken0AveragePrice(_token0);
            uint256 token1 = getToken1Amount(token0Price);

            return (_token0, token1);
        }

        if (_token1 > 0) {
            // token1 值多少钱
            // 多少钱能换多少token0
            uint256 token1Price = getToken1AveragePrice(_token1);
            uint256 token0 = getToken0Amount(token1Price);

            return (token0, _token1);
        }
    }

    function borrow(
        uint256 _pid,
        uint256 _token0, // lp
        uint256 _token1, // ctoken
        uint256 _borrowNumbers,
        uint256 _supportToken
    ) public {
        PoolInfo storage pool = poolInfo[_pid];

        require(IBooster(convexBooster).checkPool(pool.convexPid));
        require(IBooster(compoundBooster).checkPool(pool.compoundPid));

        (uint256 token0Amount, uint256 token1Amount) = getAmount(
            _pid,
            _token0,
            _token1
        );
        
         uint256 lendingAmount  = token1Amount.div(pool.lendingThreshold).div(1000);

        // uint256 utilizationRate = getUtilizationRate(IBooster(compoundBooster).totalSupplyOf(_pid), borrowInfo[_pid].supplyAmount.add(token1Amount),0);
        uint256 utilizationRate = getUtilizationRate(IBooster(compoundBooster).totalSupplyOf(_pid), lendingAmount,0);
        uint256 interestRate = ILendingInterest(pool.interest)
            .getBorrowInterestRate(utilizationRate, _pid);

       
        uint256 interestAmount =  lendingAmount.mul(interestRate).mul(_borrowNumbers).div(1e18);
        bytes16 lendingId = generateId(msg.sender, _pid, pool.borrowIndex);

        IBooster(convexBooster).lockToken(_pid, msg.sender, token0Amount);
        IBooster(compoundBooster).lockToken(
            _pid,
            msg.sender,
            lendingAmount
        );

        userLendings[msg.sender].push(
            UserLending({
                lendingId: lendingId,
                pid: _pid,
                token0Value: token0Amount,
                lendingAmount: lendingAmount,
                lendingThreshold: pool.lendingThreshold,
                supportToken: pool.supportTokens[_supportToken],
                token1Value: token1Amount,
                utilizationRate: utilizationRate,
                interestRate: interestRate,
                interestValue: interestAmount,
                liquidate: pool.liquidate,
                borrowNumbers: _borrowNumbers,
                startedBlock: block.number,
                expired: false
            })
        );

        lendings[lendingId] = LendingInfo({
            user: msg.sender,
            pid: _pid,
            borrowIndex: pool.borrowIndex,
            userLendingId: userLendings[msg.sender].length - 1
        });

        poolLending[_pid][pool.borrowIndex] = lendingId;

        BorrowInfo storage borrowInfo = borrowInfos[_pid];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.add(token0Amount);
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.add(token1Amount);

        
        Statistic storage statistic = myStatistics[msg.sender];

        statistic.totalCollateral = statistic.totalCollateral.add(token0Amount);
        statistic.totalBorrow = statistic.totalBorrow.add(lendingAmount);

        pool.borrowIndex++;

        // IGaugeManager(gaugeManager).addBorrow(address(this), token0Amount,token1Amount);
    }

    function _repayBorrow(
        bytes16 _lendingId,
        uint256 _amount,
        bool isErc20
    ) internal {
        LendingInfo storage lendingInfo = lendings[_lendingId];
        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingId
        ];
        PoolInfo memory pool = poolInfo[userLending.pid];

        require(!userLending.expired, "expired");
        require(
            block.number <=
                userLending.startedBlock.add(userLending.borrowNumbers),
            "Expired"
        );

        require(
             _amount >= userLending.token1Value.add(userLending.interestValue),
            "amount error"
        );

        userLending.expired = true;

        // IERC20(userLending.supportToken).safeTransferFrom(
        //             address(this),
        //             // address(this),
        //             _amount
        //         );

        IBooster(convexBooster).unLockToken(
            pool.convexPid,
            lendingInfo.user,
            userLending.token0Value
        );

        BorrowInfo storage borrowInfo = borrowInfos[userLending.pid];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(userLending.token0Value);
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(userLending.token1Value);

        Statistic storage statistic = myStatistics[msg.sender];

        statistic.totalCollateral = statistic.totalCollateral.sub(userLending.token0Value);
        statistic.totalBorrow = statistic.totalBorrow.sub(userLending.token1Value);
        statistic.recentRepayAt = block.timestamp;

        // borrowInfo[userLending.pid].borrowAmount = borrowInfo[userLending.pid].borrowAmount.sub(userLending.token0Value);

        if (isErc20) {
            IBooster(compoundBooster).unLockToken{value: msg.value}(
                pool.compoundPid,
                lendingInfo.user,
                userLending.token1Value
            );

        // borrowInfo[userLending.pid].supplyAmount = borrowInfo[userLending.pid].supplyAmount.sub(msg.value);
            // IGaugeManager(gaugeManager).removeBorrow(address(this), userLending.token0Value, msg.value);
        } else {
            IBooster(compoundBooster).unLockTokenErc20(
                pool.compoundPid,
                lendingInfo.user,
                userLending.token1Value,
                _amount
            );

            //  borrowInfo[userLending.pid].supplyAmount = borrowInfo[userLending.pid].supplyAmount.sub(_amount);
            // IGaugeManager(gaugeManager).removeBorrow(address(this), userLending.token0Value, _amount);
        }
    }

    function repayBorrow(bytes16 _lendingId) public payable {
        _repayBorrow(_lendingId, msg.value, true);
    }

    function repayBorrow(bytes16 _lendingId, uint256 _amount) public {
        _repayBorrow(_lendingId, _amount, false);
    }

    function kill(bytes16 _lendingId) public {
        LendingInfo storage lendingInfo = lendings[_lendingId];
        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingId
        ];

        PoolInfo memory pool = poolInfo[userLending.pid];

        // require(userLending.expired, "expired!");
        // require(
        //     block.number >
        //         userLending.startedBlock.add(userLending.borrowNumbers),
        //     "Expired"
        // );

        userLending.expired = true;

        BorrowInfo storage borrowInfo = borrowInfos[userLending.pid];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(userLending.token0Value);
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(userLending.token1Value);

        address token0 = IBooster(convexBooster).kill(
            pool.convexPid,
            lendingInfo.user,
            userLending.token0Value
        );

        address token1 = IBooster(compoundBooster).kill(
            pool.compoundPid,
            lendingInfo.user,
            userLending.token1Value
        );

        // IGaugeManager(gaugeManager).removeBorrow(address(this), token0, token1);
    }

    function batchKill(uint256 _pid, bytes16[] memory _lendingIds) public {
        uint256 totalTotal0;
        uint256 totalToken1;
        address[] memory users;
        uint256 index;

        PoolInfo memory pool = poolInfo[_pid];

        for (uint256 i = 0;i<_lendingIds.length;i++) {
             LendingInfo memory lendingInfo = lendings[_lendingIds[i]];

             if (lendingInfo.pid != _pid) continue;

            UserLending storage userLending = userLendings[lendingInfo.user][
                lendingInfo.userLendingId
            ];

            if (userLending.expired) continue;

            userLending.expired = true;

            users[index] = lendingInfo.user;
            index++;

            totalTotal0 = totalTotal0.add(userLending.token0Value);
            totalToken1 = totalToken1.add(userLending.token1Value);
        }

        BorrowInfo storage borrowInfo = borrowInfos[_pid];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(totalTotal0);
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(totalToken1);

        address token0 = IBooster(convexBooster).batchKill(
            pool.convexPid,
            users,
            totalTotal0
        );

        address token1 = IBooster(compoundBooster).batchKill(
            pool.compoundPid,
            users,
            totalToken1
        );

        // PoolInfo memory pool = poolInfo[_pid];

        // for (uint256 i = 0; i < _lendingIds.length; i++) {
        //     LendingInfo storage lendingInfo = lendings[_lendingIds[i]];
        //     UserLending storage userLending = userLendings[lendingInfo.user][
        //         lendingInfo.userLendingId
        //     ];

        //     // require(userLending.expired, "expired!");
        //     // require(
        //     //     block.number >
        //     //         userLending.startedBlock.add(userLending.borrowNumbers),
        //     //     "Expired"
        //     // );

        //     userLending.expired = true;

        //     totalTotal0 = totalTotal0.add(userLending.token0Value);
        //     totalToken1 = totalToken1.add(userLending.token1Value);
        // }

        // address token0 = IBooster(convexBooster).batchKill(
        //     pool.convexPid,
        //     users,
        //     totalTotal0
        // );

        // address token1 = IBooster(compoundBooster).batchKill(
        //     pool.compoundPid,
        //     users,
        //     totalToken1
        // );
    }

    function addPool(
        uint256 _convexPid,
        uint256 _compoundPid,
        address _liquidate,
        address _interest,
        // address _amountOracle,
        address[] memory _supportTokens,
        uint256 _lendingThreshold
    ) public {
        poolInfo.push(
            PoolInfo({
                convexPid: _convexPid,
                compoundPid: _compoundPid,
                liquidate: _liquidate,
                interest: _interest,
                // amountOracle: _amountOracle,
                supportTokens: _supportTokens,
                lendingThreshold: _lendingThreshold,
                borrowIndex: 0
            })
        );
    }

    function DemoAddPool() public {
        uint256 _convexPid = 0;
        uint256 _compoundPid = 0;
        address _liquidate =0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;
        address _interest = 0x8bc05a422ed3E6Df128F8a88384CCe0173176115;
        // address _amountOracle = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;
        
        address[] memory supportTokens = new address[](2);
        uint256 _lendingThreshold = 1000;

        supportTokens[0] = 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15;
        supportTokens[1] = 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15;

        addPool(_convexPid,_compoundPid,_liquidate,_interest,supportTokens,_lendingThreshold);
    }

    function toBytes16(uint256 x) internal pure returns (bytes16 b) {
        return bytes16(bytes32(x));
    }

    function generateId(
        address x,
        uint256 y,
        uint256 z
    ) public pure returns (bytes16 b) {
        b = toBytes16(uint256(keccak256(abi.encodePacked(x, y, z))));
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function cursor(
        uint256 _pid,
        uint256 _offset,
        uint256 _size
    ) public view returns (bytes16[] memory,uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 size = _offset + _size > pool.borrowIndex ?  pool.borrowIndex - _offset: _size;
        uint256 index;

        bytes16[] memory userLendingIds = new bytes16[](size);

        for (uint256 i = 0; i <size; i++) {
            bytes16 userLendingId = poolLending[_pid][_offset+i];

            userLendingIds[index] = userLendingId;
            index++;
        }

        return (userLendingIds,pool.borrowIndex);
    }

    function calculateRepayAmount(bytes16 _lendingId) public view returns(uint256) {
        LendingInfo storage lendingInfo = lendings[_lendingId];
        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingId
        ];

        if (userLending.expired) return 0;

        return userLending.token1Value.add(userLending.interestValue);
    }

    function getPoolSupportTokens(uint256 _pid) public view returns(address[] memory) {
        PoolInfo memory pool = poolInfo[_pid];

        return pool.supportTokens;
    }

    // 资金使用率
    function getUtilizationRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public view returns (uint256) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        // return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
        return borrows.mul(1e18).div(cash.sub(reserves));
    }

    function testGetUtilizationRate(uint256 _pid,uint256 token1Amount) public view returns(uint256,uint256){
         PoolInfo storage pool = poolInfo[_pid];
        uint256 utilizationRate = getUtilizationRate(IBooster(compoundBooster).totalSupplyOf(_pid), borrowInfos[_pid].supplyAmount.add(token1Amount),0);
        uint256 interestRate = ILendingInterest(pool.interest)
            .getBorrowInterestRate(utilizationRate.mul(1000).div(1e18), 0);

            return (utilizationRate,interestRate);
    }
}