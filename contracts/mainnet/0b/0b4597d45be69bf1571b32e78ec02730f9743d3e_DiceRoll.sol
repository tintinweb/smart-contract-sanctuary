pragma solidity ^0.4.16;

// Use the dAppBridge service to generate random numbers
// Powerful Data Oracle Service with easy to use methods, see: https://dAppBridge.com
//
interface dAppBridge_I {
    function getOwner() external returns(address);
    function getMinReward(string requestType) external returns(uint256);
    function getMinGas() external returns(uint256);    
    // Only import the functions we use...
    function callURL(string callback_method, string external_url, string external_params, string json_extract_element) external payable returns(bytes32);
}
contract DappBridgeLocator_I {
    function currentLocation() public returns(address);
}

contract clientOfdAppBridge {
    address internal _dAppBridgeLocator_Prod_addr = 0x5b63e582645227F1773bcFaE790Ea603dB948c6A;
    
    DappBridgeLocator_I internal dAppBridgeLocator;
    dAppBridge_I internal dAppBridge; 
    uint256 internal current_gas = 0;
    uint256 internal user_callback_gas = 0;
    
    function initBridge() internal {
        //} != _dAppBridgeLocator_addr){
        if(address(dAppBridgeLocator) != _dAppBridgeLocator_Prod_addr){ 
            dAppBridgeLocator = DappBridgeLocator_I(_dAppBridgeLocator_Prod_addr);
        }
        
        if(address(dAppBridge) != dAppBridgeLocator.currentLocation()){
            dAppBridge = dAppBridge_I(dAppBridgeLocator.currentLocation());
        }
        if(current_gas == 0) {
            current_gas = dAppBridge.getMinGas();
        }
    }

    modifier dAppBridgeClient {
        initBridge();

        _;
    }
    

    event event_senderAddress(
        address senderAddress
    );
    
    event evnt_dAdppBridge_location(
        address theLocation
    );
    
    event only_dAppBridgeCheck(
        address senderAddress,
        address checkAddress
    );
    
    modifier only_dAppBridge_ {
        initBridge();
        
        //emit event_senderAddress(msg.sender);
        //emit evnt_dAdppBridge_location(address(dAppBridge));
        emit only_dAppBridgeCheck(msg.sender, address(dAppBridge));
        require(msg.sender == address(dAppBridge));
        _;
    }

    // Ensures that only the dAppBridge system can call the function
    modifier only_dAppBridge {
        initBridge();
        address _dAppBridgeOwner = dAppBridge.getOwner();
        require(msg.sender == _dAppBridgeOwner);

        _;
    }
    

    
    function setGas(uint256 new_gas) internal {
        require(new_gas > 0);
        current_gas = new_gas;
    }

    function setCallbackGas(uint256 new_callback_gas) internal {
        require(new_callback_gas > 0);
        user_callback_gas = new_callback_gas;
    }

    

    function callURL(string callback_method, string external_url, string external_params) internal dAppBridgeClient returns(bytes32) {
        uint256 _reward = dAppBridge.getMinReward(&#39;callURL&#39;)+user_callback_gas;
        return dAppBridge.callURL.value(_reward).gas(current_gas)(callback_method, external_url, external_params, "");
    }
    function callURL(string callback_method, string external_url, string external_params, string json_extract_elemen) internal dAppBridgeClient returns(bytes32) {
        uint256 _reward = dAppBridge.getMinReward(&#39;callURL&#39;)+user_callback_gas;
        return dAppBridge.callURL.value(_reward).gas(current_gas)(callback_method, external_url, external_params, json_extract_elemen);
    }


    // Helper internal functions
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function char(byte b) internal pure returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
    
    function bytes32string(bytes32 b32) internal pure returns (string out) {
        bytes memory s = new bytes(64);
        for (uint8 i = 0; i < 32; i++) {
            byte b = byte(b32[i]);
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[i*2] = char(hi);
            s[i*2+1] = char(lo);            
        }
        out = string(s);
    }

    function compareStrings (string a, string b) internal pure returns (bool){
        return keccak256(a) == keccak256(b);
    }
    
    function concatStrings(string _a, string _b) internal pure returns (string){
        bytes memory bytes_a = bytes(_a);
        bytes memory bytes_b = bytes(_b);
        string memory length_ab = new string(bytes_a.length + bytes_b.length);
        bytes memory bytes_c = bytes(length_ab);
        uint k = 0;
        for (uint i = 0; i < bytes_a.length; i++) bytes_c[k++] = bytes_a[i];
        for (i = 0; i < bytes_b.length; i++) bytes_c[k++] = bytes_b[i];
        return string(bytes_c);
    }
}

// SafeMath to protect overflows
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

//
//
// Main DiceRoll.app contract
//
//

contract DiceRoll is clientOfdAppBridge {
    
    using SafeMath for uint256;

    
    string public randomAPI_url;
    string internal randomAPI_key;
    string internal randomAPI_extract;
    
    struct playerDiceRoll {
        bytes32     betID;
        address     playerAddr;
        uint256     rollUnder;
        uint256     stake;
        uint256     profit;
        uint256     win;
        bool        paid;
        uint256     result;
        uint256     timestamp;
    }
    

    mapping (bytes32 => playerDiceRoll) public playerRolls;
    mapping (address => uint256) playerPendingWithdrawals;

    address public owner;
    uint256 public contractBalance;
    bool public game_paused;
    uint256 minRoll;
    uint256 maxRoll;
    uint256 minBet;
    uint256 maxBet;
    uint256 public minRollUnder;
    uint256 public houseEdge; // 98 = 2%
    uint256 public totalUserProfit;
    uint256 public totalWins; 
    uint256 public totalLosses;
    uint256 public totalWinAmount;
    uint256 public totalLossAmount;
    uint256 public totalFails;
    uint256 internal totalProfit;
    uint256 public maxMultiRolls;
    uint256 public gameNumber;
    
    uint256 public oracleFee;
    
    
    mapping(uint256 => bool) public permittedRolls;
    
    uint public maxPendingPayouts; // Max potential payments

    function private_getGameState() public view returns(uint256 _contractBalance,
        bool _game_paused,
        uint256 _minRoll,
        uint256 _maxRoll,
        uint256 _minBet,
        uint256 _maxBet,
        uint256 _houseEdge,
        uint256 _totalUserProfit,
        uint256 _totalWins,
        uint256 _totalLosses,
        uint256 _totalWinAmount,
        uint256 _totalLossAmount,
        uint256 _liveMaxBet,
        uint256 _totalFails) {
        _contractBalance = contractBalance;
        _game_paused = game_paused;
        _minRoll = minRoll;
        _maxRoll = maxRoll;
        _minBet = minBet;
        _maxBet = maxBet;
        _houseEdge = houseEdge;
        _totalUserProfit = totalUserProfit;
        _totalWins = totalWins;
        _totalLosses = totalLosses;
        _totalWinAmount = totalWinAmount;
        _totalLossAmount = totalLossAmount;
        _liveMaxBet = getLiveMaxBet();
        _totalFails = totalFails;
    
    }
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    modifier gameActive() {
        require (game_paused == false);
        _;
    }
    modifier validBet(uint256 betSize, uint256 rollUnder) {
        require(rollUnder > minRoll);
        require(rollUnder < maxRoll);
        require(betSize <= maxBet);
        require(betSize >= minBet);
        require(permittedRolls[rollUnder] == true);
        
        uint256 potential_profit = (msg.value * (houseEdge / rollUnder)) - msg.value;
        require(maxPendingPayouts.add(potential_profit) <= address(this).balance);
        
        _;
    }
    
    modifier validBetMulti(uint256 betSize, uint256 rollUnder, uint256 number_of_rolls) {
        require(rollUnder > minRoll);
        require(rollUnder < maxRoll);
        require(betSize <= maxBet);
        require(betSize >= minBet);
        require(number_of_rolls <= maxMultiRolls);
        require(permittedRolls[rollUnder] == true);
        
        uint256 potential_profit = (msg.value * (houseEdge / rollUnder)) - msg.value;
        require(maxPendingPayouts.add(potential_profit) <= address(this).balance);
        
        _;
    }



    function getLiveMaxBet() public view returns(uint256) {
        uint256 currentAvailBankRoll = address(this).balance.sub(maxPendingPayouts);
        uint256 divisor = houseEdge.div(minRollUnder); // will be 4
        uint256 liveMaxBet = currentAvailBankRoll.div(divisor); // 0.627852
        if(liveMaxBet > maxBet)
            liveMaxBet = maxBet;
        return liveMaxBet;
    }

    function getBet(bytes32 _betID) public view returns(bytes32 betID,
        address     playerAddr,
        uint256     rollUnder,
        uint256     stake,
        uint256     profit,
        uint256     win,
        bool        paid,
        uint256     result,
        uint256     timestamp){
        playerDiceRoll memory _playerDiceRoll = playerRolls[_betID];
        betID = _betID;
        playerAddr = _playerDiceRoll.playerAddr;
        rollUnder = _playerDiceRoll.rollUnder;
        stake = _playerDiceRoll.stake;
        profit = _playerDiceRoll.profit;
        win = _playerDiceRoll.win;
        paid = _playerDiceRoll.paid;
        result = _playerDiceRoll.result;
        timestamp = _playerDiceRoll.timestamp;
        
    }

    function getOwner() external view returns(address){
        return owner;
    }

    function getBalance() external view returns(uint256){
        address myAddress = this;
        return myAddress.balance;
    }
    
    constructor() public payable {
        owner = msg.sender;
        houseEdge = 96; // 4% commission to us on wins
        contractBalance = msg.value;
        totalUserProfit = 0;
        totalWins = 0;
        totalLosses = 0;
        minRoll = 1;
        maxRoll = 100;
        minBet = 15000000000000000; //200000000000000;
        maxBet = 300000000000000000; //200000000000000000;
        randomAPI_url = "https://api.random.org/json-rpc/1/invoke";
        randomAPI_key = "7d4ab655-e778-4d9f-815a-98fd518908bd";
        randomAPI_extract = "result.random.data";
        //permittedRolls[10] = true;
        permittedRolls[20] = true;
        permittedRolls[30] = true;
        permittedRolls[40] = true;
        permittedRolls[50] = true;
        permittedRolls[60] = true;
        //permittedRolls[70] = true;
        minRollUnder = 20;
        totalProfit = 0;
        totalWinAmount = 0;
        totalLossAmount = 0;
        totalFails = 0;
        maxMultiRolls = 5;
        gameNumber = 0;
        oracleFee = 80000000000000; 
    }
    
    event DiceRollResult_failedSend(
            bytes32 indexed betID,
            address indexed playerAddress,
            uint256 rollUnder,
            uint256 result,
            uint256 amountToSend
        );
        

    // totalUserProfit : Includes the original stake
    // totalWinAmount : Is just the win amount (Does not include orig stake)
    event DiceRollResult(
            bytes32 indexed betID, 
            address indexed playerAddress, 
            uint256 rollUnder, 
            uint256 result,
            uint256 stake,
            uint256 profit,
            uint256 win,
            bool paid,
            uint256 timestamp);
    
    // This is called from dAppBridge.com with the random number with secure proof
    function callback(bytes32 key, string callbackData) external payable only_dAppBridge {
        require(playerRolls[key].playerAddr != address(0x0));
        require(playerRolls[key].win == 2); // we&#39;ve already process it if so!

        playerRolls[key].result = parseInt(callbackData);
        
        uint256 _totalWin = playerRolls[key].stake.add(playerRolls[key].profit); // total we send back to playerRolls
        
        
        if(maxPendingPayouts < playerRolls[key].profit){
            //force refund as game failed...
            playerRolls[key].result == 0;
            
        } else {
            maxPendingPayouts = maxPendingPayouts.sub(playerRolls[key].profit); // take it out of the pending payouts now
        }
        
        
        
        if(playerRolls[key].result == 0){

            totalFails = totalFails.add(1);


            if(!playerRolls[key].playerAddr.send(playerRolls[key].stake)){
                //playerRolls[key].paid = false;
                
                
                
                emit DiceRollResult(key, playerRolls[key].playerAddr, playerRolls[key].rollUnder, playerRolls[key].result,
                    playerRolls[key].stake, 0, 0, false, now);
                
                emit DiceRollResult_failedSend(
                    key, playerRolls[key].playerAddr, playerRolls[key].rollUnder, playerRolls[key].result, playerRolls[key].stake );
                    
               playerPendingWithdrawals[playerRolls[key].playerAddr] = playerPendingWithdrawals[playerRolls[key].playerAddr].add(playerRolls[key].stake);
               
               delete playerRolls[key];
            } else {
                
                emit DiceRollResult(key, playerRolls[key].playerAddr, playerRolls[key].rollUnder, playerRolls[key].result,
                    playerRolls[key].stake, 0, 0, true, now);
                
                delete playerRolls[key];
            }

            return;
            
        } else {
        
            if(playerRolls[key].result < playerRolls[key].rollUnder) {

                contractBalance = contractBalance.sub(playerRolls[key].profit.add(oracleFee)); // how much we have won/lost
                totalUserProfit = totalUserProfit.add(_totalWin); // game stats
                totalWins = totalWins.add(1);
                totalWinAmount = totalWinAmount.add(playerRolls[key].profit);
                

        
                uint256 _player_profit_1percent = playerRolls[key].profit.div(houseEdge);
                uint256 _our_cut = _player_profit_1percent.mul(100-houseEdge); // we get 4%
                totalProfit = totalProfit.add(_our_cut); // Only add when its a win!

                if(!playerRolls[key].playerAddr.send(_totalWin)){
                    // failed to send - need to retry so add to playerPendingWithdrawals
                    
                    emit DiceRollResult(key, playerRolls[key].playerAddr, playerRolls[key].rollUnder, playerRolls[key].result,
                        playerRolls[key].stake, playerRolls[key].profit, 1, false, now);
                    
                    emit DiceRollResult_failedSend(
                        key, playerRolls[key].playerAddr, playerRolls[key].rollUnder, playerRolls[key].result, _totalWin );
    
                    playerPendingWithdrawals[playerRolls[key].playerAddr] = playerPendingWithdrawals[playerRolls[key].playerAddr].add(_totalWin);
                    
                    delete playerRolls[key];
                    
                } else {
                    
                    emit DiceRollResult(key, playerRolls[key].playerAddr, playerRolls[key].rollUnder, playerRolls[key].result,
                        playerRolls[key].stake, playerRolls[key].profit, 1, true, now);
                        
                    delete playerRolls[key];
                        
                }
                
                return;
                
            } else {
                //playerRolls[key].win=0;
                totalLosses = totalLosses.add(1);
                totalLossAmount = totalLossAmount.add(playerRolls[key].stake);
                contractBalance = contractBalance.add(playerRolls[key].stake.sub(oracleFee)); // how much we have won
                
                emit DiceRollResult(key, playerRolls[key].playerAddr, playerRolls[key].rollUnder, playerRolls[key].result,
                    playerRolls[key].stake, playerRolls[key].profit, 0, true, now);
                delete playerRolls[key];

    
                return;
            }
        }

        

    }
    
    
    function rollDice(uint rollUnder) public payable gameActive validBet(msg.value, rollUnder) returns (bytes32) {

        // This is the actual call to dAppBridge - using their callURL function to easily access an external API
        // such as random.org        
        bytes32 betID = callURL("callback", randomAPI_url, 
        constructAPIParam(), 
        randomAPI_extract);

        gameNumber = gameNumber.add(1);

        
        uint256 _fullTotal = (msg.value * getBetDivisor(rollUnder)   ); // 0.0002 * 250 = 0.0005
        _fullTotal = _fullTotal.div(100);
        _fullTotal = _fullTotal.sub(msg.value);
        
        uint256 _fullTotal_1percent = _fullTotal.div(100); // e.g = 1
        
        uint256 _player_profit = _fullTotal_1percent.mul(houseEdge); // player gets 96%
        
        
        playerRolls[betID] = playerDiceRoll(betID, msg.sender, rollUnder, msg.value, _player_profit, 2, false, 0, now);

        maxPendingPayouts = maxPendingPayouts.add(_player_profit); // don&#39;t add it to contractBalance yet until its a loss

        emit DiceRollResult(betID, msg.sender, rollUnder, 0,
            msg.value, _player_profit, 2, false, now);
            
        return betID;
    }
    
    function rollDice(uint rollUnder, uint number_of_rolls) public payable gameActive validBetMulti(msg.value, rollUnder, number_of_rolls) returns (bytes32) {

        uint c = 0;
        for(c; c< number_of_rolls; c++) {
            rollDice(rollUnder);
        }

    }
    
    function getBetDivisor(uint256 rollUnder) public pure returns (uint256) {
        if(rollUnder==5)
            return 20 * 100;
        if(rollUnder==10)
            return 10 * 100;
        if(rollUnder==20)
            return 5 * 100;
        if(rollUnder==30)
            return 3.3 * 100;
        if(rollUnder==40)
            return 2.5 * 100;
        if(rollUnder==50)
            return 2 * 100;
        if(rollUnder==60)
            return 1.66 * 100;
        if(rollUnder==70)
            return 1.42 * 100;
        if(rollUnder==80)
            return 1.25 * 100;
        if(rollUnder==90)
            return 1.11 * 100;
        
        return (100/rollUnder) * 10;
    }
    
    function constructAPIParam() internal view returns(string){
        return strConcat(
            strConcat("{\"jsonrpc\":\"2.0\",\"method\":\"generateIntegers\",\"params\":{\"apiKey\":\"",
        randomAPI_key, "\",\"n\":1,\"min\":", uint2str(minRoll), ",\"max\":", uint2str(maxRoll), ",\"replacement\":true,\"base\":10},\"id\":"),
        uint2str(gameNumber), "}" 
        ); // Add in gameNumber to the params to avoid clashes
    }
    
    // need to process any playerPendingWithdrawals
    
    // Allow a user to withdraw any pending amount (That may of failed previously)
    function player_withdrawPendingTransactions() public
        returns (bool)
     {
        uint withdrawAmount = playerPendingWithdrawals[msg.sender];
        playerPendingWithdrawals[msg.sender] = 0;

        if (msg.sender.call.value(withdrawAmount)()) {
            return true;
        } else {
            /* if send failed revert playerPendingWithdrawals[msg.sender] = 0; */
            /* player can try to withdraw again later */
            playerPendingWithdrawals[msg.sender] = withdrawAmount;
            return false;
        }
    }

    // shows if a player has any pending withdrawels due (returns the amount)
    function player_getPendingTxByAddress(address addressToCheck) public constant returns (uint256) {
        return playerPendingWithdrawals[addressToCheck];
    }

    
    // need to auto calc max bet
    

    // private functions
    function private_addPermittedRoll(uint256 _rollUnder) public onlyOwner {
        permittedRolls[_rollUnder] = true;
    }
    function private_delPermittedRoll(uint256 _rollUnder) public onlyOwner {
        delete permittedRolls[_rollUnder];
    }
    function private_setRandomAPIURL(string newRandomAPI_url) public onlyOwner {
        randomAPI_url = newRandomAPI_url;
    }
    function private_setRandomAPIKey(string newRandomAPI_key) public onlyOwner {
        randomAPI_key = newRandomAPI_key;
    }
    function private_setRandomAPI_extract(string newRandomAPI_extract) public onlyOwner {
        randomAPI_extract = newRandomAPI_extract;
    }
    function private_setminRoll(uint256 newMinRoll) public onlyOwner {
        require(newMinRoll>0);
        require(newMinRoll<maxRoll);
        minRoll = newMinRoll;
    }
    function private_setmaxRoll(uint256 newMaxRoll) public onlyOwner {
        require(newMaxRoll>0);
        require(newMaxRoll>minRoll);
        maxRoll = newMaxRoll;
    }
    function private_setminBet(uint256 newMinBet) public onlyOwner {
        require(newMinBet > 0);
        require(newMinBet < maxBet);
        minBet = newMinBet;
    }
    function private_setmaxBet(uint256 newMaxBet) public onlyOwner {
        require(newMaxBet > 0);
        require(newMaxBet > minBet);
        maxBet = newMaxBet;
    }
    function private_setPauseState(bool newState) public onlyOwner {
        game_paused = newState;
    }
    function private_setHouseEdge(uint256 newHouseEdge) public onlyOwner {
        houseEdge = newHouseEdge;
    }
    function private_kill() public onlyOwner {
        selfdestruct(owner);
    }
    function private_withdrawAll(address send_to) external onlyOwner returns(bool) {
        address myAddress = this;
        return send_to.send(myAddress.balance);
    }
    function private_withdraw(uint256 amount, address send_to) external onlyOwner returns(bool) {
        address myAddress = this;
        require(amount <= myAddress.balance);
        require(amount >0);
        return send_to.send(amount);
    }
    // show how much profit has been made (houseEdge)
    function private_profits() public view onlyOwner returns(uint256) {
        return totalProfit;
    }
    function private_setMinRollUnder(uint256 _minRollUnder) public onlyOwner {
        minRollUnder = _minRollUnder;
    }
    function private_setMaxMultiRolls(uint256 _maxMultiRolls) public onlyOwner {
        maxMultiRolls = _maxMultiRolls;
    }
    function private_setOracleFee(uint256 _oracleFee) public onlyOwner {
        oracleFee = _oracleFee;
    }
    function deposit() public payable onlyOwner {
        contractBalance = contractBalance.add(msg.value);
    }
    // end private functions


    // Internal functions
    function parseInt(string _a) internal pure returns (uint256) {
        return parseInt(_a, 0);
    }
    function parseInt(string _a, uint _b) internal pure returns (uint256) {
        bytes memory bresult = bytes(_a);
        uint256 mint = 0;
        bool decimals = false;
        for (uint256 i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                    if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint256(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }
    
    function strConcat(string _a, string _b, string _c, string _d, string _e, string _f, string _g) internal pure returns (string) {
        string memory abcdef = strConcat(_a,_b,_c,_d,_e,_f);
        return strConcat(abcdef, _g);
    }
    function strConcat(string _a, string _b, string _c, string _d, string _e, string _f) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);

        string memory abc = new string(_ba.length + _bb.length + _bc.length);
        bytes memory babc = bytes(abc);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babc[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babc[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babc[k++] = _bc[i];

        return strConcat(string(babc), strConcat(_d, _e, _f));
    }
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
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
    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }
    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }
    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string){
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