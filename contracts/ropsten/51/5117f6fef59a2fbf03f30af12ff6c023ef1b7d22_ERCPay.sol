/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity ^0.5.6;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}





contract ERCPay is Ownable {
    enum TransactionStatus { FundsReceived, FundsReleased, Refunded, AwaitingResolution }
    enum Entity { Customer, Merchant, EscrowAgent }

    event PaymentCreation(address indexed customer, address indexed merchant, address indexed escrowAgent, uint id, uint value);
    event PaymentCompletion(address indexed customer, address indexed merchant, address indexed escrowAgent, uint id, uint value, TransactionStatus status);
    event PaymentDispute(address indexed customer, address indexed merchant, address indexed escrowAgent, uint id, uint value);
    event Withdraw(address indexed user, uint value);

    /**
     * A Transaction requires 3 parties, the customer, merchant and escrowAgent
     * customer - Address making payment
     * merchant - Address receiving payment
     * escrowAgent - Address to resolve transaction disputes, if any. Collects a % fee.
     */
    struct Transaction{
        address customer;
        address merchant;
        address escrowAgent;
        uint value;
        uint escrowFee;
        TransactionStatus status;
        string notes;
    }

    /**
     * All transactions are stored in TransactionLedger
     * All 3 parties have the index of transaction appended to their own ledger.
     */
    Transaction[] public TransactionLedger;

    mapping(address => uint[]) public CustomerLedger;
    mapping(address => uint[]) public MerchantLedger;
    mapping(address => uint[]) public EscrowLedger;

    mapping(address => uint) public EscrowFee;

    mapping(address => uint) public Funds;


    /**
     * @dev Customers creates a new escrow protected transaction.
     * @param _merchant The address receiving payment. Can refund customer
     * @param _escrowAgent The address for dispute resolution. Can refund customer and release funds to merchant
     * @param _notes Optional. Add info to payment
     */
    function createPayment(address _merchant, address _escrowAgent, string memory _notes) payable public {
        require(msg.value > 0);
        require(msg.sender != _merchant);

        uint fee = EscrowFee[_escrowAgent] * msg.value / 1000;

        Transaction memory NewTransaction = Transaction({
            customer: msg.sender,
            merchant: _merchant,
            escrowAgent: _escrowAgent,
            escrowFee: fee,
            value: msg.value - fee,
            status: TransactionStatus.FundsReceived,
            notes: _notes

        });
        TransactionLedger.push(NewTransaction);
        uint id = TransactionLedger.length - 1;
        CustomerLedger[msg.sender].push(id);
        MerchantLedger[_merchant].push(id);
        EscrowLedger[_escrowAgent].push(id);
        
        emit PaymentCreation(msg.sender, _merchant,_escrowAgent, msg.value, id);
    }

    function getCustomerLedgerLength(address user) public view returns (uint){
        return (CustomerLedger[user].length);
    }
    
    function getMerchantLedgerLength(address user) public view returns (uint){
        return (MerchantLedger[user].length);
    }
    
    function getEscrowLedgerLength(address user) public view returns (uint){
        return (EscrowLedger[user].length);
    }
    
    function getTransaction(uint txid) public view returns (address customer, address merchant, address escrow, uint escrowFee, uint value, TransactionStatus status, string memory notes){
        return (
            TransactionLedger[txid].customer,
            TransactionLedger[txid].merchant,
            TransactionLedger[txid].escrowAgent,
            TransactionLedger[txid].escrowFee,
            TransactionLedger[txid].value,
            TransactionLedger[txid].status,
            TransactionLedger[txid].notes
            );
    }

    /**
     * @dev Customer or escrow agent can release funds to merchant.
     * @param id id of transaction
     */
    function releaseFunds(uint id) public {
        Transaction storage t = TransactionLedger[id];
        require(t.customer == msg.sender || t.escrowAgent == msg.sender);
        require(t.status == TransactionStatus.FundsReceived || t.status == TransactionStatus.AwaitingResolution);

        t.status = TransactionStatus.FundsReleased;
        Funds[t.merchant] += t.value;
        Funds[t.escrowAgent] += t.escrowFee;

        emit PaymentCompletion(t.customer, t.merchant, t.escrowAgent, id, t.value, t.status);
    }

    /**
     * @dev Merchant or escrow agent can release funds to merchant.
     * @param id id of transaction
     */
    function refundCustomer(uint id) public {
        Transaction storage t = TransactionLedger[id];
        require(t.merchant == msg.sender || t.escrowAgent == msg.sender);
        require(t.status == TransactionStatus.FundsReceived);

        t.status = TransactionStatus.Refunded;
        Funds[t.customer] += t.value;
        Funds[t.escrowAgent] += t.escrowFee;

        emit PaymentCompletion(t.customer, t.merchant, t.escrowAgent, id, t.value, t.status);
    }

    /**
     * @dev Customer or merchant can raise dispute of transaction
     * @param id id of transaction
     */
    function raiseDispute(uint id) public {
        Transaction storage t = TransactionLedger[id];
        require(t.merchant == msg.sender || t.customer == msg.sender);
        require(t.status == TransactionStatus.FundsReceived || t.status == TransactionStatus.AwaitingResolution);

        t.status = TransactionStatus.AwaitingResolution;
        
        emit PaymentDispute(t.customer, t.merchant, t.escrowAgent, id, t.value);
    }

    /**
     * @dev For users of the platform to withdraw funds attributed to their address
     */
    function withdraw() public {
        uint amount = Funds[msg.sender];
        Funds[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev escrow agents set their fee here
     * @param fee fee/10 is percentage fee escrow agent charges for his service
     */
    function setEscrowFee(uint fee) public {
        require(fee < 50);
        EscrowFee[msg.sender] = fee;
    }

}