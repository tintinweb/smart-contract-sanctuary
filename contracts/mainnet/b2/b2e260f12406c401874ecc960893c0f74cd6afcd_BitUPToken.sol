pragma solidity ^0.4.18;
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

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
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
contract BitUPToken is ERC20, Ownable {

    using SafeMath for uint;

/*----------------- Token Information -----------------*/

    string public constant name = "BitUP Token";
    string public constant symbol = "BUT";

    uint8 public decimals = 18;                            // (ERC20 API) Decimal precision, factor is 1e18
    
    mapping (address => uint256) balances;                 // User&#39;s balances table
    mapping (address => mapping (address => uint256)) allowed; // User&#39;s allowances table

/*----------------- Alloc Information -----------------*/

    uint256 public totalSupply;
    
    uint256 public presaleSupply;                          // Pre-sale supply
    uint256 public angelSupply;                          // Angel supply
    uint256 public marketingSupply;                           // marketing supply
    uint256 public foundationSupply;                       // /Foundation supply
    uint256 public teamSupply;                          //  Team supply
    uint256 public communitySupply;                 //  Community supply
    
    uint256 public teamSupply6Months;                          //Amount of Team supply could be released after 6 months
    uint256 public teamSupply12Months;                          //Amount of Team supply could be released after 12 months
    uint256 public teamSupply18Months;                          //Amount of Team supply could be released after 18 months
    uint256 public teamSupply24Months;                          //Amount of Team supply could be released after 24 months

    uint256 public TeamLockingPeriod6Months;                  // Locking period for team&#39;s supply, release 1/4 per 6 months
    uint256 public TeamLockingPeriod12Months;                  // Locking period for team&#39;s supply, release 1/4 per 6 months
    uint256 public TeamLockingPeriod18Months;                  // Locking period for team&#39;s supply, release 1/4 per 6 months
    uint256 public TeamLockingPeriod24Months;                  // Locking period for team&#39;s supply, release 1/4 per 6 months
    
    address public presaleAddress;                       // Presale address
    address public angelAddress;                        // Angel address
    address public marketingAddress;                       // marketing address
    address public foundationAddress;                      // Foundation address
    address public teamAddress;                         // Team address
    address public communityAddress;                         // Community address    

    function () {
         //if ether is sent to this address, send it back.
         //throw;
         require(false);
    }

/*----------------- Modifiers -----------------*/

    modifier nonZeroAddress(address _to) {                 // Ensures an address is provided
        require(_to != 0x0);
        _;
    }

    modifier nonZeroAmount(uint _amount) {                 // Ensures a non-zero amount
        require(_amount > 0);
        _;
    }

    modifier nonZeroValue() {                              // Ensures a non-zero value is passed
        require(msg.value > 0);
        _;
    }

    modifier checkTeamLockingPeriod6Months() {                 // Ensures locking period is over
        assert(now >= TeamLockingPeriod6Months);
        _;
    }
    
    modifier checkTeamLockingPeriod12Months() {                 // Ensures locking period is over
        assert(now >= TeamLockingPeriod12Months);
        _;
    }
    
    modifier checkTeamLockingPeriod18Months() {                 // Ensures locking period is over
        assert(now >= TeamLockingPeriod18Months);
        _;
    }
    
    modifier checkTeamLockingPeriod24Months() {                 // Ensures locking period is over
        assert(now >= TeamLockingPeriod24Months);
        _;
    }
    
    modifier onlyTeam() {                             // Ensures only team can call the function
        require(msg.sender == teamAddress);
        _;
    }
    
/*----------------- Burn -----------------*/
    
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        // balances[burner] = balances[burner].sub(_value);
        decrementBalance(burner, _value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

/*----------------- Token API -----------------*/

    // -------------------------------------------------
    // Total supply
    // -------------------------------------------------
    function totalSupply() constant returns (uint256){
        return totalSupply;
    }

    // -------------------------------------------------
    // Transfers amount to address
    // -------------------------------------------------
    function transfer(address _to, uint256 _amount) returns (bool success) {
        require(balanceOf(msg.sender) >= _amount);
        uint previousBalances = balances[msg.sender] + balances[_to];
        addToBalance(_to, _amount);
        decrementBalance(msg.sender, _amount);
        Transfer(msg.sender, _to, _amount);
        assert(balances[msg.sender] + balances[_to] == previousBalances);
        return true;
    }

    // -------------------------------------------------
    // Transfers from one address to another (need allowance to be called first)
    // -------------------------------------------------
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        require(balanceOf(_from) >= _amount);
        require(allowance(_from, msg.sender) >= _amount);
        uint previousBalances = balances[_from] + balances[_to];
        decrementBalance(_from, _amount);
        addToBalance(_to, _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        Transfer(_from, _to, _amount);
        assert(balances[_from] + balances[_to] == previousBalances);
        return true;
    }

    // -------------------------------------------------
    // Approves another address a certain amount of FUEL
    // -------------------------------------------------
    function approve(address _spender, uint256 _value) returns (bool success) {
        require((_value == 0) || (allowance(msg.sender, _spender) == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // -------------------------------------------------
    // Gets an address&#39;s FUEL allowance
    // -------------------------------------------------
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // -------------------------------------------------
    // Gets the FUEL balance of any address
    // -------------------------------------------------
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // -------------------------------------------------
    // Contract&#39;s constructor
    // -------------------------------------------------
    function BitUPToken() {
        totalSupply  =    1000000000 * 1e18;               // 100% - 1 billion total BUT with 18 decimals

        presaleSupply =    400000000 * 1e18;               //  40% -  400 million BUT pre-crowdsale
        angelSupply =       50000000 * 1e18;               //  5% - 50 million BUT for the angel crowdsale
        teamSupply =       200000000 * 1e18;               //  20% -  200 million BUT for team. 1/4 part released per 6 months
        foundationSupply = 150000000 * 1e18;               //  15% -  300 million BUT for foundation/incentivising efforts
        marketingSupply =  100000000 * 1e18;       //  10% -  100 million BUT for 
        communitySupply =  100000000 * 1e18;       //  10% -  100 million BUT for      
        
        teamSupply6Months = 50000000 * 1e18;               // team supply release 1/4 per 6 months
        teamSupply12Months = 50000000 * 1e18;               // team supply release 1/4 per 6 months
        teamSupply18Months = 50000000 * 1e18;               // team supply release 1/4 per 6 months
        teamSupply24Months = 50000000 * 1e18;               // team supply release 1/4 per 6 months
        
        angelAddress    = 0xeF01453A730486d262D0b490eF1aDBBF62C2Fe00;                         // Angel address
        presaleAddress = 0x2822332F63a6b80E21cEA5C8c43Cb6f393eb5703;                         // Presale address
        teamAddress = 0x8E199e0c1DD38d455815E11dc2c9A64D6aD893B7;                         // Team address
        foundationAddress = 0xcA972ac76F4Db643C30b86E4A9B54EaBB88Ce5aD;                         // Foundation address
        marketingAddress = 0xd2631280F7f0472271Ae298aF034eBa549d792EA;                         // marketing address
        communityAddress = 0xF691e8b2B2293D3d3b06ecdF217973B40258208C;                         //Community address
        
        
        TeamLockingPeriod6Months = now.add(180 * 1 days); // 180 days locking period
        TeamLockingPeriod12Months = now.add(360 * 1 days); // 360 days locking period
        TeamLockingPeriod18Months = now.add(450 * 1 days); // 450 days locking period
        TeamLockingPeriod24Months = now.add(730 * 1 days); // 730 days locking period
        
        addToBalance(foundationAddress, foundationSupply);
        foundationSupply = 0;
        addToBalance(marketingAddress, marketingSupply);
        marketingSupply = 0;
        addToBalance(communityAddress, communitySupply);
        communitySupply = 0;
        addToBalance(presaleAddress, presaleSupply);
        presaleSupply = 0;
        addToBalance(angelAddress, angelSupply);
        angelSupply = 0;
    }

    // -------------------------------------------------
    // Releases 1/4 of team supply after 6 months
    // -------------------------------------------------
    function releaseTeamTokensAfter6Months() checkTeamLockingPeriod6Months onlyTeam returns(bool success) {
        require(teamSupply6Months > 0);
        addToBalance(teamAddress, teamSupply6Months);
        Transfer(0x0, teamAddress, teamSupply6Months);
        teamSupply6Months = 0;
        teamSupply.sub(teamSupply6Months);
        return true;
    }
    
    // -------------------------------------------------
    // Releases 1/4 of team supply after 12 months
    // -------------------------------------------------
    function releaseTeamTokensAfter12Months() checkTeamLockingPeriod12Months onlyTeam returns(bool success) {
        require(teamSupply12Months > 0);
        addToBalance(teamAddress, teamSupply12Months);
        Transfer(0x0, teamAddress, teamSupply12Months);
        teamSupply12Months = 0;
        teamSupply.sub(teamSupply12Months);
        return true;
    }
    
    // -------------------------------------------------
    // Releases 1/4 of team supply after 18 months
    // -------------------------------------------------
    function releaseTeamTokensAfter18Months() checkTeamLockingPeriod18Months onlyTeam returns(bool success) {
        require(teamSupply18Months > 0);
        addToBalance(teamAddress, teamSupply18Months);
        Transfer(0x0, teamAddress, teamSupply18Months);
        teamSupply18Months = 0;
        teamSupply.sub(teamSupply18Months);
        return true;
    }
    
    // -------------------------------------------------
    // Releases 1/4 of team supply after 24 months
    // -------------------------------------------------
    function releaseTeamTokensAfter24Months() checkTeamLockingPeriod24Months onlyTeam returns(bool success) {
        require(teamSupply24Months > 0);
        addToBalance(teamAddress, teamSupply24Months);
        Transfer(0x0, teamAddress, teamSupply24Months);
        teamSupply24Months = 0;
        teamSupply.sub(teamSupply24Months);
        return true;
    }

    // -------------------------------------------------
    // Adds to balance
    // -------------------------------------------------
    function addToBalance(address _address, uint _amount) internal {
        balances[_address] = SafeMath.add(balances[_address], _amount);
    }

    // -------------------------------------------------
    // Removes from balance
    // -------------------------------------------------
    function decrementBalance(address _address, uint _amount) internal {
        balances[_address] = SafeMath.sub(balances[_address], _amount);
    }
}