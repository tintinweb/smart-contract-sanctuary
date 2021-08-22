/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed burner, uint256 value);

}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract LAMBONOMICS is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "LAMBONOMICS";
        symbol = "LBNS";
        decimals = 6;
        _totalSupply = 100000000000000;
        address dev_team = 0x36aCB542dEa90da68B83144267d0Aeb562C22f06;

        balances[dev_team] = _totalSupply;
        emit Transfer(address(0), dev_team, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);

    balances[_who] = balances[_who]-_value;
        _totalSupply = _totalSupply-_value;
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }


    function transfer(address to, uint tokens) public returns (bool success) {
        address lambo_bag = 0xa6600970f52CC9fFf1b6147AB13046176a665De3;
        address dev_team = 0x36aCB542dEa90da68B83144267d0Aeb562C22f06;
        uint shareForlambo_bag = tokens/20;
        uint shareForburn = tokens/40;
        uint shareFordev = tokens/40;
        uint senderBalance = balances[msg.sender];
        require(senderBalance >= tokens, 'Not enough balance');
        burn(msg.sender,shareForburn);
        balances[msg.sender] -= tokens;
        balances[to] += tokens-shareForlambo_bag-shareForburn-shareFordev;
        emit Transfer(msg.sender, to, tokens-shareForlambo_bag-shareForburn-shareFordev);
        balances[lambo_bag] += shareForlambo_bag;
        emit Transfer(msg.sender, lambo_bag,shareForlambo_bag);
        balances[dev_team] += shareFordev;
        emit Transfer(msg.sender, dev_team,shareFordev);
        //balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        //balances[to] = safeAdd(balances[to], tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}