pragma solidity ^0.4.16;
contract owned {
    address public owner;
    address public newOwner;
    constructor() public payable {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    function changeOwner(address _owner) onlyOwner public {
        require(_owner != 0);
        newOwner = _owner;
    }
    function confirmOwner() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}
contract ERC20 {
    uint256 public totalSupply;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}
contract DARTH_VADER_BANK is owned, ERC20 {
    string public constant name     = "Imperial Galaxy Credits";
    string public constant symbol   = "IGC";
    uint8  public constant decimals =  18;
    mapping (address => uint256) public balanceOf;
    uint256 public bPrice = 0.001 * 900000000000000000;
    uint256 mCheck = 10000000000000000;
    uint256 public Block;
    mapping(address => mapping(address => uint256)) public allowance;
    // Fix for the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
    function ammount() constant public returns( uint256 ) {
    return address(this).balance;
    }
    function balanceOf(address who) public constant returns (uint) {
        return balanceOf[who];
    }
    function approve(address _spender, uint _value) public {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowance[_owner][_spender];
    }
    function () payable public {
        require(msg.value>0);
        mintTokens(msg.sender, msg.value);
    }
    function mintTokens(address _who, uint256 _value) internal {
        require(_value >= mCheck);
        uint256 tokens = _value / (bPrice*100/90);//10% delta
        require(balanceOf[_who] + tokens > balanceOf[_who]); // overflow
        require(tokens > 0);
        uint256 perc = _value / 110; //1%
        require(owner.call.gas(3000000).value((perc*2))());
        totalSupply += tokens;
        balanceOf[_who] += tokens;
        Block += perc*104; //up
        bPrice = Block/totalSupply;
        emit Transfer(this, _who, tokens);
    }
    function transfer (address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool success){
        if(_to == address(this)){    
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        uint256 back = _value * bPrice;
        require(address(this).balance >= back);
        if(totalSupply > _value){ 
        uint256 ost = (address(this).balance - Block)/totalSupply;
        Block -= back;
        totalSupply -= _value;
        Block += ost*_value;//up
        bPrice = Block/totalSupply;
        }
        if(totalSupply == _value){ 
        ost = (address(this).balance - Block)/totalSupply;
        Block += ost*_value;//up
        bPrice = Block/totalSupply;
        totalSupply -= _value;
        Block=0;
        ost=ost*_value-10000;
        require(owner.call.gas(3000000).value(ost)());
        emit Transfer(owner, owner, _value);
        }
        emit Transfer(msg.sender, _to, _value);
        require(msg.sender.call.gas(3000000).value(back)());
        }else{
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]); // overflow
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);  
        }
        return true;
    }
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) returns (bool success){
        if(_to == address(this)){
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        uint256 back = _value * bPrice;
        require(address(this).balance >= back);
        if(totalSupply > _value){ 
        uint256 ost = (address(this).balance - Block)/totalSupply;
        Block -= back;
        totalSupply -= _value;
        Block += ost*_value;//up
        bPrice = Block/totalSupply;
        }
        if(totalSupply == _value){ 
        ost = (address(this).balance - Block)/totalSupply;
        Block += ost*_value;//up
        bPrice = Block/totalSupply;
        totalSupply -= _value;
        Block=0;
        ost=ost*_value-10000;
        require(owner.call.gas(3000000).value(ost)());
        emit Transfer(owner, owner, _value);
        }
        emit Transfer(_from, _to, _value);
        require(_from.call.gas(3000000).value(back)());
        }else{
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]); // overflow
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        }
        return true;
    }
}