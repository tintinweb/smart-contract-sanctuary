pragma solidity 0.4.24;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract StandardToken is ERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) internal balances;
    mapping (address => mapping (address => uint)) internal allowed;

    constructor(string _name, string _symbol, uint8 _decimals, uint _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

}

/**
 * @title SwissBorg Referendum 2
 * @dev Hardcoded version with exactly 6 voting addresses.
 */
contract VotingToken is StandardToken, Owned {
    using SafeMath for uint;

    uint public constant numberOfAlternatives = 6;

    event Reward(address indexed to, uint amount);
    event Result(address indexed votingAddress, uint amount);

    ERC20 private rewardToken;

    bool public opened;
    bool public closed;

    address[numberOfAlternatives] public votingAddresses;

    // ~~~~~ Constructor ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    constructor(
        string _name,
        string _symbol,
        uint8 _decimals,
        ERC20 _rewardToken,
        address[numberOfAlternatives] _votingAddresses
    ) public StandardToken(_name, _symbol, _decimals, 0) {
        require(_votingAddresses.length == numberOfAlternatives);
        rewardToken = _rewardToken;
        votingAddresses = _votingAddresses;
    }

    // ~~~~~ Public Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    function transfer(address _to, uint _value) public returns (bool) {
        require(super.transfer(_to, _value));
        _rewardVote(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(super.transferFrom(_from, _to, _value));
        _rewardVote(_from, _to, _value);
        return true;
    }

    // Refuse ETH
    function () public payable {
        revert();
    }

    // ~~~~~ Admin Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    function mint(address _to, uint _amount) onlyOwner external returns (bool) {
        require(!opened);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function batchMint(address[] _tos, uint[] _amounts) onlyOwner external returns (bool) {
        require(!opened);
        require(_tos.length == _amounts.length);
        uint sum = 0;
        for (uint i = 0; i < _tos.length; i++) {
            address to = _tos[i];
            uint amount = _amounts[i];
            sum = sum.add(amount);
            balances[to] = balances[to].add(amount);
            emit Transfer(address(0), to, amount);
        }
        totalSupply = totalSupply.add(sum);
        return true;
    }

    function open() onlyOwner external {
        require(!opened);
        opened = true;
    }

    function close() onlyOwner external {
        require(opened && !closed);
        closed = true;
    }

    function destroy(address[] tokens) onlyOwner external {

        // Transfer tokens to owner
        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            uint balance = token.balanceOf(this);
            token.transfer(owner, balance);
        }

        for (uint j = 0; j < numberOfAlternatives; j++) {
            address votingAddress = votingAddresses[j];
            uint votes = balances[votingAddress];
            emit Result(votingAddress, votes);
        }

        // Transfer Eth to owner and terminate contract
        selfdestruct(owner);
    }

    // ~~~~~ Private Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    function _rewardVote(address _from, address _to, uint _value) private {
        if(_isVotingAddress(_to)) {
            require(opened && !closed);
            uint rewardTokens = _value.div(100);
            require(rewardToken.transfer(_from, rewardTokens));
            emit Reward(_from, _value);
        }
    }

    function _isVotingAddress(address votingAddress) private view returns (bool) {
        for (uint i = 0; i < numberOfAlternatives; i++) {
            if (votingAddresses[i] == votingAddress) return true;
        }
        return false;
    }

}