// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./IDAS.sol";
import "./Ownable.sol";



contract DAS is IDAS, Ownable, ReentrancyGuard{

	mapping(uint32 => SRR) private _srr;

	uint32 private _latestRequest;
	uint32 private _requestID;

	/*
	 * Record of witness addresses
	 * {RequestID => {WitnessCounter => WitnessAddress}}
	 */
	mapping(uint32 => mapping(address => bool)) private _witnesses;



	// New request can only be made after 7 days passed since the previous reqest.
	uint32 internal constant DAYS_CONSECUTIVE_REQUEST_INTERVAL = 7;

	// Any release request can only be realized after given number of days later than amendedOn
	uint32 internal constant DAYS_MIN_WITNESS_PERIOD = 7;

	constructor() payable{

	}

	function today() public view returns (uint32 dayNumber) {
		return uint32(block.timestamp / 86400);
	}

	function _generateRequestID() private returns(uint32){
		require(_requestID < 4294967296, "DAS> E18: Maximum request is reached.");

		_requestID = _requestID + 1;
		return _requestID;
	}

	function getRequestID() external view override returns (uint32) {
		return _requestID;
	}

	function getLatestRequest() external view override returns (uint32) {
		return _latestRequest;
	}

	function getSRR(uint32 ID) external view override returns (SRR memory) {
		return _srr[ID];
	}


	/*
	 * Recieve ether.
	 */
	receive() external payable{
		emit Received(msg.sender, msg.value);
	}

	function withdraw(uint256 amount) external onlyOwner nonReentrant{
		payable(msg.sender).transfer(amount);
	}


	function dispatch(
		address token, 
		address destination,
		uint256 amount, 
		uint256 bounty,
		uint32 maxWitness, 
		uint32 witnessPeriod, 
		uint256 witnessCapThreshold
	) external onlyOwner override{
		require(token                                  != address(0), "DAS> E01: Invalid token contract.");
		require(address(this).balance                  >= bounty,     "DAS> E02: Insufficent ether funds.");
		require(IERC20(token).balanceOf(address(this)) >= amount,     "DAS> E04: Insufficent token balance.");

		if(_latestRequest > 0){
			require(today() >= _latestRequest);
			require(today() - _latestRequest > DAYS_CONSECUTIVE_REQUEST_INTERVAL, "DAS> E05: Request limit exceeded. Please try again later.");
		}
		_latestRequest = today();

		require(witnessPeriod >= DAYS_MIN_WITNESS_PERIOD, "DAS> E06: Illegal witness period.");
		require(bounty % maxWitness == 0, "DAS> E07: Illegal bounty amount. It should be divisable to number of maxWitnesses evenly.");

		uint32 ID = _generateRequestID();
		_srr[ID] = SRR(
			ID,
			token,
			destination,											
			amount,														
			bounty,														
			_latestRequest,										// dispatchedOn
			_latestRequest + witnessPeriod,		// availableOn
			maxWitness,											 
			0,											 
			witnessCapThreshold,
			Status.ACTIVE
		);
	}


	function witness(uint32 ID) external nonReentrant override{
		SRR storage srr = _srr[ID];

		require(srr.ID == ID,                           "DAS> E11: Invalid SRR ID.");
		require(srr.status == Status.ACTIVE,            "DAS> E12: Invalid SRR status.");
		require(today() < srr.availableOn,              "DAS> E13: SRR witness period has ended.");
		require(today() >= srr.dispatchedOn,            "DAS> E17: SRR period not started yet.");
		require(srr.totalWitness < srr.maxWitness,      "DAS> E14: SRR witness limit is reached.");
		require(_witnesses[srr.ID][msg.sender] != true, "DAS> E18: Already witnessed.");

		// see if witness candidate satisfies the token threshold. 
		if(srr.witnessCapThreshold > 0){
			require(IERC20(srr.token).balanceOf(msg.sender) >= srr.witnessCapThreshold, "DAS> E15: Token threshold capacity is not satisfied.");
		}

		srr.totalWitness = srr.totalWitness + 1;
		_witnesses[srr.ID][msg.sender] = true;

		uint256 amount = srr.bounty / srr.maxWitness;

		if(srr.bounty > 0){
			(bool sent, bytes memory data) = payable(msg.sender).call{value: amount}("");
			require(sent, "DAS> E16: Bounty transfer failed.");
		}

		emit Witness(srr.ID, msg.sender, amount);
	}


	/*
	 * Perform supply
	 */
	function release(uint32 ID) external onlyOwner nonReentrant override{
		SRR storage srr = _srr[ID];

		require(srr.ID == ID,                             "DAS> E08: Invalid SRR ID.");
		require(srr.status == Status.ACTIVE,              "DAS> E09: Invalid SRR status.");
		require(srr.availableOn <= today(),               "DAS> E10: SRR not available yet.");

		IERC20(srr.token).transfer(srr.destination, srr.amount);

		srr.status = Status.OK;
	}

}