//SourceUnit: KrazyKewlSlotzToken.sol

pragma solidity ^0.4.24;

contract KrazyKewlSlotsToken{
    
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 public totalSupply;
    
    mapping(address => uint256)public balanceOf;
    mapping(address => mapping(address =>uint256))public allowance;
    
     event Transfer(address indexed from,address indexed to, uint256 value);
    event Approval(address indexed _owner,address indexed _spender,uint256 value);
    event Burn(address indexed from,uint256 value);
    event DiceResult(uint256 value);
    
    uint256 public participant1_count;
    uint256 participant1_amount;
    uint256 participant1_diceresult;
    address participant1_address;
    
    uint256 initialSupply = 20000000;
    string tokenName = 'KrazyKewlSlotsToken';
    string tokenSymbol= 'KKST';
    address owner;
    
    
    
    
    constructor()public{
        totalSupply=initialSupply*10**uint256(decimals);
        balanceOf[msg.sender]=totalSupply;
        name=tokenName;
        symbol=tokenSymbol;
        
        owner = msg.sender;
    }
    
    function _transfer(address _from,address _to,uint _value)internal{
        
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
         uint previousBalances=balanceOf[_from] + balanceOf[_to];
         
         balanceOf[_from] -= _value;
         balanceOf[_to] += _value;
         emit Transfer(_from,_to,_value);
         
         assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
         
        
    }
    
    function transfer(address _to,uint256 _value)public returns(bool success){
        _transfer(msg.sender, _to,_value);
        return true;
    }
    
     function transferFrom(address _from,address _to,uint256 _value)public returns(bool success){
        require(_value <= allowance[_from][msg.sender]);
        
        _transfer(_from,_to,_value);
        return true;
    }
    function approve(address _spender,uint256 _value)public returns(bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
     function burn(uint256 _value)public returns(bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender,_value);
        return true;
    }
    
    function placeBet(uint256 _value,uint256 _diceresult)public returns(bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[owner] += _value;
        
        participant1_count =+1;
        
        if(participant1_count == 1){
            participant1_diceresult = _diceresult;
            participant1_amount = _value;
            participant1_address = msg.sender;
            emit DiceResult(999);
        }
        if(participant1_count == 2){
            if(participant1_diceresult == _diceresult){
                balanceOf[participant1_address] += participant1_amount;
                balanceOf[msg.sender] += _value;
                balanceOf[owner] -= participant1_amount;
                balanceOf[owner] -= _value;
                emit DiceResult(0);//Draw
                
            }
            
            if(participant1_diceresult > _diceresult){
                balanceOf[participant1_address] += participant1_amount;
                balanceOf[participant1_address] += _value;
                balanceOf[owner] -= participant1_amount;
                balanceOf[owner] -= _value;
                emit DiceResult(1);//player1 wins
                
            }
            
            if(participant1_diceresult < _diceresult){
                balanceOf[msg.sender] += participant1_amount;
                balanceOf[msg.sender] += _value;
                balanceOf[owner] -= participant1_amount;
                balanceOf[owner] -= _value;
                emit DiceResult(2);//player2 wins
                
            }
            participant1_amount = 0;
            participant1_count = 0;
            participant1_diceresult = 0;
            participant1_address = 0x0;
        }
        return true;
        
    }
    
}