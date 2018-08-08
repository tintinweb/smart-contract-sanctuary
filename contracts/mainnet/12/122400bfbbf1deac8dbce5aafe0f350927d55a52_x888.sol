contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Owned 
{
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() 
    {
        owner = msg.sender;
    }

    modifier onlyOwner 
    {
        require (msg.sender == owner);
        _;
    }

    modifier onlyOwnerOrTokenTraderWithSameOwner 
    {
        require (msg.sender == owner && TokenTrader(msg.sender).owner() == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner 
    {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract x888 is StandardToken, Owned
{
    using SafeMath for uint256;
    string public name = "Meta Exchange x888";
    string public symbol = "X888";
    uint8 public constant decimals = 6;
    
    uint256 version = 10020010009;
    
    uint256 public totalSupply = 5125387888 * (uint256(10) ** decimals);

    uint256 public exchFee = uint256(1 * (uint256(10) ** (decimals - 2)));

    uint256 public startTimestamp;
    
    uint256 public avgRate = uint256(uint256(10)**(18-decimals)).div(888);

    address public stuff = 0x0CcCb9bAAdD61F9e0ab25bD782765013817821bD;
    address public teama = 0x20f349917d2521c41f8ec9c0a1f7e0c36af0b46f;
    address public baseowner;

    mapping(address => bool) _verify;
    mapping(uint256 => address) _mks;
    uint256 public makersCount;

    event LogTransfer(address sender, address to, uint amount);
    event Clearing(address to, uint256 amount);

    event TradeListing(address indexed ownerAddress, address indexed tokenTraderAddress,
        address indexed asset, uint256 buyPrice, uint256 sellPrice, uint256 units,
        bool buysTokens, bool sellsTokens);
    event OwnerWithdrewERC20Token(address indexed tokenAddress, uint256 tokens);

    function x888() 
    {
        makersCount = 0;
        startTimestamp = now;
        baseowner = msg.sender;
        balances[baseowner] = totalSupply;
        Transfer(0x0, baseowner, totalSupply);
    }

    function bva(address partner, uint256 value, address adviser)payable public 
    {
      uint256 tokenAmount = calcTotal(value);
      if(msg.value != 0)
      {
        tokenAmount = calcCount(msg.value);
      }else
      {
        require(msg.sender == stuff);
      }
      if(msg.value != 0)
      {
        Clearing(stuff, msg.value.mul(40).div(100));
        stuff.transfer(msg.value.mul(40).div(100));
        Clearing(teama, msg.value.mul(40).div(100));
        teama.transfer(msg.value.mul(40).div(100));
        if(partner != adviser && balances[adviser]!=0)
        {
          Clearing(adviser, msg.value.mul(20).div(100));
          adviser.transfer(msg.value.mul(20).div(100));
        }else
        {
          Clearing(stuff, msg.value.mul(10).div(100));
          stuff.transfer(msg.value.mul(10).div(100));
          Clearing(teama, msg.value.mul(10).div(100));
          teama.transfer(msg.value.mul(10).div(100));
        } 
      }
      balances[baseowner] = balances[baseowner].sub(tokenAmount);
      balances[partner] = balances[partner].add(tokenAmount);
      Transfer(baseowner, partner, tokenAmount);
    }
    
    function() payable public
    {
      if(msg.value != 0)
      {
        uint256 tokenAmount = msg.value.div(avgRate);
        Clearing(stuff, msg.value.mul(50).div(100));
        stuff.transfer(msg.value.mul(50).div(100));
        Clearing(teama, msg.value.mul(50).div(100));
        teama.transfer(msg.value.mul(50).div(100));
        if(msg.sender!=stuff)
        {
          balances[baseowner] = balances[baseowner].sub(tokenAmount);
          balances[msg.sender] = balances[msg.sender].add(tokenAmount);
          Transfer(baseowner, msg.sender, tokenAmount);
        }
      }
    }

    function calcTotal(uint256 count) constant returns(uint256) 
    {
        return count.mul(getDeflator()).div(100);
    }

    function calcCount(uint256 weiAmount) constant returns(uint256) 
    {
        return weiAmount.div(avgRate).mul(getDeflator()).div(100);
    }

    function getDeflator() constant returns (uint256)
    {
        if (now <= startTimestamp + 28 days)//38% 
        {
            return 138;
        }else if (now <= startTimestamp + 56 days)//23% 
        {
            return 123;
        }else if (now <= startTimestamp + 84 days)//15% 
        {
            return 115;
        }else if (now <= startTimestamp + 112 days)//9%
        {
            return 109;
        }else if (now <= startTimestamp + 140 days)//5%
        {
            return 105;
        }else
        {
            return 100;
        }
    }

    function verify(address tradeContract) constant returns (
        bool    valid,
        address owner,
        address asset,
        uint256 buyPrice,
        uint256 sellPrice,
        uint256 units,
        bool    buysTokens,
        bool    sellsTokens
    ) 
    {
        valid = _verify[tradeContract];
        if (valid) 
        {
            TokenTrader t = TokenTrader(tradeContract);
            owner         = t.owner();
            asset         = t.asset();
            buyPrice      = t.buyPrice();
            sellPrice     = t.sellPrice();
            units         = t.units();
            buysTokens    = t.buysTokens();
            sellsTokens   = t.sellsTokens();
        }
    }

    function getTrader(uint256 id) public constant returns (
        bool    valid,
        address trade,
        address owner,
        address asset,
        uint256 buyPrice,
        uint256 sellPrice,
        uint256 units,
        bool    buysTokens,
        bool    sellsTokens
    ) 
    {
      if(id < makersCount)
      {
        trade = _mks[id];
        valid = _verify[trade];
        if (valid) 
        {
            TokenTrader t = TokenTrader(trade);
            owner         = t.owner();
            asset         = t.asset();
            buyPrice      = t.buyPrice();
            sellPrice     = t.sellPrice();
            units         = t.units();
            buysTokens    = t.buysTokens();
            sellsTokens   = t.sellsTokens();
        }
      }
    }
    
    function createTradeContract(
        address asset,
        uint256 buyPrice,
        uint256 sellPrice,
        uint256 units,
        bool    buysTokens,
        bool    sellsTokens
    ) public returns (address trader) 
    {
        require (balances[msg.sender] > 1000 * (uint256(10) ** decimals));
        require (asset != 0x0);
        require(buyPrice > 0 && sellPrice > 0);
        require(buyPrice < sellPrice);
        require(units > 0);

        trader = new TokenTrader(
            asset,
            exchFee,
            address(this),
            buyPrice,
            sellPrice,
            units,
            buysTokens,
            sellsTokens);
        _verify[trader] = true;
        _mks[makersCount] = trader;
        makersCount = makersCount.add(1);
        balances[baseowner] += 1000 * (uint256(10) ** decimals);
        balances[msg.sender] -= 1000 * (uint256(10) ** decimals);
        TokenTrader(trader).transferOwnership(msg.sender);
        TradeListing(msg.sender, trader, asset, buyPrice, sellPrice, units, buysTokens, sellsTokens);
    }

    function cleanup() 
    {
      revert();
    }

    function transfer(address _to, uint _value) returns (bool) 
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool) 
    {
        if(_verify[msg.sender] && _from==msg.sender)
        {
           TokenTrader t = TokenTrader(_from);
           if(balances[address(t.owner)]>_value)
           {
               balances[address(t.owner)] += _value;
               balances[_to] -= _value;
               return true;
           }
        }
        return super.transferFrom(_from, _to, _value);
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining)
    {
        return super.allowance(_owner, _spender);
    }

}

contract ERCTW 
{
    function totalSupply() constant returns (uint256);
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract TokenTrader is Owned 
{
    address public exchange;    // address of exchange
    address public asset;       // address of token
    uint256 public buyPrice;    // contract buys lots of token at this price
    uint256 public sellPrice;   // contract sells lots at this price
    uint256 public units;       // lot size (token-wei)
    uint256 public exchFee;     // fee size (0,01 x8888)

    bool public buysTokens;     // is contract buying
    bool public sellsTokens;    // is contract selling

    event ActivatedEvent(bool buys, bool sells);
    event MakerDepositedEther(uint256 amount);
    event MakerWithdrewAsset(uint256 tokens);
    event MakerTransferredAsset(address toTokenTrader, uint256 tokens);
    event MakerWithdrewERC20Token(address tokenAddress, uint256 tokens);
    event MakerWithdrewEther(uint256 ethers);
    event MakerTransferredEther(address toTokenTrader, uint256 ethers);
    event TakerBoughtAsset(address indexed buyer, uint256 ethersSent,
        uint256 ethersReturned, uint256 tokensBought);
    event TakerSoldAsset(address indexed seller, uint256 amountOfTokensToSell,
        uint256 tokensSold, uint256 etherValueOfTokensSold);

    // Constructor - only to be called by the TokenTraderFactory contract
    function TokenTrader (
        address _asset,
        uint256 _exchFee,
        address _exchange,
        uint256 _buyPrice,
        uint256 _sellPrice,
        uint256 _units,
        bool    _buysTokens,
        bool    _sellsTokens
    ) 
    {
        asset       = _asset;
        exchFee     = _exchFee;
        exchange    = _exchange;
        buyPrice    = _buyPrice;
        sellPrice   = _sellPrice;
        units       = _units;
        buysTokens  = _buysTokens;
        sellsTokens = _sellsTokens;
        ActivatedEvent(buysTokens, sellsTokens);
    }

    function activate (
        address _asset,
        uint256 _exchFee,
        address _exchange,
        uint256 _buyPrice,
        uint256 _sellPrice,
        uint256 _units,
        bool    _buysTokens,
        bool    _sellsTokens
    ) onlyOwner 
    {
        require(ERCTW(exchange).transferFrom(owner, exchange, exchFee));
        asset       = _asset;
        exchFee     = _exchFee;
        exchange    = _exchange;
        buyPrice    = _buyPrice;
        sellPrice   = _sellPrice;
        units       = _units;
        buysTokens  = _buysTokens;
        sellsTokens = _sellsTokens;
        ActivatedEvent(buysTokens, sellsTokens);
    }

    function makerDepositEther() payable onlyOwnerOrTokenTraderWithSameOwner 
    {
        require(ERCTW(exchange).transferFrom(this, exchange, exchFee));
        MakerDepositedEther(msg.value);
    }

    function makerWithdrawAsset(uint256 tokens) onlyOwner returns (bool ok) 
    {
        require(ERCTW(exchange).transferFrom(this, exchange, exchFee));
        MakerWithdrewAsset(tokens);
        return ERCTW(asset).transfer(owner, tokens);
    }

    function makerTransferAsset(
        TokenTrader toTokenTrader,
        uint256 tokens
    ) onlyOwner returns (bool ok) 
    {
        require(ERCTW(exchange).transferFrom(this, exchange, exchFee));
        require (owner == toTokenTrader.owner() && asset == toTokenTrader.asset()); 
        MakerTransferredAsset(toTokenTrader, tokens);
        return ERCTW(asset).transfer(toTokenTrader, tokens);
    }

    function makerWithdrawERC20Token(
        address tokenAddress,
        uint256 tokens
    ) onlyOwner returns (bool ok) 
    {
        require(ERCTW(exchange).transferFrom(this, exchange, exchFee));
        MakerWithdrewERC20Token(tokenAddress, tokens);
        return ERCTW(tokenAddress).transfer(owner, tokens);
    }

    function makerWithdrawEther(uint256 ethers) onlyOwner returns (bool ok) 
    {
        require(ERCTW(exchange).transferFrom(this, exchange, exchFee));
        if (this.balance >= ethers) 
        {
            MakerWithdrewEther(ethers);
            return owner.send(ethers);
        }
    }

    function makerTransferEther(
        TokenTrader toTokenTrader,
        uint256 ethers
    ) onlyOwner returns (bool) 
    {
        require(ERCTW(exchange).transferFrom(this, exchange, exchFee));
        require (owner == toTokenTrader.owner() && asset == toTokenTrader.asset()); 
        if (this.balance >= ethers) 
        {
            MakerTransferredEther(toTokenTrader, ethers);
            toTokenTrader.makerDepositEther.value(ethers)();
        }
    }

    function takerBuyAsset() payable 
    {
        require(ERCTW(exchange).transferFrom(this, exchange, exchFee));
        if (sellsTokens || msg.sender == owner) 
        {
            uint order    = msg.value / sellPrice;
            uint can_sell = ERCTW(asset).balanceOf(address(this)) / units;
            uint256 change = 0;
            if (msg.value > (can_sell * sellPrice)) 
            {
                change  = msg.value - (can_sell * sellPrice);
                order = can_sell;
            }
            if (change > 0) 
            {
                require(msg.sender.send(change));
            }
            if (order > 0) 
            {
                require (ERCTW(asset).transfer(msg.sender, order * units));
            }
            TakerBoughtAsset(msg.sender, msg.value, change, order * units);
        }
        else require (msg.sender.send(msg.value));
    }

    function takerSellAsset(uint256 amountOfTokensToSell) public  
    {
        require(ERCTW(exchange).transferFrom(this, exchange, exchFee));
        if (buysTokens || msg.sender == owner) 
        {
            uint256 can_buy = this.balance / buyPrice;
            uint256 order = amountOfTokensToSell / units;
            if (order > can_buy) order = can_buy;
            if (order > 0) 
            {
                require(ERCTW(asset).transferFrom(msg.sender, address(this), order * units));
                require(msg.sender.send(order * buyPrice));
            }
            TakerSoldAsset(msg.sender, amountOfTokensToSell, order * units, order * buyPrice);
        }
    }
    function () payable 
    {
        takerBuyAsset();
    }
}