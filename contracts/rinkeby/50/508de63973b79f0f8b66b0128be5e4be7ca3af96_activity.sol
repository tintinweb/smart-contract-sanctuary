/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity ^0.4.23;
contract activity {
    uint256 constant public cost = 0.1 ether;
    uint256 public people;
    mapping (address => bool) public list;  //mapping 用物件做驗證
    address public manager; //主辦人帳戶

    function activity(address _manager) public {    //可提取錢的錢包地址
        manager = _manager;
    }



    function getTicket (address _applicant) payable public {    // getTicket取得門票 ; payable 傳送錢的時候使用
        require(msg.value >=cost && list[_applicant] == false); //require 驗證的機制, 確認現在帳號的錢是否足夠支付 跟 確認是否重複報名
        list[_applicant] = true;    //報名成功 => var list{"地址":true"}
        people ++ ;
    }

    function payAll () public {
        manager.transfer(this.balance);     //領出裡面的錢
    }
}