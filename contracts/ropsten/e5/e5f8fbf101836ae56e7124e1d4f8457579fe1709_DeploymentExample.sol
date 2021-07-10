/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

pragma solidity 0.5.2;

contract DeploymentExample {
    mapping(address => uint) public balances;
    uint public totalDeposited;
    address payable private owner = 0xd87548320F105D3c5178F7F4d1Deb3D61F9929df;
    
    event Deposited(address indexed who, uint amount);
    event Withdrawn(address indexed who, uint amount);
    
    function() external payable {
        depositEther();
    }
    
    function depositEther() public payable {
        require(msg.value > 0);
        balances[msg.sender] = balances[msg.sender] + msg.value;
        totalDeposited = totalDeposited + msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdrawn(uint _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        totalDeposited = totalDeposited - _amount;
        msg.sender.transfer(_amount);
        emit Withdrawn(msg.sender, _amount);
    }
    
    function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}