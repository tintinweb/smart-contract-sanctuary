pragma solidity ^0.4.24;

/**
 * ERC-20 standard token interface as defined at:
 * <a href=&quot;https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md&quot;>here</a>.
 */

contract Token {
    
    /**
     * Function to get the total amount of tokens in circulation.
     * 
     * @return the total amount of tokens in circulation
     */

    function totalSupply () public view returns (uint256 supply);
    
    /**
     * Function to get the number of tokens currently belonging to a given 
     * owner.
     * 
     * @param _owner is the address on which the current tokens are going to be 
     * obtained.
     * 
     * @return the total number of tokens currently in the owner&#39;s address
     */
     
    function balanceOf (address _owner) public view returns (uint256 balance);
    
    /**
     * Obtain the total tokens that the spender is able to use for a transfer
     * 
     * @param _owner is the address on which the current tokens are going to be
     * transfer from.
     * 
     * @param _spender is the address on which the current tokens are going to
     * be transfer to.
     * 
     * @return the number of tokens given to the spender that are currently
     * allowed to transfer from a given owner
     */ 
    
    function allowance (address _owner, address _spender)
        public view returns (uint256 remaining);
        
    /**
     * Approves the transaction of a given number of tokens from the sender
     * 
     * @param _spender address of the person transfering the tokens
     * 
     * @param _value the amount of tokens that are subject to the transfer
     * 
     * @return true if the token transfer was approved and false if not
     */ 
    
    function approve (address _spender, uint256 _value)
        public returns (bool success);
        
    /**
     * Transfer a number of tokens from the sender address to the given recipient
     * 
     * @param _to address where the tokens are going to be transfer
     * 
     * @param _value total number of tokens that are going to be transfer
     * 
     * @return true if the token transfer was successfull and false if it fail
     * 
     */ 

    function transfer (address _to, uint256 _value)
        public returns (bool success);
        
    /**
     * Transfer the given number of tokens from the owner to the recipient
     * 
     * @param _from the address where the tokens are taken from
     * 
     * @param _to the address where the tokens are going to be transfer to
     * 
     * @param _value total number of tokens that are going to be transfer
     * 
     * @return true if the token transfer was successfull and false if it fail
     */
        
    function transferFrom (address _from, address _to, uint256 _value)
        public returns (bool success);
        
    /**
     * Event to log when tokens are transfer from one user to another
     * 
     * @param _from address of the original owner of the tokens
     * 
     * @param _to address of the new owner of the tokens
     * 
     * @param _value total amount of tokens that were transfer in this
     * transaction
     */ 
        
    event Transfer (address indexed _from, address indexed _to, uint256 _value);
    
    /**
     * Event to log when the owner approved the transfer of the tokens to a
     * given owner
     * 
     * @param _owner address of the original owner of the tokens that got
     * trasnfered
     * 
     * @param _spender address of who was allowed to transfer the tokens that
     * belonged to the owner
     * 
     * @param _value number of tokens that were approved to be transfer by the
     * original owner
     *  
     */ 
    
    event Approval (address indexed _owner, address indexed _spender, 
    uint256 _value);

}

pragma solidity ^0.4.24;

/**
 * Math operations with safety checks that throw on error
 */ 

contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    
    /**
     * Function to add two uint246 values, throw in case of overflow.
     * 
     * @param x first value to be added
     * 
     * @param y second value to be added
     * 
     * @return the total amount of x + y
     */ 
    
    function addition (uint256 x, uint256 y)
      pure internal
      returns (uint256 z) {
        assert (x <= MAX_UINT256 - y);
        return x + y;
      }
      
      /**
       * Function to substract two uint256 values, throw in case of overflow.
       * 
       * @param x first value to be substracted from
       * 
       * @param y second value to be substracted from
       * 
       * @return the total amount of x - y
       */ 
       
    function substract (uint256 x, uint256 y)
      pure internal
      returns (uint256 z) {
        assert (x >= y);
        return x - y;
      }
      
      /**
       * Function to multiply two uint256 values, throw in case of overflow.
       * 
       * @param x first value to be multiplied from
       * 
       * @param y second value to be multiplied from
       * 
       * @return the toal amoun of x by y
       */ 
    function multiply (uint256 x, uint256 y)
      pure internal
      returns (uint256 z) {
        if (y == 0) return 0; // Prevent division by zero at the next line
        assert (x <= MAX_UINT256 / y);
        return x * y;
      }
}

