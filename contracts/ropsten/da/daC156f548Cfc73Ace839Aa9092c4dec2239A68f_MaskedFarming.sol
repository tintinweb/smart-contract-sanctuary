/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;

interface MaskedInterface{
	function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function burn(address from, uint256 amount) external;
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


contract MaskedFarming {

    using SafeMath for uint;

    // VARIABLES & CONSTANTS
    address _burnVault;
    address public _owner;
    
    // 1. Tokens
    MaskedInterface public token;
    IUniswapV2Pair public lpToken;

    uint public POOL_MULTIPLIER; // 1e18
    uint public POOL_MULTIPLIER_UPDATED;
    uint public constant POOL_MULTIPLIER_UPDATE_1WEEK = 45000; // 1 week (blocks)
    uint public POOL_lastRewardBlock;
    uint public POOL_accTokensPerLP; // 1e18

    uint public immutable POOL_START;
    uint public constant POOL_START_DELAY = 1;
    uint public constant PRECISION = 1e5;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Pair constant ETH_USDC_PAIR = IUniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);
    
    struct User {
        uint POOL_provided;
        uint POOL_rewardDebt;
    }
    
    mapping(address => User) public users;

    constructor(address owner, address burnVault){
        // Distribution = 7500 * (3/4)^(n-1) (n = week)
        POOL_MULTIPLIER = uint(7500 * 1e18) / POOL_MULTIPLIER_UPDATE_1WEEK;
        POOL_MULTIPLIER_UPDATED = block.number.add(POOL_START_DELAY);

        POOL_START = block.number.add(POOL_START_DELAY);

        _owner = owner;
        _burnVault = burnVault;
    }

    // GOVERNANCE

    // 0. Modifier
    modifier onlyOwner(){
        require(msg.sender == _owner);
        _;
    }

    // 1. Update governance address
    function setOwnerAddress(address _gov) external onlyOwner{
        _owner = _gov;
    }

    // 2. Set token address
    function setTokenAddress(address _token) external onlyOwner{
        //require(token == GFarmTokenInterface(0), "Token address already set");
        token = MaskedInterface(_token);
    }

    // 3. Set lp address
    function setLPAddress(address _lp) external onlyOwner{
        //require(lp == IUniswapV2Pair(0), "LP address already set");
        lpToken = IUniswapV2Pair(_lp);
    }


    // POOL REWARDS BETWEEN 2 BLOCKS

    // 1. Pool 1 (1e18)
    function CalculateReward(uint _from, uint _to) private view returns (uint){
        uint blocks;

        if(_from >= POOL_START && _to >= POOL_START){
            blocks = _to.sub(_from);
        }

        return blocks.mul(POOL_MULTIPLIER);
    }

    // UPDATE POOL VARIABLES

    // 1. Pool 1
    function POOL_update() private {
        uint lpSupply = lpToken.balanceOf(address(this));

        if (POOL_lastRewardBlock == 0 || lpSupply == 0) {
            POOL_lastRewardBlock = block.number;
            return;
        }

        uint reward = CalculateReward(POOL_lastRewardBlock, block.number);

        POOL_accTokensPerLP = POOL_accTokensPerLP.add(
            reward.mul(1e18).div(lpSupply)
        );
        POOL_lastRewardBlock = block.number;

        if(block.number >= POOL_MULTIPLIER_UPDATED.add(POOL_MULTIPLIER_UPDATE_1WEEK)){
            POOL_MULTIPLIER = POOL_MULTIPLIER.mul(3).div(4);
            POOL_MULTIPLIER_UPDATED = block.number;
        }
    }   

    // PENDING REWARD

    // 1. Pool 1 external (1e18)
    function UserPendingReward() external view returns(uint){
        return _POOL_pendingReward(users[msg.sender]);
    }

    // 2. Pool 1 private (1e18)
    function _POOL_pendingReward(User memory u) private view returns(uint){
        
        uint _POOL_accTokensPerLP = POOL_accTokensPerLP;
        uint lpSupply = lpToken.balanceOf(address(this));

        if (block.number > POOL_lastRewardBlock && lpSupply != 0) {
            uint pendingReward = CalculateReward(POOL_lastRewardBlock, block.number);
            _POOL_accTokensPerLP = _POOL_accTokensPerLP.add(
                pendingReward.mul(1e18).div(lpSupply)
            );
        }

        return u.POOL_provided.mul(_POOL_accTokensPerLP).div(1e18)
                .sub(u.POOL_rewardDebt);
    }

    // HARVEST REWARDS

    // 1. Pool 1 external
    function Harvest() external{
        require(block.number >= POOL_START, "Pool hasn't started yet.");
        _POOL_harvest(msg.sender);
    }

