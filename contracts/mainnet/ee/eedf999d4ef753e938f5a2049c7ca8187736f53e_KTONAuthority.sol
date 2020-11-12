pragma solidity ^0.4.24;

contract KTONAuthority {

    mapping (address => bool) public allowList;

    constructor(address[] _allowlists) public {
        for (uint i = 0; i < _allowlists.length; i ++) {
            allowList[_allowlists[i]] = true;
        }
    }

    function canCall(
        address _src, address _dst, bytes4 _sig
    ) public view returns (bool) {
        return allowList[_src] && _sig == bytes4(keccak256("burn(address,uint256)"));
    }
}