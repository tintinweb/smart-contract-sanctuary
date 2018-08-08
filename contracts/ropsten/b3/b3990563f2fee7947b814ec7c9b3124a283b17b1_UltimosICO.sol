// ----------------------------------------------------------------------------
// ULTIMOS Token
// Version 1.0
//
// Inital Supply:   1 Billion
// Decimal Places:  18
//
// (c) 2018, World Quest International.  All rights reserved.
// ----------------------------------------------------------------------------


pragma solidity ^0.4.24;


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
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


/* Deployed to:  0xd9850ea1d828cf37046af9769d460ceecb1d6fce */

contract UltimosData is SafeMath {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;
    address public tokenSupplierAddress;

    uint public sellPrice;
    uint public buyPrice;

    bool private dataIsSet;
    
    // This creates an array with all balances
    mapping (address => uint) public _balanceOf;

    mapping (address => mapping (address => uint)) public _allowance;
    mapping (address => bool) public _frozenAccount;
    
    constructor() public {
        dataIsSet = false;
        name = "ULTIMOS Token";                                   // Set the name for display purposes
        symbol = "ULTIMOS";                               // Set the symbol for display purposes
        decimals = 18;
        _totalSupply = safeMul(1000000000, 10 ** uint256(decimals));  // Update total supply with the decimal amount
    }
    
    function setInitialData(address tokenSupplier) public  {
        require(dataIsSet == false);
        tokenSupplierAddress = tokenSupplier;
        _balanceOf[tokenSupplierAddress] = _totalSupply;                // Give the creator all initial tokens
        dataIsSet = true;
    }


    function balanceOf(address tokenHolder) public constant returns (uint balance) {
        balance = _balanceOf[tokenHolder];
    }
    
    function setBalance(address tokenHolder, uint newBalance) public {
        _balanceOf[tokenHolder] = newBalance;
    }

     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        remaining = _allowance[tokenOwner][spender];
     }
     
     function setAllowance(address tokenOwner, address spender, uint _value) public {
         _allowance[tokenOwner][spender] = _value;
     }
     
     function setTotalSupply(uint newTotalSupply) public {
         _totalSupply = newTotalSupply;
     }

    function setBuyPrice(uint _buyPrice) public {
        buyPrice = _buyPrice;
    }
    
    function setSellPrice(uint _sellPrice) public {
        sellPrice = _sellPrice;
    }
    
    function frozenAccount(address _acc) public constant returns (bool) {
        return _frozenAccount[_acc];
    }
    
    function setFrozenAccount(address _acc, bool _frozen) public {
        _frozenAccount[_acc] = _frozen;
    }
    
    function setTokenSupplierAddress(address _tsAddress) public {
        tokenSupplierAddress = _tsAddress;
    }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData)  external; }


contract TokenERC20 is ERC20Interface, SafeMath, Owned {
    UltimosData data;
    
    string public symbol;
    string public name;
    uint8 public decimals;
    

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor (
        address dataAddress
    ) public {
        data = UltimosData(dataAddress);
        data.setInitialData(msg.sender);
        
        symbol = data.symbol();
        name = data.name();
        decimals = data.decimals();
    }

    function totalSupply() public constant returns (uint supply) {
        supply = data._totalSupply();
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        balance = data.balanceOf(tokenOwner);
    }

     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        remaining = data.allowance(tokenOwner, spender);
     }


    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf(_from) >= _value);
        // Check for overflows
        require(balanceOf(_to) + _value > balanceOf(_to));
        // Save this for an assertion in the future
        uint previousBalances = safeAdd(balanceOf(_from), balanceOf(_to));
        // Subtract from the sender
        data.setBalance(_from, safeSub(balanceOf(_from), _value));
        // Add the same to the recipient
        data.setBalance(_to, safeAdd(balanceOf(_to), _value));
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(safeAdd(balanceOf(_from), balanceOf(_to)) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns(bool success) {
        _transfer(msg.sender, _to, _value);
        success = true;
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
        require(_value <= allowance(_from, msg.sender));     // Check allowance
        data.setAllowance(_from, msg.sender, safeSub(allowance(_from, msg.sender), _value));
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
        data.setAllowance(msg.sender, _spender, _value);
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

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf(data.tokenSupplierAddress()) >= _value);   // Check if the sender has enough
        data.setBalance(data.tokenSupplierAddress(), safeSub(balanceOf(data.tokenSupplierAddress()), _value));            // Subtract from the sender
        data.setTotalSupply(safeSub(totalSupply(), _value));                      // Updates totalSupply
        emit Burn(data.tokenSupplierAddress(), _value);
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
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf(_from) >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance(_from, msg.sender));    // Check allowance
        data.setBalance(_from, safeSub(balanceOf(_from), _value));                         // Subtract from the targeted balance
        data.setAllowance(_from, msg.sender, safeSub(allowance(_from, msg.sender), _value));             // Subtract from the sender&#39;s allowance
        data.setTotalSupply(safeSub(totalSupply(), _value));                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}


