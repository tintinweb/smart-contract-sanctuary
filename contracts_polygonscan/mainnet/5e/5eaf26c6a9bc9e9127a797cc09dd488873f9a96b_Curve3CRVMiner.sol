/**
 *Submitted for verification at polygonscan.com on 2021-09-02
*/

// File: polygon_contracts/interfaces/IBEP20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: polygon_contracts/interfaces/ICurve.sol



pragma solidity ^0.8.0;

abstract contract ICurveFiCurve {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external virtual;

    /*
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external virtual;
    */

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external virtual;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function get_dy_underlying(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function calculateSwap(
        uint8 i,
        uint8 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function swap(
        uint8 i,
        uint8 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external virtual;

    function A() external view virtual returns (uint256);

    function balances(uint256 arg0) external view virtual returns (uint256);

    function balances(int128 arg0) external view virtual returns (uint256);

    function getTokenBalance(uint8 arg0)
        external
        view
        virtual
        returns (uint256);

    function fee() external view virtual returns (uint256);
}

// File: polygon_contracts/utils/CurvedPolygon.sol


pragma solidity ^0.8.0;


/**
 * @dev reverse-engineered utils to help Curve amount calculations
 */
contract CurveUtils {
    address internal constant CURVE_AAVE =
        0x445FE580eF8d70FF569aB36e80c647af338db351;

    address internal constant CURVE_3POOL =
        0x751B1e21756bDbc307CBcC5085c042a0e9AaEf36;

    address internal constant CURVE_3CRYPTO =
        0x3FCD5De6A9fC8A99995c406c77DDa3eD7E406f81;
    address internal constant IRON = 0x837503e8A8753ae17fB8C8151B8e6f586defCb57;

    address internal constant DAI_ADDRESS =
        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address internal constant USDC_ADDRESS =
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address internal constant USDT_ADDRESS =
        0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address internal constant WBTC_ADDRESS =
        0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address internal constant ETH_ADDRESS =
        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    mapping(address => mapping(address => int8)) internal curveIndex;

    //mapping(address => mapping(int8 => address)) internal reverseCurveIndex;

    /**
     * @dev get index of a token in Curve pool contract
     */
    function getCurveIndex(address curve, address token)
        internal
        view
        returns (int8)
    {
        // to avoid 'stack too deep' compiler issue
        return curveIndex[curve][token] - 1;
    }

    /**
     * @dev init internal variables at creation
     */
    function init() public virtual {
        curveIndex[CURVE_AAVE][DAI_ADDRESS] = 1; // actual index is 1 less
        curveIndex[CURVE_AAVE][USDC_ADDRESS] = 2;
        curveIndex[CURVE_AAVE][USDT_ADDRESS] = 3;

        /*
        reverseCurveIndex[CURVE_AAVE][1] = DAI_ADDRESS;
        reverseCurveIndex[CURVE_AAVE][2] = USDC_ADDRESS;
        reverseCurveIndex[CURVE_AAVE][3] = USDT_ADDRESS;
        */

        curveIndex[CURVE_3CRYPTO][DAI_ADDRESS] = 1; // actual index is 1 less
        curveIndex[CURVE_3CRYPTO][USDC_ADDRESS] = 2;
        curveIndex[CURVE_3CRYPTO][USDT_ADDRESS] = 3; // 1-3 is from base pool
        curveIndex[CURVE_3CRYPTO][WBTC_ADDRESS] = 4;
        curveIndex[CURVE_3CRYPTO][ETH_ADDRESS] = 5;
        /*
        reverseCurveIndex[CURVE_3CRYPTO][1] = DAI_ADDRESS;
        reverseCurveIndex[CURVE_3CRYPTO][2] = USDC_ADDRESS;
        reverseCurveIndex[CURVE_3CRYPTO][3] = USDT_ADDRESS;
        reverseCurveIndex[CURVE_3CRYPTO][4] = WBTC_ADDRESS;
        reverseCurveIndex[CURVE_3CRYPTO][5] = ETH_ADDRESS;
        */

        curveIndex[IRON][USDC_ADDRESS] = 1; // actual index is 1 less
        curveIndex[IRON][USDT_ADDRESS] = 2;
        curveIndex[IRON][DAI_ADDRESS] = 3;
        /*
        reverseCurveIndex[IRON][0] = USDC_ADDRESS;
        reverseCurveIndex[IRON][1] = USDT_ADDRESS;
        reverseCurveIndex[IRON][2] = DAI_ADDRESS;
        */
    }
}

// File: polygon_contracts/interfaces/IXChangerPolygon.sol


pragma solidity ^0.8.0;


interface XChanger {
    function swap(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount,
        bool slipProtect
    ) external payable returns (uint256 result);

    function quote(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount
    )
        external
        view
        returns (
            uint256 returnAmount,
            uint256[5] memory swapAmountsIn,
            uint256[5] memory swapAmountsOut,
            address swapVia
        );

    /*
    function reverseQuote(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 returnAmount
    )
        external
        view
        returns (
            uint256 inputAmount,
            uint256[5] memory swapAmountsIn,
            uint256[5] memory swapAmountsOut,
            bool swapVia
        );
    */
}

// File: polygon_contracts/XChangerUserPolygon.sol



pragma solidity ^0.8.0;



/**
 * @dev Helper contract to communicate to XChanger(XTrinity) contract to obtain prices and change tokens as needed
 */
contract XChangerUser {
    XChanger public xchanger;

    uint256 private constant ex_count = 5;

    /**
     * @dev get a price of one token amount in another
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param amount - of the fromToken
     */

    function quote(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount
    ) public view returns (uint256 returnAmount) {
        if (fromToken == toToken) {
            returnAmount = amount;
        } else {
            try xchanger.quote(fromToken, toToken, amount) returns (
                uint256 _returnAmount,
                uint256[ex_count] memory, //swapAmountsIn,
                uint256[ex_count] memory, //swapAmountsOut,
                address //swapVia
            ) {
                returnAmount = _returnAmount;
            } catch {}
        }
    }

    /**
     * @dev swap one token to another given the amount we want to spend
     
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param amount - of the fromToken we are spending
     * @param slipProtect - flag to ensure the transaction will be performed if the received amount is not less than expected within the given slip %% range (like 1%)
     */
    function swap(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount,
        bool slipProtect
    ) public payable returns (uint256 returnAmount) {
        allow(fromToken, address(xchanger), amount);
        returnAmount = xchanger.swap(fromToken, toToken, amount, slipProtect);
    }

    /**
     * @dev function to fix allowance if needed
     */
    function allow(
        IBEP20 token,
        address spender,
        uint256 amount
    ) internal {
        if (token.allowance(address(this), spender) < amount) {
            token.approve(spender, 0);
            token.approve(spender, type(uint256).max);
        }
    }

    /**
     * @dev payable fallback to allow for WBNB withdrawal
     */
    receive() external payable {}

    fallback() external payable {}
}

// File: polygon_contracts/access/Context.sol


pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: polygon_contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    /*
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }*/

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: polygon_contracts/Curve3CRVMiner.sol


pragma solidity ^0.8.0;





interface IWBNB is IBEP20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

interface ICurvePool {
    function add_liquidity(
        uint256[3] memory _amounts,
        uint256 _min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 _min_amount
    ) external returns (uint256 out);

    function remove_liquidity(
        uint256 _amount,
        uint256[3] memory _min_amounts,
        bool use_underlying
    ) external;

    function balances(uint256 i) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, int128 i)
        external
        view
        returns (uint256);
}

interface CurveGauge is IBEP20 {
    function claimable_reward_write(address _addr, address _token)
        external
        view
        returns (uint256);

    function claim_rewards() external;

    function deposit(uint256 _wantAmt) external;

    function withdraw(uint256 _wantAmt) external;
}

/**
 * @title https://polygon.curve.fi/ pool
 * @dev is an example of external pool which implements maximizing Curve yield mining capabilities.
 */

contract Curve3CRVMiner is Ownable, XChangerUser, CurveUtils {
    bool private initialized;
    address public valueHolder;
    address public claimManager;
    address public feeManager;

    IBEP20 public LPToken = IBEP20(0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171);

    CurveGauge internal constant CURVE_GAUGE =
        CurveGauge(0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c);

    //CurveGauge(0x3B6B158A76fd8ccc297538F454ce7B4787778c7C);

    ICurvePool internal constant CURVE = ICurvePool(CURVE_AAVE);

    IBEP20 private constant WMATIC =
        IBEP20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    IBEP20 internal constant CRV =
        IBEP20(0x172370d5Cd63279eFa6d502DAB29171933a610AF);

    IBEP20 internal constant ETH =
        IBEP20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    address public enterToken; //
    IBEP20 private enterTokenIBEP20; //= IBEP20(enterToken);

    uint256 public performanceFee; // 1% = 100
    uint256 public claimFee; // 1% = 100

    event LogValueHolderUpdated(address Manager);

    /**
     * @dev main init function
     */

    function init(address _enterToken, address _xChanger) external {
        require(!initialized, "Initialized");
        initialized = true;
        Ownable.initialize(); // Do not forget this call!
        CurveUtils.init();
        _init(_enterToken, _xChanger);
    }

    /**
     * @dev internal variable initialization
     */
    function _init(address _enterToken, address _xChanger) internal {
        enterToken = _enterToken;
        if (enterToken != address(0)) {
            enterTokenIBEP20 = IBEP20(enterToken);
        } else {
            enterTokenIBEP20 = WMATIC;
        }

        valueHolder = msg.sender;
        claimManager = msg.sender;
        feeManager = msg.sender;
        xchanger = XChanger(_xChanger);

        performanceFee = 0;
        claimFee = 100;
    }

    /**
     * @dev re-initializer might be helpful for the cases where proxy's storage is corrupted by an old contact, but we cannot run init as we have the owner address already.
     * This method might help fixing the storage state.
     */
    function reInit(address _enterToken, address _xChanger) external onlyOwner {
        _init(_enterToken, _xChanger);
    }

    /**
     * @dev this modifier is only for methods that should be called by ValueHolder contract
     */
    modifier onlyValueHolder() {
        require(msg.sender == valueHolder, "Not Value Holder");
        _;
    }

    /**
     * @dev this modifier is only for methods that should be called by ValueHolder or ClaimManager contract
     */
    modifier onlyPrivilegedHolder() {
        require(
            msg.sender == valueHolder || msg.sender == claimManager,
            "Not Privileged Holder"
        );
        _;
    }

    /**
     * @dev Sets new valueHolder address
     */
    function setValueHolder(address _valueHolder) external onlyOwner {
        valueHolder = _valueHolder;
    }

    /**
     * @dev Sets new ValueHolder address
     */
    function setClaimManager(address _claimManager) external onlyOwner {
        claimManager = _claimManager;
    }

    /**
     * @dev Sets new feeManager address
     */
    function setFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
    }

    /**
     * @dev set new XChanger (XTrinity) contract implementation address to use
     */
    function setXChangerImpl(address _Xchanger) external onlyOwner {
        xchanger = XChanger(_Xchanger);
    }

    /**
     * @dev set new fee amount - used upon harvest. value 200 = 2% fee
     */
    function setPerformanceFee(uint256 _performanceFee) public onlyOwner {
        performanceFee = _performanceFee;
    }

    /**
     * @dev set new fee amount - used upon harvest. value 200 = 2% fee
     */
    function setClaimFee(uint256 _claimFee) public onlyOwner {
        claimFee = _claimFee;
    }

    /**
     * @dev method for retrieving tokens back to ValueHolder or whereever
     */

    function transferTokenTo(
        address TokenAddress,
        address recipient,
        uint256 amount
    ) public onlyValueHolder returns (uint256) {
        if (TokenAddress != address(0)) {
            IBEP20 Token = IBEP20(TokenAddress);
            uint256 balance = Token.balanceOf(address(this));
            if (balance < amount) {
                amount = balance;
            }
            if (amount > 0) {
                Token.transfer(recipient, amount);
            }
        } else {
            amount = address(this).balance;
            payable(recipient).transfer(amount);
        }

        return amount;
    }

    /**
     * @dev method for retrieving tokens back to ValueHolder
     */

    function getToken(address TokenAddress)
        external
        onlyValueHolder
        returns (uint256)
    {
        return transferTokenTo(TokenAddress, valueHolder, type(uint256).max);
    }

    /**
     * @dev Main function to enter the position
     */
    function addPosition(address token)
        public
        payable
        onlyPrivilegedHolder
        returns (uint256 amount)
    {
        IBEP20 tokenBEP20 = IBEP20(token);
        uint256 available_amount = tokenBEP20.balanceOf(msg.sender);
        if (available_amount > 0) {
            try
                tokenBEP20.transferFrom(
                    msg.sender,
                    address(this),
                    available_amount
                )
            {} catch {}
        }

        amount = tokenBEP20.balanceOf(address(this)); // Get de-facto balance
        require(amount > 0, "No available Token");

        addLiquidity(amount, token);

        stakeLP();
    }

    /**
     * @dev Add liquidity
     */
    function addLiquidity(uint256 amount, address token) internal {
        ///Curve can do multiple tokens
        if (curveIndex[address(CURVE)][token] == 0) {
            amount = swap(IBEP20(token), enterTokenIBEP20, amount, false);
            token = enterToken;
        }

        uint256 ix = uint256(uint8(curveIndex[address(CURVE)][token]));
        require(ix > 0, "wrong curve index");

        allow(IBEP20(token), address(CURVE), amount);

        uint256[3] memory _amounts;

        _amounts[ix - 1] = amount;
        CURVE.add_liquidity(_amounts, 0, true);
    }

    /**
     * @dev Remove liquidity
     */
    function removeLiquidity(uint256 amount) public onlyValueHolder {
        // amount = number of LP tokens
        uint256[3] memory _amounts;
        CURVE.remove_liquidity(amount, _amounts, true);
    }

    /**
     * @dev Add only LP tokens to stake
     */
    function stakeLP() public onlyPrivilegedHolder {
        uint256 balance_LP = LPToken.balanceOf(address(this));
        allow(LPToken, address(CURVE_GAUGE), balance_LP);
        CURVE_GAUGE.deposit(balance_LP);
    }

    /**
     * @dev remove LP tokens from stake
     */
    function unstakeLP(uint256 amount) public onlyValueHolder {
        CURVE_GAUGE.withdraw(amount);
    }

    /**
     * @dev remove all LP tokens from stake
     */
    function unstakeAllLP() public onlyValueHolder {
        uint256 staked_balance_LP = getLPStaked();
        unstakeLP(staked_balance_LP);
    }

    /**
     * @dev Main function to exit position - partially or completely
     */
    /*
    ??????
    function exitPosition(uint256 amount) public onlyValueHolder {
        uint256 staked_balance_LP = getLPStaked();

        if (amount == type(uint256).max) {
            // remove everything
            //115792089237316195423570985008687907853269984665640564039457584007913129639935
            //10000000000000000000000

            //TODO: completely close position
            if (staked_balance_LP > 0) {
                unstakeLP(staked_balance_LP);
            }

            uint256 balance_LP = LPToken.balanceOf(address(this));
            removeLiquidity(balance_LP);
        } else {
            // TODO partial close - find out how much

            uint256 needToUnstake = (amount * LPToken.totalSupply()) /
                CURVE.balances(
                    uint256(uint8(getCurveIndex(address(CURVE), enterToken)))
                );

            require(
                staked_balance_LP >= needToUnstake,
                "Not enougn staked shares"
            );

            unstakeLP(needToUnstake);
            uint256 balance_LP = LPToken.balanceOf(address(this));

            require(needToUnstake <= balance_LP, "avail LP < needed");
            removeLiquidity(needToUnstake);
        }
    }
    */

    /**
     * @dev Get the total amount of LP value of the pool
     */
    function getLPStaked() public view returns (uint256 totalLPStaked) {
        totalLPStaked = CURVE_GAUGE.balanceOf(address(this));
    }

    /**
     * @dev Get the total amount of enterToken value of the pool
     */
    function getTokenStaked() public view returns (uint256 totalTokenStaked) {
        uint256 staked_LP = getLPStaked();
        uint256 balance_LP = LPToken.balanceOf(address(this));
        balance_LP += staked_LP;

        totalTokenStaked = CURVE.calc_withdraw_one_coin(
            balance_LP,
            int128(getCurveIndex(address(CURVE), enterToken))
        );
    }

    /**
     * @dev Get the total value the Pool in [denominateTo] tokens [DAI?]
     */

    function getPoolValue(address denominateTo)
        public
        view
        returns (uint256 totalValue)
    {
        if (denominateTo == address(0)) {
            denominateTo = address(WMATIC);
        }
        uint256 freeEnterToken = enterTokenIBEP20.balanceOf(address(this));
        uint256 totalEnterToken = freeEnterToken + getTokenStaked();
        totalValue = quote(
            enterTokenIBEP20,
            IBEP20(denominateTo),
            totalEnterToken
        );
    }

    function getClaimableReward(address Token) public view returns (uint256) {
        return CURVE_GAUGE.claimable_reward_write(address(this), Token);
    }

    /**
     * @dev Get the pending CRV + WMATIC -> WMATIC value
     */

    function getPendingBonus() public view returns (uint256 totalValue) {
        uint256 pendingCRV = getClaimableReward(address(CRV));
        uint256 performanceToken = (pendingCRV * claimFee) / 10000;

        totalValue = quote(CRV, WMATIC, performanceToken);
        uint256 pendingWMATIC = getClaimableReward(address(WMATIC));
        totalValue += pendingWMATIC;
    }

    /**
     * @dev Get the pending CRV -> [enterToken] value
     */

    function getPendingEnterToken() public view returns (uint256 totalValue) {
        uint256 pendingCRV = getClaimableReward(address(CRV));

        uint256 claimToken = (pendingCRV * claimFee) / 10000;
        uint256 performanceToken = (pendingCRV * performanceFee) / 10000;

        pendingCRV -= (performanceToken + claimToken);

        totalValue = quote(CRV, enterTokenIBEP20, pendingCRV);

        uint256 pendingWMATIC = getClaimableReward(address(WMATIC));
        if (pendingWMATIC > 0) {
            claimToken = (pendingWMATIC * claimFee) / 10000;
            performanceToken = (pendingWMATIC * performanceFee) / 10000;
            pendingWMATIC -= (performanceToken + claimToken);
            uint256 totalValueWMatic = quote(
                WMATIC,
                enterTokenIBEP20,
                pendingWMATIC
            );
            totalValue += totalValueWMatic;
        }
    }

    /**
     * @dev Claim all available BELT and convert to DAI as needed, plus WBNB
     */
    function claimValue() external {
        harvest();

        uint256 tokensCompounded = compoundHarvest();
        if (tokensCompounded > 0) {
            addLiquidity(tokensCompounded, address(ETH));

            stakeLP();
        }
    }

    function harvest() public {
        CURVE_GAUGE.claim_rewards();
    }

    function compoundHarvest() public returns (uint256 returnTokens) {
        uint256 token_balance = CRV.balanceOf(address(this));

        if (token_balance > 0) {
            if (claimFee > 0) {
                uint256 claimToken = (token_balance * claimFee) / 10000;
                token_balance -= claimToken;
                swap(CRV, WMATIC, claimToken, false);
                WMATIC.transfer(claimManager, WMATIC.balanceOf(address(this)));
            }

            if (performanceFee > 0) {
                uint256 performanceToken = (token_balance * performanceFee) /
                    10000;
                token_balance -= performanceToken;
                performanceToken = swap(CRV, WMATIC, performanceToken, false);
                WMATIC.transfer(feeManager, performanceToken);
            }

            // Change the rest to EnterToken and compound
            returnTokens = swap(CRV, enterTokenIBEP20, token_balance, false);
        }
    }
}