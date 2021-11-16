/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

// MPC management means multi-party validation.
// MPC signing likes Multi-Signature is more secure than use private key directly.
contract MPCManageable {
    address public mpc;
    address public pendingMPC;

    uint256 public constant delay = 2*24*3600;
    uint256 public delayMPC;

    modifier onlyMPC() {
        require(msg.sender == mpc, "MPC: only mpc");
        _;
    }

    event LogChangeMPC(
        address indexed oldMPC,
        address indexed newMPC,
        uint256 indexed effectiveTime);

    event LogApplyMPC(
        address indexed oldMPC,
        address indexed newMPC,
        uint256 indexed applyTime);

    constructor(address _mpc) {
        require(_mpc != address(0), "MPC: mpc is the zero address");
        mpc = _mpc;
        emit LogChangeMPC(address(0), mpc, block.timestamp);
    }

    function changeMPC(address _mpc) external onlyMPC {
        require(_mpc != address(0), "MPC: mpc is the zero address");
        pendingMPC = _mpc;
        delayMPC = block.timestamp + delay;
        emit LogChangeMPC(mpc, pendingMPC, delayMPC);
    }

    function applyMPC() external {
        require(msg.sender == pendingMPC, "MPC: only pendingMPC");
        require(block.timestamp >= delayMPC, "MPC: time before delayMPC");
        emit LogApplyMPC(mpc, pendingMPC, block.timestamp);
        mpc = pendingMPC;
        pendingMPC = address(0);
        delayMPC = 0;
    }
}

// support limit operations to whitelist
contract Whitelistable is MPCManageable {
    bool public whitelistEnabled;
    mapping(address => bool) public isInWhitelist;

    event LogSetWhitelist(address indexed to, bool indexed flag);

    modifier onlyWhitelist(address[] memory to) {
        if (whitelistEnabled) {
            for (uint256 i = 0; i < to.length; i++) {
                require(isInWhitelist[to[i]], "AnyCall: to address is not in whitelist");
            }
        }
        _;
    }

    constructor(address _mpc) MPCManageable(_mpc) {
        //whitelistEnabled = true;
        whitelistEnabled = false;
    }

    function enableWhitelist() external onlyMPC {
        whitelistEnabled = true;
    }

    function disableWhitelist() external onlyMPC {
        whitelistEnabled = false;
    }

    function whitelist(address to, bool flag) external onlyMPC {
        isInWhitelist[to] = flag;
        emit LogSetWhitelist(to, flag);
    }
}

contract AnyCallProxy is Whitelistable {
    uint256 public immutable cID;

    event LogAnyCall(address indexed from, address[] to, bytes[] data,
                     address[] callbacks, uint256[] nonces, uint256 fromChainID, uint256 toChainID);
    event LogAnyExec(address indexed from, address[] to, bytes[] data, bool[] success, bytes[] result,
                     address[] callbacks, uint256[] nonces, uint256 fromChainID, uint256 toChainID);

    constructor(address _mpc) Whitelistable(_mpc) {
        uint256 id;
        assembly {id := chainid()}
        cID = id;
    }

    /**
        @notice Trigger a cross-chain contract interaction
        @param to - list of addresses to call
        @param data - list of data payloads to send / call
        @param callbacks - the callbacks on the fromChainID to call
        `callback(address to, bytes data, uint256 nonces, uint256 fromChainID, bool success, bytes result)`
        @param nonces - the nonces (ordering) to include for the resulting callback
        @param toChainID - the recipient chain that will receive the events
    */
    function anyCall(
        address[] memory to,
        bytes[] memory data,
        address[] memory callbacks,
        uint256[] memory nonces,
        uint256 toChainID
    ) external onlyWhitelist(to) {
        emit LogAnyCall(msg.sender, to, data, callbacks, nonces, cID, toChainID);
    }

    function anyCall(
        address from,
        address[] memory to,
        bytes[] memory data,
        address[] memory callbacks,
        uint256[] memory nonces,
        uint256 fromChainID
    ) external onlyMPC {
        uint256 length = to.length;
        bool[] memory success = new bool[](length);
        bytes[] memory results = new bytes[](length);
        for (uint256 i = 0; i < length; i++) {
            address _to = to[i];
            if (!whitelistEnabled || isInWhitelist[_to]) {
                (success[i], results[i]) = _to.call{value:0}(data[i]);
            } else {
                (success[i], results[i]) = (false, "forbid calling");
            }
        }
        emit LogAnyExec(from, to, data, success, results, callbacks, nonces, fromChainID, cID);
    }

    function encode(
        string memory signature,
        bytes memory data
    ) external pure returns (bytes memory) {
        return abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    function encodePermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)",
            owner, spender, value, deadline, v, r, s);
    }

    function encodeTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            sender, recipient, amount);
    }
}