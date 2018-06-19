pragma solidity ^0.4.18;

contract Manager {
    address public ceo;
    address public cfo;
    address public coo;
    address public cao;

    event OwnershipTransferred(address previousCeo, address newCeo);
    event Pause();
    event Unpause();


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Manager() public {
        coo = msg.sender; 
        cfo = 0x7810704C6197aFA95e940eF6F719dF32657AD5af;
        ceo = 0x96C0815aF056c5294Ad368e3FBDb39a1c9Ae4e2B;
        cao = 0xC4888491B404FfD15cA7F599D624b12a9D845725;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyCEO() {
        require(msg.sender == ceo);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == coo);
        _;
    }

    modifier onlyCAO() {
        require(msg.sender == cao);
        _;
    }
    
    bool allowTransfer = false;
    
    function changeAllowTransferState() public onlyCOO {
        if (allowTransfer) {
            allowTransfer = false;
        } else {
            allowTransfer = true;
        }
    }
    
    modifier whenTransferAllowed() {
        require(allowTransfer);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newCeo.
    * @param newCeo The address to transfer ownership to.
    */
    function demiseCEO(address newCeo) public onlyCEO {
        require(newCeo != address(0));
        emit OwnershipTransferred(ceo, newCeo);
        ceo = newCeo;
    }

    function setCFO(address newCfo) public onlyCEO {
        require(newCfo != address(0));
        cfo = newCfo;
    }

    function setCOO(address newCoo) public onlyCEO {
        require(newCoo != address(0));
        coo = newCoo;
    }

    function setCAO(address newCao) public onlyCEO {
        require(newCao != address(0));
        cao = newCao;
    }

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyCAO whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyCAO whenPaused public {
        paused = false;
        emit Unpause();
    }
}


contract AlchemyBase is Manager {

    // Assets of each account
    mapping (address => bytes32[8]) assets;

    // Event
    event Transfer(address from, address to);

    // Get all assets of a particular account
    function assetOf(address account) public view returns(bytes32[8]) {
        return assets[account];
    }

    function _checkAndAdd(bytes32 x, bytes32 y) internal pure returns(bytes32) {
        bytes32 mask = bytes32(255); // 0x11111111

        bytes32 result;

        uint maskedX;
        uint maskedY;
        uint maskedResult;

        for (uint i = 0; i < 31; i++) {
            // Get current mask
            if (i > 0) {
                mask = mask << 8;
            }

            // Get masked values
            maskedX = uint(x & mask);
            maskedY = uint(y & mask);
            maskedResult = maskedX + maskedY;

            // Prevent overflow
            require(maskedResult < (2 ** (8 * (i + 1))));

            // Clear result digits in masked position
            result = (result ^ mask) & result;

            // Write to result
            result = result | bytes32(maskedResult);
        }

        return result;
    }

    function _checkAndSub(bytes32 x, bytes32 y) internal pure returns(bytes32) {
        bytes32 mask = bytes32(255); // 0x11111111

        bytes32 result;

        uint maskedX;
        uint maskedY;
        uint maskedResult;

        for (uint i = 0; i < 31; i++) {
            // Get current mask
            if (i > 0) {
                mask = mask << 8;
            }

            // Get masked values
            maskedX = uint(x & mask);
            maskedY = uint(y & mask);

            // Ensure x >= y
            require(maskedX >= maskedY);

            // Calculate result
            maskedResult = maskedX - maskedY;

            // Clear result digits in masked position
            result = (result ^ mask) & result;

            // Write to result
            result = result | bytes32(maskedResult);
        }

        return result;
    }

    // Transfer assets from one account to another
    function transfer(address to, bytes32[8] value) public whenNotPaused whenTransferAllowed {
        // One can not transfer assets to self
        require(msg.sender != to);
        bytes32[8] memory assetFrom = assets[msg.sender];
        bytes32[8] memory assetTo = assets[to];

        for (uint256 i = 0; i < 8; i++) {
            assetFrom[i] = _checkAndSub(assetFrom[i], value[i]);
            assetTo[i] = _checkAndAdd(assetTo[i], value[i]);
        }

        assets[msg.sender] = assetFrom;
        assets[to] = assetTo;

        // Emit the transfer event
        emit Transfer(msg.sender, to);
    }

    // Withdraw ETH to the owner account. Ownable-->Pausable-->AlchemyBase
    function withdrawETH() external onlyCAO {
        cfo.transfer(address(this).balance);
    }
}

contract AlchemyPatent is AlchemyBase {

    // patent struct
    struct Patent {
        // current patent owner
        address patentOwner;
        // the time when owner get the patent
        uint256 beginTime;
        // whether this patent is on sale
        bool onSale; 
        // the sale price
        uint256 price;
        // last deal price
        uint256 lastPrice;
        // the time when this sale is put on
        uint256 sellTime;
    }

    // Creator of each kind of asset
    mapping (uint16 => Patent) public patents;

    // patent fee ratio
    // Values 0-10,000 map to 0%-100%
    uint256 public feeRatio = 9705;

    uint256 public patentValidTime = 2 days;
    uint256 public patentSaleTimeDelay = 2 hours;

    // Event
    event RegisterCreator(address account, uint16 kind);
    event SellPatent(uint16 assetId, uint256 sellPrice);
    event ChangePatentSale(uint16 assetId, uint256 newPrice);
    event BuyPatent(uint16 assetId, address buyer);

    // set the patent fee ratio
    function setPatentFee(uint256 newFeeRatio) external onlyCOO {
        require(newFeeRatio <= 10000);
        feeRatio = newFeeRatio;
    }

    // sell the patent
    function sellPatent(uint16 assetId, uint256 sellPrice) public whenNotPaused {
        Patent memory patent = patents[assetId];
        require(patent.patentOwner == msg.sender);
        if (patent.lastPrice > 0) {
            require(sellPrice <= 2 * patent.lastPrice);
        } else {
            require(sellPrice <= 1 ether);
        }
        
        require(!patent.onSale);

        patent.onSale = true;
        patent.price = sellPrice;
        patent.sellTime = now;

        patents[assetId] = patent;

        // Emit the event
        emit SellPatent(assetId, sellPrice);
    }

    function publicSell(uint16 assetId) public whenNotPaused {
        Patent memory patent = patents[assetId];
        require(patent.patentOwner != address(0));  // this is a valid patent
        require(!patent.onSale);
        require(patent.beginTime + patentValidTime < now);

        patent.onSale = true;
        patent.price = patent.lastPrice;
        patent.sellTime = now;

        patents[assetId] = patent;

        // Emit the event
        emit SellPatent(assetId, patent.lastPrice);
    }

    // change sell price
    function changePatentSale(uint16 assetId, uint256 newPrice) external whenNotPaused {
        Patent memory patent = patents[assetId];
        require(patent.patentOwner == msg.sender);
        if (patent.lastPrice > 0) {
            require(newPrice <= 2 * patent.lastPrice);
        } else {
            require(newPrice <= 1 ether);
        }
        require(patent.onSale == true);

        patent.price = newPrice;

        patents[assetId] = patent;

        // Emit the event
        emit ChangePatentSale(assetId, newPrice);
    }

    // buy patent
    function buyPatent(uint16 assetId) external payable whenNotPaused {
        Patent memory patent = patents[assetId];
        require(patent.patentOwner != address(0));  // this is a valid patent
        require(patent.patentOwner != msg.sender);
        require(patent.onSale);
        require(msg.value >= patent.price);
        require(now >= patent.sellTime + patentSaleTimeDelay);

        patent.patentOwner.transfer(patent.price / 10000 * feeRatio);
        patent.patentOwner = msg.sender;
        patent.beginTime = now;
        patent.onSale = false;
        patent.lastPrice = patent.price;

        patents[assetId] = patent;

        //Emit the event
        emit BuyPatent(assetId, msg.sender);
    }
}


contract AlchemySynthesize is AlchemyPatent {

    // Synthesize formula
    ChemistryInterface public chemistry;
    SkinInterface public skinContract;

    // Cooldown after submit a after submit a transformation request
    uint256[9] public cooldownLevels = [
        5 minutes,
        10 minutes,
        15 minutes,
        20 minutes,
        25 minutes,
        30 minutes,
        35 minutes,
        40 minutes,
        45 minutes
    ];

    // patent fee for each level 
    uint256[9] public pFees = [
        0,
        10 finney,
        15 finney,
        20 finney,
        25 finney,
        30 finney,
        35 finney,
        40 finney,
        45 finney
    ];

    // alchemy furnace struct
    struct Furnace {
        // the pending assets for synthesize
        uint16[5] pendingAssets;
        // cooldown end time of synthesise
        uint256 cooldownEndTime;
        // whether this furnace is using
        bool inSynthesization;
    }

    // furnace of each account
    mapping (address => Furnace) public accountsToFurnace;

    // alchemy level of each asset
    mapping (uint16 => uint256) public assetLevel;

    // Pre-paid ether for synthesization, will be returned to user if the synthesization failed (minus gas).
    uint256 public prePaidFee = 1000000 * 3000000000; // (1million gas * 3 gwei)

    bool public isSynthesizeAllowed = false;

    // When a synthesization request starts, our daemon needs to call getSynthesizationResult() after cooldown.
    // event SynthesizeStart(address account);
    event AutoSynthesize(address account, uint256 cooldownEndTime);
    event SynthesizeSuccess(address account);

    // Initialize the asset level
    function initializeLevel() public onlyCOO {
        // Level of assets
        uint8[9] memory levelSplits = [4,     // end of level 0. start of level is 0
                                          19,    // end of level 1
                                          46,    // end of level 2
                                          82,    // end of level 3
                                          125,   // end of level 4
                                          156,
                                          180,
                                          195,
                                          198];  // end of level 8
        uint256 currentLevel = 0;
        for (uint8 i = 0; i < 198; i ++) {
            if (i == levelSplits[currentLevel]) {
                currentLevel ++;
            }
            assetLevel[uint16(i)] = currentLevel;
        }
    }

    function setAssetLevel(uint16 assetId, uint256 level) public onlyCOO {
        assetLevel[assetId] = level;
    }

    function changeSynthesizeAllowed(bool newState) external onlyCOO {
        isSynthesizeAllowed = newState;
    }

    // Get furnace information
    function getFurnace(address account) public view returns (uint16[5], uint256, bool) {
        return (accountsToFurnace[account].pendingAssets, accountsToFurnace[account].cooldownEndTime, accountsToFurnace[account].inSynthesization);
    }

    // Set chemistry science contract address
    function setChemistryAddress(address chemistryAddress) external onlyCOO {
        ChemistryInterface candidateContract = ChemistryInterface(chemistryAddress);

        require(candidateContract.isChemistry());

        chemistry = candidateContract;
    }

    // Set skin contract address
    function setSkinContract(address skinAddress) external onlyCOO {
        skinContract = SkinInterface(skinAddress);
    }

    // setPrePaidFee: set advance amount, only owner can call this
    function setPrePaidFee(uint256 newPrePaidFee) external onlyCOO {
        prePaidFee = newPrePaidFee;
    }

    // _isCooldownReady: check whether cooldown period has been passed
    function _isCooldownReady(address account) internal view returns (bool) {
        return (accountsToFurnace[account].cooldownEndTime <= now);
    }

    // synthesize: call _isCooldownReady, pending assets, fire SynthesizeStart event
    function synthesize(uint16[5] inputAssets) public payable whenNotPaused {
        require(isSynthesizeAllowed == true);
        // Check msg.sender is not in another synthesizing process
        require(accountsToFurnace[msg.sender].inSynthesization == false);

        // Check whether assets are valid
        bytes32[8] memory asset = assets[msg.sender];

        bytes32 mask; // 0x11111111
        uint256 maskedValue;
        uint256 count;
        bytes32 _asset;
        uint256 pos;
        uint256 maxLevel = 0;
        uint256 totalFee = 0;
        uint256 _assetLevel;
        Patent memory _patent;
        uint16 currentAsset;
        
        for (uint256 i = 0; i < 5; i++) {
            currentAsset = inputAssets[i];
            if (currentAsset < 248) {
                _asset = asset[currentAsset / 31];
                pos = currentAsset % 31;
                mask = bytes32(255) << (8 * pos);
                maskedValue = uint256(_asset & mask);

                require(maskedValue >= (uint256(1) << (8*pos)));
                maskedValue -= (uint256(1) << (8*pos));
                _asset = ((_asset ^ mask) & _asset) | bytes32(maskedValue); 
                asset[currentAsset / 31] = _asset;
                count += 1;

                // handle patent fee
                _assetLevel = assetLevel[currentAsset];
                if (_assetLevel > maxLevel) {
                    maxLevel = _assetLevel;
                }

                if (_assetLevel > 0) {
                    _patent = patents[currentAsset];
                    if (_patent.patentOwner != address(0) && _patent.patentOwner != msg.sender && !_patent.onSale && (_patent.beginTime + patentValidTime > now)) {
                        _patent.patentOwner.transfer(pFees[_assetLevel] / 10000 * feeRatio);
                        totalFee += pFees[_assetLevel];
                    }
                }
            }
        }

        require(msg.value >= prePaidFee + totalFee); 

        require(count >= 2 && count <= 5);

        // Check whether cooldown has ends
        require(_isCooldownReady(msg.sender));

        uint128 skinType = skinContract.getActiveSkin(msg.sender);
        uint256 _cooldownTime = chemistry.computeCooldownTime(skinType, cooldownLevels[maxLevel]);

        accountsToFurnace[msg.sender].pendingAssets = inputAssets;
        accountsToFurnace[msg.sender].cooldownEndTime = now + _cooldownTime;
        accountsToFurnace[msg.sender].inSynthesization = true;         
        assets[msg.sender] = asset;

        // Emit SnthesizeStart event
        // SynthesizeStart(msg.sender);
        emit AutoSynthesize(msg.sender, accountsToFurnace[msg.sender].cooldownEndTime);
    }

    function getPatentFee(address account, uint16[5] inputAssets) external view returns (uint256) {

        uint256 totalFee = 0;
        uint256 _assetLevel;
        Patent memory _patent;
        uint16 currentAsset;
        
        for (uint256 i = 0; i < 5; i++) {
            currentAsset = inputAssets[i];
            if (currentAsset < 248) {

                // handle patent fee
                _assetLevel = assetLevel[currentAsset];
                if (_assetLevel > 0) {
                    _patent = patents[currentAsset];
                    if (_patent.patentOwner != address(0) && _patent.patentOwner != account && !_patent.onSale && (_patent.beginTime + patentValidTime > now)) {
                        totalFee += pFees[_assetLevel];
                    }
                }
            }
        }
        return totalFee;
    }

    // getSynthesizationResult: auto synthesize daemin call this. if cooldown time has passed, give final result
    // Anyone can call this function, if they are willing to pay the gas
    function getSynthesizationResult(address account) external whenNotPaused {

        // Make sure this account is in synthesization
        require(accountsToFurnace[account].inSynthesization);

        // Make sure the cooldown has ends
        require(_isCooldownReady(account));

        // Get result using pending assets        
        uint16[5] memory _pendingAssets = accountsToFurnace[account].pendingAssets;
        uint128 skinType = skinContract.getActiveSkin(account);
        uint16[5] memory resultAssets = chemistry.turnOnFurnace(_pendingAssets, skinType);

        // Write result
        bytes32[8] memory asset = assets[account];

        bytes32 mask; // 0x11111111
        uint256 maskedValue;
        uint256 j;
        uint256 pos;   

        for (uint256 i = 0; i < 5; i++) {
            if (resultAssets[i] < 248) {
                j = resultAssets[i] / 31;
                pos = resultAssets[i] % 31;
                mask = bytes32(255) << (8 * pos);
                maskedValue = uint256(asset[j] & mask);

                require(maskedValue < (uint256(255) << (8*pos)));
                maskedValue += (uint256(1) << (8*pos));
                asset[j] = ((asset[j] ^ mask) & asset[j]) | bytes32(maskedValue); 

                // handle patent
                if (resultAssets[i] > 3 && patents[resultAssets[i]].patentOwner == address(0)) {
                    patents[resultAssets[i]] = Patent({patentOwner: account,
                                                       beginTime: now,
                                                       onSale: false,
                                                       price: 0,
                                                       lastPrice: 10 finney,
                                                       sellTime: 0});
                    // Emit the event
                    emit RegisterCreator(account, resultAssets[i]);
                }
            }
        }

        // Mark this synthesization as finished
        accountsToFurnace[account].inSynthesization = false;
        assets[account] = asset;

        emit SynthesizeSuccess(account);
    }
}



contract ChemistryInterface {
    function isChemistry() public pure returns (bool);

    // function turnOnFurnace(bytes32 x0, bytes32 x1, bytes32 x2, bytes32 x3) public returns (bytes32 r0, bytes32 r1, bytes32 r2, bytes32 r3);
    function turnOnFurnace(uint16[5] inputAssets, uint128 addition) public returns (uint16[5]);

    function computeCooldownTime(uint128 typeAdd, uint256 baseTime) public returns (uint256);
}


contract SkinInterface {
    function getActiveSkin(address account) public view returns (uint128);
}


contract AlchemyMinting is AlchemySynthesize {

    // Limit the nubmer of zero order assets the owner can create every day
    uint256 public zoDailyLimit = 2500; // we can create 4 * 2500 = 10000 0-order asset each day
    uint256[4] public zoCreated;
    
    // Limit the number each account can buy every day
    mapping(address => bytes32) public accountsBoughtZoAsset;
    mapping(address => uint256) public accountsZoLastRefreshTime;

    // Price of zero order assets
    uint256 public zoPrice = 1 finney;

    // Last daily limit refresh time
    uint256 public zoLastRefreshTime = now;

    // Event
    event BuyZeroOrderAsset(address account, bytes32 values);

    // To ensure scarcity, we are unable to change the max numbers of zo assets every day.
    // We are only able to modify the price
    function setZoPrice(uint256 newPrice) external onlyCOO {
        zoPrice = newPrice;
    }

    // Buy zo assets from us
    function buyZoAssets(bytes32 values) external payable whenNotPaused {
        // Check whether we need to refresh the daily limit
        bytes32 history = accountsBoughtZoAsset[msg.sender];
        if (accountsZoLastRefreshTime[msg.sender] == uint256(0)) {
            // This account&#39;s first time to buy zo asset, we do not need to clear accountsBoughtZoAsset
            accountsZoLastRefreshTime[msg.sender] = zoLastRefreshTime;
        } else {
            if (accountsZoLastRefreshTime[msg.sender] < zoLastRefreshTime) {
                history = bytes32(0);
                accountsZoLastRefreshTime[msg.sender] = zoLastRefreshTime;
            }
        }
 
        uint256 currentCount = 0;
        uint256 count = 0;

        bytes32 mask = bytes32(255); // 0x11111111
        uint256 maskedValue;
        uint256 maskedResult;

        bytes32 asset = assets[msg.sender][0];

        for (uint256 i = 0; i < 4; i++) {
            if (i > 0) {
                mask = mask << 8;
            }
            maskedValue = uint256(values & mask);
            currentCount = maskedValue / 2 ** (8 * i);
            count += currentCount;

            // Check whether this account has bought too many assets
            maskedResult = uint256(history & mask); 
            maskedResult += maskedValue;
            require(maskedResult < (2 ** (8 * (i + 1))));

            // Update account bought history
            history = ((history ^ mask) & history) | bytes32(maskedResult);

            // Check whether this account will have too many assets
            maskedResult = uint256(asset & mask);
            maskedResult += maskedValue;
            require(maskedResult < (2 ** (8 * (i + 1))));

            // Update user asset
            asset = ((asset ^ mask) & asset) | bytes32(maskedResult);

            // Check whether we have enough assets to sell
            require(zoCreated[i] + currentCount <= zoDailyLimit);

            // Update our creation history
            zoCreated[i] += currentCount;
        }

        // Ensure this account buy at least one zo asset
        require(count > 0);

        // Check whether there are enough money for payment
        require(msg.value >= count * zoPrice);

        // Write updated user asset
        assets[msg.sender][0] = asset;

        // Write updated history
        accountsBoughtZoAsset[msg.sender] = history;
        
        // Emit BuyZeroOrderAsset event
        emit BuyZeroOrderAsset(msg.sender, values);

    }

    // Our daemon will refresh daily limit
    function clearZoDailyLimit() external onlyCOO {
        uint256 nextDay = zoLastRefreshTime + 1 days;
        if (now > nextDay) {
            zoLastRefreshTime = nextDay;
            for (uint256 i = 0; i < 4; i++) {
                zoCreated[i] =0;
            }
        }
    }
}

contract AlchemyMarket is AlchemyMinting {

    // Sale order struct
    struct SaleOrder {
        // Asset id to be sold
        uint64 assetId;
        // Sale amount
        uint64 amount;
        // Desired price
        uint128 desiredPrice;
        // Seller
        address seller; 
    }

    // Max number of sale orders of each account 
    uint128 public maxSaleNum = 20;

    // Cut ratio for a transaction
    // Values 0-10,000 map to 0%-100%
    uint256 public trCut = 275;

    // Next sale id
    uint256 public nextSaleId = 1;

    // Sale orders list 
    mapping (uint256 => SaleOrder) public saleOrderList;

    // Sale information of each account
    mapping (address => uint256) public accountToSaleNum;

    // events
    event PutOnSale(address account, uint256 saleId);
    event WithdrawSale(address account, uint256 saleId);
    event ChangeSale(address account, uint256 saleId);
    event BuyInMarket(address buyer, uint256 saleId, uint256 amount);
    event SaleClear(uint256 saleId);

    // functions
    function setTrCut(uint256 newCut) public onlyCOO {
        trCut = newCut;
    }

    // Put asset on sale
    function putOnSale(uint256 assetId, uint256 amount, uint256 price) external whenNotPaused {
        // One account can have no more than maxSaleNum sale orders
        require(accountToSaleNum[msg.sender] < maxSaleNum);

        // check whether zero order asset is to be sold 
        // which is not allowed
        require(assetId > 3 && assetId < 248);
        require(amount > 0 && amount < 256);

        uint256 assetFloor = assetId / 31;
        uint256 assetPos = assetId - 31 * assetFloor;
        bytes32 allAsset = assets[msg.sender][assetFloor];

        bytes32 mask = bytes32(255) << (8 * assetPos); // 0x11111111
        uint256 maskedValue;
        uint256 maskedResult;
        uint256 addAmount = amount << (8 * assetPos);

        // check whether there are enough unpending assets to sell
        maskedValue = uint256(allAsset & mask);
        require(addAmount <= maskedValue);

        // Remove assets to be sold from owner
        maskedResult = maskedValue - addAmount;
        allAsset = ((allAsset ^ mask) & allAsset) | bytes32(maskedResult);

        assets[msg.sender][assetFloor] = allAsset;

        // Put on sale
        SaleOrder memory saleorder = SaleOrder(
            uint64(assetId),
            uint64(amount),
            uint128(price),
            msg.sender
        );

        saleOrderList[nextSaleId] = saleorder;
        nextSaleId += 1;

        accountToSaleNum[msg.sender] += 1;

        // Emit the Approval event
        emit PutOnSale(msg.sender, nextSaleId-1);
    }
  
    // Withdraw an sale order
    function withdrawSale(uint256 saleId) external whenNotPaused {
        // Can only withdraw self&#39;s sale order
        require(saleOrderList[saleId].seller == msg.sender);

        uint256 assetId = uint256(saleOrderList[saleId].assetId);
        uint256 assetFloor = assetId / 31;
        uint256 assetPos = assetId - 31 * assetFloor;
        bytes32 allAsset = assets[msg.sender][assetFloor];

        bytes32 mask = bytes32(255) << (8 * assetPos); // 0x11111111
        uint256 maskedValue;
        uint256 maskedResult;
        uint256 addAmount = uint256(saleOrderList[saleId].amount) << (8 * assetPos);

        // check whether this account will have too many assets
        maskedValue = uint256(allAsset & mask);
        require(addAmount + maskedValue < 2**(8 * (assetPos + 1)));

        // Retransfer asset to be sold from owner
        maskedResult = maskedValue + addAmount;
        allAsset = ((allAsset ^ mask) & allAsset) | bytes32(maskedResult);

        assets[msg.sender][assetFloor] = allAsset;

        // Delete sale order
        delete saleOrderList[saleId];

        accountToSaleNum[msg.sender] -= 1;

        // Emit the cancel event
        emit WithdrawSale(msg.sender, saleId);
    }
 
//     // Change sale order
//     function changeSale(uint256 assetId, uint256 amount, uint256 price, uint256 saleId) external whenNotPaused {
//         // Check if msg sender is the seller
//         require(msg.sender == saleOrderList[saleId].seller);
// 
//     }
 
    // Buy assets in market
    function buyInMarket(uint256 saleId, uint256 amount) external payable whenNotPaused {
        address seller = saleOrderList[saleId].seller;
        // Check whether the saleId is a valid sale order
        require(seller != address(0));

        // Check the sender isn&#39;t the seller
        require(msg.sender != seller);

        require(saleOrderList[saleId].amount >= uint64(amount));

        // Check whether pay value is enough
        require(msg.value / saleOrderList[saleId].desiredPrice >= amount);

        uint256 totalprice = amount * saleOrderList[saleId].desiredPrice;

        uint64 assetId = saleOrderList[saleId].assetId;

        uint256 assetFloor = assetId / 31;
        uint256 assetPos = assetId - 31 * assetFloor;
        bytes32 allAsset = assets[msg.sender][assetFloor];

        bytes32 mask = bytes32(255) << (8 * assetPos); // 0x11111111
        uint256 maskedValue;
        uint256 maskedResult;
        uint256 addAmount = amount << (8 * assetPos);

        // check whether this account will have too many assets
        maskedValue = uint256(allAsset & mask);
        require(addAmount + maskedValue < 2**(8 * (assetPos + 1)));

        // Transfer assets to buyer
        maskedResult = maskedValue + addAmount;
        allAsset = ((allAsset ^ mask) & allAsset) | bytes32(maskedResult);

        assets[msg.sender][assetFloor] = allAsset;

        saleOrderList[saleId].amount -= uint64(amount);

        // Cut and then send the proceeds to seller
        uint256 sellerProceeds = totalprice - _computeCut(totalprice);

        seller.transfer(sellerProceeds);

        // Emit the buy event
        emit BuyInMarket(msg.sender, saleId, amount);

        // If the sale has complete, clear this order
        if (saleOrderList[saleId].amount == 0) {
            accountToSaleNum[seller] -= 1;
            delete saleOrderList[saleId];

            // Emit the clear event
            emit SaleClear(saleId);
        }
    }

    // Compute the marketCut
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price / 10000 * trCut;
    }
}