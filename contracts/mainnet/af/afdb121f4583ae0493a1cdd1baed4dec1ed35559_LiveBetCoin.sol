/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

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

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x179A6dF4d98b1f8CBe694bc9011BEfF934DB7515;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract LiveBetCoin is ERC20Interface, Owned { 
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint _currentSupply;
    uint[] public releaseTimes;
    uint _releaseAmount;
    uint releaseCounter;
    
    uint public unlockDate;
    uint public createdAt;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor() public { 
        name = "LiveBetCoin";
        symbol = "LBET";
        decimals = 18;
       _totalSupply = 777000000 * 10**uint(decimals);
        _currentSupply = 277000000 * 10**uint(decimals);
        createdAt = now;
        _releaseAmount = 25000000 * 10**uint(decimals);
        balances[owner] = _currentSupply;
        releaseTimes = [1643068800, 1674604800, 1706140800, 1737763200, 1769299200, 1800835200, 1832371200, 1863993600, 1895529600, 1927065600, 1958601600, 1990224000, 2021760000, 2053296000, 2084832000, 2116454400, 2147990400, 2179526400, 2211062400, 2242684800];
        releaseCounter = 0;
        emit Transfer(address(0), owner, _currentSupply);
    }
    
    function release() public onlyOwner{
    require(block.timestamp >= releaseTimes[releaseCounter]);
    require(releaseCounter < 20);
    balances[owner] = balances[owner] + _releaseAmount;
    emit Transfer(address(0), owner, _releaseAmount);
    releaseCounter = releaseCounter + 1;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    

    function () external payable {
        revert();
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
}