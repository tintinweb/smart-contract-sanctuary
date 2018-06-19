pragma solidity ^0.4.22;

/**
 *@title abstract TokenContract
 *@dev  token contract to call multisig functions
*/
contract TokenContract{
  function mint(address _to, uint256 _amount) public;
  function finishMinting () public;
  function setupMultisig (address _address) public;
}

/**
 *@title contract GangMultisig
 *@dev using multisig access to call another contract functions
*/
contract GangMultisig {
  
  /**
   *@dev token contract variable, contains token address
   *can use abstract contract functions
  */
  TokenContract public token;

  //@dev Variable to check multisig functions life time.
  //change it before deploy in main network
  uint public lifeTime = 86400; // seconds;
  
  //@dev constructor
  constructor (address _token, uint _needApprovesToConfirm, address[] _owners) public{
    require (_needApprovesToConfirm > 1 && _needApprovesToConfirm <= _owners.length);
    
    //@dev setup GangTokenContract by contract address
    token = TokenContract(_token);

    addInitialOwners(_owners);

    needApprovesToConfirm = _needApprovesToConfirm;

    /**
     *@dev Call function setupMultisig in token contract
     *This function can be call once.
    */
    token.setupMultisig(address(this));
    
    ownersCount = _owners.length;
  }

  /**
   *@dev internal function, called in constructor
   *Add initial owners in mapping &#39;owners&#39;
  */
  function addInitialOwners (address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++){
      //@dev check for duplicate owner addresses
      require(!owners[_owners[i]]);
      owners[_owners[i]] = true;
    }
  }

  //@dev variable to check is minting finished;
  bool public mintingFinished = false;

  //@dev Mapping which contains all active owners.
  mapping (address => bool) public owners;

  //@dev Owner can add new proposal 1 time at each lifeTime cycle
  mapping (address => uint32) public lastOwnersAction;
  
  modifier canCreate() { 
    require (lastOwnersAction[msg.sender] + lifeTime < now);
    lastOwnersAction[msg.sender] = uint32(now);
    _; 
  }
  

  //@dev Modifier to check is message sender contains in mapping &#39;owners&#39;.
  modifier onlyOwners() { 
    require (owners[msg.sender]); 
    _; 
  }

  //@dev current owners count
  uint public ownersCount;

  //@dev current approves need to confirm for any function. Can&#39;t be less than 2. 
  uint public needApprovesToConfirm;

  //Start Minting Tokens
  struct SetNewMint {
    address spender;
    uint value;
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

  //@dev Variable which contains all information about current SetNewMint request
  SetNewMint public setNewMint;

  event NewMintRequestSetup(address indexed initiator, address indexed spender, uint value);
  event NewMintRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event NewMintRequestCanceled();  

  /**
   * @dev Set new mint request, can be call only by owner
   * @param _spender address The address which you want to mint to
   * @param _value uint256 the amount of tokens to be minted
   */
  function setNewMintRequest (address _spender, uint _value) public onlyOwners canCreate {
    require (setNewMint.creationTimestamp + lifeTime < uint32(now) || setNewMint.isExecute || setNewMint.isCanceled);

    require (!mintingFinished);

    address[] memory addr;

    setNewMint = SetNewMint(_spender, _value, 1, false, msg.sender, false, uint32(now), addr);
    setNewMint.confirmators.push(msg.sender);

    emit NewMintRequestSetup(msg.sender, _spender, _value);
  }

  /**
   * @dev Approve mint request, can be call only by owner
   * which don&#39;t call this mint request before.
   */
  function approveNewMintRequest () public onlyOwners {
    require (!setNewMint.isExecute && !setNewMint.isCanceled);
    require (setNewMint.creationTimestamp + lifeTime >= uint32(now));

    require (!mintingFinished);

    for (uint i = 0; i < setNewMint.confirmators.length; i++){
      require(setNewMint.confirmators[i] != msg.sender);
    }
      
    setNewMint.confirms++;
    setNewMint.confirmators.push(msg.sender);

    if(setNewMint.confirms >= needApprovesToConfirm){
      setNewMint.isExecute = true;

      token.mint(setNewMint.spender, setNewMint.value); 
    }
    emit NewMintRequestUpdate(msg.sender, setNewMint.confirms, setNewMint.isExecute);
  }

  /**
   * @dev Cancel mint request, can be call only by owner
   * which created this mint request.
   */
  function cancelMintRequest () public {
    require (msg.sender == setNewMint.initiator);    
    require (!setNewMint.isCanceled && !setNewMint.isExecute);

    setNewMint.isCanceled = true;
    emit NewMintRequestCanceled();
  }
  //Finish Minting Tokens

  //Start finishMinting functions
  struct FinishMintingStruct {
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

  //@dev Variable which contains all information about current finishMintingStruct request
  FinishMintingStruct public finishMintingStruct;

  event FinishMintingRequestSetup(address indexed initiator);
  event FinishMintingRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event FinishMintingRequestCanceled();
  event FinishMintingApproveCanceled(address owner);

  /**
   * @dev New finish minting request, can be call only by owner
   */
  function finishMintingRequestSetup () public onlyOwners canCreate{
    require ((finishMintingStruct.creationTimestamp + lifeTime < uint32(now) || finishMintingStruct.isCanceled) && !finishMintingStruct.isExecute);
    
    require (!mintingFinished);

    address[] memory addr;

    finishMintingStruct = FinishMintingStruct(1, false, msg.sender, false, uint32(now), addr);
    finishMintingStruct.confirmators.push(msg.sender);

    emit FinishMintingRequestSetup(msg.sender);
  }

  /**
   * @dev Approve finish minting request, can be call only by owner
   * which don&#39;t call this finish minting request before.
   */
  function ApproveFinishMintingRequest () public onlyOwners {
    require (!finishMintingStruct.isCanceled && !finishMintingStruct.isExecute);
    require (finishMintingStruct.creationTimestamp + lifeTime >= uint32(now));

    require (!mintingFinished);

    for (uint i = 0; i < finishMintingStruct.confirmators.length; i++){
      require(finishMintingStruct.confirmators[i] != msg.sender);
    }

    finishMintingStruct.confirmators.push(msg.sender);

    finishMintingStruct.confirms++;

    if(finishMintingStruct.confirms >= needApprovesToConfirm){
      token.finishMinting();
      finishMintingStruct.isExecute = true;
      mintingFinished = true;
    }
    
    emit FinishMintingRequestUpdate(msg.sender, finishMintingStruct.confirms, finishMintingStruct.isExecute);
  }
  
  /**
   * @dev Cancel finish minting request, can be call only by owner
   * which created this finish minting request.
   */
  function cancelFinishMintingRequest () public {
    require (msg.sender == finishMintingStruct.initiator);
    require (!finishMintingStruct.isCanceled);

    finishMintingStruct.isCanceled = true;
    emit FinishMintingRequestCanceled();
  }
  //Finish finishMinting functions

  //Start change approves count
  struct SetNewApproves {
    uint count;
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

  //@dev Variable which contains all information about current setNewApproves request
  SetNewApproves public setNewApproves;

  event NewNeedApprovesToConfirmRequestSetup(address indexed initiator, uint count);
  event NewNeedApprovesToConfirmRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event NewNeedApprovesToConfirmRequestCanceled();

  /**
   * @dev Function to change &#39;needApprovesToConfirm&#39; variable, can be call only by owner
   * @param _count uint256 New need approves to confirm will needed
   */
  function setNewOwnersCountToApprove (uint _count) public onlyOwners canCreate {
    require (setNewApproves.creationTimestamp + lifeTime < uint32(now) || setNewApproves.isExecute || setNewApproves.isCanceled);

    require (_count > 1);

    address[] memory addr;

    setNewApproves = SetNewApproves(_count, 1, false, msg.sender,false, uint32(now), addr);
    setNewApproves.confirmators.push(msg.sender);

    emit NewNeedApprovesToConfirmRequestSetup(msg.sender, _count);
  }

  /**
   * @dev Approve new owners count request, can be call only by owner
   * which don&#39;t call this new owners count request before.
   */
  function approveNewOwnersCount () public onlyOwners {
    require (setNewApproves.count <= ownersCount);
    require (setNewApproves.creationTimestamp + lifeTime >= uint32(now));
    
    for (uint i = 0; i < setNewApproves.confirmators.length; i++){
      require(setNewApproves.confirmators[i] != msg.sender);
    }
    
    require (!setNewApproves.isExecute && !setNewApproves.isCanceled);
    
    setNewApproves.confirms++;
    setNewApproves.confirmators.push(msg.sender);

    if(setNewApproves.confirms >= needApprovesToConfirm){
      setNewApproves.isExecute = true;

      needApprovesToConfirm = setNewApproves.count;   
    }
    emit NewNeedApprovesToConfirmRequestUpdate(msg.sender, setNewApproves.confirms, setNewApproves.isExecute);
  }

  /**
   * @dev Cancel new owners count request, can be call only by owner
   * which created this owners count request.
   */
  function cancelNewOwnersCountRequest () public {
    require (msg.sender == setNewApproves.initiator);    
    require (!setNewApproves.isCanceled && !setNewApproves.isExecute);

    setNewApproves.isCanceled = true;
    emit NewNeedApprovesToConfirmRequestCanceled();
  }
  
  //Finish change approves count

  //Start add new owner
  struct NewOwner {
    address newOwner;
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

  NewOwner public addOwner;
  //@dev Variable which contains all information about current addOwner request

  event AddOwnerRequestSetup(address indexed initiator, address newOwner);
  event AddOwnerRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event AddOwnerRequestCanceled();

  /**
   * @dev Function to add new owner in mapping &#39;owners&#39;, can be call only by owner
   * @param _newOwner address new potentially owner
   */
  function setAddOwnerRequest (address _newOwner) public onlyOwners canCreate {
    require (addOwner.creationTimestamp + lifeTime < uint32(now) || addOwner.isExecute || addOwner.isCanceled);
    
    address[] memory addr;

    addOwner = NewOwner(_newOwner, 1, false, msg.sender, false, uint32(now), addr);
    addOwner.confirmators.push(msg.sender);

    emit AddOwnerRequestSetup(msg.sender, _newOwner);
  }

  /**
   * @dev Approve new owner request, can be call only by owner
   * which don&#39;t call this new owner request before.
   */
  function approveAddOwnerRequest () public onlyOwners {
    require (!addOwner.isExecute && !addOwner.isCanceled);
    require (addOwner.creationTimestamp + lifeTime >= uint32(now));

    /**
     *@dev new owner shoudn&#39;t be in owners mapping
     */
    require (!owners[addOwner.newOwner]);

    for (uint i = 0; i < addOwner.confirmators.length; i++){
      require(addOwner.confirmators[i] != msg.sender);
    }
    
    addOwner.confirms++;
    addOwner.confirmators.push(msg.sender);

    if(addOwner.confirms >= needApprovesToConfirm){
      addOwner.isExecute = true;

      owners[addOwner.newOwner] = true;
      ownersCount++;
    }

    emit AddOwnerRequestUpdate(msg.sender, addOwner.confirms, addOwner.isExecute);
  }

  /**
   * @dev Cancel new owner request, can be call only by owner
   * which created this add owner request.
   */
  function cancelAddOwnerRequest() public {
    require (msg.sender == addOwner.initiator);
    require (!addOwner.isCanceled && !addOwner.isExecute);

    addOwner.isCanceled = true;
    emit AddOwnerRequestCanceled();
  }
  //Finish add new owner

  //Start remove owner
  NewOwner public removeOwners;
  //@dev Variable which contains all information about current removeOwners request

  event RemoveOwnerRequestSetup(address indexed initiator, address newOwner);
  event RemoveOwnerRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event RemoveOwnerRequestCanceled();

  /**
   * @dev Function to remove owner from mapping &#39;owners&#39;, can be call only by owner
   * @param _removeOwner address potentially owner to remove
   */
  function removeOwnerRequest (address _removeOwner) public onlyOwners canCreate {
    require (removeOwners.creationTimestamp + lifeTime < uint32(now) || removeOwners.isExecute || removeOwners.isCanceled);

    address[] memory addr;
    
    removeOwners = NewOwner(_removeOwner, 1, false, msg.sender, false, uint32(now), addr);
    removeOwners.confirmators.push(msg.sender);

    emit RemoveOwnerRequestSetup(msg.sender, _removeOwner);
  }

  /**
   * @dev Approve remove owner request, can be call only by owner
   * which don&#39;t call this remove owner request before.
   */
  function approveRemoveOwnerRequest () public onlyOwners {
    require (ownersCount - 1 >= needApprovesToConfirm && ownersCount > 2);

    require (owners[removeOwners.newOwner]);
    
    require (!removeOwners.isExecute && !removeOwners.isCanceled);
    require (removeOwners.creationTimestamp + lifeTime >= uint32(now));

    for (uint i = 0; i < removeOwners.confirmators.length; i++){
      require(removeOwners.confirmators[i] != msg.sender);
    }
    
    removeOwners.confirms++;
    removeOwners.confirmators.push(msg.sender);

    if(removeOwners.confirms >= needApprovesToConfirm){
      removeOwners.isExecute = true;

      owners[removeOwners.newOwner] = false;
      ownersCount--;

      _removeOwnersAproves(removeOwners.newOwner);
    }

    emit RemoveOwnerRequestUpdate(msg.sender, removeOwners.confirms, removeOwners.isExecute);
  }

  
  /**
   * @dev Cancel remove owner request, can be call only by owner
   * which created this remove owner request.
   */
  function cancelRemoveOwnerRequest () public {
    require (msg.sender == removeOwners.initiator);    
    require (!removeOwners.isCanceled && !removeOwners.isExecute);

    removeOwners.isCanceled = true;
    emit RemoveOwnerRequestCanceled();
  }
  //Finish remove owner

  //Start remove 2nd owner
  NewOwner public removeOwners2;
  //@dev Variable which contains all information about current removeOwners request

  event RemoveOwnerRequestSetup2(address indexed initiator, address newOwner);
  event RemoveOwnerRequestUpdate2(address indexed owner, uint8 indexed confirms, bool isExecute);
  event RemoveOwnerRequestCanceled2();

  /**
   * @dev Function to remove owner from mapping &#39;owners&#39;, can be call only by owner
   * @param _removeOwner address potentially owner to remove
   */
  function removeOwnerRequest2 (address _removeOwner) public onlyOwners canCreate {
    require (removeOwners2.creationTimestamp + lifeTime < uint32(now) || removeOwners2.isExecute || removeOwners2.isCanceled);

    address[] memory addr;
    
    removeOwners2 = NewOwner(_removeOwner, 1, false, msg.sender, false, uint32(now), addr);
    removeOwners2.confirmators.push(msg.sender);

    emit RemoveOwnerRequestSetup2(msg.sender, _removeOwner);
  }

  /**
   * @dev Approve remove owner request, can be call only by owner
   * which don&#39;t call this remove owner request before.
   */
  function approveRemoveOwnerRequest2 () public onlyOwners {
    require (ownersCount - 1 >= needApprovesToConfirm && ownersCount > 2);

    require (owners[removeOwners2.newOwner]);
    
    require (!removeOwners2.isExecute && !removeOwners2.isCanceled);
    require (removeOwners2.creationTimestamp + lifeTime >= uint32(now));

    for (uint i = 0; i < removeOwners2.confirmators.length; i++){
      require(removeOwners2.confirmators[i] != msg.sender);
    }
    
    removeOwners2.confirms++;
    removeOwners2.confirmators.push(msg.sender);

    if(removeOwners2.confirms >= needApprovesToConfirm){
      removeOwners2.isExecute = true;

      owners[removeOwners2.newOwner] = false;
      ownersCount--;

      _removeOwnersAproves(removeOwners2.newOwner);
    }

    emit RemoveOwnerRequestUpdate2(msg.sender, removeOwners2.confirms, removeOwners2.isExecute);
  }

  /**
   * @dev Cancel remove owner request, can be call only by owner
   * which created this remove owner request.
   */
  function cancelRemoveOwnerRequest2 () public {
    require (msg.sender == removeOwners2.initiator);    
    require (!removeOwners2.isCanceled && !removeOwners2.isExecute);

    removeOwners2.isCanceled = true;
    emit RemoveOwnerRequestCanceled2();
  }
  //Finish remove 2nd owner

  /**
   * @dev internal function to check and revert all actions
   * by removed owner in this contract.
   * If _oldOwner created request then it will be canceled.
   * If _oldOwner approved request then his approve will canceled.
   */
  function _removeOwnersAproves(address _oldOwner) internal{
    //@dev check actions in setNewMint requests
    //@dev check for empty struct
    if (setNewMint.initiator != address(0)){
      //@dev check, can this request be approved by someone, if no then no sense to change something
      if (setNewMint.creationTimestamp + lifeTime >= uint32(now) && !setNewMint.isExecute && !setNewMint.isCanceled){
        if(setNewMint.initiator == _oldOwner){
          setNewMint.isCanceled = true;
          emit NewMintRequestCanceled();
        }else{
          //@dev Trying to find _oldOwner in struct confirmators
          for (uint i = 0; i < setNewMint.confirmators.length; i++){
            if (setNewMint.confirmators[i] == _oldOwner){
              //@dev if _oldOwner confirmed this request he should be removed from confirmators
              setNewMint.confirmators[i] = address(0);
              setNewMint.confirms--;

              /**
               *@dev Struct can be confirmed each owner just once
               *so no sence to continue loop
               */
              break;
            }
          }
        }
      }
    }

    /**@dev check actions in finishMintingStruct requests
     * check for empty struct
     */
    if (finishMintingStruct.initiator != address(0)){
      //@dev check, can this request be approved by someone, if no then no sense to change something
      if (finishMintingStruct.creationTimestamp + lifeTime >= uint32(now) && !finishMintingStruct.isExecute && !finishMintingStruct.isCanceled){
        if(finishMintingStruct.initiator == _oldOwner){
          finishMintingStruct.isCanceled = true;
          emit NewMintRequestCanceled();
        }else{
          //@dev Trying to find _oldOwner in struct confirmators
          for (i = 0; i < finishMintingStruct.confirmators.length; i++){
            if (finishMintingStruct.confirmators[i] == _oldOwner){
              //@dev if _oldOwner confirmed this request he should be removed from confirmators
              finishMintingStruct.confirmators[i] = address(0);
              finishMintingStruct.confirms--;

              /**
               *@dev Struct can be confirmed each owner just once
               *so no sence to continue loop
               */
              break;
            }
          }
        }     
      }
    }

    /**@dev check actions in setNewApproves requests
     * check for empty struct
     */
    if (setNewApproves.initiator != address(0)){
      //@dev check, can this request be approved by someone, if no then no sense to change something
      if (setNewApproves.creationTimestamp + lifeTime >= uint32(now) && !setNewApproves.isExecute && !setNewApproves.isCanceled){
        if(setNewApproves.initiator == _oldOwner){
          setNewApproves.isCanceled = true;

          emit NewNeedApprovesToConfirmRequestCanceled();
        }else{
          //@dev Trying to find _oldOwner in struct confirmators
          for (i = 0; i < setNewApproves.confirmators.length; i++){
            if (setNewApproves.confirmators[i] == _oldOwner){
              //@dev if _oldOwner confirmed this request he should be removed from confirmators
              setNewApproves.confirmators[i] = address(0);
              setNewApproves.confirms--;

              /**
               *@dev Struct can be confirmed each owner just once
               *so no sence to continue loop
               */
              break;
            }
          }
        }
      }
    }

    /**
     *@dev check actions in addOwner requests
     *check for empty struct
     */
    if (addOwner.initiator != address(0)){
      //@dev check, can this request be approved by someone, if no then no sense to change something
      if (addOwner.creationTimestamp + lifeTime >= uint32(now) && !addOwner.isExecute && !addOwner.isCanceled){
        if(addOwner.initiator == _oldOwner){
          addOwner.isCanceled = true;
          emit AddOwnerRequestCanceled();
        }else{
          //@dev Trying to find _oldOwner in struct confirmators
          for (i = 0; i < addOwner.confirmators.length; i++){
            if (addOwner.confirmators[i] == _oldOwner){
              //@dev if _oldOwner confirmed this request he should be removed from confirmators
              addOwner.confirmators[i] = address(0);
              addOwner.confirms--;

              /**
               *@dev Struct can be confirmed each owner just once
               *so no sence to continue loop
               */
              break;
            }
          }
        }
      }
    }

    /**@dev check actions in removeOwners requests
     *@dev check for empty struct
    */
    if (removeOwners.initiator != address(0)){
      //@dev check, can this request be approved by someone, if no then no sense to change something
      if (removeOwners.creationTimestamp + lifeTime >= uint32(now) && !removeOwners.isExecute && !removeOwners.isCanceled){
        if(removeOwners.initiator == _oldOwner){
          removeOwners.isCanceled = true;
          emit RemoveOwnerRequestCanceled();
        }else{
          //@dev Trying to find _oldOwner in struct confirmators
          for (i = 0; i < removeOwners.confirmators.length; i++){
            if (removeOwners.confirmators[i] == _oldOwner){
              //@dev if _oldOwner confirmed this request he should be removed from confirmators
              removeOwners.confirmators[i] = address(0);
              removeOwners.confirms--;

              /**
               *@dev Struct can be confirmed each owner just once
               *so no sence to continue loop
               */
              break;
            }
          }
        }
      }
    }
  }
}