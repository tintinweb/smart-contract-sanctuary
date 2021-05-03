/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity ^0.5.16;

contract BoPhieuLogoSN{
    
    address admin;
    bool isClose = false;
    
    mapping(string => string[]) public dsLogo;
    mapping(string => bool) public dsNguoiBoPhieu;
    
    event eBoPhieu(
        string indexed hashAnh,
        string indexed user
    );
    
    constructor(address addressAdmin) public {
        admin = addressAdmin;
    }
    
    function themLogo(string memory hashAnh) public{
        require(msg.sender == admin,"Ban khong du quyen de them logo");
        string[] memory emptyArray;
        dsLogo[hashAnh] = emptyArray;
    }

    function dongSuKien() public{
        require(msg.sender == admin,"Ban khong du quyen de dong su kien");
        isClose = true;
    }
    
    function bophieu(string memory hashAnh, string memory user) public{
        require(isClose == false,"Su kien bo phieu logo da dong");
        require(dsNguoiBoPhieu[user] == false,"Nguoi dung nay da bo phieu");
        
        dsNguoiBoPhieu[user] = true;
        dsLogo[hashAnh].push(user);
        
        emit eBoPhieu(hashAnh, user);
    }
}