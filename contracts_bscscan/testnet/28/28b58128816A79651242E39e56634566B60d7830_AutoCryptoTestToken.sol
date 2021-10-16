pragma solidity ^0.8.0;

/**
 * @notice Interface for AutoCrypto presales contracts. {releaseToken} will gather the contributed BNB.
*/
interface Presale {
    function releaseToken() external;
}

contract AutoCryptoTestToken {


    function releaseToken(address presale) public {
        Presale(presale).releaseToken();
    }

}