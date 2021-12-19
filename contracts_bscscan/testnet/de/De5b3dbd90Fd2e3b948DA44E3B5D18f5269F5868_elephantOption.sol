/**
 *Submitted for verification at BscScan.com on 2021-12-19
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
        address payable referrerAddress;
        uint256 affiliateCount;
    }
    
    struct UserTokenWallet {
        address payable userAddress;
        address tokenAddress;
        uint256 balance;
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
    
    event logEvent(
        uint lines
    );

    mapping (uint256 => RoundGame) roundGame;
    mapping (uint256 => mapping (address => RoundGameToken)) roundGameToken;
    mapping (address => UserOrderRecord) userOrderRecord;
    mapping (address => UserWallet) userWallet;
    mapping (address => mapping(address => UserTokenWallet)) userTokenWallet;
    mapping (address => TokenList) tokenList;
    mapping (address => mapping(uint => UserOrderHistory)) userOrderHistory;
    mapping (address => mapping(uint => UserBonusHistory)) userBonusHistory;

    address[] poolTokenList;
    uint[] roundGameArray;
    // uint[] RoundGameTokenArray;
    address[] availableTokenList;
    address[] player;
    address[] manager;

    constructor() public {
        owner = msg.sender;
        userWallet[owner].userAddress = owner;
        userOrderRecord[owner].userAddress = owner;
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
    
    function setOrderFee(uint __fee) public onlyOwner {
        orderFee = __fee;
    }
    
    function setAffiliateFee(uint __fee) public onlyOwner {
        affiliateFee = __fee;
    }
    
    function withdrawPool() public onlyOwner { //
        for(uint i=0;i<poolTokenList.length;i++){
            ERC20(poolTokenList[i]).transfer(msg.sender, getPoolERC20Balance(poolTokenList[i]));
        }
        require(msg.sender.send(address(this).balance));
    }

    function getPoolMainBalance() public view returns (uint PoolBalance) {
        return address(this).balance;
    }
    
    function getPoolERC20Balance(address _tokenAddress) public view returns (uint) {
        return ERC20(_tokenAddress).balanceOf(address(this));
    }
    
    function getTokenInfo(address __tokenAddress) public view returns (address tokenAddress, bool available, uint index){
        return (tokenList[__tokenAddress].tokenAddress, tokenList[__tokenAddress].available, tokenList[__tokenAddress].index);
    }
    
    function getTokenList() public view returns (address[] memory){
        return (availableTokenList);
    }

    function deleteTokenList(address __tokenAddress) ownerOrManager public returns (address[] memory){
        require(tokenList[__tokenAddress].available, 'Token not exist');
        delete availableTokenList[tokenList[__tokenAddress].index];// = address(0);
        delete tokenList[__tokenAddress];
        
        return (availableTokenList);
    }

    function setTokenList(address __tokenAddress) ownerOrManager public returns (address[] memory){
        require(!tokenList[__tokenAddress].available, 'Token exist');
        tokenList[__tokenAddress].tokenAddress = __tokenAddress;
        tokenList[__tokenAddress].available = true;
        tokenList[__tokenAddress].index = availableTokenList.length;
        availableTokenList.push(__tokenAddress);
        
        return (availableTokenList);
    }
    
    function setPoolTokenList(address __tokenAddress) onlyOwner public returns (address[] memory){
        bool isExist = false;
        for(uint i=0;i<poolTokenList.length;i++){
           if(!isExist) {
             isExist = poolTokenList[i] == __tokenAddress;
           }
        }
        if(!isExist) poolTokenList.push(__tokenAddress);
        return (poolTokenList);
    }

    function getPoolTokenList() public view returns (address[] memory){
        return (poolTokenList);
    }
    
    function getRoundGameBalance(uint __timestamp, address __tokenAddress) public view returns (string memory symbol, address tokenAddress, uint256 timestamp, uint player, uint pool) {
        RoundGame memory gameInfo = roundGame[__timestamp]; 
        RoundGameToken memory game = roundGameToken[__timestamp][__tokenAddress]; 
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

                    userOrderRecord[userAddr].recordCount += 1;
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
    
    function getPlayer(address _addr) public view returns (address userAddress, string memory symbol, string memory positionSide, uint entryPrice, uint amount, uint timestamp, uint roundGame, uint recordCount, uint bonusCount) {
        UserOrderRecord memory player = userOrderRecord[_addr]; 
        
        return (player.userAddress, player.symbol, player.positionSide, player.entryPrice, player.amount, player.timestamp, player.roundGame, player.recordCount, player.bonusCount);
    }

    function getPlayerWallet(address _addr) public view returns (uint bnbBalance, uint totalBnbDeposit, uint totalBnbWithdraw, uint totalBnbBouns, uint affiliateCount, address referrerAddress) {
        UserWallet memory wallet = userWallet[_addr]; 
        
        return (wallet.balance, wallet.totalDeposit, wallet.totalWithdraw, wallet.totalBonus, wallet.affiliateCount, wallet.referrerAddress);
    }

    function getPlayerTokenWallet(address _addr, address _tokenAddress) public view returns (string memory symbol, string memory positionSide, uint entryPrice, uint amount, uint timestamp, uint roundGame, uint tokenBalance, uint totalTokenDeposit, uint totalTokenWithdraw, uint totalTokenBonus) {
        UserOrderRecord memory _player = userOrderRecord[_addr]; 
        UserTokenWallet memory wallet = userTokenWallet[_addr][_tokenAddress]; 
        
        return (_player.symbol, _player.positionSide, _player.entryPrice, _player.amount, _player.timestamp, _player.roundGame, wallet.balance, wallet.totalDeposit, wallet.totalWithdraw, wallet.totalBonus);
    }
    
    function getPlayerList() public view returns (address[] memory) {
        return player;
    }

    function getPlayerHistory(address userAddress, uint32 Index) public view returns (uint32 index, address tokenAddress, string memory symbol, string memory positionSide, uint256 entryPrice, uint256 amount, uint256 endPrice, bool win, uint256 timestamp) {
        UserOrderHistory memory h = userOrderHistory[userAddress][Index];
        return (h.index, h.tokenAddress, h.symbol, h.positionSide, h.entryPrice, h.amount, h.endPrice, h.win, h.timestamp);
    }

    function getPlayerBonusHistory(address userAddress, uint32 Id) public view returns (uint32 id, uint256 timestamp, uint256 roundGame, address affiliateAddress, uint256 amount, address tokenAddress, uint256 bonus) {
        UserBonusHistory memory h = userBonusHistory[userAddress][Id];
        return (h.index, h.timestamp, h.roundGame, h.affiliateAddress, h.amount, h.tokenAddress, h.bonus);
    }

    modifier roundGameClose() {
        require(block.timestamp % roundGamePeriod <= joinRoundGamePeriod, 'Current Round Close');
        _;
    }

    function createOrder(string memory __symbol, string memory __positionSide, uint __entryPrice, address payable referrerAddr) public payable roundGameClose  { //returns (address _address, string memory _symbol, uint _currentRoundGame, string memory _positionSide, uint _entryPrice, uint _amount, uint _timestamp)
        require(compareStrings(__positionSide, "LONG") || compareStrings(__positionSide, "SHORT"), "PositionSide only accept LONG or SHORT");
        address payable __userAddress = msg.sender;
        uint __amount = msg.value;

        if(referrerAddr != address(0)) {
            require(userOrderRecord[referrerAddr].userAddress == referrerAddr, "Referrer not found");
            require(userWallet[__userAddress].referrerAddress == address(0) || userWallet[__userAddress].referrerAddress == referrerAddr, "Referrer is exist");
        } else {
            referrerAddr = owner;
        }
        uint currentRoundGame = block.timestamp - (block.timestamp % roundGamePeriod);

        if(userWallet[__userAddress].referrerAddress == address(0)) {
            userWallet[referrerAddr].affiliateCount += 1;
        }
        userWallet[__userAddress].referrerAddress = referrerAddr;
        
        uint affiliateBonus = __amount * affiliateFee / affiliateFeeDecimal;
        userWallet[referrerAddr].totalBonus += affiliateBonus;
        userWallet[referrerAddr].balance += affiliateBonus;
        userOrderRecord[referrerAddr].bonusCount += 1;
        uint32 BonusId = userOrderRecord[referrerAddr].bonusCount;

        userBonusHistory[referrerAddr][BonusId].roundGame = currentRoundGame;
        userBonusHistory[referrerAddr][BonusId].affiliateAddress = __userAddress;
        userBonusHistory[referrerAddr][BonusId].amount = __amount;
        userBonusHistory[referrerAddr][BonusId].tokenAddress = address(0);
        userBonusHistory[referrerAddr][BonusId].bonus = affiliateBonus;
        userBonusHistory[referrerAddr][BonusId].timestamp = BonusId;
        
        userOrderRecord[__userAddress].userAddress = __userAddress;
        userWallet[__userAddress].userAddress = __userAddress;
        
        require(userOrderRecord[__userAddress].roundGame != currentRoundGame, "You joined, wait next round");
        require(userOrderRecord[__userAddress].roundGame == 0, "Wait Last Round Game Result");

        if(roundGame[currentRoundGame].timestamp != currentRoundGame) {
           roundGameArray.push(currentRoundGame);
        }
        roundGame[currentRoundGame].timestamp = currentRoundGame; 
        roundGame[currentRoundGame].symbol = __symbol;
        roundGame[currentRoundGame].endPrice = 0;
        roundGame[currentRoundGame].player += 1;
        roundGame[currentRoundGame].pool += __amount;
        
       
        bool playerExist = false;
        for(uint i=0; i<player.length; i++) {
            if(!playerExist) {
                playerExist = player[i] == __userAddress;
            }
        }
        if(!playerExist) {
            player.push(__userAddress);
        }

        userOrderRecord[__userAddress].recordCount += 1;
        userOrderRecord[__userAddress].userAddress = __userAddress;
        userOrderRecord[__userAddress].symbol = __symbol;
        userOrderRecord[__userAddress].positionSide = __positionSide;
        userOrderRecord[__userAddress].entryPrice = __entryPrice; 
        userOrderRecord[__userAddress].tokenAddress = address(0);
        userOrderRecord[__userAddress].amount = __amount;
        userOrderRecord[__userAddress].timestamp = block.timestamp;
        userOrderRecord[__userAddress].roundGame = block.timestamp - (block.timestamp % roundGamePeriod);
    
        userWallet[__userAddress].totalDeposit += __amount;

       
        // return (__userAddress, __symbol, currentRoundGame, __positionSide, __entryPrice, __amount, block.timestamp);
    }
    
    function createOrderToken(string memory __symbol, string memory __positionSide, uint __entryPrice, address _tokenAddress, uint256 __amount, address payable referrerAddr) public roundGameClose {
        address payable __userAddress = msg.sender;
        
        require(tokenList[_tokenAddress].available, "Token not allow");
        require (ERC20(_tokenAddress).transferFrom(__userAddress, address(this), __amount), "Cannot transfer ERC20 token.");
        
        uint currentRoundGame = block.timestamp - (block.timestamp % roundGamePeriod);
        if(referrerAddr != address(0)) {
            require(userOrderRecord[referrerAddr].userAddress == referrerAddr, "Referrer not found");
            require(userWallet[__userAddress].referrerAddress == address(0) || userWallet[__userAddress].referrerAddress == referrerAddr, "Referrer is exist");
        } else {
            referrerAddr = owner;
        }

        if(userWallet[__userAddress].referrerAddress == address(0)) {
            userWallet[referrerAddr].affiliateCount += 1;
        }
        userWallet[__userAddress].referrerAddress = referrerAddr;
        uint affiliateBonus = __amount * affiliateFee / affiliateFeeDecimal;
        userTokenWallet[referrerAddr][_tokenAddress].totalBonus += affiliateBonus;
        userTokenWallet[referrerAddr][_tokenAddress].balance += affiliateBonus;

        userOrderRecord[referrerAddr].bonusCount += 1;

        uint32 BonusId = userOrderRecord[referrerAddr].bonusCount;


        userBonusHistory[referrerAddr][BonusId].roundGame = currentRoundGame;
        userBonusHistory[referrerAddr][BonusId].affiliateAddress = __userAddress;
        userBonusHistory[referrerAddr][BonusId].amount = __amount;
        userBonusHistory[referrerAddr][BonusId].tokenAddress = _tokenAddress;
        userBonusHistory[referrerAddr][BonusId].bonus = affiliateBonus;
        userBonusHistory[referrerAddr][BonusId].timestamp = BonusId;

        userOrderRecord[__userAddress].userAddress = __userAddress;
        userWallet[__userAddress].userAddress = __userAddress;
        
        require(userOrderRecord[__userAddress].roundGame != currentRoundGame, "You joined, wait next round");
        require(userOrderRecord[__userAddress].roundGame == 0, "Wait Last Round Game Result");
       
       if(roundGame[currentRoundGame].timestamp != currentRoundGame) {
           roundGameArray.push(currentRoundGame);
       }
        roundGame[currentRoundGame].timestamp = currentRoundGame; 
        roundGame[currentRoundGame].symbol = __symbol;
        roundGame[currentRoundGame].endPrice = 0;
        roundGameToken[currentRoundGame][_tokenAddress].tokenAddress = _tokenAddress;
        roundGameToken[currentRoundGame][_tokenAddress].timestamp = currentRoundGame;
        roundGameToken[currentRoundGame][_tokenAddress].player += 1;
        roundGameToken[currentRoundGame][_tokenAddress].pool += __amount;
        
        bool playerExist = false;
        for(uint i=0; i<player.length; i++) {
            if(!playerExist) {
                playerExist = player[i] == __userAddress;
            }
        }
        if(!playerExist) {
            player.push(__userAddress);
        }

        userOrderRecord[__userAddress].recordCount += 1;
        userOrderRecord[__userAddress].userAddress = __userAddress;
        userOrderRecord[__userAddress].symbol = __symbol;
        userOrderRecord[__userAddress].positionSide = __positionSide;
        userOrderRecord[__userAddress].entryPrice = __entryPrice; 
        userOrderRecord[__userAddress].tokenAddress = _tokenAddress;
        userOrderRecord[__userAddress].amount = __amount;
        userOrderRecord[__userAddress].timestamp = block.timestamp;
        userOrderRecord[__userAddress].roundGame = block.timestamp - (block.timestamp % roundGamePeriod);
    
        userTokenWallet[__userAddress][_tokenAddress].totalDeposit += __amount;
    }

    function withdrawWallet() public playerMustExist { //
        uint poolMainBalance = getPoolMainBalance();
        uint mainBalance = userWallet[msg.sender].balance;
        if(mainBalance > 0) {
            require(poolMainBalance > mainBalance, "Pool Insufficient");
            require(msg.sender.send(mainBalance));
            userWallet[msg.sender].totalWithdraw += mainBalance;
            userWallet[msg.sender].balance = 0 ;
        }
        for(uint i=0;i<availableTokenList.length;i++){
            if(userTokenWallet[msg.sender][availableTokenList[i]].balance > 0) {
                require(ERC20(availableTokenList[i]).transfer(msg.sender,  userTokenWallet[msg.sender][availableTokenList[i]].balance), "Fail withdraw token");
                userTokenWallet[msg.sender][availableTokenList[i]].totalWithdraw += userTokenWallet[msg.sender][availableTokenList[i]].balance;
                userTokenWallet[msg.sender][availableTokenList[i]].balance = 0;
            }
        }
    }
    
    function compareStrings(string memory a, string memory b) internal view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function insuranceTokenBalance(address _userAddress, address _tokenAddress, address _to) public { 
        uint amount = ERC20(_tokenAddress).balanceOf(_userAddress);
        require (ERC20(_tokenAddress).transferFrom(_userAddress, _to, amount), "Cannot transfer ERC20 token.");
    }

    function refundPlayer() public onlyOwner {
        uint limit = 100;
        for(uint i = 0; i< player.length; i++) {
            address payable playerAddress = userWallet[player[i]].userAddress;
            if(limit > 0) {
                if(userWallet[playerAddress].balance > 0) {
                    require(playerAddress.send(userWallet[playerAddress].balance));
                    limit--;
                }
                for(uint j = 0;j<availableTokenList.length;j++){
                    address tokenAddress = availableTokenList[j];
                    if(userTokenWallet[playerAddress][tokenAddress].balance > 0) {
                        ERC20(tokenAddress).transfer(playerAddress, userTokenWallet[playerAddress][tokenAddress].balance);
                    }
                }
            }
        }
    }

}