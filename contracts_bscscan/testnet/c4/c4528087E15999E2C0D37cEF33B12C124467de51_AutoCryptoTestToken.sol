pragma solidity ^0.8.0;

/**
 * @notice Interface for AutoCrypto presales contracts. {releaseToken} will gather the contributed BNB.
*/
interface Presale {
    function releaseToken() external;
}

contract AutoCryptoTestToken {

    receive() payable external {}

    function releaseToken(address presale_) public {
        Presale(presale_).releaseToken();
    }

}