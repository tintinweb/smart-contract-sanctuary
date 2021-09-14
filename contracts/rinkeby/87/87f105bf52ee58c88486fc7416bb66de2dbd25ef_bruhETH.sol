/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity ^0.4.18;

contract bruhETH {
    string public name     = "bruhETH";
    string public symbol   = "bETH";
    uint8  public decimals = 18;

    event  Approval(address indexed _owner, address indexed _spender, uint _value);
    event  Transfer(address indexed _from, address indexed _to, uint _value);
    event  Deposit(address indexed _depositor, uint _value);
    event  Withdrawal(address indexed _recipient, uint _value);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() public payable {
        deposit();
    }
    
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        msg.sender.transfer(_value);
        Withdrawal(msg.sender, _value);
    }

    function totalSupply() public view returns (uint) {
        return this.balance;
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(balanceOf[_from] >= _value);

        if (_from != msg.sender && allowance[_from][msg.sender] != uint(-1)) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        Transfer(_from, _to, _value);

        return true;
    }
}