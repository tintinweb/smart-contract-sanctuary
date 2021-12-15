/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

contract Course {struct Professor {
        int256 age;
        int256 age2;
        uint256 apple;
        uint256 apple3;
        bytes16 sue;
        bytes16 sue2;

    }
    
    string constant course_name = "Painting";Professor public module_leader;
    
    constructor() public {
        module_leader.age = 9;
        module_leader.age2=9;
        module_leader.apple=9;
        module_leader.apple3=9;
        module_leader.sue=0x80000000000000000000000000000000;
        module_leader.sue2=0x80000000000000000000000000000000;
    }


    function modifyModuleLeader(Professor memory _name) public {
        Professor storage new_module_leader = module_leader;
        new_module_leader.age = 3;
    }
    

   

}