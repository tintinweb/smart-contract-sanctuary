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

contract SkinBase is Manager {

    struct Skin {
        uint128 appearance;
        uint64 cooldownEndTime;
        uint64 mixingWithId;
    }

    // All skins, mapping from skin id to skin apprance
    mapping (uint256 => Skin) skins;

    // Mapping from skin id to owner
    mapping (uint256 => address) public skinIdToOwner;

    // Whether a skin is on sale
    mapping (uint256 => bool) public isOnSale;

    // Using 
    mapping (address => uint256) public accountsToActiveSkin;

    // Number of all total valid skins
    // skinId 0 should not correspond to any skin, because skin.mixingWithId==0 indicates not mixing
    uint256 public nextSkinId = 1;  

    // Number of skins an account owns
    mapping (address => uint256) public numSkinOfAccounts;

    event SkinTransfer(address from, address to, uint256 skinId);
    event SetActiveSkin(address account, uint256 skinId);

    // Get the i-th skin an account owns, for off-chain usage only
    function skinOfAccountById(address account, uint256 id) external view returns (uint256) {
        uint256 count = 0;
        uint256 numSkinOfAccount = numSkinOfAccounts[account];
        require(numSkinOfAccount > 0);
        require(id < numSkinOfAccount);
        for (uint256 i = 1; i < nextSkinId; i++) {
            if (skinIdToOwner[i] == account) {
                // This skin belongs to current account
                if (count == id) {
                    // This is the id-th skin of current account, a.k.a, what we need
                    return i;
                } 
                count++;
            }
        }
        revert();
    }

    // Get skin by id
    function getSkin(uint256 id) public view returns (uint128, uint64, uint64) {
        require(id > 0);
        require(id < nextSkinId);
        Skin storage skin = skins[id];
        return (skin.appearance, skin.cooldownEndTime, skin.mixingWithId);
    }

    function withdrawETH() external onlyCAO {
        cfo.transfer(address(this).balance);
    }
    
    function transferP2P(uint256 id, address targetAccount) whenTransferAllowed public {
        require(skinIdToOwner[id] == msg.sender);
        require(msg.sender != targetAccount);
        skinIdToOwner[id] = targetAccount;
        
        numSkinOfAccounts[msg.sender] -= 1;
        numSkinOfAccounts[targetAccount] += 1;
        
        // emit event
        emit SkinTransfer(msg.sender, targetAccount, id);
    }

    function _isComplete(uint256 id) internal view returns (bool) {
        uint128 _appearance = skins[id].appearance;
        uint128 mask = uint128(65535);
        uint128 _type = _appearance & mask;
        uint128 maskedValue;
        for (uint256 i = 1; i < 8; i++) {
            mask = mask << 16;
            maskedValue = (_appearance & mask) >> (16*i);
            if (maskedValue != _type) {
                return false;
            }
        } 
        return true;
    }

    function setActiveSkin(uint256 id) public {
        require(skinIdToOwner[id] == msg.sender);
        require(_isComplete(id));
        require(isOnSale[id] == false);
        require(skins[id].mixingWithId == 0);

        accountsToActiveSkin[msg.sender] = id;
        emit SetActiveSkin(msg.sender, id);
    }

    function getActiveSkin(address account) public view returns (uint128) {
        uint256 activeId = accountsToActiveSkin[account];
        if (activeId == 0) {
            return uint128(0);
        }
        return (skins[activeId].appearance & uint128(65535));
    }
}


