/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract ERC20br {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        _name = "ERC20br";
        _symbol = "2BR";
        _totalSupply = 8516000 * (10**18); // 8516m km size of Brazil

        _balances[msg.sender] = _totalSupply;
    }

    function name() external view virtual returns (string memory) {
        return _name;
    }

    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() external view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool)
    {
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[msg.sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[msg.sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        returns (bool)
    {
        require(spender != address(0), "ERC20: approve to the zero address");
        require(
            _balances[msg.sender] >= amount,
            "ERC20: approval amount exceeds balance"
        );

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _allowances[sender][msg.sender] = currentAllowance - amount;
        emit Approval(sender, msg.sender, amount);

        return true;
    }

    /*
     * It exists only for tests purpose so you can mint tokens to yourself
     * and check your balance and transfer to other wallets.
     */
    function mint(uint256 amount) external virtual returns (bool) {
        require(amount > 0, "ERC20: mint 0 tokens");

        uint256 yourBalance = _balances[msg.sender];
        _balances[msg.sender] = yourBalance + amount;

        emit Transfer(address(0), msg.sender, amount);

        return true;
    }
}