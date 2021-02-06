/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

// File: contracts/XVersion.sol

pragma solidity 0.5.17;

contract XVersion {
    function getVersion() external view returns (bytes32);
}

contract XApollo is XVersion {
    function getVersion() external view returns (bytes32) {
        return bytes32("APOLLO");
    }
}

// File: contracts/XConst.sol

pragma solidity 0.5.17;

contract XConst {
    uint256 public constant BONE = 10**18;

    uint256 public constant MIN_BOUND_TOKENS = 2;
    uint256 public constant MAX_BOUND_TOKENS = 8;

    uint256 public constant EXIT_ZERO_FEE = 0;

    uint256 public constant MIN_WEIGHT = BONE;
    uint256 public constant MAX_WEIGHT = BONE * 50;
    uint256 public constant MAX_TOTAL_WEIGHT = BONE * 50;

    // min effective value: 0.000001 TOKEN
    uint256 public constant MIN_BALANCE = 10**6;

    // BONE/(10**10) XPT
    uint256 public constant MIN_POOL_AMOUNT = 10**8;

    uint256 public constant INIT_POOL_SUPPLY = BONE * 100;

    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// File: contracts/lib/XNum.sol

pragma solidity 0.5.17;

library XNum {
    uint256 public constant BONE = 10**18;
    uint256 public constant MIN_BPOW_BASE = 1 wei;
    uint256 public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant BPOW_PRECISION = BONE / 10**10;

    function btoi(uint256 a) internal pure returns (uint256) {
        return a / BONE;
    }

    function bfloor(uint256 a) internal pure returns (uint256) {
        return btoi(a) * BONE;
    }

    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint256 a, uint256 b)
        internal
        pure
        returns (uint256, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole = bfloor(exp);
        uint256 remain = bsub(exp, whole);

        uint256 wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256) {
        // term 0:
        uint256 a = exp;
        (uint256 x, bool xneg) = bsubSign(base, BONE);
        uint256 term = BONE;
        uint256 sum = term;
        bool negative = false;

        // term(k) = numer / denom
        //         = (product(a - i + 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;
            (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

// File: contracts/interface/IERC20.sol

pragma solidity 0.5.17;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

// File: contracts/XPToken.sol

pragma solidity 0.5.17;




// Highly opinionated token implementation
contract XTokenBase {
    using XNum for uint256;

    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) internal _allowance;
    uint256 internal _totalSupply;

    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    function _mint(uint256 amt) internal {
        _balance[address(this)] = (_balance[address(this)]).badd(amt);
        _totalSupply = _totalSupply.badd(amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint256 amt) internal {
        require(_balance[address(this)] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[address(this)] = (_balance[address(this)]).bsub(amt);
        _totalSupply = _totalSupply.bsub(amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(
        address src,
        address dst,
        uint256 amt
    ) internal {
        require(_balance[src] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[src] = (_balance[src]).bsub(amt);
        _balance[dst] = (_balance[dst]).badd(amt);
        emit Transfer(src, dst, amt);
    }
}

contract XPToken is XTokenBase, IERC20, XApollo {
    using XNum for uint256;

    string private constant _name = "XDeFi Pool Token";
    string private constant _symbol = "XPT";
    uint8 private constant _decimals = 18;

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function allowance(address src, address dst)
        external
        view
        returns (uint256)
    {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view returns (uint256) {
        return _balance[whom];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function approve(address dst, uint256 amt) external returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function transfer(address dst, uint256 amt) external returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool) {
        require(
            msg.sender == src || amt <= _allowance[src][msg.sender],
            "ERR_BTOKEN_BAD_CALLER"
        );
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
            _allowance[src][msg.sender] = (_allowance[src][msg.sender]).bsub(
                amt
            );
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

// File: contracts/lib/XMath.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.5.17;


library XMath {
    using XNum for uint256;

    uint256 public constant BONE = 10**18;
    uint256 public constant EXIT_ZERO_FEE = 0;

    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) public pure returns (uint256 spotPrice) {
        uint256 numer = tokenBalanceIn.bdiv(tokenWeightIn);
        uint256 denom = tokenBalanceOut.bdiv(tokenWeightOut);
        uint256 ratio = numer.bdiv(denom);
        uint256 scale = BONE.bdiv(BONE.bsub(swapFee));
        return (spotPrice = ratio.bmul(scale));
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 weightRatio;
        if (tokenWeightIn == tokenWeightOut) {
            weightRatio = 1 * BONE;
        } else if (tokenWeightIn >> 1 == tokenWeightOut) {
            weightRatio = 2 * BONE;
        } else {
            weightRatio = tokenWeightIn.bdiv(tokenWeightOut);
        }
        uint256 adjustedIn = BONE.bsub(swapFee);
        adjustedIn = tokenAmountIn.bmul(adjustedIn);
        uint256 y = tokenBalanceIn.bdiv(tokenBalanceIn.badd(adjustedIn));
        uint256 foo;
        if (tokenWeightIn == tokenWeightOut) {
            foo = y;
        } else if (tokenWeightIn >> 1 == tokenWeightOut) {
            foo = y.bmul(y);
        } else {
            foo = y.bpow(weightRatio);
        }
        uint256 bar = BONE.bsub(foo);
        tokenAmountOut = tokenBalanceOut.bmul(bar);
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountIn) {
        uint256 weightRatio;
        if (tokenWeightOut == tokenWeightIn) {
            weightRatio = 1 * BONE;
        } else if (tokenWeightOut >> 1 == tokenWeightIn) {
            weightRatio = 2 * BONE;
        } else {
            weightRatio = tokenWeightOut.bdiv(tokenWeightIn);
        }
        uint256 diff = tokenBalanceOut.bsub(tokenAmountOut);
        uint256 y = tokenBalanceOut.bdiv(diff);
        uint256 foo;
        if (tokenWeightOut == tokenWeightIn) {
            foo = y;
        } else if (tokenWeightOut >> 1 == tokenWeightIn) {
            foo = y.bmul(y);
        } else {
            foo = y.bpow(weightRatio);
        }
        foo = foo.bsub(BONE);
        tokenAmountIn = BONE.bsub(swapFee);
        tokenAmountIn = tokenBalanceIn.bmul(foo).bdiv(tokenAmountIn);
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/
    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 poolAmountOut) {
        // Charge the trading fee for the proportion of tokenAi
        ///  which is implicitly traded to the other pool tokens.
        // That proportion is (1- weightTokenIn)
        // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
        uint256 normalizedWeight = tokenWeightIn.bdiv(totalWeight);
        uint256 zaz = BONE.bsub(normalizedWeight).bmul(swapFee);
        uint256 tokenAmountInAfterFee = tokenAmountIn.bmul(BONE.bsub(zaz));

        uint256 newTokenBalanceIn = tokenBalanceIn.badd(tokenAmountInAfterFee);
        uint256 tokenInRatio = newTokenBalanceIn.bdiv(tokenBalanceIn);

        // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
        uint256 poolRatio = tokenInRatio.bpow(normalizedWeight);
        uint256 newPoolSupply = poolRatio.bmul(poolSupply);
        poolAmountOut = newPoolSupply.bsub(poolSupply);
        return poolAmountOut;
    }

    /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 normalizedWeight = tokenWeightOut.bdiv(totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint256 poolAmountInAfterExitFee =
            poolAmountIn.bmul(BONE.bsub(EXIT_ZERO_FEE));
        uint256 newPoolSupply = poolSupply.bsub(poolAmountInAfterExitFee);
        uint256 poolRatio = newPoolSupply.bdiv(poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint256 tokenOutRatio = poolRatio.bpow(BONE.bdiv(normalizedWeight));
        uint256 newTokenBalanceOut = tokenOutRatio.bmul(tokenBalanceOut);

        uint256 tokenAmountOutBeforeSwapFee =
            tokenBalanceOut.bsub(newTokenBalanceOut);

        // charge swap fee on the output token side
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint256 zaz = BONE.bsub(normalizedWeight).bmul(swapFee);
        tokenAmountOut = tokenAmountOutBeforeSwapFee.bmul(BONE.bsub(zaz));
        return tokenAmountOut;
    }
}

// File: contracts/interface/IXConfig.sol

pragma solidity 0.5.17;

interface IXConfig {
    function getCore() external view returns (address);

    function getSAFU() external view returns (address);

    function isFarmPool(address pool) external view returns (bool);

    function getMaxExitFee() external view returns (uint256);

    function getSafuFee() external view returns (uint256);

    function getSwapProxy() external view returns (address);

    function ethAddress() external pure returns (address);

    function hasPool(address[] calldata tokens, uint256[] calldata denorms)
        external
        view
        returns (bool exist, bytes32 sig);

    // add by XSwapProxy
    function addPoolSig(bytes32 sig) external;

    // remove by XSwapProxy
    function removePoolSig(bytes32 sig) external;
}

// File: contracts/XPool.sol

pragma solidity 0.5.17;







contract XPool is XApollo, XPToken, XConst {
    using XNum for uint256;

    //Swap Fees: 0.1%, 0.25%, 1%, 2.5%, 10%
    uint256[5] public SWAP_FEES = [
        BONE / 1000,
        (25 * BONE) / 10000,
        BONE / 100,
        (25 * BONE) / 1000,
        BONE / 10
    ];

    struct Record {
        bool bound; // is token bound to pool
        uint256 index; // private
        uint256 denorm; // denormalized weight
        uint256 balance;
    }

    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut
    );

    event LOG_REFER(
        address indexed caller,
        address indexed ref,
        address indexed tokenIn,
        uint256 fee
    );

    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256 tokenAmountIn
    );

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256 tokenAmountOut
    );

    event LOG_BIND(
        address indexed caller,
        address indexed token,
        uint256 denorm,
        uint256 balance
    );

    event LOG_UPDATE_SAFU(address indexed safu, uint256 fee);

    event LOG_EXIT_FEE(uint256 fee);

    event LOG_FINAL(uint256 swapFee);

    // anonymous event
    event LOG_CALL(
        bytes4 indexed sig,
        address indexed caller,
        bytes data
    ) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        require(!_mutex, "ERR_REENTRY");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        require(!_mutex, "ERR_REENTRY");
        _;
    }

    bool private _mutex;

    address public controller; // has CONTROL role

    // `finalize` require CONTROL, `finalize` sets `can SWAP and can JOIN`
    bool public finalized;

    uint256 public swapFee;
    uint256 public exitFee;

    // Pool Governance
    address public SAFU;
    uint256 public safuFee;
    bool public isFarmPool;

    address[] internal _tokens;
    mapping(address => Record) internal _records;
    uint256 private _totalWeight;

    IXConfig public xconfig;
    address public origin;

    constructor(address _xconfig, address _controller) public {
        controller = _controller;
        origin = tx.origin;
        swapFee = SWAP_FEES[1];
        exitFee = EXIT_ZERO_FEE;
        finalized = false;
        xconfig = IXConfig(_xconfig);
        SAFU = xconfig.getSAFU();
        safuFee = xconfig.getSafuFee();
    }

    function isBound(address t) external view returns (bool) {
        return _records[t].bound;
    }

    function getNumTokens() external view returns (uint256) {
        return _tokens.length;
    }

    function getFinalTokens()
        external
        view
        _viewlock_
        returns (address[] memory tokens)
    {
        require(finalized, "ERR_NOT_FINALIZED");
        return _tokens;
    }

    function getDenormalizedWeight(address token)
        external
        view
        _viewlock_
        returns (uint256)
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].denorm;
    }

    function getTotalDenormalizedWeight()
        external
        view
        _viewlock_
        returns (uint256)
    {
        return _totalWeight;
    }

    function getNormalizedWeight(address token)
        external
        view
        _viewlock_
        returns (uint256)
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        uint256 denorm = _records[token].denorm;
        return denorm.bdiv(_totalWeight);
    }

    function getBalance(address token)
        external
        view
        _viewlock_
        returns (uint256)
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].balance;
    }

    function setController(address manager) external _logs_ {
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        controller = manager;
    }

    function setExitFee(uint256 fee) external {
        require(!finalized, "ERR_IS_FINALIZED");
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        require(fee <= xconfig.getMaxExitFee(), "INVALID_EXIT_FEE");
        exitFee = fee;
        emit LOG_EXIT_FEE(fee);
    }

    // allow SAFU address and SAFE FEE be updated by xconfig
    function updateSafu(address safu, uint256 fee) external {
        require(msg.sender == address(xconfig), "ERR_NOT_CONFIG");
        require(safu != address(0), "ERR_ZERO_ADDR");
        SAFU = safu;
        safuFee = fee;

        emit LOG_UPDATE_SAFU(safu, fee);
    }

    // allow isFarmPool be updated by xconfig
    function updateFarm(bool isFarm) external {
        require(msg.sender == address(xconfig), "ERR_NOT_CONFIG");
        isFarmPool = isFarm;
    }

    function bind(address token, uint256 denorm) external _lock_ {
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(!finalized, "ERR_IS_FINALIZED");

        require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");

        uint256 balance = IERC20(token).balanceOf(address(this));

        uint256 decimal = 10**uint256(IERC20(token).decimals());
        require(decimal >= 10**6, "ERR_TOO_SMALL");

        // 0.000001 TOKEN
        require(balance >= decimal / MIN_BALANCE, "ERR_MIN_BALANCE");

        _totalWeight = _totalWeight.badd(denorm);
        require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: denorm,
            balance: balance
        });
        _tokens.push(token);

        emit LOG_BIND(msg.sender, token, denorm, balance);
    }

    // _swapFee must be one of SWAP_FEES
    function finalize(uint256 _swapFee) external _lock_ {
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        require(!finalized, "ERR_IS_FINALIZED");
        require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");
        require(_tokens.length <= MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        require(_swapFee >= SWAP_FEES[0], "ERR_MIN_FEE");
        require(_swapFee <= SWAP_FEES[SWAP_FEES.length - 1], "ERR_MAX_FEE");

        bool found = false;
        for (uint256 i = 0; i < SWAP_FEES.length; i++) {
            if (_swapFee == SWAP_FEES[i]) {
                found = true;
                break;
            }
        }
        require(found, "ERR_INVALID_SWAP_FEE");
        swapFee = _swapFee;

        finalized = true;

        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);

        emit LOG_FINAL(swapFee);
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token) external _logs_ _lock_ {
        require(_records[token].bound, "ERR_NOT_BOUND");
        _records[token].balance = IERC20(token).balanceOf(address(this));
    }

    function getSpotPrice(address tokenIn, address tokenOut)
        external
        view
        _viewlock_
        returns (uint256 spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return
            XMath.calcSpotPrice(
                inRecord.balance,
                inRecord.denorm,
                outRecord.balance,
                outRecord.denorm,
                swapFee
            );
    }

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external
        view
        _viewlock_
        returns (uint256 spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return
            XMath.calcSpotPrice(
                inRecord.balance,
                inRecord.denorm,
                outRecord.balance,
                outRecord.denorm,
                0
            );
    }

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external
        _lock_
    {
        require(finalized, "ERR_NOT_FINALIZED");
        require(maxAmountsIn.length == _tokens.length, "ERR_LENGTH_MISMATCH");

        uint256 poolTotal = totalSupply();
        uint256 ratio = poolAmountOut.bdiv(poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountIn = ratio.bmul(bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            _records[t].balance = (_records[t].balance).badd(tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
        external
        _lock_
    {
        require(finalized, "ERR_NOT_FINALIZED");
        require(minAmountsOut.length == _tokens.length, "ERR_LENGTH_MISMATCH");

        // min pool amount
        require(poolAmountIn >= MIN_POOL_AMOUNT, "ERR_MIN_AMOUNT");

        uint256 poolTotal = totalSupply();
        uint256 _exitFee = poolAmountIn.bmul(exitFee);
        uint256 pAiAfterExitFee = poolAmountIn.bsub(_exitFee);
        uint256 ratio = pAiAfterExitFee.bdiv(poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        // to origin
        _pullPoolShare(msg.sender, poolAmountIn);
        if (_exitFee > 0) {
            _pushPoolShare(origin, _exitFee);
        }
        _burnPoolShare(pAiAfterExitFee);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountOut = ratio.bmul(bal);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
            _records[t].balance = (_records[t].balance).bsub(tokenAmountOut);
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
    }

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        return
            swapExactAmountInRefer(
                tokenIn,
                tokenAmountIn,
                tokenOut,
                minAmountOut,
                maxPrice,
                address(0x0)
            );
    }

    function swapExactAmountInRefer(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice,
        address referrer
    ) public _lock_ returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(finalized, "ERR_NOT_FINALIZED");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(
            tokenAmountIn <= (inRecord.balance).bmul(MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        uint256 spotPriceBefore =
            XMath.calcSpotPrice(
                inRecord.balance,
                inRecord.denorm,
                outRecord.balance,
                outRecord.denorm,
                swapFee
            );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountOut = calcOutGivenIn(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountIn,
            swapFee
        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        require(
            spotPriceBefore <= tokenAmountIn.bdiv(tokenAmountOut),
            "ERR_MATH_APPROX"
        );

        inRecord.balance = (inRecord.balance).badd(tokenAmountIn);
        outRecord.balance = (outRecord.balance).bsub(tokenAmountOut);

        spotPriceAfter = XMath.calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");

        emit LOG_SWAP(
            msg.sender,
            tokenIn,
            tokenOut,
            tokenAmountIn,
            tokenAmountOut
        );

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        uint256 _swapFee = tokenAmountIn.bmul(swapFee);

        // to referral
        uint256 _referFee = 0;
        if (
            referrer != address(0) &&
            referrer != msg.sender &&
            referrer != tx.origin
        ) {
            _referFee = _swapFee / 5; // 20% to referrer
            _pushUnderlying(tokenIn, referrer, _referFee);
            inRecord.balance = (inRecord.balance).bsub(_referFee);
            emit LOG_REFER(msg.sender, referrer, tokenIn, _referFee);
        }

        // to SAFU
        uint256 _safuFee = tokenAmountIn.bmul(safuFee);
        if (isFarmPool) {
            _safuFee = _swapFee.bsub(_referFee);
        }
        require(_safuFee.badd(_referFee) <= _swapFee, "ERR_FEE_LIMIT");
        _pushUnderlying(tokenIn, SAFU, _safuFee);
        inRecord.balance = (inRecord.balance).bsub(_safuFee);

        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
        return (tokenAmountOut, spotPriceAfter);
    }

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
        return
            swapExactAmountOutRefer(
                tokenIn,
                maxAmountIn,
                tokenOut,
                tokenAmountOut,
                maxPrice,
                address(0x0)
            );
    }

    function swapExactAmountOutRefer(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice,
        address referrer
    ) public _lock_ returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(finalized, "ERR_NOT_FINALIZED");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(
            tokenAmountOut <= (outRecord.balance).bmul(MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        uint256 spotPriceBefore =
            XMath.calcSpotPrice(
                inRecord.balance,
                inRecord.denorm,
                outRecord.balance,
                outRecord.denorm,
                swapFee
            );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountIn = calcInGivenOut(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountOut,
            swapFee
        );
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");
        require(
            spotPriceBefore <= tokenAmountIn.bdiv(tokenAmountOut),
            "ERR_MATH_APPROX"
        );

        inRecord.balance = (inRecord.balance).badd(tokenAmountIn);
        outRecord.balance = (outRecord.balance).bsub(tokenAmountOut);

        spotPriceAfter = XMath.calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");

        emit LOG_SWAP(
            msg.sender,
            tokenIn,
            tokenOut,
            tokenAmountIn,
            tokenAmountOut
        );

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        uint256 _swapFee = tokenAmountIn.bmul(swapFee);
        // to referral
        uint256 _referFee = 0;
        if (
            referrer != address(0) &&
            referrer != msg.sender &&
            referrer != tx.origin
        ) {
            _referFee = _swapFee / 5; // 20% to referrer
            _pushUnderlying(tokenIn, referrer, _referFee);
            inRecord.balance = (inRecord.balance).bsub(_referFee);
            emit LOG_REFER(msg.sender, referrer, tokenIn, _referFee);
        }

        // to SAFU
        uint256 _safuFee = tokenAmountIn.bmul(safuFee);
        if (isFarmPool) {
            _safuFee = _swapFee.bsub(_referFee);
        }
        require(_safuFee.badd(_referFee) <= _swapFee, "ERR_FEE_LIMIT");
        _pushUnderlying(tokenIn, SAFU, _safuFee);
        inRecord.balance = (inRecord.balance).bsub(_safuFee);

        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
        return (tokenAmountIn, spotPriceAfter);
    }

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external _lock_ returns (uint256 poolAmountOut) {
        require(finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(
            tokenAmountIn <= (_records[tokenIn].balance).bmul(MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        // to SAFU
        uint256 _safuFee = tokenAmountIn.bmul(safuFee);
        if (isFarmPool) {
            _safuFee = tokenAmountIn.bmul(swapFee);
        }
        tokenAmountIn = tokenAmountIn.bsub(_safuFee);

        Record storage inRecord = _records[tokenIn];
        poolAmountOut = XMath.calcPoolOutGivenSingleIn(
            inRecord.balance,
            inRecord.denorm,
            _totalSupply,
            _totalWeight,
            tokenAmountIn,
            swapFee
        );
        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance = (inRecord.balance).badd(tokenAmountIn);

        _pushUnderlying(tokenIn, SAFU, _safuFee);
        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        return poolAmountOut;
    }

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external _logs_ _lock_ returns (uint256 tokenAmountOut) {
        require(finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(poolAmountIn >= MIN_POOL_AMOUNT, "ERR_MIN_AMOUNT");

        _pullPoolShare(msg.sender, poolAmountIn);

        // exit fee to origin
        if (exitFee > 0) {
            uint256 _exitFee = poolAmountIn.bmul(exitFee);
            _pushPoolShare(origin, _exitFee);
            poolAmountIn = poolAmountIn.bsub(_exitFee);
        }

        _burnPoolShare(poolAmountIn);

        Record storage outRecord = _records[tokenOut];
        tokenAmountOut = XMath.calcSingleOutGivenPoolIn(
            outRecord.balance,
            outRecord.denorm,
            _totalSupply,
            _totalWeight,
            poolAmountIn,
            swapFee
        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        require(
            tokenAmountOut <= (_records[tokenOut].balance).bmul(MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        outRecord.balance = (outRecord.balance).bsub(tokenAmountOut);

        // to SAFU
        uint256 _safuFee = tokenAmountOut.bmul(safuFee);
        if (isFarmPool) {
            _safuFee = tokenAmountOut.bmul(swapFee);
        }

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);
        _pushUnderlying(tokenOut, SAFU, _safuFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut.bsub(_safuFee));
        return tokenAmountOut;
    }

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 _swapFee
    ) public pure returns (uint256) {
        return
            XMath.calcOutGivenIn(
                tokenBalanceIn,
                tokenWeightIn,
                tokenBalanceOut,
                tokenWeightOut,
                tokenAmountIn,
                _swapFee
            );
    }

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 _swapFee
    ) public pure returns (uint256) {
        return
            XMath.calcInGivenOut(
                tokenBalanceIn,
                tokenWeightIn,
                tokenBalanceOut,
                tokenWeightOut,
                tokenAmountOut,
                _swapFee
            );
    }

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety
    // Fixed ERC-20 transfer revert for some special token such as USDT
    function _pullUnderlying(
        address erc20,
        address from,
        uint256 amount
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            erc20.call(
                abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ERC20_TRANSFER_FROM_FAILED"
        );
    }

    function _pushUnderlying(
        address erc20,
        address to,
        uint256 amount
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            erc20.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ERC20_TRANSFER_FAILED"
        );
    }

    function _pullPoolShare(address from, uint256 amount) internal {
        _move(from, address(this), amount);
    }

    function _pushPoolShare(address to, uint256 amount) internal {
        _move(address(this), to, amount);
    }

    function _mintPoolShare(uint256 amount) internal {
        _mint(amount);
    }

    function _burnPoolShare(uint256 amount) internal {
        _burn(amount);
    }
}