/**
 *Submitted for verification at FtmScan.com on 2021-12-19
*/

pragma solidity ^0.8.10;

contract BurnCoin{
    string name = "BurnCoin";
    string symbol = "BRNC";
    uint supply = 69000 * 10 ** 18;
    uint decimals = 18;

    mapping (address => uint) balances;
    mapping (address => mapping(address => uint)) spend_limit;

    event Transfer(address indexed owner, address indexed reciever, uint amount);
    event ApproveLimit(address indexed approved_by, address indexed owner, uint amount);
    event Burn(uint amount);

    address contract_owner = msg.sender;

    constructor() {
        balances[msg.sender] = supply;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address reciever, uint amount) public returns(bool) {
        require(balanceOf(msg.sender) >= amount, "Sender Balance Too Low");
        if (supply > 1000){
            uint to_transfer = sub(amount, 1);
            balances[msg.sender] = sub(balances[msg.sender], amount);
            balances[reciever] = add(balances[reciever], to_transfer);
            burn(1);
        }
        else{
            balances[msg.sender] = sub(balances[msg.sender], amount);
            balances[reciever] = add(balances[reciever], amount);
        }
        
        emit Transfer(msg.sender, reciever, amount);
        return true;
    }

    function transferFrom(address owner, address reciever, uint amount) public returns(bool) {
        require(balanceOf(owner) >= amount, "Sender Balance Too Low");
        require(spend_limit[msg.sender][owner] >= amount, "Sender Spend Limit Too Low");
        if (supply > 1000) {
            uint to_transfer = sub(amount, 1);
            balances[owner] = sub(balances[owner], amount);
            balances[reciever] = add(balances[reciever], to_transfer);
            spend_limit[msg.sender][owner] = sub(spend_limit[msg.sender][owner], amount);
            burn(1);
        }
        else {
            balances[owner] = sub(balances[owner], amount);
            balances[reciever] = add(balances[reciever], amount);
            spend_limit[msg.sender][owner] = sub(spend_limit[msg.sender][owner], amount);
        }
        emit Transfer(owner, reciever, amount);
        return true;
    }

    function approveSpendLimit(address owner, uint amount) public returns(bool) {
        require(balanceOf(owner) >= amount, "Spend Limit Higher Than Balance");
        spend_limit[msg.sender][owner] = amount;
        emit ApproveLimit(msg.sender, owner, amount);
        return true;
    }

    function burn(uint amount) private returns(bool) {
        require(supply > 1000, "Cannot Burn, Supply Too Low");
        supply = sub(supply, amount);
        emit Burn(amount);
        return true;
    }

    function viewLimit(address owner) public view returns(uint) {
        return spend_limit[msg.sender][owner];
    }

    function viewSupply() public view returns(uint) {
        return supply;
    }

    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a, "Addition Overflow Error");
        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        require(a >= b, "Subtraction Overflow Error");
        return a - b;
    }
}