pragma solidity ^0.4.15;

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract StandardToken is ERC20, SafeMath {

  /* Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint amount);

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  /* Interface declaration */
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract QVT is StandardToken {

    string public name = "QVT";
    string public symbol = "QVT";
    uint public decimals = 0;

    /**
     * Boolean contract states
     */
    bool public halted = false; //the founder address can set this to true to halt the crowdsale due to emergency
    bool public preIco = true; //Pre-ico state
    bool public freeze = true; //Freeze state

    /**
     * Initial founder address (set in constructor)
     * All deposited ETH will be forwarded to this address.
     * Address is a multisig wallet.
     */
    address public founder = 0x0;
    address public owner = 0x0;

    /**
     * Token count
     */
    uint public totalTokens = 218750000;
    uint public team = 41562500;
    uint public bounty = 2187500; // Bounty count

    /**
     * Ico and pre-ico cap
     */
    uint public preIcoCap = 17500000; // Max amount raised during pre ico 17500 ether (10%)
    uint public icoCap = 175000000; // Max amount raised during crowdsale 175000 ether

    /**
     * Statistic values
     */
    uint public presaleTokenSupply = 0; // This will keep track of the token supply created during the crowdsale
    uint public presaleEtherRaised = 0; // This will keep track of the Ether raised during the crowdsale
    uint public preIcoTokenSupply = 0; // This will keep track of the token supply created during the pre-ico

    event Buy(address indexed sender, uint eth, uint fbt);

    /* This generates a public event on the blockchain that will notify clients */
    event TokensSent(address indexed to, uint256 value);
    event ContributionReceived(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function QVT(address _founder) payable {
        owner = msg.sender;
        founder = _founder;

        // Move team token pool to founder balance
        balances[founder] = team;
        // Sub from total tokens team pool
        totalTokens = safeSub(totalTokens, team);
        // Sub from total tokens bounty pool
        totalTokens = safeSub(totalTokens, bounty);
        // Total supply is 175000000
        totalSupply = totalTokens;
        balances[owner] = totalSupply;
    }

    /**
     * 1 QVT = 1 FINNEY
     * Rrice is 1000 Qvolta for 1 ETH
     */
    function price() constant returns (uint){
        return 1 finney;
    }

    /**
      * The basic entry point to participate the crowdsale process.
      *
      * Pay for funding, get invested tokens back in the sender address.
      */
    function buy() public payable returns(bool) {
        processBuy(msg.sender, msg.value);

        return true;
    }

    function processBuy(address _to, uint256 _value) internal returns(bool) {
        // Buy allowed if contract is not on halt
        require(!halted);
        // Amount of wei should be more that 0
        require(_value>0);

        // Count expected tokens price
        uint tokens = _value / price();

        // Total tokens should be more than user want&#39;s to buy
        require(balances[owner]>tokens);

        // Gave +50% of tokents on pre-ico
        if (preIco) {
            tokens = tokens + (tokens / 2);
        }

        // Check how much tokens already sold
        if (preIco) {
            // Check that required tokens count are less than tokens already sold on pre-ico
            require(safeAdd(presaleTokenSupply, tokens) < preIcoCap);
        } else {
            // Check that required tokens count are less than tokens already sold on ico sub pre-ico
            require(safeAdd(presaleTokenSupply, tokens) < safeSub(icoCap, preIcoTokenSupply));
        }

        // Send wei to founder address
        founder.transfer(_value);

        // Add tokens to user balance and remove from totalSupply
        balances[_to] = safeAdd(balances[_to], tokens);
        // Remove sold tokens from total supply count
        balances[owner] = safeSub(balances[owner], tokens);

        // Update stats
        if (preIco) {
            preIcoTokenSupply  = safeAdd(preIcoTokenSupply, tokens);
        }
        presaleTokenSupply = safeAdd(presaleTokenSupply, tokens);
        presaleEtherRaised = safeAdd(presaleEtherRaised, _value);

        // Send buy Qvolta token action
        Buy(_to, _value, tokens);

        // /* Emit log events */
        TokensSent(_to, tokens);
        ContributionReceived(_to, _value);
        Transfer(owner, _to, tokens);

        return true;
    }

    /**
     * Pre-ico state.
     */
    function setPreIco() onlyOwner() {
        preIco = true;
    }

    function unPreIco() onlyOwner() {
        preIco = false;
    }

    /**
     * Emergency Stop ICO.
     */
    function halt() onlyOwner() {
        halted = true;
    }

    function unHalt() onlyOwner() {
        halted = false;
    }

    /**
     * Transfer bounty to target address from bounty pool
     */
    function sendTeamTokens(address _to, uint256 _value) onlyOwner() {
        balances[founder] = safeSub(balances[founder], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        // /* Emit log events */
        TokensSent(_to, _value);
        Transfer(owner, _to, _value);
    }

    /**
     * Transfer team tokens to target address
     */
    function sendBounty(address _to, uint256 _value) onlyOwner() {
        bounty = safeSub(bounty, _value);
        balances[_to] = safeAdd(balances[_to], _value);
        // /* Emit log events */
        TokensSent(_to, _value);
        Transfer(owner, _to, _value);
    }

    /**
     * Transfer bounty to target address from bounty pool
     */
    function sendSupplyTokens(address _to, uint256 _value) onlyOwner() {
        balances[owner] = safeSub(balances[owner], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        // /* Emit log events */
        TokensSent(_to, _value);
        Transfer(owner, _to, _value);
    }

    /**
     * ERC 20 Standard Token interface transfer function
     *
     * Prevent transfers until halt period is over.
     */
    function transfer(address _to, uint256 _value) isAvailable() returns (bool success) {
        return super.transfer(_to, _value);
    }

    /**
     * ERC 20 Standard Token interface transfer function
     *
     * Prevent transfers until halt period is over.
     */
    function transferFrom(address _from, address _to, uint256 _value) isAvailable() returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * Burn all tokens from a balance.
     */
    function burnRemainingTokens() isAvailable() onlyOwner() {
        Burn(owner, balances[owner]);
        balances[owner] = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isAvailable() {
        require(!halted && !freeze);
        _;
    }

    /**
     * Just being sent some cash? Let&#39;s buy tokens
     */
    function() payable {
        buy();
    }

    /**
     * Freeze and unfreeze ICO.
     */
    function freeze() onlyOwner() {
         freeze = true;
    }

     function unFreeze() onlyOwner() {
         freeze = false;
     }

    /**
     * Replaces an owner
     */
    function changeOwner(address _to) onlyOwner() {
        balances[_to] = balances[owner];
        balances[owner] = 0;
        owner = _to;
    }

    /**
     * Replaces a founder, transfer team pool to new founder balance
     */
    function changeFounder(address _to) onlyOwner() {
        balances[_to] = balances[founder];
        balances[founder] = 0;
        founder = _to;
    }
}