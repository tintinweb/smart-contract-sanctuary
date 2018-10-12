pragma solidity ^0.4.24;

// File: contracts/interfaces/IOwned.sol

/*
    Owned Contract Interface
*/
contract IOwned {
    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
    function transferOwnershipNow(address newContractOwner) public;
}

// File: contracts/utility/Owned.sol

/*
    This is the "owned" utility contract used by bancor with one additional function - transferOwnershipNow()
    
    The original unmodified version can be found here:
    https://github.com/bancorprotocol/contracts/commit/63480ca28534830f184d3c4bf799c1f90d113846
    
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
        @dev constructor
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner
        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    /**
        @dev transfers the contract ownership without needing the new owner to accept ownership
        @param newContractOwner    new contract owner
    */
    function transferOwnershipNow(address newContractOwner) ownerOnly public {
        require(newContractOwner != owner);
        emit OwnerUpdate(owner, newContractOwner);
        owner = newContractOwner;
    }

}

// File: contracts/utility/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 * From https://github.com/OpenZeppelin/openzeppelin-solidity/commit/a2e710386933d3002062888b35aae8ac0401a7b3
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }
}

// File: contracts/interfaces/IERC20.sol

/*
    Smart Token Interface
*/
contract IERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/interfaces/ISmartToken.sol

