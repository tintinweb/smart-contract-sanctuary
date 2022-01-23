/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

pragma solidity ^0.4.25;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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
        require(msg.sender == owner, 'only owner');
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

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'not whitelisted');
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
        }       
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @return true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     * @return true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface BEP20Basic {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is BEP20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

/**
 * @title BEP20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract BEP20 is BEP20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard BEP20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is BEP20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

/**
 * @title Mintable token
 * @dev Simple BEP20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 */
contract MintableToken is StandardToken, Whitelist {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyWhitelisted canMint public returns (bool) {
        require(_to != address(0));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyWhitelisted canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract MetaGold is MintableToken {

    struct Stats {
        uint256 txs;
        uint256 minted;
    }

    string public constant name = "MetaGold";
    string public constant symbol = "MetaG";
    uint8 public constant decimals = 18;
    uint256 public constant MAX_INT = 2**256 - 1;
    uint256 public constant targetSupply = MAX_INT;
    uint256 public totalTxs;
    uint256 public players;
    uint256 private mintedSupply_;

    mapping(address => Stats) private stats;

    address public vaultAddress;
    uint8 constant internal taxDefault = 10; // 10% tax on transfers

    mapping (address => uint8) private _customTaxRate;
    mapping (address => bool) private _hasCustomTax;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    event TaxPayed(address from, address vault, uint256 amount);
    /**
     * @dev default constructor
     */
    constructor(uint256 _initialMint) Ownable() public {
        addAddressToWhitelist(owner);
        mint(owner, _initialMint * 1e18);
        removeAddressFromWhitelist(owner);
    }

    function setVaultAddress(address _newVaultAddress) public onlyOwner {
        vaultAddress = _newVaultAddress;
    }

    /**
     * @dev Function to mint tokens (onlyOwner)
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) public returns (bool) {

        //Never fail, just don't mint if over
        if (_amount == 0 || mintedSupply_.add(_amount) > targetSupply) {
            return false;
        }

        //Mint
        super.mint(_to, _amount);
        mintedSupply_ = mintedSupply_.add(_amount);

        if (mintedSupply_ == targetSupply) {
            mintingFinished = true;
            emit MintFinished();
        }

        /* Members */
        if (stats[_to].txs == 0) {
            players += 1;
        }

        stats[_to].txs += 1;
        stats[_to].minted += _amount;

        totalTxs += 1;

        return true;

    }

    /**
     * @dev Override so that minting cannot be accidentally terminated
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        return false;
    }

    function calculateTransactionTax(uint256 _value, uint8 _tax) internal returns (uint256 adjustedValue, uint256 taxAmount){
        taxAmount = _value.mul(_tax).div(100);
        adjustedValue = _value.mul(SafeMath.sub(100, _tax)).div(100);
        return (adjustedValue, taxAmount);
    }

    /** @dev Transfers (using transferFrom) */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        (uint256 adjustedValue, uint256 taxAmount) = calculateTransferTaxes(_from, _value);

        if (taxAmount > 0){
            require(super.transferFrom(_from, vaultAddress, taxAmount));
            emit TaxPayed(_from, vaultAddress, taxAmount);
        }
        require(super.transferFrom(_from, _to, adjustedValue));

        /* Members */
        if (stats[_to].txs == 0) {
            players += 1;
        }

        stats[_to].txs += 1;
        stats[_from].txs += 1;

        totalTxs += 1;

        return true;


    }

    /** @dev Transfers */
    function transfer(address _to, uint256 _value) public returns (bool) {

        (uint256 adjustedValue, uint256 taxAmount) = calculateTransferTaxes(msg.sender, _value);

        if (taxAmount > 0){
            require(super.transfer(vaultAddress, taxAmount));
            emit TaxPayed(msg.sender, vaultAddress, taxAmount);
        }
        require(super.transfer(_to, adjustedValue));

        /* Members */
        if (stats[_to].txs == 0) {
            players += 1;
        }

        stats[_to].txs += 1;
        stats[msg.sender].txs += 1;

        totalTxs += 1;

        return true;
    }

    function calculateTransferTaxes(address _from, uint256 _value) public view returns (uint256 adjustedValue, uint256 taxAmount){
        adjustedValue = _value;
        taxAmount = 0;

        if (!_isExcluded[_from]) {
            uint8 taxPercent = taxDefault; // set to default tax 10%

            // set custom tax rate if applicable
            if (_hasCustomTax[_from]){
                taxPercent = _customTaxRate[_from];
            }

            (adjustedValue, taxAmount) = calculateTransactionTax(_value, taxPercent);
        }
        return (adjustedValue, taxAmount);
    }

    /** @dev Returns the supply still available to mint */
    function remainingMintableSupply() public view returns (uint256) {
        return targetSupply.sub(mintedSupply_);
    }

    /**
     * @dev Returns the cap for the token minting.
     */
    function cap() public view returns (uint256) {
        return targetSupply;
    }

    /**
    * @dev total number of minted tokens
    */
    function mintedSupply() public view returns (uint256) {
        return mintedSupply_;
    }

    /** @dev stats of player, (txs, minted) */
    function statsOf(address player) public view returns (uint256, uint256, uint256){
        return (balanceOf(player), stats[player].txs, stats[player].minted);
    }

    ///** @dev Returns the number of tokens minted by the player */
    function mintedBy(address player) public view returns (uint256){
        return stats[player].minted;
    }

    function setAccountCustomTax(address account, uint8 taxRate) external onlyOwner() {
        require(taxRate >= 0 && taxRate <= 100, "Invalid tax amount");
        _hasCustomTax[account] = true;
        _customTaxRate[account] = taxRate;
    }

    function removeAccountCustomTax(address account) external onlyOwner() {
        _hasCustomTax[account] = false;
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _isExcluded[account] = false;
                delete _excluded[_excluded.length - 1];
                break;
            }
        }
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
}