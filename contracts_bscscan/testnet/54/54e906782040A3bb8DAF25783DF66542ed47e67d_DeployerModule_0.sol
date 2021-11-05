// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../generics/HyperSonicGeneric.sol';

contract DeployerModule_0 is Ownable {
    function deployGeneric(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address owner_,
        address presaler
    ) public onlyOwner returns (address) {
        HyperSonicGeneric contr = new HyperSonicGeneric(name_, symbol_, decimals_, totalSupply_, owner_, presaler);
        return address(contr);
    }

    constructor(address controller) {
        transferOwnership(controller);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IWBNB is IBEP20 {
    function deposit() external payable;
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (IDEXFactory);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface ITokenConverter {
    function convertViaWETH(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) external view returns (uint256);

    function DEFAULT_FACTORY() external view returns (IDEXFactory);
}

abstract contract Auth {
    address public owner;
    mapping(address => bool) public isAuthorized;

    event OwnershipTransferred(address owner);
    event Authorization(address who, bool authorized);

    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(owner_);
        isAuthorized[owner_] = true;
        emit Authorization(owner_, true);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, '!OWNER');
        _;
    }
    modifier authorized() {
        require(isAuthorized[msg.sender], '!AUTHORIZED');
        _;
    }

    function authorize(address adr) external onlyOwner {
        isAuthorized[adr] = true;
        emit Authorization(adr, true);
    }

    function unauthorize(address adr) external onlyOwner {
        isAuthorized[adr] = false;
        emit Authorization(adr, false);
    }

    function setAuthorizationMultiple(address[] memory adr, bool value) external onlyOwner {
        for (uint256 i = 0; i < adr.length; i++) {
            isAuthorized[adr[i]] = value;
            emit Authorization(adr[i], value);
        }
    }

    function transferOwnership(address adr) external onlyOwner {
        isAuthorized[owner] = false;
        owner = adr;
        isAuthorized[adr] = true;
        emit OwnershipTransferred(adr);
    }
}

contract DividendDistributorGeneric {
    address public _token;
    IWBNB WBNB = IWBNB(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
    IBEP20 public dividendToken;
    IDEXRouter public router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 index;
        uint256 lastClaimed;
    }
    mapping(address => Share) public shares;
    address[] shareholders;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public _ACCURACY_ = 1e36;
    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 1e18;
    uint256 public shareThreshold = 0;

    uint256 public currentIndex;
    uint256 public maxGas = 500000;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(IBEP20 _dividendToken) {
        dividendToken = _dividendToken;
        _token = msg.sender;
    }

    function setRouter(IDEXRouter _router) external onlyToken {
        router = _router;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _shareThreshold
    ) external onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        shareThreshold = _shareThreshold;
    }

    function setMaxGas(uint256 gas) external onlyToken {
        maxGas = gas;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        Share storage _S = shares[shareholder];
        if (_S.amount > 0) {
            _sendDividend(shareholder);
            if (amount < shareThreshold) _removeShareholder(shareholder);
        } else if (amount >= shareThreshold) _addShareholder(shareholder);
        totalShares -= _S.amount;
        totalShares += amount;
        _S.amount = amount;
        _S.totalExcluded = _getCumulativeDividends(shareholder);
    }

    function deposit() external payable onlyToken {
        uint256 gotDividendToken = dividendToken.balanceOf(address(this));
        if (address(dividendToken) == address(WBNB)) {
            WBNB.deposit{value: msg.value}();
        } else {
            address[] memory path = new address[](2);
            path[0] = address(WBNB);
            path[1] = address(dividendToken);
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
            );
        }
        gotDividendToken = dividendToken.balanceOf(address(this)) - gotDividendToken;

        totalDividends += gotDividendToken;
        dividendsPerShare += (_ACCURACY_ * gotDividendToken) / totalShares;
    }

    function sendDividends() external onlyToken {
        uint256 shareholderCount = shareholders.length;
        if (shareholderCount == 0) return;

        uint256 gasUsed;
        uint256 gasLeft = gasleft();

        uint256 _currentIndex = currentIndex;
        for (uint256 i = 0; i < shareholderCount && gasUsed < maxGas; i++) {
            if (_currentIndex >= shareholderCount) _currentIndex = 0;
            address _shareholder = shareholders[_currentIndex];
            if (
                block.timestamp > shares[_shareholder].lastClaimed + minPeriod &&
                getUnpaidEarnings(_shareholder) > minDistribution
            ) {
                _sendDividend(_shareholder);
            }
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
            _currentIndex++;
        }
        currentIndex = _currentIndex;
    }

    function _getCumulativeDividends(address shareholder) internal view returns (uint256) {
        return (shares[shareholder].amount * dividendsPerShare) / _ACCURACY_;
    }

    function _sendDividend(address shareholder) internal {
        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount == 0) return;

        dividendToken.transfer(shareholder, amount);
        totalDistributed += amount;
        shares[shareholder].totalRealised += amount;
        shares[shareholder].totalExcluded = _getCumulativeDividends(shareholder);
        shares[shareholder].lastClaimed = block.timestamp;
    }

    function _addShareholder(address shareholder) internal {
        shares[shareholder].index = shareholders.length;
        shareholders.push(shareholder);
    }

    function _removeShareholder(address shareholder) internal {
        _sendDividend(shareholder);
        shareholders[shares[shareholder].index] = shareholders[shareholders.length - 1];
        shares[shareholders[shareholders.length - 1]].index = shares[shareholder].index;
        delete shares[shareholder];
        shareholders.pop();
    }

    function claimDividend() external {
        _sendDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        uint256 _dividends = _getCumulativeDividends(shareholder);
        uint256 _excluded = shares[shareholder].totalExcluded;
        return _dividends > _excluded ? _dividends - _excluded : 0;
    }
}

