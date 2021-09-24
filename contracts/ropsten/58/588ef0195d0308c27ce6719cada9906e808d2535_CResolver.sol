/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICounter {
    function lastExecuted() external view returns (uint256);
    function zero(uint amount) external;
    //function request(uint _requestAmount, address _user) external view returns(address[] memory)
    function userAddresses() external view returns(address[] memory);
    function getAllUsers() external view returns (address[] memory);
}

contract CResolver {
    address public immutable mFiToken;
    bytes execPayload;

    //uint256 count;
    //uint256 amount;
    constructor(address _mFI) {
        mFiToken = _mFI;
    }

    function checker1() external view returns (address[] memory) {
        address[] memory getAllUsers = ICounter(mFiToken).getAllUsers();
     
        return getAllUsers;
    }
   
    function checker() external view returns (bool canExec,bytes memory execPayload)
    {
        uint256 lastExecuted = ICounter(mFiToken).lastExecuted();
        address[] memory getAllUsers = ICounter(mFiToken).getAllUsers();
        
        //for (uint i=0; i<getAllUsers.length; i++)
    
            if(getAllUsers.length != 0){
               canExec = (block.timestamp - lastExecuted) > 50;
               return (false, execPayload);
              } 
            else {
                canExec = (block.timestamp - lastExecuted) > 50;
                execPayload = abi.encodeWithSelector(ICounter.zero.selector, uint256(1));
                return (canExec,execPayload);
             }
            
        
        
        /*
        if ((block.timestamp - lastExecuted) > 50) {
           return canExec;
        } else if (abi.encodeWithSelector(ICounter.zero.selector, uint256(1))) {
           return canExec; 
        } else 
          return canExec;  
        }*/
        //canExec1 = ((block.timestamp - lastExecuted) > 180);
        
       // execPayload = abi.encodeWithSelector(ICounter.zero.selector, uint256(1));
        //execPayload = abi.encodeWithSelector(ICounter.increaseCount.selector, uint256(100));
    }
}