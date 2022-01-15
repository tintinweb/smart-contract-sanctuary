/**
 *Submitted for verification at polygonscan.com on 2022-01-14
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
contract Simba is ERC20 {
    using SafeMath for uint256;
    address public owner;
    mapping(address => bool) public exclidedFromTax;
    bool Owner_Tax;
    uint Stage1_Burn;
    uint Stage1_Tax;
    uint Stage2_Burn;
    uint Stage2_Tax;
    uint Stage3_Burn;
    uint Stage3_Tax;
    uint Stage4_Burn;
    uint Stage4_Tax;
    uint Stage5_Burn;
    uint Stage5_Tax;
    uint Stage6_Burn;
    uint Stage6_Tax;
    uint Stage7_Burn;
    uint Stage7_Tax;
    uint Stage8_Burn;
    uint Stage8_Tax;
    uint Stage9_Burn;
    uint Stage9_Tax;
    uint Stage10_Burn;
    uint Stage10_Tax;
    uint Stage11_Burn;
    uint Stage11_Tax;
    uint Stage12_Burn;
    uint Stage12_Tax;
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
    address swap_address;

    constructor() ERC20('Simba', 'Simba Lion') {
        Stage1_Burn = 3;
        Stage1_Tax = 3;
        Stage2_Burn = 3;
        Stage2_Tax = 3;
        Stage3_Burn = 3;
        Stage3_Tax = 3;
        Stage4_Burn = 3;
        Stage4_Tax = 3;
        Stage5_Burn = 3;
        Stage5_Tax = 3;
        Stage6_Burn = 3;
        Stage6_Tax = 3;
        Stage7_Burn = 3;
        Stage7_Tax = 3;
        Stage8_Burn = 3;
        Stage8_Tax = 3;
        Stage9_Burn = 3;
        Stage9_Tax = 3;
        Stage10_Burn = 3;
        Stage10_Tax = 3;
        Stage11_Burn = 3;
        Stage11_Tax = 3;
        Stage12_Burn = 3;
        Stage12_Tax = 3;
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
        _mint(msg.sender, 2000000000000 * 10 ** 18);
        owner = msg.sender;
        exclidedFromTax[msg.sender] = true;
        Owner_Tax = true;
    }
    function Get_Swap_Address() public view returns(address){
        return swap_address;
    }
    function Set_Swap_Address(address _swap_address) public {
        swap_address = _swap_address;
    }
    
    function Get_Owner_Tax() public view returns(bool){
        return Owner_Tax;
    }
    function Get_Stage1_Burn() public view returns(uint){
        return Stage1_Burn;
    }
    function Get_Stage1_Tax() public view returns(uint){
        return Stage1_Tax;
    }
    function Get_Stage2_Burn() public view returns(uint){
        return Stage2_Burn;
    }
    function Get_Stage2_Tax() public view returns(uint){
        return Stage2_Tax;
    }
    function Get_Stage3_Burn() public view returns(uint){
        return Stage3_Burn;
    }
    function Get_Stage3_Tax() public view returns(uint){
        return Stage3_Tax;
    }
    function Get_Stage4_Burn() public view returns(uint){
        return Stage4_Burn;
    }
    function Get_Stage4_Tax() public view returns(uint){
        return Stage4_Tax;
    }
    function Get_Stage5_Burn() public view returns(uint){
        return Stage5_Burn;
    }
    function Get_Stage5_Tax() public view returns(uint){
        return Stage5_Tax;
    }
    function Get_Stage6_Burn() public view returns(uint){
        return Stage6_Burn;
    }
    function Get_Stage6_Tax() public view returns(uint){
        return Stage6_Tax;
    }
    function Get_Stage7_Burn() public view returns(uint){
        return Stage7_Burn;
    }
    function Get_Stage7_Tax() public view returns(uint){
        return Stage7_Tax;
    }
    function Get_Stage8_Burn() public view returns(uint){
        return Stage8_Burn;
    }
    function Get_Stage8_Tax() public view returns(uint){
        return Stage8_Tax;
    }
    function Get_Stage9_Burn() public view returns(uint){
        return Stage9_Burn;
    }
    function Get_Stage9_Tax() public view returns(uint){
        return Stage9_Tax;
    }
    function Get_Stage10_Burn() public view returns(uint){
        return Stage10_Burn;
    }
    function Get_Stage10_Tax() public view returns(uint){
        return Stage10_Tax;
    }
    function Get_Stage11_Burn() public view returns(uint){
        return Stage11_Burn;
    }
    function Get_Stage11_Tax() public view returns(uint){
        return Stage11_Tax;
    }
    function Get_Stage12_Burn() public view returns(uint){
        return Stage12_Burn;
    }
    function Get_Stage12_Tax() public view returns(uint){
        return Stage12_Tax;
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
    function Set_Owner_Tax(bool _Owner_Tax) public {
        Owner_Tax = _Owner_Tax;
    }
    function Set_Whale1_Burn(uint _Whale1_Burn) public {
        if(msg.sender == owner) {
            Stage1_Burn = _Whale1_Burn;
            Stage2_Burn = _Whale1_Burn;
            Stage3_Burn = _Whale1_Burn;
            Stage4_Burn = _Whale1_Burn;
            Stage5_Burn = _Whale1_Burn;
            Stage6_Burn = _Whale1_Burn;
            Stage7_Burn = _Whale1_Burn;
            Stage8_Burn = _Whale1_Burn;
            Stage9_Burn = _Whale1_Burn;
            Stage10_Burn = _Whale1_Burn;
            Stage11_Burn = _Whale1_Burn;
            Stage12_Burn = _Whale1_Burn;
        }
    }
    function Set_Whale1_Tax(uint _Whale1_Tax) public {
        if(msg.sender == owner) {
            Stage1_Tax = _Whale1_Tax;
            Stage2_Tax = _Whale1_Tax;
            Stage3_Tax = _Whale1_Tax;
            Stage4_Tax = _Whale1_Tax;
            Stage5_Tax = _Whale1_Tax;
            Stage6_Tax = _Whale1_Tax;
            Stage7_Tax = _Whale1_Tax;
            Stage8_Tax = _Whale1_Tax;
            Stage9_Tax = _Whale1_Tax;
            Stage10_Tax = _Whale1_Tax;
            Stage11_Tax = _Whale1_Tax;
            Stage12_Tax = _Whale1_Tax;
        }
    }
    function Set_Whale2_Burn(uint _Whale2_Burn) public {
        if(msg.sender == owner) {
            Stage2_Burn = _Whale2_Burn;
            Stage3_Burn = _Whale2_Burn;
            Stage4_Burn = _Whale2_Burn;
            Stage5_Burn = _Whale2_Burn;
            Stage6_Burn = _Whale2_Burn;
            Stage7_Burn = _Whale2_Burn;
            Stage8_Burn = _Whale2_Burn;
            Stage9_Burn = _Whale2_Burn;
            Stage10_Burn = _Whale2_Burn;
            Stage11_Burn = _Whale2_Burn;
            Stage12_Burn = _Whale2_Burn;
        }
    }
    function Set_Whale2_Tax(uint _Whale2_Tax) public {
        if(msg.sender == owner) {
            Stage2_Tax = _Whale2_Tax;
            Stage3_Tax = _Whale2_Tax;
            Stage4_Tax = _Whale2_Tax;
            Stage5_Tax = _Whale2_Tax;
            Stage6_Tax = _Whale2_Tax;
            Stage7_Tax = _Whale2_Tax;
            Stage8_Tax = _Whale2_Tax;
            Stage9_Tax = _Whale2_Tax;
            Stage10_Tax = _Whale2_Tax;
            Stage11_Tax = _Whale2_Tax;
            Stage12_Tax = _Whale2_Tax;
        }
    }
    function Set_Whale3_Burn(uint _Whale3_Burn) public {
        if(msg.sender == owner) {
            Stage3_Burn = _Whale3_Burn;
            Stage4_Burn = _Whale3_Burn;
            Stage5_Burn = _Whale3_Burn;
            Stage6_Burn = _Whale3_Burn;
            Stage7_Burn = _Whale3_Burn;
            Stage8_Burn = _Whale3_Burn;
            Stage9_Burn = _Whale3_Burn;
            Stage10_Burn = _Whale3_Burn;
            Stage11_Burn = _Whale3_Burn;
            Stage12_Burn = _Whale3_Burn;
        }
    }
    function Set_Whale3_Tax(uint _Whale3_Tax) public {
        if(msg.sender == owner) {
            Stage3_Tax = _Whale3_Tax;
            Stage4_Tax = _Whale3_Tax;
            Stage5_Tax = _Whale3_Tax;
            Stage6_Tax = _Whale3_Tax;
            Stage7_Tax = _Whale3_Tax;
            Stage8_Tax = _Whale3_Tax;
            Stage9_Tax = _Whale3_Tax;
            Stage10_Tax = _Whale3_Tax;
            Stage11_Tax = _Whale3_Tax;
            Stage12_Tax = _Whale3_Tax;
        }
    }
    function Set_Whale4_Burn(uint _Whale4_Burn) public {
        if(msg.sender == owner) {
            Stage4_Burn = _Whale4_Burn;
            Stage5_Burn = _Whale4_Burn;
            Stage6_Burn = _Whale4_Burn;
            Stage7_Burn = _Whale4_Burn;
            Stage8_Burn = _Whale4_Burn;
            Stage9_Burn = _Whale4_Burn;
            Stage10_Burn = _Whale4_Burn;
            Stage11_Burn = _Whale4_Burn;
            Stage12_Burn = _Whale4_Burn;
        }
    }
    function Set_Whale4_Tax(uint _Whale4_Tax) public {
        if(msg.sender == owner) {
            Stage4_Tax = _Whale4_Tax;
            Stage5_Tax = _Whale4_Tax;
            Stage6_Tax = _Whale4_Tax;
            Stage7_Tax = _Whale4_Tax;
            Stage8_Tax = _Whale4_Tax;
            Stage9_Tax = _Whale4_Tax;
            Stage10_Tax = _Whale4_Tax;
            Stage11_Tax = _Whale4_Tax;
            Stage12_Tax = _Whale4_Tax;
        }
    }
    function Set_Whale5_Burn(uint _Whale5_Burn) public {
        if(msg.sender == owner) {
            Stage5_Burn = _Whale5_Burn;
            Stage6_Burn = _Whale5_Burn;
            Stage7_Burn = _Whale5_Burn;
            Stage8_Burn = _Whale5_Burn;
            Stage9_Burn = _Whale5_Burn;
            Stage10_Burn = _Whale5_Burn;
            Stage11_Burn = _Whale5_Burn;
            Stage12_Burn = _Whale5_Burn;
        }
    }
    function Set_Whale5_Tax(uint _Whale5_Tax) public {
        if(msg.sender == owner) {
            Stage5_Tax = _Whale5_Tax;
            Stage6_Tax = _Whale5_Tax;
            Stage7_Tax = _Whale5_Tax;
            Stage8_Tax = _Whale5_Tax;
            Stage9_Tax = _Whale5_Tax;
            Stage10_Tax = _Whale5_Tax;
            Stage11_Tax = _Whale5_Tax;
            Stage12_Tax = _Whale5_Tax;
        }
    }
    function Set_Whale6_Burn(uint _Whale6_Burn) public {
        if(msg.sender == owner) {
            Stage6_Burn = _Whale6_Burn;
            Stage7_Burn = _Whale6_Burn;
            Stage8_Burn = _Whale6_Burn;
            Stage9_Burn = _Whale6_Burn;
            Stage10_Burn = _Whale6_Burn;
            Stage11_Burn = _Whale6_Burn;
            Stage12_Burn = _Whale6_Burn;
        }
    }
    function Set_Whale6_Tax(uint _Whale6_Tax) public {
        if(msg.sender == owner) {
            Stage6_Tax = _Whale6_Tax;
            Stage7_Tax = _Whale6_Tax;
            Stage8_Tax = _Whale6_Tax;
            Stage9_Tax = _Whale6_Tax;
            Stage10_Tax = _Whale6_Tax;
            Stage11_Tax = _Whale6_Tax;
            Stage12_Tax = _Whale6_Tax;
        }
    }
    function Set_Whale7_Burn(uint _Whale7_Burn) public {
        if(msg.sender == owner) {
            Stage7_Burn = _Whale7_Burn;
            Stage8_Burn = _Whale7_Burn;
            Stage9_Burn = _Whale7_Burn;
            Stage10_Burn = _Whale7_Burn;
            Stage11_Burn = _Whale7_Burn;
            Stage12_Burn = _Whale7_Burn;
        }
    }
    function Set_Whale7_Tax(uint _Whale7_Tax) public {
        if(msg.sender == owner) {
            Stage7_Tax = _Whale7_Tax;
            Stage8_Tax = _Whale7_Tax;
            Stage9_Tax = _Whale7_Tax;
            Stage10_Tax = _Whale7_Tax;
            Stage11_Tax = _Whale7_Tax;
            Stage12_Tax = _Whale7_Tax;
        }
    }
    function Set_Whale8_Burn(uint _Whale8_Burn) public {
        if(msg.sender == owner) {
            Stage8_Burn = _Whale8_Burn;
            Stage9_Burn = _Whale8_Burn;
            Stage10_Burn = _Whale8_Burn;
            Stage11_Burn = _Whale8_Burn;
            Stage12_Burn = _Whale8_Burn;
        }
    }
    function Set_Whale8_Tax(uint _Whale8_Tax) public {
        if(msg.sender == owner) {
            Stage8_Tax = _Whale8_Tax;
            Stage9_Tax = _Whale8_Tax;
            Stage10_Tax = _Whale8_Tax;
            Stage11_Tax = _Whale8_Tax;
            Stage12_Tax = _Whale8_Tax;
        }
    }
    function Set_Whale9_Burn(uint _Whale9_Burn) public {
        if(msg.sender == owner) {
            Stage9_Burn = _Whale9_Burn;
            Stage10_Burn = _Whale9_Burn;
            Stage11_Burn = _Whale9_Burn;
            Stage12_Burn = _Whale9_Burn;
        }
    }
    function Set_Whale9_Tax(uint _Whale9_Tax) public {
        if(msg.sender == owner) {
            Stage9_Tax = _Whale9_Tax;
            Stage10_Tax = _Whale9_Tax;
            Stage11_Tax = _Whale9_Tax;
            Stage12_Tax = _Whale9_Tax;
        }
    }
    function Set_Whale10_Burn(uint _Whale10_Burn) public {
        if(msg.sender == owner) {
            Stage10_Burn = _Whale10_Burn;
            Stage11_Burn = _Whale10_Burn;
            Stage12_Burn = _Whale10_Burn;
        }
    }
    function Set_Whale10_Tax(uint _Whale10_Tax) public {
        if(msg.sender == owner) {
            Stage10_Tax = _Whale10_Tax;
            Stage11_Tax = _Whale10_Tax;
            Stage12_Tax = _Whale10_Tax;
        }
    }
    function Set_Whale11_Burn(uint _Whale11_Burn) public {
        if(msg.sender == owner) {
            Stage11_Burn = _Whale11_Burn;
            Stage12_Burn = _Whale11_Burn;
        }
    }
    function Set_Whale11_Tax(uint _Whale11_Tax) public {
        if(msg.sender == owner) {
            Stage11_Tax = _Whale11_Tax;
            Stage12_Tax = _Whale11_Tax;
        }
    }
    function Set_Whale12_Burn(uint _Whale12_Burn) public {
        if(msg.sender == owner) {
            Stage12_Burn = _Whale12_Burn;
        }
    }
    function Set_Whale12_Tax(uint _Whale12_Tax) public {
        if(msg.sender == owner) {
            Stage12_Tax = _Whale12_Tax;
        }
    }
    function Set_Buy_Stage1_Burn(uint _Buy_Stage1_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage1_Burn = _Buy_Stage1_Burn;
            Buy_Stage2_Burn = _Buy_Stage1_Burn;
            Buy_Stage3_Burn = _Buy_Stage1_Burn;
            Buy_Stage4_Burn = _Buy_Stage1_Burn;
            Buy_Stage5_Burn = _Buy_Stage1_Burn;
            Buy_Stage6_Burn = _Buy_Stage1_Burn;
            Buy_Stage7_Burn = _Buy_Stage1_Burn;
            Buy_Stage8_Burn = _Buy_Stage1_Burn;
            Buy_Stage9_Burn = _Buy_Stage1_Burn;
            Buy_Stage10_Burn = _Buy_Stage1_Burn;
            Buy_Stage11_Burn = _Buy_Stage1_Burn;
            Buy_Stage12_Burn = _Buy_Stage1_Burn;
        }
    }
    function Set_Buy_Stage1_Tax(uint _Buy_Stage1_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage1_Tax = _Buy_Stage1_Tax;
            Buy_Stage2_Tax = _Buy_Stage1_Tax;
            Buy_Stage3_Tax = _Buy_Stage1_Tax;
            Buy_Stage4_Tax = _Buy_Stage1_Tax;
            Buy_Stage5_Tax = _Buy_Stage1_Tax;
            Buy_Stage6_Tax = _Buy_Stage1_Tax;
            Buy_Stage7_Tax = _Buy_Stage1_Tax;
            Buy_Stage8_Tax = _Buy_Stage1_Tax;
            Buy_Stage9_Tax = _Buy_Stage1_Tax;
            Buy_Stage10_Tax = _Buy_Stage1_Tax;
            Buy_Stage11_Tax = _Buy_Stage1_Tax;
            Buy_Stage12_Tax = _Buy_Stage1_Tax;
        }
    }
    function Set_Buy_Stage2_Burn(uint _Buy_Stage2_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage2_Burn = _Buy_Stage2_Burn;
            Buy_Stage3_Burn = _Buy_Stage2_Burn;
            Buy_Stage4_Burn = _Buy_Stage2_Burn;
            Buy_Stage5_Burn = _Buy_Stage2_Burn;
            Buy_Stage6_Burn = _Buy_Stage2_Burn;
            Buy_Stage7_Burn = _Buy_Stage2_Burn;
            Buy_Stage8_Burn = _Buy_Stage2_Burn;
            Buy_Stage9_Burn = _Buy_Stage2_Burn;
            Buy_Stage10_Burn = _Buy_Stage2_Burn;
            Buy_Stage11_Burn = _Buy_Stage2_Burn;
            Buy_Stage12_Burn = _Buy_Stage2_Burn;
        }
    }
    function Set_Buy_Stage2_Tax(uint _Buy_Stage2_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage2_Tax = _Buy_Stage2_Tax;
            Buy_Stage3_Tax = _Buy_Stage2_Tax;
            Buy_Stage4_Tax = _Buy_Stage2_Tax;
            Buy_Stage5_Tax = _Buy_Stage2_Tax;
            Buy_Stage6_Tax = _Buy_Stage2_Tax;
            Buy_Stage7_Tax = _Buy_Stage2_Tax;
            Buy_Stage8_Tax = _Buy_Stage2_Tax;
            Buy_Stage9_Tax = _Buy_Stage2_Tax;
            Buy_Stage10_Tax = _Buy_Stage2_Tax;
            Buy_Stage11_Tax = _Buy_Stage2_Tax;
            Buy_Stage12_Tax = _Buy_Stage2_Tax;
        }
    }
    function Set_Buy_Stage3_Burn(uint _Buy_Stage3_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage3_Burn = _Buy_Stage3_Burn;
            Buy_Stage4_Burn = _Buy_Stage3_Burn;
            Buy_Stage5_Burn = _Buy_Stage3_Burn;
            Buy_Stage6_Burn = _Buy_Stage3_Burn;
            Buy_Stage7_Burn = _Buy_Stage3_Burn;
            Buy_Stage8_Burn = _Buy_Stage3_Burn;
            Buy_Stage9_Burn = _Buy_Stage3_Burn;
            Buy_Stage10_Burn = _Buy_Stage3_Burn;
            Buy_Stage11_Burn = _Buy_Stage3_Burn;
            Buy_Stage12_Burn = _Buy_Stage3_Burn;
        }
    }
    function Set_Buy_Stage3_Tax(uint _Buy_Stage3_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage3_Tax = _Buy_Stage3_Tax;
            Buy_Stage4_Tax = _Buy_Stage3_Tax;
            Buy_Stage5_Tax = _Buy_Stage3_Tax;
            Buy_Stage6_Tax = _Buy_Stage3_Tax;
            Buy_Stage7_Tax = _Buy_Stage3_Tax;
            Buy_Stage8_Tax = _Buy_Stage3_Tax;
            Buy_Stage9_Tax = _Buy_Stage3_Tax;
            Buy_Stage10_Tax = _Buy_Stage3_Tax;
            Buy_Stage11_Tax = _Buy_Stage3_Tax;
            Buy_Stage12_Tax = _Buy_Stage3_Tax;
        }
    }
    function Set_Buy_Stage4_Burn(uint _Buy_Stage4_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage4_Burn = _Buy_Stage4_Burn;
            Buy_Stage5_Burn = _Buy_Stage4_Burn;
            Buy_Stage6_Burn = _Buy_Stage4_Burn;
            Buy_Stage7_Burn = _Buy_Stage4_Burn;
            Buy_Stage8_Burn = _Buy_Stage4_Burn;
            Buy_Stage9_Burn = _Buy_Stage4_Burn;
            Buy_Stage10_Burn = _Buy_Stage4_Burn;
            Buy_Stage11_Burn = _Buy_Stage4_Burn;
            Buy_Stage12_Burn = _Buy_Stage4_Burn;
        }
    }
    function Set_Buy_Stage4_Tax(uint _Buy_Stage4_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage4_Tax = _Buy_Stage4_Tax;
            Buy_Stage5_Tax = _Buy_Stage4_Tax;
            Buy_Stage6_Tax = _Buy_Stage4_Tax;
            Buy_Stage7_Tax = _Buy_Stage4_Tax;
            Buy_Stage8_Tax = _Buy_Stage4_Tax;
            Buy_Stage9_Tax = _Buy_Stage4_Tax;
            Buy_Stage10_Tax = _Buy_Stage4_Tax;
            Buy_Stage11_Tax = _Buy_Stage4_Tax;
            Buy_Stage12_Tax = _Buy_Stage4_Tax;
        }
    }
    function Set_Buy_Stage5_Burn(uint _Buy_Stage5_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage5_Burn = _Buy_Stage5_Burn;
            Buy_Stage6_Burn = _Buy_Stage5_Burn;
            Buy_Stage7_Burn = _Buy_Stage5_Burn;
            Buy_Stage8_Burn = _Buy_Stage5_Burn;
            Buy_Stage9_Burn = _Buy_Stage5_Burn;
            Buy_Stage10_Burn = _Buy_Stage5_Burn;
            Buy_Stage11_Burn = _Buy_Stage5_Burn;
            Buy_Stage12_Burn = _Buy_Stage5_Burn;
        }
    }
    function Set_Buy_Stage5_Tax(uint _Buy_Stage5_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage5_Tax = _Buy_Stage5_Tax;
            Buy_Stage6_Tax = _Buy_Stage5_Tax;
            Buy_Stage7_Tax = _Buy_Stage5_Tax;
            Buy_Stage8_Tax = _Buy_Stage5_Tax;
            Buy_Stage9_Tax = _Buy_Stage5_Tax;
            Buy_Stage10_Tax = _Buy_Stage5_Tax;
            Buy_Stage11_Tax = _Buy_Stage5_Tax;
            Buy_Stage12_Tax = _Buy_Stage5_Tax;
        }
    }
    function Set_Buy_Stage6_Burn(uint _Buy_Stage6_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage6_Burn = _Buy_Stage6_Burn;
            Buy_Stage7_Burn = _Buy_Stage6_Burn;
            Buy_Stage8_Burn = _Buy_Stage6_Burn;
            Buy_Stage9_Burn = _Buy_Stage6_Burn;
            Buy_Stage10_Burn = _Buy_Stage6_Burn;
            Buy_Stage11_Burn = _Buy_Stage6_Burn;
            Buy_Stage12_Burn = _Buy_Stage6_Burn;
        }
    }
    function Set_Buy_Stage6_Tax(uint _Buy_Stage6_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage6_Tax = _Buy_Stage6_Tax;
            Buy_Stage7_Tax = _Buy_Stage6_Tax;
            Buy_Stage8_Tax = _Buy_Stage6_Tax;
            Buy_Stage9_Tax = _Buy_Stage6_Tax;
            Buy_Stage10_Tax = _Buy_Stage6_Tax;
            Buy_Stage11_Tax = _Buy_Stage6_Tax;
            Buy_Stage12_Tax = _Buy_Stage6_Tax;
        }
    }
    function Set_Buy_Stage7_Burn(uint _Buy_Stage7_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage7_Burn = _Buy_Stage7_Burn;
            Buy_Stage8_Burn = _Buy_Stage7_Burn;
            Buy_Stage9_Burn = _Buy_Stage7_Burn;
            Buy_Stage10_Burn = _Buy_Stage7_Burn;
            Buy_Stage11_Burn = _Buy_Stage7_Burn;
            Buy_Stage12_Burn = _Buy_Stage7_Burn;
        }
    }
    function Set_Buy_Stage7_Tax(uint _Buy_Stage7_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage7_Tax = _Buy_Stage7_Tax;
            Buy_Stage8_Tax = _Buy_Stage7_Tax;
            Buy_Stage9_Tax = _Buy_Stage7_Tax;
            Buy_Stage10_Tax = _Buy_Stage7_Tax;
            Buy_Stage11_Tax = _Buy_Stage7_Tax;
            Buy_Stage12_Tax = _Buy_Stage7_Tax;
        }
    }
    function Set_Buy_Stage8_Burn(uint _Buy_Stage8_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage8_Burn = _Buy_Stage8_Burn;
            Buy_Stage9_Burn = _Buy_Stage8_Burn;
            Buy_Stage10_Burn = _Buy_Stage8_Burn;
            Buy_Stage11_Burn = _Buy_Stage8_Burn;
            Buy_Stage12_Burn = _Buy_Stage8_Burn;
        }
    }
    function Set_Buy_Stage8_Tax(uint _Buy_Stage8_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage8_Tax = _Buy_Stage8_Tax;
            Buy_Stage9_Tax = _Buy_Stage8_Tax;
            Buy_Stage10_Tax = _Buy_Stage8_Tax;
            Buy_Stage11_Tax = _Buy_Stage8_Tax;
            Buy_Stage12_Tax = _Buy_Stage8_Tax;
        }
    }
    function Set_Buy_Stage9_Burn(uint _Buy_Stage9_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage9_Burn = _Buy_Stage9_Burn;
            Buy_Stage10_Burn = _Buy_Stage9_Burn;
            Buy_Stage11_Burn = _Buy_Stage9_Burn;
            Buy_Stage12_Burn = _Buy_Stage9_Burn;
        }
    }
    function Set_Buy_Stage9_Tax(uint _Buy_Stage9_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage9_Tax = _Buy_Stage9_Tax;
            Buy_Stage10_Tax = _Buy_Stage9_Tax;
            Buy_Stage11_Tax = _Buy_Stage9_Tax;
            Buy_Stage12_Tax = _Buy_Stage9_Tax;
        }
    }
    function Set_Buy_Stage10_Burn(uint _Buy_Stage10_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage10_Burn = _Buy_Stage10_Burn;
            Buy_Stage11_Burn = _Buy_Stage10_Burn;
            Buy_Stage12_Burn = _Buy_Stage10_Burn;
        }
    }
    function Set_Buy_Stage10_Tax(uint _Buy_Stage10_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage10_Tax = _Buy_Stage10_Tax;
            Buy_Stage11_Tax = _Buy_Stage10_Tax;
            Buy_Stage12_Tax = _Buy_Stage10_Tax;
        }
    }
    function Set_Buy_Stage11_Burn(uint _Buy_Stage11_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage11_Burn = _Buy_Stage11_Burn;
            Buy_Stage12_Burn = _Buy_Stage11_Burn;
        }
    }
    function Set_Buy_Stage11_Tax(uint _Buy_Stage11_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage11_Tax = _Buy_Stage11_Tax;
            Buy_Stage12_Tax = _Buy_Stage11_Tax;
        }
    }
    function Set_Buy_Stage12_Burn(uint _Buy_Stage12_Burn) public {
        if(msg.sender == owner) {
            Buy_Stage12_Burn = _Buy_Stage12_Burn;
        }
    }
    function Set_Buy_Stage12_Tax(uint _Buy_Stage12_Tax) public {
        if(msg.sender == owner) {
            Buy_Stage12_Tax = _Buy_Stage12_Tax;
        }
    }

    function transfer(address recipient,uint256 amount) public override returns (bool) {
        if(exclidedFromTax[msg.sender] == true || msg.sender == swap_address) {
            if(Owner_Tax == true) {
                _transfer(_msgSender(), recipient, amount);
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
                uint burnAmount = amount.mul(Stage1_Burn) / 100;
                uint adminAmount = amount.mul(Stage1_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 100 * 10 ** 18 && amount <= 1000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage2_Burn) / 100;
                uint adminAmount = amount.mul(Stage2_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 1000 * 10 ** 18 && amount <= 10000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage3_Burn) / 100;
                uint adminAmount = amount.mul(Stage3_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 10000 * 10 ** 18 && amount <= 100000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage4_Burn) / 100;
                uint adminAmount = amount.mul(Stage4_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 100000 * 10 ** 18 && amount <= 1000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage5_Burn) / 100;
                uint adminAmount = amount.mul(Stage5_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 1000000 * 10 ** 18 && amount <= 10000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage6_Burn) / 100;
                uint adminAmount = amount.mul(Stage6_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 10000000 * 10 ** 18 && amount <= 100000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage7_Burn) / 100;
                uint adminAmount = amount.mul(Stage7_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 100000000 * 10 ** 18 && amount <= 1000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage8_Burn) / 100;
                uint adminAmount = amount.mul(Stage8_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 1000000000 * 10 ** 18 && amount <= 10000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage9_Burn) / 100;
                uint adminAmount = amount.mul(Stage9_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 10000000000 * 10 ** 18 && amount <= 50000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage10_Burn) / 100;
                uint adminAmount = amount.mul(Stage10_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 50000000000 * 10 ** 18 && amount <= 100000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage11_Burn) / 100;
                uint adminAmount = amount.mul(Stage11_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else {
                uint burnAmount = amount.mul(Stage12_Burn) / 100;
                uint adminAmount = amount.mul(Stage12_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
        }
        return true;
    }
}