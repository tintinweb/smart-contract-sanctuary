/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

pragma solidity =0.5.16;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract QToken {
    using SafeMath for uint256;
    
     
    address public owner;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    string public constant name = "QToken";
    string public constant symbol = "QTO";
    uint8 public constant decimals = 18;

 
    uint256 public constant totalSupply = 100000000 * (10 ** uint256(decimals));

    
    mapping(address => uint256) balances;


    mapping (address => mapping (address => uint256)) internal allowed;

    
    constructor() public {
      owner = msg.sender;
      balances[msg.sender] = totalSupply;
      emit Transfer(address(0), msg.sender, totalSupply);
     
    }
    
 
   
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /// ERC20 transfer().
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// ERC20 transferFrom().
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// ERC20 approve(). Comes with the standard caveat that an approval
    /// meant to limit spending may actually allow more to be spent due to
    /// unfortunate ordering of transactions. For safety, this method
    /// should only be called if the current allowance is 0. Alternatively,
    /// non-ERC20 increaseApproval() and decreaseApproval() can be used.
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// ERC20 allowance().
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /// Not officially ERC20. Allows an allowance to be increased safely.
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /// Not officially ERC20. Allows an allowance to be decreased safely.
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}