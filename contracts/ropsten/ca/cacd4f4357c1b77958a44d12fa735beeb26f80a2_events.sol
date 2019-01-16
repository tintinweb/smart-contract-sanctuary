pragma solidity ^0.4.17;
contract events{
        string fname;
        uint age;
    
        event instructor(
          string name,
          uint age
           );
            
            function setinst(string _fname, uint _age) public{
                fname=_fname;
                age=_age;
                instructor(_fname,_age);
                
            }
            function getins() public view returns (string,uint){
                return(fname,age);
            }
    }