/**
 * Abstract Token SmartContract that could be used as a base contract for 
 * ERC-20 token contracts
 */ 
contract AbstractToken is Token, SafeMath {
    
    /**
     * Create a new Abstract Token Contract
     * Constructor that does nothing
     */ 
    
  constructor () public {}
  
  /**
   * Function to get the number of tokens currently belonging to a given owner
   * 
   * @param _owner is the address on which the current tokens are going to 
   * be obtained.
   * 
   * @return number of tokens currently belonging to the owner of the 
   * address (owner)   
   */ 
  
    function balanceOf (address _owner) public view returns (uint256 balance) {
        return accounts [_owner];
      }
      
    /**
     * Function to allow the given spender to transfer a given amount of 
     * tokens from msg.sender
     * 
     * @param _spender address to allow the owner to transfer the amounnt 
     * of tokens given
     * 
     * @param _value number of tokens to allow to transfer
     * 
     * @return true if token transfer  was successfull or not
     */ 
    function approve (address _spender, uint256 _value)
  public returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    emit Approval (msg.sender, _spender, _value);

    return true;
  }
    
    /**
     * Function to transfer a given amount of tokens from message sender to 
     * a given recipient
     * 
     * @param _to address to transfer tokens to the owner of
     * 
     * @param _value amount of tokens that are going to be subject to this 
     * transaction
     * 
     * @return true if the tokens were trasnfered successfuly or 
     * false if it fail
     */ 
    function transfer (address _to, uint256 _value)
  public returns (bool success) {
    uint256 fromBalance = accounts [msg.sender];
    if (fromBalance < _value) return false;
    if (_value > 0 && msg.sender != _to) {
      accounts [msg.sender] = substract (fromBalance, _value);
      accounts [_to] = addition (accounts [_to], _value);
    }
    emit Transfer (msg.sender, _to, _value);
    return true;
  }
  
  /**
   * Function to transfer given number of tokens from a given owner to a 
   * given recipient
   * 
   * @param _from address to transfer tokens from the owner of 
   * 
   * @param _to address where the tokens are going to be transfer to
   * 
   * @param _value total number of tokens that are going to be subject  
   * to this transaction
   * 
   * @return true if the tokens were transfered scucessfuly or false it it fail
   */ 
  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success) {
    uint256 spenderAllowance = allowances [_from][msg.sender];
    if (spenderAllowance < _value) return false;
    uint256 fromBalance = accounts [_from];
    if (fromBalance < _value) return false;

    allowances [_from][msg.sender] =
      substract (spenderAllowance, _value);

    if (_value > 0 && _from != _to) {
      accounts [_from] = substract (fromBalance, _value);
      accounts [_to] = addition (accounts [_to], _value);
    }
    emit Transfer (_from, _to, _value);
    return true;
  }
  
  /**
   * Function to know how many tokens a given spender is currently allowed 
   * to transfer from given owner
   * 
   * @param _owner address to get number of tokens allowed to be transferred 
   * from the owner of
   * 
   * @param _spender address to get number of tokens allowed to be transferred 
   * by the owner of
   * 
   * @return number of tokens given spender is currently allowed to transfer 
   * from given owner
   */ 
  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }
  
  /**
   * Mapping from addresses of token holders to the numbers of tokens belonging 
   * to these token holders
   */ 
  mapping (address => uint256) internal accounts;
  
  /**
   * Mapping from addresses of token holders to the mapping of addresses of
   * spenders to the allowances set by these token holders to these spenders.
   */
  mapping (address => mapping (address => uint256)) internal allowances;

}