contract HyperSonicGeneric is Auth {
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    IDEXRouter public router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDividendExempt;

    mapping(address => bool) public isPair;
    mapping(address => bool) public isRouter;

    address public pair;
    DividendDistributorGeneric public distributor;

    uint256 public launchedAt;
    bool public tradingOpen;

    struct FeeSettings {
        uint256 liquidity;
        uint256 dividends;
        uint256 total;
        uint256 _burn;
        uint256 _denominator;
    }
    struct SwapbackSettings {
        bool enabled;
        uint256 amount;
    }

    FeeSettings public fees =
        FeeSettings({liquidity: 100, dividends: 300, total: 400, _burn: 100, _denominator: 10000});
    SwapbackSettings public swapback = SwapbackSettings({enabled: true, amount: totalSupply / 1000});

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event Swapback(uint256 amountBNB, uint256 amountTKN);
    event AutoLiquify(uint256 amountBNB, uint256 amountTKN);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, address owner_, address presaler) Auth(owner_) {
        // PANCAKE V1 ROUTER 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
        // PANCAKE V2 ROUTER 0x10ED43C718714eb63d5aA57B78B54704E256024E
        pair = router.factory().createPair(WBNB, address(this));
        allowance[address(this)][address(router)] = ~uint256(0);

        distributor = new DividendDistributorGeneric(IBEP20(WBNB));

        isFeeExempt[DEAD] = true;
        isFeeExempt[owner_] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(router)] = true;

        isDividendExempt[DEAD] = true;
        isDividendExempt[owner_] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(router)] = true;

        isDividendExempt[pair] = true;

        // Recommended: include used routers and pairs to avoid possible swap/swapback collisions
        // They are not fatal though
        isPair[pair] = true;
        isRouter[address(router)] = true;

        // Presale contract
        if (presaler != address(0)) {
            isAuthorized[presaler] = true;
            emit Authorization(presaler, true);
            isFeeExempt[presaler] = true;
            isDividendExempt[presaler] = true;
        }

        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        totalSupply = totalSupply_;
        balanceOf[owner_] = totalSupply;
        emit Transfer(address(0), owner_, totalSupply);
    }

    receive() external payable {}

    function getOwner() external view returns (address) {
        return owner;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        if (allowance[sender][msg.sender] != ~uint256(0)) allowance[sender][msg.sender] -= amount;
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) return _basicTransfer(sender, recipient, amount);
        if (!tradingOpen) require(isAuthorized[sender], 'Trading not open yet');

        // Sell accumulated fee for BNB and distribute
        bool _isTradingOperation = isPair[sender] ||
            isPair[recipient] ||
            isPair[msg.sender] ||
            isRouter[sender] ||
            isRouter[recipient] ||
            isRouter[msg.sender];
        if (swapback.enabled && (balanceOf[address(this)] >= swapback.amount) && !_isTradingOperation) {
            // (?swapback enabled?) Sells accumulated TKN fees for BNB
            _sellAndDistributeAccumulatedTKNFee();
        }

        // Launch at first liquidity
        if (launchedAt == 0 && isPair[recipient]) {
            require(balanceOf[sender] > 0);
            launchedAt = block.timestamp;
        }

        // Take fee; burn;
        // Exchange balances
        balanceOf[sender] -= amount;
        uint256 amountReceived = amount;
        if (!isFeeExempt[sender] && !isFeeExempt[recipient]) {
            if (fees.total > 0) {
                uint256 feeAmount = (amount * fees.total) / fees._denominator;
                balanceOf[address(this)] += feeAmount;
                emit Transfer(sender, address(this), feeAmount);
                amountReceived -= feeAmount;
            }
            if (fees._burn > 0) {
                uint256 burnAmount = (amount * fees._burn) / fees._denominator;
                balanceOf[DEAD] += burnAmount;
                emit Transfer(sender, DEAD, burnAmount);
                amountReceived -= burnAmount;
            }
        }
        balanceOf[recipient] += amountReceived;
        emit Transfer(sender, recipient, amountReceived);

        // Dividend tracker
        if (!isDividendExempt[sender]) try distributor.setShare(sender, balanceOf[sender]) {} catch {}
        if (!isDividendExempt[recipient]) try distributor.setShare(recipient, balanceOf[recipient]) {} catch {}
        try distributor.sendDividends() {} catch {}

        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _sellAndDistributeAccumulatedTKNFee() internal swapping {
        // Swap the fee taken above to BNB and distribute to liquidity and dividends;
        // Add some liquidity
        uint256 halfLiquidityFee = fees.liquidity / 2;
        uint256 TKNtoLiquidity = (swapback.amount * halfLiquidityFee) / fees.total;
        uint256 amountToSwap = swapback.amount - TKNtoLiquidity;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 gotBNB = address(this).balance;
        try
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            )
        {
            emit Swapback(address(this).balance - gotBNB, amountToSwap);
        } catch {
            emit Swapback(0, 0);
            return;
        }
        gotBNB = address(this).balance;

        uint256 totalBNBFee = fees.total - halfLiquidityFee;
        uint256 BNBtoLiquidity = (gotBNB * halfLiquidityFee) / totalBNBFee;
        uint256 BNBtoDividends = (gotBNB * fees.dividends) / totalBNBFee;

        try distributor.deposit{value: BNBtoDividends}() {} catch {}

        if (TKNtoLiquidity > 0) {
            router.addLiquidityETH{value: BNBtoLiquidity}(address(this), TKNtoLiquidity, 0, 0, owner, block.timestamp);
            emit AutoLiquify(BNBtoLiquidity, TKNtoLiquidity);
        }
    }

    function _sellBNB(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, to, block.timestamp);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply - balanceOf[DEAD] - balanceOf[ZERO];
    }

    // SET EXEMPTS

    function setIsFeeExempt(address[] memory holders, bool exempt) public onlyOwner {
        for (uint256 i = 0; i < holders.length; i++) {
            isFeeExempt[holders[i]] = exempt;
        }
    }

    function setIsDividendExempt(address[] memory holders, bool exempt) public onlyOwner {
        for (uint256 i = 0; i < holders.length; i++) {
            require(holders[i] != address(this) && !(isPair[holders[i]] && !exempt), 'forbidden address'); // Forbid including back token and pairs
            isDividendExempt[holders[i]] = exempt;
            distributor.setShare(holders[i], exempt ? 0 : balanceOf[holders[i]]);
        }
    }

    function setFullExempt(address[] memory holders, bool exempt) public onlyOwner {
        setIsFeeExempt(holders, exempt);
        setIsDividendExempt(holders, exempt);
    }

    function setIsPair(address[] memory addresses, bool isPair_) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            isPair[addresses[i]] = isPair_;
        }
        setIsDividendExempt(addresses, isPair_);
    }

    function setIsRouter(address[] memory addresses, bool isRouter_) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            isRouter[addresses[i]] = isRouter_;
        }
        setFullExempt(addresses, isRouter_);
    }

    // TOKEN SETTINGS

    function setFees(
        uint256 _liquidity,
        uint256 _dividends,
        uint256 _burn,
        uint256 _denominator
    ) external onlyOwner {
        fees = FeeSettings({
            liquidity: _liquidity,
            dividends: _dividends,
            total: _liquidity + _dividends,
            _burn: _burn,
            _denominator: _denominator
        });
        require(fees.total + _burn < fees._denominator / 4);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapback.enabled = _enabled;
        swapback.amount = _amount;
    }

    function setTradingStatus(bool _status) external onlyOwner {
        tradingOpen = _status;
    }

    // DISTRIBUTOR SETTINGS

    function deployNewDistributor(IBEP20 _dividendToken) external onlyOwner {
        distributor = new DividendDistributorGeneric(_dividendToken);
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _shareThreshold
    ) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution, _shareThreshold);
    }

    function setDistributorGas(uint256 gas) external onlyOwner {
        require(gas <= 750000, 'Max 750000 gas allowed');
        distributor.setMaxGas(gas);
    }

    // AIRDROP

    function airdrop(address[] memory addresses, uint256[] memory tokens) external onlyOwner {
        uint256 showerCapacity = 0;
        require(addresses.length == tokens.length, 'Mismatch between Address and token count');
        for (uint256 i = 0; i < addresses.length; i++) showerCapacity += tokens[i];
        require(balanceOf[msg.sender] >= showerCapacity, 'Not enough tokens to airdrop');
        for (uint256 i = 0; i < addresses.length; i++) _basicTransfer(msg.sender, addresses[i], tokens[i]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}