pragma solidity 0.4.24;

contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) public payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);

    /// @notice Notifies the controller about a token burn
    /// @param _owner The address of the burner
    /// @param _amount The amount to burn
    /// @return False if the controller does not authorize the burn
    function onBurn(address _owner, uint _amount) public returns(bool);
}
/*
    Copyright 2017, Will Harborne (Ethfinex)
*/
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

/// @dev The actual token contract, the default controller is the msg.sender
///  that deploys the contract, so usually this token will be deployed by a
///  token controller contract, which Giveth will call a "Campaign"
/// @dev The actual token contract, the default controller is the msg.sender
///  that deploys the contract, so usually this token will be deployed by a
///  token controller contract, which Giveth will call a "Campaign"
contract MiniMeToken is Controlled {

    string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = &#39;EFX_0.1&#39;; //An arbitrary versioning scheme


    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct  Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    MiniMeToken public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint public parentSnapShotBlock;

    // `creationBlock` is the block number that the Clone Token was created
    uint public creationBlock;

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

    // Tracks the history of the `pledgedFees` belonging to token holders
    Checkpoint[] totalPledgedFeesHistory; // in wei

    // The factory used to create new clone tokens
    MiniMeTokenFactory public tokenFactory;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a MiniMeToken
    /// @param _tokenFactory The address of the MiniMeTokenFactory contract that
    ///  will create the Clone token contracts, the token factory needs to be
    ///  deployed first
    /// @param _parentToken Address of the parent token, set to 0x0 if it is a
    ///  new token
    /// @param _parentSnapShotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token, set to 0 if it
    ///  is a new token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

    uint constant MAX_UINT = 2**256 - 1;

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! Confirm that you trust the
        //  controller of this contract, which in most situations should be
        //  another open source smart contract or 0x0
        if (msg.sender != controller) {
            require(transfersEnabled);

            // The standard ERC 20 transferFrom functionality
            if (allowed[_from][msg.sender] < MAX_UINT) {
                require(allowed[_from][msg.sender] >= _amount);
                allowed[_from][msg.sender] -= _amount;
            }
        }
        doTransfer(_from, _to, _amount);
        return true;
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount
    ) internal {

           if (_amount == 0) {
               Transfer(_from, _to, _amount);    // Follow the spec to louch the event when transfer 0
               return;
           }

           require(parentSnapShotBlock < block.number);

           // Do not allow transfer to 0x0 or the token contract itself
           require((_to != 0) && (_to != address(this)));

           // If the amount being transfered is more than the balance of the
           //  account the transfer throws
           var previousBalanceFrom = balanceOfAt(_from, block.number);

           require(previousBalanceFrom >= _amount);

           // Alerts the token controller of the transfer
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

           // First update the balance array with the new value for the address
           //  sending the tokens
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

           // Then update the balance array with the new value for the address
           //  receiving the tokens
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

           // An event to make the transfer easy to find on the blockchain
           Transfer(_from, _to, _amount);

    }

    /// @param _owner The address that&#39;s balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Query pledgedFees // in wei
////////////////

   /// @dev This function makes it easy to get the total pledged fees
   /// @return The total number of fees belonging to token holders
   function totalPledgedFees() public constant returns (uint) {
       return totalPledgedFeesAt(block.number);
   }

   /// @notice Total amount of fees at a specific `_blockNumber`.
   /// @param _blockNumber The block number when the totalPledgedFees is queried
   /// @return The total amount of pledged fees at `_blockNumber`
   function totalPledgedFeesAt(uint _blockNumber) public constant returns(uint) {

       // These next few lines are used when the totalPledgedFees of the token is
       //  requested before a check point was ever created for this token, it
       //  requires that the `parentToken.totalPledgedFeesAt` be queried at the
       //  genesis block for this token as that contains totalPledgedFees of this
       //  token at this block number.
       if ((totalPledgedFeesHistory.length == 0)
           || (totalPledgedFeesHistory[0].fromBlock > _blockNumber)) {
           if (address(parentToken) != 0) {
               return parentToken.totalPledgedFeesAt(min(_blockNumber, parentSnapShotBlock));
           } else {
               return 0;
           }

       // This will return the expected totalPledgedFees during normal situations
       } else {
           return getValueAt(totalPledgedFeesHistory, _blockNumber);
       }
   }

