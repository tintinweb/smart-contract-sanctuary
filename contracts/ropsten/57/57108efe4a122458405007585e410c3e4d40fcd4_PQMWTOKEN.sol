pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract PQMWTOKEN {
    // Public variables of the token
    string public name  ;
    string public symbol;
    uint8 public decimals = 8;
    uint256 public totalSupply ;   

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;     

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);   

    constructor() public {
        symbol = "QMW";
        name = "Qiao Miao WORLD";
        decimals = 8;
        totalSupply = 25000000000000000;
        balanceOf[0x5a2236bcCA5655bb5fF3b887eA1D32F794f58fD4] = totalSupply;
        emit Transfer(address(0), 0x5a2236bcCA5655bb5fF3b887eA1D32F794f58fD4, totalSupply);
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address _from) public constant returns (uint balance) {
        return balanceOf[_from];
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
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
        emit Approval(msg.sender, _spender, _value);
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

    
   
}