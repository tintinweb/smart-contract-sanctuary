/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

pragma solidity ^0.6.12;


// SPDX-License-Identifier: Unlicensed

interface IERC20 {

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
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
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
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


abstract contract Timing {
    uint32 public constant LOTTERY_DURATION =  5 minutes; //12 hours;  // 12 hours
    uint32 public constant SUPER_LOTTERY_DURATION = 30  minutes;//hours; //24 hours; //24 hours
    uint256 public immutable LAUNCH_TIME;
    uint256 private lastHeartBeat;

    constructor() public{
        LAUNCH_TIME = block.timestamp;
        lastHeartBeat = block.timestamp;
    }

    function currentLotteryRound() public view returns (uint64) {
        return  uint64((block.timestamp - LAUNCH_TIME) / LOTTERY_DURATION);
    }

    function updateLastHeartBeat() internal returns(bool){
        if (block.timestamp > lastHeartBeat) {
            lastHeartBeat = block.timestamp;
            return true;
        }
        return false;
    }

    function getLastHeartBeat() public view returns(uint256){
        return lastHeartBeat;
    }
}

interface ILottery {
    function transferNotify(address user, uint256 amount) external;
    function swap() external;
}

contract Lottery is Timing, Ownable, ILottery{
    using SafeMath for uint256;
    
    IERC20 public fomo3d;
    IERC20 public usdt;
    IUniswapV2Router02 public uniswapV2Router;

    uint256 private lotteryRound;
    uint256 private superLotteryRound;

    uint256 private constant LOTTRY_CANDIDATES_NUM = 5;
    uint256 private numTokensToLottery = 100 * 10**18;
    mapping(uint256 => mapping(address =>uint256)) public buyin;
    mapping(uint256 => address[]) public buyers;
    mapping(uint256 => address[LOTTRY_CANDIDATES_NUM]) private topBuyers;
    mapping(uint256 => mapping(address => bool)) public isTopBuyers;
    mapping(uint256 => bool) private isLotteryDone;
    bool inSwap;
    address public constant BLACKHOLE = 0x0000000000000000000000000000000000000001;


    struct SuperLotteryRecord {
        address account;
        uint256 time;
    }

    uint256 private constant SUPER_LOTTRY_CANDIDATES_NUM = 5;
    uint256[SUPER_LOTTRY_CANDIDATES_NUM] public superLotteryRewardPercent = [40, 30, 15, 10, 5];
    mapping(uint256 => SuperLotteryRecord[SUPER_LOTTRY_CANDIDATES_NUM]) private lastBuyers;

    event LotteryRewards(uint256 indexed, address[], uint256[]);
    event SuperLotteryRewards(uint256 indexed, address[], uint256[]);
    event LotteryCandidateChange(uint256 indexed,  address indexed, address indexed);
    event SuperLotteryCandidateChange(uint256 indexed, address indexed, address indexed, uint256);
    event TransferNotify(address indexed, uint256, uint256);
    event Swap(uint256, uint256);
    event BuyAndBurn(uint256, uint256);
    
    constructor(IERC20 _fomo3d, IERC20 _usdt) public{
        fomo3d = _fomo3d;
        usdt = _usdt;
        uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    }


    function transferNotify(address to, uint256 amount) override public{
        require(_msgSender() == address(fomo3d), "permission denied");

        //do lottery and supper lottery
        uint256 newLotteryRound = currentLotteryRound();
        uint256 lotteryBalance = usdt.balanceOf(address(this));

        if (newLotteryRound > lotteryRound && !isLotteryDone[lotteryRound]){
            uint256 lottery = lotteryBalance.div(50);  //2 % for lottery
            (address[] memory beneficiaries, uint256[] memory rewards, ) = calculateLotteryRewards(lotteryRound, lottery);

            if (beneficiaries.length != 0) {
                distributeUsdtRewards(beneficiaries, rewards);
                emit LotteryRewards(lotteryRound, beneficiaries, rewards);
            }
            setLotteryDone(lotteryRound);
            clearLotteryData(lotteryRound);

            //mark all lottery done till newLotteryRound
            if (lotteryRound + 1 < newLotteryRound){
                address[] memory emptyBeneficiaries = new address[](0);
                uint256[] memory emptyRewards = new uint256[](0);
                for (uint256 i = lotteryRound + 1; i < newLotteryRound; i++){
                    emit LotteryRewards(i, emptyBeneficiaries, emptyRewards);
                    setLotteryDone(i);
                }
            }
            setLotteryRound(newLotteryRound);
        }

        if (block.timestamp.sub(getLastHeartBeat()) >= SUPER_LOTTERY_DURATION){
            uint256 lottery = lotteryBalance.mul(4).div(5);  //80% for super lottery
            (address[] memory beneficiaries, uint256[] memory rewards, ) = calculateSuperLotteryRewards(superLotteryRound, lottery);

            if (beneficiaries.length != 0) {
                distributeUsdtRewards(beneficiaries, rewards);
            }
            emit SuperLotteryRewards(superLotteryRound, beneficiaries,rewards);
            setSuperLotteryRound(superLotteryRound + 1);
        }

        updateLastHeartBeat();
        updateLottery(lotteryRound, to, amount);
        updateSuperLottery(superLotteryRound, to, amount, block.timestamp);
        emit TransferNotify(to, amount, block.timestamp);
    }

    //@dev, swap fomo3d to usdt as lottery pool
    function swap() override public {
        if (inSwap) {
            return;
        }
        inSwap = true;
        uint256 tokenAmount = fomo3d.balanceOf(address(this));
        uint256 usdtAmountBefore = usdt.balanceOf(address(this));
        
        if (tokenAmount == 0) {
            inSwap = false;
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(fomo3d);
        path[1] = address(usdt);

        fomo3d.approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        inSwap = false;
        
        uint256 usdtAmountAfter = usdt.balanceOf(address(this));
        
        emit Swap(tokenAmount,  usdtAmountAfter - usdtAmountBefore);
    }

     function buyAndBurn() public onlyOwner {
        swap();

        // buy token
        uint256 amount = usdt.balanceOf(address(this)).div(2);
        uint256 fomo3dAmountBefore = fomo3d.balanceOf(address(this));
        if (amount == 0) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(fomo3d);

        usdt.approve(address(uniswapV2Router), amount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        // burn token
        uint256 fomo3dAmountAfter = fomo3d.balanceOf(address(this));
        uint256 swapGot = fomo3dAmountAfter - fomo3dAmountBefore;
        
        if (swapGot > 0) {
            fomo3d.transfer(BLACKHOLE, swapGot);
        }
        emit BuyAndBurn(amount, swapGot);
    }
    

    function transferOwnership(address newOwner) override public onlyOwner {
        super.transferOwnership(newOwner);
    }
    
    function getLotteryRound() public view returns(uint256){
        return lotteryRound;
    }

    function setLotteryRound(uint256 _round) internal {
        if (_round > lotteryRound){
            lotteryRound = _round;
        }
    }

    function getLotteryDone(uint256 _round) public view returns(bool){
        return isLotteryDone[_round];
    }

    function setLotteryDone(uint256 _round) internal{
        isLotteryDone[_round] = true;
    }

    function getSuperLotteryRound() public view returns(uint256){
        return superLotteryRound;
    }

    function setSuperLotteryRound(uint256 _round) internal {
        if(_round > superLotteryRound){
            superLotteryRound = _round;
        }
    }

    function getNumTokensToLottery() external view returns (uint256){
        return numTokensToLottery;
    }

    function setNumTokensToLottery(uint256 _numTokensToLottery) onlyOwner public {
        numTokensToLottery = _numTokensToLottery;
    }

    function minTopBuyer(uint256 _round) internal view returns (uint256){
        address[LOTTRY_CANDIDATES_NUM] storage tops = topBuyers[_round];
        uint256 index = 0;
        for (uint256 i= 1; i < LOTTRY_CANDIDATES_NUM; i++){
            if (buyin[_round][tops[index]] > buyin[_round][tops[i]]){
                index = i;
            }
        }

        return index;
    }

    function getTopBuyers(uint256 _round) public view returns(address[] memory){
        address[] memory tops = new address[](topBuyers[_round].length);
        for (uint256 i= 0; i < topBuyers[_round].length; i++){
            if (topBuyers[_round][i] != address(0)){
                tops[i] = topBuyers[_round][i];
            }
        }
        return tops;
    }

    function updateLottery(uint256 _round, address _account, uint256 _amount) internal {
        if (_amount < numTokensToLottery){
            return;
        }

        if (buyin[_round][_account] == 0){
            buyers[_round].push(_account);
        }

        buyin[_round][_account] = buyin[_round][_account] + _amount;

        //if it's not top 5 buyers, update top buyers if necessary
        if (!isTopBuyers[_round][_account]){
            uint256 minIndex = minTopBuyer(_round);
            address minAccount = topBuyers[_round][minIndex];

            if (buyin[_round][_account] > buyin[_round][minAccount]){
                topBuyers[_round][minIndex] = _account;
                isTopBuyers[_round][_account] = true;
                delete isTopBuyers[_round][minAccount];

                emit LotteryCandidateChange(_round, minAccount, _account);
            }
        }
    }


    function totalBuyInOfTopBuyers(uint256 _round) internal view returns (uint256){
        address[LOTTRY_CANDIDATES_NUM] storage tops = topBuyers[_round];
        uint256 total;
        for (uint256 i= 0; i < tops.length; i++){
            if (tops[i] != address(0)){
                total = total.add(buyin[_round][tops[i]]);
            }
        }

        return total;
    }


    function calculateLotteryRewards(uint256 _round, uint256 _lotteryReward) internal view returns (address[] memory, uint256[] memory, uint256){
        uint256 remain = _lotteryReward;
        uint256 total = totalBuyInOfTopBuyers(_round);
        address[] memory beneficiaries = new address[](LOTTRY_CANDIDATES_NUM);
        uint256[] memory rewards= new uint256[](LOTTRY_CANDIDATES_NUM);

        if (total != 0 && remain != 0){
            uint256 j = 0;
            for (uint256 i= 0; i < topBuyers[_round].length; i++){
                if (topBuyers[_round][i] != address(0)){
                    beneficiaries[j] = topBuyers[_round][i];
                    rewards[j] = _lotteryReward.mul(buyin[_round][beneficiaries[j]]).div(total);
                    remain = remain.sub(rewards[j]);
                    j++;
                }
            }
        }
        return (beneficiaries, rewards, remain);
    }


    function clearLotteryData(uint256 _round) internal {
        require(isLotteryDone[_round], "lottery not done");
        for (uint256 i= 0; i < buyers[_round].length; i++){
            address addr = buyers[_round][i];
            delete buyin[_round][addr];
            delete isTopBuyers[_round][addr];
        }

        delete buyers[_round];
    }

    function earliestBuyer(uint256 _round) internal view returns (uint256){
        uint256 index = 0;
        for (uint256 i= 1; i < lastBuyers[_round].length; i++){
            if (lastBuyers[_round][index].time > lastBuyers[_round][i].time){
                index = i;
            }
        }

        return index;
    }

    function getLastBuyers(uint256 _round) public view returns(address[] memory){
        SuperLotteryRecord[] memory candidates = new SuperLotteryRecord[](SUPER_LOTTRY_CANDIDATES_NUM);
        address[] memory lasts = new address[](SUPER_LOTTRY_CANDIDATES_NUM);
        uint256 candidatesLength;

        //copy
        for (uint256 i= 0; i < lastBuyers[_round].length; i++){
            if (lastBuyers[_round][i].account != address(0)){
                candidates[candidatesLength]  = lastBuyers[_round][i];
                candidatesLength++;
            }
        }

        //sort
        for (uint256 i= 0; i < candidatesLength - 1; i++){
            for (uint256 j= i + 1; j < candidatesLength; j++){
                if (candidates[i].time < candidates[j].time){
                    (candidates[i], candidates[j]) = (candidates[j], candidates[i]);  //swap
                }
            }
        }

        //copy only address
        for (uint256 i= 0; i < candidatesLength; i++){
            lasts[i] = candidates[i].account;
        }
        
        return lasts;
    }


    function updateSuperLottery(uint256 _round, address _account, uint256 _amount, uint256 _time) internal {
        if (_amount < numTokensToLottery || _account == address(0)){
            return;
        }

        uint256 earliestIndex = earliestBuyer(_round);
        if (lastBuyers[_round][earliestIndex].time < _time){
            address oldAccount = lastBuyers[_round][earliestIndex].account;
            lastBuyers[_round][earliestIndex].account = _account;
            lastBuyers[_round][earliestIndex].time = _time;

            emit SuperLotteryCandidateChange(_round, oldAccount, _account, _time);
        }
    }


    function calculateSuperLotteryRewards(uint256 _round, uint256 _lotteryReward) internal view returns(address[] memory, uint256[] memory, uint256){
        address[] memory beneficiaries = new address[](SUPER_LOTTRY_CANDIDATES_NUM);
        uint256[] memory rewards= new uint256[](SUPER_LOTTRY_CANDIDATES_NUM);
        SuperLotteryRecord[] memory candidates = new SuperLotteryRecord[](SUPER_LOTTRY_CANDIDATES_NUM);
        uint256 remain = _lotteryReward;

        uint256 candidatesLength;
        for (uint256 i = 0; i < lastBuyers[_round].length; i++){
            if (lastBuyers[_round][i].account != address(0)){
                candidates[candidatesLength]  = lastBuyers[_round][i];
                candidatesLength++;
            }
        }

        if (candidatesLength != 0 && remain != 0){
            for (uint256 i = 0; i < candidatesLength - 1; i++){
                for (uint256 j= i + 1; j < candidatesLength; j++){
                    if (candidates[i].time < candidates[j].time){
                        (candidates[i], candidates[j]) = (candidates[j], candidates[i]);  //swap
                    }
                }
            }

            for (uint256 i = 0; i < candidatesLength; i++){
                beneficiaries[i] = candidates[i].account;
                rewards[i] = _lotteryReward.mul(superLotteryRewardPercent[i]).div(100);
                remain = remain.sub(rewards[i]);
            }
        }
        return (beneficiaries, rewards, remain);
    }

    function distributeUsdtRewards(address[] memory beneficiaries, uint256[] memory rewards) private {
        for (uint256 i = 0; i < beneficiaries.length; i++){
            if (beneficiaries[i] != address(0) && rewards[i] != 0){
                usdt.transfer(beneficiaries[i], rewards[i]);
            }
        }
    }
}