pragma solidity ^0.4.21;

library BWUtility {
    
    // -------- UTILITY FUNCTIONS ----------


    // Return next higher even _multiple for _amount parameter (e.g used to round up to even finneys).
    function ceil(uint _amount, uint _multiple) pure public returns (uint) {
        return ((_amount + _multiple - 1) / _multiple) * _multiple;
    }

    // Checks if two coordinates are adjacent:
    // xxx
    // xox
    // xxx
    // All x (_x2, _xy2) are adjacent to o (_x1, _y1) in this ascii image. 
    // Adjacency does not wrapp around map edges so if y2 = 255 and y1 = 0 then they are not ajacent
    function isAdjacent(uint8 _x1, uint8 _y1, uint8 _x2, uint8 _y2) pure public returns (bool) {
        return ((_x1 == _x2 &&      (_y2 - _y1 == 1 || _y1 - _y2 == 1))) ||      // Same column
               ((_y1 == _y2 &&      (_x2 - _x1 == 1 || _x1 - _x2 == 1))) ||      // Same row
               ((_x2 - _x1 == 1 &&  (_y2 - _y1 == 1 || _y1 - _y2 == 1))) ||      // Right upper or lower diagonal
               ((_x1 - _x2 == 1 &&  (_y2 - _y1 == 1 || _y1 - _y2 == 1)));        // Left upper or lower diagonal
    }

    // Converts (x, y) to tileId xy
    function toTileId(uint8 _x, uint8 _y) pure public returns (uint16) {
        return uint16(_x) << 8 | uint16(_y);
    }

    // Converts _tileId to (x, y)
    function fromTileId(uint16 _tileId) pure public returns (uint8, uint8) {
        uint8 y = uint8(_tileId);
        uint8 x = uint8(_tileId >> 8);
        return (x, y);
    }
    
    function getBoostFromTile(address _claimer, address _attacker, address _defender, uint _blockValue) pure public returns (uint, uint) {
        if (_claimer == _attacker) {
            return (_blockValue, 0);
        } else if (_claimer == _defender) {
            return (0, _blockValue);
        }
    }
}

