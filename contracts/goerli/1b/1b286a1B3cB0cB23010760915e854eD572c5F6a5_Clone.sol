/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity 0.4.23;

contract Clone {

    function () public payable {
        address placeholder = 0x06e56Bd2e9BD750D1f5424E92fc11F36247D2e77;
        assembly {
            calldatacopy(0, 0, calldatasize)
            let res := delegatecall(gas, placeholder, 0, calldatasize, 0, 0)
            returndatacopy(0, 0, returndatasize)
            switch res case 0 { revert(0, returndatasize) } default { return(0, returndatasize) }
        }
    }
}