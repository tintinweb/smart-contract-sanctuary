pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract SafeMath {
    function add(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function subtract(uint256 x, uint256 y) pure internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }
}

contract ERC20 {
    function totalSupply() constant public returns (uint supply);
    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool balance);
    function approve(address _spender, uint256 _value) public returns (bool balance);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed from, uint256 value);
}

contract Bible is ERC20, SafeMath {

    string public name = "Bible";      //  token name
    string public symbol = "GIB";           //  token symbol
    uint256 public decimals = 18;            //  token digit
    uint256 public totalSupply = 0;
    string public version = "1.0.0";
    address creator = 0x0;
    /**
     *  0 : init, 1 : limited, 2 : running, 3 : finishing
     */
    uint8 public tokenStatus = 0;
      
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    function Bible() public {
        creator = msg.sender;
        tokenStatus = 2;
        totalSupply = 11000000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    modifier isCreator {
        assert(creator == msg.sender);
        _;
    }

    modifier isRunning {
        assert(tokenStatus == 2);
        _;
    }

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function status(uint8 _status) isCreator public {
        tokenStatus = _status;
    }
    
    function getStatus() constant public returns (uint8 _status) {
        return tokenStatus;
    }
    
    function totalSupply() constant public returns (uint supply) {
        return totalSupply;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balanceOf[_owner];
    }
    
    function _transfer(address _from, address _to, uint _value) isRunning validAddress internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = SafeMath.add(balanceOf[_from], balanceOf[_to]);
        balanceOf[_from] = SafeMath.subtract(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) isRunning validAddress public returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
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
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}