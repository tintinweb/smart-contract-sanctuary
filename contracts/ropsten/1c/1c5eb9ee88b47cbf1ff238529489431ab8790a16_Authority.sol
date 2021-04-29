/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// Verified by Darwinia Network

// hevm: flattened sources of contracts/Authority.sol

pragma solidity >=0.4.24 <0.5.0;

////// contracts/Authority.sol
/* pragma solidity ^0.4.24; */

contract Authority {
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Allow(bytes4 indexed usr);
    event Forbid(bytes4 indexed usr);
    event SetRoot(address indexed newRoot);

    address public root;
    mapping (address => uint) public wards;
    mapping (bytes4 => uint)  public sigs;

    modifier sudo { require(msg.sender == root); _; }
    function setRoot(address usr) public sudo { root = usr; emit SetRoot(usr); }
    function rely(address usr)    public sudo { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr)    public sudo { wards[usr] = 0; emit Deny(usr); }
    function allow(bytes4 sig)    public sudo { sigs[sig] = 1; emit Allow(sig); }
    function forbid(bytes4 sig)   public sudo { sigs[sig] = 0; emit Forbid(sig); }

    constructor(address[] _wards, bytes4[] _sigs) public {
        root = msg.sender;
        emit SetRoot(root);
        for (uint i = 0; i < _wards.length; i++) { rely(_wards[i]); }
        for (uint j = 0; j < _sigs.length; j++) { allow(_sigs[j]); }
    }

    function canCall(
        address _src, address, bytes4 _sig
    ) public view returns (bool) {
        return wards[_src] == 1 && sigs[_sig] == 1;
    }
}