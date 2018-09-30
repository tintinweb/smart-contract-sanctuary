contract Example {
      uint256 myNumber;
      address public owner;

    constructor() public {
        owner = msg.sender;
    }
  
  /*  modifier onlyOwner{
          require(myNumber == msg.sender);
          _;
    }
*/
    function showMyNumber() public returns(address){
        /* require (owner == msg.sender);*/
         return owner;
     }
}