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
    /* ERC-20 MetaData */
    string public constant name = "PixelPropertyToken";
    string public constant symbol = "PXL";
    uint256 public constant decimals = 0;
    
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
    // Whether migration is occuring or not
    bool inMigrationPeriod;
    // Old PXLProperty Contract from before update we migrate data from
    PXLProperty oldPXLProperty;
    
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
    function PXLProperty(address oldAddress) public {
        inMigrationPeriod = true;
        oldPXLProperty = PXLProperty(oldAddress);
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
    
        
    /* ### Migration Functions Post Update ### */
    //Migrates the owners of Properties
    function migratePropertyOwnership(uint16[10] propertiesToCopy) public regulatorAccess(LEVEL_3_ROOT) {
        require(inMigrationPeriod);
        for(uint16 i = 0; i < 10; i++) {
            if (propertiesToCopy[i] < 10000) {
                if (properties[propertiesToCopy[i]].owner == 0) { //Only migrate if there is no current owner
                    properties[propertiesToCopy[i]].owner = oldPXLProperty.getPropertyOwner(propertiesToCopy[i]);
                }
            }
        }
    }
    
    //Migrates the PXL balances of users
    function migrateUsers(address[10] usersToMigrate) public regulatorAccess(LEVEL_3_ROOT) {
        require(inMigrationPeriod);
        for(uint16 i = 0; i < 10; i++) {
            if(balances[usersToMigrate[i]] == 0) { //Only migrate if they have no funds to avoid duplicate migrations
                uint256 oldBalance = oldPXLProperty.balanceOf(usersToMigrate[i]);
                if (oldBalance > 0) {
                    balances[usersToMigrate[i]] = oldBalance;
                    totalSupply += oldBalance;
                    Transfer(0, usersToMigrate[i], oldBalance);
                }
            }
        }
    }
    
    //Perminantly ends migration so it cannot be abused after it is deemed complete
    function endMigrationPeriod() public regulatorAccess(LEVEL_3_ROOT) {
        inMigrationPeriod = false;
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
        Transfer(0, rewardedUser, amount);
    }
    
    function burnPXL(address burningUser, uint256 amount) public pixelPropertyAccess() {
        require(burningUser != 0);
        require(balances[burningUser] >= amount);
        balances[burningUser] -= amount;
        totalSupply -= amount;
        Transfer(burningUser, 0, amount);
    }
    
    function burnPXLRewardPXL(address burner, uint256 toBurn, address rewarder, uint256 toReward) public pixelPropertyAccess() {
        require(balances[burner] >= toBurn);
        if (toBurn > 0) {
            balances[burner] -= toBurn;
            totalSupply -= toBurn;
            Transfer(burner, 0, toBurn);
        }
        if (rewarder != 0) {
            balances[rewarder] += toReward;
            totalSupply += toReward;
            Transfer(0, rewarder, toReward);
        }
    } 
    
    function burnPXLRewardPXLx2(address burner, uint256 toBurn, address rewarder1, uint256 toReward1, address rewarder2, uint256 toReward2) public pixelPropertyAccess() {
        require(balances[burner] >= toBurn);
        if (toBurn > 0) {
            balances[burner] -= toBurn;
            totalSupply -= toBurn;
            Transfer(burner, 0, toBurn);
        }
        if (rewarder1 != 0) {
            balances[rewarder1] += toReward1;
            totalSupply += toReward1;
            Transfer(0, rewarder1, toReward1);
        }
        if (rewarder2 != 0) {
            balances[rewarder2] += toReward2;
            totalSupply += toReward2;
            Transfer(0, rewarder2, toReward2);
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
        if (properties[propertyID].colors[0] != 0 || properties[propertyID].colors[1] != 0 || properties[propertyID].colors[2] != 0 || properties[propertyID].colors[3] != 0 || properties[propertyID].colors[4] != 0) {
            return properties[propertyID].colors;
        } else {
            return oldPXLProperty.getPropertyColors(propertyID);
        }
    }

    function getPropertyColorsOfRow(uint16 propertyID, uint8 rowIndex) public view returns(uint256) {
        require(rowIndex <= 9);
        return getPropertyColors(propertyID)[rowIndex];
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