/**
 * Pinmo Token Smart Contract
 */ 
contract PinmoToken is AbstractToken {
    
    /**
     * Address of the owner of this smart contract
     */ 
    address private owner;
    
    /**
     * total number of tokens in circulation
     */ 
    uint256 tokenCount;
    
    /**
     * True if tokens are currently frozen for transfer or false if they are
     * not frozen
     */ 
    bool frozen = false;
    
    /**
     * Create a new Pinmo Token Smart Contract with the total amount of tokens
     * issued and a given msg.sender, as well, this makes the msg.sender they
     * owner of this smart contract
     * 
     * @param _tokenCount total number of tokens to be issued and given to the
     * msg.sender
     */ 
    constructor (uint256 _tokenCount) public {
        owner = msg.sender;
        tokenCount = _tokenCount;
        accounts [msg.sender] = _tokenCount;
    }
    
    /**
     * Function to get the name of this token
     * 
     * @return the name of this token
     */ 
    function name () public pure returns (string result) {
    return &quot;Pinmo Token&quot;;
    }
    /**
     * Function to ge the symbol of this token
     * 
     * @return symbol for this token
     */ 
    function symbol () public pure returns (string result) {
    return &quot;PMT&quot;;
    }
    
    /**
     * Function to get the number of decimals
     * 
     * @return number of decimals for this token
     */ 
    function decimals () public pure returns (uint8 result) {
    return 18;
    }

    /**
     * Function to get the total number of tokens in circulation
     * 
     * @return total number of tokens in circulation
     */ 
    function totalSupply () public view returns (uint256 supply) {
        return tokenCount;
    }
    
    /**
     * Function to check if the transfer is frozen or not to
     * 
     * @param _to address where the tokens are going to
     * 
     * @param _value amount of tokens that were transfered.
     * 
     * @return true if the tokens are frozen and false if they are not
     */ 
    function transfer (address _to, uint256 _value)
    public returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transfer (_to, _value);
    }
    
    /**
     * Function to check if the transfer is frozen or not from
     * 
     * @param _from address where the tokens were transfered from
     * 
     * @param _to address where the tokens are going to
     * 
     * @param _value amount of tokens that were transfered
     * 
     * @return true if the tokens are frozen and false if they are not
     */ 
    function transferFrom (address _from, address _to, uint256 _value)
    public returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transferFrom (_from, _to, _value);
  }
  
  /**
   * Function to check the allowance was approved
   * 
   * @param _spender address from the person that spend the tokens
   * 
   * @param _currentValue total value of the tokens before approving
   * 
   * @param _newValue total value of the tokens after approving
   * 
   * @return true if the msg.sender is equal to the current value and
   * false if there is a difference on this.
   */ 
    function approve (address _spender, uint256 _currentValue, uint256 _newValue)
    public returns (bool success) {
    if (allowance (msg.sender, _spender) == _currentValue)
      return approve (_spender, _newValue);
    else return false;
  }
  
  /**
   * Function to set a new owner of this contract
   * 
   * @param _newOwner address of the new owner approinted by the current owner
   */ 
  function setOwner (address _newOwner) public {
    require (msg.sender == owner);

    owner = _newOwner;
  }
  
  /**
   * Function to freeze all the transfers
   * May only be called by smart contract owner
   */ 
  function freezeTransfers () public {
    require (msg.sender == owner);

    if (!frozen) {
      frozen = true;
      emit Freeze ();
    }
    
    /**
     * Unfreeze token transfers 
     * May only be calles by the Smart Contract owner
     */ 
  }function unfreezeTransfers () public {
    require (msg.sender == owner);

    if (frozen) {
      frozen = false;
      emit Unfreeze ();
    }
  }
  
  /**
   * Logged when token transfers were frozen
   */ 
  
  event Freeze ();
  
  /**
   * Logged when token transfers were unfrozen
   */ 
  event Unfreeze ();
  
}

