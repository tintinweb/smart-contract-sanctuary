/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^0.5.16;

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
    2nd method
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
    2nd method
     */

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
    2nd method
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
 

        return c;
    }

    /**
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
   2nd method
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Gold {
    using SafeMath for uint256;
    
    string public constant name = "Gold";

    string public constant symbol = "GOLD";

    uint8 public constant decimals = 18;

    uint public totalSupply = 100000000000000000000000000; // QUICK

    ///Allowance amounts
    mapping (address => mapping (address => uint256)) internal allowances;

    /// token balances for each account
    mapping (address => uint256) internal balances;

    
    event Transfer(address indexed from, address indexed to, uint256 amount);


    event Approval(address indexed owner, address indexed spender, uint256 amount);


    constructor() public {

        _mint(msg.sender, totalSupply);
    }

    
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }


    function approve(address spender, uint amount) external returns (bool) {
        
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

   
    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        uint256 newAllowance = spenderAllowance.sub( amount);
        allowances[src][spender] = newAllowance;

        emit Approval(src, spender, newAllowance);

        _transferTokens(src, dst, amount);
        return true;
    }


    function _transferTokens(address src, address dst, uint256 amount) internal {
        require(src != address(0), "Quick::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Quick::_transferTokens: cannot transfer to the zero address");

        balances[src] = balances[src].sub(amount);
        balances[dst] = balances[dst].add(amount);
        emit Transfer(src, dst, amount);

    }


    function _mint(address dst, uint amount) internal {

        // mint the amount
        totalSupply = totalSupply.add(amount);

        // transfer the amount to the recipient
        balances[dst] = balances[dst].add(amount);
        emit Transfer(address(0), dst, amount);

    }

}