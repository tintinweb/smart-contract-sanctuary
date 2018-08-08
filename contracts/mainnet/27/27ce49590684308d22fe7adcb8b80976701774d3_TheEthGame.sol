/*
 _______  _______  ______    _______  _______  _______  ______   _______  _______  ______    _______  
|   _   ||  _    ||    _ |  |   _   ||       ||   _   ||      | |   _   ||  _    ||    _ |  |   _   | 
|  |_|  || |_|   ||   | ||  |  |_|  ||       ||  |_|  ||  _    ||  |_|  || |_|   ||   | ||  |  |_|  | 
|       ||       ||   |_||_ |       ||       ||       || | |   ||       ||       ||   |_||_ |       | 
|       ||  _   | |    __  ||       ||      _||       || |_|   ||       ||  _   | |    __  ||       | 
|   _   || |_|   ||   |  | ||   _   ||     |_ |   _   ||       ||   _   || |_|   ||   |  | ||   _   | 
|__| |__||_______||___|  |_||__| |__||_______||__| |__||______| |__| |__||_______||___|  |_||__| |__| 
                                                                                                     
                                       
                                 _       
                                | |      
  _ __  _ __ ___  ___  ___ _ __ | |_ ___ 
 | &#39;_ \| &#39;__/ _ \/ __|/ _ \ &#39;_ \| __/ __|
 | |_) | | |  __/\__ \  __/ | | | |_\__ \
 | .__/|_|  \___||___/\___|_| |_|\__|___/
 | |                                     
 |_|                                     
                                                                                                      
                                                                                                      
 _______  __   __  _______        _______  _______  __   __        _______  _______  __   __  _______ 
|       ||  | |  ||       |      |       ||       ||  | |  |      |       ||   _   ||  |_|  ||       |
|_     _||  |_|  ||    ___|      |    ___||_     _||  |_|  |      |    ___||  |_|  ||       ||    ___|
  |   |  |       ||   |___       |   |___   |   |  |       |      |   | __ |       ||       ||   |___ 
  |   |  |       ||    ___|      |    ___|  |   |  |       |      |   ||  ||       ||       ||    ___|
  |   |  |   _   ||   |___       |   |___   |   |  |   _   |      |   |_| ||   _   || ||_|| ||   |___ 
  |___|  |__| |__||_______|      |_______|  |___|  |__| |__|      |_______||__| |__||_|   |_||_______|

Copyright 2018 - theethgame.com
*/

