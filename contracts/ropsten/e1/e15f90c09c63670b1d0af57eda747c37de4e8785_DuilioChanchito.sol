pragma solidity ^0.4.24;
contract DuilioChanchito{
    
    mapping(address => uint256) public breakTime;
    mapping(address => uint256) public balances;

    function crear(uint256 _delta) public{
        require(breakTime[msg.sender] == 0, "The chanchito already exists");
        breakTime[msg.sender] = block.timestamp + _delta;
    }
    function borrar()public {
        require(balances[msg.sender] == 0, "El chanchito tiene plata");
        delete breakTime[msg.sender]; // es lo mismo que breakTime[msg.sender]=0;
    }
    function deposit() public payable{
      //can receive ether
      require(breakTime[msg.sender] != 0, "El chanchito no existe"); //guarda deberia usarse safe math
      //balance[msg.sender] += msg.value;
      //o esto que chequea sin problema
      uint256 aux = balances[msg.sender] + msg.value;
      require(aux >= msg.value && aux >=balances[msg.sender], "Overflow");
      balances[msg.sender] = aux;
    }
    //guarda se tomo la decision de que no se puede romper un chanchito vacio, pueden haber consecuencias
    function romper() public returns (bool){
        //give me my money;
        require(block.timestamp > breakTime[msg.sender],"Todavia no paso");
        require(balances[msg.sender] > 0, "EL chanchito esta vacio");
        uint256 credit = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(credit);
        return true;
    }
    
    
    
}