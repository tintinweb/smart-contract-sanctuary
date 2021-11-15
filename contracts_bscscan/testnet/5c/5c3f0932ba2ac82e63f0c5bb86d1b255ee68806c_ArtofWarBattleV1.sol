// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./IERC20.sol";
import "./safeMath.sol";
import "./AOWBattle.sol";

contract ArtofWarBattleV1 is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;

    bytes32 public constant GAMEOWNER_ROLE = keccak256("GAMEOWNER_ROLE");

    uint256 private randNonce;

    address public _game_owner;
    address public _token_AOW;
    address public _token_nft;

    uint private _divider_bnb;

    bool public levelWinner;

    bool public gameStatus;
    bool public statusGameAOW;
    bool public statusGameBNB;
    
    uint256 public poolCounter;
    uint public minPoolPlayers;
    uint public maxPoolPlayers;
    uint public minimumLevelForPlay;
    uint public returnDaysNFT;

    struct GameInfo {
        uint256 nftID;
        address user;
        uint256 pool;
        bool lose;
    }

    struct POOLS {
        bool status;
        bool finished;
        address[] players;
        uint256 total_players;
        uint256 max_players;
        uint8 rarityMin;
        uint8 rarityMax;
        uint256 levelMin;
        uint256 levelMax;
        uint8 type_war;
        bool auto_play;
        uint time_start;
        uint time_end;
    }
    
    struct currentPool{
        uint[] active;
        uint[] finished;
    }

    struct statDuels{
        bool win;
        uint256 my_nftID;
        uint256 war_nftID;
        address war_address;
        uint8 type_war;
    }

    mapping (uint256 => POOLS) public poolsGame;
    mapping (uint256 => mapping(address => GameInfo)) public game;
    mapping (uint8 => currentPool) private gamePoolStatus;
    mapping (address => mapping(uint256 => statDuels)) public gameDuelStatistic;
    mapping (uint8 => mapping(address => uint256[])) private poolsGameDuelsUser;
    mapping (string => uint[]) private levelFeeToPlayGame;
    mapping (uint => uint) private gainRarity;
    
    modifier gameStart() {
        require(gameStatus, "Game disabled");
        _;
    }

    function initialize(address _owner) initializer public {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GAMEOWNER_ROLE, _owner);

        _game_owner = _owner;

        randNonce = 0;
        _divider_bnb = 10000000000000000;
        levelWinner = true;
        gameStatus = true; // CHANGE
        statusGameAOW = false;
        statusGameBNB = true; // CHANGE
    
        poolCounter = 0;
        minPoolPlayers = 2;
        maxPoolPlayers = 2;
        minimumLevelForPlay = 2;
        returnDaysNFT = 3;

        levelFeeToPlayGame["BNB"].push(3000000000000000); // 0.003 BNB
        levelFeeToPlayGame["BNB"].push(7000000000000000); // 0.007 BNB
        levelFeeToPlayGame["BNB"].push(10000000000000000); // 0.01 BNB
        levelFeeToPlayGame["BNB"].push(17000000000000000); // 0.017 BNB
        
        levelFeeToPlayGame["AOW"].push(400000000000);
        levelFeeToPlayGame["AOW"].push(450000000000);
        levelFeeToPlayGame["AOW"].push(500000000000);
        levelFeeToPlayGame["AOW"].push(600000000000);

        gainRarity[1] = 0;
        gainRarity[2] = 2;
        gainRarity[3] = 4;
        gainRarity[4] = 6;
        gainRarity[5] = 8;
        gainRarity[6] = 10;
        gainRarity[7] = 50;
        
        // only Enforcer 2-10 2-5 5-12
        startPoolAuto(2, 1, 1, 2, 10, 0);
        startPoolAuto(2, 1, 1, 2, 10, 1);

        startPoolAuto(2, 1, 1, 2, 5, 0);
        startPoolAuto(2, 1, 1, 2, 5, 1);
        
        startPoolAuto(2, 1, 1, 5, 12, 0);
        startPoolAuto(2, 1, 1, 5, 12, 1);

        startPoolAuto(2, 1, 1, 2, 10, 0);
        startPoolAuto(2, 1, 1, 2, 10, 1);

        startPoolAuto(2, 1, 1, 2, 5, 0);
        startPoolAuto(2, 1, 1, 2, 5, 1);
        
        startPoolAuto(2, 1, 1, 5, 12, 0);
        startPoolAuto(2, 1, 1, 5, 12, 1);
        
        // only Enforcer  20-40 level
        startPoolAuto(2, 1, 1, 20, 40, 0);
        startPoolAuto(2, 1, 1, 20, 40, 1);

        startPoolAuto(2, 1, 1, 15, 35, 0);
        startPoolAuto(2, 1, 1, 15, 35, 1);

        startPoolAuto(2, 1, 1, 18, 30, 0);
        startPoolAuto(2, 1, 1, 18, 30, 1);

        startPoolAuto(2, 1, 1, 20, 30, 0);
        startPoolAuto(2, 1, 1, 20, 30, 1);

        startPoolAuto(2, 1, 1, 25, 30, 0);
        startPoolAuto(2, 1, 1, 25, 30, 1);

        startPoolAuto(2, 1, 1, 20, 40, 0);
        startPoolAuto(2, 1, 1, 20, 40, 1);

        // Enforcer-Guradian  2-20 level
        startPoolAuto(2, 1, 2, 2, 20, 0);
        startPoolAuto(2, 1, 2, 2, 20, 1);

        // Enforcer-Elite 10-30 level
        startPoolAuto(2, 1, 3, 10, 30, 0);
        startPoolAuto(2, 1, 3, 10, 30, 1);

        // Elite-Legendary 50-120 Level
        startPoolAuto(2, 3, 4, 50, 120, 0);
        startPoolAuto(2, 3, 4, 50, 120, 1);

        // Legendary-Divine 2-10
        startPoolAuto(2, 4, 6, 2, 10, 0);
        startPoolAuto(2, 4, 6, 2, 10, 1);
        
    }
    
    /*
    * SET METHODS
    */

    function setTokenAOW(address _addr_AOW) public onlyRole(GAMEOWNER_ROLE) {
        _token_AOW = _addr_AOW;
    }

    function setTokenNFT(address _addr_nft) public onlyRole(GAMEOWNER_ROLE) {
        _token_nft = _addr_nft;
    }

    function setGameStatus(bool _status) public onlyRole(GAMEOWNER_ROLE) {
        gameStatus = _status;
    }

    /*
    * CHANGE METHODS
    */
    function changeActivePool(uint _pool, bool _status) public onlyRole(GAMEOWNER_ROLE) {
        poolsGame[_pool].status = _status;
    }

    function changeGainRariry(uint _key, uint256 _value) public onlyRole(GAMEOWNER_ROLE) {
        gainRarity[_key] = _value;
    }

    function changeMaxPoolPlayers(uint _maxPoolPlayers) public onlyRole(GAMEOWNER_ROLE) {
        maxPoolPlayers = _maxPoolPlayers;
    }

    function changeMinimumLevelForPlay(uint _minimumLevelForPlay) public onlyRole(GAMEOWNER_ROLE) {
        minimumLevelForPlay = _minimumLevelForPlay;
    }

    function changeReturnDaysNFT(uint _returnDaysNFT) public onlyRole(GAMEOWNER_ROLE) {
        returnDaysNFT = _returnDaysNFT;
    }

    function changeFeeAOWGame(uint256 _one, uint256 _two, uint256 _three, uint256 _four) public onlyRole(GAMEOWNER_ROLE) {
        levelFeeToPlayGame["AOW"][0] = _one;
        levelFeeToPlayGame["AOW"][1] = _two;
        levelFeeToPlayGame["AOW"][2] = _three;
        levelFeeToPlayGame["AOW"][3] = _four;
    }

    function changeFeeBNBGame(uint256 _one, uint256 _two, uint256 _three, uint256 _four) public onlyRole(GAMEOWNER_ROLE) {
        levelFeeToPlayGame["BNB"][0] = _one;
        levelFeeToPlayGame["BNB"][1] = _two;
        levelFeeToPlayGame["BNB"][2] = _three;
        levelFeeToPlayGame["BNB"][3] = _four;
    }

    function changeStatusFeeBNB(bool _status) public onlyRole(GAMEOWNER_ROLE) {
        statusGameBNB = _status;
    }

    function changeStatusFeeAOW(bool _status) public onlyRole(GAMEOWNER_ROLE) {
        statusGameAOW = _status;
    }

    function changePoolAuto(uint256 _pool, bool _auto) public onlyRole(GAMEOWNER_ROLE) {
        poolsGame[_pool].auto_play = _auto;
    }
    
    function changeBasicPool(uint256 _pool, uint256 _max_players, uint8 _rarityMin, uint8 _rarityMax, uint256 _levelMin, uint256 _levelMax, bool _auto, uint8 _type_war, bool finished) public onlyRole(GAMEOWNER_ROLE) {
        poolsGame[_pool].max_players = _max_players;
        poolsGame[_pool].rarityMin = _rarityMin;
        poolsGame[_pool].rarityMax = _rarityMax;
        poolsGame[_pool].levelMin = _levelMin;
        poolsGame[_pool].levelMax = _levelMax;
        poolsGame[_pool].auto_play = _auto;
        poolsGame[_pool].type_war = _type_war;
        poolsGame[_pool].finished = finished;
    }
    
    /* GAME */
    
    function checkReturnNFT(uint _pool) public view returns(bool) {
        require(poolsGame[_pool].total_players < poolsGame[_pool].max_players, "Game started");
        require(poolsGame[_pool].status == true, "Closed pool");
        require(block.timestamp >= (poolsGame[_pool].time_start + returnDaysNFT * 1 days), "Error time return");

        address returnAddressPlayer = poolsGame[_pool].players[0];
        require(returnAddressPlayer == _msgSender(), "No owner NFT");

        return true;
    }

    function random(address oneCardPlayer, address twoCardPlayer, uint indexOne, uint indexTwo, uint256 _pool) private returns(uint winner, uint loser) {
        //addr1, addr2, 0, 1, 1
        (, uint256 levelOne, , , uint8 _typeOne, ) = AOWBattle(_token_nft).getFullNFTInfo(game[_pool][oneCardPlayer].nftID);
        (, uint256 levelTwo, , , uint8 _typeTwo, ) = AOWBattle(_token_nft).getFullNFTInfo(game[_pool][twoCardPlayer].nftID);
        
        levelOne = levelOne.add(gainRarity[_typeOne]);
        levelTwo = levelTwo.add(gainRarity[_typeTwo]);
        
        uint _min = 1;
        uint _max = levelOne + levelTwo;

        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce))) % _max;
        randomnumber = randomnumber + _min;
        randNonce++;
        // 
        if (randomnumber >= _min &&  randomnumber < levelOne.add(1)){
            return (indexOne, indexTwo);
        }

        if (randomnumber > levelOne){
            return (indexTwo, indexOne);
        }

        revert("error random winner");
    }

    function getTotalPlayersInPool(uint256 _pool) public view returns(uint256){
        return poolsGame[_pool].total_players;
    }

    function getTypePool(uint256 _pool) public view returns(uint8){
        return poolsGame[_pool].type_war;
    }

    function getInfoPlayersByPool(uint256 _pool) public view returns (address[] memory players) {
        return poolsGame[_pool].players;
    }

    function getActivePoolByType(uint8 _type_war) external view returns(uint256[] memory pools){
        return gamePoolStatus[_type_war].active;
    }

    function getEndPoolByType(uint8 _type_war) external view returns(uint256[] memory pools){
        return gamePoolStatus[_type_war].finished;
    }

    function getUserNFTIDinGamePool(uint256 _pool, address _player) external view returns(uint256){
        return game[_pool][_player].nftID;
    }
    
    function getAllPoolPlayer(uint8 type_war, address _player) external view returns(uint256[] memory pools){
        return poolsGameDuelsUser[type_war][_player];
    }

    /*
    * @type_war
    * 0 - level war
    * 1 - card war
    */
    
    function startPool(uint256 _max_players, uint8 _rarityMin, uint8 _rarityMax, uint256 _levelMin, uint256 _levelMax, bool _auto, uint8 _type_war) public onlyRole(GAMEOWNER_ROLE) {
        require(_max_players >= minPoolPlayers, "Error min players");
        require(_max_players <= maxPoolPlayers, "Error max players");
        
        uint256 _pool = poolCounter.add(1);
        poolCounter = _pool;

        gamePoolStatus[_type_war].active.push(_pool);

        poolsGame[_pool].status = true;
        poolsGame[_pool].finished = false;
        poolsGame[_pool].max_players = _max_players;
        poolsGame[_pool].total_players = 0;
        poolsGame[_pool].rarityMin = _rarityMin;
        poolsGame[_pool].rarityMax = _rarityMax;
        poolsGame[_pool].levelMin = _levelMin;
        poolsGame[_pool].levelMax = _levelMax;
        poolsGame[_pool].auto_play = _auto;
        poolsGame[_pool].type_war = _type_war;
        poolsGame[_pool].time_start = block.timestamp;
    }

    function startPoolAuto(uint256 _max_players, uint8 _rarityMin, uint8 _rarityMax, uint256 _levelMin, uint256 _levelMax, uint8 _type_war) private {
        require(_max_players >= minPoolPlayers, "Error min players");
        require(_max_players <= maxPoolPlayers, "Error max players");

        uint256 _pool = poolCounter.add(1);
        poolCounter = _pool;

        gamePoolStatus[_type_war].active.push(_pool);

        poolsGame[_pool].status = true;
        poolsGame[_pool].finished = false;
        poolsGame[_pool].max_players = _max_players;
        poolsGame[_pool].total_players = 0;
        poolsGame[_pool].rarityMin = _rarityMin;
        poolsGame[_pool].rarityMax = _rarityMax;
        poolsGame[_pool].levelMin = _levelMin;
        poolsGame[_pool].levelMax = _levelMax;
        poolsGame[_pool].auto_play = true;
        poolsGame[_pool].type_war = _type_war;
        poolsGame[_pool].time_start = block.timestamp;
    }

    function getFeeLevel(uint256 level, string memory type_fee) private view returns(uint){
        uint feeGame = 500000000000;

        if (level <= 100){
            feeGame = levelFeeToPlayGame[type_fee][0];
        }

        if (level > 100 && level <= 300){
            feeGame = levelFeeToPlayGame[type_fee][1];
        }

        if (level > 300 && level <= 500){
            feeGame = levelFeeToPlayGame[type_fee][2];
        }

        if (level > 500){
            feeGame = levelFeeToPlayGame[type_fee][3];
        }
        
        return feeGame;
    }

    function returnNFTFromEmptyPool(uint _pool) public {
        require(poolsGame[_pool].total_players < poolsGame[_pool].max_players, "Game started");
        require(poolsGame[_pool].status == true, "Closed pool");
        require(block.timestamp >= (poolsGame[_pool].time_start + returnDaysNFT * 1 days), "Error time return");
        
        poolsGame[_pool].status = false;

        address returnAddressPlayer = poolsGame[_pool].players[0];
        
        uint nft_id = game[_pool][returnAddressPlayer].nftID;

        AOWBattle(_token_nft).setStatusNFTAuto(nft_id, true);
    }

    function sendNFTToGamePoolAOWFee(uint256 _nftID, uint256 _pool) public payable gameStart {
        (, uint256 level, , , , bool statusNFT) = AOWBattle(_token_nft).getFullNFTInfo(_nftID);
        (address ownerNFT) = AOWBattle(_token_nft).getNFTOwner(_nftID);

        require(statusGameAOW, "Disabled AOW Fee");
        require(ownerNFT == _msgSender(), "Error owner NFT!");
        require(poolsGame[_pool].status == true, "Closed pool, start game!");
        require(statusNFT == true, "NFT disabled");
        require(game[_pool][_msgSender()].user != _msgSender(), "1 GAME = 1 NFT");
        require(level >= minimumLevelForPlay, "Error minimum level");

        uint feeGame = getFeeLevel(level, "AOW");

        if (poolsGame[_pool].total_players < poolsGame[_pool].max_players){
            // fee play game
            IERC20Standard(_token_AOW).transferFrom(_msgSender(), address(this), feeGame);
            
            poolsGame[_pool].players.push(_msgSender());

            game[_pool][_msgSender()].nftID = _nftID;
            game[_pool][_msgSender()].user = _msgSender();
            game[_pool][_msgSender()].pool = _pool;

            poolsGame[_pool].total_players = poolsGame[_pool].total_players.add(1);
            poolsGameDuelsUser[poolsGame[_pool].type_war][_msgSender()].push(_pool);

            AOWBattle(_token_nft).setStatusNFTAuto(_nftID, false);

        } else revert("Error limit Pool");
    }

    function sendNFTToGamePoolBNBFee(uint256 _nftID, uint256 _pool) public payable gameStart {
        (, uint256 level, , , , bool statusNFT) = AOWBattle(_token_nft).getFullNFTInfo(_nftID);
        (address ownerNFT) = AOWBattle(_token_nft).getNFTOwner(_nftID);

        require(statusGameBNB, "Disabled BNB Fee");
        require(ownerNFT == _msgSender(), "Error owner NFT");
        require(poolsGame[_pool].status == true, "Closed pool, start game");
        require(statusNFT == true, "NFT disabled");
        require(game[_pool][_msgSender()].user != _msgSender(), "1 GAME = 1 NFT");
        require(level >= minimumLevelForPlay, "Error minimum level");

        uint feeGame = getFeeLevel(level, "BNB");
        
        require(msg.value >= feeGame, "Error pay fee");

        if (poolsGame[_pool].total_players < poolsGame[_pool].max_players){
            // fee play game
            address toBNBAddress = _game_owner;
            contractBNBAmountSend(payable(toBNBAddress), feeGame);
            
            poolsGame[_pool].players.push(_msgSender());

            game[_pool][_msgSender()].nftID = _nftID;
            game[_pool][_msgSender()].user = _msgSender();
            game[_pool][_msgSender()].pool = _pool;

            poolsGame[_pool].total_players = poolsGame[_pool].total_players.add(1);
            poolsGameDuelsUser[poolsGame[_pool].type_war][_msgSender()].push(_pool);

            AOWBattle(_token_nft).setStatusNFTAuto(_nftID, false);

        } else revert("Error limit Pool");   
    }

    function gameToPlay(uint256 _pool) public onlyRole(GAMEOWNER_ROLE) {
        require(poolsGame[_pool].finished == false, "Error: finished arena");
        
        address winner_address;
        address loser_address;
                
        (uint winner_index, uint loser_index) = random(poolsGame[_pool].players[0], poolsGame[_pool].players[1], 0, 1, _pool);
            
        // level war
        if (poolsGame[_pool].type_war == 0) {
            winner_address = poolsGame[_pool].players[winner_index];
            loser_address = poolsGame[_pool].players[loser_index];
            
            uint nft_winner_id = game[_pool][winner_address].nftID;
            uint nft_loser_id = game[_pool][loser_address].nftID;
            
            AOWBattle(_token_nft).upLevelGame(nft_winner_id);
            AOWBattle(_token_nft).downLevelGame(nft_loser_id);
        }
        
        // card war
        if (poolsGame[_pool].type_war == 1) {
            winner_address = poolsGame[_pool].players[winner_index];
            loser_address = poolsGame[_pool].players[loser_index];
            
            if (levelWinner){
                uint nft_winner_id = game[_pool][winner_address].nftID;            
                uint nft_loser_id = game[_pool][loser_address].nftID;
                
                AOWBattle(_token_nft).upLevelGame(nft_winner_id);
                AOWBattle(_token_nft).downLevelGame(nft_loser_id);
            }
        }

        sendNFTWinner(_pool, winner_address, game[_pool][winner_address].nftID, loser_address, game[_pool][loser_address].nftID);
    }

    function deleteActivePool(uint8 _type_war, uint256 _pool) private {
        uint256 lenghtActivePools = gamePoolStatus[_type_war].active.length - 1;
        uint256 index;
        for (uint256 i = 0; i < lenghtActivePools; i++){
            if (gamePoolStatus[_type_war].active[i] == _pool){
                index = i;
                break;
            }
        }
        
        gamePoolStatus[_type_war].active[index] = gamePoolStatus[_type_war].active[gamePoolStatus[_type_war].active.length - 1];
        gamePoolStatus[_type_war].active.pop();
        gamePoolStatus[_type_war].finished.push(_pool);
    }

    function sendNFTWinner(uint256 _pool, address _winner, uint256 _winnerNFTID, address _loser, uint256 _loserNFTID) private {        
        uint8 _type_war = poolsGame[_pool].type_war;
        // winner add stat
        AOWBattle(_token_nft).upWinPool(_winnerNFTID);
        
        // loser add stat and change owner
        AOWBattle(_token_nft).downWinPool(_loserNFTID);
		
		// enabled NFT players
		AOWBattle(_token_nft).setStatusNFTAuto(_winnerNFTID, true);
		AOWBattle(_token_nft).setStatusNFTAuto(_loserNFTID, true);
        
        // NFT game lose
        game[_pool][_loser].lose = true;

        // end game
        poolsGame[_pool].status = false;
        poolsGame[_pool].finished = true;
        poolsGame[_pool].time_end = block.timestamp;

        // del active pool
        deleteActivePool(_type_war, _pool);

        // add statistic game
        gameDuelStatistic[_winner][_pool] = statDuels(true, game[_pool][_winner].nftID, game[_pool][_loser].nftID, _loser, _type_war);
        gameDuelStatistic[_loser][_pool] = statDuels(false, game[_pool][_loser].nftID, game[_pool][_winner].nftID, _winner, _type_war);

        if (_type_war == 1){

            AOWBattle(_token_nft).changeOwnerNFT(_loserNFTID, _winner);
            AOWBattle(_token_nft).delAndPushNewOwnerNFT(game[_pool][_loser].nftID, _loser, _winner);
            
            // enabled and transfer winner NFT
            //AOWBattle(_token_nft).transferGame(game[_pool][_winner].nftID, game[_pool][_loser].nftID, _loser, _winner, game[_pool][_loser].nftID);
        }

        // new auto pool
        if (poolsGame[_pool].auto_play){
            startPoolAuto(poolsGame[_pool].max_players, poolsGame[_pool].rarityMin, poolsGame[_pool].rarityMax, poolsGame[_pool].levelMin, poolsGame[_pool].levelMax, poolsGame[_pool].type_war);
        }
    }
    
    function getComissionGame(string memory _type) public view returns (uint256[] memory){
        return levelFeeToPlayGame[_type]; // AOW or BNB
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function claimContractBNBBalance(address payable _to) public payable onlyRole(GAMEOWNER_ROLE) {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send BNB");
    }

    function claimContractBNBAmountBalance(address payable _to, uint256 _amount) public payable onlyRole(GAMEOWNER_ROLE) {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send BNB");
    }
    
    function contractBNBAmountSend(address payable _to, uint256 _amount) private {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send BNB");
    }
    
    receive() external payable {}

    fallback() external payable {}

    function transferToMe(address _token, address _owner, uint _amount) public payable onlyRole(GAMEOWNER_ROLE) {
        IERC20Standard(_token).transfer(_owner, _amount);
    }

    function getBalanceOfToken(address _address) public view returns (uint) {
        return IERC20Standard(_address).balanceOf(address(this));
    }
    
    /*function test() public view returns(bool){
        return true;
    }*/
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IERC20Standard {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface AOWBattle {

    function getAllNFTIdAddress(address _player) external view returns(uint256[] memory ids);

    function getNFTOwner(uint256 _nftID) external view returns (address);

    function getLastTokenID() external view returns (uint256);

    function getLastBuyCount() external view returns (uint256);

    function getFullNFTInfo(uint256 _nftID) external view returns (uint256 id, uint256 level, uint256 win, uint256 lose, uint8 _type, bool enabled);
    
    function getStatNFTInfo(uint256 _nftID) external view returns (uint256 id, uint256 totalTransfers);

    function getPrice(uint256 _nftID) external view returns (uint256, uint256);
    
    function getStatusNFT(uint256 _nftID) external view returns (bool);

    /*
    * GAME METHODS
    */

    function upLevelGame(uint256 _id) external;

    function downLevelGame(uint256 _id) external;

    function upWinPool(uint256 _id) external;

    function downWinPool(uint256 _id) external;
    
    function changeOwnerNFT(uint256 _id, address _newOwner) external;

    function delAndPushNewOwnerNFT(uint256 _nftID, address _sender, address _newOwner) external;

    function setStatusNFTAuto(uint256 _nftID, bool _status) external;
    
    function transferGame(uint256 _nftIDWinner, uint256 _nftIDLoser, address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

