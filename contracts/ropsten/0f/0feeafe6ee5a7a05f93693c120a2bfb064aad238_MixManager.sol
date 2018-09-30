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

interface IRsVerifyPublic {
  function rsVerifyPublic(
    bytes32     arg_message,
    uint[2]     arg_keyImage,
    uint[]      arg_pubKeyXArr,
    uint[]      arg_pubKeyYArr,
    uint[]      arg_cs,
    uint[]      arg_rs
  )
  external
  constant
  returns(bool);

  function rsVerifyPoint(
    uint arg_x,
    uint arg_y
  )
  external
  constant
  returns(bool);
}

contract MixManager is Owned {
  enum MixerStatus { NONE, OPEN, COMPLETE, DEPLETED }
  enum SystemStatus {
    ENABLED_ALL,                  
    DISABLED_DEPOSITS,            
    DISABLED_WITHDRAWALS,         
    DISABLED_DEPOSITS_WITHDRAWALS 
  }
  enum AddressUsed {
    NONE,               
    DESTINATION,        
    TRIGGER,            
    DESTINATION_TRIGGER 
  }

  struct MixerParameters {
    uint depositLockTimeSec;
    uint depositAmountWei;
    uint participantsCount;
    uint comissionHundredthPercent;
  }

  struct MixParticipant {
    address addr;
    uint    addedTime;
    uint    pubKeyX;
    uint    pubKeyY;
  }

  struct Mixer {
    MixerStatus               status;
    uint                      updatedTime;
    MixParticipant[]          participants;
    uint                      withdrawalCount;
  }

  struct DepositReceipt {
    bytes32 mixerTypeKey;
    uint    mixerId;
  }

  struct DepositReceiptReference {
    address depositor;
    uint    depositReceiptIndex;
  }

  struct WithdrawArguments {
    bytes32     mixerTypeKey;
    uint        mixerId;
    address     destination;
    uint[2]     keyImage;
    uint[]      pubKeyIndices;
    uint[]      cs;
    uint[]      rs;
    bool        bypassVer;
    uint        additionalGasReimbursement;
  }

  struct WithdrawVariables {
    uint j;
    bool usingSubset;
    uint paymentWei;
    uint comissionWei;
    uint gasCostWei;
    uint gasLimit;
    uint addressUsedFlags;
  }

  
  uint public upgradeStartTime = 0;
  bytes32[] internal arrMixerTypes; 
  mapping(bytes32 => MixerParameters)       public    mapKeyMixerParameters;
  mapping(bytes32 => Mixer[])               internal  mapMixerTypeMixerArr;
  mapping(address => DepositReceipt[])      internal  mapDepositorAddressReceiptArr;
  mapping(uint => DepositReceiptReference)  public    mapPubKeyXDepositReceiptRef;
  mapping(address => uint)                  public    mapAddressUsedForZkWithdraw;
  mapping(bytes32 => bool)                  public    mapKeyImageHashUsed;
  
  uint internal fundsComissionWei;
  uint internal fundsDepositsWei;

  uint          public confPointHashAttempts  = 42;
  uint          public confGasReimbursementOverhead = 100*1000;
  SystemStatus  public confSystemStatus       = SystemStatus.ENABLED_ALL;
  uint          public confUpgradeHoldTimeSec = 1 weeks; 
  address       public confUpgradedContract;
  
  address       public constant confTrustedValidator  = address(0x0005afa8606403e65eac3d503948e89117df77ce99);
  address       public constant confCryptoNote        = address(0x000b00a43e9eca48a5c5d777311916e4778d8d964e);
  
  event Deposited             (address indexed depositor,     uint indexed pubKeyX, bytes32 indexed mixerTypeKey, uint mixerId);
  event DepositCancelled      (address indexed depositor,     uint indexed pubKeyX, bytes32 indexed mixerTypeKey, uint mixerId);
  event MixerComplete         (bytes32 indexed mixerTypeKey,  uint indexed mixerId);
  event ZeroKnowledgeWithdrawn(
    bytes32 indexed keyImageHash,
    address indexed triggerAddr,
    address indexed destinationAddr,
    bytes32 mixerTypeKey,
    uint    mixerId,
    uint    amountWithdrawnWei
  );
  event MixerTypeConfigured   (bytes32 mixerTypeKey);
  event UpgradeStarted        (address newContractAddr);
  event UpgradeFinalized      ();
  event Reconfigured          ();

  
  modifier upgradeHoldPassed() {
    require( (now - upgradeStartTime) >= confUpgradeHoldTimeSec );
    _;
  }

  function MixManager()
  public
  {
    owner = msg.sender;
  }

  function deposit(bytes32 arg_mixerTypeKey, uint arg_pubKeyX, uint arg_pubKeyY)
  public
  payable
  {
    require(mapKeyMixerParameters[arg_mixerTypeKey].depositAmountWei != 0);
    require(mapKeyMixerParameters[arg_mixerTypeKey].depositAmountWei == msg.value); 
    require(uint(arg_pubKeyX) != 0); 
    require(uint(arg_pubKeyY) != 0); 
    require(  
          confSystemStatus != SystemStatus.DISABLED_DEPOSITS
      &&  confSystemStatus != SystemStatus.DISABLED_DEPOSITS_WITHDRAWALS
    );
    
    IRsVerifyPublic rsVerifyContract = IRsVerifyPublic(confCryptoNote);
    require(rsVerifyContract.rsVerifyPoint(arg_pubKeyX, arg_pubKeyY));

    Mixer[] storage mixerArr     = mapMixerTypeMixerArr[arg_mixerTypeKey];
    
    if (mixerArr.length == 0 || mixerArr[(mixerArr.length-1)].status != MixerStatus.OPEN) {
      ++mixerArr.length;
      Mixer storage mixer = mixerArr[(mixerArr.length-1)];
      mixer.status        = MixerStatus.OPEN;
    }
    
    require(getMixParticipantIdByAddress(arg_mixerTypeKey, (mixerArr.length-1), msg.sender) == -1);
    
    Mixer storage latestMixer = mixerArr[(mixerArr.length-1)];
    latestMixer.participants.push( MixParticipant(msg.sender, now, arg_pubKeyX, arg_pubKeyY) );
    
    latestMixer.updatedTime   = now;
    
    if (latestMixer.participants.length == mapKeyMixerParameters[arg_mixerTypeKey].participantsCount) {
      latestMixer.status = MixerStatus.COMPLETE;
      MixerComplete(arg_mixerTypeKey, (mixerArr.length-1) );
    }
    
    mapDepositorAddressReceiptArr[msg.sender].push(
      DepositReceipt( arg_mixerTypeKey, (mixerArr.length-1) )
    );
    
    require(mapPubKeyXDepositReceiptRef[arg_pubKeyX].depositor == address(0));
    
    mapPubKeyXDepositReceiptRef[arg_pubKeyX] = DepositReceiptReference(
      msg.sender,
      (mapDepositorAddressReceiptArr[msg.sender].length - 1) 
    );
    
    fundsDepositsWei += msg.value;

    assertBalance();
    
    Deposited( msg.sender, arg_pubKeyX, arg_mixerTypeKey, (mixerArr.length-1) /* mixerId */ );
  }

  function cancelDeposit(bytes32 arg_mixerTypeKey, uint arg_mixerId, uint arg_pubKeyX)
  public
  {
    Mixer storage mixer = mapMixerTypeMixerArr[arg_mixerTypeKey][arg_mixerId];
    require(mixer.status == MixerStatus.OPEN); 
    require(mixer.participants.length > 0);    

    MixParticipant memory participant;
    int participantId = -1; 
    for(uint i=0; i < mixer.participants.length; ++i) {
      participant = mixer.participants[i];
      if (participant.addr == msg.sender && participant.pubKeyX == arg_pubKeyX) {
        participantId = int(i);
        
        require( (now - participant.addedTime) >= mapKeyMixerParameters[arg_mixerTypeKey].depositLockTimeSec);
        
        if ( (i+1) == mixer.participants.length) {
          delete mixer.participants[i];
          break;
        }
        
        if (i != (mixer.participants.length-1)) {
          mixer.participants[i] = mixer.participants[ (mixer.participants.length-1) ];
        }
        
        delete mixer.participants[ (mixer.participants.length-1) ];
      }
    }
    
    mixer.updatedTime   = now;
    require(participantId >= 0); 
    mixer.participants.length -= 1;

    fundsDepositsWei -= mapKeyMixerParameters[arg_mixerTypeKey].depositAmountWei;
    msg.sender.transfer(mapKeyMixerParameters[arg_mixerTypeKey].depositAmountWei);
    
    DepositCancelled( msg.sender, arg_pubKeyX, arg_mixerTypeKey, arg_mixerId );
    assertBalance();
  }

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
  {
    WithdrawArguments memory arg = WithdrawArguments(
      arg_mixerTypeKey,
      arg_mixerId,
      arg_destination,
      arg_keyImage,
      arg_pubKeyIndices,
      arg_cs,
      arg_rs,
      false,
      0 
    );

    zkWithdrawInternal(arg);
  }

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
  public
  {
    require(msg.sender == confTrustedValidator); 

    WithdrawArguments memory arg = WithdrawArguments(
      arg_mixerTypeKey,
      arg_mixerId,
      arg_destination,
      arg_keyImage,
      arg_pubKeyIndices,
      arg_cs,
      arg_rs,
      true,
      arg_gasReimbursement 
    );

    zkWithdrawInternal(arg);
  }

  function zkWithdrawInternal(
    WithdrawArguments arg
  )
  internal
  {
    vars.gasLimit = msg.gas;
    Mixer storage mixer = mapMixerTypeMixerArr[arg.mixerTypeKey][arg.mixerId];
    require(mixer.status == MixerStatus.COMPLETE);
    
    require(mixer.participants.length > 0);
    require( 
      confSystemStatus != SystemStatus.DISABLED_WITHDRAWALS
      && confSystemStatus != SystemStatus.DISABLED_DEPOSITS_WITHDRAWALS
    );

    WithdrawVariables memory vars;

    uint[] memory pubKeyXArr;
    uint[] memory pubKeyYArr;

    (pubKeyXArr, pubKeyYArr) = getPubKeyArrInternal(mixer, arg.pubKeyIndices);

    require(pubKeyXArr.length > 0);

    IRsVerifyPublic rsVerifyContract = IRsVerifyPublic(confCryptoNote);
    
    require(
      arg.bypassVer ||
      rsVerifyContract.rsVerifyPublic.gas(msg.gas)(keccak256(arg.destination), arg.keyImage, pubKeyXArr, pubKeyYArr, arg.cs, arg.rs)
    );
    
    require(
      !keyImageUsedUpdate(arg.keyImage)
    );
    
    (vars.paymentWei, vars.comissionWei) = calculatePayout(arg.mixerTypeKey);
    
    fundsDepositsWei  -= (vars.paymentWei + vars.comissionWei); 
    fundsComissionWei += vars.comissionWei;                     
    
    assertBalance();
    
    ++(mixer.withdrawalCount);
    if (mixer.withdrawalCount == mixer.participants.length) {
      mixer.status = MixerStatus.DEPLETED;
    } else if (mixer.withdrawalCount > mixer.participants.length) {
      require(false);
    }
    
    vars.addressUsedFlags = mapAddressUsedForZkWithdraw[arg.destination];
    
    if (arg.destination != address(0)) {
      mapAddressUsedForZkWithdraw[arg.destination]  |= uint(AddressUsed.DESTINATION);
      
      if (mapAddressUsedForZkWithdraw[msg.sender] & uint(AddressUsed.TRIGGER) == 0) { 
        mapAddressUsedForZkWithdraw[msg.sender]       |= uint(AddressUsed.TRIGGER);
      }
      
      vars.gasCostWei = (vars.gasLimit - msg.gas + confGasReimbursementOverhead) * tx.gasprice;
      
      vars.gasCostWei += arg.additionalGasReimbursement * tx.gasprice;
      require(vars.gasCostWei < vars.paymentWei); 
      vars.paymentWei -= vars.gasCostWei;         
      
      msg.sender.transfer(vars.gasCostWei);
    } else {
      arg.destination = msg.sender;
      
      mapAddressUsedForZkWithdraw[msg.sender] |= uint(AddressUsed.DESTINATION_TRIGGER);
    }
    
    arg.destination.transfer(vars.paymentWei);
    
    ZeroKnowledgeWithdrawn(
      keccak256(arg.keyImage),
      msg.sender,             
      arg.destination,        
      arg.mixerTypeKey,
      arg.mixerId,
      vars.paymentWei
    );
  }

  function getPubKeyArr(
    bytes32     arg_mixerTypeKey,
    uint        arg_mixerId,
    uint[]      arg_pubKeyIndices
  )
  public
  constant
  returns (
    uint[], 
    uint[]  
  )
  {
    Mixer memory mixer = mapMixerTypeMixerArr[arg_mixerTypeKey][arg_mixerId];

    return getPubKeyArrInternal(mixer, arg_pubKeyIndices);
  }

  function getPubKeyArr50(
    bytes32     arg_mixerTypeKey,
    uint        arg_mixerId,
    uint[]      arg_pubKeyIndices
  )
  public
  constant
  returns (
    uint[50], 
    uint[50]  
  )
  {
    
    require(arg_pubKeyIndices.length <= 50);
    Mixer memory mixer = mapMixerTypeMixerArr[arg_mixerTypeKey][arg_mixerId];

    uint[]    memory pubKeyXArr;
    uint[]    memory pubKeyYArr;
    uint[50]  memory pubKeyXArrStatic;
    uint[50]  memory pubKeyYArrStatic;
    (pubKeyXArr, pubKeyYArr) = getPubKeyArrInternal(mixer, arg_pubKeyIndices);

    for(uint i=0; i < pubKeyXArr.length; ++i) {
      pubKeyXArrStatic[i] = pubKeyXArr[i];
      pubKeyYArrStatic[i] = pubKeyYArr[i];
    }

    return (pubKeyXArrStatic, pubKeyYArrStatic);
  }

  function getPubKeyArrInternal(
    Mixer   arg_mixer,
    uint[]  arg_pubKeyIndices
  )
  internal
  constant
  returns (
    uint[],
    uint[]
  )
  {
    
    bool usingSubset = (arg_pubKeyIndices.length > 0);

    uint[] memory pubKeyXArr = new uint[]( (usingSubset?arg_pubKeyIndices.length:arg_mixer.participants.length) );
    uint[] memory pubKeyYArr = new uint[]( pubKeyXArr.length );

    
    for(uint i=0; i < pubKeyXArr.length; ++i) {
      uint j = (usingSubset) ? (arg_pubKeyIndices[i]) : i;
      pubKeyXArr[i] = arg_mixer.participants[ j ].pubKeyX;
      pubKeyYArr[i] = arg_mixer.participants[ j ].pubKeyY;
      
      require(pubKeyXArr[i] > 0);
      require(pubKeyYArr[i] > 0);
    }

    return (pubKeyXArr, pubKeyYArr);
  }

  function calculatePayout(
    bytes32     arg_mixerTypeKey
  )
  public
  constant
  returns(uint paymentWei, uint comissionWei)
  {
    paymentWei = mapKeyMixerParameters[arg_mixerTypeKey].depositAmountWei;
    comissionWei =
      mapKeyMixerParameters[arg_mixerTypeKey].depositAmountWei
      * mapKeyMixerParameters[arg_mixerTypeKey].comissionHundredthPercent
      /
      ( 100 
      * 100 
      );
    paymentWei -= comissionWei;

    return;
  }

  function getBalanceDiscrepancy()
  public
  constant
  returns(int, uint, uint, uint)
  {
    uint expectedBalanceWei = fundsDepositsWei + fundsComissionWei;
    uint actualFundsWei     = address(this).balance;

    return (
      int(int(actualFundsWei) - int(expectedBalanceWei)),
      actualFundsWei,
      fundsDepositsWei,
      fundsComissionWei
    );
  }

  function getDepositReceipts(
    address arg_depositor,
    int     arg_start,
    uint8   arg_limit
  )
  public
  constant
  returns(
    uint      totalCount,
    bytes32[] memory mixerTypeKey,
    uint[]    memory mixerId
  )
  {
    DepositReceipt[] memory receipts = mapDepositorAddressReceiptArr[arg_depositor];
    totalCount = receipts.length;
    mixerTypeKey  = new bytes32[](arg_limit);
    mixerId       = new uint[](arg_limit);
    
    uint startIndex = 0;
    if (arg_start < 0) {
      arg_start = int(totalCount) + arg_start;
    }
    if (arg_start >= 0) {
      startIndex = uint(arg_start);
    }

    uint resultLength = 0;
    for (uint i=startIndex; i < totalCount; ++i) {
      mixerTypeKey[resultLength] = receipts[i].mixerTypeKey;
      mixerId[resultLength]      = receipts[i].mixerId;
      ++resultLength;
      if (resultLength == arg_limit) break;
    }
  }

  function getMixParticipant(bytes32 arg_mixerTypeKey, uint arg_mixerId, uint arg_participantId)
  public
  constant
  returns(
    uint    participantsCount,
    address addr,
    uint    addedTime,
    uint    pubKeyX,
    uint    pubKeyY
  )
  {
    Mixer memory mixer  = mapMixerTypeMixerArr[arg_mixerTypeKey][arg_mixerId];
    participantsCount   = mapMixerTypeMixerArr[arg_mixerTypeKey][arg_mixerId].participants.length;
    if (arg_participantId < participantsCount) {
      MixParticipant memory p = mixer.participants[arg_participantId];
      addr      = p.addr;
      addedTime = p.addedTime;
      pubKeyX   = p.pubKeyX;
      pubKeyY   = p.pubKeyY;
    }
  }

  function getMixParticipantIdByAddress(
    bytes32 arg_mixerTypeKey,
    uint    arg_mixerId,
    address arg_address
  )
  public
  constant
  returns(int participantId)
  {
    Mixer memory mixer                      = mapMixerTypeMixerArr[arg_mixerTypeKey][arg_mixerId];
    MixParticipant[] memory participantsArr = mixer.participants;
    for (uint i=0; i < participantsArr.length; ++i) {
      MixParticipant memory p = participantsArr[i];
      if (p.addr == arg_address) {
        return int(i);
      }
    }

    return -1;
  }

  function getMixParticipantByPubKey(uint arg_pubKeyX)
  public
  constant
  returns(
    bytes32 mixerTypeKey,
    uint    mixerId,
    uint    participantId,
    address addr,
    uint    addedTime,
    uint    pubKeyX,
    uint    pubKeyY
  )
  {
    DepositReceiptReference memory receiptRef = mapPubKeyXDepositReceiptRef[arg_pubKeyX];
    if (receiptRef.depositor == address(0)) return; 
    DepositReceipt          memory receipt    = mapDepositorAddressReceiptArr[receiptRef.depositor][receiptRef.depositReceiptIndex];
    if (receipt.mixerTypeKey == bytes32(0)) return; 

    MixParticipant[]        memory participantsArr = mapMixerTypeMixerArr[receipt.mixerTypeKey][receipt.mixerId].participants;
    for (uint i=0; i < participantsArr.length; ++i) {
      MixParticipant memory participant = participantsArr[i];
      if (participant.pubKeyX == arg_pubKeyX) {
        return (
          receipt.mixerTypeKey,
          receipt.mixerId,
          i, 
          participant.addr,
          participant.addedTime,
          participant.pubKeyX,
          participant.pubKeyY
        );
      }
    }
  }

  function getMixer(bytes32 arg_mixerTypeKey, uint arg_mixerId)
  public
  constant
  returns(
    MixerStatus status,
    uint        updatedTime,
    uint        participantsCount,
    uint        withdrawalCount
  )
  {
    Mixer[] memory mixerArr  = mapMixerTypeMixerArr[arg_mixerTypeKey];
    
    if (mixerArr.length <= arg_mixerId) return;
    Mixer memory mixer        = mixerArr[arg_mixerId];
    status            = mixer.status;
    updatedTime       = mixer.updatedTime;
    participantsCount = mixer.participants.length;
    withdrawalCount   = mixer.withdrawalCount;

    return;
  }

  function getMixerInfo(bytes32 arg_mixerTypeKey, uint arg_mixerId)
  public
  constant
  returns(
    MixerStatus status,
    uint        updatedTime,
    uint        participantsCount,
    uint        withdrawalCount,
    uint[]      pubKeyX,
    uint[]      pubKeyY
  )
  {
    Mixer[] memory mixerArr  = mapMixerTypeMixerArr[arg_mixerTypeKey];
    
    if (mixerArr.length <= arg_mixerId) return;
    Mixer memory mixer        = mixerArr[arg_mixerId];
    MixParticipant memory participant;
    status            = mixer.status;
    updatedTime       = mixer.updatedTime;
    participantsCount = mixer.participants.length;
    withdrawalCount   = mixer.withdrawalCount;
    
    pubKeyX = new uint[](participantsCount);
    pubKeyY = new uint[](participantsCount);
    for(uint i=0; i < participantsCount; ++i) {
      participant = mixer.participants[i];
      pubKeyX[i]  = participant.pubKeyX;
      pubKeyY[i]  = participant.pubKeyY;
    }

    return;
  }

  function getMixerCountByType(bytes32 arg_mixerTypeKey)
  public
  constant
  returns(uint)
  {
    return mapMixerTypeMixerArr[arg_mixerTypeKey].length;
  }

  function getMixerTypes()
  public
  constant
  returns(bytes32[])
  {
    return arrMixerTypes;
  }

  function keyImageUsedUpdate(
    uint[2]     arg_keyImage
  )
  internal
  returns(bool)
  {
    bytes32 keyImageHash = keccak256(arg_keyImage);
    if (mapKeyImageHashUsed[keyImageHash] == true) {
      return true;
    } else {
      mapKeyImageHashUsed[keyImageHash] = true;
    }

    return false;
  }

  function assertBalance()
  internal
  constant
  {
    int balanceDiscrepancy;
    (balanceDiscrepancy,,,) = getBalanceDiscrepancy();
    if (balanceDiscrepancy < 0) {
      revert();
    }
  }

  function withdrawComission()
  external
  onlyOwner
  {
    if(!owner.send(fundsComissionWei)) revert();
    fundsComissionWei = 0;
  }

  function confSetupMixer(
    bytes32 mixerTypeKey,
    uint arg_depositLockTimeSec,
    uint arg_depositAmountWei,
    uint arg_participantsCount,
    uint arg_comissionHundredthPercent
  )
  external
  onlyOwner
  {
    require(arg_depositAmountWei > 0);
    require(arg_participantsCount < 1000);
    MixerParameters storage params = mapKeyMixerParameters[mixerTypeKey];
    if (arg_depositLockTimeSec        != params.depositLockTimeSec) {
      params.depositLockTimeSec           = arg_depositLockTimeSec;
    }
    if (arg_depositAmountWei          != params.depositAmountWei){
      params.depositAmountWei             = arg_depositAmountWei;
    }
    if (arg_participantsCount         != params.participantsCount){
      params.participantsCount            = arg_participantsCount;
    }
    if (arg_comissionHundredthPercent != params.comissionHundredthPercent){
      params.comissionHundredthPercent    = arg_comissionHundredthPercent;
    }
    
    MixerTypeConfigured(mixerTypeKey);
  }

  function configure(
    uint          arg_confPointHashAttempts,
    uint          arg_confGasReimbursementOverhead,
    SystemStatus  arg_systemStatus
  )
  external
  onlyOwner
  {
    if (arg_confPointHashAttempts != confPointHashAttempts) { 
      confPointHashAttempts = arg_confPointHashAttempts;
    }
    if (arg_confGasReimbursementOverhead != confGasReimbursementOverhead) { 
      confGasReimbursementOverhead = arg_confGasReimbursementOverhead;
    }
    if (arg_systemStatus != confSystemStatus) { 
      confSystemStatus = arg_systemStatus;
    }
    
    Reconfigured();
  }

  function publishMixerType(bytes32 arg_mixerTypeName)
  external
  onlyOwner
  {
    arrMixerTypes.push(arg_mixerTypeName);
    MixerTypeConfigured(keccak256(arg_mixerTypeName));
  }

  function upgradeStart(address arg_upgradedContractAddress)
  external
  onlyOwner
  {
    require(upgradeStartTime == 0);
    upgradeStartTime = now;
    confUpgradedContract = arg_upgradedContractAddress;
    UpgradeStarted(arg_upgradedContractAddress);
  }

  function upgradeFinalize()
  external
  onlyOwner
  upgradeHoldPassed
  {
    confUpgradedContract.transfer(address(this).balance); 
    confSystemStatus = SystemStatus.DISABLED_DEPOSITS_WITHDRAWALS;
    UpgradeFinalized();
  }

  function destroy()
  external
  onlyOwner
  upgradeHoldPassed
  {
    selfdestruct(msg.sender);
  }
}