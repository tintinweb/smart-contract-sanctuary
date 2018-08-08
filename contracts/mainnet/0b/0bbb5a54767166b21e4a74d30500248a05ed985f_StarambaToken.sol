pragma solidity ^0.4.24;

/**
 * @title The STT Token contract.
 * 
 * By Nikita Fuchs
 * Credit: Taking ideas from BAT token, NET token and Nimiq token.
 */

/**
 * @title Safe math operations that throw error on overflow.
 *
 * Credit: Taking ideas from FirstBlood token
 */
library SafeMath {

    /** 
     * @dev Safely add two numbers.
     *
     * @param x First operant.
     * @param y Second operant.
     * @return The result of x+y.
     */
    function add(uint256 x, uint256 y)
    internal pure
    returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    /** 
     * @dev Safely substract two numbers.
     *
     * @param x First operant.
     * @param y Second operant.
     * @return The result of x-y.
     */
    function sub(uint256 x, uint256 y)
    internal pure
    returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    /** 
     * @dev Safely multiply two numbers.
     *
     * @param x First operant.
     * @param y Second operant.
     * @return The result of x*y.
     */
    function mul(uint256 x, uint256 y)
    internal pure
    returns(uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z/x == y));
        return z;
    }
}

/**
 * @title The abstract ERC-20 Token Standard definition.
 *
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract Token {
    /// @dev Returns the total token supply.
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    /// @dev MUST trigger when tokens are transferred, including zero value transfers.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// @dev MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Default implementation of the ERC-20 Token Standard.
 */
