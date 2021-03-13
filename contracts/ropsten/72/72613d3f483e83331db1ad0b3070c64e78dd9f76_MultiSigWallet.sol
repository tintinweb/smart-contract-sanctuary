/**
 *Submitted for verification at Etherscan.io on 2021-03-13
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

/**
 * @dev ERC20 Token abstract contract.
 */
contract ERC20Token {

    function decimals() public view returns (uint8);

    function balanceOf(address owner) public view returns (uint);

    function transfer(address to, uint256 value) public returns (bool);
}

contract MultiSigWallet is Ownable{

    mapping (address => uint8) private managers;

    modifier isManager{
        require(managers[msg.sender] == 1);
        _;
    }

    uint constant MIN_SIGNATURES = 2;
    uint private nonce;

    ERC20Token private you;

    struct Transaction {
        address creator;
        address recipient;
        uint amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }

    mapping (uint => Transaction) private transactions;
    uint[] private pendingTransactions;

    constructor(address youToken) public {
        you = ERC20Token(youToken);

        managers[0xfCa8243ADc135E043D73a6F68DEc771F086277F2] = 1;
        managers[0x6A02a11035136FB3Ca55F163ed80Eae2CeE0057F] = 1;
    }

    event DepositFunds(address sender, uint amount);
    event WithdrawFunds(address recipient, uint amount);
    event TransactionCreated(
        address creator,
        address recipient,
        uint amount,
        uint transactionId
    );

    function addManager(address manager) external onlyOwner{
        managers[manager] = 1;
    }

    function removeManager(address manager) external onlyOwner{
        managers[manager] = 0;
    }

    function () external payable{
        emit DepositFunds(msg.sender, msg.value);
    }

    function withdraw(address recipient,uint amount) isManager external returns(uint){
        require(you.balanceOf(address(this)) >= amount);
        uint transactionId = nonce++;

        Transaction memory transaction;
        transaction.creator = msg.sender;
        transaction.recipient = recipient;
        transaction.amount = amount;
        transaction.signatureCount = 0;
        transactions[transactionId] = transaction;
        pendingTransactions.push(transactionId);
        emit TransactionCreated(msg.sender, recipient, amount, transactionId);
        
        return transactionId;
    }

    function withdrawETH(address payable recipient) isManager public{
        require(address(this).balance >= 0);
        recipient.transfer(address(this).balance);
        emit WithdrawFunds(recipient, address(this).balance);
    }

    function getPendingTransactions() public isManager view returns(uint[] memory){
        return pendingTransactions;
    }

    function signTransaction(uint transactionId) external isManager{
        Transaction storage transaction = transactions[transactionId];
        require(transaction.signatures[msg.sender]!=1);
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;

        if(transaction.signatureCount >= MIN_SIGNATURES){
            require(you.balanceOf(address(this)) >= transaction.amount);
            you.transfer(transaction.recipient,transaction.amount);

            emit WithdrawFunds(transaction.recipient, transaction.amount);
            deleteTransactions(transactionId);
        }
    }

    function deleteTransactions(uint transactionId) public isManager{
        uint8 replace = 0;
        for(uint i = 0; i< pendingTransactions.length; i++){
            if(1==replace){
                pendingTransactions[i-1] = pendingTransactions[i];
            }

            if(transactionId == pendingTransactions[i]){
                replace = 1;
            }
        }
        delete pendingTransactions[pendingTransactions.length - 1];
        pendingTransactions.length--;

        delete transactions[transactionId];
    }

    function walletBalance() public isManager view returns(uint){
        return you.balanceOf(address(this));
    }
}