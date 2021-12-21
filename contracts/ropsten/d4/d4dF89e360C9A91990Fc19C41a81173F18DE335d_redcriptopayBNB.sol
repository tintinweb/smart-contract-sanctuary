pragma solidity ^0.8.4;

//redcriptopay

import "./Ownable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract redcriptopayBNB is Ownable, ReentrancyGuard {

    enum TransactionStatus { FundsReceived, FundsReleased, Refunded, AwaitingResolution }

    event DepositCreation(address indexed Sender, address indexed Receiver, uint indexed id, uint amount, uint value);
    event DepositCompleted(address indexed Sender, address indexed Receiver, uint indexed id, uint value, TransactionStatus status);
    event Dispute(address indexed Sender, address indexed Receiver, uint indexed id, uint value);
    
    address public Judge;
    
    constructor () {
     Judge = msg.sender;   
    }
    
    struct Transaction{
        address Sender;
        address Receiver;
        uint amount;
        uint judgeFee;
        uint ownerFee;
        uint value;
        TransactionStatus status;
        
    }
    
    Transaction[] public TransactionLedger;

    mapping(address => uint[]) public SenderLedger;
    mapping(address => uint[]) public ReceiverLedger;
    
    modifier onlyEOA() {
    require(tx.origin == msg.sender, "Contracts can not call this function");
    _;
    }
    
    function setJudge(address _judge) external onlyOwner {
        Judge = _judge;
    }
    
    function createDeposit(address _receiver) payable external onlyEOA {
        require(msg.value > 0, 'amount has to be > 0');
        require(msg.sender != _receiver, " receiver and sender can not be the same.");
        
        uint judgeFee = (msg.value * 10) / 1000;
        uint ownerFee = (msg.value * 10) / 500;
        uint value = msg.value - ownerFee - judgeFee;
        
        Transaction memory NewTransaction = Transaction({
            Sender: msg.sender, 
            Receiver: _receiver,
            amount: msg.value,
            judgeFee: judgeFee,
            ownerFee: ownerFee,
            value: msg.value - ownerFee - judgeFee,
            status: TransactionStatus.FundsReceived
        });
        
        TransactionLedger.push(NewTransaction);
        uint id = TransactionLedger.length -1;
        SenderLedger[msg.sender].push(id);
        ReceiverLedger[_receiver].push(id);
        
         emit DepositCreation(msg.sender, _receiver, id, msg.value, value);
    }

     function getSenderLedgerLength(address user) public view returns (uint){
        return (SenderLedger[user].length);
    }
    
    function getReceiverLedgerLength(address user) public view returns (uint){
        return (ReceiverLedger[user].length);
    }
    
    function releaseFunds(uint id) external nonReentrant onlyEOA {
        Transaction storage t = TransactionLedger[id];
        require(t.Sender == msg.sender || Judge == msg.sender, "only sender or judge can call this function.");
        require(t.status == TransactionStatus.FundsReceived || t.status == TransactionStatus.AwaitingResolution);
        
        t.status = TransactionStatus.FundsReleased;
       
        payable(t.Receiver).transfer(t.value);
        payable(Judge).transfer(t.judgeFee);
        payable(owner).transfer(t.ownerFee);
        
        emit DepositCompleted(t.Sender, t.Receiver, id, t.value, t.status);
    }

    function refundSender(uint id) external nonReentrant onlyEOA{
        Transaction storage t = TransactionLedger[id];
        require(t.Receiver == msg.sender || Judge == msg.sender, "only receiver or judge can call this function.");
        require(t.status == TransactionStatus.FundsReceived || t.status == TransactionStatus.AwaitingResolution);

        t.status = TransactionStatus.Refunded;
        
        payable(t.Sender).transfer(t.value);
        payable(Judge).transfer(t.judgeFee);
        payable(owner).transfer(t.ownerFee);
        
        emit DepositCompleted(t.Sender, t.Receiver, id, t.value, t.status);
    }

    function raiseDispute(uint id) external onlyEOA {
        Transaction storage t = TransactionLedger[id];
        require(t.Sender == msg.sender || t.Receiver == msg.sender, "Only sender or Receiver can call this function.");
        require(t.status == TransactionStatus.FundsReceived, "only FundsReceived status is allowed to call this function");

        t.status = TransactionStatus.AwaitingResolution;
        
        emit Dispute(t.Sender, t.Receiver, id, t.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}