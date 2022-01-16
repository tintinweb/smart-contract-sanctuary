/**
 *Submitted for verification at polygonscan.com on 2022-01-15
*/

pragma solidity ^0.8.11;

// SPDX-License-Identifier: UNLICENCED

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

contract Tax {
    address public owner;
    bool Owner_Tax;
    uint Whale1_Burn;
    uint Whale1_Tax;
    uint Whale2_Burn;
    uint Whale2_Tax;
    uint Whale3_Burn;
    uint Whale3_Tax;
    uint Whale4_Burn;
    uint Whale4_Tax;
    uint Whale5_Burn;
    uint Whale5_Tax;
    uint Whale6_Burn;
    uint Whale6_Tax;
    uint Whale7_Burn;
    uint Whale7_Tax;
    uint Whale8_Burn;
    uint Whale8_Tax;
    uint Whale9_Burn;
    uint Whale9_Tax;
    uint Whale10_Burn;
    uint Whale10_Tax;
    uint Whale11_Burn;
    uint Whale11_Tax;
    uint Whale12_Burn;
    uint Whale12_Tax;
    uint Whale13_Burn;
    uint Whale13_Tax;
    uint Whale14_Burn;
    uint Whale14_Tax;
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
    uint Buy_Stage13_Burn;
    uint Buy_Stage13_Tax;
    uint Buy_Stage14_Burn;
    uint Buy_Stage14_Tax;

    constructor() {
        Whale1_Burn = Whale1_Tax = Whale2_Burn = Whale2_Tax = Whale3_Burn = Whale3_Tax = Whale4_Burn = Whale4_Tax = Whale5_Burn = Whale5_Tax = Whale6_Burn = Whale6_Tax = Whale7_Burn = Whale7_Tax = Whale8_Burn = Whale8_Tax = Whale9_Burn = Whale9_Tax = Whale10_Burn = Whale10_Tax = Whale11_Burn = Whale11_Tax = Whale12_Burn = Whale12_Tax = Whale13_Burn = Whale13_Tax = Whale14_Burn = Whale14_Tax = Buy_Stage1_Burn = Buy_Stage1_Tax = Buy_Stage2_Burn = Buy_Stage2_Tax = Buy_Stage3_Burn = Buy_Stage3_Tax = Buy_Stage4_Burn = Buy_Stage4_Tax = Buy_Stage5_Burn = Buy_Stage5_Tax = Buy_Stage6_Burn = Buy_Stage6_Tax = Buy_Stage7_Burn = Buy_Stage7_Tax = Buy_Stage8_Burn = Buy_Stage8_Tax = Buy_Stage9_Burn = Buy_Stage9_Tax = Buy_Stage10_Burn = Buy_Stage10_Tax = Buy_Stage11_Burn = Buy_Stage11_Tax = Buy_Stage12_Burn = Buy_Stage12_Tax = Buy_Stage13_Burn = Buy_Stage13_Tax = Buy_Stage14_Burn = Buy_Stage14_Tax = 3;
    }
    function Get_Owner_Tax() public view returns(bool){
        return Owner_Tax;
    }
    function Get_Whale1_Burn() public view returns(uint){
        return Whale1_Burn;
    }
    function Get_Whale1_Tax() public view returns(uint){
        return Whale1_Tax;
    }
    function Get_Whale2_Burn() public view returns(uint){
        return Whale2_Burn;
    }
    function Get_Whale2_Tax() public view returns(uint){
        return Whale2_Tax;
    }
    function Get_Whale3_Burn() public view returns(uint){
        return Whale3_Burn;
    }
    function Get_Whale3_Tax() public view returns(uint){
        return Whale3_Tax;
    }
    function Get_Whale4_Burn() public view returns(uint){
        return Whale4_Burn;
    }
    function Get_Whale4_Tax() public view returns(uint){
        return Whale4_Tax;
    }
    function Get_Whale5_Burn() public view returns(uint){
        return Whale5_Burn;
    }
    function Get_Whale5_Tax() public view returns(uint){
        return Whale5_Tax;
    }
    function Get_Whale6_Burn() public view returns(uint){
        return Whale6_Burn;
    }
    function Get_Whale6_Tax() public view returns(uint){
        return Whale6_Tax;
    }
    function Get_Whale7_Burn() public view returns(uint){
        return Whale7_Burn;
    }
    function Get_Whale7_Tax() public view returns(uint){
        return Whale7_Tax;
    }
    function Get_Whale8_Burn() public view returns(uint){
        return Whale8_Burn;
    }
    function Get_Whale8_Tax() public view returns(uint){
        return Whale8_Tax;
    }
    function Get_Whale9_Burn() public view returns(uint){
        return Whale9_Burn;
    }
    function Get_Whale9_Tax() public view returns(uint){
        return Whale9_Tax;
    }
    function Get_Whale10_Burn() public view returns(uint){
        return Whale10_Burn;
    }
    function Get_Whale10_Tax() public view returns(uint){
        return Whale10_Tax;
    }
    function Get_Whale11_Burn() public view returns(uint){
        return Whale11_Burn;
    }
    function Get_Whale11_Tax() public view returns(uint){
        return Whale11_Tax;
    }
    function Get_Whale12_Burn() public view returns(uint){
        return Whale12_Burn;
    }
    function Get_Whale12_Tax() public view returns(uint){
        return Whale12_Tax;
    }
    function Get_Whale13_Burn() public view returns(uint){
        return Whale13_Burn;
    }
    function Get_Whale13_Tax() public view returns(uint){
        return Whale13_Tax;
    }
    function Get_Whale14_Burn() public view returns(uint){
        return Whale14_Burn;
    }
    function Get_Whale14_Tax() public view returns(uint){
        return Whale14_Tax;
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
    function Get_Buy_Stage13_Burn() public view returns(uint){
        return Buy_Stage13_Burn;
    }
    function Get_Buy_Stage13_Tax() public view returns(uint){
        return Buy_Stage13_Tax;
    }
    function Get_Buy_Stage14_Burn() public view returns(uint){
        return Buy_Stage14_Burn;
    }
    function Get_Buy_Stage14_Tax() public view returns(uint){
        return Buy_Stage14_Tax;
    }
    function Set_Owner_Tax(bool _Owner_Tax) public {
        Owner_Tax = _Owner_Tax;
    }
    function Set_Whale1_Burn(uint _Whale1_Burn) public {
        if(msg.sender == owner) {
            Whale1_Burn = Whale2_Burn = Whale3_Burn = Whale4_Burn = Whale5_Burn = Whale6_Burn = Whale7_Burn = Whale8_Burn = Whale9_Burn = Whale10_Burn = Whale11_Burn = Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale1_Burn;
        }
    }
    function Set_Whale1_Tax(uint _Whale1_Tax) public {
        if(msg.sender == owner) {
            Whale1_Tax = Whale2_Tax = Whale3_Tax = Whale4_Tax = Whale5_Tax = Whale6_Tax = Whale7_Tax = Whale8_Tax = Whale9_Tax = Whale10_Tax = Whale11_Tax = Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale1_Tax;
        }
    }
    function Set_Whale2_Burn(uint _Whale2_Burn) public {
        if(msg.sender == owner) {
            Whale2_Burn = Whale3_Burn = Whale4_Burn = Whale5_Burn = Whale6_Burn = Whale7_Burn = Whale8_Burn = Whale9_Burn = Whale10_Burn = Whale11_Burn = Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale2_Burn;
        }
    }
    function Set_Whale2_Tax(uint _Whale2_Tax) public {
        if(msg.sender == owner) {
            Whale2_Tax = Whale3_Tax = Whale4_Tax = Whale5_Tax = Whale6_Tax = Whale7_Tax = Whale8_Tax = Whale9_Tax = Whale10_Tax = Whale11_Tax = Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale2_Tax;
        }
    }
    function Set_Whale3_Burn(uint _Whale3_Burn) public {
        if(msg.sender == owner) {
            Whale3_Burn = Whale4_Burn = Whale5_Burn = Whale6_Burn = Whale7_Burn = Whale8_Burn = Whale9_Burn = Whale10_Burn = Whale11_Burn = Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale3_Burn;
        }
    }
    function Set_Whale3_Tax(uint _Whale3_Tax) public {
        if(msg.sender == owner) {
            Whale3_Tax = Whale4_Tax = Whale5_Tax = Whale6_Tax = Whale7_Tax = Whale8_Tax = Whale9_Tax = Whale10_Tax = Whale11_Tax = Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale3_Tax;
        }
    }
    function Set_Whale4_Burn(uint _Whale4_Burn) public {
        if(msg.sender == owner) {
            Whale4_Burn = Whale5_Burn = Whale6_Burn = Whale7_Burn = Whale8_Burn = Whale9_Burn = Whale10_Burn = Whale11_Burn = Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale4_Burn;
        }
    }
    function Set_Whale4_Tax(uint _Whale4_Tax) public {
        if(msg.sender == owner) {
            Whale4_Tax = Whale5_Tax = Whale6_Tax = Whale7_Tax = Whale8_Tax = Whale9_Tax = Whale10_Tax = Whale11_Tax = Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale4_Tax;
        }
    }
    function Set_Whale5_Burn(uint _Whale5_Burn) public {
        if(msg.sender == owner) {
            Whale5_Burn = Whale6_Burn = Whale7_Burn = Whale8_Burn = Whale9_Burn = Whale10_Burn = Whale11_Burn = Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale5_Burn;
        }
    }
    function Set_Whale5_Tax(uint _Whale5_Tax) public {
        if(msg.sender == owner) {
            Whale5_Tax = Whale6_Tax = Whale7_Tax = Whale8_Tax = Whale9_Tax = Whale10_Tax = Whale11_Tax = Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale5_Tax;
        }
    }
    function Set_Whale6_Burn(uint _Whale6_Burn) public {
        if(msg.sender == owner) {
            Whale6_Burn = Whale7_Burn = Whale8_Burn = Whale9_Burn = Whale10_Burn = Whale11_Burn = Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale6_Burn;
        }
    }
    function Set_Whale6_Tax(uint _Whale6_Tax) public {
        if(msg.sender == owner) {
            Whale6_Tax = Whale7_Tax = Whale8_Tax = Whale9_Tax = Whale10_Tax = Whale11_Tax = Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale6_Tax;
        }
    }
    function Set_Whale7_Burn(uint _Whale7_Burn) public {
        if(msg.sender == owner) {
            Whale7_Burn = Whale8_Burn = Whale9_Burn = Whale10_Burn = Whale11_Burn = Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale7_Burn;
        }
    }
    function Set_Whale7_Tax(uint _Whale7_Tax) public {
        if(msg.sender == owner) {
            Whale7_Tax = Whale8_Tax = Whale9_Tax = Whale10_Tax = Whale11_Tax = Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale7_Tax;
        }
    }
    function Set_Whale8_Burn(uint _Whale8_Burn) public {
        if(msg.sender == owner) {
            Whale8_Burn = Whale9_Burn = Whale10_Burn = Whale11_Burn = Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale8_Burn;
        }
    }
    function Set_Whale8_Tax(uint _Whale8_Tax) public {
        if(msg.sender == owner) {
        Whale8_Tax = Whale9_Tax = Whale10_Tax = Whale11_Tax = Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale8_Tax;
        }
    }
    function Set_Whale9_Burn(uint _Whale9_Burn) public {
        if(msg.sender == owner) {
            Whale9_Burn = Whale10_Burn = Whale11_Burn = Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale9_Burn;
        }
    }
    function Set_Whale9_Tax(uint _Whale9_Tax) public {
        if(msg.sender == owner) {
            Whale9_Tax = Whale10_Tax = Whale11_Tax = Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale9_Tax;
        }
    }
    function Set_Whale10_Burn(uint _Whale10_Burn) public {
        if(msg.sender == owner) {
            Whale10_Burn = Whale11_Burn = Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale10_Burn;
        }
    }
    function Set_Whale10_Tax(uint _Whale10_Tax) public {
        if(msg.sender == owner) {
            Whale10_Tax = Whale11_Tax = Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale10_Tax;
        }
    }
    function Set_Whale11_Burn(uint _Whale11_Burn) public {
        if(msg.sender == owner) {
            Whale11_Burn = Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale11_Burn;
        }
    }
    function Set_Whale11_Tax(uint _Whale11_Tax) public {
        if(msg.sender == owner) {
            Whale11_Tax = Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale11_Tax;
        }
    }
    function Set_Whale12_Burn(uint _Whale12_Burn) public {
        if(msg.sender == owner) {
            Whale12_Burn = Whale13_Burn = Whale14_Burn = _Whale12_Burn;
        }
    }
    function Set_Whale12_Tax(uint _Whale12_Tax) public {
        if(msg.sender == owner) {
            Whale12_Tax = Whale13_Tax = Whale14_Tax = _Whale12_Tax;
        }
    }
    function Set_Whale13_Burn(uint _Whale13_Burn) public {
        if(msg.sender == owner) {
            Whale13_Burn = Whale14_Burn = _Whale13_Burn;
        }
    }
    function Set_Whale13_Tax(uint _Whale13_Tax) public {
        if(msg.sender == owner) {
            Whale13_Tax = Whale14_Tax = _Whale13_Tax;
        }
    }
    function Set_Whale14_Burn(uint _Whale14_Burn) public {
        if(msg.sender == owner) {
            Whale14_Burn = _Whale14_Burn;
        }
    }
    function Set_Whale14_Tax(uint _Whale14_Tax) public {
        if(msg.sender == owner) {
            Whale14_Tax = _Whale14_Tax;
        }
    }
    function Set_Buy_Stage1_Burn(uint _Buy_Stage1_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage1_Burn =  Buy_Stage2_Burn =  Buy_Stage3_Burn =  Buy_Stage4_Burn =  Buy_Stage5_Burn =  Buy_Stage6_Burn =  Buy_Stage7_Burn =  Buy_Stage8_Burn =  Buy_Stage9_Burn =  Buy_Stage10_Burn =  Buy_Stage11_Burn =  Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage1_Burn;
        }
    }
    function Set_Buy_Stage1_Tax(uint _Buy_Stage1_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage1_Tax =  Buy_Stage2_Tax =  Buy_Stage3_Tax =  Buy_Stage4_Tax =  Buy_Stage5_Tax =  Buy_Stage6_Tax =  Buy_Stage7_Tax =  Buy_Stage8_Tax =  Buy_Stage9_Tax =  Buy_Stage10_Tax =  Buy_Stage11_Tax =  Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage1_Tax;
        }
    }
    function Set_Buy_Stage2_Burn(uint _Buy_Stage2_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage2_Burn =  Buy_Stage3_Burn =  Buy_Stage4_Burn =  Buy_Stage5_Burn =  Buy_Stage6_Burn =  Buy_Stage7_Burn =  Buy_Stage8_Burn =  Buy_Stage9_Burn =  Buy_Stage10_Burn =  Buy_Stage11_Burn =  Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage2_Burn;
        }
    }
    function Set_Buy_Stage2_Tax(uint _Buy_Stage2_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage2_Tax =  Buy_Stage3_Tax =  Buy_Stage4_Tax =  Buy_Stage5_Tax =  Buy_Stage6_Tax =  Buy_Stage7_Tax =  Buy_Stage8_Tax =  Buy_Stage9_Tax =  Buy_Stage10_Tax =  Buy_Stage11_Tax =  Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage2_Tax;
        }
    }
    function Set_Buy_Stage3_Burn(uint _Buy_Stage3_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage3_Burn =  Buy_Stage4_Burn =  Buy_Stage5_Burn =  Buy_Stage6_Burn =  Buy_Stage7_Burn =  Buy_Stage8_Burn =  Buy_Stage9_Burn =  Buy_Stage10_Burn =  Buy_Stage11_Burn =  Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage3_Burn;
        }
    }
    function Set_Buy_Stage3_Tax(uint _Buy_Stage3_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage3_Tax =  Buy_Stage4_Tax =  Buy_Stage5_Tax =  Buy_Stage6_Tax =  Buy_Stage7_Tax =  Buy_Stage8_Tax =  Buy_Stage9_Tax =  Buy_Stage10_Tax =  Buy_Stage11_Tax =  Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage3_Tax;
        }
    }
    function Set_Buy_Stage4_Burn(uint _Buy_Stage4_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage4_Burn =  Buy_Stage5_Burn =  Buy_Stage6_Burn =  Buy_Stage7_Burn =  Buy_Stage8_Burn =  Buy_Stage9_Burn =  Buy_Stage10_Burn =  Buy_Stage11_Burn =  Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage4_Burn;
        }
    }
    function Set_Buy_Stage4_Tax(uint _Buy_Stage4_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage4_Tax =  Buy_Stage5_Tax =  Buy_Stage6_Tax =  Buy_Stage7_Tax =  Buy_Stage8_Tax =  Buy_Stage9_Tax =  Buy_Stage10_Tax =  Buy_Stage11_Tax =  Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage4_Tax;
        }
    }
    function Set_Buy_Stage5_Burn(uint _Buy_Stage5_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage5_Burn =  Buy_Stage6_Burn =  Buy_Stage7_Burn =  Buy_Stage8_Burn =  Buy_Stage9_Burn =  Buy_Stage10_Burn =  Buy_Stage11_Burn =  Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage5_Burn;
        }
    }
    function Set_Buy_Stage5_Tax(uint _Buy_Stage5_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage5_Tax =  Buy_Stage6_Tax =  Buy_Stage7_Tax =  Buy_Stage8_Tax =  Buy_Stage9_Tax =  Buy_Stage10_Tax =  Buy_Stage11_Tax =  Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage5_Tax;
        }
    }
    function Set_Buy_Stage6_Burn(uint _Buy_Stage6_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage6_Burn =  Buy_Stage7_Burn =  Buy_Stage8_Burn =  Buy_Stage9_Burn =  Buy_Stage10_Burn =  Buy_Stage11_Burn =  Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage6_Burn;
        }
    }
    function Set_Buy_Stage6_Tax(uint _Buy_Stage6_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage6_Tax =  Buy_Stage7_Tax =  Buy_Stage8_Tax =  Buy_Stage9_Tax =  Buy_Stage10_Tax =  Buy_Stage11_Tax =  Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage6_Tax;
        }
    }
    function Set_Buy_Stage7_Burn(uint _Buy_Stage7_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage7_Burn =  Buy_Stage8_Burn =  Buy_Stage9_Burn =  Buy_Stage10_Burn =  Buy_Stage11_Burn =  Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage7_Burn;
        }
    }
    function Set_Buy_Stage7_Tax(uint _Buy_Stage7_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage7_Tax =  Buy_Stage8_Tax =  Buy_Stage9_Tax =  Buy_Stage10_Tax =  Buy_Stage11_Tax =  Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage7_Tax;
        }
    }
    function Set_Buy_Stage8_Burn(uint _Buy_Stage8_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage8_Burn =  Buy_Stage9_Burn =  Buy_Stage10_Burn =  Buy_Stage11_Burn =  Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage8_Burn;
        }
    }
    function Set_Buy_Stage8_Tax(uint _Buy_Stage8_Tax) public {
        if(msg.sender == owner) {
         Buy_Stage8_Tax =  Buy_Stage9_Tax =  Buy_Stage10_Tax =  Buy_Stage11_Tax =  Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage8_Tax;
        }
    }
    function Set_Buy_Stage9_Burn(uint _Buy_Stage9_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage9_Burn =  Buy_Stage10_Burn =  Buy_Stage11_Burn =  Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage9_Burn;
        }
    }
    function Set_Buy_Stage9_Tax(uint _Buy_Stage9_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage9_Tax =  Buy_Stage10_Tax =  Buy_Stage11_Tax =  Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage9_Tax;
        }
    }
    function Set_Buy_Stage10_Burn(uint _Buy_Stage10_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage10_Burn =  Buy_Stage11_Burn =  Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage10_Burn;
        }
    }
    function Set_Buy_Stage10_Tax(uint _Buy_Stage10_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage10_Tax =  Buy_Stage11_Tax =  Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage10_Tax;
        }
    }
    function Set_Buy_Stage11_Burn(uint _Buy_Stage11_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage11_Burn =  Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage11_Burn;
        }
    }
    function Set_Buy_Stage11_Tax(uint _Buy_Stage11_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage11_Tax =  Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage11_Tax;
        }
    }
    function Set_Buy_Stage12_Burn(uint _Buy_Stage12_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage12_Burn = Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage12_Burn;
        }
    }
    function Set_Buy_Stage12_Tax(uint _Buy_Stage12_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage12_Tax = Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage12_Tax;
        }
    }
    function Set_Buy_Stage13_Burn(uint _Buy_Stage13_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage13_Burn = Buy_Stage14_Burn = _Buy_Stage13_Burn;
        }
    }
    function Set_Buy_Stage13_Tax(uint _Buy_Stage13_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage13_Tax = Buy_Stage14_Tax = _Buy_Stage13_Tax;
        }
    }
    function Set_Buy_Stage14_Burn(uint _Buy_Stage14_Burn) public {
        if(msg.sender == owner) {
             Buy_Stage14_Burn = _Buy_Stage14_Burn;
        }
    }
    function Set_Buy_Stage14_Tax(uint _Buy_Stage14_Tax) public {
        if(msg.sender == owner) {
             Buy_Stage14_Tax = _Buy_Stage14_Tax;
        }
    }
}

