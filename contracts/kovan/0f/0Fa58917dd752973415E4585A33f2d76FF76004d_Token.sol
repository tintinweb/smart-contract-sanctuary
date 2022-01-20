pragma solidity ^0.8.10;

//import 'hardhat/console.sol';
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract Token is IERC20, Ownable {
    string public constant name = 'MyToken';
    string public constant symbol = 'MTKN';
    uint32 public constant decimals = 18;

    using SafeMath for uint256;

    uint public _totalSupply = (10000 * (10**decimals));

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    

    constructor() {
        balances[msg.sender] = _totalSupply;
    }

    function mint(address to, uint amount) public onlyOwner {
        assert(totalSupply() + amount >= totalSupply() && balances[to] + amount >= balances[to]);
        balances[to] = balances[to].add(amount);
        _totalSupply = _totalSupply.add(amount);
    }

    function totalSupply() public view returns (uint256) {
       return _totalSupply;
    }

    function balanceOf(address account) external view returns(uint256){
        return balances[account];
    }

    function transfer(address to, uint amount) public returns (bool) {
        //console.log('Sender balance is %s tokens', balances[msg.sender]);
        //console.log('Trying to send %s tokens to %s', amount, to);
        require(balances[msg.sender] >= amount, 'Not enough tokens');
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint){
        return allowed[owner][spender];
    }

    function approve(address spender, uint amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool){
        if(allowed[from][msg.sender] >= amount
            && balances[from] >= amount
            && balances[to] + amount >= balances[to]){
                allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
                balances[from] = balances[from].sub(amount);
                balances[to] = balances[to].add(amount);
                emit Transfer(from, to, amount);
                return true;  
            }
        return false;
    }

    function burn(address account, uint amount) public onlyOwner {
        // console.log('Account balance is %s tokens', balances[account]);
        // console.log('Total supply is %s tokens', totalSupply());
        // console.log('Trying to burn %s tokens to %s', amount, account);
        require(amount <= balances[account], 'Not enough tokens for burn');
        _totalSupply = _totalSupply.sub(amount);
        balances[account] = balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
        // console.log('Account balance is %s tokens', balances[account]);
        // console.log('Total supply is %s tokens', totalSupply());
    }

}

pragma solidity ^0.8.10;

abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() {
        _owner = msg.sender;
    }


  function owner() public view returns(address) {
    return _owner;
  }


  modifier onlyOwner() {
    require(isOwner());
    _;
  }


  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }


  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }


  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }


  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

pragma solidity ^0.8.10;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); 
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

pragma solidity ^0.8.10;

interface IERC20 {

    function balanceOf(address account) external view returns (uint);

    function transfer(address to, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}