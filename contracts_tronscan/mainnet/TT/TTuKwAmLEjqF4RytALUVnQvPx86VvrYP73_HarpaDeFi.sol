//SourceUnit: HarpaDeFi.sol

pragma solidity ^0.4.23;

//██╗░░██╗░█████╗░██████╗░██████╗░░█████╗░██████╗░███████╗███████╗██╗
//██║░░██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝██║
//███████║███████║██████╔╝██████╔╝███████║██║░░██║█████╗░░█████╗░░██║
//██╔══██║██╔══██║██╔══██╗██╔═══╝░██╔══██║██║░░██║██╔══╝░░██╔══╝░░██║
//██║░░██║██║░░██║██║░░██║██║░░░░░██║░░██║██████╔╝███████╗██║░░░░░██║
//╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░╚═╝╚═════╝░╚══════╝╚═╝░░░░░╚═╝


interface ITRC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IApproveAndCallFallback {
    function receiveApproval(address _from, uint _value, address _token, bytes _data) external;
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}

contract HarpaDeFi is ITRC20, Ownable {
    using SafeMath for uint;

    string public symbol = "HAA";
    string public name = "HarpaDeFi";
    uint8 public decimals = 18;

    uint private _totalSupply = 100 * 10000 * 10 ** uint(decimals);

    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowed;

    constructor () public {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address owner) external view returns (uint) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) external view returns (uint) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) external returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint value) private {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function burn(uint value) external {
        _totalSupply = _totalSupply.sub(value);
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        emit Transfer(msg.sender, address(0), value);
    }

    function approveAndCall(address spender, uint value, bytes data) external returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        IApproveAndCallFallback(spender).receiveApproval(msg.sender, value, address(this), data);
        return true;
    }

    function() external payable {
        revert();
    }

    function transferAnyTRC20Token(address tokenAddress, uint value) external onlyOwner returns (bool) {
        return ITRC20(tokenAddress).transfer(owner, value);
    }
}