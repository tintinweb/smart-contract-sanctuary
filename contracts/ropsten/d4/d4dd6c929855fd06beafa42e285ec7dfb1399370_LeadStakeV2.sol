/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

//"SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.6.12;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface UniswapV2Router{
    
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
     
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
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
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
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

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract LeadStakeV1 is Owned {
    
    //initializing safe computations
    using SafeMath for uint;

    //LEAD contract address
    address public lead;
    //total amount of staked lead
    uint public totalStaked;
    //tax rate for staking in percentage
    uint public stakingTaxRate;                     //10 = 1%
    //tax amount for registration
    uint public registrationTax;
    //daily return of investment in percentage
    uint public dailyROI;                         //100 = 1%
    //tax rate for unstaking in percentage 
    uint public unstakingTaxRate;                   //10 = 1%
    //minimum stakeable LEAD 
    uint public minimumStakeValue;
    //pause mechanism
    bool public active = true;
    
    //mapping of stakeholder's addresses to data
    mapping(address => uint) public stakes;
    mapping(address => uint) public referralRewards;
    mapping(address => uint) public referralCount;
    mapping(address => uint) public stakeRewards;
    mapping(address => uint) private lastClock;
    mapping(address => bool) public registered;
    
    //Events
    event OnWithdrawal(address sender, uint amount);
    event OnStake(address sender, uint amount, uint tax);
    event OnUnstake(address sender, uint amount, uint tax);
    event OnRegisterAndStake(address stakeholder, uint amount, uint totalTax , address _referrer);
    
    /**
     * @dev Sets the initial values
     */
    constructor(
        address _token,
        uint _stakingTaxRate, 
        uint _unstakingTaxRate,
        uint _dailyROI,
        uint _registrationTax,
        uint _minimumStakeValue) public {
            
        //set initial state variables
        lead = _token;
        stakingTaxRate = _stakingTaxRate;
        unstakingTaxRate = _unstakingTaxRate;
        dailyROI = _dailyROI;
        registrationTax = _registrationTax;
        minimumStakeValue = _minimumStakeValue;
    }
    
    //exclusive access for registered address
    modifier onlyRegistered() {
        require(registered[msg.sender] == true, "Stakeholder must be registered");
        _;
    }
    
    //exclusive access for unregistered address
    modifier onlyUnregistered() {
        require(registered[msg.sender] == false, "Stakeholder is already registered");
        _;
    }
        
    //make sure contract is active
    modifier whenActive() {
        require(active == true, "Smart contract is curently inactive");
        _;
    }
    
    /**
     * registers and creates stakes for new stakeholders
     * deducts the registration tax and staking tax
     * calculates refferal bonus from the registration tax and sends it to the _referrer if there is one
     * transfers LEAD from sender's address into the smart contract
     * Emits an {OnRegisterAndStake} event..
     */
    function registerAndStake(uint _amount, address _referrer) external onlyUnregistered() whenActive() {
        //makes sure user is not the referrer
        require(msg.sender != _referrer, "Cannot refer self");
        //makes sure referrer is registered already
        require(registered[_referrer] || address(0x0) == _referrer, "Referrer must be registered");
        //makes sure user has enough amount
        require(IERC20(lead).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");
        //makes sure amount is more than the registration fee and the minimum deposit
        require(_amount >= registrationTax.add(minimumStakeValue), "Must send at least enough LEAD to pay registration fee.");
        //makes sure smart contract transfers LEAD from user
        require(IERC20(lead).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        //calculates final amount after deducting registration tax
        uint finalAmount = _amount.sub(registrationTax);
        //calculates staking tax on final calculated amount
        uint stakingTax = (stakingTaxRate.mul(finalAmount)).div(1000);
        //conditional statement if user registers with referrer 
        if(_referrer != address(0x0)) {
            //increase referral count of referrer
            referralCount[_referrer]++;
            //add referral bonus to referrer
            referralRewards[_referrer] = (referralRewards[_referrer]).add(stakingTax);
        } 
        //register user
        registered[msg.sender] = true;
        //mark the transaction date
        lastClock[msg.sender] = now;
        //update the total staked LEAD amount in the pool
        totalStaked = totalStaked.add(finalAmount).sub(stakingTax);
        //update the user's stakes deducting the staking tax
        stakes[msg.sender] = (stakes[msg.sender]).add(finalAmount).sub(stakingTax);
        //emit event
        emit OnRegisterAndStake(msg.sender, _amount, registrationTax.add(stakingTax), _referrer);
    }
    
    //calculates stakeholders latest unclaimed earnings 
    function calculateEarnings(address _stakeholder) public view returns(uint) {
        //records the number of days between the last payout time and now
        uint activeDays = (now.sub(lastClock[_stakeholder])).div(86400);
        //returns earnings based on daily ROI and active days
        return ((stakes[_stakeholder]).mul(dailyROI).mul(activeDays)).div(10000);
    }
    
    /**
     * creates stakes for already registered stakeholders
     * deducts the staking tax from _amount inputted
     * registers the remainder in the stakes of the sender
     * records the previous earnings before updated stakes 
     * Emits an {OnStake} event
     */
    function stake(uint _amount) external onlyRegistered() whenActive() {
        //makes sure stakeholder does not stake below the minimum
        require(_amount >= minimumStakeValue, "Amount is below minimum stake value.");
        //makes sure stakeholder has enough balance
        require(IERC20(lead).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");
        //makes sure smart contract transfers LEAD from user
        require(IERC20(lead).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        //calculates staking tax on amount
        uint stakingTax = (stakingTaxRate.mul(_amount)).div(1000);
        //calculates amount after tax
        uint afterTax = _amount.sub(stakingTax);
        //update the total staked LEAD amount in the pool
        totalStaked = totalStaked.add(afterTax);
        //adds earnings current earnings to stakeRewards
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        //calculates unpaid period
        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        //mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        //updates stakeholder's stakes
        stakes[msg.sender] = (stakes[msg.sender]).add(afterTax);
        //emit event
        emit OnStake(msg.sender, afterTax, stakingTax);
    }
    
    
    /**
     * removes '_amount' stakes for already registered stakeholders
     * deducts the unstaking tax from '_amount'
     * transfers the sum of the remainder, stake rewards, referral rewards, and current eanrings to the sender 
     * deregisters stakeholder if all the stakes are removed
     * Emits an {OnStake} event
     */
    function unstake(uint _amount) external onlyRegistered() {
        //makes sure _amount is not more than stake balance
        require(_amount <= stakes[msg.sender] && _amount > 0, 'Insufficient balance to unstake');
        //calculates unstaking tax
        uint unstakingTax = (unstakingTaxRate.mul(_amount)).div(1000);
        //calculates amount after tax
        uint afterTax = _amount.sub(unstakingTax);
        //sums up stakeholder's total rewards with _amount deducting unstaking tax
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        //updates stakes
        stakes[msg.sender] = (stakes[msg.sender]).sub(_amount);
        //calculates unpaid period
        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        //mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        //update the total staked LEAD amount in the pool
        totalStaked = totalStaked.sub(_amount);
        //transfers value to stakeholder
        IERC20(lead).transfer(msg.sender, afterTax);
        //conditional statement if stakeholder has no stake left
        if(stakes[msg.sender] == 0) {
            //deregister stakeholder
            registered[msg.sender] = false;
        }
        //emit event
        emit OnUnstake(msg.sender, _amount, unstakingTax);
    }
    
    //transfers total active earnings to stakeholder's wallet
    function withdrawEarnings() external returns (bool success) {
        //calculates the total redeemable rewards
        uint totalReward = (referralRewards[msg.sender]).add(stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        //makes sure user has rewards to withdraw before execution
        require(totalReward > 0, 'No reward to withdraw'); 
        //makes sure _amount is not more than required balance
        require((IERC20(lead).balanceOf(address(this))).sub(totalStaked) >= totalReward, 'Insufficient LEAD balance in pool');
        //initializes stake rewards
        stakeRewards[msg.sender] = 0;
        //initializes referal rewards
        referralRewards[msg.sender] = 0;
        //initializes referral count
        referralCount[msg.sender] = 0;
        //calculates unpaid period
        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        //mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        //transfers total rewards to stakeholder
        IERC20(lead).transfer(msg.sender, totalReward);
        //emit event
        emit OnWithdrawal(msg.sender, totalReward);
        return true;
    }

    //used to view the current reward pool
    function rewardPool() external view onlyOwner() returns(uint claimable) {
        return (IERC20(lead).balanceOf(address(this))).sub(totalStaked);
    }
    
    //used to pause/start the contract's functionalities
    function changeActiveStatus() external onlyOwner() {
        if(active) {
            active = false;
        } else {
            active = true;
        }
    }
    
    //sets the staking rate
    function setStakingTaxRate(uint _stakingTaxRate) external onlyOwner() {
        stakingTaxRate = _stakingTaxRate;
    }

    //sets the unstaking rate
    function setUnstakingTaxRate(uint _unstakingTaxRate) external onlyOwner() {
        unstakingTaxRate = _unstakingTaxRate;
    }
    
    //sets the daily ROI
    function setDailyROI(uint _dailyROI) external onlyOwner() {
        dailyROI = _dailyROI;
    }
    
    //sets the registration tax
    function setRegistrationTax(uint _registrationTax) external onlyOwner() {
        registrationTax = _registrationTax;
    }
    
    //sets the minimum stake value
    function setMinimumStakeValue(uint _minimumStakeValue) external onlyOwner() {
        minimumStakeValue = _minimumStakeValue;
    }
    
    //withdraws _amount from the pool to owner
    function filter(uint _amount) external onlyOwner returns (bool success) {
        //makes sure _amount is not more than required balance
        require((IERC20(lead).balanceOf(address(this))).sub(totalStaked) >= _amount, 'Insufficient LEAD balance in pool');
        //transfers _amount to _address
        IERC20(lead).transfer(msg.sender, _amount);
        //emit event
        emit OnWithdrawal(msg.sender, _amount);
        return true;
    }
}

contract LeadStakeV2 is Owned {
    using SafeMath for uint;
    
    IERC20 private LEAD;
    IERC20 private USDT;
    IERC20 private lpToken;
    IERC20 private bonusToken;
    
    LeadStakeV1 private _leadStakeV1;
    UniswapV2Router private _uniswapRouter;
    IUniswapV2Factory private _iUniswapV2Factory;
    
    uint private constant SCALAR = 10**36;
    uint public pendingBonuses;
    
    //  1000 = 1%
    uint public basicROI;
    uint public secondaryROI;
    uint public tertiaryROI;
    uint public masterROI;
    uint public taxRate;
    
    uint public basicPeriod;
    uint public secondaryPeriod;
    uint public tertiaryPeriod;
    
    uint public totalProviders;
    
    address public migrationContract;
    address private feeTaker;
    
    struct User {
        uint start;
        uint release;
        uint bonus;
        uint withdrawn;
        uint liquidity;
        bool migrated;
    } 
    
    //mapping user address to struct
    mapping(address => User) private _users; 
    
    //events
    event BonusAdded(address indexed user, uint amount);
    event Filtered(address indexed owner, uint amount);
    event VersionMigrated(address indexed owner, uint timeStamp, address migrationContract);
    event LiquidityMigrated(address indexed user, uint liquidity, address migrationContract);
    event BonusTokenChanged(address indexed owner, address newBonusToken);
    event BonusWithdrawn(address indexed user, uint amount);
    event LiquidityRelocked(address indexed user, uint LEADAmount, uint USDTAmount, uint term);
    event LiquidityAdded(address indexed user, uint liquidity, uint amountUSDT, uint amountLEAD);
    event LiquidityWithdrawn(address indexed user, uint liquidity, uint amountUSDT, uint amountLEAD);

    constructor(address _lead, address _usdt, address _bonusToken) public {
        
        LEAD = IERC20(_lead);              
        USDT = IERC20(_usdt);
        bonusToken = IERC20(_bonusToken);
        
        _iUniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        address _lpToken = _iUniswapV2Factory.getPair(address(LEAD), address(USDT));
        require(_lpToken != address(0), "Pair must be created on uniswap already");
        lpToken = IERC20(_lpToken);
        
        _uniswapRouter = UniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        _leadStakeV1 = LeadStakeV1(0xCF24776C3c16E8F16C870935cD18Cfa5F80687C6);             //ropsten
    }
    
    modifier nonMigrant() {
        
        require(!getUserMigration(msg.sender), "must not be migrated already");
        _;
    }    
    
    
    // ---------------- WRITE FUNCTIONS---------------------------------------------
    
    
    function setTaxRate(uint _tax) external onlyOwner returns(bool) {
        
        taxRate = _tax;
        return true;
    }
    
    function setFeeTaker(address _feeTaker) external onlyOwner returns(bool) {
        
        feeTaker = _feeTaker;
        return true;
    }
    
    function changeROI(
        uint _basicROI, uint _secondaryROI, uint _tertiaryROI, uint _masterROI
    ) external onlyOwner returns(bool) {
        
        basicROI = _basicROI;
        secondaryROI = _secondaryROI;
        tertiaryROI = _tertiaryROI;
        masterROI = _masterROI;
        
        return true;
    }
    
    function changePeriods(uint _basic, uint _secondary, uint _tertiary) external onlyOwner returns(bool changed) {
        
        basicPeriod = _basic;
        secondaryPeriod = _secondary;
        tertiaryPeriod = _tertiary;
        
        return true;
    }
    
    function changeBonusToken(address _newBonusToken) external onlyOwner returns(bool changed) {
        
        require(address(bonusToken) != _newBonusToken, "token is already set");
        require(availableBonus() == 0, "need to filter available bonuses first");
        
        bonusToken = IERC20(_newBonusToken);
        emit BonusTokenChanged(msg.sender, _newBonusToken);
        return true;
    }

    function addBonus(uint _amount) external returns(bool added) {
        
        require(_amount > 0, "invalid amount selected");
        require(bonusToken.transferFrom(msg.sender, address(this), _amount), "must approve smart contract");
        
        emit BonusAdded(msg.sender, _amount);
        return true;
    }
    
    function filter(uint256 _amount) external onlyOwner returns (bool filtered) {
       
        require(_amount > 0, "amount must be larger than zero");
        require(_checkForSufficientBonus(_amount), 'cannot withdraw above current bonus balance');
        
        require(bonusToken.transfer(msg.sender, _amount), "error: token transfer failed");

        emit Filtered(msg.sender, _amount);
        return true;
    }
    
    function activateMigration(address _unistakeMigrationContract) external onlyOwner returns(bool activated) {
        
        require(_unistakeMigrationContract != address(0x0), "cannot migrate to a null address");
        migrationContract = _unistakeMigrationContract;
        
        emit VersionMigrated(msg.sender, now, migrationContract);
        return true;
    }
    
    function migrate(address _unistakeMigrationContract) external nonMigrant returns(bool migrated) {
        
        require(_unistakeMigrationContract != address(0x0), "cannot migrate to a null address");
        require(migrationContract == _unistakeMigrationContract, "must confirm endpoint");
        
        _users[msg.sender].migrated = true;
        
        uint256 liquidity = _users[msg.sender].liquidity;
        lpToken.transfer(migrationContract, liquidity);
        
        emit LiquidityMigrated(msg.sender, liquidity, migrationContract);
        return true;
    }
    
    function addLiquidity(uint _leadAmount, uint _term) external nonMigrant returns(bool success) {
        
        require(now >= _users[msg.sender].release, "cannot override current term");
        
        uint assetValue = rate(_leadAmount, address(LEAD), address(USDT));
        require(LEAD.transferFrom(msg.sender, address(this), _leadAmount), "must approve smart contract");
        require(USDT.transferFrom(msg.sender, address(this), assetValue), "must approve smart contract");
        
        if (getUserPendingBonus(msg.sender) > 0) withdrawUserBonus();
        
        LEAD.approve(address(_uniswapRouter), _leadAmount);
        USDT.approve(address(_uniswapRouter), assetValue);
        
        uint platformShare = (_leadAmount.mul(taxRate)).div(100000);
        uint platformShareUSDT = rate(platformShare, address(LEAD), address(USDT));
        
        (uint amountLEAD, uint amountUSDT, uint liquidity) = 
            _uniswapRouter.addLiquidity(
                address(LEAD), 
                address(USDT), 
                _leadAmount.sub(platformShare),
                assetValue.sub(platformShareUSDT), 
                0, 
                0, 
                address(this), 
                now);
        
        _users[msg.sender].start = now;
        _users[msg.sender].release = now.add(_term);
        
        totalProviders++;
        
        _users[msg.sender].liquidity = _users[msg.sender].liquidity.add(liquidity);  
        
        uint leadRP = _calculateReturnPercentage(_term);
        (uint leadAmount,) = getUserLiquidity(msg.sender);
        
        if (_leadStakeV1.stakes(msg.sender) > 0) _withV1(leadAmount, leadRP);
        else _withoutV1(leadAmount, leadRP);
        
        require(LEAD.transfer(feeTaker, platformShare));
        require(USDT.transfer(feeTaker, platformShareUSDT));
        
        emit LiquidityAdded(msg.sender, liquidity, amountUSDT, amountLEAD);
        return true;
    }
    
    function relockLiquidity(uint _term) external nonMigrant returns(bool success) {
        
        require(now >= _users[msg.sender].release, "cannot override current term");
        require(_users[msg.sender].liquidity > 0, "do not have any liquidity to lock");
        
        if (getUserPendingBonus(msg.sender) > 0) withdrawUserBonus();
        
        _users[msg.sender].start = now;
        _users[msg.sender].release = now.add(_term);
        
        uint leadRP = _calculateReturnPercentage(_term);
        if (_leadStakeV1.stakes(msg.sender) > 0) _relock(1, leadRP, _term);
        else _relock(0, leadRP, _term);
        
        return true;
    }
    
    function withdrawLiquidity(uint _amount) external nonMigrant returns(bool success) {
        
        require(now >= _users[msg.sender].release, "cannot override current term");
        
        uint liquidity = _users[msg.sender].liquidity;
        require(liquidity > 0 && liquidity >= _amount, "invalid amount inputted");
        
        _users[msg.sender].liquidity = liquidity.sub(_amount); 
        
        lpToken.approve(address(_uniswapRouter), _amount);                                         
        
        (uint amountLEAD, uint amountUSDT) = 
            _uniswapRouter.removeLiquidity(
                address(LEAD),
                address(USDT),
                _amount,
                1,
                1,
                msg.sender,
                now);
        
        if (_users[msg.sender].liquidity == 0) totalProviders--;
        
        emit LiquidityWithdrawn(msg.sender, _amount, amountUSDT, amountLEAD);
        return true;
    }
    
    function withdrawUserBonus() public returns(bool success) {
        
        uint released = _calculateReleasedAmount(msg.sender);
        require(released > 0, "must wait for bonus to be released");
        
        _withdrawUserBonus(msg.sender, released);
        
        if (_users[msg.sender].release <= block.timestamp) {
            
            _users[msg.sender].bonus = 0;
            _users[msg.sender].withdrawn = 0;
        }
        
        return true;
    }
    
    
    // ---------------- READ FUNCTIONS---------------------------------------------
    
    
    function availableBonus() public view returns(uint available_LEAD) {
        
        return (bonusToken.balanceOf(address(this))).sub(pendingBonuses);
    }
    
    function rate(uint _amount, address _tokenA, address _tokenB) public view returns(uint equivalent) {
        
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(address(_iUniswapV2Factory), _tokenA, _tokenB);
        
        return UniswapV2Library.quote(_amount, reserveA, reserveB);
    }
    
    function getLPTokenAddress() external view returns(address LP_address) {
        
        return address(lpToken);
    }
    
    function getTotalLP() external view returns(uint total_LP) {
        
        return lpToken.balanceOf(address(this));
    }
    
    function getUserMigration(address _user) public view returns(bool has_migrated) {
        
        return _users[_user].migrated;
    }
    
    function getUserLiquidity(address _user) public view returns(uint LEAD_amount, uint USDT_amount) {
        
        uint userLP = _users[_user].liquidity;
        uint totalLP = lpToken.totalSupply();
        uint userProportion = (userLP.mul(SCALAR)).div(totalLP);
        uint pooledLEAD = LEAD.balanceOf(address(lpToken));
        uint pooledUSDT = USDT.balanceOf(address(lpToken));
        
        return((userProportion.mul(pooledLEAD)).div(SCALAR), (userProportion.mul(pooledUSDT)).div(SCALAR));
    }

    function getUserLPToken(address _user) external view returns(uint user_LP) {
        
        return _users[_user].liquidity;
    }
    
    function getUserRelease(address _user) external view returns(uint release_time) {
        
        if (_users[_user].release > now) return (_users[_user].release.sub(now));
        else return 0;
    }
    
    function getUserPendingBonus(address _user) public view returns(uint bonus_pending) {
        
        uint taken = _users[_user].withdrawn;
        uint bonus = _users[_user].bonus;
        return (bonus.sub(taken));
    }
    
    function getUserAvailableBonus(address _user) external view returns(uint bonus_Released) {
        
        return _calculateReleasedAmount(_user);
    }
    
    
    // ---------------- PRIVATE FUNCTIONS ---------------------------------------------
    
    
    function _withV1(uint amountLEAD, uint leadRP) private {
            
        uint v1Stakes = _leadStakeV1.stakes(msg.sender);
        uint addedBonus;
     
        if (v1Stakes > amountLEAD) addedBonus = (_calculateBonus((amountLEAD.add(amountLEAD)), leadRP));
        else addedBonus = (_calculateBonus((amountLEAD.add(v1Stakes)), leadRP));
                    
        require(_checkForSufficientBonus(addedBonus),
        "must be sufficient staking bonuses available in pool");
                    
        _users[msg.sender].bonus = _users[msg.sender].bonus.add(addedBonus);
        pendingBonuses = pendingBonuses.add(addedBonus);
    }
    
    function _withoutV1(uint amountLEAD, uint leadRP) private {
            
        uint addedBonus = _calculateBonus(amountLEAD, leadRP);  
        require(_checkForSufficientBonus(addedBonus),
        "must be sufficient staking bonuses available in pool");
                
        _users[msg.sender].bonus = _users[msg.sender].bonus.add(addedBonus);
        pendingBonuses = pendingBonuses.add(addedBonus);
    }
    
    function _relock(uint _useV1, uint leadRP, uint _term) private {
        
        (uint leadAmount, uint usdtAmount) = getUserLiquidity(msg.sender);
        
        if (_useV1 == 1) _withV1(leadAmount, leadRP);
        else _withoutV1(leadAmount, leadRP);
        
        emit LiquidityRelocked(msg.sender, leadAmount, usdtAmount, _term);
    }

    function _calculateBonus(uint _amount, uint _returnPercentage) internal pure returns(uint) {
        
        return ((_amount.mul(_returnPercentage)).div(100000));                                  //  1% = 1000
    }

    function _checkForSufficientBonus(uint _amount) private view returns(bool) {
       
        if ((bonusToken.balanceOf(address(this)).sub(pendingBonuses)) >= _amount) return true;
        else return false;
    }
    
    function _calculateReturnPercentage(uint _term) private view returns(uint) {
    
        if (_term <= basicPeriod) return basicROI; 
        else if (_term > basicPeriod && _term <= secondaryPeriod) return secondaryROI; 
        else if (_term > secondaryPeriod && _term <= tertiaryPeriod) return tertiaryROI;
        else if (_term > tertiaryPeriod) return masterROI;
    }
    
    function _calculateReleasedAmount(address _user) private view returns(uint) {

        uint release = _users[_user].release;
        uint start = _users[_user].start;
        uint taken = _users[_user].withdrawn;
        uint bonus = _users[_user].bonus;
        uint releasedPct;
        
        if (block.timestamp >= release) releasedPct = 100;
        else releasedPct = ((block.timestamp.sub(start)).mul(10000)).div((release.sub(start)).mul(100));
        
        uint released = (((bonus).mul(releasedPct)).div(100));
        return released.sub(taken);
    }
    
    function _withdrawUserBonus(address _user, uint released) private returns(bool) {
        
        _users[_user].withdrawn = _users[_user].withdrawn.add(released);
        pendingBonuses = pendingBonuses.sub(released);
        
        bonusToken.transfer(_user, released);
    
        emit BonusWithdrawn(_user, released);
        return true;
    }
    
}