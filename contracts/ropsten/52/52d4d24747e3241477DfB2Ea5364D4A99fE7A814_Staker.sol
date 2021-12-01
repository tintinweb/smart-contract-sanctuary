/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/MultiSigSafe.sol

pragma solidity 0.8.4;

/**  @title A Multi Sig Safe Contract
     @notice Implements a multi signature safe. Users are added to the safe when it is initialized. The number of required signatures is also set at that time.
     In order to send funds from the safe, a user must create a transaction which must by signed by the required number before it is executed. The user that 
     created the trasnaction can't sign it. 
*/
contract MultiSigSafe is Ownable {
    //mapping to determine if an address is an owner aker 1/0
    mapping(address => bool) private safeUsers;
    uint256 private minSigsRequired;
    uint256 private txnIndex;

    enum TxnState { Pending, Completed }
    struct Transaction {
        address from;
        address to;
        uint256 amount;
        uint256 signatureCount;
        TxnState txnState;
        mapping (address => uint8) signatures;
    }

    //mapping txnIndex => transaction
    mapping (uint256 => Transaction) private transactions;

    //list of current transactions
    uint256[] private pendingTransactions;

    modifier validUser() {
        require(msg.sender == owner() || safeUsers[msg.sender], "Must be a valid owner of the multi sig safe");
        _;
    }

    /// @notice An event that is emitted when a user is added to the safe.
    /// @param user The address of the added user.
    event SafeUserAdded(address indexed user);

    /// @notice An event that is emitted when funds are deposited into the safe.
    /// @param from The address of the . 
    /// @param amount The amount deposited.
    /// @param balance The safe's balance
    event DepositFunds(address from, uint256 amount, uint256 balance);

    /// @notice An event that is emitted when a transaction is created. 
    /// @param by The address of the user creating the transaction.
    /// @param to The address of the user who will receive the ETH if the transaction is completed.
    /// @param amount The amount of ETH that will be transfered from the safe to the recepient if the transaction is completed.
    /// @param transactionId The transaction Id.
    event TransactionCreated(address by, address to, uint256 amount, uint256 transactionId);

    /// @notice An event that us emitted when a trasnaction is sigend.
    /// @param by The address of the user who signed the transaction.
    /// @param transactionId The transaction Id.
    event TransactionSigned(address by, uint256 transactionId);

    /// @notice
    /// @param from The address of the user that created the transaction.
    /// @param to The address of the recepient.
    /// @param amount The amount sent to the recepient.
    /// @param transactionId The transaction Id.
    event TransactionCompleted(address from, address to, uint256 amount, uint256 transactionId);

    /** @notice Creates an instance of the multi sig safe. Assigns the users to the safe and sets the number of signatures required to complete a trasnaction. 
        The constructor is payable so ETH can be sent to fund the safe.
        @param _safeUsers A list of user addresses to be added to the safe. Those will be considered the ownders of the safe.
        @param _sigsRequired The number of signatures required to complete a trasnaction.
    */
    constructor(address[] memory _safeUsers, uint _sigsRequired) payable {
        require(_sigsRequired > 0, "Number of signatures required must be > 0");
        require(_sigsRequired <= _safeUsers.length, "Number of signatures required must be less than or equal to the number of owners");
        minSigsRequired = _sigsRequired;
        for (uint i = 0; i < _safeUsers.length; i++) {
            address _newUser = _safeUsers[i];
            require(_newUser != address(0), "constructor - Zero address can not be a staker");
            require(!safeUsers[_newUser], "constructor - is already a staker");
            safeUsers[_newUser] = true;
            emit SafeUserAdded(_newUser);
        }
        emit DepositFunds(msg.sender, msg.value, address(this).balance);
    }

    /// @notice Returns the number of signatures required to complete a transaction. 
    function getNumberOfSigsRequired() validUser public view returns (uint256) {
        return minSigsRequired;
    }

    /// @notice Returns a list pending transaction Id's
    function getPendingTransactions() validUser public view returns (uint256[] memory) {
        return pendingTransactions;
    }

    /// @notice Receives ETH
    receive() payable external {
        emit DepositFunds(msg.sender, msg.value, address(this).balance);
    }

    /// @notice Creates a trasanction and populates its fields. The transaction will need to be signed by the required number of signatures for it to be completed.
    /// @param to The address of the recepient.
    /// @param amount The amoount of ETH to be sent to the recepient.
    function transferTo(address payable to, uint amount) validUser public {
        //make sure the balance is >= the amount of the transaction
        require(address(this).balance >= amount, "Not enough balance in the safe");
        uint txnId = txnIndex;
        Transaction storage transaction = transactions[txnId];
        txnIndex++;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.signatureCount = 0;
        transaction.txnState = TxnState.Pending;
        
        pendingTransactions.push(txnId);
        emit TransactionCreated(msg.sender, to, amount, txnId);
    }

    /// @notice Signs a trasanction. If the number of required signatures is reached, the trasanction is executed and marked as complete.
    /// @param txnId The Id of the transaction to be signed.
    function signTransaction(uint txnId) validUser public {
        Transaction storage txn = transactions[txnId];
        require(address(0) != txn.from, "Transaction does not exit");
        require(msg.sender != txn.from, "Transaction creator can not sign it");
        require(txn.signatures[msg.sender] != 1, "Transaction already signed");
        require(txn.txnState != TxnState.Completed, "Transaction already completed");
        txn.signatures[msg.sender] = 1;
        txn.signatureCount++;
        emit TransactionSigned(msg.sender, txnId);

        //if the transaction has a signature count >= the minimum signatures we can process the transaction
        //then we need to validate the transaction
        if (txn.signatureCount >= minSigsRequired) {
            //check balance
            require(address(this).balance >= txn.amount, "Not enough balance in the safe");
            txn.txnState = TxnState.Completed;
            (bool success, bytes memory result) = txn.to.call{value: txn.amount}("");
            require(success, "signTransaction: tx failed");
            //emit an event
            emit TransactionCompleted(txn.from, txn.to, txn.amount, txnId);
        }
    }
}


