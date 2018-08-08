pragma solidity 0.4.24;

contract ERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function allowance(address owner, address spender) public view returns (uint256);
    
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);
    
    function transfer(address to, uint256 value) public returns (bool);
    
  
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

contract Vault is Ownable { 

    function () public payable {

    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(uint amount) public onlyOwner {
        require(address(this).balance >= amount);
        owner.transfer(amount);
    }

    function withdrawAll() public onlyOwner {
        withdraw(address(this).balance);
    }
}

contract TournamentPass is ERC20, Ownable {

    using SafeMath for uint256;

    Vault vault;

    constructor(Vault _vault) public {
        vault = _vault;
    }

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    address[] public minters;
    uint256 supply;
    uint mintLimit = 20000;
    
    function name() public view returns (string){
        return "GU Tournament Passes";
    }

    function symbol() public view returns (string) {
        return "PASS";
    }

    function addMinter(address minter) public onlyOwner {
        minters.push(minter);
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function isMinter(address test) internal view returns (bool) {
        for (uint i = 0; i < minters.length; i++) {
            if (minters[i] == test) {
                return true;
            }
        }
        return false;
    }

    function mint(address to, uint amount) public returns (bool) {
        require(isMinter(msg.sender));
        if (amount.add(supply) > mintLimit) {
            return false;
        } 
        supply = supply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

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

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    uint public price = 250 finney;

    function purchase(uint amount) public payable {
        
        require(msg.value >= price.mul(amount));
        require(supply.add(amount) <= mintLimit);

        supply = supply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        emit Transfer(address(0), msg.sender, amount);

        address(vault).transfer(msg.value);
    }

}