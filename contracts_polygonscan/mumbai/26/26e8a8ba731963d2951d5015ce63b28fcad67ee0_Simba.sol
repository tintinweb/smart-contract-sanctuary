/**
 *Submitted for verification at polygonscan.com on 2022-01-14
*/

pragma solidity ^0.8.11;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Owner() public {
        owner = msg.sender;
    }
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public isOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Tax is Ownable {
    bool Buy_Tax;
    uint Whale_Stage1_Burn;
    uint Whale_Stage1_Tax;
    uint Whale_Stage2_Burn;
    uint Whale_Stage2_Tax;
    uint Whale_Stage3_Burn;
    uint Whale_Stage3_Tax;
    uint Whale_Stage4_Burn;
    uint Whale_Stage4_Tax;
    uint Whale_Stage5_Burn;
    uint Whale_Stage5_Tax;
    uint Whale_Stage6_Burn;
    uint Whale_Stage6_Tax;
    uint Whale_Stage7_Burn;
    uint Whale_Stage7_Tax;
    uint Whale_Stage8_Burn;
    uint Whale_Stage8_Tax;
    uint Whale_Stage9_Burn;
    uint Whale_Stage9_Tax;
    uint Whale_Stage10_Burn;
    uint Whale_Stage10_Tax;
    uint Whale_Stage11_Burn;
    uint Whale_Stage11_Tax;
    uint Whale_Stage12_Burn;
    uint Whale_Stage12_Tax;
    uint Buy_Stage1_Burn;
    uint Buy_Stage1_Tax;
    uint Buy_Stage2_Burn;
    uint Buy_Stage2_Tax;
    uint Buy_Stage3_Burn;
    uint Buy_Stage3_Tax;
    uint Buy_Stage4_Burn;
    uint Buy_Stage4_Tax;
    uint Buy_Stage5_Burn;
    uint Buy_Stage5_Tax;
    uint Buy_Stage6_Burn;
    uint Buy_Stage6_Tax;
    uint Buy_Stage7_Burn;
    uint Buy_Stage7_Tax;
    uint Buy_Stage8_Burn;
    uint Buy_Stage8_Tax;
    uint Buy_Stage9_Burn;
    uint Buy_Stage9_Tax;
    uint Buy_Stage10_Burn;
    uint Buy_Stage10_Tax;
    uint Buy_Stage11_Burn;
    uint Buy_Stage11_Tax;
    uint Buy_Stage12_Burn;
    uint Buy_Stage12_Tax;

    constructor() {
        Whale_Stage1_Burn = 3;
        Whale_Stage1_Tax = 3;
        Whale_Stage2_Burn = 3;
        Whale_Stage2_Tax = 3;
        Whale_Stage3_Burn = 3;
        Whale_Stage3_Tax = 3;
        Whale_Stage4_Burn = 3;
        Whale_Stage4_Tax = 3;
        Whale_Stage5_Burn = 3;
        Whale_Stage5_Tax = 3;
        Whale_Stage6_Burn = 3;
        Whale_Stage6_Tax = 3;
        Whale_Stage7_Burn = 3;
        Whale_Stage7_Tax = 3;
        Whale_Stage8_Burn = 3;
        Whale_Stage8_Tax = 3;
        Whale_Stage9_Burn = 3;
        Whale_Stage9_Tax = 3;
        Whale_Stage10_Burn = 3;
        Whale_Stage10_Tax = 3;
        Whale_Stage11_Burn = 3;
        Whale_Stage11_Tax = 3;
        Whale_Stage12_Burn = 3;
        Whale_Stage12_Tax = 3;
        Buy_Stage1_Burn = 3;
        Buy_Stage1_Tax = 3;
        Buy_Stage2_Burn = 3;
        Buy_Stage2_Tax = 3;
        Buy_Stage3_Burn = 3;
        Buy_Stage3_Tax = 3;
        Buy_Stage4_Burn = 3;
        Buy_Stage4_Tax = 3;
        Buy_Stage5_Burn = 3;
        Buy_Stage5_Tax = 3;
        Buy_Stage6_Burn = 3;
        Buy_Stage6_Tax = 3;
        Buy_Stage7_Burn = 3;
        Buy_Stage7_Tax = 3;
        Buy_Stage8_Burn = 3;
        Buy_Stage8_Tax = 3;
        Buy_Stage9_Burn = 3;
        Buy_Stage9_Tax = 3;
        Buy_Stage10_Burn = 3;
        Buy_Stage10_Tax = 3;
        Buy_Stage11_Burn = 3;
        Buy_Stage11_Tax = 3;
        Buy_Stage12_Burn = 3;
        Buy_Stage12_Tax = 3;
    }
    
    function Get_Buy_Tax() public view returns(bool){
        return Buy_Tax;
    }
    function Get_Whale_Stage1_Burn() public view returns(uint){
        return Whale_Stage1_Burn;
    }
    function Get_Whale_Stage1_Tax() public view returns(uint){
        return Whale_Stage1_Tax;
    }
    function Get_Whale_Stage2_Burn() public view returns(uint){
        return Whale_Stage2_Burn;
    }
    function Get_Whale_Stage2_Tax() public view returns(uint){
        return Whale_Stage2_Tax;
    }
    function Get_Whale_Stage3_Burn() public view returns(uint){
        return Whale_Stage3_Burn;
    }
    function Get_Whale_Stage3_Tax() public view returns(uint){
        return Whale_Stage3_Tax;
    }
    function Get_Whale_Stage4_Burn() public view returns(uint){
        return Whale_Stage4_Burn;
    }
    function Get_Whale_Stage4_Tax() public view returns(uint){
        return Whale_Stage4_Tax;
    }
    function Get_Whale_Stage5_Burn() public view returns(uint){
        return Whale_Stage5_Burn;
    }
    function Get_Whale_Stage5_Tax() public view returns(uint){
        return Whale_Stage5_Tax;
    }
    function Get_Whale_Stage6_Burn() public view returns(uint){
        return Whale_Stage6_Burn;
    }
    function Get_Whale_Stage6_Tax() public view returns(uint){
        return Whale_Stage6_Tax;
    }
    function Get_Whale_Stage7_Burn() public view returns(uint){
        return Whale_Stage7_Burn;
    }
    function Get_Whale_Stage7_Tax() public view returns(uint){
        return Whale_Stage7_Tax;
    }
    function Get_Whale_Stage8_Burn() public view returns(uint){
        return Whale_Stage8_Burn;
    }
    function Get_Whale_Stage8_Tax() public view returns(uint){
        return Whale_Stage8_Tax;
    }
    function Get_Whale_Stage9_Burn() public view returns(uint){
        return Whale_Stage9_Burn;
    }
    function Get_Whale_Stage9_Tax() public view returns(uint){
        return Whale_Stage9_Tax;
    }
    function Get_Whale_Stage10_Burn() public view returns(uint){
        return Whale_Stage10_Burn;
    }
    function Get_Whale_Stage10_Tax() public view returns(uint){
        return Whale_Stage10_Tax;
    }
    function Get_Whale_Stage11_Burn() public view returns(uint){
        return Whale_Stage11_Burn;
    }
    function Get_Whale_Stage11_Tax() public view returns(uint){
        return Whale_Stage11_Tax;
    }
    function Get_Whale_Stage12_Burn() public view returns(uint){
        return Whale_Stage12_Burn;
    }
    function Get_Whale_Stage12_Tax() public view returns(uint){
        return Whale_Stage12_Tax;
    }
    function Get_Buy_Stage1_Burn() public view returns(uint){
        return Buy_Stage1_Burn;
    }
    function Get_Buy_Stage1_Tax() public view returns(uint){
        return Buy_Stage1_Tax;
    }
    function Get_Buy_Stage2_Burn() public view returns(uint){
        return Buy_Stage2_Burn;
    }
    function Get_Buy_Stage2_Tax() public view returns(uint){
        return Buy_Stage2_Tax;
    }
    function Get_Buy_Stage3_Burn() public view returns(uint){
        return Buy_Stage3_Burn;
    }
    function Get_Buy_Stage3_Tax() public view returns(uint){
        return Buy_Stage3_Tax;
    }
    function Get_Buy_Stage4_Burn() public view returns(uint){
        return Buy_Stage4_Burn;
    }
    function Get_Buy_Stage4_Tax() public view returns(uint){
        return Buy_Stage4_Tax;
    }
    function Get_Buy_Stage5_Burn() public view returns(uint){
        return Buy_Stage5_Burn;
    }
    function Get_Buy_Stage5_Tax() public view returns(uint){
        return Buy_Stage5_Tax;
    }
    function Get_Buy_Stage6_Burn() public view returns(uint){
        return Buy_Stage6_Burn;
    }
    function Get_Buy_Stage6_Tax() public view returns(uint){
        return Buy_Stage6_Tax;
    }
    function Get_Buy_Stage7_Burn() public view returns(uint){
        return Buy_Stage7_Burn;
    }
    function Get_Buy_Stage7_Tax() public view returns(uint){
        return Buy_Stage7_Tax;
    }
    function Get_Buy_Stage8_Burn() public view returns(uint){
        return Buy_Stage8_Burn;
    }
    function Get_Buy_Stage8_Tax() public view returns(uint){
        return Buy_Stage8_Tax;
    }
    function Get_Buy_Stage9_Burn() public view returns(uint){
        return Buy_Stage9_Burn;
    }
    function Get_Buy_Stage9_Tax() public view returns(uint){
        return Buy_Stage9_Tax;
    }
    function Get_Buy_Stage10_Burn() public view returns(uint){
        return Buy_Stage10_Burn;
    }
    function Get_Buy_Stage10_Tax() public view returns(uint){
        return Buy_Stage10_Tax;
    }
    function Get_Buy_Stage11_Burn() public view returns(uint){
        return Buy_Stage11_Burn;
    }
    function Get_Buy_Stage11_Tax() public view returns(uint){
        return Buy_Stage11_Tax;
    }
    function Get_Buy_Stage12_Burn() public view returns(uint){
        return Buy_Stage12_Burn;
    }
    function Get_Buy_Stage12_Tax() public view returns(uint){
        return Buy_Stage12_Tax;
    }
    function Set_Buy_Tax(bool _Buy_Tax) public {
        Buy_Tax = _Buy_Tax;
    }
    function Set_Whale_Stage1_Burn(uint _Whale_Stage1_Burn) public {
        Whale_Stage1_Burn = Whale_Stage2_Burn = Whale_Stage3_Burn = Whale_Stage4_Burn = Whale_Stage5_Burn = Whale_Stage6_Burn = Whale_Stage7_Burn = Whale_Stage8_Burn = Whale_Stage9_Burn = Whale_Stage10_Burn = Whale_Stage11_Burn = Whale_Stage12_Burn = _Whale_Stage1_Burn;
    }
    function Set_Whale_Stage1_Tax(uint _Whale_Stage1_Tax) public {
        Whale_Stage1_Tax = Whale_Stage2_Tax = Whale_Stage3_Tax = Whale_Stage4_Tax = Whale_Stage5_Tax = Whale_Stage6_Tax = Whale_Stage7_Tax = Whale_Stage8_Tax = Whale_Stage9_Tax = Whale_Stage10_Tax = Whale_Stage11_Tax = Whale_Stage12_Tax = _Whale_Stage1_Tax;
    }
    function Set_Whale_Stage2_Burn(uint _Whale_Stage2_Burn) public {
        Whale_Stage2_Burn = Whale_Stage3_Burn = Whale_Stage4_Burn = Whale_Stage5_Burn = Whale_Stage6_Burn = Whale_Stage7_Burn = Whale_Stage8_Burn = Whale_Stage9_Burn = Whale_Stage10_Burn = Whale_Stage11_Burn = Whale_Stage12_Burn = _Whale_Stage2_Burn;
    }
    function Set_Whale_Stage2_Tax(uint _Whale_Stage2_Tax) public {
        Whale_Stage2_Tax = Whale_Stage3_Tax = Whale_Stage4_Tax = Whale_Stage5_Tax = Whale_Stage6_Tax = Whale_Stage7_Tax = Whale_Stage8_Tax = Whale_Stage9_Tax = Whale_Stage10_Tax = Whale_Stage11_Tax = Whale_Stage12_Tax = _Whale_Stage2_Tax;
    }
    function Set_Whale_Stage3_Burn(uint _Whale_Stage3_Burn) public {
        Whale_Stage3_Burn = Whale_Stage4_Burn = Whale_Stage5_Burn = Whale_Stage6_Burn = Whale_Stage7_Burn = Whale_Stage8_Burn = Whale_Stage9_Burn = Whale_Stage10_Burn = Whale_Stage11_Burn = Whale_Stage12_Burn = _Whale_Stage3_Burn;
    }
    function Set_Whale_Stage3_Tax(uint _Whale_Stage3_Tax) public {
        Whale_Stage3_Tax = Whale_Stage4_Tax = Whale_Stage5_Tax = Whale_Stage6_Tax = Whale_Stage7_Tax = Whale_Stage8_Tax = Whale_Stage9_Tax = Whale_Stage10_Tax = Whale_Stage11_Tax = Whale_Stage12_Tax = _Whale_Stage3_Tax;
    }
    function Set_Whale_Stage4_Burn(uint _Whale_Stage4_Burn) public {
        Whale_Stage4_Burn = Whale_Stage5_Burn = Whale_Stage6_Burn = Whale_Stage7_Burn = Whale_Stage8_Burn = Whale_Stage9_Burn = Whale_Stage10_Burn = Whale_Stage11_Burn = Whale_Stage12_Burn = _Whale_Stage4_Burn;
    }
    function Set_Whale_Stage4_Tax(uint _Whale_Stage4_Tax) public {
        Whale_Stage4_Tax = Whale_Stage5_Tax = Whale_Stage6_Tax = Whale_Stage7_Tax = Whale_Stage8_Tax = Whale_Stage9_Tax = Whale_Stage10_Tax = Whale_Stage11_Tax = Whale_Stage12_Tax = _Whale_Stage4_Tax;
    }
    function Set_Whale_Stage5_Burn(uint _Whale_Stage5_Burn) public {
        Whale_Stage5_Burn = Whale_Stage6_Burn = Whale_Stage7_Burn = Whale_Stage8_Burn = Whale_Stage9_Burn = Whale_Stage10_Burn = Whale_Stage11_Burn = Whale_Stage12_Burn = _Whale_Stage5_Burn;
    }
    function Set_Whale_Stage5_Tax(uint _Whale_Stage5_Tax) public {
        Whale_Stage5_Tax = Whale_Stage6_Tax = Whale_Stage7_Tax = Whale_Stage8_Tax = Whale_Stage9_Tax = Whale_Stage10_Tax = Whale_Stage11_Tax = Whale_Stage12_Tax = _Whale_Stage5_Tax;
    }
    function Set_Whale_Stage6_Burn(uint _Whale_Stage6_Burn) public {
        Whale_Stage6_Burn = Whale_Stage7_Burn = Whale_Stage8_Burn = Whale_Stage9_Burn = Whale_Stage10_Burn = Whale_Stage11_Burn = Whale_Stage12_Burn = _Whale_Stage6_Burn;
    }
    function Set_Whale_Stage6_Tax(uint _Whale_Stage6_Tax) public {
        Whale_Stage6_Tax = Whale_Stage7_Tax = Whale_Stage8_Tax = Whale_Stage9_Tax = Whale_Stage10_Tax = Whale_Stage11_Tax = Whale_Stage12_Tax = _Whale_Stage6_Tax;
    }
    function Set_Whale_Stage7_Burn(uint _Whale_Stage7_Burn) public {
        Whale_Stage7_Burn = Whale_Stage8_Burn = Whale_Stage9_Burn = Whale_Stage10_Burn = Whale_Stage11_Burn = Whale_Stage12_Burn = _Whale_Stage7_Burn;
    }
    function Set_Whale_Stage7_Tax(uint _Whale_Stage7_Tax) public {
        Whale_Stage7_Tax = Whale_Stage8_Tax = Whale_Stage9_Tax = Whale_Stage10_Tax = Whale_Stage11_Tax = Whale_Stage12_Tax = _Whale_Stage7_Tax;
    }
    function Set_Whale_Stage8_Burn(uint _Whale_Stage8_Burn) public {
        Whale_Stage8_Burn = Whale_Stage9_Burn = Whale_Stage10_Burn = Whale_Stage11_Burn = Whale_Stage12_Burn = _Whale_Stage8_Burn;
    }
    function Set_Whale_Stage8_Tax(uint _Whale_Stage8_Tax) public {
        Whale_Stage8_Tax = Whale_Stage9_Tax = Whale_Stage10_Tax = Whale_Stage11_Tax = Whale_Stage12_Tax = _Whale_Stage8_Tax;
    }
    function Set_Whale_Stage9_Burn(uint _Whale_Stage9_Burn) public {
        Whale_Stage9_Burn = Whale_Stage10_Burn = Whale_Stage11_Burn = Whale_Stage12_Burn = _Whale_Stage9_Burn;
    }
    function Set_Whale_Stage9_Tax(uint _Whale_Stage9_Tax) public {
        Whale_Stage9_Tax = Whale_Stage10_Tax = Whale_Stage11_Tax = Whale_Stage12_Tax = _Whale_Stage9_Tax;
    }
    function Set_Whale_Stage10_Burn(uint _Whale_Stage10_Burn) public {
        Whale_Stage10_Burn = Whale_Stage11_Burn = Whale_Stage12_Burn = _Whale_Stage10_Burn;
    }
    function Set_Whale_Stage10_Tax(uint _Whale_Stage10_Tax) public {
        Whale_Stage10_Tax = Whale_Stage11_Tax = Whale_Stage12_Tax = _Whale_Stage10_Tax;
    }
    function Set_Whale_Stage11_Burn(uint _Whale_Stage11_Burn) public {
        Whale_Stage11_Burn = Whale_Stage12_Burn = _Whale_Stage11_Burn;
    }
    function Set_Whale_Stage11_Tax(uint _Whale_Stage11_Tax) public {
        Whale_Stage11_Tax = Whale_Stage12_Tax = _Whale_Stage11_Tax;
    }
    function Set_Whale_Stage12_Burn(uint _Whale_Stage12_Burn) public {
        Whale_Stage12_Burn = _Whale_Stage12_Burn;
    }
    function Set_Whale_Stage12_Tax(uint _Whale_Stage12_Tax) public {
        Whale_Stage12_Tax = _Whale_Stage12_Tax;
    }
    function Set_Buy_Stage1_Burn(uint _Buy_Stage1_Burn) public {
        Buy_Stage1_Burn = Buy_Stage2_Burn = Buy_Stage3_Burn = Buy_Stage4_Burn = Buy_Stage5_Burn = Buy_Stage6_Burn = Buy_Stage7_Burn = Buy_Stage8_Burn = Buy_Stage9_Burn = Buy_Stage10_Burn = Buy_Stage11_Burn = Buy_Stage12_Burn = _Buy_Stage1_Burn;
    }
    function Set_Buy_Stage1_Tax(uint _Buy_Stage1_Tax) public {
        Buy_Stage1_Tax = Buy_Stage2_Tax = Buy_Stage3_Tax = Buy_Stage4_Tax = Buy_Stage5_Tax = Buy_Stage6_Tax = Buy_Stage7_Tax = Buy_Stage8_Tax = Buy_Stage9_Tax = Buy_Stage10_Tax = Buy_Stage11_Tax = Buy_Stage12_Tax = _Buy_Stage1_Tax;
    }
    function Set_Buy_Stage2_Burn(uint _Buy_Stage2_Burn) public {
        Buy_Stage2_Burn = Buy_Stage3_Burn = Buy_Stage4_Burn = Buy_Stage5_Burn = Buy_Stage6_Burn = Buy_Stage7_Burn = Buy_Stage8_Burn = Buy_Stage9_Burn = Buy_Stage10_Burn = Buy_Stage11_Burn = Buy_Stage12_Burn = _Buy_Stage2_Burn;
    }
    function Set_Buy_Stage2_Tax(uint _Buy_Stage2_Tax) public {
        Buy_Stage2_Tax = Buy_Stage3_Tax = Buy_Stage4_Tax = Buy_Stage5_Tax = Buy_Stage6_Tax = Buy_Stage7_Tax = Buy_Stage8_Tax = Buy_Stage9_Tax = Buy_Stage10_Tax = Buy_Stage11_Tax = Buy_Stage12_Tax = _Buy_Stage2_Tax;
    }
    function Set_Buy_Stage3_Burn(uint _Buy_Stage3_Burn) public {
        Buy_Stage3_Burn = Buy_Stage4_Burn = Buy_Stage5_Burn = Buy_Stage6_Burn = Buy_Stage7_Burn = Buy_Stage8_Burn = Buy_Stage9_Burn = Buy_Stage10_Burn = Buy_Stage11_Burn = Buy_Stage12_Burn = _Buy_Stage3_Burn;
    }
    function Set_Buy_Stage3_Tax(uint _Buy_Stage3_Tax) public {
        Buy_Stage3_Tax = Buy_Stage4_Tax = Buy_Stage5_Tax = Buy_Stage6_Tax = Buy_Stage7_Tax = Buy_Stage8_Tax = Buy_Stage9_Tax = Buy_Stage10_Tax = Buy_Stage11_Tax = Buy_Stage12_Tax = _Buy_Stage3_Tax;
    }
    function Set_Buy_Stage4_Burn(uint _Buy_Stage4_Burn) public {
        Buy_Stage4_Burn = Buy_Stage5_Burn = Buy_Stage6_Burn = Buy_Stage7_Burn = Buy_Stage8_Burn = Buy_Stage9_Burn = Buy_Stage10_Burn = Buy_Stage11_Burn = Buy_Stage12_Burn = _Buy_Stage4_Burn;
    }
    function Set_Buy_Stage4_Tax(uint _Buy_Stage4_Tax) public {
        Buy_Stage4_Tax = Buy_Stage5_Tax = Buy_Stage6_Tax = Buy_Stage7_Tax = Buy_Stage8_Tax = Buy_Stage9_Tax = Buy_Stage10_Tax = Buy_Stage11_Tax = Buy_Stage12_Tax = _Buy_Stage4_Tax;
    }
    function Set_Buy_Stage5_Burn(uint _Buy_Stage5_Burn) public {
        Buy_Stage5_Burn = Buy_Stage6_Burn = Buy_Stage7_Burn = Buy_Stage8_Burn = Buy_Stage9_Burn = Buy_Stage10_Burn = Buy_Stage11_Burn = Buy_Stage12_Burn = _Buy_Stage5_Burn;
    }
    function Set_Buy_Stage5_Tax(uint _Buy_Stage5_Tax) public {
        Buy_Stage5_Tax = Buy_Stage6_Tax = Buy_Stage7_Tax = Buy_Stage8_Tax = Buy_Stage9_Tax = Buy_Stage10_Tax = Buy_Stage11_Tax = Buy_Stage12_Tax = _Buy_Stage5_Tax;
    }
    function Set_Buy_Stage6_Burn(uint _Buy_Stage6_Burn) public {
        Buy_Stage6_Burn = Buy_Stage7_Burn = Buy_Stage8_Burn = Buy_Stage9_Burn = Buy_Stage10_Burn = Buy_Stage11_Burn = Buy_Stage12_Burn = _Buy_Stage6_Burn;
    }
    function Set_Buy_Stage6_Tax(uint _Buy_Stage6_Tax) public {
        Buy_Stage6_Tax = Buy_Stage7_Tax = Buy_Stage8_Tax = Buy_Stage9_Tax = Buy_Stage10_Tax = Buy_Stage11_Tax = Buy_Stage12_Tax = _Buy_Stage6_Tax;
    }
    function Set_Buy_Stage7_Burn(uint _Buy_Stage7_Burn) public {
        Buy_Stage7_Burn = Buy_Stage8_Burn = Buy_Stage9_Burn = Buy_Stage10_Burn = Buy_Stage11_Burn = Buy_Stage12_Burn = _Buy_Stage7_Burn;
    }
    function Set_Buy_Stage7_Tax(uint _Buy_Stage7_Tax) public {
        Buy_Stage7_Tax = Buy_Stage8_Tax = Buy_Stage9_Tax = Buy_Stage10_Tax = Buy_Stage11_Tax = Buy_Stage12_Tax = _Buy_Stage7_Tax;
    }
    function Set_Buy_Stage8_Burn(uint _Buy_Stage8_Burn) public {
        Buy_Stage8_Burn = Buy_Stage9_Burn = Buy_Stage10_Burn = Buy_Stage11_Burn = Buy_Stage12_Burn = _Buy_Stage8_Burn;
    }
    function Set_Buy_Stage8_Tax(uint _Buy_Stage8_Tax) public {
        Buy_Stage8_Tax = Buy_Stage9_Tax = Buy_Stage10_Tax = Buy_Stage11_Tax = Buy_Stage12_Tax = _Buy_Stage8_Tax;
    }
    function Set_Buy_Stage9_Burn(uint _Buy_Stage9_Burn) public {
        Buy_Stage9_Burn = Buy_Stage10_Burn = Buy_Stage11_Burn = Buy_Stage12_Burn = _Buy_Stage9_Burn;
    }
    function Set_Buy_Stage9_Tax(uint _Buy_Stage9_Tax) public {
        Buy_Stage9_Tax = Buy_Stage10_Tax = Buy_Stage11_Tax = Buy_Stage12_Tax = _Buy_Stage9_Tax;
    }
    function Set_Buy_Stage10_Burn(uint _Buy_Stage10_Burn) public {
        Buy_Stage10_Burn = Buy_Stage11_Burn = Buy_Stage12_Burn = _Buy_Stage10_Burn;
    }
    function Set_Buy_Stage10_Tax(uint _Buy_Stage10_Tax) public {
        Buy_Stage10_Tax = Buy_Stage11_Tax = Buy_Stage12_Tax = _Buy_Stage10_Tax;
    }
    function Set_Buy_Stage11_Burn(uint _Buy_Stage11_Burn) public {
        Buy_Stage11_Burn = Buy_Stage12_Burn = _Buy_Stage11_Burn;
    }
    function Set_Buy_Stage11_Tax(uint _Buy_Stage11_Tax) public {
        Buy_Stage11_Tax = Buy_Stage12_Tax = _Buy_Stage11_Tax;
    }
    function Set_Buy_Stage12_Burn(uint _Buy_Stage12_Burn) public {
        Buy_Stage12_Burn = _Buy_Stage12_Burn;
    }
    function Set_Buy_Stage12_Tax(uint _Buy_Stage12_Tax) public {
        Buy_Stage12_Tax = _Buy_Stage12_Tax;
    }
}