// File contracts/Staker.sol

pragma solidity 0.8.4;

/** @title A Staking Contract
    @notice This contract allows a group of users to stake ETH within a specific period of time. If a predetermined threshold amount
    is reached, the contract will be executed and the staked balace will be transfered to a multi sig safe. If the threshold amount 
    is not reached, the users can withdrw the ETH they staked.
*/
contract Staker {
    /// @notice The instance of the multi sig safe. It will be initialized if the staking threshold amount is reached.
    MultiSigSafe public multiSigSafe;
    /// @notice A mapping of the user's address to the balance of ETH they staked.
    mapping ( address => uint256 ) public balances;
    
    address[] private stakersList;
    
    /// @notice The deadline to reach the staking ETH threshold. The execute method can't be called before the deadline passes.
    uint256 public deadline;
    
    /// @notice A flag that is set to true if the deadline passes and the staking threshold is not reached. 
    bool public openForWithdraw;
    
    /// @notice The staking threshold amount
     uint256 public threshold;
    
    /// @notice A flag that is set to true when the execute method is called. It is used to preven calling the execute mehtod more that one time.
    bool public stakingCompleted;
    
    /// @notice A falg that is set to true after the mutli sig safe is initialized. 
    bool public multiSigSafeInit;

    /// @notice An event that is emitted every time a user stakes ETH.
    /// @param _stakeAddress The address of the staking user
    /// @param _stakeAmount The amount staked byt the user
    event Stake(address _stakeAddress, uint256 _stakeAmount);

    /// @notice An event that is emitted when the multi sig safe is instantiated.
    /// @param _multiSigSafeAddress The address of the multi sig safe contract.
    event MultiSigSafeCreated(address _multiSigSafeAddress);

    modifier deadlinePassed() {
        require(block.timestamp >= deadline, 'Deadline has not passed yet');
        _;
    }

    modifier notCompleted() {
        require(stakingCompleted == false, 'Contract completed');
        _;
    }

    /** @notice The contract's constructor.
        @param _threshold The amount of ETH that needs to be staked to execute the contract. The amount must be passed in WEI.
        @param _duration How long will the staking be open. Must be passed in seconds.
    */
    constructor(uint256 _threshold, uint256 _duration) {
        require(_threshold > 0, "Threshold value must be greater than zero");
        require(_duration > 0, "Duration value must be greater than zero");
        threshold = _threshold;
        deadline = block.timestamp + _duration;
    }
    
    /// @notice Stake ETH. The amount staked will be added to the user's balance. Also, the user will be added to the stakers list. This method 
    /// can be called as long as the execute has not been called yet.
    function stake() public payable notCompleted {
        if (balances[msg.sender] == 0) {
            stakersList.push(msg.sender);
        }
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    /// @notice Execute the staking contract. If the deadline has passed, check the balance. If it is greater than or equal to the threshold, it will 
    /// instantiate the multi sig safe. Otherwise, it will allow the users to withdraw the ETH they staked. This method can only be called once.
    function execute() public deadlinePassed notCompleted {
        stakingCompleted = true;
        if (address(this).balance >= threshold) {
            multiSigSafe = (new MultiSigSafe){value : address(this).balance}(stakersList, stakersList.length > 1 ? stakersList.length - 1 : 1);
            multiSigSafeInit = true;
            emit MultiSigSafeCreated(address(multiSigSafe));
        } else {
            openForWithdraw = true;
        }
    }

    /// @notice The user can withdraw the amount they staked if the threshold amount was not reached before the deadline.
    /// @param payToAddress The address to send the withdrawn funds to. It must match the address of the staker.
    function withdraw(address payToAddress) public deadlinePassed {
        require(msg.sender == payToAddress, 'Not allowed to withdraw balance that does not belong to you');
        require(openForWithdraw, 'Not allowed to withdraw funds.');
        uint256 theBalance = balances[payToAddress];
        require(theBalance > 0, 'The balance is zero, nothing to withdraw');
        balances[payToAddress] = 0;
        (bool sent, ) = payToAddress.call{value: theBalance}("");
        require(sent, "Failed to send balance to the withdrawal address");
    }

    /// @notice Return the amount of time left beofre the deadline is reached.
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
}