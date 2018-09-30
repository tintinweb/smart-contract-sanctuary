pragma solidity ^0.4.24;



contract Chanchito {
    // remix.ethereum.org
    
    mapping(address => uint256) public breakTime;
    mapping(address => uint256) public balances;
    
    function crear(uint256 _delta) public {
        require(breakTime[msg.sender] == 0, "The chanchito already exist");
        breakTime[msg.sender] = block.timestamp + _delta;
    }
    
    function borrar() public {
        require(balances[msg.sender] == 0, "El chanchito tiene plata");
        delete breakTime[msg.sender];
    }
    
    function depositar() public payable {
        require(breakTime[msg.sender] != 0, "El chanchito no existe");
        uint256 aux = balances[msg.sender] + msg.value;
        require(aux >= msg.value && aux >= balances[msg.sender], "Overflow!");
        balances[msg.sender] = aux;
    }
    
    /*
        @dev No rompas un chanchito vacio!
    */
    function romper() public returns (bool){
        require(block.timestamp > breakTime[msg.sender], "Todavia no paso");
        require(balances[msg.sender] > 0, "Chachito is empty");
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(balance);
        return true;
    }
    
}