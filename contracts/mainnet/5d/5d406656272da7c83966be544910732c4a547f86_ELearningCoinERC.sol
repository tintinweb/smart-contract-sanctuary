pragma solidity ^0.4.18;

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

contract ELearningCoinERC is owned {
    string public name;
    string public symbol;
    uint8 public decimals = 2; 
    uint256 public totalSupply;
    mapping (address => bool) public frozenAccount;
    
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);


    function ELearningCoinERC() public {
        totalSupply = 10000000 * 10 ** uint256(decimals); 
        balanceOf[msg.sender] = totalSupply;              
        name = "eLearningCoin";                                 
        symbol = "ELRC";                            
    }

    function _transfer(address _from, address _to, uint _value) internal {
  
        require(_to != 0x0);

        require(balanceOf[_from] >= _value);

        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);                     
        require(!frozenAccount[_to]);  
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
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

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
    
    function mintToken(address target, uint256 initialSupply) onlyOwner public {
        balanceOf[target] += initialSupply;
        totalSupply += initialSupply;
        Transfer(0, this, initialSupply);
        Transfer(this, target, initialSupply);
    } 
   
   
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }



}