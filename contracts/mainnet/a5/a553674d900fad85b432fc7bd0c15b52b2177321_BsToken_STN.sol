pragma solidity ^0.4.11;


contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal returns (uint256 ) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal returns (uint256 ) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal returns (uint256 ) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal returns (uint256 ) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }
}

contract ERC20 {

    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20, SafeMath {

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else return false;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else return false;
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract MultiOwnable {

    mapping (address => bool) ownerMap;
    address[] public owners;

    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed oldOwner);

    modifier onlyOwner() {
        if (!isOwner(msg.sender)) throw;
        _;
    }

    function MultiOwnable() {
        // Add default owner
        address owner = msg.sender;
        ownerMap[owner] = true;
        owners.push(owner);
    }

    function isOwner(address owner) constant returns (bool) {
        return ownerMap[owner];
    }

    function addOwner(address owner) onlyOwner returns (bool) {
        if (!isOwner(owner) && owner != 0) {
            ownerMap[owner] = true;
            owners.push(owner);

            OwnerAdded(owner);
            return true;
        } else return false;
    }

    function removeOwner(address owner) onlyOwner returns (bool) {
        if (isOwner(owner)) {
            ownerMap[owner] = false;
            for (uint i = 0; i < owners.length - 1; i++) {
                if (owners[i] == owner) {
                    owners[i] = owners[owners.length - 1];
                    break;
                }
            }
            owners.length -= 1;

            OwnerRemoved(owner);
            return true;
        } else return false;
    }
}

contract TokenSpender {
    function receiveApproval(address _from, uint256 _value);
}

contract BsToken is StandardToken, MultiOwnable {

    bool public locked;

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 18;
    string public version = &#39;v0.1&#39;;

    address public creator;
    address public seller;
    uint256 public tokensSold;
    uint256 public totalSales;

    event Sell(address indexed seller, address indexed buyer, uint256 value);
    event SellerChanged(address indexed oldSeller, address indexed newSeller);

    modifier onlyUnlocked() {
        if (!isOwner(msg.sender) && locked) throw;
        _;
    }

    function BsToken(string _name, string _symbol, uint256 _totalSupply, address _seller) MultiOwnable() {
        // Lock the transfer function during the presale/crowdsale.
        locked = true;

        creator = msg.sender;
        seller = _seller;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;

        balances[seller] = totalSupply;
    }

    function changeSeller(address newSeller) onlyOwner returns (bool) {
        if (newSeller == 0x0 || seller == newSeller) throw;

        address oldSeller = seller;

        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = safeAdd(balances[newSeller], unsoldTokens);

        seller = newSeller;
        SellerChanged(oldSeller, newSeller);
        return true;
    }

    function sell(address _to, uint256 _value) onlyOwner returns (bool) {
        if (balances[seller] >= _value && _value > 0) {
            balances[seller] = safeSub(balances[seller], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            tokensSold = safeAdd(tokensSold, _value);
            totalSales = safeAdd(totalSales, 1);
            Sell(seller, _to, _value);
            Transfer(seller, _to, _value);
            return true;
        } else return false;
    }

    function transfer(address _to, uint256 _value) onlyUnlocked returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyUnlocked returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function lock() onlyOwner {
        locked = true;
    }

    function unlock() onlyOwner {
        locked = false;
    }

    function burn(uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value) ;
            totalSupply = safeSub(totalSupply, _value);
            Transfer(msg.sender, 0x0, _value);
            return true;
        } else return false;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value) {
        TokenSpender spender = TokenSpender(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value);
        }
    }
}

contract BsToken_STN is BsToken {

    function BsToken_STN()
        BsToken(
            &#39;SToken&#39;,
            &#39;STN&#39;,
            20000000,
            0xbEC7599FA247E3ABb423A76e74a7D4E575F559c3
        ) { }
}