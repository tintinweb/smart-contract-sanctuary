/**
 *  @title Kleros
 *  @author Cl&#233;ment Lesaege - <<span class="__cf_email__" data-cfemail="02616e676f676c76426e6771636765672c616d6f">[email&#160;protected]</span>>
 *  This code implements a simple version of Kleros.
 *  Bug Bounties: This code hasn&#39;t undertaken a bug bounty program yet.
 */

pragma solidity ^0.4.24;


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

/// @dev The token controller contract must implement these functions
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
}

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

/// @dev The actual token contract, the default controller is the msg.sender
///  that deploys the contract, so usually this token will be deployed by a
///  token controller contract, which Giveth will call a "Campaign"
contract Pinakion is Controlled {

    string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = &#39;MMT_0.2&#39;; //An arbitrary versioning scheme


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
    Pinakion public parentToken;

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

    // The factory used to create new clone tokens
    MiniMeTokenFactory public tokenFactory;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a Pinakion
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
    function Pinakion(
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
        parentToken = Pinakion(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

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
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
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
    ///  its behalf. This is the standard version to allow backward compatibility.
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

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
        Pinakion cloneToken = tokenFactory.createCloneToken(
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

        Pinakion token = Pinakion(_token);
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
    ) public returns (Pinakion) {
        Pinakion newToken = new Pinakion(
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

contract RNG{

    /** @dev Contribute to the reward of a random number.
     *  @param _block Block the random number is linked to.
     */
    function contribute(uint _block) public payable;

    /** @dev Request a random number.
     *  @param _block Block linked to the request.
     */
    function requestRN(uint _block) public payable {
        contribute(_block);
    }

    /** @dev Get the random number.
     *  @param _block Block the random number is linked to.
     *  @return RN Random Number. If the number is not ready or has not been required 0 instead.
     */
    function getRN(uint _block) public returns (uint RN);

    /** @dev Get a uncorrelated random number. Act like getRN but give a different number for each sender.
     *  This is to prevent users from getting correlated numbers.
     *  @param _block Block the random number is linked to.
     *  @return RN Random Number. If the number is not ready or has not been required 0 instead.
     */
    function getUncorrelatedRN(uint _block) public returns (uint RN) {
        uint baseRN=getRN(_block);
        if (baseRN==0)
            return 0;
        else
            return uint(keccak256(msg.sender,baseRN));
    }

 }

/** Simple Random Number Generator returning the blockhash.
 *  Allows saving the random number for use in the future.
 *  It allows the contract to still access the blockhash even after 256 blocks.
 *  The first party to call the save function gets the reward.
 */
contract BlockHashRNG is RNG {

    mapping (uint => uint) public randomNumber; // randomNumber[block] is the random number for this block, 0 otherwise.
    mapping (uint => uint) public reward; // reward[block] is the amount to be paid to the party w.



    /** @dev Contribute to the reward of a random number.
     *  @param _block Block the random number is linked to.
     */
    function contribute(uint _block) public payable { reward[_block]+=msg.value; }


    /** @dev Return the random number. If it has not been saved and is still computable compute it.
     *  @param _block Block the random number is linked to.
     *  @return RN Random Number. If the number is not ready or has not been requested 0 instead.
     */
    function getRN(uint _block) public returns (uint RN) {
        RN=randomNumber[_block];
        if (RN==0){
            saveRN(_block);
            return randomNumber[_block];
        }
        else
            return RN;
    }

    /** @dev Save the random number for this blockhash and give the reward to the caller.
     *  @param _block Block the random number is linked to.
     */
    function saveRN(uint _block) public {
        if (blockhash(_block) != 0x0)
            randomNumber[_block] = uint(blockhash(_block));
        if (randomNumber[_block] != 0) { // If the number is set.
            uint rewardToSend = reward[_block];
            reward[_block] = 0;
            msg.sender.send(rewardToSend); // Note that the use of send is on purpose as we don&#39;t want to block in case msg.sender has a fallback issue.
        }
    }

}


/** Random Number Generator returning the blockhash with a backup behaviour.
 *  Allows saving the random number for use in the future. 
 *  It allows the contract to still access the blockhash even after 256 blocks.
 *  The first party to call the save function gets the reward.
 *  If no one calls the contract within 256 blocks, the contract fallback in returning the blockhash of the previous block.
 */
contract BlockHashRNGFallback is BlockHashRNG {
    
    /** @dev Save the random number for this blockhash and give the reward to the caller.
     *  @param _block Block the random number is linked to.
     */
    function saveRN(uint _block) public {
        if (_block<block.number && randomNumber[_block]==0) {// If the random number is not already set and can be.
            if (blockhash(_block)!=0x0) // Normal case.
                randomNumber[_block]=uint(blockhash(_block));
            else // The contract was not called in time. Fallback to returning previous blockhash.
                randomNumber[_block]=uint(blockhash(block.number-1));
        }
        if (randomNumber[_block] != 0) { // If the random number is set.
            uint rewardToSend=reward[_block];
            reward[_block]=0;
            msg.sender.send(rewardToSend); // Note that the use of send is on purpose as we don&#39;t want to block in case the msg.sender has a fallback issue.
        }
    }
    
}

/** @title Arbitrable
 *  Arbitrable abstract contract.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
contract Arbitrable{
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData; // Extra data to require particular dispute and appeal behaviour.

    modifier onlyArbitrator {require(msg.sender==address(arbitrator)); _;}

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

    /** @dev To be emmited when meta-evidence is submitted.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

    /** @dev To be emmited when a dispute is created to link the correct meta-evidence to the disputeID
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     */
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID);

    /** @dev To be raised when evidence are submitted. Should point to the ressource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _disputeID, address _party, string _evidence);

    /** @dev Constructor. Choose the arbitrator.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     */
    constructor(Arbitrator _arbitrator, bytes _arbitratorExtraData) public {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) public onlyArbitrator {
        emit Ruling(Arbitrator(msg.sender),_disputeID,_ruling);

        executeRuling(_disputeID,_ruling);
    }


    /** @dev Execute a ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function executeRuling(uint _disputeID, uint _ruling) internal;
}

/** @title Arbitrator
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don&#39;t forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID,ruling).
 */
contract Arbitrator{

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes _extraData) {require(msg.value>=arbitrationCost(_extraData)); _;}
    modifier requireAppealFee(uint _disputeID, bytes _extraData) {require(msg.value>=appealCost(_disputeID, _extraData)); _;}

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     */
    event AppealPossible(uint _disputeID);

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint indexed _disputeID, Arbitrable _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint indexed _disputeID, Arbitrable _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID)  {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes _extraData) public constant returns(uint fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes _extraData) public constant returns(uint fee);

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public constant returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint _disputeID) public constant returns(uint ruling);

}



contract Kleros is Arbitrator, ApproveAndCallFallBack {

    // **************************** //
    // *    Contract variables    * //
    // **************************** //

    // Variables which should not change after initialization.
    Pinakion public pinakion;
    uint public constant NON_PAYABLE_AMOUNT = (2**256 - 2) / 2; // An astronomic amount, practically can&#39;t be paid.

    // Variables which will subject to the governance mechanism.
    // Note they will only be able to be changed during the activation period (because a session assumes they don&#39;t change after it).
    RNG public rng; // Random Number Generator used to draw jurors.
    uint public arbitrationFeePerJuror = 0.05 ether; // The fee which will be paid to each juror.
    uint16 public defaultNumberJuror = 3; // Number of drawn jurors unless specified otherwise.
    uint public minActivatedToken = 0.1 * 1e18; // Minimum of tokens to be activated (in basic units).
    uint[5] public timePerPeriod; // The minimum time each period lasts (seconds).
    uint public alpha = 2000; // alpha in ‱ (1 / 10 000).
    uint constant ALPHA_DIVISOR = 1e4; // Amount we need to divided alpha in ‱ to get the float value of alpha.
    uint public maxAppeals = 5; // Number of times a dispute can be appealed. When exceeded appeal cost becomes NON_PAYABLE_AMOUNT.
    // Initially, the governor will be an address controlled by the Kleros team. At a later stage,
    // the governor will be switched to a governance contract with liquid voting.
    address public governor; // Address of the governor contract.

    // Variables changing during day to day interaction.
    uint public session = 1;      // Current session of the court.
    uint public lastPeriodChange; // The last time we changed of period (seconds).
    uint public segmentSize;      // Size of the segment of activated tokens.
    uint public rnBlock;          // The block linked with the RN which is requested.
    uint public randomNumber;     // Random number of the session.

    enum Period {
        Activation, // When juror can deposit their tokens and parties give evidences.
        Draw,       // When jurors are drawn at random, note that this period is fast.
        Vote,       // Where jurors can vote on disputes.
        Appeal,     // When parties can appeal the rulings.
        Execution   // When where token redistribution occurs and Kleros call the arbitrated contracts.
    }

    Period public period;

    struct Juror {
        uint balance;      // The amount of tokens the contract holds for this juror.
        uint atStake;      // Total number of tokens the jurors can loose in disputes they are drawn in. Those tokens are locked. Note that we can have atStake > balance but it should be statistically unlikely and does not pose issues.
        uint lastSession;  // Last session the tokens were activated.
        uint segmentStart; // Start of the segment of activated tokens.
        uint segmentEnd;   // End of the segment of activated tokens.
    }

    mapping (address => Juror) public jurors;

    struct Vote {
        address account; // The juror who casted the vote.
        uint ruling;     // The ruling which was given.
    }

    struct VoteCounter {
        uint winningChoice; // The choice which currently has the highest amount of votes. Is 0 in case of a tie.
        uint winningCount;  // The number of votes for winningChoice. Or for the choices which are tied.
        mapping (uint => uint) voteCount; // voteCount[choice] is the number of votes for choice.
    }

    enum DisputeState {
        Open,       // The dispute is opened but the outcome is not available yet (this include when jurors voted but appeal is still possible).
        Resolving,  // The token repartition has started. Note that if it&#39;s done in just one call, this state is skipped.
        Executable, // The arbitrated contract can be called to enforce the decision.
        Executed    // Everything has been done and the dispute can&#39;t be interacted with anymore.
    }

    struct Dispute {
        Arbitrable arbitrated;       // Contract to be arbitrated.
        uint session;                // First session the dispute was schedule.
        uint appeals;                // Number of appeals.
        uint choices;                // The number of choices available to the jurors.
        uint16 initialNumberJurors;  // The initial number of jurors.
        uint arbitrationFeePerJuror; // The fee which will be paid to each juror.
        DisputeState state;          // The state of the dispute.
        Vote[][] votes;              // The votes in the form vote[appeals][voteID].
        VoteCounter[] voteCounter;   // The vote counters in the form voteCounter[appeals].
        mapping (address => uint) lastSessionVote; // Last session a juror has voted on this dispute. Is 0 if he never did.
        uint currentAppealToRepartition; // The current appeal we are repartitioning.
        AppealsRepartitioned[] appealsRepartitioned; // Track a partially repartitioned appeal in the form AppealsRepartitioned[appeal].
    }

    enum RepartitionStage { // State of the token repartition if oneShotTokenRepartition would throw because there are too many votes.
        Incoherent,
        Coherent,
        AtStake,
        Complete
    }

    struct AppealsRepartitioned {
        uint totalToRedistribute;   // Total amount of tokens we have to redistribute.
        uint nbCoherent;            // Number of coherent jurors for session.
        uint currentIncoherentVote; // Current vote for the incoherent loop.
        uint currentCoherentVote;   // Current vote we need to count.
        uint currentAtStakeVote;    // Current vote we need to count.
        RepartitionStage stage;     // Use with multipleShotTokenRepartition if oneShotTokenRepartition would throw.
    }

    Dispute[] public disputes;

    // **************************** //
    // *          Events          * //
    // **************************** //

    /** @dev Emitted when we pass to a new period.
     *  @param _period The new period.
     *  @param _session The current session.
     */
    event NewPeriod(Period _period, uint indexed _session);

    /** @dev Emitted when a juror wins or loses tokens.
      * @param _account The juror affected.
      * @param _disputeID The ID of the dispute.
      * @param _amount The amount of parts of token which was won. Can be negative for lost amounts.
      */
    event TokenShift(address indexed _account, uint _disputeID, int _amount);

    /** @dev Emited when a juror wins arbitration fees.
      * @param _account The account affected.
      * @param _disputeID The ID of the dispute.
      * @param _amount The amount of weis which was won.
      */
    event ArbitrationReward(address indexed _account, uint _disputeID, uint _amount);

    // **************************** //
    // *         Modifiers        * //
    // **************************** //
    modifier onlyBy(address _account) {require(msg.sender == _account); _;}
    modifier onlyDuring(Period _period) {require(period == _period); _;}
    modifier onlyGovernor() {require(msg.sender == governor); _;}


    /** @dev Constructor.
     *  @param _pinakion The address of the pinakion contract.
     *  @param _rng The random number generator which will be used.
     *  @param _timePerPeriod The minimal time for each period (seconds).
     *  @param _governor Address of the governor contract.
     */
    constructor(Pinakion _pinakion, RNG _rng, uint[5] _timePerPeriod, address _governor) public {
        pinakion = _pinakion;
        rng = _rng;
        lastPeriodChange = now;
        timePerPeriod = _timePerPeriod;
        governor = _governor;
    }

    // **************************** //
    // *  Functions interacting   * //
    // *  with Pinakion contract  * //
    // **************************** //

    /** @dev Callback of approveAndCall - transfer pinakions of a juror in the contract. Should be called by the pinakion contract. TRUSTED.
     *  @param _from The address making the transfer.
     *  @param _amount Amount of tokens to transfer to Kleros (in basic units).
     */
    function receiveApproval(address _from, uint _amount, address, bytes) public onlyBy(pinakion) {
        require(pinakion.transferFrom(_from, this, _amount));

        jurors[_from].balance += _amount;
    }

    /** @dev Withdraw tokens. Note that we can&#39;t withdraw the tokens which are still atStake. 
     *  Jurors can&#39;t withdraw their tokens if they have deposited some during this session.
     *  This is to prevent jurors from withdrawing tokens they could loose.
     *  @param _value The amount to withdraw.
     */
    function withdraw(uint _value) public {
        Juror storage juror = jurors[msg.sender];
        require(juror.atStake <= juror.balance); // Make sure that there is no more at stake than owned to avoid overflow.
        require(_value <= juror.balance-juror.atStake);
        require(juror.lastSession != session);

        juror.balance -= _value;
        require(pinakion.transfer(msg.sender,_value));
    }

    // **************************** //
    // *      Court functions     * //
    // *    Modifying the state   * //
    // **************************** //

    /** @dev To call to go to a new period. TRUSTED.
     */
    function passPeriod() public {
        require(now-lastPeriodChange >= timePerPeriod[uint8(period)]);

        if (period == Period.Activation) {
            rnBlock = block.number + 1;
            rng.requestRN(rnBlock);
            period = Period.Draw;
        } else if (period == Period.Draw) {
            randomNumber = rng.getUncorrelatedRN(rnBlock);
            require(randomNumber != 0);
            period = Period.Vote;
        } else if (period == Period.Vote) {
            period = Period.Appeal;
        } else if (period == Period.Appeal) {
            period = Period.Execution;
        } else if (period == Period.Execution) {
            period = Period.Activation;
            ++session;
            segmentSize = 0;
            rnBlock = 0;
            randomNumber = 0;
        }


        lastPeriodChange = now;
        NewPeriod(period, session);
    }


    /** @dev Deposit tokens in order to have chances of being drawn. Note that once tokens are deposited, 
     *  there is no possibility of depositing more.
     *  @param _value Amount of tokens (in basic units) to deposit.
     */
    function activateTokens(uint _value) public onlyDuring(Period.Activation) {
        Juror storage juror = jurors[msg.sender];
        require(_value <= juror.balance);
        require(_value >= minActivatedToken);
        require(juror.lastSession != session); // Verify that tokens were not already activated for this session.

        juror.lastSession = session;
        juror.segmentStart = segmentSize;
        segmentSize += _value;
        juror.segmentEnd = segmentSize;

    }

    /** @dev Vote a ruling. Juror must input the draw ID he was drawn.
     *  Note that the complexity is O(d), where d is amount of times the juror was drawn.
     *  Since being drawn multiple time is a rare occurrence and that a juror can always vote with less weight than it has, it is not a problem.
     *  But note that it can lead to arbitration fees being kept by the contract and never distributed.
     *  @param _disputeID The ID of the dispute the juror was drawn.
     *  @param _ruling The ruling given.
     *  @param _draws The list of draws the juror was drawn. Draw numbering starts at 1 and the numbers should be increasing.
     */
    function voteRuling(uint _disputeID, uint _ruling, uint[] _draws) public onlyDuring(Period.Vote) {
        Dispute storage dispute = disputes[_disputeID];
        Juror storage juror = jurors[msg.sender];
        VoteCounter storage voteCounter = dispute.voteCounter[dispute.appeals];
        require(dispute.lastSessionVote[msg.sender] != session); // Make sure juror hasn&#39;t voted yet.
        require(_ruling <= dispute.choices);
        // Note that it throws if the draws are incorrect.
        require(validDraws(msg.sender, _disputeID, _draws));

        dispute.lastSessionVote[msg.sender] = session;
        voteCounter.voteCount[_ruling] += _draws.length;
        if (voteCounter.winningCount < voteCounter.voteCount[_ruling]) {
            voteCounter.winningCount = voteCounter.voteCount[_ruling];
            voteCounter.winningChoice = _ruling;
        } else if (voteCounter.winningCount==voteCounter.voteCount[_ruling] && _draws.length!=0) { // Verify draw length to be non-zero to avoid the possibility of setting tie by casting 0 votes.
            voteCounter.winningChoice = 0; // It&#39;s currently a tie.
        }
        for (uint i = 0; i < _draws.length; ++i) {
            dispute.votes[dispute.appeals].push(Vote({
                account: msg.sender,
                ruling: _ruling
            }));
        }

        juror.atStake += _draws.length * getStakePerDraw();
        uint feeToPay = _draws.length * dispute.arbitrationFeePerJuror;
        msg.sender.transfer(feeToPay);
        ArbitrationReward(msg.sender, _disputeID, feeToPay);
    }

    /** @dev Steal part of the tokens and the arbitration fee of a juror who failed to vote.
     *  Note that a juror who voted but without all his weight can&#39;t be penalized.
     *  It is possible to not penalize with the maximum weight.
     *  But note that it can lead to arbitration fees being kept by the contract and never distributed.
     *  @param _jurorAddress Address of the juror to steal tokens from.
     *  @param _disputeID The ID of the dispute the juror was drawn.
     *  @param _draws The list of draws the juror was drawn. Numbering starts at 1 and the numbers should be increasing.
     */
    function penalizeInactiveJuror(address _jurorAddress, uint _disputeID, uint[] _draws) public {
        Dispute storage dispute = disputes[_disputeID];
        Juror storage inactiveJuror = jurors[_jurorAddress];
        require(period > Period.Vote);
        require(dispute.lastSessionVote[_jurorAddress] != session); // Verify the juror hasn&#39;t voted.
        dispute.lastSessionVote[_jurorAddress] = session; // Update last session to avoid penalizing multiple times.
        require(validDraws(_jurorAddress, _disputeID, _draws));
        uint penality = _draws.length * minActivatedToken * 2 * alpha / ALPHA_DIVISOR;
        penality = (penality < inactiveJuror.balance) ? penality : inactiveJuror.balance; // Make sure the penality is not higher than the balance.
        inactiveJuror.balance -= penality;
        TokenShift(_jurorAddress, _disputeID, -int(penality));
        jurors[msg.sender].balance += penality / 2; // Give half of the penalty to the caller.
        TokenShift(msg.sender, _disputeID, int(penality / 2));
        jurors[governor].balance += penality / 2; // The other half to the governor.
        TokenShift(governor, _disputeID, int(penality / 2));
        msg.sender.transfer(_draws.length*dispute.arbitrationFeePerJuror); // Give the arbitration fees to the caller.
    }

    /** @dev Execute all the token repartition.
     *  Note that this function could consume to much gas if there is too much votes. 
     *  It is O(v), where v is the number of votes for this dispute.
     *  In the next version, there will also be a function to execute it in multiple calls 
     *  (but note that one shot execution, if possible, is less expensive).
     *  @param _disputeID ID of the dispute.
     */
    function oneShotTokenRepartition(uint _disputeID) public onlyDuring(Period.Execution) {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.state == DisputeState.Open);
        require(dispute.session+dispute.appeals <= session);

        uint winningChoice = dispute.voteCounter[dispute.appeals].winningChoice;
        uint amountShift = getStakePerDraw();
        for (uint i = 0; i <= dispute.appeals; ++i) {
            // If the result is not a tie, some parties are incoherent. Note that 0 (refuse to arbitrate) winning is not a tie.
            // Result is a tie if the winningChoice is 0 (refuse to arbitrate) and the choice 0 is not the most voted choice.
            // Note that in case of a "tie" among some choices including 0, parties who did not vote 0 are considered incoherent.
            if (winningChoice!=0 || (dispute.voteCounter[dispute.appeals].voteCount[0] == dispute.voteCounter[dispute.appeals].winningCount)) {
                uint totalToRedistribute = 0;
                uint nbCoherent = 0;
                // First loop to penalize the incoherent votes.
                for (uint j = 0; j < dispute.votes[i].length; ++j) {
                    Vote storage vote = dispute.votes[i][j];
                    if (vote.ruling != winningChoice) {
                        Juror storage juror = jurors[vote.account];
                        uint penalty = amountShift<juror.balance ? amountShift : juror.balance;
                        juror.balance -= penalty;
                        TokenShift(vote.account, _disputeID, int(-penalty));
                        totalToRedistribute += penalty;
                    } else {
                        ++nbCoherent;
                    }
                }
                if (nbCoherent == 0) { // No one was coherent at this stage. Give the tokens to the governor.
                    jurors[governor].balance += totalToRedistribute;
                    TokenShift(governor, _disputeID, int(totalToRedistribute));
                } else { // otherwise, redistribute them.
                    uint toRedistribute = totalToRedistribute / nbCoherent; // Note that few fractions of tokens can be lost but due to the high amount of decimals we don&#39;t care.
                    // Second loop to redistribute.
                    for (j = 0; j < dispute.votes[i].length; ++j) {
                        vote = dispute.votes[i][j];
                        if (vote.ruling == winningChoice) {
                            juror = jurors[vote.account];
                            juror.balance += toRedistribute;
                            TokenShift(vote.account, _disputeID, int(toRedistribute));
                        }
                    }
                }
            }
            // Third loop to lower the atStake in order to unlock tokens.
            for (j = 0; j < dispute.votes[i].length; ++j) {
                vote = dispute.votes[i][j];
                juror = jurors[vote.account];
                juror.atStake -= amountShift; // Note that it can&#39;t underflow due to amountShift not changing between vote and redistribution.
            }
        }
        dispute.state = DisputeState.Executable; // Since it was solved in one shot, go directly to the executable step.
    }

    /** @dev Execute token repartition on a dispute for a specific number of votes.
     *  This should only be called if oneShotTokenRepartition will throw because there are too many votes (will use too much gas).
     *  Note that There are 3 iterations per vote. e.g. A dispute with 1 appeal (2 sessions) and 3 votes per session will have 18 iterations
     *  @param _disputeID ID of the dispute.
     *  @param _maxIterations the maxium number of votes to repartition in this iteration
     */
    function multipleShotTokenRepartition(uint _disputeID, uint _maxIterations) public onlyDuring(Period.Execution) {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.state <= DisputeState.Resolving);
        require(dispute.session+dispute.appeals <= session);
        dispute.state = DisputeState.Resolving; // Mark as resolving so oneShotTokenRepartition cannot be called on dispute.

        uint winningChoice = dispute.voteCounter[dispute.appeals].winningChoice;
        uint amountShift = getStakePerDraw();
        uint currentIterations = 0; // Total votes we have repartitioned this iteration.
        for (uint i = dispute.currentAppealToRepartition; i <= dispute.appeals; ++i) {
            // Allocate space for new AppealsRepartitioned.
            if (dispute.appealsRepartitioned.length < i+1) {
                dispute.appealsRepartitioned.length++;
            }

            // If the result is a tie, no parties are incoherent and no need to move tokens. Note that 0 (refuse to arbitrate) winning is not a tie.
            if (winningChoice==0 && (dispute.voteCounter[dispute.appeals].voteCount[0] != dispute.voteCounter[dispute.appeals].winningCount)) {
                // If ruling is a tie we can skip to at stake.
                dispute.appealsRepartitioned[i].stage = RepartitionStage.AtStake;
            }

            // First loop to penalize the incoherent votes.
            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.Incoherent) {
                for (uint j = dispute.appealsRepartitioned[i].currentIncoherentVote; j < dispute.votes[i].length; ++j) {
                    if (currentIterations >= _maxIterations) {
                        return;
                    }
                    Vote storage vote = dispute.votes[i][j];
                    if (vote.ruling != winningChoice) {
                        Juror storage juror = jurors[vote.account];
                        uint penalty = amountShift<juror.balance ? amountShift : juror.balance;
                        juror.balance -= penalty;
                        TokenShift(vote.account, _disputeID, int(-penalty));
                        dispute.appealsRepartitioned[i].totalToRedistribute += penalty;
                    } else {
                        ++dispute.appealsRepartitioned[i].nbCoherent;
                    }

                    ++dispute.appealsRepartitioned[i].currentIncoherentVote;
                    ++currentIterations;
                }

                dispute.appealsRepartitioned[i].stage = RepartitionStage.Coherent;
            }

            // Second loop to reward coherent voters
            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.Coherent) {
                if (dispute.appealsRepartitioned[i].nbCoherent == 0) { // No one was coherent at this stage. Give the tokens to the governor.
                    jurors[governor].balance += dispute.appealsRepartitioned[i].totalToRedistribute;
                    TokenShift(governor, _disputeID, int(dispute.appealsRepartitioned[i].totalToRedistribute));
                    dispute.appealsRepartitioned[i].stage = RepartitionStage.AtStake;
                } else { // Otherwise, redistribute them.
                    uint toRedistribute = dispute.appealsRepartitioned[i].totalToRedistribute / dispute.appealsRepartitioned[i].nbCoherent; // Note that few fractions of tokens can be lost but due to the high amount of decimals we don&#39;t care.
                    // Second loop to redistribute.
                    for (j = dispute.appealsRepartitioned[i].currentCoherentVote; j < dispute.votes[i].length; ++j) {
                        if (currentIterations >= _maxIterations) {
                            return;
                        }
                        vote = dispute.votes[i][j];
                        if (vote.ruling == winningChoice) {
                            juror = jurors[vote.account];
                            juror.balance += toRedistribute;
                            TokenShift(vote.account, _disputeID, int(toRedistribute));
                        }

                        ++currentIterations;
                        ++dispute.appealsRepartitioned[i].currentCoherentVote;
                    }

                    dispute.appealsRepartitioned[i].stage = RepartitionStage.AtStake;
                }
            }

            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.AtStake) {
                // Third loop to lower the atStake in order to unlock tokens.
                for (j = dispute.appealsRepartitioned[i].currentAtStakeVote; j < dispute.votes[i].length; ++j) {
                    if (currentIterations >= _maxIterations) {
                        return;
                    }
                    vote = dispute.votes[i][j];
                    juror = jurors[vote.account];
                    juror.atStake -= amountShift; // Note that it can&#39;t underflow due to amountShift not changing between vote and redistribution.

                    ++currentIterations;
                    ++dispute.appealsRepartitioned[i].currentAtStakeVote;
                }

                dispute.appealsRepartitioned[i].stage = RepartitionStage.Complete;
            }

            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.Complete) {
                ++dispute.currentAppealToRepartition;
            }
        }

        dispute.state = DisputeState.Executable;
    }

    // **************************** //
    // *      Court functions     * //
    // *     Constant and Pure    * //
    // **************************** //

    /** @dev Return the amount of jurors which are or will be drawn in the dispute.
     *  The number of jurors is doubled and 1 is added at each appeal. We have proven the formula by recurrence.
     *  This avoid having a variable number of jurors which would be updated in order to save gas.
     *  @param _disputeID The ID of the dispute we compute the amount of jurors.
     *  @return nbJurors The number of jurors which are drawn.
     */
    function amountJurors(uint _disputeID) public view returns (uint nbJurors) {
        Dispute storage dispute = disputes[_disputeID];
        return (dispute.initialNumberJurors + 1) * 2**dispute.appeals - 1;
    }

    /** @dev Must be used to verify that a juror has been draw at least _draws.length times.
     *  We have to require the user to specify the draws that lead the juror to be drawn.
     *  Because doing otherwise (looping through all draws) could consume too much gas.
     *  @param _jurorAddress Address of the juror we want to verify draws.
     *  @param _disputeID The ID of the dispute the juror was drawn.
     *  @param _draws The list of draws the juror was drawn. It draw numbering starts at 1 and the numbers should be increasing.
     *  Note that in most cases this list will just contain 1 number.
     *  @param valid true if the draws are valid.
     */
    function validDraws(address _jurorAddress, uint _disputeID, uint[] _draws) public view returns (bool valid) {
        uint draw = 0;
        Juror storage juror = jurors[_jurorAddress];
        Dispute storage dispute = disputes[_disputeID];
        uint nbJurors = amountJurors(_disputeID);

        if (juror.lastSession != session) return false; // Make sure that the tokens were deposited for this session.
        if (dispute.session+dispute.appeals != session) return false; // Make sure there is currently a dispute.
        if (period <= Period.Draw) return false; // Make sure that jurors are already drawn.
        for (uint i = 0; i < _draws.length; ++i) {
            if (_draws[i] <= draw) return false; // Make sure that draws are always increasing to avoid someone inputing the same multiple times.
            draw = _draws[i];
            if (draw > nbJurors) return false;
            uint position = uint(keccak256(randomNumber, _disputeID, draw)) % segmentSize; // Random position on the segment for draw.
            require(position >= juror.segmentStart);
            require(position < juror.segmentEnd);
        }

        return true;
    }

    // **************************** //
    // *   Arbitrator functions   * //
    // *   Modifying the state    * //
    // **************************** //

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost().
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Null for the default number. Otherwise, first 16 bytes will be used to return the number of jurors.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes _extraData) public payable returns (uint disputeID) {
        uint16 nbJurors = extraDataToNbJurors(_extraData);
        require(msg.value >= arbitrationCost(_extraData));

        disputeID = disputes.length++;
        Dispute storage dispute = disputes[disputeID];
        dispute.arbitrated = Arbitrable(msg.sender);
        if (period < Period.Draw) // If drawing did not start schedule it for the current session.
            dispute.session = session;
        else // Otherwise schedule it for the next one.
            dispute.session = session+1;
        dispute.choices = _choices;
        dispute.initialNumberJurors = nbJurors;
        dispute.arbitrationFeePerJuror = arbitrationFeePerJuror; // We store it as the general fee can be changed through the governance mechanism.
        dispute.votes.length++;
        dispute.voteCounter.length++;

        DisputeCreation(disputeID, Arbitrable(msg.sender));
        return disputeID;
    }

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Standard but not used by this contract.
     */
    function appeal(uint _disputeID, bytes _extraData) public payable onlyDuring(Period.Appeal) {
        super.appeal(_disputeID,_extraData);
        Dispute storage dispute = disputes[_disputeID];
        require(msg.value >= appealCost(_disputeID, _extraData));
        require(dispute.session+dispute.appeals == session); // Dispute of the current session.
        require(dispute.arbitrated == msg.sender);
        
        dispute.appeals++;
        dispute.votes.length++;
        dispute.voteCounter.length++;
    }

    /** @dev Execute the ruling of a dispute which is in the state executable. UNTRUSTED.
     *  @param disputeID ID of the dispute to execute the ruling.
     */
    function executeRuling(uint disputeID) public {
        Dispute storage dispute = disputes[disputeID];
        require(dispute.state == DisputeState.Executable);

        dispute.state = DisputeState.Executed;
        dispute.arbitrated.rule(disputeID, dispute.voteCounter[dispute.appeals].winningChoice);
    }

    // **************************** //
    // *   Arbitrator functions   * //
    // *    Constant and pure     * //
    // **************************** //

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, 
     *  as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Null for the default number. Other first 16 bits will be used to return the number of jurors.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes _extraData) public view returns (uint fee) {
        return extraDataToNbJurors(_extraData) * arbitrationFeePerJuror;
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, 
     *  as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Is not used there.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes _extraData) public view returns (uint fee) {
        Dispute storage dispute = disputes[_disputeID];

        if(dispute.appeals >= maxAppeals) return NON_PAYABLE_AMOUNT;

        return (2*amountJurors(_disputeID) + 1) * dispute.arbitrationFeePerJuror;
    }

    /** @dev Compute the amount of jurors to be drawn.
     *  @param _extraData Null for the default number. Other first 16 bits will be used to return the number of jurors.
     *  Note that it does not check that the number of jurors is odd, but users are advised to choose a odd number of jurors.
     */
    function extraDataToNbJurors(bytes _extraData) internal view returns (uint16 nbJurors) {
        if (_extraData.length < 2)
            return defaultNumberJuror;
        else
            return (uint16(_extraData[0]) << 8) + uint16(_extraData[1]);
    }

    /** @dev Compute the minimum activated pinakions in alpha.
     *  Note there may be multiple draws for a single user on a single dispute.
     */
    function getStakePerDraw() public view returns (uint minActivatedTokenInAlpha) {
        return (alpha * minActivatedToken) / ALPHA_DIVISOR;
    }


    // **************************** //
    // *     Constant getters     * //
    // **************************** //

    /** @dev Getter for account in Vote.
     *  @param _disputeID ID of the dispute.
     *  @param _appeals Which appeal (or 0 for the initial session).
     *  @param _voteID The ID of the vote for this appeal (or initial session).
     *  @return account The address of the voter.
     */
    function getVoteAccount(uint _disputeID, uint _appeals, uint _voteID) public view returns (address account) {
        return disputes[_disputeID].votes[_appeals][_voteID].account;
    }

    /** @dev Getter for ruling in Vote.
     *  @param _disputeID ID of the dispute.
     *  @param _appeals Which appeal (or 0 for the initial session).
     *  @param _voteID The ID of the vote for this appeal (or initial session).
     *  @return ruling The ruling given by the voter.
     */
    function getVoteRuling(uint _disputeID, uint _appeals, uint _voteID) public view returns (uint ruling) {
        return disputes[_disputeID].votes[_appeals][_voteID].ruling;
    }

    /** @dev Getter for winningChoice in VoteCounter.
     *  @param _disputeID ID of the dispute.
     *  @param _appeals Which appeal (or 0 for the initial session).
     *  @return winningChoice The currently winning choice (or 0 if it&#39;s tied). Note that 0 can also be return if the majority refuses to arbitrate.
     */
    function getWinningChoice(uint _disputeID, uint _appeals) public view returns (uint winningChoice) {
        return disputes[_disputeID].voteCounter[_appeals].winningChoice;
    }

    /** @dev Getter for winningCount in VoteCounter.
     *  @param _disputeID ID of the dispute.
     *  @param _appeals Which appeal (or 0 for the initial session).
     *  @return winningCount The amount of votes the winning choice (or those who are tied) has.
     */
    function getWinningCount(uint _disputeID, uint _appeals) public view returns (uint winningCount) {
        return disputes[_disputeID].voteCounter[_appeals].winningCount;
    }

    /** @dev Getter for voteCount in VoteCounter.
     *  @param _disputeID ID of the dispute.
     *  @param _appeals Which appeal (or 0 for the initial session).
     *  @param _choice The choice.
     *  @return voteCount The amount of votes the winning choice (or those who are tied) has.
     */
    function getVoteCount(uint _disputeID, uint _appeals, uint _choice) public view returns (uint voteCount) {
        return disputes[_disputeID].voteCounter[_appeals].voteCount[_choice];
    }

    /** @dev Getter for lastSessionVote in Dispute.
     *  @param _disputeID ID of the dispute.
     *  @param _juror The juror we want to get the last session he voted.
     *  @return lastSessionVote The last session the juror voted.
     */
    function getLastSessionVote(uint _disputeID, address _juror) public view returns (uint lastSessionVote) {
        return disputes[_disputeID].lastSessionVote[_juror];
    }

    /** @dev Is the juror drawn in the draw of the dispute.
     *  @param _disputeID ID of the dispute.
     *  @param _juror The juror.
     *  @param _draw The draw. Note that it starts at 1.
     *  @return drawn True if the juror is drawn, false otherwise.
     */
    function isDrawn(uint _disputeID, address _juror, uint _draw) public view returns (bool drawn) {
        Dispute storage dispute = disputes[_disputeID];
        Juror storage juror = jurors[_juror];
        if (juror.lastSession != session
        || (dispute.session+dispute.appeals != session)
        || period<=Period.Draw
        || _draw>amountJurors(_disputeID)
        || _draw==0
        || segmentSize==0
        ) {
            return false;
        } else {
            uint position = uint(keccak256(randomNumber,_disputeID,_draw)) % segmentSize;
            return (position >= juror.segmentStart) && (position < juror.segmentEnd);
        }

    }

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The current ruling which will be given if there is no appeal. If it is not available, return 0.
     */
    function currentRuling(uint _disputeID) public view returns (uint ruling) {
        Dispute storage dispute = disputes[_disputeID];
        return dispute.voteCounter[dispute.appeals].winningChoice;
    }

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view returns (DisputeStatus status) {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.session+dispute.appeals < session) // Dispute of past session.
            return DisputeStatus.Solved;
        else if(dispute.session+dispute.appeals == session) { // Dispute of current session.
            if (dispute.state == DisputeState.Open) {
                if (period < Period.Appeal)
                    return DisputeStatus.Waiting;
                else if (period == Period.Appeal)
                    return DisputeStatus.Appealable;
                else return DisputeStatus.Solved;
            } else return DisputeStatus.Solved;
        } else return DisputeStatus.Waiting; // Dispute for future session.
    }

    // **************************** //
    // *     Governor Functions   * //
    // **************************** //

    /** @dev General call function where the contract execute an arbitrary call with data and ETH following governor orders.
     *  @param _data Transaction data.
     *  @param _value Transaction value.
     *  @param _target Transaction target.
     */
    function executeOrder(bytes32 _data, uint _value, address _target) public onlyGovernor {
        _target.call.value(_value)(_data);
    }

    /** @dev Setter for rng.
     *  @param _rng An instance of RNG.
     */
    function setRng(RNG _rng) public onlyGovernor {
        rng = _rng;
    }

    /** @dev Setter for arbitrationFeePerJuror.
     *  @param _arbitrationFeePerJuror The fee which will be paid to each juror.
     */
    function setArbitrationFeePerJuror(uint _arbitrationFeePerJuror) public onlyGovernor {
        arbitrationFeePerJuror = _arbitrationFeePerJuror;
    }

    /** @dev Setter for defaultNumberJuror.
     *  @param _defaultNumberJuror Number of drawn jurors unless specified otherwise.
     */
    function setDefaultNumberJuror(uint16 _defaultNumberJuror) public onlyGovernor {
        defaultNumberJuror = _defaultNumberJuror;
    }

    /** @dev Setter for minActivatedToken.
     *  @param _minActivatedToken Minimum of tokens to be activated (in basic units).
     */
    function setMinActivatedToken(uint _minActivatedToken) public onlyGovernor {
        minActivatedToken = _minActivatedToken;
    }

    /** @dev Setter for timePerPeriod.
     *  @param _timePerPeriod The minimum time each period lasts (seconds).
     */
    function setTimePerPeriod(uint[5] _timePerPeriod) public onlyGovernor {
        timePerPeriod = _timePerPeriod;
    }

    /** @dev Setter for alpha.
     *  @param _alpha Alpha in ‱.
     */
    function setAlpha(uint _alpha) public onlyGovernor {
        alpha = _alpha;
    }

    /** @dev Setter for maxAppeals.
     *  @param _maxAppeals Number of times a dispute can be appealed. When exceeded appeal cost becomes NON_PAYABLE_AMOUNT.
     */
    function setMaxAppeals(uint _maxAppeals) public onlyGovernor {
        maxAppeals = _maxAppeals;
    }

    /** @dev Setter for governor.
     *  @param _governor Address of the governor contract.
     */
    function setGovernor(address _governor) public onlyGovernor {
        governor = _governor;
    }
}