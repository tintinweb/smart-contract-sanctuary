pragma solidity ^0.4.19;

/* taking ideas from OpenZeppelin, thanks*/
contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSub(uint256 x, uint256 y) internal pure returns (uint256) {
        assert(x >= y);
        return x - y;
    }
}

contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/* ERC 20 token */
contract StandardToken is Token, SafeMath {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) allowed;

    // prvent from the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool success) {
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract XCTToken is StandardToken {
    //meta data
    string public constant name = "XChain Token";
    string public constant symbol = "NXCT";
    uint8 public constant decimals = 18;

    function XCTToken() public {
        // 3.2b Coins in total, destroyed 130m, left 3.07b
        totalSupply = 307 * 10**25;
        balances[msg.sender] = totalSupply;
    }
}