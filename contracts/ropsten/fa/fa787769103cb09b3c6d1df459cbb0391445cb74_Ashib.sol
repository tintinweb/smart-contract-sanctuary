/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity 0.5.17;

contract Ashib {
    //initialize
    mapping(address=> uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalsupply = 100000000 * 10 ** 18;
    string public symbol = "Shibuae";
    string public name = "Ashib";
    uint public decimals = 18;
    event Burn (address indexed from, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Mint(address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    //balance array given a sender id
    constructor() public {
    balances[msg.sender] = totalsupply;
    }

    //burn mechanic
    function burn(address _who, uint256 _value) public returns (bool) {
        require(_value <= balances[_who]);
        totalsupply = totalsupply-_value;
        balances[ _who] = balances[ _who]-_value;
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
        return true;
    }

    // mint mechanic
    function mint(address _to, uint256 _amount) public returns (bool) {
        totalsupply = totalsupply+_amount;
        balances[_to] = balances[_to]+_amount;
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    //balance given
    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }

    //transfer functionality
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >=value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    //transfer functionality from
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}