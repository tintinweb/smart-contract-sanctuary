/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

pragma solidity >=0.5.1 <0.6.0;

contract Donation {
    address owner;
    event fundMoved(address _to, uint _amount);
    modifier onlyowner { if (msg.sender == owner) _; }
    address[] _giver;
    uint[] _values;
    uint public balance;
    uint public balance1;

    constructor() public {
        owner = msg.sender;
        address owner1 = msg.sender;
    }

    function donate() payable  public {
        addGiver(msg.value);
    }
    
    function getBalance()  public {
        balance = address(this).balance;
        balance1 = msg.sender.balance;
    }

    function moveFund(address payable _to, uint _amount) onlyowner  public {
        balance = address(this).balance;
        balance1 = msg.sender.balance;
        uint amount = _amount;
        if (_amount <= balance) {
            if (_to.send(_amount)) {
                emit fundMoved(_to, _amount);    
            } else {
               revert();
            }
        } else {
            revert();
        }
    }

    function addGiver(uint _amount) internal {
        _giver.push(msg.sender);
        _values.push(_amount);
    }
}