pragma solidity >=0.6.0;

import "../interfaces/UnderlyingFeed.sol";
import "./ManagedContract.sol";
import "./Proxy.sol";

contract Deployer {

    struct ContractData {
        string key;
        address origAddr;
        address proxyAddr;
    }

    mapping(string => address) private contractMap;
    mapping(string => string) private aliases;

    address private owner;
    address private original;
    ContractData[] private contracts;
    bool private deployed;

    constructor(address _owner, address _original) public {

        owner = _owner;
        original = _original;
    }

    function getOwner() public view returns (address) {

        return owner;
    }

    function hasKey(string memory key) public view returns (bool) {
        
        return contractMap[key] != address(0) || contractMap[aliases[key]] != address(0);
    }

    function addAlias(string memory fromKey, string memory toKey) public {
        
        ensureNotDeployed();
        ensureCaller();
        require(contractMap[toKey] != address(0), buildAddressNotSetMessage(toKey));
        aliases[fromKey] = toKey;
    }

    function getContractAddress(string memory key) public view returns (address) {

        if (original != address(0)) {
            if (Deployer(original).hasKey(key)) {
                return Deployer(original).getContractAddress(key);
            }
        }
        
        require(hasKey(key), buildAddressNotSetMessage(key));
        address addr = contractMap[key];
        if (addr == address(0)) {
            addr = contractMap[aliases[key]];
        }
        return addr;
    }

    function getPayableContractAddress(string memory key) public view returns (address payable) {

        return address(uint160(address(getContractAddress(key))));
    }

    function setContractAddress(string memory key) public {

        setContractAddress(key, msg.sender);
    }

    function setContractAddress(string memory key, address addr) public {

        ensureNotDeployed();
        ensureCaller();
        
        if (addr == address(0)) {
            contractMap[key] = address(0);
        } else {
            Proxy p = new Proxy(tx.origin, addr);
            contractMap[key] = address(p);
            contracts.push(ContractData(key, addr, address(p)));
        }
    }

    function isDeployed() public view returns(bool) {
        
        return deployed;
    }

    function deploy() public {

        ensureNotDeployed();
        ensureCaller();
        deployed = true;

        for (uint i = 0; i < contracts.length; i++) {
            if (contractMap[contracts[i].key] != address(0)) {
                ManagedContract(contracts[i].proxyAddr).initializeAndLock(this);
            }
        }
    }

    function reset() public {

        ensureCaller();
        deployed = false;

        for (uint i = 0; i < contracts.length; i++) {
            if (contractMap[contracts[i].key] != address(0)) {
                Proxy p = new Proxy(tx.origin, contracts[i].origAddr);
                contractMap[contracts[i].key] = address(p);
                contracts[i].proxyAddr = address(p);
            }
        }
    }

    function ensureNotDeployed() private view {

        require(!deployed, "already deployed");
    }

    function ensureCaller() private view {

        require(owner == address(0) || tx.origin == owner, "unallowed caller");
    }

    function buildAddressNotSetMessage(string memory key) private pure returns(string memory) {

        return string(abi.encodePacked("contract address not set: ", key));
    }
}

pragma solidity ^0.6.0;

import "./Deployer.sol";

contract ManagedContract {

    // ATTENTION: storage variable alignment
    address private owner;
    address private pendingOwner;
    address private implementation;
    bool private locked;
    // -------------------------------------

    function initializeAndLock(Deployer deployer) public {

        require(!locked, "locked");
        initialize(deployer);
        locked = true;
    }

    function initialize(Deployer deployer) virtual internal {

    }
}

pragma solidity ^0.6.0;