/**
    @notice Smart Token Interface
*/
contract ISmartToken is IOwned, IERC20 {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

// File: contracts/SmartToken.sol

/*

This contract implements the required functionality to be considered a Bancor smart token.
Additionally it has custom token sale functionality and the ability to withdraw tokens accidentally deposited

// TODO abstract this into 3 contracts and inherit from them: 1) ERC20, 2) Smart Token, 3) Native specific functionality
*/
contract SmartToken is Owned, IERC20, ISmartToken {

    /**
        Smart Token Implementation
    */

    bool public transfersEnabled = true;    // true if transfer/transferFrom are enabled, false if not
    /// @notice Triggered when a smart token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
    event NewSmartToken(address _token);
    /// @notice Triggered when the total supply is increased
    event Issuance(uint256 _amount);
    // @notice Triggered when the total supply is decreased
    event Destruction(uint256 _amount);

    // @notice Verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

    /// @notice Validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

    /**
        @dev disables/enables transfers
        can only be called by the contract owner
        @param _disable    true to disable transfers, false to enable them
    */
    function disableTransfers(bool _disable) public ownerOnly {
        transfersEnabled = !_disable;
    }

    /**
        @dev increases the token supply and sends the new tokens to an account
        can only be called by the contract owner
        @param _to         account to receive the new amount
        @param _amount     amount to increase the supply by
    */
    function issue(address _to, uint256 _amount)
    public
    ownerOnly
    validAddress(_to)
    notThis(_to)
    {
        totalSupply = SafeMath.add(totalSupply, _amount);
        balances[_to] = SafeMath.add(balances[_to], _amount);
        emit Issuance(_amount);
        emit Transfer(this, _to, _amount);
    }

    /**
        @dev removes tokens from an account and decreases the token supply
        can be called by the contract owner to destroy tokens from any account or by any holder to destroy tokens from his/her own account
        @param _from       account to remove the amount from
        @param _amount     amount to decrease the supply by
    */
    function destroy(address _from, uint256 _amount) public {
        require(msg.sender == _from || msg.sender == owner); // validate input
        balances[_from] = SafeMath.sub(balances[_from], _amount);
        totalSupply = SafeMath.sub(totalSupply, _amount);

        emit Transfer(_from, this, _amount);
        emit Destruction(_amount);
    }

    /**
        @notice ERC20 Implementation
    */
    uint256 public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        if (balances[msg.sender] >= _value && _to != address(0)) {
            balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
            balances[_to] = SafeMath.add(balances[_to], _value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _to != address(0)) {

            balances[_to] = SafeMath.add(balances[_to], _value);
            balances[_from] = SafeMath.sub(balances[_from], _value);
            allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version;

    constructor(string _name, uint _totalSupply, uint8 _decimals, string _symbol, string _version, address sender) public {
        balances[sender] = _totalSupply;               // Give the creator all initial tokens
        totalSupply = _totalSupply;                        // Update total supply
        name = _name;                                   // Set the name for display purposes
        decimals = _decimals;                            // Amount of decimals for display purposes
        symbol = _symbol;                               // Set the symbol for display purposes
        version = _version;

        emit NewSmartToken(address(this));
    }

    /**
        @notice Token Sale Implementation
    */
    uint public saleStartTime;
    uint public saleEndTime;
    uint public price;
    uint public amountRemainingForSale;
    bool public buyModeEth = true;
    address public beneficiary;
    address public payableTokenAddress;

    event TokenSaleInitialized(uint _saleStartTime, uint _saleEndTime, uint _price, uint _amountForSale, uint nowTime);
    event TokensPurchased(address buyer, uint amount);

    /**
        @dev increases the token supply and sends the new tokens to an account.  Similar to issue() but for use in token sale
        @param _to         account to receive the new amount
        @param _amount     amount to increase the supply by
    */
    function issuePurchase(address _to, uint256 _amount)
    internal
    validAddress(_to)
    notThis(_to)
    {
        totalSupply = SafeMath.add(totalSupply, _amount);
        balances[_to] = SafeMath.add(balances[_to], _amount);
        emit Issuance(_amount);
        emit Transfer(this, _to, _amount);
    }

    /**
        @notice Begins the token sale for this token instance
        @param _saleStartTime Unix timestamp of the token sale start
        @param _saleEndTime Unix timestamp of the token sale close
        @param _price If sale initialized in ETH: price in Wei.
                If not, token purchases are enabled and this is the amount of tokens issued per tokens paid
        @param _amountForSale Amount of tokens for sale
        @param _beneficiary Recipient of the token sale proceeds
    */
    function initializeTokenSale(uint _saleStartTime, uint _saleEndTime, uint _price, uint _amountForSale, address _beneficiary) public ownerOnly {
        // Check that the token sale has not yet been initialized
        initializeSale(_saleStartTime, _saleEndTime, _price, _amountForSale, _beneficiary);
    }
    /**
        @notice Begins the token sale for this token instance
        @notice Uses the same signature as initializeTokenSale() with:
        @param _tokenAddress The whitelisted token address to allow payments in
    */
    function initializeTokenSaleWithToken(uint _saleStartTime, uint _saleEndTime, uint _price, uint _amountForSale, address _beneficiary, address _tokenAddress) public ownerOnly {
        buyModeEth = false;
        payableTokenAddress = _tokenAddress;
        initializeSale(_saleStartTime, _saleEndTime, _price, _amountForSale, _beneficiary);
    }

    function initializeSale(uint _saleStartTime, uint _saleEndTime, uint _price, uint _amountForSale, address _beneficiary) internal {
        // Check that the token sale has not yet been initialized
        require(saleStartTime == 0);
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
        price = _price;
        amountRemainingForSale = _amountForSale;
        beneficiary = _beneficiary;
        emit TokenSaleInitialized(saleStartTime, saleEndTime, price, amountRemainingForSale, now);
    }

    function updateStartTime(uint _newSaleStartTime) public ownerOnly {
        saleStartTime = _newSaleStartTime;
    }

    function updateEndTime(uint _newSaleEndTime) public ownerOnly {
        require(_newSaleEndTime >= saleStartTime);
        saleEndTime = _newSaleEndTime;
    }

    function updateAmountRemainingForSale(uint _newAmountRemainingForSale) public ownerOnly {
        amountRemainingForSale = _newAmountRemainingForSale;
    }

    function updatePrice(uint _newPrice) public ownerOnly { 
        price = _newPrice;
    }

    /// @dev Allows owner to withdraw erc20 tokens that were accidentally sent to this contract
    function withdrawToken(IERC20 _token, uint amount) public ownerOnly {
        _token.transfer(msg.sender, amount);
    }

    /**
        @dev Allows token sale with parent token
    */
    function buyWithToken(IERC20 _token, uint amount) public payable {
        require(_token == payableTokenAddress);
        uint amountToBuy = SafeMath.mul(amount, price);
        require(amountToBuy <= amountRemainingForSale);
        require(now <= saleEndTime && now >= saleStartTime);
        amountRemainingForSale = SafeMath.sub(amountRemainingForSale, amountToBuy);
        require(_token.transferFrom(msg.sender, beneficiary, amount));
        issuePurchase(msg.sender, amountToBuy);
        emit TokensPurchased(msg.sender, amountToBuy);
    }

    function() public payable {
        require(buyModeEth == true);
        uint amountToBuy = SafeMath.div( SafeMath.mul(msg.value, 1 ether), price);
        require(amountToBuy <= amountRemainingForSale);
        require(now <= saleEndTime && now >= saleStartTime);
        amountRemainingForSale = SafeMath.sub(amountRemainingForSale, amountToBuy);
        issuePurchase(msg.sender, amountToBuy);
        beneficiary.transfer(msg.value);
        emit TokensPurchased(msg.sender, amountToBuy);
    }
}