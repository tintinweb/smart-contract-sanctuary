pragma solidity ^0.4.24;

contract INTIME {
    using SafeMath for *;
    
    struct Player {
        uint id;
        uint referrer;
        uint generation;
        string name;
        uint256 weight;
        uint256 balance;
        uint256 withdrawal;
        uint256 referralBonus;
        uint256 lastKeyBonus;
        uint256 potBonus;
        uint256 stakingBonus;
        uint256 airdropBonus;
    }
    
    mapping(address => Player) public players;
    
    // System
    address public teamAddress;
    uint256 public teamNamingIncome;
    address public keyAddress;
    address[] participantPool;
    uint256 participantPoolStart;
    uint256 participantPoolEnd;
    address[] public participants;
    uint256 public participantsLength;
    address[] public winner;
    uint256 public deadline;
    uint256 keyPrice_min;
    uint256 keyPrice_max;
    uint256 public keyPrice;
    uint256 public currentGeneration;
    uint256 public currentKeyRound;
    uint256 public duration;
    uint256[] public durationPhaseArray;
    uint256 public durationPhaseIndex;
    uint256 public poolWeight;
    uint256 public poolBalance;
    uint256 public poolReward;
    uint256 public poolWithdraw;
    bool public airdropped;
    bool public keyLocked;
    uint256 public airdropWinTime;
    uint256 public airdropBalance;
    uint256 public airdroppedAmount;
    uint256 public unitStake;
    uint256 public potReserve;
    
    mapping(string => address) addressFromName;
    
    event Withdrawal(
        address indexed _from,
        uint256 _value
    );
    event Deposit(
        address indexed _keyHolder,
        uint256 _weight,
        uint256 _keyPrice,
        uint256 _deadline,
        uint256 _durationPhaseIndex,
        bool _phaseChanged,
        uint256 _poolBalance,
        uint256 _poolReward,
        uint256 _poolWeight,
        // If Airdrop
        bool _airdropped,
        uint256 _airdropBalance,
        // If Trigger Reserve
        bool _potReserveGive,
        uint256 _potReserve
    );
    
    /**
     * @dev prevents contracts from interacting with fomo3d 
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    /**
     * Constructor function
     * 
     */
    constructor (
        address _teamAddress
    ) public {
        teamAddress = _teamAddress;
        keyPrice_min = 1e14;       // in wei, 0.0001 eth
        keyPrice_max = 15e15;      // in wei, 0.015 eth
        keyPrice = keyPrice_min;   // in wei, 0.0001 eth
        keyAddress = msg.sender;
        durationPhaseArray = [1440, 720, 360, 180, 90, 60, 30];
        durationPhaseIndex = 0;
        duration = durationPhaseArray[durationPhaseIndex];
        currentGeneration = 0;
        resetGame();
    }
    
    function resetGame() private {
        uint256 residualBalance = 0;
        if(currentGeneration != 0) {
            // Distribute tokens
            // Staking distribution => distributed on deposit
            // Pool distribution => 20%
            unitStake = 0;
            // 75% for the winner;
            players[keyAddress].balance += poolBalance / 5 * 75 / 100;
            players[keyAddress].lastKeyBonus += poolBalance / 5 * 75 / 100;
            // 15% for random participant
            if(participantPoolEnd - participantPoolStart > 0) {
                uint randParticipantIndex = rand(participantPoolStart + 1, participantPoolEnd);
                players[participantPool[randParticipantIndex - 1]].balance += poolBalance / 5 * 15 / 100;
                players[participantPool[randParticipantIndex - 1]].lastKeyBonus += poolBalance / 5 * 15 / 100;
            } else {
                players[keyAddress].balance += poolBalance / 5 * 15 / 100;
                players[keyAddress].lastKeyBonus += poolBalance / 5 * 15 / 100;
            }
            // 10% and pot reserve for next round
            residualBalance += poolBalance / 5 * 10 / 100 + potReserve;
            winner.push(keyAddress);
        }
        airdropWinTime = now;
        keyPrice = 1e15;
        poolWeight = 0;
        poolReward = 0;
        potReserve = 0;
        
        // Reset duration and deadline
        durationPhaseIndex = 0;
        duration = durationPhaseArray[durationPhaseIndex];
        deadline = now + duration * 1 minutes;
        
        poolBalance = residualBalance;
        keyLocked = false;
        currentKeyRound = 0;
        currentGeneration ++;
        keyAddress = teamAddress;
        participantPoolStart = participantPool.length;
        participantPoolEnd = participantPool.length;
    }
    
    /**
     * Unique address
     *
     */
    function setName(string name) isHuman() payable public {
        uint256 amount = msg.value;
        require(amount >= 1e15);
        require(addressFromName[name] == address(0));
        players[teamAddress].balance += amount;
        teamNamingIncome += amount;
        players[msg.sender].name = name;
        addressFromName[name] = msg.sender;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function referralName (string name) isHuman() payable public {
        if(addressFromName[name] != address(0) && addressFromName[name] != msg.sender && players[msg.sender].referrer == 0)
            players[msg.sender].referrer = players[addressFromName[name]].id;
        uint256 amount = msg.value;
        deposit(amount);
    }
    function referralPay (uint referrer) isHuman() payable public {
        if(referrer > participants.length)
            referrer = 0;
        if(players[msg.sender].id != referrer && players[msg.sender].referrer == 0)
            players[msg.sender].referrer = referrer;
        uint256 amount = msg.value;
        deposit(amount);
    }
    function () isHuman() payable public {
        uint256 amount = msg.value;
        deposit(amount);
    }
    function depositVault (uint keyCount, uint referrer) isHuman() public {
        require(keyLocked == false);
        keyLocked = true;
        // Buy key from current balance
        uint256 amount = keyCount * keyPrice;
        uint256 availableWithdrawal = players[msg.sender].balance - players[msg.sender].withdrawal;
        require(amount <= availableWithdrawal);
        require(amount > 0);
        players[msg.sender].withdrawal += amount;
        
        if(referrer > participants.length)
            referrer = 0;
        if(players[msg.sender].id != referrer && players[msg.sender].referrer == 0)
            players[msg.sender].referrer = referrer;
        keyLocked = false;
        deposit(amount);
    }
    function deposit(uint256 amount) private {
        if(now >= deadline) resetGame();
        require(keyLocked == false);
        keyLocked = true;
        
        // Update pool balance
		require(amount >= keyPrice, "You have to buy at least one key.");
		poolBalance += amount;
		
		currentKeyRound ++;
		participantPool.push(msg.sender);
		participantPoolEnd = participantPool.length;
		// Update deadline if not last round
		if(durationPhaseIndex < 6) deadline = now + duration * 1 minutes;
		
		// Update key holder
		keyAddress = msg.sender;
		
		if(players[msg.sender].generation == 0) {
		    participants.push(msg.sender);
		    participantsLength = participants.length;
		    players[msg.sender].id = participants.length;
		}
		if(players[msg.sender].generation != currentGeneration) {
			players[msg.sender].generation = currentGeneration;
			players[msg.sender].weight = 0;
		}
		// Handling stake distribution
		uint256 p_i = 0;
		uint256 deltaStake = 0;
		address _addr;
		// 58% for staking
		if(poolWeight > 0) {
		    unitStake = amount * 58 / 100 / poolWeight;
		    for(p_i = 0; p_i < participants.length; p_i++) {
		        _addr = participants[p_i];
		        if(players[_addr].generation == currentGeneration) {
		            players[_addr].balance += players[_addr].weight * unitStake;
		            players[_addr].stakingBonus += players[_addr].weight * unitStake;
		        }
		    }
		}
		// 15% for referral
		if(players[msg.sender].referrer > 0) {
		    _addr = participants[players[msg.sender].referrer - 1];
		    players[_addr].balance += amount * 15 / 100;
		    players[_addr].referralBonus += amount * 15 / 100;
		} else {
		    if(poolWeight > 0) {
		        deltaStake = amount * 15 / 100 / poolWeight;
		        for(p_i = 0; p_i < participants.length; p_i++) {
		            _addr = participants[p_i];
		            if(players[_addr].generation == currentGeneration) {
		                players[_addr].balance += players[_addr].weight * deltaStake;
		                players[_addr].stakingBonus += players[_addr].weight * deltaStake;
		            }
		        }
		    } else {
		        players[teamAddress].balance += amount * 15 / 100;
		        players[teamAddress].stakingBonus += amount * 15 / 100;
		    }
		}
		// 4% for team
		unitStake += deltaStake;
		players[teamAddress].balance += amount * 4 / 100;
		players[teamAddress].stakingBonus += amount * 4 / 100;
		
		poolReward += amount * 77 / 100;
		
		airdropBalance += amount * 2 / 100;
		airdropped = false;
		airdroppedAmount = 0;
		uint randNum = 0;
		if(amount >= 1e17 && amount < 1e18) {
		    // 0.1 ~ 1 eth, 1% chance
		    randNum = rand(1, 10000);
		    if(randNum <= 10) airdropped = true;
		} else if(amount >= 1e18 && amount < 1e19) {
		    // 1 eth ~ 10 eth, 10% chance
		    randNum = rand(1, 10000);
		    if(randNum <= 100) airdropped = true;
		} else if(amount >= 1e19) {
		    // greater than 1 eth, 5% chance
		    randNum = rand(1, 10000);
		    if(randNum <= 500) airdropped = true;
		}
		bool _phaseChanged = false;
		if(airdropped) {
		    
		    airdropWinTime = now;
		    players[msg.sender].balance += airdropBalance;
            players[msg.sender].airdropBonus += airdropBalance;
            poolReward += airdropBalance;
            
            airdroppedAmount = airdropBalance;
            airdropBalance = 0;
            if(durationPhaseIndex == 0 && airdropBalance >= 1e18) _phaseChanged = true;
            else if(durationPhaseIndex == 1 && airdropBalance >= 2e18) _phaseChanged = true;
            else if(durationPhaseIndex == 2 && airdropBalance >= 3e18) _phaseChanged = true;
            else if(durationPhaseIndex == 3 && airdropBalance >= 5e18) _phaseChanged = true;
            else if(durationPhaseIndex == 4 && airdropBalance >= 7e18) _phaseChanged = true;
            else if(durationPhaseIndex == 5 && airdropBalance >= 1e19) _phaseChanged = true;
            if(_phaseChanged) {
                durationPhaseIndex ++;
                duration = durationPhaseArray[durationPhaseIndex];
                deadline = now + duration * 1 minutes;
            }
            
		}
		
		// Staking weight calculation
		uint256 weight = amount.mul(1e7).div(keyPrice);
		players[msg.sender].weight += weight;
		uint256 originalPoolSegment = poolWeight / ((5e5).mul(1e7));
		poolWeight += weight;
		uint256 afterPoolSegment = poolWeight / ((5e5).mul(1e7));
		
		// Different Segment => giveout potReserve, every 1e5 keys
		potReserve += amount * 1 / 100;
		bool _potReserveGive = false;
		uint256 _potReserve = potReserve;
		if(originalPoolSegment != afterPoolSegment) {
		    _potReserveGive = true;
		    players[msg.sender].balance += potReserve;
		    players[msg.sender].potBonus += potReserve;
		    poolReward += potReserve;
		    potReserve = 0;
		}
		
		// Grow key price
		if(keyPrice < keyPrice_max) {
		    keyPrice = keyPrice_max - (1e23 - poolBalance).mul(keyPrice_max - keyPrice_min).div(1e23);
		} else {
		    keyPrice = keyPrice_max;
		}
		keyLocked = false;
		emit Deposit(
		    msg.sender,
		    weight,
		    keyPrice,
		    deadline,
		    durationPhaseIndex,
		    _phaseChanged,
		    poolBalance,
		    poolReward,
		    poolWeight,
		    airdropped,
		    airdropBalance,
		    _potReserveGive,
		    _potReserve
        );
    }
    uint256 nonce = 0;
    function rand(uint min, uint max) private returns (uint){
        nonce++;
        return uint(keccak256(toBytes(nonce)))%(min+max)-min;
    }
    function toBytes(uint256 x) private pure returns (bytes b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
    /**
     * Withdraw the funds
     */
    function safeWithdrawal() isHuman() public {
        uint256 availableWithdrawal = players[msg.sender].balance - players[msg.sender].withdrawal;
        require(availableWithdrawal > 0);
        require(keyLocked == false);
        keyLocked = true;
        poolWithdraw += availableWithdrawal;
        players[msg.sender].withdrawal += availableWithdrawal;
        msg.sender.transfer(availableWithdrawal);
        keyLocked = false;
        emit Withdrawal(msg.sender, availableWithdrawal);
    }
    function helpWithdrawal(address userAddress) isHuman() public {
        // Will only be executed when user himself cannot withdraw and asks our team for help
        require(msg.sender == teamAddress);
        uint256 availableWithdrawal = players[userAddress].balance - players[userAddress].withdrawal;
        require(availableWithdrawal > 0);
        require(keyLocked == false);
        keyLocked = true;
        poolWithdraw += availableWithdrawal;
        players[userAddress].withdrawal += availableWithdrawal;
        // Service fee: 5%
        players[teamAddress].balance += availableWithdrawal * 5 / 100;
        // User get 95%
        userAddress.transfer(availableWithdrawal * 95 / 100);
        keyLocked = false;
        emit Withdrawal(userAddress, availableWithdrawal);
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}