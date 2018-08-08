pragma solidity ^0.4.11;

contract Owned {

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}


/**
 * @title Prealloc
 * @dev Pre-alloc storage vars, to flatten gas usage in future operations.
 */
library Prealloc {
    struct UINT256 {
        uint256 value_;
    }

    function set(UINT256 storage i, uint256 value) internal {
        i.value_ = ~value;
    }

    function get(UINT256 storage i) internal constant returns (uint256) {
        return ~i.value_;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



/// VEN token, ERC20 compliant
contract VEN is Token, Owned {
    using SafeMath for uint256;

    string public constant name    = "VeChain Token";  //The Token&#39;s name
    uint8 public constant decimals = 18;               //Number of decimals of the smallest unit
    string public constant symbol  = "VEN";            //An identifier    

    struct Account {
        uint256 balance;
        // raw token can be transformed into balance with bonus
        uint256 rawTokens;
    }

    // Balances for each account
    mapping(address => Account) accounts;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping(address => uint256)) allowed;

    // every buying will update this var. 
    // pre-alloc to make first buying cost no much more gas than subsequent
    using Prealloc for Prealloc.UINT256;
    Prealloc.UINT256 rawTokensSupplied;

    // bonus that can be shared by raw tokens
    uint256 bonusOffered;

    // Constructor
    function VEN() {
        rawTokensSupplied.set(0);
    }

    // Send back ether sent to me
    function () {
        revert();
    }

    // If sealed, transfer is enabled and mint is disabled
    function isSealed() constant returns (bool) {
        return owner == 0;
    }

    // Claim bonus by raw tokens
    function claimBonus(address _owner) internal{      
        require(isSealed());
        if (accounts[_owner].rawTokens != 0) {
            accounts[_owner].balance = balanceOf(_owner);
            accounts[_owner].rawTokens = 0;
        }
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256 balance) {
        if (accounts[_owner].rawTokens == 0)
            return accounts[_owner].balance;

        if (isSealed()) {
            uint256 bonus = 
                 accounts[_owner].rawTokens
                .mul(bonusOffered)
                .div(rawTokensSupplied.get());

            return accounts[_owner].balance
                    .add(accounts[_owner].rawTokens)
                    .add(bonus);
        }
        
        return accounts[_owner].balance.add(accounts[_owner].rawTokens);
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) returns (bool success) {
        require(isSealed());

        // implicitly claim bonus for both sender and receiver
        claimBonus(msg.sender);
        claimBonus(_to);

        if (accounts[msg.sender].balance >= _amount
            && _amount > 0
            && accounts[_to].balance + _amount > accounts[_to].balance) {
            accounts[msg.sender].balance -= _amount;
            accounts[_to].balance += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        require(isSealed());

        // implicitly claim bonus for both sender and receiver
        claimBonus(_from);
        claimBonus(_to);

        if (accounts[_from].balance >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && accounts[_to].balance + _amount > accounts[_to].balance) {
            accounts[_from].balance -= _amount;
            allowed[_from][msg.sender] -= _amount;
            accounts[_to].balance += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        //if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        ApprovalReceiver(_spender).receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // Mint tokens and assign to some one
    function mint(address _owner, uint256 _amount, bool _isRaw) onlyOwner{
        if (_isRaw) {
            accounts[_owner].rawTokens = accounts[_owner].rawTokens.add(_amount);
            rawTokensSupplied.set(rawTokensSupplied.get().add(_amount));
        } else {
            accounts[_owner].balance = accounts[_owner].balance.add(_amount);
        }

        totalSupply = totalSupply.add(_amount);
        Transfer(0, _owner, _amount);
    }
    
    // Offer bonus to raw tokens holder
    function offerBonus(uint256 _bonus) onlyOwner {
        bonusOffered = bonusOffered.add(_bonus);
    }

    // Set owner to zero address, to disable mint, and enable token transfer
    function seal() onlyOwner {
        setOwner(0);

        totalSupply = totalSupply.add(bonusOffered);
        Transfer(0, address(-1), bonusOffered);
    }
}

contract ApprovalReceiver {
    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData);
}


// Contract to sell and distribute VEN tokens
contract VENSale is Owned{

    /// chart of stage transition 
    ///
    /// deploy   initialize      startTime                            endTime                 finalize
    ///                              | <-earlyStageLasts-> |             | <- closedStageLasts -> |
    ///  O-----------O---------------O---------------------O-------------O------------------------O------------>
    ///     Created     Initialized           Early             Normal             Closed            Finalized
    enum Stage {
        NotCreated,
        Created,
        Initialized,
        Early,
        Normal,
        Closed,
        Finalized
    }

    using SafeMath for uint256;
    
    uint256 public constant totalSupply         = (10 ** 9) * (10 ** 18); // 1 billion VEN, decimals set to 18

    uint256 constant privateSupply              = totalSupply * 9 / 100;  // 9% for private ICO
    uint256 constant commercialPlan             = totalSupply * 23 / 100; // 23% for commercial plan
    uint256 constant reservedForTeam            = totalSupply * 5 / 100;  // 5% for team
    uint256 constant reservedForOperations      = totalSupply * 22 / 100; // 22 for operations

    // 59%
    uint256 public constant nonPublicSupply     = privateSupply + commercialPlan + reservedForTeam + reservedForOperations;
    // 41%
    uint256 public constant publicSupply = totalSupply - nonPublicSupply;

    uint256 public officialLimit;
    uint256 public channelsLimit;

    using Prealloc for Prealloc.UINT256;
    Prealloc.UINT256 officialSold_; // amount of tokens officially sold out

    uint256 public channelsSold;    // amount of tokens sold out via channels
    
    uint256 constant venPerEth = 3500;  // normal exchange rate
    uint256 constant venPerEthEarlyStage = venPerEth + venPerEth * 15 / 100;  // early stage has 15% reward
   
    VEN ven; // VEN token contract follows ERC20 standard

    address ethVault; // the account to keep received ether
    address venVault; // the account to keep non-public offered VEN tokens

    uint public startTime; // time to start sale
    uint public endTime;   // tiem to close sale
    uint public earlyStageLasts; // early bird stage lasts in seconds

    bool initialized;
    bool finalized;

    function VENSale() {
        officialSold_.set(0);
    }    

    /// @notice calculte exchange rate according to current stage
    /// @return exchange rate. zero if not in sale.
    function exchangeRate() constant returns (uint256){
        if (stage() == Stage.Early) {
            return venPerEthEarlyStage;
        }
        if (stage() == Stage.Normal) {
            return venPerEth;
        }
        return 0;
    }

    /// @notice for test purpose
    function blockTime() constant returns (uint) {
        return block.timestamp;
    }

    /// @notice estimate stage
    /// @return current stage
    function stage() constant returns (Stage) { 
        if (finalized) {
            return Stage.Finalized;
        }

        if (!initialized) {
            // deployed but not initialized
            return Stage.Created;
        }

        if (blockTime() < startTime) {
            // not started yet
            return Stage.Initialized;
        }

        if (officialSold_.get().add(channelsSold) >= publicSupply) {
            // all sold out
            return Stage.Closed;
        }

        if (blockTime() < endTime) {
            // in sale            
            if (blockTime() < startTime.add(earlyStageLasts)) {
                // early bird stage
                return Stage.Early;
            }
            // normal stage
            return Stage.Normal;
        }

        // closed
        return Stage.Closed;
    }

    /// @notice entry to buy tokens
    function () payable {        
        buy();
    }

    /// @notice entry to buy tokens
    function buy() payable {
        require(msg.value >= 0.01 ether);

        uint256 rate = exchangeRate();
        // here don&#39;t need to check stage. rate is only valid when in sale
        require(rate > 0);

        uint256 remained = officialLimit.sub(officialSold_.get());
        uint256 requested = msg.value.mul(rate);
        if (requested > remained) {
            //exceed remained
            requested = remained;
        }

        uint256 ethCost = requested.div(rate);
        if (requested > 0) {
            ven.mint(msg.sender, requested, true);
            // transfer ETH to vault
            ethVault.transfer(ethCost);

            officialSold_.set(officialSold_.get().add(requested));
            onSold(msg.sender, requested, ethCost);        
        }

        uint256 toReturn = msg.value.sub(ethCost);
        if(toReturn > 0) {
            // return over payed ETH
            msg.sender.transfer(toReturn);
        }        
    }

    /// @notice calculate tokens sold officially
    function officialSold() constant returns (uint256) {
        return officialSold_.get();
    }

    /// @notice manually offer tokens to channels
    function offerToChannels(uint256 _venAmount) onlyOwner {
        Stage stg = stage();
        // since the settlement may be delayed, so it&#39;s allowed in closed stage
        require(stg == Stage.Early || stg == Stage.Normal || stg == Stage.Closed);

        channelsSold = channelsSold.add(_venAmount);

        //should not exceed limit
        require(channelsSold <= channelsLimit);

        ven.mint(
            venVault,
            _venAmount,
            true  // unsold tokens can be claimed by channels portion
            );

        onSold(venVault, _venAmount, 0);
    }

    /// @notice initialize to prepare for sale
    /// @param _ven The address VEN token contract following ERC20 standard
    /// @param _ethVault The place to store received ETH
    /// @param _venVault The place to store non-publicly supplied VEN tokens
    /// @param _channelsLimit The hard limit for channels sale
    /// @param _startTime The time when sale starts
    /// @param _endTime The time when sale ends
    /// @param _earlyStageLasts duration of early stage
    function initialize(
        VEN _ven,
        address _ethVault,
        address _venVault,
        uint256 _channelsLimit,
        uint _startTime,
        uint _endTime,
        uint _earlyStageLasts) onlyOwner {
        require(stage() == Stage.Created);

        // ownership of token contract should already be this
        require(_ven.owner() == address(this));

        require(address(_ethVault) != 0);
        require(address(_venVault) != 0);

        require(_startTime > blockTime());
        require(_startTime.add(_earlyStageLasts) < _endTime);        

        ven = _ven;
        
        ethVault = _ethVault;
        venVault = _venVault;

        channelsLimit = _channelsLimit;
        officialLimit = publicSupply.sub(_channelsLimit);

        startTime = _startTime;
        endTime = _endTime;
        earlyStageLasts = _earlyStageLasts;        
        
        ven.mint(
            venVault,
            reservedForTeam.add(reservedForOperations),
            false // team and operations reserved portion can&#39;t share unsold tokens
        );

        ven.mint(
            venVault,
            privateSupply.add(commercialPlan),
            true // private ICO and commercial plan can share unsold tokens
        );

        initialized = true;
        onInitialized();
    }

    /// @notice finalize
    function finalize() onlyOwner {
        // only after closed stage
        require(stage() == Stage.Closed);       

        uint256 unsold = publicSupply.sub(officialSold_.get()).sub(channelsSold);

        if (unsold > 0) {
            // unsold VEN as bonus
            ven.offerBonus(unsold);        
        }
        ven.seal();

        finalized = true;
        onFinalized();
    }

    event onInitialized();
    event onFinalized();

    event onSold(address indexed buyer, uint256 venAmount, uint256 ethCost);
}