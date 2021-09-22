pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";

import "./ReentrancyGuard.sol";


contract Staking is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeMath for uint256;
    using SafeMath for uint8;



    struct Stake{
        uint deposit_amount;        //Deposited Amount
        uint stake_creation_time;   //The time when the stake was created
        bool returned;              //Specifies if the funds were withdrawed
        uint alreadyWithdrawedAmount;   //TODO Correct Lint
    }


    struct Account{
        address referral;
        uint referralAlreadyWithdrawed;
    }


    //---------------------------------------------------------------------
    //-------------------------- EVENTS -----------------------------------
    //---------------------------------------------------------------------


    /**
    *   @dev Emitted when the pot value changes
     */
    event PotUpdated(
        uint newPot
    );


    /**
    *   @dev Emitted when a customer tries to withdraw an amount
    *       of token greater than the one in the pot
     */
    event PotExhausted(

    );


    /**
    *   @dev Emitted when a new stake is issued
     */
    event NewStake(
        uint stakeAmount,
        address from
    );

    /**
    *   @dev Emitted when a new stake is withdrawed
     */
    event StakeWithdraw(
        uint stakeID,
        uint amount
    );

    /**
    *   @dev Emitted when a referral reward is sent
     */
    event referralRewardSent(
        address account,
        uint reward
    );

    event rewardWithdrawed(
        address account
    );


    /**
    *   @dev Emitted when the machine is stopped (500.000 tokens)
     */
    event machineStopped(
    );

    /**
    *   @dev Emitted when the subscription is stopped (400.000 tokens)
     */
    event subscriptionStopped(
    );



    //--------------------------------------------------------------------
    //-------------------------- GLOBALS -----------------------------------
    //--------------------------------------------------------------------

    mapping (address => Stake[]) private stake; /// @dev Map that contains account's stakes

    address private tokenAddress;

    ERC20 private ERC20Interface;

    uint private pot;    //The pot where token are taken

    uint256 private amount_supplied;    //Store the remaining token to be supplied

    uint private pauseTime;     //Time when the machine paused
    uint private stopTime;      //Time when the machine stopped




    // @dev Mapping the referrals
    mapping (address => address[]) private referral;    //Store account that used the referral

    mapping (address => Account) private account_referral;  //Store the setted account referral


    address[] private activeAccounts;   //Store both staker and referer address


    uint256 private constant _DECIMALS = 18;

    uint256 private constant _INTEREST_PERIOD = 1 days;    //One Month
    uint256 private constant _INTEREST_VALUE = 333;    //0.333% per day

    uint256 private constant _PENALTY_VALUE = 20;    //20% of the total stake



    uint256 private constant _MIN_STAKE_AMOUNT = 100 * (10**_DECIMALS);

    uint256 private constant _MAX_STAKE_AMOUNT = 100000 * (10**_DECIMALS);

    uint private constant _REFERALL_REWARD = 333; //0.333% per day

    uint256 private constant _MAX_TOKEN_SUPPLY_LIMIT =     50000000 * (10**_DECIMALS);
    uint256 private constant _MIDTERM_TOKEN_SUPPLY_LIMIT = 40000000 * (10**_DECIMALS);


    constructor() public {
        pot = 0;
        amount_supplied = _MAX_TOKEN_SUPPLY_LIMIT;    //The total amount of token released
        tokenAddress = address(0);
    }

    //--------------------------------------------------------------------
    //-------------------------- TOKEN ADDRESS -----------------------------------
    //--------------------------------------------------------------------


    function setTokenAddress(address _tokenAddress) external onlyOwner {
        require(Address.isContract(_tokenAddress), "The address does not point to a contract");

        tokenAddress = _tokenAddress;
        ERC20Interface = ERC20(tokenAddress);
    }

    function isTokenSet() external view returns (bool) {
        if(tokenAddress == address(0))
            return false;
        return true;
    }

    function getTokenAddress() external view returns (address){
        return tokenAddress;
    }

    //--------------------------------------------------------------------
    //-------------------------- ONLY OWNER -----------------------------------
    //--------------------------------------------------------------------


    function depositPot(uint _amount) external onlyOwner nonReentrant {
        require(tokenAddress != address(0), "The Token Contract is not specified");

        pot = pot.add(_amount);

        if(ERC20Interface.transferFrom(msg.sender, address(this), _amount)){
            //Emit the event to update the UI
            emit PotUpdated(pot);
        }else{
            revert("Unable to tranfer funds");
        }

    }


    function returnPot(uint _amount) external onlyOwner nonReentrant{
        require(tokenAddress != address(0), "The Token Contract is not specified");
        require(pot.sub(_amount) >= 0, "Not enough token");

        pot = pot.sub(_amount);

        if(ERC20Interface.transfer(msg.sender, _amount)){
            //Emit the event to update the UI
            emit PotUpdated(pot);
        }else{
            revert("Unable to tranfer funds");
        }

    }


    function finalShutdown() external onlyOwner nonReentrant{

        uint machineAmount = getMachineBalance();

        if(!ERC20Interface.transfer(owner(), machineAmount)){
            revert("Unable to transfer funds");
        }
        //Goodbye
    }

    function getAllAccount() external onlyOwner view returns (address[] memory){
        return activeAccounts;
    }

    /**
    *   @dev Check if the pot has enough balance to satisfy the potential withdraw
     */
    function getPotentialWithdrawAmount() external onlyOwner view returns (uint){
        uint accountNumber = activeAccounts.length;

        uint potentialAmount = 0;

        for(uint i = 0; i<accountNumber; i++){

            address currentAccount = activeAccounts[i];

            potentialAmount = potentialAmount.add(calculateTotalRewardReferral(currentAccount));    //Referral

            potentialAmount = potentialAmount.add(calculateTotalRewardToWithdraw(currentAccount));  //Normal Reward
        }

        return potentialAmount;
    }


    //--------------------------------------------------------------------
    //-------------------------- CLIENTS -----------------------------------
    //--------------------------------------------------------------------

    /**
    *   @dev Stake token verifying all the contraint
    *   @notice Stake tokens
    *   @param _amount Amoun to stake
    *   @param _referralAddress Address of the referer; 0x000...1 if no referer is provided
     */
    function stakeToken(uint _amount, address _referralAddress) external nonReentrant {

        require(tokenAddress != address(0), "No contract set");

        require(_amount >= _MIN_STAKE_AMOUNT, "You must stake at least 100 tokens");
        require(_amount <= _MAX_STAKE_AMOUNT, "You must stake at maximum 100000 tokens");

        require(!isSubscriptionEnded(), "Subscription ended");

        address staker = msg.sender;
        Stake memory newStake;

        newStake.deposit_amount = _amount;
        newStake.returned = false;
        newStake.stake_creation_time = now;
        newStake.alreadyWithdrawedAmount = 0;

        stake[staker].push(newStake);

        if(!hasReferral()){
            setReferral(_referralAddress);
        }

        activeAccounts.push(msg.sender);

        if(ERC20Interface.transferFrom(msg.sender, address(this), _amount)){
            emit NewStake(_amount, _referralAddress);
        }else{
            revert("Unable to transfer funds");
        }


    }

    /**
    *   @dev Return the staked tokens, requiring that the stake was
    *        not alreay withdrawed
    *   @notice Return staked token
    *   @param _stakeID The ID of the stake to be returned
     */
    function returnTokens(uint _stakeID) external nonReentrant returns (bool){
        Stake memory selectedStake = stake[msg.sender][_stakeID];

        //Check if the stake were already withdraw
        require(selectedStake.returned == false, "Stake were already returned");

        uint deposited_amount = selectedStake.deposit_amount;
        //Get the net reward
        uint penalty = calculatePenalty(deposited_amount);

        //Sum the net reward to the total reward to withdraw
        uint total_amount = deposited_amount.sub(penalty);


        //Update the supplied amount considering also the penalty
        uint supplied = deposited_amount.sub(total_amount);
        require(updateSuppliedToken(supplied), "Limit reached");

        //Add the penalty to the pot
        pot = pot.add(penalty);


        //Only set the withdraw flag in order to disable further withdraw
        stake[msg.sender][_stakeID].returned = true;

        if(ERC20Interface.transfer(msg.sender, total_amount)){
            emit StakeWithdraw(_stakeID, total_amount);
        }else{
            revert("Unable to transfer funds");
        }


        return true;
    }


    function withdrawReward(uint _stakeID) external nonReentrant returns (bool){
        Stake memory _stake = stake[msg.sender][_stakeID];

        uint rewardToWithdraw = calculateRewardToWithdraw(_stakeID);

        require(updateSuppliedToken(rewardToWithdraw), "Supplied limit reached");

        if(rewardToWithdraw > pot){
            revert("Pot exhausted");
        }

        pot = pot.sub(rewardToWithdraw);

        stake[msg.sender][_stakeID].alreadyWithdrawedAmount = _stake.alreadyWithdrawedAmount.add(rewardToWithdraw);

        if(ERC20Interface.transfer(msg.sender, rewardToWithdraw)){
            emit rewardWithdrawed(msg.sender);
        }else{
            revert("Unable to transfer funds");
        }

        return true;
    }


    function withdrawReferralReward() external nonReentrant returns (bool){
        uint referralCount = referral[msg.sender].length;

        uint totalAmount = 0;

        for(uint i = 0; i<referralCount; i++){
            address currentAccount = referral[msg.sender][i];
            uint currentReward = calculateRewardReferral(currentAccount);

            totalAmount = totalAmount.add(currentReward);

            //Update the alreadyWithdrawed status
            account_referral[currentAccount].referralAlreadyWithdrawed = account_referral[currentAccount].referralAlreadyWithdrawed.add(currentReward);
        }

        require(updateSuppliedToken(totalAmount), "Machine limit reached");

        //require(withdrawFromPot(totalAmount), "Pot exhausted");

        if(totalAmount > pot){
            revert("Pot exhausted");
        }

        pot = pot.sub(totalAmount);


        if(ERC20Interface.transfer(msg.sender, totalAmount)){
            emit referralRewardSent(msg.sender, totalAmount);
        }else{
            revert("Unable to transfer funds");
        }


        return true;
    }

    /**
    *   @dev Check if the provided amount is available in the pot
    *   If yes, it will update the pot value and return true
    *   Otherwise it will emit a PotExhausted event and return false
     */
    function withdrawFromPot(uint _amount) public nonReentrant returns (bool){

        if(_amount > pot){
            emit PotExhausted();
            return false;
        }

        //Update the pot value

        pot = pot.sub(_amount);
        return true;

    }


    //--------------------------------------------------------------------
    //-------------------------- VIEWS -----------------------------------
    //--------------------------------------------------------------------

    /**
    * @dev Return the amount of token in the provided caller's stake
    * @param _stakeID The ID of the stake of the caller
     */
    function getCurrentStakeAmount(uint _stakeID) external view returns (uint256)  {
        require(tokenAddress != address(0), "No contract set");

        return stake[msg.sender][_stakeID].deposit_amount;
    }

    /**
    * @dev Return sum of all the caller's stake amount
    * @return Amount of stake
     */
    function getTotalStakeAmount() external view returns (uint256) {
        require(tokenAddress != address(0), "No contract set");

        Stake[] memory currentStake = stake[msg.sender];
        uint nummberOfStake = stake[msg.sender].length;
        uint totalStake = 0;
        uint tmp;
        for (uint i = 0; i<nummberOfStake; i++){
            tmp = currentStake[i].deposit_amount;
            totalStake = totalStake.add(tmp);
        }

        return totalStake;
    }

    /**
    *   @dev Return all the available stake info
    *   @notice Return stake info
    *   @param _stakeID ID of the stake which info is returned
    *
    *   @return 1) Amount Deposited
    *   @return 2) Bool value that tells if the stake was withdrawed
    *   @return 3) Stake creation time (Unix timestamp)
    *   @return 4) The eventual referAccountess != address(0), "No contract set");
    *   @return 5) The current amount
    *   @return 6) The penalty of withdraw
    */
    function getStakeInfo(uint _stakeID) external view returns(uint, bool, uint, address, uint, uint){

        Stake memory selectedStake = stake[msg.sender][_stakeID];

        uint amountToWithdraw = calculateRewardToWithdraw(_stakeID);

        uint penalty = calculatePenalty(selectedStake.deposit_amount);

        address myReferral = getMyReferral();

        return (
            selectedStake.deposit_amount,
            selectedStake.returned,
            selectedStake.stake_creation_time,
            myReferral,
            amountToWithdraw,
            penalty
        );
    }


    /**
    *  @dev Get the current pot value
    *  @return The amount of token in the current pot
     */
    function getCurrentPot() external view returns (uint){
        return pot;
    }

    /**
    * @dev Get the number of active stake of the caller
    * @return Number of active stake
     */
    function getStakeCount() external view returns (uint){
        return stake[msg.sender].length;
    }


    function getActiveStakeCount() external view returns(uint){
        uint stakeCount = stake[msg.sender].length;

        uint count = 0;

        for(uint i = 0; i<stakeCount; i++){
            if(!stake[msg.sender][i].returned){
                count = count + 1;
            }
        }
        return count;
    }


    function getReferralCount() external view returns (uint) {
        return referral[msg.sender].length;
    }

    function getAccountReferral() external view returns (address[] memory){
        referral[msg.sender];
    }

    function getAlreadyWithdrawedAmount(uint _stakeID) external view returns (uint){
        return stake[msg.sender][_stakeID].alreadyWithdrawedAmount;
    }


    //--------------------------------------------------------------------
    //-------------------------- REFERRALS -----------------------------------
    //--------------------------------------------------------------------


    function hasReferral() public view returns (bool){

        Account memory myAccount = account_referral[msg.sender];

        if(myAccount.referral == address(0) || myAccount.referral == address(0x0000000000000000000000000000000000000001)){
            //If I have no referral...
            assert(myAccount.referralAlreadyWithdrawed == 0);
            return false;
        }

        return true;
    }


    function getMyReferral() public view returns (address){
        Account memory myAccount = account_referral[msg.sender];

        return myAccount.referral;
    }


    function setReferral(address referer) internal {
        require(referer != address(0), "Invalid address");
        require(!hasReferral(), "Referral already setted");

        if(referer == address(0x0000000000000000000000000000000000000001)){
            return;   //This means no referer
        }

        if(referer == msg.sender){
            revert("Referral is the same as the sender, forbidden");
        }

        referral[referer].push(msg.sender);

        Account memory account;

        account.referral = referer;
        account.referralAlreadyWithdrawed = 0;

        account_referral[msg.sender] = account;

        activeAccounts.push(referer);    //Add to the list of active account for pot calculation
    }


    function getCurrentReferrals() external view returns (address[] memory){
        return referral[msg.sender];
    }


    /**
    *   @dev Calculate the current referral reward of the specified customer
    *   @return The amount of referral reward related to the given customer
     */
    function calculateRewardReferral(address customer) public view returns (uint){

        uint lowestStake;
        uint lowStakeID;
        (lowestStake, lowStakeID) = getLowestStake(customer);

        if(lowestStake == 0 && lowStakeID == 0){
            return 0;
        }

        uint periods = calculateAccountStakePeriods(customer, lowStakeID);

        uint currentReward = lowestStake.mul(_REFERALL_REWARD).mul(periods).div(100000);

        uint alreadyWithdrawed = account_referral[customer].referralAlreadyWithdrawed;


        if(currentReward <= alreadyWithdrawed){
            return 0;   //Already withdrawed all the in the past
        }


        uint availableReward = currentReward.sub(alreadyWithdrawed);

        return availableReward;
    }


    function calculateTotalRewardReferral() external view returns (uint){

        uint referralCount = referral[msg.sender].length;

        uint totalAmount = 0;

        for(uint i = 0; i<referralCount; i++){
            totalAmount = totalAmount.add(calculateRewardReferral(referral[msg.sender][i]));
        }

        return totalAmount;
    }

    function calculateTotalRewardReferral(address _account) public view returns (uint){

        uint referralCount = referral[_account].length;

        uint totalAmount = 0;

        for(uint i = 0; i<referralCount; i++){
            totalAmount = totalAmount.add(calculateRewardReferral(referral[_account][i]));
        }

        return totalAmount;
    }

    /**
     * @dev Returns the lowest stake info of the current account
     * @param customer Customer where the lowest stake is returned
     * @return uint The stake amount
     * @return uint The stake ID
     */
    function getLowestStake(address customer) public view returns (uint, uint){
        uint stakeNumber = stake[customer].length;
        uint min = _MAX_STAKE_AMOUNT;
        uint minID = 0;
        bool foundFlag = false;

        for(uint i = 0; i<stakeNumber; i++){
            if(stake[customer][i].deposit_amount <= min){
                if(stake[customer][i].returned){
                    continue;
                }
                min = stake[customer][i].deposit_amount;
                minID = i;
                foundFlag = true;
            }
        }


        if(!foundFlag){
            return (0, 0);
        }else{
            return (min, minID);
        }

    }



    //--------------------------------------------------------------------
    //-------------------------- INTERNAL -----------------------------------
    //--------------------------------------------------------------------

    /**
     * @dev Calculate the customer reward based on the provided stake
     * param uint _stakeID The stake where the reward should be calculated
     * @return The reward value
     */
    function calculateRewardToWithdraw(uint _stakeID) public view returns (uint){
        Stake memory _stake = stake[msg.sender][_stakeID];

        uint amount_staked = _stake.deposit_amount;
        uint already_withdrawed = _stake.alreadyWithdrawedAmount;

        uint periods = calculatePeriods(_stakeID);  //Periods for interest calculation

        uint interest = amount_staked.mul(_INTEREST_VALUE);

        uint total_interest = interest.mul(periods).div(100000);

        uint reward = total_interest.sub(already_withdrawed); //Subtract the already withdrawed amount

        return reward;
    }

    function calculateRewardToWithdraw(address _account, uint _stakeID) internal view onlyOwner returns (uint){
        Stake memory _stake = stake[_account][_stakeID];

        uint amount_staked = _stake.deposit_amount;
        uint already_withdrawed = _stake.alreadyWithdrawedAmount;

        uint periods = calculateAccountStakePeriods(_account, _stakeID);  //Periods for interest calculation

        uint interest = amount_staked.mul(_INTEREST_VALUE);

        uint total_interest = interest.mul(periods).div(100000);

        uint reward = total_interest.sub(already_withdrawed); //Subtract the already withdrawed amount

        return reward;
    }

    function calculateTotalRewardToWithdraw(address _account) internal view onlyOwner returns (uint){
        Stake[] memory accountStakes = stake[_account];

        uint stakeNumber = accountStakes.length;
        uint amount = 0;

        for( uint i = 0; i<stakeNumber; i++){
            amount = amount.add(calculateRewardToWithdraw(_account, i));
        }

        return amount;
    }

    function calculateCompoundInterest(uint _stakeID) external view returns (uint256){

        Stake memory _stake = stake[msg.sender][_stakeID];

        uint256 periods = calculatePeriods(_stakeID);
        uint256 amount_staked = _stake.deposit_amount;

        uint256 excepted_amount = amount_staked;

        //Calculate reward
        for(uint i = 0; i < periods; i++){

            uint256 period_interest;

            period_interest = excepted_amount.mul(_INTEREST_VALUE).div(100);

            excepted_amount = excepted_amount.add(period_interest);
        }

        assert(excepted_amount >= amount_staked);

        return excepted_amount;
    }

    function calculatePeriods(uint _stakeID) public view returns (uint){
        Stake memory _stake = stake[msg.sender][_stakeID];


        uint creation_time = _stake.stake_creation_time;
        uint current_time = now;

        uint total_period = current_time.sub(creation_time);

        uint periods = total_period.div(_INTEREST_PERIOD);

        return periods;
    }

    function calculateAccountStakePeriods(address _account, uint _stakeID) public view returns (uint){
        Stake memory _stake = stake[_account][_stakeID];


        uint creation_time = _stake.stake_creation_time;
        uint current_time = now;

        uint total_period = current_time.sub(creation_time);

        uint periods = total_period.div(_INTEREST_PERIOD);

        return periods;
    }

    function calculatePenalty(uint _amountStaked) private pure returns (uint){
        uint tmp_penalty = _amountStaked.mul(_PENALTY_VALUE);   //Take the 10 percent
        return tmp_penalty.div(100);
    }

    function updateSuppliedToken(uint _amount) internal returns (bool){
        
        if(_amount > amount_supplied){
            return false;
        }
        
        amount_supplied = amount_supplied.sub(_amount);
        return true;
    }

    function checkPotBalance(uint _amount) internal view returns (bool){
        if(pot >= _amount){
            return true;
        }
        return false;
    }



    function getMachineBalance() internal view returns (uint){
        return ERC20Interface.balanceOf(address(this));
    }

    function getMachineState() external view returns (uint){
        return amount_supplied;
    }

    function isSubscriptionEnded() public view returns (bool){
        if(amount_supplied >= _MAX_TOKEN_SUPPLY_LIMIT - _MIDTERM_TOKEN_SUPPLY_LIMIT){
            return false;
        }else{
            return true;
        }
    }

    function isMachineStopped() public view returns (bool){
        if(amount_supplied > 0){
            return true;
        }else{
            return false;
        }
    }

    //--------------------------------------------------------------
    //------------------------ DEBUG -------------------------------
    //--------------------------------------------------------------

    function getOwner() external view returns (address){
        return owner();
    }

}