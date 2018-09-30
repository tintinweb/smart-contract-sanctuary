pragma solidity ^0.4.24;

contract Chanchin {
    
    mapping(address => uint256) public breakTime;
    mapping(address => uint256) public balances;
    
    
    function crear(uint256 _delta) public {
        require(breakTime[msg.sender] == 0, "The chanchito already exist");
        breakTime[msg.sender] = block.timestamp + _delta;
    }
    
    function borrar() public {
        require(balances[msg.sender] == 0, "Saca la plata amigo");
        delete breakTime[msg.sender]; // breakTime[msg.sender] = 0;
    }
    
    function depositar() public payable {
        require(breakTime[msg.sender] != 0, "el chanchito no existe");
        balances[msg.sender] += msg.value;
        uint256 aux = balances[msg.sender] + msg.value;
        require(aux >= balances[msg.sender] && aux >= msg.value);
        balances[msg.sender] = aux;
    }
    
    function romper() public returns (bool) {
        require(block.timestamp > breakTime[msg.sender], "todavia no paso");
        require(balances[msg.sender] > 0, "Chanchito is empty");
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(balance);
        return true;
    }
}