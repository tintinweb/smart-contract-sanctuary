/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


contract Lottery is Initializable {
    // 开奖号码数量
    uint8 constant numQuantity = 4;
    // 开奖号码的最大取值范围（不包含max）
    uint8 constant max = 10;

    // 奖项
    enum Awards { FIRST, SECOND }

    // 彩民投注号码
    struct PlayerBet {
        address payable player;
        uint8[numQuantity] bet;
    }

    // 中奖人中奖号码及奖项
    struct WinnerBetGrade {
        address payable winner;
        uint8[numQuantity] bet;
        uint8 awards;
    }

    // 管理员地址
    address payable manager;
    // 所有彩民投注号码
    PlayerBet[] playersBet;
    // 开奖号码
    uint8[numQuantity] lotteryNums;
    // 所有中奖人中奖号码及奖项
    WinnerBetGrade[] winnersBetGrade;
    // 每个奖项的中奖人数
    mapping(uint8 => uint) winnersGradeCount;
    // 彩票期数
    uint round;

    function initialize() public initializer {
        manager = payable(msg.sender);
    }

    // 定义onlyManager修饰器
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    /*
     * 投注
     * bet  投注号码
     */
    function play(uint8[numQuantity] memory bet) payable public {
        // 每次投注1Eth
        require(msg.value == 1 ether);
        // 输入的投注号码必须小于max
        for (uint8 i = 0; i < bet.length; i++) {
            require(bet[i] < max);
        }
        PlayerBet memory playerBet = PlayerBet(payable(msg.sender), bet);
        playersBet.push(playerBet);

    }

    /*
     * 开奖
     */
    function runLottery() public onlyManager {
        // 至少1个参与者才能开奖
        require(playersBet.length > 0);

        // 随机生成的开奖号码
        for (uint8 i = 0; i < lotteryNums.length; i++) {
            uint v = uint(sha256(abi.encodePacked(block.timestamp, playersBet.length, i)));
            // 将随机获取的Hash值对max取余，保证号码在0~max之间（不包含max）
            lotteryNums[i] = uint8(v % uint(max));
        }

        deleteWinnersData(); // 本期开奖前，删除上一期中奖数据

        for (uint i = 0; i < playersBet.length; i++) {
            uint8 count; // 记录彩民投注号码顺序符合开奖号码的个数
            uint8[numQuantity] memory bet = playersBet[i].bet;
            // 遍历开奖号码与彩民投注号码，顺序符合则count加1
            for (uint8 j = 0; j < lotteryNums.length; j++) {
                if (lotteryNums[j] == bet[j]) {
                    count ++;
                }
            }
            // 如果numQuantity（4）个号码顺序相同，则中一等奖；如果3个号码相同则中二等奖
            if (count == numQuantity) {
                WinnerBetGrade memory winnerBetGrade = WinnerBetGrade(playersBet[i].player, bet, uint8(Awards.FIRST));
                winnersBetGrade.push(winnerBetGrade);
                // 一等奖的中奖人数加1
                winnersGradeCount[uint8(Awards.FIRST)]++;
            } else if (count == numQuantity - 1) {
                WinnerBetGrade memory winnerBetGrade = WinnerBetGrade(playersBet[i].player, bet, uint8(Awards.SECOND));
                winnersBetGrade.push(winnerBetGrade);
                // 二等奖的中奖人数加1
                winnersGradeCount[uint8(Awards.SECOND)]++;
            }
        }

        dividePrizePool(); // 瓜分奖池

        round++;
        deletePlayersData(); // 开奖结束，删除本期彩民数据
    }

    /*
     * 删除彩民数据
     */
    function deletePlayersData() private {
        delete playersBet;
    }

    /*
     * 删除中奖数据
     */
    function deleteWinnersData() private {
        delete winnersBetGrade;

        // 重置每个奖项人数
        delete winnersGradeCount[uint8(Awards.FIRST)];
        delete winnersGradeCount[uint8(Awards.SECOND)];
    }

    /*
     * 瓜分奖池
     */
    function dividePrizePool() private {
        // 管理员瓜分的金额（管理员投注瓜分的金额不计入）：没有人中奖时奖池全部归管理员，每注中奖减去中奖金额，剩余金额归管理员
        uint managerDivide = address(this).balance;
        // 每注一等奖瓜分的金额
        uint firstDivide = 0;
        // 每注二等奖瓜分的金额
        uint secondDivide = 0;

        if (winnersGradeCount[uint8(Awards.FIRST)] != 0) {
            firstDivide = address(this).balance * 78 / (100 * winnersGradeCount[uint8(Awards.FIRST)]);
        }

        if (winnersGradeCount[uint8(Awards.SECOND)] != 0) {
            secondDivide = address(this).balance * 17 / (100 * winnersGradeCount[uint8(Awards.SECOND)]);
        }

        for (uint i = 0; i < winnersBetGrade.length; i++) {
            if (winnersBetGrade[i].awards == uint8(Awards.FIRST)) {
                winnersBetGrade[i].winner.transfer(firstDivide);
                // 减去一等奖瓜分金额
                managerDivide = managerDivide - firstDivide;
            } else if (winnersBetGrade[i].awards == uint8(Awards.SECOND)) {
                winnersBetGrade[i].winner.transfer(secondDivide);
                // 减去二等奖瓜分金额
                managerDivide = managerDivide - secondDivide;
            }
        }

        manager.transfer(managerDivide);
    }

    /*
     * 获取管理员地址
     */
    function getManager() public view returns(address) {
        return manager;
    }

    /*
     * 获取合约余额
     */
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    /*
     * 获取彩民投注号码数组长度
     */
    function getPlayersBetLength() public view returns(uint) {
        return playersBet.length;
    }

    /*
     * 获取开奖号码
     */
    function getLotteryNums() public view returns(uint8[numQuantity] memory) {
        return lotteryNums;
    }

    /*
     * 获取中奖人中奖号码及奖项数组长度
     */
    function getWinnersBetGradeLength() public view returns(uint) {
        return winnersBetGrade.length;
    }

    /*
     * 获取彩票期数
     */
    function getRound() public view returns(uint) {
        return round;
    }
}