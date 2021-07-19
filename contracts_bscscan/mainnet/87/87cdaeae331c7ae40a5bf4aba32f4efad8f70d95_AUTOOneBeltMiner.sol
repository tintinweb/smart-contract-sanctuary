/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// File: contracts/interfaces/IBEP20.sol

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

// File: contracts/interfaces/IXChangerBSC.sol


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
            uint256[7] memory swapAmountsIn,
            uint256[7] memory swapAmountsOut,
            bool swapVia
        );

    function reverseQuote(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 returnAmount
    )
        external
        view
        returns (
            uint256 inputAmount,
            uint256[7] memory swapAmountsIn,
            uint256[7] memory swapAmountsOut,
            bool swapVia
        );
}

// File: contracts/XChangerUserBSC.sol



pragma solidity ^0.8.0;



/**
 * @dev Helper contract to communicate to XChanger(XTrinity) contract to obtain prices and change tokens as needed
 */
contract XChangerUser {
    XChanger public xchanger;

    uint256 private constant ex_count = 7;

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
                bool //swapVia
            ) {
                returnAmount = _returnAmount;
            } catch {}
        }
    }

    /**
     * @dev get a reverse price of one token amount in another
     * the opposite of above 'quote' method when we need to understand how much we need to spend actually
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param returnAmount - of the toToken
     */
    /*
    function reverseQuote(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 returnAmount
    ) public view returns (uint256 inputAmount) {
        if (fromToken == toToken) {
            inputAmount = returnAmount;
        } else {
            try
                xchanger.reverseQuote(fromToken, toToken, returnAmount)
            returns (
                uint256 _inputAmount,
                uint256[3] memory, //swapAmountsIn,
                uint256[3] memory, //swapAmountsOut,
                bool // swapVia
            ) {
                inputAmount = _inputAmount;
                inputAmount += 1; // Curve requires this
            } catch {}
        }
    }
    */

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

// File: contracts/access/Context.sol


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

// File: contracts/access/Ownable.sol



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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/AUTOOneBELTMinerBSC.sol


pragma solidity ^0.8.0;




interface IBELT is IBEP20 {
    function withdraw(uint256 _shares, uint256 _minAmount) external;

    function deposit(uint256 _amount, uint256 _minShares) external;

    function sharesToAmount(uint256 _shares) external view returns (uint256);

    function amountToShares(uint256 _amount) external view returns (uint256);
}

/*----------->8--------------*/

interface IAutoFarm {
    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdraw(uint256 _pid, uint256 _wantAmt) external;

