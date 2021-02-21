// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
import {
    IERC20,
    ISafeMath,
    IChainlinkOracle,
    IKladeDiffToken
} from "./Interfaces.sol";


contract ChainlinkReceiver {
    uint256 constant multiple = 10**7;
    uint256 constant initial_factor = 1396984; // initial_factor =  600 * 10^13 / 2^32 rounded to nearest whole number
    // factor = block_reward * seconds_per_block * Hashes_per_second * WBTC_adjustment_factor / constant
    // Formula for Earnings Per Block in BTC = block_reward * 600 * hash_rate / (2^32 * difficulty)
    uint256 constant Q3_end_unix = 1632960000;

    uint256 constant secondsInDay = 86400; // Number of seconds in a day
    uint256 constant blocksBetweenHalvings = 210000; // Number of blocks between each bitcoin block reward halving ie 12.5 BTC/block -> 6.25 BTC/block
    uint256 constant initialBlockReward = 5000000000; // Initial bitcoin block reward in satoshis
    uint256 constant numBlockBetweenDiffChanges = 2016; // Number of Blocks between each BTC difficulty adjustment(~2 weeks or 2016 blocks)

    //Static Variable used to check validity of data given by the chainlink oracle
                                          
    uint256 constant minValidDifficulty = 500000000000; // Minimum valid difficulty for Q32021
    uint256 constant maxValidDifficulty = 600000000000000; // Maximum valid difficulty for Q32021

    uint256 constant minValidBlockNum = 663904; // Minimum valid block number for Q32021
    uint256 constant maxValidBlockNum = 1000000; // Maximum valid block number for Q32021
    uint256 constant maxValidBlockNumberIncrease = 10000; // Maximum valid block number between Chainlink Updates

    uint256 immutable factor;

    address public immutable KladeAddress1;
    address public immutable KladeAddress2;
    ISafeMath public immutable safemath;

    struct ChainlinkUpdate {
        uint256 block_number;
        uint256 difficulty;
        uint80 blocknum_roundID;
        uint80 diff_roundID;
    }

    struct quarter_details {
        IKladeDiffToken alpha_token;
        IKladeDiffToken omega_token;
        IChainlinkOracle chainlink_diff_oracle;
        IChainlinkOracle chainlink_blocknum_oracle;
        uint256 required_collateral;
        uint256 hedged_revenue;
        uint256 end_unix;
        uint256 intermediateActualMinerEarnings;
        uint256 number_of_updates;
    }

    quarter_details public Q3_details;
    bool public Q3_set;
    mapping(uint256 => ChainlinkUpdate) public chainlink_data;

    constructor(
        address klade_address1,
        address klade_address2,
        ISafeMath safemath_contract
    ) {
        KladeAddress1 = klade_address1;
        KladeAddress2 = klade_address2;
        safemath = safemath_contract;
        factor = safemath_contract.mul(initial_factor, multiple);
    }

    /**
     * Set basic quarter details for Chainlink Receiver
     * @param alpha_token_contract IKladeDiffToken - Klade Alpha Token Contract
     * @param omega_token_contract IKladeDifFToken - Klade Omega Token Contract
     * @param chainlink_diff_oracle IChainlinkOracle - Chainlink oracle contract that provides difficulty information
     * @param chainlink_blocknum_oracle IChainlinkOracle - Chainlink oracle contract that provides difficulty information
     * @param required_collateral uint - required collateral to mint a single pair of Klade Alpha/Omega tokens
     * @param hedged_revenue uint - hedged revenue for bitcoin miners for single pair of tokens
     * @param miner_earnings uint - miner earnings for single pair of tokens
     */
    function set_quarter_details(
        IKladeDiffToken alpha_token_contract,
        IKladeDiffToken omega_token_contract,
        IChainlinkOracle chainlink_diff_oracle,
        IChainlinkOracle chainlink_blocknum_oracle,
        uint256 required_collateral,
        uint256 hedged_revenue,
        uint256 miner_earnings
    ) external {
        require(
            msg.sender == KladeAddress1 || msg.sender == KladeAddress2,
            "Only Klade can set quarter details"
        );
        require(Q3_set == false, "Quarter details already set");
        Q3_details = quarter_details(
            alpha_token_contract,
            omega_token_contract,
            chainlink_diff_oracle,
            chainlink_blocknum_oracle,
            required_collateral,
            hedged_revenue,
            Q3_end_unix,
            miner_earnings,
            0
        );
        Q3_set = true;
    }

    /**
     * At the call to getChainlinkUpdate at the beginning or end of the quarter, the current_block_number should
     * be passed in as the block number at the beginning or end of the quarter.
     * On all other calls, current_block_number should be fed as the block number
     * at the most recent time the Oracle has updated its data
     */
    function getChainlinkUpdate() external returns (bool updated) {
        require(Q3_set, "Quarter details not set yet");
        uint256 i = Q3_details.number_of_updates;
        require(i < 13, "All datapoints for the quarter have been collected");

        ChainlinkUpdate memory current_update =
            read_chainlink(
                Q3_details.chainlink_blocknum_oracle,
                Q3_details.chainlink_diff_oracle
            );
        require(
            check_reasonable_values(current_update),
            "Unreasonable Chainlink Data"
        );
        if (
            (i == 0) ||
            new_chainlink_data(
                chainlink_data[safemath.sub(i, 1)],
                current_update
            )
        ) {
            chainlink_data[i] = current_update;
            Q3_details.number_of_updates = safemath.add(
                Q3_details.number_of_updates,
                1
            );
            if (i > 0) {
                Q3_details.intermediateActualMinerEarnings = safemath.add(
                    Q3_details.intermediateActualMinerEarnings,
                    additional_miner_earnings(
                        chainlink_data[safemath.sub(i, 1)],
                        current_update
                    )
                );
            }
            return true;
        }
        return false;
    }

    /**
     * Checks if the current_update has updated difficulty and block_number values
     * compared to last_update. If either the difficulty or the block_number has
     * not been updated by Chainlink, this returns false.
     * @param last_update ChainlinkUpdate - previous update data returned by Chainlink Oracle
     * @param current_update ChainlinkUpdate - most recent update data returned by Chainlink Oracle
     */
    function new_chainlink_data(
        ChainlinkUpdate memory last_update,
        ChainlinkUpdate memory current_update
    ) internal pure returns (bool new_data) {
        bool new_difficulty_data =
            current_update.diff_roundID != last_update.diff_roundID;
        bool new_blocknum_data =
            current_update.blocknum_roundID != last_update.blocknum_roundID;
        return new_difficulty_data && new_blocknum_data;
    }

    /**
     * Calls Chainlink's Oracles, gets the latest data, and returns it.
     * @param blocknum_oracle IChainlinkOracle - Chainlink block number oracle
     * @param diff_oracle IChainlinkOracle - Chainlink difficulty number oracle
     */
    function read_chainlink(
        IChainlinkOracle blocknum_oracle,
        IChainlinkOracle diff_oracle
    ) internal view returns (ChainlinkUpdate memory latest) {
        uint80 updated_roundID_diff;
        int256 current_diff;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
        int256 current_blocknum;
        uint80 updated_roundID_blocknum;

        (
            updated_roundID_blocknum,
            current_blocknum,
            startedAt,
            updatedAt,
            answeredInRound
        ) = blocknum_oracle.latestRoundData();

        (
            updated_roundID_diff,
            current_diff,
            startedAt,
            updatedAt,
            answeredInRound
        ) = diff_oracle.latestRoundData();

        return
            ChainlinkUpdate(
                uint256(current_blocknum),
                uint256(current_diff),
                updated_roundID_blocknum,
                updated_roundID_diff
            );
    }

    /**
     * Revenue (in WBTC base units) for 10 TH/s over the blocks from startBlock to endBlock
     * does not account for if there is a halving in between a difficulty update.
     * should not be relevant for Q3 2021
     * @param last_update ChainlinkUpdate - previous update data returned by Chainlink Oracle
     * @param current_update ChainlinkUpdate - most recent update data returned by Chainlink Oracle
     */
    function additional_miner_earnings(
        ChainlinkUpdate memory last_update,
        ChainlinkUpdate memory current_update
    ) internal view returns (uint256 earnings) {
        uint256 startBlock = last_update.block_number;
        uint256 startDiff = last_update.difficulty;
        uint256 endBlock = current_update.block_number;
        uint256 endDiff = current_update.difficulty;

        require(
            endBlock >= startBlock,
            "Latest Block Number is less than last block number"
        );
        uint256 last_diff_update_block = get_last_diff_update(endBlock);
        if (last_diff_update_block <= startBlock) {
            return
                safemath.mul(
                    safemath.sub(endBlock, startBlock),
                    earnings_on_block(endDiff, startBlock)
                );
        } else {
            uint256 total =
                safemath.mul(
                    safemath.sub(last_diff_update_block, startBlock),
                    earnings_on_block(startDiff, startBlock)
                );
            total = safemath.add(
                total,
                safemath.mul(
                    safemath.sub(endBlock, last_diff_update_block),
                    earnings_on_block(endDiff, endBlock)
                )
            );
            return total;
        }
    }

    /**
     * Returns the Bitcoin block number when difficulty was last updated prior to the given block_num
     * @param block_num uint - bitcoin block number
     */
    function get_last_diff_update(uint256 block_num)
        internal
        view
        returns (uint256)
    {
        return
            safemath.sub(
                block_num,
                safemath.mod(block_num, numBlockBetweenDiffChanges)
            );
    }

    /**
     * Returns earnings in WBTC base units
     * @param difficulty uint - bitcoin network difficulty
     * @param block_number uint - bitcoin block number
     */
    function earnings_on_block(uint256 difficulty, uint256 block_number)
        internal
        view
        returns (uint256)
    {
        uint256 numerator =
            safemath.mul(factor, block_reward_on_block(block_number));
        return safemath.div(numerator, difficulty);
    }

    /**
     * Returns bitcoin block reward in WBTC base units
     * @param block_number uint - bitcoin block number
     */
    function block_reward_on_block(uint256 block_number)
        internal
        view
        returns (uint256)
    {
        uint256 divisor =
            2**(safemath.div(block_number, blocksBetweenHalvings));
        return safemath.div(initialBlockReward, divisor);
    }

    /**
     * Check that the values that are trying to be added to the ChainlinkData 
     * for a quarter actually makes sense. 
     * Returns True if the update seems reasonable and returns false if the update
     * values seems unreasonable
     * Very generous constraints that are just sanity checks.
     * @param update ChainlinkUpdate - A chainlink update with block number and difficulty data
     */
    function check_reasonable_values(ChainlinkUpdate memory update)
        internal
        view
        returns (bool reasonable)
    {
        uint256 update_diff = update.difficulty;
        uint256 update_block_number = update.block_number;
        uint256 number_of_updates = Q3_details.number_of_updates;
        if (
            (update_diff > maxValidDifficulty) ||
            (update_diff < minValidDifficulty)
        ) {
            return false;
        }
        if (
            (update_block_number > maxValidBlockNum) ||
            (update_block_number < minValidBlockNum)
        ) {
            return false;
        }
        if (number_of_updates > 0) {
            uint256 last_update_block_number =
                chainlink_data[safemath.sub(number_of_updates, 1)].block_number;
            if (update_block_number <= last_update_block_number) {
                return false;
            }
            if (
                update_block_number >
                safemath.add(
                    last_update_block_number,
                    maxValidBlockNumberIncrease
                )
            ) {
                return false;
            }
        }
        return true;
    }

    // payouts are set in WBTC base units for 1.0 tokens
    function set_payouts() public {
        require(
            Q3_details.number_of_updates == 13,
            "Need 13 datapoints before setting payout"
        );
        require(
            (block.timestamp >= Q3_details.end_unix),
            "You cannot set a payout yet"
        );

        uint256 hedged_revenue = Q3_details.hedged_revenue;
        uint256 required_collateral = Q3_details.required_collateral;

        uint256 miner_revenue =
            safemath.div(Q3_details.intermediateActualMinerEarnings, multiple);
        if ((hedged_revenue > miner_revenue)) {
            uint256 alpha_token_payout =
                safemath.min(
                    safemath.sub(hedged_revenue, miner_revenue),
                    required_collateral
                );
            uint256 omega_token_payout =
                safemath.sub(required_collateral, alpha_token_payout);
            Q3_details.alpha_token.set_payout(alpha_token_payout);
            Q3_details.omega_token.set_payout(omega_token_payout);
        } else {
            Q3_details.alpha_token.set_payout(0);
            Q3_details.omega_token.set_payout(required_collateral);
        }
    }

    // If any address accidentally sends any ERC20 token to this address,
    // they can contact us. Off-chain we will verify that the address did
    // in fact accidentally send tokens and return them.
    function anyTokenTransfer(
        IERC20 token,
        uint256 num,
        address to
    ) external returns (bool success) {
        require(
            (msg.sender == KladeAddress1 || msg.sender == KladeAddress2),
            "Only Klade can recover tokens"
        );
        return token.transfer(to, num);
    }
}