pragma solidity ^0.4.13;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}
contract TheEthGame {
    using SafeMath for uint256;
    
    struct Player {
        uint256 score;
        uint256 lastCellBoughtOnBlockNumber;
        uint256 numberOfCellsOwned;
        uint256 numberOfCellsBought;
        uint256 earnings;

        uint256 partialHarmonicSum;
        uint256 partialScoreSum;
        
        address referreal;

        bytes32 name;
    }
    
    struct Cell {
        address owner;
        uint256 price;
    }
    
    address public owner;
    
    uint256 constant private NUMBER_OF_LINES = 6;
    uint256 constant private NUMBER_OF_COLUMNS = 6;
    uint256 constant private NUMBER_OF_CELLS = NUMBER_OF_COLUMNS * NUMBER_OF_LINES;
    uint256 constant private DEFAULT_POINTS_PER_CELL = 3;
    uint256 constant private POINTS_PER_NEIGHBOUR = 1;

    uint256 constant private CELL_STARTING_PRICE = 0.002 ether;
    uint256 constant private BLOCKS_TO_CONFIRM_TO_WIN_THE_GAME = 10000;
    uint256 constant private PRICE_INCREASE_PERCENTAGE = uint(2);
    uint256 constant private REFERREAL_PERCENTAGE = uint(10);
    uint256 constant private POT_PERCENTAGE = uint(30);
    uint256 constant private DEVELOPER_PERCENTAGE = uint(5);
    uint256 constant private SCORE_PERCENTAGE = uint(25);
    uint256 constant private NUMBER_OF_CELLS_PERCENTAGE = uint(30);
    
    Cell[NUMBER_OF_CELLS] cells;
    
    address[] private ranking;
    mapping(address => Player) players;
    mapping(bytes32 => address) nameToAddress;
    
    uint256 public numberOfCellsBought;
    uint256 private totalScore;
    
    uint256 private developersCut = 0 ether;
    uint256 private potCut = 0 ether;
    uint256 private harmonicSum;
    uint256 private totalScoreSum;
    
    address private rankOnePlayerAddress;
    uint256 private isFirstSinceBlock;
    
    address public trophyAddress;
    
    event Bought (address indexed _from, address indexed _to);

    constructor () public {
        owner = msg.sender;
        trophyAddress = new TheEthGameTrophy();
    }
    
    /* Modifiers */
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    /* Buying */
    function nextPriceOf (uint256 _cellId) public view returns (uint256 _nextPrice) {
        return priceOf(_cellId).mul(100 + PRICE_INCREASE_PERCENTAGE) / 100;
    }
    
    function priceOf (uint256 _cellId) public view returns (uint256 _price) {
        if (cells[_cellId].price == 0) {
            return CELL_STARTING_PRICE;
        }
        
        return cells[_cellId].price;
    }
    
    function earningsFromNumberOfCells (address _address) internal view returns (uint256 _earnings) {
        return harmonicSum.sub(players[_address].partialHarmonicSum).mul(players[_address].numberOfCellsBought);
    }
    
    function distributeEarningsBasedOnNumberOfCells (address _address) internal {
        players[_address].earnings = players[_address].earnings.add(earningsFromNumberOfCells(_address));
        players[_address].partialHarmonicSum = harmonicSum;
    }
    
    function earningsFromScore (address _address) internal view returns (uint256 _earnings) {
        return totalScoreSum.sub(players[_address].partialScoreSum).mul(scoreOf(_address));
    }
    
    function distributeEarningsBasedOnScore (address _newOwner, address _oldOwner) internal {
        players[_newOwner].earnings = players[_newOwner].earnings.add(earningsFromScore(_newOwner));
        players[_newOwner].partialScoreSum = totalScoreSum;
        
        if (_oldOwner != address(0)) {
            players[_oldOwner].earnings = players[_oldOwner].earnings.add(earningsFromScore(_oldOwner));
            players[_oldOwner].partialScoreSum = totalScoreSum;
        }
    }
    
    function earningsOfPlayer () public view returns (uint256 _wei) {
        return players[msg.sender].earnings.add(earningsFromScore(msg.sender)).add(earningsFromNumberOfCells(msg.sender));
    }
    
    function getRankOnePlayer (address _oldOwner) internal view returns (address _address, uint256 _oldOwnerIndex) {
        address rankOnePlayer;
        uint256 oldOwnerIndex;
        
        for (uint256 i = 0; i < ranking.length; i++) {
            if (scoreOf(ranking[i]) > scoreOf(rankOnePlayer)) {
                    rankOnePlayer = ranking[i];
            } else if (scoreOf(ranking[i]) == scoreOf(rankOnePlayer) && players[ranking[i]].lastCellBoughtOnBlockNumber > players[rankOnePlayer].lastCellBoughtOnBlockNumber) {
                    rankOnePlayer = ranking[i];
            }
            
            if (ranking[i] == _oldOwner) {
                oldOwnerIndex = i;
            }
        }
        
        
        return (rankOnePlayer, oldOwnerIndex);
    }

    function buy (uint256 _cellId, address _referreal) payable public {
        require(msg.value >= priceOf(_cellId));
        require(!isContract(msg.sender));
        require(_cellId < NUMBER_OF_CELLS);
        require(msg.sender != address(0));
        require(!isGameFinished()); //If game is finished nobody can buy cells.
        require(ownerOf(_cellId) != msg.sender);
        require(msg.sender != _referreal);
        
        address oldOwner = ownerOf(_cellId);
        address newOwner = msg.sender;
        uint256 price = priceOf(_cellId);
        uint256 excess = msg.value.sub(price);

        bool isReferrealDistributed = distributeToReferreal(price, _referreal);
        
        //If numberOfCellsBought > 0 imply totalScore > 0
        if (numberOfCellsBought > 0) {
            harmonicSum = harmonicSum.add(price.mul(NUMBER_OF_CELLS_PERCENTAGE) / (numberOfCellsBought * 100));
            if (isReferrealDistributed) {
                totalScoreSum = totalScoreSum.add(price.mul(SCORE_PERCENTAGE) / (totalScore * 100));
            } else {
                totalScoreSum = totalScoreSum.add(price.mul(SCORE_PERCENTAGE.add(REFERREAL_PERCENTAGE)) / (totalScore * 100));
            }
        }else{
            //First cell bought price goes to the pot.
            potCut = potCut.add(price.mul(NUMBER_OF_CELLS_PERCENTAGE.add(SCORE_PERCENTAGE)) / 100);
        }
        
        numberOfCellsBought++;
        
        distributeEarningsBasedOnNumberOfCells(newOwner);
        
        players[newOwner].numberOfCellsBought++;
        players[newOwner].numberOfCellsOwned++;
        
        if (ownerOf(_cellId) != address(0)) {
             players[oldOwner].numberOfCellsOwned--;
        }
        
        players[newOwner].lastCellBoughtOnBlockNumber = block.number;
         
        address oldRankOnePlayer = rankOnePlayerAddress;
        
        (uint256 newOwnerScore, uint256 oldOwnerScore) = calculateScoresIfCellIsBought(newOwner, oldOwner, _cellId);
        
        distributeEarningsBasedOnScore(newOwner, oldOwner);
        
        totalScore = totalScore.sub(scoreOf(newOwner).add(scoreOf(oldOwner)));
                
        players[newOwner].score = newOwnerScore;
        players[oldOwner].score = oldOwnerScore;
        
        totalScore = totalScore.add(scoreOf(newOwner).add(scoreOf(oldOwner)));

        cells[_cellId].price = nextPriceOf(_cellId);
        
        //It had 0 cells before
        if (players[newOwner].numberOfCellsOwned == 1) {
           ranking.push(newOwner);
        }
        
        if (oldOwner == rankOnePlayerAddress || (players[oldOwner].numberOfCellsOwned == 0 && oldOwner != address(0))) {
            (address rankOnePlayer, uint256 oldOwnerIndex) = getRankOnePlayer(oldOwner); 
            if (players[oldOwner].numberOfCellsOwned == 0 && oldOwner != address(0)) {
                delete ranking[oldOwnerIndex];
            }
            rankOnePlayerAddress = rankOnePlayer;
        }else{ //Otherwise check if the new owner score is greater or equal than the rank one player score.
            if (scoreOf(newOwner) >= scoreOf(rankOnePlayerAddress)) {
                rankOnePlayerAddress = newOwner;
            }
        }
        
        if (rankOnePlayerAddress != oldRankOnePlayer) {
            isFirstSinceBlock = block.number;
        }
        

        developersCut = developersCut.add(price.mul(DEVELOPER_PERCENTAGE) / 100);
        potCut = potCut.add(price.mul(POT_PERCENTAGE) / 100);

        _transfer(oldOwner, newOwner, _cellId);
        
        emit Bought(oldOwner, newOwner);
        
        if (excess > 0) {
          newOwner.transfer(excess);
        }
    }
    
    function distributeToReferreal (uint256 _price, address _referreal) internal returns (bool _isDstributed) {
        if (_referreal != address(0) && _referreal != msg.sender) {
            players[msg.sender].referreal = _referreal;
        }
        
        //Distribute to referreal
        if (players[msg.sender].referreal != address(0)) {
            address ref = players[msg.sender].referreal;
            players[ref].earnings = players[ref].earnings.add(_price.mul(REFERREAL_PERCENTAGE) / 100);
            return true;
        }
        
        return false;
    }
    
    /* Game */
    function getPlayers () external view returns(uint256[] _scores, uint256[] _lastCellBoughtOnBlock, address[] _addresses, bytes32[] _names) {
        uint256[] memory scores = new uint256[](ranking.length);
        address[] memory addresses = new address[](ranking.length);
        uint256[] memory lastCellBoughtOnBlock = new uint256[](ranking.length);
        bytes32[] memory names = new bytes32[](ranking.length);
        
        for (uint256 i = 0; i < ranking.length; i++) {
            Player memory p = players[ranking[i]];
            
            scores[i] = p.score;
            addresses[i] = ranking[i];
            lastCellBoughtOnBlock[i] = p.lastCellBoughtOnBlockNumber;
            names[i] = p.name;
        }
        
        return (scores, lastCellBoughtOnBlock, addresses, names);
    }
    
    function getCells () external view returns (uint256[] _prices, uint256[] _nextPrice, address[] _owner, bytes32[] _names) {
        uint256[] memory prices = new uint256[](NUMBER_OF_CELLS);
        address[] memory owners = new address[](NUMBER_OF_CELLS);
        bytes32[] memory names = new bytes32[](NUMBER_OF_CELLS);
        uint256[] memory nextPrices = new uint256[](NUMBER_OF_CELLS);
        
        for (uint256 i = 0; i < NUMBER_OF_CELLS; i++) {
             prices[i] = priceOf(i);
             owners[i] = ownerOf(i);
             names[i] = players[ownerOf(i)].name;
             nextPrices[i] = nextPriceOf(i);
        }
        
        return (prices, nextPrices, owners, names);
    }
    
    function getPlayer () external view returns (bytes32 _name, uint256 _score, uint256 _earnings, uint256 _numberOfCellsBought) {
        return (players[msg.sender].name, players[msg.sender].score, earningsOfPlayer(), players[msg.sender].numberOfCellsBought);
    }
    
    function getCurrentPotSize () public view returns (uint256 _wei) {
        return potCut;
    }
    
    function getCurrentWinner () public view returns (address _address) {
        return rankOnePlayerAddress;
    }
    
    function getNumberOfBlocksRemainingToWin () public view returns (int256 _numberOfBlocks) {
        return int256(BLOCKS_TO_CONFIRM_TO_WIN_THE_GAME) - int256(block.number.sub(isFirstSinceBlock));
    }
    
    function scoreOf (address _address) public view returns (uint256 _score) {
        return players[_address].score;
    }
    
    function ownerOf (uint256 _cellId) public view returns (address _owner) {
        return cells[_cellId].owner;
    }
    
    function isGameFinished() public view returns (bool _isGameFinished) {
        return rankOnePlayerAddress != address(0) && getNumberOfBlocksRemainingToWin() < 0;
    }
    
    function calculateScoresIfCellIsBought (address _newOwner, address _oldOwner, uint256 _cellId) internal view returns (uint256 _newOwnerScore, uint256 _oldOwnerScore) {
        //Minus 2 points at the old owner.
        uint256 oldOwnerScoreAdjustment = DEFAULT_POINTS_PER_CELL;
        
        //Plus 2 points at the new owner.
        uint256 newOwnerScoreAdjustment = DEFAULT_POINTS_PER_CELL;
        
        //Calulcate the number of neightbours of _cellId for the old 
        //and the new owner, then double the number and multiply it by POINTS_PER_NEIGHBOUR.
        oldOwnerScoreAdjustment = oldOwnerScoreAdjustment.add(calculateNumberOfNeighbours(_cellId, _oldOwner).mul(POINTS_PER_NEIGHBOUR).mul(2));
        newOwnerScoreAdjustment = newOwnerScoreAdjustment.add(calculateNumberOfNeighbours(_cellId, _newOwner).mul(POINTS_PER_NEIGHBOUR).mul(2));
        
        if (_oldOwner == address(0)) {
            oldOwnerScoreAdjustment = 0;
        }
        
        return (scoreOf(_newOwner).add(newOwnerScoreAdjustment), scoreOf(_oldOwner).sub(oldOwnerScoreAdjustment));
    }
    
    //Diagonal is not considered.
    function calculateNumberOfNeighbours(uint256 _cellId, address _address) internal view returns (uint256 _numberOfNeighbours) {
        uint256 numberOfNeighbours;
        
        (uint256 top, uint256 bottom, uint256 left, uint256 right) = getNeighbourhoodOf(_cellId);
        
        if (top != NUMBER_OF_CELLS && ownerOf(top) == _address) {
            numberOfNeighbours = numberOfNeighbours.add(1);
        }
        
        if (bottom != NUMBER_OF_CELLS && ownerOf(bottom) == _address) {
            numberOfNeighbours = numberOfNeighbours.add(1);
        }
        
        if (left != NUMBER_OF_CELLS && ownerOf(left) == _address) {
            numberOfNeighbours = numberOfNeighbours.add(1);
        }
        
        if (right != NUMBER_OF_CELLS && ownerOf(right) == _address) {
            numberOfNeighbours = numberOfNeighbours.add(1);
        }
        
        return numberOfNeighbours;
    }

    function getNeighbourhoodOf(uint256 _cellId) internal pure returns (uint256 _top, uint256 _bottom, uint256 _left, uint256 _right) {
        //IMPORTANT: The number &#39;NUMBER_OF_CELLS&#39; is used  to indicate that a cell does not exists.
        
        //Set top cell as non existent.
        uint256 topCellId = NUMBER_OF_CELLS;
        
        //If cell id is not on the first line set the correct _cellId as topCellId.
        if(_cellId >= NUMBER_OF_LINES){
           topCellId = _cellId.sub(NUMBER_OF_LINES);
        }
        
        //Get the cell under _cellId by adding the number of cells per line.
        uint256 bottomCellId = _cellId.add(NUMBER_OF_LINES);
        
        //If it&#39;s greater or equal than NUMBER_OF_CELLS bottom cell does not exists.
        if (bottomCellId >= NUMBER_OF_CELLS) {
            bottomCellId = NUMBER_OF_CELLS;
        }
        
        //Set left cell as non existent.
        uint256 leftCellId = NUMBER_OF_CELLS;
        
        //If the remainder of _cellId / NUMBER_OF_LINES is not 0 then _cellId is on
        //not the first column and thus has a left neighbour.
        if ((_cellId % NUMBER_OF_LINES) != 0) {
            leftCellId = _cellId.sub(1);
        }
        
        //Get the cell on the right by adding 1.
        uint256 rightCellId = _cellId.add(1);

        //If the remainder of rightCellId / NUMBER_OF_LINES is 0 then _cellId is on
        //the last column and thus has no right neighbour.
        if ((rightCellId % NUMBER_OF_LINES) == 0) {
            rightCellId = NUMBER_OF_CELLS;
        }
        
        return (topCellId, bottomCellId, leftCellId, rightCellId);
    }

    function _transfer(address _from, address _to, uint256 _cellId) internal {
        require(_cellId < NUMBER_OF_CELLS);
        require(ownerOf(_cellId) == _from);
        require(_to != address(0));
        require(_to != address(this));
        cells[_cellId].owner = _to;
    }
    
    /*Withdraws*/
    function withdrawPot(string _message) public {
        require(!isContract(msg.sender));
        require(msg.sender != owner);
        //A player can withdraw the pot if he is the rank one player
        //and the game is finished.
        require(rankOnePlayerAddress == msg.sender);
        require(isGameFinished());
        
        uint256 toWithdraw = potCut;
        potCut = 0;
        msg.sender.transfer(toWithdraw);
        
        TheEthGameTrophy trophy = TheEthGameTrophy(trophyAddress);
        trophy.award(msg.sender, _message);
    }
    
    function withdrawDevelopersCut () onlyOwner() public {
        uint256 toWithdraw = developersCut;
        developersCut = 0;
        owner.transfer(toWithdraw);
    }
  
    function withdrawEarnings () public {
        distributeEarningsBasedOnScore(msg.sender, address(0));
        distributeEarningsBasedOnNumberOfCells(msg.sender);
        
        uint256 toWithdraw = earningsOfPlayer();
        players[msg.sender].earnings = 0;
        
        msg.sender.transfer(toWithdraw);
    }
    
    /* Player Name */
    function setName(bytes32 _name) public {
        if (nameToAddress[_name] != address(0)) {
            return;
        }
        
        players[msg.sender].name = _name;
        nameToAddress[_name] = msg.sender;
    }
    
    function nameOf(address _address) external view returns(bytes32 _name) {
        return players[_address].name;
    }
    
    function addressOf(bytes32 _name) external view returns (address _address) {
        return nameToAddress[_name];
    }
    
    /* Util */
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) } // solium-disable-line
        return size > 0;
    }
}

