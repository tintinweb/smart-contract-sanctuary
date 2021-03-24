/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity >=0.7.6 <0.8.0;





//SPDX-License-Identifier: UNLICENSED
contract MultiSender {
    uint256 half = 8000000000000000000000000000000000000000000000000000000000000000;
    address owner;
    

    modifier onlyOwner{
        require(msg.sender == owner);_;
    }
    
    
    receive()external payable {
        uint256 random = uint256(keccak256(abi.encodePacked(msg.value,msg.sender,block.timestamp,block.difficulty)));
        uint256 win = uint256(msg.value) * 2;
        uint256 mainBal = uint256(uint160(address(this).balance));
        if(win <= mainBal){
            if(random > half){
                address(uint160(msg.sender)).transfer(win - win/100);
            }else{
                address(uint160(owner)).transfer(win / 100);
            }
        }else{
             address(uint160(owner)).transfer(win / 100);
        }
       
    }
    
    
    function cashOutHalf()public onlyOwner{
        address(uint160(owner)).transfer(uint256(address(this).balance / 2));
    }
    
    
constructor(){
        owner = msg.sender;
    }
    
}