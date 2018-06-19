pragma solidity 0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract iERC223Token {
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transferFrom(address from, address to, uint value, bytes data) public returns (bool ok);
}

contract ERC223Receiver {
    function tokenFallback( address _origin, uint _value, bytes _data) public returns (bool ok);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract iERC20Token {
    uint256 public totalSupply = 0;
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeERC20 {
  function safeTransfer(StandardToken token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(StandardToken token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(StandardToken token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract StandardToken is iERC20Token {

    using SafeMath for uint256;
    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    function transfer(address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

   /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


contract FreezableToken is iERC223Token, StandardToken, Ownable {

    event ContractTransfer(address indexed _from, address indexed _to, uint _value, bytes _data);

    bool public freezed;

    modifier canTransfer(address _transferer) {
        require(owner == _transferer || !freezed);
        _;
    }

    function FreezableToken() public {
        freezed = true;
    }

    function transfer(address _to, uint _value, bytes _data) canTransfer(msg.sender)
        public
        canTransfer(msg.sender)
        returns (bool success) {
        //filtering if the target is a contract with bytecode inside it
        require(super.transfer(_to, _value)); // do a normal token transfer
        if (isContract(_to)) {
            require(contractFallback(msg.sender, _to, _value, _data));
        }
        return true;
    }

    function transferFrom(address _from, address _to, uint _value, bytes _data) public canTransfer(msg.sender) returns (bool success) {
        require(super.transferFrom(_from, _to, _value)); // do a normal token transfer
        if (isContract(_to)) {
            require(contractFallback(_from, _to, _value, _data));
        }
        return true;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender) public canTransfer(msg.sender) returns (bool success) {
        return transfer(_to, _value, new bytes(0));
    }

    function transferFrom(address _from, address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
        return transferFrom(_from, _to, _value, new bytes(0));
    }

    //function that is called when transaction target is a contract
    function contractFallback(address _origin, address _to, uint _value, bytes _data) private returns (bool) {
        ContractTransfer(_origin, _to, _value, _data);
        ERC223Receiver reciever = ERC223Receiver(_to);
        require(reciever.tokenFallback(_origin, _value, _data));
        return true;
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }

    function unfreeze() public onlyOwner returns (bool){
        freezed = false;
        return true;
    }
}

contract SimpleMultisigWallet is ERC223Receiver {


    // Max size of owners that can be added to wallet
    uint constant private MAX_OWNER_COUNT = 5;

    /**
      * event for transaction confirmation logging
      * @param sender who confirmed transaction
      * @param transactionId transaction identifier
      * @param createdOn time of log
      */
    event Confirmation(address sender, uint transactionId, uint256 createdOn);

    /**
      * event for transaction revocation logging
      * @param sender who confirmed transaction
      * @param transactionId transaction identifier
      * @param createdOn time of log
      */
    event Revocation(address sender, uint transactionId, uint256 createdOn);

    /**
      * event for transaction submission logging
      * @param transactionId transaction identifier
      * @param token token contract address if transaction submits tokens
      * @param transactionType type of transaction showing if tokens or ether is submited
      * @param createdOn time of log
      */
    event Submission(uint indexed transactionId, address indexed token, address indexed newOwner, TransactionType transactionType, uint256 createdOn);

    /**
      * event for transaction execution logging
      * @param transactionId transaction identifier
      * @param createdOn time of log
      */
    event Execution(uint indexed transactionId, uint256 createdOn);

    /**
      * event for deposit logging
      * @param sender account who send ether
      * @param value amount of wei which was sent
      * @param createdOn time of log
      */
    event Deposit(address indexed sender, uint value, uint256 createdOn);

    /**
      * event for owner addition logging
      * @param owner new added wallet owner
      * @param createdOn time of log
      */
    event OwnerAddition(address indexed owner, uint256 createdOn);

    /**
      * event for owner removal logging
      * @param owner wallet owner who was removed from wallet
      * @param createdOn time of log
      */
    event OwnerRemoval(address indexed owner, uint256 createdOn);

    /**
      * event for needed confirmation requirement change logging
      * @param required number of confirmation needed for action to be proceeded
      * @param createdOn time of log
      *//*
    event RequirementChange(uint required, uint256 createdOn);*/

    // dictionary which shows transaction info by transaction identifer
    mapping (uint => Transaction) public transactions;

    // dictionary which shows which owners confirmed transactions
    mapping (uint => mapping (address => bool)) public confirmations;

    // dictionary which shows if ether account is owner
    mapping (address => bool) internal isOwner;

    // owners of wallet
    address[] internal owners;

    // number of confirmation which is needed to action be proceeded
    uint internal required;

    //total transaction count
    uint public transactionCount;

    // dictionary which shows owners who confirmed new owner addition
    mapping(address => address[]) private ownersConfirmedOwnerAdd;

    // dictionary which shows owners who confirmed existing owner remove
    mapping(address => address[]) private ownersConfirmedOwnerRemove;

    // Type which identifies if transaction will operate with ethers or tokens
    enum TransactionType{Standard, Token, Unfreeze, PassOwnership}

    // Structure of detailed transaction information
    struct Transaction {
        address token;
        address destination;
        uint value;
        TransactionType transactionType;
        bool executed;
    }

    modifier notConfirmedOwnerAdd(address _owner) {
        for(uint i = 0; i < ownersConfirmedOwnerAdd[_owner].length; i++){
            require(ownersConfirmedOwnerAdd[_owner][i] != msg.sender);
        }
        _;
    }

    modifier notConfirmedOwnerRemove(address _owner) {
        for(uint i = 0; i < ownersConfirmedOwnerRemove[_owner].length; i++){
            require(ownersConfirmedOwnerRemove[_owner][i] != msg.sender);
        }
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require (transactions[transactionId].destination != 0 || transactions[transactionId].token != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(transactionId >= 0 && transactionId < transactionCount);
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(transactionId >= 0 && transactionId < transactionCount);
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require (_address != 0x0);
        _;
    }

    modifier validRequirement(uint _ownersCount, uint _required) {
        require(_ownersCount <= MAX_OWNER_COUNT);
        require(_required <= _ownersCount);
        require(_required > 1);
        require(_ownersCount > 1);
        _;
    }

    modifier validTransaction(address destination, uint value) {
        require(destination != 0x0);
        require(value > 0);
        _;
    }

    modifier validTokenTransaction(address token, address destination, uint value) {
        require(token != 0x0);
        require(destination != 0x0);
        require(value > 0);
        _;
    }

    modifier validFreezableToken(address token) {
        require(token != 0x0);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function() public payable {
        if (msg.value > 0){
            Deposit(msg.sender, msg.value, now);
        }
    }

    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required number of needed confirmation to proceed any action
    function SimpleMultisigWallet(address[] _owners, uint _required)
    public
    validRequirement(_owners.length, _required)
    {
        for (uint i = 0; i < _owners.length; i++) {
            require(!(isOwner[_owners[i]] || _owners[i] == 0));
            isOwner[_owners[i]] = true;
        }

        owners = _owners;
        //        owners.push(msg.sender);
        //        isOwner[msg.sender] = true;
        require(_required <= owners.length);
        required = _required;
    }

    function getOwners()
    public
    view
    returns(address[])
    {
        return owners;
    }


    function removeOwnersConfirmations(address _owner) private {
        uint[] memory transactionIds = ownersConfirmedTransactions(_owner);
        for (uint i = 0; i < transactionIds.length; i++) {
            confirmations[transactionIds[i]][_owner] = false;
        }
    }

    /*/// @dev Allows to change the number of required confirmations.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        ownerExists(msg.sender)
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required, now);
    }*/

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value)
    public
    ownerExists(msg.sender)
    validTransaction(destination, value)
    returns (uint)
    {
        require(address(this).balance >= value);
        uint transactionId = addTransaction(0x0, destination, value, TransactionType.Standard);
        confirmTransaction(transactionId);
        return transactionId;
    }

    /// @dev Allows an owner to submit and confirm a token transaction.
    /// @param token address of token SC which supply will b transferred.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return Returns transaction ID.
    function submitTokenTransaction(address token, address destination, uint value)
    public
    ownerExists(msg.sender)
    validTokenTransaction(token, destination, value)
    returns (uint)
    {
        require(StandardToken(token).balanceOf(address(this)) >= value);
        uint transactionId = addTransaction(token, destination, value, TransactionType.Token);
        confirmTransaction(transactionId);
        return transactionId;
    }



    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
    public
    ownerExists(msg.sender)
    transactionExists(transactionId)
    notConfirmed(transactionId, msg.sender)
    returns (bool)
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId, now);
        executeTransaction(transactionId);
        return true;
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
    public
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId, now);
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
    public
    view
    returns (bool)
    {
        uint count = 0;
        for (uint i=0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]){
                count += 1;
            }
            if (count == required){
                return true;
            }
        }
        return false;
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
    public
    notExecuted(transactionId)
    returns(bool)
    {
        if (transactions[transactionId].transactionType == TransactionType.Standard
        && isConfirmed(transactionId)
        && this.balance >= transactions[transactionId].value) {
            transactions[transactionId].executed = true;
            transactions[transactionId].destination.transfer(transactions[transactionId].value);
            Execution(transactionId, now);
            return true;
        } else if(transactions[transactionId].transactionType == TransactionType.Token
        && isConfirmed(transactionId)
        && StandardToken(transactions[transactionId].token).balanceOf(address(this)) >= transactions[transactionId].value) {
            transactions[transactionId].executed = true;
            StandardToken(transactions[transactionId].token).transfer(transactions[transactionId].destination, transactions[transactionId].value);
            Execution(transactionId, now);
            return true;
        } else if(transactions[transactionId].transactionType == TransactionType.Unfreeze
        && isConfirmed(transactionId)) {
            transactions[transactionId].executed = true;
            FreezableToken(transactions[transactionId].token).unfreeze();
            Execution(transactionId, now);
            return true;
        } else if(transactions[transactionId].transactionType == TransactionType.PassOwnership
        && isConfirmed(transactionId)) {
            transactions[transactionId].executed = true;
            Ownable(transactions[transactionId].token).transferOwnership(transactions[transactionId].destination);
            Execution(transactionId, now);
            return true;
        }
        return false;
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether/token value.
    /// @param transactionType Transaction type (Standard/token).
    /// @return Returns transaction ID.
    function addTransaction(address token, address destination, uint value, TransactionType transactionType)
    internal
    notNull(destination)
    returns (uint)
    {
        uint transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            token: token,
            value: value,
            transactionType: transactionType,
            executed: false
            });

        transactionCount += 1;
        Submission(transactionId, token, 0x0, transactionType, now);
        return transactionId;
    }



    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
    public
    view
    returns (uint count)
    {
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
    public
    view
    returns (uint founded)
    {
        for (uint i=0; i < transactionCount; i++) {
            if ((pending && !transactions[i].executed) || (executed && transactions[i].executed)) {
                founded += 1;
            }
        }
    }

    /// @dev Check balance of holding specific tokens
    /// @param token address of token
    /// @return balance of tokens
    function tokenBalance(StandardToken token)
    public
    view
    returns(uint)
    {
        return token.balanceOf(address(this));
    }


    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
    public
    view
    returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
    public
    view
    returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count;
        uint i;
        for (i=0; i < transactionCount; i++){
            if ((pending && !transactions[i].executed) ||
                (executed && transactions[i].executed))
            {
                transactionIdsTemp[count] = i;
                count +=1;
            }
        }

        if(to > count) {
            to = count;
        }

        _transactionIds = new uint[](to - from);

        for (i=from; i<to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }

    function ownersConfirmedTransactions(address _owner)
    public
    view
    ownerExists(msg.sender)
    returns(uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;

        for (i=0; i < transactionCount; i++){
            if (confirmations[i][_owner]) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }

        _transactionIds = new uint[](count);
        for(i = 0; i< count; i++){
            _transactionIds[i] = transactionIdsTemp[i];
        }

    }


    /// @dev Implementation of ERC223 receiver fallback function in order to protect
    /// @dev sending tokens (standard ERC223) to smart tokens who doesn&#39;t except them
    function tokenFallback(address /*_origin*/, uint /*_value*/, bytes /*_data*/) public returns (bool ok) {
        return true;
    }
}

contract SimpleTokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for StandardToken;

    event Released(uint256 amount, uint releaseDate);

    // beneficiary of tokens after they are released
    address public beneficiary;

    uint256 public vestedDate;

    mapping(address => uint256) public released;

    modifier vested() {
        require(now >= vestedDate);
        _;
    }

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * _beneficiary
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _vestedDate the period in which the tokens will vest
     */
    function SimpleTokenVesting(address _beneficiary, uint256 _vestedDate) public {
        require(_beneficiary != address(0));
        require(_vestedDate >= now);

        beneficiary = _beneficiary;
        vestedDate = _vestedDate;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    function release(StandardToken token)
    vested
    public
    {
        uint256 unreleased = token.balanceOf(this);

        require(unreleased > 0);

        released[token] = released[token].add(unreleased);

        token.safeTransfer(beneficiary, unreleased);

        Released(unreleased, now);
    }

    /// @dev Implementation of ERC223 receiver fallback function in order to protect
    /// @dev sending tokens (standard ERC223) to smart tokens who doesn&#39;t except them
    function tokenFallback(address /*_origin*/, uint /*_value*/, bytes /*_data*/) pure public returns (bool ok) {
        return true;
    }

}
contract VestedMultisigWallet is SimpleMultisigWallet {

    //date till when multi-signature wallet will be vested
    uint public vestedDate;


    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required number of needed confirmation to proceed any action
    /// @param _vestedDate date till when multisignature will be vested
    function VestedMultisigWallet(address[] _owners, uint _required, uint _vestedDate)
    SimpleMultisigWallet(_owners, _required)
    public
    {
        vestedDate = _vestedDate;
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
    public
    notExecuted(transactionId)
    returns(bool)
    {
        if (transactions[transactionId].transactionType == TransactionType.Standard
        && isConfirmed(transactionId)
        && this.balance >= transactions[transactionId].value) {
            transactions[transactionId].executed = true;
            transactions[transactionId].destination.transfer(transactions[transactionId].value);
            Execution(transactionId, now);
            return true;
        } else if(transactions[transactionId].transactionType == TransactionType.Token
        && isConfirmed(transactionId)
        && StandardToken(transactions[transactionId].token).balanceOf(address(this)) >= transactions[transactionId].value) {
            require(now >= vestedDate);
            transactions[transactionId].executed = true;
            StandardToken(transactions[transactionId].token).transfer(transactions[transactionId].destination, transactions[transactionId].value);
            Execution(transactionId, now);
            return true;
        } else if(transactions[transactionId].transactionType == TransactionType.Unfreeze
        && isConfirmed(transactionId)) {
            transactions[transactionId].executed = true;
            FreezableToken(transactions[transactionId].token).unfreeze();
            Execution(transactionId, now);
            return true;
        } else if(transactions[transactionId].transactionType == TransactionType.PassOwnership
        && isConfirmed(transactionId)) {
            transactions[transactionId].executed = true;
            Ownable(transactions[transactionId].token).transferOwnership(transactions[transactionId].destination);
            Execution(transactionId, now);
            return true;
        }
        return false;
    }

}