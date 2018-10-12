/**
 * Test & Staging servers.
 * Allows EDG token holders to lend the Edgeless Casino tokens for the bankroll.
 * Users may pay in their tokens at any time, but they will only be used for the bankroll
 * begining from the next cycle. When the cycle is closed (at the end of the month), they may
 * withdraw their stake of the bankroll. The casino may decide to limit the number of tokens
 * used for the bankroll. The user will be able to withdraw the remaining tokens along with the
 * bankroll tokens once per cycle.
 * author: Rytis Grincevicius
 * */

pragma solidity ^0.4.21;

contract Token {
  function transfer(address receiver, uint amount) public returns(bool);
  function transferFrom(address sender, address receiver, uint amount) public returns(bool);
  function balanceOf(address holder) public view returns(uint);
}

contract Casino {
  mapping(address => bool) public authorized;
}

contract Owned {
  address public owner;
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function Owned() public {
    owner = msg.sender;
  }

  function changeOwner(address newOwner) onlyOwner public {
    owner = newOwner;
  }
}

contract SafeMath {

	function safeSub(uint a, uint b) pure internal returns(uint) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) pure internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

	function safeMul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
}

contract BankrollLending is Owned, SafeMath {
  /** The set of lending contracts state phases **/
  enum StatePhases { deposit, bankroll, update, withdraw }
  /** The number of the current cycle. Increases by 1 each month.**/
  uint public cycle;
  /** The address of the casino contract.**/
  Casino public casino;
  /** The Edgeless casino token contract **/
  Token public token;
  /** The sum of the initial stakes per cycle **/
  mapping(uint => uint) public initialStakes;
  /** The sum of the final stakes per cycle **/
  mapping(uint => uint) public finalStakes;
  /** The sum of the user stakes currently on the contract **/
  uint public totalStakes; //note: uint is enough because the Edgeless Token Contract has 0 decimals and a total supply of 132,046,997 EDG
  /** the number of stake holders **/
  uint public numHolders;
  /** List of all stakeholders **/
  address[] public stakeholders;
  /** Stake per user address **/
  mapping(address => uint) public stakes;
  /** the gas cost if the casino helps the user with the deposit in full EDG **/
  uint8 public depositGasCost;
  /** the gas cost if the casino helps the user with the withdrawal in full EDG **/
  uint8 public withdrawGasCost;
  /** the gas cost for balance update at the end of the cycle per user in EDG with 2 decimals
  * (updates are made for all users at once, so it&#39;s possible to subtract all gas costs from the paid back tokens before
  * setting the final stakes of the cycle.) **/
  uint public updateGasCost;
  /** The minimum staking amount required **/
  uint public minStakingAmount;
  /** The maximum number of addresses to process in one batch of stake updates **/
  uint public maxUpdates; 
  /** The maximum number of addresses that can be assigned in one batch **/
  uint public maxBatchAssignment;
  /** remembers the last index updated per cycle **/
  mapping(uint => uint) lastUpdateIndex;
  /** notifies listeners about a stake update **/
  event StakeUpdate(address holder, uint stake);

  /**
   * Constructor.
   * @param tokenAddr the address of the edgeless token contract
   *        casinoAddr the address of the edgeless casino contract
   * */
  function BankrollLending(address tokenAddr, address casinoAddr) public {
    token = Token(tokenAddr);
    casino = Casino(casinoAddr);
    maxUpdates = 200;
    maxBatchAssignment = 200;
    cycle = 1;
  }

  /**
   * Sets the casino contract address.
   * @param casinoAddr the new casino contract address
   * */
  function setCasinoAddress(address casinoAddr) public onlyOwner {
    casino = Casino(casinoAddr);
  }

  /**
   * Sets the deposit gas cost.
   * @param gasCost the new deposit gas cost
   * */
  function setDepositGasCost(uint8 gasCost) public onlyAuthorized {
    depositGasCost = gasCost;
  }

  /**
   * Sets the withdraw gas cost.
   * @param gasCost the new withdraw gas cost
   * */
  function setWithdrawGasCost(uint8 gasCost) public onlyAuthorized {
    withdrawGasCost = gasCost;
  }

  /**
   * Sets the update gas cost.
   * @param gasCost the new update gas cost
   * */
  function setUpdateGasCost(uint gasCost) public onlyAuthorized {
    updateGasCost = gasCost;
  }
  
  /**
   * Sets the maximum number of user stakes to update at once
   * @param newMax the new maximum
   * */
  function setMaxUpdates(uint newMax) public onlyAuthorized{
    maxUpdates = newMax;
  }
  
  /**
   * Sets the minimum amount of user stakes
   * @param amount the new minimum
   * */
  function setMinStakingAmount(uint amount) public onlyAuthorized {
    minStakingAmount = amount;
  }
  
  /**
   * Sets the maximum number of addresses that can be assigned at once
   * @param newMax the new maximum
   * */
  function setMaxBatchAssignment(uint newMax) public onlyAuthorized {
    maxBatchAssignment = newMax;
  }
  
  /**
   * Allows the user to deposit funds, where the sender address and max allowed value have to be signed together with the cycle
   * number by the casino. The method verifies the signature and makes sure, the deposit was made in time, before updating
   * the storage variables.
   * @param value the number of tokens to deposit
   *        allowedMax the maximum deposit allowed this cycle
   *        v, r, s the signature of an authorized casino wallet
   * */
  function deposit(uint value, uint allowedMax, uint8 v, bytes32 r, bytes32 s) public depositPhase {
    require(verifySignature(msg.sender, allowedMax, v, r, s));
    if (addDeposit(msg.sender, value, numHolders, allowedMax))
      numHolders = safeAdd(numHolders, 1);
    totalStakes = safeSub(safeAdd(totalStakes, value), depositGasCost);
  }

  /**
   * Allows an authorized casino wallet to assign some tokens held by the lending contract to the given addresses.
   * Only allows to assign token which do not already belong to any other user.
   * Caller needs to make sure that the number of assignments can be processed in a single batch!
   * @param to array containing the addresses of the holders
   *        value array containing the number of tokens per address
   * */
  function batchAssignment(address[] to, uint[] value) public onlyAuthorized depositPhase {
    require(to.length == value.length);
    require(to.length <= maxBatchAssignment);
    uint newTotalStakes = totalStakes;
    uint numSH = numHolders;
    for (uint8 i = 0; i < to.length; i++) {
      newTotalStakes = safeSub(safeAdd(newTotalStakes, value[i]), depositGasCost);
      if(addDeposit(to[i], value[i], numSH, 0))
        numSH = safeAdd(numSH, 1);//save gas costs by increasing a memory variable instead of the storage variable per iteration
    }
    numHolders = numSH;
    //rollback if more tokens have been assigned than the contract possesses
    assert(newTotalStakes < tokenBalance());
    totalStakes = newTotalStakes;
  }
  
  /**
   * updates the stake of an address.
   * @param to the address
   *        value the value to add to the stake
   *        numSH the number of stakeholders
   *        allowedMax the maximum amount a user may stake (0 in case the casino is making the assignment)
   * */
  function addDeposit(address to, uint value, uint numSH, uint allowedMax) internal returns (bool newHolder) {
    require(value > 0);
    uint newStake = safeSub(safeAdd(stakes[to], value), depositGasCost);
    require(newStake >= minStakingAmount);
    if(allowedMax > 0){//if allowedMax > 0 the caller is the user himself
      require(newStake <= allowedMax);
      assert(token.transferFrom(to, address(this), value));
    }
    if(stakes[to] == 0){
      addHolder(to, numSH);
      newHolder = true;
    }
    stakes[to] = newStake;
    emit StakeUpdate(to, newStake);
  }

  /**
   * Transfers the total stakes to the casino contract to be used as bankroll.
   * Callabe only once per cycle and only after a cycle was started.
   * */
  function useAsBankroll() public onlyAuthorized depositPhase {
    initialStakes[cycle] = totalStakes;
    totalStakes = 0; //withdrawals are unlocked until this value is > 0 again and the final stakes have been set
    assert(token.transfer(address(casino), initialStakes[cycle]));
  }

  /**
   * Initiates the next cycle. Callabe only once per cycle and only after the last one was closed.
   * */
  function startNextCycle() public onlyAuthorized {
    // make sure the last cycle was closed, can be called in update or withdraw phase
    require(finalStakes[cycle] > 0);
    cycle = safeAdd(cycle, 1);
  }

  /**
   * Sets the final sum of user stakes for history and profit computation. Callable only once per cycle.
   * The token balance of the contract may not be set as final stake, because there might have occurred unapproved deposits.
   * @param value the number of EDG tokens that were transfered from the bankroll
   * */
  function closeCycle(uint value) public onlyAuthorized bankrollPhase {
    require(tokenBalance() >= value);
    finalStakes[cycle] = safeSub(value, safeMul(updateGasCost, numHolders)/100);//updateGasCost is using 2 decimals
  }

  /**
   * Updates the user shares depending on the difference between final and initial stake.
   * For doing so, it iterates over the array of stakeholders, while it processes max 500 addresses at once.
   * If the array length is bigger than that, the contract remembers the position to start with on the next invocation.
   * Therefore, this method might need to be called multiple times.
   * It does consider the gas costs and subtracts them from the final stakes before computing the profit/loss.
   * As soon as the last stake has been updated, withdrawals are unlocked by setting the totalStakes to the height of final stakes of the cycle.
   * */
  function updateUserShares() public onlyAuthorized updatePhase {
    uint limit = safeAdd(lastUpdateIndex[cycle], maxUpdates);
    if(limit >= numHolders) {
      limit = numHolders;
      totalStakes = finalStakes[cycle]; //enable withdrawals after this method call was processed
      if (cycle > 1) {
        lastUpdateIndex[cycle - 1] = 0;
      }
    }
    address holder;
    uint newStake;
    for(uint i = lastUpdateIndex[cycle]; i < limit; i++){
      holder = stakeholders[i];
      newStake = computeFinalStake(stakes[holder]);
      stakes[holder] = newStake;
      emit StakeUpdate(holder, newStake);
    }
    lastUpdateIndex[cycle] = limit;
  }

  /**
  * In case something goes wrong above, enable the users to withdraw their tokens.
  * Should never be necessary.
  * @param value the number of tokens to release
  **/
  function unlockWithdrawals(uint value) public onlyOwner {
    require(value <= tokenBalance());
    totalStakes = value;
  }

  /**
   * If withdrawals are unlocked (final stakes of the cycle > 0 and totalStakes > 0), this function withdraws tokens from the sender’s balance to
   * the specified address. If no balance remains, the user is removed from the stakeholder array.
   * @param to the receiver
   *        value the number of tokens
   *        index the index of the message sender in the stakeholder array (save gas costs by not looking it up on the contract)
   * */
  function withdraw(address to, uint value, uint index) public withdrawPhase{
    makeWithdrawal(msg.sender, to, value, index);
  }

  /**
   * An authorized casino wallet may use this function to make a withdrawal for the user.
   * The value is subtracted from the signer’s balance and transferred to the specified address.
   * If no balance remains, the signer is removed from the stakeholder array.
   * @param to the receiver
   *        value the number of tokens
   *        index the index of the signer in the stakeholder array (save gas costs by not looking it up on the contract)
   *        v, r, s the signature of the stakeholder
   * */
  function withdrawFor(address to, uint value, uint index, uint8 v, bytes32 r, bytes32 s) public onlyAuthorized withdrawPhase{
    address from = ecrecover(keccak256(to, value, cycle), v, r, s);
    makeWithdrawal(from, to, value, index);
  }
  
  /**
   * internal method for processing the withdrawal.
   * @param from the stakeholder
   *        to the receiver
   *        value the number of tokens
   *        index the index of the message sender in the stakeholder array (save gas costs by not looking it up on the contract)
   * */
  function makeWithdrawal(address from, address to, uint value, uint index) internal{
    if(value == stakes[from]){
      stakes[from] = 0;
      removeHolder(from, index);
      emit StakeUpdate(from, 0);
    }
    else{
      uint newStake = safeSub(stakes[from], value);
      require(newStake >= minStakingAmount);
      stakes[from] = newStake;
      emit StakeUpdate(from, newStake);
    }
    totalStakes = safeSub(totalStakes, value);
    assert(token.transfer(to, safeSub(value, withdrawGasCost)));
  }

  /**
   * Allows the casino to withdraw tokens which do not belong to any stakeholder.
   * This is the case for gas-payback-tokens and if people send their tokens directly to the contract
   * without the approval of the casino.
   * */
  function withdrawExcess() public onlyAuthorized {
    uint value = safeSub(tokenBalance(), totalStakes);
    token.transfer(owner, value);
  }

  /**
   * Closes the contract in state of emergency or on contract update.
   * Transfers all tokens held by the contract to the owner before doing so.
   **/
  function kill() public onlyOwner {
    assert(token.transfer(owner, tokenBalance()));
    selfdestruct(owner);
  }

  /**
   * @return the current token balance of the contract.
   * */
  function tokenBalance() public view returns(uint) {
    return token.balanceOf(address(this));
  }

  /**
  * Adds a new stakeholder to the list.
  * @param holder the address of the stakeholder
  *        numSH  the current number of stakeholders
  **/
  function addHolder(address holder, uint numSH) internal{
    if(numSH < stakeholders.length)
      stakeholders[numSH] = holder;
    else
      stakeholders.push(holder);
  }
  
  /**
  * Removes a stakeholder from the list.
  * @param holder the address of the stakeholder
  *        index  the index of the holder
  **/
  function removeHolder(address holder, uint index) internal{
    require(stakeholders[index] == holder);
    numHolders = safeSub(numHolders, 1);
    stakeholders[index] = stakeholders[numHolders];
  }

  /**
   * computes the final stake.
   * @param initialStake the initial number of tokens the user invested
   * @return finalStake  the final number of tokens the user receives
   * */
  function computeFinalStake(uint initialStake) internal view returns(uint) {
    return safeMul(initialStake, finalStakes[cycle]) / initialStakes[cycle];
  }

  /**
   * verifies if the withdrawal request was signed by an authorized wallet
   * @param to      the receiver address
   *        value   the number of tokens
   *        v, r, s the signature of an authorized wallet
   * */
  function verifySignature(address to, uint value, uint8 v, bytes32 r, bytes32 s) internal view returns(bool) {
    address signer = ecrecover(keccak256(to, value, cycle), v, r, s);
    return casino.authorized(signer);
  }

  /**
   * computes state based on the initial, total and final stakes of the current cycle.
   * @return current state phase
   * */
  function getPhase() internal view returns (StatePhases) {
    if (initialStakes[cycle] == 0) {
      return StatePhases.deposit;
    } else if (finalStakes[cycle] == 0) {
      return StatePhases.bankroll;
    } else if (totalStakes == 0) {
      return StatePhases.update;
    }
    return StatePhases.withdraw;
  }
  
  //check if the sender is an authorized casino wallet
  modifier onlyAuthorized {
    require(casino.authorized(msg.sender));
    _;
  }

  // deposit phase: initialStakes[cycle] == 0
  modifier depositPhase {
    require(getPhase() == StatePhases.deposit);
    _;
  }

  // bankroll phase: initialStakes[cycle] > 0 and finalStakes[cycle] == 0
  modifier bankrollPhase {
    require(getPhase() == StatePhases.bankroll);
    _;
  }

  // update phase: finalStakes[cycle] > 0 and totalStakes == 0
  modifier updatePhase {
    require(getPhase() == StatePhases.update);
    _;
  }

  // withdraw phase: finalStakes[cycle] > 0 and totalStakes > 0
  modifier withdrawPhase {
    require(getPhase() == StatePhases.withdraw);
    _;
  }

}