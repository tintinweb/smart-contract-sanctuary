/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Fund {
    address private owner;
    Hocsinh[] public arrayHocsinh;
    uint public tongTien;
    
    struct Hocsinh{
        address _Address;
        uint _Tieen;
        string _HoTen;
    }
    
    constructor() {
        owner = msg.sender;
        tongTien=0;
    }
    
    // events
    event CoHocSinhVuaNapTien(uint tongTien, address vi, uint tien, string hoten);
    
    function napTien(string memory hoten) public payable{
        if(msg.value>0){
            arrayHocsinh.push(Hocsinh(msg.sender, msg.value, hoten));
            tongTien = tongTien + msg.value;
            emit CoHocSinhVuaNapTien(tongTien, msg.sender, msg.value, hoten);
        }
    }
    
    function hocSinhCounter() public view returns(uint){
        return arrayHocsinh.length;
    }
    
    function get_One_HocSinh(uint thutu) public view returns(address, uint, string memory) {
        return (arrayHocsinh[thutu]._Address, arrayHocsinh[thutu]._Tieen, arrayHocsinh[thutu]._HoTen);
    }
}

// msg.sender   : Address cua khach dang chay SM
// msg.value    : so tien cua khach dang chay ham payable
// Address.this : Address cuar SM