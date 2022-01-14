/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^ 0.8.7;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function claim() external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _previousOwner = _owner;
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract StakingPool4 is Context, Ownable {
    using SafeMath for uint256;

    IERC20 private _token;
    IERC20 private _busdToken;

    mapping(address => uint256) public walletClaimed;
    uint256 public totalTokenClaimed;
    uint256 public totalBusdClaimed;
    uint256 public totalReinvested;

    uint256 public calculationTime = 365 days;
    uint8 public poolNo = 1;

    struct Pool {
        uint8 pool;
        string rarity;
        uint256 stakeSize;
        uint256 minStake;
        uint256 apyNoLock;
        uint256 apy15Day;
        uint256 apy30Day;
    }

    struct Staker {
        address wallet;
        uint8 poolNo;
        uint256 amount;
        uint256 apyTime;
        uint256 timeStakedFor;
        uint256 stakeTime; 
    }

    mapping(address => Staker) public stakers;
    mapping(address => bool) public isStaker;
    Staker[] public stakerSize;
    Pool public pool;

    event Deposit(address indexed wallet, uint8 pool, uint256 amount);
    event WithdrawStaking(address indexed wallet, uint8 pool, uint256 amount);
    event WithdrawReturn(address indexed wallet, uint8 pool, uint256 amount);
    event ReinvestReturn(address indexed wallet, uint8 pool, uint256 amount);
    event PoolUpdated(uint8 poolNo, uint256 time);
    event BusdWithdraw(address indexed to, uint256 amount);

    constructor(){
        _token = IERC20(0xCc67D1fC96DCc004A5178eF01f79bF2f2be490eF);
        _busdToken = IERC20(0xb809b9B2dc5e93CB863176Ea2D565425B03c0540);

        uint256 minStake_ = 10000000 * 10 ** 18;
        uint256 apyNoLock = 170;
        uint256 apy15Day = 218;
        uint256 apy30Day = 288;
        uint256 maxStakers = 140;
        pool = Pool(3, "Rare", maxStakers, minStake_, apyNoLock, apy15Day, apy30Day);
    }

    receive() external payable{}

    function getTokenInfo() public view returns(address, address){
        return (address(_token), address(_busdToken));
    }

    function updateTokens(IERC20 token_, IERC20 busdToken_) public onlyOwner {
        _token = token_;
        _busdToken = busdToken_;
    }

    function myBusdReward(address account) public view returns(uint256){
       return _claimableBusd(account);
    }

    function _claimableBusd(address account) internal view returns(uint256){
        if(_token.balanceOf(address(this)) <= 0) {
            return 0;
        }
        uint256 balance = _busdToken.balanceOf(address(this));
        uint256 grandTotal = balance.add(totalBusdClaimed);
        uint256 myHolding = stakers[_msgSender()].amount.div(_token.balanceOf(address(this))).mul(10**2);
        uint256 withdrawable = grandTotal.mul(myHolding).div(10**2);
        uint256 finalWithdrawable = withdrawable.sub(walletClaimed[account]);
        return finalWithdrawable;
    }


    function claimBusd() public {
        require(stakers[_msgSender()].amount > 0, "You have not staking.");
        uint256 amountToWithdraw = _claimableBusd(_msgSender());
        require(amountToWithdraw > 0, "Not enough balance to claim.");
        walletClaimed[_msgSender()] = walletClaimed[_msgSender()].add(amountToWithdraw);
        totalBusdClaimed = totalBusdClaimed.add(amountToWithdraw);
        _busdToken.transfer(_msgSender(), amountToWithdraw);
        emit BusdWithdraw(_msgSender(), amountToWithdraw);
    }

    function claimDividend() public onlyOwner {
        _token.claim();
    }

    function totalBusdInPool() public view returns(uint256){
        return _busdToken.balanceOf(address(this));
    }

    function deposit(uint256 amount, uint256 apyTime) public {
        if(pool.stakeSize > 0) {
            require(stakerSize.length < pool.stakeSize, "Pool size reached.");
        }
        
        require(_token.allowance(_msgSender(), address(this)) >= amount, "Please approve the amount to spend us.");
        _token.transferFrom(_msgSender(), address(this), amount);
        uint256 rAmount = calculateReturn(_msgSender());
        amount = amount.add(rAmount);
        stakers[_msgSender()].wallet = _msgSender();
        stakers[_msgSender()].poolNo = poolNo;
        stakers[_msgSender()].amount += amount;
        stakers[_msgSender()].apyTime = apyTime;
        stakers[_msgSender()].timeStakedFor = _stakeTimes(apyTime);
        stakers[_msgSender()].stakeTime = block.timestamp;

        if(!isStaker[_msgSender()]){
            stakerSize.push(stakers[_msgSender()]);
        } else {
            _updateStakerSize(_msgSender(), stakers[_msgSender()]);
        }
        
        isStaker[_msgSender()] = true;
        emit Deposit(_msgSender(), poolNo, amount);
    }

    function _stakeTimes(uint256 apyTime) internal view returns(uint256){
        uint256 stakeTimes;
        if(apyTime == 0) {stakeTimes = block.timestamp;}
        if(apyTime == 1) {stakeTimes = block.timestamp.add(15 days);}
        if(apyTime == 2) {stakeTimes = block.timestamp.add(30 days);}
        return stakeTimes;
    }

    function calculateReturn(address account) public view returns(uint256){
        if(stakers[account].amount == 0) {
            return 0;
        }
        uint256 apy;
        uint256 returnAmount;
        uint256 timeSpan = block.timestamp.sub(stakers[account].stakeTime);
        if(stakers[account].apyTime == 0) {apy = pool.apyNoLock;}
        if(stakers[account].apyTime == 1) {apy = pool.apy15Day;}
        if(stakers[account].apyTime == 2) {apy = pool.apy30Day;}
        returnAmount = stakers[account].amount.mul(apy).mul(timeSpan).div(calculationTime).div(10**2);
        return returnAmount;
    }

    function claimStaking() public {
        uint256 returnAmount = calculateReturn(_msgSender());
        require(stakers[_msgSender()].amount > 0, "Sorry! you have not staked anything.");
        require(block.timestamp >= stakers[_msgSender()].timeStakedFor, "Sorry!, staking perioud not finished.");
        uint256 amountToWithdraw = returnAmount.add(stakers[_msgSender()].amount);
        stakers[_msgSender()].amount = 0;
        _token.transfer(_msgSender(), amountToWithdraw);
        _claimableBusd(_msgSender());
        _updateStakerSize(_msgSender(), stakers[_msgSender()]);
        _deleteStakerFromSize(_msgSender());
        isStaker[_msgSender()] = false;
        emit WithdrawStaking(_msgSender(), poolNo, amountToWithdraw);
    }

    function claimReturn() public {
        uint256 returnAmount = calculateReturn(_msgSender());
        require(stakers[_msgSender()].amount > 0, "Sorry! you have not staked anything.");
        stakers[_msgSender()].stakeTime = block.timestamp;
        _token.transfer(_msgSender(), returnAmount);
        totalTokenClaimed = totalTokenClaimed.add(returnAmount);
        emit WithdrawReturn(_msgSender(), poolNo, returnAmount);
    }

    function reinvestReturn() public {
        uint256 returnAmount = calculateReturn(_msgSender());
        require(stakers[_msgSender()].amount > 0, "Sorry! you have not staked anything.");
        stakers[_msgSender()].amount += returnAmount;
        stakers[_msgSender()].stakeTime = block.timestamp;
        _updateStakerSize(_msgSender(), stakers[_msgSender()]);
        totalReinvested = totalReinvested.add(returnAmount);
        emit ReinvestReturn(_msgSender(), poolNo, returnAmount);
    }

    function updatePool(uint8 poolNo_, string memory rarity_, uint256 stakeSize_, uint256 minStake_, uint256 apyNoLock_, uint256 apy15Day_, uint256 apy30Day_) public onlyOwner {
        poolNo = poolNo_;
        pool.pool = poolNo_;
        pool.rarity = rarity_;
        pool.stakeSize = stakeSize_;
        pool.minStake = minStake_;
        pool.apyNoLock = apyNoLock_;
        pool.apy15Day = apy15Day_;
        pool.apy30Day = apy30Day_;
        emit PoolUpdated(poolNo, block.timestamp);
    }

    function totalStakers() public view returns(uint256){
        return stakerSize.length;
    }

    function _updateStakerSize(address account, Staker memory staker) internal {
        uint256 index;
        for(uint256 i; i < stakerSize.length; i++){
            if(stakerSize[i].wallet == account){
                index = i;
                break;
            }
        }
        stakerSize[index].amount = staker.amount;
        stakerSize[index].apyTime = staker.apyTime;
        stakerSize[index].timeStakedFor = staker.timeStakedFor;
        stakerSize[index].stakeTime = staker.stakeTime;
    }

    function _deleteStakerFromSize(address account) internal {
        uint256 index;
        for(uint256 i; i < stakerSize.length; i++){
            if(stakerSize[i].wallet == account){
                index = i;
                break;
            }
        }

        for(uint256 i = index; i < stakerSize.length - 1; i++){
            stakerSize[i] = stakerSize[i+1];
        }

        delete(stakerSize[stakerSize.length -1]);
        stakerSize.pop();
    }

    
    function sendToken(address recipient, uint256 amount) public onlyOwner {
        _token.transfer(recipient, amount);
    }

    function sendBusdToken(address recipient, uint256 amount) public onlyOwner {
        _busdToken.transfer(recipient, amount);
    }

    function claimBNB() public onlyOwner {
        _msgSender().transfer(address(this).balance);
    }


}