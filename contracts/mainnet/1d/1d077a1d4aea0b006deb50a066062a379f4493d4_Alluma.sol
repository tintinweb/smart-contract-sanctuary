// * Alluma (LUMA) Selfdrop
// * Send 0 ETH to contract address 0x1D077A1d4aEA0B006Deb50A066062a379f4493D4
// * (sending any extra amount of ETH will be considered as donations)
// * Use 120 000 Gas if sending


// * Token Structure

// * Token Name: Alluma
// * Token Symbol: LUMA
// * Token Decimal: 8
// * Token Supply: 500,000,000
// * Smart Contract: 0x1D077A1d4aEA0B006Deb50A066062a379f4493D4

// * Website: https://token.alluma.io
// * Whitepaper: https://go.alluma.io/whitepaper-download


// * The LUMA Token

// * Alluma&#39;s vision is to provide access and education to the next billion people on the blockchain.
// * The Alluma exchange provides the opportunity for users to access highly liquid cryptocurrency markets and engage with the Alluma Training Academy to learn the ins and outs of the crypto world.
// * To support our vision and fuel our ecosystem we’re introducing Alluma utility token: The LUMA Token.

// * LUMA will power numerous aspects of the Alluma ecosystem.
// * The LUMA token is an ERC-20 compliant token to be issued on the Ethereum blockchain, and its use cases include:

// * Settling Trading Fees
// * All users will have the ability to settle trading fees on Alluma’s Exchange

// * Alluma Loyalty Program
// * A first of its kind membership-based tiered loyalty program

// * Community Voting
// * Participation in Alluma’s product developments including token listing initiatives

// * Alluma Training Academy
// * A digital education platform to learn about cryptocurrency and blockchain technology

// * Token Sale Platform
// * A platform for the next generation of technology companies in emerging markets

// * Decentralized Chat
// * P2P chat allowing users to connect and communicate throughout the Alluma ecosystem


// * Follow us on social

// * Telegram: https://t.me/allumaexchange
// * Medium: https://medium.com/alluma
// * Facebook: https://www.facebook.com/alluma
// * Twitter: https://twitter.com/allumaexchange
// * Reddit: https://www.reddit.com/r/alluma
// * Linkedin: https://www.linkedin.com/company/alluma-exchange/
// * Google+: https://plus.google.com/u/0/b/105558719635795800693/105558719635795800693


pragma solidity ^0.4.22;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Token { 
    function distr(address _to, uint256 _value) external returns (bool);
    function totalSupply() constant external returns (uint256 supply);
    function balanceOf(address _owner) constant external returns (uint256 balance);
}

contract Alluma is ERC20 {

    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public blacklist;

    string public constant name = "Alluma";
    string public constant symbol = "LUMA";
    uint public constant decimals = 8;
    
uint256 public totalSupply = 500000000e8;
    
uint256 public totalDistributed = 450000000e8;
    
uint256 public totalRemaining = totalSupply.sub(totalDistributed);
    
uint256 public value = 150e8;



    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    
    event Burn(address indexed burner, uint256 value);

    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
    function Alluma() public {
        owner = msg.sender;
        balances[owner] = totalDistributed;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
        
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }
    
    function () external payable {
        getTokens();
     }
    
    function getTokens() payable canDistr onlyWhitelist public {
        if (value > totalRemaining) {
            value = totalRemaining;
        }
        
        require(value <= totalRemaining);
        
        address investor = msg.sender;
        uint256 toGive = value;
        
        distr(investor, toGive);
        
        if (toGive > 0) {
            blacklist[investor] = true;
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
        
        value = value.div(100000).mul(99999);
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}