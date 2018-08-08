pragma solidity ^0.4.18;

contract ERC20Interface {

    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20 is ERC20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public name;
    uint8 public decimals;
    string public symbol;

    function ERC20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
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

contract EtherZaarFactory {

    mapping(address => address[]) public created;
    mapping(address => bool) public isERC20;
    bytes public ERC20ByteCode;

    function EtherZaarFactory() public {
        address verifiedToken = createERC20(100, "Verification Tokens", 0, "EtherZaar");
        ERC20ByteCode = codeAt(verifiedToken);
    }

    function verifyERC20(address _tokenContract) public view returns (bool) {
        bytes memory fetchedTokenByteCode = codeAt(_tokenContract);

        if (fetchedTokenByteCode.length != ERC20ByteCode.length) {
            return false;
        }

        for (uint i = 0; i < fetchedTokenByteCode.length; i++) {
            if (fetchedTokenByteCode[i] != ERC20ByteCode[i]) {
                return false;
            }
        }
        return true;
    }
    
    function createERC20(uint256 _initialAmount, string _name, uint8 _decimals, string _symbol) 
        public 
    returns (address) {

        ERC20 newToken = (new ERC20(_initialAmount, _name, _decimals, _symbol));
        created[msg.sender].push(address(newToken));
        isERC20[address(newToken)] = true;
        newToken.transfer(msg.sender, _initialAmount); 
        return address(newToken);
    }

    function codeAt(address _addr) internal view returns (bytes outputCode) {
        assembly { 
            let size := extcodesize(_addr)
            outputCode := mload(0x40)
            mstore(0x40, add(outputCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(outputCode, size)
            extcodecopy(_addr, add(outputCode, 0x20), 0, size)
        }
    }
}