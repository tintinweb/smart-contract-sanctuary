pragma solidity ^0.4.16;

contract owned {
    address public owner;
    address public manager;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function setManager(address newManager) onlyOwner public {
        manager = newManager;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    string public name = "Robot Trading Token";
    string public detail = "Robot Trading token ERC20";
    string public symbol ="RTD";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    address public owner;
    address[] public owners;

    mapping (address => bool) ownerAppended;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event AirDropCoin(address target, uint256 token, uint256 rate, uint256 amount);
    event AirDropToken(address token_address, address target, uint256 token, uint256 rate, uint256 amount);

    constructor() public {}

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getOwner(uint index) public view returns (address, uint256) {
        return (owners[index], balanceOf[owners[index]]);
    }

    function getOwnerCount() public view returns (uint) {
        return owners.length;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        if(!ownerAppended[_to]) {
            ownerAppended[_to] = true;
            owners.push(_to);
        }

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}

contract Coin{
  function transfer(address to, uint value) public returns (bool);
}

contract Token is owned, TokenERC20 {
    address public ico_address;
    address public old_address;
    address public app_address;

    constructor() public {
        owner = msg.sender;
    }

    function setDetail(string tokenDetail) onlyOwner public {
        detail = tokenDetail;
    }

    function() payable public {}

    function setApp(address _app_address) onlyOwner public {
        app_address = _app_address;
    }

    function importFromOld(address _ico_address, address _old_address, address[] _to, uint256[] _value) onlyOwner public {
        ico_address = _ico_address;
        old_address = _old_address;
        for (uint256 i = 0; i < _to.length; i++) {
            balanceOf[_to[i]] += _value[i] * 10 ** uint256(12);
            totalSupply += _value[i] * 10 ** uint256(12);
            if(!ownerAppended[_to[i]]) {
                ownerAppended[_to[i]] = true;
                owners.push(_to[i]);
            }
            emit Transfer(old_address, _to[i], _value[i] * 10 ** uint256(12));
        }
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;

        if(!ownerAppended[target]) {
            ownerAppended[target] = true;
            owners.push(target);
        }

        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function withdrawEther() onlyOwner public {
        manager.transfer(address(this).balance);
    }

    function withdrawToken(address _tokenAddr,uint256 _value) onlyOwner public {
        assert(Coin(_tokenAddr).transfer(owner, _value) == true);
    }

    function airDropCoin(uint256 _value)  onlyOwner public {
        for (uint256 i = 0; i < owners.length; i++) {
            address(owners[i]).transfer(balanceOf[owners[i]]/_value);
            emit AirDropCoin(address(owners[i]), balanceOf[owners[i]], _value, (balanceOf[owners[i]]/_value));
        }
    }

    function airDropToken(address _tokenAddr,uint256 _value)  onlyOwner public {
        for (uint256 i = 0; i < owners.length; i++) {
             assert((Coin(_tokenAddr).transfer(address(owners[i]), balanceOf[owners[i]] / _value)) == true);
             emit AirDropToken(address(_tokenAddr), address(owners[i]), balanceOf[owners[i]], _value, (balanceOf[owners[i]]/_value));
        }
    }
}