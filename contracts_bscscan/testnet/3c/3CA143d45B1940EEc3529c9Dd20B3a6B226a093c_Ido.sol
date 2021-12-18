// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IterableMapping.sol";

/*
 * IDO 以币筹币锁仓合约
 */
contract Ido {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // 总额度
    uint256 public immutable maxQuota;
    // 价格
    uint256 public immutable price;
    // 合约创建者
    address public immutable owner;
    // 收取者
    address public immutable mainAddress;
    // 用户的支付token
    IERC20 public immutable moneyToken;
    // 用户接收币合约
    IERC20 public immutable coinToken;
    // 最小支付
    uint256 public immutable min;
    // 最大支付
    uint256 public immutable max;
    // 开始时间
    uint256 public immutable startTime;
    // 结束时间
    uint256 public immutable endTime;

    // 已经筹集总量
    uint256 public totalSupply=0;

    // 已发放比例,千分之X
    uint256 public distRate=0;
    // 可领取余额
    mapping(address => uint256) public claimed;
    // 总获取余额
    mapping(address => uint256) public balanceOf;
    // 可领取余额
    mapping(address => bool) public whiteList;
    
    // 设置白名单
    bool public isEnableWhiteList;

    constructor(
        uint256 maxQuota_,
        uint256 price_,
        address  mainAddress_,
        uint256 min_,
        uint256 max_,
        uint256 startTime_,
        uint256 endTime_,
        IERC20 moneyToken_,
        IERC20 coinToken_
    ) {
        maxQuota = maxQuota_;
        price = price_;
        owner = _msgSender();
        moneyToken = moneyToken_;
        coinToken = coinToken_;
        min = min_;
        max = max_;
        startTime = startTime_;
        endTime = endTime_;
        mainAddress = mainAddress_;
    }

    // 投资
    function invest(uint256 amount) public returns (bool) {
        address sender = _msgSender();
        require(block.timestamp > startTime, "Coming soon");
        require(block.timestamp < endTime, "Sold out");
        require(!isEnableWhiteList || whiteList[sender], "Not in whiteList");
        // 单个用户投资太多
        require(amount <= max, "Invest too much");
        // 单个用户投资太少
        require(amount >= min, "Invest too low");
        // 总额度不足
        require(totalSupply.add(amount) <= maxQuota, "Insufficient quota");
        // 单个用户投资太多
        require(balanceOf[sender].add(amount) <= max, "Invest too much");

        // 用户余额
        uint256 balance = moneyToken.balanceOf(sender);
        // 应支付金额
        uint256 payAmount = amount.mul(price).div(10**18);
        require(balance > payAmount, "Insufficient funds");
        // 支付金额
        moneyToken.safeTransferFrom(sender,mainAddress,payAmount);

        _mint(sender, amount);
        return true;
    }

    // 启用白名单
    function enableWhiteList(bool isEnable) public {
        require(msg.sender == owner, "no owner");
        isEnableWhiteList = isEnable;
    }

    // 添加白名单
    function addWhiteList(address[] memory accounts) public {
        require(msg.sender == owner, "no owner");
        for (uint i = 0; i < accounts.length;i++) {
            whiteList[accounts[i]] = true;
        }
    }

    // 移除白名单
    function removeWhiteList(address[] memory accounts) public {
        require(msg.sender == owner, "no owner");
        for (uint i = 0; i < accounts.length;i++) {
            whiteList[accounts[i]] = false;
        }
    }
    function inWhiteList(address account) view public returns (bool){
        return whiteList[account];
    }
    // 铸造
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
    }

    // 认领
    function claim() public virtual {
        address sender = _msgSender();
        // 能领取的总额 = 总获取到的coin * 释放比例 - 已经领取的
        uint256 claimAmount = claimBalance();
        require(claimAmount > 0, "no tokens to claim");
        
        // 代币总余额 需大于 认领余额
        uint256 amount = coinToken.balanceOf(mainAddress);
        require(amount > claimAmount, "main account no tokens to claim");

        // 已认领的总余额
        claimed[sender] +=  claimAmount;

        // 发放代币
        coinToken.safeTransferFrom(mainAddress,sender, amount);
    }

    // 可认领数量
    function claimBalance() public virtual returns (uint256) {
        address sender = _msgSender();
        // 能领取的总额 = 总获取到的coin * 释放比例 - 已经领取的
        uint256 claimAmount = balanceOf[sender].mul(distRate).div(1000).sub(claimed[sender]);
        return claimAmount;
    }

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    // 发放比例
    function addDistRate(uint8 rate) public returns (uint) {
        require(msg.sender == owner, "no owner");
        distRate += rate;
        require(distRate < 1000, "too large");
        return distRate;
    }
}