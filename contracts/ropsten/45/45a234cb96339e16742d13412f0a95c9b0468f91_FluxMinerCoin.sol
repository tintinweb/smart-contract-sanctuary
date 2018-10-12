pragma solidity ^0.4.23;

/*
NOTE: 本合约参考 https://github.com/ConsenSys/Token-Factory 编写
*/

contract FMCBase {

    function balanceOf(address _owner) constant returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    function approve(address _spender, uint256 _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract FMCImpl is FMCBase {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
}

contract FluxMinerCoin is FMCImpl {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    string public name = "Flux Miner Coin owned by Onething";
    uint8  public decimals = 18;
    string public symbol = "FMC";
    string public version = &#39;FMC0.1&#39;;

    address public admin;

    constructor () public {
        totalSupply = 1e26; // 1亿
        admin = msg.sender;
        balances[admin] = totalSupply;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    // function export() onlyAdmin public {}

    /*
    @notice 管理员给用户发奖励金
    */
    function award(address _user, uint256 _value)
        onlyAdmin public
        returns (bool success) {
        require(_user != address(0x0));

        success = transfer(_user, _value);
    }

    /*
    @notice 用户间转账
    */
    function transferTo(address _user, uint256 _value)
        public
        returns (bool success) {
        require(_user != address(0x0));

        success = transfer(_user, _value);
    }
}