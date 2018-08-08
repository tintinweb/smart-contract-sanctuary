pragma solidity ^0.4.3;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC677 is ERC20 {
  function transferAndCall(address to, uint value, bytes data) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract PoolOwners is Ownable {

    mapping(uint64 => address)  private ownerAddresses;
    mapping(address => bool)    private whitelist;

    mapping(address => uint256) public ownerPercentages;
    mapping(address => uint256) public ownerShareTokens;
    mapping(address => uint256) public tokenBalance;

    mapping(address => mapping(address => uint256)) private balances;

    uint64  public totalOwners = 0;
    uint16  public distributionMinimum = 20;

    bool   private contributionStarted = false;
    bool   private distributionActive = false;

    // Public Contribution Variables
    uint256 private ethWei = 1000000000000000000; // 1 ether in wei
    uint256 private valuation = ethWei * 4000; // 1 ether * 4000
    uint256 private hardCap = ethWei * 1000; // 1 ether * 1000
    address private wallet;
    bool    private locked = false;

    uint256 public totalContributed = 0;

    // The contract hard-limit is 0.04 ETH due to the percentage precision, lowest % possible is 0.001%
    // It&#39;s been set at 0.2 ETH to try and minimise the sheer number of contributors as that would up the distribution GAS cost
    uint256 private minimumContribution = 200000000000000000; // 0.2 ETH

    /**
        Events
     */

    event Contribution(address indexed sender, uint256 share, uint256 amount);
    event TokenDistribution(address indexed token, uint256 amount);
    event TokenWithdrawal(address indexed token, address indexed owner, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 amount);

    /**
        Modifiers
     */

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    /**
        Constructor
     */

    constructor(address _wallet) public {
        wallet = _wallet;
    }

    /**
        Contribution Methods
     */

    // Fallback, redirects to contribute
    function() public payable { contribute(msg.sender); }

    function contribute(address sender) internal {
        // Make sure the shares aren&#39;t locked
        require(!locked);

        // Ensure the contribution phase has started
        require(contributionStarted);

        // Make sure they&#39;re in the whitelist
        require(whitelist[sender]);

        // Assert that the contribution is above or equal to the minimum contribution
        require(msg.value >= minimumContribution);

        // Make sure the contribution isn&#39;t above the hard cap
        require(hardCap >= msg.value);

        // Ensure the amount contributed is cleanly divisible by the minimum contribution
        require((msg.value % minimumContribution) == 0);

        // Make sure the contribution doesn&#39;t exceed the hardCap
        require(hardCap >= SafeMath.add(totalContributed, msg.value));

        // Increase the total contributed
        totalContributed = SafeMath.add(totalContributed, msg.value);

        // Calculated share
        uint256 share = percent(msg.value, valuation, 5);

        // Calculate and set the contributors % holding
        if (ownerPercentages[sender] != 0) { // Existing contributor
            ownerShareTokens[sender] = SafeMath.add(ownerShareTokens[sender], msg.value);
            ownerPercentages[sender] = SafeMath.add(share, ownerPercentages[sender]);
        } else { // New contributor
            ownerAddresses[totalOwners] = sender;
            totalOwners += 1;
            ownerPercentages[sender] = share;
            ownerShareTokens[sender] = msg.value;
        }

        // Transfer the ether to the wallet
        wallet.transfer(msg.value);

        // Fire event
        emit Contribution(sender, share, msg.value);
    }

    // Add a wallet to the whitelist
    function whitelistWallet(address contributor) external onlyOwner() {
        // Is it actually an address?
        require(contributor != address(0));

        // Add address to whitelist
        whitelist[contributor] = true;
    }

    // Start the contribution
    function startContribution() external onlyOwner() {
        require(!contributionStarted);
        contributionStarted = true;
    }

    /**
        Public Methods
     */

    // Set the owners share per owner, the balancing of shares is done externally
    function setOwnerShare(address owner, uint256 value) public onlyOwner() {
        // Make sure the shares aren&#39;t locked
        require(!locked);

        if (ownerShareTokens[owner] == 0) {
            whitelist[owner] = true;
            ownerAddresses[totalOwners] = owner;
            totalOwners += 1;
        }
        ownerShareTokens[owner] = value;
        ownerPercentages[owner] = percent(value, valuation, 5);
    }

    // Non-Standard token transfer, doesn&#39;t confine to any ERC
    function sendOwnership(address receiver, uint256 amount) public onlyWhitelisted() {
        // Require they have an actual balance
        require(ownerShareTokens[msg.sender] > 0);

        // Require the amount to be equal or less to their shares
        require(ownerShareTokens[msg.sender] >= amount);

        // Deduct the amount from the owner
        ownerShareTokens[msg.sender] = SafeMath.sub(ownerShareTokens[msg.sender], amount);

        // Remove the owner if the share is now 0
        if (ownerShareTokens[msg.sender] == 0) {
            ownerPercentages[msg.sender] = 0;
            whitelist[receiver] = false; 
            
        } else { // Recalculate percentage
            ownerPercentages[msg.sender] = percent(ownerShareTokens[msg.sender], valuation, 5);
        }

        // Add the new share holder
        if (ownerShareTokens[receiver] == 0) {
            whitelist[receiver] = true;
            ownerAddresses[totalOwners] = receiver;
            totalOwners += 1;
        }
        ownerShareTokens[receiver] = SafeMath.add(ownerShareTokens[receiver], amount);
        ownerPercentages[receiver] = SafeMath.add(ownerPercentages[receiver], percent(amount, valuation, 5));

        emit OwnershipTransferred(msg.sender, receiver, amount);
    }

    // Lock the shares so contract owners cannot change them
    function lockShares() public onlyOwner() {
        require(!locked);
        locked = true;
    }

    // Distribute the tokens in the contract to the contributors/creators
    function distributeTokens(address token) public onlyWhitelisted() {
        // Is this method already being called?
        require(!distributionActive);
        distributionActive = true;

        // Get the token address
        ERC677 erc677 = ERC677(token);

        // Has the contract got a balance?
        uint256 currentBalance = erc677.balanceOf(this) - tokenBalance[token];
        require(currentBalance > ethWei * distributionMinimum);

        // Add the current balance on to the total returned
        tokenBalance[token] = SafeMath.add(tokenBalance[token], currentBalance);

        // Loop through stakers and add the earned shares
        // This is GAS expensive, but unless complex more bug prone logic was added there is no alternative
        // This is due to the percentages needed to be calculated for all at once, or the amounts would differ
        for (uint64 i = 0; i < totalOwners; i++) {
            address owner = ownerAddresses[i];

            // If the owner still has a share
            if (ownerShareTokens[owner] > 0) {
                // Calculate and transfer the ownership of shares with a precision of 5, for example: 12.345%
                balances[owner][token] = SafeMath.add(SafeMath.div(SafeMath.mul(currentBalance, ownerPercentages[owner]), 100000), balances[owner][token]);
            }
        }
        distributionActive = false;

        // Emit the event
        emit TokenDistribution(token, currentBalance);
    }

    // Withdraw tokens from the owners balance
    function withdrawTokens(address token, uint256 amount) public {
        // Can&#39;t withdraw nothing
        require(amount > 0);

        // Assert they&#39;re withdrawing what is in their balance
        require(balances[msg.sender][token] >= amount);

        // Substitute the amounts
        balances[msg.sender][token] = SafeMath.sub(balances[msg.sender][token], amount);
        tokenBalance[token] = SafeMath.sub(tokenBalance[token], amount);

        // Transfer the tokens
        ERC677 erc677 = ERC677(token);
        require(erc677.transfer(msg.sender, amount) == true);

        // Emit the event
        emit TokenWithdrawal(token, msg.sender, amount);
    }

    // Sets the minimum balance needed for token distribution
    function setDistributionMinimum(uint16 minimum) public onlyOwner() {
        distributionMinimum = minimum;
    }

    // Is an account whitelisted?
    function isWhitelisted(address contributor) public view returns (bool) {
        return whitelist[contributor];
    }

    // Get the owners token balance
    function getOwnerBalance(address token) public view returns (uint256) {
        return balances[msg.sender][token];
    }

    /**
        Private Methods
    */

    // Credit to Rob Hitchens: https://stackoverflow.com/a/42739843
    function percent(uint numerator, uint denominator, uint precision) private pure returns (uint quotient) {
        uint _numerator = numerator * 10 ** (precision+1);
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }
}