/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

/// SPDX-License-Identifier: MIT
/*
▄▄█    ▄   ██   █▄▄▄▄ ▄█ 
██     █  █ █  █  ▄▀ ██ 
██ ██   █ █▄▄█ █▀▀▌  ██ 
▐█ █ █  █ █  █ █  █  ▐█ 
 ▐ █  █ █    █   █    ▐ 
   █   ██   █   ▀   
           ▀          */
/// Special thanks to Keno, Boring and Gonpachi for review and inspiration.
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]
/// License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @notice Inari registers and batches contract calls for crafty strategies.
contract Inari {
    address public dao = msg.sender; // initialize governance with Inari summoner
    uint public offerings; // strategies offered into Kitsune and `inari()` calls
    mapping(uint => Kitsune) kitsune; // internal Kitsune mapping to `offerings`
    
    event MakeOffering(address indexed server, address[] to, bytes4[] sig, bytes32 descr, uint indexed offering);
    event Bridge(IERC20[] token, address[] approveTo);
    event Govern(address indexed dao, uint indexed kit, bool zenko);
    
    /// @notice Stores Inari strategies - `zenko` flagged by `dao`.
    struct Kitsune {
        address[] to;
        bytes4[] sig;
        bytes32 descr;
        bool zenko;
    }
    
    /*********
    CALL INARI 
    *********/
    /// @notice Batch Inari strategies and perform calls.
    /// @param kit Kitsune strategy 'offerings' ID.
    /// @param value ETH value (if any) for call.
    /// @param param Parameters for call data after Kitsune `sig`.
    function inari(uint[] calldata kit, uint[] calldata value, bytes[] calldata param) 
        external payable returns (bool success, bytes memory returnData) {
        for (uint i = 0; i < kit.length; i++) {
            Kitsune storage ki = kitsune[kit[i]];
            (success, returnData) = ki.to[i].call{value: value[i]}
            (abi.encodePacked(ki.sig[i], param[i]));
            require(success, '!served');
        }
    }
    
    /// @notice Batch Inari strategies into single call with `zenko` check.
    /// @param kit Kitsune strategy 'offerings' ID.
    /// @param value ETH value (if any) for call.
    /// @param param Parameters for call data after Kitsune `sig`.
    function inariZushi(uint[] calldata kit, uint[] calldata value, bytes[] calldata param) 
        external payable returns (bool success, bytes memory returnData) {
        for (uint i = 0; i < kit.length; i++) {
            Kitsune storage ki = kitsune[kit[i]];
            require(ki.zenko, "!zenko");
            (success, returnData) = ki.to[i].call{value: value[i]}
            (abi.encodePacked(ki.sig[i], param[i]));
            require(success, '!served');
        }
    }
    
    /********
    OFFERINGS 
    ********/
    /// @notice Inspect a Kitsune offering (`kit`).
    function checkOffering(uint kit) external view returns (address[] memory to, bytes4[] memory sig, string memory descr, bool zenko) {
        Kitsune storage ki = kitsune[kit];
        to = ki.to;
        sig = ki.sig;
        descr = string(abi.encodePacked(ki.descr));
        zenko = ki.zenko;
    }
    
    /// @notice Offer Kitsune strategy that can be called by `inari()`.
    /// @param to The contract(s) to be called in strategy. 
    /// @param sig The function signature(s) involved (completed by `inari()` `param`).
    function makeOffering(address[] calldata to, bytes4[] calldata sig, bytes32 descr) external { 
        uint kit = offerings;
        kitsune[kit] = Kitsune(to, sig, descr, false);
        offerings++;
        emit MakeOffering(msg.sender, to, sig, descr, kit);
    }
    
    /*********
    GOVERNANCE 
    *********/
    /// @notice Approve token for Inari to spend among contracts.
    /// @param token ERC20 contract(s) to register approval for.
    /// @param approveTo Spender contract(s) to pull `token` in `inari()` calls.
    function bridge(IERC20[] calldata token, address[] calldata approveTo) external {
        for (uint i = 0; i < token.length; i++) {
            token[i].approve(approveTo[i], type(uint).max);
            emit Bridge(token, approveTo);
        }
    }
    
    /// @notice Update Inari `dao` and Kitsune `zenko` status.
    /// @param dao_ Address to grant Kitsune governance.
    /// @param kit Kitsune strategy 'offerings' ID.
    /// @param zen `kit` approval. 
    function govern(address dao_, uint kit, bool zen) external {
        require(msg.sender == dao, "!dao");
        dao = dao_;
        kitsune[kit].zenko = zen;
        emit Govern(dao_, kit, zen);
    }
}