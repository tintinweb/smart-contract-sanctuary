/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

pragma solidity ^0.5.16;




contract BaseSynthetix  {
    // ========== STATE VARIABLES ==========

    // Available Synths which can be used with the system
    string public constant TOKEN_NAME = "SDIP Network Token";
    string public constant TOKEN_SYMBOL = "SDIP";
    uint8 public constant DECIMALS = 18;
    bytes32 public constant sUSD = "dUSD";

 

    function debtBalanceOf(bytes32 stake, address account, bytes32 currencyKey) external view returns (uint) {
        return 2e25;
    }

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint) {
        return 2e26;
    }

    function availableCurrencyKeys() external view returns (bytes32[] memory) {
        uint numSynths = 2;
        bytes32[] memory currencyKeys = new bytes32[](numSynths);
        
        
        currencyKeys[0] = bytes32("sTSLA");
        currencyKeys[1] = bytes32("sAPPLE");
        
        return currencyKeys;
    }

    function availableSynthCount() external view returns (uint) {
        uint numSynths = 2;
        return numSynths;
    }


    function synthsByAddress(address synthAddress) external view returns (bytes32) {
        return bytes32("sTSLA");
    }

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool) {
        return true;
    }


    function maxIssuableSynths(address account) external view returns (uint maxIssuable) {
        uint numSynths = 2;
        return numSynths;
    }

  
    function collateralisationRatio(bytes32 stake, address _issuer) external view returns (uint) {
        return 2e18;
    }

    function collateral(bytes32 stake, address account) external view returns (uint) {
        return 2e23;
    }


    function issueSynths(bytes32 stake, uint amount) external  {
    }

    function issueSynthsOnBehalf(bytes32 stake, address issueForAddress, uint amount) external  {
    }

    function issueMaxSynths(bytes32 stake) external  {
    }

    function issueMaxSynthsOnBehalf(bytes32 stake, address issueForAddress) external  {
    }

    function burnSynths(bytes32 stake, uint amount) external  {
    }

 

    function exchange(
        bytes32,
        uint,
        bytes32
    ) external returns (uint) {
    }


    function mint() external returns (bool) {
    }


 
    function _notImplemented() internal pure {
        revert("Cannot be run on this layer");
    }

}