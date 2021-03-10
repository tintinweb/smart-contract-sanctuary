/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value) returns (bool);
  function approve(address spender, uint value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/*
The owner (or anyone) will deposit tokens in here
The owner calls the multisend method to send out payments
*/
contract UniqueBatchedPayments  {

    mapping(bytes32 => bool) successfulPayments;

 


    function paymentSuccessful(address sender, bytes32 paymentId) public constant returns (bool){
        
        bytes32 scopedPaymentId = keccak256(abi.encodePacked(sender,paymentId));
        
        return (successfulPayments[scopedPaymentId] == true);
    }
 
   

     //tokens need to be in msg.senders account and approved to this contract 
    function multisend(address _tokenAddr, bytes32 paymentId, address[] dests, uint256[] values) 
    returns (uint256)
     {  
         
        bytes32 scopedPaymentId = keccak256(abi.encodePacked(msg.sender,paymentId));

        require(dests.length > 0);
        require(values.length >= dests.length);
        require(successfulPayments[scopedPaymentId] != true);

        uint256 i = 0;
        while (i < dests.length) {
           require(ERC20(_tokenAddr).transferFrom(msg.sender, dests[i], values[i]));
           i += 1;
        }

        successfulPayments[scopedPaymentId] = true;

        return (i);

    }



     // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------

    function () public payable {

        revert();


    }
    
}