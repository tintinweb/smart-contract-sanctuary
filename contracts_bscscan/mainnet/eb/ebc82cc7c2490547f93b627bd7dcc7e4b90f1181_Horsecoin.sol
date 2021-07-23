// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract Horsecoin is Ownable {
    using SafeMath for uint256;

    string public name = "Horse Coin";
    string public symbol = "HOS";
    uint8 public decimals = 9;
    uint256 public totalSupply = 9000 * 10**12;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // 转账手续费率
    uint256 public transferFeeRate = 400;

    // 卖币手续费率 精确度包含四位小数
    uint256 public sellFeeRate = 1000;

    // 分红比例 精确度包含四位小数
    uint256 public luckyBonusRate = 2000;
    uint256 public luckyBonusCondition = 1 * 10**16; // 测试0.001
    address public luckyBonusAddress;

    /* 交易池地址 */
    mapping(address => bool) public isPoolAddress;

    mapping(address => bool) public isExcluded;

    uint256 public numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9; // 当手续费累加起来超过一定数额时添加流动性

    /* 手续费分发设置开始 */
    // 账户列表
    address[] public allocationAddress;
    // 每个账户所占比例 四位小数
    mapping(address => uint256) public allocationRatio;
    /* 手续费分发设置结束 */

    IUniswapV2Router02 public uniswapV2Router =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // 路由合约地址
    address public uniswapV2Pair; // 交易池合约地址

    bool inSwapAndLiquify;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    // 锁定交易 多次转账只加一次池子
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        // 创建交易池
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        // 发行代币
        _mint(msg.sender, totalSupply * 10**decimals);

        // 将owner账户设置为默认幸运分红账户
        luckyBonusAddress = owner();

        // 将交易池地址添加进去
        isPoolAddress[uniswapV2Pair] = true;

        // 添加初始排除的账户
        isExcluded[owner()] = true;
        isExcluded[address(this)] = true;
    }

    // 查询余额
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // 转账
    function transfer(address recipient, uint256 amount) public returns (bool) {
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
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // 授权转账
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
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

    // 设置加池子阈值
    function setNumTokensSellToAddToLiquidity(
        uint256 _numTokensSellToAddToLiquidity
    ) external onlyOwner {
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
    }

    // 设置幸运分红比例
    function setLuckyBonusRate(uint256 _luckyBonusRate) external onlyOwner {
        luckyBonusRate = _luckyBonusRate;
    }

    // 设置幸运分红条件
    function setLuckyBonusCondition(uint256 _luckyBonusCondition)
        external
        onlyOwner
    {
        luckyBonusCondition = _luckyBonusCondition;
    }

    // 设置卖出交易费用
    function setSellFeeRate(uint256 rate) external virtual onlyOwner {
        sellFeeRate = rate;
    }

    // 设置转账交易费用
    function setTransferFeeRate(uint256 rate) external virtual onlyOwner {
        transferFeeRate = rate;
    }

    // 添加被排除的账户
    function excludeFee(address account) external onlyOwner {
        require(!isExcluded[account], "Account is already excluded");
        isExcluded[account] = true;
    }

    // 从排除账户移除
    function includeFee(address account) external onlyOwner {
        require(isExcluded[account], "Account is already excluded");
        isExcluded[account] = false;
    }

    // 添加交易池地址
    function addPoolAddress(address pool) external virtual onlyOwner {
        require(
            isPoolAddress[pool] == false,
            "Horsecoin: the pool address is already added"
        );
        isPoolAddress[pool] = true;
    }

    // 移除交易池地址
    function removePoolAddress(address pool) external virtual onlyOwner {
        require(
            isPoolAddress[pool] == true,
            "Horsecoin: the pool address is not added"
        );
        delete isPoolAddress[pool];
    }

    // 设置分成账户
    function setAllocationAddress(
        address[] memory accounts,
        uint256[] memory ratios
    ) external virtual onlyOwner {
        require(
            accounts.length == ratios.length,
            "Horsecoin: accounts's length must be equal to ratios's length"
        );

        // 清空之前的数据
        for (uint256 i = 0; i < allocationAddress.length; i++) {
            delete allocationRatio[allocationAddress[i]];
        }
        delete allocationAddress;

        // 写入新数据
        for (uint256 i = 0; i < accounts.length; i++) {
            require(
                !isPoolAddress[accounts[i]],
                "Horsecoin: pool address can't be allocation account"
            ); // 交易池地址不能作为分发地址
            require(ratios[i] > 0, "Horsecoin: ratio must be greater than 0");
            /* 添加基金账户 */
            allocationAddress.push(accounts[i]);
            allocationRatio[accounts[i]] = ratios[i];
        }
    }

    // 分发代币以及添加流动性
    function allocationAndLiquify() public virtual {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            for (uint256 i = 0; i < allocationAddress.length; i++) {
                address recipient = allocationAddress[i];
                require(
                    !isPoolAddress[recipient],
                    "Horsecoin: pool address can't be allocation account"
                ); // 交易池地址不能作为分发地址
                uint256 amount = contractTokenBalance
                .mul(allocationRatio[recipient])
                .div(10000);
                _transfer(address(this), recipient, amount);
            }
            // 分发完代币剩余部分添加流动池
            swapAndLiquify(balanceOf(address(this)));
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
        } else if (isPoolAddress[sender]) {
            // 买入
            _transferStandard(sender, recipient, amount);
            _checkBoundsAddress(sender, amount);
        } else if (transferFeeRate > 0) {
            // 普通转账
            _transferStandard(sender, recipient, amount);
        } else {
            // 不扣除手续费
            _transferExcluded(sender, recipient, amount);
        }
    }

    // 判断是否为下一个分红账户
    function _checkBoundsAddress(address recipient, uint256 amount) private {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(uniswapV2Pair)
        .getReserves();
        uint256 tokenAmount;
        uint256 wethAmount;
        if (address(this) == IUniswapV2Pair(uniswapV2Pair).token0()) {
            tokenAmount = reserve0;
            wethAmount = reserve1;
        } else {
            tokenAmount = reserve1;
            wethAmount = reserve0;
        }
        if (amount.mul(wethAmount).div(tokenAmount) >= luckyBonusCondition) {
            luckyBonusAddress = recipient;
        }
    }

    // 卖出转账，扣除卖出手续费
    function _transferSell(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        // 如果开启了卖出手续费并且收款账户是交易池地址 收卖出手续费
        uint256 fee = amount.mul(sellFeeRate).div(10000);
        uint256 luckyBonus = fee.mul(luckyBonusRate).div(10000);

        _balances[sender] = _balances[sender].sub(amount);

        amount = amount.sub(fee);
        fee = fee.sub(luckyBonus);

        _balances[address(this)] = _balances[address(this)].add(fee);

        _balances[luckyBonusAddress] = _balances[luckyBonusAddress].add(
            luckyBonus
        );
        emit Transfer(sender, luckyBonusAddress, luckyBonus);

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);

        if (!inSwapAndLiquify && balanceOf(address(this)) > numTokensSellToAddToLiquidity) {
            // 合约中代币余额足够大时分发代币
            allocationAndLiquify();
        }
    }

    // 标准转账，扣除转账手续费
    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        // 收转账手续费
        uint256 fee = amount.mul(transferFeeRate).div(10000);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[address(this)] = _balances[address(this)].add(fee);
        amount = amount.sub(fee);
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

    // 交换代币并添加流动性
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // 将合约中的代币分为两部分
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        // 获取合同的当前余额。这样，我们就可以准确地获取掉期创建的ETH金额，而不会使流动性事件包括任何手动发送到合同的ETH
        uint256 initialBalance = address(this).balance;

        // 将代币兑换成BNB
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered 当swap+liquify被触发时，这将中断交换

        // 换到多少BNB
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // 将代币添加到流动池，流动性token转入owner账户
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    // 将代币兑换为BNB
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // 兑换代币
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    // 添加流动性
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // 添加流动性
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}