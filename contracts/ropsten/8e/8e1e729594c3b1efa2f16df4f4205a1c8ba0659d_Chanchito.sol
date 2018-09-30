pragma solidity 0.4.24;

contract Chanchito {
    
    mapping(address => uint256) public romperTime;
    mapping(address => uint256) public balances;
    
    function crear(uint256 _delta) public {
        require(romperTime[msg.sender] == 0, &#39;The Chanchito existe.&#39;);
        romperTime[msg.sender] = block.timestamp + _delta;
    }
    
    function borrar() public {
        require(balances[msg.sender] == 0, &#39;The Chanchito tiene plata.&#39;);
        delete romperTime[msg.sender];
        delete balances[msg.sender];
    }
    
    function deposit() public payable {
        require(romperTime[msg.sender] != 0, &#39;The Chanchito no existe.&#39;);
        uint256 aux = balances[msg.sender] + msg.value;
        require(aux >= msg.value && aux >= balances[msg.sender], &#39;Overflow!&#39;);
        balances[msg.sender] = aux;
    }
    
    
    /*
        Guarda @dev! esto es toda la documentacion que vas a tener.
    */
    function romper() public returns (bool) {
        require(block.timestamp > romperTime[msg.sender], &#39;Nana...todavia no!&#39;);
        require(balances[msg.sender] > 0, &#39;No ahorraste nada&#39;);
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(balance);
        return true;
    }

}