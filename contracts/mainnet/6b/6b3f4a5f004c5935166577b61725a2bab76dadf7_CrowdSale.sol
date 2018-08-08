pragma solidity ^0.4.18;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 {
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

contract TokenContract is Ownable, StandardToken {
    string public constant name = "MTE Token";
    string public constant symbol = "MTE";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 80000000 * (10 ** uint256(decimals));

    function TokenContract(address _mainWallet) public {
    address mainWallet = _mainWallet;
    uint256 tokensForWallet = 18400000 * (10 ** uint256(decimals));
    uint256 tokensForICO = INITIAL_SUPPLY - tokensForWallet;
    totalSupply = INITIAL_SUPPLY;
    balances[mainWallet] = tokensForWallet;
    balances[msg.sender] = tokensForICO;
    emit Transfer(0x0, mainWallet, tokensForWallet);
    emit Transfer(0x0, msg.sender, tokensForICO);
  }

    function transfer(address _to, uint256 _value) public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function burn(uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        emit Burn(msg.sender, _amount);
    }

    event Burn(address indexed from, uint256 amount);
}


contract CrowdSale is Ownable {
using SafeMath for uint256;

  struct Wave {
    uint256 price;
    uint256 start;
    uint256 finish;
    uint256 amount;
    uint256 sold;
  }

  Wave[5] private waves;
  TokenContract public tkn;
  address public mainWallet;
  uint8 public currentWave;
  uint256 public tokensSold;

  function CrowdSale() public {
    uint256 _startTime = 1522166400;
    tkn = new TokenContract(msg.sender);
    emit TokenCreation(address(tkn));
    mainWallet = msg.sender;  
    waves[0].price = 700;
    waves[0].amount = 6160000 * (10 ** 18);
    waves[0].start = _startTime;
    waves[0].finish = _startTime + 7 days;
    waves[1].price = 600;
    waves[1].amount = 12320000 * (10 ** 18);
    waves[1].start = waves[0].finish;
    waves[1].finish = waves[1].start + 14 days;
    waves[2].price = 500;
    waves[2].amount = 12320000 * (10 ** 18);
    waves[2].start = waves[1].finish;
    waves[2].finish = waves[2].start + 14 days;
    waves[3].price = 400;
    waves[3].amount = 15400000 * (10 ** 18);
    waves[3].start = waves[2].finish;
    waves[3].finish = waves[3].start + 14 days;
    waves[4].price = 300;
    waves[4].amount = 15400000 * (10 ** 18);
    waves[4].start = waves[3].finish;
    waves[4].finish = waves[4].start + 14 days;
  }

  function validPurchase() private returns (bool) {
    if ((waves[currentWave].finish > now) && (waves[currentWave].sold < waves[currentWave].amount)) {
      return true;
    } else {
      if (waves[currentWave].finish < now) {
        bool onTime;
        for (uint8 i = (currentWave); i < 5; i++) {
          currentWave += 1;
          if (waves[currentWave].finish > now) {
            onTime = true;
            break;
          }
        }
        if (onTime) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    }
  }

  function forwardFunds() private {
    if (currentWave < 2) {
      uint256 totalFunds = address(this).balance;
      mainWallet.transfer(totalFunds);
    }
  }

  function finishICO() onlyOwner public {
    if ((waves[currentWave].finish > now) || (waves[currentWave].sold == waves[currentWave].amount)) {
        forwardFunds();
        uint256 tokensToBurn;
        tokensToBurn = tkn.balanceOf(address(this));
        tkn.burn(tokensToBurn);
        selfdestruct(mainWallet);
    }
  }

  function autoSell(address _investor, uint256 _investment) private {
    uint256 tokensToSell;
    tokensToSell = _investment.mul(waves[currentWave].price);
    if (tokensToSell < (waves[currentWave].amount - waves[currentWave].sold)) {
      executeSell(_investor, tokensToSell);
    } else {
      uint256 toKeep;
      uint256 toRefund;
      tokensToSell = waves[currentWave].amount - waves[currentWave].sold;
      toKeep = tokensToSell.div(waves[currentWave].price);
      toRefund = _investment.sub(toKeep);
      _investor.transfer(toRefund);
      executeSell(_investor, tokensToSell);
    }
  }

  function executeSell(address _investor, uint256 _amount) private {
      waves[currentWave].sold += _amount;
      tokensSold += _amount;
      require(tkn.transfer(_investor, _amount));
      emit NewInvestment(_investor, _amount);
      forwardFunds();
  }

  function offlineSell(address _investor, uint256 _amount) onlyOwner public {
    //require(validPurchase());
    require(_amount > 0);
    require(_amount < (waves[currentWave].amount - waves[currentWave].sold));
    require(_investor != address(0));
    executeSell(_investor, _amount);
  }

  function() payable public {
    require(msg.value > 1 finney);
    require(validPurchase());
    autoSell(msg.sender, msg.value);
  }

  event NewInvestment(address investor, uint256 amount);
  event TokenCreation(address _token);


}