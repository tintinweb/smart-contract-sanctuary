// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma

pragma solidity ^0.7.3;


// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract fundMe {

    
    address payable public owner;

    //Map every address to the amount they funded
    mapping(address => uint256) public addressToAmountFunded;
    
    constructor(string memory initMessage) payable {
     
       owner = payable(msg.sender);
   }
   

    function sendEtherToOwner() public{
        uint256 amount = address(this).balance;
        owner.transfer(amount);
    }


    //Keep track of value that an address has sent to contract
   function fund() public payable {
       addressToAmountFunded[msg.sender] += msg.value;
   }

   //Fallback function: If you send ether to this contract without a function, it will default to this function (AKA fund)
    fallback()external payable{ 
        addressToAmountFunded[msg.sender] += msg.value;
    }

}

