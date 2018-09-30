pragma solidity ^0.4.24;

contract Recruit2{
    
    uint sixteen = 16;
    uint modulus = 10**sixteen;
    
    event Apply(string _name, uint _birthday, uint _personalNumber);
    
    
    struct Applier{
        string name;
        uint birthday;
        uint personalNumber;
        }
        
    Applier[] public appliers;
    
    
    function insertInfo(string _name, uint _birthday, uint _personalNumber) {
        appliers.push(Applier(_name, _birthday, _personalNumber));
        
    }
    
    function _generatePersonalNumber(string _name, uint _birthday) private view returns(uint){
        uint personalNumber = uint( keccak256 (_name, _birthday)) ;
        return personalNumber % modulus;
    }
    
    function apply(string _name, uint _birthday) public {
        uint personalNumber = _generatePersonalNumber(_name, _birthday);
        insertInfo(_name, _birthday, personalNumber);
        
        emit Apply(_name, _birthday, personalNumber);
    }
    
    

 
    
    
}