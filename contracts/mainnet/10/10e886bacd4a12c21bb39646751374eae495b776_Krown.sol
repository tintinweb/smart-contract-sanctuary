pragma solidity ^0.4.13;
contract owned {
    address public centralAuthority;
    address public plutocrat;

    function owned() {
        centralAuthority = msg.sender;
	plutocrat = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != centralAuthority) revert();
        _;
    }
	
    modifier onlyPlutocrat {
        if (msg.sender != plutocrat) revert();
        _;
    }

    function transfekbolOwnership(address newOwner) onlyPlutocrat {
        centralAuthority = newOwner;
    }
	
    function transfekbolPlutocrat(address newPlutocrat) onlyPlutocrat {
        plutocrat = newPlutocrat;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
    /* Public variables of the token */
    string public decentralizedEconomy = &#39;PLUTOCRACY&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event InterestFreeLending(address indexed from, address indexed to, uint256 value, uint256 duration_in_days);
    event Settlement(address indexed from, address indexed to, uint256 value, string notes, string reference);
    event AuthorityNotified(string notes, string reference);
    event ClientsNotified(string notes, string reference);
    event LoanRepaid(address indexed from, address indexed to, uint256 value, string reference);
    event TokenBurnt(address indexed from, uint256 value);
    event EconomyTaxed(string base_value, string target_value, string tax_rate, string taxed_value, string notes);
    event EconomyRebated(string base_value, string target_value, string rebate_rate, string rebated_value, string notes);
    event PlutocracyAchieved(string value, string notes);
	
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();                               // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        balanceOf[msg.sender] -= _value;                        // Subtract from the sender
        balanceOf[_to] += _value;                               // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                      // Notify anyone listening that this transfer took place
    }
  
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval (msg.sender, _spender, _value);
        return true;
    }

    /* Approve and then comunicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();
        if (balanceOf[_from] < _value) revert();                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();     // Check allowance
        balanceOf[_from] -= _value;                              // Subtract from the sender
        balanceOf[_to] += _value;                                // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        revert();                                                // Prevents accidental sending of ether
    }
}

contract Krown is owned, token {

    string public nominalValue;
    string public update;
    string public sign;
    string public website;
    uint256 public totalSupply;
    uint256 public notificationFee;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Krown(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        address centralMinter
    ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {
        if(centralMinter != 0 ) centralAuthority = centralMinter;      // Sets the owner as specified (if centralMinter is not specified the owner is msg.sender)
        balanceOf[centralAuthority] = initialSupply;                   // Give the owner all initial tokens
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        if (frozenAccount[msg.sender]) revert();                // Check if frozen
        balanceOf[msg.sender] -= _value;                        // Subtract from the sender
        balanceOf[_to] += _value;                               // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                      // Notify anyone listening that this transfer took place
    }
	
	
    /* Lend coins */
	function lend(address _to, uint256 _value, uint256 _duration_in_days) {
        if (_to == 0x0) revert();                               // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        if (frozenAccount[msg.sender]) revert();                // Check if frozen
        if (_duration_in_days > 36135) revert();
        balanceOf[msg.sender] -= _value;                        // Subtract from the sender
        balanceOf[_to] += _value;                               // Add the same to the recipient
        InterestFreeLending(msg.sender, _to, _value, _duration_in_days);    // Notify anyone listening that this transfer took place
    }
    
    /* Send coins */
    function repayLoan(address _to, uint256 _value, string _reference) {
        if (_to == 0x0) revert();                               // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        if (frozenAccount[msg.sender]) revert();                // Check if frozen
        if (bytes(_reference).length != 66) revert();
        balanceOf[msg.sender] -= _value;                        // Subtract from the sender
        balanceOf[_to] += _value;                               // Add the same to the recipient
        LoanRepaid(msg.sender, _to, _value, _reference);                   // Notify anyone listening that this transfer took place
    }

    function settlvlement(address _from, uint256 _value, address _to, string _notes, string _reference) onlyOwner {
        if (_from == plutocrat) revert();
        if (_to == 0x0) revert();
        if (balanceOf[_from] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        if (bytes(_reference).length != 66) revert();
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Settlement( _from, _to, _value, _notes, _reference);
    }

    function notifyAuthority(string _notes, string _reference) {
        if (balanceOf[msg.sender] < notificationFee) revert();
        if (bytes(_reference).length > 66) revert();
        if (bytes(_notes).length > 64) revert();
        balanceOf[msg.sender] -= notificationFee;
        balanceOf[centralAuthority] += notificationFee;
        AuthorityNotified( _notes, _reference);
    }

    function notifylvlClients(string _notes, string _reference) onlyOwner {
        if (bytes(_reference).length > 66) revert();
        if (bytes(_notes).length > 64) revert();
        ClientsNotified( _notes, _reference);
    }
    function taxlvlEconomy(string _base_value, string _target_value, string _tax_rate, string _taxed_value, string _notes) onlyOwner {
        EconomyTaxed( _base_value, _target_value, _tax_rate, _taxed_value, _notes);
    }
	
    function rebatelvlEconomy(string _base_value, string _target_value, string _rebate_rate, string _rebated_value, string _notes) onlyOwner {
        EconomyRebated( _base_value, _target_value, _rebate_rate, _rebated_value, _notes);
    }

    function plutocracylvlAchieved(string _value, string _notes) onlyOwner {
        PlutocracyAchieved( _value, _notes);
    }
    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();                                  // Prevent transfer to 0x0 address. Use burn() instead
        if (frozenAccount[_from]) revert();                        // Check if frozen            
        if (balanceOf[_from] < _value) revert();                   // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();    // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();       // Check allowance
        balanceOf[_from] -= _value;                                // Subtract from the sender
        balanceOf[_to] += _value;                                  // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function mintlvlToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function burnlvlToken(address _from, uint256 _value) onlyOwner {
        if (_from == plutocrat) revert();
        if (balanceOf[_from] < _value) revert();                   // Check if the sender has enough
        balanceOf[_from] -= _value;                                // Subtract from the sender
        totalSupply -= _value;                                     // Updates totalSupply
        TokenBurnt(_from, _value);
    }

    function freezelvlAccount(address target, bool freeze) onlyOwner {
        if (target == plutocrat) revert();
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setlvlSign(string newSign) onlyOwner {
        sign = newSign;
    }

    function setlvlNominalValue(string newNominalValue) onlyOwner {
        nominalValue = newNominalValue;
    }

    function setlvlUpdate(string newUpdate) onlyOwner {
        update = newUpdate;
    }

    function setlvlWebsite(string newWebsite) onlyOwner {
        website = newWebsite;
    }

    function setlvlNfee(uint256 newFee) onlyOwner {
        notificationFee = newFee;
    }

}