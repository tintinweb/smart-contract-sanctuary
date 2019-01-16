pragma solidity ^0.4.20;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal  pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal  pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Owned {

    address public owner;
    address newOwner;

    modifier only(address _allowed) {
        require(msg.sender == _allowed);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) only(owner) public {
        newOwner = _newOwner;
    }

    function acceptOwnership() only(newOwner) public {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);

}

contract Token is Owned {
    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    address public crowdsale;
    bool public mintable = true; //transferrable if not mintable

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);


    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function setCrowdsale(address _crowdsale) public {
        require(crowdsale == 0);
        crowdsale = _crowdsale;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(!mintable);
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(!mintable);
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function multiTransfer(address[] dests, uint[] values) public  returns (bool result) {
        uint i = 0;
        while (i < dests.length) {
           result  = result || transfer(dests[i], values[i]);
           i += 1;
        }
        return result;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve_fixed(address _spender, uint _currentValue, uint _value) public returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function mint(address _to, uint _amount) public returns(bool) {
        require(msg.sender == owner || msg.sender == crowdsale);
        require(mintable);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function multimint(address[] dests, uint[] values) public returns (uint) {
        require(msg.sender == owner || msg.sender == crowdsale);
        uint i = 0;
        while (i < dests.length) {
           mint(dests[i], values[i]);
           i += 1;
        }
        return(i);
    }

    function deactivateMint() only(owner) public {
        require(mintable);
        mintable = false;
    }

    function unMint(address _who) public {
        require(balances[_who] > 0);
        require(mintable);
        require(msg.sender == owner || msg.sender == crowdsale);
        totalSupply = totalSupply.sub(balances[_who]);
        balances[_who] = 0;
        emit Transfer(_who, 0x0, balances[_who]);
    }


}

contract Crowdsale is Owned {

    mapping(address => uint) contributions;
    mapping(address => uint) contributionsUSD;

    Token public token; //the token to be distributed
    uint public ETHUSD; //pulled from exchange

    uint public hardCap = 10000000000000000000; //in usd  
    uint public softCap = 2000000000000000000; //in usd
    bool public active = false;

    bool public softCapReached;
    bool public hardCapReached;

    uint public totalUSD; //total USD contributed, via the rate at the moment it was contributed
    uint public totalETH; //total ETH contributed (may be redudnant)

    address[] public beneficiaries; //hardcoded beneficiaries, they recieve half of all contributed amount
    address public updater; //the address who is eligible to update the ETH/USD price

    uint[] public timestamps = [1544313600, 1545523200, 1546819200, 1547942400, 1549238400, 1550361600, 1551398400];
    uint[] public prices = [1000, 1428, 1666, 1739, 1818, 1904, 2000];

    modifier only(address _address) {
        require(msg.sender == _address);
        _;
    }

    constructor(address _tokenAddress, address _owner, address _updater) public {
        token = Token(_tokenAddress);
        require(prices.length == timestamps.length);
        owner = _owner;
        updater = _updater;
        beneficiaries.push(0x8A0Dee4fB57041Da7104372004a9Fd80A5aC9716);
        beneficiaries.push(0x049d1EC8Af5e1C5E2b79983dAdb68Ca3C7eb37F4);
    }


    //Fallback function to receive Ether. Ether contributed is recalculated into USD.
    function() payable public {
        require(active);
        require(!hardCapReached);

        contributions[msg.sender] += msg.value;
        contributionsUSD[msg.sender] += msg.value*ETHUSD / 10**(uint(18));

        uint amount = calculateTokens(msg.value);

        totalETH += msg.value;
        totalUSD += msg.value*ETHUSD / 10**(uint(18));

        token.mint(msg.sender, amount);
        if (totalUSD >= softCap ) {
            softCapReached = true;
        }
        if (totalUSD >= hardCap ) {
            active = false;
            hardCapReached = true;
        }
    }

    //Takes amount of wei sent by investor and calculates how many tokens he must receive (according to the current
    //ETH price and token price.
    //function calculateTokens(uint val) view internal returns(uint) {
    function calculateTokens(uint val) view public returns(uint) {
        uint amount = val * ETHUSD / currentPrice();
        return amount;
    }

    //Calculates current price of token in USD.
    function currentPrice() constant public returns(uint) {
        for (uint i = 0; i < prices.length; i++ ) {
            if (now < timestamps[i]) {
                return prices[i]*10**uint(17);
            }
        }
        return prices[prices.length-1]*10**uint(17);
    }

    //Update current ETHUSD price.
    function updatePrice(uint _newPrice) only(updater) public {
        require(msg.sender == updater);
        require(_newPrice != 0);
        ETHUSD = _newPrice;
    }

    //Activates the ICO. It means tokens can be purchased only when ICO is active.
    function activate() only(owner) public {
        require(now < timestamps[timestamps.length-1]);
        require(!active);
        active = true;
    }

    //Deactivates the ICO;
    function deactivate() only(owner) public {
        require(active);
        active = false;
    }

    //Only full amount of Ether can be sent back to the contributor
    function returnEther(address _contributor) only(owner) public payable {
        require(_contributor.send(contributions[_contributor]));
        contributions[_contributor] = 0;
        contributionsUSD[_contributor] = 0;
        totalETH += contributions[_contributor];
        totalUSD += contributionsUSD[_contributor];
        token.unMint(_contributor);
    }

    function withdrawContributed() only(owner) public {
        require(softCapReached);
        require(beneficiaries[0].send(address(this).balance/2));
        require(beneficiaries[1].send(address(this).balance));
    }


}