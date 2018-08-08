pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;AWMV&#39; AnyWhereMobile Voucher Token
//
// Symbol      : AWMV
// Name        : Example Fixed Supply Token
// Total supply: 100,000,000,000.000000
// Decimals    : 6
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe math
// ----------------------------------------------------------------------------

contract SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

}



// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // This notifies clients about the amount minted
    event Mint(address indexed from, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients 
    event FrozenFunds(address target, bool frozen);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// StopTrade contract - allows owner to stop trading
// ----------------------------------------------------------------------------
contract StopTrade is Owned {

    bool public stopped = false;

    event TradeStopped(bool stopped);

    modifier stoppable {
        assert (!stopped);
        _;
    }

    function stop() onlyOwner public {
        stopped = true;
        TradeStopped(true);
    }

    function start() onlyOwner public {
        stopped = false;
        TradeStopped(false);
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external ; }

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------

contract AWMVoucher is ERC20Interface, SafeMath, StopTrade {

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping (address => bool) public frozenAccount;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function AWMVoucher() public {

        symbol = "ATEST";
        name = "AWM Test Token";
        decimals = 6;

        _totalSupply = 100000000000 * 10**uint(decimals);

        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        require(!frozenAccount[_from]);          // Check if sender is frozen
        require(!frozenAccount[_to]);            // Check if recipient is frozen

        // Save this for an assertion in the future
        uint previousBalances = add(balances[_from], balances[_to]);

        // Subtract from the sender
        balances[_from] -= _value;

        // Add the same to the recipient
        balances[_to] += _value;
        Transfer(_from, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }

     /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) stoppable public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) stoppable public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Redeem tokens
     *
     * Send `_value` tokens from &#39;_from&#39; to `_to`
     * Used to redeem AWMVouchers for AWMDollars
     *
     * @param _from The address of the source
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function redeem(address _from, address _to, uint256 _value) stoppable public onlyOwner {
        _transfer(_from, _to, _value);
    }



    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowed[msg.sender][_spender] = _value;
	    Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) stoppable onlyOwner public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] = sub(balances[msg.sender], _value); 
        _totalSupply = sub(_totalSupply,_value);
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) stoppable onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance

        // Subtract from the targeted balance
        balances[_from] = sub(balances[_from], _value);

        // Subtract from the sender&#39;s allowance
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);

        //totalSupply -= _value;                              // Update totalSupply
        _totalSupply = sub(_totalSupply, _value);

        Burn(_from, _value);
        return true;
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param _target Address to receive the tokens
    /// @param _mintedAmount the amount of tokens it will receive
    function mintToken(address _target, uint256 _mintedAmount) onlyOwner stoppable public {
        require(!frozenAccount[_target]);            // Check if recipient is frozen

	balances[_target] = add(balances[_target], _mintedAmount);

        _totalSupply = add(_totalSupply, _mintedAmount);

        Mint(_target, _mintedAmount);
        Transfer(0, this, _mintedAmount);
        Transfer(this, _target, _mintedAmount);
    }

    

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param _target Address to be frozen
    /// @param _freeze either to freeze it or not
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccount[_target] = _freeze;
        FrozenFunds(_target, _freeze);
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


    function transferToken(address _tokenContract, address _transferTo, uint256 _value) onlyOwner external {

         // If ERC20 tokens are sent to this contract, they will be trapped forever.
         // This function is way for us to withdraw them so we can get them back to their rightful owner

         ERC20Interface(_tokenContract).transfer(_transferTo, _value);
    }

    function transferTokenFrom(address _tokenContract, address _transferTo, address _transferFrom, uint256 _value) onlyOwner external {

         // If ERC20 tokens are sent to this contract, they will be trapped forever.
         // This function is way for us to withdraw them so we can get them back to their rightful owner

         ERC20Interface(_tokenContract).transferFrom(_transferTo, _transferFrom, _value);
    }

    function approveToken(address _tokenContract, address _spender, uint256 _value) onlyOwner external {
         // If ERC20 tokens are sent to this contract, they will be trapped forever.
         // This function is way for us to withdraw them so we can get them back to their rightful owner

         ERC20Interface(_tokenContract).approve(_spender, _value);
    }

}