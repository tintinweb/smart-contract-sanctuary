/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// File: contracts\SafeMath.sol

pragma solidity ^0.4.17;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  // it is recommended to define functions which can neither read the state of blockchain nor write in it as pure instead of constant

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
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: contracts\escrow_.sol

pragma solidity ^0.4.17;

contract Escrow {
    mapping (address => uint256) private balances; // stores the balances pf addresses.

    address public seller; //address of the seller
    address public buyer;  // address of the buyer
    address public escrowAgent; //owner of this escrow contract
    uint256 public blockNumber;
    uint public feePercent; //fee percent that needs to be paid to escrow agent
 
    uint256 public contract_balance; // stores balance of escrow contract

    bool public sellerShipmentApproval; //variable that confirms that seller sent the shipment
    bool public buyerShipmentApproval;  //variable that confirms that buyer has received the shipment. 
    
    bool public buyerOrderPlacement; //buyer has placed the order
    bool public sellerApprovesOrder; // seller has approved the placed order.
    
   
    uint256 public sellerAmount;  //the amount seller sells the product
    uint256 public feeAmount;   //amount that needs to be paid to escrow agent.

    enum EscrowState { unInitialized, initialized, buyerDeposited, shipmentStarted, shipmentReceived, escrowCompleted,escrowCancelled }
    
    EscrowState public eState = EscrowState.unInitialized;

    event Deposit(address depositor, uint256 deposited); // event that tells that the buyer has deposited amount
    
    event PaymentCompleted(uint256 blockNo, uint256 contractBalance);  // event that tells the amount has been received by seller.

    modifier onlyBuyer() {
        if (msg.sender == buyer) {
            _;
        } else {
            revert();
        }
    }
    
    modifier onlySeller() {
        if (msg.sender == seller) {
            _;
        } else {
            revert();
        }
    }

    modifier onlyEscrowAgent() {
        if (msg.sender == escrowAgent) {
            _;
        } else {
            revert();
        }
    }    

    modifier checkBlockNumber() {
        if (blockNumber > block.number) {
            _;
        } else {
            revert();
        }
    }

   //function called at contract deployment
    function Escrow(address eAgent) public {
        escrowAgent = eAgent;
    }

    function () public { 
        // fallback function to disallow any other deposits to the contract
        revert();
    }
 
 // function that initializes the seller, buyer addresses
    function initEscrow(address _seller, address _buyer, uint _feePercent, uint256 _blockNum) public onlyEscrowAgent {
        require((_seller != msg.sender) && (_buyer != msg.sender));
        seller = _seller;
        buyer = _buyer;
        feePercent = _feePercent;
        blockNumber = _blockNum;
        eState = EscrowState.initialized;

    }
    
    // seller sets the price of the product
      function setProductPrice(uint price) public onlySeller{
        sellerAmount = price;
        
    }
    
    //get the sellerAmount
     function getSellermount() public view returns (uint256) {
        return sellerAmount;
    }
    // buyer places the product order
     function placeProductOrder() public onlyBuyer{
        buyerOrderPlacement = true;
        
    }
    // approve the order placed by buyer
     function approveProductOrder() public onlySeller{
         
         if(buyerOrderPlacement){
            sellerApprovesOrder = true;
         }
        
    }

//After Buyer and a Seller confirm and agree on the terms of a sale of a Seller's product. 
//The Buyer places Ethereum currency into the smart contract - this provides buyer's proof-offunds to the seller
    function depositToEscrow() public payable checkBlockNumber onlyBuyer {
        
        require(msg.value > 0, "Make sure you just call deposit with some money"); // make sure buyer does not deposit 0 amount
        if(buyerOrderPlacement && sellerApprovesOrder){
            contract_balance= SafeMath.add(contract_balance, msg.value);
            eState = EscrowState.buyerDeposited;
            emit Deposit(msg.sender, msg.value); // solhint-disable-line
        }
    }

//The Seller sees that the buyer has enough funds and ships the product to the Buyer producing an 
//evidence of shipment to an independent third party called Escrow Agent.
    function sellerInitiatesShipment() public onlySeller{
        
        require(contract_balance >= sellerAmount);
            eState = EscrowState.shipmentStarted;
        
    }
//After buyer confirms that shipment is received this produces evidence for escrowAgent regarding shipment    
    function buyerConfirmsShipment() public onlyBuyer{
        eState = EscrowState.shipmentReceived;
    }
    
//Escrow Agent sees the evidence of shipment and initiates the transfer of the funds stored in the escrow to the Seller.     
    function approveEscrow() public checkBlockNumber onlyEscrowAgent{
       
        if (eState == EscrowState.shipmentReceived) {
            eState = EscrowState.escrowCompleted;
            fee();
            payOutFromEscrow();
            emit PaymentCompleted(block.number,contract_balance); 
        }else{ //In case the seller does not produce an evidence of shipment to the Escrow Agent then Escrow Agent returns the funds
        //from escrow to the Buyer. Buyer receives his/her money back.
            eState = EscrowState.escrowCancelled;
            fee();  //Escrow Agent can get a small fee of the transaction amount for his/her impartial arbitration.
            refund();
        }
    }


    function checkEscrowStatus() public view returns (EscrowState) {
        return eState;
    }
    
    function getEscrowContractAddress() public view returns (address) {
        return address(this);
    }

// function that pays to the sells
    function payOutFromEscrow() private {
        balances[seller] = SafeMath.add(balances[seller], contract_balance);
        eState = EscrowState.escrowCompleted;
        sellerAmount = contract_balance;
        seller.transfer(contract_balance);
        contract_balance =0;
    }

     function refund() private {
        buyer.transfer(contract_balance);
        contract_balance=0;
    }
    //fee paid to the escrow agent.
    function fee() private {
        uint totalFee = contract_balance * (feePercent / 100);
        feeAmount = totalFee;
        escrowAgent.transfer(totalFee);
    }

    
}