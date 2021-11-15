/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

abstract contract BEP20Aasrwaead{
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Math20Aasrwaead {
    function Sub(uint O, uint b) public pure returns (uint c) {
        require(b <= O);
        c = O - b;
    }
   
}

contract METAMAX is BEP20Aasrwaead, Math20Aasrwaead {
    string public name20Aasrwaead =  "META MAX";
    string public symbol20Aasrwaead =  "META MAX";
    uint8 public decimals20Aasrwaead = 9;
    uint public _totalSupply20Aasrwaead = 1*10**11 * 10**9;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply20Aasrwaead;
        emit Transfer(address(0), msg.sender, _totalSupply20Aasrwaead);
    }
    
    function name() public virtual view returns (string memory) {
        return name20Aasrwaead;
    }

    function symbol() public virtual view returns (string memory) {
        return symbol20Aasrwaead;
    }

  function decimals() public view virtual returns (uint8) {
        return decimals20Aasrwaead;
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply20Aasrwaead - balances[address(0)];
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