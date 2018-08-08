pragma solidity 0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Moneda {
    using SafeMath for uint256;
    
    string constant public standard = "ERC20";
    string constant public name = "Moneda Token";
    string constant public symbol = "MND";
    uint8 constant public decimals = 18;
    
    uint256 private _totalSupply = 400000000e18; // Total supply tokens 400mil
    uint256 constant public preICOLimit = 20000000e18; // Pre-ICO limit 5%, 20mil
    uint256 constant public icoLimit = 250000000e18; // ICO limit 62.5%, 250mil
    uint256 constant public companyReserve = 80000000e18; // Company Reserve 20%, 80mil
    uint256 constant public teamReserve = 40000000e18; // Team Reserve 10%, 40mil
    uint256 constant public giveawayReserve = 10000000e18; // referral and giving away 2.5%, 10mil

    uint256 public preICOEnds = 1525132799; // Monday, April 30, 2018 11:59:59 PM
    uint256 public icoStarts = 1526342400; // Tuesday, May 15, 2018 12:00:00 AM
    uint256 public icoEnds = 1531699199; // Sunday, July 15, 2018 11:59:59 PM
    
    uint256 constant public startTime = 1532822400; // Two weeks after ICO ends, Sunday, July 29, 2018 12:00:00 AM
    uint256 constant public teamCompanyLock = 1563148800; // One Year after ICO Ends, Reserve Tokens of company and team becomes transferable.  Monday, July 15, 2019 12:00:00 AM

    address public ownerAddr;
    address public companyAddr;
    address public giveawayAddr;
    bool public burned;

    // Array with all balances
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    // Public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burned(uint256 amount);
    
    // Initializes contract with initial supply tokens to the creator of the contract
    function Moneda(address _ownerAddr, address _companyAddr, address _giveawayAddr) public {
        ownerAddr = _ownerAddr;
        companyAddr = _companyAddr;
        giveawayAddr = _giveawayAddr;
        balances[ownerAddr] = _totalSupply; // Give the owner all initial tokens
    }
    
    // Gets the total token supply
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Gets the balance of the specified address.
    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }
    
    // Function to check the amount of tokens that an owner allowed to a spender.
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
    // Transfer some of your tokens to another address
    function transfer(address to, uint256 value) public returns (bool) {
        require(now >= startTime); // Check if one month lock is passed
        require(value > 0);

        if (msg.sender == ownerAddr || msg.sender == companyAddr)
                require(now >= teamCompanyLock);
                
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    // Transfer tokens from one address to another
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value > 0);
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        
        if (now < icoEnds)  // Check if the crowdsale is already over
            require(from == ownerAddr);

        if (msg.sender == ownerAddr || msg.sender == companyAddr)
            require(now >= teamCompanyLock);
            
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    //Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    function approve(address spender, uint256 value) public returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

   // Called when ICO is closed. Burns the remaining tokens except the tokens reserved:
    // Anybody may burn the tokens after ICO ended, but only once (in case the owner holds more tokens in the future).
    // this ensures that the owner will not posses a majority of the tokens.
    function burn() public {
        // Make sure it&#39;s after ICO and hasn&#39;t been called before.
        require(!burned && now > icoEnds);
        uint256 totalReserve = teamReserve.add(companyReserve);
        uint256 difference = balances[ownerAddr].sub(totalReserve);
        balances[ownerAddr] = teamReserve;
        balances[companyAddr] = companyReserve;
        balances[giveawayAddr] = giveawayReserve;
        _totalSupply = _totalSupply.sub(difference);
        burned = true;
        emit Burned(difference);
    }
}