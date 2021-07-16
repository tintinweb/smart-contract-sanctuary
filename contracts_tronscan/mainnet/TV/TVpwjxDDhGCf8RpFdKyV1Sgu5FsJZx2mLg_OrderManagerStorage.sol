//SourceUnit: OrderManager.sol

pragma solidity >=0.5.0 <0.6.0;
contract KTimeController {
    uint public offsetTime;
}
contract KOwnerable {
    address[] internal _authAddress;
    address[] public KContractOwners;
    bool private _call_locked;
    constructor() public {
        KContractOwners.push(msg.sender);
        _authAddress.push(msg.sender);
    }
    function KAuthAddresses() external view returns (address[] memory) {
        return _authAddress;
    }
    function KAddAuthAddress(address auther) external KOwnerOnly {
        _authAddress.push(auther);
    }
    function KDelAuthAddress(address auther) external KOwnerOnly {
        for (uint i = 0; i < _authAddress.length; i++) {
            if (_authAddress[i] == auther) {
                for (uint j = 0; j < _authAddress.length - 1; j++) {
                    _authAddress[j] = _authAddress[j+1];
                }
                delete _authAddress[_authAddress.length - 1];
                _authAddress.pop();
                return ;
            }
        }
    }
    modifier KOwnerOnly() {
        bool exist = false;
        for ( uint i = 0; i < KContractOwners.length; i++ ) {
            if ( KContractOwners[i] == msg.sender ) {
                exist = true;
                break;
            }
        }
        require(exist, 'NotAuther'); _;
    }
    modifier KOwnerOnlyAPI() {
        bool exist = false;
        for ( uint i = 0; i < KContractOwners.length; i++ ) {
            if ( KContractOwners[i] == msg.sender ) {
                exist = true;
                break;
            }
        }
        require(exist, 'NotAuther'); _;
    }
    modifier KRejectContractCall() {
        uint256 size;
        address payable safeAddr = msg.sender;
        assembly {size := extcodesize(safeAddr)}
        require( size == 0, "Sender Is Contract" );
        _;
    }
    modifier KDAODefense() {
        require(!_call_locked, "DAO_Warning");
        _call_locked = true;
        _;
        _call_locked = false;
    }
    modifier KDelegateMethod() {
        bool exist = false;
        for (uint i = 0; i < _authAddress.length; i++) {
            if ( _authAddress[i] == msg.sender ) {
                exist = true;
                break;
            }
        }
        require(exist, "PermissionDeny"); _;
    }
    function uint2str(uint i) internal pure returns (string memory c) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte( uint8(48 + i % 10) );
            i /= 10;
        }
        c = string(bstr);
    }
}
contract KPausable is KOwnerable {
    event Paused(address account);
    event Unpaused(address account);
    bool public paused;
    constructor () internal {
        paused = false;
    }
    modifier KWhenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    modifier KWhenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }
    function Pause() public KOwnerOnly {
        paused = true;
        emit Paused(msg.sender);
    }
    function Unpause() public KOwnerOnly {
        paused = false;
        emit Unpaused(msg.sender);
    }
}
contract KDebug is KPausable {
    KTimeController internal debugTimeController;
    function timestemp() internal view returns (uint) {
        return now;
    }
}
contract KStorage is KDebug {
    address public KImplementAddress;
    function SetKImplementAddress(address impl) external KOwnerOnly {
        KImplementAddress = impl;
    }
    function () external {
        address impl_address = KImplementAddress;
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), impl_address, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}
contract KStoragePayable is KDebug {
    address public KImplementAddress;
    function SetKImplementAddress(address impl) external KOwnerOnly {
        KImplementAddress = impl;
    }
    function () external payable {
        address impl_address = KImplementAddress;
        assembly {
            if eq(calldatasize(), 0) {
                return(0, 0)
            }
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(gas(), impl_address, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}
interface iERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
pragma solidity >=0.5.1 <0.7.0;
interface iERC777_1 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    function granularity() external view returns (uint);
    function defaultOperators() external view returns (address[] memory);
    function addDefaultOperators(address owner) external returns (bool);
    function removeDefaultOperators(address owner) external returns (bool);
    function isOperatorFor(address operator, address holder) external view returns (bool);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
    function send(address to, uint amount, bytes calldata data) external;
    function operatorSend(address from, address to, uint amount, bytes calldata data, bytes calldata operatorData) external;
    function burn(uint amount, bytes calldata data) external;
    function operatorBurn(address from, uint amount, bytes calldata data, bytes calldata operatorData) external;
    event Sent(address indexed operator, address indexed from, address indexed to, uint amount, bytes data, bytes operatorData);
    event Minted(address indexed operator, address indexed to, uint amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed holder);
    event RevokedOperator(address indexed operator, address indexed holder);
}
pragma solidity >=0.5.1 <0.7.0;
contract CompensateStorage is KStorage {
    struct Compensate {
        uint total;
        uint currentWithdraw;
        uint latestWithdrawTime;
    }
    mapping(address => Compensate) public compensateMapping;
    iERC777_1 internal _mctInterface;
    constructor(
        iERC777_1 erc777Inc
    ) public {
        _mctInterface = erc777Inc;
    }
}
contract Compensate is CompensateStorage {
    constructor() public CompensateStorage(iERC777_1(0)) {}
    event Log_CompensateCreated(address indexed owner, uint when, uint compensateAmount);
    event Log_CompensateRelase(address indexed owner, uint when, uint relaseAmount);
    function increaseCompensateAmountDelegate(address owner, uint amount) external KDelegateMethod {
        compensateMapping[owner].total += amount;
        if ( compensateMapping[owner].latestWithdrawTime == 0 ) {
            compensateMapping[owner].latestWithdrawTime = timestemp() / 1 days * 1 days;
        }
        emit Log_CompensateCreated(msg.sender, timestemp(), amount);
    }
    function withdrawCompensate() external returns (uint amount) {
        Compensate storage c = compensateMapping[msg.sender];
        if ( c.total == 0 || c.currentWithdraw >= c.total ) {
            return 0;
        }
        uint deltaDay = (timestemp() - c.latestWithdrawTime) / 1 days;
        if ( deltaDay > 0 ) {
            amount = (c.total * 0.005e12 / 1e12) * deltaDay;
        } else {
            return 0;
        }
        if ( (amount + c.currentWithdraw) > c.total ) {
            amount = c.total - c.currentWithdraw;
        }
        if ( amount > 0 ) {
            c.currentWithdraw += amount;
            c.latestWithdrawTime = timestemp() / 1 days * 1 days;
            _mctInterface.operatorSend(
                address(_mctInterface),
                msg.sender,
                amount,
                "",
                "CompensateRelease"
            );
            emit Log_CompensateRelase(msg.sender, timestemp(), amount);
        }
    }
}
contract RelationsStorage is KStorage {
    enum AddRelationError {
        NoError,
        CannotBindYourSelf,
        AlreadyBinded,
        ParentUnbinded,
        ShortCodeExisted
    }
    address public rootAddress = address(0xdead);
    uint public totalAddresses;
    mapping (address => address) internal _recommerMapping;
    mapping (address => address[]) internal _recommerList;
    mapping (bytes6 => address) internal _shortCodeMapping;
    mapping (address => bytes6) internal _addressShotCodeMapping;
    mapping (address => bytes16) internal _nickenameMapping;
    mapping (address => uint) internal _depthMapping;
    mapping (address => uint8) internal _levelMapping;
    mapping (address => uint8) internal  _chilrenLevelMaxMapping;
    constructor() public {
        _shortCodeMapping[0x305844454144] = rootAddress;
        _addressShotCodeMapping[rootAddress] = 0x305844454144;
        _recommerMapping[rootAddress] = address(0xdeaddead);
    }
}
contract Relations is RelationsStorage {
    function levelOf(address owner) external view returns (uint) {
        return _levelMapping[owner];
    }
    function levelDistribution(address owner, uint maxLimit) external view returns (uint[] memory distribution) {
        address[] storage directAddresses = _recommerList[owner];
        distribution = new uint[](maxLimit + 1);
        for ( uint i = 0; i < directAddresses.length; i++) {
            uint lv = _chilrenLevelMaxMapping[directAddresses[i]];
            if ( lv <= maxLimit ) {
                distribution[lv]++;
            }
        }
    }
    function getIntroducer(address owner) external view returns (address) {
        return _recommerMapping[owner];
    }
    function getForefathers2(address owner, uint depth, uint endLevel) external view returns (uint[] memory seq, address[] memory fathers) {
        seq = new uint[](endLevel + 1);
        fathers = new address[](endLevel + 1);
        uint seqOffset = 0;
        address parent = _recommerMapping[owner];
        for (
            uint i = 0;
            ( i < depth && parent != address(0x0) && parent != rootAddress );
            ( i++, parent = _recommerMapping[parent] )
        ) {
            uint lv = uint(_levelMapping[parent]);
            if ( fathers[lv] == address(0) ) {
                fathers[lv] = parent;
                seq[seqOffset++] = uint(lv);
            }
            if ( lv >= endLevel + 1 ) {
                break;
            }
        }
    }
    function getForefathers(address owner, uint depth) external view returns (address[] memory, uint8[] memory) {
        address[] memory forefathers = new address[](depth);
        uint8[] memory levels = new uint8[](depth);
        for (
            (address parent, uint i) = (_recommerMapping[owner], 0);
            i < depth && parent != address(0) && parent != rootAddress;
            (i++, parent = _recommerMapping[parent])
        ) {
            forefathers[i] = parent;
            levels[i] = _levelMapping[parent];
        }
        return (forefathers, levels);
    }
    function recommendList(address owner) external view returns (address[] memory) {
        return (_recommerList[owner]);
    }
    function shortCodeToAddress(bytes6 shortCode) external view returns (address) {
        return _shortCodeMapping[shortCode];
    }
    function addressToShortCode(address addr) external view returns (bytes6) {
        return _addressShotCodeMapping[addr];
    }
    function addressToNickName(address addr) external view returns (bytes16) {
        return _nickenameMapping[addr];
    }
    function depth(address addr) external view returns (uint) {
        return _depthMapping[addr];
    }
    function registerShortCode(bytes6 shortCode) external returns (bool) {
        if ( _shortCodeMapping[shortCode] != address(0x0) ) {
            return false;
        }
        if ( _addressShotCodeMapping[msg.sender] != bytes6(0x0) ) {
            return false;
        }
        _shortCodeMapping[shortCode] = msg.sender;
        _addressShotCodeMapping[msg.sender] = shortCode;
        return true;
    }
    function updateNickName(bytes16 name) external {
        _nickenameMapping[msg.sender] = name;
    }
    function addRelationEx(address recommer, bytes6 shortCode, bytes16 nickname) external returns (AddRelationError) {
        if ( _shortCodeMapping[shortCode] != address(0x0) ) {
            return AddRelationError.ShortCodeExisted;
        }
        if ( _addressShotCodeMapping[msg.sender] != bytes6(0x0) ) {
            return AddRelationError.ShortCodeExisted;
        }
        if ( recommer == msg.sender )  {
            return AddRelationError.CannotBindYourSelf;
        }
        if ( _recommerMapping[msg.sender] != address(0x0) ) {
            return AddRelationError.AlreadyBinded;
        }
        if ( recommer != rootAddress && _recommerMapping[recommer] == address(0x0) ) {
            return AddRelationError.ParentUnbinded;
        }
        totalAddresses++;
        _shortCodeMapping[shortCode] = msg.sender;
        _addressShotCodeMapping[msg.sender] = shortCode;
        _nickenameMapping[msg.sender] = nickname;
        _recommerMapping[msg.sender] = recommer;
        _recommerList[recommer].push(msg.sender);
        _depthMapping[msg.sender] = _depthMapping[recommer] + 1;
        return AddRelationError.NoError;
    }
    function upgradeLevelDelegate(address owner, uint8 lv) external KDelegateMethod {
        require( _levelMapping[owner] < lv, "LevelLess" );
        _levelMapping[owner] = lv;
        for (
            (uint i, address parent) = (0, owner);
            i < 32 && parent != address(0x0) && parent != rootAddress;
            (parent = _recommerMapping[parent], i++)
        ) {
            if ( _chilrenLevelMaxMapping[parent] < lv ) {
                _chilrenLevelMaxMapping[parent] = uint8(lv);
            }
        }
    }
}
pragma solidity >=0.5.1 <0.7.0;
contract PoolStorage is KStorage {
    enum AssertPoolName {
        LuckyDog,
        Explore,
        Reboot,
        SuperNode
    }
    uint[4] public availTotalAmouns = [
        0,
        0,
        0,
        0
    ];
    address[4] public operators = [
        address(0x0),
        address(0x0),
        address(0x0),
        address(0x0)
    ];
    iERC20 internal usdtInterface;
    constructor(iERC20 usdtInc) public {
        usdtInterface = usdtInc;
    }
}
contract Pool is PoolStorage(iERC20(0)) {
    function poolNameFromOperator(address operator) public view returns (AssertPoolName) {
        for (uint i = 0; i < operators.length; i++) {
            if ( operators[i] == operator ) {
                return AssertPoolName(i);
            }
        }
        require(false, "SenderIsNotOperator");
    }
    function allowance(address operator) external view returns (uint) {
        for (uint i = 0; i < operators.length; i++) {
            if ( operators[i] == operator ) {
                return availTotalAmouns[i];
            }
        }
        return 0;
    }
    function operatorSend(address to, uint amount) external {
        AssertPoolName pname = poolNameFromOperator(msg.sender);
        require( availTotalAmouns[uint(pname)] >= amount );
        availTotalAmouns[uint(pname)] -= amount;
        usdtInterface.transfer(to, amount);
    }
    function recipientQuotaDelegate(AssertPoolName name, uint amountQuota) external KDelegateMethod {
        availTotalAmouns[uint8(name)] += amountQuota;
    }
    function setOperator(address operator, AssertPoolName poolName) external KOwnerOnly {
        operators[uint(poolName)] = operator;
    }
}
contract NoderStorage is KStorage {
    uint public latestBonusTime;
    address[] public noderAddresses;
    mapping(address => uint) public totalReward;
    Pool internal _poolInterface;
    event Log_Bounds(uint indexed time, uint amount);
    constructor(Pool poolInc) public {
        _poolInterface = poolInc;
        latestBonusTime = now;
    }
}
contract Noder is NoderStorage {
    constructor() public NoderStorage(Pool(0)) {
    }
    function isNoder(address owner) external view returns (bool) {
        for (uint i = 0; i < noderAddresses.length; i++) {
            if ( noderAddresses[i] == owner) {
                return true;
            }
        }
        return false;
    }
    function doBounds() external KOwnerOnly {
        uint totalRward = _poolInterface.allowance(address(this));
        uint everRward = totalRward / noderAddresses.length;
        for ( uint i = 0; i < noderAddresses.length; i++ ) {
             _poolInterface.operatorSend( noderAddresses[i], everRward );
             totalReward[noderAddresses[i]] += everRward;
        }
        latestBonusTime = now;
        emit Log_Bounds(now / 1 days * 1 days, everRward);
    }
    function paymentedSuperNodeDelegate(address owner) external KDelegateMethod {
        for (uint i = 0; i < noderAddresses.length; i++) {
            require(noderAddresses[i] != owner);
        }
        noderAddresses.push(owner);
    }
}
interface OrderManager {
    function conditionLevelOneFinished(address owner) external view returns (bool);
}
contract ManagerStorage is KStorage {
    struct DLevelItemPrice {
        uint levelNum;
        uint price;
        uint sentToken;
        uint [] sharedLevels;
    }
    struct StockInfo {
        uint sold;
        uint total;
    }
    uint public dlvDepthMaxLimit = 512;
    uint[] public dlevelAwarProp = [
        0.00e12,
        0.01e12,
        0.005e12,
        0.005e12,
        0.005e12,
        0.005e12
    ];
    mapping(uint => StockInfo) public stockInfoMapping;
    mapping(uint => DLevelItemPrice) public goodsMapping;
    mapping(address => DLevelItemPrice) public purchasedMapping;
    Relations internal _rlsInterface;
    OrderManager internal _mrgInterface;
    iERC20 internal _usdtInterface;
    iERC777_1 internal _mctInterface;
    Noder internal _nodeInterface;
    constructor(
        Relations rltInc,
        iERC20 usdtInc,
        iERC777_1 erc777,
        Noder nodeInc
    ) public {
        _rlsInterface = rltInc;
        _usdtInterface = usdtInc;
        _mctInterface = erc777;
        _nodeInterface = nodeInc;
        goodsMapping[1] = DLevelItemPrice(1,  500e6,  5000e6, new uint[](0));
        goodsMapping[2] = DLevelItemPrice(2, 1000e6, 10000e6, new uint[](0));
        goodsMapping[3] = DLevelItemPrice(3, 2000e6, 20000e6, new uint[](0));
        goodsMapping[6] = DLevelItemPrice(6, 5000e6, 50000e6, new uint[](0));
        goodsMapping[1].sharedLevels = [0,  0, 0, 0, 0];
        goodsMapping[2].sharedLevels = [0,  2, 0, 0, 0];
        goodsMapping[3].sharedLevels = [0,  4, 2, 0, 0];
        goodsMapping[6].sharedLevels = [0, 10, 5, 0, 0];
        stockInfoMapping[1] = StockInfo(0, 50);
        stockInfoMapping[2] = StockInfo(0, 50);
        stockInfoMapping[3] = StockInfo(0, 50);
        stockInfoMapping[6] = StockInfo(0, 33);
    }
}
contract Manager is ManagerStorage {
    constructor() public ManagerStorage(
        Relations(0),
        iERC20(0),
        iERC777_1(0),
        Noder(0)
    ) {}
    function stockInfoList() external view returns (uint[] memory stock) {
        stock = new uint[](4);
        stock[0] = stockInfoMapping[1].sold;
        stock[1] = stockInfoMapping[2].sold;
        stock[2] = stockInfoMapping[3].sold;
        stock[3] = stockInfoMapping[6].sold;
    }
    function setOrderManagerInc(address inc) external KOwnerOnly {
        _mrgInterface = OrderManager(inc);
    }
    function upgradeDLevel() external returns (uint origin, uint current) {
        origin = _rlsInterface.levelOf(msg.sender);
        current = origin;
        if ( origin == dlevelAwarProp.length - 1 ) {
            return (origin, current);
        }
        uint[] memory childrenDLVSCount = _rlsInterface.levelDistribution(msg.sender, dlevelAwarProp.length - 1);
        if ( current == 0 ) {
            if ( _mrgInterface.conditionLevelOneFinished(msg.sender) ) {
                current = 1;
            }
        }
        if ( current == 1 ) {
            uint effCount = 0;
            for (uint i = current; i < dlevelAwarProp.length; i++ ) {
                effCount += childrenDLVSCount[i];
            }
            if ( effCount >= 2 ) {
                current = 2;
            }
        }
        if ( current == 2 ) {
            uint effCount = 0;
            for (uint i = current; i < dlevelAwarProp.length; i++ ) {
                effCount += childrenDLVSCount[i];
            }
            if ( effCount >= 2 ) {
                current = 3;
            }
        }
        if ( current == 3 ) {
            uint effCount = 0;
            for (uint i = current; i < dlevelAwarProp.length; i++ ) {
                effCount += childrenDLVSCount[i];
            }
            if ( effCount >= 3 ) {
                current = 4;
            }
        }
        if ( current == 4 ) {
            uint effCount = 0;
            for (uint i = current; i < dlevelAwarProp.length; i++ ) {
                effCount += childrenDLVSCount[i];
            }
            if ( effCount >= 3 ) {
                current = 5;
            }
        }
        if ( current > origin ) {
            _rlsInterface.upgradeLevelDelegate(msg.sender, uint8(current));
        }
        return (origin, current);
    }
    function paymentDLevel(uint targetLevel) external {
        require( _rlsInterface.getIntroducer(msg.sender) != address(0x0), "NoIntroducer" );
        require( targetLevel > 0 && targetLevel <= dlevelAwarProp.length, "TargetLevelRangeError");
        require( stockInfoMapping[targetLevel].sold + 1 <= stockInfoMapping[targetLevel].total, "NoStock");
        require( _rlsInterface.levelOf(msg.sender) < targetLevel, "CurrentLvGreatThanTarget" );
        uint goodsPrice = goodsMapping[targetLevel].price;
        purchasedMapping[msg.sender] = goodsMapping[targetLevel];
        _rlsInterface.upgradeLevelDelegate(msg.sender, uint8(targetLevel));
        require(
            _usdtInterface.transferFrom(msg.sender, address(0x41351eb60e80a7c87f34a0e710ebeedf3d4ea117e9), goodsPrice),
            "USD TransferFailed"
        );
        _mctInterface.operatorSend(
            address(_mctInterface),
            msg.sender,
            goodsMapping[targetLevel].sentToken,
            "",
            ""
        );
        stockInfoMapping[targetLevel].sold += 1;
    }
    function paymentSuperNode() external {
        require( _rlsInterface.getIntroducer(msg.sender) != address(0x0), "NoIntroducer" );
        require( purchasedMapping[msg.sender].levelNum != 6, "NoPaymentAgain" );
        require( stockInfoMapping[6].sold + 1 <= stockInfoMapping[6].total, "NoStock");
        uint goodsPrice = goodsMapping[6].price;
        require(
            _usdtInterface.transferFrom(msg.sender, address(0x41351eb60e80a7c87f34a0e710ebeedf3d4ea117e9), goodsPrice),
            "USD TransferFailed"
        );
        purchasedMapping[msg.sender] = goodsMapping[6];
        stockInfoMapping[6].sold += 1;
        if ( _rlsInterface.levelOf(msg.sender) < 3 ) {
            _rlsInterface.upgradeLevelDelegate(msg.sender, 3);
        }
        _mctInterface.operatorSend(
            address(_mctInterface),
            msg.sender,
            goodsMapping[6].sentToken,
            "",
            ""
        );
        _nodeInterface.paymentedSuperNodeDelegate(msg.sender);
    }
    function giftList(address owner) external view returns (uint[] memory) {
        return purchasedMapping[owner].sharedLevels;
    }
    function useGiftDLevel(uint giftLevel, address to) external {
        require( purchasedMapping[msg.sender].sharedLevels[giftLevel] > 0, "EnoughGifts" );
        require( _rlsInterface.levelOf(to) < giftLevel, "GreaterThanGift" );
        purchasedMapping[msg.sender].sharedLevels[giftLevel] -= 1;
        _rlsInterface.upgradeLevelDelegate(to, uint8(giftLevel));
    }
    function setGoodsMappingPrice(
        uint lv,
        uint price,
        uint sentToken,
        uint stockTotal,
        uint[] calldata giftCounts
    ) external KOwnerOnly {
        goodsMapping[lv].price = price;
        goodsMapping[lv].sentToken = sentToken;
        goodsMapping[lv].sharedLevels = giftCounts;
        stockInfoMapping[lv].total = stockTotal;
    }
    function setDLevelAwardProp(uint dl, uint p) external KOwnerOnly {
        require( dl >= 1 && dl < dlevelAwarProp.length );
        dlevelAwarProp[dl] = p;
    }
    function setDLevelSearchDepth(uint depth) external KOwnerOnly {
        dlvDepthMaxLimit = depth;
    }
    function calculationAwards(address owner, uint value) external view returns (
        address[] memory addresses,
        uint[] memory awards
    ) {
        uint len = dlevelAwarProp.length;
        addresses = new address[](len);
        awards = new uint[](len);
        uint[] memory awarProps = dlevelAwarProp;
        (
            uint[] memory seq,
            address[] memory fathers
        ) = _rlsInterface.getForefathers2(
            owner,
            dlvDepthMaxLimit,
            dlevelAwarProp.length - 1
        );
        for ( uint i = 0; i < seq.length; i++ ) {
            uint dlv = seq[i];
            uint psum = 0;
            for ( uint x = dlv; x > 0; x-- ) {
                psum += awarProps[x];
                awarProps[x] = 0;
            }
            if ( psum > 0 ) {
                addresses[dlv] = fathers[dlv];
                awards[dlv] = value * psum / 1e12;
            }
            if ( dlv >= dlevelAwarProp.length - 1 ) {
                break;
            }
        }
    }
}
contract _ERC20AssetPool {
    constructor(iERC20 erc20) public {
        erc20.approve(msg.sender, 201803262018032620180326e6);
    }
}
interface OrderManagerStruct {
    enum OrderStates {
        Unknown,
        Created,
        PaymentPart,
        PaymentCountDown,
        TearUp,
        Frozen,
        Profiting,
        Done,
        Settlemented
    }
    enum TimeType {
        OnCreated,
        OnPaymentFrist,
        OnPaymentSuccess,
        OnProfitingBegin,
        OnCountDownStart,
        OnCountDownEnd,
        OnConvertConsumer,
        OnUnfreezing,
        OnDone
    }
    enum AwardType {
        Recommend,
        Manager,
        Admin,
        Withdrawable
    }
    struct Order {
        address owner;
        uint index;
        uint total;
        uint paymented;
        uint profix;
        OrderStates state;
        bool consumed;
        uint getHelped;
        mapping (uint8 => uint) times;
    }
    struct UserInfo {
        uint totalIn;
        uint totalOut;
        uint awardQuota;
        uint awardWithdrawableTotal;
        bytes[] awardHistory;
    }
}
contract OrderManagerStorage is OrderManagerStruct, KStorage {
    Order[] public orders;
    mapping( address => UserInfo) public userInfoMapping;
    uint public depositedUSDMaxLimit = 100000e6;
    uint public exchangeRateUSDToMC = 20;
    uint public costProp = 0.02e12;
    uint public depositTimeInterval = 3 days;
    uint public queueTime = 2 days;
    mapping( uint => uint ) public depositedLimitMapping;
    mapping( address => uint[] ) public orderIndexMapping;
    iERC20 internal _usdtInterface;
    iERC777_1 internal _mctInterface;
    Relations internal _relationInterface;
    Manager internal _managerInterface;
    Pool internal _astPoolInterface;
    Compensate internal _compensateInterface;
    _ERC20AssetPool[] internal _hiddenUSDTPools;
    mapping(address => uint) public validCountOf;
    mapping(address => bool) public isValid;
    struct Invest {address owner; uint amount;}
    struct LuckyDog {uint award; uint time; bool canwithdraw;}
    event Log_Luckdog(address indexed who, uint indexed awardsTotal, uint seqNo);
    bool public isInCountdowning = false;
    uint public deadlineTime;
    bool public death = false;
    uint public withdrawableTotal;
    Invest[] public investQueue;
    mapping(address => LuckyDog) internal _luckydogMapping;
    uint[] internal _waitingPaymentOrders;
    uint internal _waitingPaymentOrdersSeek;
    constructor(
        iERC20 _usdtInc,
        iERC777_1 _mctInc,
        Relations _relationInc,
        Pool _poolInc,
        Compensate _compInc
    ) public {
        _usdtInterface = _usdtInc;
        _mctInterface = _mctInc;
        _relationInterface = _relationInc;
        _astPoolInterface = _poolInc;
        _compensateInterface = _compInc;
    }
}