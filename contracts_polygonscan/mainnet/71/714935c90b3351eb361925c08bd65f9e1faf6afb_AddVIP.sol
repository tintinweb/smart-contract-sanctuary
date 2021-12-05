/**
 *Submitted for verification at polygonscan.com on 2021-12-05
*/

pragma solidity ^0.8.0;
/*
0x714935C90b3351eB361925C08bD65F9e1FAf6aFB
*/

interface LBEGG {
    function addVIP(address a, uint v) external;
    function vipList(address) external view returns(uint256);
}

contract AddVIP {
    
    address public lbegg = 0x1Eadfc06342895cf9a2cA50ee9Fc1032C6cAfc59;
    address admin;
    mapping (address => uint) public operators;
    uint public opIx;
    LBEGG eggCon;
    
    constructor() {
        eggCon = LBEGG(lbegg);
        admin = msg.sender;
    }
    
    function selfDestruct() external {
        require(msg.sender == admin);
        selfdestruct(payable(admin));
    }
    
    function addVIP(address[] calldata aa, uint val) external {
        require( operators[msg.sender] > 0 || msg.sender == admin );
        for(uint k = 0; k < aa.length; k++) {
            eggCon.addVIP(aa[k], val);
        }
    }
    
    function setLbEgg(address a) external {
        require(msg.sender == admin);
        lbegg = a;
        eggCon = LBEGG(lbegg);
    }
    
    function modOperator(address a, uint status) external {
        require(msg.sender == admin);
        if(status > 0) {
            if(operators[a] == 0)
                operators[a] = ++opIx;
        }
        else { // clear
            if(operators[a] > 0)
                delete operators[a];
        }
    }

    function checkVIP() external view returns(bool) {
        if( eggCon.vipList(msg.sender) % 3 == 1 )
            return true;
        else
            return false;
    }
}