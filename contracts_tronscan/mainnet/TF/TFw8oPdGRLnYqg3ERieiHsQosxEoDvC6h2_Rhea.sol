//SourceUnit: Rhea.sol

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.5.10;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint c = a / b;

        return c;
    }
}

contract TRC20 {
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint);
    function approve(address spender, uint value) public returns (bool);
    function burn(uint value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint value);
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "address is null");
        owner = newOwner;
    }
}

contract StandardToken is TRC20 {
    using SafeMath for uint;

    uint public totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) internal allowed;
    
    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender], "Insufficient allowed");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

    function burn(uint _value) public returns (bool) {
        require(_value <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        require(_from != address(0), "Address is null");
        require(_to != address(0), "Address is null");
        require(_value <= balances[_from], "Insufficient balance");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract Rhea is StandardToken, Ownable {
    string  public name;
    string  public symbol;
    uint    public decimals;

    // the max levels of each tower
    uint constant MAX_LEVELS = 212;
    // start token num of the first level for each tower
    uint constant START_TOKEN = 225000 trx;
    // the start token price
    uint constant START_PRICE = 2 trx;

    uint curr_tower;
    uint curr_level;
    uint curr_price;
    uint curr_token;
    uint curr_remain_token;

    uint total_trx;
    uint total_token;
    uint total_user_count;

    address public mining_pool;
    address team_funds1;
    address team_funds2;
    address team_funds3;
    address team_funds4;

    mapping(address => bool) users;
    
    constructor(string memory _name, string memory _symbol, address _team_funds1, address _team_funds2, address _team_funds3, address _team_funds4) public {
        name = _name;
        symbol = _symbol;
        decimals = 6;
        totalSupply = 2100000000 * (10 ** decimals);
        balances[address(this)] = totalSupply;

        team_funds1 = _team_funds1;
        team_funds2 = _team_funds2;
        team_funds3 = _team_funds3;
        team_funds4 = _team_funds4;

        curr_tower = 1;
        curr_level = 1;
        curr_token = START_TOKEN;
        curr_price = START_PRICE;
        curr_remain_token = START_TOKEN;
    }

    function set_mining_pool(address _mining_pool) public onlyOwner returns (bool){
        require(_mining_pool != address(0));
        mining_pool = _mining_pool;
        return true;
    }

    function exchange() public payable returns (bool){
        require(msg.value >= 200 trx, "A minimum of 200 TRX to exchange");
        require(mining_pool != address(0), "Not yet set mining pool");
        uint amount = msg.value;
        uint exchange_token;
        uint remain_amount = amount;

        while(true){
            uint taked_token = remain_amount.mul(1 trx).div(curr_price);

            // current level token not enough
            if(taked_token >= curr_remain_token){
                // exchange next level or next tower level
                // pay 6.8% bonus to project team for each level completed 
                uint bonus = curr_token.mul(68).div(1000); // 6.8%
                total_token = total_token.add(bonus);
                _transfer(address(this), team_funds1, bonus.mul(40).div(100));
                _transfer(address(this), team_funds2, bonus.mul(20).div(100));
                _transfer(address(this), team_funds3, bonus.mul(20).div(100));
                _transfer(address(this), team_funds4, bonus.mul(20).div(100));

                uint _curr_price = curr_price;
                uint _curr_remain_token = curr_remain_token;
                
                // setting next level data
                setting_next_level_data();
                
                uint taked_amount = _curr_remain_token.mul(_curr_price).div(1 trx);
                if(taked_token == _curr_remain_token || taked_amount >= remain_amount){
                    exchange_token = exchange_token.add(taked_token);
                    break;
                } else {
                    // calc remain amount
                    exchange_token = exchange_token.add(_curr_remain_token);
                    remain_amount = remain_amount.sub(taked_amount);
                }
            } else {
                exchange_token = exchange_token.add(taked_token);
                curr_remain_token = curr_remain_token.sub(taked_token);
                break;
            }
        }

        if(users[msg.sender] == false){
            // count new user
            users[msg.sender] = true;
            total_user_count = total_user_count.add(1);
        }

        total_trx = total_trx.add(amount);
        total_token = total_token.add(exchange_token);

        _transfer(address(this), msg.sender, exchange_token);
        address(uint160(mining_pool)).transfer(amount);

        return true;
    }

    function query_account(address addr)public view returns(bool, uint, uint) {
        return (users[addr], balances[addr], addr.balance);
    }

    function query_summary() public view returns(uint, uint, uint) {
        return (total_user_count, total_trx, total_token);
    }

    function query_current() public view returns(uint, uint, uint, uint, uint) {
        return (curr_tower, curr_level, curr_price, curr_token, curr_remain_token);
    }

    function query_price() public view returns(uint) {
        return curr_price;
    }
    function query_tower() public view returns(uint) {
        return curr_tower;
    }

    function setting_next_level_data() private {
        uint _token;
        uint _price;

        if(curr_level == MAX_LEVELS){
            // next tower
            curr_tower = curr_tower.add(1);
            curr_level = 1;

            // first level with start token
            _token = START_TOKEN;
            // token price of first level equals previous tower with max level
            _price = curr_price;
        } else {
            // next level
            curr_level = curr_level.add(1);

            _token = curr_token.sub(curr_token.mul(2).div(1000)); // token -0.2% each level
            _price = curr_price.add(curr_price.mul(2).div(1000)); // price +0.2% each level
        }

        // init next level or next tower level data
        curr_price = _price;
        curr_token = _token;
        curr_remain_token = _token;
    }
}