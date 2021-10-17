/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity ^0.7.0;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _owner = newOwner;
    }
}



pragma solidity ^0.7.0;
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




//--------------------------CROWD SALE------------------------

pragma solidity ^0.7.0;


interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PreSale is Ownable {
    using SafeMath for uint256;

    IERC20 public dexrToken;
    IERC20 public dexrShToken;
    IERC20 public nucleusToken;

    struct VestingPlan {
        uint256 vType;
        uint256 totalBalance;
        uint256 totalClaimed;
        uint256 start;
        uint256 end;
        uint256 releasePercentWhenStart;
        uint256 releasePercentEachMonth;
        uint256 claimedCheckPoint;
    }
    mapping (address => VestingPlan) public vestingList;

    uint256 public totalTokenForSeed;
    uint256 public totalTokenForVip;
    uint256 public totalTokenForHolder;
    uint256 public totalTokenForPublic;

    uint256 public soldAmountSeed        = 0;
    uint256 public soldAmountVip         = 0;
    uint256 public soldAmountHolder      = 0;
    uint256 public soldAmountPublic      = 0;

    uint256 public _TOTAL_SOLD_TOKEN;
    uint256 public _TOTAL_DEPOSIT_ETH;

    uint256 public _MAX_ETH_CONTRIBUTION = 100 * 10**18;
    uint256 public _MIN_ETH_CONTRIBUTION = 10**16;

    uint256 public _TYPE_SEED = 1;
    uint256 public _TYPE_VIP = 2;
    uint256 public _TYPE_HOLDER = 3;
    uint256 public _TYPE_PUBLIC = 4;

    uint256 public MONTH = 10* 60;
    
    mapping(address => bool) public listSeed;
    mapping(address => uint256) public ethPurchased;

    constructor() {
        dexrToken = IERC20(0x603cA1476Ef0123c939367efDB6d195975C118A5);
        dexrShToken = IERC20(0x9276a5531027bFfd6C5F3E3D3Bf39FcdA4DEA411);
        nucleusToken = IERC20(0xc1F5a0Fd7Db9A22DA3c978f2e27a4a3E195Cc649);
        
        totalTokenForSeed    = dexrToken.totalSupply().mul(10).div(100);
        totalTokenForVip     = dexrToken.totalSupply().mul(4).div(100);
        totalTokenForHolder  = dexrToken.totalSupply().mul(4).div(100);
        totalTokenForPublic  = dexrToken.totalSupply().mul(2).div(100);
    }

    receive() external payable {
        deposite();
    }

    function ownerWithdrawEthAndNucleus() public onlyOwner{        
        payable(msg.sender).transfer(address(this).balance);
        nucleusToken.transfer(address(msg.sender), nucleusToken.balanceOf(address(this)));
    }

    function ownerWithdrawToken() public onlyOwner{    
        uint256 withdrawable = totalTokenForSeed + totalTokenForVip + totalTokenForHolder + totalTokenForPublic - _TOTAL_SOLD_TOKEN;  
        dexrToken.transfer(msg.sender, withdrawable);
        dexrShToken.transfer(msg.sender, withdrawable);
    }

    function ownerAddSeedWhitelist(address[] calldata accounts, bool granted) public onlyOwner {
        for( uint256 i = 0; i < accounts.length; i++){
            listSeed[accounts[i]] = granted;
        }
    }

    function getMemberType(address account) public view returns(uint256){
        VestingPlan memory vestPlan = vestingList[account];
        if(vestPlan.vType > 0)
            return vestPlan.vType;

        uint256 memType = _TYPE_PUBLIC;
        if(listSeed[account]){
            memType = _TYPE_SEED;
        }else if(nucleusToken.balanceOf(account) >= 1000000000 * 10**nucleusToken.decimals()){
            memType = _TYPE_VIP;
        }else if(nucleusToken.balanceOf(account) >= 20000000 * 10**nucleusToken.decimals()){
            memType = _TYPE_HOLDER;
        }
        return memType;
    }

    function getRate(address account) public view returns(uint256) {
        uint256 memType = getMemberType(account);
        uint256 rate;
        if(memType == _TYPE_SEED){
            rate = 144927;
        }else if(memType == _TYPE_VIP){
            rate = 71428;
        }else if(memType == _TYPE_HOLDER){
            rate = 47619;
        }else {
            rate = 14492;
        }
        return rate;
    }

    function getClaimableInVesting(address account) public view returns (uint256){
        VestingPlan memory vestPlan = vestingList[account];

        //Already withdraw all
        if(vestPlan.totalClaimed == vestPlan.totalBalance){
            return 0;
        }

        //No infor
        if(vestPlan.start == 0 || vestPlan.end == 0 || vestPlan.totalBalance == 0){
            return 0;
        }
        
        uint256 currentTime = block.timestamp;
        if(currentTime >= vestPlan.end){
            return vestPlan.totalBalance.sub(vestPlan.totalClaimed);
        }else {
            uint256 currentCheckPoint = (currentTime - vestPlan.start) / MONTH;
            if(currentCheckPoint > vestPlan.claimedCheckPoint){
                uint256 claimable =  ((currentCheckPoint - vestPlan.claimedCheckPoint)* vestPlan.releasePercentEachMonth * vestPlan.totalBalance) / 100;
                return claimable;
            }else
                return 0;
        }
    }

    function balanceRemainingInVesting(address account) public view returns(uint256){
        VestingPlan memory vestPlan = vestingList[account];
        return vestPlan.totalBalance -  vestPlan.totalClaimed;
    }

    function withDrawFromVesting() public {
        VestingPlan storage vestPlan = vestingList[msg.sender];

        uint256 claimableAmount = getClaimableInVesting(msg.sender);
        require(claimableAmount > 0, "There isn't token in vesting that claimable at the moment");

        uint256 currentTime = block.timestamp;
        if(currentTime > vestPlan.end){
            currentTime = vestPlan.end;
        }
        
        vestPlan.claimedCheckPoint = (currentTime - vestPlan.start) / MONTH;
        vestPlan.totalClaimed = vestPlan.totalClaimed.add(claimableAmount);
        dexrToken.transfer(msg.sender, claimableAmount);
        dexrShToken.transfer(msg.sender, claimableAmount);
    }

    function deposite() public payable {
        require(msg.value >= _MIN_ETH_CONTRIBUTION, "Please check minimum ETH contribution");
        require(ethPurchased[msg.sender].add(msg.value) <= _MAX_ETH_CONTRIBUTION, "Check max contribution per wallet");
        
        uint256 memType = getMemberType(msg.sender);
        uint256 rate = getRate(msg.sender);

        uint256 numToken = msg.value.mul(rate);
        require(_TOTAL_SOLD_TOKEN.add(numToken) <= dexrToken.balanceOf(address(this)), "Do not enough token in contract");

        //User have to pay Nucleus with amount DEXR * 200
        nucleusToken.transferFrom(address(msg.sender), address(this), numToken.mul(200));

        ethPurchased[msg.sender]=  ethPurchased[msg.sender].add(msg.value);
        _TOTAL_DEPOSIT_ETH = _TOTAL_DEPOSIT_ETH.add(msg.value);
        _TOTAL_SOLD_TOKEN = _TOTAL_SOLD_TOKEN.add(numToken);

        addingVestToken(msg.sender, numToken, memType);
    }

    function addingVestToken(address account, uint256 amount, uint256 vType) private {
        VestingPlan storage vestPlan = vestingList[account];
        if(vType == _TYPE_SEED){
            require(soldAmountSeed.add(amount) <= totalTokenForSeed, "Exceed token for SEED");
            soldAmountSeed = soldAmountSeed.add(amount);
            vestPlan.releasePercentWhenStart = 10;
            vestPlan.releasePercentEachMonth = 10;
        }else if(vType == _TYPE_VIP){
            require(soldAmountVip.add(amount) <= totalTokenForVip, "Exceed token for VIP");
            soldAmountVip = soldAmountVip.add(amount);
            vestPlan.releasePercentWhenStart = 20;
            vestPlan.releasePercentEachMonth = 20;
        }else if(vType == _TYPE_HOLDER){
            require(soldAmountHolder.add(amount) <= totalTokenForHolder, "Exceed token for HOLDER");
            soldAmountHolder = soldAmountHolder.add(amount);
            vestPlan.releasePercentWhenStart = 25;
            vestPlan.releasePercentEachMonth = 25;
        }else if(vType == _TYPE_PUBLIC){
            require(soldAmountPublic.add(amount) <= totalTokenForPublic, "Exceed token for Public");
            soldAmountPublic = soldAmountPublic.add(amount);
            dexrToken.transfer(account, amount);
            dexrShToken.transfer(account, amount);
            return;
        }

        vestPlan.vType = vType;
        vestPlan.totalBalance = vestPlan.totalBalance.add(amount);
        vestPlan.start = vestPlan.start == 0 ? block.timestamp : vestPlan.start;
        vestPlan.end = vestPlan.end == 0 ? block.timestamp + ((100 - vestPlan.releasePercentWhenStart)/vestPlan.releasePercentEachMonth) * MONTH : vestPlan.end;

        uint256 claimNow = (amount * vestPlan.releasePercentWhenStart)/100;
        vestPlan.totalClaimed = vestPlan.totalClaimed.add(claimNow);

        dexrToken.transfer(account, claimNow);
        dexrShToken.transfer(account, claimNow);
    }
}