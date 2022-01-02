/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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


interface IBEP20 {
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

contract PresaleContract is Ownable {
    using SafeMath for uint256;

    IBEP20 public tokenBUSD = IBEP20(0x5c9926a5D41bEb53aa6542e33CD06791E13E6135);
    IBEP20 public tokenPCA = IBEP20(0xCf43e66D19d6B290D056a7EAa9419A6259FA65ed);

    /* PRIVATE SALE */
    struct Vesting {
        uint256 totalBalance;
        uint256 totalClaimed;
        uint256 start;
        uint256 end;
        uint256 claimedCheckPoint;
    }
    mapping (address => Vesting) public privateList;
    uint256 VEST_RELEASE_EACH_MONTH = 10;
    uint256 VEST_MONTH = 1 days;
    uint256 VEST_CLIFF = 6 * VEST_MONTH;

    uint256 public privateHardCap;
    uint256 public privateSoldAmount;
    uint256 public privateRate;
    uint256 public privateMinDeposit;
    uint256 public privateMaxDeposit;
    bool public privateSaleEnabled;
    mapping (address => uint256) public privateBUSDDeposit;
    mapping (address=>bool) public privateWhitelist;

    function ownerSetupPrivateSale(uint256 totalAmount, uint256 rate, uint256 min, uint256 max) public onlyOwner{
        privateHardCap = totalAmount;
        privateRate = rate;
        privateMinDeposit= min;
        privateMaxDeposit = max;
    }

    function ownerEnablePrivateSale(bool enabled) public onlyOwner{
        privateSaleEnabled = enabled;
    }

    function ownerAddWhitelistForPrivate(address[] calldata accounts) public onlyOwner{
        for( uint256 i = 0; i < accounts.length; i++){
            privateWhitelist[accounts[i]] = true;
        }
    }

    function buyPrivateSale(uint256 busdAmount) public {
        require(privateSaleEnabled, "Private sale is not open this time");
        require(privateWhitelist[msg.sender], "You are not allowed to buy private sale");
        require(busdAmount >= privateMinDeposit, "Check minimum amount BUSD");

        privateBUSDDeposit[msg.sender] = privateBUSDDeposit[msg.sender].add(busdAmount);
        require(privateBUSDDeposit[msg.sender] <= privateMaxDeposit, "Exceed maximum amount BUSD deposit");
        tokenBUSD.transferFrom(msg.sender, address(this), busdAmount);

        uint256 tokenAmount = busdAmount.mul(privateRate);
        privateSoldAmount = privateSoldAmount.add(tokenAmount);
        require(privateSoldAmount <= privateHardCap,"Exceed total amount for private sale");
    
        Vesting storage vestPlan = privateList[msg.sender];
        vestPlan.totalBalance = vestPlan.totalBalance.add(tokenAmount);
        vestPlan.start = vestPlan.start == 0 ? block.timestamp : vestPlan.start;
        vestPlan.end = vestPlan.end == 0 ? block.timestamp + 15 * VEST_MONTH : vestPlan.end;
    }

    function availableAmountPrivate(address account) public view returns (uint256){
        Vesting memory vestPlan = privateList[account];

        //Already withdraw all
        if(vestPlan.totalClaimed >= vestPlan.totalBalance){
            return 0;
        }

        //No infor
        if(vestPlan.start == 0 || vestPlan.totalBalance == 0){
            return 0;
        }
        
        uint256 currentTime = block.timestamp;
        if(currentTime >= vestPlan.end){
            return vestPlan.totalBalance.sub(vestPlan.totalClaimed);
        }else if(currentTime < vestPlan.start.add(VEST_CLIFF)){
            return 0;
        }else{
            uint256 currentCheckPoint = (currentTime - vestPlan.start.add(VEST_CLIFF)) / VEST_MONTH + 1;
            if(currentCheckPoint > vestPlan.claimedCheckPoint){
                uint256 claimable =  ((currentCheckPoint - vestPlan.claimedCheckPoint)* VEST_RELEASE_EACH_MONTH * vestPlan.totalBalance) / 100;
                return claimable;
            }else
                return 0;
        }
    }

    function claimTokenPrivate() public {
        Vesting storage vestPlan = privateList[msg.sender];
        uint256 claimableAmount = availableAmountPrivate(msg.sender);
        if(claimableAmount > 0){
            uint256 currentTime = block.timestamp;
            if(currentTime > vestPlan.end){
                currentTime = vestPlan.end;
            }
            vestPlan.claimedCheckPoint = (currentTime - vestPlan.start.add(VEST_CLIFF)) / VEST_MONTH + 1;
            vestPlan.totalClaimed = vestPlan.totalClaimed.add(claimableAmount);
            tokenPCA.transfer(msg.sender, claimableAmount);
        }
    }

    function nextClaimPrivate (address account) public view returns (uint256){
        Vesting memory vestPlan = privateList[account];

        if(vestPlan.totalBalance > 0) { // This account bought private
            uint256 nextClaimPrivateVesting = vestPlan.claimedCheckPoint * VEST_MONTH + vestPlan.start.add(VEST_CLIFF);
            return nextClaimPrivateVesting;
        }else
            return 0;
    }

    function lockedAmountPrivate(address account) public view returns(uint256){
        Vesting memory vestPlan = privateList[account];
        return  (vestPlan.totalBalance -  vestPlan.totalClaimed) - availableAmountPrivate(account);        
    }

    /* PUBLIC SALE */
    struct PublicRound {
        uint256 hardcap;
        uint256 sold;
        uint256 rate;
        uint256 minDeposit;
        uint256 maxDeposit;
    }
    mapping (uint256 => PublicRound) public publicRound;
    mapping(uint256 => mapping (address => uint256)) public publicBUSDDeposit;
    uint256 public currentPublicRound;

    bool public publicSaleEnable;
    uint256 public claimTimePublic = 1643500800; // 30/1/2022 - https://www.epochconverter.com/
    mapping (address => uint256) public publicVestingAmount;

    function ownerSetupNewPublicSale(uint256 totalAmount, uint256 rate, uint256 min, uint256 max) public onlyOwner{
        currentPublicRound = currentPublicRound + 1;
        publicRound[currentPublicRound].hardcap = totalAmount;
        publicRound[currentPublicRound].rate = rate;
        publicRound[currentPublicRound].minDeposit = min;
        publicRound[currentPublicRound].maxDeposit = max;
    }

    function ownerSetOpenTimePublicSale( uint256 epochTimeOpenForClaim) public onlyOwner{
        claimTimePublic = epochTimeOpenForClaim;
    }

    function ownerEnablePublicSale(bool enabled) public onlyOwner{
        publicSaleEnable = enabled;
    }

    function buyPublicSale(uint256 busdAmount) public {
        require(currentPublicRound > 0, "Public Sale is not started");
        require(publicSaleEnable, "Public sale is not open this time");

        PublicRound storage round = publicRound[currentPublicRound];
        require(busdAmount >= round.minDeposit, "Minimum amount is 1 BUSD");

        publicBUSDDeposit[currentPublicRound][msg.sender] = publicBUSDDeposit[currentPublicRound][msg.sender].add(busdAmount);
        require(publicBUSDDeposit[currentPublicRound][msg.sender] <= round.maxDeposit, "Exceed maximum amount BUSD deposit this round");
        tokenBUSD.transferFrom(msg.sender, address(this), busdAmount);

        uint256 tokenAmount = busdAmount.mul(round.rate);
        publicVestingAmount[msg.sender] = publicVestingAmount[msg.sender].add(tokenAmount);

        round.sold = round.sold.add(tokenAmount);
        require(round.sold  <= round.hardcap,"Exceed total amount for this round");
    }

    function claimTokenPublic() public {
        if (publicVestingAmount[msg.sender] > 0 && block.timestamp > claimTimePublic) {
            tokenPCA.transfer(msg.sender, publicVestingAmount[msg.sender]);
            publicVestingAmount[msg.sender] = 0;
        }
    }

    /*Owner withdraw */
    function ownerWithdrawBUSD() public onlyOwner {
        tokenBUSD.transfer(msg.sender, tokenBUSD.balanceOf(address(this)));
    }

    function ownerWithdrawUnsoldPCA() public onlyOwner {
        uint256 totalPublicSold;
        for(uint256 i = 1; i <= currentPublicRound; i ++){
            totalPublicSold += publicRound[currentPublicRound].sold;
        }
        tokenPCA.transfer(msg.sender, tokenPCA.balanceOf(address(this)) - totalPublicSold - privateSoldAmount);
    }
}