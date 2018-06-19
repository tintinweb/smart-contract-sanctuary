pragma solidity ^0.4.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract Pausable is owned {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}


contract TokenERC20 is Pausable {
    using SafeMath for uint256;
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    // total no of tokens for sale
    uint256 public TokenForSale;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);


    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 TokenSale
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        TokenForSale =  TokenSale * 10 ** uint256(decimals);

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
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
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
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] =  allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
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
        allowance[msg.sender][_spender] = _value;
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
}

contract Sale is owned, TokenERC20 {

    // total token which is sold
    uint256 public soldTokens;

    modifier CheckSaleStatus() {
        require (TokenForSale >= soldTokens);
        _;
    }

}


contract Mundo is TokenERC20, Sale {
    using SafeMath for uint256;
    uint256 public  unitsOneEthCanBuy;
    uint256 public  minPurchaseQty;

    mapping (address => bool) public airdrops;


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Mundo()
    TokenERC20(20000000000, &#39;MUNDO&#39;, &#39;MUO&#39;, 100000) public {
        unitsOneEthCanBuy = 80000;
        soldTokens = 0;
        minPurchaseQty = 16000 * 10 ** uint256(decimals);
    }

    function changeOwnerWithTokens(address newOwner) onlyOwner public {
        uint previousBalances = balanceOf[owner] + balanceOf[newOwner];
        balanceOf[newOwner] += balanceOf[owner];
        balanceOf[owner] = 0;
        assert(balanceOf[owner] + balanceOf[newOwner] == previousBalances);
        owner = newOwner;
    }

    function changePrice(uint256 _newAmount) onlyOwner public {
        unitsOneEthCanBuy = _newAmount;
    }

    function startSale() onlyOwner public {
        soldTokens = 0;
    }

    function increaseSaleLimit(uint256 TokenSale)  onlyOwner public {
        TokenForSale = TokenSale * 10 ** uint256(decimals);
    }

    function increaseMinPurchaseQty(uint256 newQty) onlyOwner public {
        minPurchaseQty = newQty * 10 ** uint256(decimals);
    }
    
    function airDrop(address[] _recipient, uint _totalTokensToDistribute) onlyOwner public {
        uint256 total_token_to_transfer = (_totalTokensToDistribute * 10 ** uint256(decimals)).mul(_recipient.length); 
        require(balanceOf[owner] >=  total_token_to_transfer);
        for(uint256 i = 0; i< _recipient.length; i++)
        {
            if (!airdrops[_recipient[i]]) {
              airdrops[_recipient[i]] = true;
              _transfer(owner, _recipient[i], _totalTokensToDistribute * 10 ** uint256(decimals));
            }
        }
    }
    function() public payable whenNotPaused CheckSaleStatus {
        uint256 eth_amount = msg.value;
        uint256 amount = eth_amount.mul(unitsOneEthCanBuy);
        soldTokens = soldTokens.add(amount);
        require(amount >= minPurchaseQty );
        require(balanceOf[owner] >= amount );
        _transfer(owner, msg.sender, amount);
        //Transfer ether to fundsWallet
        owner.transfer(msg.value);
    }
}