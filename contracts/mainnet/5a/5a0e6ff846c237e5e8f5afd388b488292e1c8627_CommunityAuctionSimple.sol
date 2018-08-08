pragma solidity 0.4.24;

interface CommAuctionIface {
    function getNextPrice(bytes32 democHash) external view returns (uint);
    function noteBallotDeployed(bytes32 democHash) external;

    // add more when we need it

    function upgradeMe(address newSC) external;
}

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

contract CommunityAuctionSimple is owned {
    // about $1USD at $600usd/eth
    uint public commBallotPriceWei = 1666666666000000;

    struct Record {
        bytes32 democHash;
        uint ts;
    }

    mapping (address => Record[]) public ballotLog;
    mapping (address => address) public upgrades;

    function getNextPrice(bytes32) external view returns (uint) {
        return commBallotPriceWei;
    }

    function noteBallotDeployed(bytes32 d) external {
        require(upgrades[msg.sender] == address(0));
        ballotLog[msg.sender].push(Record(d, now));
    }

    function upgradeMe(address newSC) external {
        require(upgrades[msg.sender] == address(0));
        upgrades[msg.sender] = newSC;
    }

    function getBallotLogN(address a) external view returns (uint) {
        return ballotLog[a].length;
    }

    function setPriceWei(uint newPrice) only_owner() external {
        commBallotPriceWei = newPrice;
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