    // 2. Pool 1 private
    function _POOL_harvest(address a) private{
        
        User storage u = users[a];
        uint pending = _POOL_pendingReward(u);
        POOL_update();

        if(pending > 0){
            SafeTokenTransfer(a, pending);
            //token.transfer(address(_burnVault), pending.mul(POOL_REFERRAL_P).div(100));
        }

        u.POOL_rewardDebt = u.POOL_provided.mul(POOL_accTokensPerLP).div(1e18);
    }

    // STAKE

    // 1. Pool 1
    function Stake(uint256 amount) external {
        
        require(tx.origin == msg.sender, "Contracts not allowed.");
        require(block.number >= POOL_START, "Pool hasn't started yet.");
        require(amount > 0, "Staking 0 lp.");
       
        User storage u = users[msg.sender]; //test that this works
        uint pending = _POOL_pendingReward(u);

        if(pending > 0)
            revert("Please harvest before staking again.");

        lpToken.transferFrom(msg.sender, address(this), amount);

        u.POOL_provided = u.POOL_provided.add(amount);
        u.POOL_rewardDebt = u.POOL_provided.mul(POOL_accTokensPerLP).div(1e18);
    }


    // UNSTAKE

    function Unstake(uint amount) external{
        User storage u = users[msg.sender];
        require(amount > 0, "Unstaking 0 lp.");
        require(u.POOL_provided >= amount, "Unstaking more than currently staked.");

        //_POOL_harvest(msg.sender); //remove this...
        uint pending = _POOL_pendingReward(u);

        if(pending > 0)
            revert("Please harvest before unstaking.");
        
        lpToken.transfer(msg.sender, amount);

        u.POOL_provided = u.POOL_provided.sub(amount);
        u.POOL_rewardDebt = u.POOL_provided.mul(POOL_accTokensPerLP).div(1e18);
    }

    function SafeTokenTransfer(address _to, uint _amount) private {
        uint bal = token.balanceOf(address(this));
        if (_amount > bal) {
            token.transfer(_to, bal);
        } else {
            token.transfer(_to, _amount);
        }
    }

    // USEFUL PRICING FUNCTIONS (FOR TVL & APY)

    // 1. ETH/USD price (PRECISION)
    function getEthPrice() public view returns(uint) {
        (uint112 reserves0, uint112 reserves1, ) = ETH_USDC_PAIR.getReserves();
        uint reserveUSDC;
        uint reserveETH;

        if(WETH == ETH_USDC_PAIR.token0()){
            reserveETH = reserves0;
            reserveUSDC = reserves1;
        }else{
            reserveUSDC = reserves0;
            reserveETH = reserves1;
        }
        // Divide number of USDC by number of ETH
        // we multiply by 1e12 because USDC only has 6 decimals
        return reserveUSDC.mul(1e12).mul(PRECISION).div(reserveETH);
    }
    
    // 2. GFARM/ETH price (PRECISION)
    function getMASKEDPriceEth() public view returns(uint) {
        (uint112 reserves0, uint112 reserves1, ) = lpToken.getReserves();

        uint reserveETH;
        uint reserveMASKED;

        if(WETH == lpToken.token0()){
            reserveETH = reserves0;
            reserveMASKED = reserves1;
        }else{
            reserveMASKED = reserves0;
            reserveETH = reserves1;
        }

        return reserveETH.mul(PRECISION).div(reserveMASKED);
    }

    // UI VIEW FUNCTIONS (READ-ONLY)

    function GetMultiplier() public view returns (uint) {
        if(block.number < POOL_START){
            return 0;
        }
        return POOL_MULTIPLIER;
    }

    function SetMultiplier(uint256 newMultiplier) public {
        POOL_MULTIPLIER = newMultiplier;
    }

    function Provided() external view returns(uint) {
        return users[msg.sender].POOL_provided;
    }

    function PoolTotalValue() public view returns(uint) {
        
        if(lpToken.totalSupply() == 0)
            return 0; 

        (uint112 reserves0, uint112 reserves1, ) = lpToken.getReserves();
        uint reserveEth;

        if(WETH == lpToken.token0())
            reserveEth = reserves0;
        else
            reserveEth = reserves1;
        

        uint lpPriceEth = reserveEth.mul(1e5).mul(2).div(lpToken.totalSupply());
        uint lpPriceUsd = lpPriceEth.mul(getEthPrice()).div(1e5);

        return lpToken.balanceOf(address(this)).mul(lpPriceUsd).div(1e18);
    }


    function PoolAPY() external view returns(uint){
        if(PoolTotalValue() == 0){ return 0; }
        return POOL_MULTIPLIER.mul(2336000).mul(getMASKEDPriceEth()).mul(getEthPrice()).mul(100).div(PoolTotalValue());
    }
}