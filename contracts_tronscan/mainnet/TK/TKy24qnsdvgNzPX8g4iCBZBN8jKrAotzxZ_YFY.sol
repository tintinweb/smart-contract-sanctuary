//SourceUnit: yfy.sol

// SPDX-License-Identifier:  SimPL-2.0
pragma solidity ^0.8.6;

contract YFY {
    string public name = "YFY";
    string public symbol = "YFY";
    uint8 public decimals = 8;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;

    //运营地址
    address public operateOwner =
        address(0x0A79FdA22221A98C253ace0BefF5dD120498b8e9);
    //联创地址
    address public produceOwner =
        address(0x4FB3ae8DA2296cd960FACcBD7690bCc6d9281C41);
    //lpowner地址
    address public LpAddOwner =
        address(0x14C2FC7769C1dA57F3Ac7200d9f9760a82524e44);

    //交易手续费 / 100
    uint256 public feeRate = 10;
    //运营分红比例 / 100
    uint256 public operateRate = 20;
    //联创分红比例 / 100
    uint256 public produceRate = 30;
    //LP分红比例 / 100
    uint256 public lpRate = 50;
    //上次分红时间
    uint256 public lastBonusAt;
    //分红周期
    uint256 public bonusEpoch = 120; //86400*10 10天
    //流动池地址
    address public pairAddr;

    mapping(address => bool) public fromExcludedFee; //from白名单地址
    mapping(address => bool) public toExcludedFee; //to白名单地址

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed holder,
        address indexed spender,
        uint256 value
    );

    constructor() {
        owner = msg.sender;

        fromExcludedFee[owner] = true;
        toExcludedFee[owner] = true;

        fromExcludedFee[produceOwner] = true;
        toExcludedFee[produceOwner] = true;

        fromExcludedFee[operateOwner] = true;
        toExcludedFee[operateOwner] = true;

        fromExcludedFee[LpAddOwner] = true;
        toExcludedFee[LpAddOwner] = true;

        //总量2100W
        _mint(LpAddOwner, 21000000 * 10**8);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function setOwner(address owner_) public onlyOwner {
        owner = owner_;
    }

    //设置手续费比例
    function setFee(uint256 fee_) public onlyOwner {
        feeRate = fee_;
    }

    //排除 转账地址 交易手续费
    function setFromExcludedFee(address from_) public onlyOwner {
        fromExcludedFee[from_] = !fromExcludedFee[from_];
    }

    //排除 接收地址 交易手续费
    function setToExcludedFee(address to_) public onlyOwner {
        toExcludedFee[to_] = !toExcludedFee[to_];
    }

    //设置运营地址
    function setOperateAddr(address addr_) public onlyOwner {
        operateOwner = addr_;
    }

    //设置联创地址
    function setProduceAddr(address addr_) public onlyOwner {
        produceOwner = addr_;
    }

    //设置流动池地址
    function setPair(address pair_) public onlyOwner {
        pairAddr = pair_;
    }

    //执行分红
    function bonus_reward() public returns (bool) {
        uint256 lpReward = balanceOf[address(this)];
        require(lpReward > 0, "Bonus: reward is 0");
        // 分红周期验证
        require(
            lastBonusAt + bonusEpoch < block.timestamp,
            "Bonus: reward duration error"
        );

        // 重置领取奖励时间
        lastBonusAt = block.timestamp;
        balanceOf[address(this)] -= lpReward;
        balanceOf[pairAddr] += lpReward;

        return true;
    }

    //计算手续费
    function transfer_fee(
        address _from,
        address _to,
        uint256 _value
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _fee = 0;
        uint256 addAmount = _value; //接收数量
        uint256 subAmount = _value; //转出数量

        if (fromExcludedFee[_from] != true && toExcludedFee[_to] != true) {
            _fee = (_value * feeRate) / 100;
            if (pairAddr == _from) {
                //买入
                addAmount = _value - _fee;
                subAmount = _value;
            } else if (pairAddr == _to) {
                //卖出
                addAmount = _value;
                subAmount = _value + _fee;
            }
        }
        return (_fee, addAmount, subAmount);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        require(amount > 0, "amount error");

        //扣除余额需要计算手续费
        (uint256 fee, uint256 addAmount, uint256 subAmount) = transfer_fee(
            msg.sender,
            recipient,
            amount
        );
        _transfer(msg.sender, recipient, fee, addAmount, subAmount);
        return true;
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
        require(amount > 0, "amount error");

        //扣除余额需要计算手续费
        (uint256 fee, uint256 addAmount, uint256 subAmount) = transfer_fee(
            sender,
            recipient,
            amount
        );

        uint256 currentAllowance = allowance[sender][msg.sender];
        require(
            currentAllowance >= subAmount,
            "ERC20: transfer amount exceeds allowance"
        );

        _transfer(sender, recipient, fee, addAmount, subAmount);

        unchecked {
            _approve(sender, msg.sender, currentAllowance - subAmount);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 fee,
        uint256 addAmount,
        uint256 subAmount
    ) private {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(recipient != address(0));
        //自己不能转给自己
        require(sender != recipient);

        //需要计算加上手续费后是否够
        require(balanceOf[sender] >= subAmount, "sender balanceOf overflows");

        //Check for overflows
        require(
            balanceOf[recipient] + addAmount >= balanceOf[recipient],
            "recipient balanceOf overflows"
        );
        balanceOf[sender] -= subAmount;
        balanceOf[recipient] += addAmount;

        //分配手续费
        if (fee > 0) {
            // 联创分配地址3%
            uint256 produceReward = (fee * produceRate) / 100;
            balanceOf[produceOwner] += produceReward;

            // 运营分配地址2%
            uint256 operateReward = (fee * operateRate) / 100;
            balanceOf[operateOwner] += operateReward;

            //LP分红
            balanceOf[address(this)] = (fee - produceReward - operateReward);
        }

        emit Transfer(sender, recipient, addAmount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowance[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balanceOf[account] = accountBalance - amount;
        }
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address holder,
        address spender,
        uint256 amount
    ) internal virtual {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }
}