/**
 *Submitted for verification at Etherscan.io on 2020-11-23
*/

/*
  STK3R Presale Contract
   _____ _______ _  ______  _____  
  / ____|__   __| |/ /___ \|  __ \ 
 | (___    | |  | ' /  __) | |__) |
  \___ \   | |  |  <  |__ <|  _  / 
  ____) |  | |  | . \ ___) | | \ \ 
 |_____/   |_|  |_|\_\____/|_|  \_\
 
*/

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
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

}

contract Presale {
    using SafeMath for uint256;

    event Distribute(address participant, uint256 amount);

    uint256 constant private PRESALE_PRICE = 1200; // STK3R presale price is 1200 STK3R/ETH

    IERC20 public token;
    
    address payable public owner;
    
    constructor(address _token) public {
        require(_token != address(0), "Token address required");
        owner = msg.sender;
        token = IERC20(_token);
    }

    receive() external payable {
        require(msg.value > 0, "You need to send more than 0 Ether");
        uint256 amountTobuy = msg.value.mul(PRESALE_PRICE);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(amountTobuy <= tokenBalance, "No enough token in the reserve");
        owner.transfer(msg.value);
        token.transfer(msg.sender, amountTobuy);
        emit Distribute(msg.sender, amountTobuy);
    }

    fallback() external payable {
        require(msg.value > 0, "You need to send more than 0 Ether");
        uint256 amountTobuy = msg.value.mul(PRESALE_PRICE);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(amountTobuy <= tokenBalance, "No enough token in the reserve");
        owner.transfer(msg.value);
        token.transfer(msg.sender, amountTobuy);
        emit Distribute(msg.sender, amountTobuy);
    }
    
    function retrieve() external payable {
        owner.transfer(address(this).balance);
        token.transfer(owner, token.balanceOf(address(this)));
    }

}