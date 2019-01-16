pragma solidity ^0.4.24;

contract BasicToken {
    
    address public minter;

    mapping (address => uint) balances;
    uint public totalSupply;
    
    event Transfer(address _sender, address _receiver, uint _value);
    event TokensMinted(address _receiver, uint _value);
    event TokensBurn(address _burner, uint _value);

    constructor(uint _totalSupply) 
        public
    {
        totalSupply = _totalSupply;
        // msg.sender : la personne/le contrat qui fait la transaction
        // msg.value : la valeur inclue dans la transaction
        balances[msg.sender] = totalSupply;
        minter = msg.sender;
    }

    function transfer(address _dest, uint _value)
        public
    {
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] -= _value;
        balances[_dest] += _value;
        
        // event
        emit Transfer(msg.sender, _dest, _value);
    }
    
    // g&#233;n&#233;rer des nouveaux tokens
    function mint(address _dest, uint _value)
        public
    {
        require(msg.sender == minter);
        
        totalSupply += _value;
        balances[_dest] += _value;
        
        emit TokensMinted(_dest, _value);
    }
    
    // br&#251;ler des tokens
    function burn(uint _value)
        public
    {
        require(balances[msg.sender] >= _value);
        
        totalSupply -= _value;
        balances[msg.sender] -= _value;
        
        emit TokensBurn(msg.sender, _value);
    }

    function getBalance(address _a)
        public
        view
        returns (uint)
    {
        return balances[_a];
    }

}