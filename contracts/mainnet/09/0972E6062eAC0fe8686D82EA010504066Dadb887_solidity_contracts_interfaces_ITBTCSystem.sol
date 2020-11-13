pragma solidity 0.5.17;

/**
 * @title Keep interface
 */

interface ITBTCSystem {

    // expected behavior:
    // return the price of 1 sat in wei
    // these are the native units of the deposit contract
    function fetchBitcoinPrice() external view returns (uint256);

    // passthrough requests for the oracle
    function fetchRelayCurrentDifficulty() external view returns (uint256);
    function fetchRelayPreviousDifficulty() external view returns (uint256);
    function getNewDepositFeeEstimate() external view returns (uint256);
    function getAllowNewDeposits() external view returns (bool);
    function isAllowedLotSize(uint64 _requestedLotSizeSatoshis) external view returns (bool);
    function requestNewKeep(uint64 _requestedLotSizeSatoshis, uint256 _maxSecuredLifetime) external payable returns (address);
    function getSignerFeeDivisor() external view returns (uint16);
    function getInitialCollateralizedPercent() external view returns (uint16);
    function getUndercollateralizedThresholdPercent() external view returns (uint16);
    function getSeverelyUndercollateralizedThresholdPercent() external view returns (uint16);
}
