// SPDX-License-Identifier: NONE
// © mia.bet
pragma solidity 0.7.3;

import "./EIP712MetaTransaction.sol";
import "./WETH.sol";

contract owned {
    address payable public owner;
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}

/**
 * @author The Mia.bet team
 * @title Bet processing contract for mia.bet
 */
contract MultiPot is owned, EIP712MetaTransaction("MultiPot","1") {
    enum Color {red, green, blue, yellow, white, orange, black}
    enum State {seeding, accepting_bets, race_in_progress, paying_out, refunding}
    Color public lastWinningColor;
    State public current_state;
    uint8 constant public numPots = 7;
    uint16 public workoutTresholdMeters = 2000;
    uint32 public workoutDeziMeters = 0;
    uint32 public round = 0;
    uint64 public roundStartTime = 0;
    uint public minimumBetAmount = 1000000 gwei; // 0.001 ether
    address wethBaseContract = 0xa4254439E51E196AC1f54c2ac958F928864AEa96;

    struct Pot {
        uint amount;
        address payable[] uniqueGamblers;
        mapping (address => uint) stakes;
    }

    mapping (uint => Pot) pots;


    /**
     * state: seeding
     */

    function setMinimumBetAmount(uint amount) external onlyOwner {
        require(current_state == State.seeding, "Not possible in current state");
        minimumBetAmount = amount;
    }

    function setWethBaseContract(address contractAddress) external onlyOwner {
        require(current_state == State.seeding, "Not possible in current state");
        wethBaseContract = contractAddress;
    }

    function setWorkoutThresholdMeters(uint16 meters) external onlyOwner {
        require(current_state == State.seeding, "Not possible in current state");
        workoutTresholdMeters = meters;
    }

    function kill() external onlyOwner {
        require(current_state == State.seeding, "Not possible in current state");
        selfdestruct(owner);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        require(current_state == State.seeding, "Not possible in current state");
        IERC20(tokenAddress).transfer(owner, tokenAmount);
    }

    function startNewRound(uint seedAmount) internal {
        roundStartTime = uint64(block.timestamp); // security/no-block-members: see remark at the bottom
        round += 1;
        workoutDeziMeters = 0;
        emit RoundStarted(round, seedAmount);
    }

    function seedPots(uint seedAmount) external onlyOwner {
        require(current_state == State.seeding, "Not possible in current state");
        require(seedAmount >= numPots * 1 wei, "Pots must not have amount 0");
        MaticWETH(wethBaseContract).transferFrom(owner, address(this), seedAmount);
        uint offset = numPots * round;
        delete pots[offset + uint8(Color.red)];
        delete pots[offset + uint8(Color.green)];
        delete pots[offset + uint8(Color.blue)];
        delete pots[offset + uint8(Color.yellow)];
        delete pots[offset + uint8(Color.white)];
        delete pots[offset + uint8(Color.orange)];
        delete pots[offset + uint8(Color.black)];
        startNewRound(seedAmount);
        offset = offset + numPots;
        uint seedAmountPerPot = seedAmount / numPots;
        for(uint8 j = 0; j < numPots; j++) {
           pots[offset + j].amount = seedAmountPerPot;
        }
        transitionTo(State.accepting_bets);
    }


    /**
     * state: accepting_bets
     */

    function placeBet(uint amount, Color potColor, uint32 bet_round, bytes memory approveAbiHex, bytes32 r, bytes32 s, uint8 v) external payable {
        require(current_state == State.accepting_bets, "Game has not started yet or a race is already in progress.");
        require(round == bet_round, "Bets can only be placed for the current round.");
        require(amount >= minimumBetAmount, "Your bet must be greater than or equal to the minimum bet amount.");
        address payable gambler = payable(msgSender());
        MaticWETH weth = MaticWETH(wethBaseContract);
        weth.executeMetaTransaction(gambler, approveAbiHex, r, s, v);
        weth.transferFrom(gambler, address(this), amount);
        Pot storage pot = pots[uint8(potColor) + numPots * round];
        if (pot.stakes[gambler] == 0) {
            pot.uniqueGamblers.push(gambler);
        }
        pot.stakes[gambler] += amount;
        pot.amount += amount;
        emit BetPlaced(potColor, amount);
    }

    function miaFinishedWorkout(uint32 dezi_meters) external onlyOwner {
        require(current_state == State.accepting_bets, "Not possible in current state");
        emit HamsterRan(dezi_meters);
        workoutDeziMeters += dezi_meters;

        if (workoutDeziMeters / 10 >= workoutTresholdMeters) {
            transitionTo(State.race_in_progress);
            emit RaceStarted(round);
        }
    }


    /**
     * state: race_in_progress
     */

    function setWinningMarble(Color color, uint64 video_id, string calldata photo_id) external onlyOwner {
        require(current_state == State.race_in_progress, "Not possible in current state");
        lastWinningColor = color;
        emit WinnerChosen(round, color, video_id, photo_id);
        transitionTo(State.paying_out);
    }


    /**
     * state: paying_out
     */

    function payoutWinners() external returns (uint pendingPayouts) {
        require(current_state == State.paying_out, "Not possible in current state.");
        Pot storage winningPot = pots[uint8(lastWinningColor) + numPots * round];
        uint totalPayoutAmount = 0;
        for(uint8 j = 0; j < numPots; j++) {
            // sum up original payout amount (self.balance changes during payouts)
            totalPayoutAmount += pots[j + numPots * round].amount;
        }
        totalPayoutAmount = totalPayoutAmount * 80 / 100; // 20% house fee
        uint winningPotAmount = winningPot.amount;
        for(uint i = winningPot.uniqueGamblers.length; i >= 1; i--) {
            address payable gambler = winningPot.uniqueGamblers[i - 1];
            winningPot.uniqueGamblers.pop();
            uint stake = winningPot.stakes[gambler];
            /* profit = totalPayoutAmount * (stake / winningPotAmount)
               but do the multiplication before the division: */
            uint profit = totalPayoutAmount * stake / winningPotAmount;
            profit = profit >= stake ? profit : stake; // ensure no loss for player (reduces house profit)
            winningPot.stakes[gambler] = 0; // checks-effects-interactions pattern
            MaticWETH(wethBaseContract).transfer(gambler, profit);
            emit PayoutSuccessful(gambler, profit, round);
            if(!(gasleft() > 26000)) {
                pendingPayouts = i - 1;
                break;
            }
        }

        assert(current_state == State.paying_out);
        if(gasleft() > 400000) { // 400_000 gas for 7 pots
            // payout house fee
            MaticWETH weth = MaticWETH(wethBaseContract);
            weth.transfer(owner, weth.balanceOf(address(this)));
            emit WinnersPaid(round, totalPayoutAmount, lastWinningColor, winningPotAmount);
            // transition to next state
            transitionTo(State.seeding);
        }
        return pendingPayouts;
    }


    /**
     * state: refunding
     */

    function claimRefund() external {
        require(block.timestamp > roundStartTime + 2 days, "Only possible 2 day after round started."); // security/no-block-members: see remark at the bottom
        require(current_state == State.accepting_bets || current_state == State.race_in_progress, "Not possible in current state.");
        transitionTo(State.refunding);
    }

    function refundAll() external returns (uint pendingRefunds) {
        require(current_state == State.refunding, "Only possible after a successful claimRefund()");
        for(uint8 i = 0; i < numPots; i++) {
           pendingRefunds = refundPot(pots[i + numPots * round]);
           if (pendingRefunds != 0) break;
        }
        assert(current_state == State.refunding); // assure no state changes in re-entrancy attacks
        if (pendingRefunds == 0) {
            transitionTo(State.seeding);
        }
        return pendingRefunds;
    }

    function refundPot(Pot storage pot) internal returns (uint pendingRefunds) {
        for(uint i = pot.uniqueGamblers.length; i >= 1; i--) {
            address payable gambler = pot.uniqueGamblers[i - 1];
            pot.uniqueGamblers.pop();
            uint amount = pot.stakes[gambler];
            pot.stakes[gambler] = 0;
            MaticWETH(wethBaseContract).transfer(gambler, amount);
            emit RefundSuccessful(gambler, amount);
            if(gasleft() < 26000) {
                // stop execution here to let state be saved
                // call function again to continue
                break;
            }
        }
        return pot.uniqueGamblers.length;
    }

    /**
     * state transition method
     */
    function transitionTo(State newState) internal {
      emit StateChanged(current_state, newState);
      current_state = newState;
    }

    /**
     * stateless functions
     */

    function getPotAmounts() external view returns (uint[numPots] memory amounts) {
        for(uint8 j = 0; j < numPots; j++) {
            amounts[j] = pots[j + numPots * round].amount;
        }
        return amounts;
    }


    /* events */
    event StateChanged(State from, State to);
    event WinnerChosen(uint32 indexed round, Color color, uint64 video_id, string photo_id);
    event WinnersPaid(uint32 indexed round, uint total_amount, Color color, uint winningPotAmount);
    event PayoutSuccessful(address winner, uint amount, uint32 round);
    event PayoutFailed(address winner, uint amount, uint32 round);
    event RefundSuccessful(address gambler, uint amount);
    event RefundFailed(address gambler, uint amount);
    event RoundStarted(uint32 indexed round, uint total_seed_amount);
    event RaceStarted(uint32 indexed round);
    event BetPlaced(Color pot, uint amount);
    event HamsterRan(uint32 dezi_meters);
}

/** Further Remarks
 * ----------------
 *
 * Warnings
 * - "security/no-block-members: Avoid using 'block.timestamp'." => Using block.timestamp is safe for time periods greather than 900s [1]. We use 1 day.
 *
 * Sources
 * [1] Is block.timestamp safe for longer time periods? https://ethereum.stackexchange.com/a/9752/44462
 */