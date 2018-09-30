pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract MyGCTokenERC20 {
    // Public variables of the token
    string public name = "Malaysian - Good Citizen Token";
    string public symbol = "MyGC";
    uint8 public decimals = 0;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    address public creator; // owner of the contract


    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public maxtransfer;
    mapping (address => bool) public isProvider;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _provider, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply
    ) public {
        creator = msg.sender;
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(msg.sender == creator || 
                       _to == creator || 
                       (
                           isProvider[msg.sender] && _value <= maxtransfer[msg.sender] && !isProvider[_to]
                       ));
        
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(msg.sender == creator);             // function only for creator
        require(_value <= balanceOf[_from]);     // Check maxtransfer
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set address and maxtransfer as provider
     *
     * Allows `_provider` to spend no more than `_value` tokens on your behalf
     *
     * @param _provider The address authorized to spend
     * @param _maxtransfer the max amount they can spend
     */
    function approveProvider(address _provider, uint256 _maxtransfer) public
        returns (bool success) {
        require(msg.sender == creator);                     // function only for creator
        maxtransfer[_provider] = _maxtransfer;
        isProvider[_provider] = true;
        emit Approval(msg.sender, _provider, _maxtransfer);
        return true;
    }

    /**
     * Set maxtransfer for other address and notify
     *
     * Allows `_provider` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _provider The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _provider, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        require(msg.sender == creator);                     // function only for creator
        tokenRecipient provider = tokenRecipient(_provider);
        if (approveProvider(_provider, _value)) {
            provider.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(msg.sender == creator);             // function only for creator
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _provider the address of the sender
     */
    function burnProvider(address _provider) public returns (bool success) {
        require(msg.sender == creator);                     // function only for creator
        maxtransfer[_provider] = 0;             // Subtract from the sender&#39;s maxtransfer
        balanceOf[creator] += balanceOf[_provider];                              // Update totalSupply
        balanceOf[_provider] = 0;
        isProvider[_provider] = false;               // Withdraw from provider list
        emit Burn(_provider, balanceOf[_provider]);
        return true;
    }
    
    /**
     * Creator able to topup tokens
     * 
     * @param _value the value to be added on token supply
     */ 
     function topupSupply(uint _value) public returns(uint){
         require(msg.sender == creator);                     // function only for creator
         totalSupply += _value;
         balanceOf[creator] += _value;
         return totalSupply;
     }
    
   
     
}