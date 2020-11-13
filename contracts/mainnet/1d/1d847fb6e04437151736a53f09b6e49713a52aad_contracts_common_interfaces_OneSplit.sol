pragma solidity ^0.6.0;


abstract contract OneSplit {
    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    ) public virtual view returns (uint256 returnAmount, uint256[] memory distribution);

    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    ) public virtual payable returns (uint256 returnAmount);
}
