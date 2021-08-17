// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract MyDefiWar is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name = "My Defi War";
    string public symbol = "DFA";
    uint256 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public sellFeeRate = 600;

    mapping(address => bool) public isPoolAddress;
    mapping(address => bool) public isExcluded;

    address[] public allocationAddress;
    mapping(address => uint256) public allocationRatio;

    IUniswapV2Router02 private uniswapV2Router =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // pancakeswap router

    address public uniswapV2Pair;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event WithdrawToken(IERC20 indexed token, uint256 amount);
    event AddExcludeAddress(address indexed account);
    event RemoveExcludeAddress(address indexed account);
    event AddPoolAddress(address indexed pool);
    event RemovePoolAddress(address indexed pool);
    event SetFeeRate(uint256 sellFeeRate);
    event SetAllocationAddress(address[] accounts, uint256[] ratios);

    constructor() {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        _mint(msg.sender, 76000000 * 10**decimals);

        isPoolAddress[uniswapV2Pair] = true;

        isExcluded[owner()] = true;
        isExcluded[address(this)] = true;
    }

    function withdrawToken(IERC20 token, uint256 amount)
        public
        virtual
        onlyOwner
    {
        require(
            address(token) != address(this),
            "DFA: can't withdraw main token"
        );
        token.safeTransfer(msg.sender, amount);
        emit WithdrawToken(token, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
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
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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

    function setFeeRate(uint256 _sellFeeRate) external virtual onlyOwner {
        require(sellFeeRate <= 10000, "DFA: the ratio must be less than 10000");
        sellFeeRate = _sellFeeRate;
        emit SetFeeRate(_sellFeeRate);
    }

    function addExcludeAddress(address account) external virtual onlyOwner {
        require(!isExcluded[account], "DFA: Account is already excluded");
        isExcluded[account] = true;
        emit AddExcludeAddress(account);
    }

    function removeExcludeAddress(address account) external virtual onlyOwner {
        require(isExcluded[account], "DFA: Account is already excluded");
        isExcluded[account] = false;
        emit RemoveExcludeAddress(account);
    }

    function addPoolAddress(address pool) external virtual onlyOwner {
        require(
            isPoolAddress[pool] == false,
            "DFA: the pool address is already added"
        );
        isPoolAddress[pool] = true;
        emit AddPoolAddress(pool);
    }

    function removePoolAddress(address pool) external virtual onlyOwner {
        require(
            isPoolAddress[pool] == true,
            "DFA: the pool address is not added"
        );
        delete isPoolAddress[pool];
        emit RemovePoolAddress(pool);
    }

    function setAllocationAddress(
        address[] memory accounts,
        uint256[] memory ratios
    ) external virtual onlyOwner {
        require(
            accounts.length == ratios.length,
            "DFA: accounts's length must be equal to ratios's length"
        );

        for (uint256 i = 0; i < allocationAddress.length; i++) {
            delete allocationRatio[allocationAddress[i]];
        }
        delete allocationAddress;
        uint256 count;

        for (uint256 i = 0; i < accounts.length; i++) {
            require(
                !isPoolAddress[accounts[i]],
                "DFA: pool address can't be allocation account"
            );
            require(ratios[i] > 0, "DFA: ratio must be greater than 0");
            count = count.add(ratios[i]);
            allocationAddress.push(accounts[i]);
            allocationRatio[accounts[i]] = ratios[i];
        }
        require(count == 10000, "DFA: The sum of the ratios equals 10000");

        emit SetAllocationAddress(accounts, ratios);
    }

    function allocation() external virtual onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            for (uint256 i = 0; i < allocationAddress.length; i++) {
                address recipient = allocationAddress[i];
                require(
                    !isPoolAddress[recipient],
                    "DFA: pool address can't be allocation account"
                );
                uint256 amount = contractTokenBalance
                    .mul(allocationRatio[recipient])
                    .div(10000);
                _transfer(address(this), recipient, amount);
            }
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(
            _balances[sender] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        if (isExcluded[sender]) {
            _transferExcluded(sender, recipient, amount);
        } else if (sellFeeRate > 0 && isPoolAddress[recipient]) {
            _transferSell(sender, recipient, amount);
        } else {
            _transferExcluded(sender, recipient, amount);
        }
    }

    function _transferSell(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 fee = amount.mul(sellFeeRate).div(10000);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[address(this)] = _balances[address(this)].add(fee);
        _balances[recipient] = _balances[recipient].add(amount.sub(fee));
        emit Transfer(sender, recipient, amount);
    }

    function _transferExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}