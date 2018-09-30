/*************************************************************************
 *
 *  (c) 2018 HODLBank.org LLC
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of HODLBank.org LLC and its suppliers, if any.
 * The intellectual and technical concepts contained
 * herein are proprietary to HODLBank.org LLC
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from HODLBank.org LLC.
 * This includes, but not limited to source code text,
 * compiled binary form and any other derivative of this material.
 * We reserve the right to take any other actions and pursue any other 
 * legal rights available to us in order to protect our property.
 */

pragma solidity ^0.4.15;


contract Owned {
  address public owner;
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract RestrictedUsers is Owned {
  mapping(address => bool) mapAuthorizedAddress;

  modifier restricted() {
    require(mapAuthorizedAddress[msg.sender]);
    _;
  }

  function addAuthorized(address arg_user)
  public
  onlyOwner
  {
    mapAuthorizedAddress[arg_user] = true;
  }
}

// Also used in MixManager
interface IRsVerifyPublic {
  function rsVerifyPublic(
    bytes32     arg_message,
    uint[2]     arg_keyImage,
    uint[]      arg_pubKeyXArr,
    uint[]      arg_pubKeyYArr,
    uint[]      arg_cs,
    uint[]      arg_rs
  )
  public
  constant
  returns(bool);
}

interface IMixManager {
  function zkWithdrawTrusted(
    bytes32     arg_mixerTypeKey,
    uint        arg_mixerId,
    address     arg_destination,
    uint[2]     arg_keyImage,
    uint[]      arg_pubKeyIndices,
    uint[]      arg_cs,
    uint[]      arg_rs,
    uint        arg_gasReimbursement
  )
  public;

  function getPubKeyArr50(
    bytes32     arg_mixerTypeKey,
    uint        arg_mixerId,
    uint[]      arg_pubKeyIndices
  )
  public
  constant
  returns (
    uint[50], // pubKeyXArr,
    uint[50]  // pubKeyYArr
  );

  function getMixParticipant(
    bytes32 arg_mixerTypeKey,
    uint    arg_mixerId,
    uint    arg_participantId
  )
  public
  constant
  returns(
    uint    participantsCount,
    address addr,
    uint    addedTime,
    uint    pubKeyX,
    uint    pubKeyY
  );
}

contract ValidatorBond is RestrictedUsers {
  enum WithdrawStatus {
    NONE,
    PROVEN_CORRECT,
    PROVEN_INCORRECT
  }

  struct WithdrawParameters {
    bytes32     mixerTypeKey;
    uint        mixerId;
    address     destination;
    uint[2]     keyImage;
    uint[]      pubKeyIndices;
    uint[]      cs;
    uint[]      rs;
    WithdrawStatus        status;
  }

  // working around "stack too deep" limitation
  struct ClaimVariables {
    uint[]    pubKeyXArr;
    uint[]    pubKeyYArr;
    uint[50]  pubKeyXArrStatic;
    uint[50]  pubKeyYArrStatic;
  }

  uint    public destructionInitiatedTime;
  // to prevent malicious destruction, owner has to wait one week before it can proceed.
  uint    public destructionHoldTime  = 7 * 24 * 3600; // one week
  // 15k is safe default. Value of 14k generates over-reimbursement of less than 1 finney. 13k makes under-reimbursement.
  uint    public confWithdrawGasOverhead = 15*1000;
  address public confMixManager;
  address public confCryptoNote;

  // stores hashes of arguments of successful withdrawals.
  mapping(bytes32 => WithdrawParameters) mapArgumentsHashToParam;

  // Bond is active only when it has funds in bond and destruction procedure has not initiated.
  modifier onlyActive() {
    require(this.balance > 0 && !isDestructionStarted());
    _;
  }

  event Withdraw(address validator, bytes32 argHash);
  event ClaimResult(address claimant, bytes32 argHash, uint8 status);
  event DestructionStarted(uint time);

  function ValidatorBond(address arg_bondedContract, address arg_cryptoNoteContr)
  public
  {
    owner           = msg.sender;
    confMixManager  = arg_bondedContract;
    confCryptoNote  = arg_cryptoNoteContr;
  }

  /**
    PUBLIC
    Trusted validator calls this method to make a zero-knowledge withdraw.

    Test covered.
  */
  function zkWithdraw(
    bytes32     arg_mixerTypeKey,
    uint        arg_mixerId,
    address     arg_destination,
    uint[2]     arg_keyImage,
    uint[]      arg_pubKeyIndices,
    uint[]      arg_cs,
    uint[]      arg_rs
  )
  public
  restricted  // only authorized validator. Test covered.
  onlyActive  // only active bond. Test covered.
  {
    uint reimburseGas = msg.gas;
    IMixManager mixManager = IMixManager(confMixManager);

    // signature must include destination, otherwise funds will be withdrawn
    // to this contract.
    require(arg_destination != address(0));

    // calculating digest of arguments passed by validator
    bytes32 argHash = keccak256(
      arg_mixerTypeKey,
      arg_mixerId,
      arg_destination,
      arg_keyImage,
      arg_pubKeyIndices,
      arg_cs,
      arg_rs
    );

    // recording that validator swore that arguments are valid ring signature
    mapArgumentsHashToParam[argHash] = WithdrawParameters(
      arg_mixerTypeKey,
      arg_mixerId,
      arg_destination,
      arg_keyImage,
      arg_pubKeyIndices,
      arg_cs,
      arg_rs,
      WithdrawStatus.NONE
    );

    // saving balance in order to be able calculate gas reimbursement received from zkWithdraw
    uint balanceBeforeReimbursement = this.balance;

    // publishing event before gas reimbursement calculation.
    // in case transaction fails event will not make it to the chain
    Withdraw(msg.sender, argHash);

    // calculating how much gas this function spent so far plus planned overhead after zkWithdrawTrusted() call.
    assert(reimburseGas >= msg.gas);          // underflow protection
    reimburseGas =  reimburseGas - msg.gas;   // underflow protected
    reimburseGas += confWithdrawGasOverhead;

    // zkWithdrawTrusted is hard-coded to accept calls only from this bond contract.
    // It trusts this bond contract and does not check ring signature to save gas.
    // In case validator makes (un)intentional mistake, anyone can make a claim.
    // Claim verified by this smart contract calculating ring signature on-chain.
    // If claim is valid, claimant and participants collect the bond value.
    // This disincentivizes validator from malicious actions.
    mixManager.zkWithdrawTrusted.gas(msg.gas)(
      arg_mixerTypeKey,
      arg_mixerId,
      arg_destination,
      arg_keyImage,
      arg_pubKeyIndices,
      arg_cs,
      arg_rs,
      reimburseGas
    );

    // zkWithdraw(Trusted) reimburses sender for gas, bond contract must pass it up to original sender.
    // Test covered.
    uint reimbursementWei = this.balance - balanceBeforeReimbursement;
    if (reimbursementWei > 0) {
      // re-entrancy attack is not possible here due to gas-expensive code above.
      msg.sender.transfer(reimbursementWei);
    }

    // make sure bond funds are not affected
    assert(this.balance == balanceBeforeReimbursement);
  }

  /**
    Accepts money into bond.
    Test covered.
  */
  function addBond()
  public
  payable
  {
    // just pile money over there
  }

  /**
    Default function.
  */
  function()
  public
  payable
  {
    // otherwise contract would not accept gas reimbursement from MixManager
  }

  /**
    PUBLIC
    Claimant calls this method to contest validator&#39;s calculation.
    Test covered.
  */
  function claimMistake(
    bytes32     arg_hash
  )
  public
  {
    // getting storage pointer because changing status at the end. Test covered.
    WithdrawParameters storage arg = mapArgumentsHashToParam[arg_hash];
    // ensuring validator has used these arguments as a valid ring signature
    require(arg.mixerTypeKey != bytes32(0)); // 0 means entry does not exist
    // checking if already was contested. Test covered.
    require(arg.status == WithdrawStatus.NONE);

    // reference implementation of ring signature verification
    // if validator calculated differently from that - it made a mistake
    IRsVerifyPublic cryptoNote = IRsVerifyPublic(confCryptoNote);

    // mix manager stores public keys for particular mixer
    IMixManager mixManager = IMixManager(confMixManager);

    // local variables in a struct
    ClaimVariables memory vars;

    // getting public keys for a Mixer.
    (vars.pubKeyXArrStatic, vars.pubKeyYArrStatic) = mixManager.getPubKeyArr50(
      arg.mixerTypeKey,
      arg.mixerId,
      arg.pubKeyIndices
    );

    // converting static array into dynamic array for rsVerifyPublic
    vars.pubKeyXArr = new uint[](arg.pubKeyIndices.length);
    vars.pubKeyYArr = new uint[](arg.pubKeyIndices.length);

    for(uint i=0; i < arg.pubKeyIndices.length; ++i) {
      vars.pubKeyXArr[i] = vars.pubKeyXArrStatic[i];
      vars.pubKeyYArr[i] = vars.pubKeyYArrStatic[i];
    }

    // getting independent result from reference implementation
    bool rsVerifyResult = cryptoNote.rsVerifyPublic(
      keccak256(arg.destination),
      arg.keyImage,
      vars.pubKeyXArr,
      vars.pubKeyYArr,
      arg.cs,
      arg.rs
    );

    // Validator sworn these arguments produce true.
    // Claimant shows us reference implementation returns false,
    // means validator made a mistake.
    // Whether malicious or not, it should be fined.
    if (rsVerifyResult == false) {
      // pay out claimant and participants
      payOffClaim(arg.mixerTypeKey, arg.mixerId); // Test covered.
      arg.status = WithdrawStatus.PROVEN_INCORRECT; // Test covered.
      ClaimResult(msg.sender, arg_hash, uint8(WithdrawStatus.PROVEN_INCORRECT) );

    // calimant was wrong. Reference implementation proved validator was right.
    } else {
      arg.status = WithdrawStatus.PROVEN_CORRECT; // Test covered.
      ClaimResult(msg.sender, arg_hash, uint8(WithdrawStatus.PROVEN_CORRECT) );
    }
  }

  /**
    INTERNAL
    Makes payments to claimant and mixer participants.
  */
  function payOffClaim(bytes32 arg_mixerTypeKey, uint arg_mixerId)
  internal
  {
    IMixManager mixManager = IMixManager(confMixManager);
    address claimant = msg.sender;
    uint    participantsCount;
    address addr;


    (participantsCount, addr,,,) = mixManager.getMixParticipant(arg_mixerTypeKey, arg_mixerId, 0);
    assert(participantsCount > 0 && addr != address(0)); // failure should not be possible but checking anyway.

    uint payoffWei = this.balance / (participantsCount + 1); // +1 is for claimant who gets a reward

    // re-entrancy attack is not possible here due to gas-expensive code above.
    addr.transfer(payoffWei); // Test covered.

    for(uint i=1; i < participantsCount; ++i) {
      // skipped i=0 because we already got address of participant #0 from call above
      (,addr,,,) = mixManager.getMixParticipant(arg_mixerTypeKey, arg_mixerId, i);
      // re-entrancy secure
      addr.transfer(payoffWei); // Test covered.
    }

    // claimant get rest of the balance which can be more that payoffWei
    // due to division remainder
    // re-entrancy secure
    //  Test covered.
    claimant.transfer(this.balance);

    // here, because balance is depleted, bond becomes inactive
    // and does not allow trusted zkWithdraw anymore.
  }

  /**
    CONSTANT
    Returns true if destruction process has been initiated.
  */
  function isDestructionStarted()
  public
  constant
  returns(bool)
  {
    return (destructionInitiatedTime != 0);
  }

  /**
    MANAGEMENT
    Configure gas overhead to properly reimburse trigger.

  */
  function setWithdrawGasOverhead(uint arg_gasOverhead)
  public
  onlyOwner
  {
    // tests showed that 50,000 generates excessive reimbursement
    // while 10,000 makes not enough reimbursement
    require(arg_gasOverhead <= 50000 && arg_gasOverhead >= 10000);
    confWithdrawGasOverhead = arg_gasOverhead;
  }


  /**
    MANAGEMENT
    Initiates destruction of the contract.
    Actual destruction can take place a week from initiation.
    zkWithdraw is not accessible if destruction has started.
  */
  function startDestruction()
  public
  onlyOwner
  {
    require(!isDestructionStarted());
    destructionInitiatedTime = now;
    DestructionStarted(now);
  }

  /**
    MANAGEMENT
    Finalize destruction of the contract.
    Can be called not earlier than one week after initiation.
  */
  function finalizeDestruction()
  public
  onlyOwner
  {
    require(isDestructionStarted());
    // hold period passed
    require( now > (destructionInitiatedTime + destructionHoldTime) );
    selfdestruct(msg.sender);
  }
}