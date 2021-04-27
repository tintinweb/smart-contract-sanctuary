/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^0.5.0;



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/*
PAYSPEC: Generic global invoicing contract


*/

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}






contract PaySpec  {

   using SafeMath for uint;


   mapping(bytes32 => Invoice) invoices;



  event CreatedInvoice(bytes32 uuid);
  event PaidInvoice(bytes32 uuid, address from);


  struct Invoice {
    bytes32 uuid;
    string description;
    uint256 refNumber;


    address token;
    uint256 amountDue;
    address payTo;
    uint256 ethBlockCreatedAt;


    address paidBy;
    uint256 amountPaid;
    uint256 ethBlockPaidAt;


    uint256 ethBlockExpiresAt;

  }



  constructor(  ) public {


  }


  //do not allow ether to enter
  function() external    payable {
      revert();
  }


  function getContractVersion( ) public pure returns (uint)
  {
      return 1;
  }


  function createInvoice(uint256 refNumber, string memory description,  address token, uint256 amountDue, address payTo, uint256 ethBlockExpiresAt ) public returns (bytes32 uuid) {
      return _createInvoiceInternal(msg.sender, refNumber,description,token,amountDue,payTo,ethBlockExpiresAt);
  }

  //why doesnt this work ?
  function createAndPayInvoice(uint256 refNumber, string memory description,  address token, uint256 amountDue, address payTo, uint256 ethBlockExpiresAt ) public returns (bool) {
      bytes32 invoiceUUID =  _createInvoiceInternal(msg.sender, refNumber,description,token,amountDue,payTo,ethBlockExpiresAt) ;

      require( ERC20Interface(  invoices[invoiceUUID].token ).transferFrom(msg.sender, address(this),  invoices[invoiceUUID].amountDue )   );

      return _payInvoiceInternal( invoiceUUID, msg.sender);
  }

   function _createInvoiceInternal( address from, uint256 refNumber, string memory description,  address token, uint256 amountDue, address payTo, uint256 ethBlockExpiresAt ) private returns (bytes32 uuid) {

      uint256 ethBlockCreatedAt = block.number;

      bytes32 newuuid = keccak256( abi.encodePacked(from, refNumber, description,  token, amountDue, payTo ) );

      require( invoices[newuuid].uuid == 0 );  //make sure you do not overwrite invoices

      invoices[newuuid] = Invoice({
       uuid: newuuid,
       description: description,
       refNumber: refNumber,
       token: token,
       amountDue: amountDue,
       payTo: payTo,
       ethBlockCreatedAt: ethBlockCreatedAt,
       paidBy: address(0),
       amountPaid: 0,
       ethBlockPaidAt: 0,
       ethBlockExpiresAt: ethBlockExpiresAt

      });


       emit CreatedInvoice(newuuid);

       return newuuid;
   }

   function payInvoice(bytes32 invoiceUUID) public returns (bool)
   {
     //transfer the tokens into escrow into this contract to stage for paying the invoice
     require( ERC20Interface(  invoices[invoiceUUID].token ).transferFrom(msg.sender, address(this),  invoices[invoiceUUID].amountDue )   );

     return _payInvoiceInternal( invoiceUUID, msg.sender);


   }

   function _payInvoiceInternal( bytes32 invoiceUUID, address from ) private returns (bool) {

       require( invoices[invoiceUUID].uuid == invoiceUUID ); //make sure invoice exists
       require( invoiceWasPaid(invoiceUUID) == false );
       require( invoiceHasExpired(invoiceUUID) == false);

       //Transfer the tokens. Always transfer from this contracts escrow (not wildcard) so tokens only approved to this universal contract cannot be spent by others.
       require( ERC20Interface( invoices[invoiceUUID].token  ).transfer(  invoices[invoiceUUID].payTo, invoices[invoiceUUID].amountDue   ) );

       invoices[invoiceUUID].amountPaid = invoices[invoiceUUID].amountDue;

       invoices[invoiceUUID].paidBy = from;

       invoices[invoiceUUID].ethBlockPaidAt = block.number;



       emit PaidInvoice(invoiceUUID, from);

       return true;


   }

   function getDescription( bytes32 invoiceUUID ) public view returns ( string  memory )
   {
       return invoices[invoiceUUID].description;
   }

   function getRefNumber( bytes32 invoiceUUID ) public view returns (uint)
   {
       return invoices[invoiceUUID].refNumber;
   }

   function getEthBlockExpiresAt( bytes32 invoiceUUID ) public view returns (uint)
   {
       return invoices[invoiceUUID].ethBlockExpiresAt;
   }

   function getTokenAddress( bytes32 invoiceUUID ) public view returns (address)
   {
       return invoices[invoiceUUID].token;
   }

   function getRecipientAddress( bytes32 invoiceUUID ) public view returns (address)
   {
       return invoices[invoiceUUID].payTo;
   }

   function invoiceExists ( bytes32 invoiceUUID ) public view returns (bool)
   {
     return invoices[invoiceUUID].uuid == invoiceUUID;
   }


   function getAmountDue( bytes32 invoiceUUID ) public view returns (uint)
   {
       return invoices[invoiceUUID].amountDue;
   }

   function getAmountPaid( bytes32 invoiceUUID ) public view returns (uint)
   {
       return invoices[invoiceUUID].amountPaid;
   }

   function getEthBlockPaidAt( bytes32 invoiceUUID ) public view returns (uint)
   {
       return invoices[invoiceUUID].ethBlockPaidAt;
   }


   function invoiceWasPaid( bytes32 invoiceUUID ) public view returns (bool)
   {
       return getEthBlockPaidAt(invoiceUUID) > 0;
   }


   function invoiceHasExpired( bytes32 invoiceUUID ) public view returns (bool)
   {
       return (getEthBlockExpiresAt(invoiceUUID) != 0 && block.number >= getEthBlockExpiresAt(invoiceUUID));
   }



   /*
     Receive approval from ApproveAndCall() to pay invoice.  The first 32 bytes of the data array are used for the invoice UUID bytes32.

   */
     function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public returns (bool) {

        //can only be called by the token contract
        require(msg.sender == token);

        //transfer the tokens into escrow into this contract to stage for paying the invoice
        require( ERC20Interface(token).transferFrom(from, address(this), tokens)   );

        require(  _payInvoiceInternal(bytesToBytes32(data,0), from)  );

        return true;

     }

    function bytesToBytes32(bytes memory b, uint offset) private pure returns (bytes32) {
      bytes32 out;

      for (uint i = 0; i < 32; i++) {
        out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
      }
      return out;
    }


}