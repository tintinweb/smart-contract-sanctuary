//The Eth Game smart contract.
//Copyright 2018 - Abracadabra
//TheEthGame.com 

pragma solidity ^0.4.13;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract TheEthGame {
    using SafeMath for uint256;
    address private owner;

    event Bought (uint256 indexed _cellId, address indexed _owner, uint256 _price);
    event Sold (uint256 indexed _cellId, address indexed _owner, uint256 _price);
    event NewRankOnePlayer (uint256 indexed _blockNumber, address _address);
    event TrophyAwarded (uint256 indexed _blockNumber, uint256 indexed _timestamp, address _address);
    
    uint256 private NUMBER_OF_LINES = 6;
    uint256 private NUMBER_OF_COLUMNS = 6;
    uint256 private NUMBER_OF_CELLS = NUMBER_OF_COLUMNS.mul(NUMBER_OF_LINES);
    uint256 private DEFAULT_POINTS_PER_CELL = 3;
    uint256 private POINTS_PER_NEIGHBOUR = 1;
    uint256 private CELL_STARTING_PRICE = 0.005 ether;
    uint256 private BLOCKS_TO_CONFIRM_TO_WIN_THE_GAME = 10000;
    uint256 private LIMITATION_PERIOD_BLOCKS = 6000;
    uint256 private MAXIMUM_NUMBER_OF_CELLS_OWNABLE_DURING_LIMITATION_PERIOD = 9;
    uint256 private BLOCKS_TO_START_GAME = 240;
    
    uint256 private increaseLimit1 = 0.05 ether;
    uint256 private increaseLimit2 = 0.5 ether;
    uint256 private increaseLimit3 = 2.0 ether;

    address[] private ownerOfCell = new address[](NUMBER_OF_CELLS);
    uint256[] private priceOfCell = new uint256[](NUMBER_OF_CELLS);
    mapping (address => uint256) private scoreOfAddress;
    mapping (address => uint256) private lastCellBoughtOnBlockNumber;
    mapping (address => bytes32) private nameOf;
    
    uint256 private developersCut = 0 ether;
    address private rankOnePlayerAddress;
    uint256 private limitBuyingTillBlock;
    uint256 private startGameAtBlock;
    
    address public trophyAddress;
    
    constructor () public {
        owner = msg.sender;
        
        startGameAtBlock = block.number.add(BLOCKS_TO_START_GAME);
        limitBuyingTillBlock = startGameAtBlock.add(LIMITATION_PERIOD_BLOCKS);
        
        for(uint256 i = 0; i < NUMBER_OF_CELLS; i++){
            priceOfCell[i] = CELL_STARTING_PRICE;
            ownerOfCell[i] = owner; //Owner can&#39;t buy cells back and his score will awlays be 0.
        }
        
        trophyAddress = new TheEthGameTrophy();
    }

    
    /* Modifiers */
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    /* Buying */
    function nextPriceOf (uint256 _cellId) public view returns (uint256 _nextPrice) {
        return calculateNextPrice(priceOf(_cellId));
    }

    function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
        if (_price < increaseLimit1) {
            return _price.mul(200).div(65); //5% Dev, 30% Pot
        } else if (_price < increaseLimit2) {
            return _price.mul(135).div(81); //4% Dev, 15% Pot
        } else if (_price < increaseLimit3) {
            return _price.mul(125).div(84); //4% Dev, 12% Pot
        } else {
            return _price.mul(115).div(89); //3% Dev, 10% Pot
        }
    }
    
    function calculateDevCut (uint256 _price) internal view returns (uint256 _devCut) {
        if (_price < increaseLimit1) {
            return _price.mul(5).div(100); // 5%
        } else if (_price < increaseLimit2) {
            return _price.mul(4).div(100); // 4%
        } else if (_price < increaseLimit3) {
            return _price.mul(4).div(100); // 4%
        }else {
            return _price.mul(3).div(100); // 3%
        }
    }

    function calculatePotCut (uint256 _price) internal view returns (uint256 _potCut) {
        if (_price < increaseLimit1) {
            return _price.mul(30).div(100); // 30%
        } else if (_price < increaseLimit2) {
            return _price.mul(15).div(100); // 14%
        } else if (_price < increaseLimit3) {
            return _price.mul(12).div(100); // 14%
        } else {
            return _price.mul(8).div(100); // 10%
        }
    }
    
    function buy (uint256 _cellId) payable public {
        //Game has to start
        require(isGameStarted());
        
        require(priceOf(_cellId) > 0);
        require(msg.value >= priceOf(_cellId));
        require(ownerOf(_cellId) != msg.sender);
        require(!isContract(msg.sender));
        require(msg.sender != address(0));
        require(_cellId < NUMBER_OF_CELLS);
        require(ownerOf(_cellId) != address(0));

        //Owner can&#39;t buy cells.
        require(msg.sender != owner);
        
        //If game is finished nobody can buy cells.
        require(!isGameFinished());
        
        //Limit the number of cells a player can own for three days since deployment.
        if (isLimitationPeriodActive()) {
            require(numberOfCellsOwnedBy(msg.sender) < MAXIMUM_NUMBER_OF_CELLS_OWNABLE_DURING_LIMITATION_PERIOD);
        }
        
        address oldOwner = ownerOf(_cellId);
        address newOwner = msg.sender;
        
        uint256 price = priceOf(_cellId);
        uint256 excess = msg.value.sub(price);
        
        //Save the block in which this cell was bought.
        lastCellBoughtOnBlockNumber[newOwner] = block.number;
        
        //Transfer ownership.
        _transfer(oldOwner, newOwner, _cellId);
        
        //Calulcate new price.
        priceOfCell[_cellId] = nextPriceOf(_cellId);
    
        //Store rank one player before calculating the new scores.
        address oldRankOnePlayer = rankOnePlayerAddress;
       
        (uint256 newOwnerScore, uint256 oldOwnerScore) = calculateScoresIfCellIsBought(newOwner, oldOwner, _cellId);
        
        //Set the scores.
        scoreOfAddress[newOwner] = newOwnerScore;
        
        //If the old owner is the owner of the contract oldOwnerScore is 0
        //because of the implementation of calculateScoresIfCellIsBought(,,).
        scoreOfAddress[oldOwner] = oldOwnerScore;
        
        
        //If the old owner is the rank one player then recalculate the rank one player.
        if (oldOwner == rankOnePlayerAddress) {
            rankOnePlayerAddress = getRankOnePlayer();
        }else{ //Otherwise check if the new owner score is greater or equal than the rank one player score.
            if (scoreOfAddress[newOwner] >= scoreOfAddress[rankOnePlayerAddress]) {
                rankOnePlayerAddress = newOwner;
            }
        }

        //If the new rank one player is different from the old one then reset the
        //timer for the win.
        if (rankOnePlayerAddress != oldRankOnePlayer) {
            emit NewRankOnePlayer (block.number, rankOnePlayerAddress);
        }
        
        emit Bought(_cellId, newOwner, price);
        emit Sold(_cellId, oldOwner, price);
    
        //Calculate developers cut and add it to the &quot;developersCut&quot; variable which controls
        //the maximum amount withdrawable by the owner.
        uint256 devCut = calculateDevCut(price);
        developersCut = developersCut.add(devCut);
        
        // Transfer payment to old owner minus the developer&#39;s cut and pot&#39;s cut.
        // If the oldOwner is contract creator do nothing,
        // thus adding the cell cost to the pot.
        if (oldOwner != owner) {
            uint256 potCut = calculatePotCut(price);
            uint256 toTransfer = price.sub(potCut);
            oldOwner.transfer(toTransfer.sub(devCut));
        }
        
        if (excess > 0) {
          newOwner.transfer(excess);
        }
    }
    
    /* Game */
    function calculateRanking () external view returns(uint256[] _scores, uint256[] _lastCellBoughtOnBlock, address[] _addresses, bytes32[] _names) {
        uint256[] memory scores = new uint256[](NUMBER_OF_CELLS);
        address[] memory addresses = new address[](NUMBER_OF_CELLS);
        uint256[] memory lastCellBoughtOnBlock = new uint256[](NUMBER_OF_CELLS);
        bytes32[] memory names = new bytes32[](NUMBER_OF_CELLS);
        
        for (uint256 i = 0; i < ownerOfCell.length; i++) {
            scores[i] = scoreOfAddress[ownerOfCell[i]];
            addresses[i] = ownerOfCell[i];
            lastCellBoughtOnBlock[i] = lastCellBoughtOnBlockNumber[ownerOfCell[i]];
            names[i] = nameOf[ownerOfCell[i]];
        }
        
        return (scores, lastCellBoughtOnBlock, addresses, names);
    }
    
    function getCellsInfo () external view returns (uint256[] _prices, uint256[] _nextPrice, address[] _owner, bytes32[] _names) {
        uint256[] memory prices = new uint256[](NUMBER_OF_CELLS);
        address[] memory owners = new address[](NUMBER_OF_CELLS);
        bytes32[] memory names = new bytes32[](NUMBER_OF_CELLS);
        uint256[] memory nextPrices = new uint256[](NUMBER_OF_CELLS);
        
        for (uint256 i = 0; i < NUMBER_OF_CELLS; i++) {
             prices[i] = priceOf(i);
             owners[i] = ownerOf(i);
             names[i] = nameOf[ownerOfCell[i]];
             nextPrices[i] = nextPriceOf(i);
        }
        return (prices, nextPrices, owners, names);
    }

    function getCurrentPotSize () public view returns (uint256 _wei) {
        return address(this).balance.sub(developersCut);
    }
    
    function getCurrentWinner () public view returns (address _address) {
        return rankOnePlayerAddress;
    }
    
    function getNumberOfBlocksRemainingToWin () public view returns (int256 _numberOfBlocks) {
        return int256(BLOCKS_TO_CONFIRM_TO_WIN_THE_GAME) - int256(block.number.sub(lastCellBoughtOnBlockNumber[rankOnePlayerAddress]));
    }
    
    function isLimitationPeriodActive () public view returns (bool _isLimitationPeriodActive) {
        return numberOfBlocksToEndLimitationPeriod() >= 0;
    }
    
    function numberOfBlocksToEndLimitationPeriod () public view returns (int256 _numberOfBlocksToEndLimitationPeriod) {
        return int256(limitBuyingTillBlock) - int256(block.number);
    }
    
    function scoreOf (address _address) public view returns (uint256 _score) {
        return scoreOfAddress[_address];
    }
    
    function priceOf(uint256 _cellId) public view returns (uint256 _price) {
        return priceOfCell[_cellId];
    }
    
    function ownerOf(uint256 _cellId) public view returns (address _owner) {
        return ownerOfCell[_cellId];
    }
    
    //The game finish when someone stays on top of the ranking for more than BLOCKS_TO_CONFIRM_TO_WIN_THE_GAME blocks.
    function isGameFinished() public view returns (bool _isGameFinished) {
        return rankOnePlayerAddress != address(0) && getNumberOfBlocksRemainingToWin() < 0;
    }
    
    function isGameStarted() public view returns (bool _isGameStarted) {
        return numberOfBlocksToStartGame () < 0;
    }
    
    function numberOfBlocksToStartGame () public view returns (int256 _numberOfBlocksToStartGame) {
        return int256(startGameAtBlock) - int256(block.number);
    }
    
    //Rank one player is the one with the highest score, if two players have the same
    //score then the higher player is the last one that bought a cell, if the two players
    //bought the cell on the same block than rank one player is the one that own
    //the cell with lower id.
    function getRankOnePlayer () internal view returns (address _address) {
        address rankOnePlayer;
        
        for (uint256 i = 0; i < ownerOfCell.length; i++){
            if (ownerOfCell[i] != rankOnePlayer) {
                if (scoreOf(ownerOfCell[i]) > scoreOf(rankOnePlayer)) {
                    rankOnePlayer = ownerOfCell[i];
                } else if (scoreOf(ownerOfCell[i]) == scoreOf(rankOnePlayer)) {
                    if (lastCellBoughtOnBlockNumber[ownerOfCell[i]] > lastCellBoughtOnBlockNumber[rankOnePlayer]) {
                        rankOnePlayer = ownerOfCell[i];
                    }
                }
            }
        }
        
        return rankOnePlayer;
    }
    
        function numberOfCellsOwnedBy(address _address) internal view returns (uint256 _number) {
        uint256 numberOfOwnedCells = 0;
        for(uint256 i = 0; i < NUMBER_OF_CELLS; i++){
            if(ownerOfCell[i] == _address){
                numberOfOwnedCells = numberOfOwnedCells.add(1);
            }
        }
        
        return numberOfOwnedCells;
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
        
        //If old owner is the owner of the contract.
        if (_oldOwner == owner) {
            oldOwnerScoreAdjustment = 0;
        }
        
        return (scoreOfAddress[_newOwner].add(newOwnerScoreAdjustment), scoreOfAddress[_oldOwner].sub(oldOwnerScoreAdjustment));
    }
    
    //Calculate the number of cells confining with _cellId owned by 
    //_address, diagonal is not considered.
    function calculateNumberOfNeighbours(uint256 _cellId, address _address) internal view returns (uint256 _numberOfNeighbours) {
        uint256 numberOfNeighbours;
        
        (uint256 top, uint256 bottom, uint256 left, uint256 right) = getNeighbourhoodOf(_cellId);
        
        if (top != NUMBER_OF_CELLS && ownerOfCell[top] == _address) {
            numberOfNeighbours = numberOfNeighbours.add(1);
        }
        
        if (bottom != NUMBER_OF_CELLS && ownerOfCell[bottom] == _address) {
            numberOfNeighbours = numberOfNeighbours.add(1);
        }
        
        if (left != NUMBER_OF_CELLS && ownerOfCell[left] == _address) {
            numberOfNeighbours = numberOfNeighbours.add(1);
        }
        
        if (right != NUMBER_OF_CELLS && ownerOfCell[right] == _address) {
            numberOfNeighbours = numberOfNeighbours.add(1);
        }
        
        return numberOfNeighbours;
    }

    //Returns an array containing the ids of the cells confining with _cellId.
    function getNeighbourhoodOf(uint256 _cellId) internal view returns (uint256 _top, uint256 _bottom, uint256 _left, uint256 _right) {
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
        ownerOfCell[_cellId] = _to;
    }
    
    /*Withdraws*/
    
    //Withdraw the pot, award The Eth Game Trophy and allow the winner to add a 
    //message.
    function withdrawPot(string _message) public {
        require(!isContract(msg.sender));
        require(msg.sender != owner);
        //A player can withdraw the pot if he is the rank one player
        //and the game is finished.
        require(rankOnePlayerAddress == msg.sender);
        require(isGameFinished());
        
        TheEthGameTrophy trophy = TheEthGameTrophy(trophyAddress);
        trophy.award(msg.sender, _message);
        emit TrophyAwarded(block.number, block.timestamp, msg.sender);
        
        msg.sender.transfer(address(this).balance.sub(developersCut));
    }
    
    function withdrawAllDevelopersCut () onlyOwner() public {
        uint256 toWithdraw = developersCut;
        developersCut = 0;
        owner.transfer(toWithdraw);
    }
  
    function withdrawPartialDevelopersCut (uint256 _amount) onlyOwner() public {
        require(_amount <= developersCut);
        developersCut = developersCut.sub(_amount);
        owner.transfer(_amount);
    }
    
    /* Player Name */
    function setName(bytes32 _name) public {
        nameOf[msg.sender] = _name;
    }
    
    function getNameOf(address _address) external view returns(bytes32 _name) {
        return nameOf[_address];
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
        name = &quot;The Eth Game Winner&quot;;
        description = &quot;2019-08-17&quot;;
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
  
    //Trophy can be awarded once.
    function award(address _address, string _message) public {
        require(msg.sender == creator && !isAwarded);
        isAwarded = true;
        owner = _address;
        winner = _address;
        message = _message;
        
        emit Award(block.number, block.timestamp, _address);
    }
    
    //Function that is called when transaction target is an address
    function transfer(address _to) private returns (bool success) {
        require(msg.sender == owner);
        owner = _to;
        emit Transfer(msg.sender, _to);
        return true;
    }
    
}