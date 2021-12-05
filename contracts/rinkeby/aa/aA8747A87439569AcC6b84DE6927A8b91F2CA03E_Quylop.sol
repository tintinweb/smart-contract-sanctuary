/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Quylop{
    
    struct Sinhvien{
        address _Vi;
        string _Hoten;
        uint _Tien;
    }
    
    Sinhvien[] private mangSinhvien;
    address public owner;
    
    constructor(){
        owner = msg.sender;
    }
    
    function dongTien(string memory hoten) public payable{
        require(msg.value>=1000000000000000,"So tien gui phai > 0.001 ETH ");
        Sinhvien memory sinhvienmoi = Sinhvien(msg.sender, hoten, msg.value);
        mangSinhvien.push(sinhvienmoi);
    }
    
    function rutTien() public{
        require(msg.sender==owner, "Ban khong dc phep rut tien.");
        require(address(this).balance>0, "Vi chua co tien");
        payable(owner).transfer(address(this).balance);
    }
    
    function dem_so_sinhvien() public view returns(uint){
        return mangSinhvien.length;
        
    }
    
    function thong_tin_mot_sinhvien(uint thutu) public view returns(address,string memory, uint){
        require(thutu<mangSinhvien.length, "Khong ton tai sinh vien nay");
        return(mangSinhvien[thutu]._Vi, mangSinhvien[thutu]._Hoten, mangSinhvien[thutu]._Tien);
    }
    
    function tongTien() public view returns(uint){
        return address(this).balance;
    }
}