pragma solidity ^0.4.18;


contract EIP20Interface {
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
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name  
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract EIP20 is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   
}

contract EIP20Factory {

    mapping(address => address[]) public created;
    mapping(address => bool) public isEIP20; //verify without having to do a bytecode check.
    bytes public EIP20ByteCode; // solhint-disable-line var-name-mixedcase  

    function EIP20Factory() public {
        //upon creation of the factory, deploy a EIP20 (parameters are meaningless) and store the bytecode provably.
        address verifiedToken = createEIP20(10000, "Verify Token", 3, "VTX");
        EIP20ByteCode = codeAt(verifiedToken);
    }

    //verifies if a contract that has been deployed is a Human Standard Token.
    //NOTE: This is a very expensive function, and should only be used in an eth_call. ~800k gas
    function verifyEIP20(address _tokenContract) public view returns (bool) {
        bytes memory fetchedTokenByteCode = codeAt(_tokenContract);

        if (fetchedTokenByteCode.length != EIP20ByteCode.length) {
            return false; //clear mismatch
        }

      //starting iterating through it if lengths match
        for (uint i = 0; i < fetchedTokenByteCode.length; i++) {
            if (fetchedTokenByteCode[i] != EIP20ByteCode[i]) {
                return false;
            }
        }
        return true;
    }
    
    function createEIP20(uint256 _initialAmount, string _name, uint8 _decimals, string _symbol) 
        public 
    returns (address) {

        EIP20 newToken = (new EIP20(_initialAmount, _name, _decimals, _symbol));
        created[msg.sender].push(address(newToken));
        isEIP20[address(newToken)] = true;
        //the factory will own the created tokens. You must transfer them.
        newToken.transfer(msg.sender, _initialAmount); 
        return address(newToken);
    }

    //for now, keeping this internal. Ideally there should also be a live version of this that 
    // any contract can use, lib-style.
    //retrieves the bytecode at a specific address.
    function codeAt(address _addr) internal view returns (bytes outputCode) {
        assembly { // solhint-disable-line no-inline-assembly   
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using outputCode = new bytes(size)
            outputCode := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(outputCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(outputCode, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(outputCode, 0x20), 0, size)
        }
    }
}