contract BWData {
    address public owner;
    address private bwService;
    address private bw;
    address private bwMarket;

    uint private blockValueBalance = 0;
    uint private feeBalance = 0;
    uint private BASE_TILE_PRICE_WEI = 1 finney; // 1 milli-ETH.
    
    mapping (address => User) private users; // user address -> user information
    mapping (uint16 => Tile) private tiles; // tileId -> list of TileClaims for that particular tile
    
    // Info about the users = those who have purchased tiles.
    struct User {
        uint creationTime;
        bool censored;
        uint battleValue;
    }

    // Info about a tile ownership
    struct Tile {
        address claimer;
        uint blockValue;
        uint creationTime;
        uint sellPrice;    // If 0 -> not on marketplace. If > 0 -> on marketplace.
    }

    struct Boost {
        uint8 numAttackBoosts;
        uint8 numDefendBoosts;
        uint attackBoost;
        uint defendBoost;
    }

    constructor() public {
        owner = msg.sender;
    }

    // Can&#39;t send funds straight to this contract. Avoid people sending by mistake.
    function () payable public {
        revert();
    }

    function kill() public isOwner {
        selfdestruct(owner);
    }

    modifier isValidCaller {
        if (msg.sender != bwService && msg.sender != bw && msg.sender != bwMarket) {
            revert();
        }
        _;
    }
    
    modifier isOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    function setBwServiceValidCaller(address _bwService) public isOwner {
        bwService = _bwService;
    }

    function setBwValidCaller(address _bw) public isOwner {
        bw = _bw;
    }

    function setBwMarketValidCaller(address _bwMarket) public isOwner {
        bwMarket = _bwMarket;
    }    
    
    // ----------USER-RELATED GETTER FUNCTIONS------------
    
    //function getUser(address _user) view public returns (bytes32) {
        //BWUtility.User memory user = users[_user];
        //require(user.creationTime != 0);
        //return (user.creationTime, user.imageUrl, user.tag, user.email, user.homeUrl, user.creationTime, user.censored, user.battleValue);
    //}
    
    function addUser(address _msgSender) public isValidCaller {
        User storage user = users[_msgSender];
        require(user.creationTime == 0);
        user.creationTime = block.timestamp;
    }

    function hasUser(address _user) view public isValidCaller returns (bool) {
        return users[_user].creationTime != 0;
    }
    

    // ----------TILE-RELATED GETTER FUNCTIONS------------

    function getTile(uint16 _tileId) view public isValidCaller returns (address, uint, uint, uint) {
        Tile storage currentTile = tiles[_tileId];
        return (currentTile.claimer, currentTile.blockValue, currentTile.creationTime, currentTile.sellPrice);
    }
    
    function getTileClaimerAndBlockValue(uint16 _tileId) view public isValidCaller returns (address, uint) {
        Tile storage currentTile = tiles[_tileId];
        return (currentTile.claimer, currentTile.blockValue);
    }
    
    function isNewTile(uint16 _tileId) view public isValidCaller returns (bool) {
        Tile storage currentTile = tiles[_tileId];
        return currentTile.creationTime == 0;
    }
    
    function storeClaim(uint16 _tileId, address _claimer, uint _blockValue) public isValidCaller {
        tiles[_tileId] = Tile(_claimer, _blockValue, block.timestamp, 0);
    }

    function updateTileBlockValue(uint16 _tileId, uint _blockValue) public isValidCaller {
        tiles[_tileId].blockValue = _blockValue;
    }

    function setClaimerForTile(uint16 _tileId, address _claimer) public isValidCaller {
        tiles[_tileId].claimer = _claimer;
    }

    function updateTileTimeStamp(uint16 _tileId) public isValidCaller {
        tiles[_tileId].creationTime = block.timestamp;
    }
    
    function getCurrentClaimerForTile(uint16 _tileId) view public isValidCaller returns (address) {
        Tile storage currentTile = tiles[_tileId];
        if (currentTile.creationTime == 0) {
            return 0;
        }
        return currentTile.claimer;
    }

    function getCurrentBlockValueAndSellPriceForTile(uint16 _tileId) view public isValidCaller returns (uint, uint) {
        Tile storage currentTile = tiles[_tileId];
        if (currentTile.creationTime == 0) {
            return (0, 0);
        }
        return (currentTile.blockValue, currentTile.sellPrice);
    }
    
    function getBlockValueBalance() view public isValidCaller returns (uint){
        return blockValueBalance;
    }

    function setBlockValueBalance(uint _blockValueBalance) public isValidCaller {
        blockValueBalance = _blockValueBalance;
    }

    function getFeeBalance() view public isValidCaller returns (uint) {
        return feeBalance;
    }

    function setFeeBalance(uint _feeBalance) public isValidCaller {
        feeBalance = _feeBalance;
    }
    
    function getUserBattleValue(address _userId) view public isValidCaller returns (uint) {
        return users[_userId].battleValue;
    }
    
    function setUserBattleValue(address _userId, uint _battleValue) public  isValidCaller {
        users[_userId].battleValue = _battleValue;
    }
    
    function verifyAmount(address _msgSender, uint _msgValue, uint _amount, bool _useBattleValue) view public isValidCaller {
        User storage user = users[_msgSender];
        require(user.creationTime != 0);

        if (_useBattleValue) {
            require(_msgValue == 0);
            require(user.battleValue >= _amount);
        } else {
            require(_amount == _msgValue);
        }
    }
    
    function addBoostFromTile(Tile _tile, address _attacker, address _defender, Boost memory _boost) pure private {
        if (_tile.claimer == _attacker) {
            require(_boost.attackBoost + _tile.blockValue >= _tile.blockValue); // prevent overflow
            _boost.attackBoost += _tile.blockValue;
            _boost.numAttackBoosts += 1;
        } else if (_tile.claimer == _defender) {
            require(_boost.defendBoost + _tile.blockValue >= _tile.blockValue); // prevent overflow
            _boost.defendBoost += _tile.blockValue;
            _boost.numDefendBoosts += 1;
        }
    }

    function calculateBattleBoost(uint16 _tileId, address _attacker, address _defender) view public isValidCaller returns (uint, uint) {
        uint8 x;
        uint8 y;

        (x, y) = BWUtility.fromTileId(_tileId);

        Boost memory boost = Boost(0, 0, 0, 0);
        // We overflow x, y on purpose here if x or y is 0 or 255 - the map overflows and so should adjacency.
        // Go through all adjacent tiles to (x, y).
        if (y != 255) {
            if (x != 255) {
                addBoostFromTile(tiles[BWUtility.toTileId(x+1, y+1)], _attacker, _defender, boost);
            }
            
            addBoostFromTile(tiles[BWUtility.toTileId(x, y+1)], _attacker, _defender, boost);

            if (x != 0) {
                addBoostFromTile(tiles[BWUtility.toTileId(x-1, y+1)], _attacker, _defender, boost);
            }
        }

        if (x != 255) {
            addBoostFromTile(tiles[BWUtility.toTileId(x+1, y)], _attacker, _defender, boost);
        }

        if (x != 0) {
            addBoostFromTile(tiles[BWUtility.toTileId(x-1, y)], _attacker, _defender, boost);
        }

        if (y != 0) {
            if(x != 255) {
                addBoostFromTile(tiles[BWUtility.toTileId(x+1, y-1)], _attacker, _defender, boost);
            }

            addBoostFromTile(tiles[BWUtility.toTileId(x, y-1)], _attacker, _defender, boost);

            if(x != 0) {
                addBoostFromTile(tiles[BWUtility.toTileId(x-1, y-1)], _attacker, _defender, boost);
            }
        }
        // The benefit of boosts is multiplicative (quadratic):
        // - More boost tiles gives a higher total blockValue (the sum of the adjacent tiles)
        // - More boost tiles give a higher multiple of that total blockValue that can be used (10% per adjacent tie)
        // Example:
        //   A) I boost attack with 1 single tile worth 10 finney
        //      -> Total boost is 10 * 1 / 10 = 1 finney
        //   B) I boost attack with 3 tiles worth 1 finney each
        //      -> Total boost is (1+1+1) * 3 / 10 = 0.9 finney
        //   C) I boost attack with 8 tiles worth 2 finney each
        //      -> Total boost is (2+2+2+2+2+2+2+2) * 8 / 10 = 14.4 finney
        //   D) I boost attack with 3 tiles of 1, 5 and 10 finney respectively
        //      -> Total boost is (ss1+5+10) * 3 / 10 = 4.8 finney
        // This division by 10 can&#39;t create fractions since our uint is wei, and we can&#39;t have overflow from the multiplication
        // We do allow fractions of finney here since the boosted values aren&#39;t stored anywhere, only used for attack rolls and sent in events
        boost.attackBoost = (boost.attackBoost / 10 * boost.numAttackBoosts);
        boost.defendBoost = (boost.defendBoost / 10 * boost.numDefendBoosts);

        return (boost.attackBoost, boost.defendBoost);
    }
    
    function censorUser(address _userAddress, bool _censored) public isValidCaller {
        User storage user = users[_userAddress];
        require(user.creationTime != 0);
        user.censored = _censored;
    }
    
    function deleteTile(uint16 _tileId) public isValidCaller {
        delete tiles[_tileId];
    }
    
    function setSellPrice(uint16 _tileId, uint _sellPrice) public isValidCaller {
        tiles[_tileId].sellPrice = _sellPrice;  //testrpc cannot estimate gas when delete is used.
    }

    function deleteOffer(uint16 _tileId) public isValidCaller {
        tiles[_tileId].sellPrice = 0;  //testrpc cannot estimate gas when delete is used.
    }
}