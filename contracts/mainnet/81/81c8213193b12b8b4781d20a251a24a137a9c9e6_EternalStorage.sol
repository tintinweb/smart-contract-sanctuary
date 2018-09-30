pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract EternalStorage is Ownable {

    struct Storage {
        mapping(uint256 => uint256) _uint;
        mapping(uint256 => address) _address;
    }

    Storage internal s;
    address allowed;

    constructor(uint _rF, address _r, address _f, address _a, address _t)

    public {
        setAddress(0, _a);
        setAddress(1, _r);
        setUint(1, _rF);
        setAddress(2, _f);
        setAddress(3, _t);
    }

    modifier onlyAllowed() {
        require(msg.sender == owner || msg.sender == allowed);
        _;
    }

    function identify(address _address) external onlyOwner {
        allowed = _address;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a
     * newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        Ownable.transferOwnership(newOwner);
    }

    /**
     * @dev Allows the owner to set a value for an unsigned integer variable.
     * @param i Unsigned integer variable key
     * @param v The value to be stored
     */
    function setUint(uint256 i, uint256 v) public onlyOwner {
        s._uint[i] = v;
    }

    /**
     * @dev Allows the owner to set a value for a address variable.
     * @param i Unsigned integer variable key
     * @param v The value to be stored
     */
    function setAddress(uint256 i, address v) public onlyOwner {
        s._address[i] = v;
    }

    /**
     * @dev Get the value stored of a uint variable by the hash name
     * @param i Unsigned integer variable key
     */
    function getUint(uint256 i) external view onlyAllowed returns (uint256) {
        return s._uint[i];
    }

    /**
     * @dev Get the value stored of a address variable by the hash name
     * @param i Unsigned integer variable key
     */
    function getAddress(uint256 i) external view onlyAllowed returns (address) {
        return s._address[i];
    }

    function selfDestruct () external onlyOwner {
        selfdestruct(owner);
    }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
    public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
    public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract Escrow is Ownable {

    enum transactionStatus {
        Default,
        Pending,
        PendingR1,
        PendingR2,
        Completed,
        Canceled}

    struct Transaction {
        transactionStatus status;
        uint baseAmt;
        uint txnAmt;
        uint sellerFee;
        uint buyerFee;
        uint buyerBalance;
        address buyer;
        uint token;
    }

    mapping(address => Transaction) transactions;
    mapping(address => uint) balance;
    ERC20 base;
    ERC20 token;
    EternalStorage eternal;
    uint rF;
    address r;
    address reserve;

    constructor(ERC20 _base, address _s) public {

        base = _base;
        eternal = EternalStorage(_s);

    }

    modifier onlyAllowed() {
        require(msg.sender == owner || msg.sender == eternal.getAddress(0));
        _;
    }

    function createTransaction (

        address _tag,
        uint _baseAmt,
        uint _txnAmt,
        uint _sellerFee,
        uint _buyerFee) external payable {

        Transaction storage transaction = transactions[_tag];
        require(transaction.buyer == 0x0);
        transactions[_tag] =
        Transaction(
            transactionStatus.Pending,
            _baseAmt,
            _txnAmt,
            _sellerFee,
            _buyerFee,
            0,
            msg.sender,
            0);

        uint buyerTotal = _txnAmt + _buyerFee;
        require(transaction.buyerBalance + msg.value == buyerTotal);
        transaction.buyerBalance += msg.value;
        balance[msg.sender] += msg.value;
    }

    function createTokenTransaction (

        address _tag,
        uint _baseAmt,
        uint _txnAmt,
        uint _sellerFee,
        uint _buyerFee,
        address _buyer,
        uint _token) external onlyAllowed {

        require(_token != 0);
        require(eternal.getAddress(_token) != 0x0);
        Transaction storage transaction = transactions[_tag];
        require(transaction.buyer == 0x0);
        transactions[_tag] =
        Transaction(
            transactionStatus.Pending,
            _baseAmt,
            _txnAmt,
            _sellerFee,
            _buyerFee,
            0,
            _buyer,
            _token);

        uint buyerTotal = _txnAmt + _buyerFee;
        token = ERC20(eternal.getAddress(_token));
        token.transferFrom(_buyer, address(this), buyerTotal);
        transaction.buyerBalance += buyerTotal;
    }

    function release(address _tag) external onlyAllowed {
        releaseFunds(_tag);
    }

    function releaseFunds (address _tag) private {
        Transaction storage transaction = transactions[_tag];
        require(transaction.status == transactionStatus.Pending);
        uint buyerTotal = transaction.txnAmt + transaction.buyerFee;
        uint buyerBalance = transaction.buyerBalance;
        transaction.buyerBalance = 0;
        require(buyerTotal == buyerBalance);
        base.transferFrom(_tag, transaction.buyer, transaction.baseAmt);
        uint totalFees = transaction.buyerFee + transaction.sellerFee;
        uint sellerTotal = transaction.txnAmt - transaction.sellerFee;
        transaction.txnAmt = 0;
        transaction.sellerFee = 0;
        if (transaction.token == 0) {
            _tag.transfer(sellerTotal);
            owner.transfer(totalFees);
        } else {
            token = ERC20(eternal.getAddress(transaction.token));
            token.transfer(_tag, sellerTotal);
            token.transfer(owner, totalFees);
        }

        transaction.status = transactionStatus.PendingR1;
        recovery(_tag);
    }

    function recovery(address _tag) private {
        r1(_tag);
        r2(_tag);
    }

    function r1 (address _tag) private {
        Transaction storage transaction = transactions[_tag];
        require(transaction.status == transactionStatus.PendingR1);
        transaction.status = transactionStatus.PendingR2;
        base.transferFrom(reserve, _tag, rF);
    }

    function r2 (address _tag) private {
        Transaction storage transaction = transactions[_tag];
        require(transaction.status == transactionStatus.PendingR2);
        transaction.buyer = 0x0;
        transaction.status = transactionStatus.Completed;
        base.transferFrom(_tag, r, rF);
    }

    function cancel (address _tag) external onlyAllowed {
        Transaction storage transaction = transactions[_tag];
        if (transaction.token == 0) {
            cancelTransaction(_tag);
        } else {
            cancelTokenTransaction(_tag);
        }
    }

    function cancelTransaction (address _tag) private {
        Transaction storage transaction = transactions[_tag];
        require(transaction.status == transactionStatus.Pending);
        uint refund = transaction.buyerBalance;
        transaction.buyerBalance = 0;
        address buyer = transaction.buyer;
        transaction.buyer = 0x0;
        buyer.transfer(refund);
        transaction.status = transactionStatus.Canceled;
    }

    function cancelTokenTransaction (address _tag) private {
        Transaction storage transaction = transactions[_tag];
        require(transaction.status == transactionStatus.Pending);
        token = ERC20(eternal.getAddress(transaction.token));
        uint refund = transaction.buyerBalance;
        transaction.buyerBalance = 0;
        address buyer = transaction.buyer;
        transaction.buyer = 0x0;
        token.transfer(buyer, refund);
        transaction.status = transactionStatus.Canceled;
    }

    function resync () external onlyOwner {
        rF = eternal.getUint(1);
        r = eternal.getAddress(1);
        reserve = eternal.getAddress(2);
    }

    function selfDestruct () external onlyOwner {
        selfdestruct(owner);
    }

    function status (address _tag) external view onlyOwner returns (
        transactionStatus _status,
        uint _baseAmt,
        uint _txnAmt,
        uint _sellerFee,
        uint _buyerFee,
        uint _buyerBalance,
        address _buyer,
        uint _token) {

        Transaction storage transaction = transactions[_tag];
        return (
        transaction.status,
        transaction.baseAmt,
        transaction.txnAmt,
        transaction.sellerFee,
        transaction.buyerFee,
        transaction.buyerBalance,
        transaction.buyer,
        transaction.token
        );
    }

    function getAddress (uint i) external view onlyAllowed returns (address) {
        return eternal.getAddress(i);
    }

    function variables () external view onlyAllowed returns (
        address,
        address,
        address,
        uint) {

        address p = eternal.getAddress(0);
        return (p, r, reserve, rF);
    }

}