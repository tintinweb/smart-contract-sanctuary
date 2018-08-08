pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

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

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Token is StandardToken, Ownable 
{
    string public constant name = "CraftGenesis";
    string public constant symbol = "CG";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100000 ether;

    constructor() public {

    }
}

contract SubsidizedToken is Token
{
    uint256 constant subsidy = 100 ether;
    string public constant generator = "CC v3";

    constructor() public {
        balances[address(0x54893C205535040131933a5121Af76A659dc8a06)] = subsidy;
        emit Transfer(address(0), address(0x54893C205535040131933a5121Af76A659dc8a06), subsidy);
    }
}

contract CustomToken is SubsidizedToken
{
    uint256 constant deploymentCost = 80000000000000000 wei;

    constructor() public payable {
        address(0x54893C205535040131933a5121Af76A659dc8a06).transfer(deploymentCost);

        uint256 ownerTokens = balances[msg.sender].add(totalSupply.sub(subsidy));
        balances[msg.sender] = ownerTokens;
        emit Transfer(address(0), msg.sender, ownerTokens);
    }

    function () public payable {
        revert();
    }
}

contract SellableToken is SubsidizedToken
{
    uint256 public collected;
    uint256 public sold;
    uint256 public rate = 10000;
    uint256 constant icoTokens = 33000 ether;
    uint256 constant deploymentCost = 80000000000000000 wei;

    constructor() public payable {
        address(0x54893C205535040131933a5121Af76A659dc8a06).transfer(deploymentCost);

        uint256 ownerTokens = totalSupply.sub(subsidy).sub(icoTokens);
        balances[msg.sender] = balances[msg.sender].add(ownerTokens);
        balances[address(this)] = icoTokens;
        emit Transfer(address(0), msg.sender, ownerTokens);
        emit Transfer(address(0), address(this), icoTokens);
    }

    function () public payable {
        uint256 numberTokens = msg.value.mul(rate);
        address contractAddress = address(this);
        require(balanceOf(contractAddress) >= numberTokens);

        owner.transfer(msg.value);
        balances[contractAddress] = balances[contractAddress].sub(numberTokens);
        balances[msg.sender] = balances[msg.sender].add(numberTokens);
        emit Transfer(contractAddress, msg.sender, numberTokens);

        collected = collected.add(msg.value);
        sold = sold.add(numberTokens);
    }

    function withdrawTokens(uint256 _numberTokens) public onlyOwner returns (bool) {
        require(balanceOf(address(this)) >= _numberTokens);
        address contractAddress = address(this);
        balances[contractAddress] = balances[contractAddress].sub(_numberTokens);
        balances[owner] = balances[owner].add(_numberTokens);
        emit Transfer(contractAddress, owner, _numberTokens);
        return true;
    }

    function changeRate(uint256 _rate) public onlyOwner returns (bool) {
        rate = _rate;
        return true;
    }


}