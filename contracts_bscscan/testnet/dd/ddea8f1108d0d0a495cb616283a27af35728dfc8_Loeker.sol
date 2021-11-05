/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// this is the basics of creating an ERC20 token
//change the name loeker to what ever you would like

contract Loeker is ERC20 {
    string public constant symbol = "LKRX";
    string public constant name = "LoekerX1";
    uint8 public constant decimals = 18;
 
    //1,000,000+18 zeros
    uint private constant __totalSupply = 1000000000000000000000000;

    //this mapping iw where we store the balances of an address
    mapping (address => uint) private __balanceOf;

    //This is a mapping of a mapping.  This is for the approval function to determine how much an address can spend
    mapping (address => mapping (address => uint)) private __allowances;

    //the creator of the contract has the total supply and no one can create tokens
    constructor() {
        __balanceOf[msg.sender] = __totalSupply;
    }

    //constant value that does not change/  returns the amount of initial tokens to display
    function totalSupply() public pure override returns (uint _totalSupply) {
       return _totalSupply = __totalSupply;
    }

    //returns the balance of a specific address
    function balanceOf(address _addr) public view override returns (uint balance) {
        return __balanceOf[_addr];
    }
    

    //transfer an amount of tokens to another address.  The transfer needs to be >0 
    //does the msg.sender have enough tokens to forfill the transfer
    //decrease the balance of the sender and increase the balance of the to address
    function transfer(address _to, uint _value) public override returns (bool success) {
        if (_value > 0 && _value <= balanceOf(msg.sender)) {
            __balanceOf[msg.sender] -= _value;
            __balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    
    //this allows someone else (a 3rd party) to transfer from my wallet to someone elses wallet
    //If the 3rd party has an allowance of >0 
    //and the value to transfer is >0 
    //and the allowance is >= the value of the transfer
    //and it is not a contract
    //perform the transfer by increasing the to account and decreasing the from accounts
    function transferFrom(address _from, address _to, uint _value) public override returns (bool success) {
        if (__allowances[_from][msg.sender] > 0 &&
            _value >0 &&
            __allowances[_from][msg.sender] >= _value
            //  the to address is not a contract
            && !isContract(_to)) {
            __balanceOf[_from] -= _value;
            __balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }


    //This check is to determine if we are sending to a contract?
    //Is there code at this address?  If the code size is greater then 0 then it is a contract.
    function isContract(address _addr) public view returns (bool) {
        uint codeSize;
        //in line assembly code
        assembly {
            codeSize := extcodesize(_addr)
        }
        // i=s code size > 0  then true
        return codeSize > 0;    
    }

 
    //allows a spender address to spend a specific amount of value
    function approve(address _spender, uint _value) external override returns (bool success) {
        __allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    //shows how much a spender has the approval to spend to a specific address
    function allowance(address _owner, address _spender) external override view returns (uint remaining) {
        return __allowances[_owner][_spender];
    }
}