contract StandardToken is Token {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /**
     * @dev Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
     * @dev The function SHOULD throw if the _from account balance does not have enough tokens to spend.
     *
     * @dev A token contract which creates new tokens SHOULD trigger a Transfer event with the _from address set to 0x0 when tokens are created.
     *
     * Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
     *
     * @param _to The receiver of the tokens.
     * @param _value The amount of tokens to send.
     * @return True on success, false otherwise.
     */
    function transfer(address _to, uint256 _value)
    public
    returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
            balances[_to] = SafeMath.add(balances[_to], _value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
     *
     * @dev The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. 
     * @dev This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in 
     * @dev sub-currencies. The function SHOULD throw unless the _from account has deliberately authorized the sender of 
     * @dev the message via some mechanism.
     *
     * Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
     *
     * @param _from The sender of the tokens.
     * @param _to The receiver of the tokens.
     * @param _value The amount of tokens to send.
     * @return True on success, false otherwise.
     */
    function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[_to] = SafeMath.add(balances[_to], _value);
            balances[_from] = SafeMath.sub(balances[_from], _value);
            allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns the account balance of another account with address _owner.
     *
     * @param _owner The address of the account to check.
     * @return The account balance.
     */
    function balanceOf(address _owner)
    public view
    returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev Allows _spender to withdraw from your account multiple times, up to the _value amount. 
     * @dev If this function is called again it overwrites the current allowance with _value.
     *
     * @dev NOTE: To prevent attack vectors like the one described in [1] and discussed in [2], clients 
     * @dev SHOULD make sure to create user interfaces in such a way that they set the allowance first 
     * @dev to 0 before setting it to another value for the same spender. THOUGH The contract itself 
     * @dev shouldn&#39;t enforce it, to allow backwards compatilibilty with contracts deployed before.
     * @dev [1] https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/
     * @dev [2] https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     * @return True on success, false otherwise.
     */
    function approve(address _spender, uint256 _value)
    public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Returns the amount which _spender is still allowed to withdraw from _owner.
     *
     * @param _owner The address of the sender.
     * @param _spender The address of the receiver.
     * @return The allowed withdrawal amount.
     */
    function allowance(address _owner, address _spender)
    public view
    returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract RelocationToken {
    // function of possible new contract to recieve tokenbalance to relocate - to be protected by msg.sender == StarambaToken
    function recieveRelocation(address _creditor, uint _balance) external returns (bool);
}



 /*is StandardToken */
contract StarambaToken is StandardToken {

    // Token metadata
    string public constant name = "STARAMBA.Token";
    string public constant symbol = "STT";
    uint256 public constant decimals = 18;
    string public constant version = "1";

    uint256 public TOKEN_CREATION_CAP = 1000 * (10**6) * 10**decimals; // 1000 million STTs
    uint256 public constant TOKEN_MIN = 1 * 10**decimals;              // 1 STT

    address public STTadmin1;      // First administrator for multi-sig mechanism
    address public STTadmin2;      // Second administrator for multi-sig mechanism

    // Contracts current state (transactions still paused during sale or already publicly available)
    bool public transactionsActive;

    // Indicate if the token is in relocation mode
    bool public relocationActive;
    address public newTokenContractAddress;

    // How often was the supply adjusted ? (See STT Whitepaper Version 1.0 from 23. May 2018 )
    uint8 supplyAdjustmentCount = 0;

    // Keep track of holders and icoBuyers
    mapping (address => bool) public isHolder; // track if a user is a known token holder to the smart contract - important for payouts later
    address[] public holders;                  // array of all known holders - important for payouts later

    // Store the hashes of admins&#39; msg.data
    mapping (address => bytes32) private multiSigHashes;

    // Declare vendor keys
    mapping (address => bool) public vendors;

    // Count amount of vendors for easier verification of correct contract deployment
    uint8 public vendorCount;

    // Events used for logging
    event LogDeliverSTT(address indexed _to, uint256 _value);
    //event Log

    modifier onlyVendor() {
        require(vendors[msg.sender] == true);
        _;
    }

    modifier isTransferable() {
        require (transactionsActive == true);
        _;
    }

    modifier onlyOwner() {
        // check if transaction sender is admin.
        require (msg.sender == STTadmin1 || msg.sender == STTadmin2);
        // if yes, store his msg.data. 
        multiSigHashes[msg.sender] = keccak256(msg.data);
        // check if his stored msg.data hash equals to the one of the other admin
        if ((multiSigHashes[STTadmin1]) == (multiSigHashes[STTadmin2])) {
            // if yes, both admins agreed - continue.
            _;

            // Reset hashes after successful execution
            multiSigHashes[STTadmin1] = 0x0;
            multiSigHashes[STTadmin2] = 0x0;
        } else {
            // if not (yet), return.
            return;
        }
    }

    /**
     * @dev Create a new STTToken contract.
     *
     *  _admin1 The first admin account that owns this contract.
     *  _admin2 The second admin account that owns this contract.
     *  _vendors List of exactly 10 addresses that are allowed to deliver tokens.
     */
    constructor(address _admin1, address _admin2, address[] _vendors)
    public
    {
        // Check if the parameters make sense

        // admin1 and admin2 address must be set and must be different
        require (_admin1 != 0x0);
        require (_admin2 != 0x0);
        require (_admin1 != _admin2);

        // 10 vendor instances for delivering token purchases
        require (_vendors.length == 10);

        totalSupply = 0;

        // define state
        STTadmin1 = _admin1;
        STTadmin2 = _admin2;

        for (uint8 i = 0; i < _vendors.length; i++){
            vendors[_vendors[i]] = true;
            vendorCount++;
        }
    }

    // Overridden method to check for end of fundraising before allowing transfer of tokens
    function transfer(address _to, uint256 _value)
    public
    isTransferable // Only allow token transfer after the fundraising has ended
    returns (bool success)
    {
        bool result = super.transfer(_to, _value);
        if (result) {
            trackHolder(_to); // track the owner for later payouts
        }
        return result;
    }

    // Overridden method to check for end of fundraising before allowing transfer of tokens
    function transferFrom(address _from, address _to, uint256 _value)
    public
    isTransferable // Only allow token transfer after the fundraising has ended
    returns (bool success)
    {
        bool result = super.transferFrom(_from, _to, _value);
        if (result) {
            trackHolder(_to); // track the owner for later payouts
        }
        return result;
    }

    // Allow for easier balance checking
    function getBalanceOf(address _owner)
    public
    view
    returns (uint256 _balance)
    {
        return balances[_owner];
    }

    // Perform an atomic swap between two token contracts 
    function relocate()
    external 
    {
        // Check if relocation was activated
        require (relocationActive == true);
        
        // Define new token contract is
        RelocationToken newSTT = RelocationToken(newTokenContractAddress);

        // Burn the old balance
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;

        // Perform the relocation of balances to new contract
        require(newSTT.recieveRelocation(msg.sender, balance));
    }

    // Allows to figure out the amount of known token holders
    function getHolderCount()
    public
    view
    returns (uint256 _holderCount)
    {
        return holders.length;
    }

    // Allows for easier retrieval of holder by array index
    function getHolder(uint256 _index)
    public
    view
    returns (address _holder)
    {
        return holders[_index];
    }

    function trackHolder(address _to)
    private
    returns (bool success)
    {
        // Check if the recipient is a known token holder
        if (isHolder[_to] == false) {
            // if not, add him to the holders array and mark him as a known holder
            holders.push(_to);
            isHolder[_to] = true;
        }
        return true;
    }


    /// @dev delivers STT tokens from Leondra (Leondrino Exchange Germany)
    function deliverTokens(address _buyer, uint256 _amount)
    external
    onlyVendor
    {
        require(_amount >= TOKEN_MIN);

        uint256 checkedSupply = SafeMath.add(totalSupply, _amount);
        require(checkedSupply <= TOKEN_CREATION_CAP);

        // Adjust the balance
        uint256 oldBalance = balances[_buyer];
        balances[_buyer] = SafeMath.add(oldBalance, _amount);
        totalSupply = checkedSupply;

        trackHolder(_buyer);

        // Log the creation of these tokens
        emit LogDeliverSTT(_buyer, _amount);
    }

    /// @dev Creates new STT tokens
    function deliverTokensBatch(address[] _buyer, uint256[] _amount)
    external
    onlyVendor
    {
        require(_buyer.length == _amount.length);

        for (uint8 i = 0 ; i < _buyer.length; i++) {
            require(_amount[i] >= TOKEN_MIN);
            require(_buyer[i] != 0x0);

            uint256 checkedSupply = SafeMath.add(totalSupply, _amount[i]);
            require(checkedSupply <= TOKEN_CREATION_CAP);

            // Adjust the balance
            uint256 oldBalance = balances[_buyer[i]];
            balances[_buyer[i]] = SafeMath.add(oldBalance, _amount[i]);
            totalSupply = checkedSupply;

            trackHolder(_buyer[i]);

            // Log the creation of these tokens
            emit LogDeliverSTT(_buyer[i], _amount[i]);
        }
    }

    // Allow / Deny transfer of tokens
    function transactionSwitch(bool _transactionsActive) 
    external 
    onlyOwner
    {
        transactionsActive = _transactionsActive;
    }

    // For eventual later moving to another token contract
    function relocationSwitch(bool _relocationActive, address _newTokenContractAddress) 
    external 
    onlyOwner
    {
        if (_relocationActive) {
            require(_newTokenContractAddress != 0x0);
        } else {
            require(_newTokenContractAddress == 0x0);
        }
        relocationActive = _relocationActive;
        newTokenContractAddress = _newTokenContractAddress;
    }

    // Adjust the cap according to the white paper terms (See STT Whitepaper Version 1.0 from 23. May 2018 )
    function adjustCap()
    external
    onlyOwner
    {
        require (supplyAdjustmentCount < 4);
        TOKEN_CREATION_CAP = SafeMath.add(TOKEN_CREATION_CAP, 50 * (10**6) * 10**decimals); // 50 million STTs
        supplyAdjustmentCount++;
    }

    // Burn function - name indicating the burn of ALL owner&#39;s tokens
    function burnWholeBalance()
    external
    {
        require(balances[msg.sender] > 0);
        totalSupply = SafeMath.sub(totalSupply, balances[msg.sender]);
        balances[msg.sender] = 0;
    }

}