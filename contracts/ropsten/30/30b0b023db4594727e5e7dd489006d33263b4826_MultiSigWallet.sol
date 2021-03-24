/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity = 0.5.16;

contract Ownable {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "YouSwap: CALLER_IS_NOT_THE_OWNER");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "YouSwap: NEW_OWNER_IS_THE_ZERO_ADDRESS");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MultiSigWallet is Ownable{

    mapping (address => uint8) private _managers;
    mapping (address => uint8) private _cashiers;

    modifier isManager{
        require(_managers[msg.sender] == 1);
        _;
    }
    
    modifier isCashier{
        require(_cashiers[msg.sender] == 1 || _managers[msg.sender] == 1);
        _;
    }

    uint constant MIN_SIGNATURES = 2;
    uint private _nonce;

    address private _youToken;

    struct Transaction {
        uint8 state;
        address creator;
        address recipient;
        uint amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }

    mapping (uint => Transaction) private _pendingTransactions;
    uint[] private _pendingTxIDs;

    constructor() public {
        _youToken = 0x941BF24605b3cb640717eEb19Df707954CE85ebe;

        _managers[0x9Eb6040Ba1656e5fD5763B8f4E6CD9Af538B6bE6] = 1;
        _managers[0x80b10F9b9D67FD8CCA73624c1da1e3F8BD14970f] = 1;
        _managers[0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F] = 1;
        
        _cashiers[0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F] = 1;
        _cashiers[0xfCa8243ADc135E043D73a6F68DEc771F086277F2] = 1;
    }

    event WithdrawFunds(address recipient, uint amount);
    event TransactionCreated(
        address creator,
        address recipient,
        uint amount,
        uint transactionId
    );

    function addManager(address manager) external onlyOwner{
        _managers[manager] = 1;
    }

    function removeManager(address manager) external onlyOwner{
        _managers[manager] = 0;
    }
    
    function manager(address account) external view returns (bool) {
        return _managers[account] == 1;
    }
    
    function addCashier(address cashier) external isManager{
        _cashiers[cashier] = 1;
    }

    function removeCashier(address cashier) external isManager{
        _cashiers[cashier] = 0;
    }
    
    function cashier(address account) external view returns (bool) {
        return _cashiers[account] == 1;
    }

    function withdraw(address recipient,uint amount) isCashier external returns(uint){
        uint transactionId = ++_nonce;

        Transaction storage transaction = _pendingTransactions[transactionId];
        transaction.state = 1;
        transaction.creator = msg.sender;
        transaction.recipient = recipient;
        transaction.amount = amount;
        transaction.signatureCount = 0;
        if(_managers[msg.sender] == 1)
        {
            transaction.signatureCount = 1;
        }
        
        _pendingTxIDs.push(transactionId);
        emit TransactionCreated(msg.sender, recipient, amount, transactionId);
        
        return transactionId;
    }

    function getPendingTxIDs() public view returns(uint[] memory){
        return _pendingTxIDs;
    }

    function getPendingTransaction(uint transactionId) external view returns
    (
        address creator,
        address recipient,
        uint256 amount,
        uint8 signatureCount
    ){
        require(_pendingTransactions[transactionId].state == 1, 'YouSwap:NOT_EXIST');

        return (
        _pendingTransactions[transactionId].creator,
        _pendingTransactions[transactionId].recipient,
        _pendingTransactions[transactionId].amount,
        _pendingTransactions[transactionId].signatureCount
        );
    }

    function signTransaction(uint transactionId) external isManager{
        require(_pendingTransactions[transactionId].state == 1, 'YouSwap:NOT_EXIST');
        Transaction storage transaction = _pendingTransactions[transactionId];
        require(transaction.signatures[msg.sender]!=1,"YouSwap: SIGNED_ALREADY");
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;

        if(transaction.signatureCount >= MIN_SIGNATURES){
           _transfer(_youToken,transaction.recipient,transaction.amount);
            emit WithdrawFunds(transaction.recipient, transaction.amount);
            deleteTransaction(transactionId);
        }
    }

    function deleteTransaction(uint transactionId) public isCashier{
        require(_pendingTransactions[transactionId].state == 1, 'YouSwap:NOT_EXIST');
        _pendingTransactions[transactionId].state = 0;
        uint8 replace = 0;
        for(uint i = 0; i< _pendingTxIDs.length; i++){
            if(1==replace){
                _pendingTxIDs[i-1] = _pendingTxIDs[i];
            }

            if(transactionId == _pendingTxIDs[i]){
                replace = 1;
            }
        }
        delete _pendingTxIDs[_pendingTxIDs.length - 1];
        _pendingTxIDs.length--;

        delete _pendingTransactions[transactionId];
        
        _nonce--;
    }

    function _transfer(address token, address recipient, uint amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }
}