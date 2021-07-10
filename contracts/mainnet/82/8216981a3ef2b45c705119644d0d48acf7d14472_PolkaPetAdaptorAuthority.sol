/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

// hevm: flattened sources of contracts/PolkaPetAdaptorAuthority.sol

pragma solidity >=0.4.24 <0.5.0;

////// contracts/PolkaPetAdaptorAuthority.sol
/* pragma solidity ^0.4.24; */

contract PolkaPetAdaptorAuthority {
    mapping (address => bool) public whiteList;

    constructor(address[] _whitelists) public {
        for (uint i = 0; i < _whitelists.length; i++) {
            whiteList[_whitelists[i]] = true;
        }
    }

    function canCall(
        address _src, address /*_dst*/, bytes4 _sig
    ) public view returns (bool) {
        return  whiteList[_src] && _sig == bytes4(keccak256("toMirrorTokenIdAndIncrease(uint256)"));
    }
}