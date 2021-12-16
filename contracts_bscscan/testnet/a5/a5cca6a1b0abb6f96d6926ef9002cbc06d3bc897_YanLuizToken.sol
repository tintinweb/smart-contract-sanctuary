/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

pragma solidity ^0.8.0;

contract YanLuizToken {
    uint256 private _totalSupply;
    uint256 private _decimals;
    string private _name;
    string private _symbol;
    address private _owner;
    bool private _paused;

    constructor() {
        _decimals = 18;
        _name = "Yan Luiz Token";
        _symbol = "YLT";

        _mint(msg.sender, 333000000);
        _transferOwnership(msg.sender);
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused() returns(bool){
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused() returns(bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function approve(address spender, uint256 amount) public whenNotPaused() returns(bool){
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns(uint256){
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused() returns(bool){
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function drecreaseAllowance(address spender, uint256 subtracredValue) public whenNotPaused() returns(bool){
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtracredValue, "ERC20: drecrease allowance below zero");

        unchecked{_approve(msg.sender, spender, currentAllowance - subtracredValue);}
        return true;
    }

    function owner() public view returns(address){
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner() whenNotPaused() {
        _transferOwnership(newOwner);
    }

    modifier onlyOwner(){
        require(msg.sender == owner(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public {
        _transferOwnership(address(0));
    }

    function mint(address account, uint256 amount) public onlyOwner(){
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner(){
        _burn(account, amount);
    }


    function pause() public onlyOwner(){
        _pause();
    }

    function unpause() public onlyOwner(){
        _unpause();
    }

    function paused() public view returns(bool){
        return _paused;
    }

    modifier whenNotPaused(){
        require(!paused(), "Pausable: Pause");
        _;
    }

//FUNCOES INTERNAS
    function _transfer(address sender, address recipient, uint256 amount) internal {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked{_balances[sender] = senderBalance - amount;}
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit TransferOwnership(oldOwner, newOwner);
    }

    function _mint(address _account, uint256 _amount) internal {
        _totalSupply += _amount;
        _balances[_account] += _amount;

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address account, uint256 amount) internal {
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _pause() internal {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal {
        _paused = false;
        emit Unpaused(msg.sender);
    }


}