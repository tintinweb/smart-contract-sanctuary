/**
 *Submitted for verification at BscScan.com on 2021-12-11
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

contract dappOptions {
    using SafeMath for uint256;
    
    address payable public owner;
    
    uint public orderFee = 10;
    uint public orderFeeBase = 10**2;
    uint public orderPriceBase = 10**2; // 57111.43
    uint public roundGamePeriod = 120;
    uint public availableJoinRoundGamePeriod = 30;
    uint public winRatio = 19 ;
    uint public winRatioDecimal = 10;

    struct tokenList {
        address tokenAddress;
        bool available;
        uint index;
    }

    struct roundGame {
        uint256 timestamp;
        // address tokenAddress;
        string symbol;
        uint endPrice;
        uint player;
        uint256 pool;
    }
    
    struct roundGameToken {
        address tokenAddress;
        uint256 timestamp;
        uint player;
        uint256 pool;
    }

    struct userOrderRecord {
        address userAddress;
        address tokenAddress;
        string symbol;
        string positionSide;
        uint256 entryPrice; 
        uint256 amount;
        uint256 timestamp;
        uint256 roundGame;
    }

    struct userWallet {
        address userAddress;
        uint256 balance;
        uint256 totalDeposit;
        uint256 totalWithdraw;
    }
    
    struct userTokenWallet {
        address userAddress;
        address tokenAddress;
        uint256 balance;
        uint256 totalDeposit;
        uint256 totalWithdraw;
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

    mapping (uint256 => roundGame) __roundGame;
    mapping (uint256 => mapping (address => roundGameToken)) __roundGameList;
    mapping (address => userOrderRecord) __userOrderRecord;
    mapping (address => userWallet) __userWallet;
    mapping (address => mapping(address => userTokenWallet)) __userWalletList;
    mapping (address => tokenList) __tokenList;

    address[] poolTokenList;
    uint[] roundGameArray;
    // uint[] roundGameTokenArray;
    address[] availableTokenList;
    address[] player;
    address[] manager;

    constructor() public {
        owner = msg.sender;
    }

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
        require(msg.sender == __userOrderRecord[msg.sender].userAddress, "Player not exist");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function getManagerList() public view returns(address[] memory){
        return manager;
    }

    function setManagerList(address _manager) ownerOrManager public returns(string memory exist){
        bool exist = false;
        for(uint i=0; i<manager.length; i++){
            if(manager[i] == _manager) {
                exist = true;
            }
        }
        if(!exist) {
            manager.push(_manager);
            return 'Added';
        }
        return 'Already exist';
    }

    function deleteManagerList(address _manager) ownerOrManager public returns(string memory exist){
        bool exist = false;
        uint index = 0;
        for(uint i=0; i<manager.length; i++){
            if(manager[i] == _manager) {
                exist = true;
                index = i;
            }
        }
        if(exist) {
            delete manager[index];
            return 'Deleted';
        }
        return 'No exist';
    }


    function setOrderFee(uint __fee) public onlyOwner {
        orderFee = __fee;
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
        return (__tokenList[__tokenAddress].tokenAddress, __tokenList[__tokenAddress].available, __tokenList[__tokenAddress].index);
    }
    
    function getTokenList() public view returns (address[] memory){
        return (availableTokenList);
    }

    function setTokenList(address __tokenAddress) ownerOrManager public returns (address[] memory){
        require(!__tokenList[__tokenAddress].available, 'Token exist');
        __tokenList[__tokenAddress].tokenAddress = __tokenAddress;
        __tokenList[__tokenAddress].available = true;
        __tokenList[__tokenAddress].index = availableTokenList.length;
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
        if(isExist) poolTokenList.push(__tokenAddress);
        return (poolTokenList);
    }

    function getPoolTokenList() public returns (address[] memory){
        return (poolTokenList);
    }
    
    function deleteTokenList(address __tokenAddress) ownerOrManager public returns (address[] memory){
        require(__tokenList[__tokenAddress].available, 'Token not exist');
        delete availableTokenList[__tokenList[__tokenAddress].index];// = address(0);
        delete __tokenList[__tokenAddress];
        
        return (availableTokenList);
    }

    // function getGameParams() public view returns(uint orderFee, uint orderFeeBase, uint orderPriceBase, uint roundGamePeriod, uint availableJoinRoundGamePeriod){
    //     return(orderFee, orderFeeBase, orderPriceBase, roundGamePeriod, availableJoinRoundGamePeriod);
    // }
    
    function getRoundGameBalance(uint __timestamp, address __tokenAddress) public view returns (string memory symbol, address tokenAddress, uint256 timestamp, uint player, uint pool) {
        roundGame memory gameInfo = __roundGame[__timestamp]; 
        roundGameToken memory game = __roundGameList[__timestamp][__tokenAddress]; 
        return (gameInfo.symbol, game.tokenAddress, game.timestamp, game.player, game.pool);
    }
    
    function getRoundGame(uint __timestamp) public view returns (uint256 timestamp, string memory symbol, uint endPrice, uint mainPlayer, uint mainPool) {
        roundGame memory game = __roundGame[__timestamp]; 
        return (game.timestamp, game.symbol, game.endPrice, game.player, game.pool);
    }
    
    function getRoundGameList() public view returns (uint[] memory) {
        return roundGameArray;
    }
    
    function setRoundGame(uint __timestamp, uint __endPrice) public ownerOrManager returns (uint timestamp, uint endPrice) {
        if(__roundGame[__timestamp].timestamp == __timestamp) {
            __roundGame[__timestamp].endPrice = __endPrice; 
            // emit createRoundGameEvent(__roundGame[__timestamp].timestamp, __roundGame[__timestamp].symbol, __roundGame[__timestamp].endPrice);
            for(uint i=0; i<player.length; i++) {
                address __userAddress =player[i];
                uint roundGameId = __userOrderRecord[__userAddress].roundGame;
                if(roundGameId != 0) {
                    require(__roundGame[__timestamp].endPrice > 0, 'Wait Last Round Game Result');
                    
                    uint256 allowedWithdrawAmount = 0;
                    bool __win = false;
                    uint256 endPrice = __roundGame[__timestamp].endPrice;
                    
                    if(endPrice > __userOrderRecord[__userAddress].entryPrice) {
                        if(compareStrings(__userOrderRecord[__userAddress].positionSide, 'LONG')) {
                            //long win
                            allowedWithdrawAmount = __userOrderRecord[__userAddress].amount * 19/10;
                            __win = true;
                        }
                        // else {
                        //     // short loss
                        // }  
                    } else if(endPrice < __userOrderRecord[__userAddress].entryPrice) {
                        if(compareStrings(__userOrderRecord[__userAddress].positionSide, 'SHORT')) {
                            //short win
                            allowedWithdrawAmount = __userOrderRecord[__userAddress].amount * 19/10;
                            __win = true;
                        }
                        // else {
                        //     //long loss
                        // } 
                    }
                    
                    if(__userOrderRecord[__userAddress].tokenAddress == address(0)) {
                        __userWallet[__userAddress].balance += allowedWithdrawAmount;
                    } else {
                        __userWalletList[__userAddress][__userOrderRecord[__userAddress].tokenAddress].balance += allowedWithdrawAmount;
                    }

                    emit userOrderEvent(__userAddress, __userOrderRecord[__userAddress].tokenAddress,  __userOrderRecord[__userAddress].symbol, __userOrderRecord[__userAddress].positionSide, __userOrderRecord[__userAddress].entryPrice, __userOrderRecord[__userAddress].amount * winRatio / winRatioDecimal, endPrice, __win, roundGameId, block.timestamp);
                    __userOrderRecord[__userAddress].roundGame = 0;
                    __userOrderRecord[__userAddress].symbol = '';
                    __userOrderRecord[__userAddress].timestamp = 0;
                    __userOrderRecord[__userAddress].entryPrice = 0;
                    __userOrderRecord[__userAddress].amount = 0;
                    __userOrderRecord[__userAddress].positionSide = '';
                }
            }
            return (__roundGame[__timestamp].timestamp, __roundGame[__timestamp].endPrice);
        }
    }
    
    function getPlayer(address __address) public view returns (address _address, string memory _symbol, string memory _positionSide, uint _entryPrice, uint _amount, uint _timestamp, uint _roundGame, uint _bnbBalance, uint _totalBnbDeposit, uint _totalBnbWithdraw) {
        userOrderRecord memory _player = __userOrderRecord[__address]; 
        userWallet memory wallet = __userWallet[__address]; 
        
        return (_player.userAddress, _player.symbol, _player.positionSide, _player.entryPrice, _player.amount, _player.timestamp, _player.roundGame, wallet.balance, wallet.totalDeposit, wallet.totalWithdraw);
    }

    function getPlayerBalance(address __address, address __tokenAddress) public view returns (address _address, string memory _symbol, string memory _positionSide, uint _entryPrice, uint _amount, uint _timestamp, uint _roundGame, uint _tokenBalance, uint _totalTokenDeposit, uint _totalTokenWithdraw) {
        userOrderRecord memory _player = __userOrderRecord[__address]; 
        userTokenWallet memory wallet = __userWalletList[__address][__tokenAddress]; 
        
        return (_player.userAddress, _player.symbol, _player.positionSide, _player.entryPrice, _player.amount, _player.timestamp, _player.roundGame, wallet.balance, wallet.totalDeposit, wallet.totalWithdraw);
    }
    
    function getPlayerList() public view returns (address[] memory) {
        return player;
    }

    modifier roundGameClose() {
        require(block.timestamp % roundGamePeriod <= availableJoinRoundGamePeriod, 'Current Round Close');
        _;
    }

    function createOrder(string memory __symbol, string memory __positionSide, uint __entryPrice) public payable roundGameClose returns (address _address, string memory _symbol, uint _currentRoundGame, string memory _positionSide, uint _entryPrice, uint _amount, uint _timestamp) 
    {
        require(compareStrings(__positionSide, 'LONG') || compareStrings(__positionSide, 'SHORT'), 'PositionSide only accept LONG or SHORT');
        address payable __userAddress = msg.sender;
        uint __amount = msg.value;
        
        uint currentRoundGame = block.timestamp - (block.timestamp % roundGamePeriod);
        
        __userOrderRecord[__userAddress].userAddress = __userAddress;
        __userWallet[__userAddress].userAddress = __userAddress;
        
        require(__userOrderRecord[__userAddress].roundGame != currentRoundGame, 'You joined, wait next round');
        require(__userOrderRecord[__userAddress].roundGame == 0, 'Wait Last Round Game Result');

       if(__roundGame[currentRoundGame].timestamp != currentRoundGame) {
           roundGameArray.push(currentRoundGame);
       }
        __roundGame[currentRoundGame].timestamp = currentRoundGame; 
        __roundGame[currentRoundGame].symbol = __symbol;
        __roundGame[currentRoundGame].endPrice = 0;
        __roundGame[currentRoundGame].player += 1;
        __roundGame[currentRoundGame].pool += __amount;
        
       
        bool playerExist = false;
        for(uint i=0; i<player.length; i++) {
            playerExist = player[i] == __userAddress ? true : false ;
        }
        if(!playerExist) {
            player.push(__userAddress);
        }

        __userOrderRecord[__userAddress].userAddress = __userAddress;
        __userOrderRecord[__userAddress].symbol = __symbol;
        __userOrderRecord[__userAddress].positionSide = __positionSide;
        __userOrderRecord[__userAddress].entryPrice = __entryPrice; 
        __userOrderRecord[__userAddress].tokenAddress = address(0);
        __userOrderRecord[__userAddress].amount = __amount;
        __userOrderRecord[__userAddress].timestamp = block.timestamp;
        __userOrderRecord[__userAddress].roundGame = block.timestamp - (block.timestamp % roundGamePeriod);
    
        __userWallet[__userAddress].totalDeposit += __amount;
       
        // emit createOrderEvent(currentRoundGame, __positionSide, __amount, __entryPrice);
        return (__userAddress, __symbol, currentRoundGame, __positionSide, __entryPrice, __amount, block.timestamp);
    }
    
    
    function createOrderToken(string memory __symbol, string memory __positionSide, uint __entryPrice, address _tokenAddress, uint256 __amount) public roundGameClose returns (string memory _symbol, address tokenAddress, uint _currentRoundGame, string memory _positionSide, uint _entryPrice, uint256 _amount, uint _timestamp) 
    {
        address payable __userAddress = msg.sender;
        
        require(__tokenList[_tokenAddress].available, 'Token not allow');
        require (ERC20(_tokenAddress).transferFrom(__userAddress, address(this), __amount), "Cannot transfer ERC20 token.");
        
        uint currentRoundGame = block.timestamp - (block.timestamp % roundGamePeriod);
        __userOrderRecord[__userAddress].userAddress = __userAddress;
        __userWallet[__userAddress].userAddress = __userAddress;
        
        require(__userOrderRecord[__userAddress].roundGame != currentRoundGame, 'You joined, wait next round');
        require(__userOrderRecord[__userAddress].roundGame == 0, 'Wait Last Round Game Resulttt');
       
       if(__roundGame[currentRoundGame].timestamp != currentRoundGame) {
           roundGameArray.push(currentRoundGame);
       }
        __roundGame[currentRoundGame].timestamp = currentRoundGame; 
        __roundGame[currentRoundGame].symbol = __symbol;
        __roundGame[currentRoundGame].endPrice = 0;
        __roundGameList[currentRoundGame][_tokenAddress].tokenAddress = _tokenAddress;
        __roundGameList[currentRoundGame][_tokenAddress].timestamp = currentRoundGame;
        __roundGameList[currentRoundGame][_tokenAddress].player += 1;
        __roundGameList[currentRoundGame][_tokenAddress].pool += __amount;
        
        bool playerExist = false;
        for(uint i=0; i<player.length; i++) {
            playerExist = player[i] == __userAddress ? true : false ;
        }
         if(!playerExist) {
            player.push(__userAddress);
        }

        __userOrderRecord[__userAddress].userAddress = __userAddress;
        __userOrderRecord[__userAddress].symbol = __symbol;
        __userOrderRecord[__userAddress].positionSide = __positionSide;
        __userOrderRecord[__userAddress].entryPrice = __entryPrice; 
        __userOrderRecord[__userAddress].tokenAddress = _tokenAddress;
        __userOrderRecord[__userAddress].amount = __amount;
        __userOrderRecord[__userAddress].timestamp = block.timestamp;
        __userOrderRecord[__userAddress].roundGame = block.timestamp - (block.timestamp % roundGamePeriod);
    
        __userWalletList[__userAddress][_tokenAddress].totalDeposit += __amount;
        
        // emit createOrderEvent(__userAddress, __symbol, address(0), __positionSide, __amount, __entryPrice, block.timestamp);
        // return (__symbol, _tokenAddress, currentRoundGame, __positionSide, __entryPrice, __amount, block.timestamp);
    }
    

    function withdrawWallet() public playerMustExist { //
        uint poolMainBalance = getPoolMainBalance();
        require(poolMainBalance > __userWallet[msg.sender].balance, "Pool Insufficient");
        require(msg.sender.send(__userWallet[msg.sender].balance));
        __userWallet[msg.sender].totalWithdraw += __userWallet[msg.sender].balance;
        __userWallet[msg.sender].balance = 0 ;
        for(uint i=0;i<availableTokenList.length;i++){
            require(ERC20(availableTokenList[i]).transfer(msg.sender,  __userWalletList[msg.sender][availableTokenList[i]].balance), 'Fail withdraw token');
            __userWalletList[msg.sender][availableTokenList[i]].totalWithdraw += __userWalletList[msg.sender][availableTokenList[i]].balance;
            __userWalletList[msg.sender][availableTokenList[i]].balance = 0;
        }
    }
    
    function compareStrings(string memory a, string memory b) internal view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}