pragma solidity ^0.6.0;

import "./IMVDProxy.sol";
import "./IERC20.sol";
import "./IVotingToken.sol";
import "./IMVDFunctionalityProposalManager.sol";
import "./IMVDFunctionalitiesManager.sol";

contract VotingToken is IERC20, IVotingToken {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _decimals;
    address private _proxy;
    string private _name;
    string private _symbol;

    constructor(string memory name, string memory symbol, uint256 decimals, uint256 totalSupply) public {
        if(totalSupply == 0) {
            return;
        }
        init(name, symbol, decimals, totalSupply);
    }

    function init(string memory name, string memory symbol, uint256 decimals, uint256 totalSupply) public override {
        require(_totalSupply == 0, "Init already called!");

        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply * (10 ** decimals);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(this), msg.sender, _totalSupply);
    }

    receive() external payable {
        revert("ETH not accepted");
    }

    function getProxy() public override view returns(address) {
        return _proxy;
    }

    function name() public override view returns(string memory) {
        return _name;
    }

    function symbol() public override view returns(string memory) {
        return _symbol;
    }

    function decimals() public override view returns(uint256) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        address txSender = msg.sender;
        if(_proxy == address(0) || !(IMVDFunctionalityProposalManager(IMVDProxy(_proxy).getMVDFunctionalityProposalManagerAddress()).isValidProposal(txSender) && recipient == txSender)) {
            _approve(sender, txSender, _allowances[sender][txSender] = sub(_allowances[sender][txSender], amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _approve(msg.sender, spender, add(_allowances[msg.sender][spender], addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        _approve(msg.sender, spender, sub(_allowances[msg.sender][spender], subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = sub(_balances[sender], amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = add(_balances[recipient], amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256 c) {
        require(b <= a, errorMessage);
        c = a - b;
    }

    function setProxy() public override {
        require(_totalSupply != 0, "Init not called!");
        require(_proxy == address(0) || _proxy == msg.sender, _proxy != address(0) ? "Proxy already set!" : "Only Proxy can toggle itself!");
        _proxy = _proxy == address(0) ?  msg.sender : address(0);
    }

    function mint(uint256 amount) public override {
        require(IMVDFunctionalitiesManager(IMVDProxy(_proxy).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized access!");

        _totalSupply = add(_totalSupply, amount);
        _balances[_proxy] = add(_balances[_proxy], amount);
        emit Transfer(address(0), _proxy, amount);
    }

    function burn(uint256 amount) public override {
        _balances[msg.sender] = sub(_balances[msg.sender], amount, "VotingToken: burn amount exceeds balance");
        _totalSupply = sub(_totalSupply, amount, "VotingToken: burn amount exceeds total supply");
        emit Transfer(msg.sender, address(0), amount);
    }
}