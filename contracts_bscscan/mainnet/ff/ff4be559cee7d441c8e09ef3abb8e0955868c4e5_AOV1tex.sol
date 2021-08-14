/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

// SPDX-License-Identifier: AOV


pragma solidity ^0.8.7;

library SecureMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((z = x + y) >= x == (y >= 0)), 'Addition error noticed! For safety reasons the operation has been reverted.');}
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((z = x - y) <= x == (y >= 0)), 'Subtraction error noticed! For safety reasons the operation has been reverted.');}
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((x == 0) || ((z = x * y) / x == y)), 'Multiplication error noticed! For safety reasons the operation has been reverted.');}
    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((y != 0) && ((z = x / y) * y == x)), 'Division error noticed! For safety reasons the operation has been reverted.');}
    function mod(uint256 x, uint256 y) internal pure returns (uint256 z) {require((((y > 0) && (x >= 0) && ((z = x % y) > y))), 'Modulo error noticed! For safety reasons the operation has been reverted.');}
}

library AddressSecurity {
    
}

contract AOV1tex {
    mapping(address => uint) public balance;
    mapping(address => mapping(address => uint)) public allowance;
    
    uint public Supply = 10000 * 10 ** 18;
    uint public CappedSupply =  20000 * 10 ** 18;
    uint public Decimals = 18;
    using SecureMath for uint;
    
    string public Name = "AOV";
    string public Symbol = "AOV-TKN";
    address onlyminter = msg.sender;

    event Transfer(address indexed sender, address indexed recipient, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    event Burn(uint amount);
    
    constructor() {
        balance[msg.sender] = Supply;
    }
    
    function balanceof(address owner) public view returns(uint) {
        require((owner == msg.sender), "You aren't allowed to see balances of other acounts.");
        return balance[owner];
    }
    
    function transfer(address payable recipient, uint value) public returns(bool) {
        require(balanceof(msg.sender) >= value, "Acount balance is too low");
        balance[recipient].add(value);
        balance[msg.sender].sub(value);
        emit Transfer(msg.sender, recipient, value);
        return true;
    }
    
    function transferfrom(address sender, address recipient, uint amount) public returns(bool) {
        require(balanceof(sender) >= amount, "Acount balance is too low");
        require(allowance[sender][msg.sender] >= amount, "Allowance limit is too low");
        balance[recipient].add(amount);
        balance[sender].sub(amount);
        emit Transfer(sender, recipient, amount);
        return true;   
    }
    
    function approve(address spender, uint amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;   
    }
    
    function burn(uint amount) public returns (bool) {
        require(balance[msg.sender] >= amount, "You can't burn more tokens than you own!");
        balance[msg.sender] = balance[msg.sender].sub(amount);
        Supply = Supply.sub(amount);
        emit Burn(amount);
        return true;
    }
    
    function declarenewminter(address newminter) public returns (bool) {
        require(onlyminter == msg.sender, "Only the current minter may call this function!");
        onlyminter = newminter;
        return true;
    }
    
    function renouncetokens(uint tokensrenounced) public returns (bool) {
        require(balance[msg.sender] >= tokensrenounced, "Please enter an amount of tokens less than or equal to the amount you own!");
        balance[address(0)] = balance[address(0)].add(tokensrenounced);
        balance[msg.sender] = balance[msg.sender].sub(tokensrenounced);
        emit Transfer(msg.sender, 0x0000000000000000000000000000000000000000, tokensrenounced);
        return true;
    }
    
    function mint(uint amount) public returns (bool) {
        require(onlyminter == msg.sender, "Only the minter can call this function!");
        require(Supply.add(amount) <= CappedSupply, "You aren't allowed to mint more than the capped Supply maximum!");
        Supply = Supply.add(amount);
        return true;
    }
    
    
    /*
    function returnaddress(address here) pure public returns (address) {
        return address(0);
    }
    */
}