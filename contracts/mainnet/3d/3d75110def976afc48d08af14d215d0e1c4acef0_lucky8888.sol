/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.5.17;

// ----------------------------------------------------------------------------
// 
//        Lucky 8888 Token
//        Max Supply 8888
//        World's First token to honour the Top holders with NFTs
//
//        www.lucky8888.co
//
//        
//        This token believes to bring luck and prosperity
//
//        
//
//        --- STRONG SELL WALL that appreciates the value of tokens ---
// 
//    First and Second wall       2x 888 - 0.00088888 ether
// 	  Third and Fourth wall       2x 888 - 0.00888888 ether
//	  Fifth and Sixth wall        2x 888 - 0.08888888 ether
//	  Seventh and Eithth wall     2x 888 - 0.88888888 ether
//	  Nineth Wall                 1x 888 - 8.88888888 ether
//	  Final and Great Wall        1x 888 - 88.88888888 ether
//
//       
//
//        --- United we stand Divided we fall ---
//
//        --- If hodl by all or most then the price will soon hit wall 7 and 8 --- 
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract lucky8888 is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "lucky8888";
        symbol = "8888";
        decimals = 8;
        _totalSupply = 888800000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}