contract Simba is ERC20, Tax {
    using SafeMath for uint256;
    mapping(address => bool) public exclidedFromTax;
    address adr1;
    address adr2;
    address swapadr1;
    address swapadr2;
    address swapadr3;

    constructor() ERC20('Simba', 'Simba Lion') {
        _mint(msg.sender, 1000000000000000 * 10 ** 18);
        exclidedFromTax[msg.sender] = true;
        owner = msg.sender;
        Buy_Tax = true;
        adr1 = 0xD4a551D7A540CFC96fE84Fc286bDA97279bdcC5d;
        adr2 = 0x2707eaC046d6d92cEEe3d038dbf0F42E4867bF97;
        swapadr1 = 0x28D634cF1b8Eb0F4cd28C6966C62f860B24C9Bf7;
        swapadr2 = 0x4AFf51EFb3bA64C5604397CB420565A6262B39F6;
        swapadr3 = 0x9a4bBC8C0A7Ee39eC005f8997697BA1209894Cc9;
    }
    function get_adr1() public view returns(address){
        return adr1;
    }
    function get_adr2() public view returns(address){
        return adr2;
    }
    function get_swapadr1() public view returns(address){
        return swapadr1;
    }
    function get_swapadr2() public view returns(address){
        return swapadr2;
    }
    function get_swapadr3() public view returns(address){
        return swapadr3;
    }
    function set_adr1(address _adr1) public {
        adr1 = _adr1;
    }
    function set_adr2(address _adr2) public {
        adr2 = _adr2;
    }
    function set_swapadr1(address _swapadr1) public {
        swapadr1 = _swapadr1;
    }
    function set_swapadr2(address _swapadr2) public {
        swapadr2 = _swapadr2;
    }
    function set_swapadr3(address _swapadr3) public {
        swapadr3 = _swapadr3;
    }

    function transfer(address recipient,uint256 amount) public override returns (bool) {
        if(exclidedFromTax[msg.sender] = true || msg.sender == adr1 || msg.sender == adr2 || msg.sender == swapadr1 || msg.sender == swapadr2 || msg.sender == swapadr3) {
            if(Buy_Tax == true) {
                if(recipient == address(0x000000000000000000000000000000000000dEaD)) {
                    uint burnAmount = amount;
                    uint adminAmount = amount.mul(0) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else {
                    _transfer(_msgSender(), recipient, amount);
                }
            }
            else {
                if(recipient == address(0x000000000000000000000000000000000000dEaD)) {
                    uint burnAmount = amount;
                    uint adminAmount = amount.mul(0) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 100 * 10 ** 18) {
                    uint burnAmount = amount.mul(Buy_Stage1_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage1_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount > 100 * 10 ** 18 && amount <= 1000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Buy_Stage2_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage2_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount > 1000 * 10 ** 18 && amount <= 10000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Buy_Stage3_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage3_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount > 10000 * 10 ** 18 && amount <= 100000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Buy_Stage4_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage4_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount > 100000 * 10 ** 18 && amount <= 1000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Buy_Stage5_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage5_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 1000000 * 10 ** 18 && amount <= 10000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Buy_Stage6_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage6_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 10000000 * 10 ** 18 && amount <= 100000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Buy_Stage7_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage7_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 100000000 * 10 ** 18 && amount <= 1000000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Buy_Stage8_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage8_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 1000000000 * 10 ** 18 && amount <= 10000000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Buy_Stage9_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage9_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 10000000000 * 10 ** 18 && amount <= 50000000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Buy_Stage10_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage10_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 50000000000 * 10 ** 18 && amount <= 100000000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Buy_Stage11_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage11_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else {
                    uint burnAmount = amount.mul(Buy_Stage12_Burn) / 100;
                    uint adminAmount = amount.mul(Buy_Stage12_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
            }
        } 
        else {
            if(recipient == address(0x000000000000000000000000000000000000dEaD)) {
                uint burnAmount = amount;
                uint adminAmount = amount.mul(0) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 100 * 10 ** 18) {
                uint burnAmount = amount.mul(Whale_Stage1_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage1_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 100 * 10 ** 18 && amount <= 1000 * 10 ** 18) {
                uint burnAmount = amount.mul(Whale_Stage2_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage2_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 1000 * 10 ** 18 && amount <= 10000 * 10 ** 18) {
                uint burnAmount = amount.mul(Whale_Stage3_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage3_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 10000 * 10 ** 18 && amount <= 100000 * 10 ** 18) {
                uint burnAmount = amount.mul(Whale_Stage4_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage4_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 100000 * 10 ** 18 && amount <= 1000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Whale_Stage5_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage5_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 1000000 * 10 ** 18 && amount <= 10000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Whale_Stage6_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage6_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 10000000 * 10 ** 18 && amount <= 100000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Whale_Stage7_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage7_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 100000000 * 10 ** 18 && amount <= 1000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Whale_Stage8_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage8_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 1000000000 * 10 ** 18 && amount <= 10000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Whale_Stage9_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage9_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 10000000000 * 10 ** 18 && amount <= 50000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Whale_Stage10_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage10_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 50000000000 * 10 ** 18 && amount <= 100000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Whale_Stage11_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage11_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else {
                uint burnAmount = amount.mul(Whale_Stage12_Burn) / 100;
                uint adminAmount = amount.mul(Whale_Stage12_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
        }
        return true;
    }
}