/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity >=0.4.22 <0.8.0;

contract YaiToken{

    string  public  name        = "Yogi's version of DAI";
    string  public  symbol      = "YAI";
    uint256 public  totalSupply = 1000000000000000000000000; // 1 million tokens
    uint8   public  decimals    = 18;

    //takes care of transfer is done.
    event Transfer( address indexed _from, address indexed _to, uint _value);

    //emits when Transaction is approved.
    event Approval( address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    //to check if user has enough money to make the transaction.
    modifier capableToPay(address _from, uint256 _value) {
        require(balanceOf[_from] >= _value);
        _;
    }

    function transfer(address _to, uint256 _value) public capableToPay(msg.sender, _value) returns (bool success) {
        balanceOf[msg.sender]   -= _value;
        balanceOf[_to]          += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;

    }

    function approve (address _spender, uint256 _value) public returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom (address _from, address _to, uint256 _value)  public capableToPay(_from, _value) returns(bool success) {
        require (allowance[_from][msg.sender] >= _value);
        balanceOf[_from]    -= _value;
        balanceOf[_to]      += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from , _to, _value);
        return true;
        
    }
    
    
}