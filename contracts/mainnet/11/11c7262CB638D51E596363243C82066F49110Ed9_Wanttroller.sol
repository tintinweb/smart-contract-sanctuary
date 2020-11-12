pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./WantFaucet.sol";
import "./WanttrollerStorage.sol";
import "./Unitroller.sol";
import "./EIP20Interface.sol";
import "./SafeMath.sol";

contract Wanttroller is WanttrollerV1Storage, WanttrollerErrorReporter {
  using SafeMath for uint256;

  uint constant initialReward = 50e18;

  event WantDropIndex(address account, uint index);
  event CollectRewards(address owner, uint rewardsAmount);
  event AccrueRewards(address owner, uint rewardsAmount);
  
  constructor() public {
    admin = msg.sender;
  }

//--------------------
// Main actions
// -------------------

  /**
   * @notice Redeem rewards earned in wallet and register for next drop 
   */
  function collectRewards() public {
    // Register for next drop, accrue last reward if applicable 
    registerForDrop();

    if (_needsDrip()){
      _dripFaucet();
    }

    // send accrued reward to sender
    EIP20Interface want = EIP20Interface(wantTokenAddress);
    bool success = want.transfer(msg.sender, accruedRewards[msg.sender]);
    require(success, "collectRewards(): Unable to send tokens");
    
    // emit
    emit CollectRewards(msg.sender, accruedRewards[msg.sender]);
    
    // Reset accrued to zero 
    accruedRewards[msg.sender] = 0; 
  }

  /**
   * @notice Register to receive reward in next WantDrop, accrues any rewards from the last drop 
   */
  function registerForDrop() public {
    // If previous drop has finished, start a new drop
    if (isDropOver()) {
      _startNewDrop();
    }

    // Add rewards to balance
    _accrueRewards();
    
    // Update want index
    if (lastDropRegistered[msg.sender] != currentDropIndex) {
      // Store index for account
      lastDropRegistered[msg.sender] = currentDropIndex;
      
      // Bump total registered count for this drop
      uint _numRegistrants = wantDropState[currentDropIndex].numRegistrants;
      wantDropState[currentDropIndex].numRegistrants = _numRegistrants.add(1);
    
      // Add to array of those on drop 
      accountsRegisteredForDrop.push(msg.sender);

      // Emit event
      emit WantDropIndex(msg.sender, currentDropIndex);
    }
    
    // Track sender registered for current drop 
    lastDropRegistered[msg.sender] = currentDropIndex;
  }

  /**
   * @notice Register to receive reward in next WantDrop, accrues any rewards from the last drop, 
   *         sends all rewards to wallet 
   */
  function registerAndCollect() public {
    registerForDrop();
    collectRewards();
  }

//---------------------
// Statuses & getters
//---------------------
  
  /**
   * @notice Gets most current drop index. If current drop has finished, returns next drop index 
   */
  function getCurrentDropIndex() public view returns(uint) {
    if (isDropOver())
      return currentDropIndex.add(1);
    else
      return currentDropIndex;
  }
  
  /**
   * @notice True if registered for most current drop 
   */
  function registeredForNextDrop() public view returns(bool) {
    if (isDropOver())
      return false;
    else if (lastDropRegistered[msg.sender] == currentDropIndex)
      return true;
    else
      return false;
  }

  /**
    * @notice Blocks remaining to register for stake drop
    */
  function blocksRemainingToRegister() public view returns(uint) {
    if (isDropOver() || currentDropIndex == 0){
      return waitblocks; 
    }
    else {
      return currentDropStartBlock.add(waitblocks).sub(block.number);
    }
  }

  /**
   * @notice True if waitblocks have passed since drop registration started 
   */
  function isDropOver() public view returns(bool) {
    // If current block is beyond start + waitblocks, drop registration over
    if (block.number >= currentDropStartBlock.add(waitblocks))
      return true;
    else
      return false;
  }

  function getTotalCurrentDropReward() public view returns(uint) {
    if (isDropOver()) {
      return _nextReward(currentReward);
    }
    else {
      return currentReward;
    }
  }

  /**
   * @notice returns expected drop based on how many registered
   */
  function getExpectedReward() public view returns(uint) {
    if (isDropOver()) {
      return _nextReward(currentReward);
    }
    
    // total reward / num registrants
    (MathError err, Exp memory result) = divScalar(Exp({mantissa: wantDropState[currentDropIndex].totalDrop}), wantDropState[currentDropIndex].numRegistrants ); 
    require(err == MathError.NO_ERROR);
    return result.mantissa;
  }

  /**
   * @notice Gets the sender's total accrued rewards 
   */
  function getRewards() public view returns(uint) {
    uint pendingRewards = _pendingRewards();
     
    if (pendingRewards > 0) { 
      return accruedRewards[msg.sender].add(pendingRewards);
    }
    else {
      return accruedRewards[msg.sender];
    }
  }


  /**
   * @notice Return stakers list for  
   */
  function getAccountsRegisteredForDrop() public view returns(address[] memory) {
    if (isDropOver()){
      address[] memory blank;
      return blank;
    }
    else
      return accountsRegisteredForDrop;
  }

// --------------------------------
// Reward computation and helpers
// --------------------------------
  
  /**
   * @notice Used to compute any pending reward not yet accrued onto a users accruedRewards  
   */
  function _pendingRewards() internal view returns(uint) {
    // Last drop user wanted
    uint _lastDropRegistered = lastDropRegistered[msg.sender];
    
    // If new account, no rewards
    if (_lastDropRegistered == 0) 
      return 0;

    // If drop requested has completed, accrue rewards
    if (_lastDropRegistered < currentDropIndex) {
      // Accrued = accrued + reward for last drop
      return _computeRewardMantissa(_lastDropRegistered);
    }
    else if (isDropOver()) {
      // Accrued = accrued + reward for last drop
      return _computeRewardMantissa(_lastDropRegistered);
    }
    else {
      return 0;
    }
  }
  
  /**
   * @notice Used to add rewards from last drop user was in to their accuedRewards balances 
   */
  function _accrueRewards() internal {
    uint pendingRewards = _pendingRewards();
     
    if (pendingRewards > 0) { 
      accruedRewards[msg.sender] = accruedRewards[msg.sender].add(pendingRewards);
      emit AccrueRewards(msg.sender, pendingRewards);
    }
  }

  /**
   * @notice Compute how much reward each participant in the drop received 
   */
  function _computeRewardMantissa(uint index) internal view returns(uint) {
    WantDrop memory wantDrop = wantDropState[index]; 
    
    // Total Reward / Total participants
    (MathError err, Exp memory reward) = divScalar(Exp({ mantissa: wantDrop.totalDrop }), wantDrop.numRegistrants);
    require(err == MathError.NO_ERROR, "ComputeReward() Division error");
    return reward.mantissa;
  }

//------------------------------
// Drop management
//------------------------------
  /**
   * @notice Sets up state for new drop state and drips from faucet if rewards getting low 
   */
  function _startNewDrop() internal {
    // Bump drop index
    currentDropIndex = currentDropIndex.add(1);
    
    // Update current drop start to now
    currentDropStartBlock = block.number;

    // Compute next drop reward 
    uint nextReward = _nextReward(currentReward);
    
    // Update global for total dropped
    totalDropped = totalDropped.add(nextReward);
    
    // Init next drop state
    wantDropState[currentDropIndex] = WantDrop({ 
      totalDrop:  nextReward,
      numRegistrants: 0
    });
   
    // Clear registrants
    delete accountsRegisteredForDrop; 

    // Update currentReward
    currentReward = nextReward;
  }
  
  /**
   * @notice Compute next drop reward, based on current reward 
   * @param _currentReward the current block reward for reference
   */
  function _nextReward(uint _currentReward) private view returns(uint) {
    if (currentDropIndex == 1) { 
      return initialReward; 
    }
    else {
      (MathError err, Exp memory newRewardExp) = mulExp(Exp({mantissa: discountFactor }), Exp({mantissa: _currentReward }));
      require(err == MathError.NO_ERROR);
      return newRewardExp.mantissa;
    }
  }

//------------------------------
// Receiving from faucet 
//------------------------------
  /**
   * @notice checks if balance is too low and needs to visit the WANT faucet 
   */
  function _needsDrip() internal view returns(bool) {
    EIP20Interface want = EIP20Interface(wantTokenAddress);
    uint curBalance = want.balanceOf(address(this));
    if (curBalance < currentReward || curBalance < accruedRewards[msg.sender]) {
      return true;
    }
    return false;
  }

  /**
   * @notice Receive WANT from the want. Attempts to get about 10x more than it needs to reduce need to call so frequently. 
   */
  function _dripFaucet() internal {
    EIP20Interface want = EIP20Interface(wantTokenAddress);
    uint faucetBlance = want.balanceOf(wantFaucetAddress);

    // Let's bulk drip for the next ~ 25 drops
    (MathError err, Exp memory toDrip) = mulScalar(Exp({ mantissa: currentReward }), 25);
    require(err == MathError.NO_ERROR);
    
    WantFaucet faucet = WantFaucet(wantFaucetAddress);
   
    if (toDrip.mantissa.add(faucetBlance) < accruedRewards[msg.sender]) {
      toDrip.mantissa = accruedRewards[msg.sender];
    }

    // If the facuet is ~empty, empty it 
    if (faucetBlance < toDrip.mantissa) {
      faucet.drip(faucetBlance);
    }
    else {
      faucet.drip(toDrip.mantissa);
    }
   }

///------------------------------------
// Admin functions: require governance
// ------------------------------------
  function _setWantFacuet(address newFacuetAddress) public  {
    require(adminOrInitializing());
    wantFaucetAddress = newFacuetAddress;
  }
  
  function _setWantAddress(address newWantAddress) public {
    require(adminOrInitializing());
    wantTokenAddress = newWantAddress;
  }
  
  function _setDiscountFactor(uint256 newDiscountFactor) public {
    require(adminOrInitializing());
    discountFactor = newDiscountFactor;
  }
  
  function _setWaitBlocks(uint256 newWaitBlocks) public {
    require(adminOrInitializing(), "not an admin");
    waitblocks = newWaitBlocks;
  }
  
  function _setCurrentReward(uint256 _currentReward) public {
    require(adminOrInitializing(), "not an admin");
    currentReward = _currentReward;
  }
  
  function _become(Unitroller unitroller) public {
      require(msg.sender == unitroller.admin(), "only unitroller admin can change brains");
      require(unitroller._acceptImplementation() == 0, "change not authorized"); 
  }

  /**
   * @notice Checks caller is admin, or this contract is becoming the new implementation
   */
  function adminOrInitializing() internal view returns (bool) {
      return msg.sender == admin || msg.sender == wanttrollerImplementation;
  }

  // Used for testing
  function tick() public {
  }
}
