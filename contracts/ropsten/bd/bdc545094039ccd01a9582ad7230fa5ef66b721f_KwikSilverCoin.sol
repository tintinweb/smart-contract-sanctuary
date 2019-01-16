pragma solidity ^0.5.0;

// ERC-20 standard interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract KwikSilverCoin is ERC20Interface {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public _totalSupply;
    uint256 constant private MAX_UINT256 = 2**256 - 1;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // For each address, this keeps track of how many tokens were received during each block
    mapping(address => mapping(uint => uint)) inputs;

    constructor() public {
        symbol = "KWIK";
        name = "KwikSilverCoin";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[0x671446f120539cBBa92655082c881f18BF334001] = _totalSupply;
        emit Transfer(address(0), 0x671446f120539cBBa92655082c881f18BF334001, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply; // TODO: check this
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);

        // Start from the current block and find unspent inputs until we have enough for the transaction amount
        // Each iteration, we do some busy work
        // This way, you will need to spend more gas to spend older tokens
        uint totalInput = 0;
        uint blockNum = block.number;
        while (totalInput != _value) {
            // Count the input amount at this block
            totalInput += inputs[msg.sender][blockNum];
            if (totalInput <= _value) {
                inputs[msg.sender][blockNum] = 0;
            } else {
                inputs[msg.sender][blockNum] = totalInput - _value; // TODO: double check this logic
            }
            blockNum--;

            // TODO: Add busy work
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        inputs[_to][block.number] += _value; ////////
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}