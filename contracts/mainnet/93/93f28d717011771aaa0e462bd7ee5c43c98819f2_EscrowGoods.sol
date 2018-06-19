/* A contract to store goods with escrowed funds. */

/* Deployment:
Contract:
Owner: seller
Last address: dynamic
ABI: [{&quot;constant&quot;:true,&quot;inputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;escrows&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;buyer&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;name&quot;:&quot;lockedFunds&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;frozenFunds&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;frozenTime&quot;,&quot;type&quot;:&quot;uint64&quot;},{&quot;name&quot;:&quot;count&quot;,&quot;type&quot;:&quot;uint16&quot;},{&quot;name&quot;:&quot;buyerNo&quot;,&quot;type&quot;:&quot;bool&quot;},{&quot;name&quot;:&quot;sellerNo&quot;,&quot;type&quot;:&quot;bool&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;count&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint16&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_dataInfo&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;name&quot;:&quot;_version&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;cancel&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;seller&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;freezePeriod&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_lockId&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_dataInfo&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;name&quot;:&quot;_version&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_count&quot;,&quot;type&quot;:&quot;uint16&quot;}],&quot;name&quot;:&quot;buy&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:true,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;status&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint16&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;rewardPromille&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_lockId&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;getMoney&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_lockId&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_dataInfo&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;name&quot;:&quot;_version&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;no&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[],&quot;name&quot;:&quot;kill&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_lockId&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_dataInfo&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;name&quot;:&quot;_version&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;reject&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_lockId&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_dataInfo&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;name&quot;:&quot;_version&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;accept&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;totalEscrows&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_lockId&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_who&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;name&quot;:&quot;_payment&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_dataInfo&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;name&quot;:&quot;_version&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;arbYes&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;feeFunds&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_lockId&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_dataInfo&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;name&quot;:&quot;_version&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;yes&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;name&quot;:&quot;buyers&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;bool&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;availableCount&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint16&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;price&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;contentCount&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;logsCount&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[],&quot;name&quot;:&quot;unbuy&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[],&quot;name&quot;:&quot;getFees&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;feePromille&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;pendingCount&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint16&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_dataInfo&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;name&quot;:&quot;_version&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;addDescription&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;arbiter&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;inputs&quot;:[{&quot;name&quot;:&quot;_arbiter&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;name&quot;:&quot;_freezePeriod&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_feePromille&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_rewardPromille&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_count&quot;,&quot;type&quot;:&quot;uint16&quot;},{&quot;name&quot;:&quot;_price&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;type&quot;:&quot;constructor&quot;},{&quot;payable&quot;:false,&quot;type&quot;:&quot;fallback&quot;},{&quot;anonymous&quot;:false,&quot;inputs&quot;:[{&quot;indexed&quot;:false,&quot;name&quot;:&quot;message&quot;,&quot;type&quot;:&quot;string&quot;}],&quot;name&quot;:&quot;LogDebug&quot;,&quot;type&quot;:&quot;event&quot;},{&quot;anonymous&quot;:false,&quot;inputs&quot;:[{&quot;indexed&quot;:true,&quot;name&quot;:&quot;lockId&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;dataInfo&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;indexed&quot;:true,&quot;name&quot;:&quot;version&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;eventType&quot;,&quot;type&quot;:&quot;uint16&quot;},{&quot;indexed&quot;:true,&quot;name&quot;:&quot;sender&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;count&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;payment&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;LogEvent&quot;,&quot;type&quot;:&quot;event&quot;}]
Optimized: yes
Solidity version: v0.4.4
*/

pragma solidity ^0.4.0;

