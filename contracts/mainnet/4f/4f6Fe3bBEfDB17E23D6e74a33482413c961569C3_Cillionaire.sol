pragma solidity 0.4.15;

contract owned {
    
    address public owner;
    
    event ContractOwnershipTransferred(address newOwner);
    
    function owned() { owner = msg.sender; }
    
    modifier onlyOwner { 
        require(msg.sender == owner); 
        _; 
    }
    
    function setContractOwner(address newOwner) external onlyOwner  {
        owner = newOwner;
        ContractOwnershipTransferred(newOwner);
    }
}

/// Cillionaire is a lottery where people can participate until a pot limit is reached. Then, a random participant is chosen to be the winner.
/// 
/// Randomness is achieved by XOR&#39;ing the following two numbers:
/// ownerRandomNumber ... a random number supplied by the contract owner and submitted upon `start` as a hash, much like a concealed bid in an auction.
/// minerRandomNumber ... timestamp of the block that contains the last participant&#39;s `particpate` transaction.
/// Neither can the owner know the minerRandomNumber, nor can the miner know the ownerRandomNumber (unless the owner supplies a breakable hash, e.h. keccak256(1)).
///
/// Many safeguards are in place to prevent loss of participants&#39; stakes and ensure fairness:
/// - The owner can `cancel`, in which case participants must be refunded.
/// - If the owner does not end the game via `chooseWinner` within 24 hours after PARTICIPATION `state` ended, then anyone can `cancel`.
/// - The contract has no `kill` function which would allow the owner to run off with the pot.
/// - Game parameters cannot be changed when a game is ongoing
/// - Logging of relevant events to increase transparency
contract Cillionaire is owned {
    
    enum State { ENDED, PARTICIPATION, CHOOSE_WINNER, REFUND }

    /// Target amount of ether. As long as the `potTarget` is not reached, people can `participate` when the contract is in PARTICIPATION `state`.
    uint public potTarget;
    /// Amount of ether that will be used to `participate`.
    uint public stake;
    /// Amount of ether that will be taken from `stake` as a fee for the owner.
    uint public fee;
    
    State public state;
    address[] public participants;
    bytes32 public ownerRandomHash;
    uint public minerRandomNumber;
    uint public ownerRandomNumber;
    uint public participationEndTimestamp;
    uint public pot;
    address public winner;
    mapping (address => uint) public funds;
    uint public fees;
    uint public lastRefundedIndex;
    
    event StateChange(State newState);
    event NewParticipant(address participant, uint total, uint stakeAfterFee, uint refundNow);
    event MinerRandomNumber(uint number);
    event OwnerRandomNumber(uint number);
    event RandomNumber(uint randomNumber);
    event WinnerIndex(uint winnerIndex);
    event Winner(address _winner, uint amount);
    event Refund(address participant, uint amount);
    event Cancelled(address cancelledBy);
    event ParametersChanged(uint newPotTarget, uint newStake, uint newFee);
    
    modifier onlyState(State _state) { 
        require(state == _state); 
        _; 
    }
    
    // Taken from: https://solidity.readthedocs.io/en/develop/common-patterns.html
    // This modifier requires a certain
    // fee being associated with a function call.
    // If the caller sent too much, he or she is
    // refunded, but only after the function body.
    // This was dangerous before Solidity version 0.4.0,
    // where it was possible to skip the part after `_;`.
    modifier costs(uint _amount) {
        require(msg.value >= _amount);
        _;
        if (msg.value > _amount) {
            msg.sender.transfer(msg.value - _amount);
        }
    }
    
    function Cillionaire() {
        state = State.ENDED;
        potTarget = 0.1 ether;
        stake = 0.05 ether;
        fee = 0;
    }
    
    function setState(State _state) internal {
        state = _state;
        StateChange(state);
    }
    
    /// Starts the game, i.e. resets game variables and transitions to state `PARTICIPATION`
    /// `_ownerRandomHash` is the owner&#39;s concealed random number. 
    /// It must be a keccak256 hash that can be verfied in `chooseWinner`.
    function start(bytes32 _ownerRandomHash) external onlyOwner onlyState(State.ENDED) {
        ownerRandomHash = _ownerRandomHash;
        minerRandomNumber = 0;
        ownerRandomNumber = 0;
        participationEndTimestamp = 0;
        winner = 0;
        pot = 0;
        lastRefundedIndex = 0;
        delete participants;
        setState(State.PARTICIPATION);
    }
    
    /// Participate in the game.
    /// You must send at least `stake` amount of ether. Surplus ether is refunded automatically and immediately.
    /// This function will only work when the contract is in `state` PARTICIPATION.
    /// Once the `potTarget` is reached, the `state` transitions to CHOOSE_WINNER.
    function participate() external payable onlyState(State.PARTICIPATION) costs(stake) {
        participants.push(msg.sender);
        uint stakeAfterFee = stake - fee;
        pot += stakeAfterFee;
        fees += fee;
        NewParticipant(msg.sender, msg.value, stakeAfterFee, msg.value - stake);
        if (pot >= potTarget) {
            participationEndTimestamp = block.timestamp;
            minerRandomNumber = block.timestamp;
            MinerRandomNumber(minerRandomNumber);
            setState(State.CHOOSE_WINNER);
        }
    }
    
    /// Reveal the owner&#39;s random number and choose a winner using all three random numbers.
    /// The winner is credited the pot and can get their funds using `withdraw`.
    /// This function will only work when the contract is in `state` CHOOSE_WINNER.
    function chooseWinner(string _ownerRandomNumber, string _ownerRandomSecret) external onlyOwner onlyState(State.CHOOSE_WINNER) {
        require(keccak256(_ownerRandomNumber, _ownerRandomSecret) == ownerRandomHash);
        require(!startsWithDigit(_ownerRandomSecret)); // This is needed because keccak256("12", "34") == keccak256("1", "234") to prevent owner from changing his initially comitted random number
        ownerRandomNumber = parseInt(_ownerRandomNumber);
        OwnerRandomNumber(ownerRandomNumber);
        uint randomNumber = ownerRandomNumber ^ minerRandomNumber;
        RandomNumber(randomNumber);
        uint winnerIndex = randomNumber % participants.length;
        WinnerIndex(winnerIndex);
        winner = participants[winnerIndex];
        funds[winner] += pot;
        Winner(winner, pot);
        setState(State.ENDED);
    }
    
    /// Cancel the game.
    /// Participants&#39; stakes (including fee) are refunded. Use the `withdraw` function to get the refund.
    /// Owner can cancel at any time in `state` PARTICIPATION or CHOOSE_WINNER
    /// Anyone can cancel 24h after `state` PARTICIPATION ended. This is to make sure no funds get locked up due to inactivity of the owner.
    function cancel() external {
        if (msg.sender == owner) {
            require(state == State.PARTICIPATION || state == State.CHOOSE_WINNER);
        } else {
            require((state == State.CHOOSE_WINNER) && (participationEndTimestamp != 0) && (block.timestamp > participationEndTimestamp + 1 days));
        }
        Cancelled(msg.sender);
        // refund index 0 so lastRefundedIndex=0 is correct
        if (participants.length > 0) {
            funds[participants[0]] += stake;
            fees -= fee;
            lastRefundedIndex = 0;
            Refund(participants[0], stake);
            if (participants.length == 1) {
                setState(State.ENDED);
            } else {
                setState(State.REFUND);
            }
        } else {
            // nothing to refund
            setState(State.ENDED);
        }
    }
    
    /// Refund a number of accounts specified by `_count`, beginning at the next un-refunded index which is lastRefundedIndex`+1.
    /// This is so that refunds can be dimensioned such that they don&#39;t exceed block gas limit.
    /// Once all participants are refunded `state` transitions to ENDED.
    /// Any user can do the refunds.
    function refund(uint _count) onlyState(State.REFUND) {
        require(participants.length > 0);
        uint first = lastRefundedIndex + 1;
        uint last = lastRefundedIndex + _count;
        if (last > participants.length - 1) {
            last = participants.length - 1;
        }
        for (uint i = first; i <= last; i++) {
            funds[participants[i]] += stake;
            fees -= fee;
            Refund(participants[i], stake);
        }
        lastRefundedIndex = last;
        if (lastRefundedIndex >= participants.length - 1) {
            setState(State.ENDED);
        }
    }

    /// Withdraw your funds, i.e. winnings and refunds.
    /// This function can be called in any state and will withdraw all winnings as well as refunds. 
    function withdraw() external {
        uint amount = funds[msg.sender];
        funds[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    /// Withdraw accumulated fees. 
    /// Usable by contract owner when `state` is ENDED.
    function withdrawFees() external onlyOwner onlyState(State.ENDED) {
        uint amount = fees;
        fees = 0;
        msg.sender.transfer(amount);
    }
    
    /// Adjust game parameters. All parameters are in Wei.
    /// Can be called by the contract owner in `state` ENDED.
    function setParams(uint _potTarget, uint _stake, uint _fee) external onlyOwner onlyState(State.ENDED) {
        require(_fee < _stake);
        potTarget = _potTarget;
        stake = _stake; 
        fee = _fee;
        ParametersChanged(potTarget, stake, fee);
    }
    
    function startsWithDigit(string str) internal returns (bool) {
        bytes memory b = bytes(str);
        return b[0] >= 48 && b[0] <= 57; // 0-9; see http://dev.networkerror.org/utf8/
    }
    
    // parseInt 
    // Copyright (c) 2015-2016 Oraclize SRL
    // Copyright (c) 2016 Oraclize LTD
    // Source: https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.4.sol
    function parseInt(string _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    // Copyright (c) 2015-2016 Oraclize SRL
    // Copyright (c) 2016 Oraclize LTD
    // Source: https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.4.sol
    function parseInt(string _a, uint _b) internal returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

}