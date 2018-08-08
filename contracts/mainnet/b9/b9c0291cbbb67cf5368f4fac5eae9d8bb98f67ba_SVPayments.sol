pragma solidity 0.4.24;

contract safeSend {
    bool private txMutex3847834;

    // we want to be able to call outside contracts (e.g. the admin proxy contract)
    // but reentrency is bad, so here&#39;s a mutex.
    function doSafeSend(address toAddr, uint amount) internal {
        doSafeSendWData(toAddr, "", amount);
    }

    function doSafeSendWData(address toAddr, bytes data, uint amount) internal {
        require(txMutex3847834 == false, "ss-guard");
        txMutex3847834 = true;
        // we need to use address.call.value(v)() because we want
        // to be able to send to other contracts, even with no data,
        // which might use more than 2300 gas in their fallback function.
        require(toAddr.call.value(amount)(data), "ss-failed");
        txMutex3847834 = false;
    }
}

contract payoutAllC is safeSend {
    address private _payTo;

    event PayoutAll(address payTo, uint value);

    constructor(address initPayTo) public {
        // DEV NOTE: you can overwrite _getPayTo if you want to reuse other storage vars
        assert(initPayTo != address(0));
        _payTo = initPayTo;
    }

    function _getPayTo() internal view returns (address) {
        return _payTo;
    }

    function _setPayTo(address newPayTo) internal {
        _payTo = newPayTo;
    }

    function payoutAll() external {
        address a = _getPayTo();
        uint bal = address(this).balance;
        doSafeSend(a, bal);
        emit PayoutAll(a, bal);
    }
}

contract payoutAllCSettable is payoutAllC {
    constructor (address initPayTo) payoutAllC(initPayTo) public {
    }

    function setPayTo(address) external;
    function getPayTo() external view returns (address) {
        return _getPayTo();
    }
}

contract owned {
    address public owner;

    event OwnerChanged(address newOwner);

    modifier only_owner() {
        require(msg.sender == owner, "only_owner: forbidden");
        _;
    }

    modifier owner_or(address addr) {
        require(msg.sender == addr || msg.sender == owner, "!owner-or");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address newOwner) only_owner() external {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
}

contract CanReclaimToken is owned {

    /**
    * @dev Reclaim all ERC20Basic compatible tokens
    * @param token ERC20Basic The address of the token contract
    */
    function reclaimToken(ERC20Interface token) external only_owner {
        uint256 balance = token.balanceOf(this);
        require(token.approve(owner, balance));
    }

}

contract controlledIface {
    function controller() external view returns (address);
}

contract hasAdmins is owned {
    mapping (uint => mapping (address => bool)) admins;
    uint public currAdminEpoch = 0;
    bool public adminsDisabledForever = false;
    address[] adminLog;

    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed oldAdmin);
    event AdminEpochInc();
    event AdminDisabledForever();

    modifier only_admin() {
        require(adminsDisabledForever == false, "admins must not be disabled");
        require(isAdmin(msg.sender), "only_admin: forbidden");
        _;
    }

    constructor() public {
        _setAdmin(msg.sender, true);
    }

    function isAdmin(address a) view public returns (bool) {
        return admins[currAdminEpoch][a];
    }

    function getAdminLogN() view external returns (uint) {
        return adminLog.length;
    }

    function getAdminLog(uint n) view external returns (address) {
        return adminLog[n];
    }

    function upgradeMeAdmin(address newAdmin) only_admin() external {
        // note: already checked msg.sender has admin with `only_admin` modifier
        require(msg.sender != owner, "owner cannot upgrade self");
        _setAdmin(msg.sender, false);
        _setAdmin(newAdmin, true);
    }

    function setAdmin(address a, bool _givePerms) only_admin() external {
        require(a != msg.sender && a != owner, "cannot change your own (or owner&#39;s) permissions");
        _setAdmin(a, _givePerms);
    }

    function _setAdmin(address a, bool _givePerms) internal {
        admins[currAdminEpoch][a] = _givePerms;
        if (_givePerms) {
            emit AdminAdded(a);
            adminLog.push(a);
        } else {
            emit AdminRemoved(a);
        }
    }

    // safety feature if admins go bad or something
    function incAdminEpoch() only_owner() external {
        currAdminEpoch++;
        admins[currAdminEpoch][msg.sender] = true;
        emit AdminEpochInc();
    }

    // this is internal so contracts can all it, but not exposed anywhere in this
    // contract.
    function disableAdminForever() internal {
        currAdminEpoch++;
        adminsDisabledForever = true;
        emit AdminDisabledForever();
    }
}

