/**
 *Submitted for verification at polygonscan.com on 2021-07-12
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




contract Owned {

    address public owner;

    address public newOwner;


    event OwnershipTransferred(address indexed _from, address indexed _to);


    constructor() public {

        owner = msg.sender;

    }


    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }


    function transferOwnership(address _newOwner) public onlyOwner {

        newOwner = _newOwner;

    }

    function acceptOwnership() public {

        require(msg.sender == newOwner);

        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);

    }

}







contract PaySpec is Owned {

   using SafeMath for uint;


   mapping(bytes32 => Invoice) invoices;

   bool lockedByOwner = false;
   uint fee_pct;

  event CreatedInvoice(bytes32 uuid);
  event PaidInvoice(bytes32 uuid, address from);


  struct Invoice {
    bytes32 uuid;
    string description;
    uint256 nonce;


    address token;
    uint256 amountDue;
    address payTo;


    address paidBy;
    uint256 amountPaid;
    uint256 ethBlockPaidAt;


    uint256 ethBlockExpiresAt;

  }



  constructor( uint fee_percent ) public {
    fee_pct = fee_percent;

    require(fee_pct >= 0 && fee_pct <= 100);
  }


  //do not allow ether to enter
  function() external    payable {
      revert();
  }

  function lockContract() public onlyOwner {
    lockedByOwner = true;
  }


  function createAndPayInvoice(  string memory description, uint256 nonce, address token, uint256 amountDue, address payTo, uint256 ethBlockExpiresAt, bytes32 expecteduuid  ) public returns (bool) {
     bytes32 newuuid = _createInvoice(description,nonce,token,amountDue,payTo,ethBlockExpiresAt,expecteduuid);
     require(newuuid == expecteduuid);
     return _payInvoice(newuuid);
  }

   function _createInvoice(  string memory description, uint256 nonce, address token, uint256 amountDue, address payTo, uint256 ethBlockExpiresAt, bytes32 expecteduuid ) private returns (bytes32 uuid) {

     

      bytes32 newuuid = getInvoiceUUID(description, nonce, token, amountDue, payTo, ethBlockExpiresAt ) ;

      require(!lockedByOwner);
      require( newuuid == expecteduuid );
      require( invoices[newuuid].uuid == 0 );  //make sure you do not overwrite invoices

      invoices[newuuid] = Invoice({
       uuid:newuuid,
       description:description,
       nonce: nonce,
       token: token,
       amountDue: amountDue,
       payTo: payTo,
       paidBy: address(0),
       amountPaid: 0,
       ethBlockPaidAt: 0,
       ethBlockExpiresAt: ethBlockExpiresAt

      });


       emit CreatedInvoice(newuuid);

       return newuuid;
   }

   function _payInvoice( bytes32 invoiceUUID ) private returns (bool) {

       address from = msg.sender;

       require(!lockedByOwner);
       require( invoices[invoiceUUID].uuid == invoiceUUID ); //make sure invoice exists
       require( invoiceWasPaid(invoiceUUID) == false );
       require( invoiceHasExpired(invoiceUUID) == false);

       uint amountDueInFees = invoices[invoiceUUID].amountDue.mul( fee_pct ).div(100);

       uint amountDueLessFees =  invoices[invoiceUUID].amountDue.sub( amountDueInFees );

       require( amountDueInFees.add(amountDueLessFees) ==  invoices[invoiceUUID].amountDue );

       //transfer the tokens to the seller
       require( ERC20Interface( invoices[invoiceUUID].token  ).transferFrom( from ,  invoices[invoiceUUID].payTo, amountDueLessFees  ) );

       //transfer the fee to contract owner
       require( ERC20Interface( invoices[invoiceUUID].token  ).transferFrom( from ,  owner, amountDueInFees) );


       invoices[invoiceUUID].amountPaid = invoices[invoiceUUID].amountDue;

       invoices[invoiceUUID].paidBy = from;

       invoices[invoiceUUID].ethBlockPaidAt = block.number;



       emit PaidInvoice(invoiceUUID, from);

       return true;


   }

   function getInvoiceUUID(  string memory description, uint256 nonce, address token, uint256 amountDue, address payTo, uint expiresAt  ) public view returns (bytes32 uuid) {
 

         bytes32 newuuid = keccak256( abi.encodePacked( description, nonce, token, amountDue, payTo, expiresAt ) );

         return newuuid;
    }

   function invoiceWasPaid( bytes32 invoiceUUID ) public view returns (bool){

       return invoices[invoiceUUID].amountPaid >= invoices[invoiceUUID].amountDue;
   }



   function invoiceExpiresAt( bytes32 invoiceUUID ) public view returns (uint){

       return invoices[invoiceUUID].ethBlockExpiresAt;
   }

   function invoiceHasExpired( bytes32 invoiceUUID ) public view returns (bool){

       return (invoiceExpiresAt(invoiceUUID) != 0 && block.number >= invoiceExpiresAt(invoiceUUID));
   }



}