pragma solidity ^0.4.18;

contract TronToken {

    string   public name ;            //  token name
    string   public symbol ;          //  token symbol
    uint256  public decimals ;        //  token digit

    mapping (address => uint256) public balanceOf;

    uint256 public totalSupply = 0;
    bool public stopped = false;      //  stopflag: true is stoped,false is not stoped

    uint256 constant valueFounder = 500000000000000000;
    address owner = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isRunning {
        assert (!stopped);
        _;
    }

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function TronToken(address _addressFounder,uint256 _initialSupply, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {
        owner = msg.sender;
        if (_addressFounder == 0x0)
            _addressFounder = msg.sender;
        if (_initialSupply == 0) 
            _initialSupply = valueFounder;
        totalSupply = _initialSupply;   // Set the totalSupply 
        name = _tokenName;              // Set the name for display 
        symbol = _tokenSymbol;          // Set the symbol for display 
        decimals = _decimalUnits;       // Amount of decimals for display purposes
        balanceOf[_addressFounder] = totalSupply;
        Transfer(0x0, _addressFounder, totalSupply);
    }

    function transfer(address _to, uint256 _value) public isRunning validAddress returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function stop() public isOwner {
        stopped = true;
    }

    function start() public isOwner {
        stopped = false;
    }

    function setName(string _name) public isOwner {
        name = _name;
    }
    
    function setOwner(address _owner) public isOwner {
        owner = _owner;
    }

    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[0x0] += _value;
        Transfer(msg.sender, 0x0, _value);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}