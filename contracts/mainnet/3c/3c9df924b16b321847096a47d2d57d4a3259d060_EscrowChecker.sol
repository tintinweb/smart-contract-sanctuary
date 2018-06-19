pragma solidity ^0.4.21;


contract HavvenEscrow {
    function numVestingEntries(address account) public returns (uint);
    function getVestingScheduleEntry(address account, uint index) public returns (uint[2]);
}


contract EscrowChecker {
    HavvenEscrow public havven_escrow;
    function EscrowChecker(HavvenEscrow _esc) public {
        havven_escrow = _esc;
    }

    function checkAccountSchedule(address account)
        public
        view
        returns (uint[16])
    {
        uint[16] memory _result;
        uint schedules = havven_escrow.numVestingEntries(account);
        for (uint i=0; i < schedules; i++) {
            uint[2] memory pair = havven_escrow.getVestingScheduleEntry(account, i);
            _result[i*2] = pair[0];
            _result[i*2 + 1] = pair[1];
        }
        return _result;
    }
}