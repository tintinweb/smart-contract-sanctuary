/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

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

contract SimpleCrowdsale {
    using SafeMath for uint256;
      // The token being sold
  address public token;
  
  address[] public incoming_addresses;
  
    
    uint256 public count = 1;
     mapping (uint256 => address) public investor_list;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;
    uint256 total_tokens_value;
  
  bool public locked = false;
  
    address public owner_address;
    

    // function get_total_count() public returns (uint256){
    //     return count;
    // }
    // function get_address_from_list(uint256 tcount) public returns (address){
    //     return investor_list[tcount];
    // }
    // function get_balance(address address_of_investor) public returns (uint256){
    //     return IERC20(token).balanceOf(address_of_investor);
    // }
    function get_incoming_addresses(uint256 index) public returns (address){
        return incoming_addresses[index];
    }
    


  
    constructor(uint256 t_rate,address t_token) public payable {
        token = t_token;
        owner_address = msg.sender;
        rate = t_rate;
        
        
    }
        function total_tokens() public view returns (uint256)
    {
        return IERC20(token).balanceOf(address(this));
    }
            function upadte_total_tokens() internal
    {
        total_tokens_value = IERC20(token).balanceOf(address(this));
    }
    function unlock() public {
        require(msg.sender == owner_address,"Only owner");
        locked = false;
    }
    function get_back_all_tokens() public {
        require(msg.sender == owner_address,"Only owner");
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        upadte_total_tokens();
    }
    function get_back_tokens(uint256 amount) public {
        require(msg.sender == owner_address,"Only owner");
        //require(total_tokens_value >= amount);
        IERC20(token).transfer(msg.sender, amount);
        
        upadte_total_tokens();
    }
        function lock() public {
            require(msg.sender == owner_address,"Only owner");
        locked = true;
    }

    
    // function getBalanceOfToken(address _address) public view returns (uint256) {
    //     return IERC20(_address).balanceOf(address(this));
    // }
    
    receive() external payable {
      buyTokens(msg.sender);
     //IERC20(token).transfer(msg.sender, 100000000000000000);
    }
    fallback() external payable {
       // buyTokens(msg.sender);
    }
    
    function buyTokens(address payable _beneficiary) public payable{

         require(!locked, "Locked");
         uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary,msg.value);
    
        // calculate token amount to be created
         uint256 t_rate = _getTokenAmount(weiAmount);
         require(IERC20(token).balanceOf(address(this)) >= t_rate, "Contract Doesnot have enough tokens");
    
        //  // update state
         
        
        IERC20(token).transfer(_beneficiary, t_rate);
        incoming_addresses.push(_beneficiary);
        weiRaised = weiRaised.add(weiAmount);
        investor_list[count] = _beneficiary;
        count++;
       // _deliverTokens(_beneficiary, t_rate);
       upadte_total_tokens();

  }
  
    function _preValidatePurchase (
        address _beneficiary,
        uint256 _weiAmount
    ) pure
    internal
    {
        require(_beneficiary != address(0), "Beneficiary = address(0)");
        require(_weiAmount >= 100000000000000000 || _weiAmount <= 10000000000000000000 ,"send Minimum 0.1 eth or 10 Eth max");
    }
    
      function extractEther() public {
           require(msg.sender == owner_address,"Only owner");
          msg.sender.transfer(address(this).balance);
       }
        function changeOwner(address new_owner) public {
           require(msg.sender == owner_address,"Only owner");
          owner_address = new_owner;
       }
  
    function _getTokenAmount(uint256 _weiAmount)
    public view returns (uint256)
    {
        uint256 temp1 = _weiAmount.div(1000000000);
        return temp1.mul(rate) * 10**9;
       // return _weiAmount.mul(325) * 10**9;
    }
    
        function _calculate_TokenAmount(uint256 _weiAmount, uint256 t_rate, uint divide_amount)
    public pure returns (uint256)
    {
        uint256 temp2 = _weiAmount.div(divide_amount);
        return temp2.mul(t_rate);
    }
    

         function update_rate(uint256 _rate)
    public
    {
        require(msg.sender == owner_address,"Only owner");
        rate = _rate;
    }

  
    function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    IERC20(token).transfer(_beneficiary, _tokenAmount);
  }
    
}