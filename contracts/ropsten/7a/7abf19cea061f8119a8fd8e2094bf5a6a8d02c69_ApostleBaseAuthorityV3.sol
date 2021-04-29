/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// Verified by Darwinia Network

// hevm: flattened sources of contracts/ApostleBaseAuthorityV3.sol

pragma solidity >=0.4.24 <0.5.0;

////// contracts/ApostleBaseAuthorityV3.sol
/* pragma solidity ^0.4.24; */

contract ApostleBaseAuthorityV3 {
    address public root;
    modifier sudo { require(msg.sender == root); _; }
    event LogSetRoot(address indexed newRoot);
    function setRoot(address usr) public sudo {
        root = usr;
        emit LogSetRoot(usr);
    }

    mapping (address => bool) public wards;
    event LogRely(address indexed usr);
    function rely(address usr) public sudo { wards[usr] = true; emit LogRely(usr); }
    event LogDeny(address indexed usr);
    function deny(address usr) public sudo { wards[usr] = false; emit LogDeny(usr); }

    constructor(address[] _wards) public {
        root = msg.sender;
        emit LogSetRoot(root);
        for (uint i = 0; i < _wards.length; i ++) { rely(_wards[i]); }
    }

    function canCall(
        address _src, address /*_dst*/, bytes4 _sig
    ) public view returns (bool) {
        return ( wards[_src] && _sig == bytes4(keccak256("createApostle(uint256,uint256,uint256,uint256,uint256,address)")) ) ||
               ( wards[_src] && _sig == bytes4(keccak256("breedWithInAuction(uint256,uint256)")) ) ||
               ( wards[_src] && _sig == bytes4(keccak256("activityAdded(uint256,address,address)"))) ||
                ( wards[_src] && _sig == bytes4(keccak256("activityRemoved(uint256,address,address)"))) ||
                ( wards[_src] && _sig == bytes4(keccak256("updateGenesAndTalents(uint256,uint256,uint256)"))) ||
                ( wards[_src] && _sig == bytes4(keccak256("batchUpdate(uint256[],uint256[],uint256[])"))) ||
                ( wards[_src] && _sig == bytes4(keccak256("activityStopped(uint256)")));
    }
}