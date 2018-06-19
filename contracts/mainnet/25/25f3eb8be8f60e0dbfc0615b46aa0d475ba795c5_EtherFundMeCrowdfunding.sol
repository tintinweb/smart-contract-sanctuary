pragma solidity ^0.4.16;


/// @title etherfund.me  basic crowdfunding contract
contract EtherFundMeCrowdfunding {

	/// The crowdfunding project name
	string public name;

	/// The crowdfunding project description
	string public description;

    /// The crowdfunding team contact
	string public teamContact;

	/// The start time of crowdfunding
    uint public startsAt;

	/// The end time of crowdfunding
    uint public endsAt;

	/// Crowdfunding team wallet
    address public team;

    /// etherfund.me fee wallet
    address public feeReceiver;

	/// etherfund.me deploy agent
	address public deployAgent;

	/// if the funding goal is not reached, investors may withdraw their funds
    uint public fundingGoal;

    ///  How many distinct addresses have invested
    uint public investorCount = 0;

	///  Has this crowdfunding been finalized
    bool public finalized;

    ///  Has this crowdfunding been paused
	bool public halted;

    ///  How much ETH each address has invested to this crowdfunding
    mapping (address => uint256) public investedAmountOf;

	/// etherfund.me final fee in %
    uint public constant ETHERFUNDME_FEE = 2;

	/// etherfund.me each transaction fee in %
    uint public constant ETHERFUNDME_ONLINE_FEE = 1;

    /// if a project reach 60% of their funding goal it becomes successful
	uint public constant GOAL_REACHED_CRITERION = 60;

	/// State machine
	/// Preparing: All contract initialization calls and variables have not been set yet
	/// Funding: Active crowdsale
	/// Success: Minimum funding goal reached
	/// Failure: Minimum funding goal not reached before ending time
	/// Finalized: The finalized has been called and succesfully executed
	/// Refunding: Refunds are loaded on the contract for reclaim
    enum State { Unknown, Preparing, Funding, Success, Failure, Finalized, Refunding }

    /// A new investment was made
    event Invested(address investor, uint weiAmount);

    /// Withdraw was processed for a contributor
    event Withdraw(address receiver, uint weiAmount);

    /// Returning funds for a contributor
    event Refund(address receiver, uint weiAmount);

    /// Modified allowing execution only if the crowdfunding is currently running
	 modifier inState(State state) {
		require(getState() == state);
		_;
	 }

	 /// Modified allowing execution only if deploy agent call
	 modifier onlyDeployAgent() {
		require(msg.sender == deployAgent);
		_;
	 }

	 /// Modified allowing execution only if not stopped
	 modifier stopInEmergency {
		require(!halted);
		_;
	 }

	 /// Modified allowing execution only if stopped
	 modifier onlyInEmergency {
		require(halted);
		_;
	 }

	 /// @dev Constructor
	 /// @param _name crowdfunding project name
	 /// @param _description crowdfunding project short description
	 /// @param _teamContact crowdfunding team contact
	 /// @param _startsAt crowdfunding start time
	 /// @param _endsAt crowdfunding end time
	 /// @param _fundingGoal funding goal in wei
	 /// @param _team  team address
	 /// @param _feeReceiver  fee receiver address
	 function EtherFundMeCrowdfunding(string _name, string _description, string _teamContact, uint _startsAt, uint _endsAt, uint _fundingGoal, address _team, address _feeReceiver) {
		require(_startsAt != 0);
	 	require(_endsAt != 0);
		require(_fundingGoal != 0);
	 	require(_team != 0);
		require(_feeReceiver != 0);

		deployAgent = msg.sender;
		name = _name;
		description = _description;
		teamContact = _teamContact;
		startsAt = _startsAt;
		endsAt = _endsAt;
		fundingGoal = _fundingGoal;
		team = _team;
		feeReceiver = _feeReceiver;
	 }

	 /// @dev Crowdfund state machine management.
	 /// @return State current state
	function getState() public constant returns (State) {
		if (finalized)
			return State.Finalized;
		if (startsAt > now)
			return State.Preparing;
		if (now >= startsAt && now < endsAt)
			return State.Funding;
		if (isGoalReached())
			return State.Success;
		if (!isGoalReached() && this.balance > 0)
			return State.Refunding;
		return State.Failure;
	}

	/// @dev Goal was reached
	/// @return true if the crowdsale has raised enough money to be a succes
	function isGoalReached() public constant returns (bool reached) {
		return this.balance >= (fundingGoal * GOAL_REACHED_CRITERION) / 100;
	}

	 /// @dev Fallback method
	 function() payable {
		invest();
	 }

	 /// @dev Allow contributions to this crowdfunding.
	 function invest() public payable stopInEmergency  {
		require(getState() == State.Funding);
		require(msg.value > 0);

		uint weiAmount = msg.value;
		address investor = msg.sender;

		if(investedAmountOf[investor] == 0) {
			// A new investor
			investorCount++;
		}

	    // calculate online fee
		uint onlineFeeAmount = (weiAmount * ETHERFUNDME_ONLINE_FEE) / 100;
		Withdraw(feeReceiver, onlineFeeAmount);
		// send online fee
		feeReceiver.transfer(onlineFeeAmount);

		uint investedAmount = weiAmount - onlineFeeAmount;
		// Update investor
		investedAmountOf[investor] += investedAmount;
		// Tell us invest was success
		Invested(investor, investedAmount);
	 }

	 /// @dev Finalize a succcesful crowdfunding. The team can triggre a call the contract that provides post-crowdfunding actions, like releasing the funds.
	 function finalize() public inState(State.Success) stopInEmergency  {
		require(msg.sender == deployAgent || msg.sender == team);
		require(!finalized);

		finalized = true;

		uint feeAmount = (this.balance * ETHERFUNDME_FEE) / 100;
		uint teamAmount = this.balance - feeAmount;

		Withdraw(team, teamAmount);
		team.transfer(teamAmount);

		Withdraw(feeReceiver, feeAmount);
		feeReceiver.transfer(feeAmount);
	 }

	 /// @dev Investors can claim refund.
	 function refund() public inState(State.Refunding) {
		uint weiValue = investedAmountOf[msg.sender];
	    if (weiValue == 0) revert();
	    investedAmountOf[msg.sender] = 0;
	    Refund(msg.sender, weiValue);
		msg.sender.transfer(weiValue);
	 }

	 /// called by the deploy agent on emergency, triggers stopped state
	 function halt() public onlyDeployAgent {
		halted = true;
	 }

	 /// called by the deploy agent on end of emergency, returns to normal state
	 function unhalt() public onlyDeployAgent onlyInEmergency {
		halted = false;
	 }
}