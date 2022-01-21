/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @author mertzdev
/// @title A fun experimental Web3 game playable at https://piggybankbomb.com
contract PiggyBankBomb {
    /// @notice The initial amount of seconds on the bomb timer. Whenever a deposit is made the bomb timer will be reset to this value.
    uint16 public immutable bombTimerMaxSeconds;

    /// @notice Emitted when a new game has started
    /// @param _from The address that made the deposit to start the game
    /// @param _balance The initial `piggyBankBalance` for the game
    event GameStarted(address _from, uint256 _balance);

    /// @notice Emitted when a deposit is made
    /// @param _from The address that made the deposit
    /// @param _value The amount of WEI deposited
    event Deposit(address _from, uint256 _value);

    /// @notice Emitted when a the winnings of the most recent game are stored in the contract
    /// @param _winner The address that had winnings stored
    /// @param _value The amount of WEI stored for the winner
    event WinningsStored(address _winner, uint256 _value);

    /// @notice Emitted when winnings have been withdrawn
    /// @param _winner The address that withdrew their winnings
    /// @param _value The amount of WEI withdrawn
    event WinningsWithdrawn(address _winner, uint256 _value);

    uint256 public piggyBankBalance; /// @notice The amount of WEI in the piggy bank
    address public lastDepositAddress; /// @notice The last address that made a deposit. They currently "own" the piggy bank.
    uint256 public lastDepositTime; /// @notice The timestamp (seconds since unix epoch) the last deposit was made
    mapping(address => uint256) public winnerBalances; /// @notice Keeps track of the balances for all winners that can be withdrawn

    /// @notice Start a new game with the initial piggyBankBalance equal to `msg.value`
    /// @param _bombTimerMaxSeconds The amount of seconds that the bomb timer will start at
    constructor(uint16 _bombTimerMaxSeconds) payable {
        bombTimerMaxSeconds = _bombTimerMaxSeconds;
        piggyBankBalance = msg.value;
        lastDepositAddress = msg.sender;
        lastDepositTime = getBlockTimestamp();
        emit GameStarted(msg.sender, piggyBankBalance);
    }

    /// @notice Deposit ETH into the piggy bank and reset the bomb clock. The clock must have time remaining and `msg.value` must be > `calculateMinDeposit()`
    function deposit() external payable {
        require(!isGameOver(), "Time ran out");
        require(msg.value >= calculateMinDeposit(), "Below minimum deposit");

        piggyBankBalance += msg.value; // TODO: Pull this update into it's own function?
        lastDepositAddress = msg.sender;
        lastDepositTime = getBlockTimestamp();
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Starts a new game. This also stores the winnings of `lastDepositAddress`. 95% of the `piggyBankBalance` goes to `lastDepositAddress` and the remanining 5% stays in the piggy bank.
    function startNewGame() external {
        require(isGameOver(), "Time still left");

        // ~5% stays in the piggy bank for next game
        uint256 winnings = piggyBankBalance - (piggyBankBalance / 20);
        piggyBankBalance -= winnings;
        winnerBalances[lastDepositAddress] += winnings;
        emit WinningsStored(lastDepositAddress, winnings);
        lastDepositAddress = msg.sender; // TODO: pull out into function? Or just add test
        lastDepositTime = getBlockTimestamp();
        emit GameStarted(msg.sender, piggyBankBalance);
    }

    /// @notice Transfer any winnings to `msg.sender` if they have any
    function withdrawWinnings() external {
        uint256 amount = winnerBalances[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        delete winnerBalances[msg.sender];
        payable(msg.sender).transfer(amount);
        emit WinningsWithdrawn(msg.sender, amount);
    }

    /// @notice Determines the minimum allowable deposit amount. This grows as the `piggyBankBalance` grows.
    /// @return minimum deposit amount, in wei
    function calculateMinDeposit() public view returns (uint256) {
        if (piggyBankBalance < 0.005 ether) {
            return 0.00025 ether;
        } else if (piggyBankBalance < 0.05 ether) {
            return 0.0025 ether;
        } else if (piggyBankBalance < 0.1 ether) {
            return 0.005 ether;
        } else if (piggyBankBalance < 0.2 ether) {
            return 0.01 ether;
        } else if (piggyBankBalance < 0.5 ether) {
            return 0.025 ether;
        } else if (piggyBankBalance < 1 ether) {
            return 0.05 ether;
        } else if (piggyBankBalance < 2 ether) {
            return 0.1 ether;
        } else if (piggyBankBalance < 5 ether) {
            return 0.25 ether;
        } else if (piggyBankBalance < 10 ether) {
            return 0.5 ether;
        } else if (piggyBankBalance < 20 ether) {
            return 1 ether;
        } else if (piggyBankBalance < 50 ether) {
            return 2.5 ether;
        } else if (piggyBankBalance < 100 ether) {
            return 5 ether;
        } else if (piggyBankBalance < 200 ether) {
            return 10 ether;
        }

        return 25 ether;
    }

    /// @notice Returns `block.timestamp`. This function is added so it can be mocked in tests
    /// @return current block timestamp as seconds since unix epoch
    function getBlockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @notice Determines if the current game is complete by seeing if the bomb timer has run out
    /// @return `true` if game is over, `false` if game still in progress
    function isGameOver() private view returns (bool) {
        return getBlockTimestamp() > (lastDepositTime + bombTimerMaxSeconds);
    }
}