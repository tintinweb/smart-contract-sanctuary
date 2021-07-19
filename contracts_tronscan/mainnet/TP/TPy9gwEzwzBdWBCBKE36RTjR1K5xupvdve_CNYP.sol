//SourceUnit: CNYP.sol

pragma solidity ^0.4.25;
//TRC20
contract Ownable {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}
contract TRC20 {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract TRC20Token is TRC20,Ownable {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
        );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
        );

    //Fix for short address attack against ERC20
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2*32) public returns (bool){
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        //require(_spender.call(bytes4(keccak256("receiveApproval(address,uint256,address,bytes)")), abi.encode(msg.sender, _value, this, _extraData)));
        require(_spender.call(abi.encodeWithSelector(bytes4(keccak256("receiveApproval(address,uint256,address,bytes)")),msg.sender, _value, this, _extraData)));

        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
}

contract CNYP is TRC20Token {
    uint256 public totalSupply;
    string public name;
    uint256 public decimals;
    string public symbol;


    constructor() public{
        decimals = 18;
        symbol = "CNYP";
        name = "CNYP";
        owner = msg.sender;
        
        totalSupply = 5000000000 * (10**decimals);
        balances[owner] = totalSupply;
        
        emit Transfer(address(0), owner, totalSupply);
    }

    function mint(uint256 amount) onlyOwner public {
        require(amount >= 0);
        balances[msg.sender] += amount;
        totalSupply += amount;
    }

    function burn(uint256 _value) onlyOwner public returns (bool) {
        require(balances[msg.sender] >= _value  && totalSupply >=_value && _value > 0);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Transfer(msg.sender, 0x0, _value);
        return true;
    }
}