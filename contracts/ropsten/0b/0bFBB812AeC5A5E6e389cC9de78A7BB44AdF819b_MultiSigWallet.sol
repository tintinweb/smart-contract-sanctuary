pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/RVMultiSigWallet.sol

/**
 * @title MultiSigWallet
 * @dev Multisignature wallet - Allows multiple parties to agree on withdrawTransactions before execution.,
 */

contract MultiSigWallet is Ownable {
    using SafeMath for uint256;

    mapping (uint => WithdrawTransaction) public withdrawTransactions;
    mapping (uint => StackholderTransaction) public stakeholderTransactions;
    mapping (uint => mapping (address => bool)) public withdrawConfirmations;
    mapping (uint => mapping (address => bool)) public stakeholderConfirmations;
    mapping (address => bool) public isStackholder;
    address[] public stakeholders;
    uint public requiredConfirmationNumber;
    uint public withdrawTransactionCount;
    uint public stakeholderTransactionCount;
    bool public autoLock;
    bool public isLock = false;
    
    struct WithdrawTransaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    struct StackholderTransaction {
        address stakeholder;
        bool isAdd;
        bool executed;
    }

    event WithdrawConfirmation(address indexed sender, uint indexed transactionId);
    event WithdrawRevocation(address indexed sender, uint indexed transactionId);
    event WithdrawSubmission(uint indexed transactionId);
    event WithdrawExecution(uint indexed transactionId);
    event WithdrawExecutionFailure(uint indexed transactionId);
    event WithdrawDeposit(address indexed sender, uint value);
    event StackholderAddition(address indexed stakeholder);
    event StackholderRemoval(address indexed stakeholder);
    event RequirementChange(uint requiredWithdrawConfirmationNumber);
    event StackholderConfirmation(address indexed sender, uint indexed transactionId);
    event StackholderRevocation(address indexed sender, uint indexed transactionId);
    event StackholderSubmission(uint indexed transactionId);
    event StackholderExecution(uint indexed transactionId);

    modifier isUnlock() {
      require(!isLock);
      _;
    }

    modifier notStackholder(address stakeholder) {
      require(!isStackholder[stakeholder]);
      _;
    }

    modifier existStackholder(address stakeholder) {
      require(isStackholder[stakeholder], "Not stakeholder.");
      _;
    }

    modifier transactionWithdrawExists(uint transactionId) {
      require(withdrawTransactions[transactionId].destination != 0, "No exists transactionId");
      _;
    }

    modifier transactionStackholderExists(uint transactionId) {
      require(stakeholderTransactions[transactionId].stakeholder != 0);
      _;
    }

    modifier confirmedWithdraw(uint transactionId, address stakeholder) {
      require(withdrawConfirmations[transactionId][stakeholder]);
      _;
    }

    modifier confirmedStackholder(uint transactionId, address stakeholder) {
      require(stakeholderConfirmations[transactionId][stakeholder]);
      _;
    }

    modifier notConfirmedWithdraw(uint transactionId, address stakeholder) {
      require(!withdrawConfirmations[transactionId][stakeholder], "Stackholder is already confirmed.");
      _;
    }

    modifier notConfirmedStackholder(uint transactionId, address stakeholder) {
      require(!stakeholderConfirmations[transactionId][stakeholder]);
      _;
    }

    modifier notExecutedWithdraw(uint transactionId) {
      require(!withdrawTransactions[transactionId].executed);
      _;
    }

    modifier notExecutedStackholder(uint transactionId) {
      require(!stakeholderTransactions[transactionId].executed);
      _;
    }

    modifier notNull(address _address) {
      require(_address != 0);
      _;
    }

    modifier validRequirement(uint stakeholderCount, uint _requiredConfirmationNumber) {
      require(_requiredConfirmationNumber <= stakeholderCount && _requiredConfirmationNumber >= ((uint(stakeholderCount)/2)+1) && stakeholderCount > 0);
      _;
    }

    function()
        public
        payable
    {
        if (msg.value > 0) {
          if (autoLock) {
            isLock = true;
          }

          emit WithdrawDeposit(msg.sender, msg.value);
        }
    }

    /**
    * @dev Contract constructor sets initial stakeholders and requiredConfirmationNumber number of withdrawConfirmations.
    * @param _stakeholders List of initial stakeholders.
    * @param _requiredConfirmationNumber Number of requiredConfirmationNumber withdrawConfirmations.
    */
    constructor(address[] _stakeholders, uint _requiredConfirmationNumber, bool _autoLock)
        public
        validRequirement(_stakeholders.length, _requiredConfirmationNumber)
    {
        for (uint i=0; i<_stakeholders.length; i++) {
            require(!isStackholder[_stakeholders[i]] && _stakeholders[i] != 0);
                
            isStackholder[_stakeholders[i]] = true;
        }
        stakeholders = _stakeholders;
        requiredConfirmationNumber = _requiredConfirmationNumber;
        autoLock = _autoLock;
    }

    /**
    * @dev Allows to add a new stakeholder. WithdrawTransaction has to be sent by wallet.
    * @param stakeholder Address of new stakeholder.
    */
    function addStackholder(address stakeholder)
        public
        onlyOwner
        notStackholder(stakeholder)
        notNull(stakeholder)
        validRequirement(stakeholders.length + 1, requiredConfirmationNumber)
    {
        if (isLock) {
          submitStackholderTransaction(stakeholder, true);
        } else {
          _addStackholder(stakeholder);
        }
    }

    function _addStackholder(address _stakeholder) private {
        isStackholder[_stakeholder] = true;
        stakeholders.push(_stakeholder);
        emit StackholderAddition(_stakeholder);
    }

    /**
    * @dev Allows to remove an stakeholder. WithdrawTransaction has to be sent by wallet.
    * @param _stakeholder Address of new stakeholder.
    */
    function removeStackholder(address _stakeholder)
        public
        onlyOwner
        existStackholder(_stakeholder)
    {
        if (isLock) {

        } else {
          _removeStackholder(_stakeholder);
        }
    }

    function _removeStackholder(address _stakeholder) private {
      isStackholder[_stakeholder] = false;
      for (uint i=0; i<stakeholders.length - 1; i++)
          if (stakeholders[i] == _stakeholder) {
              stakeholders[i] = stakeholders[stakeholders.length - 1];
              break;
          }
      stakeholders.length = stakeholders.length.sub(1);
      if (requiredConfirmationNumber > stakeholders.length) {
        changeRequirement(stakeholders.length);
      }
          
      emit StackholderRemoval(_stakeholder);
    }

    /**
    * @dev Allows to change the number of requiredConfirmationNumber withdrawConfirmations. WithdrawTransaction has to be sent by wallet.
    * @param _requiredConfirmationNumber Number of requiredConfirmationNumber withdrawConfirmations.
    */
    function changeRequirement(uint _requiredConfirmationNumber)
        public
        onlyOwner
        validRequirement(stakeholders.length, _requiredConfirmationNumber)
    {
        requiredConfirmationNumber = _requiredConfirmationNumber;
        emit RequirementChange(_requiredConfirmationNumber);
    }

    /**
    * @dev Allows an stakeholder to submit and confirm a transaction.
    * @param destination WithdrawTransaction target address.
    * @param value WithdrawTransaction ether value.
    * @param data WithdrawTransaction data payload.
    * @return Returns transaction ID.
    */
    function submitWithdrawTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addWithdrawTransaction(destination, value, data);
        confirmWithdrawTransaction(transactionId);
    }

    function submitStackholderTransaction(address _stakeholder, bool _isAdd)
        public
        returns (uint transactionId)
    {
        transactionId = addStackholderTransaction(_stakeholder, _isAdd);
        confirmStackholderTransaction(transactionId);
    }

    /**
    * @dev Allows an stakeholder to confirm a transaction.
    * @param _transactionId WithdrawTransaction ID.
    */
    function confirmWithdrawTransaction(uint _transactionId)
        public
        existStackholder(msg.sender)
        transactionWithdrawExists(_transactionId)
        notConfirmedWithdraw(_transactionId, msg.sender)
    {
        withdrawConfirmations[_transactionId][msg.sender] = true;
        emit WithdrawConfirmation(msg.sender, _transactionId);
        executeWithdrawTransaction(_transactionId);
    }

    function confirmStackholderTransaction(uint _transactionId)
        public
        existStackholder(msg.sender)
        transactionWithdrawExists(_transactionId)
        notConfirmedWithdraw(_transactionId, msg.sender)
    {
        stakeholderConfirmations[_transactionId][msg.sender] = true;
        emit StackholderConfirmation(msg.sender, _transactionId);
        executeStackholderTransaction(_transactionId);
    }

    /**
    * @dev Allows an stakeholder to revoke a confirmation for a transaction.
    * @param _transactionId WithdrawTransaction ID.
    */
    function revokeWithdrawConfirmation(uint _transactionId)
        public
        existStackholder(msg.sender)
        confirmedWithdraw(_transactionId, msg.sender)
        notExecutedWithdraw(_transactionId)
    {
        withdrawConfirmations[_transactionId][msg.sender] = false;
        emit WithdrawRevocation(msg.sender, _transactionId);
    }

    function revokeStackholderConfirmation(uint _transactionId)
        public
        existStackholder(msg.sender)
        confirmedStackholder(_transactionId, msg.sender)
        notExecutedStackholder(_transactionId)
    {
        stakeholderConfirmations[_transactionId][msg.sender] = false;
        emit StackholderRevocation(msg.sender, _transactionId);
    }

    /**
    * @dev Allows anyone to execute a confirmed transaction.
    * @param _transactionId WithdrawTransaction ID.
    */
    function executeWithdrawTransaction(uint _transactionId)
        public
        notExecutedWithdraw(_transactionId)
    {
        if (isConfirmedWithdraw(_transactionId)) {
            WithdrawTransaction tx = withdrawTransactions[_transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data)) {
              emit WithdrawExecution(_transactionId);
            } else {
                emit WithdrawExecutionFailure(_transactionId);
                tx.executed = false;
            }
        }
    }

    function executeStackholderTransaction(uint _transactionId)
        public
        notExecutedStackholder(_transactionId)
    {
        if (isConfirmedStackholder(_transactionId)) {
            StackholderTransaction tx = stakeholderTransactions[_transactionId];
            tx.executed = true;

            if (tx.isAdd) {
              _addStackholder(tx.stakeholder);
            } else {
              _removeStackholder(tx.stakeholder);
            }

            emit StackholderExecution(_transactionId);
        }
    }

    /**
    * @dev Returns the confirmation status of a transaction.
    * @param _transactionId WithdrawTransaction ID.
    * @return Confirmation status.
    */
    function isConfirmedWithdraw(uint _transactionId)
        public
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<stakeholders.length; i++) {
            if (withdrawConfirmations[_transactionId][stakeholders[i]]) {
              count = count.add(1);
            }
                
            if (count == requiredConfirmationNumber) {
              return true;
            }
        }
    }

    function isConfirmedStackholder(uint _transactionId)
        public
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<stakeholders.length; i++) {
            if (stakeholderConfirmations[_transactionId][stakeholders[i]]) {
              count = count.add(1);
            }
                
            if (count == requiredConfirmationNumber) {
              return true;
            }
        }
    }

    /**
    * @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    * @param destination WithdrawTransaction target address.
    * @param value WithdrawTransaction ether value.
    * @param data WithdrawTransaction data payload.
    * @return Returns transaction ID.
    */
    function addWithdrawTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = withdrawTransactionCount;
        withdrawTransactions[transactionId] = WithdrawTransaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        withdrawTransactionCount = withdrawTransactionCount.add(1);
        emit WithdrawSubmission(transactionId);
    }

    function addStackholderTransaction(address _stakeholder, bool _isAdd)
        internal
        notNull(_stakeholder)
        returns (uint transactionId)
    {
        transactionId = stakeholderTransactionCount;
        stakeholderTransactions[transactionId] = StackholderTransaction({
            stakeholder: _stakeholder,
            isAdd: _isAdd,
            executed: false
        });
        stakeholderTransactionCount = stakeholderTransactionCount.add(1);
        emit StackholderSubmission(transactionId);
    }

    /**
    * @dev Returns number of withdrawConfirmations of a transaction.
    * @param _transactionId WithdrawTransaction ID.
    * @return Number of withdrawConfirmations.
    */
    function getWithdrawConfirmationCount(uint _transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<stakeholders.length; i++) {
          if (withdrawConfirmations[_transactionId][stakeholders[i]]) {
            count = count.add(1);
          }
        }
    }

    function getStackholderConfirmationCount(uint _transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<stakeholders.length; i++) {
          if (stakeholderConfirmations[_transactionId][stakeholders[i]]) {
            count = count.add(1);
          }
        }
    }

    /**
    * @dev Returns total number of withdrawTransactions after filers are applied.
    * @param pending Include pending withdrawTransactions.
    * @param executed Include executed withdrawTransactions.
    * @return Total number of withdrawTransactions after filters are applied.
    */
    function getWithdrawTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<withdrawTransactionCount; i++) {
          if (pending && !withdrawTransactions[i].executed || executed && withdrawTransactions[i].executed) {
              count = count.add(1);
          }
                 
        }
    }

    function getStackholderTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<stakeholderTransactionCount; i++) {
          if (pending && !stakeholderTransactions[i].executed || executed && stakeholderTransactions[i].executed) {
              count = count.add(1);
          }
                 
        }
    }

    /**
    * @dev Returns list of stakeholders.
    * @return List of stakeholder addresses.
    */
    function getStackholders()
        public
        view
        returns (address[])
    {
        return stakeholders;
    }

    /**
    * @dev Returns array with stakeholder addresses, which confirmed transaction.
    * @param transactionId WithdrawTransaction ID.
    * @return Returns array of stakeholder addresses.
    */
    function getWithdrawConfirmations(uint transactionId)
        public
        view
        returns (address[] _withdrawConfirmations)
    {
        address[] memory withdrawConfirmationsTemp = new address[](stakeholders.length);
        uint count = 0;
        uint i;
        for (i=0; i<stakeholders.length; i++) {
          if (withdrawConfirmations[transactionId][stakeholders[i]]) {
              withdrawConfirmationsTemp[count] = stakeholders[i];
              count = count.add(1);
          }
        }
            
        _withdrawConfirmations = new address[](count);
        for (i=0; i<count; i++) {
          _withdrawConfirmations[i] = withdrawConfirmationsTemp[i];
        }
            
    }

    function getStackholderConfirmations(uint transactionId)
        public
        view
        returns (address[] _stakeholderConfirmations)
    {
        address[] memory stakeholderConfirmationsTemp = new address[](stakeholders.length);
        uint count = 0;
        uint i;
        for (i=0; i<stakeholders.length; i++) {
          if (stakeholderConfirmations[transactionId][stakeholders[i]]) {
              stakeholderConfirmationsTemp[count] = stakeholders[i];
              count = count.add(1);
          }
        }
            
        _stakeholderConfirmations = new address[](count);
        for (i=0; i<count; i++) {
          _stakeholderConfirmations[i] = stakeholderConfirmationsTemp[i];
        }
            
    }

    /**
    * @dev Returns list of transaction IDs in defined range.
    * @param from Index start position of transaction array.
    * @param to Index end position of transaction array.
    * @param pending Include pending withdrawTransactions.
    * @param executed Include executed withdrawTransactions.
    * @return Returns array of transaction IDs.
    */
    function getWithdrawTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        view
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](withdrawTransactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<withdrawTransactionCount; i++) {
          if (   pending && !withdrawTransactions[i].executed
                || executed && withdrawTransactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                 count = count.add(1);
            }
        }
            
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++) {
          _transactionIds[i - from] = transactionIdsTemp[i];
        }
            
    }
}