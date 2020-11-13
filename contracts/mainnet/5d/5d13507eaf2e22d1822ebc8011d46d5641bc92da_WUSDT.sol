// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IUSDT {
    function transferFrom(address _from, address _to, uint _value) external;
}

contract WUSDT {
    IUSDT constant USDT = IUSDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    function transferFrom(address _from, address _to, uint _value) public returns(bool) {
        require(msg.sender == 0xde4EE8057785A7e8e800Db58F9784845A5C2Cbd6, 'Only Dexe');
        USDT.transferFrom(_from, _to, _value);
        return true;
    }
}