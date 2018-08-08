pragma solidity ^0.4.24;

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
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract Phila_Token is ERC20Interface, Owned {
    string public constant symbol = "φιλα";
    string public constant name = "φιλανθρωπία";
    uint8 public constant decimals = 0;
    uint private constant _totalSupply = 10000000;

    address public vaultAddress;
    bool public fundingEnabled;
    uint public totalCollected;         // In wei
    uint public tokenPrice;         // In wei

    mapping(address => uint) balances;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        balances[this] = _totalSupply;
        emit Transfer(address(0), this, _totalSupply);
    }

    function setVaultAddress(address _vaultAddress) public onlyOwner {
        vaultAddress = _vaultAddress;
        return;
    }

    function setFundingEnabled(bool _fundingEnabled) public onlyOwner {
        fundingEnabled = _fundingEnabled;
        return;
    }

    function updateTokenPrice(uint _newTokenPrice) public onlyOwner {
        require(_newTokenPrice > 0);
        tokenPrice = _newTokenPrice;
        return;
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
    function balanceOf(address tokenOwner) public constant returns (uint) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    //
    // THIS TOKENS ARE NOT TRANSFERRABLE.
    //
    // ------------------------------------------------------------------------
    function approve(address, uint) public returns (bool) {
        revert();
        return false;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    //
    // THIS TOKENS ARE NOT TRANSFERRABLE.
    //
    // ------------------------------------------------------------------------
    function allowance(address, address) public constant returns (uint) {
        return 0;
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    //
    // THIS TOKENS ARE NOT TRANSFERRABLE.
    //
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _amount) public returns (bool) {
       if (_amount == 0) {
           emit Transfer(msg.sender, _to, _amount);    // Follow the spec to louch the event when transfer 0
           return true;
       }
        revert();
        return false;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // THIS TOKENS ARE NOT TRANSFERRABLE.
    //
    // ------------------------------------------------------------------------
    function transferFrom(address, address, uint) public returns (bool) {
        revert();
        return false;
    }


    function () public payable {
        require (fundingEnabled && (tokenPrice > 0) && (msg.value >= tokenPrice));
        
        totalCollected += msg.value;

        //Send the ether to the vault
        vaultAddress.transfer(msg.value);

        uint tokens = msg.value / tokenPrice;

           // Do not allow transfer to 0x0 or the token contract itself
           require((msg.sender != 0) && (msg.sender != address(this)));

           // If the amount being transfered is more than the balance of the
           //  account the transfer throws
           uint previousBalanceFrom = balances[this];

           require(previousBalanceFrom >= tokens);

           // First update the balance array with the new value for the address
           //  sending the tokens
           balances[this] = previousBalanceFrom - tokens;

           // Then update the balance array with the new value for the address
           //  receiving the tokens
           uint previousBalanceTo = balances[msg.sender];
           require(previousBalanceTo + tokens >= previousBalanceTo); // Check for overflow
           balances[msg.sender] = previousBalanceTo + tokens;

           // An event to make the transfer easy to find on the blockchain
           emit Transfer(this, msg.sender, tokens);

        return;
    }


    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    //
    // THIS TOKENS ARE NOT TRANSFERRABLE.
    //
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(this));
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20Interface token = ERC20Interface(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }
    
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}