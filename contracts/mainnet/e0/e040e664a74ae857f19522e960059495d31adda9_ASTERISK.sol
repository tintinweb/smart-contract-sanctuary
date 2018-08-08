pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _new_owner) onlyOwner public returns (bool _success) {
        require(_new_owner != address(0));

        owner = _new_owner;

        emit OwnershipTransferred(owner, _new_owner);

        return true;
    }
}

contract Pausable is Ownable {
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    function setPauseStatus(bool _pause) onlyOwner public returns (bool _success) {
        paused = _pause;
        return true;
    }
}

contract ERC223 {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool _success);
    function transfer(address to, uint value, bytes data) public returns (bool _success);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);

    function totalSupply() public view returns (uint256 _totalSupply);
    function transfer(address to, uint value, bytes data, string customFallback) public returns (bool _success);

    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success);
    function approve(address _spender, uint256 _value) public returns (bool _success);
    function allowance(address _owner, address _spender) public view returns (uint256 _remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ContractReceiver {
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);
    }
}

contract ASTERISK is ERC223, Pausable {
    using SafeMath for uint256;

    string public name = "asterisk";
    string public symbol = "ASTER";
    uint8 public decimals = 9;
    uint256 public totalSupply = 10e9 * 1e9;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozenAccount;

    event Freeze(address indexed target, uint256 value);
    event Unfreeze(address indexed target, uint256 value);
    event Burn(address indexed from, uint256 amount);
    event Rain(address indexed from, uint256 amount);


    struct ITEM {
        uint256 id;
        address owner;
        mapping(address => uint256) holders;
        string name;
        uint256 price;
        uint256 itemTotalSupply;
        bool transferable;
        bool approveForAll;
        string option;
        uint256 limitHolding;
    }

    struct ALLOWANCEITEM {
        uint256 amount;
        uint256 price;
    }

    mapping(uint256 => ITEM) public items;

    uint256 public itemId = 1;

    mapping(address => mapping(address => mapping(uint256 => ALLOWANCEITEM))) public allowanceItems;

    constructor() public {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    modifier messageSenderNotFrozen() {
        require(frozenAccount[msg.sender] == false);
        _;
    }

    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return balanceOf[_owner];
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) messageSenderNotFrozen whenNotPaused public returns (bool _success) {
        require(_value > 0 && frozenAccount[_to] == false);

        if (isContract(_to)) {
            require(balanceOf[msg.sender] >= _value);

            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);

            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));

            emit Transfer(msg.sender, _to, _value, _data);
            emit Transfer(msg.sender, _to, _value);

            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint _value, bytes _data) messageSenderNotFrozen whenNotPaused public returns (bool _success) {
        require(_value > 0 && frozenAccount[_to] == false);

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint _value) messageSenderNotFrozen whenNotPaused public returns (bool _success) {
        require(_value > 0 && frozenAccount[_to] == false);

        bytes memory empty;

        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    function name() public view returns (string _name) {
        return name;
    }

    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool _success) {
        require(_to != address(0)
            && _value > 0
            && balanceOf[_from] >= _value
            && allowance[_from][msg.sender] >= _value
            && frozenAccount[_from] == false && frozenAccount[_to] == false);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) whenNotPaused public returns (bool _success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 _remaining) {
        return allowance[_owner][_spender];
    }

    function freezeAccounts(address[] _targets) onlyOwner whenNotPaused public returns (bool _success) {
        require(_targets.length > 0);

        for (uint j = 0; j < _targets.length; j++) {
            require(_targets[j] != 0x0);

            frozenAccount[_targets[j]] = true;

            emit Freeze(_targets[j], balanceOf[_targets[j]]);
        }
        return true;
    }

    function unfreezeAccounts(address[] _targets) onlyOwner whenNotPaused public returns (bool _success) {
        require(_targets.length > 0);

        for (uint j = 0; j < _targets.length; j++) {
            require(_targets[j] != 0x0);

            frozenAccount[_targets[j]] = false;

            emit Unfreeze(_targets[j], balanceOf[_targets[j]]);
        }
        return true;
    }

    function isFrozenAccount(address _target) public view returns (bool _is_frozen){
        return frozenAccount[_target] == true;
    }

    function isContract(address _target) private view returns (bool _is_contract) {
        uint length;
        assembly {
            length := extcodesize(_target)
        }
        return (length > 0);
    }

    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool _success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferToContract(address _to, uint _value, bytes _data) private returns (bool _success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);

        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function burn(address _from, uint256 _amount) onlyOwner whenNotPaused public returns (bool _success) {
        require(_amount > 0 && balanceOf[_from] >= _amount);

        balanceOf[_from] = balanceOf[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Burn(_from, _amount);

        return true;
    }

    function rain(address[] _addresses, uint256 _amount) messageSenderNotFrozen whenNotPaused public returns (bool _success) {
        require(_amount > 0 && _addresses.length > 0);

        uint256 totalAmount = _amount.mul(_addresses.length);

        require(balanceOf[msg.sender] >= totalAmount);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);

        for (uint j = 0; j < _addresses.length; j++) {
            require(_addresses[j] != address(0));

            balanceOf[_addresses[j]] = balanceOf[_addresses[j]].add(_amount);

            emit Transfer(msg.sender, _addresses[j], _amount);
        }

        emit Rain(msg.sender, totalAmount);
        return true;
    }

    function collectTokens(address[] _addresses, uint[] _amounts) onlyOwner whenNotPaused public returns (bool _success) {
        require(_addresses.length > 0 && _amounts.length > 0
            && _addresses.length == _amounts.length);

        uint256 totalAmount = 0;

        for (uint j = 0; j < _addresses.length; j++) {
            require(_amounts[j] > 0 && _addresses[j] != address(0)
                && balanceOf[_addresses[j]] >= _amounts[j]);

            balanceOf[_addresses[j]] = balanceOf[_addresses[j]].sub(_amounts[j]);
            totalAmount = totalAmount.add(_amounts[j]);

            emit Transfer(_addresses[j], msg.sender, _amounts[j]);
        }

        balanceOf[msg.sender] = balanceOf[msg.sender].add(totalAmount);
        return true;
    }


    function createItemId() whenNotPaused private returns (uint256 _id) {
        return itemId++;
    }



    function createItem(string _name, uint256 _initial_amount, uint256 _price, bool _transferable, bool _approve_for_all, string _option, uint256 _limit_holding) messageSenderNotFrozen whenNotItemStopped whenNotPaused public returns (uint256 _id) {
        uint256 item_id = createItemId();
        ITEM memory i;
        i.id = item_id;
        i.owner = msg.sender;
        i.name = _name;
        i.price = _price;
        i.itemTotalSupply = _initial_amount;
        i.transferable = _transferable;
        i.approveForAll = _approve_for_all;
        i.option = _option;
        i.limitHolding = _limit_holding;
        items[item_id] = i;
        items[item_id].holders[msg.sender] = _initial_amount;
        return i.id;
    }


    function getItemAmountOf(uint256 _id, address _holder) whenNotItemStopped whenNotPaused public view returns (uint256 _amount) {
        return items[_id].holders[_holder];
    }


    function setItemOption(uint256 _id, string _option) messageSenderNotFrozen whenNotItemStopped whenNotPaused public returns (bool _success) {
        require(items[_id].owner == msg.sender);

        items[_id].option = _option;

        return true;
    }

    function setItemApproveForAll(uint256 _id, bool _approve_for_all) messageSenderNotFrozen whenNotItemStopped whenNotPaused public returns (bool _success) {
        require(items[_id].owner == msg.sender);

        items[_id].approveForAll = _approve_for_all;

        return true;
    }

    function setItemTransferable(uint256 _id, bool _transferable) messageSenderNotFrozen whenNotItemStopped whenNotPaused public returns (bool _success) {
        require(items[_id].owner == msg.sender);

        items[_id].transferable = _transferable;

        return true;
    }

    function setItemPrice(uint256 _id, uint256 _price) messageSenderNotFrozen whenNotItemStopped whenNotPaused public returns (bool _success) {
        require(items[_id].owner == msg.sender && _price >= 0);

        items[_id].price = _price;

        return true;
    }

    function setItemLimitHolding(uint256 _id, uint256 _limit) messageSenderNotFrozen whenNotItemStopped whenNotPaused public returns (bool _success) {
        require(items[_id].owner == msg.sender && _limit > 0);

        items[_id].limitHolding = _limit;

        return true;
    }

    function buyItem(uint256 _id, uint256 _amount) messageSenderNotFrozen whenNotItemStopped whenNotPaused public returns (bool _success) {
        require(items[_id].approveForAll
            && _amount > 0
            && items[_id].holders[items[_id].owner] >= _amount);

        uint256 afterAmount = items[_id].holders[msg.sender].add(_amount);

        require(items[_id].limitHolding >= afterAmount);

        uint256 value = items[_id].price.mul(_amount);

        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        items[_id].holders[items[_id].owner] = items[_id].holders[items[_id].owner].sub(_amount);
        items[_id].holders[msg.sender] = items[_id].holders[msg.sender].add(_amount);
        balanceOf[items[_id].owner] = balanceOf[items[_id].owner].add(value);

        return true;
    }

    function allowanceItem(uint256 _id, uint256 _amount, uint256 _price, address _to) messageSenderNotFrozen whenNotItemStopped whenNotPaused public returns (bool _success) {
        require(_amount > 0 && _price >= 0
            && _to != address(0)
            && items[_id].holders[msg.sender] >= _amount
            && items[_id].transferable);

        ALLOWANCEITEM memory a;
        a.price = _price;
        a.amount = _amount;
        allowanceItems[msg.sender][_to][_id] = a;

        return true;
    }

    function getItemAllowanceAmount(uint256 _id, address _from, address _to) whenNotItemStopped whenNotPaused public view returns (uint256 _amount) {
        return allowanceItems[_from][_to][_id].amount;
    }

    function getItemAllowancePrice(uint256 _id, address _from, address _to) whenNotItemStopped whenNotPaused public view returns (uint256 _price) {
        return allowanceItems[_from][_to][_id].price;
    }

    function transferItemFrom(uint256 _id, address _from, uint256 _amount, uint256 _price) messageSenderNotFrozen whenNotItemStopped whenNotPaused public returns (bool _success) {
        require(_amount > 0 && _price >= 0 && frozenAccount[_from] == false);

        uint256 value = _amount.mul(_price);

        require(allowanceItems[_from][msg.sender][_id].amount >= _amount
            && allowanceItems[_from][msg.sender][_id].price >= _price
            && balanceOf[msg.sender] >= value
            && items[_id].holders[_from] >= _amount
            && items[_id].transferable);

        uint256 afterAmount = items[_id].holders[msg.sender].add(_amount);

        require(items[_id].limitHolding >= afterAmount);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        allowanceItems[_from][msg.sender][_id].amount = allowanceItems[_from][msg.sender][_id].amount.sub(_amount);
        items[_id].holders[_from] = items[_id].holders[_from].sub(_amount);
        items[_id].holders[msg.sender] = items[_id].holders[msg.sender].add(_amount);
        balanceOf[_from] = balanceOf[_from].add(value);

        return true;
    }

    function transferItem(uint256 _id, address _to, uint256 _amount) messageSenderNotFrozen whenNotItemStopped whenNotPaused public returns (bool _success) {
        require(frozenAccount[_to] == false && _to != address(0)
            && _amount > 0 && items[_id].holders[msg.sender] >= _amount
            && items[_id].transferable);

        uint256 afterAmount = items[_id].holders[_to].add(_amount);

        require(items[_id].limitHolding >= afterAmount);

        items[_id].holders[msg.sender] = items[_id].holders[msg.sender].sub(_amount);
        items[_id].holders[_to] = items[_id].holders[_to].add(_amount);

        return true;
    }


    bool public isItemStopped = false;

    modifier whenNotItemStopped() {
        require(!isItemStopped);
        _;
    }

    function setItemStoppedStatus(bool _status) onlyOwner whenNotPaused public returns (bool _success) {
        isItemStopped = _status;
        return true;
    }

    function() payable public {}
}