/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract UltimosToken is TokenERC20 {
    string public _version;
    
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(address dataContract) TokenERC20(dataContract) public {
        _version = "1.0";
        data.setBuyPrice(515350000000000);
        data.setSellPrice(0);
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf(_from) >= _value);               // Check if the sender has enough
        require (balanceOf(_to) + _value >= balanceOf(_to)); // Check for overflows
        require(!data.frozenAccount(_from));                     // Check if sender is frozen
        require(!data.frozenAccount(_to));                       // Check if recipient is frozen
        data.setBalance(_from, safeSub(balanceOf(_from), _value));                         // Subtract from the sender
        data.setBalance(_to, safeAdd(balanceOf(_to), _value));                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    function setTokenSupplier(address newTokenSupplierAddress) onlyOwner public {
        _transfer(data.tokenSupplierAddress(), newTokenSupplierAddress, balanceOf(data.tokenSupplierAddress()));
        data.setTokenSupplierAddress(newTokenSupplierAddress);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        data.setBalance(target, safeAdd(balanceOf(target), mintedAmount));
        data.setTotalSupply(safeAdd(totalSupply(), mintedAmount));
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        data.setFrozenAccount(target, freeze);
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        data.setSellPrice(newSellPrice);
        data.setBuyPrice(newBuyPrice);
    }

    /// @notice Get the current buy and sell prices
    function getPrices() public view returns(uint256, uint256) {
        return (data.sellPrice(), data.buyPrice());
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        require(data.buyPrice() > 0);                            // not allowed if the buyPrice is 0
        uint amount = safeDiv(msg.value, data.buyPrice());               // calculates the amount
        _transfer(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        require(data.sellPrice() > 0);
        require(address(this).balance > safeMul(amount, data.sellPrice()));      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(safeMul(amount, data.sellPrice()));          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }


    function () payable public {
        require(msg.sender.balance >= msg.value);
        owner.transfer(msg.value);
    }


    function version() public constant returns(string) {
        return _version;
    }


    function refund(address target, uint256 amount) public onlyOwner {
        uint txAmount = amount > 0 && amount <= address(this).balance
            ? amount
            : address(this).balance;
        require(address(this).balance >= txAmount);
        target.transfer(txAmount);
    }
}


contract UltimosICO is SafeMath, Owned {

    UltimosData data;

    uint public startDate;
    uint public endDate;
    uint public bonusEnds;
    uint8 public bonusPercent;
    bool public isICORunning;

    event Transfer(address indexed from, address indexed to, uint tokens);

    constructor (address dataContract) public {
        startDate = 0;
        endDate = 0;
        bonusEnds = 0;
        bonusPercent = 0;
        isICORunning = false;
        data = UltimosData(dataContract);
    }


    function startICO(uint icoStartDate, uint icoEndDate, uint presaleEndDate, uint8 presalesDiscountPercent) onlyOwner public  {
        require(isICORunning == false);
        startDate = icoStartDate;
        endDate = icoEndDate;
        bonusEnds = presaleEndDate;
        bonusPercent = presalesDiscountPercent;
        isICORunning = true;
    }


    function extendICO(uint extendUntilDate) public onlyOwner {
        require(isICORunning);
        require(endDate < extendUntilDate);
        endDate = extendUntilDate;
    }


    function () public payable {
        require(isICORunning);
        require(startDate > 0 && endDate > 0 && startDate <= endDate);
        require(now <= endDate);
        uint tokens;
        if (now <= bonusEnds) {
            tokens = safeDiv(msg.value, safeSub(data.buyPrice(), safeMul(safeDiv(data.buyPrice(),  100), bonusPercent)));
        } else {
            tokens = safeDiv(msg.value, data.buyPrice());
        }
        data.setBalance(msg.sender, safeAdd(data.balanceOf(msg.sender), tokens));
        //totalSupply = safeAdd(totalSupply, tokens);
        owner.transfer(msg.value);
        emit Transfer(data.tokenSupplierAddress(), msg.sender, tokens);
    }
}