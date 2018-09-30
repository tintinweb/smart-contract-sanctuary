pragma solidity ^0.4.25;

contract ECToken {
    string public constant tokenName = "大象链";
    string public constant tokenSymbol = "EC";
    uint8 public constant tokenDecimals = 8;
    uint256 public tokenTotalSupply = 21000000 * 10 ** uint256(tokenDecimals);

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) public balanceOf;
    
    constructor () public {
        balanceOf[msg.sender] = tokenTotalSupply;
    }
    
    address public owner;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    function owner() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public returns (bool success) {
        if (newOwner > address(0)) {
            owner = newOwner;
            return true;
        } else {
            return false;
        }
        
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (_to != address(0) && _value > 0) {
            _transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function freezeAccount(address target) onlyOwner public returns(bool success) {
        if (target != address(0)) {
            frozenAccount[target] = true;
            emit FrozenFunds(target, true);
            return true;
        } else {
            return false;
        }
    }

    function unfreezeAccount(address target) onlyOwner public returns(bool success) {
        if (target != address(0)) {
            frozenAccount[target] = false;
            emit FrozenFunds(target, false);
            return true;
        } else {
            return false;
        }
    }

    function increaseSupply(uint256 _value, address _owner) onlyOwner public returns(bool success) {
        if (_value > 0) {
            tokenTotalSupply = tokenTotalSupply + _value;
            balanceOf[_owner] = balanceOf[_owner] + _value;
            _transfer(msg.sender, _owner, _value);
            return true;
        } else {
            return false;
        }   
    }

    function decreaseSupply(uint256 _value, address _owner) onlyOwner public returns(bool success) {
        if (_value > 0 && balanceOf[_owner] > _value) {
            balanceOf[_owner] = balanceOf[_owner] + _value;
            tokenTotalSupply = tokenTotalSupply - _value;
            _transfer(_owner, msg.sender, _value);
            return true;
        } else {
            return false;
        } 
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(_value > 0);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
}