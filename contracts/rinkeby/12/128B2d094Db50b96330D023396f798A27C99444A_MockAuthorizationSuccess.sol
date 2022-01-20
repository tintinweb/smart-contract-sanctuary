/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// File: contracts/interfaces/IAuthorizationContract.sol



pragma solidity ^0.8.9;

interface IAuthorizationContract {
    function isAccountAuthorized(
        address _account,
        uint256 id,
        bytes memory data
    ) external view returns (bool);
}

// File: contracts/MockAuthorizationContract.sol

pragma solidity ^0.8.9;

// @notice An authorization contract to pass all transfers
contract MockAuthorizationSuccess is IAuthorizationContract {
    function isAccountAuthorized(
        address,
        uint256,
        bytes memory
    ) external pure returns (bool) {
        return true;
    }
}