pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "this action is only for owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

pragma solidity ^0.4.21;

import "./Lib.sol";

contract ERC20Interface {
    uint256 public totalSupply;
    bool public allowTransfer;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(uint256 _value);
}

// Contract function to receive approval and execute function in one call
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract StandardToken is ERC20Interface {
    using SafeMath for uint256;

    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        require(allowTransfer);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool success) {
        require(allowTransfer);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(allowTransfer && !((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
}


contract Token is StandardToken {

    string public name = "GAMBLR.ONE";
    uint256 public decimals = 18;
    string public symbol = "GAMBLR";
    string public version = '1.1';
    address public mintableAddress;

    constructor(address sale_address) public {
        balances[msg.sender] = 0;
        totalSupply = 0;
        name = name;
        decimals = decimals;
        symbol = symbol;
        mintableAddress = sale_address;
        allowTransfer = true;
        createTokens();
    }

    function createTokens() internal {
        uint256 total = 100000000000000000000000000; //100M
        balances[this] = total;
        totalSupply = total;
    }

    function changeTransfer(bool allowed) external {
        require(msg.sender == mintableAddress);
        allowTransfer = allowed;
    }

    function mintToken(address to, uint256 amount) external returns (bool success) {
        require(msg.sender == mintableAddress);
        require(balances[this] >= amount);
        balances[this] -= amount;
        balances[to] += amount;
        emit Transfer(this, to, amount);
        return true;
    }

    function getTotalSupply() view returns (uint256 supply) {
        return totalSupply;
    }

    function burnUnused(uint256 _amount) external {
        require(msg.sender == mintableAddress, "Action restricted");
        require(balances[this] >= _amount, "Amount to burn is too big");
        balances[this] = balances[this] - _amount;
        totalSupply = totalSupply - _amount;
        emit Burned(_amount);
    }

    function() external payable {
        revert();
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

}