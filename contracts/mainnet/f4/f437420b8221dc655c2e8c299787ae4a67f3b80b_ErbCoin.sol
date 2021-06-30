pragma solidity ^0.5.7;

import './safemath.sol';

contract ErbCoin {
    using SafeMath for uint256;

    string constant public name = "INST Coin";      //  token name
    string constant public symbol = "INST";           //  token symbol
    uint256 public decimals = 18;            //  token digit

    //mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance; //a授权给b表示b可转账给其他人的代币数
    mapping (address => uint256) public frozenBalances; //冻结余额
    mapping (address => uint256) public balances; //可操作余额

    uint256 public totalSupply = 0;
    bool public stopped = false;

    //uint256 constant valueFounder = 1000000;
    address constant zeroaddr = address(0);
    address owner = zeroaddr;   //合约所有者
    address founder = zeroaddr; //初始代币持有者

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isFounder {
        assert(founder == msg.sender);
        _;
    }

    modifier isAdmin {
        assert(owner == msg.sender || founder == msg.sender);
        _;
    }

    modifier isRunning {
        assert (!stopped);
        _;
    }

    modifier validAddress {
        assert(zeroaddr != msg.sender);
        _;
    }

    constructor(address _addressFounder,uint256 _valueFounder) public {
        owner = msg.sender;
        founder = _addressFounder;
        totalSupply = _valueFounder*10**decimals;
        balances[founder] = totalSupply;
        emit Transfer(zeroaddr, founder, totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        //账户余额 = 可操作余额 + 被冻结余额
        return balances[_owner] + frozenBalances[_owner];
    }

    function transfer(address _to, uint256 _value) public isRunning validAddress returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    //msg.sender 将 _from 授权给他（msg.sender）的代币转给 _to
    function transferFrom(address _from, address _to, uint256 _value) public isRunning validAddress returns (bool success) {
        balances[_from] = balances[_from].sub(_value);
        //balances[_to] = balances[_to].add(_value);
        frozenBalances[_to] = frozenBalances[_to].add(_value); //代币为冻结状态
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit TransferFrozen(_to, _value);
        return true;
    }

    //msg.sender 授权 _spender 可操作代币数
    function approve(address _spender, uint256 _value) public isRunning isFounder returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0,"illegal operation");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //冻结部分释放
    function release(address _target, uint256 _value) public isRunning isAdmin returns(bool){
        frozenBalances[_target] = frozenBalances[_target].sub(_value);
        balances[_target] = balances[_target].add(_value);
        emit Release(_target, _value);
        return true;
    }

    function stop() public isAdmin {
        stopped = true;
    }

    function start() public isAdmin {
        stopped = false;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TransferFrozen(address _target, uint256 _value);
    event Release(address _target, uint256 _value);
}