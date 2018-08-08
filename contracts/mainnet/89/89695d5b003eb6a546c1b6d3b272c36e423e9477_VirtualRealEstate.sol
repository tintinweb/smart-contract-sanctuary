pragma solidity ^0.4.2;

// Make setPrivate payout any pending payouts

// ERC20 Token Interface
contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// ERC20 Token Implementation
contract StandardToken is Token {
    function transfer(address _to, uint256 _value) public returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

/*
    PXLProperty is the ERC20 Cryptocurrency & Cryptocollectable
    * It is a StandardToken ERC20 token and inherits all of that
    * It has the Property structure and holds the Properties
    * It governs the regulators (moderators, admins, root, Property DApps and PixelProperty)
    * It has getters and setts for all data storage
    * It selectively allows access to PXL and Properties based on caller access
    
    Moderation is handled inside PXLProperty, not by external DApps. It&#39;s up to other apps to respect the flags, however
*/
contract PXLProperty is StandardToken {
    /* Access Level Constants */
    uint8 constant LEVEL_1_MODERATOR = 1;    // 1: Level 1 Moderator - nsfw-flagging power
    uint8 constant LEVEL_2_MODERATOR = 2;    // 2: Level 2 Moderator - ban power + [1]
    uint8 constant LEVEL_1_ADMIN = 3;        // 3: Level 1 Admin - Can manage moderator levels + [1,2]
    uint8 constant LEVEL_2_ADMIN = 4;        // 4: Level 2 Admin - Can manage admin level 1 levels + [1-3]
    uint8 constant LEVEL_1_ROOT = 5;         // 5: Level 1 Root - Can set property DApps level [1-4]
    uint8 constant LEVEL_2_ROOT = 6;         // 6: Level 2 Root - Can set pixelPropertyContract level [1-5]
    uint8 constant LEVEL_3_ROOT = 7;         // 7: Level 3 Root - Can demote/remove root, transfer root, [1-6]
    uint8 constant LEVEL_PROPERTY_DAPPS = 8; // 8: Property DApps - Power over manipulating Property data
    uint8 constant LEVEL_PIXEL_PROPERTY = 9; // 9: PixelProperty - Power over PXL generation & Property ownership
    /* Flags Constants */
    uint8 constant FLAG_NSFW = 1;
    uint8 constant FLAG_BAN = 2;
    
    /* Accesser Addresses & Levels */
    address pixelPropertyContract; // Only contract that has control over PXL creation and Property ownership
    mapping (address => uint8) public regulators; // Mapping of users/contracts to their control levels
    
    // Mapping of PropertyID to Property
    mapping (uint16 => Property) public properties;
    // Property Owner&#39;s website
    mapping (address => uint256[2]) public ownerWebsite;
    // Property Owner&#39;s hover text
    mapping (address => uint256[2]) public ownerHoverText;
    
    /* ### Ownable Property Structure ### */
    struct Property {
        uint8 flag;
        bool isInPrivateMode; //Whether in private mode for owner-only use or free-use mode to be shared
        address owner; //Who owns the Property. If its zero (0), then no owner and known as a "system-Property"
        address lastUpdater; //Who last changed the color of the Property
        uint256[5] colors; //10x10 rgb pixel colors per property. colors[0] is the top row, colors[9] is the bottom row
        uint256 salePrice; //PXL price the owner has the Property on sale for. If zero, then its not for sale.
        uint256 lastUpdate; //Timestamp of when it had its color last updated
        uint256 becomePublic; //Timestamp on when to become public
        uint256 earnUntil; //Timestamp on when Property token generation will stop
    }
    
    /* ### Regulation Access Modifiers ### */
    modifier regulatorAccess(uint8 accessLevel) {
        require(accessLevel <= LEVEL_3_ROOT); // Only request moderator, admin or root levels forr regulatorAccess
        require(regulators[msg.sender] >= accessLevel); // Users must meet requirement
        if (accessLevel >= LEVEL_1_ADMIN) { //
            require(regulators[msg.sender] <= LEVEL_3_ROOT); //DApps can&#39;t do Admin/Root stuff, but can set nsfw/ban flags
        }
        _;
    }
    
    modifier propertyDAppAccess() {
        require(regulators[msg.sender] == LEVEL_PROPERTY_DAPPS || regulators[msg.sender] == LEVEL_PIXEL_PROPERTY );
        _;
    }
    
    modifier pixelPropertyAccess() {
        require(regulators[msg.sender] == LEVEL_PIXEL_PROPERTY);
        _;
    }
    
    /* ### Constructor ### */
    function PXLProperty() public {
        regulators[msg.sender] = LEVEL_3_ROOT; // Creator set to Level 3 Root
    }
    
    /* ### Moderator, Admin & Root Functions ### */
    // Moderator Flags
    function setPropertyFlag(uint16 propertyID, uint8 flag) public regulatorAccess(flag == FLAG_NSFW ? LEVEL_1_MODERATOR : LEVEL_2_MODERATOR) {
        properties[propertyID].flag = flag;
        if (flag == FLAG_BAN) {
            require(properties[propertyID].isInPrivateMode); //Can&#39;t ban an owner&#39;s property if a public user caused the NSFW content
            properties[propertyID].colors = [0, 0, 0, 0, 0];
        }
    }
    
    // Setting moderator/admin/root access
    function setRegulatorAccessLevel(address user, uint8 accessLevel) public regulatorAccess(LEVEL_1_ADMIN) {
        if (msg.sender != user) {
            require(regulators[msg.sender] > regulators[user]); // You have to be a higher rank than the user you are changing
        }
        require(regulators[msg.sender] > accessLevel); // You have to be a higher rank than the role you are setting
        regulators[user] = accessLevel;
    }
    
    function setPixelPropertyContract(address newPixelPropertyContract) public regulatorAccess(LEVEL_2_ROOT) {
        require(newPixelPropertyContract != 0);
        if (pixelPropertyContract != 0) {
            regulators[pixelPropertyContract] = 0; //If we already have a pixelPropertyContract, revoke its ownership
        }
        
        pixelPropertyContract = newPixelPropertyContract;
        regulators[newPixelPropertyContract] = LEVEL_PIXEL_PROPERTY;
    }
    
    function setPropertyDAppContract(address propertyDAppContract, bool giveAccess) public regulatorAccess(LEVEL_1_ROOT) {
        require(propertyDAppContract != 0);
        regulators[propertyDAppContract] = giveAccess ? LEVEL_PROPERTY_DAPPS : 0;
    }
    
    /* ### PropertyDapp Functions ### */
    function setPropertyColors(uint16 propertyID, uint256[5] colors) public propertyDAppAccess() {
        for(uint256 i = 0; i < 5; i++) {
            if (properties[propertyID].colors[i] != colors[i]) {
                properties[propertyID].colors[i] = colors[i];
            }
        }
    }
    
    function setPropertyRowColor(uint16 propertyID, uint8 row, uint256 rowColor) public propertyDAppAccess() {
        if (properties[propertyID].colors[row] != rowColor) {
            properties[propertyID].colors[row] = rowColor;
        }
    }
    
    function setOwnerHoverText(address textOwner, uint256[2] hoverText) public propertyDAppAccess() {
        require (textOwner != 0);
        ownerHoverText[textOwner] = hoverText;
    }
    
    function setOwnerLink(address websiteOwner, uint256[2] website) public propertyDAppAccess() {
        require (websiteOwner != 0);
        ownerWebsite[websiteOwner] = website;
    }
    
    /* ### PixelProperty Property Functions ### */
    function setPropertyPrivateMode(uint16 propertyID, bool isInPrivateMode) public pixelPropertyAccess() {
        if (properties[propertyID].isInPrivateMode != isInPrivateMode) {
            properties[propertyID].isInPrivateMode = isInPrivateMode;
        }
    }
    
    function setPropertyOwner(uint16 propertyID, address propertyOwner) public pixelPropertyAccess() {
        if (properties[propertyID].owner != propertyOwner) {
            properties[propertyID].owner = propertyOwner;
        }
    }
    
    function setPropertyLastUpdater(uint16 propertyID, address lastUpdater) public pixelPropertyAccess() {
        if (properties[propertyID].lastUpdater != lastUpdater) {
            properties[propertyID].lastUpdater = lastUpdater;
        }
    }
    
    function setPropertySalePrice(uint16 propertyID, uint256 salePrice) public pixelPropertyAccess() {
        if (properties[propertyID].salePrice != salePrice) {
            properties[propertyID].salePrice = salePrice;
        }
    }
    
    function setPropertyLastUpdate(uint16 propertyID, uint256 lastUpdate) public pixelPropertyAccess() {
        properties[propertyID].lastUpdate = lastUpdate;
    }
    
    function setPropertyBecomePublic(uint16 propertyID, uint256 becomePublic) public pixelPropertyAccess() {
        properties[propertyID].becomePublic = becomePublic;
    }
    
    function setPropertyEarnUntil(uint16 propertyID, uint256 earnUntil) public pixelPropertyAccess() {
        properties[propertyID].earnUntil = earnUntil;
    }
    
    function setPropertyPrivateModeEarnUntilLastUpdateBecomePublic(uint16 propertyID, bool privateMode, uint256 earnUntil, uint256 lastUpdate, uint256 becomePublic) public pixelPropertyAccess() {
        if (properties[propertyID].isInPrivateMode != privateMode) {
            properties[propertyID].isInPrivateMode = privateMode;
        }
        properties[propertyID].earnUntil = earnUntil;
        properties[propertyID].lastUpdate = lastUpdate;
        properties[propertyID].becomePublic = becomePublic;
    }
    
    function setPropertyLastUpdaterLastUpdate(uint16 propertyID, address lastUpdater, uint256 lastUpdate) public pixelPropertyAccess() {
        if (properties[propertyID].lastUpdater != lastUpdater) {
            properties[propertyID].lastUpdater = lastUpdater;
        }
        properties[propertyID].lastUpdate = lastUpdate;
    }
    
    function setPropertyBecomePublicEarnUntil(uint16 propertyID, uint256 becomePublic, uint256 earnUntil) public pixelPropertyAccess() {
        properties[propertyID].becomePublic = becomePublic;
        properties[propertyID].earnUntil = earnUntil;
    }
    
    function setPropertyOwnerSalePricePrivateModeFlag(uint16 propertyID, address owner, uint256 salePrice, bool privateMode, uint8 flag) public pixelPropertyAccess() {
        if (properties[propertyID].owner != owner) {
            properties[propertyID].owner = owner;
        }
        if (properties[propertyID].salePrice != salePrice) {
            properties[propertyID].salePrice = salePrice;
        }
        if (properties[propertyID].isInPrivateMode != privateMode) {
            properties[propertyID].isInPrivateMode = privateMode;
        }
        if (properties[propertyID].flag != flag) {
            properties[propertyID].flag = flag;
        }
    }
    
    function setPropertyOwnerSalePrice(uint16 propertyID, address owner, uint256 salePrice) public pixelPropertyAccess() {
        if (properties[propertyID].owner != owner) {
            properties[propertyID].owner = owner;
        }
        if (properties[propertyID].salePrice != salePrice) {
            properties[propertyID].salePrice = salePrice;
        }
    }
    
    /* ### PixelProperty PXL Functions ### */
    function rewardPXL(address rewardedUser, uint256 amount) public pixelPropertyAccess() {
        require(rewardedUser != 0);
        balances[rewardedUser] += amount;
        totalSupply += amount;
    }
    
    function burnPXL(address burningUser, uint256 amount) public pixelPropertyAccess() {
        require(burningUser != 0);
        require(balances[burningUser] >= amount);
        balances[burningUser] -= amount;
        totalSupply -= amount;
    }
    
    function burnPXLRewardPXL(address burner, uint256 toBurn, address rewarder, uint256 toReward) public pixelPropertyAccess() {
        require(balances[burner] >= toBurn);
        if (toBurn > 0) {
            balances[burner] -= toBurn;
            totalSupply -= toBurn;
        }
        if (rewarder != 0) {
            balances[rewarder] += toReward;
            totalSupply += toReward;
        }
    } 
    
    function burnPXLRewardPXLx2(address burner, uint256 toBurn, address rewarder1, uint256 toReward1, address rewarder2, uint256 toReward2) public pixelPropertyAccess() {
        require(balances[burner] >= toBurn);
        if (toBurn > 0) {
            balances[burner] -= toBurn;
            totalSupply -= toBurn;
        }
        if (rewarder1 != 0) {
            balances[rewarder1] += toReward1;
            totalSupply += toReward1;
        }
        if (rewarder2 != 0) {
            balances[rewarder2] += toReward2;
            totalSupply += toReward2;
        }
    } 
    
    /* ### All Getters/Views ### */
    function getOwnerHoverText(address user) public view returns(uint256[2]) {
        return ownerHoverText[user];
    }
    
    function getOwnerLink(address user) public view returns(uint256[2]) {
        return ownerWebsite[user];
    }
    
    function getPropertyFlag(uint16 propertyID) public view returns(uint8) {
        return properties[propertyID].flag;
    }
    
    function getPropertyPrivateMode(uint16 propertyID) public view returns(bool) {
        return properties[propertyID].isInPrivateMode;
    }
    
    function getPropertyOwner(uint16 propertyID) public view returns(address) {
        return properties[propertyID].owner;
    }
    
    function getPropertyLastUpdater(uint16 propertyID) public view returns(address) {
        return properties[propertyID].lastUpdater;
    }
    
    function getPropertyColors(uint16 propertyID) public view returns(uint256[5]) {
        return properties[propertyID].colors;
    }

    function getPropertyColorsOfRow(uint16 propertyID, uint8 rowIndex) public view returns(uint256) {
        require(rowIndex <= 9);
        return properties[propertyID].colors[rowIndex];
    }
    
    function getPropertySalePrice(uint16 propertyID) public view returns(uint256) {
        return properties[propertyID].salePrice;
    }
    
    function getPropertyLastUpdate(uint16 propertyID) public view returns(uint256) {
        return properties[propertyID].lastUpdate;
    }
    
    function getPropertyBecomePublic(uint16 propertyID) public view returns(uint256) {
        return properties[propertyID].becomePublic;
    }
    
    function getPropertyEarnUntil(uint16 propertyID) public view returns(uint256) {
        return properties[propertyID].earnUntil;
    }
    
    function getRegulatorLevel(address user) public view returns(uint8) {
        return regulators[user];
    }
    
    // Gets the (owners address, Ethereum sale price, PXL sale price, last update timestamp, whether its in private mode or not, when it becomes public timestamp, flag) for a Property
    function getPropertyData(uint16 propertyID, uint256 systemSalePriceETH, uint256 systemSalePricePXL) public view returns(address, uint256, uint256, uint256, bool, uint256, uint8) {
        Property memory property = properties[propertyID];
        bool isInPrivateMode = property.isInPrivateMode;
        //If it&#39;s in private, but it has expired and should be public, set our bool to be public
        if (isInPrivateMode && property.becomePublic <= now) { 
            isInPrivateMode = false;
        }
        if (properties[propertyID].owner == 0) {
            return (0, systemSalePriceETH, systemSalePricePXL, property.lastUpdate, isInPrivateMode, property.becomePublic, property.flag);
        } else {
            return (property.owner, 0, property.salePrice, property.lastUpdate, isInPrivateMode, property.becomePublic, property.flag);
        }
    }
    
    function getPropertyPrivateModeBecomePublic(uint16 propertyID) public view returns (bool, uint256) {
        return (properties[propertyID].isInPrivateMode, properties[propertyID].becomePublic);
    }
    
    function getPropertyLastUpdaterBecomePublic(uint16 propertyID) public view returns (address, uint256) {
        return (properties[propertyID].lastUpdater, properties[propertyID].becomePublic);
    }
    
    function getPropertyOwnerSalePrice(uint16 propertyID) public view returns (address, uint256) {
        return (properties[propertyID].owner, properties[propertyID].salePrice);
    }
    
    function getPropertyPrivateModeLastUpdateEarnUntil(uint16 propertyID) public view returns (bool, uint256, uint256) {
        return (properties[propertyID].isInPrivateMode, properties[propertyID].lastUpdate, properties[propertyID].earnUntil);
    }
}

// PixelProperty
contract VirtualRealEstate {
    /* ### Variables ### */
    // Contract owner
    address owner;
    PXLProperty pxlProperty;
    
    bool initialPropertiesReserved;
    
    mapping (uint16 => bool) hasBeenSet;
    
    // The amount in % for which a user is paid
    uint8 constant USER_BUY_CUT_PERCENT = 98;
    // Maximum amount of generated PXL a property can give away per minute
    uint8 constant PROPERTY_GENERATES_PER_MINUTE = 1;
    // The point in time when the initial grace period is over, and users get the default values based on coins burned
    uint256 GRACE_PERIOD_END_TIMESTAMP;
    // The amount of time required for a Property to generate tokens for payouts
    uint256 constant PROPERTY_GENERATION_PAYOUT_INTERVAL = (1 minutes); //Generation amount
    
    uint256 ownerEth = 0; // Amount of ETH the contract owner is entitled to withdraw (only Root account can do withdraws)
    
    // The current system prices of ETH and PXL, for which unsold Properties are listed for sale at
    uint256 systemSalePriceETH;
    uint256 systemSalePricePXL;
    uint8 systemPixelIncreasePercent;
    uint8 systemPriceIncreaseStep;
    uint16 systemETHStepTally;
    uint16 systemPXLStepTally;
    uint16 systemETHStepCount;
    uint16 systemPXLStepCount;

    /* ### Events ### */
    event PropertyColorUpdate(uint16 indexed property, uint256[5] colors, uint256 lastUpdate, address indexed lastUpdaterPayee, uint256 becomePublic, uint256 indexed rewardedCoins);
    event PropertyBought(uint16 indexed property, address indexed newOwner, uint256 ethAmount, uint256 PXLAmount, uint256 timestamp, address indexed oldOwner);
    event SetUserHoverText(address indexed user, uint256[2] newHoverText);
    event SetUserSetLink(address indexed user, uint256[2] newLink);
    event PropertySetForSale(uint16 indexed property, uint256 forSalePrice);
    event DelistProperty(uint16 indexed property);
    event SetPropertyPublic(uint16 indexed property);
    event SetPropertyPrivate(uint16 indexed property, uint32 numMinutesPrivate, address indexed rewardedUser, uint256 indexed rewardedCoins);
    event Bid(uint16 indexed property, uint256 bid, uint256 timestamp);
    
    /* ### MODIFIERS ### */

    // Only the contract owner can call these methods
    modifier ownerOnly() {
        require(owner == msg.sender);
        _;
    }
    
    // Can only be called on Properties referecing a valid PropertyID
    modifier validPropertyID(uint16 propertyID) {
        if (propertyID < 10000) {
            _;
        }
    }
    
    /* ### PUBLICALLY INVOKABLE FUNCTIONS ### */
    
    /* CONSTRUCTOR */
    function VirtualRealEstate() public {
        owner = msg.sender; // Default the owner to be whichever Ethereum account created the contract
        systemSalePricePXL = 1000; //Initial PXL system price
        systemSalePriceETH = 19500000000000000; //Initial ETH system price
        systemPriceIncreaseStep = 10;
        systemPixelIncreasePercent = 5;
        systemETHStepTally = 0;
        systemPXLStepTally = 0;
        systemETHStepCount = 1;
        systemPXLStepCount = 1;
        initialPropertiesReserved = false;
    }
    
    function setPXLPropertyContract(address pxlPropertyContract) public ownerOnly() {
        pxlProperty = PXLProperty(pxlPropertyContract);
        if (!initialPropertiesReserved) {
            uint16 xReserved = 45;
            uint16 yReserved = 0;
            for(uint16 x = 0; x < 10; ++x) {
                uint16 propertyID = (yReserved) * 100 + (xReserved + x);
                _transferProperty(propertyID, owner, 0, 0, 0, 0);
            }
            initialPropertiesReserved = true;
            GRACE_PERIOD_END_TIMESTAMP = now + 3 days; // Extends the three 
        }
    }

    function getSaleInformation() public view ownerOnly() returns(uint8, uint8, uint16, uint16, uint16, uint16) {
        return (systemPixelIncreasePercent, systemPriceIncreaseStep, systemETHStepTally, systemPXLStepTally, systemETHStepCount, systemPXLStepCount);
    }
    
    /* USER FUNCTIONS */
    
    // Property owners can change their hoverText for when a user mouses over their Properties
    function setHoverText(uint256[2] text) public {
        pxlProperty.setOwnerHoverText(msg.sender, text);
        SetUserHoverText(msg.sender, text);
    }
    
    // Property owners can change the clickable link for when a user clicks on their Properties
    function setLink(uint256[2] website) public {
        pxlProperty.setOwnerLink(msg.sender, website);
        SetUserSetLink(msg.sender, website);
    }
    
    // If a Property is private which has expired, make it public
    function tryForcePublic(uint16 propertyID) public validPropertyID(propertyID) { 
        var (isInPrivateMode, becomePublic) = pxlProperty.getPropertyPrivateModeBecomePublic(propertyID);
        if (isInPrivateMode && becomePublic < now) {
            pxlProperty.setPropertyPrivateMode(propertyID, false);
        }
    }
    
    // Update the 10x10 image data for a Property, triggering potential payouts if it succeeds
    function setColors(uint16 propertyID, uint256[5] newColors, uint256 PXLToSpend) public validPropertyID(propertyID) returns(bool) {
        uint256 projectedPayout = getProjectedPayout(propertyID);
        if (_tryTriggerPayout(propertyID, PXLToSpend)) {
            pxlProperty.setPropertyColors(propertyID, newColors);
            var (lastUpdater, becomePublic) = pxlProperty.getPropertyLastUpdaterBecomePublic(propertyID);
            PropertyColorUpdate(propertyID, newColors, now, lastUpdater, becomePublic, projectedPayout);
            // The first user to set a Properties color ever is awarded extra PXL due to eating the extra GAS cost of creating the uint256[5]
            if (!hasBeenSet[propertyID]) {
                pxlProperty.rewardPXL(msg.sender, 25);
                hasBeenSet[propertyID] = true;
            }
            return true;
        }
        return false;
    }

    //Wrapper to call setColors 4 times in one call. Reduces overhead, however still duplicate work everywhere to ensure
    function setColorsX4(uint16[4] propertyIDs, uint256[20] newColors, uint256 PXLToSpendEach) public returns(bool[4]) {
        bool[4] results;
        for(uint256 i = 0; i < 4; i++) {
            require(propertyIDs[i] < 10000);
            results[i] = setColors(propertyIDs[i], [newColors[i * 5], newColors[i * 5 + 1], newColors[i * 5 + 2], newColors[i * 5 + 3], newColors[i * 5 + 4]], PXLToSpendEach);
        }
        return results;
    }

    //Wrapper to call setColors 8 times in one call. Reduces overhead, however still duplicate work everywhere to ensure
    function setColorsX8(uint16[8] propertyIDs, uint256[40] newColors, uint256 PXLToSpendEach) public returns(bool[8]) {
        bool[8] results;
        for(uint256 i = 0; i < 8; i++) {
            require(propertyIDs[i] < 10000);
            results[i] = setColors(propertyIDs[i], [newColors[i * 5], newColors[i * 5 + 1], newColors[i * 5 + 2], newColors[i * 5 + 3], newColors[i * 5 + 4]], PXLToSpendEach);
        }
        return results;
    }
    
    // Update a row of image data for a Property, triggering potential payouts if it succeeds
    function setRowColors(uint16 propertyID, uint8 row, uint256 newColorData, uint256 PXLToSpend) public validPropertyID(propertyID) returns(bool) {
        require(row < 10);
        uint256 projectedPayout = getProjectedPayout(propertyID);
        if (_tryTriggerPayout(propertyID, PXLToSpend)) {
            pxlProperty.setPropertyRowColor(propertyID, row, newColorData);
            var (lastUpdater, becomePublic) = pxlProperty.getPropertyLastUpdaterBecomePublic(propertyID);
            PropertyColorUpdate(propertyID, pxlProperty.getPropertyColors(propertyID), now, lastUpdater, becomePublic, projectedPayout);
            return true;
        }
        return false;
    }
    // Property owners can toggle their Properties between private mode and free-use mode
    function setPropertyMode(uint16 propertyID, bool setPrivateMode, uint32 numMinutesPrivate) public validPropertyID(propertyID) {
        var (propertyFlag, propertyIsInPrivateMode, propertyOwner, propertyLastUpdater, propertySalePrice, propertyLastUpdate, propertyBecomePublic, propertyEarnUntil) = pxlProperty.properties(propertyID);
        
        require(msg.sender == propertyOwner);
        uint256 whenToBecomePublic = 0;
        uint256 rewardedAmount = 0;
        
        if (setPrivateMode) {
            //If inprivate, we can extend the duration, otherwise if becomePublic > now it means a free-use user locked it
            require(propertyIsInPrivateMode || propertyBecomePublic <= now || propertyLastUpdater == msg.sender ); 
            require(numMinutesPrivate > 0);
            require(pxlProperty.balanceOf(msg.sender) >= numMinutesPrivate);
            // Determines when the Property becomes public, one payout interval per coin burned
            whenToBecomePublic = (now < propertyBecomePublic ? propertyBecomePublic : now) + PROPERTY_GENERATION_PAYOUT_INTERVAL * numMinutesPrivate;

            rewardedAmount = getProjectedPayout(propertyIsInPrivateMode, propertyLastUpdate, propertyEarnUntil);
            if (rewardedAmount > 0 && propertyLastUpdater != 0) {
                pxlProperty.burnPXLRewardPXLx2(msg.sender, numMinutesPrivate, propertyLastUpdater, rewardedAmount, msg.sender, rewardedAmount);
            } else {
                pxlProperty.burnPXL(msg.sender, numMinutesPrivate);
            }

        } else {
            // If its in private mode and still has time left, reimburse them for N-1 minutes tokens back
            if (propertyIsInPrivateMode && propertyBecomePublic > now) {
                pxlProperty.rewardPXL(msg.sender, ((propertyBecomePublic - now) / PROPERTY_GENERATION_PAYOUT_INTERVAL) - 1);
            }
        }
        
        pxlProperty.setPropertyPrivateModeEarnUntilLastUpdateBecomePublic(propertyID, setPrivateMode, 0, 0, whenToBecomePublic);
        
        if (setPrivateMode) {
            SetPropertyPrivate(propertyID, numMinutesPrivate, propertyLastUpdater, rewardedAmount);
        } else {
            SetPropertyPublic(propertyID);
        }
    }
    // Transfer Property ownership between accounts. This has no cost, no cut and does not change flag status
    function transferProperty(uint16 propertyID, address newOwner) public validPropertyID(propertyID) returns(bool) {
        require(pxlProperty.getPropertyOwner(propertyID) == msg.sender);
        _transferProperty(propertyID, newOwner, 0, 0, pxlProperty.getPropertyFlag(propertyID), msg.sender);
        return true;
    }
    // Purchase a unowned system-Property in a combination of PXL and ETH
    function buyProperty(uint16 propertyID, uint256 pxlValue) public validPropertyID(propertyID) payable returns(bool) {
        //Must be the first purchase, otherwise do it with PXL from another user
        require(pxlProperty.getPropertyOwner(propertyID) == 0);
        // Must be able to afford the given PXL
        require(pxlProperty.balanceOf(msg.sender) >= pxlValue);
        require(pxlValue != 0);
        
        // Protect against underflow
        require(pxlValue <= systemSalePricePXL);
        uint256 pxlLeft = systemSalePricePXL - pxlValue;
        uint256 ethLeft = systemSalePriceETH / systemSalePricePXL * pxlLeft;
        
        // Must have spent enough ETH to cover the ETH left after PXL price was subtracted
        require(msg.value >= ethLeft);
        
        pxlProperty.burnPXLRewardPXL(msg.sender, pxlValue, owner, pxlValue);
        
        systemPXLStepTally += uint16(100 * pxlValue / systemSalePricePXL);
        if (systemPXLStepTally >= 1000) {
             systemPXLStepCount++;
            systemSalePricePXL += systemSalePricePXL * 9 / systemPXLStepCount / 10;
            systemPXLStepTally -= 1000;
        }
        
        ownerEth += msg.value;

        systemETHStepTally += uint16(100 * pxlLeft / systemSalePricePXL);
        if (systemETHStepTally >= 1000) {
            systemETHStepCount++;
            systemSalePriceETH += systemSalePriceETH * 9 / systemETHStepCount / 10;
            systemETHStepTally -= 1000;
        }

        _transferProperty(propertyID, msg.sender, msg.value, pxlValue, 0, 0);
        
        return true;
    }
    // Purchase a listed user-owner Property in PXL
    function buyPropertyInPXL(uint16 propertyID, uint256 PXLValue) public validPropertyID(propertyID) {
        // If Property is system-owned
        var (propertyOwner, propertySalePrice) = pxlProperty.getPropertyOwnerSalePrice(propertyID);
        address originalOwner = propertyOwner;
        if (propertyOwner == 0) {
            // Turn it into a user-owned at system price with contract owner as owner
            pxlProperty.setPropertyOwnerSalePrice(propertyID, owner, systemSalePricePXL);
            propertyOwner = owner;
            propertySalePrice = systemSalePricePXL;
            // Increase system PXL price
            systemPXLStepTally += 100;
            if (systemPXLStepTally >= 1000) {
                systemPXLStepCount++;
                systemSalePricePXL += systemSalePricePXL * 9 / systemPXLStepCount / 10;
                systemPXLStepTally -= 1000;
            }
        }
        require(propertySalePrice <= PXLValue);
        uint256 amountTransfered = propertySalePrice * USER_BUY_CUT_PERCENT / 100;
        pxlProperty.burnPXLRewardPXLx2(msg.sender, propertySalePrice, propertyOwner, amountTransfered, owner, (propertySalePrice - amountTransfered));        
        _transferProperty(propertyID, msg.sender, 0, propertySalePrice, 0, originalOwner);
    }

    // Purchase a system-Property in pure ETH
    function buyPropertyInETH(uint16 propertyID) public validPropertyID(propertyID) payable returns(bool) {
        require(pxlProperty.getPropertyOwner(propertyID) == 0);
        require(msg.value >= systemSalePriceETH);
        
        ownerEth += msg.value;
        systemETHStepTally += 100;
        if (systemETHStepTally >= 1000) {
            systemETHStepCount++;
            systemSalePriceETH += systemSalePriceETH * 9 / systemETHStepCount / 10;
            systemETHStepTally -= 1000;
        }
        _transferProperty(propertyID, msg.sender, msg.value, 0, 0, 0);
        return true;
    }
    
    // Property owner lists their Property for sale at their preferred price
    function listForSale(uint16 propertyID, uint256 price) public validPropertyID(propertyID) returns(bool) {
        require(price != 0);
        require(msg.sender == pxlProperty.getPropertyOwner(propertyID));
        pxlProperty.setPropertySalePrice(propertyID, price);
        PropertySetForSale(propertyID, price);
        return true;
    }
    
    // Property owner delists their Property from being for sale
    function delist(uint16 propertyID) public validPropertyID(propertyID) returns(bool) {
        require(msg.sender == pxlProperty.getPropertyOwner(propertyID));
        pxlProperty.setPropertySalePrice(propertyID, 0);
        DelistProperty(propertyID);
        return true;
    }

    // Make a public bid and notify a Property owner of your bid. Burn 1 coin
    function makeBid(uint16 propertyID, uint256 bidAmount) public validPropertyID(propertyID) {
        require(bidAmount > 0);
        require(pxlProperty.balanceOf(msg.sender) >= 1 + bidAmount);
        Bid(propertyID, bidAmount, now);
        pxlProperty.burnPXL(msg.sender, 1);
    }
    
    /* CONTRACT OWNER FUNCTIONS */
    
    // Contract owner can withdraw up to ownerEth amount
    function withdraw(uint256 amount) public ownerOnly() {
        if (amount <= ownerEth) {
            owner.transfer(amount);
            ownerEth -= amount;
        }
    }
    
    // Contract owner can withdraw ownerEth amount
    function withdrawAll() public ownerOnly() {
        owner.transfer(ownerEth);
        ownerEth = 0;
    }
    
    // Contract owner can change who is the contract owner
    function changeOwners(address newOwner) public ownerOnly() {
        owner = newOwner;
    }
    
    /* ## PRIVATE FUNCTIONS ## */
    
    // Function which wraps payouts for setColors
    function _tryTriggerPayout(uint16 propertyID, uint256 pxlToSpend) private returns(bool) {
        var (propertyFlag, propertyIsInPrivateMode, propertyOwner, propertyLastUpdater, propertySalePrice, propertyLastUpdate, propertyBecomePublic, propertyEarnUntil) = pxlProperty.properties(propertyID);
        //If the Property is in private mode and expired, make it public
        if (propertyIsInPrivateMode && propertyBecomePublic <= now) {
            pxlProperty.setPropertyPrivateMode(propertyID, false);
            propertyIsInPrivateMode = false;
        }
        //If its in private mode, only the owner can interact with it
        if (propertyIsInPrivateMode) {
            require(msg.sender == propertyOwner);
            require(propertyFlag != 2);
        //If if its in free-use mode
        } else if (propertyBecomePublic <= now || propertyLastUpdater == msg.sender) {
            uint256 pxlSpent = pxlToSpend + 1; //All pxlSpent math uses N+1, so built in for convenience
            if (isInGracePeriod() && pxlToSpend < 2) { //If first 3 days and we spent <2 coins, treat it as if we spent 2
                pxlSpent = 3; //We&#39;re treating it like 2, but it&#39;s N+1 in the math using this
            }
            
            uint256 projectedAmount = getProjectedPayout(propertyIsInPrivateMode, propertyLastUpdate, propertyEarnUntil);
            pxlProperty.burnPXLRewardPXLx2(msg.sender, pxlToSpend, propertyLastUpdater, projectedAmount, propertyOwner, projectedAmount);
            
            //BecomePublic = (N+1)/2 minutes of user-private mode
            //EarnUntil = (N+1)*5 coins earned max/minutes we can earn from
            pxlProperty.setPropertyBecomePublicEarnUntil(propertyID, now + (pxlSpent * PROPERTY_GENERATION_PAYOUT_INTERVAL / 2), now + (pxlSpent * 5 * PROPERTY_GENERATION_PAYOUT_INTERVAL));
        } else {
            return false;
        }
        pxlProperty.setPropertyLastUpdaterLastUpdate(propertyID, msg.sender, now);
        return true;
    }
    // Transfer ownership of a Property and reset their info
    function _transferProperty(uint16 propertyID, address newOwner, uint256 ethAmount, uint256 PXLAmount, uint8 flag, address oldOwner) private {
        require(newOwner != 0);
        pxlProperty.setPropertyOwnerSalePricePrivateModeFlag(propertyID, newOwner, 0, false, flag);
        PropertyBought(propertyID, newOwner, ethAmount, PXLAmount, now, oldOwner);
    }
    
    // Gets the (owners address, Ethereum sale price, PXL sale price, last update timestamp, whether its in private mode or not, when it becomes public timestamp, flag) for a Property
    function getPropertyData(uint16 propertyID) public validPropertyID(propertyID) view returns(address, uint256, uint256, uint256, bool, uint256, uint32) {
        return pxlProperty.getPropertyData(propertyID, systemSalePriceETH, systemSalePricePXL);
    }
    
    // Gets the system ETH and PXL prices
    function getSystemSalePrices() public view returns(uint256, uint256) {
        return (systemSalePriceETH, systemSalePricePXL);
    }
    
    // Gets the sale prices of any Property in ETH and PXL
    function getForSalePrices(uint16 propertyID) public validPropertyID(propertyID) view returns(uint256, uint256) {
        if (pxlProperty.getPropertyOwner(propertyID) == 0) {
            return getSystemSalePrices();
        } else {
            return (0, pxlProperty.getPropertySalePrice(propertyID));
        }
    }
    
    // Gets the projected sale price for a property should it be triggered at this very moment
    function getProjectedPayout(uint16 propertyID) public view returns(uint256) {
        var (propertyIsInPrivateMode, propertyLastUpdate, propertyEarnUntil) = pxlProperty.getPropertyPrivateModeLastUpdateEarnUntil(propertyID);
        return getProjectedPayout(propertyIsInPrivateMode, propertyLastUpdate, propertyEarnUntil);
    }
    
    function getProjectedPayout(bool propertyIsInPrivateMode, uint256 propertyLastUpdate, uint256 propertyEarnUntil) public view returns(uint256) {
        if (!propertyIsInPrivateMode && propertyLastUpdate != 0) {
            uint256 earnedUntil = (now < propertyEarnUntil) ? now : propertyEarnUntil;
            uint256 minutesSinceLastColourChange = (earnedUntil - propertyLastUpdate) / PROPERTY_GENERATION_PAYOUT_INTERVAL;
            return minutesSinceLastColourChange * PROPERTY_GENERATES_PER_MINUTE;
            //return (((now < propertyEarnUntil) ? now : propertyEarnUntil - propertyLastUpdate) / PROPERTY_GENERATION_PAYOUT_INTERVAL) * PROPERTY_GENERATES_PER_MINUTE; //Gave too high number wtf?
        }
        return 0;
    }
    
    // Gets whether the contract is still in the intial grace period where we give extra features to color setters
    function isInGracePeriod() public view returns(bool) {
        return now <= GRACE_PERIOD_END_TIMESTAMP;
    }
}