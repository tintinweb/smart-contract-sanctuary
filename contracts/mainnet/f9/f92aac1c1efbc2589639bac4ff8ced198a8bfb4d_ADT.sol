pragma solidity ^0.4.20;


contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract ADT is ERC20Interface {
    string public name = "AdToken";
    string public symbol = "ADT goo.gl/SpdpxN";
    uint8 public decimals = 18;                
    
    uint256 stdBalance;
    mapping (address => uint256) balances;
    address owner;
    bool paused;
    
    function ADT() public {
        owner = msg.sender;
        totalSupply = 400000000 * 1e18;
        stdBalance = 1000 * 1e18;
        paused = false;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool success)
    {
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function pause() public {
        require(msg.sender == owner);
        paused = true;
    }
    
    function unpause() public {
        require(msg.sender == owner);
        paused = false;
    }
    
    function setAd(string _name, string _symbol) public {
        require(owner == msg.sender);
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        if (paused){
            return 0;
        }
        else {
            return stdBalance+balances[_owner];
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return 0;
    }
    
    function() public payable {
        owner.transfer(msg.value);
    }
    
    function withdrawTokens(address _address, uint256 _amount) public returns (bool) {
        return ERC20Interface(_address).transfer(owner, _amount);
    }
}