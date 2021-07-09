/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

/**
    
    Welcome to Shiba Duck
   
   This is a community token. If you want to create a telegram I suggest to name it to @SHIBADUCK
   Important: The early you create a group that shares the token, the more gain you got.
   
   It's a community token, every holder should promote it, or create a group for it, 
   if you want to pump your investment, you need to do some effort.
   

   I will burn liquidity LPs to burn addresses to lock the pool forever.
   I will renounce the ownership to burn addresses to transfer #SHIBADUCK to the community, make sure it's 100% safe.

   I will add 1 BNB and all the left 10% total supply to the pool
   Can you make #SHIBADUCK 10000X? 

   100,000,000,000 total supply
   50,000,000,000 tokens limitation for trade, which is 0.5% of the total supply
   
   
 */
 
// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

    abstract contract BP20 {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Math {
    function Add(uint A1, uint A2) public pure returns (uint A3) {
        A3 = A1 + A2;
        require(A3 >= A1);
    }
    function Sub(uint A1, uint A2) public pure returns (uint A3) {
        require(A2 <= A1);
        A3 = A1 - A2;
    }
    function Mul(uint A1, uint A2) public pure returns (uint A3) {
        A3 = A1 * A2;
        require(A1 == 0 || A3 / A1 == A2);
    }
    function Div(uint A1, uint A2) public pure returns (uint A3) {
        require(A2 > 0);
        A3 = A1 / A2;
    }
   
}

contract ShibaDuck is BP20, Math {
    string public name =  "Shiba Duck";
    string public symbol =  "SHIDUCK";
    uint8 public decimals = 9;
    uint public _totalSupply = 1*10**11 * 10**9;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    


    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            balances[sender] = senderBalance - amount;
        }
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        allowed[from][msg.sender] = Sub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


}