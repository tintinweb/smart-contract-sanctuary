/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

interface IPairXCore {

    // 向池子中存入资产
    function deposit( address token , address to , uint amount ) external  ;

    // 取回指定的Token资产及奖励
    function claim( address token ) external returns (uint amount) ;

    // 提取PairX的挖矿奖励,可以提取当前已解锁的份额
    function redeem(address token ) external returns (uint amount ) ;

    /**
     *  结束流动性挖矿
     */
    function finish() external ;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
}

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

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


contract PairPairX is IPairXCore {
    using SafeMath for uint256;

    address public Owner;
    uint8 public Fee = 10;
    address public FeeTo;

    uint256 private MinToken0Deposit;
    uint256 private MinToken1Deposit;

    // for pairx
    address public RewardToken; // Reward Token
    uint256 public RewardAmount;

    uint8 public Status = 0; // 0 = not init , 1 = open , 2 = locked , 9 = finished
    // uint public MaxLockDays = 365 ;
    uint256 public RewardBeginTime = 0; // 开始PairX计算日期,在addLiquidityAndStake时设置
    uint256 public DepositEndTime = 0; // 存入结束时间
    uint256 public StakeEndTime = 0;

    address public UniPairAddress; // 配对奖励Token address
    address public MainToken; // stake and reward token
    address public Token0; // Already sorted .
    address public Token1;
    TokenRecord Token0Record;
    TokenRecord Token1Record;

    address public StakeAddress; //
    // uint StakeAmount ;

    uint RewardGottedTotal ;    //已提现总数
    mapping(address => mapping(address => uint256)) UserBalance; // 用户充值余额 UserBalance[sender][token]
    mapping(address => mapping(address => uint256)) RewardGotted; // RewardGotted[sender][token]

    event Deposit(address from, address to, address token, uint256 amount);
    event Claim(
        address from,
        address to,
        address token,
        uint256 principal,
        uint256 interest,
        uint256 reward
    );

    struct TokenRecord {
        uint256 total; // 存入总代币计数
        uint256 reward; // 分配的总奖励pairx,默认先分配40%,最后20%根据规则分配
        uint256 compensation; // PairX补贴额度,默认为0
        uint256 stake; // lon staking token
        uint256 withdraw; // 可提现总量，可提现代币需要包含挖矿奖励部分
        uint256 mint; // 挖矿奖励
    }

    modifier onlyOwner() {
        require(msg.sender == Owner, "no role.");
        _;
    }

    modifier isActive() {
        require(block.timestamp < StakeEndTime, "Mining was expired.");
        require(Status == 1, "Not open.");
        _;
    }

    constructor(address owner) public {
        Owner = owner;
    }

    function active(
        address feeTo,
        address pair,
        address main,
        address stake,
        uint256 stakeEndTime
    ) external onlyOwner {
        FeeTo = feeTo;
        UniPairAddress = pair;
        MainToken = main;
        // 通过接口读取token0和token1的值
        IUniswapV2Pair uni = IUniswapV2Pair(UniPairAddress);
        Token0 = uni.token0();
        Token1 = uni.token1();

        StakeEndTime = stakeEndTime; //按秒计算，不再按天计算了
        StakeAddress = stake;
    }

    /**
     *  deposit reward-tokens (PairX token).
     */
    function setReward(
        address reward,
        uint256 amount,
        uint256 token0min,
        uint256 token1min,
        uint256 depositEndTime
    ) external onlyOwner {
        RewardToken = reward;
        TransferHelper.safeTransferFrom(
            reward,
            msg.sender,
            address(this),
            amount
        );
        RewardAmount = RewardAmount.add(amount);
        MinToken0Deposit = token0min;
        MinToken1Deposit = token1min;
        Status = 1;

        //update TokenRecord
        uint256 defaultReward = RewardAmount.mul(4).div(10);
        Token0Record.reward = defaultReward;
        Token1Record.reward = defaultReward;
        DepositEndTime = depositEndTime;
    }

    function tokenRecordInfo(address token)
        external
        view
        returns (
            uint256 free,
            uint256 total,
            uint256 reward,
            uint256 stake,
            uint256 withdraw
        )
    {
        if (token == Token0) {
            // free = _tokenBalance(Token0);
            free = Token0Record.withdraw ;
            total = Token0Record.total;
            reward = Token0Record.reward;
            stake = Token0Record.stake;
            withdraw = Token0Record.withdraw;
        } else {
            // free = _tokenBalance(Token1);
            free = Token1Record.withdraw ;
            total = Token1Record.total;
            reward = Token1Record.reward;
            stake = Token1Record.stake;
            withdraw = Token1Record.withdraw;
        }

    }

    function info() external view returns (
        // address owner , uint8 fee , address feeTo ,
        uint minToken0Deposit , uint minToken1Deposit ,
        address rewardToken  , uint rewardAmount , 
        uint8 status , uint stakeEndTime , 
        address token0 , address token1 , address pair ,
        address mainToken , uint rewardBeginTime , uint depositEndTime
    ) {
        minToken0Deposit = MinToken0Deposit ;
        minToken1Deposit = MinToken1Deposit ;
        rewardToken = RewardToken ;
        rewardAmount = RewardAmount ;
        status = Status ;
        stakeEndTime = StakeEndTime ;
        token0 = Token0 ;
        token1 = Token1 ;
        mainToken = MainToken ;
        pair = UniPairAddress ;
        rewardBeginTime = RewardBeginTime ;
        depositEndTime = DepositEndTime ;
    } 

    function depositInfo( address sender , address token ) external view returns 
     ( uint depositBalance ,uint depositTotal , uint leftDays ,
       uint lockedReward , uint freeReward , uint gottedReward ) {
        depositBalance = UserBalance[sender][token] ;
        if( token == Token0 ) {
            depositTotal = Token0Record.total ;
        } else {
            depositTotal = Token1Record.total ;
        }
        // rewardTotal = RewardTotal[sender] ;
        if( sender != address(0) ){
            ( leftDays , lockedReward , freeReward , gottedReward )
                = getRewardRecord( token , sender ) ;
        } else {
            leftDays = 0 ;
            lockedReward = 0 ;
            freeReward = 0 ;
            gottedReward = 0 ;
        }
    }

    function getRewardRecord(address token , address sender ) public view returns  
     ( uint leftDays , uint locked , uint free , uint gotted ) {

        uint nowDate = getDateTime( block.timestamp ) ;
        //计算一共可提取的奖励
        uint depositAmount = UserBalance[sender][token] ;
        TokenRecord memory record = token == Token0 ? Token0Record : Token1Record ;

        leftDays = _leftDays( StakeEndTime , nowDate ) ;
        locked = 0 ;
        free = 0 ;
        gotted = 0 ;
        if( depositAmount == 0 ) {
            return ( leftDays , 0 , 0 , 0 );
        }

        if( record.reward == 0 ) {
            return ( leftDays , 0 , 0 , 0 );
        }

        gotted = RewardGotted[sender][token] ;

        //换个计算方法,计算每秒可获得的收益
        uint lockedTimes = _leftDays( StakeEndTime , RewardBeginTime ) ;
        uint oneTimeReward = record.reward.div( lockedTimes ) ;
        uint freeTime ;

        if( nowDate > StakeEndTime ) {
            leftDays = 0 ;
            locked = 0 ;
            freeTime = lockedTimes ; 
        } else {
            leftDays = _leftDays( StakeEndTime , nowDate ) ;
            freeTime = lockedTimes.sub( leftDays ) ;
        }

        // 防止溢出,保留3位精度
        uint maxReward = depositAmount.mul( oneTimeReward ).div(1e15)
            .mul( lockedTimes ).div( record.total.div(1e15) );
            
        if( Status == 2 ) {
            free = depositAmount.mul( oneTimeReward ).div(1e15)
                .mul( freeTime ).div( record.total.div(1e15) ); 
            if( free.add(gotted) > maxReward ){
                locked = 0 ;
            } else {
                locked = maxReward.sub( free ).sub( gotted ) ;
            }
        } else if ( Status == 9 ) {
            free = maxReward.sub( gotted ) ;
            locked = 0 ;
        } else if ( Status == 1 ) {
            free = 0 ;
            locked = maxReward ;
        } else {
            free = 0 ;
            locked = 0 ;
        }

    }    
    
    function getDateTime( uint timestamp ) public pure returns ( uint ) {
        // timeValue = timestamp ;
        return timestamp ;
    }

    function _sendReward( address to , uint amount ) internal {
        //Give reward tokens .
        uint balance = RewardAmount.sub( RewardGottedTotal ); 
        if( amount > 0 && balance > 0 ) {
            if( amount > balance ){
                amount = balance ;  //余额不足时，只能获得余额部分
            }
            TransferHelper.safeTransfer( RewardToken , to , amount ) ;
            // RewardAmount = RewardAmount.sub( amount ) ;  使用balanceOf 确定余额
        }
    }

    function _deposit(address sender ,  address token , uint amount ) internal {
        if( token == Token0 ) {
            require( amount > MinToken0Deposit , "Deposit tokens is too less." ) ;
        }

        if( token == Token1 ) {
            require( amount > MinToken1Deposit , "Deposit tokens is too less." ) ;
        }

        if( token == Token0 ) {
            Token0Record.total = Token0Record.total.add( amount ) ;
            Token0Record.withdraw = Token0Record.total ;
        }

        if( token == Token1 ) {
            Token1Record.total = Token1Record.total.add( amount ) ;
            Token1Record.withdraw = Token1Record.total ;
        }

        UserBalance[sender][token] = UserBalance[sender][token].add(amount );
    }

    function _fee( uint amount ) internal returns ( uint fee ) {
        fee = amount.mul( Fee ).div( 100 ) ;
        if( fee > 0 ) {
            _safeTransfer( MainToken , FeeTo , fee ) ;
        }
    }

    function _leftDays(uint afterDate , uint beforeDate ) internal pure returns( uint ) {
        if( afterDate <= beforeDate ) {
            return 0 ;
        } else {
            return afterDate.sub(beforeDate ) ;
            // 将由天计算改为由秒计算
            //return afterDate.sub(beforeDate).div( OneDay )  ;
        }
    }

    /*
    *   向池子中存入资产, 目前该接口只支持erc20代币.
    *   如果需要使用eth，会在前置合约进行处理,将eth兑换成WETH
    */
    function deposit( address token , address to , uint amount  ) public override isActive {
        
        require( Status == 1 , "Not allow deposit ." ) ;
        require( (token == Token0) || ( token == Token1) , "Match token faild." ) ;

        // More gas , But logic will more easy.
        if( token == MainToken ){
            TransferHelper.safeTransferFrom( token , msg.sender , address(this) , amount ) ;
        } else {
            // 兑换 weth
            IWETH( token ).deposit{
                value : amount 
            }() ;
        }
        _deposit( to , token , amount ) ;

        emit Deposit( to, address(this) , token , amount ) ;
    } 

    /**
     *  提取可提现的奖励Token
     */
    function redeem(address token ) public override returns ( uint amount ) {
        require( Status == 2 || Status == 9 , "Not finished." ) ;
        address sender = msg.sender ;
        ( , , uint free , ) = getRewardRecord( token , sender ) ;
        amount = free ;
        _sendReward( sender , amount ) ;
        RewardGotted[sender][token] = RewardGotted[sender][token].add( amount ) ;  
        RewardGottedTotal = RewardGottedTotal.add( amount ) ;
    }

    // redeem all , claim from tokenlon , and removeLiquidity from uniswap
    // 流程结束
    function finish() external override onlyOwner {
        // require(block.timestamp >= StakeEndTime , "It's not time for redemption." ) ;
        // redeem liquidity from staking contracts 
        IStakingRewards staking = IStakingRewards(StakeAddress) ;
        // uint stakeBalance = staking.balanceOf( address(this) ) ;

        //计算MainToken余额变化,即挖矿Token的余额变化，获取收益
        uint beforeExit = _tokenBalance( MainToken ); 
        staking.exit() ;
        uint afterExit = _tokenBalance( MainToken ); 

        uint interest = afterExit.sub( beforeExit ) ;

        // remove liquidity
        IUniswapV2Pair pair = IUniswapV2Pair( UniPairAddress ) ;
        uint liquidityBalance = pair.balanceOf( address(this) ) ;
        TransferHelper.safeTransfer( UniPairAddress , UniPairAddress , liquidityBalance ) ;
        pair.burn( address(this) ) ;

        //计算剩余本金
        uint mainTokenBalance = _tokenBalance( MainToken ) ;
        uint principal = mainTokenBalance.sub( interest ).sub( RewardAmount ).add( RewardGottedTotal ) ;  

        // 收取 interest 的 10% 作为管理费
        uint fee = _fee( interest ) ;
        uint interestWithoutFee = interest - fee ;
        //判断无偿损失
        // 判断Token0是否受到了无偿损失影响
        TokenRecord memory mainRecord = MainToken == Token0 ? Token0Record : Token1Record ;
        
        uint mainTokenRate = 5 ;
        uint pairTokenRate = 5 ;  //各50%的收益,不需要补偿无偿损失的一方
        if( mainRecord.total > principal ) {
            // 有无偿损失
            uint diff = mainRecord.total - principal ;
            uint minDiff = mainRecord.total.div( 10 ) ; // 10%的损失
            if( diff > minDiff ) {
                //满足补贴条件
                mainTokenRate = 6 ;
                pairTokenRate = 4 ;
            }
        } else {
            // 计算另一个token的是否满足补偿条件
            TokenRecord memory pairRecord = MainToken == Token0 ? Token1Record : Token0Record ;
            //获取配对Token的余额
            address pairToken = Token0 == MainToken ? Token1 : Token0 ;
            //TODO 二池因为奖励token和挖矿token属于同一token，所以这里通过余额计算会存在问题，需要调整
            uint pairTokenBalance = _tokenBalance( pairToken ) ;
            uint diff = pairRecord.total - pairTokenBalance ;
            uint minDiff = pairRecord.total.div(10) ;
            if( diff > minDiff ) {
                pairTokenRate = 6 ;
                mainTokenRate = 4 ;
            }
        }

        ( uint token0Rate , uint token1Rate ) = Token0 == MainToken ? 
            ( mainTokenRate , pairTokenRate) : ( pairTokenRate , mainTokenRate ) ;

        Token0Record.reward = RewardAmount.mul( token0Rate ).div( 10 ) ;
        Token1Record.reward = RewardAmount.mul( token1Rate ).div( 10 ) ;

        Token0Record.mint = interestWithoutFee.mul( token0Rate ).div( 10 ) ;
        Token1Record.mint = interestWithoutFee.mul( token1Rate ).div( 10 ) ;

        // 设置为挖矿结束
        Status = 9 ;
    }

    /**
     *  添加流动性并开始挖矿时
     *      1、不接收继续存入资产。
     *      2、开始计算PairX的挖矿奖励，并线性释放。
     */
    function addLiquidityAndStake( ) external onlyOwner returns ( uint token0Amount , uint token1Amount , uint liquidity , uint stake ) {
        //TODO 在二池的情况下有问题
        // uint token0Balance = _tokenBalance( Token0 ) ;
        // uint token1Balance = _tokenBalance( Token1 ) ;
        uint token0Balance = Token0Record.total ; 
        uint token1Balance = Token1Record.total ;

        require( token0Balance > MinToken0Deposit && token1Balance > MinToken1Deposit , "No enought balance ." ) ;
        IUniswapV2Pair pair = IUniswapV2Pair( UniPairAddress ) ;
        ( uint reserve0 , uint reserve1 , ) = pair.getReserves() ;  // sorted

        //先计算将A全部存入需要B的配对量
        token0Amount = token0Balance ;
        token1Amount = token0Amount.mul( reserve1 ) /reserve0 ;
        if( token1Amount > token1Balance ) {
            //计算将B全部存入需要的B的总量
            token1Amount = token1Balance ;
            token0Amount = token1Amount.mul( reserve0 ) / reserve1 ;
        } 

        require( token0Amount > 0 && token1Amount > 0 , "No enought tokens for pair." ) ;
        TransferHelper.safeTransfer( Token0 , UniPairAddress , token0Amount ) ;
        TransferHelper.safeTransfer( Token1 , UniPairAddress , token1Amount ) ;

        //add liquidity
        liquidity = pair.mint( address(this) ) ;

        require( liquidity > 0 , "Stake faild. No liquidity." ) ;
        //stake 
        stake = _stake( ) ;
        // 开始计算PairX挖矿
        RewardBeginTime = getDateTime( block.timestamp ) ;
        Status = 2 ;    //Locked 
    }

    //提取存入代币及挖矿收益,一次性全部提取
    function claim( address token ) public override returns (uint amount ) {
        // require( StakeEndTime <= block.timestamp , "Unexpired for locked.") ;
        // 余额做了处理,不用担心重入
        amount = UserBalance[msg.sender][token] ;

        require( amount > 0 , "Invaild request, balance is not enough." ) ;
        require( Status != 2 , "Not finish. " ) ;   //locked
        require( token == Token0 || token == Token1 , "No matched token.") ; 
        uint reward = 0 ;
        uint principal = amount ;
        uint interest = 0 ;
        if( Status == 1 ) {
            // 直接提取本金,但没有任何收益
            _safeTransfer( token , msg.sender , amount ) ;
            if( token == Token0 ) {
                Token0Record.total = Token0Record.total.sub( amount ) ;
                Token0Record.withdraw = Token0Record.total ;
            }
            if( token == Token1 ) {
                Token1Record.total = Token1Record.total.sub( amount ) ;
                Token1Record.withdraw = Token1Record.total ;
            }
            // UserBalance[msg.sender][token] = UserBalance[msg.sender][token].sub( amount ) ; 
        } 

        if( Status == 9 ) {
            TokenRecord storage tokenRecord = token == Token0 ? Token0Record : Token1Record ;
            // 计算可提取的本金 amount / total * withdraw
            principal = amount.div(1e15).mul( tokenRecord.withdraw ).div( tokenRecord.total.div(1e15) );
            if( tokenRecord.mint > 0 ) {
                interest = amount.div(1e15).mul( tokenRecord.mint ).div( tokenRecord.total.div(1e15) ) ;
            }
            
            // if( token == Token0 ) {
            //     tokenBalance = Token0Record.total ;
            // }
            if( token == MainToken ) {
                // 一次性转入
                uint tranAmount = principal + interest ;
                _safeTransfer( token , msg.sender , tranAmount ) ;
            } else {
                _safeTransfer( token , msg.sender , principal ) ;
                if( interest > 0 ) {
                    // 分别转出
                    _safeTransfer( MainToken , msg.sender , interest ) ;
                }
            }

            // 提取解锁的解锁的全部奖励
            reward = redeem( token ) ;
        }
        
        // clear 
        UserBalance[msg.sender][token] = uint(0);

        emit Claim( address(this) , msg.sender , token , principal , interest , reward ) ;
    }

    function _stake() internal returns (uint stake ) {
        IStakingRewards staking = IStakingRewards( StakeAddress ) ;
        uint liquidity = IUniswapV2Pair( UniPairAddress ).balanceOf( address(this) ) ;
        stake = liquidity ;
        TransferHelper.safeApprove( UniPairAddress , StakeAddress , liquidity) ;
        staking.stake( liquidity ) ;
        // emit Staking( address(this) , StakeAddress , liquidity , stake ) ;
    }

    function depositETH() external payable {
        uint ethValue = msg.value ;
        require( ethValue > 0 , "Payment is zero." ) ;
        address weth = Token0 == MainToken ? Token1 : Token0 ;
        deposit( weth , msg.sender , ethValue ) ;
    }

    function _safeTransfer( address token , address to , uint amount ) internal {
        uint balance = _tokenBalance( token ) ;
        if( amount > balance ){
            amount = balance ;
        }
        if( token == MainToken ) {
            TransferHelper.safeTransfer( token , to , amount ) ;
        } else {
            // weth
            IWETH( token ).withdraw( amount ) ;
            TransferHelper.safeTransferETH( to , amount );
        }
    }

    function _tokenBalance( address token ) internal view returns (uint) {
        return IERC20( token ).balanceOf( address(this) ) ;
    }

    receive() external payable {
        assert(msg.sender == Token0 || msg.sender == Token1 ); // only accept ETH via fallback from the WETH contract
    }

}