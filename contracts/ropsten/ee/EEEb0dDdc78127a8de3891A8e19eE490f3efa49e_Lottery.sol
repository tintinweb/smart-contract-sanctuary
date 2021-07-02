/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Lottery {
    address payable manager;
    address payable[] players;
    address payable winner;
    uint round;

    constructor() {
        manager = payable(msg.sender);
    }

    // 定义onlyManager修饰器
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    /*
     * 投注
     */
    function play() payable public {
        require(msg.value == 1 ether);
        players.push(payable(msg.sender));
    }

    /*
     * 开奖
     */
    function runLottery() public onlyManager {
        // 至少2个参与者才能开奖
        require(players.length > 1);

        // 生成随机数
        uint v = uint(sha256(abi.encodePacked(block.timestamp, players.length)));
        // 将随机数对players.length取余，得到中奖人的下标
        uint index = v % players.length;

        winner = players[index];

        dividePrizePool();

        round++;
        delete players;
    }

    /*
     * 瓜分奖池
     */
    function dividePrizePool() private {
        uint winnerDivide = address(this).balance * 99 / 100;
        uint managerDivide = address(this).balance - winnerDivide;

        winner.transfer(winnerDivide);
        manager.transfer(managerDivide);
    }

    /*
     * 退奖
     */
    function refund() public onlyManager {
        for (uint i = 0; i < players.length; i++) {
            players[i].transfer(1 ether);
        }

        round++;
        delete players;
    }

    /*
     * 获取管理员地址
     */
    function getManager() public view returns (address) {
        return manager;
    }

    /*
     * 获取合约余额
     */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /*
     * 获取彩民池
     */
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    /*
     * 获取彩民池人数
     */
    function getPlayersCount() public view returns (uint) {
        return players.length;
    }

    /*
     * 获取中奖人
     */
    function getWinner() public view returns (address) {
        return winner;
    }

    /*
     * 获取彩票期数
     */
    function getRound() public view returns (uint) {
        return round;
    }
}