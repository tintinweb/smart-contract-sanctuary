pragma solidity ^0.4.11;

contract boleno {
    string public constant name = "Boleno";                 // Token name
    string public constant symbol = "BLN";                  // Boleno token symbol
    uint8 public constant decimals = 18;                    // Number of decimals
    uint256 public totalSupply = 10**25;                    // The initial supply (10 million) in base unit
    address public supplier;                                // Boleno supplier address
    uint public blnpereth = 50;                             // Price of 1 Ether in Bolenos by the supplier
    uint public bounty = 15;                                // Percentage of bounty program. Initiates with 15%
    bool public sale = false;                               // Is there an ongoing sale?
    bool public referral = false;                           // Is the referral program enabled?

    // Events
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    mapping (address => uint256) public balances;           // Balances
    mapping(address => mapping (address => uint256)) allowed;// Record of allowances

    // Initialization
    function boleno() {
      supplier = msg.sender;                                // Supplier is contract creator
      balances[supplier] = totalSupply;                     // The initial supply goes to supplier
    }

    // For functions that require only supplier usage
    modifier onlySupplier {
      if (msg.sender != supplier) throw;
      _;
    }

    // Token transfer
    function transfer(address _to, uint256 _value) returns (bool success) {
      if (now < 1502755200 && msg.sender != supplier) throw;// Cannot trade until Tuesday, August 15, 2017 12:00:00 AM (End of ICO)
      if (balances[msg.sender] < _value) throw;            // Does the spender have enough Bolenos to send?
      if (balances[_to] + _value < balances[_to]) throw;   // Overflow?
      balances[msg.sender] -= _value;                      // Subtract the Bolenos from the sender&#39;s balance
      balances[_to] += _value;                             // Add the Bolenos to the recipient&#39;s balance
      Transfer(msg.sender, _to, _value);                   // Send Bolenos transfer event
      return true;                                         // Return true to client
    }

    // Token transfer on your behalf (i.e. by contracts)
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (now < 1502755200 && _from != supplier) throw;     // Cannot trade until Tuesday, August 15, 2017 12:00:00 AM (End of ICO)
      if (balances[_from] < _value) throw;                  // Does the spender have enough Bolenos to send?
      if(allowed[_from][msg.sender] < _value) throw;        // Is the sender allowed to spend as much money on behalf of the spender?
      if (balances[_to] + _value < balances[_to]) throw;    // Overflow?
      balances[_from] -= _value;                            // Subtract the Bolenos from the sender&#39;s balance
      allowed[_from][msg.sender] -= _value;                 // Update allowances record
      balances[_to] += _value;                              // Add the Bolenos to the recipient&#39;s balance
      Transfer(_from, _to, _value);                         // Send Bolenos transfer event
      return true;                                          // Return true to client
     }

     // Allows someone (i.e a contract) to spend on your behalf multiple times up to a certain value.
     // If this function is called again, it overwrites the current allowance with _value.
     // Approve 0 to cancel previous approval
     function approve(address _spender, uint256 _value) returns (bool success) {
       allowed[msg.sender][_spender] = _value;             // Update allowances record
       Approval(msg.sender, _spender, _value);             // Send approval event
       return true;                                        // Return true to client
     }

     // Check how much someone approved you to spend on their behalf
     function allowance(address _owner, address _spender) returns (uint256 bolenos) {
       return allowed[_owner][_spender];                   // Check the allowances record
     }

    // What is the Boleno balance of a particular person?
    function balanceOf(address _owner) returns (uint256 bolenos){
      return balances[_owner];
    }

    /*
     Crowdsale related functions
    */

    // Referral bounty system
    function referral(address referrer) payable {
      if(sale != true) throw;                               // Is there an ongoing sale?
      if(referral != true) throw;                           // Is referral bounty allowed by supplier?
      if(balances[referrer] < 100**18) throw;               // Make sure referrer already has at least 100 Bolenos
      uint256 bolenos = msg.value * blnpereth;              // Determine amount of equivalent Bolenos to the Ethers received
      /*
        First give Bolenos to the purchaser
      */
      uint256 purchaserBounty = (bolenos / 100) * (100 + bounty);// Add bounty to the purchased amount
      if(balances[supplier] < purchaserBounty) throw;       // Does the supplier have enough BLN tokens to sell?
      if (balances[msg.sender] + purchaserBounty < balances[msg.sender]) throw; // Overflow?
      balances[supplier] -= purchaserBounty;                // Subtract the Bolenos from the supplier&#39;s balance
      balances[msg.sender] += purchaserBounty;              // Add the Bolenos to the buyer&#39;s balance
      Transfer(supplier, msg.sender, purchaserBounty);      // Send Bolenos transfer event
      /*
        Then give Bolenos to the referrer
      */
      uint256 referrerBounty = (bolenos / 100) * bounty;    // Only the bounty percentage is added to the referrer
      if(balances[supplier] < referrerBounty) throw;        // Does the supplier have enough BLN tokens to sell?
      if (balances[referrer] + referrerBounty < balances[referrer]) throw; // Overflow?
      balances[supplier] -= referrerBounty;                 // Subtract the Bolenos from the supplier&#39;s balance
      balances[referrer] += referrerBounty;                 // Add the Bolenos to the buyer&#39;s balance
      Transfer(supplier, referrer, referrerBounty);         // Send Bolenos transfer event
    }

    // Set the number of BLNs sold per ETH (only by the supplier).
    function setbounty(uint256 newBounty) onlySupplier {
      bounty = newBounty;
    }

    // Set the number of BLNs sold per ETH (only by the supplier).
    function setblnpereth(uint256 newRate) onlySupplier {
      blnpereth = newRate;
    }

    // Trigger Sale (only by the supplier)
    function triggerSale(bool newSale) onlySupplier {
      sale = newSale;
    }

    // Transfer both supplier status and all held Boleno tokens supply to a different address (only supplier)
    function transferSupply(address newSupplier) onlySupplier {
      if (balances[newSupplier] + balances[supplier] < balances[newSupplier]) throw;// Overflow?
      uint256 supplyValue = balances[supplier];             // Determine current value of the supply
      balances[newSupplier] += supplyValue;                 // Add supply to new supplier
      balances[supplier] -= supplyValue;                    // Substract supply from old supplier
      Transfer(supplier, newSupplier, supplyValue);         // Send Bolenos transfer event
      supplier = newSupplier;                               // Transfer supplier status
    }

    // Claim sale Ethers. Can be executed by anyone.
    function claimSale(){
      address dao = 0xE6237a036366b8003AeD725E8001BD91890be03F;// Hardcoded address of the Bolenum private DAO
      dao.transfer(this.balance);                           // Send all collected Ethers to the address
    }

    // Fallback function. Used for buying Bolenos from supplier by simply sending Ethers to contract
    function () payable {
      if(sale != true) throw;                               // Is there an ongoing sale?
      uint256 bolenos = msg.value * blnpereth;              // Determine amount of equivalent Bolenos to the Ethers received
      if(balances[supplier] < bolenos) throw;               // Does the supplier have enough BLN tokens to sell?
      if (balances[msg.sender] + bolenos < balances[msg.sender]) throw; // Overflow?
      balances[supplier] -= bolenos;                        // Subtract the Bolenos the supplier&#39;s balance
      balances[msg.sender] += bolenos;                      // Add the Bolenos to the buyer&#39;s balance
      Transfer(supplier, msg.sender, bolenos);              // Send Bolenos transfer event
    }
}