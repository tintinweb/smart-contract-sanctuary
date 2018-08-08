pragma solidity ^0.4.19;

contract SimpleStorage {

    string[] public photoArr;

    mapping(address => uint) storeAddress;

    function storePhoto(string hash) public {
        if(storeAddress[msg.sender]==0){
            photoArr.push(hash);
            storeAddress[msg.sender] = 1;
        }
    }

    function getPhoto(uint index) public view returns (uint, string){
        if(photoArr.length==0){
            return (0, "");
        }else{
           return (photoArr.length, photoArr[index]);
        }
    }

    function isStored() public view returns (bool) {
        if(storeAddress[msg.sender]==0){
            return false;
        }else{
            return true;
        }
    }

}