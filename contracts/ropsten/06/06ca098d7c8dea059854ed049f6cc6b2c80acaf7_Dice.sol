pragma solidity ^0.4.0;

// <ORACLIZE_API>
/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016 Oraclize LTD



Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:



The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.



THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

pragma solidity ^0.4.0;//please import oraclizeAPI_pre0.4.sol when solidity < 0.4.0

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) payable returns (bytes32 _id);
    function getPrice(string _datasource) returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) returns (uint _dsprice);
    function useCoupon(string _coupon);
    function setProofType(byte _proofType);
    function setConfig(bytes32 _config);
    function setCustomGasPrice(uint _gasPrice);
}
contract OraclizeAddrResolverI {
    function getAddress() returns (address _addr);
}
contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;
    
    OraclizeI oraclize;
    modifier oraclizeAPI {
        if(address(OAR)==0) oraclize_setNetwork(networkID_auto);
        oraclize = OraclizeI(OAR.getAddress());
        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        oraclize.useCoupon(code);
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
        if (getCodeSize(0x1d3b2638a7cc9f2cb3d298a3da7a90b67e5506ed)>0){ //mainnet
            OAR = OraclizeAddrResolverI(0x1d3b2638a7cc9f2cb3d298a3da7a90b67e5506ed);
            return true;
        }
        if (getCodeSize(0xc03a2615d5efaf5f49f60b7bb6583eaec212fdf1)>0){ //ropsten testnet
            OAR = OraclizeAddrResolverI(0xc03a2615d5efaf5f49f60b7bb6583eaec212fdf1);
            return true;
        }
        if (getCodeSize(0x51efaf4c8b3c9afbd5ab9f4bbc82784ab6ef8faa)>0){ //browser-solidity
            OAR = OraclizeAddrResolverI(0x51efaf4c8b3c9afbd5ab9f4bbc82784ab6ef8faa);
            return true;
        }
        return false;
    }
    
    function __callback(bytes32 myid, string result) {
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string result, bytes proof) {
    }
    
    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }
    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }
    
    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }    
    function oraclize_setConfig(bytes32 config) oraclizeAPI internal {
        return oraclize.setConfig(config);
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }


    function parseAddr(string _a) internal returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }


    function strCompare(string _a, string _b) internal returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
   } 

    function indexOf(string _haystack, string _needle) internal returns (int)
    {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
            return -1;
        else if(h.length > (2**128 -1))
            return -1;                                  
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }   
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }   
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    
    function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    // parseInt
    function parseInt(string _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }
    
    function uint2str(uint i) internal returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
    
    

}
// </ORACLIZE_API>

