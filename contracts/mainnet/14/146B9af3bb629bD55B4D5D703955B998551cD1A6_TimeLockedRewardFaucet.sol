pragma solidity ^0.4.11;

contract ERC20_Transferable {
    function balanceOf(address addr) public returns(uint);
    function transfer(address to, uint value) public returns (bool);
}

contract TimeLockedRewardFaucet {

    // =========== CONFIG START =========== 
    address constant public MULTISIG_OWNER = 0xe18Af0dDA74fC4Ee90bCB37E45b4BD623dC6e099;
    address constant public TEAM_WALLET = 0x008cdC9b89AD677CEf7F2C055efC97d3606a50Bd;

    ERC20_Transferable public token = ERC20_Transferable(0x7C5A0CE9267ED19B22F8cae653F198e3E8daf098);
    uint constant public LOCK_RELASE_TIME = 1502661351 + 15 minutes; //block.timestamp(4011221) == 1499846591
    uint constant public WITHDRAWAL_END_TIME = LOCK_RELASE_TIME + 10 minutes;
    // =========== CONFIG END ===========

    address[] public team_accounts;
    uint      public locked_since = 0;
    uint      amount_to_distribute;

    function all_team_accounts() external constant returns(address[]) {
        return team_accounts;
    }

    function timeToUnlockDDHHMM() external constant returns(uint[3]) {
        if (LOCK_RELASE_TIME > now) {
            uint diff = LOCK_RELASE_TIME - now;
            uint dd = diff / 1 days;
            uint hh = diff % 1 days / 1 hours;
            uint mm = diff % 1 hours / 1 minutes;
            return [dd,hh,mm];
        } else {
            return [uint(0), uint(0), uint(0)];
        }
    }

    function start() external
    only(MULTISIG_OWNER)
    inState(State.INIT){
        locked_since = now;
    }

    function () payable {
        msg.sender.transfer(msg.value); //pay back whole amount sent

        State state = _state();
        if (state==State.INIT) {
            //collect addresses for payout
            require(indexOf(team_accounts,msg.sender)==-1);
            team_accounts.push(msg.sender);
        } else if (state==State.WITHDRAWAL) {
            // setup amount to distribute
            if (amount_to_distribute==0) amount_to_distribute = token.balanceOf(this);
            //payout processing
            require(indexOf(team_accounts, msg.sender)>=0);
            token.transfer(msg.sender,  amount_to_distribute / team_accounts.length);
        } else if (state==State.CLOSED) {
            //collect unclaimed token to team wallet
            require(msg.sender == TEAM_WALLET);
            var balance = token.balanceOf(this);
            token.transfer(msg.sender, balance);
        } else {
            revert();
        }
    }


    enum State {INIT, LOCKED, WITHDRAWAL, CLOSED}
    string[4] labels = ["INIT", "LOCKED", "WITHDRAWAL", "CLOSED"];

    function _state() internal returns(State) {
        if (locked_since == 0)               return State.INIT;
        else if (now < LOCK_RELASE_TIME)     return State.LOCKED;
        else if (now < WITHDRAWAL_END_TIME)  return State.WITHDRAWAL;
        else return State.CLOSED;
    }

    function state() constant public returns(string) {
        return labels[uint(_state())];
    }

    function indexOf(address[] storage addrs, address addr) internal returns (int){
         for(uint i=0; i<addrs.length; ++i) {
            if (addr == addrs[i]) return int(i);
        }
        return -1;
    }

    //fails if state dosn&#39;t match
    modifier inState(State s) {
        if (_state() != s) revert();
        _;
    }

    modifier only(address allowed) {
        if (msg.sender != allowed) revert();
        _;
    }

}