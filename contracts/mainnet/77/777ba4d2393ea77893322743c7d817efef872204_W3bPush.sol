/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: UNLICENSED

//............................................................................................
//.....................................................................SSSSSS.................
//.WWWW..WWWWW..WWWW..333333...BBBBBBBBBB...PPPPPPPPPP..UUUU...UUUU...SSSSSSSS...HHHH...HHHH..
//.WWWW..WWWWW..WWWW.33333333..BBBBBBBBBBB..PPPPPPPPPP..UUUU...UUUU..SSSSSSSSSS..HHHH...HHHH..
//.WWWW..WWWWW..WWWW333333333..BBBBBBBBBBB..PPPPPPPPPPP.UUUU...UUUU..SSSSSSSSSS..HHHH...HHHH..
//..WWWW.WWWWW.WWWW.3333.3333..BBBB...BBBB..PPPP...PPPP.UUUU...UUUU.USSS...SSSSS.HHHH...HHHH..
//..WWWWWWWWWWWWWWW.3333.3333..BBBB..BBBBB..PPPP...PPPP.UUUU...UUUU.USSSSS.......HHHHHHHHHHH..
//..WWWWWWWWWWWWWWW....333333..BBBBBBBBBBB..PPPPPPPPPPP.UUUU...UUUU..SSSSSSSSS...HHHHHHHHHHH..
//..WWWWWWWWWWWWWWW....333333..BBBBBBBBBBB..PPPPPPPPPPP.UUUU...UUUU..SSSSSSSSSS..HHHHHHHHHHH..
//...WWWWWW.WWWWWW.....3333333.BBBBBBBBBBB..PPPPPPPPPP..UUUU...UUUU....SSSSSSSSS.HHHHHHHHHHH..
//...WWWWWW.WWWWWW..3333..3333.BBBB....BBBB.PPPPPPPPP...UUUU...UUUU.USSS..SSSSSS.HHHH...HHHH..
//...WWWWWW.WWWWWW..3333..3333.BBBB...BBBBB.PPPP........UUUU...UUUU.USSS....SSSS.HHHH...HHHH..
//....WWWWW.WWWWW...3333333333.BBBBBBBBBBB..PPPP........UUUUUUUUUUU.USSSSSSSSSSS.HHHH...HHHH..
//....WWWW...WWWW...333333333..BBBBBBBBBBB..PPPP........UUUUUUUUUUU..SSSSSSSSSS..HHHH...HHHH..
//....WWWW...WWWW....33333333..BBBBBBBBBB...PPPP.........UUUUUUUUU....SSSSSSSSS..HHHH...HHHH..
//.....................3333................................UUUUU.......SSSSSS.................
//............................................................................................

pragma solidity ^0.7.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/*
    W3bPush is notification ecosystem for DApps and CApps.
*/
contract W3bPush is ERC20 {
    using SafeMath for uint256;

    uint8 public constant _DECIMALS = 18;
    uint256 private _totalSupply = 1000000 * (10**uint256(_DECIMALS));
    address private _contractDeployer;

    constructor() ERC20("W3bPush", "W3B", _DECIMALS) {
        _contractDeployer = msg.sender;
        _mint(_contractDeployer, _totalSupply);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}