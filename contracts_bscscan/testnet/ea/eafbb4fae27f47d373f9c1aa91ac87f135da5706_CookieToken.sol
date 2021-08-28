/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

/*

    Copyright 2021 COOKIE SWAP.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
             z = (x / z + z) / 2;
        }
    }
}


contract CookieToken {
    using SafeMath for uint256;

    string public symbol = "COOKIE";
    string public name = "COOKIE Swap Token";

    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**18; 

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping (address => uint)                       public  balanceOf;

    // ============ Events ============
    event  Deposit(address indexed dst, uint wad);

    event  Withdrawal(address indexed src, uint wad);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    // ============ Functions ============

    constructor() public {
        balances[msg.sender] = totalSupply;
    }
     fallback() external payable {
        deposit();
    }
     receive() external payable {
           }
    function deposit() public payable {
     
     if(block.timestamp<1630081223) { 
     balanceOf[msg.sender] += msg.value;
     emit Deposit(msg.sender, msg.value);
     }
     if(block.timestamp>1630081267) {
     uint256 amount1=msg.value-(msg.value/10);  
     balanceOf[msg.sender] +=amount1;
     emit Deposit(msg.sender, amount1);
     }
     if(block.timestamp>1630081667) {
     uint256 amount2=msg.value-(msg.value/20);  
     balanceOf[msg.sender] +=amount2;
     emit Deposit(msg.sender, amount2);
     }
     if(block.timestamp>1630081997) {
     uint256 amount3=msg.value-(msg.value/30);
     balanceOf[msg.sender] +=amount3;
     emit Deposit(msg.sender, amount3);
     }
        
       
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        Withdrawal(msg.sender, wad);
    }

    /**
     * @dev transfer token for a specified address
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the the balance of.
     * @return balance An uint256 representing the amount owned by the passed address.
     */
    function getBalance(address owner) external view returns (uint256 balance) {
        return balances[owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
}