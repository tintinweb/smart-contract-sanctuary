pragma solidity 0.5.17;


// Compound finance Comptroller interface
// Documentation: https://compound.finance/docs/comptroller
interface IComptroller {
    function claimComp(address holder) external;
    function getCompAddress() external view returns (address);
}