////////////////
// Pledge Fees To Token Holders or Reduce Pledged Fees // in wei
////////////////

   /// @notice Pledges fees to the token holders, later to be claimed by burning
   /// @param _value The amount sent to the vault by controller, reserved for token holders
   function pledgeFees(uint _value) public onlyController returns (bool) {
       uint curTotalFees = totalPledgedFees();
       require(curTotalFees + _value >= curTotalFees); // Check for overflow
       updateValueAtNow(totalPledgedFeesHistory, curTotalFees + _value);
       return true;
   }

   /// @notice Reduces pledged fees to the token holders, i.e. during upgrade or token burning
   /// @param _value The amount of pledged fees which are being distributed to token holders, reducing liability
   function reducePledgedFees(uint _value) public onlyController returns (bool) {
       uint curTotalFees = totalPledgedFees();
       require(curTotalFees >= _value);
       updateValueAtNow(totalPledgedFeesHistory, curTotalFees - _value);
       return true;
   }

////////////////
// Clone Token Method
////////////////

    /// @notice Creates a new clone token with the initial distribution being
    ///  this token at `_snapshotBlock`
    /// @param _cloneTokenName Name of the clone token
    /// @param _cloneDecimalUnits Number of decimals of the smallest unit
    /// @param _cloneTokenSymbol Symbol of the clone token
    /// @param _snapshotBlock Block when the distribution of the parent token is
    ///  copied to set the initial distribution of the new clone token;
    ///  if the block is zero than the actual block, the current block is used
    /// @param _transfersEnabled True if transfers are allowed in the clone
    /// @return The address of the new MiniMeToken Contract
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

        // An event to make the token easy to find on the blockchain
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////


    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    /// @notice The fallback function: If the contract&#39;s controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

////////////////
// Events
////////////////
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


////////////////
// MiniMeTokenFactory
////////////////

