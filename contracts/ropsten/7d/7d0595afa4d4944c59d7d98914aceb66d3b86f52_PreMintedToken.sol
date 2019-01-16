pragma solidity ^0.4.24;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function mul(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(y != 0);
        uint256 z = x / y;
        assert(x == y * z + x % y);
        return z;
    }
}


/// @title NRC1 receiver interface
contract NRC1Receiver { 
    /// @dev Standard NRC1 function that will handle incoming token transfers.
    /// @param from Token sender address.
    /// @param amount Amount of tokens.
    /// @param data Transaction metadata.
    function tokenFallback(address from, uint amount, bytes data) external;
}






/// @title NRC1 interface
contract NRC1 {
    // Contract should also define the following constants with your token&#39;s metadata:
    // string public constant name = "Your Token Name";
    // string public constant symbol = "SYM";
    // uint8 public constant decimals = 18;

    uint256 internal _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 amount, bytes data);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @return Total supply of tokens.
    function totalSupply() public view returns (uint256 supply) {
        return _totalSupply;
    }

    /// @dev Gets the balance of the specified address.
    /// @param owner Address to query the the balance of.
    /// @return Balance of the owner.
    function balanceOf(address owner) public view returns (uint256 balance);

    /// @dev Gets the approved amount between the owner and spender.
    /// @param owner Address of the approver.
    /// @param spender Address of the approvee.
    function allowance(address owner, address spender) public view returns (uint256 remaining);

    /// @dev Transfer tokens to a specified address.
    /// @param to The address to transfer to.
    /// @param amount The amount to be transferred.
    /// @return Transfer successful or not.
    function transfer(address to, uint256 amount) public returns (bool success);

    /// @dev Transfer tokens to a specified address with data. A receiver who is a contract must implement the NRC1Receiver interface.
    /// @param to The address to transfer to.
    /// @param amount The amount to be transferred.
    /// @param data Transaction metadata.
    /// @return Transfer successful or not.
    function transfer(address to, uint256 amount, bytes data) public returns (bool success);

    /// @dev Approves the spender to be able to withdraw up to the amount.
    /// @param spender Address of spender.
    /// @param amount Allowed amount the spender may transfer up to.
    /// @return Approve successful or not.
    function approve(address spender, uint256 amount) public returns (bool success);

    /// @dev Transfer tokens for a previously approved amount.
    /// @param from Address which tokens will be transferred from.
    /// @param to Address which tokens will be transferred to.
    /// @param amount Amount of tokens to be transferred.
    /// @return Transfer successful or not.
    function transferFrom(address from, address to, uint256 amount) public returns (bool success);
}




contract StandardToken is NRC1 {
    using SafeMath for uint256;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowed;

    modifier validAddress(address _address) {
        require(_address != address(0), "Requires valid address.");
        _;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 amount) public validAddress(to) returns (bool success) {
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[to] = _balances[to].add(amount);

        bytes memory empty;
        emit Transfer(msg.sender, to, amount, empty);
        return true;
    }

    function transfer(address to, uint256 amount, bytes data) public validAddress(to) returns (bool success) {
        uint codeLength;
        assembly {
            // Retrieve the size of the code on target address, this needs assembly
            codeLength := extcodesize(to)
        }

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[to] = _balances[to].add(amount);

        // Call tokenFallback() if &#39;to&#39; is a contract. Rejects if not implemented.
        if (codeLength > 0) {
            NRC1Receiver(to).tokenFallback(msg.sender, amount, data);
        }

        emit Transfer(msg.sender, to, amount, data);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        // To change the approve amount you first have to reduce the addresses&#39;
        //  allowance to zero by calling `approve(spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((amount == 0) || (_allowed[msg.sender][spender] == 0), "Requires amount to be 0 or current allowance to be 0");

        _allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public validAddress(to) returns (bool success) {
        uint256 _allowance = _allowed[from][msg.sender];
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        _allowed[from][msg.sender] = _allowance.sub(amount);

        bytes memory empty;
        emit Transfer(from, to, amount, empty);
        return true;
    }
}


contract PreMintedToken is StandardToken {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Creates the token and mints the entire token supply to the owner.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param decimals Decimals of the token.
     * @param totalSupply Total supply of all the tokens.
     * @param owner Owner of all the tokens.
     */
    constructor(
        string name,
        string symbol,
        uint8 decimals,
        uint256 totalSupply,
        address owner)
        public
        validAddress(owner)
    {
        require(bytes(name).length > 0, "name cannot be empty.");
        require(bytes(symbol).length > 0, "symbol cannot be empty.");
        require(totalSupply > 0, "totalSupply must be greater than 0.");

        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply;
        _balances[owner] = totalSupply;
    }

    /// @return Name of the token.
    function name() public view returns (string) {
        return _name;
    }

    /// @return Symbol of the token.
    function symbol() public view returns (string) {
        return _symbol;
    }

    /// @return Decimals of the token.
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}