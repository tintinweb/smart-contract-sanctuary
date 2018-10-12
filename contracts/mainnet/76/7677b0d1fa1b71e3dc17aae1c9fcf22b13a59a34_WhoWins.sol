pragma solidity ^0.4.24;

/**
 *
 * Easy Investment Lottery Contract
 *  - EARN 5% PER DAY IN YOUR ACCOUNT BALANCE
 *  - DOUBLE YOUR PROFIT WITH LOTTERY AT 50%
 *  - YOUR WINNING IS SENT DIRECTLY TO YOU (then tip the house to celebrate)
 *
 * How to use:
 *  1. Send ether to start your easy investment at 5% per day
 *
 *  2. Send 0 ether to double your profit with lottery at 50%
 *                            OR
 *     Send more ether to reinvest and play the lottery at the same time
 *
 * RECOMMENDED GAS LIMIT: 70000
 * RECOMMENDED GAS PRICE: 6 gwei
 *
 * Contract reviewed and approved by the house!!!
 *
 */
contract WhoWins {
    // records your account balance
    mapping (address => uint256) public balance;
    // records block number of your last transaction
    mapping (address => uint256) public atBlock;

    // records casino&#39;s address
    address public house;
    constructor() public {
        house = msg.sender;
    }

    // this function is called when you send a transaction to this contract
    function () external payable {
        // if sender (aka YOU) is invested more than 0 ether
        if (balance[msg.sender] != 0) {
            // calculate profit as such:
            // profit = balance * 5% * (blocks since last transaction) / average Ethereum blocks per day
            uint256 profit = balance[msg.sender] * 5 / 100 * (block.number - atBlock[msg.sender]) / 5900;

            // Random
            uint8 toss = uint8(keccak256(abi.encodePacked(blockhash(block.timestamp), block.difficulty, block.coinbase))) % 2;
            if (toss == 0) {
                // double your profit, you won!!!
                uint256 winning = profit * 2;

                // send winning directly to YOU
                msg.sender.transfer(profit * 2);

                // send a tip of 5% to the house
                house.transfer(winning * 5 / 100);
            }
        }

        // record balance and block number of your transaction
        balance[msg.sender] += msg.value;
        atBlock[msg.sender] = block.number;
    }
}