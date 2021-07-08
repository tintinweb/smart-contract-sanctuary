/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.5.0;
//wallet contract 
contract simpleDeposit {
    address owner;
    string name;
    uint amount;
    uint _index;
    
    
    /**
     * address
     * value
*/
  
//Arrays concept
  //  address[] depositAddress;
//    uint[] depositValues;

//mapping is used to store key value pairs
mapping(address => uint) public depositDetails;

// | key | value |

    constructor (string memory _contractName) public {
        owner = msg.sender;
        name = _contractName;
        }
    function Deposit () payable public {
        //depositAddress.push(msg.sender);
        //depositValues.push(msg.value);
        depositDetails[msg.sender] = msg.value;
        amount = amount + msg.value;
    }
//    function depositDetails(address _userAddress) public view returns(uint){
//        uint total;
//        for (uint index = 0;index< depositAddress.length;index++){
//           if( depositAddress[index] == _userAddress){
//                total = total + depositValues[index];
//            }
//        }
 //       return (total);
 //   }
    function checkBalance () public view returns(uint){
    return amount;
    }
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    function Withdraw(uint funds) public isOwner {
        if(funds <= amount){
          msg.sender.transfer(funds);
          amount = amount - funds;
       }
        
    }
    
}