contract permissioned is owned, hasAdmins {
    mapping (address => bool) editAllowed;
    bool public adminLockdown = false;

    event PermissionError(address editAddr);
    event PermissionGranted(address editAddr);
    event PermissionRevoked(address editAddr);
    event PermissionsUpgraded(address oldSC, address newSC);
    event SelfUpgrade(address oldSC, address newSC);
    event AdminLockdown();

    modifier only_editors() {
        require(editAllowed[msg.sender], "only_editors: forbidden");
        _;
    }

    modifier no_lockdown() {
        require(adminLockdown == false, "no_lockdown: check failed");
        _;
    }


    constructor() owned() hasAdmins() public {
    }


    function setPermissions(address e, bool _editPerms) no_lockdown() only_admin() external {
        editAllowed[e] = _editPerms;
        if (_editPerms)
            emit PermissionGranted(e);
        else
            emit PermissionRevoked(e);
    }

    function upgradePermissionedSC(address oldSC, address newSC) no_lockdown() only_admin() external {
        editAllowed[oldSC] = false;
        editAllowed[newSC] = true;
        emit PermissionsUpgraded(oldSC, newSC);
    }

    // always allow SCs to upgrade themselves, even after lockdown
    function upgradeMe(address newSC) only_editors() external {
        editAllowed[msg.sender] = false;
        editAllowed[newSC] = true;
        emit SelfUpgrade(msg.sender, newSC);
    }

    function hasPermissions(address a) public view returns (bool) {
        return editAllowed[a];
    }

    function doLockdown() external only_owner() no_lockdown() {
        disableAdminForever();
        adminLockdown = true;
        emit AdminLockdown();
    }
}

contract upgradePtr {
    address ptr = address(0);

    modifier not_upgraded() {
        require(ptr == address(0), "upgrade pointer is non-zero");
        _;
    }

    function getUpgradePointer() view external returns (address) {
        return ptr;
    }

    function doUpgradeInternal(address nextSC) internal {
        ptr = nextSC;
    }
}

interface ERC20Interface {
    // Get the total token supply
    function totalSupply() constant external returns (uint256 _totalSupply);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant external returns (uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) external returns (bool success);

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) external returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
    function subToZero(uint a, uint b) internal pure returns (uint) {
        if (a < b) {  // then (a - b) would overflow
            return 0;
        }
        return a - b;
    }
}

contract ixPaymentEvents {
    event UpgradedToPremium(bytes32 indexed democHash);
    event GrantedAccountTime(bytes32 indexed democHash, uint additionalSeconds, bytes32 ref);
    event AccountPayment(bytes32 indexed democHash, uint additionalSeconds);
    event SetCommunityBallotFee(uint amount);
    event SetBasicCentsPricePer30Days(uint amount);
    event SetPremiumMultiplier(uint8 multiplier);
    event DowngradeToBasic(bytes32 indexed democHash);
    event UpgradeToPremium(bytes32 indexed democHash);
    event SetExchangeRate(uint weiPerCent);
    event FreeExtension(bytes32 democHash);
    event SetBallotsPer30Days(uint amount);
    event SetFreeExtension(bytes32 democHash, bool hasFreeExt);
    event SetDenyPremium(bytes32 democHash, bool isPremiumDenied);
    event SetPayTo(address payTo);
    event SetMinorEditsAddr(address minorEditsAddr);
    event SetMinWeiForDInit(uint amount);
}

interface hasVersion {
    function getVersion() external pure returns (uint);
}