contract Proxy {

    // ATTENTION: storage variable alignment
    address private owner;
    address private pendingOwner;
    address private implementation;
    bool private locked;
    // -------------------------------------

    event OwnershipTransferRequested(address indexed from, address indexed to);
    
    event OwnershipTransferred(address indexed from, address indexed to);

    event ImplementationUpdated(address indexed from, address indexed to);

    constructor(address _owner, address _implementation) public {

        owner = _owner;
        implementation = _implementation;
    }

    fallback () payable external {
        
        _fallback();
    }

    receive () payable external {

        _fallback();
    }
    
    function transferOwnership(address _to) external {
        
        require(msg.sender == owner);
        pendingOwner = _to;
        emit OwnershipTransferRequested(owner, _to);
    }

    function acceptOwnership() external {
    
        require(msg.sender == pendingOwner);
        address oldOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    function setImplementation(address _implementation) public {

        require(msg.sender == owner);
        address oldImplementation = implementation;
        implementation = _implementation;
        emit ImplementationUpdated(oldImplementation, implementation);
    }

    function delegate(address _implementation) internal {
        assembly {

            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result

            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _fallback() internal {
        willFallback();
        delegate(implementation);
    }

    function willFallback() internal virtual {
        
    }
}

pragma solidity >=0.6.0;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../governance/ProtocolSettings.sol";
import "../utils/ERC20.sol";
import "../interfaces/TimeProvider.sol";
import "../utils/MoreMath.sol";
import "../utils/SafeMath.sol";
import "../utils/SignedSafeMath.sol";
import "./CreditToken.sol";

contract CreditProvider is ManagedContract {

    using SafeMath for uint;
    using SignedSafeMath for int;
    
    TimeProvider private time;
    ProtocolSettings private settings;
    CreditToken private creditToken;

    mapping(address => uint) private balances;
    mapping(address => uint) private debts;
    mapping(address => uint) private debtsDate;
    mapping(address => uint) private callers;

    address private ctAddr;
    uint private _totalTokenStock;
    uint private _totalAccruedFees;

    event TransferBalance(address indexed from, address indexed to, uint value);

    event AccumulateDebt(address indexed to, uint value);

    event BurnDebt(address indexed from, uint value);

    constructor(address deployer) public {

        Deployer(deployer).setContractAddress("CreditProvider");
        Deployer(deployer).addAlias("CreditIssuer", "CreditProvider");
    }

    function initialize(Deployer deployer) override internal {

        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        creditToken = CreditToken(deployer.getContractAddress("CreditToken"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));

        callers[address(settings)] = 1;
        callers[deployer.getContractAddress("CreditToken")] = 1;
        callers[deployer.getContractAddress("OptionsExchange")] = 1;

        ctAddr = address(creditToken);
    }

    function totalTokenStock() external view returns (uint) {

        return _totalTokenStock;
    }

    function totalAccruedFees() external view returns (uint) {

        return _totalAccruedFees;
    }

    function issueCredit(address to, uint value) external {
        
        ensureCaller();

        require(msg.sender == address(settings));
        issueCreditTokens(to, value);
    }

    function balanceOf(address owner) public view returns (uint) {

        return balances[owner];
    }
    
    function addBalance(address to, address token, uint value) external {

        addBalance(to, token, value, false);
    }

    function transferBalance(address from, address to, uint value) public {

        ensureCaller();
        removeBalance(from, value);
        addBalance(to, value);
        emit TransferBalance(from, to, value);
    }
    
    function depositTokens(address to, address token, uint value) external {

        ERC20(token).transferFrom(msg.sender, address(this), value);
        addBalance(to, token, value, true);
    }

    function withdrawTokens(address owner, uint value) external {
        
        ensureCaller();
        removeBalance(owner, value);
        burnDebtAndTransferTokens(owner, value);
    }

    function grantTokens(address to, uint value) external {
        
        ensureCaller();
        burnDebtAndTransferTokens(to, value);
    }

    function calcDebt(address addr) public view returns (uint debt) {

        debt = debts[addr];
        if (debt > 0) {
            debt = settings.applyDebtInterestRate(debt, debtsDate[addr]);
        }
    }

    function processPayment(address from, address to, uint value) external {
        
        ensureCaller();

        require(from != to);

        if (value > 0) {

            (uint v, uint b) = settings.getProcessingFee();
            if (v > 0) {
                uint fee = MoreMath.min(value.mul(v).div(b), balanceOf(from));
                value = value.sub(fee);
                _totalAccruedFees = _totalAccruedFees.add(fee);
            }

            uint credit;
            if (balanceOf(from) < value) {
                credit = value.sub(balanceOf(from));
                value = balanceOf(from);
            }

            transferBalance(from, to, value);

            if (credit > 0) {                
                applyDebtInterestRate(from);
                setDebt(from, debts[from].add(credit));
                addBalance(to, credit);
                emit AccumulateDebt(to, value);
            }
        }
    }
    
    function addBalance(address to, address token, uint value, bool trusted) private {

        if (value > 0) {

            if (!trusted) {
                ensureCaller();
            }
            
            (uint r, uint b) = settings.getTokenRate(token);
            require(r != 0 && token != ctAddr, "token not allowed");
            value = value.mul(b).div(r);
            addBalance(to, value);
            emit TransferBalance(address(0), to, value);
            _totalTokenStock = _totalTokenStock.add(value);
        }
    }
    
    function addBalance(address owner, uint value) public {

        if (value > 0) {

            uint burnt = burnDebt(owner, value);
            uint v = value.sub(burnt);
            balances[owner] = balances[owner].add(v);
        }
    }
    
    function removeBalance(address owner, uint value) private {
        
        require(balances[owner] >= value, "insufficient balance");
        balances[owner] = balances[owner].sub(value);
    }

    function burnDebtAndTransferTokens(address to, uint value) private {

        if (debts[to] > 0) {
            uint burnt = burnDebt(to, value);
            value = value.sub(burnt);
        }

        transferTokens(to, value);
    }

    function burnDebt(address from, uint value) private returns (uint burnt) {
        
        uint d = applyDebtInterestRate(from);
        if (d > 0) {
            burnt = MoreMath.min(value, d);
            setDebt(from, d.sub(burnt));
            emit BurnDebt(from, value);
        }
    }

    function applyDebtInterestRate(address owner) private returns (uint debt) {

        uint d = debts[owner];
        if (d > 0) {

            debt = calcDebt(owner);

            if (debt > 0 && debt != d) {
                setDebt(owner, debt);
            }
        }
    }

    function setDebt(address owner, uint value)  private {
        
        debts[owner] = value;
        debtsDate[owner] = time.getNow();
    }

    function transferTokens(address to, uint value) private returns (uint) {
        
        require(to != address(this) && to != ctAddr, "invalid token transfer address");

        address[] memory tokens = settings.getAllowedTokens();
        for (uint i = 0; i < tokens.length && value > 0; i++) {
            ERC20 t = ERC20(tokens[i]);
            (uint r, uint b) = settings.getTokenRate(tokens[i]);
            if (b != 0) {
                uint v = MoreMath.min(value, t.balanceOf(address(this)).mul(b).div(r));
                t.transfer(to, v.mul(r).div(b));
                _totalTokenStock = _totalTokenStock.sub(v);
                value = value.sub(v);
            }
        }
        
        if (value > 0) {
            issueCreditTokens(to, value);
        }
    }

    function issueCreditTokens(address to, uint value) private {
        
        (uint r, uint b) = settings.getTokenRate(ctAddr);
        if (b != 0) {
            value = value.mul(r).div(b);
        }
        creditToken.issue(to, value);
    }

    function ensureCaller()  private view {
        
        require(callers[msg.sender] == 1, "unauthorized caller");
    }
}

pragma solidity >=0.6.0;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../governance/ProtocolSettings.sol";
import "../utils/ERC20.sol";
import "../interfaces/TimeProvider.sol";
import "../utils/SafeMath.sol";
import "../utils/MoreMath.sol";
import "./CreditProvider.sol";

contract CreditToken is ManagedContract, ERC20 {

    using SafeMath for uint;

    struct WithdrawQueueItem {
        address addr;
        uint value;
        address nextAddr;
    }

    TimeProvider private time;
    ProtocolSettings private settings;
    CreditProvider private creditProvider;

    mapping(address => uint) private creditDates;
    mapping(address => WithdrawQueueItem) private queue;

    string private constant _name = "Credit Token";
    string private constant _symbol = "CREDTK";

    address private issuer;
    address private headAddr;
    address private tailAddr;

    constructor(address deployer) ERC20(_name) public {

        Deployer(deployer).setContractAddress("CreditToken");
    }

    function initialize(Deployer deployer) override internal {
        
        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        creditProvider = CreditProvider(deployer.getContractAddress("CreditProvider"));
        issuer = deployer.getContractAddress("CreditIssuer");
    }

    function name() override external view returns (string memory) {
        return _name;
    }

    function symbol() override external view returns (string memory) {
        return _symbol;
    }

    function setIssuer(address _issuer) public {

        require(issuer == address(0), "issuer already set");
        issuer = _issuer;
    }

    function issue(address to, uint value) public {

        require(msg.sender == issuer, "issuance unallowed");
        addBalance(to, value);
        _totalSupply = _totalSupply.add(value);
        emitTransfer(address(0), to, value);
    }

    function balanceOf(address owner) override public view returns (uint bal) {

        bal = 0;
        if (balances[owner] > 0) {
            bal = settings.applyCreditInterestRate(balances[owner], creditDates[owner]);
        }
    }

    function requestWithdraw(uint value) public {

        uint sent;
        if (headAddr == address(0)) {
            (sent,) = withdrawTokens(msg.sender, value);
        }
        if (sent < value) {
            enqueueWithdraw(msg.sender, value.sub(sent));
        }
    }

    function processWithdraws() public {
        
        while (headAddr != address(0)) {
            (uint sent, bool dequeue) = withdrawTokens(
                queue[headAddr].addr,
                queue[headAddr].value
            );
            if (dequeue) {
                dequeueWithdraw();
            } else {
                queue[headAddr].value = queue[headAddr].value.sub(sent);
                break;
            }
        }
    }

    function addBalance(address owner, uint value) override internal {

        updateBalance(owner);
        balances[owner] = balances[owner].add(value);
    }

    function removeBalance(address owner, uint value) override internal {

        updateBalance(owner);
        balances[owner] = balances[owner].sub(value);
    }

    function updateBalance(address owner) private {

        uint nb = balanceOf(owner);
        _totalSupply = _totalSupply.add(nb).sub(balances[owner]);
        balances[owner] = nb;
        creditDates[owner] = time.getNow();
    }

    function enqueueWithdraw(address owner, uint value) private {

        if (queue[owner].addr == owner) {
            
            require(queue[owner].value > value, "invalid value");
            queue[owner].value = value;

        } else {

            queue[owner] = WithdrawQueueItem(owner, value, address(0));
            if (headAddr == address(0)) {
                headAddr = owner;
            } else {
                queue[tailAddr].nextAddr = owner;
            }
            tailAddr = owner;

        }
    }

    function dequeueWithdraw() private {

        address aux = headAddr;
        headAddr = queue[headAddr].nextAddr;
        if (headAddr == address(0)) {
            tailAddr = address(0);
        }
        delete queue[aux];
    }

    function withdrawTokens(address owner, uint value) private returns(uint sent, bool dequeue) {

        if (value > 0) {

            value = MoreMath.min(balanceOf(owner), value);
            uint b = creditProvider.totalTokenStock();

            if (b >= value) {
                sent = value;
                dequeue = true;
            } else {
                sent = b;
            }

            if (sent > 0) {
                removeBalance(owner, sent);
                creditProvider.grantTokens(owner, sent);
            }
        }
    }
}

pragma solidity >=0.6.0;

import "../../contracts/finance/OptionsExchange.sol";
import "../../contracts/finance/RedeemableToken.sol";
import "../utils/ERC20.sol";
import "../utils/Arrays.sol";
import "../utils/SafeMath.sol";

contract OptionToken is RedeemableToken {

    using SafeMath for uint;

    string private constant _prefix = "Option Redeemable Token: ";
    string private _symbol;

    constructor(string memory _sb, address _issuer)
        ERC20(string(abi.encodePacked(_prefix, _symbol)))
        public
    {    
        _symbol = _sb;
        exchange = OptionsExchange(_issuer);
    }

    function name() override external view returns (string memory) {
        return string(abi.encodePacked(_prefix, _symbol));
    }

    function symbol() override external view returns (string memory) {

        return _symbol;
    }

    function issue(address to, uint value) external {

        require(msg.sender == address(exchange), "issuance unallowed");
        addBalance(to, value);
        _totalSupply = _totalSupply.add(value);
        emit Transfer(address(0), to, value);
    }

    function burn(uint value) external {

        require(balanceOf(msg.sender) >= value, "burn unallowed");
        removeBalance(msg.sender, value);
        _totalSupply = _totalSupply.sub(value);
        exchange.burnOptions(_symbol, msg.sender, value);
    }

    function writtenVolume(address owner) external view returns (uint) {

        return exchange.writtenVolume(_symbol, owner);
    }

    function redeemAllowed() override public returns (bool) {
        
        exchange.liquidateSymbol(_symbol, uint(-1));
        return true;
    }

    function addBalance(address owner, uint value) override internal {

        if (balanceOf(owner) == 0) {
            holders.push(owner);
        }
        balances[owner] = balanceOf(owner).add(value);
    }

    function emitTransfer(address from, address to, uint value) override internal {

        exchange.transferOwnership(_symbol, from, to, value);
        emit Transfer(from, to, value);
    }
}

pragma solidity >=0.6.0;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "./OptionToken.sol";

contract OptionTokenFactory is ManagedContract {

    constructor(address deployer) public {

        Deployer(deployer).setContractAddress("OptionTokenFactory");
    }

    function initialize(Deployer deployer) override internal {

    }

    function create(string calldata symbol) external returns (address) {

        return address(new OptionToken(symbol, msg.sender));
    }

    function create(string calldata symbol, address udlFeed) external returns (address) {

        bytes memory sb1 = bytes(UnderlyingFeed(udlFeed).symbol());
        bytes memory sb2 = bytes(symbol);
        for (uint i = 0; i < sb1.length; i++) {
            if (sb1[i] != sb2[i]) {
                revert("invalid feed");
            }
        }
        return address(new OptionToken(symbol, msg.sender));
    }
}

pragma solidity >=0.6.0;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../governance/ProtocolSettings.sol";
import "../utils/ERC20.sol";
import "../interfaces/TimeProvider.sol";
import "../interfaces/UnderlyingFeed.sol";
import "../utils/Arrays.sol";
import "../utils/MoreMath.sol";
import "../utils/SafeCast.sol";
import "../utils/SafeMath.sol";
import "../utils/SignedSafeMath.sol";
import "./CreditProvider.sol";
import "./OptionToken.sol";
import "./OptionTokenFactory.sol";

contract OptionsExchange is ManagedContract {

    using SafeCast for uint;
    using SafeMath for uint;
    using SignedSafeMath for int;
    
    enum OptionType { CALL, PUT }
    
    struct OptionData {
        uint48 id;
        address udlFeed;
        OptionType _type;
        uint120 strike;
        uint32 maturity;
    }

    struct FeedData {
        uint120 lowerVol;
        uint120 upperVol;
    }
    
    struct OrderData {
        uint48 id;
        uint48 optId;
        address owner;
        uint120 written;
        uint120 holding;
    }
    
    TimeProvider private time;
    ProtocolSettings private settings;
    CreditProvider private creditProvider;
    OptionTokenFactory private factory;

    mapping(uint => OptionData) private options;
    mapping(address => FeedData) private feeds;
    mapping(uint => OrderData) private orders;
    mapping(address => uint48[]) private book;
    mapping(string => uint48) private optIndex;
    mapping(address => mapping(string => uint48)) private ordIndex;
    mapping(address => uint256) public collateral;

    mapping(string => address) private tokenAddress;
    mapping(string => uint48[]) private tokenIds;

    mapping(address => uint) public nonces;
    
    uint48 private serial;
    uint private volumeBase;
    uint private timeBase;
    uint private sqrtTimeBase;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    event CreateSymbol(address indexed token, address indexed issuer);

    event WriteOptions(address indexed token, address indexed issuer, uint volume, uint id);

    event LiquidateEarly(address indexed token, address indexed sender, uint volume);

    event LiquidateExpired(address indexed token, address indexed sender, uint volume);

    constructor(address deployer) public {

        string memory _name = "OptionsExchange";
        Deployer(deployer).setContractAddress(_name);

        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function initialize(Deployer deployer) override internal {

        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        creditProvider = CreditProvider(deployer.getContractAddress("CreditProvider"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        factory = OptionTokenFactory(deployer.getContractAddress("OptionTokenFactory"));

        serial = 1;
        volumeBase = 1e18;
        timeBase = 1e18;
        sqrtTimeBase = 1e9;
    }

    function depositTokens(
        address to,
        address token,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        ERC20(token).permit(msg.sender, address(this), value, deadline, v, r, s);
        depositTokens(to, token, value);
    }

    function depositTokens(address to, address token, uint value) public {

        ERC20 t = ERC20(token);
        t.transferFrom(msg.sender, address(creditProvider), value);
        creditProvider.addBalance(to, token, value);
    }

    function balanceOf(address owner) external view returns (uint) {

        return creditProvider.balanceOf(owner);
    }

    function transferBalance(
        address from, 
        address to, 
        uint value,
        uint maxValue,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        require(maxValue >= value, "insufficient permit value");
        permit(from, to, maxValue, deadline, v, r, s);
        creditProvider.transferBalance(from, to, value);
        ensureFunds(from);
    }

    function transferBalance(address to, uint value) public {

        creditProvider.transferBalance(msg.sender, to, value);
        ensureFunds(msg.sender);
    }
    
    function withdrawTokens(uint value) external {
        
        require(value <= calcSurplus(msg.sender), "insufficient surplus");
        creditProvider.withdrawTokens(msg.sender, value);
    }

    function writeOptions(
        address udlFeed,
        uint volume,
        OptionType optType,
        uint strike, 
        uint maturity
    )
        external 
        returns (uint id, address tk)
    {
        (id, tk) = createOrder(udlFeed, volume, optType, strike, maturity, msg.sender);
        ensureFunds(msg.sender);
    }

    function writeOptions(
        address udlFeed,
        uint volume,
        OptionType optType,
        uint strike, 
        uint maturity,
        address to
    )
        external 
        returns (uint id, address tk)
    {
        (id, tk) = createOrder(udlFeed, volume, optType, strike, maturity, to);
        if (to != msg.sender) {
            transferOwnershipInternal(OptionToken(tk).symbol(), msg.sender, to, volume);
        } else {
            ensureFunds(msg.sender);
        }
    }

    function writtenVolume(string calldata symbol, address owner) external view returns (uint) {

        return uint(findOrder(owner, symbol).written);
    }

    function transferOwnership(
        string calldata symbol,
        address from,
        address to,
        uint volume
    )
        external
    {
        require(tokenAddress[symbol] == msg.sender, "unauthorized ownership transfer");
        transferOwnershipInternal(symbol, from, to, volume);
    }

    function burnOptions(
        string calldata symbol,
        address owner,
        uint volume
    )
        external
    {
        require(tokenAddress[symbol] == msg.sender, "unauthorized burn");
        
        OrderData memory ord = findOrder(owner, symbol);
        
        require(isValid(ord), "order not found");
        require(ord.written >= volume && ord.holding >= volume, "invalid volume");
        
        uint120 _written = uint(ord.written).sub(volume).toUint120();
        orders[ord.id].written = _written;
        uint120 _holding = uint(ord.holding).sub(volume).toUint120();
        orders[ord.id].holding = _holding;

        if (shouldRemove(_written, _holding)) {
            removeOrder(symbol, ord);
        }
    }

    function liquidateSymbol(string calldata symbol, uint limit) external {

        uint value;
        uint volume;
        int udlPrice;
        uint iv;
        uint len = tokenIds[symbol].length;
        OptionData memory opt;

        if (len > 0) {

            for (uint i = 0; i < len && i < limit; i++) {
                
                uint48 id = tokenIds[symbol][0];
                OrderData memory ord = orders[id];
                if (opt.udlFeed == address(0)) {
                    opt = options[ord.optId];
                }

                if (i == 0) {
                    udlPrice = getUdlPrice(opt);
                    uint _now = getUdlNow(opt);
                    iv = uint(calcIntrinsicValue(opt));
                    require(opt.maturity <= _now, "maturity not reached");
                }

                require(ord.id == id, "invalid order id");
                
                volume = volume.add(ord.written).add(ord.holding);

                if (ord.written > 0) {
                    value.add(
                        liquidateAfterMaturity(ord, symbol, msg.sender, iv.mul(ord.written))
                    );
                } else {
                    removeOrder(symbol, ord);
                }
            }
        }

        if (volume > 0) {
            emit LiquidateExpired(tokenAddress[symbol], msg.sender, volume);
        }

        if (len <= limit) {
            delete tokenIds[symbol];
            delete tokenAddress[symbol];
        }
    }

    function liquidateOptions(uint id) external returns (uint value) {
        
        OrderData memory ord = orders[id];
        require(ord.id == id && ord.written > 0, "invalid order id");
        OptionData memory opt = options[ord.optId];

        address token = resolveToken(id);
        string memory symbol = OptionToken(token).symbol();
        uint iv = uint(calcIntrinsicValue(opt)).mul(ord.written);
        
        if (getUdlNow(opt) >= opt.maturity) {
            value = liquidateAfterMaturity(ord, symbol, token, iv);
            emit LiquidateExpired(token, msg.sender, ord.written);
        } else {
            FeedData memory fd = feeds[opt.udlFeed];
            value = liquidateBeforeMaturity(ord, opt, fd, symbol, token, iv);
        }
    }

    function calcDebt(address owner) external view returns (uint debt) {

        debt = creditProvider.calcDebt(owner);
    }
    
    function calcSurplus(address owner) public view returns (uint) {
        
        uint coll = calcCollateral(owner);
        uint bal = creditProvider.balanceOf(owner);
        if (bal >= coll) {
            return bal.sub(coll);
        }
        return 0;
    }

    function setCollateral(address owner) external {

        collateral[owner] = calcCollateral(owner);
    }
    
    function calcCollateral(address owner) public view returns (uint) {
        
        int coll;
        uint48[] memory ids = book[owner];

        for (uint i = 0; i < ids.length; i++) {

            OrderData memory ord = orders[ids[i]];
            OptionData memory opt = options[ord.optId];

            if (isValid(ord)) {
                coll = coll.add(
                    calcIntrinsicValue(opt).mul(
                        int(ord.written).sub(int(ord.holding))
                    )
                ).add(int(calcCollateral(feeds[opt.udlFeed].upperVol, ord.written, opt)));
            }
        }

        coll = coll.div(int(volumeBase));

        if (coll < 0)
            return 0;
        return uint(coll);
    }

    function calcCollateral(
        address udlFeed,
        uint volume,
        OptionType optType,
        uint strike, 
        uint maturity
    )
        public
        view
        returns (uint)
    {
        (OptionData memory opt,,) = createOptionInMemory(udlFeed, optType, strike, maturity);
        return calcCollateral(opt, volume);
    }

    function calcExpectedPayout(address owner) external view returns (int payout) {

        uint48[] memory ids = book[owner];

        for (uint i = 0; i < ids.length; i++) {

            OrderData memory ord = orders[ids[i]];
            OptionData memory opt = options[ord.optId];

            if (isValid(ord)) {
                payout = payout.add(
                    calcIntrinsicValue(opt).mul(
                        int(ord.holding).sub(int(ord.written))
                    )
                );
            }
        }

        payout = payout.div(int(volumeBase));
    }

    function createSymbol(string memory symbol, address udlFeed) public returns (address tk) {

        tk = factory.create(symbol, udlFeed);
        tokenAddress[symbol] = tk;
        prefetchFeedData(udlFeed);
        emit CreateSymbol(tk, msg.sender);
    }

    function prefetchFeedData(address udlFeed) public {
        
        feeds[udlFeed] = getFeedData(udlFeed);
    }

    function resolveSymbol(uint id) external view returns (string memory) {
        
        OptionData memory opt = options[orders[id].optId];
        return getOptionSymbol(opt);
    }

    function resolveToken(uint id) public view returns (address) {
        
        OptionData memory opt = options[orders[id].optId];
        address addr = tokenAddress[getOptionSymbol(opt)];
        require(addr != address(0), "token not found");
        return addr;
    }

    function resolveToken(string memory symbol) public view returns (address) {
        
        address addr = tokenAddress[symbol];
        require(addr != address(0), "token not found");
        return addr;
    }

    function getBook(address owner)
        external view
        returns (
            string memory symbols,
            uint[] memory holding,
            uint[] memory written,
            int[] memory iv
        )
    {
        uint48[] memory ids = book[owner];
        holding = new uint[](ids.length);
        written = new uint[](ids.length);
        iv = new int[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            OrderData memory ord = orders[ids[i]];
            OptionData memory opt = options[ord.optId];
            if (i == 0) {
                symbols = getOptionSymbol(opt);
            } else {
                symbols = string(abi.encodePacked(symbols, "\n", getOptionSymbol(opt)));
            }
            holding[i] = ord.holding;
            written[i] = ord.written;
            iv[i] = calcIntrinsicValue(opt);
        }
    }

    function getBookLength() external view returns (uint len) {
        
        for (uint i = 0; i < serial; i++) {
            if (isValid(orders[i])) {
                len++;
            }
        }
    }

    function getVolumeBase() external view returns (uint) {
        
        return volumeBase;
    }
    
    function calcIntrinsicValue(uint id) external view returns (int) {
        
        return calcIntrinsicValue(options[orders[id].optId]);
    }

    function calcIntrinsicValue(
        address udlFeed,
        OptionType optType,
        uint strike, 
        uint maturity
    )
        external
        view
        returns (int)
    {
        (OptionData memory opt,,) = createOptionInMemory(udlFeed, optType, strike, maturity);
        return calcIntrinsicValue(opt);
    }

    function permit(
        address from,
        address to,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        private
    {
        require(deadline >= block.timestamp, "permit expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(PERMIT_TYPEHASH, from, to, value, nonces[from]++, deadline)
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == from, "invalid signature");
    }

    function createOrder(
        address udlFeed,
        uint volume,
        OptionType optType,
        uint strike, 
        uint maturity,
        address to
    )
        private 
        returns (uint id, address tk)
    {
        require(settings.getUdlFeed(udlFeed) > 0, "feed not allowed");
        require(volume > 0, "invalid volume");
        require(maturity > time.getNow(), "invalid maturity");

        uint48 _serial = serial;
        bool _updateSerial = false;

        (OptionData memory opt, string memory symbol, bool cached) =
            createOptionInMemory(udlFeed, optType, strike, maturity);
        if (!cached) {
            opt.id = _serial++;
            _updateSerial = true;
            options[opt.id] = opt;
            optIndex[symbol] = opt.id;
        }

        OrderData memory result = findOrder(msg.sender, symbol);

        if (isValid(result)) {
            id = result.id;
            orders[id].written = uint(result.written).add(volume).toUint120();
            orders[id].holding = uint(result.holding).add(volume).toUint120();
        } else {
            id = _serial++;
            _updateSerial = true;
            orders[id] = OrderData(
                uint48(id),
                opt.id,
                msg.sender,
                volume.toUint120(),
                volume.toUint120()
            );
            book[msg.sender].push(uint48(id));
            ordIndex[msg.sender][symbol] = uint48(id);
            tokenIds[symbol].push(uint48(id));
        }

        tk = tokenAddress[symbol];
        if (tk == address(0)) {
            tk = createSymbol(symbol, udlFeed);
        }
        OptionToken(tk).issue(to, volume);

        if (_updateSerial) {
            serial = _serial;
        }
        
        collateral[msg.sender] = collateral[msg.sender].add(
            calcCollateral(opt, volume)
        );

        emit WriteOptions(tk, msg.sender, volume, id);
    }

    function transferOwnershipInternal(
        string memory symbol,
        address from,
        address to,
        uint volume
    )
        private
    {
        OrderData memory ord = findOrder(from, symbol);

        require(isValid(ord), "order not found");
        require(volume <= ord.holding, "invalid volume");
                
        OrderData memory toOrd = findOrder(to, symbol);

        if (!isValid(toOrd)) {
            toOrd.id = serial++;
            toOrd.optId = ord.optId;
            toOrd.owner = address(to);
            toOrd.written = 0;
            toOrd.holding = volume.toUint120();
            orders[toOrd.id] = toOrd;
            book[to].push(toOrd.id);
            ordIndex[to][symbol] = toOrd.id;
            tokenIds[symbol].push(toOrd.id);
        } else {
            orders[toOrd.id].holding = uint(toOrd.holding).add(volume).toUint120();
        }
        
        uint120 _holding = uint(ord.holding).sub(volume).toUint120();
        orders[ord.id].holding = _holding;

        ensureFunds(ord.owner);

        if (shouldRemove(ord.written, _holding)) {
            removeOrder(symbol, ord);
        }
    }

    function createOptionInMemory(
        address udlFeed,
        OptionType optType,
        uint strike, 
        uint maturity
    )
        private
        view
        returns (OptionData memory opt, string memory symbol, bool cached)
    {
        OptionData memory aux =
            OptionData(0, udlFeed, optType, strike.toUint120(), maturity.toUint32());

        symbol = getOptionSymbol(aux);

        opt = options[optIndex[symbol]];
        if (opt.id == 0) {
            opt = aux;
        } else {
            cached = true;
        }
    }

    function getFeedData(address udlFeed) private view returns (FeedData memory fd) {
        
        UnderlyingFeed feed = UnderlyingFeed(udlFeed);

        uint vol = feed.getDailyVolatility(settings.getVolatilityPeriod());

        fd = FeedData(
            feed.calcLowerVolatility(uint(vol)).toUint120(),
            feed.calcUpperVolatility(uint(vol)).toUint120()
        );
    }

    function findOrder(
        address owner,
        string memory symbol
    )
        private
        view
        returns (OrderData memory)
    {
        uint48 id = ordIndex[owner][symbol];
        if (id > 0) {
            return orders[id];
        }
    }

    function liquidateAfterMaturity(
        OrderData memory ord,
        string memory symbol,
        address token,
        uint iv
    )
        private
        returns (uint value)
    {
        if (iv > 0) {
            value = iv.div(volumeBase);
            creditProvider.processPayment(ord.owner, token, value);
        }
    
        removeOrder(symbol, ord);
    }

    function liquidateBeforeMaturity(
        OrderData memory ord,
        OptionData memory opt,
        FeedData memory fd,
        string memory symbol,
        address token,
        uint iv
    )
        private
        returns (uint value)
    {
        uint volume = calcLiquidationVolume(ord, opt, fd);
        value = calcLiquidationValue(ord, opt, fd, iv, volume);
        
        uint120 _written = uint(ord.written).sub(volume).toUint120();
        orders[ord.id].written = _written;
        
        if (shouldRemove(_written, ord.holding)) {
            removeOrder(symbol, ord);
        }

        creditProvider.processPayment(ord.owner, token, value);
        emit LiquidateEarly(token, msg.sender, volume);
    }

    function calcLiquidationVolume(
        OrderData memory ord,
        OptionData memory opt,
        FeedData memory fd
    )
        private
        view
        returns (uint volume)
    {    
        uint bal = creditProvider.balanceOf(ord.owner);
        uint coll = calcCollateral(ord.owner);
        require(coll > bal, "unfit for liquidation");

        volume = coll.sub(bal).mul(volumeBase).mul(ord.written).div(
            calcCollateral(
                uint(fd.upperVol).sub(uint(fd.lowerVol)),
                ord.written,
                opt
            )
        );

        volume = MoreMath.min(volume, ord.written);
    }

    function calcLiquidationValue(
        OrderData memory ord,
        OptionData memory opt,
        FeedData memory fd,
        uint iv,
        uint volume
    )
        private
        view
        returns (uint value)
    {    
        value = calcCollateral(fd.lowerVol, ord.written, opt).add(iv)
            .mul(volume.toUint120()).div(ord.written).div(volumeBase);
    }

    function shouldRemove(uint120 w, uint120 h) private pure returns (bool) {

        return w == 0 && h == 0;
    }
    
    function removeOrder(string memory symbol, OrderData memory ord) private {
        
        Arrays.removeItem(tokenIds[symbol], ord.id);
        Arrays.removeItem(book[ord.owner], ord.id);
        delete ordIndex[ord.owner][symbol];
        delete orders[ord.id];
    }

    function getOptionSymbol(OptionData memory opt) private view returns (string memory symbol) {    

        symbol = string(abi.encodePacked(
            UnderlyingFeed(opt.udlFeed).symbol(),
            "-",
            "E",
            opt._type == OptionType.CALL ? "C" : "P",
            "-",
            MoreMath.toString(opt.strike),
            "-",
            MoreMath.toString(opt.maturity)
        ));
    }
    
    function ensureFunds(address owner) private view {
        
        require(
            creditProvider.balanceOf(owner) >= collateral[owner],
            "insufficient collateral"
        );
    }
    
    function isValid(OrderData memory ord) private pure returns (bool) {
        
        return ord.id > 0;
    }

    function calcCollateral(
        OptionData memory opt,
        uint volume
    )
        private
        view
        returns (uint)
    {
        FeedData memory fd = feeds[opt.udlFeed];
        if (fd.lowerVol == 0 || fd.upperVol == 0) {
            fd = getFeedData(opt.udlFeed);
        }

        int coll = calcIntrinsicValue(opt).mul(int(volume)).add(
            int(calcCollateral(fd.upperVol, volume, opt))
        ).div(int(volumeBase));

        return coll > 0 ? uint(coll) : 0;
    }
    
    function calcCollateral(uint vol, uint volume, OptionData memory opt) private view returns (uint) {
        
        return (vol.mul(volume).mul(
            MoreMath.sqrt(daysToMaturity(opt)))
        ).div(sqrtTimeBase);
    }
    
    function calcIntrinsicValue(OptionData memory opt) private view returns (int value) {
        
        int udlPrice = getUdlPrice(opt);
        int strike = int(opt.strike);

        if (opt._type == OptionType.CALL) {
            value = MoreMath.max(0, udlPrice.sub(strike));
        } else if (opt._type == OptionType.PUT) {
            value = MoreMath.max(0, strike.sub(udlPrice));
        }
    }
    
    function daysToMaturity(OptionData memory opt) private view returns (uint d) {
        
        uint _now = getUdlNow(opt);
        if (opt.maturity > _now) {
            d = (timeBase.mul(uint(opt.maturity).sub(uint(_now)))).div(1 days);
        } else {
            d = 0;
        }
    }

    function getUdlPrice(OptionData memory opt) private view returns (int answer) {

        if (opt.maturity > time.getNow()) {
            (,answer) = UnderlyingFeed(opt.udlFeed).getLatestPrice();
        } else {
            (,answer) = UnderlyingFeed(opt.udlFeed).getPrice(opt.maturity);
        }
    }

    function getUdlNow(OptionData memory opt) private view returns (uint timestamp) {

        (timestamp,) = UnderlyingFeed(opt.udlFeed).getLatestPrice();
    }
}

pragma solidity >=0.6.0;

import "../../contracts/finance/OptionsExchange.sol";
import "../../contracts/utils/Arrays.sol";
import "../../contracts/utils/ERC20.sol";
import "../../contracts/utils/SafeMath.sol";

abstract contract RedeemableToken is ERC20 {

    using SafeMath for uint;

    OptionsExchange internal exchange;

    address[] internal holders;

    function redeemAllowed() virtual public returns(bool);

    function redeem(uint index) external returns (uint) {

        require(redeemAllowed(), "redeem not allowed");

        uint v = exchange.balanceOf(address(this));
        (uint bal, uint val) = redeem(v,  _totalSupply, index);
        _totalSupply = _totalSupply.sub(bal);

        return val;
    }

    function destroy() external {

        destroy(uint(-1));
    }

    function destroy(uint limit) public {

        require(redeemAllowed());

        uint valTotal = exchange.balanceOf(address(this));
        uint valRemaining = valTotal;
        uint supplyTotal = _totalSupply;
        uint supplyRemaining = _totalSupply;
        
        for (uint i = holders.length - 1; i != uint(-1) && limit != 0 && valRemaining > 0; i--) {
            (uint bal, uint val) = redeem(valTotal, supplyTotal, i);
            valRemaining = valRemaining.sub(val);
            supplyRemaining = supplyRemaining.sub(bal);
            Arrays.removeAtIndex(holders, i);
            limit--;
        }
        
        if (valRemaining > 0) {
            exchange.transferBalance(msg.sender, valRemaining);
        }

        if (supplyRemaining == 0) {
            selfdestruct(msg.sender);
        } else {
            _totalSupply = supplyRemaining;
        }
    }

    function redeem(uint valTotal, uint supplyTotal, uint i) 
        private
        returns (uint bal, uint val)
    {
        bal = balanceOf(holders[i]);
        
        if (bal > 0) {
            uint b = 1e3;
            val = MoreMath.round(valTotal.mul(bal.mul(b)).div(supplyTotal), b);
            exchange.transferBalance(holders[i], val);
            removeBalance(holders[i], bal);
        }
    }
}

pragma solidity >=0.6.0;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../utils/ERC20.sol";
import "../interfaces/TimeProvider.sol";
import "../utils/Arrays.sol";
import "../utils/SafeMath.sol";
import "./Proposal.sol";
import "./ProtocolSettings.sol";

contract GovToken is ManagedContract, ERC20 {

    using SafeMath for uint;

    TimeProvider private time;
    ProtocolSettings private settings;

    mapping(uint => Proposal) private proposalsMap;
    mapping(address => uint) private proposingDate;

    string private constant _name = "Governance Token";
    string private constant _symbol = "GOVTK";

    uint private serial;
    uint[] private proposals;

    constructor(address deployer) ERC20(_name) public {

        Deployer(deployer).setContractAddress("GovToken");
    }
    
    function initialize(Deployer deployer) override internal {

        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        serial = 1;
    }

    function name() override external view returns (string memory) {
        return _name;
    }

    function symbol() override external view returns (string memory) {
        return _symbol;
    }

    function setInitialSupply(address owner, uint supply) public {
        
        require(_totalSupply == 0, "initial supply already set");
        _totalSupply = supply;
        balances[owner] = supply;
        emitTransfer(address(0), owner, supply);
    }

    function registerProposal(address addr) public returns (uint id) {
        
        require(
            proposingDate[addr] == 0 || time.getNow() - proposingDate[addr] > 1 days,
            "minimum interval between proposals not met"
        );

        Proposal p = Proposal(addr);
        (uint v, uint b) = settings.getMinShareForProposal();
        require(calcShare(msg.sender, b) >= v);

        id = serial++;
        p.open(id);
        proposalsMap[id] = p;
        proposingDate[addr] = time.getNow();
        proposals.push(id);
    }

    function isRegisteredProposal(address addr) public view returns (bool) {
        
        Proposal p = Proposal(addr);
        return address(proposalsMap[p.getId()]) == addr;
    }

    function calcShare(address owner, uint base) private view returns (uint) {

        return balanceOf(owner).mul(base).div(_totalSupply);
    }

    function emitTransfer(address from, address to, uint value) override internal {

        for (uint i = 0; i < proposals.length; i++) {
            uint id = proposals[i];
            Proposal p = proposalsMap[id];
            if (p.isClosed()) {
                Arrays.removeAtIndex(proposals, i);
                i--;
            } else {
                p.update(from, to, value);
            }
        }

        emit Transfer(from, to, value);
    }
}

pragma solidity >=0.6.0;

import "../interfaces/TimeProvider.sol";
import "../utils/MoreMath.sol";
import "../utils/SafeMath.sol";
import "./GovToken.sol";

abstract contract Proposal {

    using SafeMath for uint;

    enum Quorum { SIMPLE_MAJORITY, TWO_THIRDS }

    enum Status { PENDING, OPEN, APPROVED, REJECTED }

    TimeProvider private time;
    GovToken private govToken;

    mapping(address => int) private votes;
    
    uint private id;
    uint private yea;
    uint private nay;
    Quorum private quorum;
    Status private status;
    uint private expiresAt;
    bool private closed;

    constructor(
        address _time,
        address _govToken,
        Quorum _quorum,
        uint _expiresAt
    )
        public
    {
        time = TimeProvider(_time);
        govToken = GovToken(_govToken);
        quorum = _quorum;
        status = Status.PENDING;
        expiresAt = _expiresAt;
        closed = false;
    }

    function getId() public view returns (uint) {

        return id;
    }

    function getQuorum() public view returns (Quorum) {

        return quorum;
    }

    function getStatus() public view returns (Status) {

        return status;
    }

    function isExecutionAllowed() public view returns (bool) {

        return status == Status.APPROVED && !closed;
    }

    function isClosed() public view returns (bool) {

        return closed;
    }

    function open(uint _id) public {

        require(msg.sender == address(govToken));
        require(status == Status.PENDING);
        id = _id;
        status = Status.OPEN;
    }

    function castVote(bool support) public {
        
        ensureIsActive();
        require(votes[msg.sender] == 0);
        
        uint balance = govToken.balanceOf(msg.sender);
        require(balance > 0);

        if (support) {
            votes[msg.sender] = int(balance);
            yea = yea.add(balance);
        } else {
            votes[msg.sender] = int(-balance);
            nay = nay.add(balance);
        }
    }

    function update(address from, address to, uint value) public {

        update(from, -int(value));
        update(to, int(value));
    }

    function close() public {

        ensureIsActive();

        uint total = govToken.totalSupply();

        uint v;
        if (quorum == Proposal.Quorum.SIMPLE_MAJORITY) {
            v = total.div(2);
        } else if (quorum == Proposal.Quorum.TWO_THIRDS) {
            v = total.mul(2).div(3);
        } else {
            revert();
        }

        if (yea > v) {
            status = Status.APPROVED;
            execute();
        } else if (nay >= v) {
            status = Status.REJECTED;
        } else {
            revert("quorum not reached");
        }

        closed = true;
    }

    function execute() public virtual;

    function ensureIsActive() private view {

        require(!closed);
        require(status == Status.OPEN);
        require(expiresAt > time.getNow());
    }

    function update(address voter, int diff) private {

        if (votes[voter] != 0) {
            ensureIsActive();
            require(msg.sender == address(govToken));

            uint _diff = MoreMath.abs(diff);
            uint oldBalance = MoreMath.abs(votes[voter]);
            uint newBalance = diff > 0 ? oldBalance.add(_diff) : oldBalance.sub(_diff);

            if (votes[voter] > 0) {
                yea = yea.add(newBalance).sub(oldBalance);
            } else {
                nay = nay.add(newBalance).sub(oldBalance);
            }
        }
    }
}

pragma solidity >=0.6.0;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../finance/CreditProvider.sol";
import "../interfaces/TimeProvider.sol";
import "../interfaces/UnderlyingFeed.sol";
import "../utils/Arrays.sol";
import "../utils/MoreMath.sol";
import "../utils/SafeMath.sol";
import "./GovToken.sol";
import "./Proposal.sol";

contract ProtocolSettings is ManagedContract {

    using SafeMath for uint;

    struct Rate {
        uint value;
        uint base;
        uint date;
    }

    TimeProvider private time;
    CreditProvider private creditProvider;
    GovToken private govToken;

    mapping(address => int) private underlyingFeeds;
    mapping(address => Rate) private tokenRates;

    address private owner;
    address[] private tokens;
    Rate private minShareForProposal;
    Rate[] private debtInterestRates;
    Rate[] private creditInterestRates;
    Rate private processingFee;
    uint private volatilityPeriod;

    uint private MAX_UINT;

    constructor(address deployer) public {

        Deployer(deployer).setContractAddress("ProtocolSettings");
    }
    
    function initialize(Deployer deployer) override internal {

        owner = deployer.getOwner();
        time = TimeProvider(deployer.getPayableContractAddress("TimeProvider"));
        creditProvider = CreditProvider(deployer.getPayableContractAddress("CreditProvider"));
        govToken = GovToken(deployer.getPayableContractAddress("GovToken"));

        MAX_UINT = uint(-1);

        minShareForProposal = Rate( // 1%
            100,
            10000, 
            MAX_UINT
        );

        debtInterestRates.push(Rate( // 25% per year
            10000254733325807, 
            10000000000000000, 
            MAX_UINT
        ));

        creditInterestRates.push(Rate( // 5% per year
            10000055696689545, 
            10000000000000000,
            MAX_UINT
        ));

        processingFee = Rate( // no fees
            0,
            10000000000000000, 
            MAX_UINT
        );

        volatilityPeriod = 90 days;
    }

    function getOwner() external view returns (address) {

        return owner;
    }

    function setOwner(address _owner) external {

        require(msg.sender == owner || owner == address(0));
        owner = _owner;
    }

    function getTokenRate(address token) external view returns (uint v, uint b) {

        v = tokenRates[token].value;
        b = tokenRates[token].base;
    }

    function setTokenRate(address token, uint v, uint b) external {

        ensureWritePriviledge();
        tokenRates[token] = Rate(v, b, MAX_UINT);
    }

    function getAllowedTokens() external view returns (address[] memory) {

        return tokens;
    }

    function setAllowedToken(address token, uint v, uint b) external {

        ensureWritePriviledge();
        if (tokenRates[token].value != 0) {
            Arrays.removeItem(tokens, token);
        }
        tokens.push(token);
        tokenRates[token] = Rate(v, b, MAX_UINT);
    }

    function getMinShareForProposal() external view returns (uint v, uint b) {
        
        v = minShareForProposal.value;
        b = minShareForProposal.base;
    }

    function setMinShareForProposal(uint s, uint b) external {
        
        ensureWritePriviledge();
        minShareForProposal = Rate(s, b, MAX_UINT);
    }

    function getDebtInterestRate() external view returns (uint v, uint b, uint d) {
        
        uint len = debtInterestRates.length;
        Rate memory r = debtInterestRates[len - 1];
        v = r.value;
        b = r.base;
        d = r.date;
    }

    function applyDebtInterestRate(uint value, uint date) external view returns (uint) {
        
        return applyRates(debtInterestRates, value, date);
    }

    function setDebtInterestRate(uint i, uint b) external {
        
        ensureWritePriviledge();
        debtInterestRates[debtInterestRates.length - 1].date = time.getNow();
        debtInterestRates.push(Rate(i, b, MAX_UINT));
    }

    function getCreditInterestRate() external view returns (uint v, uint b, uint d) {
        
        uint len = creditInterestRates.length;
        Rate memory r = creditInterestRates[len - 1];
        v = r.value;
        b = r.base;
        d = r.date;
    }

    function applyCreditInterestRate(uint value, uint date) external view returns (uint) {
        
        return applyRates(creditInterestRates, value, date);
    }

    function getCreditInterestRate(uint date) external view returns (uint v, uint b, uint d) {
        
        Rate memory r = getRate(creditInterestRates, date);
        v = r.value;
        b = r.base;
        d = r.date;
    }

    function setCreditInterestRate(uint i, uint b) external {
        
        ensureWritePriviledge();
        creditInterestRates[creditInterestRates.length - 1].date = time.getNow();
        creditInterestRates.push(Rate(i, b, MAX_UINT));
    }

    function getProcessingFee() external view returns (uint v, uint b) {
        
        v = processingFee.value;
        b = processingFee.base;
    }

    function setProcessingFee(uint f, uint b) external {
        
        ensureWritePriviledge();
        processingFee = Rate(f, b, MAX_UINT);
    }

    function getUdlFeed(address addr) external view returns (int) {

        return underlyingFeeds[addr];
    }

    function setUdlFeed(address addr, int v) external {

        ensureWritePriviledge();
        underlyingFeeds[addr] = v;
    }

    function setVolatilityPeriod(uint _volatilityPeriod) external {

        volatilityPeriod = _volatilityPeriod;
    }

    function getVolatilityPeriod() external view returns(uint) {

        return volatilityPeriod;
    }

    function applyRates(Rate[] storage rates, uint value, uint date) private view returns (uint) {
        
        Rate memory r;
        
        do {
            r = getRate(rates, date);
            uint dt = MoreMath.min(r.date, time.getNow()).sub(date).div(1 hours);
            if (dt > 0) {
                value = MoreMath.powAndMultiply(r.value, r.base, dt, value);
                date = r.date;
            }
        } while (r.date != MAX_UINT);

        return value;
    }

    function getRate(Rate[] storage rates, uint date) private view returns (Rate memory r) {
        
        uint len = rates.length;
        r = rates[len - 1];
        for (uint i = 0; i < len; i++) { // TODO: optimize with binary search and offset index
            if (date < rates[i].date) {
                r = rates[i];
                break;
            }
        }
    }

    function ensureWritePriviledge() private view {

        if (msg.sender != owner) {
            Proposal p = Proposal(msg.sender);
            require(govToken.isRegisteredProposal(msg.sender), "proposal not registered");
            require(p.isExecutionAllowed(), "execution not allowed");
        }
    }
}

pragma solidity >=0.6.0;

interface IERC20Details {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity >=0.6.0;

interface LiquidityPool {

    event AddSymbol(string optSymbol);
    
    event RemoveSymbol(string optSymbol);

    event Buy(address indexed token, address indexed buyer, uint price, uint volume);
    
    event Sell(address indexed token, address indexed seller, uint price, uint volume);

    function maturity() external view returns (uint);

    function yield(uint dt) external view returns (uint y);

    function depositTokens(
        address to,
        address token,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function depositTokens(address to, address token, uint value) external;

    function listSymbols() external view returns (string memory);

    function queryBuy(string calldata optSymbol) external view returns (uint price, uint volume);

    function querySell(string calldata optSymbol) external view returns (uint price, uint volume);

    function buy(
        string calldata optSymbol,
        uint price,
        uint volume,
        address token,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (address addr);

    function buy(string calldata optSymbol, uint price, uint volume, address token)
        external
        returns (address addr);

    function sell(string calldata optSymbol, uint price, uint volume) external;
}

pragma solidity >=0.6.0;

interface TimeProvider {

    function getNow() external view returns (uint);

}

pragma solidity >=0.6.0;

interface UnderlyingFeed {

    function symbol() external view returns (string memory);

    function getLatestPrice() external view returns (uint timestamp, int price);

    function getPrice(uint position) external view returns (uint timestamp, int price);

    function getDailyVolatility(uint timespan) external view returns (uint vol);

    function calcLowerVolatility(uint vol) external view returns (uint lowerVol);

    function calcUpperVolatility(uint vol) external view returns (uint upperVol);
}

pragma solidity >=0.6.0;

import "../deployment/ManagedContract.sol";
import "../finance/OptionsExchange.sol";
import "../finance/RedeemableToken.sol";
import "../governance/ProtocolSettings.sol";
import "../interfaces/TimeProvider.sol";
import "../interfaces/LiquidityPool.sol";
import "../interfaces/UnderlyingFeed.sol";
import "../utils/ERC20.sol";
import "../utils/MoreMath.sol";
import "../utils/SafeCast.sol";
import "../utils/SafeMath.sol";
import "../utils/SignedSafeMath.sol";

contract LinearLiquidityPool is LiquidityPool, ManagedContract, RedeemableToken {

    using SafeCast for uint;
    using SafeMath for uint;
    using SignedSafeMath for int;

    enum Operation { BUY, SELL }

    struct PricingParameters {
        address udlFeed;
        OptionsExchange.OptionType optType;
        uint120 strike;
        uint32 maturity;
        uint32 t0;
        uint32 t1;
        uint120 buyStock;
        uint120 sellStock;
        uint120[] x;
        uint120[] y;
    }

    struct Deposit {
        uint32 date;
        uint balance;
        uint value;
    }

    TimeProvider private time;
    ProtocolSettings private settings;

    mapping(string => PricingParameters) private parameters;

    string private constant _name = "Linear Liquidity Pool Redeemable Token";
    string private constant _symbol = "LLPTK";

    address private owner;
    uint private spread;
    uint private reserveRatio;
    uint private _maturity;
    string[] private optSymbols;
    Deposit[] private deposits;

    uint private timeBase;
    uint private sqrtTimeBase;
    uint private volumeBase;
    uint private fractionBase;

    constructor(address deployer) ERC20(_name) public {

        Deployer(deployer).setContractAddress("LinearLiquidityPool");
    }

    function initialize(Deployer deployer) override internal {

        owner = deployer.getOwner();
        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        exchange = OptionsExchange(deployer.getContractAddress("OptionsExchange"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));

        timeBase = 1e18;
        sqrtTimeBase = 1e9;
        volumeBase = exchange.getVolumeBase();
        fractionBase = 1e9;
    }

    function name() override external view returns (string memory) {
        return _name;
    }

    function symbol() override external view returns (string memory) {
        return _symbol;
    }

    function setParameters(
        uint _spread,
        uint _reserveRatio,
        uint _mt
    )
        external
    {
        ensureCaller();
        spread = _spread;
        reserveRatio = _reserveRatio;
        _maturity = _mt;
    }

    function redeemAllowed() override public returns (bool) {
        
        return time.getNow() >= _maturity;
    }

    function maturity() override external view returns (uint) {
        
        return _maturity;
    }

    function yield(uint dt) override external view returns (uint y) {
        
        y = fractionBase;

        if (deposits.length > 0) {
            
            uint _now = time.getNow();
            uint start = _now.sub(dt);
            
            uint i = 0;
            for (i = 0; i < deposits.length; i++) {
                if (deposits[i].date > start) {
                    break;
                }
            }

            for (; i <= deposits.length; i++) {
                if (i > 0) {
                    y = y.mul(calcYield(i, start)).div(fractionBase);
                }
            }
        }
    }

    function addSymbol(
        string calldata optSymbol,
        address udlFeed,
        uint strike,
        uint _mt,
        OptionsExchange.OptionType optType,
        uint t0,
        uint t1,
        uint120[] calldata x,
        uint120[] calldata y,
        uint buyStock,
        uint sellStock
    )
        external
    {
        ensureCaller();
        require(_mt < _maturity, "invalid maturity");
        require(x.length > 0 && x.length.mul(2) == y.length, "invalid pricing surface");

        if (parameters[optSymbol].x.length == 0) {
            optSymbols.push(optSymbol);
        }

        parameters[optSymbol] = PricingParameters(
            udlFeed,
            optType,
            strike.toUint120(),
            _mt.toUint32(),
            t0.toUint32(),
            t1.toUint32(),
            buyStock.toUint120(),
            sellStock.toUint120(),
            x,
            y
        );

        emit AddSymbol(optSymbol);
    }
    
    function removeSymbol(string calldata optSymbol) external {

        ensureCaller();
        PricingParameters memory empty;
        parameters[optSymbol] = empty;
        Arrays.removeItem(optSymbols, optSymbol);
        emit RemoveSymbol(optSymbol);
    }

    function depositTokens(
        address to,
        address token,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        override
        external
    {
        ERC20(token).permit(msg.sender, address(this), value, deadline, v, r, s);
        depositTokens(to, token, value);
    }

    function depositTokens(address to, address token, uint value) override public {

        uint b0 = exchange.balanceOf(address(this));
        depositTokensInExchange(msg.sender, token, value);
        uint b1 = exchange.balanceOf(address(this));
        int po = exchange.calcExpectedPayout(address(this));
        
        deposits.push(Deposit(time.getNow().toUint32(), uint(int(b0).add(po)), value));

        uint ts = _totalSupply;
        int expBal = po.add(int(b1));
        uint p = b1.sub(b0).mul(fractionBase).div(uint(expBal));

        uint b = 1e3;
        uint v = ts > 0 ?
            ts.mul(p).mul(b).div(fractionBase.sub(p)) : 
            uint(expBal).mul(b);
        v = MoreMath.round(v, b);

        addBalance(to, v);
        _totalSupply = ts.add(v);
        emitTransfer(address(0), to, v);
    }

    function calcFreeBalance() public view returns (uint balance) {

        uint exBal = exchange.balanceOf(address(this));
        balance = exBal.mul(reserveRatio).div(fractionBase);
        uint sp = exBal.sub(exchange.collateral(address(this)));
        balance = sp > balance ? sp.sub(balance) : 0;
    }
    
    function listSymbols() override external view returns (string memory available) {

        for (uint i = 0; i < optSymbols.length; i++) {
            if (parameters[optSymbols[i]].maturity > time.getNow()) {
                if (bytes(available).length == 0) {
                    available = optSymbols[i];
                } else {
                    available = string(abi.encodePacked(available, "\n", optSymbols[i]));
                }
            }
        }
    }

    function setUpSymbol(string calldata optSymbol) external {

        PricingParameters memory param = parameters[optSymbol];
        writeOptions(optSymbol, param, 1, address(this));
    }

    function queryBuy(string memory optSymbol)
        override
        public
        view
        returns (uint price, uint volume)
    {
        ensureValidSymbol(optSymbol);
        PricingParameters memory param = parameters[optSymbol];
        price = calcOptPrice(param, Operation.BUY);
        uint _written = exchange.writtenVolume(optSymbol, address(this));
        volume = MoreMath.min(
            calcVolume(param, price, Operation.BUY),
            uint(param.buyStock).sub(_written)
        );
    }

    function querySell(string memory optSymbol)
        override
        public
        view
        returns (uint price, uint volume)
    {    
        ensureValidSymbol(optSymbol);
        PricingParameters memory param = parameters[optSymbol];
        price = calcOptPrice(param, Operation.SELL);
        address tk = exchange.resolveToken(optSymbol);
        volume = MoreMath.min(
            calcVolume(param, price, Operation.SELL),
            uint(param.sellStock).sub(ERC20(tk).balanceOf(address(this)))
        );
    }
    
    function buy(
        string memory optSymbol,
        uint price,
        uint volume,
        address token,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        override
        public
        returns (address tk)
    {
        require(volume > 0, "invalid volume");
        ensureValidSymbol(optSymbol);

        PricingParameters memory param = parameters[optSymbol];
        price = receivePayment(param, price, volume, token, deadline, v, r, s);

        tk = exchange.resolveToken(optSymbol);
        uint _holding = ERC20(tk).balanceOf(address(this));
        if (volume > _holding) {
            writeOptions(optSymbol, param, volume, msg.sender);
        } else {
            OptionToken(tk).transfer(msg.sender, volume);
        }

        emit Buy(tk, msg.sender, price, volume);
    }

    function buy(string calldata optSymbol, uint price, uint volume, address token)
        override
        external
        returns (address tk)
    {
        bytes32 x;
        tk = buy(optSymbol, price, volume, token, 0, 0, x, x);
    }

    function sell(string calldata optSymbol, uint price, uint volume) override external {
        
        require(volume > 0, "invalid volume");
        ensureValidSymbol(optSymbol);

        PricingParameters memory param = parameters[optSymbol];
        price = validatePrice(price, param, Operation.SELL);

        address addr = exchange.resolveToken(optSymbol);
        OptionToken tk = OptionToken(addr);
        tk.transferFrom(msg.sender, address(this), volume);

        uint value = price.mul(volume).div(volumeBase);
        exchange.transferBalance(msg.sender, value);
        
        require(calcFreeBalance() > 0, "excessive volume");
        
        uint _written = exchange.writtenVolume(optSymbol, address(this));

        if (_written > 0) {
            uint toBurn = MoreMath.min(_written, volume);
            tk.burn(toBurn);
        }

        uint _holding = tk.balanceOf(address(this));
        require(_holding <= param.sellStock, "excessive volume");

        emit Sell(addr, msg.sender, price, volume);
    }

    function receivePayment(
        PricingParameters memory param,
        uint price,
        uint volume,
        address token,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        private
        returns (uint)
    {
        uint maxValue = price.mul(volume).div(volumeBase);
        price = validatePrice(price, param, Operation.BUY);
        uint value = price.mul(volume).div(volumeBase);

        if (token != address(exchange)) {
            (uint tv, uint tb) = settings.getTokenRate(token);
            if (deadline > 0) {
                maxValue = maxValue.mul(tv).div(tb);
                ERC20(token).permit(msg.sender, address(this), maxValue, deadline, v, r, s);
            }
            value = value.mul(tv).div(tb);
            depositTokensInExchange(msg.sender, token, value);
        } else {
            exchange.transferBalance(msg.sender, address(this), value, maxValue, deadline, v, r, s);
        }

        return price;
    }

    function validatePrice(
        uint price, 
        PricingParameters memory param, 
        Operation op
    ) 
        private
        view
        returns (uint p) 
    {
        p = calcOptPrice(param, op);
        require(
            op == Operation.BUY ? price >= p : price <= p,
            "insufficient price"
        );
    }

    function writeOptions(
        string memory optSymbol,
        PricingParameters memory param,
        uint volume,
        address to
    )
        private
    {
        uint _written = exchange.writtenVolume(optSymbol, address(this));
        require(_written.add(volume) <= param.buyStock, "excessive volume");

        exchange.writeOptions(
            param.udlFeed,
            volume,
            param.optType,
            param.strike,
            param.maturity,
            to
        );
        
        require(calcFreeBalance() > 0, "excessive volume");
    }

    function calcOptPrice(PricingParameters memory p, Operation op)
        private
        view
        returns (uint price)
    {
        uint f = op == Operation.BUY ? spread.add(fractionBase) : fractionBase.sub(spread);
        
        (uint j, uint xp) = findUdlPrice(p);

        uint _now = time.getNow();
        uint dt = uint(p.t1).sub(uint(p.t0));
        require(_now >= p.t0 && _now <= p.t1, "invalid pricing parameters");
        uint t = _now.sub(p.t0);
        uint p0 = calcOptPriceAt(p, 0, j, xp);
        uint p1 = calcOptPriceAt(p, p.x.length, j, xp);

        price = p0.mul(dt).sub(
            t.mul(p0.sub(p1))
        ).mul(f).div(fractionBase).div(dt);
    }

    function findUdlPrice(PricingParameters memory p) private view returns (uint j, uint xp) {

        UnderlyingFeed feed = UnderlyingFeed(p.udlFeed);
        (,int udlPrice) = feed.getLatestPrice();
        
        j = 0;
        xp = uint(udlPrice);
        while (p.x[j] < xp && j < p.x.length) {
            j++;
        }
        require(j > 0 && j < p.x.length, "invalid pricing parameters");
    }

    function calcOptPriceAt(
        PricingParameters memory p,
        uint offset,
        uint j,
        uint xp
    )
        private
        pure
        returns (uint price)
    {
        uint k = offset.add(j);
        int yA = int(p.y[k]);
        int yB = int(p.y[k - 1]);
        price = uint(
            yA.sub(yB).mul(
                int(xp.sub(p.x[j - 1]))
            ).div(
                int(p.x[j]).sub(int(p.x[j - 1]))
            ).add(yB)
        );
    }

    function calcVolume(
        PricingParameters memory p,
        uint price,
        Operation op
    )
        private
        view
        returns (uint volume)
    {
        uint fb = calcFreeBalance();

        if (op == Operation.BUY) {

            uint coll = exchange.calcCollateral(
                p.udlFeed,
                volumeBase,
                p.optType,
                p.strike,
                p.maturity
            );

            volume = coll <= price ? uint(-1) :
                fb.mul(volumeBase).div(coll.sub(price));

        } else {
            
            uint iv = uint(exchange.calcIntrinsicValue(
                p.udlFeed,
                p.optType,
                p.strike,
                p.maturity
            ));

            volume = price <= iv ? uint(-1) :
                fb.mul(volumeBase).div(price.sub(iv));

            volume = MoreMath.min(
                volume, 
                exchange.balanceOf(address(this)).mul(volumeBase).div(price)
            );
        }
    }

    function calcYield(uint index, uint start) private view returns (uint y) {

        uint t0 = deposits[index - 1].date;
        uint t1 = index < deposits.length ?
            deposits[index].date : time.getNow();

        int v0 = int(deposits[index - 1].value.add(deposits[index - 1].balance));
        int v1 = index < deposits.length ? 
            int(deposits[index].balance) :
            exchange.calcExpectedPayout(address(this)).add(int(exchange.balanceOf(address(this))));

        y = uint(v1.mul(int(fractionBase)).div(v0));
        if (start > t0) {
            y = MoreMath.powDecimal(
                y, 
                (t1.sub(start)).mul(fractionBase).div(t1.sub(t0)), 
                fractionBase
            );
        }
    }

    function depositTokensInExchange(address sender, address token, uint value) private {
        
        ERC20 t = ERC20(token);
        t.transferFrom(sender, address(this), value);
        t.approve(address(exchange), value);
        exchange.depositTokens(address(this), token, value);
    }

    function addBalance(address _owner, uint value) override internal {

        if (balanceOf(_owner) == 0) {
            holders.push(_owner);
        }
        balances[_owner] = balanceOf(_owner).add(value);
    }

    function ensureValidSymbol(string memory optSymbol) private view {

        require(parameters[optSymbol].udlFeed !=  address(0), "invalid optSymbol");
    }

    function ensureCaller() private view {

        require(owner == address(0) || msg.sender == owner, "unauthorized caller");
    }
}

pragma solidity >=0.6.0;

library Arrays {

    function removeAtIndex(uint[] storage array, uint index) internal {

        array[index] = array[array.length - 1];
        array.pop();
    }

    function removeAtIndex(address[] storage array, uint index) internal {

        array[index] = array[array.length - 1];
        array.pop();
    }

    function removeItem(uint48[] storage array, uint48 item) internal returns (bool) {

        for (uint i = 0; i < array.length; i++) {
            if (array[i] == item) {
                array[i] = array[array.length - 1];
                array.pop();
                return true;
            }
        }

        return false;
    }

    function removeItem(uint[] storage array, uint item) internal returns (bool) {

        for (uint i = 0; i < array.length; i++) {
            if (array[i] == item) {
                array[i] = array[array.length - 1];
                array.pop();
                return true;
            }
        }

        return false;
    }

    function removeItem(address[] storage array, address item) internal returns (bool) {

        for (uint i = 0; i < array.length; i++) {
            if (array[i] == item) {
                array[i] = array[array.length - 1];
                array.pop();
                return true;
            }
        }

        return false;
    }

    function removeItem(string[] storage array, string memory item) internal returns (bool) {

        for (uint i = 0; i < array.length; i++) {
            if (keccak256(bytes(array[i])) == keccak256(bytes(item))) {
                array[i] = array[array.length - 1];
                array.pop();
                return true;
            }
        }

        return false;
    }
}

pragma solidity >=0.6.0;

import "../interfaces/IERC20Details.sol";
import "../utils/SafeMath.sol";

abstract contract ERC20 is IERC20Details {

    using SafeMath for uint;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    uint _totalSupply;

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(string memory _name) public {

        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function decimals() override external view returns (uint8) {
        return 18;
    }

    function totalSupply() virtual public view returns (uint) {

        return _totalSupply;
    }

    function balanceOf(address owner) virtual public view returns (uint) {

        return balances[owner];
    }

    function allowance(address owner, address spender) virtual public view returns (uint) {

        return allowed[owner][spender];
    }

    function transfer(address to, uint value) virtual external returns (bool) {

        require(value <= balanceOf(msg.sender));
        require(to != address(0));

        removeBalance(msg.sender, value);
        addBalance(to, value);
        emitTransfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) virtual external returns (bool) {

        return approve(msg.sender, spender, value);
    }

    function transferFrom(address from, address to, uint value) virtual public returns (bool) {

        require(value <= balanceOf(from));
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));

        removeBalance(from, value);
        addBalance(to, value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emitTransfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) virtual public returns (bool) {

        require(spender != address(0));

        allowed[msg.sender][spender] = (
            allowed[msg.sender][spender].add(addedValue));
        emitApproval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) virtual public returns (bool) {

        require(spender != address(0));

        allowed[msg.sender][spender] = (
            allowed[msg.sender][spender].sub(subtractedValue));
        emitApproval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        require(deadline >= block.timestamp, "permit expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline)
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "invalid signature");
        approve(owner, spender, value);
    }

    function approve(address owner, address spender, uint value) private returns (bool) {

        require(spender != address(0));

        allowed[owner][spender] = value;
        emitApproval(owner, spender, value);
        return true;
    }

    function addBalance(address owner, uint value) virtual internal {

        balances[owner] = balanceOf(owner).add(value);
    }

    function removeBalance(address owner, uint value) virtual internal {

        balances[owner] = balanceOf(owner).sub(value);
    }

    function emitTransfer(address from, address to, uint value) virtual internal {

        emit Transfer(from, to, value);
    }

    function emitApproval(address owner, address spender, uint value) virtual internal {

        emit Approval(owner, spender, value);
    }
}

pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./SignedSafeMath.sol";

library MoreMath {

    using SafeMath for uint;
    using SignedSafeMath for int;

    function round(uint v, uint b) internal pure returns (uint) {

        return v.div(b).add((v % b) >= b.div(2) ? 1 : 0);
    }

    function powAndMultiply(uint n, uint d, uint e, uint f) internal pure returns (uint) {
        
        if (e == 0) {
            return 1;
        } else if (e == 1) {
            return f.mul(n).div(d);
        } else {
            uint p = powAndMultiply(n, d, e.div(2), f);
            p = p.mul(p).div(f);
            if (e.mod(2) == 1) {
                p = p.mul(n).div(d);
            }
            return p;
        }
    }

    function pow(uint n, uint e) internal pure returns (uint) {
        
        if (e == 0) {
            return 1;
        } else if (e == 1) {
            return n;
        } else {
            uint p = pow(n, e.div(2));
            p = p.mul(p);
            if (e.mod(2) == 1) {
                p = p.mul(n);
            }
            return p;
        }
    }

    function powDecimal(uint n, uint e, uint b) internal pure returns (uint v) {
        
        if (e == 0) {
            return b;
        }

        if (e > b) {
            return n.mul(powDecimal(n, e.sub(b), b)).div(b);
        }

        v = b;
        uint f = b;
        uint aux = 0;
        uint rootN = n;
        uint rootB = sqrt(b);
        while (f > 1) {
            f = f.div(2);
            rootN = sqrt(rootN).mul(rootB);
            if (aux.add(f) < e) {
                aux = aux.add(f);
                v = v.mul(rootN).div(b);
            }
        }
    }
    
    function divCeil(uint n, uint d) internal pure returns (uint v) {
        
        v = n.div(d);
        if (n.mod(d) > 0) {
            v = v.add(1);
        }
    }
    
    function sqrtAndMultiply(uint x, uint f) internal pure returns (uint y) {
    
        y = sqrt(x.mul(1e18)).mul(f).div(1e9);
    }
    
    function sqrt(uint x) internal pure returns (uint y) {
    
        uint z = (x.add(1)).div(2);
        y = x;
        while (z < y) {
            y = z;
            z = (x.div(z).add(z)).div(2);
        }
    }

    function std(int[] memory array) internal pure returns (uint _std) {

        int avg = sum(array).div(int(array.length));
        uint x2 = 0;
        for (uint i = 0; i < array.length; i++) {
            int p = array[i].sub(avg);
            x2 = x2.add(uint(p.mul(p)));
        }
        _std = sqrt(x2 / array.length);
    }

    function sum(int[] memory array) internal pure returns (int _sum) {

        for (uint i = 0; i < array.length; i++) {
            _sum = _sum.add(array[i]);
        }
    }

    function abs(int a) internal pure returns (uint) {

        return uint(a < 0 ? -a : a);
    }
    
    function max(int a, int b) internal pure returns (int) {
        
        return a > b ? a : b;
    }
    
    function max(uint a, uint b) internal pure returns (uint) {
        
        return a > b ? a : b;
    }
    
    function min(int a, int b) internal pure returns (int) {
        
        return a < b ? a : b;
    }
    
    function min(uint a, uint b) internal pure returns (uint) {
        
        return a < b ? a : b;
    }

    function toString(uint v) internal pure returns (string memory str) {

        str = toString(v, true);
    }
    
    function toString(uint v, bool scientific) internal pure returns (string memory str) {

        if (v == 0) {
            return "0";
        }

        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }

        uint zeros = 0;
        if (scientific) {
            for (uint k = 0; k < i; k++) {
                if (reversed[k] == '0') {
                    zeros++;
                } else {
                    break;
                }
            }
        }

        uint len = i - (zeros > 2 ? zeros : 0);
        bytes memory s = new bytes(len);
        for (uint j = 0; j < len; j++) {
            s[j] = reversed[i - j - 1];
        }

        str = string(s);

        if (scientific && zeros > 2) {
            str = string(abi.encodePacked(s, "e", toString(zeros, false)));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value < 2**120, "SafeCast: value doesn\'t fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opsymbol (which leaves remaining gas untouched) while Solidity
     * uses an invalid opsymbol to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opsymbol (which leaves remaining gas untouched) while Solidity
     * uses an invalid opsymbol to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opsymbol (which leaves remaining gas untouched) while Solidity uses an
     * invalid opsymbol to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opsymbol (which leaves remaining gas untouched) while Solidity uses an
     * invalid opsymbol to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opsymbol (which leaves remaining gas untouched) while Solidity
     * uses an invalid opsymbol to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 500
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}