pragma solidity 0.7.1;

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

    interface ERC20Interface {
        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }


    abstract contract ApproveAndCallFallBack {
        function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
    }

    contract Owned {
        address public owner;
        address public newOwner;

        event OwnershipTransferred(address indexed _from, address indexed _to);

        constructor() public  {
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

    contract BITTO is ERC20Interface, Owned {
        using SafeMath for uint;

        string public symbol;
        string public  name;
        uint8 public decimals;
        uint _totalSupply;

        mapping(address => uint) balances;
        mapping(address => mapping(address => uint)) allowed;

        constructor() public {
            symbol = "BITTO";
            name = "BITTO";
            decimals = 18;
            _totalSupply = 17709627 * 10**uint(decimals);
            balances[owner] = _totalSupply;
            emit Transfer(address(0), owner, _totalSupply);
        }

        function totalSupply() public view override returns (uint) {
            return _totalSupply.sub(balances[address(0)]);
        }

        function balanceOf(address tokenOwner) public view override returns (uint balance) {
            return balances[tokenOwner];
        }

        function transfer(address to, uint tokens) public override returns (bool success) {
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(msg.sender, to, tokens);
            return true;
        }

        function approve(address spender, uint tokens) public override returns (bool success) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            return true;
        }

        function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(from, to, tokens);
            return true;
        }


        function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
            return allowed[tokenOwner][spender];
        }


        function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
            return true;
        }

        fallback () external {
            revert();
        }


        function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
            return ERC20Interface(tokenAddress).transfer(owner, tokens);
        }
    }