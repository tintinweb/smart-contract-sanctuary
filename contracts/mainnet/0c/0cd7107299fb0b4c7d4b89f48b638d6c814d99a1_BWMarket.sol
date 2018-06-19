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



interface ERC20I {
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function balanceOf(address _holder) external view returns (uint256);
}


contract BWService {
    using SafeMath for uint256;
    address private owner;
    address private bw;
    address private bwMarket;
    BWData private bwData;
    uint private seed = 42;
    uint private WITHDRAW_FEE = 5; // 5%
    uint private ATTACK_FEE = 5; // 5%
    uint private ATTACK_BOOST_CAP = 300; // 300%
    uint private DEFEND_BOOST_CAP = 300; // 300%
    uint private ATTACK_BOOST_MULTIPLIER = 100; // 100%
    uint private DEFEND_BOOST_MULTIPLIER = 100; // 100%
    mapping (uint16 => address) private localGames;
    
    modifier isOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }  

    modifier isValidCaller {
        if (msg.sender != bw && msg.sender != bwMarket) {
            revert();
        }
        _;
    }

    event TileClaimed(uint16 tileId, address newClaimer, uint priceInWei, uint creationTime);
    event TileFortified(uint16 tileId, address claimer, uint addedValueInWei, uint priceInWei, uint fortifyTime); // Sent when a user fortifies an existing claim by bumping its value.
    event TileAttackedSuccessfully(uint16 tileId, address attacker, uint attackAmount, uint totalAttackAmount, address defender, uint defendAmount, uint totalDefendAmount, uint attackRoll, uint attackTime); // Sent when a user successfully attacks a tile.    
    event TileDefendedSuccessfully(uint16 tileId, address attacker, uint attackAmount, uint totalAttackAmount, address defender, uint defendAmount, uint totalDefendAmount, uint attackRoll, uint defendTime); // Sent when a user successfully defends a tile when attacked.    
    event BlockValueMoved(uint16 sourceTileId, uint16 destTileId, address owner, uint movedBlockValue, uint postSourceValue, uint postDestValue, uint moveTime); // Sent when a user buys a tile from another user, by accepting a tile offer
    event UserBattleValueUpdated(address userAddress, uint battleValue, bool isWithdraw);

    // Constructor.
    constructor(address _bwData) public {
        bwData = BWData(_bwData);
        owner = msg.sender;
    }

    // Can&#39;t send funds straight to this contract. Avoid people sending by mistake.
    function () payable public {
        revert();
    }

    // OWNER-ONLY FUNCTIONS
    function kill() public isOwner {
        selfdestruct(owner);
    }

    function setValidBwCaller(address _bw) public isOwner {
        bw = _bw;
    }
    
    function setValidBwMarketCaller(address _bwMarket) public isOwner {
        bwMarket = _bwMarket;
    }

    function setWithdrawFee(uint _feePercentage) public isOwner {
        WITHDRAW_FEE = _feePercentage;
    }

    function setAttackFee(uint _feePercentage) public isOwner {
        ATTACK_FEE = _feePercentage;
    }

    function setAttackBoostMultipler(uint _multiplierPercentage) public isOwner {
        ATTACK_BOOST_MULTIPLIER = _multiplierPercentage;
    }

    function setDefendBoostMultiplier(uint _multiplierPercentage) public isOwner {
        DEFEND_BOOST_MULTIPLIER = _multiplierPercentage;
    }

    function setAttackBoostCap(uint _capPercentage) public isOwner {
        ATTACK_BOOST_CAP = _capPercentage;
    }

    function setDefendBoostCap(uint _capPercentage) public isOwner {
        DEFEND_BOOST_CAP = _capPercentage;
    }

    // TILE-RELATED FUNCTIONS
    // This function claims multiple previously unclaimed tiles in a single transaction.
    // The value assigned to each tile is the msg.value divided by the number of tiles claimed.
    // The msg.value is required to be an even multiple of the number of tiles claimed.
    function storeInitialClaim(address _msgSender, uint16[] _claimedTileIds, uint _claimAmount, bool _useBattleValue) public isValidCaller {
        uint tileCount = _claimedTileIds.length;
        require(tileCount > 0);
        require(_claimAmount >= 1 finney * tileCount); // ensure enough funds paid for all tiles
        require(_claimAmount % tileCount == 0); // ensure payment is an even multiple of number of tiles claimed

        uint valuePerBlockInWei = _claimAmount.div(tileCount); // Due to requires above this is guaranteed to be an even number
        require(valuePerBlockInWei >= 5 finney);

        if (_useBattleValue) {
            subUserBattleValue(_msgSender, _claimAmount, false);  
        }

        addGlobalBlockValueBalance(_claimAmount);

        uint16 tileId;
        bool isNewTile;
        for (uint16 i = 0; i < tileCount; i++) {
            tileId = _claimedTileIds[i];
            isNewTile = bwData.isNewTile(tileId); // Is length 0 if first time purchased
            require(isNewTile); // Can only claim previously unclaimed tiles.

            // Send claim event
            emit TileClaimed(tileId, _msgSender, valuePerBlockInWei, block.timestamp);

            // Update contract state with new tile ownership.
            bwData.storeClaim(tileId, _msgSender, valuePerBlockInWei);
        }
    }

    function fortifyClaims(address _msgSender, uint16[] _claimedTileIds, uint _fortifyAmount, bool _useBattleValue) public isValidCaller {
        uint tileCount = _claimedTileIds.length;
        require(tileCount > 0);

        address(this).balance.add(_fortifyAmount); // prevent overflow with SafeMath
        require(_fortifyAmount % tileCount == 0); // ensure payment is an even multiple of number of tiles fortified
        uint addedValuePerTileInWei = _fortifyAmount.div(tileCount); // Due to requires above this is guaranteed to be an even number
        require(_fortifyAmount >= 1 finney * tileCount); // ensure enough funds paid for all tiles

        address claimer;
        uint blockValue;
        for (uint16 i = 0; i < tileCount; i++) {
            (claimer, blockValue) = bwData.getTileClaimerAndBlockValue(_claimedTileIds[i]);
            require(claimer != 0); // Can&#39;t do this on never-owned tiles
            require(claimer == _msgSender); // Only current claimer can fortify claim

            if (_useBattleValue) {
                subUserBattleValue(_msgSender, addedValuePerTileInWei, false);
            }
            
            fortifyClaim(_msgSender, _claimedTileIds[i], addedValuePerTileInWei);
        }
    }

    function fortifyClaim(address _msgSender, uint16 _claimedTileId, uint _fortifyAmount) private {
        uint blockValue;
        uint sellPrice;
        (blockValue, sellPrice) = bwData.getCurrentBlockValueAndSellPriceForTile(_claimedTileId);
        uint updatedBlockValue = blockValue.add(_fortifyAmount);
        // Send fortify event
        emit TileFortified(_claimedTileId, _msgSender, _fortifyAmount, updatedBlockValue, block.timestamp);
        
        // Update tile value. The tile has been fortified by bumping up its value.
        bwData.updateTileBlockValue(_claimedTileId, updatedBlockValue);

        // Track addition to global block value
        addGlobalBlockValueBalance(_fortifyAmount);
    }

    // Return a pseudo random number between lower and upper bounds
    // given the number of previous blocks it should hash.
    // Random function copied from https://github.com/axiomzen/eth-random/blob/master/contracts/Random.sol.
    // Changed sha3 to keccak256, then modified.
    // Changed random range from uint64 to uint (=uint256).
    function random(uint _upper) private returns (uint)  {
        seed = uint(keccak256(blockhash(block.number - 1), block.coinbase, block.timestamp, seed, address(0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE).balance));
        return seed % _upper;
    }

    // A user tries to claim a tile that&#39;s already owned by another user. A battle ensues.
    // A random roll is done with % based on attacking vs defending amounts.
    function attackTile(address _msgSender, uint16 _tileId, uint _attackAmount, bool _useBattleValue) public isValidCaller {
        require(_attackAmount >= 1 finney);         // Don&#39;t allow attacking with less than one base tile price.
        require(_attackAmount % 1 finney == 0);

        address claimer;
        uint blockValue;
        (claimer, blockValue) = bwData.getTileClaimerAndBlockValue(_tileId);
        
        require(claimer != 0); // Can&#39;t do this on never-owned tiles
        require(claimer != _msgSender); // Can&#39;t attack one&#39;s own tiles
        require(claimer != owner); // Can&#39;t attack owner&#39;s tiles because it is used for raffle.

        // Calculate boosted amounts for attacker and defender
        // The base attack amount is sent in the by the user.
        // The base defend amount is the attacked tile&#39;s current blockValue.
        uint attackBoost;
        uint defendBoost;
        (attackBoost, defendBoost) = bwData.calculateBattleBoost(_tileId, _msgSender, claimer);

        // Adjust boost to optimize game strategy
        attackBoost = attackBoost.mul(ATTACK_BOOST_MULTIPLIER).div(100);
        defendBoost = defendBoost.mul(DEFEND_BOOST_MULTIPLIER).div(100);
        
        // Cap the boost to minimize its impact (prevents whales somehow)
        if (attackBoost > _attackAmount.mul(ATTACK_BOOST_CAP).div(100)) {
            attackBoost = _attackAmount.mul(ATTACK_BOOST_CAP).div(100);
        }
        if (defendBoost > blockValue.mul(DEFEND_BOOST_CAP).div(100)) {
            defendBoost = blockValue.mul(DEFEND_BOOST_CAP).div(100);
        }

        uint totalAttackAmount = _attackAmount.add(attackBoost);
        uint totalDefendAmount = blockValue.add(defendBoost);

        // Verify that attack odds are within allowed range.
        require(totalAttackAmount.div(10) <= totalDefendAmount); // Disallow attacks with more than 1000% of defendAmount
        require(totalAttackAmount >= totalDefendAmount.div(10)); // Disallow attacks with less than 10% of defendAmount

        uint attackFeeAmount = _attackAmount.mul(ATTACK_FEE).div(100);
        uint attackAmountAfterFee = _attackAmount.sub(attackFeeAmount);
        
        updateFeeBalance(attackFeeAmount);

        // The battle considers boosts.
        uint attackRoll = random(totalAttackAmount.add(totalDefendAmount)); // This is where the excitement happens!

        //gas cost of attack branch is higher than denfense branch solving MSB1
        if (attackRoll > totalDefendAmount) {
            // Change block owner but keep same block value (attacker got battlevalue instead)
            bwData.setClaimerForTile(_tileId, _msgSender);

            // Tile successfully attacked!
            if (_useBattleValue) {
                // Withdraw followed by deposit of same amount to prevent MSB1
                addUserBattleValue(_msgSender, attackAmountAfterFee); // Don&#39;t include boost here!
                subUserBattleValue(_msgSender, attackAmountAfterFee, false);
            } else {
                addUserBattleValue(_msgSender, attackAmountAfterFee); // Don&#39;t include boost here!
            }
            addUserBattleValue(claimer, 0);

            bwData.updateTileTimeStamp(_tileId);
            // Send update event
            emit TileAttackedSuccessfully(_tileId, _msgSender, attackAmountAfterFee, totalAttackAmount, claimer, blockValue, totalDefendAmount, attackRoll, block.timestamp);
        } else {
            bwData.setClaimerForTile(_tileId, claimer); //should be old owner
            // Tile successfully defended!
            if (_useBattleValue) {
                subUserBattleValue(_msgSender, attackAmountAfterFee, false); // Don&#39;t include boost here!
            }
            addUserBattleValue(claimer, attackAmountAfterFee); // Don&#39;t include boost here!
            
            // Send update event
            emit TileDefendedSuccessfully(_tileId, _msgSender, attackAmountAfterFee, totalAttackAmount, claimer, blockValue, totalDefendAmount, attackRoll, block.timestamp);
        }
    }

    function updateFeeBalance(uint attackFeeAmount) private {
        uint feeBalance = bwData.getFeeBalance();
        feeBalance = feeBalance.add(attackFeeAmount);
        bwData.setFeeBalance(feeBalance);
    }

    function moveBlockValue(address _msgSender, uint8 _xSource, uint8 _ySource, uint8 _xDest, uint8 _yDest, uint _moveAmount) public isValidCaller {
        uint16 sourceTileId = BWUtility.toTileId(_xSource, _ySource);
        uint16 destTileId = BWUtility.toTileId(_xDest, _yDest);

        address sourceTileClaimer;
        address destTileClaimer;
        uint sourceTileBlockValue;
        uint destTileBlockValue;
        (sourceTileClaimer, sourceTileBlockValue) = bwData.getTileClaimerAndBlockValue(sourceTileId);
        (destTileClaimer, destTileBlockValue) = bwData.getTileClaimerAndBlockValue(destTileId);

        uint newBlockValue = sourceTileBlockValue.sub(_moveAmount);
        // Must transfer the entire block value or leave at least 5
        require(newBlockValue == 0 || newBlockValue >= 5 finney);

        require(sourceTileClaimer == _msgSender);
        require(destTileClaimer == _msgSender);
        require(_moveAmount >= 1 finney); // Can&#39;t be less
        require(_moveAmount % 1 finney == 0); // Move amount must be in multiples of 1 finney
        // require(sourceTile.blockValue - _moveAmount >= BASE_TILE_PRICE_WEI); // Must always leave some at source
        
        require(BWUtility.isAdjacent(_xSource, _ySource, _xDest, _yDest));

        sourceTileBlockValue = sourceTileBlockValue.sub(_moveAmount);
        destTileBlockValue = destTileBlockValue.add(_moveAmount);

        // If ALL block value was moved away from the source tile, we lose our claim to it. It becomes ownerless.
        if (sourceTileBlockValue == 0) {
            bwData.deleteTile(sourceTileId);
        } else {
            bwData.updateTileBlockValue(sourceTileId, sourceTileBlockValue);
            bwData.deleteOffer(sourceTileId); // Offer invalid since block value has changed
        }

        bwData.updateTileBlockValue(destTileId, destTileBlockValue);
        bwData.deleteOffer(destTileId);   // Offer invalid since block value has changed
        emit BlockValueMoved(sourceTileId, destTileId, _msgSender, _moveAmount, sourceTileBlockValue, destTileBlockValue, block.timestamp);        
    }

    function verifyAmount(address _msgSender, uint _msgValue, uint _amount, bool _useBattleValue) view public isValidCaller {
        if (_useBattleValue) {
            require(_msgValue == 0);
            require(bwData.getUserBattleValue(_msgSender) >= _amount);
        } else {
            require(_amount == _msgValue);
        }
    }

    function setLocalGame(uint16 _tileId, address localGameAddress) public isOwner {
        localGames[_tileId] = localGameAddress;
    }

    function getLocalGame(uint16 _tileId) view public isValidCaller returns (address) {
        return localGames[_tileId];
    }

    // BATTLE VALUE FUNCTIONS
    function withdrawBattleValue(address msgSender, uint _battleValueInWei) public isValidCaller returns (uint) {
        //require(_battleValueInWei % 1 finney == 0); // Must be divisible by 1 finney
        uint fee = _battleValueInWei.mul(WITHDRAW_FEE).div(100); // Since we divide by 20 we can never create infinite fractions, so we&#39;ll always count in whole wei amounts.
        uint amountToWithdraw = _battleValueInWei.sub(fee);
        uint feeBalance = bwData.getFeeBalance();
        feeBalance = feeBalance.add(fee);
        bwData.setFeeBalance(feeBalance);
        subUserBattleValue(msgSender, _battleValueInWei, true);
        return amountToWithdraw;
    }

    function addUserBattleValue(address _userId, uint _amount) public isValidCaller {
        uint userBattleValue = bwData.getUserBattleValue(_userId);
        uint newBattleValue = userBattleValue.add(_amount);
        bwData.setUserBattleValue(_userId, newBattleValue); // Don&#39;t include boost here!
        emit UserBattleValueUpdated(_userId, newBattleValue, false);
    }
    
    function subUserBattleValue(address _userId, uint _amount, bool _isWithdraw) public isValidCaller {
        uint userBattleValue = bwData.getUserBattleValue(_userId);
        require(_amount <= userBattleValue); // Must be less than user&#39;s battle value - also implicitly checks that underflow isn&#39;t possible
        uint newBattleValue = userBattleValue.sub(_amount);
        bwData.setUserBattleValue(_userId, newBattleValue); // Don&#39;t include boost here!
        emit UserBattleValueUpdated(_userId, newBattleValue, _isWithdraw);
    }

    function addGlobalBlockValueBalance(uint _amount) public isValidCaller {
        // Track addition to global block value.
        uint blockValueBalance = bwData.getBlockValueBalance();
        bwData.setBlockValueBalance(blockValueBalance.add(_amount));
    }

    function subGlobalBlockValueBalance(uint _amount) public isValidCaller {
        // Track addition to global block value.
        uint blockValueBalance = bwData.getBlockValueBalance();
        bwData.setBlockValueBalance(blockValueBalance.sub(_amount));
    }

    // Allow us to transfer out airdropped tokens if we ever receive any
    function transferTokens(address _tokenAddress, address _recipient) public isOwner {
        ERC20I token = ERC20I(_tokenAddress);
        require(token.transfer(_recipient, token.balanceOf(this)));
    }
}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BWMarket {
    using SafeMath for uint256;
    address private owner;
    BWService private bwService;
    BWData private bwData;
    bool private allowMarketplace = true;
    bool public paused = false;
    uint private MARKETPLACE_FEE = 5; // 5%
    
    modifier isOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    modifier isMarketplaceEnabled {
        if (!allowMarketplace) {
            revert();
        }
        _;
    }

    // Only allow wallets to call this function, not contracts.
    modifier isNotContractCaller {
        require(msg.sender == tx.origin);
        _;
    }
    
    event TileOfferCreated(uint16 tileId, address seller, uint priceInWei, uint creationTime); // Sent when user offers to sell a tile
    event TileOfferUpdated(uint16 tileId, address seller, uint priceInWei, uint updateTime); // Sent when user updates the price of an offer to sell a tile
    event TileOfferCancelled(uint16 tileId, uint cancelTime, address seller); // Sent when a seller withdraws an offer
    event TileOfferAccepted(uint16 tileId, address seller, address buyer, uint priceInWei, uint acceptTime); // Sent when a user buys a tile from another user, by accepting a tile offer

    constructor(address _bwService, address _bwData) public {
        bwService = BWService(_bwService);
        bwData = BWData(_bwData);
        owner = msg.sender;
    }

    // Can&#39;t send funds straight to this contract. Avoid people sending by mistake.
    function () payable public {
        revert();
    }

    function kill() public isOwner {
        selfdestruct(owner);
    }

    function setAllowMarketplace(bool _allowMarketplace) public isOwner {
        allowMarketplace = _allowMarketplace;
    }

    function setMarketplaceFee(uint _feePercentage) public isOwner {
        MARKETPLACE_FEE = _feePercentage;
    }
    
    // Lets a tile owner offer a tile for sale.
    function createOffer(uint16 _tileId, uint _offerInWei) public isMarketplaceEnabled isNotContractCaller {
        require(_offerInWei % 1 finney == 0);           //Don&#39;t allow decimals
        require(_offerInWei >= 1 finney);    //Check for > 1 finney
        
        address claimer;
        uint blockValue;
        uint creationTime;
        uint sellPrice;
        (claimer, blockValue, creationTime, sellPrice) = bwData.getTile(_tileId);
        
        require(creationTime > 0); // Can&#39;t do this on never-owned tiles
        require(claimer == msg.sender); // Only current claimer can offer to sell tile

        bwData.setSellPrice(_tileId, _offerInWei);
        // Create or update offer
        if (sellPrice == 0) {   //TODO : Use on event? Looks similair
            emit TileOfferCreated(_tileId, msg.sender, _offerInWei, block.timestamp);
        } else {
            emit TileOfferUpdated(_tileId, msg.sender, _offerInWei, block.timestamp);
        }
    }

    function acceptOffer(uint16 _tileId, uint _acceptedBlockValue) payable public isMarketplaceEnabled isNotContractCaller {
        uint balance = address(this).balance.add(msg.value);
        
        address seller;
        uint blockValue;
        uint creationTime;
        uint sellPrice;
        (seller, blockValue, creationTime, sellPrice) = bwData.getTile(_tileId);
        // We don&#39;t check if buyer is not the seller to save gas
        require(creationTime > 0); // Can&#39;t do this on never-owned tiles
        require(sellPrice != 0); // Verify that there is an offer for this tile
        require(sellPrice == msg.value); // Must pay the price of the offer

        // Prevent bait-and-switch sales (moving block value around in same mined Ethereum block as accept happens),
        // this way we pass in the block value the buyer believes he&#39;s going to get and make sure it&#39;s actually still set to that value
        require(blockValue == _acceptedBlockValue);

        // This is where we actually send ether AWAY from the contract. Will require careful testing.
        require(balance >= sellPrice); // Ensure contract has funds to send to users.

        // Send offer accepted event
        emit TileOfferAccepted(_tileId, seller, msg.sender, sellPrice, block.timestamp); // Sent when a user buys a tile from another user, by accepting a tile offer

        uint fee = sellPrice.mul(MARKETPLACE_FEE).div(100);
        uint userAmount = sellPrice.sub(fee);
        uint feeBalance = bwData.getFeeBalance();
        feeBalance = feeBalance.add(fee);
        bwData.setFeeBalance(feeBalance);

        // Update storage
        bwData.deleteOffer(_tileId); // Must zero this before transfer() is called to avoid re-entrancy attacks.
        bwData.setClaimerForTile(_tileId, msg.sender); // Update contract state with new tile ownership. Note that this changes the tile.claimer variable!

        // Send funds AFTER updating storage and AFTER zeroing sellPrice.
        seller.transfer(userAmount);
    }

    function cancelOffer(uint16 _tileId) public isMarketplaceEnabled isNotContractCaller {
        address claimer = bwData.getCurrentClaimerForTile(_tileId);
        require(claimer == msg.sender); // Only the creator of an offer can withdraw it (this also catches the case where there is no offer)
        bwData.deleteOffer(_tileId);
        emit TileOfferCancelled(_tileId, now, msg.sender);    //now for future use in client.
    }

    // Allow us to transfer out airdropped tokens if we ever receive any
    function transferTokens(address _tokenAddress, address _recipient) public isOwner {
        ERC20I token = ERC20I(_tokenAddress);
        require(token.transfer(_recipient, token.balanceOf(this)));
    }
}