/**
 *Submitted for verification at polygonscan.com on 2021-07-24
*/

pragma solidity ^0.8.0;



contract fee_divider {
   
   address payable public toadd1 = payable(0x08Be0EB2345a54454FDD19ED5E01391914f721A1);
   address payable public toadd2 = payable(0x08Be0EB2345a54454FDD19ED5E01391914f721A1);
   address public owner;

    function transferfee() public {
        toadd1.transfer(address(this).balance / 2);
        toadd2.transfer(address(this).balance / 2);
    }

    fallback() external payable{}
    receive() external payable{}

   
   function checkbalance() public view returns(uint){
       return address(this).balance / 10 ** 18;
   }
   
    constructor() {
        owner = msg.sender;
    }

    function setadd1(address _toadd1) public{
        require( owner == msg.sender );
        toadd1 = payable(_toadd1);
    }

    function setadd2(address _toadd2) public{
        require( owner == msg.sender );
        toadd2 = payable(_toadd2);
    }
}