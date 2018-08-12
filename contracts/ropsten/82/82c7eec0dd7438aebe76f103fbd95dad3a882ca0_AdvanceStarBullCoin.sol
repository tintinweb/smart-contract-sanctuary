pragma solidity ^0.4.16;

contract AdvanceStarBullCoin {
    
    string public name = "AdvanceStarBullCoin";
    string public symbol = "asb";
    uint public totalSupply = 20000000000;
    uint8  public decimals = 0;
    
    address owner;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => bool) public frozenAccount;
    
    event Transfer(address _from, address _to, uint _value);
    event Approval(address _tokenOwner, address _spender, uint _value);
    event TransferFrom(address _sender,address _from, address _to, uint _value);
    
    constructor() public{
        owner = msg.sender;
		balanceOf[msg.sender] = totalSupply;
    }
    
    modifier isOwner{
       require(msg.sender==owner);
        _;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        require(_from != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint preBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from]+balanceOf[_to] == preBalances);
    }
    
    function transfer(address _to, uint _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_spender]);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        emit TransferFrom(msg.sender, _from, _to, _value);
        return true;
    }

    function frozen(address _addr) public isOwner{
        frozenAccount[_addr] = true;
    }

    function unFrozen(address _addr) public isOwner{
        frozenAccount[_addr] = false;
    }

}