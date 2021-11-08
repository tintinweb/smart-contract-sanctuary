/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

pragma solidity 0.8.4;

contract Minigame{
    
    HocVien[] public arrHocVien; 
    
    
    struct HocVien{
        string _ID;
        address _VI;
    }
    
    event SM_Ban_Data(address _vi, string _id);
    
    function dangKy(string memory id) public{
        HocVien memory hocVienMoi = HocVien(id,msg.sender);
        arrHocVien.push(hocVienMoi);
        emit SM_Ban_Data(msg.sender,id);
    }
}