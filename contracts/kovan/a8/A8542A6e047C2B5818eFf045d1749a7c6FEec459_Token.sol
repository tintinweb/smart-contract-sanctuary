/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity ^0.8.5;

contract Token {

    uint256 public calculateResult;
    address public callingUser;
    uint256 public functionCallingCount;

	string public name = "WenJinGe";
    string public symbol = "munkh";
    uint256 private _totalSupply = 1000000;
    address private _owner;

    mapping(address => uint256) private _balances; 
    mapping (address => mapping (address => uint256)) private _allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event valueChanged(address message_sender, uint256 calcResult, address indexed callUser, uint256 functionResult);

	constructor() {
        _balances[_msgSender()] = _totalSupply;
        _owner = _msgSender();
    }

    function delgateCallingDelegateFunc(address sol, uint256 a, uint256 b) public returns (uint256){
        emit valueChanged(_msgSender(), calculateResult, callingUser, functionCallingCount);
        (bool success, bytes memory result) = sol.delegatecall(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit valueChanged(_msgSender(), calculateResult, callingUser, functionCallingCount);
        return abi.decode(result, (uint256));
    }
    function callingDelegateFunc(address sol, uint256 a, uint256 b) public returns (uint256){
        emit valueChanged(_msgSender(), calculateResult, callingUser, functionCallingCount);
        (bool success, bytes memory result) = sol.call(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit valueChanged(_msgSender(), calculateResult, callingUser, functionCallingCount);
        return abi.decode(result, (uint256));
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(_balances[_msgSender()] >= amount, "Not enough tokens");
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    

    function _msgSender() internal virtual returns (address) {
        return msg.sender;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
}