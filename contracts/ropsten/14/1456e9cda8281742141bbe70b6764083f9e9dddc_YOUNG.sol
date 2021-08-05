// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract YOUNG is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name = "YOUNG"; // 代币名称 改成自己的
    string public symbol = "YOUNG"; // 代币符号 改成自己的
    uint8 public decimals = 9; // 代币精度  改成自己的
    uint256 public totalSupply = 10000 * 10**8 * 10**9; // 代币总量 改成自己的

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // 购买手续费 精确度包含四位小数
    uint256 public buyFeeRate = 1200;
    // 卖币手续费率 精确度包含四位小数
    uint256 public sellFeeRate = 1200;

    /* 交易池地址 */
    mapping(address => bool) public isPoolAddress;

    mapping(address => bool) public isExcluded;

    /* 购买手续费分发设置开始 */
    // 账户列表
    address[] public buyAllocationAddress;
    // 每个账户所占比例 四位小数
    mapping(address => uint256) public buyAllocationRatio;
    /* 购买手续费分发设置结束 */

    /* 卖出手续费分发设置开始 */
    // 账户列表
    address[] public sellAllocationAddress;
    // 每个账户所占比例 四位小数
    mapping(address => uint256) public sellAllocationRatio;
    /* 卖出手续费分发设置结束 */

    // IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // 路由合约地址  pancakeswap
    // IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); // 路由合约地址  quickswap
    IUniswapV2Router02 public uniswapV2Router =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // 路由合约地址  ropsten 寿司
    // IUniswapV2Router02 public uniswapV2Router =
    //     IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // 路由合约地址  pancakeswap 正式

    address public uniswapV2Pair; // 交易池合约地址

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event WithdrawToken(IERC20 indexed token, uint256 amount);
    event WithdrawETH(uint256 amount);
    event SetFeeRate(uint256 buyFeeRate, uint256 sellFeeRate);
    event AddExcludeAddress(address indexed account);
    event RemoveExcludeAddress(address indexed account);
    event AddPoolAddress(address indexed pool);
    event RemovePoolAddress(address indexed pool);
    event SetBuyAllocationAddress(address[] accounts, uint256[] ratios);
    event SetSellAllocationAddress(address[] accounts, uint256[] ratios);

    constructor() {
        // 创建交易池
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        // 发行代币
        _mint(msg.sender, totalSupply * 10**decimals);

        // 将交易池地址添加进去
        isPoolAddress[uniswapV2Pair] = true;

        // 添加初始排除的账户
        isExcluded[owner()] = true;
        isExcluded[address(this)] = true;
    }

    // 提现ERC20代币
    function withdrawToken(IERC20 token, uint256 amount)
        public
        virtual
        onlyOwner
    {
        token.safeTransfer(msg.sender, amount);
        emit WithdrawToken(token, amount);
    }

    // 提现主网币
    function withdrawETH(uint256 amount) public virtual onlyOwner {
        payable(msg.sender).transfer(amount);
        emit WithdrawETH(amount);
    }

    // 查询余额
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // 转账
    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // 查询授权
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    // 授权
    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // 授权转账
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

    // 增加授权
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

    // 减少授权
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

    // 设置费率
    function setFeeRate(uint256 _buyFeeRate, uint256 _sellFeeRate)
        external
        virtual
        onlyOwner
    {
        require(
            _buyFeeRate <= 10000 && _sellFeeRate <= 10000,
            "YOUNG: the ratio must be less than 10000"
        );
        buyFeeRate = _buyFeeRate;
        sellFeeRate = _sellFeeRate;
        emit SetFeeRate(_buyFeeRate, _sellFeeRate);
    }

    // 添加被排除的账户
    function addExcludeAddress(address account) external virtual onlyOwner {
        require(!isExcluded[account], "Account is already excluded");
        isExcluded[account] = true;
        emit AddExcludeAddress(account);
    }

    // 从排除账户移除
    function removeExcludeAddress(address account) external virtual onlyOwner {
        require(isExcluded[account], "Account is already excluded");
        isExcluded[account] = false;
        emit RemoveExcludeAddress(account);
    }

    // 添加交易池地址
    function addPoolAddress(address pool) external virtual onlyOwner {
        require(
            isPoolAddress[pool] == false,
            "YOUNG: the pool address is already added"
        );
        isPoolAddress[pool] = true;
        emit AddPoolAddress(pool);
    }

    // 移除交易池地址
    function removePoolAddress(address pool) external virtual onlyOwner {
        require(
            isPoolAddress[pool] == true,
            "YOUNG: the pool address is not added"
        );
        delete isPoolAddress[pool];
        emit RemovePoolAddress(pool);
    }

    // 设置买入分成账户
    function setBuyAllocationConfig(
        address[] memory accounts,
        uint256[] memory ratios
    ) external virtual onlyOwner {
        require(
            accounts.length == ratios.length,
            "YOUNG: accounts's length must be equal to ratios's length"
        );

        // 清空之前的数据
        for (uint256 i = 0; i < buyAllocationAddress.length; i++) {
            delete buyAllocationRatio[buyAllocationAddress[i]];
        }
        delete buyAllocationAddress;

        uint256 count = 0;

        // 写入新数据
        for (uint256 i = 0; i < accounts.length; i++) {
            require(
                !isPoolAddress[accounts[i]],
                "YOUNG: pool address can't be allocation account"
            ); // 交易池地址不能作为分发地址
            require(ratios[i] > 0, "YOUNG: ratio must be greater than 0");
            /* 添加基金账户 */
            buyAllocationAddress.push(accounts[i]);
            buyAllocationRatio[accounts[i]] = ratios[i];
            count = count + ratios[i];
        }

        require(count == 10000, "YOUNG: ratios count must be 10000");

        emit SetBuyAllocationAddress(accounts, ratios);
    }

    // 设置卖出分成账户
    function setSellAllocationConfig(
        address[] memory accounts,
        uint256[] memory ratios
    ) external virtual onlyOwner {
        require(
            accounts.length == ratios.length,
            "YOUNG: accounts's length must be equal to ratios's length"
        );

        // 清空之前的数据
        for (uint256 i = 0; i < sellAllocationAddress.length; i++) {
            delete sellAllocationRatio[sellAllocationAddress[i]];
        }
        delete sellAllocationAddress;

        uint256 count = 0;

        // 写入新数据
        for (uint256 i = 0; i < accounts.length; i++) {
            require(
                !isPoolAddress[accounts[i]],
                "YOUNG: pool address can't be allocation account"
            ); // 交易池地址不能作为分发地址
            require(ratios[i] > 0, "YOUNG: ratio must be greater than 0");
            /* 添加基金账户 */
            sellAllocationAddress.push(accounts[i]);
            sellAllocationRatio[accounts[i]] = ratios[i];
            count = count + ratios[i];
        }

        require(count == 10000, "YOUNG: ratios count must be 10000");

        emit SetSellAllocationAddress(accounts, ratios);
    }

    // 分发费用代币
    function _allocationFee(
        address sender,
        uint256 amount,
        address[] memory allocationAddress,
        mapping(address => uint256) storage allocationRatio
    ) private {
        for (uint256 i = 0; i < allocationAddress.length; i++) {
            address recipient = allocationAddress[i];
            require(
                !isPoolAddress[recipient],
                "YOUNG: pool address can't be allocation account"
            ); // 交易池地址不能作为分发地址
            uint256 fee = amount.mul(allocationRatio[recipient]).div(10000);
            _balances[recipient] = _balances[recipient].add(fee);
            emit Transfer(sender, recipient, fee);
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
        if (isExcluded[sender] || isExcluded[recipient]) {
            // 特权转账 不扣手续费
            _transferExcluded(sender, recipient, amount);
        } else if (sellFeeRate > 0 && isPoolAddress[recipient]) {
            // 卖出转账
            _transferSell(sender, recipient, amount);
        } else if (buyFeeRate > 0 && isPoolAddress[sender]) {
            // 买入
            _transferBuy(sender, recipient, amount);
        } else {
            // 不扣除手续费
            _transferExcluded(sender, recipient, amount);
        }
    }

    // 卖出转账，扣除卖出手续费
    function _transferSell(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] = _balances[sender].sub(amount);

        // 如果开启了卖出手续费并且收款账户是交易池地址 收卖出手续费
        uint256 fee = amount.mul(sellFeeRate).div(10000);

        amount = amount.sub(fee);

        // 分发手续费
        _allocationFee(sender, fee, sellAllocationAddress, sellAllocationRatio);

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    // 购买转账，扣除卖出手续费
    function _transferBuy(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] = _balances[sender].sub(amount);

        // 如果开启了卖出手续费并且收款账户是交易池地址 收卖出手续费
        uint256 fee = amount.mul(buyFeeRate).div(10000);

        amount = amount.sub(fee);

        // 分发手续费
        _allocationFee(sender, fee, buyAllocationAddress, buyAllocationRatio);

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    // 超级转账，不扣除手续费
    function _transferExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        // 关闭手续费的时候
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}