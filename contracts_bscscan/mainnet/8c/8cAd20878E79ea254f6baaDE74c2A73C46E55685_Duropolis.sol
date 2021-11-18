/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract aaa7BEP{
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract aaa7Math {
    function Sub(uint O, uint b) public pure returns (uint c) {
        require(b <= O);
        c = O - b;
    }
    function Div(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
    function Add(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
   
}

contract Duropolis is aaa7BEP, aaa7Math {
    string public aaa7name =  "Duropolis";
    string public aaa7symbol =  "DURO";
    uint8 public aaa7decimals = 9;
    uint public aaa7_supply = 1*10**12 * 10**9;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        balances[msg.sender] = aaa7_supply;
        emit Transfer(address(0), msg.sender, aaa7_supply);
    }
    
    function name() public virtual view returns (string memory) {
        return aaa7name;
    }

    function symbol() public virtual view returns (string memory) {
        return aaa7symbol;
    }

  function decimals() public view virtual returns (uint8) {
        return aaa7decimals;
    }

    function totalSupply() public override view returns (uint) {
        return aaa7_supply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address from, address to, uint256 tokens) private returns (bool success) {
        uint256 amountToBurn = Div(tokens, 18); // 5% of the transaction shall be burned
        uint256 amountToTransfer = Sub(tokens, amountToBurn);
        
        balances[from] = Sub(balances[from], tokens);
        balances[0x0000000000000000000000000000000000000000] = Add(balances[0x0000000000000000000000000000000000000000], amountToBurn);
        balances[to] = Add(balances[to], amountToTransfer);
        return true;
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