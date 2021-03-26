/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

/**
用户支付 0.1 以太即可加入 lottery
不限用户数量
同一用户可以多次加入
合约所有人亦可以加入
合约所有人决定何时选出赢家
赢家将得到所有奖金
选出赢家即可开始新一轮 lottery
 */

 pragma solidity ^0.5.16;

 contract LotteryNoLimit{
    address owner;
    address payable[] users;
    uint randNonce = 0;

    modifier onlyOwner(){
        require(owner == msg.sender, "only owner can do");
        _;
    }

    constructor() public{
        owner = msg.sender;
    }

    function getRandomNumber(uint _limit) public returns(uint){
        uint rand = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % _limit;
        randNonce ++;
        return rand;
    }

    function bet() public payable {
        require(msg.value == 0.1 ether, "send 0.1 ether");
        users.push(msg.sender);
    }

    function winer() public onlyOwner {
        require(users.length > 0);
        users[getRandomNumber(users.length)].transfer(address(this).balance);
        delete users;
    }

 }