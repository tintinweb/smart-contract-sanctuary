pragma solidity 0.5.1;

interface Token {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    function balanceOf(address _who) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
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

contract ethifly is Owned, SafeMath{

    struct EscrowStruct
    {    
        address buyer;          //Person who is making payment
        address seller;         //Person who will receive funds
        address escrow_agent;   //Escrow agent to resolve disputes, if any
                                   
        uint escrow_fee;        //Fee charged by escrow
        uint amount;            //Amount of Ether (in Wei) seller will receive after fees

        bool escrow_intervention; //Buyer or Seller can call for Escrow intervention
        bool release_approval;   //Buyer or Escrow(if escrow_intervention is true) can approve release of funds to seller
        bool refund_approval;    //Seller or Escrow(if escrow_intervention is true) can approve refund of funds to buyer 

        bytes32 notes;             //Notes for Seller
        
    }

    struct TransactionStruct
    {                        
        //Links to transaction from buyer
        address buyer;          //Person who is making payment
        uint buyer_nounce;         //Nounce of buyer transaction                            
    }
    
    //address public owner;

    //Token address -> User address -> Array of transaction structs
    mapping (address => mapping (address => EscrowStruct[])) public buyerDatabase;
    mapping (address => mapping (address => TransactionStruct[])) public sellerDatabase;
    mapping (address => mapping (address => TransactionStruct[])) public escrowDatabase;

    //Every address have a Funds bank for each token. 
    //All refunds, sales and escrow comissions are sent to this bank. Address owner can withdraw them at any time.
    mapping(address => mapping (address => uint)) public Funds;

    //Escrow agents can charge a 0 - 10% fee for their services, in increments of 0.1%. 
    mapping(address => uint) public escrowFee;
    
    constructor() public{
        //owner = msg.sender;
    }
    
    function() payable external
    {
        revert();
    }

    function setEscrowFee(uint fee) external {
    //Allowed fee range: 0.1% to 10%, in increments of 0.1%
    require (fee >= 1 && fee <= 100);
    escrowFee[msg.sender] = fee;
    }
    
    function newEscrow(address sellerAddress, address escrowAddress, address _token, uint _amount, bytes32 notes, bool dev_fee) payable public returns (bool) {

    //require(msg.sender != escrowAddress);
    Token token = Token(_token);
    uint amount = _amount * 10**18; //Grab decimal directly from contract in the future
    
    require(
    token.transferFrom(
        msg.sender,
        address(this),
        (amount)
    ));  // Require the token for escrow to be sucessfully sent to contract first
    
    
    //Store escrow details in memory
    EscrowStruct memory currentEscrow;
    TransactionStruct memory currentTransaction;
    
    currentEscrow.buyer = msg.sender;
    currentEscrow.seller = sellerAddress;
    currentEscrow.escrow_agent = escrowAddress;

    //Calculates and stores Escrow Fee.
    currentEscrow.escrow_fee = escrowFee[escrowAddress]*amount/1000;
    
    
    uint dev_fee_amount = 0;
    //0.2% dev fee for ethifly platform
    if (dev_fee == true){
        dev_fee_amount = amount/500;
        Funds[_token][owner] += dev_fee_amount;
    }

    //Amount seller receives = Total amount - dev fee (if any) - Escrow Fee
    currentEscrow.amount = msg.value - dev_fee_amount - currentEscrow.escrow_fee;

    currentEscrow.notes = notes;

    //Links this transaction to Seller and Escrow&#39;s list of transactions.
    currentTransaction.buyer = msg.sender;
    currentTransaction.buyer_nounce = buyerDatabase[_token][msg.sender].length;

    sellerDatabase[_token][sellerAddress].push(currentTransaction);
    escrowDatabase[_token][escrowAddress].push(currentTransaction);
    buyerDatabase[_token][msg.sender].push(currentEscrow);
    
    return true;

}

    //switcher 0 for Buyer, 1 for Seller, 2 for Escrow
    function getNumTransactions(address inputAddress, address _token ,uint switcher) public view returns (uint)
    {
        if (switcher == 0) return (buyerDatabase[_token][inputAddress].length);
        else if (switcher == 1) return (sellerDatabase[_token][inputAddress].length);
        else return (escrowDatabase[_token][inputAddress].length);
    }
    
    //switcher 0 for Buyer, 1 for Seller, 2 for Escrow
    function getSpecificBuyerTransaction(address inputAddress, address _token , uint ID) public view returns (address, address, address, uint, bytes32, uint, bytes32)

    {
        bytes32 status;
        EscrowStruct memory currentEscrow;
        currentEscrow = buyerDatabase[_token][inputAddress][ID];
        status = checkStatus(inputAddress, _token, ID);

        return (currentEscrow.buyer, currentEscrow.seller, currentEscrow.escrow_agent, currentEscrow.amount, status, currentEscrow.escrow_fee, currentEscrow.notes);
    }
    
    function checkStatus(address buyerAddress, address _token, uint nounce) public view returns (bytes32){

        bytes32 status = "";
    
        if (buyerDatabase[_token][buyerAddress][nounce].release_approval){
            status = "Complete";
        } else if (buyerDatabase[_token][buyerAddress][nounce].refund_approval){
            status = "Refunded";
        } else if (buyerDatabase[_token][buyerAddress][nounce].escrow_intervention){
            status = "Pending Escrow Decision";
        } else
        {
            status = "In Progress";
        }
    
        return (status);
    }
    
    //When transaction is complete, buyer will release funds to seller
    //Even if EscrowEscalation is raised, buyer can still approve fund release at any time
    function buyerFundRelease(uint ID, address _token) public
    {
        require(ID < buyerDatabase[_token][msg.sender].length && 
        buyerDatabase[_token][msg.sender][ID].release_approval == false &&
        buyerDatabase[_token][msg.sender][ID].refund_approval == false);
        
        //Set release approval to true. Ensure approval for each transaction can only be called once.
        buyerDatabase[_token][msg.sender][ID].release_approval = true;

        address seller = buyerDatabase[_token][msg.sender][ID].seller;
        address escrow_agent = buyerDatabase[_token][msg.sender][ID].escrow_agent;

        uint amount = buyerDatabase[_token][msg.sender][ID].amount;
        uint escrow_fee = buyerDatabase[_token][msg.sender][ID].escrow_fee;

        //Move funds under seller&#39;s owership
        Funds[_token][seller] += amount;
        Funds[_token][escrow_agent] += escrow_fee;
    }
    
    //Seller can refund the buyer at any time
    function sellerRefund(uint ID, address _token) public
    {
        address buyerAddress = sellerDatabase[_token][msg.sender][ID].buyer;
        uint buyerID = sellerDatabase[_token][msg.sender][ID].buyer_nounce;

        require(
        buyerDatabase[_token][buyerAddress][buyerID].release_approval == false &&
        buyerDatabase[_token][buyerAddress][buyerID].refund_approval == false); 

        address escrow_agent = buyerDatabase[_token][buyerAddress][buyerID].escrow_agent;
        uint escrow_fee = buyerDatabase[_token][buyerAddress][buyerID].escrow_fee;
        uint amount = buyerDatabase[_token][buyerAddress][buyerID].amount;
    
        //Once approved, buyer can invoke WithdrawFunds to claim his refund
        buyerDatabase[_token][buyerAddress][buyerID].refund_approval = true;

        Funds[_token][buyerAddress] += amount;
        Funds[_token][escrow_agent] += escrow_fee;
    }
    
            //Either buyer or seller can raise escalation with escrow agent. 
        //Once escalation is activated, escrow agent can release funds to seller OR make a full refund to buyer

        //Switcher = 0 for Buyer, Switcher = 1 for Seller
    function EscrowEscalation(uint switcher, uint ID, address _token) public
    {
        //To activate EscrowEscalation
        //1) Buyer must not have approved fund release.
        //2) Seller must not have approved a refund.
        //3) EscrowEscalation is being activated for the first time

        //There is no difference whether the buyer or seller activates EscrowEscalation.
        address buyerAddress;
        uint buyerID; //transaction ID of in buyer&#39;s history
        
        if (switcher == 0) // Buyer
        {
            buyerAddress = msg.sender;
            buyerID = ID;
        } else if (switcher == 1) //Seller
        {
            buyerAddress = sellerDatabase[_token][msg.sender][ID].buyer;
            buyerID = sellerDatabase[_token][msg.sender][ID].buyer_nounce;
        }

        require(buyerDatabase[_token][buyerAddress][buyerID].escrow_intervention == false  &&
        buyerDatabase[_token][buyerAddress][buyerID].release_approval == false &&
        buyerDatabase[_token][buyerAddress][buyerID].refund_approval == false);

        //Activate the ability for Escrow Agent to intervent in this transaction
        buyerDatabase[_token][buyerAddress][buyerID].escrow_intervention = true;

    }
    
        //ID is the transaction ID from Escrow&#39;s history. 
    //Decision = 0 is for refunding Buyer. Decision = 1 is for releasing funds to Seller
    function escrowDecision(uint ID, uint Decision, address _token) public
    {
        //Escrow can only make the decision IF
        //1) Buyer has not yet approved fund release to seller
        //2) Seller has not yet approved a refund to buyer
        //3) Escrow Agent has not yet approved fund release to seller AND not approved refund to buyer
        //4) Escalation Escalation is activated

        address buyerAddress = escrowDatabase[_token][msg.sender][ID].buyer;
        uint buyerID = escrowDatabase[_token][msg.sender][ID].buyer_nounce;
        

        require(
        buyerDatabase[_token][buyerAddress][buyerID].release_approval == false &&
        buyerDatabase[_token][buyerAddress][buyerID].escrow_intervention == true &&
        buyerDatabase[_token][buyerAddress][buyerID].refund_approval == false);
        
        uint escrow_fee = buyerDatabase[_token][buyerAddress][buyerID].escrow_fee;
        uint amount = buyerDatabase[_token][buyerAddress][buyerID].amount;

        if (Decision == 0) //Refund Buyer
        {
            buyerDatabase[_token][buyerAddress][buyerID].refund_approval = true;    
            Funds[_token][buyerAddress] += amount;
            Funds[_token][msg.sender] += escrow_fee;
            
        } else if (Decision == 1) //Release funds to Seller
        {                
            buyerDatabase[_token][buyerAddress][buyerID].release_approval = true;
            Funds[_token][buyerDatabase[_token][buyerAddress][buyerID].seller] += amount;
            Funds[_token][msg.sender] += escrow_fee;
        }  
    }
    
    function WithdrawFunds(address _token) public
    {
        Token token = Token(_token);
        uint amount = Funds[_token][msg.sender];
        Funds[_token][msg.sender] = 0;
        token.transfer(msg.sender, amount);
            
    }

    function CheckBalance(address fromAddress, address _token) public view returns (uint){
        return (Funds[_token][fromAddress]);
    }


}