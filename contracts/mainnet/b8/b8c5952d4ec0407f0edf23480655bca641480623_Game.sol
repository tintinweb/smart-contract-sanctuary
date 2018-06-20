pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Owned {
    address public owner;

    event LogNew(address indexed old, address indexed current);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        emit LogNew(owner, _newOwner);
        owner = _newOwner;
    }
}

contract IMoneyManager {
    function payTo(address _participant, uint256 _revenue) payable public returns(bool);
}

contract Game is Owned {
    using SafeMath for uint256;
    
    // The address of the owner 
    address public ownerWallet;
    // The address of the activator
    mapping(address => bool) internal activator;
    
    // Constants
    uint256 public constant BET = 10 finney; //0.01 ETH
    uint8 public constant ODD = 1;
    uint8 public constant EVEN = 2;
    uint8 public constant noBets = 3;
    uint256 public constant COMMISSION_PERCENTAGE = 10;
    uint256 public constant END_DURATION_BETTING_BLOCK = 5520;
    uint256 public constant TARGET_DURATION_BETTING_BLOCK = 5760;
	
	uint256 public constant CONTRACT_VERSION = 201805311200;
    
    // The address of the moneyManager
    address public moneyManager;
    
    // Array which stores the target blocks
    uint256[] targetBlocks;
    
    // Mappings
    mapping(address => Participant) public participants;

    mapping(uint256 => mapping(uint256 => uint256)) oddAndEvenBets; // Stores the msg.value for the block and the bet (odd or even)

    mapping(uint256 => uint256) blockResult; // Stores if the blockhash&#39;s last char is odd or even
    mapping(uint256 => bytes32) blockHash; // Stores the hash of block (block.number)

    mapping(uint256 => uint256) blockRevenuePerTicket; // Stores the amount of the revenue per person for given block
    mapping(uint256 => bool) isBlockRevenueCalculated; // Stores if the blocks revenue is calculated

    mapping(uint256 => uint256) comissionsAtBlock; // Stores the commision amount for given block
    
    // Public variables
    uint256 public _startBetBlock;
    uint256 public _endBetBlock;

    uint256 public _targetBlock;
    
    // Modifiers
    modifier afterBlock(uint256 _blockNumber) {
        require(block.number >= _blockNumber);
        _;
    }

    modifier onlyActivator(address _activator) {
        require(activator[_activator] == true);
        _;
    }
    
    // Structures
    struct Participant {
        mapping(uint256 => Bet) bets;
        bool isParticipated;
    }

    struct Bet {
        uint256 ODDBets;
		uint256 EVENBets;
        bool isRevenuePaid;
    }
    
    /** @dev Constructor 
      * @param _moneyManager The address of the money manager.
      * @param _ownerWallet The address of the owner.
      * 
      */
    constructor(address _moneyManager, address _ownerWallet) public {
        setMoneyManager(_moneyManager);
        setOwnerWallet(_ownerWallet);
    }
    
    /** @dev Fallback function.
      * Provides functionality for person to bet.
      */
    function() payable public {
        bet(getBlockHashOddOrEven(block.number - 128), msg.value.div(BET));
    }
    
    /** @dev Function which activates the cycle. 
      * Only the activator can call the function.
      * @param _startBlock The starting block of the game.
      * Set the starting block from which the participants can start to bet for target block.
      * Set the end block to which the participants can bet fot target block. 
      * Set the target block for which the participants will bet.
      * @return success Is the activation of the cycle successful.
      */
    function activateCycle(uint256 _startBlock) public onlyActivator(msg.sender) returns (bool _success) {
        if (_startBlock == 0) {
            _startBlock = block.number;
        }
        require(block.number >= _endBetBlock);

        _startBetBlock = _startBlock;
        _endBetBlock = _startBetBlock.add(END_DURATION_BETTING_BLOCK);

        _targetBlock = _startBetBlock.add(TARGET_DURATION_BETTING_BLOCK);
        targetBlocks.push(_targetBlock);

        return true;
    }
    
    // Events
    event LogBet(address indexed participant, uint256 blockNumber, uint8 oddOrEven, uint256 betAmount);
    event LogNewParticipant(address indexed _newParticipant);
    
    /** @dev Function from which everyone can bet 
      * @param oddOrEven The number on which the participant want to bet (it is 1 - ODD or 2 - EVEN).
      * @param betsAmount The amount of tickets the participant want to buy.
      * @return success Is the bet successful.
      */
    function bet(uint8 oddOrEven, uint256 betsAmount) public payable returns (bool _success) {
		require(betsAmount > 0);
		uint256 participantBet = betsAmount.mul(BET);
		require(msg.value == participantBet);
        require(oddOrEven == ODD || oddOrEven == EVEN);
        require(block.number <= _endBetBlock && block.number >= _startBetBlock);

		// @dev - check if participant already betted
		if (participants[msg.sender].isParticipated == false) {
			// create new participant in memory
			Participant memory newParticipant;
			newParticipant.isParticipated = true;
			//save the participant to state
			participants[msg.sender] = newParticipant;
			emit LogNewParticipant(msg.sender);
		}
		
		uint256 betTillNowODD = participants[msg.sender].bets[_targetBlock].ODDBets;
		uint256 betTillNowEVEN = participants[msg.sender].bets[_targetBlock].EVENBets;
		if(oddOrEven == ODD) {
			betTillNowODD = betTillNowODD.add(participantBet);
		} else {
			betTillNowEVEN = betTillNowEVEN.add(participantBet);
		}
		Bet memory newBet = Bet({ODDBets : betTillNowODD, EVENBets: betTillNowEVEN, isRevenuePaid : false});
	
        //save the bet
        participants[msg.sender].bets[_targetBlock] = newBet;
        // save the bet for the block
        oddAndEvenBets[_targetBlock][oddOrEven] = oddAndEvenBets[_targetBlock][oddOrEven].add(msg.value);
        address(moneyManager).transfer(msg.value);
        emit LogBet(msg.sender, _targetBlock, oddOrEven, msg.value);

        return true;
    }
    
    /** @dev Function which calculates the revenue for block.
      * @param _blockNumber The block for which the revenie will be calculated.
      */
    function calculateRevenueAtBlock(uint256 _blockNumber) public afterBlock(_blockNumber) {
        require(isBlockRevenueCalculated[_blockNumber] == false);
        if(oddAndEvenBets[_blockNumber][ODD] > 0 || oddAndEvenBets[_blockNumber][EVEN] > 0) {
            blockResult[_blockNumber] = getBlockHashOddOrEven(_blockNumber);
            require(blockResult[_blockNumber] == ODD || blockResult[_blockNumber] == EVEN);
            if (blockResult[_blockNumber] == ODD) {
                calculateRevenue(_blockNumber, ODD, EVEN);
            } else if (blockResult[_blockNumber] == EVEN) {
                calculateRevenue(_blockNumber, EVEN, ODD);
            }
        } else {
            isBlockRevenueCalculated[_blockNumber] = true;
            blockResult[_blockNumber] = noBets;
        }
    }

    event LogOddOrEven(uint256 blockNumber, bytes32 blockHash, uint256 oddOrEven);
    
    /** @dev Function which calculates the hash of the given block.
      * @param _blockNumber The block for which the hash will be calculated.
      * The function is called by the calculateRevenueAtBlock()
      * @return oddOrEven
      */
    function getBlockHashOddOrEven(uint256 _blockNumber) internal returns (uint8 oddOrEven) {
        blockHash[_blockNumber] = blockhash(_blockNumber);
        uint256 result = uint256(blockHash[_blockNumber]);
        uint256 lastChar = (result * 2 ** 252) / (2 ** 252);
        uint256 _oddOrEven = lastChar % 2;

        emit LogOddOrEven(_blockNumber, blockHash[_blockNumber], _oddOrEven);

        if (_oddOrEven == 1) {
            return ODD;
        } else if (_oddOrEven == 0) {
            return EVEN;
        }
    }

    event LogRevenue(uint256 blockNumber, uint256 winner, uint256 revenue);
    
    /** @dev Function which calculates the revenue of given block.
      * @param _blockNumber The block for which the revenue will be calculated.
      * @param winner The winner bet (1 - odd or 2 - even).
      * @param loser The loser bet (2 even or 1 - odd).
      * The function is called by the calculateRevenueAtBlock()
      */
    function calculateRevenue(uint256 _blockNumber, uint256 winner, uint256 loser) internal {
        uint256 revenue = oddAndEvenBets[_blockNumber][loser];
        if (oddAndEvenBets[_blockNumber][ODD] != 0 && oddAndEvenBets[_blockNumber][EVEN] != 0) {
            uint256 comission = (revenue.div(100)).mul(COMMISSION_PERCENTAGE);
            revenue = revenue.sub(comission);
            comissionsAtBlock[_blockNumber] = comission;
            IMoneyManager(moneyManager).payTo(ownerWallet, comission);
            uint256 winners = oddAndEvenBets[_blockNumber][winner].div(BET);
            blockRevenuePerTicket[_blockNumber] = revenue.div(winners);
        }
        isBlockRevenueCalculated[_blockNumber] = true;
        emit LogRevenue(_blockNumber, winner, revenue);
    }

    event LogpayToRevenue(address indexed participant, uint256 blockNumber, bool revenuePaid);
    
    /** @dev Function which allows the participants to withdraw their revenue.
      * @param _blockNumber The block for which the participants will withdraw their revenue.
      * @return _success Is the revenue withdrawn successfully.
      */
    function withdrawRevenue(uint256 _blockNumber) public returns (bool _success) {
        require(participants[msg.sender].bets[_blockNumber].ODDBets > 0 || participants[msg.sender].bets[_blockNumber].EVENBets > 0);
        require(participants[msg.sender].bets[_blockNumber].isRevenuePaid == false);
        require(isBlockRevenueCalculated[_blockNumber] == true);

        if (oddAndEvenBets[_blockNumber][ODD] == 0 || oddAndEvenBets[_blockNumber][EVEN] == 0) {
			if(participants[msg.sender].bets[_blockNumber].ODDBets > 0) {
				IMoneyManager(moneyManager).payTo(msg.sender, participants[msg.sender].bets[_blockNumber].ODDBets);
			}else{
				IMoneyManager(moneyManager).payTo(msg.sender, participants[msg.sender].bets[_blockNumber].EVENBets);
			}
            participants[msg.sender].bets[_blockNumber].isRevenuePaid = true;
            emit LogpayToRevenue(msg.sender, _blockNumber, participants[msg.sender].bets[_blockNumber].isRevenuePaid);

            return participants[msg.sender].bets[_blockNumber].isRevenuePaid;
        }
        // @dev - initial revenue to be paid
        uint256 _revenue = 0;
        uint256 counter = 0;
		uint256 totalPayment = 0;
        if (blockResult[_blockNumber] == ODD) {
			counter = (participants[msg.sender].bets[_blockNumber].ODDBets).div(BET);
            _revenue = _revenue.add(blockRevenuePerTicket[_blockNumber].mul(counter));
        } else if (blockResult[_blockNumber] == EVEN) {
			counter = (participants[msg.sender].bets[_blockNumber].EVENBets).div(BET);
           _revenue = _revenue.add(blockRevenuePerTicket[_blockNumber].mul(counter));
        }
		totalPayment = _revenue.add(BET.mul(counter));
        // pay the revenue
        IMoneyManager(moneyManager).payTo(msg.sender, totalPayment);
        participants[msg.sender].bets[_blockNumber].isRevenuePaid = true;

        emit LogpayToRevenue(msg.sender, _blockNumber, participants[msg.sender].bets[_blockNumber].isRevenuePaid);
        return participants[msg.sender].bets[_blockNumber].isRevenuePaid;
    }
    
    /** @dev Function which set the activator of the cycle.
      * Only owner can call the function.
      */
    function setActivator(address _newActivator) onlyOwner public returns(bool) {
        require(activator[_newActivator] == false);
        activator[_newActivator] = true;
        return activator[_newActivator];
    }
    
    /** @dev Function which remove the activator.
      * Only owner can call the function.
      */
    function removeActivator(address _Activator) onlyOwner public returns(bool) {
        require(activator[_Activator] == true);
        activator[_Activator] = false;
        return true;
    }
    
    /** @dev Function which set the owner of the wallet.
      * Only owner can call the function.
      * Called when the contract is deploying.
      */
    function setOwnerWallet(address _newOwnerWallet) public onlyOwner {
        emit LogNew(ownerWallet, _newOwnerWallet);
        ownerWallet = _newOwnerWallet;
    }
    
    /** @dev Function which set the money manager.
      * Only owner can call the function.
      * Called when contract is deploying.
      */
    function setMoneyManager(address _moneyManager) public onlyOwner {
        emit LogNew(moneyManager, _moneyManager);
        moneyManager = _moneyManager;
    }
    
    function getActivator(address _isActivator) public view returns(bool) {
        return activator[_isActivator];
    }
    
    /** @dev Function for getting the current block.
      * @return _blockNumber
      */
    function getblock() public view returns (uint256 _blockNumber){
        return block.number;
    }

    /** @dev Function for getting the current cycle info
      * @return startBetBlock, endBetBlock, targetBlock
      */
    function getCycleInfo() public view returns (uint256 startBetBlock, uint256 endBetBlock, uint256 targetBlock){
        return (
        _startBetBlock,
        _endBetBlock,
        _targetBlock);
    }
    
    /** @dev Function for getting the given block hash
      * @param _blockNumber The block number of which you want to check hash.
      * @return _blockHash
      */
    function getBlockHash(uint256 _blockNumber) public view returns (bytes32 _blockHash) {
        return blockHash[_blockNumber];
    }
    
    /** @dev Function for getting the bets for ODD and EVEN.
      * @param _participant The address of the participant whose bets you want to check.
      * @param _blockNumber The block for which you want to check.
      * @return _oddBets, _evenBets
      */
    function getBetAt(address _participant, uint256 _blockNumber) public view returns (uint256 _oddBets, uint256 _evenBets){
        return (participants[_participant].bets[_blockNumber].ODDBets, participants[_participant].bets[_blockNumber].EVENBets);
    }
    
    /** @dev Function for getting the block result if it is ODD or EVEN.
      * @param _blockNumber The block for which you want to get the result.
      * @return _oddOrEven
      */
    function getBlockResult(uint256 _blockNumber) public view returns (uint256 _oddOrEven){
        return blockResult[_blockNumber];
    }
    
    /** @dev Function for getting the wei amount for given block.
      * @param _blockNumber The block for which you want to get wei amount.
      * @param _blockOddOrEven The block which is odd or even.
      * @return _weiAmountAtStage
      */
    function getoddAndEvenBets(uint256 _blockNumber, uint256 _blockOddOrEven) public view returns (uint256 _weiAmountAtStage) {
        return oddAndEvenBets[_blockNumber][_blockOddOrEven];
    }
    
    /** @dev Function for checking if the given address participated in given block.
      * @param _participant The participant whose participation we are going to check.
      * @param _blockNumber The block for which we will check the participation.
      * @return _isParticipate
      */
    function getIsParticipate(address _participant, uint256 _blockNumber) public view returns (bool _isParticipate) {
        return (participants[_participant].bets[_blockNumber].ODDBets > 0 || participants[_participant].bets[_blockNumber].EVENBets > 0);
    }
    
     /** @dev Function for getting the block revenue per ticket.
      * @param _blockNumber The block for which we will calculate revenue per ticket.
      * @return _revenue
      */
    function getblockRevenuePerTicket(uint256 _blockNumber) public view returns (uint256 _revenue) {
        return blockRevenuePerTicket[_blockNumber];
    }
    
    /** @dev Function which tells us is the revenue for given block is calculated.
      * @param _blockNumber The block for which we will check.
      * @return _isCalculated
      */
    function getIsBlockRevenueCalculated(uint256 _blockNumber) public view returns (bool _isCalculated) {
        return isBlockRevenueCalculated[_blockNumber];
    }
    
    /** @dev Function which tells us is the revenue for given block is paid.
      * @param _blockNumber The block for which we will check.
      * @return _isPaid
      */
    function getIsRevenuePaid(address _participant, uint256 _blockNumber) public view returns (bool _isPaid) {
        return participants[_participant].bets[_blockNumber].isRevenuePaid;
    }
    
    /** @dev Function which will return the block commission.
      * @param _blockNumber The block for which we will get the commission.
      * @return _comission
      */
    function getBlockComission(uint256 _blockNumber) public view returns (uint256 _comission) {
        return comissionsAtBlock[_blockNumber];
    }
    
    /** @dev Function which will return the ODD and EVEN bets.
      * @param _blockNumber The block for which we will get the commission.
      * @return _ODDBets, _EVENBets
      */
    function getBetsEvenAndODD(uint256 _blockNumber) public view returns (uint256 _ODDBets, uint256 _EVENBets) {
        return (oddAndEvenBets[_blockNumber][ODD], oddAndEvenBets[_blockNumber][EVEN]);
    }

    /** @dev Function which will return the count of target blocks.
      * @return _targetBlockLenght
      */
    function getTargetBlockLength() public view returns (uint256 _targetBlockLenght) {
        return targetBlocks.length;
    }
    
    /** @dev Function which will return the whole target blocks.
      * @return _targetBlocks Array of target blocks
      */
    function getTargetBlocks() public view returns (uint256[] _targetBlocks) {
        return targetBlocks;
    }
    
    /** @dev Function which will return a specific target block at index.
      * @param _index The index of the target block which we want to get.
      * @return _targetBlockNumber
      */
    function getTargetBlock(uint256 _index) public view returns (uint256 _targetBlockNumber) {
        return targetBlocks[_index];
    }
}