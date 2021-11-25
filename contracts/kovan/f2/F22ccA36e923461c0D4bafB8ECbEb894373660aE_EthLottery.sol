// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";

contract EthLottery is Ownable {
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNERS
    }

    enum PRIZE_TYPE {
        FIRST,
        SECOND,
        THIRD
    }

    struct Player {
        address payable playerAddress;
        string ticketNumber;
    }

    struct WinnerTicket {
        string ticketNumber;
        uint256 ticketDate;
    }

    uint256 public ticketValue;
    uint256 totalPrizes;
    uint256 public firstPrize; // 50% of the total fund.
    uint256 public secondPrize; // 20% of the total fund.
    uint256 public thirdPrize; // 10% of the total fund.
    uint256 reserve; // 20% of the total fund

    Player[] public currentPlayers;
    WinnerTicket[] public lottoResults;
    LOTTERY_STATE public lotteryState;

    constructor() {
        ticketValue = 10**15; //in wei (0.001 ETH)
        lotteryState = LOTTERY_STATE.CLOSED;
    }

    //0. Fund lottery first time.
    function fundLottery(
        uint256 pFPrize,
        uint256 pSPrize,
        uint256 pTPrize
    ) public payable onlyOwner {
        require(
            pFPrize + pSPrize + pTPrize == 100,
            "The sum of the parameters should be 100"
        );
        uint256 amount = msg.value;
        firstPrize = (amount * pFPrize) / 100;
        secondPrize = (amount * pSPrize) / 100;
        thirdPrize = (amount * pTPrize) / 100;

        totalPrizes = firstPrize + secondPrize + thirdPrize;
    }

    // 1. Start lottery
    function startLottery() public onlyOwner {
        // Start lottery.
        //Note: Only the owner can start the lottery.
        lotteryState = LOTTERY_STATE.OPEN;
    }

    // 2. Tickets sale
    function enterLottery(string memory lottoTicket) public payable {
        // Buy a lotto ticket.

        //Requires that the lottery is open.
        require(
            lotteryState == LOTTERY_STATE.OPEN,
            "The lottery hasn't started yet"
        );
        //Requires that the user pays the correct amount for the lotto ticket
        require(msg.value == ticketValue, "Send the correct amount");

        //Requires a valid ticket
        require(validateTicket(lottoTicket), "Not a valid ticket.");

        currentPlayers.push(Player(payable(msg.sender), lottoTicket));
    }

    function validateTicket(string memory lottoTicket)
        public
        view
        returns (bool)
    {
        bytes memory bytesLottoTicket = bytes(lottoTicket);

        if (bytesLottoTicket.length != 12) return false; //Validate the length of the string.
        //Validate that the string is numeric, using  the ASCII code (HEX) of each char.

        for (uint256 i = 0; i < bytesLottoTicket.length; i++) {
            bytes1 char = bytesLottoTicket[i];
            if (char < 0x30 || char > 0x39) return false;
        }

        return true;
    }

    // 3. Close lottery.
    function endLottery(string memory winnerTicket) public onlyOwner {
        // End the lottery.
        //Note: only the owner can end the lottery.
        require(validateTicket(winnerTicket), "Not a valid ticket.");
        lottoResults.push(WinnerTicket(winnerTicket, block.timestamp));
        lotteryState = LOTTERY_STATE.CLOSED;
    }

    function calculatePrizesAndReserve() internal {
        uint256 totalBalance = address(this).balance;

        firstPrize = (totalBalance * 50) / 100; //  50%
        secondPrize = (totalBalance * 20) / 100; //  20%
        thirdPrize = (totalBalance * 10) / 100; //  10%
        reserve = (totalBalance * 20) / 100; //  20%
    }
    /*
    function selectWinners() internal {
        // Select the winners after the numbers are selected.
    }

    function transferToWinners() internal {
        //Transfers assets to the winners.
    }

    function withdrawEarnings() public payable onlyOwner {
        //Withdraw the earnings of the lotto.
        //Note: only the owner can withdraw the funds of the contract.
    }*/
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}