contract Dice is usingOraclize {

    uint constant pwin = 4000; //probability of winning (10000 = 100%)
    uint constant edge = 190; //edge percentage (10000 = 100%)
    uint constant maxWin = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
    uint constant minBet = 200 finney;
    uint constant maxInvestors = 10; //maximum number of investors
    uint constant houseEdge = 90; //edge percentage (10000 = 100%)
    uint constant divestFee = 50; //divest fee percentage (10000 = 100%)
    uint constant emergencyWithdrawalRatio = 10; //ratio percentage (100 = 100%)

    uint safeGas = 2300;
    uint constant ORACLIZE_GAS_LIMIT = 175000;
    uint constant INVALID_BET_MARKER = 99999;
    uint constant EMERGENCY_TIMEOUT = 3 days;

    struct Investor {
        address investorAddress;
        uint amountInvested;
        bool votedForEmergencyWithdrawal;
    }

    struct Bet {
        address playerAddress;
        uint amountBet;
        uint numberRolled;
    }

    struct WithdrawalProposal {
        address toAddress;
        uint atTime;
    }

    //Starting at 1
    mapping(address => uint) public investorIDs;
    mapping(uint => Investor) public investors;
    uint public numInvestors = 0;

    uint public invested = 0;

    address public owner;
    address public houseAddress;
    bool public isStopped;

    WithdrawalProposal public proposedWithdrawal;

    mapping (bytes32 => Bet) public bets;
    bytes32[] public betsKeys;

    uint public investorsProfit = 0;
    uint public investorsLosses = 0;
    bool profitDistributed;

    event LOG_NewBet(address playerAddress, uint amount);
    event LOG_BetWon(address playerAddress, uint numberRolled, uint amountWon);
    event LOG_BetLost(address playerAddress, uint numberRolled);
    event LOG_EmergencyWithdrawalProposed();
    event LOG_EmergencyWithdrawalFailed(address withdrawalAddress);
    event LOG_EmergencyWithdrawalSucceeded(address withdrawalAddress, uint amountWithdrawn);
    event LOG_FailedSend(address receiver, uint amount);
    event LOG_ZeroSend();
    event LOG_InvestorEntrance(address investor, uint amount);
    event LOG_InvestorCapitalUpdate(address investor, int amount);
    event LOG_InvestorExit(address investor, uint amount);
    event LOG_ContractStopped();
    event LOG_ContractResumed();
    event LOG_OwnerAddressChanged(address oldAddr, address newOwnerAddress);
    event LOG_HouseAddressChanged(address oldAddr, address newHouseAddress);
    event LOG_GasLimitChanged(uint oldGasLimit, uint newGasLimit);
    event LOG_EmergencyAutoStop();
    event LOG_EmergencyWithdrawalVote(address investor, bool vote);
    event LOG_ValueIsTooBig();
    event LOG_SuccessfulSend(address addr, uint amount);

    function Dice() {
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        owner = msg.sender;
        houseAddress = msg.sender;
    }

    //SECTION I: MODIFIERS AND HELPER FUNCTIONS

    //MODIFIERS

    modifier onlyIfNotStopped {
        if (isStopped) throw;
        _;
    }

    modifier onlyIfStopped {
        if (!isStopped) throw;
        _;
    }

    modifier onlyInvestors {
        if (investorIDs[msg.sender] == 0) throw;
        _;
    }

    modifier onlyNotInvestors {
        if (investorIDs[msg.sender] != 0) throw;
        _;
    }

    modifier onlyOwner {
        if (owner != msg.sender) throw;
        _;
    }

    modifier onlyOraclize {
        if (msg.sender != oraclize_cbAddress()) throw;
        _;
    }

    modifier onlyMoreThanMinInvestment {
        if (msg.value <= getMinInvestment()) throw;
        _;
    }

    modifier onlyMoreThanZero {
        if (msg.value == 0) throw;
        _;
    }

    modifier onlyIfBetExist(bytes32 myid) {
        if(bets[myid].playerAddress == address(0x0)) throw;
        _;
    }

    modifier onlyIfBetSizeIsStillCorrect(bytes32 myid) {
        if ((((bets[myid].amountBet * ((10000 - edge) - pwin)) / pwin ) <= (maxWin * getBankroll()) / 10000)  && (bets[myid].amountBet >= minBet)) {
             _;
        }
        else {
            bets[myid].numberRolled = INVALID_BET_MARKER;
            safeSend(bets[myid].playerAddress, bets[myid].amountBet);
            return;
        }
    }

    modifier onlyIfValidRoll(bytes32 myid, string result) {
        uint numberRolled = parseInt(result);
        if ((numberRolled < 1 || numberRolled > 10000) && bets[myid].numberRolled == 0) {
            bets[myid].numberRolled = INVALID_BET_MARKER;
            safeSend(bets[myid].playerAddress, bets[myid].amountBet);
            return;
        }
        _;
    }

    modifier onlyWinningBets(uint numberRolled) {
        if (numberRolled - 1 < pwin) {
            _;
        }
    }

    modifier onlyLosingBets(uint numberRolled) {
        if (numberRolled - 1 >= pwin) {
            _;
        }
    }

    modifier onlyAfterProposed {
        if (proposedWithdrawal.toAddress == 0) throw;
        _;
    }

    modifier onlyIfProfitNotDistributed {
        if (!profitDistributed) {
            _;
        }
    }

    modifier onlyIfValidGas(uint newGasLimit) {
        if (ORACLIZE_GAS_LIMIT + newGasLimit < ORACLIZE_GAS_LIMIT) throw;
        if (newGasLimit < 25000) throw;
        _;
    }

    modifier onlyIfNotProcessed(bytes32 myid) {
        if (bets[myid].numberRolled > 0) throw;
        _;
    }

    modifier onlyIfEmergencyTimeOutHasPassed {
        if (proposedWithdrawal.atTime + EMERGENCY_TIMEOUT > now) throw;
        _;
    }

    modifier investorsInvariant {
        _;
        if (numInvestors > maxInvestors) throw;
    }

    //CONSTANT HELPER FUNCTIONS

    function getBankroll()
        constant
        returns(uint) {

        if ((invested < investorsProfit) ||
            (invested + investorsProfit < invested) ||
            (invested + investorsProfit < investorsLosses)) {
            return 0;
        }
        else {
            return invested + investorsProfit - investorsLosses;
        }
    }

    function getMinInvestment()
        constant
        returns(uint) {

        if (numInvestors == maxInvestors) {
            uint investorID = searchSmallestInvestor();
            return getBalance(investors[investorID].investorAddress);
        }
        else {
            return 0;
        }
    }

    function getStatus()
        constant
        returns(uint, uint, uint, uint, uint, uint, uint, uint) {

        uint bankroll = getBankroll();
        uint minInvestment = getMinInvestment();
        return (bankroll, pwin, edge, maxWin, minBet, (investorsProfit - investorsLosses), minInvestment, betsKeys.length);
    }

    function getBet(uint id)
        constant
        returns(address, uint, uint) {

        if (id < betsKeys.length) {
            bytes32 betKey = betsKeys[id];
            return (bets[betKey].playerAddress, bets[betKey].amountBet, bets[betKey].numberRolled);
        }
    }

    function numBets()
        constant
        returns(uint) {

        return betsKeys.length;
    }

    function getMinBetAmount()
        constant
        returns(uint) {

        uint oraclizeFee = OraclizeI(OAR.getAddress()).getPrice("URL", ORACLIZE_GAS_LIMIT + safeGas);
        return oraclizeFee + minBet;
    }

    function getMaxBetAmount()
        constant
        returns(uint) {

        uint oraclizeFee = OraclizeI(OAR.getAddress()).getPrice("URL", ORACLIZE_GAS_LIMIT + safeGas);
        uint betValue =  (maxWin * getBankroll()) * pwin / (10000 * (10000 - edge - pwin));
        return betValue + oraclizeFee;
    }

    function getLossesShare(address currentInvestor)
        constant
        returns (uint) {

        return investors[investorIDs[currentInvestor]].amountInvested * (investorsLosses) / invested;
    }

    function getProfitShare(address currentInvestor)
        constant
        returns (uint) {

        return investors[investorIDs[currentInvestor]].amountInvested * (investorsProfit) / invested;
    }

    function getBalance(address currentInvestor)
        constant
        returns (uint) {

        uint invested = investors[investorIDs[currentInvestor]].amountInvested;
        uint profit = getProfitShare(currentInvestor);
        uint losses = getLossesShare(currentInvestor);

        if ((invested + profit < profit) ||
            (invested + profit < invested) ||
            (invested + profit < losses))
            return 0;
        else
            return invested + profit - losses;
    }

    function searchSmallestInvestor()
        constant
        returns(uint) {

        uint investorID = 1;
        for (uint i = 1; i <= numInvestors; i++) {
            if (getBalance(investors[i].investorAddress) < getBalance(investors[investorID].investorAddress)) {
                investorID = i;
            }
        }

        return investorID;
    }

    function changeOraclizeProofType(byte _proofType)
        onlyOwner {

        if (_proofType == 0x00) throw;
        oraclize_setProof( _proofType |  proofStorage_IPFS );
    }

    function changeOraclizeConfig(bytes32 _config)
        onlyOwner {

        oraclize_setConfig(_config);
    }

    // PRIVATE HELPERS FUNCTION

    function safeSend(address addr, uint value)
        private {

        if (value == 0) {
            LOG_ZeroSend();
            return;
        }

        if (this.balance < value) {
            LOG_ValueIsTooBig();
            return;
        }

        if (!(addr.call.gas(safeGas).value(value)())) {
            LOG_FailedSend(addr, value);
            if (addr != houseAddress) {
                //Forward to house address all change
                if (!(houseAddress.call.gas(safeGas).value(value)())) LOG_FailedSend(houseAddress, value);
            }
        }

        LOG_SuccessfulSend(addr,value);
    }

    function addInvestorAtID(uint id)
        private {

        investorIDs[msg.sender] = id;
        investors[id].investorAddress = msg.sender;
        investors[id].amountInvested = msg.value;
        invested += msg.value;

        LOG_InvestorEntrance(msg.sender, msg.value);
    }

    function profitDistribution()
        private
        onlyIfProfitNotDistributed {

        uint copyInvested;

        for (uint i = 1; i <= numInvestors; i++) {
            address currentInvestor = investors[i].investorAddress;
            uint profitOfInvestor = getProfitShare(currentInvestor);
            uint lossesOfInvestor = getLossesShare(currentInvestor);
            //Check for overflow and underflow
            if ((investors[i].amountInvested + profitOfInvestor >= investors[i].amountInvested) &&
                (investors[i].amountInvested + profitOfInvestor >= lossesOfInvestor))  {
                investors[i].amountInvested += profitOfInvestor - lossesOfInvestor;
                LOG_InvestorCapitalUpdate(currentInvestor, (int) (profitOfInvestor - lossesOfInvestor));
            }
            else {
                isStopped = true;
                LOG_EmergencyAutoStop();
            }

            if (copyInvested + investors[i].amountInvested >= copyInvested)
                copyInvested += investors[i].amountInvested;
        }

        delete investorsProfit;
        delete investorsLosses;
        invested = copyInvested;

        profitDistributed = true;
    }

    // SECTION II: BET & BET PROCESSING

    function()
        payable {

        bet();
    }

    function bet()
        payable
        onlyIfNotStopped {

        uint oraclizeFee = OraclizeI(OAR.getAddress()).getPrice("URL", ORACLIZE_GAS_LIMIT + safeGas);
        if (oraclizeFee >= msg.value) throw;
        uint betValue = msg.value - oraclizeFee;
        if ((((betValue * ((10000 - edge) - pwin)) / pwin ) <= (maxWin * getBankroll()) / 10000) && (betValue >= minBet)) {
            LOG_NewBet(msg.sender, betValue);
            bytes32 myid =
                oraclize_query(
                    "nested",
                    "[URL] [&#39;json(https://api.random.org/json-rpc/1/invoke).result.random.data.0&#39;, &#39;\\n{\"jsonrpc\":\"2.0\",\"method\":\"generateSignedIntegers\",\"params\":{\"apiKey\":${[decrypt]  BIEYyi6vbXiYKe2uO2HEDb8A5kAr6stdHSHXFhx7lWSQw1sQJrjQ/hsPEJc2JSzk25cBg5LMG+BwDaRgelBgqU0dRbQ8T6nnBAv56az9GeM4QHhMN0l0lRxydjcMIkphI0GBDkZiUgCE8gtU0QnWQvTbxa7L6JgHUT2HXsMeyCzFE1//3fXNJxIcz8e14S6HOTA+xvug2poc6LSm0Y4jsf/nf9d/CAQI6YZry56EHFlQCoAKtLZ0VWePFgiXmusYPQ0J1SpogbK0y7gfNoz6m8WsTJBvap6iYIVT4Q1SRNKTXsXtder5DNxecpbpJKsHRdgefKi8QYO+gozg3HAflEg9ed5FwQOmJ4/mrDsfNaYELH2whi1Blqhccx6ROtv0MdtR5C20iasrJ47Kg/7ObUzi8sLMBxv3Jc6YAVXGthUsmuKzChWGHyzTmHYxxN+cPLPImjCIUQ9Qm+E3o/NLGHUaM1A=},\"n\":1,\"min\":1,\"max\":10000${[identity] \"}\"},\"id\":1${[identity] \"}\"}&#39;]",
                    ORACLIZE_GAS_LIMIT + safeGas
                );
            bets[myid] = Bet(msg.sender, betValue, 0);
            betsKeys.push(myid);
        }
        else {
            throw;
        }
    }

    function __callback(bytes32 myid, string result, bytes proof)
        onlyOraclize
        onlyIfBetExist(myid)
        onlyIfNotProcessed(myid)
        onlyIfValidRoll(myid, result)
        onlyIfBetSizeIsStillCorrect(myid)  {

        uint numberRolled = parseInt(result);
        bets[myid].numberRolled = numberRolled;
        isWinningBet(bets[myid], numberRolled);
        isLosingBet(bets[myid], numberRolled);
        delete profitDistributed;
    }

    function isWinningBet(Bet thisBet, uint numberRolled)
        private
        onlyWinningBets(numberRolled) {

        uint winAmount = (thisBet.amountBet * (10000 - edge)) / pwin;
        LOG_BetWon(thisBet.playerAddress, numberRolled, winAmount);
        safeSend(thisBet.playerAddress, winAmount);

        //Check for overflow and underflow
        if ((investorsLosses + winAmount < investorsLosses) ||
            (investorsLosses + winAmount < thisBet.amountBet)) {
                throw;
            }

        investorsLosses += winAmount - thisBet.amountBet;
    }

    function isLosingBet(Bet thisBet, uint numberRolled)
        private
        onlyLosingBets(numberRolled) {

        LOG_BetLost(thisBet.playerAddress, numberRolled);
        safeSend(thisBet.playerAddress, 1);

        //Check for overflow and underflow
        if ((investorsProfit + thisBet.amountBet < investorsProfit) ||
            (investorsProfit + thisBet.amountBet < thisBet.amountBet) ||
            (thisBet.amountBet == 1)) {
                throw;
            }

        uint totalProfit = investorsProfit + (thisBet.amountBet - 1); //added based on audit feedback
        investorsProfit += (thisBet.amountBet - 1)*(10000 - houseEdge)/10000;
        uint houseProfit = totalProfit - investorsProfit; //changed based on audit feedback
        safeSend(houseAddress, houseProfit);
    }

    //SECTION III: INVEST & DIVEST

    function increaseInvestment()
        payable
        onlyIfNotStopped
        onlyMoreThanZero
        onlyInvestors  {

        profitDistribution();
        investors[investorIDs[msg.sender]].amountInvested += msg.value;
        invested += msg.value;
    }

    function newInvestor()
        payable
        onlyIfNotStopped
        onlyMoreThanZero
        onlyNotInvestors
        onlyMoreThanMinInvestment
        investorsInvariant {

        profitDistribution();

        if (numInvestors == maxInvestors) {
            uint smallestInvestorID = searchSmallestInvestor();
            divest(investors[smallestInvestorID].investorAddress);
        }

        numInvestors++;
        addInvestorAtID(numInvestors);
    }

    function divest()
        onlyInvestors {

        divest(msg.sender);
    }


    function divest(address currentInvestor)
        private
        investorsInvariant {

        profitDistribution();
        uint currentID = investorIDs[currentInvestor];
        uint amountToReturn = getBalance(currentInvestor);

        if ((invested >= investors[currentID].amountInvested)) {
            invested -= investors[currentID].amountInvested;
            uint divestFeeAmount =  (amountToReturn*divestFee)/10000;
            amountToReturn -= divestFeeAmount;

            delete investors[currentID];
            delete investorIDs[currentInvestor];

            //Reorder investors
            if (currentID != numInvestors) {
                // Get last investor
                Investor lastInvestor = investors[numInvestors];
                //Set last investor ID to investorID of divesting account
                investorIDs[lastInvestor.investorAddress] = currentID;
                //Copy investor at the new position in the mapping
                investors[currentID] = lastInvestor;
                //Delete old position in the mappping
                delete investors[numInvestors];
            }

            numInvestors--;
            safeSend(currentInvestor, amountToReturn);
            safeSend(houseAddress, divestFeeAmount);
            LOG_InvestorExit(currentInvestor, amountToReturn);
        } else {
            isStopped = true;
            LOG_EmergencyAutoStop();
        }
    }

    function forceDivestOfAllInvestors()
        onlyOwner {

        uint copyNumInvestors = numInvestors;
        for (uint i = 1; i <= copyNumInvestors; i++) {
            divest(investors[1].investorAddress);
        }
    }

    /*
    The owner can use this function to force the exit of an investor from the
    contract during an emergency withdrawal in the following situations:
        - Unresponsive investor
        - Investor demanding to be paid in other to vote, the facto-blackmailing
        other investors
    */
    function forceDivestOfOneInvestor(address currentInvestor)
        onlyOwner
        onlyIfStopped {

        divest(currentInvestor);
        //Resets emergency withdrawal proposal. Investors must vote again
        delete proposedWithdrawal;
    }

    //SECTION IV: CONTRACT MANAGEMENT

    function stopContract()
        onlyOwner {

        isStopped = true;
        LOG_ContractStopped();
    }

    function resumeContract()
        onlyOwner {

        isStopped = false;
        LOG_ContractResumed();
    }

    function changeHouseAddress(address newHouse)
        onlyOwner {

        if (newHouse == address(0x0)) throw; //changed based on audit feedback
        houseAddress = newHouse;
        LOG_HouseAddressChanged(houseAddress, newHouse);
    }

    function changeOwnerAddress(address newOwner)
        onlyOwner {

        if (newOwner == address(0x0)) throw;
        owner = newOwner;
        LOG_OwnerAddressChanged(owner, newOwner);
    }

    function changeGasLimitOfSafeSend(uint newGasLimit)
        onlyOwner
        onlyIfValidGas(newGasLimit) {

        safeGas = newGasLimit;
        LOG_GasLimitChanged(safeGas, newGasLimit);
    }

    //SECTION V: EMERGENCY WITHDRAWAL

    function voteEmergencyWithdrawal(bool vote)
        onlyInvestors
        onlyAfterProposed
        onlyIfStopped {

        investors[investorIDs[msg.sender]].votedForEmergencyWithdrawal = vote;
        LOG_EmergencyWithdrawalVote(msg.sender, vote);
    }

    function proposeEmergencyWithdrawal(address withdrawalAddress)
        onlyIfStopped
        onlyOwner {

        //Resets previous votes
        for (uint i = 1; i <= numInvestors; i++) {
            delete investors[i].votedForEmergencyWithdrawal;
        }

        proposedWithdrawal = WithdrawalProposal(withdrawalAddress, now);
        LOG_EmergencyWithdrawalProposed();
    }

    function executeEmergencyWithdrawal()
        onlyOwner
        onlyAfterProposed
        onlyIfStopped
        onlyIfEmergencyTimeOutHasPassed {

        uint numOfVotesInFavour;
        uint amountToWithdraw = this.balance;

        for (uint i = 1; i <= numInvestors; i++) {
            if (investors[i].votedForEmergencyWithdrawal == true) {
                numOfVotesInFavour++;
                delete investors[i].votedForEmergencyWithdrawal;
            }
        }

        if (numOfVotesInFavour >= emergencyWithdrawalRatio * numInvestors / 100) {
            if (!proposedWithdrawal.toAddress.send(amountToWithdraw)) {
                LOG_EmergencyWithdrawalFailed(proposedWithdrawal.toAddress);
            }
            else {
                LOG_EmergencyWithdrawalSucceeded(proposedWithdrawal.toAddress, amountToWithdraw);
            }
        }
        else {
            throw;
        }
    }

}