contract SkinMix is SkinBase {

    // Mix formula
    MixFormulaInterface public mixFormula;


    // Pre-paid ether for synthesization, will be returned to user if the synthesization failed (minus gas).
    uint256 public prePaidFee = 150000 * 5000000000; // (15w gas * 5 gwei)

    bool public enableMix = false;

    // Events
    event MixStart(address account, uint256 skinAId, uint256 skinBId);
    event AutoMix(address account, uint256 skinAId, uint256 skinBId, uint64 cooldownEndTime);
    event MixSuccess(address account, uint256 skinId, uint256 skinAId, uint256 skinBId);

    // Set mix formula contract address 
    function setMixFormulaAddress(address mixFormulaAddress) external onlyCOO {
        mixFormula = MixFormulaInterface(mixFormulaAddress);
    }

    // setPrePaidFee: set advance amount, only owner can call this
    function setPrePaidFee(uint256 newPrePaidFee) external onlyCOO {
        prePaidFee = newPrePaidFee;
    }

    function changeMixEnable(bool newState) external onlyCOO {
        enableMix = newState;
    }

    // _isCooldownReady: check whether cooldown period has been passed
    function _isCooldownReady(uint256 skinAId, uint256 skinBId) private view returns (bool) {
        return (skins[skinAId].cooldownEndTime <= uint64(now)) && (skins[skinBId].cooldownEndTime <= uint64(now));
    }

    // _isNotMixing: check whether two skins are in another mixing process
    function _isNotMixing(uint256 skinAId, uint256 skinBId) private view returns (bool) {
        return (skins[skinAId].mixingWithId == 0) && (skins[skinBId].mixingWithId == 0);
    }

    // _setCooldownTime: set new cooldown time
    function _setCooldownEndTime(uint256 skinAId, uint256 skinBId) private {
        uint256 end = now + 20 minutes;
        // uint256 end = now;
        skins[skinAId].cooldownEndTime = uint64(end);
        skins[skinBId].cooldownEndTime = uint64(end);
    }

    // _isValidSkin: whether an account can mix using these skins
    // Make sure two things:
    // 1. these two skins do exist
    // 2. this account owns these skins
    function _isValidSkin(address account, uint256 skinAId, uint256 skinBId) private view returns (bool) {
        // Make sure those two skins belongs to this account
        if (skinAId == skinBId) {
            return false;
        }
        if ((skinAId == 0) || (skinBId == 0)) {
            return false;
        }
        if ((skinAId >= nextSkinId) || (skinBId >= nextSkinId)) {
            return false;
        }
        if (accountsToActiveSkin[account] == skinAId || accountsToActiveSkin[account] == skinBId) {
            return false;
        }
        return (skinIdToOwner[skinAId] == account) && (skinIdToOwner[skinBId] == account);
    }

    // _isNotOnSale: whether a skin is not on sale
    function _isNotOnSale(uint256 skinId) private view returns (bool) {
        return (isOnSale[skinId] == false);
    }

    // mix  
    function mix(uint256 skinAId, uint256 skinBId) public whenNotPaused {

        require(enableMix == true);
        // Check whether skins are valid
        require(_isValidSkin(msg.sender, skinAId, skinBId));

        // Check whether skins are neither on sale
        require(_isNotOnSale(skinAId) && _isNotOnSale(skinBId));

        // Check cooldown
        require(_isCooldownReady(skinAId, skinBId));

        // Check these skins are not in another process
        require(_isNotMixing(skinAId, skinBId));

        // Set new cooldown time
        _setCooldownEndTime(skinAId, skinBId);

        // Mark skins as in mixing
        skins[skinAId].mixingWithId = uint64(skinBId);
        skins[skinBId].mixingWithId = uint64(skinAId);

        // Emit MixStart event
        emit MixStart(msg.sender, skinAId, skinBId);
    }

    // Mixing auto
    function mixAuto(uint256 skinAId, uint256 skinBId) public payable whenNotPaused {
        require(msg.value >= prePaidFee);

        mix(skinAId, skinBId);

        Skin storage skin = skins[skinAId];

        emit AutoMix(msg.sender, skinAId, skinBId, skin.cooldownEndTime);
    }

    // Get mixing result, return the resulted skin id
    function getMixingResult(uint256 skinAId, uint256 skinBId) public whenNotPaused {
        // Check these two skins belongs to the same account
        address account = skinIdToOwner[skinAId];
        require(account == skinIdToOwner[skinBId]);

        // Check these two skins are in the same mixing process
        Skin storage skinA = skins[skinAId];
        Skin storage skinB = skins[skinBId];
        require(skinA.mixingWithId == uint64(skinBId));
        require(skinB.mixingWithId == uint64(skinAId));

        // Check cooldown
        require(_isCooldownReady(skinAId, skinBId));

        // Create new skin
        uint128 newSkinAppearance = mixFormula.calcNewSkinAppearance(skinA.appearance, skinB.appearance, getActiveSkin(account));
        Skin memory newSkin = Skin({appearance: newSkinAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = account;
        isOnSale[nextSkinId] = false;
        nextSkinId++;

        // Clear old skins
        skinA.mixingWithId = 0;
        skinB.mixingWithId = 0;

        // In order to distinguish created skins in minting with destroyed skins
        // skinIdToOwner[skinAId] = owner;
        // skinIdToOwner[skinBId] = owner;
        delete skinIdToOwner[skinAId];
        delete skinIdToOwner[skinBId];
        // require(numSkinOfAccounts[account] >= 2);
        numSkinOfAccounts[account] -= 1;

        emit MixSuccess(account, nextSkinId - 1, skinAId, skinBId);
    }
}


contract MixFormulaInterface {
    function calcNewSkinAppearance(uint128 x, uint128 y, uint128 addition) public returns (uint128);

    // create random appearance
    function randomSkinAppearance(uint256 externalNum, uint128 addition) public returns (uint128);

    // bleach
    function bleachAppearance(uint128 appearance, uint128 attributes) public returns (uint128);

    // recycle
    function recycleAppearance(uint128[5] appearances, uint256 preference, uint128 addition) public returns (uint128);

    // summon10
    function summon10SkinAppearance(uint256 externalNum, uint128 addition) public returns (uint128);
}


contract SkinMarket is SkinMix {

    // Cut ratio for a transaction
    // Values 0-10,000 map to 0%-100%
    uint128 public trCut = 400;

    // Sale orders list 
    mapping (uint256 => uint256) public desiredPrice;

    // events
    event PutOnSale(address account, uint256 skinId);
    event WithdrawSale(address account, uint256 skinId);
    event BuyInMarket(address buyer, uint256 skinId);

    // functions

    function setTrCut(uint256 newCut) external onlyCOO {
        trCut = uint128(newCut);
    }

    // Put asset on sale
    function putOnSale(uint256 skinId, uint256 price) public whenNotPaused {
        // Only owner of skin pass
        require(skinIdToOwner[skinId] == msg.sender);
        require(accountsToActiveSkin[msg.sender] != skinId);

        // Check whether skin is mixing 
        require(skins[skinId].mixingWithId == 0);

        // Check whether skin is already on sale
        require(isOnSale[skinId] == false);

        require(price > 0); 

        // Put on sale
        desiredPrice[skinId] = price;
        isOnSale[skinId] = true;

        // Emit the Approval event
        emit PutOnSale(msg.sender, skinId);
    }
  
    // Withdraw an sale order
    function withdrawSale(uint256 skinId) external whenNotPaused {
        // Check whether this skin is on sale
        require(isOnSale[skinId] == true);
        
        // Can only withdraw self&#39;s sale
        require(skinIdToOwner[skinId] == msg.sender);

        // Withdraw
        isOnSale[skinId] = false;
        desiredPrice[skinId] = 0;

        // Emit the cancel event
        emit WithdrawSale(msg.sender, skinId);
    }
 
    // Buy skin in market
    function buyInMarket(uint256 skinId) external payable whenNotPaused {
        // Check whether this skin is on sale
        require(isOnSale[skinId] == true);

        address seller = skinIdToOwner[skinId];

        // Check the sender isn&#39;t the seller
        require(msg.sender != seller);

        uint256 _price = desiredPrice[skinId];
        // Check whether pay value is enough
        require(msg.value >= _price);

        // Cut and then send the proceeds to seller
        uint256 sellerProceeds = _price - _computeCut(_price);

        seller.transfer(sellerProceeds);

        // Transfer skin from seller to buyer
        numSkinOfAccounts[seller] -= 1;
        skinIdToOwner[skinId] = msg.sender;
        numSkinOfAccounts[msg.sender] += 1;
        isOnSale[skinId] = false;
        desiredPrice[skinId] = 0;

        // Emit the buy event
        emit BuyInMarket(msg.sender, skinId);
    }

    // Compute the marketCut
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price / 10000 * trCut;
    }
}


contract SkinMinting is SkinMarket {

    // Limits the number of skins the contract owner can ever create.
    uint256 public skinCreatedLimit = 50000;
    uint256 public skinCreatedNum;

    // The summon and bleach numbers of each accounts: will be cleared every day
    mapping (address => uint256) public accountToSummonNum;
    mapping (address => uint256) public accountToBleachNum;

    // Pay level of each accounts
    mapping (address => uint256) public accountToPayLevel;
    mapping (address => uint256) public accountLastClearTime;
    mapping (address => uint256) public bleachLastClearTime;

    // Free bleach number donated
    mapping (address => uint256) public freeBleachNum;
    bool isBleachAllowed = false;
    bool isRecycleAllowed = false;

    uint256 public levelClearTime = now;

    // price and limit
    uint256 public bleachDailyLimit = 3;
    uint256 public baseSummonPrice = 1 finney;
    uint256 public bleachPrice = 100 ether;  // do not call this

    // Pay level
    uint256[5] public levelSplits = [10,
                                     20,
                                     50,
                                     100,
                                     200];

    uint256[6] public payMultiple = [10,
                                     12,
                                     15,
                                     20,
                                     30,
                                     40];


    // events
    event CreateNewSkin(uint256 skinId, address account);
    event Bleach(uint256 skinId, uint128 newAppearance);
    event Recycle(uint256 skinId0, uint256 skinId1, uint256 skinId2, uint256 skinId3, uint256 skinId4, uint256 newSkinId);

    // functions

    // Set price
    function setBaseSummonPrice(uint256 newPrice) external onlyCOO {
        baseSummonPrice = newPrice;
    }

    function setBleachPrice(uint256 newPrice) external onlyCOO {
        bleachPrice = newPrice;
    }

    function setBleachDailyLimit(uint256 limit) external onlyCOO {
        bleachDailyLimit = limit;
    }

    function switchBleachAllowed(bool newBleachAllowed) external onlyCOO {
        isBleachAllowed = newBleachAllowed;
    }

    function switchRecycleAllowed(bool newRecycleAllowed) external onlyCOO {
        isRecycleAllowed = newRecycleAllowed;
    }

    // Create base skin for sell. Only owner can create
    function createSkin(uint128 specifiedAppearance, uint256 salePrice) external onlyCOO {
        require(skinCreatedNum < skinCreatedLimit);

        // Create specified skin
        // uint128 randomAppearance = mixFormula.randomSkinAppearance();
        Skin memory newSkin = Skin({appearance: specifiedAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = coo;
        isOnSale[nextSkinId] = false;

        // Emit the create event
        emit CreateNewSkin(nextSkinId, coo);

        // Put this skin on sale
        putOnSale(nextSkinId, salePrice);

        nextSkinId++;
        numSkinOfAccounts[coo] += 1;
        skinCreatedNum += 1;
    }

    // Donate a skin to player. Only COO can operate
    function donateSkin(uint128 specifiedAppearance, address donee) external whenNotPaused onlyCOO {
        Skin memory newSkin = Skin({appearance: specifiedAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = donee;
        isOnSale[nextSkinId] = false;

        // Emit the create event
        emit CreateNewSkin(nextSkinId, donee);

        nextSkinId++;
        numSkinOfAccounts[donee] += 1;
        skinCreatedNum += 1;
    }

    //
    function moveData(uint128[] legacyAppearance, address[] legacyOwner, bool[] legacyIsOnSale, uint256[] legacyDesiredPrice) external onlyCOO {
        Skin memory newSkin = Skin({appearance: 0, cooldownEndTime: 0, mixingWithId: 0});
        for (uint256 i = 0; i < legacyOwner.length; i++) {
            newSkin.appearance = legacyAppearance[i];
            newSkin.cooldownEndTime = uint64(now);
            newSkin.mixingWithId = 0;

            skins[nextSkinId] = newSkin;
            skinIdToOwner[nextSkinId] = legacyOwner[i];
            isOnSale[nextSkinId] = legacyIsOnSale[i];
            desiredPrice[nextSkinId] = legacyDesiredPrice[i];

            // Emit the create event
            emit CreateNewSkin(nextSkinId, legacyOwner[i]);

            nextSkinId++;
            numSkinOfAccounts[legacyOwner[i]] += 1;
            if (numSkinOfAccounts[legacyOwner[i]] > freeBleachNum[legacyOwner[i]]*10 || freeBleachNum[legacyOwner[i]] == 0) {
                freeBleachNum[legacyOwner[i]] += 1;
            }
            skinCreatedNum += 1;
        }
    }

    // Summon
    function summon() external payable whenNotPaused {
        // Clear daily summon numbers
        if (accountLastClearTime[msg.sender] == uint256(0)) {
            // This account&#39;s first time to summon, we do not need to clear summon numbers
            accountLastClearTime[msg.sender] = now;
        } else {
            if (accountLastClearTime[msg.sender] < levelClearTime && now > levelClearTime) {
                accountToSummonNum[msg.sender] = 0;
                accountToPayLevel[msg.sender] = 0;
                accountLastClearTime[msg.sender] = now;
            }
        }

        uint256 payLevel = accountToPayLevel[msg.sender];
        uint256 price = payMultiple[payLevel] * baseSummonPrice;
        require(msg.value >= price);

        // Create random skin
        uint128 randomAppearance = mixFormula.randomSkinAppearance(nextSkinId, getActiveSkin(msg.sender));
        // uint128 randomAppearance = 0;
        Skin memory newSkin = Skin({appearance: randomAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = msg.sender;
        isOnSale[nextSkinId] = false;

        // Emit the create event
        emit CreateNewSkin(nextSkinId, msg.sender);

        nextSkinId++;
        numSkinOfAccounts[msg.sender] += 1;

        accountToSummonNum[msg.sender] += 1;

        // Handle the paylevel
        if (payLevel < 5) {
            if (accountToSummonNum[msg.sender] >= levelSplits[payLevel]) {
                accountToPayLevel[msg.sender] = payLevel + 1;
            }
        }
    }

    // Summon10
    function summon10() external payable whenNotPaused {
        // Clear daily summon numbers
        if (accountLastClearTime[msg.sender] == uint256(0)) {
            // This account&#39;s first time to summon, we do not need to clear summon numbers
            accountLastClearTime[msg.sender] = now;
        } else {
            if (accountLastClearTime[msg.sender] < levelClearTime && now > levelClearTime) {
                accountToSummonNum[msg.sender] = 0;
                accountToPayLevel[msg.sender] = 0;
                accountLastClearTime[msg.sender] = now;
            }
        }

        uint256 payLevel = accountToPayLevel[msg.sender];
        uint256 price = payMultiple[payLevel] * baseSummonPrice;
        require(msg.value >= price*10);

        Skin memory newSkin;
        uint128 randomAppearance;
        // Create random skin
        for (uint256 i = 0; i < 10; i++) {
            randomAppearance = mixFormula.randomSkinAppearance(nextSkinId, getActiveSkin(msg.sender));
            newSkin = Skin({appearance: randomAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
            skins[nextSkinId] = newSkin;
            skinIdToOwner[nextSkinId] = msg.sender;
            isOnSale[nextSkinId] = false;
            // Emit the create event
            emit CreateNewSkin(nextSkinId, msg.sender);
            nextSkinId++;
        }

        // Give additional skin
        randomAppearance = mixFormula.summon10SkinAppearance(nextSkinId, getActiveSkin(msg.sender));
        newSkin = Skin({appearance: randomAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = msg.sender;
        isOnSale[nextSkinId] = false;
        // Emit the create event
        emit CreateNewSkin(nextSkinId, msg.sender);
        nextSkinId++;

        numSkinOfAccounts[msg.sender] += 11;
        accountToSummonNum[msg.sender] += 10;

        // Handle the paylevel
        if (payLevel < 5) {
            if (accountToSummonNum[msg.sender] >= levelSplits[payLevel]) {
                accountToPayLevel[msg.sender] = payLevel + 1;
            }
        }
    }

    // Recycle bin
    function recycleSkin(uint256[5] wasteSkins, uint256 preferIndex) external whenNotPaused {
        require(isRecycleAllowed == true);
        for (uint256 i = 0; i < 5; i++) {
            require(skinIdToOwner[wasteSkins[i]] == msg.sender);
            skinIdToOwner[wasteSkins[i]] = address(0);
        }

        uint128[5] memory apps;
        for (i = 0; i < 5; i++) {
            apps[i] = skins[wasteSkins[i]].appearance;
        }
        // Create random skin
        uint128 recycleApp = mixFormula.recycleAppearance(apps, preferIndex, getActiveSkin(msg.sender));
        Skin memory newSkin = Skin({appearance: recycleApp, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = msg.sender;
        isOnSale[nextSkinId] = false;

        // Emit event
        emit Recycle(wasteSkins[0], wasteSkins[1], wasteSkins[2], wasteSkins[3], wasteSkins[4], nextSkinId);

        nextSkinId++;
        numSkinOfAccounts[msg.sender] -= 4;
    }

    // Bleach some attributes
    function bleach(uint128 skinId, uint128 attributes) external payable whenNotPaused {
        require(isBleachAllowed);

        // Clear daily summon numbers
        if (bleachLastClearTime[msg.sender] == uint256(0)) {
            // This account&#39;s first time to summon, we do not need to clear bleach numbers
            bleachLastClearTime[msg.sender] = now;
        } else {
            if (bleachLastClearTime[msg.sender] < levelClearTime && now > levelClearTime) {
                accountToBleachNum[msg.sender] = 0;
                bleachLastClearTime[msg.sender] = now;
            }
        }

        require(accountToBleachNum[msg.sender] < bleachDailyLimit);
        accountToBleachNum[msg.sender] += 1;

        // Check whether msg.sender is owner of the skin
        require(msg.sender == skinIdToOwner[skinId]);

        // Check whether this skin is on sale
        require(isOnSale[skinId] == false);

        uint256 bleachNum = 0;
        for (uint256 i = 0; i < 8; i++) {
            if ((attributes & (uint128(1) << i)) > 0) {
                if (freeBleachNum[msg.sender] > 0) {
                    freeBleachNum[msg.sender]--;
                } else {
                    bleachNum++;
                }
            }
        }
        // Check whether there is enough money
        require(msg.value >= bleachNum * bleachPrice);

        Skin storage originSkin = skins[skinId];
        // Check whether this skin is in mixing
        require(originSkin.mixingWithId == 0);

        uint128 newAppearance = mixFormula.bleachAppearance(originSkin.appearance, attributes);
        originSkin.appearance = newAppearance;

        // Emit bleach event
        emit Bleach(skinId, newAppearance);
    }

    // Our daemon will clear daily summon numbers
    function clearSummonNum() external onlyCOO {
        uint256 nextDay = levelClearTime + 1 days;
        if (now > nextDay) {
            levelClearTime = nextDay;
        }
    }
}