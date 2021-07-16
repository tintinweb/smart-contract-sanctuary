//SourceUnit: heba.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.12;

contract TRC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining);

    function burn(uint256 _value)
        public
        returns (bool success);

    function burnFrom(address _from, uint256 _value)
        public
        returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

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

contract TokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes memory _extraData
    ) public;
}

contract TRC20Token is TRC20Interface, Owned {
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowed;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= _allowed[_from][msg.sender]);
        _allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowed[_owner][_spender];
    }

    function transferAnyTRC20Token(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return TRC20Interface(tokenAddress).transfer(owner, tokens);
    }

    /**
  Approves and then calls the receiving contract
   */
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        approve(_spender, _value);
        spender.receiveApproval(msg.sender, _value, address(this), _extraData);
        return true;
    }

    /**
  Destroy tokens.
  Remove `_value` tokens from the system irreversibly
    */
    function burn(uint256 _value) public returns (bool success) {
        require(_balances[msg.sender] >= _value);
        _balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
  Destroy tokens from other account.
  Remove `_value` tokens from the system irreversibly on behalf of `_from`.
    */
    function burnFrom(address _from, uint256 _value)
        public
        returns (bool success)
    {
        require(_balances[_from] >= _value);
        require(_value <= _allowed[_from][msg.sender]);
        _balances[_from] -= _value;
        _allowed[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

    /**
  Internal transfer, only can be called by this contract
    */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(_balances[_from] >= _value);
        // Check for overflows
        require(_balances[_to] + _value > _balances[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = _balances[_from] + _balances[_to];
        // Subtract from the sender
        _balances[_from] -= _value;
        // Add the same to the recipient
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(_balances[_from] + _balances[_to] == previousBalances);
    }
}

contract HEBA is TRC20Token {
    constructor() public {
        initialSupply = 7000000000;
        name = "HEBA";
        symbol = "HEBA";
        decimals = 8;
        totalSupply = initialSupply * 10**uint256(decimals);
        _balances[msg.sender] = totalSupply;
    }
}