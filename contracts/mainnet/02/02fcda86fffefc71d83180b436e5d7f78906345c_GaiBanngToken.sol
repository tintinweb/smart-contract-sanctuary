pragma solidity ^0.4.24;

contract GaiBanngToken {

    string public name = &#39;丐帮令牌&#39;;      //  token name
    string constant public symbol = "GAI";           //  token symbol
    uint256 constant public decimals = 8;            //  token digit

    uint256 public constant INITIAL_SUPPLY = 20170808 * (10 ** uint256(decimals));
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 0;
    address public owner = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }
    function transferOwnership(address newOwner) public isOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    constructor() public {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        balanceOf[owner] = totalSupply;
        emit Transfer(0x0, owner, totalSupply);
    }

    function transfer(address _to, uint256 _value)  public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit  Approval(msg.sender, _spender, _value);
        return true;
    }

    function setName(string _name) public isOwner {
        name = _name;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}