/**
 * Multisignature wallet to approve transfers within wallets as a safe guard
 * that multiple approvals are needed
 */ 
contract MultiSigWallet { // this is safe to implement but it consumes gas 
    address private _owner;
    
    /**
     * mapping from addresses of token owners
     */ 
    mapping(address => uint8) private _owners; 
    
    /**
     * Constant value for minimum number of signatures
     * uint for the transaction id storage as private
     */ 
    uint constant MIN_SIGNATURES = 2; // number of signatures required 
    uint private _transactionsIdx;
    
    /**
     * the base structure for the transaction
     * @param from address that where the transfer is initiated
     * 
     * @param to address where the tokens are going to be transfer
     * 
     * @param amount total number of tokens part of this transaction
     * 
     * @param signatureCount total number of signatures provided by the owners
     * 
     * @param signatures mapping that contains all the signatures of the
     * owners
     */ 
    struct Transaction {
        address from;
        address to;
        uint amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }
    
    /**
     * mapping of uint transactions that contains all the pending transactions
     * @param _transactions number of transactions in the queue
     * 
     * @param _pendingTransactions number of pending transactions in the
     * queue
     */ 
    mapping (uint => Transaction) private _transactions;
    uint[] private _pendingTransactions;
    
    /**
     * Modifier to verified the owners needs to be equal to the msg.sender
     */ 
    modifier isOwner(){
        require(msg.sender == _owner);
        _;
    }
    
    /**
     * Modifier to check the owner is a valid owner
     */ 
    
    modifier validOwner(){
        require(msg.sender == _owner || _owners[msg.sender] == 1);
        _;
    }
    
    /**
     * Event to log the deposit of DepositFunds
     * @param from address where the funds are coming
     * 
     * @param amount of tokens that awere deposit
     */ 
    
    event DepositFunds(address from, uint amount);
    
    /**
     * Event to log when the transaction was created
     * @param from address where the transaction originated
     * 
     * @param to address where the transaction finalized
     * 
     * @param amount of tokens that are subject of the transaction
     */ 
    event TransactionCreated(address from, address to, uint amount, 
    uint transactionId);
    
    /**
     * Event to log when the transaction was completed
     * @param from addtress where the transaction originated
     * 
     * @param to address where the transaction finalized
     * 
     * @param amount of tokens that are subject of the transaction
     */ 
    event TransactionCompleted(address from, address to, uint amount, 
    uint transactionId);
    
    /**
     * Event to log who signed the transaction
     * 
     * @param by address of the owner that signed and approved the transaction
     * 
     * @param transactionId id of the transaction that was signed
     */ 
    event TransactionSigned(address by, uint transactionId);

    /**
     * Constructor that validates the owner
     */ 
    constructor() MultiSigWallet() // can only be tested in the real environment
        public {
            _owner = msg.sender;
    }
    
    /**
     * Function to add an owner to sign transactions
     * 
     * @param owner address that is going to get authorized to sign 
     * transactions
     */ 
    function addOwner(address owner)
        isOwner
        public {
            _owners[owner] = 1;    
        }
    /**
     * Function to remove an owner to sign transactions
     * 
     * @param owner address that is going to be unauthorized to sign
     * transactions
     */ 
    function removeOwner(address owner)
        isOwner
        public {
            _owners[owner] = 0;
        }
    /**
     * function to make the DepositFunds payable
     */ 
    function ()
    public
    payable {
        emit DepositFunds(msg.sender, msg.value);
    }
    /**
     * Function to withdraw money from the account
     * 
     * @param amount total tokens that want to be withdraw
     */ 
    function withdraw(uint amount)
    
    public {
        transferTo(msg.sender, amount);
    }
    
    /**
     * Function to transfer to a valid owner
     * @param to address where the tokens are going to go to
     * 
     * @param amount total amount of tokens that are going to be transfer
     */ 
    function transferTo(address to, uint amount)
    validOwner
    public {
        require(address(this).balance >= amount);
        uint transactionId = _transactionsIdx++;
        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.signatureCount = 0;
        
        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);
        
        emit TransactionCreated(msg.sender, to, amount, transactionId);
    }
    
    /**
     * Function to obtain the pending transactions that need to be signed
     */ 
    function getPendingTransactions()
        view
        validOwner
        public
        returns (uint[]) {
            return _pendingTransactions;
        }
    
    /**
     * Function to sign the transactions that are either pending or current
     * 
     * @param transactionId that needs to be signed
     */ 
    function signTransaction(uint transactionId)
        validOwner
        public{
            Transaction storage transaction = _transactions[transactionId];
            // Transaction must exist
            require(0x0 != transaction.from);
            // Creator cannot sign the transaction 
            require(msg.sender != transaction.from);
            // Cannot sign a transaction more than once
            require(transaction.signatures[msg.sender] != 1);
            
            transaction.signatures[msg.sender] == 1;
            transaction.signatureCount++;
            
            emit TransactionSigned(msg.sender, transactionId);
            
            if(transaction.signatureCount >= MIN_SIGNATURES){
                require(address(this).balance >= transaction.amount);
                transaction.to.transfer(transaction.amount);
                emit TransactionCompleted(transaction.from, transaction.to, transaction.amount, transactionId);
                deleteTransaction(transactionId);
            }
        }
        
        /**
         * Function to delete any pending transactions
         * 
         * @param transactionId that needs to be deleted
         */ 
        function deleteTransaction(uint transactionId)
            validOwner
            public {
                uint8 replace = 0;
                for (uint i = 0; i < _pendingTransactions.length; i++){
                    if(1 == replace){
                        _pendingTransactions[i-1] = _pendingTransactions[i];
                    } else if(transactionId == _pendingTransactions[i]){
                        replace = 1;
                    }
                }
                delete _pendingTransactions[_pendingTransactions.length -1];
                _pendingTransactions.length--;
                delete _transactions[transactionId];
            }
            
            /**
             * Function to obtain the balance of a given wallet
             * 
             * @return balance of a given address
             */ 
            function walletBalance()
            constant
            public
            returns (uint){
                return address(this).balance;
            }
}

