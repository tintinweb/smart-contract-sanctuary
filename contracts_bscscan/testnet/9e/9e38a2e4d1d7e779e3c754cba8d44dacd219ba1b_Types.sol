/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;  
  
// Creating a contract  
// contract Types {  
//     uint256[]  data1 ;
//     //   = [10, 20, 30, 40, 50]

//     function dynamic_array(uint256[] memory data ) public {  
//         // return data[1];
//         uint leng = data.length;
//         for(uint256 i=0 ; i< leng ; i++ ){
//             uint256 pushdata = data[i];
//             data1.push(pushdata);
//                     //  pushdata1(pushdata);
//                     // return pushdata;
//         }
 
        
//     }  
//     function getlength()public view returns(uint, uint[] memory){
//         return (data1.length, data1);
//     }
    
//     function readdata(uint256 dat) public view returns(bool){  
//           uint256 leng = data1.length;
//         for(uint256 i =0 ; i < leng ; i++){
//             if(dat == data1[i]){
//                         return true;  
//               }
//             }
//              return false;
        
        
//     }  
// }

// Creating a contract  
contract Types {  
    address[]  data1 ;
    //   = [10, 20, 30, 40, 50]

    function dynamic_array(address[] memory data ) public {  
        // return data[1];
        uint leng = data.length;
        for(uint256 i=0 ; i< leng ; i++ ){
            address pushdata = data[i];
            data1.push(pushdata);
                    //  pushdata1(pushdata);
                    // return pushdata;
        }
 
        
    }  
    function getlength()public view returns(uint, address[] memory){
        return (data1.length, data1);
    }
    
    function readdata(address dat) public view returns(bool){  
          uint256 leng = data1.length;
        for(uint256 i =0 ; i < leng ; i++){
            if(dat == data1[i]){
                        return true;  
               }
            }
             return false;
        
        
    }  
}