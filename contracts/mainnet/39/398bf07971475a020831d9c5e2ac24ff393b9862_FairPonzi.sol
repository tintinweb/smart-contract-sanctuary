pragma solidity ^0.4.0;

contract FairPonzi {
    struct Investment {
        uint initamount;
        uint inittime;
        
        uint refbonus;
        address refaddress;
        uint refcount;
    }
    struct Payment {
        address receiver;
        uint inamount;
        uint outamount;
    }
    mapping(uint => mapping(address => Investment)) public investmentTable;
    mapping(uint => Payment) public payoutList;
    
    uint public rewardinterval = 3600 * 24; // 1day
    //uint public rewardinterval = 60; // 1min
    uint public constant minbid = 1000000000000; // 1uETH
    uint public payoutcount = 0;
    uint public constant startblock = 5646372; // this disables preinvest advantage
    uint public payincount = 0;
    uint roundcount = 0;
    uint constant maxdays = 365 * 3; // max 3 years, to cap gas costs
    
    address constant restaddress = 0x9feA38edD1875cefD3D071C549a3f7Cc7983B455;
    address constant nulladdress = 0x0000000000000000000000000000000000000000;
    
    constructor() public {
    }
    
    function () public payable {
        buyin(nulladdress); // if normal transaction, nobody get referral
    }
    function buyin(address refaddr)public payable{
        if(block.number < startblock) revert();
        if(msg.value < minbid) { // wants a payout
            redeemPayout();
            return;
        }
        Investment storage acc = investmentTable[roundcount][msg.sender];
        uint addreward = getAccountBalance(msg.sender);
        uint win = addreward - acc.initamount;
        if(win > 0){
            investmentTable[roundcount][acc.refaddress].refbonus += win / 10; // Referral get 10%
        }
        
        acc.initamount = msg.value + addreward;
        acc.inittime = block.timestamp;
        if(refaddr != msg.sender && acc.refaddress == nulladdress){
            acc.refaddress = refaddr;
            investmentTable[roundcount][refaddr].refcount++;
        }
        
        payincount++;
    }
    function redeemPayout() public {
        Investment storage acc = investmentTable[roundcount][msg.sender];
        uint addreward = getAccountBalance(msg.sender);
        uint win = addreward - acc.initamount;
        uint payamount = addreward + acc.refbonus;
        if(payamount <= 0) return;
        if(address(this).balance < payamount){
            reset();
        }else{
            payoutList[payoutcount++] = Payment(msg.sender, acc.initamount, payamount);
            acc.initamount = 0;
            acc.refbonus = 0;
            msg.sender.transfer(payamount);
            investmentTable[roundcount][acc.refaddress].refbonus += win / 10; // Referral get 10%
        }
    }
    function reset() private {
        // todo reset list
        if(restaddress.send(address(this).balance)){
            // Should always be possible, otherwise new payers have good luck ;)
        }
        roundcount++;
        payincount = 0;
    }
    function getAccountBalance(address addr)public constant returns (uint amount){
        Investment storage acc = investmentTable[roundcount][addr];
        uint ret = acc.initamount;
        if(acc.initamount > 0){
            uint rewardcount = (block.timestamp - acc.inittime) / rewardinterval;
            if(rewardcount > maxdays) rewardcount = maxdays;
            while(rewardcount > 0){
                ret += ret / 200; // 0.5%
                rewardcount--;
            }
        }
        return ret;
    }
    function getPayout(uint idrel) public constant returns (address bidder, uint inamount, uint outamount) {
        Payment storage cur =  payoutList[idrel];
        return (cur.receiver, cur.inamount, cur.outamount);
    }
    function getBlocksUntilStart() public constant returns (uint count){
        if(startblock <= block.number) return 0;
        else return startblock - block.number;
    }
    function getAccountInfo(address addr) public constant returns (address retaddr, uint initamount, uint investmenttime, uint currentbalance, uint _timeuntilnextreward, uint _refbonus, address _refaddress, uint _refcount) {
        Investment storage acc = investmentTable[roundcount][addr];
        uint nextreward = rewardinterval - ((block.timestamp - acc.inittime) % rewardinterval);
        if(acc.initamount <= 0) nextreward = 0;
        return (addr, acc.initamount, block.timestamp - acc.inittime, getAccountBalance(addr), nextreward, acc.refbonus, acc.refaddress, acc.refcount);
    }
    function getAccountInfo() public constant returns (address retaddr, uint initamount, uint investmenttime, uint currentbalance, uint _timeuntilnextreward, uint _refbonus, address _refaddress, uint _refcount) {
        return getAccountInfo(msg.sender);
    }
    function getStatus() public constant returns (uint _payoutcount, uint _blocksUntilStart, uint _payincount){
        return (payoutcount, getBlocksUntilStart(), payincount);
    }
}