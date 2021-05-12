/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity 0.8.0;


contract Likelion_10 {
    //YunJun Lee
    uint[] students_num ;
    string[] students = ["Ava", "Becky", 'Charlse', "Devy", "Elice", "Fabian"];
    
    
    function f1() public view returns(uint){
        return students.length;
        
    }
    
    function f2(string memory new_student) public {
        if (students.length <10)
            students.push(new_student);
            
    }
    
    function f3(string memory new_student) public returns(string memory){
            for (uint i=0; i<students.length; i+=1){
                if(keccak256(bytes(students[i])) == keccak256(bytes(new_student)))
                {
                    return "YES";
                }
            }
            return "NO";
    }
    
    function f4() public view returns(uint){
        return 10-students.length;
    }
    
    
    
}