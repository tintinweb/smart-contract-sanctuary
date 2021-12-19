// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '../interfaces/IBlockmineVRF.sol';

contract GunsCowboy is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    // global information
    IBlockmineVRF public vrf;
    address payable public gameTreasury;
    uint256 public fee;
    uint256 public gameFee;
    uint256 public blocksPerTournament;
    uint256 public rndActive = 1; // randomizer requests are collected until there are 10.
    uint256 public rndNext = 1; // next rnd to be handled
    IBEP20 public nugget;
    IBEP20 public goldcoin;
    IBEP20 public goldbar;
    address public sustainabilityContract;
    uint256 public burnDivisor;
    uint256 public minRequestors;
    uint256 private DECIMALS_NUGGET_RATIO = 1e12;
    uint256 private DECIMALS_STD = 1e1;
    uint256 public gameId = 1;
    uint256 public queueId = 0;
    uint256 public tournamentId = 0;
    uint256 public playerId = 1;
    uint256 public burnedNuggets;
    
        // events
    event EmitVRF(address indexed vrf);
    event EmitFee(uint256 newFee);
    event EmitGameFee(uint256 min);
    event EmitBurnDivisor(uint256 newBurnDivisor);
    event EmitMinRequestors(uint256 minRequestors);
    event EmitSusChanged(address _new);
    event EmitInvalid(string waiting);
    event EmitGameOpen(address indexed player);
    event EmitShoot(address indexed player, uint256 damage, address indexed opponent, uint256 health);
    event EmitBattle(address indexed player, address indexed opponent);
    event EmitTreasury(address indexed treasury);
    event EmitTournamentLength(uint256 tournamentLength);
    event EmitPayout(uint256 payoutGC, uint256 payoutGB);
    
    
    // token address information
    enum TOKEN {GC, GB}
    enum GAMESTATE {LOCKED, READY, LOADING, WON, LOST}
    
       struct RANK {
        address _address;
        uint256 _xp;
    }

    struct GAME {
        uint256 health;
        uint256 gameId;
        uint256 queueId;
        uint256 tournamentId;
        uint256 rndAwaiting;
        GAMESTATE gameState;
        address opponent;
    }
    
   struct POWER {
        uint256 playerId;
        uint256 tournamentId;
        uint256 health; // factor 1e1
        uint256 damage; // factor 1e1
        uint256 defense; // factor 1e1; max 500
        uint256 accuracy; // factor 1e2; max 900
    }
    
   struct STATS {
        uint256 playedGames;
        uint256 wonGames;
        uint256 lostGames;
        uint256 xp;
    }
    
   struct TOURNAMENT {
        uint256 id;
        bool finished;
        bool claimed;
        uint256 startBlock;
        uint256 endBLock;
        uint256 prizeGC;
        uint256 prizeGB;
        address leaderAddr;
        uint256 leaderPoints;
    }
    
    mapping (TOKEN => IBEP20) public tokens;
    // information w.r.t. rnd requests (array used since number of entries is limited per array (10 - 20)
    //mapping (uint256 => address[]) public rndRequestorsMap; // stores rnd requestor addresses
    mapping (uint256 => uint256) public rndRndIdsRequestorQueue; // maps rnd ids to number of requestors
    mapping(uint256 => bytes32) public rndRndIdsRequestIds; // link rnd ids to request ids
    // mapping(uint256 => uint256) public rndRndIdsReceived; // link rnd ids to recived numbers
    mapping (address => uint256) public gameIndex; // game index starts with 1 (0 = no game assigned)
    mapping (address => mapping(uint256 => GAME)) public games;  // maps address to games of player
    mapping(uint256 => TOURNAMENT) public tournaments;  // maps tournament id to tournament
    mapping (address => POWER) public powers; // maps address to current power
    mapping (address => STATS) public stats; // maps address to current stats
    mapping (uint256 => address) public players; // used to enumerate players.
    mapping (address => uint256) public ranks; // used to store total rank of players (overall, not just current tournament).
    mapping (uint256 => address) public playerQueue; // used to queue up players.
    
    constructor (IBlockmineVRF _vrf, IBEP20 _nugget, IBEP20 _gc, IBEP20 _gb, address _sustainabilityContract, address payable _gameTreasury) public {
        updateVRF(_vrf);
        updateFee(1 * 10 ** 15 / 100); // 0.002 BNB needed for LINK costs
        updateGameFee(1e16);
        updateBurnDivisor(10);
        updateMinRequestors(1); // ToDO modify
        updateTournamentLength(500);
        nugget = _nugget; // nuggget token
        goldcoin = _gc; // goldcoin token
        goldbar = _gb; // gold bar token
        tokens[TOKEN.GC] = _gc;
        tokens[TOKEN.GB] = _gb;
        sustainabilityContract = _sustainabilityContract;
        gameTreasury = _gameTreasury;
        
    }
    
    function updateVRF(IBlockmineVRF _vrf) public {
        vrf = _vrf;
        emit EmitVRF(address(_vrf));
    }
    
    function updateFee(uint256 _fee) public onlyOwner  {
        require(fee <= 1e16, "don't steal from people");
        fee = _fee;
        emit EmitFee(_fee);
    }
    
    function updateGameFee(uint256 _fee) public onlyOwner  {
        require(gameFee <= 1e16, "don't steal from people");
        gameFee = _fee;
        emit EmitGameFee(_fee);
    }   
    
    function updateBurnDivisor(uint256 _burnDivisor) public onlyOwner  {
        require(_burnDivisor != 0, "burn divisor cannot be 0");
        burnDivisor = _burnDivisor;
        emit EmitBurnDivisor(_burnDivisor);
    }    
    
        // Update treasury address by the previous dev.
    function updateTreasury(address payable _gameTreasury) external {
        require(msg.sender == gameTreasury, "treasury: wut?");
        gameTreasury = _gameTreasury;
        emit EmitTreasury(_gameTreasury);
    }
    
    function updateMinRequestors(uint256 _minRequestors) public onlyOwner  {
        require(_minRequestors != 0, "cannot be 0");
        minRequestors = _minRequestors;
        emit EmitMinRequestors(_minRequestors);
    }
        // Update sustainability contract. Old funds are locked in the old contract for security reasons
    function updateSustainabilitContract(address _sustainabilityContract) public onlyOwner {
        sustainabilityContract = _sustainabilityContract;
        emit EmitSusChanged(_sustainabilityContract);
    }
        // Update sustainability contract. Old funds are locked in the old contract for security reasons
    function updateTournamentLength(uint256 _blocksPerTournament) public onlyOwner {
        blocksPerTournament = _blocksPerTournament;
        emit EmitTournamentLength(_blocksPerTournament);
    }
    
    function getActiveRequestors() public view returns (uint256){
        return rndRndIdsRequestorQueue[rndActive];
    }
    
    function calculateNuggetRatio() public view returns(uint256) {
        // TODO: do good calcuation
        // TODO: don't forget to sub dead nuggets/goldcoins
        uint256 nuggetSupply = nugget.totalSupply().sub(nugget.balanceOf(0x000000000000000000000000000000000000dEaD)); // more than gold? maybe 1000
        uint256 goldcoinSupply = goldcoin.totalSupply().sub(goldcoin.balanceOf(0x000000000000000000000000000000000000dEaD)); // maybe 10 ->
        uint256 ratio = nuggetSupply.mul(DECIMALS_NUGGET_RATIO).div(goldcoinSupply); // then 100?
        // require 10% of that ratio
        return ratio.div(burnDivisor); // so burn 10 nuggetwei per goldcoinwei (for this example)?
    }
    
    function isGunLoaded(address player) public view returns (bool) {
        GAME storage game = games[player][gameIndex[player]];
        bytes32 requestId = rndRndIdsRequestIds[game.rndAwaiting];
        return vrf.isCallback(requestId);
    }
    
   function hasOpponent(address player) public view returns (bool) {
        GAME storage game = games[player][gameIndex[player]];
        return game.opponent != address(0);
    }
    
    function hasWon(address player) public view returns (bool) {
        GAME storage game = games[player][gameIndex[player]];
        TOURNAMENT storage _tournament = tournaments[game.tournamentId];
        return _tournament.leaderAddr == player && _tournament.finished;
    }
    
    function isQueueValid() public view returns (bool) {
        return queueId > 1;
    }
    
    function isTurn(address player) public view returns (bool) {
        GAME storage game = games[player][gameIndex[player]];
        return game.gameState == GAMESTATE.READY;
    }
    
    function isOpponentTurn(address player) public view returns (bool) {
        GAME storage game = games[player][gameIndex[player]];
        GAME storage gameOpponent = games[game.opponent][gameIndex[game.opponent]];
        return gameOpponent.gameState == GAMESTATE.READY;
    }
    
    function canOpenGame(address player) public view returns (bool){
        GAME storage game = games[player][gameIndex[player]];
        // if last tournament is over, a new game can be started
        return game.gameState == GAMESTATE.WON || game.gameState == GAMESTATE.LOST || game.tournamentId != tournamentId || game.tournamentId == 0;
        
    }
    
    function exitGame() public {
        GAME storage game = games[msg.sender][gameIndex[msg.sender]];
        GAME storage gameOpponent = games[game.opponent][gameIndex[game.opponent]];
        // if last tournament is over, a new game can be started
        game.gameState = GAMESTATE.LOST;
        gameOpponent.gameState = GAMESTATE.WON;
    }
    
    function payout() public {
        if (hasWon(msg.sender)){
            GAME storage game = games[msg.sender][gameIndex[msg.sender]];
            TOURNAMENT storage _tournament = tournaments[game.tournamentId];
            if (!_tournament.claimed) {
                goldcoin.safeTransfer(msg.sender, _tournament.prizeGC);
                goldbar.safeTransfer(msg.sender, _tournament.prizeGB);
                _tournament.claimed = true;
                emit EmitPayout(_tournament.prizeGC, _tournament.prizeGB);
            }
        }
    }

    function hasOpenXP (address user) external view returns (bool){
        STATS storage _stats = stats[user];
        POWER storage _power = powers[msg.sender];
        uint256 sum; 
        sum = sum.add(_power.health);
        sum = sum.add(_power.damage);
        sum = sum.add(_power.accuracy);
        sum = sum.add(_power.defense);
        // aquired xp minus base values;
        if (sum >= 900)
            return _stats.xp > sum.sub(900);
        return false;        
    }

    function setStats(uint256 health, uint256 damage, uint256 accuracy, uint256 defense) external {
        STATS storage _stats = stats[msg.sender];
        POWER storage _power = powers[msg.sender];
        require(health.add(damage).add(accuracy).add(defense) <= _stats.xp, "set: you do not have that much xp");
        _power.health = health.add(500);
        _power.accuracy = accuracy.add(300);
        _power.damage = damage.add(100);
        _power.defense = defense;
        require(_power.accuracy <= 1000 && _power.defense <= 500, "set: max accuracy 1000, max defense 500 (50%)");
    }
	
	function getRank() external view returns (RANK[] memory) {
        // external view function to load all rank information from contract at once instead of calling the contract n times
        // no gas fees on this function
        if (playerId == 1)
            return new RANK[](0);
        // init array
        RANK[] memory _ranks = new RANK[](playerId - 1);
        uint256 counter = 0;
        for (uint i = 1; i < playerId; i++) {
            address _address = players[i];
            // check last played game (within tournament) and only return active players' ranks
            if (games[_address][gameIndex[_address]].tournamentId == tournamentId) {
                uint256 _xp = ranks[_address];
                _ranks[counter] = RANK({
                    _address: _address,
                    _xp: _xp
                });
                // update counter
                counter = counter.add(1);
            }
        }
        return _ranks;
    }
    
    // shoot function -> can only shoot if both playes have shot and rnd shoot number has been received. 
    function shoot() public {
        GAME storage game = games[msg.sender][gameIndex[msg.sender]];
        STATS storage _stats = stats[msg.sender];
        POWER storage _power = powers[msg.sender];
        GAME storage gameOpponent = games[game.opponent][gameIndex[game.opponent]];
        STATS storage statsOpponent = stats[game.opponent];
        POWER storage powerOpponent = powers[game.opponent];
        TOURNAMENT storage _tournament = tournaments[game.tournamentId];
        if (_tournament.endBLock < block.number){
            // old tournament
            _tournament.finished = true;
            // not counted towards lost games
            gameOpponent.gameState = GAMESTATE.LOST;
            game.gameState = GAMESTATE.LOST;
            // end shoot
            return;
        }
        // require state ready (gun is loaded)
        require (game.gameState == GAMESTATE.READY, "shoot: you can only shoot once");
        require (isGunLoaded(msg.sender), "shoot: you need a loaded gun. The heck are you doing?");
        require (hasOpponent(msg.sender), "shoot: you need an opponent you can shoot.");
        // handle game play
        // compute damage
        // get individual random number
        bytes32 requestId = rndRndIdsRequestIds[game.rndAwaiting];
        uint256 number = vrf.getRequest(requestId);
        // uint256 number = rndRndIdsReceived[game.rndAwaiting];
        // compute random number in percent (1 - 100)
        uint256 _number = 1 + uint256(keccak256(abi.encode(number, game.gameId, game.health, gameOpponent.health, _stats.xp, block.timestamp))) % 1000;
        // compute damage
        uint256 damage; 
        if (_power.accuracy > _number) {
            uint256 health = gameOpponent.health;
            uint256 damageDefended = _power.damage.mul(powerOpponent.defense).div(1000);
            damage = _power.damage.sub(damageDefended);
            if (damage <= health){
                gameOpponent.health = gameOpponent.health.sub(_power.damage);
                _stats.xp = _stats.xp.add(4); 
            }
            else{
                _stats.xp = _stats.xp.add(4);
				if (statsOpponent.xp > _stats.xp) {
					_stats.xp = _stats.xp.add(statsOpponent.xp.sub(_stats.xp).div(3));
				}
				// setting rank list
				ranks[msg.sender] = _stats.xp;
                gameOpponent.health = 0;
                // set stats
                gameOpponent.gameState = GAMESTATE.LOST;
                game.gameState = GAMESTATE.WON;
                _stats.playedGames = _stats.playedGames.add(1);
                statsOpponent.playedGames = statsOpponent.playedGames.add(1);
                _stats.wonGames = _stats.wonGames.add(1);
                statsOpponent.lostGames = statsOpponent.lostGames.add(1);
                // set new xp + health
                // TODO: comment out
                _power.health = _power.health.add(1);
                _power.damage = _power.damage.add(1);
                if (_power.defense < 500) {
                    _power.damage = _power.damage.add(1);
                }
                if (_power.accuracy < 900) {
                    _power.accuracy = _power.accuracy.add(1);
                }
                if (_stats.xp > _tournament.leaderPoints){
                    // set leading stats
                    _tournament.leaderAddr = msg.sender;
                    _tournament.leaderPoints = _stats.xp;
                }
                return;
            }
            // emit event
            emit EmitShoot(msg.sender, damage, game.opponent, gameOpponent.health);
        }
        
        game.gameState = GAMESTATE.LOADING;
        gameOpponent.gameState = GAMESTATE.READY;
    }
    
    function revealOpponent() external {
        GAME storage game = games[msg.sender][gameIndex[msg.sender]];
        require (isGunLoaded(msg.sender), "reveal: you need a loaded gun before seeing you opponent. You do not wanna fight without bullet, do ya?");
        if (game.tournamentId != tournamentId){
            game.gameState = GAMESTATE.LOST;
            // if player joined too late and tournament is over
            return;
        }
        // queue needs at least 2 players (queueId == 2)
        if (queueId >= 2){
            if (game.opponent != address(0))
                // player alreay revealed by another player in same or previous block -> player switch not possible
                return;
            // remove current player from list 
            // decrease queue id
            queueId = queueId.sub(1);
            if (queueId != game.queueId){
                // move last item if player is not last one
                playerQueue[game.queueId] = playerQueue[queueId];
            }
            
            // get individual random number
            // compute rnd number based on max queueId
            bytes32 requestId = rndRndIdsRequestIds[game.rndAwaiting];
            uint256 number = vrf.getRequest(requestId);
            uint256 _number = uint256(keccak256(abi.encode(number, game.gameId))) % queueId;
            // find opponent
            address opponent = playerQueue[_number];
            GAME storage gameOpponent = games[opponent][gameIndex[opponent]];
            // remove opponent from list
            queueId = queueId.sub(1);
            if (queueId != gameOpponent.queueId){
                // move last item if player is not last one
                playerQueue[gameOpponent.queueId] = playerQueue[queueId];
            }
            // set player bi-directional
            game.opponent = opponent;
            gameOpponent.opponent = msg.sender;
            // both players are ready to shoot (no new random number needed for better gaming experience)
            // random numbers are generated based on stats of opponent, xp and health
            game.gameState = GAMESTATE.READY;
            // the player who paid for the gas fees comes first (fair? of course :))
            gameOpponent.gameState = GAMESTATE.LOADING;
            emit EmitBattle(msg.sender, opponent);
        }
        else {
            emit EmitInvalid("reveal: queue empty. please wait and try again");
        }
    }
    
    // open new game. only possible if no active game
    function openGame(uint8 tokenId) payable external returns (bool) {
        require(msg.value >= fee, "open: fee too low");
        require(tokenId <= 1, "open: invalid token id");
        // set torunament data
        TOURNAMENT storage _tournament = tournaments[tournamentId];
        if (block.number > _tournament.endBLock){
            // old tournament
            _tournament.finished = true;
            // reset queue id
            queueId = 0;
            // new tournament
            tournamentId = tournamentId.add(1);
            _tournament = tournaments[tournamentId];
            _tournament.id = tournamentId;
            _tournament.startBlock = block.number;
            _tournament.endBLock = block.number.add(blocksPerTournament);
        }
        // call paypout if winner starts game (no effect for everyone else)
        payout();
        // gold bars allow for higher betting
        if (TOKEN(tokenId) == TOKEN.GC){
            // goldcoin handling
            goldcoin.safeTransferFrom(msg.sender, address(this), gameFee);
            // burn nuggets as entry fee
            uint256 nuggetDebt = gameFee.mul(calculateNuggetRatio()).div(DECIMALS_NUGGET_RATIO);
            // burn
            nugget.safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), nuggetDebt.div(2));
            burnedNuggets = burnedNuggets.add(nuggetDebt.div(2));
            // 2nd half goes to sustainability contract
            nugget.safeTransferFrom(msg.sender, address(sustainabilityContract), nuggetDebt.div(2));
            // set prize pool
            _tournament.prizeGC = _tournament.prizeGC.add(gameFee);
            
        }
        else{
            // goldbar handling (no burn fees) -> 1/10 fo GC fee (standard ratio)
            goldbar.safeTransferFrom(msg.sender, address(this), gameFee.div(10));
            // set prize pool
            _tournament.prizeGB = _tournament.prizeGC.add(gameFee.div(10));
        }
        uint256 index = gameIndex[msg.sender];
        if (index != 0) {
            // if last tournament is over, a new game can be started as well
            require(canOpenGame(msg.sender), "open: active game. please wait till game is finished.");
        }
        // new game
        gameIndex[msg.sender] = gameIndex[msg.sender].add(1);
        GAME storage game = games[msg.sender][gameIndex[msg.sender]];
        POWER storage _power = powers[msg.sender];
        
        if (_power.tournamentId != tournamentId) {
            _power.tournamentId = tournamentId;
            if (_power.playerId == 0) {
                _power.playerId = playerId;
                players[playerId] = msg.sender;
                playerId = playerId.add(1);
            }
            // reset stats for tournament
            _power.health = 500;
            _power.damage = 100;
            _power.accuracy = 300;
            // defense == 0
        }
        game.health = _power.health;
        // next game + queue ids
        game.gameId = gameId;
        game.queueId = queueId;
        // current tournament id
        game.tournamentId = tournamentId;
        playerQueue[queueId] = msg.sender;
        gameId += 1;
        queueId += 1;
        // add to rnd requestor queue and wait for response
        rndRndIdsRequestorQueue[rndActive] += 1;
        game.rndAwaiting = rndActive;
        game.gameState = GAMESTATE.LOCKED;
        handleRndRequest();
        gameTreasury.transfer(address(this).balance);
        emit EmitGameOpen(msg.sender);
    }
    
    function handleRndRequest() internal {
        if (getActiveRequestors() >= minRequestors){
            // get random number request and store request id
            bytes32 requestId = vrf.getRandomNumber();
            // set awaiting request in sequence
            rndRndIdsRequestIds[rndActive] = requestId;
            // set next active vrf
            rndActive += 1;
            // caller does not have to pay for handling as well.next
            return; 
        }
        // checking first awaiting requestId
        /*
        if (rndNext == rndActive)
            return;
        // get next awaiting request
        bytes32 requestId = rndRndIdsRequestIds[rndNext];
        if (vrf.isCallback(requestId)){
            // random number received
            uint256 rnd = vrf.getRequest(requestId);
            // store received rnd for request id
            rndRndIdsReceived[rndNext] = rnd;
            // update rnd next if callback has been received
            rndNext += 1;
        } */
    }
    
    // only in case of emergency
    function emergencyTokenWithdraw(address _token) public onlyOwner {
        IBEP20 token = IBEP20(_token);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Blockmine token with Governance.
interface IBlockmineVRF{
    
    // initiate random number request
    function getRandomNumber() external returns (bytes32);
    
    // can be called by initiator to check if callback arrived
    // handling must be done by respective contract
    function isCallback(bytes32 requestId) external view returns (bool);
    
    // can be called by initiator to receive the random number
    // handling must be done by respective contract
    function getRequest(bytes32 requestId) external view returns (uint256);
    
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}