pragma solidity ^0.4.21;


//**********************************************************************************
//	KITTYPILLAR CONTRACT
//**********************************************************************************

contract KittyPillar {
	using SafeMath for uint256;
	
	address public owner;								//owner of this contract
	address public kittyCoreAddress;					//address of kittyCore
	KittyCoreInterface private kittyCore;				//kittycore reference
	
	
//**********************************************************************************
//	Events
//**********************************************************************************
	event PlayerJoined
    (
        address playerAddr,
        uint256 pId,
        uint256 timeStamp
    );
	
	event KittyJoined
    (
        address ownerAddr,
        uint256 kittyId,
		uint8 pillarIdx,
        uint256 contribution,
		uint256 currentRound,
        uint256 timeStamp
    );

	event RoundEnded
	(		
		uint256 currentRId,
		uint256 pillarWon,
		uint256 timeStamp
	);
	
	event Withdrawal
	(
		address playerAddr,
        uint256 pId,
		uint256 amount,
        uint256 timeStamp
	);
	
//**********************************************************************************
//	Modifiers
//**********************************************************************************
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
		
//**********************************************************************************
//	Configs
//**********************************************************************************
	
	uint256 public contributionTarget_ = 100; //round target contributions
	bool public paused_ = false;
	uint256 public joinFee_ = 10000000000000000; //0.01 ether
	uint256 public totalDeveloperCut_ = 0;
	uint256 public minPower_ = 3; //minimum power of kitty
	uint256 public maxPower_ = 20; //maximum power of kitty
	
//**********************************************************************************
//	Data
//**********************************************************************************
	//***************************
	// Round
	//***************************
	uint256 public currentRId_;
	mapping (uint256 => KittyPillarDataSets.Round) public round_;		// (rId => data) round data
	
	//***************************
	// Player 
	//***************************
	uint256 private currentPId_;
	mapping (address => uint256) public pIdByAddress_;          										// (address => pId) returns player id by address
	mapping (uint8 => mapping (uint256 => KittyPillarDataSets.Pillar)) public pillarRounds_;			// (pillarIdx => roundId -> Pillar) returns pillar&#39;s round information
	mapping (uint256 => KittyPillarDataSets.Player) public players_;										// (pId => player) returns player information	
	mapping (uint256 => mapping (uint256 => uint256[])) public playerRounds_;		// (pId => roundId => uint256[]) returns player&#39;s round information
	mapping (uint256 => mapping (uint256 => KittyPillarDataSets.KittyRound)) public kittyRounds_;		// (kittyId => roundId => KittyRound) returns kitty&#39;s round information
	
	
//**********************************************************************************
//	Functions
//**********************************************************************************	
	constructor(address _kittyCoreAddress) public {
		owner = msg.sender; //init owner
		kittyCoreAddress = _kittyCoreAddress;
        kittyCore = KittyCoreInterface(kittyCoreAddress);
		
		//start round
		currentRId_ = 1;
		round_[currentRId_].pot = 0;
		round_[currentRId_].targetContributions = contributionTarget_;
		round_[currentRId_].timeStarted = now;
		round_[currentRId_].ended = false;
	}
	
	function getPillarRoundsKitties(uint8 _pillarIdx, uint256 _rId) external view returns (uint256[]) {
		return pillarRounds_[_pillarIdx][_rId].kittyIds;
	}
	
	function getPlayerRoundsKitties(uint256 _pId, uint256 _rId) external view returns (uint256[]) {
		return playerRounds_[_pId][_rId];
	}
	
	function joinPillarWithEarnings(uint256 _kittyId, uint8 _pillarIdx, uint256 _rId) external {
		require(!paused_, "game is paused");
		
		require((_pillarIdx>=0)&&(_pillarIdx<=2), "there is no such pillar here");

        require(msg.sender == kittyCore.ownerOf(_kittyId), "sender not owner of kitty");
				
		uint256 _pId = pIdByAddress_[msg.sender];
		require(_pId!=0, "not an existing player"); //needs to be an existing player
		
		require(players_[_pId].totalEth >= joinFee_, "insufficient tokens in pouch for join fee");
		
		require(kittyRounds_[_kittyId][currentRId_].contribution==0, "kitty has already joined a pillar this round");
		
		require(_rId == currentRId_, "round has ended, wait for next round");
		
		players_[_pId].totalEth = players_[_pId].totalEth.sub(joinFee_); //deduct joinFee from winnings
		
		joinPillarCore(_pId, _kittyId, _pillarIdx);	
	}
	
	
	function joinPillar(uint256 _kittyId, uint8 _pillarIdx, uint256 _rId) external payable {
		require(!paused_, "game is paused");

        require(msg.value == joinFee_, "incorrect join fee");
		
		require((_pillarIdx>=0)&&(_pillarIdx<=2), "there is no such pillar here");
		
        require(msg.sender == kittyCore.ownerOf(_kittyId), "sender not owner of kitty");
		
		require(kittyRounds_[_kittyId][currentRId_].contribution==0, "kitty has already joined a pillar this round");
		
		require(_rId == currentRId_, "round has ended, wait for next round");
		
		uint256 _pId = pIdByAddress_[msg.sender];
		//add player if he/she doesn&#39;t exists in game
        if (_pId == 0) {
			currentPId_ = currentPId_.add(1);
			pIdByAddress_[msg.sender] = currentPId_;
			players_[currentPId_].ownerAddr = msg.sender;
			_pId = currentPId_;
			
			emit PlayerJoined
			(
				msg.sender,
				_pId,
				now
			);
		}
		
		joinPillarCore(_pId, _kittyId, _pillarIdx);	
	}
	
	function joinPillarCore(uint256 _pId, uint256 _kittyId, uint8 _pillarIdx) private {
		//record kitty under player for this round
		playerRounds_[_pId][currentRId_].push(_kittyId);
						
		//calculate kitty&#39;s power
		uint256 minPower = minPower_;
		if (pillarRounds_[_pillarIdx][currentRId_].totalContributions<(round_[currentRId_].targetContributions/2)) { //pillar under half, check other pillars
			uint8 i;
			for (i=0; i<3; i++) {
				if (i!=_pillarIdx) {
					if (pillarRounds_[i][currentRId_].totalContributions >= (round_[currentRId_].targetContributions/2)) {
						minPower = maxPower_/2; //minimum power increases, so to help the low pillar grow faster
						break;
					}
				}
			}
		}
				
		uint256 genes;
        ( , , , , , , , , , genes) = kittyCore.getKitty(_kittyId);		
		uint256 _contribution = ((getKittyPower(genes) % maxPower_) + minPower); //from min to max power
		
		// add to kitty round
		uint256 joinedTime = now;
		kittyRounds_[_kittyId][currentRId_].pillar = _pillarIdx;
		kittyRounds_[_kittyId][currentRId_].contribution = _contribution;
		kittyRounds_[_kittyId][currentRId_].kittyOwnerPId = _pId;
		kittyRounds_[_kittyId][currentRId_].timeStamp = joinedTime;
		
		// update current round&#39;s info
		pillarRounds_[_pillarIdx][currentRId_].totalContributions = pillarRounds_[_pillarIdx][currentRId_].totalContributions.add(_contribution);
		pillarRounds_[_pillarIdx][currentRId_].kittyIds.push(_kittyId);
				
		//update current round pot
		totalDeveloperCut_ = totalDeveloperCut_.add((msg.value/100).mul(4)); //4% developer fee
		round_[currentRId_].pot = round_[currentRId_].pot.add((msg.value/100).mul(96)); //update pot minus fee
		
		emit KittyJoined
		(
			msg.sender,
			_kittyId,
			_pillarIdx,
			_contribution,
			currentRId_,
			joinedTime
		);
		
		//if meet target contribution, end round
		if (pillarRounds_[_pillarIdx][currentRId_].totalContributions >= round_[currentRId_].targetContributions) {			
			endRound(_pillarIdx);
		}	
	}
	
	
	function getKittyPower(uint256 kittyGene) private view returns(uint256) {
		return (uint(keccak256(abi.encodePacked(kittyGene,
			blockhash(block.number - 1),
			blockhash(block.number - 2),
			blockhash(block.number - 4),
			blockhash(block.number - 7))
		)));
	}
	
	
	function endRound(uint8 _wonPillarIdx) private {
				
		//distribute pot
		uint256 numWinners = pillarRounds_[_wonPillarIdx][currentRId_].kittyIds.length;
						
		
		uint256 numFirstMovers = numWinners / 2; //half but rounded floor
		
		//perform round up if required
		if ((numFirstMovers * 2) < numWinners) {
			numFirstMovers = numFirstMovers.add(1);
		}
		
		uint256 avgTokensPerWinner = round_[currentRId_].pot/numWinners;
		
		//first half (round up) of the pillar kitties get 20% extra off the pot to reward the precision, strength and valor!
		uint256 tokensPerFirstMovers = avgTokensPerWinner.add(avgTokensPerWinner.mul(2) / 10);
		
		//the rest of the pot is divided by the rest of the followers
		uint256 tokensPerFollowers = (round_[currentRId_].pot - (numFirstMovers.mul(tokensPerFirstMovers))) / (numWinners-numFirstMovers);
		
		uint256 totalEthCount = 0;
								
		for(uint256 i = 0; i < numWinners; i++) {
			uint256 kittyId = pillarRounds_[_wonPillarIdx][currentRId_].kittyIds[i];
			if (i < numFirstMovers) {
				players_[kittyRounds_[kittyId][currentRId_].kittyOwnerPId].totalEth = players_[kittyRounds_[kittyId][currentRId_].kittyOwnerPId].totalEth.add(tokensPerFirstMovers);
				totalEthCount = totalEthCount.add(tokensPerFirstMovers);
			} else {
				players_[kittyRounds_[kittyId][currentRId_].kittyOwnerPId].totalEth = players_[kittyRounds_[kittyId][currentRId_].kittyOwnerPId].totalEth.add(tokensPerFollowers);
				totalEthCount = totalEthCount.add(tokensPerFollowers);
			}			
		}
		
				
		//set round param to end
		round_[currentRId_].pillarWon = _wonPillarIdx;
		round_[currentRId_].timeEnded = now;
		round_[currentRId_].ended = true;

		emit RoundEnded(
			currentRId_,
			_wonPillarIdx,
			round_[currentRId_].timeEnded
		);		
		
		//start next round
		currentRId_ = currentRId_.add(1);
		round_[currentRId_].pot = 0;
		round_[currentRId_].targetContributions = contributionTarget_;
		round_[currentRId_].timeStarted = now;
		round_[currentRId_].ended = false;		
	}
	
	function withdrawWinnings() external {
		uint256 _pId = pIdByAddress_[msg.sender];
		//player doesn&#39;t exists in game
		require(_pId != 0, "player doesn&#39;t exist in game, don&#39;t disturb");
		require(players_[_pId].totalEth > 0, "there is nothing to withdraw");
		
		uint256 withdrawalSum = players_[_pId].totalEth;
		players_[_pId].totalEth = 0; //all is gone from contract to user wallet
		
		msg.sender.transfer(withdrawalSum); //byebye ether
		
		emit Withdrawal
		(
			msg.sender,
			_pId,
			withdrawalSum,
			now
		);
	}


//**********************************************************************************
//	Admin Functions
//**********************************************************************************	


	function setJoinFee(uint256 _joinFee) external onlyOwner {
		joinFee_ = _joinFee;
	}
	
	function setPlayConfigs(uint256 _contributionTarget, uint256 _maxPower, uint256 _minPower) external onlyOwner {
		require(_minPower.mul(2) <= _maxPower, "min power cannot be more than half of max power");
		contributionTarget_ = _contributionTarget;
		maxPower_ = _maxPower;
		minPower_ = _minPower;
	}
		
	function setKittyCoreAddress(address _kittyCoreAddress) external onlyOwner {
		kittyCoreAddress = _kittyCoreAddress;
        kittyCore = KittyCoreInterface(kittyCoreAddress);
	}
	
	/**
	* @dev Current owner can transfer control of the contract to a newOwner.
	* @param newOwner The address to transfer ownership to.
	*/
	function transferOwnership(address newOwner) external onlyOwner {
		require(newOwner != address(0));
		owner = newOwner;
	}
	
	function setPaused(bool _paused) external onlyOwner {
		paused_ = _paused;
	}
	
	function withdrawDeveloperCut() external onlyOwner {
		address thisAddress = this;
		uint256 balance = thisAddress.balance;
		uint256 withdrawalSum = totalDeveloperCut_;

		if (balance >= withdrawalSum) {
			totalDeveloperCut_ = 0;
			owner.transfer(withdrawalSum);
		}
	}
	
}



