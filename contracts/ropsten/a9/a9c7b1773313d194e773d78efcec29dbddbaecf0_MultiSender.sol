/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity >=0.7.0 <0.8.0;





//SPDX-License-Identifier: UNLICENSED
contract MultiSender {
    
    address owner;
    uint256 fee;
    
    modifier onlyOwner{
        require(msg.sender == owner);_;
    }


    constructor() {  
	owner = msg.sender;
	fee = 1000000000000000;
    } 
    
    function changeOwner(address adr)public onlyOwner{
        owner = adr;
    }
    
    function multiSender(address[] memory _address, uint256[] memory _amo)external  payable{
        if(_address.length == _amo.length && _address.length <= 100){
            for(uint8 i=0; i < 100; i++){
                if(i>=_address.length){
                    break;
                }else{
                    address(uint160(_address[i])).transfer(_amo[i]);
                }
                
            }
                address(uint160(owner)).transfer(fee);
        }else{
            revert();
        }
    }
    
    function errorHandler()external onlyOwner{
            address(uint160(owner)).transfer(address(this).balance);
    }
    function changeFee(uint256 _fee)external onlyOwner{
        fee = _fee;
    }
    
    function Fee()public view returns(uint256){
        return fee;
    }
    
    
    
}