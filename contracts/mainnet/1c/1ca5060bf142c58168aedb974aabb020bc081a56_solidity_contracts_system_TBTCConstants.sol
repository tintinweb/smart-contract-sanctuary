pragma solidity 0.5.17;

library TBTCConstants {
    // This is intended to make it easy to update system params
    // During testing swap this out with another constats contract

    // System Parameters
    uint256 public constant BENEFICIARY_FEE_DIVISOR = 1000;  // 1/1000 = 10 bps = 0.1% = 0.001
    uint256 public constant SATOSHI_MULTIPLIER = 10 ** 10; // multiplier to convert satoshi to TBTC token units
    uint256 public constant DEPOSIT_TERM_LENGTH = 180 * 24 * 60 * 60; // 180 days in seconds
    uint256 public constant TX_PROOF_DIFFICULTY_FACTOR = 6; // confirmations on the Bitcoin chain

    // Redemption Flow
    uint256 public constant REDEMPTION_SIGNATURE_TIMEOUT = 2 * 60 * 60;  // seconds
    uint256 public constant INCREASE_FEE_TIMER = 4 * 60 * 60;  // seconds
    uint256 public constant REDEMPTION_PROOF_TIMEOUT = 6 * 60 * 60;  // seconds
    uint256 public constant MINIMUM_REDEMPTION_FEE = 2000; // satoshi
    uint256 public constant MINIMUM_UTXO_VALUE = 2000; // satoshi

    // Funding Flow
    uint256 public constant FUNDING_PROOF_TIMEOUT = 3 * 60 * 60; // seconds
    uint256 public constant FORMATION_TIMEOUT = 3 * 60 * 60; // seconds

    // Liquidation Flow
    uint256 public constant COURTESY_CALL_DURATION = 6 * 60 * 60; // seconds
    uint256 public constant AUCTION_DURATION = 24 * 60 * 60; // seconds

    // Getters for easy access
    function getBeneficiaryRewardDivisor() external pure returns (uint256) { return BENEFICIARY_FEE_DIVISOR; }
    function getSatoshiMultiplier() external pure returns (uint256) { return SATOSHI_MULTIPLIER; }
    function getDepositTerm() external pure returns (uint256) { return DEPOSIT_TERM_LENGTH; }
    function getTxProofDifficultyFactor() external pure returns (uint256) { return TX_PROOF_DIFFICULTY_FACTOR; }

    function getSignatureTimeout() external pure returns (uint256) { return REDEMPTION_SIGNATURE_TIMEOUT; }
    function getIncreaseFeeTimer() external pure returns (uint256) { return INCREASE_FEE_TIMER; }
    function getRedemptionProofTimeout() external pure returns (uint256) { return REDEMPTION_PROOF_TIMEOUT; }
    function getMinimumRedemptionFee() external pure returns (uint256) { return MINIMUM_REDEMPTION_FEE; }
    function getMinimumUtxoValue() external pure returns (uint256) { return MINIMUM_UTXO_VALUE; }

    function getFundingTimeout() external pure returns (uint256) { return FUNDING_PROOF_TIMEOUT; }
    function getSigningGroupFormationTimeout() external pure returns (uint256) { return FORMATION_TIMEOUT; }

    function getCourtesyCallTimeout() external pure returns (uint256) { return COURTESY_CALL_DURATION; }
    function getAuctionDuration() external pure returns (uint256) { return AUCTION_DURATION; }
}