contract IxPaymentsIface is hasVersion, ixPaymentEvents, permissioned, CanReclaimToken, payoutAllCSettable {
    /* in emergency break glass */
    function emergencySetOwner(address newOwner) external;

    /* financial calcluations */
    function weiBuysHowManySeconds(uint amount) public view returns (uint secs);
    function weiToCents(uint w) public view returns (uint);
    function centsToWei(uint c) public view returns (uint);

    /* account management */
    function payForDemocracy(bytes32 democHash) external payable;
    function doFreeExtension(bytes32 democHash) external;
    function downgradeToBasic(bytes32 democHash) external;
    function upgradeToPremium(bytes32 democHash) external;

    /* account status - getters */
    function accountInGoodStanding(bytes32 democHash) external view returns (bool);
    function getSecondsRemaining(bytes32 democHash) external view returns (uint);
    function getPremiumStatus(bytes32 democHash) external view returns (bool);
    function getFreeExtension(bytes32 democHash) external view returns (bool);
    function getAccount(bytes32 democHash) external view returns (bool isPremium, uint lastPaymentTs, uint paidUpTill, bool hasFreeExtension);
    function getDenyPremium(bytes32 democHash) external view returns (bool);

    /* admin utils for accounts */
    function giveTimeToDemoc(bytes32 democHash, uint additionalSeconds, bytes32 ref) external;

    /* admin setters global */
    function setPayTo(address) external;
    function setMinorEditsAddr(address) external;
    function setBasicCentsPricePer30Days(uint amount) external;
    function setBasicBallotsPer30Days(uint amount) external;
    function setPremiumMultiplier(uint8 amount) external;
    function setWeiPerCent(uint) external;
    function setFreeExtension(bytes32 democHash, bool hasFreeExt) external;
    function setDenyPremium(bytes32 democHash, bool isPremiumDenied) external;
    function setMinWeiForDInit(uint amount) external;

    /* global getters */
    function getBasicCentsPricePer30Days() external view returns(uint);
    function getBasicExtraBallotFeeWei() external view returns (uint);
    function getBasicBallotsPer30Days() external view returns (uint);
    function getPremiumMultiplier() external view returns (uint8);
    function getPremiumCentsPricePer30Days() external view returns (uint);
    function getWeiPerCent() external view returns (uint weiPerCent);
    function getUsdEthExchangeRate() external view returns (uint centsPerEth);
    function getMinWeiForDInit() external view returns (uint);

    /* payments stuff */
    function getPaymentLogN() external view returns (uint);
    function getPaymentLog(uint n) external view returns (bool _external, bytes32 _democHash, uint _seconds, uint _ethValue);
}