/// @dev This contract is used to generate clone contracts from a contract.
///  In solidity this is the way to create a contract from a contract of the
///  same class
contract MiniMeTokenFactory {

    /// @notice Update the DApp by creating a new token with new functionalities
    ///  the msg.sender becomes the controller of this clone token
    /// @param _parentToken Address of the token being cloned
    /// @param _snapshotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    /// @return The address of the new token contract
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

contract DestructibleMiniMeToken is MiniMeToken {

    address public terminator;

    constructor(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled,
        address _terminator
    ) public MiniMeToken(
        _tokenFactory,
        _parentToken,
        _parentSnapShotBlock,
        _tokenName,
        _decimalUnits,
        _tokenSymbol,
        _transfersEnabled
    ) {
        terminator = _terminator;
    }

    function recycle() public {
        require(msg.sender == terminator);
        selfdestruct(terminator);
    }
}

contract DestructibleMiniMeTokenFactory {

    /// @notice Update the DApp by creating a new token with new functionalities
    ///  the msg.sender becomes the controller of this clone token
    /// @param _parentToken Address of the token being cloned
    /// @param _snapshotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    /// @return The address of the new token contract
    function createDestructibleCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (DestructibleMiniMeToken) {
        DestructibleMiniMeToken newToken = new DestructibleMiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled,
            msg.sender
        );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

contract Ownable {
  
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/*
    Copyright 2018, Will Harborne @ Ethfinex
*/

/// @title ProposalManager Contract
/// @author Will Harborne @ Ethfinex
contract TokenListingManagerAdvanced is Ownable {

    address public constant NECTAR_TOKEN = 0xCc80C051057B774cD75067Dc48f8987C4Eb97A5e;
    address public constant TOKEN_FACTORY = 0x6EB97237B8bc26E8057793200207bB0a2A83C347;
    uint public constant MAX_CANDIDATES = 50;

    struct TokenProposal {
        uint startBlock;
        uint startTime;
        uint duration;
        address votingToken;
        // criteria values
        // 0. only first one win the vote;
        // 1. top N (number in extraData) win the vote;
        // 2. All over N (number in extra data) votes win the vote;
        uint criteria;
        uint extraData;
    }

    struct Delegate {
        address user;
        bytes32 storageHash;
        bool exists;
    }

    TokenProposal[] public tokenBatches;
    Delegate[] public allDelegates;
    mapping(address => uint) addressToDelegate;

    uint[] public yesVotes;
    address[] public consideredTokens;

    DestructibleMiniMeTokenFactory public tokenFactory;
    address public nectarToken;
    mapping(address => bool) public admins;
    mapping(address => bool) public isWinner;
    mapping(address => bool) public tokenExists;
    mapping(address => uint) public lastVote;

    mapping(address => address[]) public myVotes;
    mapping(address => address) public myDelegate;
    mapping(address => bool) public isDelegate;

    mapping(uint => mapping(address => uint256)) public votesSpentThisRound;

    modifier onlyAdmins() {
        require(isAdmin(msg.sender));
        _;
    }

    constructor(address _tokenFactory, address _nectarToken) public {
        tokenFactory = DestructibleMiniMeTokenFactory(_tokenFactory);
        nectarToken = _nectarToken;
        admins[msg.sender] = true;
        isDelegate[address(0)] = true;
    }

    /// @notice Admins are able to approve proposal that someone submitted
    /// @param _tokens the list of tokens in consideration during this period
    /// @param _duration number of days for voting
    /// @param _criteria number that determines how winner is selected
    /// @param _extraData extra data for criteria parameter
    /// @param _previousWinners addresses that won previous proposal
    function startTokenVotes(address[] _tokens, uint _duration, uint _criteria, uint _extraData, address[] _previousWinners) public onlyAdmins {
        require(_tokens.length <= MAX_CANDIDATES);

        for (uint i=0; i < _previousWinners.length; i++) {
            isWinner[_previousWinners[i]] = true;
        }

        if (_criteria == 1) {
            // in other case all tokens would be winners
            require(_extraData < consideredTokens.length);
        }

        uint _proposalId = tokenBatches.length;
        if (_proposalId > 0) {
            TokenProposal memory op = tokenBatches[_proposalId - 1];
            DestructibleMiniMeToken(op.votingToken).recycle();
        }
        tokenBatches.length++;
        TokenProposal storage p = tokenBatches[_proposalId];
        p.duration = _duration * (1 days);

        for (i = 0; i < _tokens.length; i++) {
            require(!tokenExists[_tokens[i]]);

            consideredTokens.push(_tokens[i]);
            yesVotes.push(0);
            lastVote[_tokens[i]] = _proposalId;
            tokenExists[_tokens[i]] = true;
        }

        p.votingToken = tokenFactory.createDestructibleCloneToken(
                nectarToken,
                getBlockNumber(),
                appendUintToString("EfxTokenVotes-", _proposalId),
                MiniMeToken(nectarToken).decimals(),
                appendUintToString("EVT-", _proposalId),
                true);

        p.startTime = now;
        p.startBlock = getBlockNumber();
        p.criteria = _criteria;
        p.extraData = _extraData;

        emit NewTokens(_proposalId);
    }

    /// @notice Vote for specific token with yes
    /// @param _tokenIndex is the position from 0-9 in the token array of the chosen token
    /// @param _amount number of votes you give for this token
    function vote(uint _tokenIndex, uint _amount) public {
        require(myDelegate[msg.sender] == address(0));
        require(!isWinner[consideredTokens[_tokenIndex]]);

        // voting only on the most recent set of proposed tokens
        require(tokenBatches.length > 0);
        uint _proposalId = tokenBatches.length - 1;

        require(isActive(_proposalId));

        TokenProposal memory p = tokenBatches[_proposalId];

        if (lastVote[consideredTokens[_tokenIndex]] < _proposalId) {
            // if voting for this token for first time in current proposal, we need to deduce votes
            // we deduce number of yes votes for diff of current proposal and lastVote time multiplied by 2
            yesVotes[_tokenIndex] /= 2*(_proposalId - lastVote[consideredTokens[_tokenIndex]]);
            lastVote[consideredTokens[_tokenIndex]] = _proposalId;
        }

        uint balance = DestructibleMiniMeToken(p.votingToken).balanceOf(msg.sender);

        // user is able to have someone in myVotes if he unregistered and some people didn&#39;t undelegated him after that
        if (isDelegate[msg.sender]) {
            for (uint i=0; i < myVotes[msg.sender].length; i++) {
                address user = myVotes[msg.sender][i];
                balance += DestructibleMiniMeToken(p.votingToken).balanceOf(user);
            }
        }

        require(_amount <= balance);
        require(votesSpentThisRound[_proposalId][msg.sender] + _amount <= balance);

        yesVotes[_tokenIndex] += _amount;
        // set the info that the user voted in this round
        votesSpentThisRound[_proposalId][msg.sender] += _amount;

        emit Vote(_proposalId, msg.sender, consideredTokens[_tokenIndex], _amount);
    }

    function unregisterAsDelegate() public {
        require(isDelegate[msg.sender]);

        address lastDelegate = allDelegates[allDelegates.length - 1].user;
        uint currDelegatePos = addressToDelegate[msg.sender];
        // set last delegate to new pos
        addressToDelegate[lastDelegate] = currDelegatePos;
        allDelegates[currDelegatePos] = allDelegates[allDelegates.length - 1];

        // delete this delegate
        delete allDelegates[allDelegates.length - 1];
        allDelegates.length--;

        // set bool to false
        isDelegate[msg.sender] = false;
    }

    function registerAsDelegate(bytes32 _storageHash) public {
        // can&#39;t register as delegate if already gave vote
        require(!gaveVote(msg.sender));
        // can&#39;t register as delegate if you have delegate (undelegate first)
        require(myDelegate[msg.sender] == address(0));
        // can&#39;t call this method if you are already delegate
        require(!isDelegate[msg.sender]);

        isDelegate[msg.sender] = true;
        allDelegates.push(Delegate({
            user: msg.sender,
            storageHash: _storageHash,
            exists: true
        }));

        addressToDelegate[msg.sender] = allDelegates.length-1;
    }

    function undelegateVote() public {
        // can&#39;t undelegate if I already gave vote in this round
        require(!gaveVote(msg.sender));
        // I must have delegate if I want to undelegate
        require(myDelegate[msg.sender] != address(0));

        address delegate = myDelegate[msg.sender];

        for (uint i=0; i < myVotes[delegate].length; i++) {
            if (myVotes[delegate][i] == msg.sender) {
                myVotes[delegate][i] = myVotes[delegate][myVotes[delegate].length-1];

                delete myVotes[delegate][myVotes[delegate].length-1];
                myVotes[delegate].length--;

                break;
            }
        }

        myDelegate[msg.sender] = address(0);
    }

    /// @notice Delegate vote to other address
    /// @param _to address who will be able to vote instead of you
    function delegateVote(address _to) public {
        // not possible to delegate if I already voted
        require(!gaveVote(msg.sender));
        // can&#39;t set delegate if I am delegate
        require(!isDelegate[msg.sender]);
        // I can only set delegate to someone who is registered delegate
        require(isDelegate[_to]);
        // I can&#39;t have delegate if I&#39;m setting one (call undelegate first)
        require(myDelegate[msg.sender] == address(0));

        myDelegate[msg.sender] = _to;
        myVotes[_to].push(msg.sender);
    }

    function delegateCount() public view returns(uint) {
        return allDelegates.length;
    }

    function getWinners() public view returns(address[] winners) {
        require(tokenBatches.length > 0);
        uint _proposalId = tokenBatches.length - 1;

        TokenProposal memory p = tokenBatches[_proposalId];

        // there is only one winner in criteria 0
        if (p.criteria == 0) {
            winners = new address[](1);
            uint max = 0;

            for (uint i=0; i < consideredTokens.length; i++) {
                if (isWinner[consideredTokens[i]]) {
                    continue;
                }

                if (isWinner[consideredTokens[max]]) {
                    max = i;
                }

                if (getCurrentVotes(i) > getCurrentVotes(max)) {
                    max = i;
                }
            }

            winners[0] = consideredTokens[max];
        }

        // there is N winners in criteria 1
        if (p.criteria == 1) {
            uint count = 0;
            uint[] memory indexesWithMostVotes = new uint[](p.extraData);
            winners = new address[](p.extraData);

            // for each token we check if he has more votes than last one,
            // if it has we put it in array and always keep array sorted
            for (i = 0; i < consideredTokens.length; i++) {
                if (isWinner[consideredTokens[i]]) {
                    continue;
                }
                if (count < p.extraData) {
                    indexesWithMostVotes[count] = i;
                    count++;
                    continue;
                }

                // so we just do it once, sort all in descending order
                if (count == p.extraData) {
                    for (j = 0; j < indexesWithMostVotes.length; j++) {
                        for (uint k = j+1; k < indexesWithMostVotes.length; k++) {
                            if (getCurrentVotes(indexesWithMostVotes[j]) < getCurrentVotes(indexesWithMostVotes[k])) {
                                uint help = indexesWithMostVotes[j];
                                indexesWithMostVotes[j] = indexesWithMostVotes[k];
                                indexesWithMostVotes[k] = help;
                            }
                        }
                    }
                }

                uint last = p.extraData - 1;
                if (getCurrentVotes(i) > getCurrentVotes(indexesWithMostVotes[last])) {
                    indexesWithMostVotes[last] = i;

                    for (uint j=last; j > 0; j--) {
                        if (getCurrentVotes(indexesWithMostVotes[j]) > getCurrentVotes(indexesWithMostVotes[j-1])) {
                            help = indexesWithMostVotes[j];
                            indexesWithMostVotes[j] = indexesWithMostVotes[j-1];
                            indexesWithMostVotes[j-1] = help;
                        }
                    }
                }
            }

            for (i = 0; i < p.extraData; i++) {
                winners[i] = consideredTokens[indexesWithMostVotes[i]];
            }
        }

        // everybody who has over N votes are winners in criteria 2
        if (p.criteria == 2) {
            uint numOfTokens = 0;
            for (i = 0; i < consideredTokens.length; i++) {
                if (isWinner[consideredTokens[i]]) {
                    continue;
                }
                if (getCurrentVotes(i) > p.extraData) {
                    numOfTokens++;
                }
            }

            winners = new address[](numOfTokens);
            count = 0;
            for (i = 0; i < consideredTokens.length; i++) {
                if (isWinner[consideredTokens[i]]) {
                    continue;
                }
                if (getCurrentVotes(i) > p.extraData) {
                    winners[count] = consideredTokens[i];
                    count++;
                }
            }
        }
    }

    /// @notice Get number of proposals so you can know which is the last one
    function numberOfProposals() public view returns(uint) {
        return tokenBatches.length;
    }

    /// @notice Any admin is able to add new admin
    /// @param _newAdmin Address of new admin
    function addAdmin(address _newAdmin) public onlyAdmins {
        admins[_newAdmin] = true;
    }

    /// @notice Only owner is able to remove admin
    /// @param _admin Address of current admin
    function removeAdmin(address _admin) public onlyOwner {
        admins[_admin] = false;
    }

    /// @notice Get data about specific proposal
    /// @param _proposalId Id of proposal
    function proposal(uint _proposalId) public view returns(
        uint _startBlock,
        uint _startTime,
        uint _duration,
        bool _active,
        bool _finalized,
        uint[] _votes,
        address[] _tokens,
        address _votingToken,
        bool _hasBalance
    ) {
        require(_proposalId < tokenBatches.length);

        TokenProposal memory p = tokenBatches[_proposalId];
        _startBlock = p.startBlock;
        _startTime = p.startTime;
        _duration = p.duration;
        _finalized = (_startTime+_duration < now);
        _active = isActive(_proposalId);
        _votes = getVotes();
        _tokens = getConsideredTokens();
        _votingToken = p.votingToken;
        _hasBalance = (p.votingToken == 0x0) ? false : (DestructibleMiniMeToken(p.votingToken).balanceOf(msg.sender) > 0);
    }

    function getConsideredTokens() public view returns(address[] tokens) {
        tokens = new address[](consideredTokens.length);

        for (uint i = 0; i < consideredTokens.length; i++) {
            if (!isWinner[consideredTokens[i]]) {
                tokens[i] = consideredTokens[i];
            } else {
                tokens[i] = address(0);
            }
        }
    }

    function getVotes() public view returns(uint[] votes) {
        votes = new uint[](consideredTokens.length);

        for (uint i = 0; i < consideredTokens.length; i++) {
            votes[i] = getCurrentVotes(i);
        }
    }

    function getCurrentVotes(uint index) public view returns(uint) {
        require(tokenBatches.length > 0);

        uint _proposalId = tokenBatches.length - 1;
        uint vote = yesVotes[index];
        if (_proposalId > lastVote[consideredTokens[index]]) {
            vote = yesVotes[index] / (2 * (_proposalId - lastVote[consideredTokens[index]]));
        }

        return vote;
    }

    function isAdmin(address _admin) public view returns(bool) {
        return admins[_admin];
    }

    function proxyPayment(address ) public payable returns(bool) {
        return false;
    }

    // only users that didn&#39;t gave vote in current round can transfer tokens
    function onTransfer(address _from, address _to, uint _amount) public view returns(bool) {
        return !gaveVote(_from);
    }

    function onApprove(address, address, uint ) public pure returns(bool) {
        return true;
    }

    function gaveVote(address _user) public view returns(bool) {
        if (tokenBatches.length == 0) return false;

        uint _proposalId = tokenBatches.length - 1;

        if (votesSpentThisRound[_proposalId][myDelegate[_user]] + votesSpentThisRound[_proposalId][_user] > 0 ) {
            return true;
        } else {
            return false;
        }
    }

    function getBlockNumber() internal constant returns (uint) {
        return block.number;
    }

    function isActive(uint id) internal view returns (bool) {
        TokenProposal memory p = tokenBatches[id];
        bool _finalized = (p.startTime + p.duration < now);
        return !_finalized && (p.startBlock < getBlockNumber());
    }

    function appendUintToString(string inStr, uint v) private pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        if (v == 0) {
            reversed[i++] = byte(48);
        } else {
            while (v != 0) {
                uint remainder = v % 10;
                v = v / 10;
                reversed[i++] = byte(48 + remainder);
            }
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    event Vote(uint indexed idProposal, address indexed _voter, address chosenToken, uint amount);
    event NewTokens(uint indexed idProposal);
}