contract TheEthGameTrophy {
    string public name; 
    string public description;
    string public message;
    
    address public creator;
    address public owner;
    address public winner;
    uint public rank;
    
    bool private isAwarded = false;
    
    event Award(uint256 indexed _blockNumber, uint256 indexed _timestamp, address indexed _owner);
    event Transfer (address indexed _from, address indexed _to);

    constructor () public {
        name = "The Eth Game Winner";
        description = "2019-08-17";
        rank = 1;
        creator = msg.sender;
    }
    
    function name() constant public returns (string _name) {
        return name;
    }
    
    function description() constant public returns (string _description) {
        return description;
    }
    
    function message() constant public returns (string _message) {
        return message;
    }
    
    function creator() constant public returns (address _creator) {
        return creator;
    }
    
    function owner() constant public returns (address _owner) {
        return owner;
    }
    
    function winner() constant public returns (address _winner) {
        return winner;
    }
    
    function rank() constant public returns (uint _rank) {
        return rank;
    }
  
    function award(address _address, string _message) public {
        require(msg.sender == creator && !isAwarded);
        isAwarded = true;
        owner = _address;
        winner = _address;
        message = _message;
        
        emit Award(block.number, block.timestamp, _address);
    }
    
    function transfer(address _to) private returns (bool success) {
        require(msg.sender == owner);
        owner = _to;
        emit Transfer(msg.sender, _to);
        return true;
    }
}