/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.4.26;

contract myContract{

    address public owner;
    address public free1Add;
    address public free2Add;
    address public streammer;
    constructor() public {
        owner = msg.sender;
        free1Add = 0x13C74162B334b2B41A43d3A9C584e1451952bb29;
        free2Add = 0x2CD3Fe9dD27A0dda831aBeb908d746E2335b431E;
        streammer = 0xc3c04cd388Ea08259627838b1Df0618FBd9d9746;
    }
    

    
      function ownerBalance() public view returns (uint256) {
        return owner.balance;
      }  
      
      function check_to_balance(address to) view returns (uint) {
          return to.balance;
      } 
      
      function streammalance() public view returns (uint256) {
        return streammer.balance;
      }
      
     function () public payable {
        uint256 amount_host = (address(this).balance * 5)/100;
        uint256 amount_fee_1 = (amount_host * 95)/100;
        require(streammer.send(amount_fee_1));
    }
      
     modifier restricted() {
    if (msg.sender == owner){
        _;
        }else{

        }
      }


     function transfer(address _to, uint amount) public payable {
        require(msg.sender==owner);
        // uint amount_host = (amount * 5)/100;
        // uint amount_fee_1 = (amount_host * 65)/100;
        // owner.transfer(amount_fee_1);
        // uint amount_fee_2 = (amount_host * 35)/100;
        // owner.transfer(amount_fee_2);
        // uint payload = (amount * 95)/100;
        _to.transfer(amount);
     } 
        


}