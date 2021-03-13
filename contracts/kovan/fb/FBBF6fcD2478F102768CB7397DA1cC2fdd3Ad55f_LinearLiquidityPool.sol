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

    function transferBalance(address from, address to, uint value) public {

        ensureCaller();
        removeBalance(from, value);
        addBalance(to, value);
    }
    
    function depositTokens(address to, address token, uint value) external {

        if (value > 0) {
            
            (uint r, uint b) = settings.getTokenRate(token);
            require(r != 0 && token != ctAddr, "token not allowed");
            ERC20(token).transferFrom(msg.sender, address(this), value);
            value = value.mul(b).div(r);
            addBalance(to, value);
            _totalTokenStock = _totalTokenStock.add(value);
        }
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
            }
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

    address private issuer;
    address private headAddr;
    address private tailAddr;

    constructor(address deployer) public {

        Deployer(deployer).setContractAddress("CreditToken");
    }

    function initialize(Deployer deployer) override internal {
        
        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        creditProvider = CreditProvider(deployer.getContractAddress("CreditProvider"));
        issuer = deployer.getContractAddress("CreditIssuer");
    }

    function setIssuer(address _issuer) public {

        require(issuer == address(0), "issuer already set");
        issuer = _issuer;
    }

    function issue(address to, uint value) public {

        require(msg.sender == issuer, "issuance unallowed");
        addBalance(to, value);
        _totalSupply = _totalSupply.add(value);
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

    string private _symbol;

    constructor(string memory _sb, address _issuer) public {
        
        _symbol = _sb;
        exchange = OptionsExchange(_issuer);
    }

    function symbol() external view returns (string memory) {

        return _symbol;
    }

    function issue(address to, uint value) external {

        require(msg.sender == address(exchange), "issuance unallowed");
        addBalance(to, value);
        _totalSupply = _totalSupply.add(value);
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
import "../utils/SafeMath.sol";
import "../utils/SignedSafeMath.sol";
import "./CreditProvider.sol";
import "./OptionToken.sol";
import "./OptionTokenFactory.sol";

contract OptionsExchange is ManagedContract {

    using SafeMath for uint;
    using SignedSafeMath for int;
    
    enum OptionType { CALL, PUT }
    
    struct OrderData {
        uint id;
        address owner;
        address udlFeed;
        uint lowerVol;
        uint upperVol;
        uint written;
        uint holding;
        OptionData option;
    }
    
    struct OptionData {
        OptionType _type;
        uint strike;
        uint maturity;
    }
    
    TimeProvider private time;
    ProtocolSettings private settings;
    CreditProvider private creditProvider;
    OptionTokenFactory private factory;

    mapping(uint => OrderData) private orders;
    mapping(address => uint[]) private book;
    mapping(string => address) private optionTokens;
    mapping(string => uint[]) private tokensIds;
    
    uint private serial;
    uint private bookLength; // TODO: remove unused variable
    uint private volumeBase;
    uint private timeBase;
    uint private sqrtTimeBase;

    event CreateSymbol(string indexed symbol);

    event WriteOptions(string indexed symbol, address indexed issuer, uint volume, uint id);

    event LiquidateSymbol(string indexed symbol, int udlPrice, uint value);

    constructor(address deployer) public {

        Deployer(deployer).setContractAddress("OptionsExchange");
    }

    function initialize(Deployer deployer) override internal {

        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        creditProvider = CreditProvider(deployer.getContractAddress("CreditProvider"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        factory = OptionTokenFactory(deployer.getContractAddress("OptionTokenFactory"));

        serial = 1;
        volumeBase = 1e9;
        timeBase = 1e18;
        sqrtTimeBase = 1e9;
    }

    function depositTokens(address to, address token, uint value) external {

        ERC20 t = ERC20(token);
        t.transferFrom(msg.sender, address(this), value);
        t.approve(address(creditProvider), value);
        creditProvider.depositTokens(to, token, value);
    }

    function balanceOf(address owner) external view returns (uint) {

        return creditProvider.balanceOf(owner);
    }

    function transferBalance(address to, uint value) external {

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
        returns (uint id)
    {
        id = createOrder(udlFeed, volume, optType, strike, maturity);
        ensureFunds(msg.sender);
    }

    function writtenVolume(string calldata symbol, address owner) external view returns (uint) {

        return findOrder(book[owner], symbol).written;
    }

    function transferOwnership(
        string calldata symbol,
        address from,
        address to,
        uint volume
    )
        external
    {
        require(optionTokens[symbol] == msg.sender, "unauthorized ownership transfer");

        OrderData memory ord = findOrder(book[from], symbol);

        require(isValid(ord), "order not found");
        require(volume <= ord.holding, "invalid volume");
                
        OrderData memory toOrd = findOrder(book[to], symbol);

        if (!isValid(toOrd)) {
            toOrd = orders[ord.id];
            toOrd.id = serial++;
            toOrd.owner = address(to);
            toOrd.written = 0;
            toOrd.holding = 0;
            orders[toOrd.id] = toOrd;
            book[to].push(toOrd.id);
            tokensIds[symbol].push(toOrd.id);
        }
        
        orders[ord.id].holding = orders[ord.id].holding.sub(volume);
        orders[toOrd.id].holding = orders[toOrd.id].holding.add(volume);
        ensureFunds(ord.owner);

        if (shouldRemove(ord.id)) {
            removeOrder(symbol, ord.id);
        }
    }

    function burnOptions(
        string calldata symbol,
        address owner,
        uint volume
    )
        external
    {
        require(optionTokens[symbol] == msg.sender, "unauthorized burn");
        
        OrderData memory ord = findOrder(book[owner], symbol);
        
        require(isValid(ord), "order not found");
        require(ord.written >= volume && ord.holding >= volume, "invalid volume");
        
        orders[ord.id].written = ord.written.sub(volume);
        orders[ord.id].holding = ord.holding.sub(volume);

        if (shouldRemove(ord.id)) {
            removeOrder(symbol, ord.id);
        }
    }

    function liquidateSymbol(string calldata symbol, uint limit) external {

        uint value;
        int udlPrice;
        uint iv;
        uint len = tokensIds[symbol].length;
        OrderData memory ord;

        if (len > 0) {

            for (uint i = 0; i < len && i < limit; i++) {
                
                uint id = tokensIds[symbol][0];
                ord = orders[id];

                if (i == 0) {
                    udlPrice = getUdlPrice(ord);
                    uint _now = getUdlNow(ord);
                    iv = uint(calcIntrinsicValue(ord));
                    require(ord.option.maturity <= _now, "maturity not reached");
                }

                require(ord.id == id, "invalid order id");

                if (ord.written > 0) {
                    value.add(
                        liquidateAfterMaturity(ord, symbol, msg.sender, iv.mul(ord.written))
                    );
                } else {
                    removeOrder(symbol, id);
                }
            }
        }

        if (len <= limit) {
            delete tokensIds[symbol];
            delete optionTokens[symbol];
        }

        emit LiquidateSymbol(symbol, udlPrice, value);
    }

    function liquidateOptions(uint id) external returns (uint value) {
        
        OrderData memory ord = orders[id];
        require(ord.id == id && ord.written > 0, "invalid order id");

        address token = resolveToken(id);
        string memory symbol = OptionToken(token).symbol();
        uint iv = uint(calcIntrinsicValue(ord)).mul(ord.written);
        
        if (getUdlNow(ord) >= ord.option.maturity) {
            value = liquidateAfterMaturity(ord, symbol, token, iv);
        } else {
            value = liquidateBeforeMaturity(ord, symbol, token, iv);
        }
    }

    function calcDebt(address owner) external view returns (uint debt) {

        debt = creditProvider.calcDebt(owner);
    }
    
    function calcSurplus(address owner) public view returns (uint) {
        
        uint collateral = calcCollateral(owner);
        uint bal = creditProvider.balanceOf(owner);
        if (bal >= collateral) {
            return bal.sub(collateral);
        }
        return 0;
    }

    function calcCollateral(
        address udlFeed,
        uint volume,
        OptionType optType,
        uint strike, 
        uint maturity
    )
        external
        view
        returns (uint)
    {
        OrderData memory ord = createOrderInMemory(udlFeed, volume, optType, strike, maturity);

        int collateral = calcIntrinsicValue(ord).mul(int(volume)).add(
            int(calcCollateral(ord.upperVol, ord))
        ).div(int(volumeBase));

        return collateral > 0 ? uint(collateral) : 0;
    }
    
    function calcCollateral(address owner) public view returns (uint) {
        
        int collateral;
        uint[] memory ids = book[owner];

        for (uint i = 0; i < ids.length; i++) {

            OrderData memory ord = orders[ids[i]];

            if (isValid(ord)) {
                collateral = collateral.add(
                    calcIntrinsicValue(ord).mul(
                        int(ord.written).sub(int(ord.holding))
                    )
                ).add(int(calcCollateral(ord.upperVol, ord)));
            }
        }

        collateral = collateral.div(int(volumeBase));

        if (collateral < 0)
            return 0;
        return uint(collateral);
    }

    function calcExpectedPayout(address owner) external view returns (int payout) {

        uint[] memory ids = book[owner];

        for (uint i = 0; i < ids.length; i++) {

            OrderData memory ord = orders[ids[i]];

            if (isValid(ord)) {
                payout = payout.add(
                    calcIntrinsicValue(ord).mul(
                        int(ord.holding).sub(int(ord.written))
                    )
                );
            }
        }

        payout = payout.div(int(volumeBase));
    }

    function resolveSymbol(uint id) external view returns (string memory) {
        
        return getOptionSymbol(orders[id]);
    }

    function resolveToken(uint id) public view returns (address) {
        
        address addr = optionTokens[getOptionSymbol(orders[id])];
        require(addr != address(0), "token not found");
        return addr;
    }

    function resolveToken(string memory symbol) public view returns (address) {
        
        address addr = optionTokens[symbol];
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
        uint[] memory ids = book[owner];
        holding = new uint[](ids.length);
        written = new uint[](ids.length);
        iv = new int[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            OrderData memory ord = orders[ids[i]];
            if (i == 0) {
                symbols = getOptionSymbol(ord);
            } else {
                symbols = string(abi.encodePacked(symbols, "\n", getOptionSymbol(ord)));
            }
            holding[i] = ord.holding;
            written[i] = ord.written;
            iv[i] = calcIntrinsicValue(ord);
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
    
    function calcLowerCollateral(uint id) external view returns (uint) {
        
        return calcCollateral(orders[id].lowerVol, orders[id]).div(volumeBase);
    }
    
    function calcUpperCollateral(uint id) external view returns (uint) {
        
        return calcCollateral(orders[id].upperVol, orders[id]).div(volumeBase);
    }
    
    function calcIntrinsicValue(uint id) external view returns (int) {
        
        return calcIntrinsicValue(orders[id]);
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
        OrderData memory ord = createOrderInMemory(udlFeed, volumeBase, optType, strike, maturity);

        return calcIntrinsicValue(ord);
    }

    function createOrder(
        address udlFeed,
        uint volume,
        OptionType optType,
        uint strike, 
        uint maturity
    )
        private 
        returns (uint id)
    {
        require(udlFeed == address(0) || settings.getUdlFeed(udlFeed) > 0, "feed not allowed");
        require(volume > 0, "invalid volume");
        require(maturity > time.getNow(), "invalid maturity");

        OrderData memory ord = createOrderInMemory(udlFeed, volume, optType, strike, maturity);
        id = serial++;
        ord.id = id;

        string memory symbol = getOptionSymbol(ord);

        OrderData memory result = findOrder(book[msg.sender], symbol);
        if (isValid(result)) {
            orders[result.id].written = result.written.add(volume);
            orders[result.id].holding = result.holding.add(volume);
            id = result.id;
        } else {
            orders[id] = ord;
            book[msg.sender].push(ord.id);
            tokensIds[symbol].push(ord.id);
        }

        address tk = optionTokens[symbol];
        if (tk == address(0)) {
            tk = factory.create(symbol);
            optionTokens[symbol] = tk;
            emit CreateSymbol(symbol);
        }
        
        OptionToken(tk).issue(msg.sender, volume);
        emit WriteOptions(symbol, msg.sender, volume, id);
    }

    function createOrderInMemory(
        address udlFeed,
        uint volume,
        OptionType optType,
        uint strike, 
        uint maturity
    )
        private
        view
        returns (OrderData memory ord)
    {
        OptionData memory opt = OptionData(optType, strike, maturity);

        UnderlyingFeed feed = udlFeed != address(0) ?
            UnderlyingFeed(udlFeed) :
            UnderlyingFeed(settings.getDefaultUdlFeed());

        uint vol = feed.getDailyVolatility(settings.getVolatilityPeriod());

        ord = OrderData(
            0, 
            msg.sender, 
            address(feed),
            feed.calcLowerVolatility(vol),
            feed.calcUpperVolatility(vol),
            volume,
            volume,
            opt
        );
    }

    function findOrder(
        uint[] storage ids,
        string memory symbol
    )
        private
        view
        returns (OrderData memory)
    {
        for (uint i = 0; i < ids.length; i++) {
            OrderData memory ord = orders[ids[i]];
            if (compareStrings(getOptionSymbol(ord), symbol)) {
                return ord;
            }
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
    
        removeOrder(symbol, ord.id);
    }

    function liquidateBeforeMaturity(
        OrderData memory ord,
        string memory symbol,
        address token,
        uint iv
    )
        private
        returns (uint value)
    {
        uint volume = calcLiquidationVolume(ord);
        value = calcCollateral(ord.lowerVol, ord).add(iv)
            .mul(volume).div(ord.written).div(volumeBase);
        
        orders[ord.id].written = orders[ord.id].written.sub(volume);
        if (shouldRemove(ord.id)) {
            removeOrder(symbol, ord.id);
        }

        creditProvider.processPayment(ord.owner, token, value);
    }

    function calcLiquidationVolume(OrderData memory ord) private view returns (uint volume) {
        
        uint bal = creditProvider.balanceOf(ord.owner);
        uint collateral = calcCollateral(ord.owner);
        require(collateral > bal, "unfit for liquidation");

        volume = collateral.sub(bal).mul(volumeBase).mul(ord.written).div(
            calcCollateral(ord.upperVol.sub(ord.lowerVol), ord)
        );

        volume = MoreMath.min(volume, ord.written);
    }

    function shouldRemove(uint id) private view returns (bool) {

        return orders[id].written == 0 && orders[id].holding == 0;
    }
    
    function removeOrder(string memory symbol, uint id) private {
        
        Arrays.removeItem(tokensIds[symbol], id);
        Arrays.removeItem(book[orders[id].owner], id);
        delete orders[id];
    }

    function getOptionSymbol(OrderData memory ord) private view returns (string memory symbol) {
        
        symbol = string(abi.encodePacked(
            UnderlyingFeed(ord.udlFeed).symbol(),
            "-",
            "E",
            ord.option._type == OptionType.CALL ? "C" : "P",
            "-",
            MoreMath.toString(ord.option.strike),
            "-",
            MoreMath.toString(ord.option.maturity)
        ));
    }
    
    function ensureFunds(address owner) private view {
        
        require(
            creditProvider.balanceOf(owner) >= calcCollateral(owner),
            "insufficient collateral"
        );
    }
    
    function calcCollateral(uint vol, OrderData memory ord) private view returns (uint) {
        
        return (vol.mul(ord.written).mul(MoreMath.sqrt(daysToMaturity(ord)))).div(sqrtTimeBase);
    }
    
    function calcIntrinsicValue(OrderData memory ord) private view returns (int value) {
        
        OptionData memory opt = ord.option;
        int udlPrice = getUdlPrice(ord);
        int strike = int(opt.strike);

        if (opt._type == OptionType.CALL) {
            value = MoreMath.max(0, udlPrice.sub(strike));
        } else if (opt._type == OptionType.PUT) {
            value = MoreMath.max(0, strike.sub(udlPrice));
        }
    }
    
    function isValid(OrderData memory ord) private pure returns (bool) {
        
        return ord.id > 0;
    }
    
    function daysToMaturity(OrderData memory ord) private view returns (uint d) {
        
        uint _now = getUdlNow(ord);
        if (ord.option.maturity > _now) {
            d = (timeBase.mul(ord.option.maturity.sub(uint(_now)))).div(1 days);
        } else {
            d = 0;
        }
    }

    function getUdlPrice(OrderData memory ord) private view returns (int answer) {

        if (ord.option.maturity > time.getNow()) {
            (,answer) = UnderlyingFeed(ord.udlFeed).getLatestPrice();
        } else {
            (,answer) = UnderlyingFeed(ord.udlFeed).getPrice(ord.option.maturity);
        }
    }

    function getUdlNow(OrderData memory ord) private view returns (uint timestamp) {

        (timestamp,) = UnderlyingFeed(ord.udlFeed).getLatestPrice();
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
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

    uint private serial;
    uint[] private proposals;

    constructor(address deployer) public {

        Deployer(deployer).setContractAddress("GovToken");
    }
    
    function initialize(Deployer deployer) override internal {

        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        serial = 1;
    }

    function setInitialSupply(address owner, uint supply) public {
        
        require(_totalSupply == 0, "initial supply already set");
        _totalSupply = supply;
        balances[owner] = supply;
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
    UnderlyingFeed private defaultUdlFeed;
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

    function getDefaultUdlFeed() external view returns (address addr) {

        return address(defaultUdlFeed);
    }

    function setDefaultUdlFeed(address addr) external {

        ensureWritePriviledge();
        defaultUdlFeed = UnderlyingFeed(addr);
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

interface LiquidityPool {

    event AddSymbol(string indexed symbol);
    
    event RemoveSymbol(string indexed symbol);

    event Buy(string indexed symbol, uint price, uint volume, address token);
    
    event Sell(string indexed symbol, uint price, uint volume);

    function apy() external view returns (uint);

    function depositTokens(address to, address token, uint value) external;

    function listSymbols() external returns (string memory);

    function queryBuy(string calldata symbol) external view returns (uint price, uint volume);

    function querySell(string calldata symbol) external view returns (uint price, uint volume);

    function buy(string calldata symbol, uint price, uint volume, address token)
        external
        returns (address addr);

    function sell(string calldata symbol, uint price, uint volume) external;
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
import "../interfaces/TimeProvider.sol";
import "../interfaces/LiquidityPool.sol";
import "../interfaces/UnderlyingFeed.sol";
import "../utils/ERC20.sol";
import "../utils/MoreMath.sol";
import "../utils/SafeMath.sol";
import "../utils/SignedSafeMath.sol";

contract LinearLiquidityPool is LiquidityPool, ManagedContract, RedeemableToken {

    using SafeMath for uint;
    using SignedSafeMath for int;

    enum Operation { BUY, SELL }

    struct PricingParameters {
        address udlFeed;
        uint strike;
        uint maturity;
        OptionsExchange.OptionType optType;
        uint t0;
        uint t1;
        uint[] x;
        uint[] y;
        uint buyStock;
        uint sellStock;
    }

    TimeProvider private time;

    mapping(string => PricingParameters) private parameters;
    mapping(string => uint) private written;
    mapping(string => uint) private holding;

    address private owner;
    uint private spread;
    uint private reserveRatio;
    uint private maturity;

    uint private timeBase;
    uint private sqrtTimeBase;
    uint private volumeBase;
    uint private fractionBase;
    string[] private symbols;

    constructor(address deployer) public {

        Deployer(deployer).setContractAddress("LinearLiquidityPool");
    }

    function initialize(Deployer deployer) override internal {

        owner = deployer.getOwner();
        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        exchange = OptionsExchange(deployer.getContractAddress("OptionsExchange"));

        timeBase = 1e18;
        sqrtTimeBase = 1e9;
        volumeBase = exchange.getVolumeBase();
        fractionBase = 1e9;
    }

    function setParameters(
        uint _spread,
        uint _reserveRatio,
        uint _maturity
    )
        external
    {
        ensureCaller();
        spread = _spread;
        reserveRatio = _reserveRatio;
        maturity = _maturity;
    }

    function redeemAllowed() override public returns (bool) {
        
        return time.getNow() >= maturity;
    }

    function apy() override external view returns (uint) {

        return 0; // TODO: calculate pool APY
    }

    function addSymbol(
        string calldata symbol,
        address udlFeed,
        uint strike,
        uint _maturity,
        OptionsExchange.OptionType optType,
        uint t0,
        uint t1,
        uint[] calldata x,
        uint[] calldata y,
        uint buyStock,
        uint sellStock
    )
        external
    {
        ensureCaller();
        require(_maturity < maturity, "invalid maturity");
        require(x.length > 0 && x.length.mul(2) == y.length, "invalid pricing surface");

        if (parameters[symbol].x.length == 0) {
            symbols.push(symbol);
        }

        parameters[symbol] = PricingParameters(
            udlFeed,
            strike,
            _maturity,
            optType,
            t0,
            t1,
            x,
            y,
            buyStock,
            sellStock
        );

        emit AddSymbol(symbol);
    }
    
    function removeSymbol(string calldata symbol) external {

        ensureCaller();
        PricingParameters memory empty;
        parameters[symbol] = empty;
        delete written[symbol];
        delete holding[symbol];
        Arrays.removeItem(symbols, symbol);
        emit RemoveSymbol(symbol);
    }

    function depositTokens(address to, address token, uint value) override external {

        uint b0 = exchange.balanceOf(address(this));
        depositTokensInExchange(msg.sender, token, value);
        uint b1 = exchange.balanceOf(address(this));
        int expBal = exchange.calcExpectedPayout(address(this)).add(int(b1));

        uint ts = _totalSupply;
        uint p = b1.sub(b0).mul(fractionBase).div(uint(expBal));

        uint b = 1e3;
        uint v = ts > 0 ?
            ts.mul(p).mul(b).div(fractionBase.sub(p)) : 
            uint(expBal).mul(b);
        v = MoreMath.round(v, b);

        addBalance(to, v);
        _totalSupply = ts.add(v);
    }
    
    function listSymbols() override external returns (string memory available) {

        for (uint i = 0; i < symbols.length; i++) {
            if (parameters[symbols[i]].maturity > time.getNow()) {
                if (bytes(available).length == 0) {
                    available = symbols[i];
                } else {
                    available = string(abi.encodePacked(available, "\n", symbols[i]));
                }
            }
        }
    }

    function queryBuy(string memory symbol)
        override
        public
        view
        returns (uint price, uint volume)
    {
        ensureValidSymbol(symbol);
        PricingParameters memory param = parameters[symbol];
        price = calcOptPrice(param, Operation.BUY);
        volume = MoreMath.min(
            calcVolume(param, price, Operation.BUY),
            param.buyStock.sub(written[symbol])
        );
    }

    function querySell(string memory symbol)
        override
        public
        view
        returns (uint price, uint volume)
    {    
        ensureValidSymbol(symbol);
        PricingParameters memory param = parameters[symbol];
        price = calcOptPrice(param, Operation.SELL);
        volume = MoreMath.min(
            calcVolume(param, price, Operation.SELL),
            param.sellStock.sub(holding[symbol])
        );
    }

    function buy(string calldata symbol, uint price, uint volume, address token)
        override
        external
        returns (address addr)
    {
        ensureValidSymbol(symbol);

        PricingParameters memory param = parameters[symbol];
        uint p = calcOptPrice(param, Operation.BUY);
        require(price >= p, "insufficient price");

        uint value = p.mul(volume).div(volumeBase);
        depositTokensInExchange(msg.sender, token, value);

        uint _holding = holding[symbol];
        if (volume > _holding) {

            uint _written = written[symbol];
            uint toWrite = volume.sub(_holding);
            require(_written.add(toWrite) <= param.buyStock, "excessive volume");
            written[symbol] = _written.add(toWrite);

            exchange.writeOptions(
                param.udlFeed,
                toWrite,
                param.optType,
                param.strike,
                param.maturity
            );

            require(calcFreeBalance() > 0, "excessive volume");
        }

        if (_holding > 0) {
            uint diff = MoreMath.min(_holding, volume);
            holding[symbol] = _holding.sub(diff);
        }

        addr = exchange.resolveToken(symbol);
        OptionToken tk = OptionToken(addr);
        tk.transfer(msg.sender, volume);

        emit Buy(symbol, price, volume, token);
    }

    function sell(string calldata symbol, uint price, uint volume) override external {

        ensureValidSymbol(symbol);

        PricingParameters memory param = parameters[symbol];
        uint p = calcOptPrice(param, Operation.SELL);
        require(price <= p, "insufficient price");

        address addr = exchange.resolveToken(symbol);
        OptionToken tk = OptionToken(addr);
        tk.transferFrom(msg.sender, address(this), volume);

        uint value = p.mul(volume).div(volumeBase);
        exchange.transferBalance(msg.sender, value);
        require(calcFreeBalance() > 0, "excessive volume");
        
        uint _holding = holding[symbol].add(volume);
        uint _written = written[symbol];

        if (_written > 0) {
            uint toBurn = MoreMath.min(_written, volume);
            tk.burn(toBurn);
            written[symbol] = _written.sub(toBurn);
            _holding = _holding.sub(toBurn);
        }

        require(_holding <= param.sellStock, "excessive volume");
        holding[symbol] = _holding;

        emit Sell(symbol, price, volume);
    }

    function calcOptPrice(PricingParameters memory p, Operation op)
        private
        view
        returns (uint price)
    {
        uint f = op == Operation.BUY ? spread.add(fractionBase) : fractionBase.sub(spread);
        
        (uint j, uint xp) = findUdlPrice(p);

        uint _now = time.getNow();
        uint dt = p.t1.sub(p.t0);
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
                int(p.x[j].sub(p.x[j - 1]))
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

    function calcFreeBalance() private view returns (uint balance) {

        balance = exchange.balanceOf(address(this)).mul(reserveRatio).div(fractionBase);
        uint sp = exchange.calcSurplus(address(this));
        balance = sp > balance ? sp.sub(balance) : 0;
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

    function ensureValidSymbol(string memory symbol) private view {

        require(parameters[symbol].udlFeed !=  address(0), "invalid symbol");
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

import "../utils/SafeMath.sol";

contract ERC20 {

    using SafeMath for uint;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    uint _totalSupply;

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

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

        require(spender != address(0));

        allowed[msg.sender][spender] = value;
        emitApproval(msg.sender, spender, value);
        return true;
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