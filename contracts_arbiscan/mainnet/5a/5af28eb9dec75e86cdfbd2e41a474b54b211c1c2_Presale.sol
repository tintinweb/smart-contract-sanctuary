/**
 *Submitted for verification at arbiscan.io on 2021-11-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @notice Info Storage for Tangle
/// @dev This is a Diamond Storage implementation described in EIP-2535.
library SLib {

    struct SBundle {
        bool minted;
        uint8 decimals;
        address liquidityAddress;
        uint wc;
        uint last;
        uint totalSupply;
        uint piecesPerUnit;
        uint minHoldAmount;
        uint cropDustAmount;
        string name;
        string symbol;
        address[] addresses;
        address[] blacklist;
        string[] names;
        Reflect_[] reflects;
        mapping(address => uint) balances;
        mapping(address => uint) addressIndex;
        mapping(address => uint) reflectIndex;
        mapping(address => uint) blacklistIndex;
        mapping(address => Split) splits;
        mapping(string => uint) nameIndex;
        mapping(string => string) ids;
        mapping(string => Farm) farms;
        mapping(address => mapping(address => uint)) allowances;
        mapping(address => mapping(string => uint)) points;
        mapping(address => mapping(string => uint)) rewards;
        mapping(address => mapping(string => uint)) wcInits;
        mapping(address => mapping(string => uint)) propSumInits;
    }
    struct Reflect_ {
        address address_;
        bool flag;
    }
    struct Split {
        uint16 numerator;
        uint16 denominator;
        address to;
    }
    struct Farm {
        uint C;
        uint N;
        uint D;
        uint max;
        uint last;
        uint start;
        uint elapsed;
        uint propSum;
        uint points;
        string name;
    }
    struct S {
        bool enabled;
        uint nativeTotal;
        uint goal;
        uint tokens;
        uint piecesPerUnit;
        mapping(address => uint) values;
        mapping(address => uint) balances;
        address[] buyInAddresses;
    }
    event Transfer(address sender, address receiever, uint value);
    event GoalChange(uint goal);
    event TokensChange(uint tokens);
    event EnabledChange(bool enabled);
    event BuyIn(address sender, uint value);
    event Disburse(uint total);
    event Refund();

    function getS() internal pure returns (S storage s) {
        bytes32 storagePosition = keccak256(bytes("0.Presale"));
        assembly { s.slot := storagePosition }
    }

    function getSBundle() internal pure returns (SBundle storage s) {
        bytes32 storagePosition = keccak256(bytes("0"));
        assembly { s.slot := storagePosition }
    }

}

/// @title Presale
/// @author Brad Brown
/// @notice This contract provides presale functions for Tangle
/// (assumes that presale tokens are minted)
contract Presale {

    mapping(bytes4 => address) private _0;
    address private owner;

    function setGoal(uint goal_) external {
        require(msg.sender == owner);
        emit SLib.GoalChange(goal_);
        SLib.getS().goal = goal_;
    }
    
    function goal() external view returns (uint) {
        return SLib.getS().goal;
    }
    
    function setTokens(uint tokens_) external {
        require(msg.sender == owner);
        emit SLib.TokensChange(tokens_);
        SLib.getS().tokens = tokens_;
    }
    
    function tokens() external view returns (uint) {
        return SLib.getS().tokens;
    }
    
    function setEnabled(bool enabled_) external {
        require(msg.sender == owner);
        emit SLib.EnabledChange(enabled_);
        SLib.getS().enabled = enabled_;
    }
    
    function enabled() external view returns (bool) {
        return SLib.getS().enabled;
    }
    
    function buyIn() external payable {
        SLib.S storage s = SLib.getS();
        require(s.enabled == true && msg.value > 0);
        emit SLib.BuyIn(msg.sender, msg.value);
        if (s.values[msg.sender] == 0)
            s.buyInAddresses.push(msg.sender);
        s.values[msg.sender] += msg.value;
        s.nativeTotal += msg.value;
    }
    
    function nativeTotal() external view returns (uint) {
        return SLib.getS().nativeTotal;
    }
    
    function buyInAddresses() external view returns (address[] memory) {
        return SLib.getS().buyInAddresses;
    }
    
    function disburse() external {
        SLib.S storage s = SLib.getS();
        SLib.SBundle storage sBundle = SLib.getSBundle();
        require(msg.sender == owner && s.enabled == false && s.nativeTotal >= s.goal);
        if (sBundle.piecesPerUnit == 0)
            sBundle.piecesPerUnit = (type(uint128).max - (type(uint128).max % 10 ** 18)) / 10 ** 18;
        uint totalDisbursed;
        for (uint i = 0; i < s.buyInAddresses.length; i++) {
            address address_ = s.buyInAddresses[i];
            uint disbursedUnits = s.tokens * s.values[address_] / s.nativeTotal;
            sBundle.balances[address_] += unitsToPieces(disbursedUnits);
            emit SLib.Transfer(address(0), address_, disbursedUnits);
            totalDisbursed += disbursedUnits;
        }
        emit SLib.Disburse(totalDisbursed);
        payable(msg.sender).transfer(s.nativeTotal);
        require(!sBundle.minted);
        sBundle.name = "Tangle";
        sBundle.symbol = "TNGL";
        sBundle.decimals = 9;
        sBundle.totalSupply = 10 ** 18;
        sBundle.minted = true;
        sBundle.balances[msg.sender] = unitsToPieces(10 ** 18 - totalDisbursed);
        emit SLib.Transfer(address(0), msg.sender, 10 ** 18 - totalDisbursed);
    } 
    
    function refund() external {
        SLib.S storage s = SLib.getS();
        require(msg.sender == owner && s.enabled == false && s.nativeTotal < s.goal);
        for (uint i = 0; i < s.buyInAddresses.length; i++) {
            address address_ = s.buyInAddresses[i];
            payable(address_).transfer(s.values[address_]);
            s.values[address_] = 0;
        }
        delete s.buyInAddresses;
        s.nativeTotal = 0;
        emit SLib.Refund();
    }

    function unitsToPieces(uint units) internal view returns (uint) {
        return units * SLib.getSBundle().piecesPerUnit;
    }
    
    

}