/**
 * Escrow function to hold tokens after reviewing the transactions
 */ 
contract Escrow {
    uint balance;
    address public buyer;
    address public seller;
    address private escrow;
    uint private start;
    bool buyerOk;
    bool sellerOk;
    
    /**
     * constructor that contains the buyer and seller addresses
     */ 
    constructor (address buyer_address, address seller_address) 
    public{
        buyer = buyer_address;
        seller = seller_address;
        escrow = msg.sender;
        start = now;
    }
    /**
     * Function to accept the payment
     */ 
    function accept() payable public{
        if (msg.sender == buyer){
            buyerOk = true;
        } else if (msg.sender == seller){
            sellerOk = true;
        }
        if (buyerOk && sellerOk){
            payBalance();
        } else if (buyerOk && !!sellerOk && now > start + 30 days){
            // Freeze 30 days before release to buyer. The customer needs to remember
            // to call this method after freeze period.
            selfdestruct(buyer);
        }
    }
    /**
     * Function to pay the hold balance if it hasn&#39;t been paid
     */ 
    function payBalance() private {
        escrow.transfer(address(this).balance / 100);
        if (seller.send(address(this).balance)){
            balance = 0;
        } else {
            revert();
        }
        
    }
    /**
     * Function to deposit the balance of the transaction
     */ 
    function deposit() public payable {
        if(msg.sender == buyer){
            balance += msg.value;
        }
    }
    /**
     * Function to cancel the balance that was hold
     */ 
    function cancel() public {
        if(msg.sender == buyer){
            buyerOk = false;
        }else if (msg.sender == seller){
            sellerOk = false;
        }
        if(!buyerOk && !sellerOk){
            selfdestruct(buyer);
        }
    }
    /**
     * Function to kill the escrow function on this transaction
     */ 
    function kill() public payable {
        if(msg.sender == escrow){
            selfdestruct(buyer);
        }
    }
}