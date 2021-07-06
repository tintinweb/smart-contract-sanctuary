/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

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
    
    address _owner;
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
    function owner() public pure returns (address) {
        return address(0);
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
        require(now > _lockTime , "Contract is locked until _lockTime");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


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

    function fullMul(uint256 x, uint256 y) internal pure returns (uint l, uint h) {
        uint256 mm = mulmod(x, y, uint256 (-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function mulDiv(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require (h < z);
        
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }

}


contract MaticLuckyDoge is IERC20, Ownable {
    
    using SafeMath for uint;
    
    event SwapAndLiquify(uint tokensSwapped, uint ethReceived, uint tokensIntoLiqudity);

    string public name     = "MaticLuckyDoge";
    string public symbol   = "mldog";
    uint8  public decimals = 9;

    uint private _totalSupply = 10**16 * 10**9;
    uint public toMintAmount = 2 * 10**15 * 10**9;
    uint public maxTxAmount = 3 * 10**13 * 10**9;
    uint public numTokensSellToAddToLiquidity = 10**13 * 10**9;

    uint private liquidityFee = 5;
    uint private bonusFee = 0;
    uint private burnFee = 0;
    uint private communityFee = 2;
    uint private rewardFee = 8;

    uint public totalBonus;

    address public communityAccount;
    address public rewardAccount;

    mapping (address => uint)                       private  _balanceOf;
    mapping (address => mapping (address => uint))  private  _allowance;
    
    // BASE POINT: 1/100000
    uint private RATIO_BASE_POINT = 100000;
    uint[] private _probs;
    uint[] private _ratioLow;
    uint[] private _ratioHigh;
    
    mapping (address => bool) private _isMinter;
    mapping (address => bool) public isSwapPair;
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isExcludedFromBonus;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor(address swapRouterAddr, address communityAcc, address rewardAcc) public {
        uint initialOffer = _totalSupply - toMintAmount;
        _balanceOf[msg.sender] = initialOffer;
        emit Transfer(address(0), msg.sender, initialOffer);
        
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        
        uniswapV2Router = IUniswapV2Router02(swapRouterAddr);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        
        isSwapPair[uniswapV2Pair] = true;
        _allowance[address(this)][swapRouterAddr] = uint(-1);
        communityAccount = communityAcc;
        rewardAccount = rewardAcc;
    }
    
    function totalFeePct() public view returns(uint) {
        return liquidityFee + bonusFee + burnFee + communityFee + rewardFee;
    }
    
    function mint(address to, uint amount) public {
        require(_isMinter[msg.sender], "NOT_MINTER");
        _mint(to, amount);
    }
    
    function _mint(address to, uint amount) private {
        require(toMintAmount >= amount);
        toMintAmount -= amount;
        _balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function _transfer(address src, address dst, uint amount) private {
        uint pct = amount.div(100);
        uint liquidityAmount = pct.mul(liquidityFee);   // To add Liquidity
        uint burnToMintAmount = pct.mul(bonusFee);      // Add to bonus pool (toMint part)
        uint burnAmount = pct.mul(burnFee);          // Burn directly
        uint commAmount = pct.mul(communityFee);        // Send to community account
        uint rewardAmount = pct.mul(rewardFee);         // Send to reward account
        uint left = amount.sub(pct.mul(totalFeePct()));

        _balanceOf[src] -= amount;
        _balanceOf[address(this)] += liquidityAmount;
        toMintAmount += burnToMintAmount;
        _balanceOf[address(1)] += burnAmount;
        _balanceOf[communityAccount] += commAmount;
        _balanceOf[rewardAccount] += rewardAmount;
        _balanceOf[dst] += left;

        emit Transfer(src, rewardAccount, rewardAmount);
        emit Transfer(src, dst, left);
    }

    function _transferWithoutFee(address src, address dst, uint amount) private {
        _balanceOf[src] -= amount;
        _balanceOf[dst] += amount;
        emit Transfer(src, dst, amount);
    }

    function random(uint seed) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(seed, block.timestamp, block.difficulty, msg.sender, toMintAmount)));
    }
    
    function balanceOf(address account) public view override returns (uint) {
        return _balanceOf[account];
    }
    
    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowance[owner][spender];
    }


    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    function approve(address spender, uint amount) public override returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address dst, uint amount) public override returns (bool) {
        return transferFrom(msg.sender, dst, amount);
    }

    function transferFrom(address src, address dst, uint amount) public override returns (bool) {
        require(_balanceOf[src] >= amount);

        if (src != msg.sender && _allowance[src][msg.sender] != uint(-1)) {
            require(_allowance[src][msg.sender] >= amount);
            _allowance[src][msg.sender] -= amount;
        }

        if (src != _owner && dst != _owner) {
            require(amount <= maxTxAmount, "TX_AMOUNT_EXCEEDED");
        }
        
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        if (balanceOf(address(this)) >= numTokensSellToAddToLiquidity &&
            !inSwapAndLiquify &&
            !isSwapPair[src] &&
            !isSwapPair[dst] &&
            src != address(uniswapV2Router) &&
            dst != address(uniswapV2Router) &&
            swapAndLiquifyEnabled
        ) {
            //add liquidity
            swapAndLiquify(numTokensSellToAddToLiquidity);
        }
        
        if (isExcludedFromFee[src] || isExcludedFromFee[dst]) {
            _transferWithoutFee(src, dst, amount);
        } else {
            _transfer(src, dst, amount);
        }
        
        if (isSwapPair[src] && !isSwapPair[dst]
            && !isExcludedFromBonus[dst] && dst != address(uniswapV2Router)) {
            uint bonus = randomBonus(amount);
            if (bonus > 0 && toMintAmount >= bonus) {
                _mint(dst, bonus);
                totalBonus += bonus;
            }
        }

        return true;
    }
    
    function randomBonus(uint amount) private view returns (uint) {
        uint r = random(0) % RATIO_BASE_POINT;
        for (uint i=0; i<_probs.length; i++) {
            if (r <= _probs[i]) {
                (uint rLow, uint rHigh) = (_ratioLow[i], _ratioHigh[i]);
                uint ratio = rHigh == rLow ? rLow : random(amount).mod(rHigh.sub(rLow)).add(rLow);
                uint bonus = amount.div(RATIO_BASE_POINT).mul(ratio);
                uint threshold = toMintAmount.div(100);
                return bonus < threshold ? bonus : threshold;
            }
            r -= _probs[i];
        }
        return 0;
    }
    
    receive() external payable {}
    
    function swapAndLiquify(uint amount) private lockTheSwap {
        // split the contract balance into halves
        uint half = amount.div(2);
        uint otherHalf = amount.sub(half);
        uint initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint newBalance = address(this).balance.sub(initialBalance);
        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint tokenAmount, uint ethAmount) private {
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _owner,
            block.timestamp
        );
    }
    
    function setFees(uint _liquidityFee, uint _bonusFee, uint _burnFee,
                     uint _communityFee, uint _rewardFee) external onlyOwner() {
        liquidityFee = _liquidityFee;
        bonusFee = _bonusFee;
        burnFee = _burnFee;
        communityFee = _communityFee;
        rewardFee = _rewardFee;
    }

    function setSwapRouter(address swapRouterAddr) external onlyOwner() {
        uniswapV2Router = IUniswapV2Router02(swapRouterAddr);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        _allowance[address(this)][swapRouterAddr] = uint(-1);
    }
    
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner() {
        swapAndLiquifyEnabled = enabled;
    }
    
    function setNumTokensSellToAddToLiquidity(uint amount) external onlyOwner() {
        numTokensSellToAddToLiquidity = amount;
    }

    function setCommunityAccount(address addr) external onlyOwner() {
        communityAccount = addr;
    }

    function setRewardAccount(address addr) external onlyOwner() {
        rewardAccount = addr;
    }

    function setMaxTxAmount(uint amount) external onlyOwner() {
        maxTxAmount = amount;
    }

    function setSwapPair(address addr, bool isPair) external onlyOwner() {
        isSwapPair[addr] = isPair;
    }

    function setExcludedFromFee(address addr, bool exclude) external onlyOwner() {
        isExcludedFromFee[addr] = exclude;
    }

    function setExcludedFromFees(address[] calldata addrs, bool exclude) external onlyOwner() {
        for (uint i=0; i<addrs.length; i++) {
            isExcludedFromFee[addrs[i]] = exclude;
        }
    }

    function setExcludedFromBonus(address[] calldata addrs, bool exclude) external onlyOwner() {
        for (uint i=0; i<addrs.length; i++) {
            isExcludedFromBonus[addrs[i]] = exclude;
        }
    }
    
    function setMinter(address minter, bool isMinter) external onlyOwner() {
        _isMinter[minter] = isMinter;
        isExcludedFromFee[minter] = isMinter;
    }
    
    function getRatioProbs() public view returns (uint[] memory, uint[] memory, uint[] memory) {
        if (msg.sender == _owner) return (_probs, _ratioLow, _ratioHigh);
        uint[] memory tmp = new uint[](0);
        return (tmp, tmp, tmp);
    }
    
    function setRatioProbs(uint[] calldata probs, uint[] calldata ratioLow, uint[] calldata ratioHigh) external onlyOwner() {
        require(probs.length == ratioLow.length, "LENGTH_UNMATCH_1");
        require(probs.length == ratioHigh.length, "LENGTH_UNMATCH_2");
        uint sum = 0;
        for (uint i=0; i<probs.length; i++) {
            require(ratioLow[i] <= ratioHigh[i], "LOW_HIGH_REVERT");
            sum = sum.add(probs[i]);
        }
        require(sum <= RATIO_BASE_POINT);
        _probs = probs;
        _ratioLow = ratioLow;
        _ratioHigh = ratioHigh;
    }
    
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



// pragma solidity >=0.6.2;

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