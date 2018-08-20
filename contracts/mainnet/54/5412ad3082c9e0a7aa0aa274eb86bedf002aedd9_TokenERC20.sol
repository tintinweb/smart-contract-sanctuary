pragma solidity ^0.4.24;

interface tokenRecipient {
    function receiveApproval(address _from, uint _value, address _token, bytes _extraData) external;
}

contract owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner public returns (bool success) {
        newOwner = _newOwner;
        return true;
    }

    function acceptOwnership() public returns (bool success) {
        require(msg.sender == newOwner);
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
        newOwner = address(0);
        return true;
    }
}

contract TokenERC20 is owned {
    string public name = &#39;Telex&#39;;
    string public symbol = &#39;TLX&#39;;
    uint8 public decimals = 8;
    uint public totalSupply = 2000000000000000;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => bool) public frozenAccount;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event FrozenFunds(address indexed target, bool frozen);

    constructor() TokenERC20() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        if (msg.sender != owner) {
          require(!frozenAccount[msg.sender]);
          require(!frozenAccount[_from]);
          require(!frozenAccount[_to]);
        }
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function _multipleTransfer(address _from, address[] addresses, uint[] amounts) internal {
        for (uint i=0; i<addresses.length; i++) {
            address _to = addresses[i];
            uint _value = amounts[i];
            _transfer(_from, _to, _value);
        }
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function multipleTransfer(address[] addresses, uint[] amounts) public returns (bool success) {
        _multipleTransfer(msg.sender, addresses, amounts);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        if (msg.sender != owner) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function freezeAccount(address target, bool freeze) onlyOwner public returns (bool success) {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
        return true;
    }
}