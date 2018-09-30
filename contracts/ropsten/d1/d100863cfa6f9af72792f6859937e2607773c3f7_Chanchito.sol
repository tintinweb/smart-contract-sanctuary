pragma solidity ^0.4.24;

contract Chanchito {
    // remix.ethereum.org
    
    mapping(address => uint256) public breakTime;
    mapping(address => uint256) public balances;
    
    function crear(uint256 _delta) public {
        require(breakTime[msg.sender] == 0, "El chanchito ya existe!");
        breakTime[msg.sender] = block.timestamp + _delta;
    }
    
    function borrar() public {
        require(balances[msg.sender] == 0, "Tienes fondos!");
        delete breakTime[msg.sender]; // breakTime[msg.sender] = 0;
    }
    
    function depositar() public payable {
        require(breakTime[msg.sender] != 0, "El chanchito no existe");
        balances[msg.sender] += msg.value;
    }
    
    function romper() public returns (bool) {
        require(block.timestamp > breakTime[msg.sender], "Aun no es tiempo");
        require(balances[msg.sender] > 0, "No tienes fondos!");
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        delete breakTime[msg.sender];
        msg.sender.transfer(balance);
        return true;
    }
    
    
}