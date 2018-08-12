pragma solidity ^0.4.24;

/* Follows the ERC20 token standard */

contract EthereumPepe {

    string public tokenName;
    string public tokenSymbol;
    uint256 public totalSupply;
    uint8 public decimals = 18;

    mapping (address => uint256) public balances;
    mapping (address => mapping(address => uint256)) public allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);

    constructor() public {
        
        /* Final token characteristics */
        tokenName = "Ethereum Pepe";
        tokenSymbol = "ETHPEPE";
        uint256 initSupply = 120000;
        /*******************************/
        
        totalSupply = initSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {

        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        uint256 previousBalances = balances[_from] + balances[_to];

        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        assert(balances[_from] + balances[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {

        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(allowed[_from][msg.sender] >= _value);

        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {

        require(_value <= totalSupply);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function burn(uint256 _value) public returns(bool success) {
        
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns(bool success) {
        
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        totalSupply -= _value;
        
        emit Burn(_from, _value);
        return true;
    }
    
    function name() public view returns (string text) {
        
        return tokenName;
    }
    
    function symbol() public view returns (string text) {
        
        return tokenSymbol;
    }
    
    function decimals() public view returns (uint8 value) {
        
        return decimals;
    }
    
    function totalSupply() public view returns (uint256 value) {
        
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 value) {

        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256 value) {

        return allowed[_owner][_spender];
    }
    
    /* Reverts any purposely or inadvertently Ether payment to the contract */
    function () public payable {
        
        revert();
    }
}