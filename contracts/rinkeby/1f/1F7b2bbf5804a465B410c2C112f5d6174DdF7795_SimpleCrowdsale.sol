/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// - Token Address - where the tokens are being taken
// - Presale Rate - N tokens per BNB (example : 1,000,000 tokens per BNB)
// - A Soft cap - goal to raise in BNB for the presale (example : 10 BNB)
// - A Hard cap - when the sale stop automatically if hit (example : 50 BNB)
// - a Min contribution in BNB for people buying the pre-sale (for ex 0.100)
// - a Max contribution in BNB for people buying the pre-sale (for ex 10)
// - A start time of the pre-sale (example : 2021-08-18 12:13:28 UTC)
// - Duration of Presale (in Days, example : 7 days)
// - Manual claim of tokens (people can manually claim their tokens)
// - Lock Days before claim is open (people have to wait n days, example : 30 days)
// - Auto add liquidity to PancakeSwap with a defined rate : (example : 75%)
// - PancakeSwap Liquidity rate : 1 BNB for N tokens, (example : 1 BNB for 1,000,000 tokens)
// - A defined admin address - Used to manage Ido contracts and receive raised tokens
// Written by blockchainguy.net


// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;



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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function decimals() external view returns (uint);

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
}
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

contract SimpleCrowdsale is Ownable{
  using SafeMath for uint256;
  // The token address which is being sold
  address public token;
  
  //this means 999 per eth
  uint256 public rate = 500;
  
  uint256 public softcap = 10 ether;
  uint256 public hardcap = 50 ether;
  
  uint256 public min_buy_limit = 0.1 ether;
  uint256 public max_buy_limit = 10 ether;
  
  uint256 public sale_start_time = now + 2 minutes;
  uint256 public sale_duration = sale_start_time + 2 minutes;
  uint256 public claim_time = sale_duration + 2 minutes;

  // Amount of wei raised
  uint256 public weiRaised = 0;
  
  mapping (address => uint256) public _Deposits;
  
  bool public locked = false;

    constructor(address t_token) public payable {
        token = t_token;
        _owner = msg.sender;
    }
    
    function total_tokens() public view returns (uint256){
        return IERC20(token).balanceOf(address(this));
    }
    
    function lock() onlyOwner public {
        locked = true;
    }    
    
    function unlock() onlyOwner public {
        locked = false;
    }
    
    function get_back_all_tokens() onlyOwner public {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function get_wei_raised() public view returns (uint256){
        return weiRaised;
    }
    function get_back_tokens(uint256 amount) onlyOwner public {
        require(total_tokens() >= amount, "Not Enough Tokens");
        IERC20(token).transfer(msg.sender, amount);
    }
  
    function depositEth() public payable{
        address payable _beneficiary = msg.sender;
        uint256 weiAmount = msg.value;
        require(!locked, "Locked");
        require(weiRaised <= hardcap, "Hardcap Reached");
        require(_beneficiary != address(0), "Beneficiary = address(0)");
        require(weiAmount >= min_buy_limit || weiAmount <= max_buy_limit ,"Make Transactions within the TX limits");
        require(now >= sale_start_time, "Sale is not started");
        require(now <= sale_duration, "Sale Ended");
        
        // calculate token amount to be created
        uint256 t_rate = _getTokenAmount(weiAmount);
        require(total_tokens() >= t_rate, "Contract Doesnot have enough tokens");
        
        _Deposits[_beneficiary] = _Deposits[_beneficiary].add(t_rate);  
        //IERC20(token).transfer(_beneficiary, t_rate);
        weiRaised = weiRaised.add(weiAmount);
    }
      function claimTokens() public{
            uint256 deposited_amount = _Deposits[_msgSender()];
            require(deposited_amount > 0);
            require(now > claim_time, "Cannot claim right now");
            
            IERC20(token).transfer(_msgSender(), deposited_amount);
            _Deposits[_msgSender()] = 0;
    }
    
    receive() external payable {
        depositEth();
    }
    
    fallback() external payable {}
   
    function extractEther() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }
  
    function _getTokenAmount(uint256 _weiAmount) public view returns (uint256){
        uint256 token_decimals = IERC20(token).decimals();
        
        //if token decimals are 9
        if(token_decimals == 9){
            _weiAmount = _weiAmount.div(1000000000);
            return _weiAmount.mul(rate);
        }
        
        //if token decimals are 18
        _weiAmount = _weiAmount.div(1);
        return _weiAmount.mul(rate);
        
        //return _weiAmount.mul(rate) * 10**9;
      // return _weiAmount.mul(325) * 10**9;
    }
    
    function _calculate_TokenAmount(uint256 _weiAmount, uint256 t_rate, uint divide_amount) public pure returns (uint256){
        uint256 temp2 = _weiAmount.div(divide_amount);
        return temp2.mul(t_rate);
    }
    

    function update_rate(uint256 _rate) onlyOwner public {
        rate = _rate;
    }

    
}
// Written by blockchainguy.net