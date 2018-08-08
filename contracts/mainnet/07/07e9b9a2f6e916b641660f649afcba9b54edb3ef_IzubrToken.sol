pragma solidity ^0.4.18;

contract Ownable 
{
    address public owner;
    address public newOwner;
    
    function Ownable() public 
    {
        owner = msg.sender;
    }

    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _owner) onlyOwner public 
    {
        require(_owner != 0);
        newOwner = _owner;
    }
    
    function confirmOwner() public 
    {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}


/**
 * Math operations with safety checks
 */
contract SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
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


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 
{
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public;
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function getDecimals() public constant returns(uint8);
    function getTotalSupply() public constant returns(uint256 supply);
}



contract IzubrToken is Ownable, ERC20, SafeMath 
{
    string  public constant standard    = &#39;Token 0.1&#39;;
    string  public constant name        = &#39;Izubr&#39;;
    string  public constant symbol      = "IZR";
    uint8   public constant decimals    = 18;
    uint256 public constant tokenKoef = 1000000000000000000;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) public allowed;

    uint       private constant gasPrice = 3000000;

    uint256    public etherPrice;
    uint256    public minimalSuccessTokens;
    uint256    public collectedTokens;

    enum    State { Disabled, PreICO, CompletePreICO, Crowdsale, Enabled, Migration }
    event   NewState(State state);

    State      public state = State.Disabled;
    uint256    public crowdsaleStartTime;
    uint256    public crowdsaleFinishTime;

    mapping (address => uint256)  public investors;
    mapping (uint256 => address)  public investorsIter;
    uint256                       public numberOfInvestors;

    modifier onlyTokenHolders 
    {
        require(balances[msg.sender] != 0);
        _;
    }

    // Fix for the ERC20 short address attack
    modifier onlyPayloadSize(uint size) 
    {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier enabledState 
    {
        require(state == State.Enabled);
        _;
    }

    modifier enabledOrMigrationState 
    {
        require(state == State.Enabled || state == State.Migration);
        _;
    }



    function getDecimals() public constant returns(uint8)
    {
        return decimals;
    }

    function balanceOf(address who) public constant returns (uint256) 
    {
        return balances[who];
    }

    function investorsCount() public constant returns (uint256) 
    {
        return numberOfInvestors;
    }

    function transfer(address _to, uint256 _value)
        public enabledState onlyPayloadSize(2 * 32) 
    {
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = sub( balances[msg.sender], _value );
        balances[_to] = add( balances[_to], _value );

        Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value)
        public enabledState onlyPayloadSize(3 * 32) 
    {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        balances[_from] = sub( balances[_from], _value );
        balances[_to] = add( balances[_to], _value );

        allowed[_from][msg.sender] = sub( allowed[_from][msg.sender], _value );

        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public enabledState 
    {
        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant enabledState
        returns (uint256 remaining) 
    {
        return allowed[_owner][_spender];
    }


    
    function () public payable
    {
        require(state == State.PreICO || state == State.Crowdsale);
        require(now < crowdsaleFinishTime);

        uint256 valueWei = msg.value;

        uint256 price = currentPrice();

        uint256 valueTokens = div( mul( valueWei, price ), 1 ether);

        if( valueTokens > 33333*tokenKoef ) // 5 BTC
        {
            price = price * 112 / 100;
            valueTokens = mul( valueWei, price );
        }

        require(valueTokens > 10*tokenKoef);


        collectedTokens = add( collectedTokens, valueTokens );
            
        if(msg.data.length == 20) 
        {
            address referer = bytesToAddress(bytes(msg.data));

            require(referer != msg.sender);

            mintTokensWithReferal(msg.sender, referer, valueTokens);
        }
        else
        {
            mintTokens(msg.sender, valueTokens);
        }
    }

    function bytesToAddress(bytes source) internal pure returns(address) 
    {
        uint result;
        uint mul = 1;

        for(uint i = 20; i > 0; i--) 
        {
            result += uint8(source[i-1])*mul;
            mul = mul*256;
        }

        return address(result);
    }

    function getTotalSupply() public constant returns(uint256) {
        return totalSupply;
    }

    function depositTokens(address _who, uint256 _valueTokens) public onlyOwner 
    {
        require(state == State.PreICO || state == State.Crowdsale);
        require(now < crowdsaleFinishTime);

        uint256 bonus = currentBonus();
        uint256 tokens = _valueTokens * (100 + bonus) / 100;

        collectedTokens = add( collectedTokens, tokens );

        mintTokens(_who, tokens);
    }


    function bonusForDate(uint date) public constant returns (uint256) 
    {
        require(state == State.PreICO || state == State.Crowdsale);

        uint nday = (date - crowdsaleStartTime) / (1 days);

        uint256 bonus = 0;

        if (state == State.PreICO) 
        {
            if( nday < 7*1 ) bonus = 100;
            else
            if( nday < 7*2 ) bonus = 80;
            else
            if( nday < 7*3 ) bonus = 70;
            else
            if( nday < 7*4 ) bonus = 60;
            else
            if( nday < 7*5 ) bonus = 50;
            else             bonus = 40;
        }
        else
        if (state == State.Crowdsale) 
        {
            if( nday < 1 ) bonus = 20;
            else
            if( nday < 4 ) bonus = 15;
            else
            if( nday < 8 ) bonus = 10;
            else
            if( nday < 12 ) bonus = 5;
        }

        return bonus;
    }

    function currentBonus() public constant returns (uint256) 
    {
        return bonusForDate(now);
    }


    function priceForDate(uint date) public constant returns (uint256) 
    {
        uint256 bonus = bonusForDate(date);

        return etherPrice * (100 + bonus) / 100;
    }

    function currentPrice() public constant returns (uint256) 
    {
        return priceForDate(now);
    }


    function mintTokens(address _who, uint256 _tokens) internal 
    {
        uint256 inv = investors[_who];

        if (inv == 0) // new investor
        {
            investorsIter[numberOfInvestors++] = _who;
        }

        inv = add( inv, _tokens );
        balances[_who] = add( balances[_who], _tokens );

        Transfer(this, _who, _tokens);

        totalSupply = add( totalSupply, _tokens );
    }


    function mintTokensWithReferal(address _who, address _referal, uint256 _valueTokens) internal 
    {
        uint256 refererTokens = _valueTokens * 5 / 100;

        uint256 valueTokens = _valueTokens * 103 / 100;

        mintTokens(_referal, refererTokens);

        mintTokens(_who, valueTokens);
    }
    
    function startTokensSale(
            uint    _crowdsaleStartTime,
            uint    _crowdsaleFinishTime,
            uint256 _minimalSuccessTokens,
            uint256 _etherPrice) public onlyOwner 
    {
        require(state == State.Disabled || state == State.CompletePreICO);

        crowdsaleStartTime  = _crowdsaleStartTime;
        crowdsaleFinishTime = _crowdsaleFinishTime;

        etherPrice = _etherPrice;
        delete numberOfInvestors;
        delete collectedTokens;

        minimalSuccessTokens = _minimalSuccessTokens;

        if (state == State.Disabled) 
        {
            state = State.PreICO;
        } 
        else 
        {
            state = State.Crowdsale;
        }

        NewState(state);
    }
    
    function timeToFinishTokensSale() public constant returns(uint256 t) 
    {
        require(state == State.PreICO || state == State.Crowdsale);

        if (now > crowdsaleFinishTime) 
        {
            t = 0;
        } 
        else 
        {
            t = crowdsaleFinishTime - now;
        }
    }
    
    function finishTokensSale(uint256 _investorsToProcess) public 
    {
        require(state == State.PreICO || state == State.Crowdsale);

        require(now >= crowdsaleFinishTime || 
            (collectedTokens >= minimalSuccessTokens && msg.sender == owner));

        if (collectedTokens < minimalSuccessTokens) 
        {
            // Investors can get their ether calling withdrawBack() function
            while (_investorsToProcess > 0 && numberOfInvestors > 0) 
            {
                address addr = investorsIter[--numberOfInvestors];
                uint256 inv = investors[addr];
                balances[addr] = sub( balances[addr], inv );
                totalSupply = sub( totalSupply, inv );
                Transfer(addr, this, inv);

                --_investorsToProcess;

                delete investorsIter[numberOfInvestors];
            }

            if (numberOfInvestors > 0) 
            {
                return;
            }

            if (state == State.PreICO) 
            {
                state = State.Disabled;
            } 
            else 
            {
                state = State.CompletePreICO;
            }
        } 
        else 
        {
            while (_investorsToProcess > 0 && numberOfInvestors > 0) 
            {
                --numberOfInvestors;
                --_investorsToProcess;

                address i = investorsIter[numberOfInvestors];

                investors[i] = 0;

                delete investors[i];
                delete investorsIter[numberOfInvestors];
            }

            if (numberOfInvestors > 0) 
            {
                return;
            }

            if (state == State.PreICO) 
            {
                state = State.CompletePreICO;
            } 
            else 
            {
                // Create additional tokens for owner (40% of complete totalSupply)
                uint256 tokens = div( mul( 4, totalSupply ) , 6 );
                balances[owner] = tokens;
                totalSupply = add( totalSupply, tokens );
                Transfer(this, owner, tokens);
                state = State.Enabled;
            }
        }

        NewState(state);
    }
    
    // This function must be called by token holder in case of crowdsale failed
    function withdrawBack() public 
    {
        require(state == State.Disabled);

        uint256 tokens = investors[msg.sender];
        uint256 value = div( tokens, etherPrice );

        if (value > 0) 
        {
            investors[msg.sender] = 0;
            require( msg.sender.call.gas(gasPrice).value(value)() );

            totalSupply = sub( totalSupply, tokens );
        }
    }

    
}