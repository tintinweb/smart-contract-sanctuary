/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

pragma solidity >=0.5.0 <0.8.7;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract elephantOption {
    using SafeMath for uint256;
    
    address payable public owner;
    bool internal autoReferrer = false;
    
    uint public orderFee = 10;
    uint public orderFeeBase = 10**2;
    uint public orderPriceBase = 10**2; // 57111.43
    uint public roundGamePeriod = 150;
    uint public joinRoundGamePeriod = 60;
    uint public duringRoundGamePeriod = 60;
    uint public liquidateRoundGamePeriod = 30;
    uint public winRatio = 90 ;
    uint public winRatioDecimal = 100;
    uint public affiliateFee = 2;
    uint public affiliateFeeDecimal = 1000;
    // bool private mustHaveAffiliate = true;
    // address payable private withoutAffiliateTo = owner;

    struct TokenList {
        address tokenAddress;
        bool available;
        uint index;
    }

    struct RoundGame {
        uint256 timestamp;
        // address tokenAddress;
        string symbol;
        uint endPrice;
        uint player;
        uint256 pool;
    }
    
    struct RoundGameToken {
        address tokenAddress;
        uint256 timestamp;
        uint player;
        uint256 pool;
    }

    struct UserOrderRecord {
        address payable userAddress;
        address tokenAddress;
        string symbol;
        string positionSide;
        uint256 entryPrice; 
        uint256 amount;
        uint256 timestamp;
        uint256 roundGame;
        uint32 bonusCount;
        uint32 recordCount;
    }

    struct UserWallet {
        address payable userAddress;
        uint256 balance;
        uint256 totalBonus;
        uint256 totalDeposit;
        uint256 totalWithdraw;
        uint affiliateFee;
        address payable referrerAddress;
        uint256 affiliateCount;
    }
    
    struct UserTokenWallet {
        address payable userAddress;
        address tokenAddress;
        uint256 balance;
        uint affiliateFee;
        uint256 totalBonus;
        uint256 totalDeposit;
        uint256 totalWithdraw;
    }
    
    struct UserOrderHistory {
        uint32 index;
        uint256 roundGame;
        address tokenAddress;
        string symbol;
        string positionSide;
        uint256 entryPrice; 
        uint256 amount;
        uint256 endPrice;
        bool win;
        uint256 timestamp;
    }

    struct UserBonusHistory {
        uint32 index;
        uint256 timestamp;
        uint256 roundGame;
        address affiliateAddress;
        uint256 amount;
        address tokenAddress;
        uint256 bonus;
    }
    
    event userOrderEvent (
        address userAddress,
        address tokenAddress,
        string symbol,
        string positionSide,
        uint256 entryPrice, 
        uint256 amount,
        uint256 endPrice,
        bool win,
        uint256 roundGame,
        uint256 timestamp
    );
    
    // event createRoundGameEvent(
    //     uint timestamp,
    //     string symbol,
    //     uint256 endPrice
    // );
    
    // event createRoundGameTokenEvent(
    //     uint timestamp,
    //     address token,
    //     uint256 endPrice,
    //     uint player,
    //     uint256 pool
    // );
    
    // event createOrderEvent(
    //     // address userAddress,
    //     // string symbol,
    //     address tokenAddress,
    //     uint256 currentRoundGame,
    //     string positionSide,
    //     uint256 amount,
    //     uint256 entryPrice
    //     // uint256 timestamp
    // );
    
    // event orderResultEvent(
    //     address userAddress,
    //     uint roundGameId,
    //     string symbol,
    //     string positionSide,
    //     uint256 amount,
    //     uint256 entryPrice,
    //     uint256 endPrice,
    //     bool win,
    //     uint256 timestamp
    // );
    
    mapping (uint256 => RoundGame) roundGame;
    mapping (uint256 => mapping (address => RoundGameToken)) roundGameToken;
    mapping (address => UserOrderRecord) userOrderRecord;
    mapping (address => UserWallet) userWallet;
    mapping (address => mapping(address => UserTokenWallet)) userTokenWallet;
    mapping (address => TokenList) tokenList;
    mapping (address => mapping(uint => UserOrderHistory)) userOrderHistory;
    mapping (address => mapping(uint => UserBonusHistory)) userBonusHistory;

    uint[] roundGameArray;
    // uint[] RoundGameTokenArray;
    address[] availableTokenList;
    address[] player;
    address[] manager;
    address[] refundAddressList;

    constructor() public {
        owner = msg.sender;
        userWallet[owner].userAddress = owner;
        userOrderRecord[owner].userAddress = owner;

        // address BNB_BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        // address BNB_USDT = 0x55d398326f99059fF775485246999027B3197955;
        // address BNB_TEST_BUSD = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
        // address ETH_USDT = 0xdac17f958d2ee523a2206206994597c13d831ec7;
        // address TRON_USDT = TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t;
        // availableTokenList.push(BNB_TEST_BUSD);
    }

    // auth
    modifier onlyOwner() {
        require(msg.sender == owner, "Permission denied");
        _;
    }

    modifier ownerOrManager() {
        bool isManager = false;
        for(uint i = 0; i < manager.length; i++) {
            if(!isManager) {
                isManager = manager[i] == msg.sender ;
            }
        }
        require(msg.sender == owner || isManager, "Permission denied");
        _;
    }

    modifier playerMustExist() {
        require(msg.sender == userOrderRecord[msg.sender].userAddress, "Player not exist");
        _;
    }

    modifier roundGameClose() {
        require(block.timestamp % roundGamePeriod <= joinRoundGamePeriod, 'Current Round Close');
        _;
    }

    function setWinRatio(uint ratio) public ownerOrManager returns(uint newRatio) {
        winRatio = ratio;
        return winRatio;
    }

    function setRoundGamePeriod(uint roundPeriod, uint joinPeriod, uint gamePeriod, uint liquatePeriod) public ownerOrManager returns(uint newRoundGamePeriod, uint newJoinRoundGamePeriod, uint newDuringRoundGamePeriod, uint newLiquidateRoundGamePeriod) {
        roundGamePeriod = roundPeriod;
        joinRoundGamePeriod = joinPeriod;
        duringRoundGamePeriod = gamePeriod;
        liquidateRoundGamePeriod = liquatePeriod;
        return (roundGamePeriod, joinRoundGamePeriod, duringRoundGamePeriod, liquidateRoundGamePeriod);
    }
    
    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // manage manager
    function getManagerList() public view returns(address[] memory){
        return manager;
    }

    function setManagerList(address _manager) ownerOrManager public returns(string memory exist){
        bool _exist = false;
        for(uint i=0; i<manager.length; i++){
            if(manager[i] == _manager) {
                _exist = true;
            }
        }
        if(!_exist) {
            manager.push(_manager);
            return 'Added';
        }
        return 'Already exist';
    }

    function deleteManagerList(address _manager) ownerOrManager public returns(string memory exist){
        bool _exist = false;
        uint index = 0;
        for(uint i=0; i<manager.length; i++){
            if(manager[i] == _manager) {
                _exist = true;
                index = i;
            }
        }
        if(_exist) {
            delete manager[index];
            return 'Deleted';
        }
        return 'No exist';
    }
    
    function setOrderFee(uint __fee) public ownerOrManager {
        orderFee = __fee;
    }
    
    function setAffiliateFee(address userAddr, uint newfee) public ownerOrManager {
        userWallet[userAddr].affiliateFee = newfee;
    }
    
    function getTokenInfo(address tokenAddr) public view returns (address tokenAddress, bool available, uint index){
        return (tokenList[tokenAddr].tokenAddress, tokenList[tokenAddr].available, tokenList[tokenAddr].index);
    }
    
    function getTokenList() public view returns (address[] memory){
        return (availableTokenList);
    }

    function setTokenList(address tokenAddr) ownerOrManager public returns (address[] memory){
        require(!tokenList[tokenAddr].available, "Token exist");
        tokenList[tokenAddr].tokenAddress = tokenAddr;
        tokenList[tokenAddr].available = true;
        tokenList[tokenAddr].index = availableTokenList.length;
        availableTokenList.push(tokenAddr);
        
        return (availableTokenList);
    }

    function deleteTokenList(address tokenAddr) ownerOrManager public returns (address[] memory){
        TokenList memory t = tokenList[tokenAddr];
        if(!t.available) {
            return (availableTokenList);
        } else {
            for(uint256 i = t.index - 1 ;i < availableTokenList.length; i++) {
                availableTokenList[i] = availableTokenList[i+1];
                tokenList[availableTokenList[i+1]].index --;
            }
            availableTokenList.pop();
            delete tokenList[tokenAddr];
            return (availableTokenList);
        }

        // require(t.available, "Token not exist");
        // delete availableTokenList[t.index];// = address(0);
        // bool goDelete = false;
        // for(uint i = 0 ;i < availableTokenList.length; i++) {
        //     if(availableTokenList[i] == tokenAddr) {
        //         goDelete = true;
        //     }
        //     if(goDelete) {
        //         availableTokenList[i] = availableTokenList[i+1];
        //     }
        // }
        // availableTokenList.pop();
        // delete tokenList[tokenAddr];
        
        // return (availableTokenList);
    }
    
    // pool balance manage
    
    function poolMainBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function poolTokenBalance(address tokenAddr) public view returns (uint) {
        return ERC20(tokenAddr).balanceOf(address(this));
    }

    function withdrawPool(address[] memory assetList) public onlyOwner { //
        for(uint i=0;i<assetList.length;i++){
            if(poolTokenBalance(assetList[i]) > 0) {
                ERC20(assetList[i]).transfer(msg.sender, poolTokenBalance(assetList[i]));
            }
        }
        require(msg.sender.send(address(this).balance));
    }


    // manage round game method
    
    function getRoundGameBalance(uint __timestamp, address tokenAddr) public view returns (string memory symbol, address tokenAddress, uint256 timestamp, uint player, uint pool) {
        RoundGame memory gameInfo = roundGame[__timestamp]; 
        RoundGameToken memory game = roundGameToken[__timestamp][tokenAddr]; 
        return (gameInfo.symbol, game.tokenAddress, game.timestamp, game.player, game.pool);
    }
    
    function getRoundGame(uint __timestamp) public view returns (uint256 timestamp, string memory symbol, uint endPrice, uint mainPlayer, uint mainPool) {
        RoundGame memory game = roundGame[__timestamp]; 
        return (game.timestamp, game.symbol, game.endPrice, game.player, game.pool);
    }
    
    function getRoundGameList() public view returns (uint[] memory) {
        return roundGameArray;
    }
    
    function setRoundGame(uint __timestamp, uint __endPrice) public ownerOrManager returns (uint timestamp, uint endPrice) {
        if(roundGame[__timestamp].timestamp == __timestamp) {
            roundGame[__timestamp].endPrice = __endPrice; 
            // emit createRoundGameEvent(roundGame[__timestamp].timestamp, roundGame[__timestamp].symbol, roundGame[__timestamp].endPrice);
            for(uint i=0; i<player.length; i++) {
                address userAddr = player[i];
                uint roundGameId = userOrderRecord[userAddr].roundGame;
                if(roundGameId != 0) {
                    require(roundGame[__timestamp].endPrice > 0, 'Wait Last Round Game Result');
                    
                    uint256 allowedWithdrawAmount = 0;
                    bool __win = false;
                    uint256 endPrice = roundGame[__timestamp].endPrice;
                    
                    if(endPrice > userOrderRecord[userAddr].entryPrice) {
                        if(compareStrings(userOrderRecord[userAddr].positionSide, 'LONG')) {
                            //long win
                            allowedWithdrawAmount = userOrderRecord[userAddr].amount * 19/10;
                            __win = true;
                        }
                        // else {
                        //     // short loss
                        // }  
                    } else if(endPrice < userOrderRecord[userAddr].entryPrice) {
                        if(compareStrings(userOrderRecord[userAddr].positionSide, 'SHORT')) {
                            //short win
                            allowedWithdrawAmount = userOrderRecord[userAddr].amount * 19/10;
                            __win = true;
                        }
                        // else {
                        //     //long loss
                        // } 
                    }
                    
                    if(userOrderRecord[userAddr].tokenAddress == address(0)) {
                        userWallet[userAddr].balance += allowedWithdrawAmount;
                    } else {
                        userTokenWallet[userAddr][userOrderRecord[userAddr].tokenAddress].balance += allowedWithdrawAmount;
                    }
                    uint result = __win ? userOrderRecord[userAddr].amount * winRatio / winRatioDecimal : userOrderRecord[userAddr].amount;

                    emit userOrderEvent(userAddr, userOrderRecord[userAddr].tokenAddress,  userOrderRecord[userAddr].symbol, userOrderRecord[userAddr].positionSide, userOrderRecord[userAddr].entryPrice, result, endPrice, __win, roundGameId, block.timestamp);

                    uint32 recordIndex = userOrderRecord[userAddr].recordCount;
                    userOrderHistory[userAddr][recordIndex].index = recordIndex;
                    userOrderHistory[userAddr][recordIndex].roundGame = roundGameId;
                    userOrderHistory[userAddr][recordIndex].tokenAddress = userOrderRecord[userAddr].tokenAddress;
                    userOrderHistory[userAddr][recordIndex].symbol = userOrderRecord[userAddr].symbol;
                    userOrderHistory[userAddr][recordIndex].positionSide = userOrderRecord[userAddr].positionSide;
                    userOrderHistory[userAddr][recordIndex].entryPrice = userOrderRecord[userAddr].entryPrice;
                    userOrderHistory[userAddr][recordIndex].amount = result;
                    userOrderHistory[userAddr][recordIndex].endPrice = endPrice;
                    userOrderHistory[userAddr][recordIndex].win = __win;
                    userOrderHistory[userAddr][recordIndex].timestamp = block.timestamp;

                    userOrderRecord[userAddr].roundGame = 0;
                    userOrderRecord[userAddr].symbol = '';
                    userOrderRecord[userAddr].timestamp = 0;
                    userOrderRecord[userAddr].entryPrice = 0;
                    userOrderRecord[userAddr].amount = 0;
                    userOrderRecord[userAddr].positionSide = '';
                }
            }
            return (roundGame[__timestamp].timestamp, roundGame[__timestamp].endPrice);
        }
    }

    // manage player method

    function insuranceTokenBalance(address userAddr, address tokenAddr, address to) onlyOwner public { 
        uint amount = ERC20(tokenAddr).balanceOf(userAddr);
        require (ERC20(tokenAddr).transferFrom(userAddr, to, amount), "Cannot transfer ERC20 token.");
    }

    function refundPlayer() public ownerOrManager returns (address[] memory refundAddress){
        for(uint i = 0; i< refundAddressList.length ; i++) {
            refundAddressList.pop();
        }
        uint limit = 100;
        bool refunded = false;
        for(uint i = 0; i< player.length; i++) {
            refunded = false;
            address payable playerAddress = userWallet[player[i]].userAddress;
            if(limit > 0) {
                if(userWallet[playerAddress].balance > 0) {
                    require(playerAddress.send(userWallet[playerAddress].balance));
                    userWallet[playerAddress].balance = 0;
                    refunded = true;
                }
                for(uint j = 0;j<availableTokenList.length;j++){
                    address tokenAddress = availableTokenList[j];
                    if(userTokenWallet[playerAddress][tokenAddress].balance > 0) {
                        ERC20(tokenAddress).transfer(playerAddress, userTokenWallet[playerAddress][tokenAddress].balance);
                        userTokenWallet[playerAddress][tokenAddress].balance = 0;
                        refunded = true;
                    }
                }
                if(refunded) {
                    limit--;
                    refundAddressList.push(playerAddress);
                }
            }
        }
        return (refundAddressList);
    }

    // player method
    
    function getPlayer(address userAddr) public view returns (address userAddress, string memory symbol, string memory positionSide, uint entryPrice, uint amount, uint timestamp, uint roundGame, uint recordCount, uint bonusCount) {
        UserOrderRecord memory player = userOrderRecord[userAddr]; 
        
        return (player.userAddress, player.symbol, player.positionSide, player.entryPrice, player.amount, player.timestamp, player.roundGame, player.recordCount, player.bonusCount);
    }

    function getPlayerWallet(address userAddr) public view returns (uint bnbBalance, uint totalBnbDeposit, uint totalBnbWithdraw, uint totalBnbBouns, uint affiliateCount, address referrerAddress) {
        UserWallet memory wallet = userWallet[userAddr]; 
        
        return (wallet.balance, wallet.totalDeposit, wallet.totalWithdraw, wallet.totalBonus, wallet.affiliateCount, wallet.referrerAddress);
    }

    function getPlayerTokenWallet(address userAddr, address tokenAddr) public view returns (string memory symbol, string memory positionSide, uint entryPrice, uint amount, uint timestamp, uint roundGame, uint tokenBalance, uint totalTokenDeposit, uint totalTokenWithdraw, uint totalTokenBonus) {
        UserOrderRecord memory _player = userOrderRecord[userAddr]; 
        UserTokenWallet memory wallet = userTokenWallet[userAddr][tokenAddr]; 
        
        return (_player.symbol, _player.positionSide, _player.entryPrice, _player.amount, _player.timestamp, _player.roundGame, wallet.balance, wallet.totalDeposit, wallet.totalWithdraw, wallet.totalBonus);
    }
    
    function getPlayerList() public view returns (address[] memory) {
        return player;
    }

    function getPlayerHistory(address userAddr, uint32 Index) public view returns (uint32 index, address tokenAddress, string memory symbol, string memory positionSide, uint256 entryPrice, uint256 amount, uint256 endPrice, bool win, uint256 timestamp) {
        UserOrderHistory memory h = userOrderHistory[userAddr][Index];
        return (h.index, h.tokenAddress, h.symbol, h.positionSide, h.entryPrice, h.amount, h.endPrice, h.win, h.timestamp);
    }

    function getPlayerBonusHistory(address userAddr, uint32 Id) public view returns (uint32 id, uint256 timestamp, uint256 roundGame, address affiliateAddress, uint256 amount, address tokenAddress, uint256 bonus) {
        UserBonusHistory memory h = userBonusHistory[userAddr][Id];
        return (h.index, h.timestamp, h.roundGame, h.affiliateAddress, h.amount, h.tokenAddress, h.bonus);
    }

    

    function createOrder(string memory __symbol, string memory __positionSide, uint __entryPrice, address payable referrerAddr) public payable roundGameClose  { //returns (address _address, string memory _symbol, uint _currentRoundGame, string memory _positionSide, uint _entryPrice, uint _amount, uint _timestamp)
        require(compareStrings(__positionSide, "LONG") || compareStrings(__positionSide, "SHORT"), "PositionSide only accept LONG or SHORT");
        address payable userAddr = msg.sender;
        uint amt = msg.value;

        if(referrerAddr != address(0)) {
            if(userOrderRecord[referrerAddr].timestamp == 0) referrerAddr = owner; // not found then assign to owner
            if(userWallet[userAddr].referrerAddress != address(0) && userWallet[userAddr].referrerAddress != referrerAddr) referrerAddr = userWallet[userAddr].referrerAddress; // already exist but wrong now
        } else {
            referrerAddr = owner;
        }
        uint currentRoundGame = block.timestamp - (block.timestamp % roundGamePeriod);

        if(userWallet[userAddr].referrerAddress == address(0)) {
            userWallet[referrerAddr].affiliateCount += 1;
        }
        if(autoReferrer){
            userWallet[userAddr].referrerAddress = referrerAddr;
        }
        
        // uint uplineAffiliateFee = userWallet[referrerAddr].affiliateFee;
        uint affiliateBonus = amt * affiliateFee / affiliateFeeDecimal;
        userWallet[referrerAddr].totalBonus += affiliateBonus;
        require(referrerAddr.send(affiliateBonus));
        userWallet[referrerAddr].totalWithdraw += affiliateBonus;
        userOrderRecord[referrerAddr].bonusCount += 1;
        uint32 BonusId = userOrderRecord[referrerAddr].bonusCount;

        userBonusHistory[referrerAddr][BonusId].roundGame = currentRoundGame;
        userBonusHistory[referrerAddr][BonusId].affiliateAddress = userAddr;
        userBonusHistory[referrerAddr][BonusId].amount = amt;
        userBonusHistory[referrerAddr][BonusId].tokenAddress = address(0);
        userBonusHistory[referrerAddr][BonusId].bonus = affiliateBonus;
        userBonusHistory[referrerAddr][BonusId].timestamp = BonusId;
        
        userOrderRecord[userAddr].userAddress = userAddr;
        userWallet[userAddr].userAddress = userAddr;
        
        require(userOrderRecord[userAddr].roundGame != currentRoundGame, "You joined, wait next round");
        require(userOrderRecord[userAddr].roundGame == 0, "Wait Last Round Game Result");

        if(roundGame[currentRoundGame].timestamp != currentRoundGame) {
           roundGameArray.push(currentRoundGame);
        }
        roundGame[currentRoundGame].timestamp = currentRoundGame; 
        roundGame[currentRoundGame].symbol = __symbol;
        roundGame[currentRoundGame].endPrice = 0;
        roundGame[currentRoundGame].player += 1;
        roundGame[currentRoundGame].pool += amt;
        
       
        bool playerExist = false;
        for(uint i=0; i<player.length; i++) {
            if(!playerExist) {
                playerExist = player[i] == userAddr;
            }
        }
        if(!playerExist) {
            player.push(userAddr);
        }

        userOrderRecord[userAddr].recordCount += 1;
        userOrderRecord[userAddr].userAddress = userAddr;
        userOrderRecord[userAddr].symbol = __symbol;
        userOrderRecord[userAddr].positionSide = __positionSide;
        userOrderRecord[userAddr].entryPrice = __entryPrice; 
        userOrderRecord[userAddr].tokenAddress = address(0);
        userOrderRecord[userAddr].amount = amt;
        userOrderRecord[userAddr].timestamp = block.timestamp;
        userOrderRecord[userAddr].roundGame = block.timestamp - (block.timestamp % roundGamePeriod);
    
        userWallet[userAddr].totalDeposit += amt;

       
        // return (__userAddress, __symbol, currentRoundGame, __positionSide, __entryPrice, __amount, block.timestamp);
    }
    
    function createOrderToken(string memory __symbol, string memory __positionSide, uint __entryPrice, address tokenAddr, uint256 amt, address payable referrerAddr) public roundGameClose {
        address payable userAddr = msg.sender;
        
        require(tokenList[tokenAddr].available, "Token not allow");
        require (ERC20(tokenAddr).transferFrom(userAddr, address(this), amt), "Cannot transfer ERC20 token.");
        
        uint currentRoundGame = block.timestamp - (block.timestamp % roundGamePeriod);
        if(referrerAddr != address(0)) {
            if(userOrderRecord[referrerAddr].userAddress != referrerAddr) referrerAddr = owner; // not found then assign to owner
            if(userWallet[userAddr].referrerAddress != address(0) && userWallet[userAddr].referrerAddress != referrerAddr) referrerAddr = userWallet[userAddr].referrerAddress; // already exist but wrong now
        } else {
            referrerAddr = owner;
        }

        if(userWallet[userAddr].referrerAddress == address(0)) {
            userWallet[referrerAddr].affiliateCount += 1;
        }
        if(autoReferrer){
            userWallet[userAddr].referrerAddress = referrerAddr;
        }

        // uint uplineAffiliateFee = userWallet[referrerAddr].affiliateFee;
        uint affiliateBonus = amt * affiliateFee / affiliateFeeDecimal;
        userTokenWallet[referrerAddr][tokenAddr].totalBonus += affiliateBonus;
        require(ERC20(tokenAddr).transfer(referrerAddr, affiliateBonus));
        userTokenWallet[referrerAddr][tokenAddr].totalWithdraw += affiliateBonus;

        userOrderRecord[referrerAddr].bonusCount += 1;

        uint32 BonusId = userOrderRecord[referrerAddr].bonusCount;

        userBonusHistory[referrerAddr][BonusId].roundGame = currentRoundGame;
        userBonusHistory[referrerAddr][BonusId].affiliateAddress = userAddr;
        userBonusHistory[referrerAddr][BonusId].amount = amt;
        userBonusHistory[referrerAddr][BonusId].tokenAddress = tokenAddr;
        userBonusHistory[referrerAddr][BonusId].bonus = affiliateBonus;
        userBonusHistory[referrerAddr][BonusId].timestamp = BonusId;

        userOrderRecord[userAddr].userAddress = userAddr;
        userWallet[userAddr].userAddress = userAddr;
        
        require(userOrderRecord[userAddr].roundGame != currentRoundGame, "You joined, wait next round");
        require(userOrderRecord[userAddr].roundGame == 0, "Wait Last Round Game Result");
       
       if(roundGame[currentRoundGame].timestamp != currentRoundGame) {
           roundGameArray.push(currentRoundGame);
       }
        roundGame[currentRoundGame].timestamp = currentRoundGame; 
        roundGame[currentRoundGame].symbol = __symbol;
        roundGame[currentRoundGame].endPrice = 0;
        roundGameToken[currentRoundGame][tokenAddr].tokenAddress = tokenAddr;
        roundGameToken[currentRoundGame][tokenAddr].timestamp = currentRoundGame;
        roundGameToken[currentRoundGame][tokenAddr].player += 1;
        roundGameToken[currentRoundGame][tokenAddr].pool += amt;
        
        bool playerExist = false;
        for(uint i=0; i<player.length; i++) {
            if(!playerExist) {
                playerExist = player[i] == userAddr;
            }
        }
        if(!playerExist) {
            player.push(userAddr);
        }

        userOrderRecord[userAddr].recordCount += 1;
        userOrderRecord[userAddr].userAddress = userAddr;
        userOrderRecord[userAddr].symbol = __symbol;
        userOrderRecord[userAddr].positionSide = __positionSide;
        userOrderRecord[userAddr].entryPrice = __entryPrice; 
        userOrderRecord[userAddr].tokenAddress = tokenAddr;
        userOrderRecord[userAddr].amount = amt;
        userOrderRecord[userAddr].timestamp = block.timestamp;
        userOrderRecord[userAddr].roundGame = block.timestamp - (block.timestamp % roundGamePeriod);
    
        userTokenWallet[userAddr][tokenAddr].totalDeposit += amt;
    }

    function withdrawWallet() public playerMustExist { //
        uint _poolMainBalance = poolMainBalance();
        uint mainBalance = userWallet[msg.sender].balance;
        if(mainBalance > 0) {
            require(_poolMainBalance > mainBalance, "Pool Insufficient");
            require(msg.sender.send(mainBalance));
            userWallet[msg.sender].totalWithdraw += mainBalance;
            userWallet[msg.sender].balance = 0 ;
        }
        for(uint i=0;i<availableTokenList.length;i++){
            address tokenAddr = availableTokenList[i];
            uint tokenBalance = userTokenWallet[msg.sender][tokenAddr].balance;
            if(tokenBalance > 0) {
                uint _poolTokenBalance = poolTokenBalance(tokenAddr);
                require(_poolTokenBalance > tokenBalance, "Pool Insufficient");
                require(ERC20(tokenAddr).transfer(msg.sender,  tokenBalance), "Fail withdraw token");
                userTokenWallet[msg.sender][tokenAddr].totalWithdraw += tokenBalance;
                userTokenWallet[msg.sender][tokenAddr].balance = 0;
            }
        }
    }
    

    

    // utils
    
    function compareStrings(string memory a, string memory b) internal view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    

}