/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

//yeong hae
pragma solidity 0.8.0;

contract Likelion_11 {
        string[] grade;
        
        function class() public {
            if(grade.length == 0){
                grade.push("ava");
                grade.push("becky");
                grade.push("charise");
                grade.push("devy");
                grade.push("elice");
                grade.push("fabian");
            }
            
        }
        
        function studentCountAndAdd() public view returns(uint, uint) {
            uint viewCount= 0;
            uint add = 0;
            
            for(uint i = 0; i < grade.length; i++){
                viewCount += 1;
            }
            
            add = 10 - viewCount;
            
            return (viewCount, add);
        }
        
        function studentPush(string memory name) public {
            if(grade.length < 10){
                grade.push(name);
            }
            
        }
        
    //     function existent() public view returns(bool) {
            
    //         for(uint i = 0; i < grade.length; i++) {
    //             if( keccak256(bytes(grade[i])) == keccak256(bytes("sophia")) ) {
    //                 return true;
    //             }
    //             else{
    //                 return false;
    //             }
    //         }
    // }
        
        
        
        
}