contract EscrowGoods {

    struct EscrowInfo {

        address buyer;
        uint lockedFunds;
        uint frozenFunds;
        uint64 frozenTime;
        uint16 count;
        bool buyerNo;
        bool sellerNo;
    }

    //enum GoodsStatus
    uint16 constant internal None = 0;
    uint16 constant internal Available = 1;
    uint16 constant internal Canceled = 2;

    //enum EventTypes
    uint16 constant internal Buy = 1;
    uint16 constant internal Accept = 2;
    uint16 constant internal Reject = 3;
    uint16 constant internal Cancel = 4;
    uint16 constant internal Description = 10;
    uint16 constant internal Unlock = 11;
    uint16 constant internal Freeze = 12;
    uint16 constant internal Resolved = 13;

    //data

    uint constant arbitrationPeriod = 30 days;
    uint constant safeGas = 25000;

    //seller/owner of the goods
    address public seller;

    //event counters
    uint public contentCount = 0;
    uint public logsCount = 0;

    //escrow related

    address public arbiter;

    uint public freezePeriod;
    //each lock fee in promilles.
    uint public feePromille;
    //reward in promilles. promille = percent * 10, eg 1,5% reward = 15 rewardPromille
    uint public rewardPromille;

    uint public feeFunds;
    uint public totalEscrows;

    mapping (uint => EscrowInfo) public escrows;

    //goods related

    //status of the goods: see GoodsStatus enum
    uint16 public status;
    //how many for sale
    uint16 public count;

    uint16 public availableCount;
    uint16 public pendingCount;

    //price per item
    uint public price;

    mapping (address => bool) public buyers;

    bool private atomicLock;

    //events

    event LogDebug(string message);
    event LogEvent(uint indexed lockId, string dataInfo, uint indexed version, uint16 eventType, address indexed sender, uint count, uint payment);

    modifier onlyOwner {
        if (msg.sender != seller)
          throw;
        _;
    }

    modifier onlyArbiter {
        if (msg.sender != arbiter)
          throw;
        _;
    }

    //modules

    function EscrowGoods(address _arbiter, uint _freezePeriod, uint _feePromille, uint _rewardPromille,
                          uint16 _count, uint _price) {

        seller = msg.sender;

        // all variables are always initialized to 0, save gas

        //escrow related

        arbiter = _arbiter;
        freezePeriod = _freezePeriod;
        feePromille = _feePromille;
        rewardPromille = _rewardPromille;

        //goods related

        status = Available;
        count = _count;
        price = _price;

        availableCount = count;
    }

    //helpers for events with counter
    function logDebug(string message) internal {
        logsCount++;
        LogDebug(message);
    }

    function logEvent(uint lockId, string dataInfo, uint version, uint16 eventType,
                                address sender, uint count, uint payment) internal {
        contentCount++;
        LogEvent(lockId, dataInfo, version, eventType, sender, count, payment);
    }

    function kill() onlyOwner {

        //do not allow killing contract with active escrows
        if(totalEscrows > 0) {
            logDebug(&quot;totalEscrows > 0&quot;);
            return;
        }
        //do not allow killing contract with unclaimed escrow fees
        if(feeFunds > 0) {
            logDebug(&quot;feeFunds > 0&quot;);
            return;
        }
        suicide(msg.sender);
    }

    function safeSend(address addr, uint value) internal {

        if(atomicLock) throw;
        atomicLock = true;
        if (!(addr.call.gas(safeGas).value(value)())) {
            atomicLock = false;
            throw;
        }
        atomicLock = false;
    }

    //escrow API

    //vote YES - immediately sends funds to the peer
    function yes(uint _lockId, string _dataInfo, uint _version) {

        EscrowInfo info = escrows[_lockId];

        if(info.lockedFunds == 0) {
            logDebug(&quot;info.lockedFunds == 0&quot;);
            return;
        }
        if(msg.sender != info.buyer && msg.sender != seller) {
            logDebug(&quot;msg.sender != info.buyer && msg.sender != seller&quot;);
            return;
        }

        uint payment = info.lockedFunds;
        if(payment > this.balance) {
            //HACK: should not get here - funds cannot be unlocked in this case
            logDebug(&quot;payment > this.balance&quot;);
            return;
        }

        if(msg.sender == info.buyer) {

            //send funds to seller
            safeSend(seller, payment);
        } else if(msg.sender == seller) {

            //send funds to buyer
            safeSend(info.buyer, payment);
        } else {
            //HACK: should not get here
            logDebug(&quot;unknown msg.sender&quot;);
            return;
        }

        //remove record from escrows
        if(totalEscrows > 0) totalEscrows -= 1;
        info.lockedFunds = 0;

        logEvent(_lockId, _dataInfo, _version, Unlock, msg.sender, info.count, payment);
    }

    //vote NO - freeze funds for arbitration
    function no(uint _lockId, string _dataInfo, uint _version) {

        EscrowInfo info = escrows[_lockId];

        if(info.lockedFunds == 0) {
            logDebug(&quot;info.lockedFunds == 0&quot;);
            return;
        }
        if(msg.sender != info.buyer && msg.sender != seller) {
            logDebug(&quot;msg.sender != info.buyer && msg.sender != seller&quot;);
            return;
        }

        //freeze funds
        //only allow one time freeze
        if(info.frozenFunds == 0) {
            info.frozenFunds = info.lockedFunds;
            info.frozenTime = uint64(now);
        }

        if(msg.sender == info.buyer) {
            info.buyerNo = true;
        }
        else if(msg.sender == seller) {
            info.sellerNo = true;
        } else {
            //HACK: should not get here
            logDebug(&quot;unknown msg.sender&quot;);
            return;
        }

        logEvent(_lockId, _dataInfo, _version, Freeze, msg.sender, info.count, info.lockedFunds);
    }

    //arbiter&#39;s decision on the case.
    //arbiter can only decide when both buyer and seller voted NO
    //arbiter decides on his own reward but not bigger than announced percentage (rewardPromille)
    function arbYes(uint _lockId, address _who, uint _payment, string _dataInfo, uint _version) onlyArbiter {

        EscrowInfo info = escrows[_lockId];

        if(info.lockedFunds == 0) {
            logDebug(&quot;info.lockedFunds == 0&quot;);
            return;
        }
        if(info.frozenFunds == 0) {
            logDebug(&quot;info.frozenFunds == 0&quot;);
            return;
        }

        if(_who != seller && _who != info.buyer) {
            logDebug(&quot;_who != seller && _who != info.buyer&quot;);
            return;
        }
        //requires both NO to arbitration
        if(!info.buyerNo || !info.sellerNo) {
            logDebug(&quot;!info.buyerNo || !info.sellerNo&quot;);
            return;
        }

        if(_payment > info.lockedFunds) {
            logDebug(&quot;_payment > info.lockedFunds&quot;);
            return;
        }
        if(_payment > this.balance) {
            //HACK: should not get here - funds cannot be unlocked in this case
            logDebug(&quot;_payment > this.balance&quot;);
            return;
        }

        //limit payment
        uint reward = (info.lockedFunds * rewardPromille) / 1000;
        if(reward > (info.lockedFunds - _payment)) {
            logDebug(&quot;reward > (info.lockedFunds - _payment)&quot;);
            return;
        }

        //send funds to the winner
        safeSend(_who, _payment);

        //send the rest as reward
        info.lockedFunds -= _payment;
        feeFunds += info.lockedFunds;
        info.lockedFunds = 0;

        logEvent(_lockId, _dataInfo, _version, Resolved, msg.sender, info.count, _payment);
    }

    //allow arbiter to get his collected fees
    function getFees() onlyArbiter {

        if(feeFunds > this.balance) {
            //HACK: should not get here - funds cannot be unlocked in this case
            logDebug(&quot;feeFunds > this.balance&quot;);
            return;
        }
        
        safeSend(arbiter, feeFunds);

        feeFunds = 0;
    }

    //allow buyer or seller to take timeouted funds.
    //buyer can get funds if seller is silent and seller can get funds if buyer is silent (after freezePeriod)
    //buyer can get back funds under arbitration if arbiter is silent (after arbitrationPeriod)
    function getMoney(uint _lockId) {

        EscrowInfo info = escrows[_lockId];

        if(info.lockedFunds == 0) {
            logDebug(&quot;info.lockedFunds == 0&quot;);
            return;
        }
        //HACK: this check is necessary since frozenTime == 0 at escrow creation
        if(info.frozenFunds == 0) {
            logDebug(&quot;info.frozenFunds == 0&quot;);
            return;
        }

        //timout for voting not over yet
        if(now < (info.frozenTime + freezePeriod)) {
            logDebug(&quot;now < (info.frozenTime + freezePeriod)&quot;);
            return;
        }

        uint payment = info.lockedFunds;
        if(payment > this.balance) {
            //HACK: should not get here - funds cannot be unlocked in this case
            logDebug(&quot;payment > this.balance&quot;);
            return;
        }

        //both has voted - money is under arbitration
        if(info.buyerNo && info.sellerNo) {

            //arbitration timeout is not over yet
            if(now < (info.frozenTime + freezePeriod + arbitrationPeriod)) {
                logDebug(&quot;now < (info.frozenTime + freezePeriod + arbitrationPeriod)&quot;);
                return;
            }

            //arbiter was silent so redeem the funds to the buyer
            safeSend(info.buyer, payment);

            info.lockedFunds = 0;
            return;
        }

        if(info.buyerNo) {

            safeSend(info.buyer, payment);

            info.lockedFunds = 0;
            return;
        }
        if(info.sellerNo) {

            safeSend(seller, payment);

            info.lockedFunds = 0;
            return;
        }
    }

    //goods API

    //add new description to the goods
    function addDescription(string _dataInfo, uint _version) onlyOwner {

        //Accept order to event log
        logEvent(0, _dataInfo, _version, Description, msg.sender, 0, 0);
    }

    //buy with escrow. id - escrow info id
    function buy(uint _lockId, string _dataInfo, uint _version, uint16 _count) payable {

        //reject money transfers for bad item status

        if(status != Available) throw;
        if(msg.value < (price * _count)) throw;
        if(_count > availableCount) throw;
        if(_count == 0) throw;
        if(feePromille > 1000) throw;
        if(rewardPromille > 1000) throw;
        if((feePromille + rewardPromille) > 1000) throw;

        //create default EscrowInfo struct or access existing
        EscrowInfo info = escrows[_lockId];

        //lock only once for a given id
        if(info.lockedFunds > 0) throw;

        //lock funds

        uint fee = (msg.value * feePromille) / 1000;
        //limit fees
        if(fee > msg.value) throw;

        uint funds = (msg.value - fee);
        feeFunds += fee;
        totalEscrows += 1;

        info.buyer = msg.sender;
        info.lockedFunds = funds;
        info.frozenFunds = 0;
        info.buyerNo = false;
        info.sellerNo = false;
        info.count = _count;

        pendingCount += _count;
        buyers[msg.sender] = true;

        //Buy order to event log
        logEvent(_lockId, _dataInfo, _version, Buy, msg.sender, _count, msg.value);
    }

    function accept(uint _lockId, string _dataInfo, uint _version) onlyOwner {

        EscrowInfo info = escrows[_lockId];
        
        if(info.count > availableCount) {
            logDebug(&quot;info.count > availableCount&quot;);
            return;
        }
        if(info.count > pendingCount) {
            logDebug(&quot;info.count > pendingCount&quot;);
            return;
        }

        pendingCount -= info.count;
        availableCount -= info.count;

        //Accept order to event log
        logEvent(_lockId, _dataInfo, _version, Accept, msg.sender, info.count, info.lockedFunds);
    }

    function reject(uint _lockId, string _dataInfo, uint _version) onlyOwner {
        
        EscrowInfo info = escrows[_lockId];

        if(info.count > pendingCount) {
            logDebug(&quot;info.count > pendingCount&quot;);
            return;
        }

        pendingCount -= info.count;

        //send money back
        yes(_lockId, _dataInfo, _version);

        //Reject order to event log
        //HACK: &quot;yes&quot; call above may fail and this event will be non-relevant. Do not rely on it.
        logEvent(_lockId, _dataInfo, _version, Reject, msg.sender, info.count, info.lockedFunds);
    }

    function cancel(string _dataInfo, uint _version) onlyOwner {

        //Canceled status
        status = Canceled;

        //Cancel order to event log
        logEvent(0, _dataInfo, _version, Cancel, msg.sender, availableCount, 0);
    }

    //remove buyer from the watchlist
    function unbuy() {

        buyers[msg.sender] = false;
    }

    function () {
        throw;
    }
}