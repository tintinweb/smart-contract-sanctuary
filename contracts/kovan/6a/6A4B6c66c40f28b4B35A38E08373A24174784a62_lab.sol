/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

pragma solidity ^0.8.0;

contract lab
{

    uint total = 0;
    
    struct Tasks{
        string task;
        bool status;
    }
    
    mapping(uint=>Tasks) list;

    function addTask(string memory _task) public{
        list[total++]= Tasks(_task,false);
    }

    function completeTask(uint _index) public{   
        list[_index].status=true;
    }

    function getTotal() public view returns(uint){
        return total;
    }

    function printTask() public view returns(string memory){
        string memory a="";

        uint x=0;
        while (x<total){
            a = string(abi.encodePacked(a," ",list[x].task));
            x++;
        }
        return a;
    }

    function completed() public view returns(uint){
        uint c=0;
        uint t=0;
        while (t<total){
            if(list[t].status==true){
                c++;
            }
            t++;
        }
        return c;
    }

    function uncompleted() public view returns(uint){
        uint c=0;
        uint t=0;
        while (t<total){
            if(list[t].status==false)
                c++;
            t++;
        }
        return c;
    }
}