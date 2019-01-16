pragma solidity 0.4.25;
contract test {
    
   constructor() public{
       
   }
   function call_test() public returns(Itest3){
       test2 test_create = new test2();
       Itest3 Itest = Itest3(test_create);
       return Itest;
   }
    
}


contract test2{
    constructor() public {
        
    }
}

contract Itest3 {
    function assertIsWhitelisted(address _target) public view returns(bool);
    function lookup(bytes32 _key) public view returns(address);
    function stopInEmergency() public view returns(bool);
    function onlyInEmergency() public view returns(bool);
    // function getAugur() public view returns (IAugur);
    function getTimestamp() public view returns (uint256);
}