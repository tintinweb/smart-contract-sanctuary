pragma solidity ^0.4.18;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

   modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

contract NDUXBase is BasicToken, Ownable {

  string public constant name = "NODUX";
  string public constant symbol = "NDUX";
  uint constant maxTotalSupply = 75000000;
  
  function NDUXBase() public {
    mint(this, maxTotalSupply);
  }

  function mint(address to, uint amount) internal returns(bool) {
    require(to != address(0) && amount > 0);
    totalSupply_ = totalSupply_.add(amount);
    balances[to] = balances[to].add(amount);
    emit Transfer(address(0), to, amount);
    return true;
  }
  
  function send(address to, uint amount) public onlyOwner returns(bool) {
    require(to != address(0));
    require(amount <= balances[this]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[this] = balances[this].sub(amount);
    balances[to] = balances[to].add(amount);
    emit Transfer(this, to, amount);
  }

  function burn(address from, uint amount) public onlyOwner returns(bool) {
    require(from != address(0) && amount > 0);
    balances[from] = balances[from].sub(amount);
    totalSupply_ = totalSupply_.sub(amount);
    emit Transfer(from, address(0), amount);
    return true;
  }

}

contract TxFeatures is BasicToken {

  struct Tx {
    uint timestamp;
    uint amount;
  }

  mapping(address => Tx[]) public txs;

  event NewTx(address user, uint timestamp, uint amount);

  function pushtx(address user, uint amount) internal {
    emit NewTx(user, now, amount);
    txs[user].push(Tx(now, amount));
  }

  function poptxs(address user, uint amount) internal {
    require(balanceOf(user) >= amount);
    Tx[] storage usertxs = txs[user];

    for(Tx storage curtx = usertxs[usertxs.length - 1]; usertxs.length != 0;) {

      if(curtx.amount > amount) {
        curtx.amount -= amount;
        amount = 0;
      } else {
        amount -= curtx.amount;
        delete usertxs[usertxs.length - 1];
        --usertxs.length;
      }
      if(amount == 0) break;
    }

    require(amount == 0);

  }
}

contract NDUXB is NDUXBase, TxFeatures {
   
     function calculateTokensEnabledOne(address user, uint minAge) public view onlyOwner returns(uint amount) {
    Tx[] storage usertxs = txs[user];
    for(uint it = 0; it < usertxs.length; ++it) {
      Tx storage curtx = usertxs[it];
      uint diff = now - curtx.timestamp;
      if(diff >= minAge) {
        amount += curtx.amount;
      }
    }
    return amount;
  }

  event SendMiningProfit(address user, uint tokens, uint ethers);

  function sendMiningProfit(address[] users, uint minAge) public payable onlyOwner returns(uint) {
    require(users.length > 0);
    uint total = 0;

    uint[] memory __balances = new uint[](users.length);

    for(uint it = 0; it < users.length; ++it) {
      address user = users[it];
      uint balance = calculateTokensEnabledOne(user, minAge);
      __balances[it] = balance;
      total += balance;
    }

    if(total == 0) return 0;

    uint ethersPerToken = msg.value / total;

    for(it = 0; it < users.length; ++it) {
      user = users[it];
      balance = __balances[it];
      uint ethers = balance * ethersPerToken;
      if(balance > 0)
        user.transfer(balance * ethersPerToken);
      emit SendMiningProfit(user, balance, ethers);
    }
    return ethersPerToken;
  }

  function calculateTokensEnabledforAirdrop(address[] users,uint minAge) public view onlyOwner returns(uint total) {
    for(uint it = 0; it < users.length; ++it) {
      total += calculateTokensEnabledOne(users[it], minAge);
    }
  }

  function airdrop(address[] users, uint minAge, uint percent, uint maxToSend) public onlyOwner returns(uint) {
    require(users.length > 0);
    require(balanceOf(msg.sender) >= maxToSend);
    require(percent > 0 && percent < 10);

    uint total = 0;

    for(uint it = 0; it < users.length; ++it) {
      address user = users[it];
      uint balance = calculateTokensEnabledOne(user, minAge);
      if(balance > 0) {
        uint toSend = balance.mul(percent).div(100);
        total += toSend;
        transfer(user, balance.mul(percent).div(100));
        require(total <= maxToSend);
      }
    }

    return total;
  }

  function send(address to, uint amount) public onlyOwner returns(bool) {
    super.send(to, amount);
    pushtx(to, amount);
  }

  function burn(address from, uint amount) public onlyOwner returns(bool) {
    poptxs(from, amount);
    return super.burn(from, amount);
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    poptxs(msg.sender, _value);
    pushtx(_to, _value);
    super.transfer(_to, _value);
  }
  
  function () payable public {  }
  
  function sendAllLocalEthers(address to) public onlyOwner {
    to.transfer(address(this).balance);
  }
  
}