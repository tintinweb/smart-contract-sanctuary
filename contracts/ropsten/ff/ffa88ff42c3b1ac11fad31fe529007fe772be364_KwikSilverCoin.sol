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

    // Keeping track of inputs for every block results in gas costs that are too high
    // We instead keep track of inputs for groups of blockGroupSize blocks
    uint blockGroupSize = 5;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // For each address, this keeps track of how many tokens were received during each block group
    mapping(address => mapping(uint => uint)) inputs;

    constructor() public {
        symbol = "KWIK";
        name = "KwikSilverCoin";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[0x671446f120539cBBa92655082c881f18BF334001] = _totalSupply;
        inputs[0x671446f120539cBBa92655082c881f18BF334001][block.number/blockGroupSize] = _totalSupply;
        emit Transfer(address(0), 0x671446f120539cBBa92655082c881f18BF334001, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);

        // Do some work to increase the gas cost
        busyWork(msg.sender, _value);

        // Standard transfer
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        inputs[_to][block.number] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);

        busyWork(msg.sender, _value);

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

    function busyWork(address sender, uint amount) private returns (bool success) {
        // Start from the current block and find unspent inputs until we have enough for the transaction amount
        // The further back the last input is, the more gas is needed to spend it, since this loop will go longer
        uint totalInput = 0;
        uint blockGroupNum = block.number / blockGroupSize;
        while (totalInput < amount) {
            // Count the input amount at this block
            totalInput += inputs[msg.sender][blockGroupNum];
            // Remove the input, or if we have more than enough, remove the amount used
            if (totalInput <= amount) {
                inputs[sender][blockGroupNum] = 0;
            } else {
                inputs[sender][blockGroupNum] = totalInput - amount;
            }
            blockGroupNum--;
        }
    }
}