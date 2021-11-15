// SPDX-License-Identifier: NONE


//TEST CONTRACT. DO NOT LAUNCH THIS
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./uniswap/IUniswapV2Router02.sol";
import "./Mining.sol";

interface IRUG is IERC20{
    function burn(uint256) external;
}
contract Lottery is Ownable{
    using Mining for bytes32;
    using SafeMath for uint128;

    address immutable public RUG;
    address immutable public UNISWAP_ROUTER;
    address immutable public WBNB;
    address payable immutable public TREASURY;
    address payable[] public devs;
    uint32 constant public JACKPOT = 2**32 - 1;         //2^32-1 is a special num to signify jackpot. Actual jackpot multiplier is this num as the KEY in prizes
    uint256 immutable public BLOCK_VEST_PERIOD;

    mapping(address => guess) public entry;                
    mapping(uint32 => uint32) public prizes;                   //If KEY number of leading 0s, then VAL multiplier to wager

    struct guess{
        bytes32 guess;
        uint256 blockSubmited;
        uint128 wager;
        uint128 vestEnd;
    }

    event RugBurn(uint256);
    event Win(address, uint256);
    event Jackpot(address, uint256);

    constructor(
        address _rug,
        uint128 _blockVestPeriod, 
        address _uniswapV2Router, 
        address _wbnb,
        address payable _treasury,
        address payable[] memory _devs
        )
        {
        RUG = _rug;
        BLOCK_VEST_PERIOD = _blockVestPeriod;
        UNISWAP_ROUTER = _uniswapV2Router;
        WBNB = _wbnb;
        TREASURY = _treasury;
        devs = _devs;
        //Default prizes
        prizes[1] = 10;
        prizes[2] = 100;
        prizes[3] = JACKPOT;
        prizes[JACKPOT] = 1000;
    }
    //--------------------------------------------------------------------------
    //TEST FUNCTIONS. IF YOU SEE THESE FUNCTIONS. THIS CODE SHOULD NOT BE IN PRODUCTION
    //--------------------------------------------------------------------------

    function testReward(uint32 prizeIndex, uint128 wager, address payable receiver)external{
        _sendReward(prizes[prizeIndex], wager, receiver);
    }

    function testJackpot(uint128 wager, address payable receiver)external{
        _sendReward(prizes[JACKPOT], wager, receiver);
        _jackpot();
    }

    //----------------------------------------------------------------------------

    function setPrize(uint8 _difficulty, uint8 _multiplier) external onlyOwner{
        require(_difficulty != 0, "_difficulty cannot be 0");
        prizes[_difficulty] = _multiplier;
    }

    function submitEntry(uint128 _x) external payable{
        require(msg.value > 0, "must send a wager");
        entry[msg.sender] = guess(
            {guess: keccak256(abi.encodePacked(_x)),           //guess is stored as the hash of the number entry
            blockSubmited: block.number,
            wager: uint128(msg.value),
            vestEnd: uint128(block.number + BLOCK_VEST_PERIOD)}
        );
    }

    /// @dev fails if entry is not a winner
    function claimEntry()external{
        guess memory _entry = entry[msg.sender];
        require(_entry.wager != 0, "No wager recorded");
        require(block.number >= _entry.vestEnd && block.number - _entry.vestEnd < 256, "cannot claimEntry if less than vest period or more than 255 blocks have passed");

        //First reset the entry
        entry[msg.sender] = guess(0,0,0,0);

        bytes32 hash = _entry.guess;
        // Hash from most recent to oldest so miners have as little controll as possible
        for(uint128 i = 0; i < BLOCK_VEST_PERIOD; i++){
            hash = keccak256(abi.encodePacked(
                hash,
                blockhash(_entry.vestEnd - i)
                ));
        }
        uint8 score = hash.countScore();
        if( score == 0){
            revert("No reward to claim. Better luck next time");
        }else{
            //Go down to highest score set if score is higher than what is defined
            while(prizes[score] == 0){
                score--;
            }
            if(prizes[score] == JACKPOT){
                _sendReward(prizes[JACKPOT], _entry.wager, payable(msg.sender));
                _jackpot();
                emit Jackpot(msg.sender, prizes[JACKPOT] * _entry.wager);
            }else{
                _sendReward(prizes[score], _entry.wager, payable(msg.sender));
                emit Win(msg.sender,prizes[score] * _entry.wager);
            }
        }
    }

    function _sendReward(uint32 _multipler, uint128 _wager, address payable _receiver) private{
        uint toPay = _wager * _multipler;
        uint thisBalance = address(this).balance;
        require(thisBalance > 0, "There is no money to give :(");
        //If there is enough balance in the contract to pay out
        if(thisBalance > toPay){
            _receiver.transfer(toPay);
        }else{
            _receiver.transfer(thisBalance);
        }
    }

    function _jackpot() private{
        uint256 amt = address(this).balance;

        //First send treasury fee (half)
        TREASURY.transfer(amt/2);

        //Send dev fee next ~8.3333%
        uint256 devFee = amt/12;
        for(uint8 i = 0; i < devs.length; i++){
            devs[i].transfer(devFee/devs.length);
        }

        //Use the funds to buy a bunch of Rug
        amt = address(this).balance;
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER);
        address[] memory path;
            path = new address[](2);
            path[0] = WBNB;
            path[1] = RUG;
        uniswapRouter.swapExactTokensForTokens(amt, 1, path, address(this), block.timestamp + 30);
    }

    ///@dev Burns rug earned from jackpot and sends the caller a little as a thanks for paying gas
    function rugBurn() external{
        uint256 amt = IERC20(RUG).balanceOf(address(this));
        uint256 gasReimbursement = amt/42;
        IERC20(RUG).transfer(msg.sender,gasReimbursement);            //Could change this. Sends 1/42nd of the rug to caller to reimburse for gas fees
        IRUG(RUG).burn(amt-gasReimbursement);
        emit RugBurn(amt-gasReimbursement);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
* @title mining library for bytes32
* @author Carson Case
 */
library Mining {

    /**
    * @notice checkNonce is a function to return true if inputs solve a hash puzzle 
    * where the number of leading zeros required is equal to the leading zeros of input 1 + leading zeros
    * of input 2 + 1 
    * @param _x is the first input hash
    * @param _y is the second input hash
    * @return true or false
     */    
    function checkNonce(bytes32 _x, bytes32 _y, uint256 _nonce) internal pure returns(bool){
        bytes32 check = hash(_x,_y,_nonce);
        uint8 difficulty = countScore(_x) + countScore(_y) + 1;
        return puzzle(check, difficulty);
    }
    
    /**
    * @notice puzzle returns true if a hash has _difficulty number of leading 0s
    * @param _entry is the hash
    * @param _difficulty is the required number of leading 0s
     */
    function puzzle(bytes32 _entry, uint8 _difficulty) internal pure returns(bool){
        bytes32 check = _entry >> (32*8) - _difficulty*4;
        return(check == 0);
    }
    
    /**
    * @notice countScore returns the number of leading 0s a hash has
    * @param _toCount is the hash to count zeros
    * @return the number of leading 0s
     */
    function countScore(bytes32 _toCount) internal pure returns(uint8){
        if (_toCount == 0) {return 0;}
        uint8 difficulty = 64;
        
        while(_toCount != 0){
            difficulty--;
            _toCount >>= 4;
        }
        return difficulty;
    }

    /**
    * @notice hash two inputs and a nonce with kecckak256
    * @dev all inputs are sorted and then hashed. This way the order of elements does not matter. (fire X water & water x fire = same)
    * @param _x input 1
    * @param _y input 2
    * @param _nonce is the nonce
    * @return result
     */
    function hash(bytes32 _x, bytes32 _y, uint256 _nonce) internal pure returns(bytes32){
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = bytes32(_nonce);
        hashes[1] = _x;
        hashes[2] = _y;
        return keccak256(abi.encodePacked(_sort(hashes)));
    }
    
    /**
    * @notice helper bubble sort
    * @dev Note the use of bubble sort. I was considering using a more fancy algo like quicksort/mergesort since this IS a resume
    * project after all. But bubble is just a good call here. There's only 3 inputs so asymtotic complexity is not a big concern. And 
    * unlike fancier sorts bubble is good in special situations that will be more common in small datasets like this. Such as if the array is already
    * sorted, or the array is partially sorted. So bubble is what I went with. Costs about 3000 - 9000 gas in a few runs I did. Would like to test
    * other algos.
    * @param _hashes. Array to sort
    * @return sorted array
     */
    function _sort(bytes32[] memory _hashes) private pure returns(bytes32[] memory){
        uint8 size = uint8(_hashes.length);
        bool sorted = false;
        while(!sorted){
            for(uint i=0; i<size-1; i++){
                sorted = true;
                if(_hashes[i] > _hashes[i+1]){
                    sorted = false;
                    //Swap with no register. This is so neat. I love this.
                    _hashes[i] ^= _hashes[i+1];
                    _hashes[i+1] ^= _hashes[i];
                    _hashes[i] ^= _hashes[i+1];
                }
            } 
        }
        return _hashes;
    }
    

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

