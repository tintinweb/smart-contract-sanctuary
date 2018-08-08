pragma solidity ^0.4.23;

contract MyToken {
    string public name = "MyToken";
    
    string public symbol = "MTK";

    uint8 public decimals = 18;
    
    uint public totalSupply = 1000000000000000000000000;
    
    mapping(address => uint) public balanceOf;
    
    bool active = false;
    
    address owner;
    
    address authorizedSpender;
    
    constructor () public {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    
    function activate() public {
        require(msg.sender == owner);
        active = true;
    }
    
    function setAuthorizedSpender(address _authorizedSpender) public {
        require(msg.sender == owner);
        authorizedSpender = _authorizedSpender;
    }

    event Transfer(address indexed _from, address indexed _to, uint value);
    
    function transfer(address _to, uint _value) public {
        require(active);
        if(balanceOf[msg.sender] >= _value) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
        }
    }
    
    mapping(address => mapping(address => uint)) public allowance;
 
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
    function approve(address _spender, uint _value) public {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public {
        require(active || _from == authorizedSpender);
        if(allowance[_from][msg.sender] >= _value && balanceOf[_from] >= _value) {
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
            allowance[_from][msg.sender] -= _value;
        }
    }
}

contract TokenSale {
    uint etherInToken; // 1 Ether = xxx token
    address tokenPool;
    MyToken tokenInstance;
    address owner;
    
    constructor (address tokenAddress, address _tokenPool, uint _rate) public {
        tokenInstance = MyToken(tokenAddress);
        tokenPool = _tokenPool;
        etherInToken = _rate;
        owner = msg.sender;
    }
    
    event RateUpdated(uint newRate);
    
    function updateRate (uint newRate) public {
        require(msg.sender == owner);
        etherInToken = newRate;
        emit RateUpdated(newRate);
    }

    function () public payable {
        address buyer = msg.sender;
        uint value = msg.value;
        tokenInstance.transferFrom(tokenPool, buyer, value * etherInToken);
    }
}