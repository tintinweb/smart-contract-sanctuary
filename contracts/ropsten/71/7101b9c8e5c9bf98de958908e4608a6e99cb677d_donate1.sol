/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.7.0;


// 捐款合約(可以使用捐款地址捐款金額和當下時間，結束時間為開始時間後一周)

contract donate1{
    
    
    // 捐款機構名稱、捐款機構地址、發起人名稱、發起人地址、開始時間、結束時間
    string donatename;
    address payable donate_address;
    string owner_name;
    address owner;
    uint public startime;
    uint public endtime;
    
    // 捐款人地址、捐款金額、捐款時間
    struct DonatePeople {
        address d_people;
        uint p_value;
        uint time;
    }
    
    mapping (address => DonatePeople) public DP_date;
    
    // 紀錄捐款有幾筆
    event setdonatedata(uint money);
    
    constructor(address payable _dname) public{
        donatename = "TRGO";                   // 設定捐款機構名稱
        donate_address = _dname;               // 設定捐款機構地址
        owner_name = "me";                     // 設定發起人名稱
        owner = msg.sender;                    // 發起人地址
        startime = block.timestamp;            // 開始時間(當前區塊高度時間)
        endtime = block.timestamp + 604800;    // 結束時間(開始時間後一周)
    }
    
    // 只有合約發起人能操作
    modifier OnlyOwner {
        require (owner == msg.sender,"你並非合約發起人");
        _;
    }
    
    // 捐款方法
    function donateMoney(uint money) public payable {
        require(now < startime + 604800,"募捐已經結束"); // 超過捐款時間後就無法進行捐款
        require(money == msg.value,"請檢查金額是否相符");
        
        emit setdonatedata(money);
        DP_date[msg.sender] = DonatePeople(msg.sender, money, now); // 捐款當下資料紀錄
    }
    
    // 將捐款發送給捐款機構(只有合約發起人能操作)
    function payDoation() public payable OnlyOwner{
        donate_address.transfer(address(this).balance);
    }
    // 查詢捐款金額
    function getDoation() public view returns(uint) {
        return address(this).balance;
    }
    
}