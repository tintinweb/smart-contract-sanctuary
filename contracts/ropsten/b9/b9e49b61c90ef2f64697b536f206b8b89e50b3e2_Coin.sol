pragma solidity ^0.4.25;

contract Coin {
    address public minter;
    mapping (address => uint256) public balances;
    
    event Sent(address _from, address _to, uint256 _amount);
    
    constructor() public {
        minter = msg.sender;
    }
    
    function mint(address _addr, uint256 _amount) public {
        require(msg.sender == minter);
        balances[_addr] += _amount;
    }
    
    function send(address _receiver, uint256 _amount) public {
        require(balances[msg.sender] > _amount);
        balances[msg.sender] -= _amount;
        balances[_receiver] += _amount;
        
        emit Sent(msg.sender, _receiver, _amount);
    }
}