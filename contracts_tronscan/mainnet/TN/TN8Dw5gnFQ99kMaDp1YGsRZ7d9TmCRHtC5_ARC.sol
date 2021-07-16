//SourceUnit: ARC.sol

pragma solidity ^0.4.20;

contract ARC {

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    uint256 initialSupply = 64000000;
    string tokenName = 'Arcade Credits';
    string tokenSymbol = 'ARC';
    
    address public owner;
    
    bool public paused;

    constructor() public {

        totalSupply = initialSupply*10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;

        owner = msg.sender;
        paused = false;

    }

    function _transfer(address _from, address _to, uint _value) internal {

        require(_to!=0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

    }
    
    function setOwner(address _newOwner) public returns (bool success) {
        
        require(msg.sender == owner);
        owner = _newOwner;
        
        return true;
        
    }

    function transfer(address _to, uint256 _value) public returns (bool success){

        require(paused == false);

        _transfer(msg.sender, _to, _value);
        return true;

    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        
        require(paused == false);

        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);

        return true;

    }

    function approve (address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function burn(uint256 _value) public returns (bool success){
        
        require(paused == false);

        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);
        return true;

    }

    function burnFrom(address _from, uint256 _value) public returns (bool success){
        
        require(paused == false);

        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(_from, _value);
        return true;

    }
    
    function pause() public returns (bool success) {
        
        require(msg.sender == owner);
        
        if (paused == false) {
            paused = true;
        } else {
            paused = false;
        }
        
        return true;
        
    }

}

// by Shay#5787 (shay.services)