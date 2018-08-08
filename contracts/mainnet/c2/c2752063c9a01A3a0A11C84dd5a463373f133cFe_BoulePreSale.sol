pragma solidity ^0.4.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

pragma solidity ^0.4.11;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.4.11;




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.4.11;




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

pragma solidity ^0.4.11;




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

pragma solidity ^0.4.11;





/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

pragma solidity ^0.4.11;


/*
    Copyright 2017, Giovanni Zorzato (Boul&#233; Foundation)
*/

contract BouleToken is MintableToken {
    // BouleToken is an OpenZeppelin Mintable Token
    string public name = "Boule Token";
    string public symbol = "BOU";
    uint public decimals = 18;

    // do no allow to send ether to this token
    function () public payable {
        throw;
    }

}



pragma solidity ^0.4.4;


/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <<span class="__cf_email__" data-cfemail="afdcdbcac9cec181c8cac0ddc8caefccc0c1dccac1dcd6dc81c1cadb">[email&#160;protected]</span>>
contract MultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this))
            throw;
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            throw;
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            throw;
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0)
            throw;
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            throw;
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            throw;
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            throw;
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            throw;
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (   ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0)
            throw;
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function MultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                throw;
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param owner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
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
        Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction tx = transactions[transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                tx.executed = false;
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
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
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

pragma solidity ^0.4.11;


/*
    Copyright 2017, Giovanni Zorzato (Boul&#233; Foundation)
 */

contract BoulePreSale is Ownable{

    uint public initialBlock;             // Block number in which the sale starts.
    uint public discountBlock;            // Block number in which the priority discount end.
    uint public finalBlock;               // Block number in which the sale end.

    address public bouleDevMultisig;      // The address to hold the funds donated


    uint public totalCollected = 0;               // In wei
    bool public saleStopped = false;              // Has Boul&#233; Dev stopped the sale?
    bool public saleFinalized = false;            // Has Boul&#233; Dev finalized the sale?

    BouleToken public token;              // The token

    MultiSigWallet wallet;

    uint constant public minInvestment = 1 finney;    // Minimum investment  0,001 ETH
    uint public hardCap = 10000 ether;               // Pre-sale Cap
    uint public minFundingGoal = 300 ether;          // Minimum funding goal for sale success


    /** Addresses that are allowed to invest even before ICO offical opens. For testing, for ICO partners, etc. */
    mapping (address => bool) public whitelist;

    /** How much they have invested */
    mapping(address => uint) public balances;

    event NewBuyer(address indexed holder, uint256 bouAmount, uint256 amount);
    // Address early participation whitelist status changed
    event Whitelisted(address addr, bool status);
    // Investor has been refunded because the ico did not reach the min funding goal
    event Refunded(address investor, uint value);

    function BoulePreSale (
    address _token,
    uint _initialBlock,
    uint _discountBlock,
    uint _finalBlock,
    address _bouleDevMultisig
    )
    {
        if (_initialBlock >= _finalBlock) throw;

        // Save constructor arguments as global variables
        token = BouleToken(_token);

        initialBlock = _initialBlock;
        discountBlock = _discountBlock;
        finalBlock = _finalBlock;
        bouleDevMultisig = _bouleDevMultisig;
        // create wallet object
        wallet = MultiSigWallet(bouleDevMultisig);

    }

    // change whitelist status for a specific address
    function setWhitelistStatus(address addr, bool status)
    onlyOwner {
        whitelist[addr] = status;
        Whitelisted(addr, status);
    }

    // @notice Get the price for a BOU token at any given block number
    // @param _blockNumber the block for which the price is requested
    // @return price of boule
    // If sale isn&#39;t ongoing for that block, returns 0.
    function getPrice(uint _blockNumber) constant public returns (uint256) {
        if (_blockNumber >= finalBlock) return 0;
        if(_blockNumber <= discountBlock){
            return 2000; // 2000 BOU for 1 ETH first 24 hours (approx in blocks)
        }
        return 1400; // 1400 BOU for 1 ETH after 24 hours (approx in blocks)
    }


    /// @dev The fallback function is called when ether is sent to the contract, it
    /// simply calls `doPayment()` with the address that sent the ether as the
    /// `_owner`. Payable is a required solidity modifier for functions to receive
    /// ether, without this modifier functions will throw if ether is sent to them

    function () public payable {
        doPayment(msg.sender);
    }



    /// @dev `doPayment()` is an internal function that sends the ether that this
    ///  contract receives to the bouleDevMultisig and creates tokens in the address of the
    /// @param _owner The address that will hold the newly created tokens

    function doPayment(address _owner)
    only_during_sale_period_or_whitelisted(_owner)
    only_sale_not_stopped
    non_zero_address(_owner)
    minimum_value(minInvestment)
    internal {
        // do not allow to go past hard cap
        if ((totalCollected + msg.value) > hardCap) throw; // If past hard cap, throw

        if ((totalCollected + msg.value) < minFundingGoal){ // if under min funding goal
            // record the investment for possible refund in case the ICO does not finalize
            balances[_owner] = SafeMath.add(balances[_owner], msg.value);
            // keep funds here
        }
        else{
            if (!wallet.send(msg.value)) throw; // Send funds to multisig wallet
        }

        uint256 boughtTokens = SafeMath.mul(msg.value, getPrice(getBlockNumber())); // Calculate how many tokens bought

        if (!token.mint(_owner, boughtTokens)) throw; // Allocate tokens.

        totalCollected = SafeMath.add(totalCollected, msg.value); // Save total collected amount

        NewBuyer(_owner, boughtTokens, msg.value);
    }

    // allow investors to be refunded if the sale does not reach min investment target (minFundingGoal)
    // refund can be asked only after sale period
    function refund()
    only_sale_refundable {
        address investor = msg.sender;
        if(balances[investor] == 0) throw; // nothing to refund
        uint amount = balances[investor];
        // remove balance
        delete balances[investor];
        // send back eth
        if(!investor.send(amount)) throw;

        Refunded(investor, amount);
    }

    // @notice Function to stop sale for an emergency.
    // @dev Only Boul&#233; Dev can do it after it has been activated.
    function emergencyStopSale()
    only_sale_not_stopped
    onlyOwner
    public {

        saleStopped = true;
    }

    // @notice Function to restart stopped sale.
    // @dev Only Boul&#233; Dev can do it after it has been disabled and sale is ongoing.
    function restartSale()
    only_during_sale_period
    only_sale_stopped
    onlyOwner
    public {

        saleStopped = false;
    }

    // @notice Function to change sale block intervals.
    // @dev Only Boul&#233; Dev can do it while the sale is ongoing to fix block time variations.
    function changeSaleBlocks(uint _initialBlock, uint _discountBlock, uint _finalBlock)
    onlyOwner
    only_sale_not_stopped
    public {
        if (_initialBlock >= _finalBlock) throw;
        if (_initialBlock >= _discountBlock) throw;
        if (saleFinalized) throw; // only if sale is still active
        initialBlock = _initialBlock;
        discountBlock = _discountBlock;
        finalBlock = _finalBlock;
    }


    // @notice Moves funds in sale contract to Boul&#233; MultiSigWallet.
    // @dev  Moves funds in sale contract to Boul&#233; MultiSigWallet.
    function moveFunds()
    onlyOwner
    public {
        if (totalCollected < minFundingGoal) throw;
        // move funds
        if (!wallet.send(this.balance)) throw;
    }


    // @notice Finalizes sale generating the tokens for Boul&#233; Dev.
    // @dev Transfers the token controller power to the ANPlaceholder.
    function finalizeSale()
    only_after_sale
    onlyOwner
    public {

        doFinalizeSale();
    }

    function doFinalizeSale()
    internal {
        // Doesn&#39;t check if saleStopped is false, because sale could end in a emergency stop.
        // This function cannot be successfully called twice, because it will top being the controller,
        // and the generateTokens call will fail if called again.

        // Boul&#233; owns 50% of the total number of emitted tokens at the end of the pre-sale.

        if (totalCollected >= minFundingGoal){ // if min funding goal reached
            // move all remaining eth in the sale contract into multisig wallet (no refund is possible anymore)
            if (!wallet.send(this.balance)) throw;

            uint256 bouleTokenSupply = token.totalSupply();

            if (!token.mint(bouleDevMultisig, bouleTokenSupply)) throw; // Allocate tokens for Boul&#233;.
        }
        // token will be owned by Boul&#233; multisig wallet, this contract cannot mint anymore
        token.transferOwnership(bouleDevMultisig);

        saleFinalized = true;
        saleStopped = true;
    }


    function getBlockNumber() constant internal returns (uint) {
        return block.number;
    }


    modifier only(address x) {
        if (msg.sender != x) throw;
        _;
    }

    modifier only_before_sale {
        if (getBlockNumber() >= initialBlock) throw;
        _;
    }

    modifier only_during_sale_period {
        if (getBlockNumber() < initialBlock) throw;
        if (getBlockNumber() >= finalBlock) throw;
        _;
    }

    // valid only during sale or before sale if the sender is whitelisted
    modifier only_during_sale_period_or_whitelisted(address x) {
        if (getBlockNumber() < initialBlock && !whitelist[x]) throw;
        if (getBlockNumber() >= finalBlock) throw;
        _;
    }

    modifier only_after_sale {
        if (getBlockNumber() < finalBlock) throw;
        _;
    }

    modifier only_sale_stopped {
        if (!saleStopped) throw;
        _;
    }

    modifier only_sale_not_stopped {
        if (saleStopped) throw;
        _;
    }

    modifier only_finalized_sale {
        if (getBlockNumber() < finalBlock) throw;
        if (!saleFinalized) throw;
        _;
    }

    modifier non_zero_address(address x) {
        if (x == 0) throw;
        _;
    }

    modifier only_sale_refundable {
        if (getBlockNumber() < finalBlock) throw; // sale must have ended
        if (totalCollected >= minFundingGoal) throw; // sale must be under min funding goal
        _;
    }

    modifier minimum_value(uint256 x) {
        if (msg.value < x) throw;
        _;
    }
}