/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

// 最好遵循一个文件一个合约，且文件名保持与合约一致。这里的合约名是 Vote

// 第一行通常是版权声明的注释
// SPDX-License-Identifier: GPL-3.0

// 声明编译器版本
// pragma solidity = 0.8.7;

// 也可以指定版本范围
pragma solidity >=0.8.0 <0.9.0;

// 由关键字 contract 声明一个合约
contract Vote {
    // 一个合约就相当于一个类，合约内部可以有成员变量

    // 合约可以定义事件（Event），我们在 Vote 合约中定义了一个 onVote 事件
    // 只定义事件还不够，触发事件必须在合约的写函数中通过 emit 关键字实现
    event onVote(address indexed voter, uint256 target);

    mapping(address => bool) public voted; // 记录已投票的地址，mapping 是一个键值对
    uint256 endTime; // 记录投票终止时间
    address payable public owner; // 记录管理员地址

    // 结构体
    struct Person {
        string name;
        uint256 votes;
        address payable ads;
    }

    // 记录得票数量
    Person[] public list;

    // 所有的成员变量都默认初始化为 0 或 false（针对 bool）或空（针对 mapping）
    // 如果某个成员变量要指定初始值，那么需要在构造函数中赋值
    constructor() {
        endTime = 1635739200;
        owner = payable(msg.sender);

        list.push(
            Person({
                name: "DengShen",
                votes: 0,
                ads: payable(0xD96DE875d586743CE457E8Ef72145Ae75715F7E1)
            })
        );
        list.push(
            Person({
                name: "LiJilang",
                votes: 0,
                ads: payable(0x303fC2FC594Cf19014Da9831646581CDFc7ECa2E)
            })
        );
        list.push(
            Person({
                name: "QiuYuhang",
                votes: 0,
                ads: payable(0xbe188Cb3730d91Bbf2272e0B827aCF6fFdB4D074)
            })
        );
        list.push(
            Person({
                name: "RaoWenbing",
                votes: 0,
                ads: payable(0xe8d3Ceab4e5E0D33361DA6c7355835417a9B3bbe)
            })
        );
        list.push(
            Person({
                name: "WangXin",
                votes: 0,
                ads: payable(0x25309087503C0C7a4f2e9b1A04875747d61340EC)
            })
        );
        list.push(
            Person({
                name: "XuWang",
                votes: 0,
                ads: payable(0x535186c86B22B423D150530EbD57E48D4297a9Cc)
            })
        );
        list.push(
            Person({
                name: "YangLidong",
                votes: 0,
                ads: payable(0x6143CcC61F582b38626AaDAe93D1F119c66b2a70)
            })
        );
        list.push(
            Person({
                name: "ZhongDakang",
                votes: 0,
                ads: payable(0x8Fb155803f695DBE7B53b94BC1bb6db5D338d60b)
            })
        );
        list.push(
            Person({
                name: "ZhouHuiyu",
                votes: 0,
                ads: payable(0x5b9edA1F23501D891B299919dee69Ce00004cF12)
            })
        );
    }

    // 以太坊合约支持读、写两种类型的成员函数
    // 没有 view 修饰的函数是写入函数，它会修改成员变量，即改变了合约的状态
    function vote(uint256 target) public payable {
        require(block.timestamp < endTime, "-1"); // 判断投票是否截止
        require(msg.value >= 100000000000000000, "-2"); // 投票需要 0.1 eth

        // 给mapping增加一个key-value
        voted[msg.sender] = true;
        list[target].votes++;

        // 当调用 vote() 写方法时，会触发 Voted 事件
        emit onVote(msg.sender, target);
    }

    function setEndTime(uint256 time) public {
        require(msg.sender == owner, "-3"); // 只有管理员才能调用
        endTime = time;
    }

    function endVote() public {
        require(msg.sender == owner, "-3"); // 只有管理员才能调用

        uint256 max = 0;
        uint256 winnerIndex = 0;

        for (uint256 i = 0; i < list.length; i++) {
            if (list[i].votes > max) {
                max = list[i].votes;
                winnerIndex = i;
            }
        }

        list[winnerIndex].ads.transfer(address(this).balance);
    }

    // 以 view 修饰的函数是只读函数，它不会修改成员变量，即不会改变合约的状态
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

    // 接收转账
    fallback() external payable {}
}