contract SVPayments is IxPaymentsIface {
    uint constant VERSION = 2;

    struct Account {
        bool isPremium;
        uint lastPaymentTs;
        uint paidUpTill;
        uint lastUpgradeTs;  // timestamp of the last time it was upgraded to premium
    }

    struct PaymentLog {
        bool _external;
        bytes32 _democHash;
        uint _seconds;
        uint _ethValue;
    }

    // this is an address that&#39;s only allowed to make minor edits
    // e.g. setExchangeRate, setDenyPremium, giveTimeToDemoc
    address public minorEditsAddr;

    // payment details
    uint basicCentsPricePer30Days = 125000; // $1250/mo
    uint basicBallotsPer30Days = 10;
    uint8 premiumMultiplier = 5;
    uint weiPerCent = 0.000016583747 ether;  // $603, 4th June 2018

    uint minWeiForDInit = 1;  // minimum 1 wei - match existing behaviour in SVIndex

    mapping (bytes32 => Account) accounts;
    PaymentLog[] payments;

    // can set this on freeExtension democs to deny them premium upgrades
    mapping (bytes32 => bool) denyPremium;
    // this is used for non-profits or organisations that have perpetual licenses, etc
    mapping (bytes32 => bool) freeExtension;


    /* BREAK GLASS IN CASE OF EMERGENCY */
    // this is included here because something going wrong with payments is possibly
    // the absolute worst case. Note: does this have negligable benefit if the other
    // contracts are compromised? (e.g. by a leaked privkey)
    address public emergencyAdmin;
    function emergencySetOwner(address newOwner) external {
        require(msg.sender == emergencyAdmin, "!emergency-owner");
        owner = newOwner;
    }
    /* END BREAK GLASS */


    constructor(address _emergencyAdmin) payoutAllCSettable(msg.sender) public {
        emergencyAdmin = _emergencyAdmin;
        assert(_emergencyAdmin != address(0));
    }

    /* base SCs */

    function getVersion() external pure returns (uint) {
        return VERSION;
    }

    function() payable public {
        _getPayTo().transfer(msg.value);
    }

    function _modAccountBalance(bytes32 democHash, uint additionalSeconds) internal {
        uint prevPaidTill = accounts[democHash].paidUpTill;
        if (prevPaidTill < now) {
            prevPaidTill = now;
        }

        accounts[democHash].paidUpTill = prevPaidTill + additionalSeconds;
        accounts[democHash].lastPaymentTs = now;
    }

    /* Financial Calculations */

    function weiBuysHowManySeconds(uint amount) public view returns (uint) {
        uint centsPaid = weiToCents(amount);
        // multiply by 10**18 to ensure we make rounding errors insignificant
        uint monthsOffsetPaid = ((10 ** 18) * centsPaid) / basicCentsPricePer30Days;
        uint secondsOffsetPaid = monthsOffsetPaid * (30 days);
        uint additionalSeconds = secondsOffsetPaid / (10 ** 18);
        return additionalSeconds;
    }

    function weiToCents(uint w) public view returns (uint) {
        return w / weiPerCent;
    }

    function centsToWei(uint c) public view returns (uint) {
        return c * weiPerCent;
    }

    /* account management */

    function payForDemocracy(bytes32 democHash) external payable {
        require(msg.value > 0, "need to send some ether to make payment");

        uint additionalSeconds = weiBuysHowManySeconds(msg.value);

        if (accounts[democHash].isPremium) {
            additionalSeconds /= premiumMultiplier;
        }

        if (additionalSeconds >= 1) {
            _modAccountBalance(democHash, additionalSeconds);
        }
        payments.push(PaymentLog(false, democHash, additionalSeconds, msg.value));
        emit AccountPayment(democHash, additionalSeconds);

        _getPayTo().transfer(msg.value);
    }

    function doFreeExtension(bytes32 democHash) external {
        require(freeExtension[democHash], "!free");
        uint newPaidUpTill = now + 60 days;
        accounts[democHash].paidUpTill = newPaidUpTill;
        emit FreeExtension(democHash);
    }

    function downgradeToBasic(bytes32 democHash) only_editors() external {
        require(accounts[democHash].isPremium, "!premium");
        accounts[democHash].isPremium = false;
        // convert premium minutes to basic
        uint paidTill = accounts[democHash].paidUpTill;
        uint timeRemaining = SafeMath.subToZero(paidTill, now);
        // if we have time remaining: convert it
        if (timeRemaining > 0) {
            // prevent accounts from downgrading if they have time remaining
            // and upgraded less than 24hrs ago
            require(accounts[democHash].lastUpgradeTs < (now - 24 hours), "downgrade-too-soon");
            timeRemaining *= premiumMultiplier;
            accounts[democHash].paidUpTill = now + timeRemaining;
        }
        emit DowngradeToBasic(democHash);
    }

    function upgradeToPremium(bytes32 democHash) only_editors() external {
        require(denyPremium[democHash] == false, "upgrade-denied");
        require(!accounts[democHash].isPremium, "!basic");
        accounts[democHash].isPremium = true;
        // convert basic minutes to premium minutes
        uint paidTill = accounts[democHash].paidUpTill;
        uint timeRemaining = SafeMath.subToZero(paidTill, now);
        // if we have time remaning then convert it - otherwise don&#39;t need to do anything
        if (timeRemaining > 0) {
            timeRemaining /= premiumMultiplier;
            accounts[democHash].paidUpTill = now + timeRemaining;
        }
        accounts[democHash].lastUpgradeTs = now;
        emit UpgradedToPremium(democHash);
    }

    /* account status - getters */

    function accountInGoodStanding(bytes32 democHash) external view returns (bool) {
        return accounts[democHash].paidUpTill >= now;
    }

    function getSecondsRemaining(bytes32 democHash) external view returns (uint) {
        return SafeMath.subToZero(accounts[democHash].paidUpTill, now);
    }

    function getPremiumStatus(bytes32 democHash) external view returns (bool) {
        return accounts[democHash].isPremium;
    }

    function getFreeExtension(bytes32 democHash) external view returns (bool) {
        return freeExtension[democHash];
    }

    function getAccount(bytes32 democHash) external view returns (bool isPremium, uint lastPaymentTs, uint paidUpTill, bool hasFreeExtension) {
        isPremium = accounts[democHash].isPremium;
        lastPaymentTs = accounts[democHash].lastPaymentTs;
        paidUpTill = accounts[democHash].paidUpTill;
        hasFreeExtension = freeExtension[democHash];
    }

    function getDenyPremium(bytes32 democHash) external view returns (bool) {
        return denyPremium[democHash];
    }

    /* admin utils for accounts */

    function giveTimeToDemoc(bytes32 democHash, uint additionalSeconds, bytes32 ref) owner_or(minorEditsAddr) external {
        _modAccountBalance(democHash, additionalSeconds);
        payments.push(PaymentLog(true, democHash, additionalSeconds, 0));
        emit GrantedAccountTime(democHash, additionalSeconds, ref);
    }

    /* admin setters global */

    function setPayTo(address newPayTo) only_owner() external {
        _setPayTo(newPayTo);
        emit SetPayTo(newPayTo);
    }

    function setMinorEditsAddr(address a) only_owner() external {
        minorEditsAddr = a;
        emit SetMinorEditsAddr(a);
    }

    function setBasicCentsPricePer30Days(uint amount) only_owner() external {
        basicCentsPricePer30Days = amount;
        emit SetBasicCentsPricePer30Days(amount);
    }

    function setBasicBallotsPer30Days(uint amount) only_owner() external {
        basicBallotsPer30Days = amount;
        emit SetBallotsPer30Days(amount);
    }

    function setPremiumMultiplier(uint8 m) only_owner() external {
        premiumMultiplier = m;
        emit SetPremiumMultiplier(m);
    }

    function setWeiPerCent(uint wpc) owner_or(minorEditsAddr) external {
        weiPerCent = wpc;
        emit SetExchangeRate(wpc);
    }

    function setFreeExtension(bytes32 democHash, bool hasFreeExt) owner_or(minorEditsAddr) external {
        freeExtension[democHash] = hasFreeExt;
        emit SetFreeExtension(democHash, hasFreeExt);
    }

    function setDenyPremium(bytes32 democHash, bool isPremiumDenied) owner_or(minorEditsAddr) external {
        denyPremium[democHash] = isPremiumDenied;
        emit SetDenyPremium(democHash, isPremiumDenied);
    }

    function setMinWeiForDInit(uint amount) owner_or(minorEditsAddr) external {
        minWeiForDInit = amount;
        emit SetMinWeiForDInit(amount);
    }

    /* global getters */

    function getBasicCentsPricePer30Days() external view returns (uint) {
        return basicCentsPricePer30Days;
    }

    function getBasicExtraBallotFeeWei() external view returns (uint) {
        return centsToWei(basicCentsPricePer30Days / basicBallotsPer30Days);
    }

    function getBasicBallotsPer30Days() external view returns (uint) {
        return basicBallotsPer30Days;
    }

    function getPremiumMultiplier() external view returns (uint8) {
        return premiumMultiplier;
    }

    function getPremiumCentsPricePer30Days() external view returns (uint) {
        return _premiumPricePer30Days();
    }

    function _premiumPricePer30Days() internal view returns (uint) {
        return uint(premiumMultiplier) * basicCentsPricePer30Days;
    }

    function getWeiPerCent() external view returns (uint) {
        return weiPerCent;
    }

    function getUsdEthExchangeRate() external view returns (uint) {
        // this returns cents per ether
        return 1 ether / weiPerCent;
    }

    function getMinWeiForDInit() external view returns (uint) {
        return minWeiForDInit;
    }

    /* payments stuff */

    function getPaymentLogN() external view returns (uint) {
        return payments.length;
    }

    function getPaymentLog(uint n) external view returns (bool _external, bytes32 _democHash, uint _seconds, uint _ethValue) {
        _external = payments[n]._external;
        _democHash = payments[n]._democHash;
        _seconds = payments[n]._seconds;
        _ethValue = payments[n]._ethValue;
    }
}