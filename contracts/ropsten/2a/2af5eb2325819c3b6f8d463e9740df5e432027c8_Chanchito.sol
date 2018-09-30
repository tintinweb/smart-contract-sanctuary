pragma solidity ^0.4.24;

contract Chanchito {
    mapping(address => uint256) public breakTime;
    mapping(address => uint256) public balances;
    
    function crear(uint256 _delta) public {
        require(breakTime[msg.sender] == 0, "The chanchito already exist");
        breakTime[msg.sender] = block.timestamp + _delta;
    }
    
    function borrar() public {
        require(balances[msg.sender] == 0, "El chanchito tiene plata");
        delete breakTime[msg.sender];  // Normal way
        // breakTime[msg.sender] = 0;  // Work
    }

    function depositar() public payable {  // payable can send ethers
        require(breakTime[msg.sender] != 0, &#39;El chanchito no existe&#39;);
        uint256 aux = balances[msg.sender] + msg.value;
        require(aux >= msg.value && aux >= balances[msg.sender], &#39;Overflow&#39;);
        balances[msg.sender] = aux;
    }

    function romper() public returns (bool) {
        require(block.timestamp > breakTime[msg.sender], &#39;Todavia no paso&#39;);
        require(balances[msg.sender] > 0, &#39;Chanchito Empty&#39;);
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(balance);
        return true;
    }
    
}