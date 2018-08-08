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

/**
* Copyright 2018 Block Wars Team
*
*/

interface LocalGameI {
    function getBountyBalance() view external returns (uint);
    function getTimeLeftToNextCollect(address _claimer, uint _latestClaimTime) view external returns (uint);
    function collectBounty(address _msgSender, uint _latestClaimTime, uint _amount) external returns (uint);
}

/*
* @title ERC721 interface
*/
contract ERC721 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    //event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    //event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    //event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    //function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    //function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    //function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`&#39;s assets.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    //function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    //function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    //function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    //function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract BW { 
    using SafeMath for uint256;
    address public owner;
    BWService private bwService;
    BWData private bwData;
    bool public paused = false;
    uint private BV_TO_BP_FEE = 5; // 5%
    mapping (uint16 => Prize[]) private prizes; // Use mapping instead of array (key would be a unique priceId) - NO (we want to loop all prices)
    
    struct Prize {
        address token; // BWT or CryptoKiities (ERC721)
        uint tokenId; 
        uint startTime; // To be able to add a price before the game starts
        uint hodlPeriod; // Amount of seconds you have to own the tile before being able to claim this price. One block is ~15 sec.
    }

    event PrizeCreated(uint16 tileId,  address token, uint tokenId, uint creationTime, uint startTime, uint hodlPeriod);
    event PrizeRemoved(uint16 tileId, address token, uint tokenId, uint removeTime);
    event PrizeClaimed(address token, uint tokenId);

    // Add price (only BW owner can do this)
    function addPrize(uint16 _tileId, address _token, uint _tokenId, uint _startTime, uint _hodlPeriod) public isOwner {
        //startTime must be same or after block.timestamp
        uint startTime = _startTime;
        if(startTime < block.timestamp) {
            startTime = block.timestamp;
        }
        // we could check if token exists with ownerOf function in interface, 
        // but if any erc721 token doesn&#39;t implement the function, this function would revert.
        // also cheaper to not make an interface call
        prizes[_tileId].push(Prize(_token, _tokenId, startTime, _hodlPeriod));
        emit PrizeCreated(_tileId, _token, _tokenId, block.timestamp, startTime, _hodlPeriod);
    }

    // Remove price (only BW owner can do this)
    function removePrize(uint16 _tileId, address _token, uint _tokenId) public isOwner {
        Prize[] storage prizeArr = prizes[_tileId];
        require(prizeArr.length > 0);

        for(uint idx = 0; idx < prizeArr.length; ++idx) {
            if(prizeArr[idx].tokenId == _tokenId && prizeArr[idx].token == _token) {
                delete prizeArr[idx];
                emit PrizeRemoved(_tileId, _token, _tokenId, block.timestamp);
            }
        }
    }

    // Add price (only BW owner can do this)
    function claimPrize(address _tokenAddress, uint16 _tileId) public isNotPaused isNotContractCaller {
        ERC721 token = ERC721(_tokenAddress);
        Prize[] storage prizeArr = prizes[_tileId];
        require(prizeArr.length > 0);
        address claimer;
        uint blockValue;
        uint lastClaimTime;
        uint sellPrice;
        (claimer, blockValue, lastClaimTime, sellPrice) = bwData.getTile(_tileId);
        require(lastClaimTime != 0 && claimer == msg.sender);

        for(uint idx = 0; idx < prizeArr.length; ++idx) {
            if(prizeArr[idx].startTime.add(prizeArr[idx].hodlPeriod) <= block.timestamp
                && lastClaimTime.add(prizeArr[idx].hodlPeriod) <= block.timestamp) {
                uint tokenId = prizeArr[idx].tokenId;
                address tokenOwner = token.ownerOf(tokenId);
                delete prizeArr[idx];
                token.safeTransferFrom(tokenOwner, msg.sender, tokenId); //Will revert if token does not exists
                emit PrizeClaimed(_tokenAddress, tokenId);
            }
        }
    }

    modifier isOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    // Checks if entire game (except battle value withdraw) is paused or not.
    modifier isNotPaused {
        if (paused) {
            revert();
        }
        _;
    }

    // Only allow wallets to call this function, not contracts.
    modifier isNotContractCaller {
        require(msg.sender == tx.origin);
        _;
    }

    // All contract event types.
    event UserCreated(address userAddress, bytes32 name, bytes imageUrl, bytes32 tag, bytes32 homeUrl, uint creationTime, address invitedBy);
    event UserCensored(address userAddress, bool isCensored);
    event TransferTileFromOwner(uint16 tileId, address seller, address buyer, uint acceptTime); // Sent when a user buys a tile from another user, by accepting a tile offer
    event UserUpdated(address userAddress, bytes32 name, bytes imageUrl, bytes32 tag, bytes32 homeUrl, uint updateTime);
    event TileRetreated(uint16 tileId, address owner, uint amount, uint newBlockValue, uint retreatTime);
    event BountyCollected(uint tile, address userAddress, uint amount, uint amountCollected, uint collectedTime, uint latestClaimTime);

    // BASIC CONTRACT FUNCTIONS
    constructor(address _bwService, address _bwData) public {
        bwService = BWService(_bwService);
        bwData = BWData(_bwData);
        owner = msg.sender;
    }

    // Can&#39;t send funds straight to this contract. Avoid people sending by mistake.
    function () payable public isOwner {

    }

    // Allow a new user to claim one or more previously unclaimed tiles by paying Ether.
    function claimTilesForNewUser(bytes32 _name, bytes _imageUrl, bytes32 _tag, bytes32 _homeUrl, uint16[] _claimedTileIds, address _invitedBy) payable public isNotPaused isNotContractCaller {
        bwData.addUser(msg.sender);
        emit UserCreated(msg.sender, _name, _imageUrl, _tag, _homeUrl, block.timestamp, _invitedBy);
        bwService.storeInitialClaim(msg.sender, _claimedTileIds, msg.value, false);
    }

    // Allow an existing user to claim one or more previously unclaimed tiles by paying Ether.
    function claimTilesForExistingUser(uint16[] _claimedTileIds, uint _claimAmount, bool _useBattleValue) payable public isNotPaused isNotContractCaller {
        bwService.verifyAmount(msg.sender, msg.value, _claimAmount, _useBattleValue);
        bwService.storeInitialClaim(msg.sender, _claimedTileIds, _claimAmount, _useBattleValue);
    }

    // Allow users to change name, image URL, tag and home URL. Not censored status or battle value though.
    function updateUser(bytes32 _name, bytes _imageUrl, bytes32 _tag, bytes32 _homeUrl) public isNotPaused isNotContractCaller {
        require(bwData.hasUser(msg.sender));
        // All the updated values are stored in events only so there&#39;s no state to update on the contract here.
        emit UserUpdated(msg.sender, _name, _imageUrl, _tag, _homeUrl, block.timestamp);
    }
    
    // This function fortifies multiple previously claimed tiles in a single transaction.
    // The value assigned to each tile is the msg.value divided by the number of tiles fortified.
    // The msg.value is required to be an even multiple of the number of tiles fortified.
    // Only tiles owned by msg.sender can be fortified.
    function fortifyClaims(uint16[] _claimedTileIds, uint _fortifyAmount, bool _useBattleValue) payable public isNotPaused isNotContractCaller {
        bwService.verifyAmount(msg.sender, msg.value, _fortifyAmount, _useBattleValue);
        bwService.fortifyClaims(msg.sender, _claimedTileIds, _fortifyAmount, _useBattleValue);
    }

    // A new user attacks a tile claimed by someone else, trying to make it theirs through battle.
    function attackTileForNewUser(uint16 _tileId, bytes32 _name, bytes _imageUrl, bytes32 _tag, bytes32 _homeUrl, address _invitedBy) payable public isNotPaused isNotContractCaller {
        bwData.addUser(msg.sender);
        emit UserCreated(msg.sender, _name, _imageUrl, _tag, _homeUrl, block.timestamp, _invitedBy);
        bwService.attackTile(msg.sender, _tileId, msg.value, false);
    }

    // An existing user attacks a tile claimed by someone else, trying to make it theirs through battle.
    function attackTileForExistingUser(uint16 _tileId, uint _attackAmount, bool _useBattleValue) payable public isNotPaused isNotContractCaller {
        bwService.verifyAmount(msg.sender, msg.value, _attackAmount, _useBattleValue);
        bwService.attackTile(msg.sender, _tileId, _attackAmount, _useBattleValue);
    }
    
    // Move "army" = block value from one block to an adjacent block. Moving ALL value equates giving up ownership of the source tile.
    function moveBlockValue(uint8 _xSource, uint8 _ySource, uint8 _xDest, uint8 _yDest, uint _moveAmount) public isNotPaused isNotContractCaller {
        require(_moveAmount > 0);
        bwService.moveBlockValue(msg.sender, _xSource, _ySource, _xDest, _yDest, _moveAmount);
    }

    // Allow users to withdraw battle value in Ether.
    function withdrawBattleValue(uint _battleValueInWei) public isNotContractCaller {
        require(_battleValueInWei > 0);
        uint amountToWithdraw = bwService.withdrawBattleValue(msg.sender, _battleValueInWei);
        msg.sender.transfer(amountToWithdraw);
    }

    // Transfer block value to battle points for free 
    function transferBlockValueToBattleValue(uint16 _tileId, uint _amount) public isNotContractCaller {
        require(_amount > 0);
        address claimer;
        uint blockValue;
        (claimer, blockValue) = bwData.getTileClaimerAndBlockValue(_tileId);
        require(claimer == msg.sender);
        uint newBlockValue = blockValue.sub(_amount);
        // Must transfer the entire block value or leave at least 5
        require(newBlockValue == 0 || newBlockValue >= 5 finney);
        if(newBlockValue == 0) {
            bwData.deleteTile(_tileId);
        } else {
            bwData.updateTileBlockValue(_tileId, newBlockValue);
            bwData.deleteOffer(_tileId); // Offer invalid since block value has changed
        }
        
        uint fee = _amount.mul(BV_TO_BP_FEE).div(100);
        uint userAmount = _amount.sub(fee);
        uint feeBalance = bwData.getFeeBalance();
        feeBalance = feeBalance.add(fee);
        bwData.setFeeBalance(feeBalance);

        bwService.addUserBattleValue(msg.sender, userAmount);
        bwService.subGlobalBlockValueBalance(_amount);
        emit TileRetreated(_tileId, msg.sender, _amount, newBlockValue, block.timestamp);
    }

    // -------- LOCAL GAME FUNCTIONS ----------

    function getLocalBountyBalance(uint16 _tileId) view public isNotContractCaller returns (uint) {
        address localGameAddress = bwService.getLocalGame(_tileId);
        require(localGameAddress != 0);
        LocalGameI localGame = LocalGameI(localGameAddress);
        return localGame.getBountyBalance();
    }

    function getTimeLeftToNextLocalBountyCollect(uint16 _tileId) view public isNotContractCaller returns (uint) {
        address localGameAddress = bwService.getLocalGame(_tileId);
        require(localGameAddress != 0);
        LocalGameI localGame = LocalGameI(localGameAddress);
        address claimer;
        uint blockValue;
        uint latestClaimTime;
        uint sellPrice;
        (claimer, blockValue, latestClaimTime, sellPrice) = bwData.getTile(_tileId);
        return localGame.getTimeLeftToNextCollect(claimer, latestClaimTime);
    }

    function collectLocalBounty(uint16 _tileId, uint _amount) public isNotContractCaller {
        address localGameAddress = bwService.getLocalGame(_tileId);
        require(localGameAddress != 0);
        address claimer;
        uint blockValue;
        uint latestClaimTime;
        uint sellPrice;
        (claimer, blockValue, latestClaimTime, sellPrice) = bwData.getTile(_tileId);
        require(latestClaimTime != 0 && claimer == msg.sender);
        
        LocalGameI localGame = LocalGameI(localGameAddress);
        uint amountCollected = localGame.collectBounty(msg.sender, latestClaimTime, _amount);
        emit BountyCollected(_tileId, msg.sender, _amount, amountCollected, block.timestamp, latestClaimTime);
    }

    // -------- OWNER-ONLY FUNCTIONS ----------

    // Only used by owner for raffle. Owner need name, address and picture from user.
    // These users can then be given tiles by owner using transferTileFromOwner.
    function createNewUser(bytes32 _name, bytes _imageUrl, bytes32 _tag, bytes32 _homeUrl, address _user) public isOwner {
        bwData.addUser(_user);
        emit UserCreated(_user, _name, _imageUrl, _tag, _homeUrl, block.timestamp, msg.sender); //check on client if invitedBy is owner.
    }

    // Allow updating censored status. Owner only. In case someone uploads offensive content.
    // The contract owners reserve the right to apply censorship. This will mean that the
    // name, tag or URL images might not be displayed for a censored user.
    function censorUser(address _userAddress, bool _censored) public isOwner {
        bwData.censorUser(_userAddress, _censored);
        emit UserCensored(_userAddress, _censored);
    }

    // Pause the entire game, but let users keep withdrawing battle value
    function setPaused(bool _paused) public isOwner {
        paused = _paused;
    }

    function kill() public isOwner {
        selfdestruct(owner);
    }
    
    function withdrawFee() public isOwner {
        uint balance = address(this).balance;
        uint amountToWithdraw = bwData.getFeeBalance();

        if (balance < amountToWithdraw) { // Should never happen, but paranoia
            amountToWithdraw = balance;
        }
        bwData.setFeeBalance(0);

        owner.transfer(amountToWithdraw);
    }

    function getFee() view public isOwner returns (uint) {
        return bwData.getFeeBalance();
    }

    function setBvToBpFee(uint _feePercentage) public isOwner {
        BV_TO_BP_FEE = _feePercentage;
    }

    function depositBattleValue(address _user) payable public isOwner {
        require(msg.value % 1 finney == 0); // Must be divisible by 1 finney
        bwService.addUserBattleValue(_user, msg.value);
    }

    // The owner can transfer ownership of own tiles to other users, as prizes in competitions.
    function transferTileFromOwner(uint16[] _tileIds, address _newOwner) public isOwner {
        for(uint i = 0; i < _tileIds.length; ++i) {
            uint16 tileId = _tileIds[i];
            address claimer = bwData.getCurrentClaimerForTile(tileId);
            require(claimer == owner);
            bwData.setClaimerForTile(tileId, _newOwner);
            
            emit TransferTileFromOwner(tileId, _newOwner, msg.sender, block.timestamp);
        }
    }

    // Allow us to transfer out airdropped tokens if we ever receive any
    function transferTokens(address _tokenAddress, address _recipient) public isOwner {
        ERC20I token = ERC20I(_tokenAddress);
        require(token.transfer(_recipient, token.balanceOf(this)));
    }
}