    function pendingAUTO(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function stakedWantTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}

/**
 * @title autofarm.network external pool contract for BELT pool
 * @dev is an example of external pool which implements maximizing BELT yield mining capabilities.
 */

contract AUTOOneBeltMiner is Ownable, XChangerUser {
    bool private initialized;
    address public valueHolder;
    address public claimManager;
    address public feeManager;

    IBELT public LPToken;

    IAutoFarm internal constant AUTOFARM =
        IAutoFarm(0x0895196562C7868C5Be92459FaE7f877ED450452);

    uint256 public pid;

    IBEP20 internal constant AUTO =
        IBEP20(0xa184088a740c695E156F91f5cC086a06bb78b827);
    IBEP20 private constant WBNB =
        IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    uint256 internal constant test_amount = 1000000000000000000000000;

    address public enterToken; //= DAI_ADDRESS;
    IBEP20 private enterTokenIBEP20; //= IBEP20(enterToken);

    uint256 public performanceFee; // 1% = 100
    uint256 public claimFee; // 1% = 100
    uint256 private lastClaim;
    uint256 public currentPC;
    uint256 public lastValue;

    event LogValueHolderUpdated(address Manager);

    /**
     * @dev main init function
     */

    function init(
        address _enterToken,
        address _iToken,
        uint256 _pid,
        address _xChanger
    ) external {
        require(!initialized, "Initialized");
        initialized = true;
        Ownable.initialize(); // Do not forget this call!
        _init(_enterToken, _iToken, _pid, _xChanger);
    }

    /**
     * @dev internal variable initialization
     */
    function _init(
        address _enterToken,
        address _iToken,
        uint256 _pid,
        address _xChanger
    ) internal {
        enterToken = _enterToken;
        enterTokenIBEP20 = IBEP20(enterToken);
        pid = _pid;
        LPToken = IBELT(_iToken);
        //enterLPToken = address(BELT_LP_TOKEN);

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
    function reInit(
        address _enterToken,
        address _iToken,
        uint256 _pid,
        address _xChanger
    ) external onlyOwner {
        _init(_enterToken, _iToken, _pid, _xChanger);
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
    ) external onlyValueHolder returns (uint256) {
        IBEP20 Token = IBEP20(TokenAddress);
        uint256 balance = Token.balanceOf(address(this));
        if (balance < amount) {
            amount = balance;
        }
        Token.transfer(recipient, amount);
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
        IBEP20 Token = IBEP20(TokenAddress);
        uint256 balance = Token.balanceOf(address(this));
        Token.transfer(valueHolder, balance);
        return balance;
    }

    /**
     * @dev Main function to enter the position
     */
    function addPosition(address token)
        public
        onlyPrivilegedHolder
        returns (uint256 amount)
    {
        IBEP20 tokenBEP20 = IBEP20(token);
        uint256 available_amount = tokenBEP20.balanceOf(msg.sender);
        if (available_amount > 0) {
            tokenBEP20.transferFrom(
                msg.sender,
                address(this),
                available_amount
            );
        }

        amount = tokenBEP20.balanceOf(address(this)); // Get de-facto balance
        require(amount > 0, "No available enterToken");

        if (token != enterToken) {
            amount = swap(tokenBEP20, enterTokenIBEP20, amount, false);
            tokenBEP20 = enterTokenIBEP20;
            token = enterToken;
        }

        addLiquidity(amount);

        stakeLP();
    }

    /**
     * @dev Add liquidity
     */
    function addLiquidity(uint256 amount) internal {
        allow(enterTokenIBEP20, address(LPToken), amount);
        LPToken.deposit(amount, LPToken.amountToShares(amount) / 2);
    }

    /**
     * @dev Remove liquidity
     */
    function removeLiquidity(uint256 amount) public onlyValueHolder {
        LPToken.withdraw(amount, LPToken.sharesToAmount(amount) / 2);
    }

    /**
     * @dev Add only LP tokens to stake
     */
    function stakeLP() public onlyPrivilegedHolder {
        uint256 balance_LP = LPToken.balanceOf(address(this));
        allow(LPToken, address(AUTOFARM), balance_LP);
        AUTOFARM.deposit(pid, balance_LP);
    }

    /**
     * @dev remove LP tokens from stake
     */
    function unstakeLP(uint256 amount) public onlyValueHolder {
        AUTOFARM.withdraw(pid, amount);
    }

    /**
     * @dev remove all LP tokens from stake
     */
    function unstakeAllLP() public onlyValueHolder {
        unstakeLP(getLPStaked());
    }

    /**
     * @dev Main function to exit position - partially or completely
     */
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

            uint256 needToUnstake = LPToken.amountToShares(amount);
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

    /**
     * @dev Get the total amount of LP value of the pool
     */
    function getLPStaked() public view returns (uint256 totalLPStaked) {
        totalLPStaked = AUTOFARM.stakedWantTokens(pid, address(this));
    }

    /**
     * @dev Get the total amount of enterToken value of the pool
     */
    function getTokenStaked() public view returns (uint256 totalTokenStaked) {
        uint256 staked_LP = getLPStaked();
        uint256 balance_LP = LPToken.balanceOf(address(this));
        balance_LP += staked_LP;

        totalTokenStaked = LPToken.sharesToAmount(balance_LP);
    }

    /**
     * @dev Get the total value the Pool in [denominateTo] tokens [DAI?]
     */

    function getPoolValue(address denominateTo)
        public
        view
        returns (uint256 totalValue)
    {
        uint256 freeEnterToken = enterTokenIBEP20.balanceOf(address(this));
        uint256 totalEnterToken = freeEnterToken + getTokenStaked();
        totalValue = quote(
            enterTokenIBEP20,
            IBEP20(denominateTo),
            totalEnterToken
        );
    }

    /**
     * @dev Get the pending BELT -> BNB value
     */

    function getPendingBonus() public view returns (uint256 totalValue) {
        uint256 pendingTokens = AUTOFARM.pendingAUTO(pid, address(this));
        uint256 performanceToken = (pendingTokens * claimFee) / 10000;

        totalValue = quote(AUTO, WBNB, performanceToken);
    }

    /**
     * @dev Get the pending BELT -> [DAI] value
     */

    function getPendingEnterToken() public view returns (uint256 totalValue) {
        uint256 pendingTokens = AUTOFARM.pendingAUTO(pid, address(this));

        uint256 claimToken = (pendingTokens * claimFee) / 10000;
        uint256 performanceToken = (pendingTokens * performanceFee) / 10000;
        pendingTokens -= (performanceToken + claimToken);

        totalValue = quote(AUTO, enterTokenIBEP20, pendingTokens);
    }

    /**
     * @dev Claim all available BELT and convert to DAI as needed, plus WBNB
     */
    function claimValue() external {
        AUTOFARM.withdraw(pid, 0);

        uint256 token_balance = AUTO.balanceOf(address(this));

        if (claimFee > 0) {
            uint256 claimToken = (token_balance * claimFee) / 10000;
            swap(AUTO, WBNB, claimToken, false);
            WBNB.transfer(claimManager, WBNB.balanceOf(address(this)));
            token_balance -= claimToken;
        }

        if (performanceFee > 0) {
            uint256 performanceToken = (token_balance * performanceFee) / 10000;
            swap(AUTO, WBNB, performanceToken, false);
            WBNB.transfer(feeManager, WBNB.balanceOf(address(this)));
            token_balance -= performanceToken;
        }

        // Get what is left
        token_balance = AUTO.balanceOf(address(this));

        // Change the rest to EnterToken and compound
        uint256 returnTokens =
            swap(AUTO, enterTokenIBEP20, token_balance, false);

        uint256 currentValue = getTokenStaked() + returnTokens;
        uint256 timeDiff = block.timestamp - lastClaim;
        if (lastValue > 0) {
            uint256 bonus = currentValue - lastValue;
            currentPC = (((31536000 * bonus) / timeDiff) * 10000) / lastValue;
        }

        addPosition(enterToken);

        lastValue = currentValue;
        lastClaim = block.timestamp;
    }
}