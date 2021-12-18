/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract HelloToken {
    string private _name;
    string private _symbol;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _priceInBNB;

    address private _masterWallet;

    address constant MY_WALLET = 0x5975f19Eb3Da85e61892c00E13a197FF6B66Fb4b;

    constructor() {
        _name = "My First Token";
        _symbol = "MFT";
        _priceInBNB = 0.01 * (10**18);
        _masterWallet = MY_WALLET;
        _mint(address(this),500);
        _mint(_masterWallet,30);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 0;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllownce = _allowances[sender][msg.sender];
        require(currentAllownce >= amount);

        unchecked {
            _approve(sender, msg.sender, currentAllownce - amount);
        }

        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 incValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + incValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 decValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= decValue);
        unchecked {
            _approve(msg.sender, spender, currentAllowance - decValue);
        }
        return true;
    }

    function buyToken(uint256 amount) external payable {
        require(msg.value >= _priceInBNB * amount);
        _transfer(address(this), msg.sender, amount);
        payable(_masterWallet).transfer(address(this).balance);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount);

        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal{
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0));

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount);

        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
}