//**********************************************************************************
//	STRUCTS
//**********************************************************************************
library KittyPillarDataSets {	
	struct Round {
		uint256 pot;						// total Eth in pot
		uint256 targetContributions;		// target contribution to end game
		uint8 pillarWon;					// idx of pillar which won this round
		uint256 timeStarted;					// time round started
		uint256 timeEnded;					// time round ended
		bool ended;							// has round ended
	}
	
	struct Pillar {
		uint256 totalContributions;
		uint256[] kittyIds;
	}
	
	struct Player {
        address ownerAddr; 	// player address
		uint256 totalEth;	// total Eth won and not yet claimed
    }
	
	struct KittyRound {
		uint8 pillar;
		uint256 contribution;
		uint256 kittyOwnerPId;
		uint256 timeStamp;
	}	
}
	


//**********************************************************************************
//	INTERFACES
//**********************************************************************************

//Cryptokitties interface
interface KittyCoreInterface {
    function getKitty(uint _id) external returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    );

    function ownerOf(uint256 _tokenId) external view returns (address owner);
}




//**********************************************************************************
//	LIBRARIES
//**********************************************************************************

/**
 * @title SafeMath from OpenZeppelin
 * @dev Math operations with safety checks that throw on error
 * Changes:
 * - changed asserts to require with error log
 * - removed div
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
	require(c / a == b, "SafeMath mul failed");
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath sub failed");
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "SafeMath add failed");
    return c;
  }
}