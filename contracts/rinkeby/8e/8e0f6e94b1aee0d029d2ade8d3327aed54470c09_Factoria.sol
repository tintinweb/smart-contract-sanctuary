/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;

contract Factoria{
     Child[] public children;
     uint disabledCount;

    event ChildCreated(address childAddress, uint data);

     function createChild(uint data) external{
       Child child = new Child(data, children.length);
       children.push(child);
       emit ChildCreated(address(child), data);
     }

     function getChildren() external view returns(Child[] memory _children){
       _children = new Child[](children.length- disabledCount);
       uint count;
       for(uint i=0;i<children.length; i++){
          if(children[i].isEnabled()){
             _children[count] = children[i];
             count++;
          }
        }
     }  

     function disable(Child child) external {
        children[child.index()].disable();
        disabledCount++;
     }
 
}
contract Child{
    uint data;
    bool public isEnabled;
    uint public index;
    constructor (uint _data,uint _index){
       data = _data;
       isEnabled = true;
       index = _index;
    }

    function disable() external{
      isEnabled = false;
    }
}