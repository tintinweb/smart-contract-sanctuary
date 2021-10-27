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
import "../utils/SafeERC20.sol";
import "../utils/SafeMath.sol";
import "../utils/SignedSafeMath.sol";
import "./CreditProvider.sol";
import "./OptionToken.sol";
import "./OptionTokenFactory.sol";
import "./UnderlyingVault.sol";

contract OptionsExchange is ManagedContract {

    using SafeCast for uint;
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using SignedSafeMath for int;
    
    enum OptionType { CALL, PUT }
    
    struct OptionData {
        address udlFeed;
        OptionType _type;
        uint120 strike;
        uint32 maturity;
    }

    struct FeedData {
        uint120 lowerVol;
        uint120 upperVol;
    }
    
    TimeProvider private time;
    ProtocolSettings private settings;
    CreditProvider private creditProvider;
    OptionTokenFactory private factory;
    UnderlyingVault private vault;

    mapping(address => uint) public collateral;
    mapping(address => OptionData) private options;
    mapping(address => FeedData) private feeds;
    mapping(address => address[]) private book;
    mapping(string => address) private tokenAddress;
    mapping(address => mapping(address => uint)) private allowed;
    
    uint public volumeBase;
    uint private timeBase;
    uint private sqrtTimeBase;

    event WithdrawTokens(address indexed from, uint value);

    event CreateSymbol(address indexed token, address indexed sender);

    event Approval(address indexed owner, address indexed spender, uint value);

    event WriteOptions(
        address indexed token,
        address indexed issuer,
        address indexed onwer,
        uint volume
    );

    event LiquidateEarly(
        address indexed token,
        address indexed sender,
        address indexed onwer,
        uint volume
    );

    event LiquidateExpired(
        address indexed token,
        address indexed sender,
        address indexed onwer,
        uint volume
    );

    function initialize(Deployer deployer) override internal {

        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        creditProvider = CreditProvider(deployer.getContractAddress("CreditProvider"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        factory = OptionTokenFactory(deployer.getContractAddress("OptionTokenFactory"));
        vault = UnderlyingVault(deployer.getContractAddress("UnderlyingVault"));

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
        IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
        depositTokens(to, token, value);
    }

    function depositTokens(address to, address token, uint value) public {

        IERC20 t = IERC20(token);
        t.safeTransferFrom(msg.sender, address(creditProvider), value);
        creditProvider.addBalance(to, token, value);
    }

    function balanceOf(address owner) external view returns (uint) {

        return creditProvider.balanceOf(owner);
    }

    function allowance(address owner, address spender) external view returns (uint) {

        return allowed[owner][spender];
    }

    function approve(address spender, uint value) external returns (bool) {

        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferBalance(
        address from, 
        address to, 
        uint value
    )
        external
    {
        uint allw = allowed[from][msg.sender];
        if (allw >= value) {
            allowed[from][msg.sender] = allw.sub(value);
        } else {
            creditProvider.ensureCaller(msg.sender);
        }
        creditProvider.transferBalance(from, to, value);
        ensureFunds(from);
    }

    function transferBalance(address to, uint value) public {

        creditProvider.transferBalance(msg.sender, to, value);
        ensureFunds(msg.sender);
    }

    function underlyingBalance(address owner, address _tk) external view returns (uint) {

        return vault.balanceOf(owner, _tk);
    }
    
    function withdrawTokens(uint value) external {
        
        require(value <= calcSurplus(msg.sender), "insufficient surplus");
        creditProvider.withdrawTokens(msg.sender, value);
        emit WithdrawTokens(msg.sender, value);
    }

    function createSymbol(
        address udlFeed,
        OptionType optType,
        uint strike, 
        uint maturity
    )
        public
        returns (address tk)
    {
        ensureFeedIsAlowed(udlFeed);

        (OptionData memory opt, string memory symbol) =
            createOptionInMemory(udlFeed, optType, strike, maturity);

        require(tokenAddress[symbol] == address(0), "already created");

        tk = factory.create(symbol, udlFeed);
        tokenAddress[symbol] = tk;
        options[tk] = opt;
        prefetchFeedData(udlFeed);

        emit CreateSymbol(tk, msg.sender);
    }

    function getOptionSymbol(
        address udlFeed,
        OptionType optType,
        uint strike, 
        uint maturity
    )
        public
        view
        returns (string memory symbol)
    {    
        symbol = string(abi.encodePacked(
            UnderlyingFeed(udlFeed).symbol(),
            "-",
            "E",
            optType == OptionType.CALL ? "C" : "P",
            "-",
            MoreMath.toString(strike),
            "-",
            MoreMath.toString(maturity)
        ));
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
        returns (address _tk)
    {
        (OptionData memory opt, string memory symbol) =
            createOptionInMemory(udlFeed, optType, strike, maturity);
        (_tk) = writeOptionsInternal(opt, symbol, volume, to);
        ensureFunds(msg.sender);
    }

    function writeCovered(
        address udlFeed,
        uint volume,
        uint strike, 
        uint maturity,
        address to
    )
        external 
        returns (address _tk)
    {
        (OptionData memory opt, string memory symbol) =
            createOptionInMemory(udlFeed, OptionType.CALL, strike, maturity);
        _tk = tokenAddress[symbol];

        if (_tk == address(0)) {
            _tk = createSymbol(opt.udlFeed, OptionType.CALL, strike, maturity);
        }
        
        address underlying = getUnderlyingAddr(opt);
        require(underlying != address(0), "underlying token not set");
        IERC20(underlying).safeTransferFrom(msg.sender, address(vault), volume);
        vault.lock(msg.sender, _tk, volume);

        writeOptionsInternal(opt, symbol, volume, to);
        ensureFunds(msg.sender);
    }
    
    function transferOwnership(
        string calldata symbol,
        address from,
        address to,
        uint value
    )
        external
    {
        require(tokenAddress[symbol] == msg.sender, "unauthorized ownership transfer");
        
        OptionToken tk = OptionToken(msg.sender);
        
        if (tk.writtenVolume(from) == 0 && tk.balanceOf(from) == 0) {
            Arrays.removeItem(book[from], msg.sender);
        }

        if (tk.writtenVolume(to) == 0 && tk.balanceOf(to) == value) {
            book[to].push(msg.sender);
        }

        ensureFunds(from);
    }

    function release(address owner, uint udl, uint coll) public {

        OptionToken tk = OptionToken(msg.sender);
        require(tokenAddress[tk.symbol()] == msg.sender, "unauthorized release");

        OptionData memory opt = options[msg.sender];

        if (udl > 0) {
            vault.release(owner,  msg.sender, opt.udlFeed, udl);
        }
        
        if (coll > 0) {
            uint c = collateral[owner];
            collateral[owner] = c.sub(
                MoreMath.min(c, calcCollateral(opt, coll))
            );
        }
    }

    function cleanUp(address owner, address _tk) public {

        OptionToken tk = OptionToken(_tk);

        if (tk.balanceOf(owner) == 0 && tk.writtenVolume(owner) == 0) {
            Arrays.removeItem(book[owner], _tk);
        }
    }

    function liquidateExpired(address _tk, address[] calldata owners) external {

        OptionData memory opt = options[_tk];
        OptionToken tk = OptionToken(_tk);
        require(getUdlNow(opt) >= opt.maturity, "option not expired");
        uint iv = uint(calcIntrinsicValue(opt));

        for (uint i = 0; i < owners.length; i++) {
            liquidateOptions(owners[i], opt, tk, true, iv);
        }
    }

    function liquidateOptions(address _tk, address owner) public returns (uint value) {
        
        OptionData memory opt = options[_tk];
        require(opt.udlFeed != address(0), "token not found");

        OptionToken tk = OptionToken(_tk);
        require(tk.writtenVolume(owner) > 0, "invalid token");

        bool isExpired = getUdlNow(opt) >= opt.maturity;
        uint iv = uint(calcIntrinsicValue(opt));
        
        value = liquidateOptions(owner, opt, tk, isExpired, iv);
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
        address[] memory _book = book[owner];

        for (uint i = 0; i < _book.length; i++) {

            address _tk = _book[i];
            OptionToken tk = OptionToken(_tk);
            OptionData memory opt = options[_tk];

            uint written = tk.uncoveredVolume(owner);
            uint holding = tk.balanceOf(owner);

            coll = coll.add(
                calcIntrinsicValue(opt).mul(
                    int(written).sub(int(holding))
                )
            ).add(int(calcCollateral(feeds[opt.udlFeed].upperVol, written, opt)));
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
        (OptionData memory opt,) = createOptionInMemory(udlFeed, optType, strike, maturity);
        return calcCollateral(opt, volume);
    }

    function calcExpectedPayout(address owner) external view returns (int payout) {

        address[] memory _book = book[owner];

        for (uint i = 0; i < _book.length; i++) {

            OptionToken tk = OptionToken(_book[i]);
            OptionData memory opt = options[_book[i]];

            uint written = tk.writtenVolume(owner);
            uint holding = tk.balanceOf(owner);

            payout = payout.add(
                calcIntrinsicValue(opt).mul(
                    int(holding).sub(int(written))
                )
            );
        }

        payout = payout.div(int(volumeBase));
    }
    
    function calcIntrinsicValue(address _tk) external view returns (int) {
        
        return calcIntrinsicValue(options[_tk]);
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
        (OptionData memory opt,) = createOptionInMemory(udlFeed, optType, strike, maturity);
        return calcIntrinsicValue(opt);
    }

    function getUnderlyingPrice(string calldata symbol) external view returns (int) {
        
        address _ts = tokenAddress[symbol];
        require(_ts != address(0), "token not found");
        return getUdlPrice(options[_ts]);
    }

    function resolveToken(string memory symbol) public view returns (address) {
        
        address addr = tokenAddress[symbol];
        require(addr != address(0), "token not found");
        return addr;
    }

    function prefetchFeedData(address udlFeed) public {
        
        feeds[udlFeed] = getFeedData(udlFeed);
    }

    function getBook(address owner)
        external view
        returns (
            string memory symbols,
            address[] memory tokens,
            uint[] memory holding,
            uint[] memory written,
            int[] memory iv
        )
    {
        tokens = book[owner];
        holding = new uint[](tokens.length);
        written = new uint[](tokens.length);
        iv = new int[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            OptionToken tk = OptionToken(tokens[i]);
            OptionData memory opt = options[tokens[i]];
            if (i == 0) {
                symbols = getOptionSymbol(opt);
            } else {
                symbols = string(abi.encodePacked(symbols, "\n", getOptionSymbol(opt)));
            }
            holding[i] = tk.balanceOf(owner);
            written[i] = tk.writtenVolume(owner);
            iv[i] = calcIntrinsicValue(opt);
        }
    }

    function ensureFunds(address owner) private view {
        
        require(
            creditProvider.balanceOf(owner) >= collateral[owner],
            "insufficient collateral"
        );
    }

    function createOptionInMemory(
        address udlFeed,
        OptionType optType,
        uint strike, 
        uint maturity
    )
        private
        view
        returns (OptionData memory opt, string memory symbol)
    {
        opt = OptionData(udlFeed, optType, strike.toUint120(), maturity.toUint32());
        symbol = getOptionSymbol(opt);
    }

    function writeOptionsInternal(
        OptionData memory opt,
        string memory symbol,
        uint volume,
        address to
    )
        private 
        returns (address _tk)
    {
        ensureFeedIsAlowed(opt.udlFeed);
        require(volume > 0, "invalid volume");
        require(opt.maturity > time.getNow(), "invalid maturity");

        _tk = tokenAddress[symbol];
        if (_tk == address(0)) {
            _tk = createSymbol(opt.udlFeed, opt._type, opt.strike, opt.maturity);
        }

        OptionToken tk = OptionToken(_tk);
        if (tk.writtenVolume(msg.sender) == 0 && tk.balanceOf(msg.sender) == 0) {
            book[msg.sender].push(_tk);
        }
        if (msg.sender != to && tk.writtenVolume(to) == 0 && tk.balanceOf(to) == 0) {
            book[to].push(_tk);
        }
        tk.issue(msg.sender, to, volume);

        if (options[_tk].udlFeed == address(0)) {
            options[_tk] = opt;
        }
        
        uint v = MoreMath.min(volume, tk.uncoveredVolume(msg.sender));
        if (v > 0) {
            collateral[msg.sender] = collateral[msg.sender].add(
                calcCollateral(opt, v)
            );
        }

        emit WriteOptions(_tk, msg.sender, to, volume);
    }

    function liquidateOptions(
        address owner,
        OptionData memory opt,
        OptionToken tk,
        bool isExpired,
        uint iv
    )
        private
        returns (uint value)
    {
        uint written = isExpired ?
            tk.writtenVolume(owner) :
            tk.uncoveredVolume(owner);
        iv = iv.mul(written);

        if (isExpired) {
            value = liquidateAfterMaturity(owner, tk, opt.udlFeed, written, iv);
            emit LiquidateExpired(address(tk), msg.sender, owner, written);
        } else {
            require(written > 0, "invalid volume");
            value = liquidateBeforeMaturity(owner, opt, tk, written, iv);
        }
    }

    function liquidateAfterMaturity(
        address owner,
        OptionToken tk,
        address feed,
        uint written,
        uint iv
    )
        private
        returns (uint value)
    {
        if (iv > 0) {
            value = iv.div(volumeBase);
            vault.liquidate(owner, address(tk), feed, value);
            creditProvider.processPayment(owner, address(tk), value);
        }

        vault.release(owner, address(tk), feed, uint(-1));

        if (written > 0) {
            tk.burn(owner, written);
        }
    }

    function liquidateBeforeMaturity(
        address owner,
        OptionData memory opt,
        OptionToken tk,
        uint written,
        uint iv
    )
        private
        returns (uint value)
    {
        FeedData memory fd = feeds[opt.udlFeed];

        uint volume = calcLiquidationVolume(owner, opt, fd, written);
        value = calcLiquidationValue(opt, fd.lowerVol, written, volume, iv)
            .div(volumeBase);
        creditProvider.processPayment(owner, address(tk), value);

        if (volume > 0) {
            tk.burn(owner, volume);
        }

        emit LiquidateEarly(address(tk), msg.sender, owner, volume);
    }

    function calcLiquidationVolume(
        address owner,
        OptionData memory opt,
        FeedData memory fd,
        uint written
    )
        private
        view
        returns (uint volume)
    {    
        uint bal = creditProvider.balanceOf(owner);
        uint coll = calcCollateral(owner);
        require(coll > bal, "unfit for liquidation");

        volume = coll.sub(bal).mul(volumeBase).mul(written).div(
            calcCollateral(
                uint(fd.upperVol).sub(uint(fd.lowerVol)),
                written,
                opt
            )
        );

        volume = MoreMath.min(volume, written);
    }

    function calcLiquidationValue(
        OptionData memory opt,
        uint vol,
        uint written,
        uint volume,
        uint iv
    )
        private
        view
        returns (uint value)
    {    
        value = calcCollateral(vol, written, opt).add(iv).mul(volume).div(written);
    }

    function getFeedData(address udlFeed) private view returns (FeedData memory fd) {
        
        UnderlyingFeed feed = UnderlyingFeed(udlFeed);

        uint vol = feed.getDailyVolatility(settings.getVolatilityPeriod());

        fd = FeedData(
            feed.calcLowerVolatility(uint(vol)).toUint120(),
            feed.calcUpperVolatility(uint(vol)).toUint120()
        );
    }

    function getOptionSymbol(OptionData memory opt) private view returns (string memory symbol) {    

        symbol = getOptionSymbol(
            opt.udlFeed,
            opt._type,
            opt.strike,
            opt.maturity
        );
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

        if (opt._type == OptionType.PUT) {
            int max = int(uint(opt.strike).mul(volume).div(volumeBase));
            coll = MoreMath.min(coll, max);
        }

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

    function getUnderlyingAddr(OptionData memory opt) private view returns (address) {
        
        return UnderlyingFeed(opt.udlFeed).getUnderlyingAddr();
    }

    function getUdlNow(OptionData memory opt) private view returns (uint timestamp) {

        (timestamp,) = UnderlyingFeed(opt.udlFeed).getLatestPrice();
    }

    function ensureFeedIsAlowed(address udlFeed) private view {
        
        require(settings.getUdlFeed(udlFeed) > 0, "feed not allowed");
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

pragma solidity >=0.6.0;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./SignedSafeMath.sol";

library MoreMath {

    using SafeMath for uint;
    using SignedSafeMath for int;

    // rounds "v" considering a base "b"
    function round(uint v, uint b) internal pure returns (uint) {

        return v.div(b).add((v % b) >= b.div(2) ? 1 : 0);
    }

    // calculates {[(n/d)^e]*f}
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

    // calculates (n^e)
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

    // calculates {n^(e/b)}
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
    
    // calculates ceil(n/d)
    function divCeil(uint n, uint d) internal pure returns (uint v) {
        
        v = n.div(d);
        if (n.mod(d) > 0) {
            v = v.add(1);
        }
    }
    
    // calculates the square root of "x" and multiplies it by "f"
    function sqrtAndMultiply(uint x, uint f) internal pure returns (uint y) {
    
        y = sqrt(x.mul(1e18)).mul(f).div(1e9);
    }
    
    // calculates the square root of "x"
    function sqrt(uint x) internal pure returns (uint y) {
    
        uint z = (x.div(2)).add(1);
        y = x;
        while (z < y) {
            y = z;
            z = (x.div(z).add(z)).div(2);
        }
    }

    // calculates the standard deviation
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

pragma solidity >=0.6.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Details.sol";
import "../interfaces/IERC20Permit.sol";
import "../utils/SafeMath.sol";

abstract contract ERC20 is IERC20, IERC20Details, IERC20Permit {

    using SafeMath for uint;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    uint _totalSupply;

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

    function decimals() override virtual external view returns (uint8) {
        return 18;
    }

    function totalSupply() override public view returns (uint) {

        return _totalSupply;
    }

    function balanceOf(address owner) override virtual public view returns (uint) {

        return balances[owner];
    }

    function allowance(address owner, address spender) override public view returns (uint) {

        return allowed[owner][spender];
    }

    function transfer(address to, uint value) override external returns (bool) {

        require(value <= balanceOf(msg.sender));
        require(to != address(0));

        removeBalance(msg.sender, value);
        addBalance(to, value);
        emitTransfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) override external returns (bool) {

        return approve(msg.sender, spender, value);
    }

    function transferFrom(address from, address to, uint value) override public returns (bool) {

        require(value <= balanceOf(from));
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));

        removeBalance(from, value);
        addBalance(to, value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emitTransfer(from, to, value);
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
        override
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call.value(amount)(bytes(""));
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call.value(value)(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity >=0.6.0;

interface UnderlyingFeed {

    function symbol() external view returns (string memory);

    function getUnderlyingAddr() external view returns (address);

    function getLatestPrice() external view returns (uint timestamp, int price);

    function getPrice(uint position) external view returns (uint timestamp, int price);

    function getDailyVolatility(uint timespan) external view returns (uint vol);

    function calcLowerVolatility(uint vol) external view returns (uint lowerVol);

    function calcUpperVolatility(uint vol) external view returns (uint upperVol);
}

pragma solidity >=0.6.0;

interface TimeProvider {

    function getNow() external view returns (uint);

}

pragma solidity >=0.6.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

interface IERC20Permit {

    function permit(
        address owner, 
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity >=0.6.0;

interface IERC20Details {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.6.0;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../finance/CreditProvider.sol";
import "../interfaces/TimeProvider.sol";
import "../utils/Arrays.sol";
import "../utils/MoreMath.sol";
import "../utils/SafeMath.sol";
import "./GovToken.sol";
import "./ProposalsManager.sol";
import "./ProposalWrapper.sol";

contract ProtocolSettings is ManagedContract {

    using SafeMath for uint;

    struct Rate {
        uint value;
        uint base;
        uint date;
    }

    TimeProvider private time;
    CreditProvider private creditProvider;
    ProposalsManager private manager;
    GovToken private govToken;

    mapping(address => int) private underlyingFeeds;
    mapping(address => Rate) private tokenRates;
    mapping(address => mapping(address => address[])) private paths;

    address[] private tokens;

    Rate[] private debtInterestRates;
    Rate[] private creditInterestRates;
    Rate private processingFee;
    uint private volatilityPeriod;

    bool private hotVoting;
    Rate private minShareForProposal;
    uint private circulatingSupply;

    address private swapRouter;
    address private swapToken;
    Rate private swapTolerance;

    uint private MAX_SUPPLY;
    uint private MAX_UINT;

    event SetCirculatingSupply(address sender, uint supply);
    event SetTokenRate(address sender, address token, uint v, uint b);
    event SetAllowedToken(address sender, address token, uint v, uint b);
    event SetMinShareForProposal(address sender, uint s, uint b);
    event SetDebtInterestRate(address sender, uint i, uint b);
    event SetCreditInterestRate(address sender, uint i, uint b);
    event SetProcessingFee(address sender, uint f, uint b);
    event SetUdlFeed(address sender, address addr, int v);
    event SetVolatilityPeriod(address sender, uint _volatilityPeriod);
    event SetSwapRouterInfo(address sender, address router, address token);
    event SetSwapRouterTolerance(address sender, uint r, uint b);
    event SetSwapPath(address sender, address from, address to);
    event TransferBalance(address sender, address to, uint amount);
    event TransferGovToken(address sender, address to, uint amount);
    
    constructor(bool _hotVoting) public {
        
        hotVoting = _hotVoting;
    }
    
    function initialize(Deployer deployer) override internal {

        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        creditProvider = CreditProvider(deployer.getContractAddress("CreditProvider"));
        manager = ProposalsManager(deployer.getContractAddress("ProposalsManager"));
        govToken = GovToken(deployer.getContractAddress("GovToken"));

        MAX_UINT = uint(-1);

        MAX_SUPPLY = 100e6 * 1e18;

        hotVoting = ProtocolSettings(getImplementation()).isHotVotingAllowed();

        circulatingSupply = 23e6 * 1e18;

        minShareForProposal = Rate( // 2.5%
            250,
            10000, 
            MAX_UINT
        );

        debtInterestRates.push(Rate( // 50% per year
            10000469299331318, 
            10000000000000000, 
            MAX_UINT
        ));

        creditInterestRates.push(Rate( // 15% per year
            10000161762815725, 
            10000000000000000,
            MAX_UINT
        ));

        processingFee = Rate( // 0.5%
            50,
            10000,
            MAX_UINT
        );

        volatilityPeriod = 90 days;
    }

    function getCirculatingSupply() external view returns (uint) {

        return circulatingSupply;
    }

    function setCirculatingSupply(uint supply) external {

        require(supply > circulatingSupply, "cannot decrease supply");
        require(supply <= MAX_SUPPLY, "max supply surpassed");

        ensureWritePrivilege();
        circulatingSupply = supply;

        emit SetCirculatingSupply(msg.sender, supply);
    }

    function getTokenRate(address token) external view returns (uint v, uint b) {

        v = tokenRates[token].value;
        b = tokenRates[token].base;
    }

    function setTokenRate(address token, uint v, uint b) external {

        require(v != 0 && b != 0, "invalid parameters");
        ensureWritePrivilege();
        tokenRates[token] = Rate(v, b, MAX_UINT);

        emit SetTokenRate(msg.sender, token, v, b);
    }

    function getAllowedTokens() external view returns (address[] memory) {

        return tokens;
    }

    function setAllowedToken(address token, uint v, uint b) external {

        require(token != address(0), "invalid token address");
        require(v != 0 && b != 0, "invalid parameters");
        ensureWritePrivilege();
        if (tokenRates[token].value != 0) {
            Arrays.removeItem(tokens, token);
        }
        tokens.push(token);
        tokenRates[token] = Rate(v, b, MAX_UINT);

        emit SetAllowedToken(msg.sender, token, v, b);
    }

    function isHotVotingAllowed() external view returns (bool) {

        // IMPORTANT: hot voting should be set to 'false' for mainnet deployment
        return hotVoting;
    }

    function suppressHotVoting() external {

        // no need to ensure write privilege. can't be undone.
        hotVoting = false;
    }

    function getMinShareForProposal() external view returns (uint v, uint b) {
        
        v = minShareForProposal.value;
        b = minShareForProposal.base;
    }

    function setMinShareForProposal(uint s, uint b) external {
        
        require(b / s <= 100, "minimum share too low");
        validateFractionLTEOne(s, b);
        ensureWritePrivilege();
        minShareForProposal = Rate(s, b, MAX_UINT);

        emit SetMinShareForProposal(msg.sender, s, b);
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
        
        validateFractionGTEOne(i, b);
        ensureWritePrivilege();
        debtInterestRates[debtInterestRates.length - 1].date = time.getNow();
        debtInterestRates.push(Rate(i, b, MAX_UINT));

        emit SetDebtInterestRate(msg.sender, i, b);
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
        
        validateFractionGTEOne(i, b);
        ensureWritePrivilege();
        creditInterestRates[creditInterestRates.length - 1].date = time.getNow();
        creditInterestRates.push(Rate(i, b, MAX_UINT));

        emit SetCreditInterestRate(msg.sender, i, b);
    }

    function getProcessingFee() external view returns (uint v, uint b) {
        
        v = processingFee.value;
        b = processingFee.base;
    }

    function setProcessingFee(uint f, uint b) external {
        
        validateFractionLTEOne(f, b);
        ensureWritePrivilege();
        processingFee = Rate(f, b, MAX_UINT);

        emit SetProcessingFee(msg.sender, f, b);
    }

    function getUdlFeed(address addr) external view returns (int) {

        return underlyingFeeds[addr];
    }

    function setUdlFeed(address addr, int v) external {

        require(addr != address(0), "invalid feed address");
        ensureWritePrivilege();
        underlyingFeeds[addr] = v;

        emit SetUdlFeed(msg.sender, addr, v);
    }

    function setVolatilityPeriod(uint _volatilityPeriod) external {

        require(
            _volatilityPeriod > 30 days && _volatilityPeriod < 720 days,
            "invalid volatility period"
        );
        ensureWritePrivilege();
        volatilityPeriod = _volatilityPeriod;

        emit SetVolatilityPeriod(msg.sender, _volatilityPeriod);
    }

    function getVolatilityPeriod() external view returns(uint) {

        return volatilityPeriod;
    }

    function setSwapRouterInfo(address router, address token) external {
        
        require(router != address(0), "invalid router address");
        ensureWritePrivilege();
        swapRouter = router;
        swapToken = token;

        emit SetSwapRouterInfo(msg.sender, router, token);
    }

    function getSwapRouterInfo() external view returns (address router, address token) {

        router = swapRouter;
        token = swapToken;
    }

    function setSwapRouterTolerance(uint r, uint b) external {

        validateFractionGTEOne(r, b);
        ensureWritePrivilege();
        swapTolerance = Rate(r, b, MAX_UINT);

        emit SetSwapRouterTolerance(msg.sender, r, b);
    }

    function getSwapRouterTolerance() external view returns (uint r, uint b) {

        r = swapTolerance.value;
        b = swapTolerance.base;
    }

    function setSwapPath(address from, address to, address[] calldata path) external {

        require(from != address(0), "invalid 'from' address");
        require(to != address(0), "invalid 'to' address");
        require(path.length >= 2, "invalid swap path");
        ensureWritePrivilege();
        paths[from][to] = path;

        emit SetSwapPath(msg.sender, from, to);
    }

    function getSwapPath(address from, address to) external view returns (address[] memory path) {

        path = paths[from][to];
        if (path.length == 0) {
            path = new address[](2);
            path[0] = from;
            path[1] = to;
        }
    }

    function transferBalance(address to, uint amount) external {
        
        uint total = creditProvider.totalTokenStock();
        require(total >= amount, "excessive amount");
        
        ensureWritePrivilege(true);

        creditProvider.transferBalance(address(this), to, amount);

        emit TransferBalance(msg.sender, to, amount);
    }

    function transferGovTokens(address to, uint amount) external {
        
        ensureWritePrivilege(true);

        govToken.transfer(to, amount);

        emit TransferGovToken(msg.sender, to, amount);
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

    function ensureWritePrivilege() private view {

        ensureWritePrivilege(false);
    }

    function ensureWritePrivilege(bool enforceProposal) private view {

        if (msg.sender != getOwner() || enforceProposal) {

            ProposalWrapper w = ProposalWrapper(manager.resolve(msg.sender));
            require(manager.isRegisteredProposal(msg.sender), "proposal not registered");
            require(w.isExecutionAllowed(), "execution not allowed");
        }
    }

    function validateFractionLTEOne(uint n, uint d) private pure {

        require(d > 0 && d >= n, "fraction should be less then or equal to one");
    }

    function validateFractionGTEOne(uint n, uint d) private pure {

        require(d > 0 && n >= d, "fraction should be greater than or equal to one");
    }
}

pragma solidity >=0.6.0;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../interfaces/TimeProvider.sol";
import "../utils/Arrays.sol";
import "../utils/SafeMath.sol";
import "./ProposalWrapper.sol";
import "./ProtocolSettings.sol";
import "./GovToken.sol";

contract ProposalsManager is ManagedContract {

    using SafeMath for uint;

    TimeProvider private time;
    ProtocolSettings private settings;
    GovToken private govToken;

    mapping(address => uint) private proposingDate;
    mapping(address => address) private wrapper;
    
    uint private serial;
    address[] private proposals;

    event RegisterProposal(
        address indexed wrapper,
        address indexed addr,
        ProposalWrapper.Quorum quorum,
        uint expiresAt
    );
    
    function initialize(Deployer deployer) override internal {

        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        govToken = GovToken(deployer.getContractAddress("GovToken"));
        serial = 1;
    }

    function registerProposal(
        address addr,
        ProposalWrapper.Quorum quorum,
        uint expiresAt
    )
        public
        returns (uint id, address wp)
    {    
        require(
            proposingDate[msg.sender] == 0 || time.getNow().sub(proposingDate[msg.sender]) > 1 days,
            "minimum interval between proposals not met"
        );
        
        (uint v, uint b) = settings.getMinShareForProposal();
        require(govToken.calcShare(msg.sender, b) >= v, "insufficient share");

        ProposalWrapper w = new ProposalWrapper(
            addr,
            address(time), 
            address(govToken),
            address(this),
            address(settings),
            quorum,
            expiresAt
        );

        proposingDate[msg.sender] = time.getNow();
        id = serial++;
        w.open(id);
        wp = address(w);
        proposals.push(wp);
        wrapper[addr] = wp;

        emit RegisterProposal(wp, addr, quorum, expiresAt);
    }

    function isRegisteredProposal(address addr) public view returns (bool) {
        
        address wp = wrapper[addr];
        if (wp == address(0)) {
            return false;
        }
        
        ProposalWrapper w = ProposalWrapper(wp);
        return w.implementation() == addr;
    }

    function resolve(address addr) public view returns (address) {

        return wrapper[addr];
    }

    function update(address from, address to, uint value) public {

        require(msg.sender == address(govToken), "invalid sender");

        for (uint i = 0; i < proposals.length; i++) {
            ProposalWrapper w = ProposalWrapper(proposals[i]);
            if (!w.isActive()) {
                Arrays.removeAtIndex(proposals, i);
                i--;
            } else {
                w.update(from, to, value);
            }
        }
    }
}

pragma solidity >=0.6.0;

import "../interfaces/TimeProvider.sol";
import "../utils/MoreMath.sol";
import "../utils/SafeMath.sol";
import "./GovToken.sol";
import "./Proposal.sol";
import "./ProposalsManager.sol";
import "./ProtocolSettings.sol";

contract ProposalWrapper {

    using SafeMath for uint;

    enum Quorum { SIMPLE_MAJORITY, TWO_THIRDS }

    enum Status { PENDING, OPEN, APPROVED, REJECTED }

    TimeProvider private time;
    GovToken private govToken;
    ProposalsManager private manager;
    ProtocolSettings private settings;

    mapping(address => int) private votes;

    address public implementation;
    
    uint private id;
    uint private yea;
    uint private nay;
    Quorum private quorum;
    Status private status;
    uint private expiresAt;
    bool private closed;

    constructor(
        address _implementation,
        address _time,
        address _govToken,
        address _manager,
        address _settings,
        Quorum _quorum,
        uint _expiresAt
    )
        public
    {
        implementation = _implementation;
        time = TimeProvider(_time);
        govToken = GovToken(_govToken);
        manager = ProposalsManager(_manager);
        settings = ProtocolSettings(_settings);
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

    function isActive() public view returns (bool) {

        return
            !closed &&
            status == Status.OPEN &&
            expiresAt > time.getNow();
    }

    function isClosed() public view returns (bool) {

        return closed;
    }

    function open(uint _id) public {

        require(msg.sender == address(manager), "invalid sender");
        require(status == Status.PENDING, "invalid status");
        id = _id;
        status = Status.OPEN;
    }

    function castVote(bool support) public {
        
        ensureIsActive();
        require(votes[msg.sender] == 0, "already voted");
        
        uint balance = govToken.delegateBalanceOf(msg.sender);
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

        govToken.enforceHotVotingSetting();

        uint total = settings.getCirculatingSupply();

        uint v;
        if (quorum == ProposalWrapper.Quorum.SIMPLE_MAJORITY) {
            v = total.div(2);
        } else if (quorum == ProposalWrapper.Quorum.TWO_THIRDS) {
            v = total.mul(2).div(3);
        } else {
            revert("quorum not set");
        }

        if (yea > v) {
            status = Status.APPROVED;
            Proposal(implementation).execute(settings);
        } else if (nay >= v) {
            status = Status.REJECTED;
        } else {
            revert("quorum not reached");
        }

        closed = true;
    }

    function ensureIsActive() private view {

        require(isActive(), "ProposalWrapper not active");
    }

    function update(address voter, int diff) private {
        
        if (votes[voter] != 0 && isActive()) {
            require(msg.sender == address(manager), "invalid sender");

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

import "./ProtocolSettings.sol";

abstract contract Proposal {

    function getName() public virtual view returns (string memory);

    function execute(ProtocolSettings _settings) public virtual;
}

pragma solidity >=0.6.0;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../interfaces/TimeProvider.sol";
import "../utils/ERC20.sol";
import "../utils/Arrays.sol";
import "../utils/SafeMath.sol";
import "./ProposalsManager.sol";
import "./ProtocolSettings.sol";

contract GovToken is ManagedContract, ERC20 {

    using SafeMath for uint;

    TimeProvider private time;
    ProtocolSettings private settings;
    ProposalsManager private manager;
    
    mapping(address => uint) private transferBlock;
    mapping(address => address) private delegation;
    mapping(address => uint) private delegated;

    address public childChainManagerProxy;

    string private constant _name = "Governance Token";
    string private constant _symbol = "GOVTK";

    event DelegateTo(
        address indexed owner,
        address indexed oldDelegate,
        address indexed newDelegate,
        uint bal
    );

    constructor(address _childChainManagerProxy) ERC20(_name) public {

        childChainManagerProxy = _childChainManagerProxy;
    }
    
    function initialize(Deployer deployer) override internal {

        DOMAIN_SEPARATOR = ERC20(getImplementation()).DOMAIN_SEPARATOR();
        childChainManagerProxy = GovToken(getImplementation()).childChainManagerProxy();

        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        manager = ProposalsManager(deployer.getContractAddress("ProposalsManager"));
    }

    function name() override external view returns (string memory) {
        return _name;
    }

    function symbol() override external view returns (string memory) {
        return _symbol;
    }
    
    function setChildChainManager(address _childChainManagerProxy) external {

        require(childChainManagerProxy == address(0), "childChainManagerProxy already set");
        childChainManagerProxy = _childChainManagerProxy;
    }

    function deposit(
        address user,
        bytes calldata depositData
    )
        external
    {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        _totalSupply = _totalSupply.add(amount);
        addBalance(user, amount);
        emitTransfer(address(0), user, amount);
    }

    function withdraw(uint256 amount) external {

        removeBalance(msg.sender, amount);
        _totalSupply = _totalSupply.sub(amount);
        emitTransfer(msg.sender, address(0), amount);
    }

    function delegateBalanceOf(address delegate) external view returns (uint) {

        return delegated[delegate];
    }

    function delegateTo(address newDelegate) public {

        address oldDelegate = delegation[msg.sender];

        require(newDelegate != address(0), "invalid delegate address");

        enforceHotVotingSetting();

        uint bal = balanceOf(msg.sender);

        if (oldDelegate != address(0)) {
            delegated[oldDelegate] = delegated[oldDelegate].sub(bal);
        }

        delegated[newDelegate] = delegated[newDelegate].add(bal);
        delegation[msg.sender] = newDelegate;

        emit DelegateTo(msg.sender, oldDelegate, newDelegate, bal);
    }

    function enforceHotVotingSetting() public view {

        require(
            settings.isHotVotingAllowed() ||
            transferBlock[tx.origin] != block.number,
            "delegation not allowed"
        );
    }

    function calcShare(address owner, uint base) public view returns (uint) {

        return delegated[owner].mul(base).div(settings.getCirculatingSupply());
    }

    function emitTransfer(address from, address to, uint value) override internal {

        transferBlock[tx.origin] = block.number;

        address fromDelegate = delegation[from];
        address toDelegate = delegation[to];

        manager.update(fromDelegate, toDelegate, value);

        if (fromDelegate != address(0)) {
            delegated[fromDelegate] = delegated[fromDelegate].sub(value);
        }

        if (toDelegate != address(0)) {
            delegated[toDelegate] = delegated[toDelegate].add(value);
        }

        emit Transfer(from, to, value);
    }
}

pragma solidity >=0.6.0;

import "../deployment/ManagedContract.sol";
import "../governance/ProtocolSettings.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/TimeProvider.sol";
import "../interfaces/UnderlyingFeed.sol";
import "../utils/MoreMath.sol";
import "../utils/SafeERC20.sol";
import "../utils/SafeMath.sol";
import "../utils/SignedSafeMath.sol";
import "./CreditProvider.sol";

contract UnderlyingVault is ManagedContract {

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using SignedSafeMath for int;

    TimeProvider private time;
    ProtocolSettings private settings;
    CreditProvider private creditProvider;
    
    mapping(address => uint) private callers;
    mapping(address => mapping(address => uint)) private allocation;

    event Lock(address indexed owner, address indexed token, uint value);

    event Liquidate(address indexed owner, address indexed token, uint valueIn, uint valueOut);

    event Release(address indexed owner, address indexed token, uint value);

    function initialize(Deployer deployer) override internal {

        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        creditProvider = CreditProvider(deployer.getContractAddress("CreditProvider"));
        
        callers[deployer.getContractAddress("OptionsExchange")] = 1;
    }

    function balanceOf(address owner, address token) public view returns (uint) {

        return allocation[owner][token];
    }

    function lock(address owner, address token, uint value) external {

        ensureCaller();
        
        require(owner != address(0), "invalid owner");
        require(token != address(0), "invalid token");

        allocation[owner][token] = allocation[owner][token].add(value);
        emit Lock(owner, token, value);
    }

    function liquidate(
        address owner,
        address token,
        address feed,
        uint amountOut
    )
        external
        returns (uint _in, uint _out)
    {
        ensureCaller();
        
        require(owner != address(0), "invalid owner");
        require(token != address(0), "invalid token");
        require(feed != address(0), "invalid feed");

        uint balance = balanceOf(owner, token);

        if (balance > 0) {

            (address _router, address _stablecoin) = settings.getSwapRouterInfo();
            require(
                _router != address(0) && _stablecoin != address(0),
                "invalid swap router settings"
            );

            IUniswapV2Router01 router = IUniswapV2Router01(_router);
            (, int p) = UnderlyingFeed(feed).getLatestPrice();

            address[] memory path = settings.getSwapPath(
                UnderlyingFeed(feed).getUnderlyingAddr(),
                _stablecoin
            );

            (_in, _out) = swapUnderlyingForStablecoin(
                owner,
                router,
                path,
                p,
                balance,
                amountOut
            );

            allocation[owner][token] = allocation[owner][token].sub(_in);
            emit Liquidate(owner, token, _in, _out);
        }
    }

    function release(address owner, address token, address feed, uint value) external {
        
        ensureCaller();
        
        require(owner != address(0), "invalid owner");
        require(token != address(0), "invalid token");
        require(feed != address(0), "invalid feed");

        uint bal = allocation[owner][token];
        value = MoreMath.min(bal, value);

        if (bal > 0) {
            address underlying = UnderlyingFeed(feed).getUnderlyingAddr();
            allocation[owner][token] = bal.sub(value);
            IERC20(underlying).safeTransfer(owner, value);
            emit Release(owner, token, value);
        }
    }

    function swapUnderlyingForStablecoin(
        address owner,
        IUniswapV2Router01 router,
        address[] memory path,
        int price,
        uint balance,
        uint amountOut
    )
        private
        returns (uint _in, uint _out)
    {
        require(path.length >= 2, "invalid swap path");
        
        uint amountInMax = getAmountInMax(
            price,
            amountOut,
            path
        );

        if (amountInMax > balance) {
            amountOut = amountOut.mul(balance).div(amountInMax);
            amountInMax = balance;
        }

        (uint r, uint b) = settings.getTokenRate(path[path.length - 1]);
        IERC20(path[0]).safeApprove(address(router), amountInMax);

        _out = amountOut;
        _in = router.swapTokensForExactTokens(
            amountOut.mul(r).div(b),
            amountInMax,
            path,
            address(creditProvider),
            time.getNow()
        )[0];

        if (amountOut > 0) {
            creditProvider.addBalance(owner, path[path.length - 1], amountOut.mul(r).div(b));
        }
    }

    function getAmountInMax(
        int price,
        uint amountOut,
        address[] memory path
    )
        private
        view
        returns (uint amountInMax)
    {
        uint8 d = IERC20Details(path[0]).decimals();
        amountInMax = amountOut.mul(10 ** uint(d)).div(uint(price));
        
        (uint rTol, uint bTol) = settings.getSwapRouterTolerance();
        amountInMax = amountInMax.mul(rTol).div(bTol);
    }

    function ensureCaller() private view {
        
        require(callers[msg.sender] == 1, "unauthorized caller");
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

    function redeemAllowed() virtual public view returns(bool);

    function redeem(address owner) external returns (uint value) {

        address[] memory owners = new address[](1);
        owners[0] = owner;
        value = redeem(owners);
    }

    function redeem(address[] memory owners) public returns (uint value) {

        require(redeemAllowed(), "redeem not allowed");

        uint valTotal = exchange.balanceOf(address(this));
        uint supplyTotal = _totalSupply;
        uint supplyRemaining = _totalSupply;
        
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] != address(0)) {
                (uint bal, uint val) = redeem(valTotal, supplyTotal, owners[i]);
                value = value.add(val);
                supplyRemaining = supplyRemaining.sub(bal);
            }
        }

        _totalSupply = supplyRemaining;
    }

    function redeem(uint valTotal, uint supplyTotal, address owner) 
        private
        returns (uint bal, uint val)
    {
        bal = balanceOf(owner);
        
        if (bal > 0) {
            uint b = 1e3;
            val = MoreMath.round(valTotal.mul(bal.mul(b)).div(supplyTotal), b);
            removeBalance(owner, bal);
            exchange.transferBalance(owner, val);
        }

        afterRedeem(owner, bal, val);
    }

    function afterRedeem(address owner, uint bal, uint val) virtual internal {

    }
}

pragma solidity >=0.6.0;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../interfaces/UnderlyingFeed.sol";
import "./OptionToken.sol";

contract OptionTokenFactory is ManagedContract {

    function initialize(Deployer deployer) override internal {

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

import "../finance/OptionsExchange.sol";
import "../finance/RedeemableToken.sol";
import "../utils/ERC20.sol";
import "../utils/Arrays.sol";
import "../utils/SafeMath.sol";

contract OptionToken is RedeemableToken {

    using SafeMath for uint;

    mapping(address => uint) private _issued;

    string private constant _prefix = "Option Redeemable Token: ";
    string private _symbol;
    uint private _unliquidatedVolume;

    constructor(string memory _sb, address _issuer)
        ERC20(string(abi.encodePacked(_prefix, _sb)))
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

    function issue(address from, address to, uint value) external {

        require(msg.sender == address(exchange), "issuance unallowed");
        _issued[from] = _issued[from].add(value);
        addBalance(to, value);
        _totalSupply = _totalSupply.add(value);
        _unliquidatedVolume = _unliquidatedVolume.add(value);
        emit Transfer(address(0), to, value);
    }

    function burn(uint value) external {

        burn(msg.sender, value);
    }

    function burn(address owner, uint value) public {

        require(
            msg.sender == owner || msg.sender == address(exchange),
            "burn sender unallowed"
        );

        uint b = balanceOf(owner);
        uint w = _issued[owner];
        require(
            b >= value && w >= value || (msg.sender == address(exchange) && w >= value),
            "invalid burn value"
        );

        if (msg.sender == owner) {
            removeBalance(owner, value);
            _totalSupply = _totalSupply.sub(value);
        }
        
        uint uc = uncoveredVolume(owner);
        uint coll = MoreMath.min(value, uc);

        w = w.sub(value);
        _issued[owner] = w;
        _unliquidatedVolume = _unliquidatedVolume.sub(value);

        uint udl = value > uc ? value.sub(uc) : 0;

        exchange.release(owner, udl, coll);
        exchange.cleanUp(owner, address(this));
        emit Transfer(owner, address(0), value);
    }

    function writtenVolume(address owner) external view returns (uint) {

        return _issued[owner];
    }

    function uncoveredVolume(address owner) public view returns (uint) {

        uint covered = exchange.underlyingBalance(owner, address(this));
        uint w = _issued[owner];
        return w > covered ? w.sub(covered) : 0;
    }

    function redeemAllowed() override public view returns (bool) {
        
        return _unliquidatedVolume == 0;
    }

    function afterRedeem(address owner, uint, uint value) override internal {

        exchange.cleanUp(owner, address(this));
        emit Transfer(owner, address(0), value);
    }

    function emitTransfer(address from, address to, uint value) override internal {

        exchange.transferOwnership(_symbol, from, to, value);
        emit Transfer(from, to, value);
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

    constructor() ERC20(_name) public {
        
    }

    function initialize(Deployer deployer) override internal {

        DOMAIN_SEPARATOR = ERC20(getImplementation()).DOMAIN_SEPARATOR();
        
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

    function processWithdraws(uint limit) public {
        
        while (headAddr != address(0) && (limit-- > 0)) {
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

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../governance/ProtocolSettings.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/TimeProvider.sol";
import "../utils/MoreMath.sol";
import "../utils/SafeERC20.sol";
import "../utils/SafeMath.sol";
import "../utils/SignedSafeMath.sol";
import "./CreditToken.sol";

contract CreditProvider is ManagedContract {

    using SafeERC20 for IERC20;
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

    event DepositTokens(address indexed to, address indexed token, uint value);

    event WithdrawTokens(address indexed from, address indexed token, uint value);

    event TransferBalance(address indexed from, address indexed to, uint value);

    event AccumulateDebt(address indexed to, uint value);

    event BurnDebt(address indexed from, uint value);

    event AccrueFees(address indexed from, uint value);

    function initialize(Deployer deployer) override internal {

        time = TimeProvider(deployer.getContractAddress("TimeProvider"));
        creditToken = CreditToken(deployer.getContractAddress("CreditToken"));
        settings = ProtocolSettings(deployer.getContractAddress("ProtocolSettings"));

        callers[address(settings)] = 1;
        callers[address(creditToken)] = 1;
        callers[deployer.getContractAddress("OptionsExchange")] = 1;
        callers[deployer.getContractAddress("UnderlyingVault")] = 1;

        ctAddr = address(creditToken);
    }

    function totalTokenStock() external view returns (uint v) {

        address[] memory tokens = settings.getAllowedTokens();
        for (uint i = 0; i < tokens.length; i++) {
            (uint r, uint b) = settings.getTokenRate(tokens[i]);
            uint value = IERC20(tokens[i]).balanceOf(address(this));
            v = v.add(value.mul(b).div(r));
        }
    }

    function ensureCaller(address addr) public view {
        
        require(callers[addr] == 1, "unauthorized caller");
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

        IERC20(token).safeTransferFrom(msg.sender, address(this), value);
        addBalance(to, token, value, true);
        emit DepositTokens(to, token, value);
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
                addBalance(address(settings), fee);
                emit AccrueFees(from, fee);
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
                emit AccumulateDebt(to, credit);
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
        }
    }
    
    function addBalance(address owner, uint value) private {

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
            emit BurnDebt(from, burnt);
        }
    }

    function applyDebtInterestRate(address owner) private returns (uint debt) {

        uint d = debts[owner];
        if (d > 0) {

            debt = calcDebt(owner);

            if (debt > 0 && debt != d) {
                setDebt(owner, debt);
                uint diff = debt.sub(d);
                emit AccumulateDebt(owner, diff);
            }
        }
    }

    function setDebt(address owner, uint value)  private {
        
        debts[owner] = value;
        debtsDate[owner] = time.getNow();
    }

    function transferTokens(address to, uint value) private {
        
        require(to != address(this) && to != ctAddr, "invalid token transfer address");

        address[] memory tokens = settings.getAllowedTokens();
        for (uint i = 0; i < tokens.length && value > 0; i++) {
            IERC20 t = IERC20(tokens[i]);
            (uint r, uint b) = settings.getTokenRate(tokens[i]);
            if (b != 0) {
                uint v = MoreMath.min(value, t.balanceOf(address(this)).mul(b).div(r));
                t.safeTransfer(to, v.mul(r).div(b));
                emit WithdrawTokens(to, tokens[i], v.mul(r).div(b));
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
        emit WithdrawTokens(to, ctAddr, value);
    }

    function ensureCaller() private view {
        
        ensureCaller(msg.sender);
    }
}

pragma solidity ^0.6.0;

// *** IMPORTANT ***
// "onwer" storage variable must be set to a GnosisSafe multisig wallet address:
// - https://github.com/gnosis/safe-contracts/blob/main/contracts/GnosisSafe.sol

contract Proxy {

    // ATTENTION: storage variable alignment
    address private owner;
    address private pendingOwner;
    address private implementation;
    uint private locked; // 1 = Initialized; 2 = Non upgradable
    // --------------------------------------------------------

    event OwnershipTransferRequested(address indexed from, address indexed to);
    
    event OwnershipTransferred(address indexed from, address indexed to);

    event SetNonUpgradable();

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

    function setNonUpgradable() public {

        require(msg.sender == owner && locked == 1);
        locked = 2;
        emit SetNonUpgradable();
    }

    function setImplementation(address _implementation) public {

        require(msg.sender == owner && locked != 2);
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

pragma solidity ^0.6.0;

import "./Deployer.sol";
// *** IMPORTANT ***
// "onwer" storage variable must be set to a GnosisSafe multisig wallet address:
// - https://github.com/gnosis/safe-contracts/blob/main/contracts/GnosisSafe.sol

contract ManagedContract {

    // ATTENTION: storage variable alignment
    address private owner;
    address private pendingOwner;
    address private implementation;
    uint private locked; // 1 = Initialized; 2 = Non upgradable
    // --------------------------------------------------------

    function initializeAndLock(Deployer deployer) public {

        require(locked == 0, "initialization locked");
        locked = 1;
        initialize(deployer);
    }

    function initialize(Deployer deployer) virtual internal {

    }

    function getOwner() public view returns (address) {

        return owner;
    }

    function getImplementation() public view returns (address) {

        return implementation;
    }
}

pragma solidity >=0.6.0;

import "./ManagedContract.sol";
import "./Proxy.sol";

contract Deployer {

    struct ContractData {
        string key;
        address origAddr;
        bool upgradeable;
    }

    mapping(string => address) private contractMap;
    mapping(string => string) private aliases;

    address private owner;
    ContractData[] private contracts;
    bool private deployed;

    constructor(address _owner) public {

        owner = _owner;
    }

    function hasKey(string memory key) public view returns (bool) {
        
        return contractMap[key] != address(0) || contractMap[aliases[key]] != address(0);
    }

    function setContractAddress(string memory key, address addr) public {

        setContractAddress(key, addr, true);
    }

    function setContractAddress(string memory key, address addr, bool upgradeable) public {
        
        require(!hasKey(key), buildKeyAlreadySetMessage(key));

        ensureNotDeployed();
        ensureCaller();
        
        contracts.push(ContractData(key, addr, upgradeable));
        contractMap[key] = address(1);
    }

    function addAlias(string memory fromKey, string memory toKey) public {
        
        ensureNotDeployed();
        ensureCaller();
        require(contractMap[toKey] != address(0), buildAddressNotSetMessage(toKey));
        aliases[fromKey] = toKey;
    }

    function getContractAddress(string memory key) public view returns (address) {
        
        require(hasKey(key), buildAddressNotSetMessage(key));
        address addr = contractMap[key];
        if (addr == address(0)) {
            addr = contractMap[aliases[key]];
        }
        require(addr != address(1), buildProxyNotDeployedMessage(key));
        return addr;
    }

    function getPayableContractAddress(string memory key) public view returns (address payable) {

        return address(uint160(address(getContractAddress(key))));
    }

    function isDeployed() public view returns(bool) {
        
        return deployed;
    }

    function deploy() public {

        deploy(owner);
    }

    function deploy(address _owner) public {

        ensureNotDeployed();
        ensureCaller();
        deployed = true;

        for (uint i = contracts.length - 1; i != uint(-1); i--) {
            if (contractMap[contracts[i].key] == address(1)) {
                if (contracts[i].upgradeable) {
                    Proxy p = new Proxy(_owner, contracts[i].origAddr);
                    contractMap[contracts[i].key] = address(p);
                } else {
                    contractMap[contracts[i].key] = contracts[i].origAddr;
                }
            } else {
                contracts[i] = contracts[contracts.length - 1];
                contracts.pop();
            }
        }

        for (uint i = 0; i < contracts.length; i++) {
            if (contracts[i].upgradeable) {
                address p = contractMap[contracts[i].key];
                ManagedContract(p).initializeAndLock(this);
            }
        }
    }

    function reset() public {

        ensureCaller();
        deployed = false;

        for (uint i = 0; i < contracts.length; i++) {
            contractMap[contracts[i].key] = address(1);
        }
    }

    function ensureNotDeployed() private view {

        require(!deployed, "already deployed");
    }

    function ensureCaller() private view {

        require(owner == address(0) || msg.sender == owner, "unallowed caller");
    }

    function buildKeyAlreadySetMessage(string memory key) private pure returns(string memory) {

        return string(abi.encodePacked("key already set: ", key));
    }

    function buildAddressNotSetMessage(string memory key) private pure returns(string memory) {

        return string(abi.encodePacked("contract address not set: ", key));
    }

    function buildProxyNotDeployedMessage(string memory key) private pure returns(string memory) {

        return string(abi.encodePacked("proxy not deployed: ", key));
    }
}