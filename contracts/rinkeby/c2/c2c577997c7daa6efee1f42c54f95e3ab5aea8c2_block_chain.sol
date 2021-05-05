/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract block_chain{
    
    uint public send_money;
    address public senderAddress;
    uint public check;
    uint public to_n;
    function mul_to_n(uint n) public view returns(uint ret){
        if(check == 1090322 )
        {
            ret =1;
            for(uint count =1;count<=n;count++ ){
                ret = ret*count;
        }    
        }
        else{
            ret =0;
        }
    }
    function get_info()public payable{
       send_money = msg.value;
        senderAddress = msg.sender;
        check = send_money;
       
    }
}