contract Simba is ERC20, Tax {
    using SafeMath for uint256;
    mapping(address => bool) public exclidedFromTax;
    uint adminAmount;
    uint burnAmount;
    address adr;
    address swap_adr1;
    address swap_adr2;

    constructor() ERC20('Simba Lion', 'Simba') {
        _mint(msg.sender, 1000000000000000 * 10 ** 18);
        owner = msg.sender;
        exclidedFromTax[msg.sender] = true;
        Owner_Tax = true;
    }
    function Get_Owner() public view returns(address){
        return owner;
    }
    function transferOwnership(address newOwner) public {
        if (msg.sender == owner) {
            owner = newOwner;
        }
    }
    function Get_Swap_Address1() public view returns(address){
        return swap_adr1;
    }
    function Get_Swap_Address2() public view returns(address){
        return swap_adr2;
    }
    function Set_Swap_Address1(address _swap_adr1) public {
        if(msg.sender == owner) {
            swap_adr1 = _swap_adr1;
        }
    }
    function Set_Swap_Address2(address _swap_adr2) public {
        if(msg.sender == owner) {
            swap_adr2 = _swap_adr2;
        }
    }

    function transfer(address recipient,uint256 amount) public override returns (bool) {
        if(exclidedFromTax[msg.sender] == true || msg.sender == swap_adr1 || msg.sender == swap_adr2) {
            if(Owner_Tax == true) {
                _transfer(_msgSender(), recipient, amount);
            }
            else {
                if(recipient == address(0x000000000000000000000000000000000000dEaD)) {
                    burnAmount = amount;
                    adminAmount = amount.mul(0) / 100;
                }
                else if(amount <= 100 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage1_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage1_Tax) / 100;
                }
                else if(amount > 100 * 10 ** 18 && amount <= 1000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage2_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage2_Tax) / 100;
                }
                else if(amount > 1000 * 10 ** 18 && amount <= 10000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage3_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage3_Tax) / 100;
                }
                else if(amount > 10000 * 10 ** 18 && amount <= 100000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage4_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage4_Tax) / 100;
                }
                else if(amount > 100000 * 10 ** 18 && amount <= 1000000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage5_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage5_Tax) / 100;
                }
                else if(amount > 1000000 * 10 ** 18 && amount <= 10000000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage6_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage6_Tax) / 100;
                }
                else if(amount > 10000000 * 10 ** 18 && amount <= 100000000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage7_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage7_Tax) / 100;
                }
                else if(amount > 100000000 * 10 ** 18 && amount <= 1000000000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage8_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage8_Tax) / 100;
                }
                else if(amount > 1000000000 * 10 ** 18 && amount <= 10000000000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage9_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage9_Tax) / 100;
                }
                else if(amount > 10000000000 * 10 ** 18 && amount <= 50000000000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage10_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage10_Tax) / 100;
                }
                else if(amount > 50000000000 * 10 ** 18 && amount <= 100000000000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage11_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage11_Tax) / 100;
                }
                else if(amount > 100000000000 * 10 ** 18 && amount <= 500000000000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage12_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage12_Tax) / 100;
                }
                else if(amount > 500000000000 * 10 ** 18 && amount <= 1000000000000 * 10 ** 18) {
                    burnAmount = amount.mul(Buy_Stage13_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage13_Tax) / 100;
                }
                else {
                    burnAmount = amount.mul(Buy_Stage14_Burn) / 100;
                    adminAmount = amount.mul(Buy_Stage14_Tax) / 100;
                }
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            } 
        }
        else {
            if(recipient == address(0x000000000000000000000000000000000000dEaD)) {
                burnAmount = amount;
                adminAmount = amount.mul(0) / 100;
            }
            else if(amount <= 100 * 10 ** 18) {
                burnAmount = amount.mul(Whale1_Burn) / 100;
                adminAmount = amount.mul(Whale1_Tax) / 100;
            }
            else if(amount > 100 * 10 ** 18 && amount <= 1000 * 10 ** 18) {
                burnAmount = amount.mul(Whale2_Burn) / 100;
                adminAmount = amount.mul(Whale2_Tax) / 100;
            }
            else if(amount > 1000 * 10 ** 18 && amount <= 10000 * 10 ** 18) {
                burnAmount = amount.mul(Whale3_Burn) / 100;
                adminAmount = amount.mul(Whale3_Tax) / 100;
            }
            else if(amount > 10000 * 10 ** 18 && amount <= 100000 * 10 ** 18) {
                burnAmount = amount.mul(Whale4_Burn) / 100;
                adminAmount = amount.mul(Whale4_Tax) / 100;
            }
            else if(amount > 100000 * 10 ** 18 && amount <= 1000000 * 10 ** 18) {
                burnAmount = amount.mul(Whale5_Burn) / 100;
                adminAmount = amount.mul(Whale5_Tax) / 100;
            }
            else if(amount > 1000000 * 10 ** 18 && amount <= 10000000 * 10 ** 18) {
                burnAmount = amount.mul(Whale6_Burn) / 100;
                adminAmount = amount.mul(Whale6_Tax) / 100;
            }
            else if(amount > 10000000 * 10 ** 18 && amount <= 100000000 * 10 ** 18) {
                burnAmount = amount.mul(Whale7_Burn) / 100;
                adminAmount = amount.mul(Whale7_Tax) / 100;
            }
            else if(amount > 100000000 * 10 ** 18 && amount <= 1000000000 * 10 ** 18) {
                burnAmount = amount.mul(Whale8_Burn) / 100;
                adminAmount = amount.mul(Whale8_Tax) / 100;
            }
            else if(amount > 1000000000 * 10 ** 18 && amount <= 10000000000 * 10 ** 18) {
                burnAmount = amount.mul(Whale9_Burn) / 100;
                adminAmount = amount.mul(Whale9_Tax) / 100;
            }
            else if(amount > 10000000000 * 10 ** 18 && amount <= 50000000000 * 10 ** 18) {
                burnAmount = amount.mul(Whale10_Burn) / 100;
                adminAmount = amount.mul(Whale10_Tax) / 100;
            }
            else if(amount > 50000000000 * 10 ** 18 && amount <= 100000000000 * 10 ** 18) {
                burnAmount = amount.mul(Whale11_Burn) / 100;
                adminAmount = amount.mul(Whale11_Tax) / 100;
            }
            else if(amount > 100000000000 * 10 ** 18 && amount <= 500000000000 * 10 ** 18) {
                burnAmount = amount.mul(Whale12_Burn) / 100;
                adminAmount = amount.mul(Whale12_Tax) / 100;
            }
            else if(amount > 500000000000 * 10 ** 18 && amount <= 1000000000000 * 10 ** 18) {
                burnAmount = amount.mul(Whale13_Burn) / 100;
                adminAmount = amount.mul(Whale13_Tax) / 100;
            }
            else {
                burnAmount = amount.mul(Whale14_Burn) / 100;
                adminAmount = amount.mul(Whale14_Tax) / 100;
            }
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), owner, adminAmount);
            _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
        }
        return true;
    }
}