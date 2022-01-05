/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

pragma solidity >=0.7.0 <0.9.0;

contract  Play {
    
    string  public name;
    address  public owner;
    constructor() public {
        owner = msg.sender;
    }

    function deposit() public payable{}

     function  withdraw() public {

         payable(msg.sender).transfer(address(this).balance);
     }

     function balance() public  view returns(uint256) {
       return   address(this).balance;
     }

     function change(string memory  _name) public  {
         name = _name;

     }

     function withdrawProtected() public  {

         require(msg.sender == owner);
          withdraw();

     }


}