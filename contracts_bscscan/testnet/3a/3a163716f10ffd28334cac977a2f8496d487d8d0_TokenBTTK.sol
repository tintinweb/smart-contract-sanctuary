/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenBTTK {
    string public name;
    
    string public symbol;
    
    uint8 public decimals = 18;  
    
    uint256 public totalSupply;
    
    address public _owner;
    
    address public technologyAddress;
    
    address public operateAddress;
    
    address public nodeAddress;
    
    address public computeAddress;

  
    mapping (address => uint256) public balanceOf;
    

    mapping (address => mapping (address => uint256)) public allowance;


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);
    

    function TokenBTTK() public {
        totalSupply = 100000000 * 10 ** 18;  
        balanceOf[msg.sender] = totalSupply;
        _owner = msg.sender;
        name = 'Lyrics';                                   
        symbol = 'LR';  
        technologyAddress = 0x5A71e9302b90a2DBc968027276aE2Cf860419448;
        operateAddress = 0x5A71e9302b90a2DBc968027276aE2Cf860419448;
        nodeAddress = 0x5A71e9302b90a2DBc968027276aE2Cf860419448;
        computeAddress = 0x5A71e9302b90a2DBc968027276aE2Cf860419448;
    }


    function _transfer(address _from, address _to, uint _value) internal {
        
        require(_to != 0x0);
        
        require(balanceOf[_from] >= _value);

        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        
        if(_from == computeAddress || _from == nodeAddress || _from == technologyAddress || _from == operateAddress
          || _to == computeAddress || _to == nodeAddress || _to == technologyAddress || _to == operateAddress){
            
            // Add the same to the recipient
             balanceOf[_to] += _value;
            Transfer(_from, _to, _value);

            assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        }else{
            uint receiveAmount = _value * 7/10;
            uint nodeAmount = _value * 6/100;
            uint computeAmount = _value * 18/100;
            uint technologyAmount = _value * 3/100;
            uint operateAmount = _value * 3/100;
            
            // Add the same to the recipient
             balanceOf[_to] += receiveAmount;
            // Add the nodeAmount to the nodeAddress
             balanceOf[nodeAddress] += nodeAmount;
            // Add the computeAmount to the computeAddress
             balanceOf[computeAddress] += computeAmount;
            // Add the technologyAmount to the technologyAddress
             balanceOf[technologyAddress] += technologyAmount;
            // Add the operateAmount to the operateAddress
             balanceOf[operateAddress] += operateAmount;
             
            Transfer(_from, _to, _value);
            
            uint afterBalances = balanceOf[_from] + balanceOf[_to];
            afterBalances = afterBalances +nodeAmount + computeAmount + technologyAmount + operateAmount;
            
            assert(afterBalances == previousBalances);
            
        }

        
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }


    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
    
    function bindNode(address addressNode) public returns (bool){
        require(addressNode != 0x0);
        require(msg.sender == _owner);
        nodeAddress = addressNode;
        
        return true;
    }
    
    function bindCompute(address addressCompute) public returns (bool){
        require(addressCompute != 0x0);
        require(msg.sender == _owner);
        computeAddress = addressCompute;
        
        return true;
    }
    
    function bindOperate(address addressOperate) public returns (bool){
        require(addressOperate != 0x0);
        require(msg.sender == _owner);
        operateAddress = addressOperate;
        
        return true;
    }
    
    function bindTechnology(address addressTechnology) public returns (bool){
        require(addressTechnology != 0x0);
        require(msg.sender == _owner);
        technologyAddress = addressTechnology;
        
        return true;
    }
}