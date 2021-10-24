/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;



// Part: Address

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

// Part: Context

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

// Part: IERC20

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Part: IPancakeV2Factory

interface IPancakeV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Part: IPancakeV2Router

interface IPancakeV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// Part: SafeMath

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
}

// Part: IERC20Metadata

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// Part: Manageable

abstract contract Manageable is Context {
    address private _manager;
    event ManagementTransferred(
        address indexed previousManager,
        address indexed newManager
    );

    constructor() {
        address msgSender = _msgSender();
        _manager = msgSender;
        emit ManagementTransferred(address(0), msgSender);
    }

    function manager() public view returns (address) {
        return _manager;
    }

    modifier onlyManager() {
        require(
            _manager == _msgSender(),
            "Manageable: caller is not the manager"
        );
        _;
    }

    function transferManagement(address newManager)
        external
        virtual
        onlyManager
    {
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }
}

// Part: Ownable

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner, bool safety_param)
        public
        virtual
        onlyOwner
    {
        require(safety_param);
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time, bool safety_param) public virtual onlyOwner {
        require(safety_param);
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock(bool safety_param) public virtual {
        require(safety_param);
        require(
            _previousOwner == msg.sender,
            "Only the previous owner can unlock onwership"
        );
        require(block.timestamp > _lockTime, "The contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// Part: Tokenomics

abstract contract Tokenomics {
    using SafeMath for uint256;

    // --------------------- Token Settings ------------------- //

    string internal constant NAME = "VokenDeploy20"; //dont forget; n the bottom of the code make sure it looks like this: contract [yourtokenname] is VokenToken
    string internal constant SYMBOL = "VKND20";

    uint16 internal constant FEES_DIVISOR = 10**3;
    uint8 internal constant DECIMALS = 6; //FIXME: change back to 18
    uint256 internal constant ZEROES = 10**DECIMALS;

    uint256 private constant MAX = ~uint256(0); // OK; max value of an uint256
    uint256 internal constant TOTAL_SUPPLY = 10_000 * ZEROES; // total supply FIXME: change back to 10_000_000. 10_000_000*10**18
    uint256 internal _reflectedSupply = (MAX - (MAX % TOTAL_SUPPLY)); // OK

    /**
     * @dev Set the maximum transaction amount allowed in a transfer.
     * NOTE: set the value to `TOTAL_SUPPLY` to have an unlimited max
     */
    uint256 internal constant maxTransactionAmount = TOTAL_SUPPLY / 100; // 1% of the total supply

    /**
     * @dev Set the maximum allowed balance in a wallet.
     * NOTE: set the value to 0 to have an unlimited max.
     *
     * IMPORTANT: This value MUST be greater than `thresholdSwapToLiquidity` set below,
     * otherwise the liquidity swap will never be executed
     */
    uint256 internal constant maxWalletBalance = TOTAL_SUPPLY / 25; // 4% of the total supply

    /**
     * @dev Set the number of tokens to (activate) swap and add to liquidity.
     *
     * Whenever the contract's balance reaches this number of tokens (=threshold), a swap & liquify will be
     * executed in the very next transfer (via the `_beforeTokenTransfer`)
     *
     * If the `FeeType.Liquidity` is enabled in `FeesSettings`, the given % of each transaction will be first
     * sent to the contract address. Once the contract's balance reaches `thresholdSwapToLiquidity` the
     * `swapAndLiquify` of `Liquifier` will be executed. Half of the tokens will be swapped for BNB
     * and together with the other half converted into a Token-BNB LP Token.
     *
     * See: `Liquifier`
     */
    uint256 internal constant thresholdSwapToLiquidity = TOTAL_SUPPLY / 5_000; // 0.05% of the total supply (5.000 vokens)

    // --------------------- Fees Settings ------------------- //
    address internal rndAddress = 0x71422DfAc007920d47D3A32724C1431671b73F1D;
    address internal fundAddress = 0x3Df416497347A20BDb3B124B081A18c029E0675C;
    address internal controlledBurnAddress =
        0x6daE480fA27A1314D8c1E5a291Ec18ec0e489735;

    enum FeeType {
        Liquidity,
        Rfi,
        External
    }

    struct Fee {
        FeeType name;
        uint256 value;
        address recipient;
        uint256 total;
    }

    Fee[] internal fees;
    uint256 internal sumOfFees;

    constructor() {
        _addFees();
    }

    function _addFee(
        FeeType name,
        uint256 value,
        address recipient
    ) private {
        fees.push(Fee(name, value, recipient, 0));
        sumOfFees += value;
    }

    function _addFees() private {
        /**
         * The RFI recipient is ignored but we need to give a valid address value
         *
         * The value of fees is given in part per 1000 (based on the value of FEES_DIVISOR),
         * e.g. for 5% use 50, for 3.5% use 35, etc.
         */
        _addFee(FeeType.Rfi, 20, address(this));
        _addFee(FeeType.External, 50, fundAddress);
        _addFee(FeeType.Liquidity, 40, address(this));
        _addFee(FeeType.External, 40, rndAddress);
    }

    function _getFeesCount() internal view returns (uint256) {
        return fees.length;
    }

    function _getFeeStruct(uint256 index) private view returns (Fee storage) {
        require(
            index >= 0 && index < fees.length,
            "FeesSettings._getFeeStruct: Fee index out of bounds"
        );
        return fees[index];
    }

    //INFO: changed "internal" to "public" to access it for the unit tests and _getFee -> getFee
    function getFee(uint256 index)
        public
        view
        returns (
            FeeType,
            uint256,
            address,
            uint256
        )
    {
        Fee memory fee = _getFeeStruct(index);
        return (fee.name, fee.value, fee.recipient, fee.total);
    }

    // For fee at index 'index' (i.e. marketting), add an amount 'amount' to the total of that fee
    function _addFeeCollectedAmount(uint256 index, uint256 amount) internal {
        Fee storage fee = _getFeeStruct(index);
        fee.total = fee.total.add(amount);
    }

    // Get the total of a fee
    function getCollectedFeeTotal(uint256 index)
        external
        view
        returns (uint256)
    {
        Fee memory fee = _getFeeStruct(index);
        return fee.total;
    }
}

// Part: Antiwhale

//////////////////////////////////////////////////////////////////////////
abstract contract Antiwhale is Tokenomics {
    /**
     * @dev Returns the total sum of fees (in percents / per-mille - this depends on the FEES_DIVISOR value)
     *
     * NOTE: Currently this is just a placeholder. The parameters passed to this function are the
     *      sender's token balance and the transfer amount. An *antiwhale* mechanics can use these
     *      values to adjust the fees total for each tx
     */
    // function _getAntiwhaleFees(uint256 sendersBalance, uint256 amount) internal view returns (uint256){
    function _getAntiwhaleFees(uint256, uint256)
        internal
        view
        returns (uint256)
    {
        return sumOfFees;
    }
}

// Part: Liquifier

abstract contract Liquifier is Ownable, Manageable {
    using SafeMath for uint256;

    uint256 private withdrawableBalance;

    enum Env {
        Testnet,
        MainnetV1,
        MainnetV2
    }
    Env private _env;
    // multisig contract for the safety of the lp tokens
    address private multiSigWallet = 0x42489c73E040fF7a3dA77294A54fA0a617550072;
    // PancakeSwap V1
    address private _mainnetRouterV1Address =
        0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    // PancakeSwap V2
    address private _mainnetRouterV2Address =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // Testnet
    // Rinkeby/Kovan: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    // BSC testnet (also for PCS testnet + lil bit more fees ofc): 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    // BSC testnet (not for PCS + less creation fees): 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    // PancakeSwap Testnet = https://pancake.kiemtienonline360.com/
    address private _testnetRouterAddress =
        0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    IPancakeV2Router internal _router;
    address internal _pair; // PanCakeSwap pair

    bool private inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true; // if set to false, the liq fee on each tx will stay inside the contract and won't go to the lp FIXME be able to transfer these if it's the case

    uint256 private maxTransactionAmount;
    uint256 private thresholdSwapToLiquidity;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event RouterSet(address indexed router);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(
        uint256 tokenAmountSent,
        uint256 ethAmountSent,
        uint256 liquidity
    );

    receive() external payable {}

    function initializeLiquiditySwapper(
        Env env,
        uint256 maxTx,
        uint256 liquifyAmount
    ) internal {
        _env = env;
        if (_env == Env.MainnetV1) {
            _setRouterAddress(_mainnetRouterV1Address);
        } else if (_env == Env.MainnetV2) {
            _setRouterAddress(_mainnetRouterV2Address);
        }
        /*(_env == Env.Testnet)*/
        else {
            _setRouterAddress(_testnetRouterAddress);
        }

        maxTransactionAmount = maxTx;
        thresholdSwapToLiquidity = liquifyAmount;
    }

    /**
     * NOTE: passing the `contractTokenBalance` here is preferred to creating `balanceOfDelegate`
     */
    function liquify(uint256 contractTokenBalance, address sender) internal {
        if (contractTokenBalance >= maxTransactionAmount)
            contractTokenBalance = maxTransactionAmount;

        bool isOverRequiredTokenBalance = (contractTokenBalance >=
            thresholdSwapToLiquidity);

        /**
         * - first check if the contract has collected enough tokens to swap and liquify
         * - then check swap and liquify is enabled
         * - then make sure not to get caught in a circular liquidity event
         * - finally, don't swap & liquify if the sender is the PanCakeSwap pair
         */
        if (
            isOverRequiredTokenBalance &&
            swapAndLiquifyEnabled &&
            !inSwapAndLiquify &&
            (sender != _pair)
        ) {
            // TODO check if the `(sender != _pair)` is necessary because that basically
            // stops swap and liquify for all "buy" transactions
            _swapAndLiquify(contractTokenBalance);
        }
    }

    /**
     * @dev sets the router address and created the router, factory pair to enable
     * swapping and liquifying (contract) tokens
     */
    function _setRouterAddress(address router) private {
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(router);
        _pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(
            address(this),
            _newPancakeRouter.WETH()
        );
        _router = _newPancakeRouter;
        emit RouterSet(router);
    }

    // The tokens inside the contract (for liq.) are split 50/50 (i.e. token-bnb (Swap)) and added to the liquidity (hence the AndLiquify)
    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        _swapTokensForEth(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to PanCakeSwap
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the PanCakeSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approveDelegate(address(this), address(_router), tokenAmount);

        // make the swap
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            // The minimum amount of output tokens that must be received for the transaction not to revert.
            // 0 = accept any amount (slippage is inevitable)
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // Add liquidity manually after the deployment
    // https://docs.pancakeswap.finance/code/smart-contracts/pancakeswap-exchange/router-v2
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approveDelegate(address(this), address(_router), tokenAmount);

        // add the liquidity
        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = _router
            .addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            // Bounds the extent to which the WBNB/token price can go up before the transaction reverts.
            // Must be <= amountTokenDesired; 0 = accept any amount (slippage is inevitable)
            0,
            // Bounds the extent to which the token/WBNB price can go up before the transaction reverts.
            // 0 = accept any amount (slippage is inevitable)
            0,
            // this is a centralized risk if the owner's account is ever compromised (see Certik SSL-04)
            multiSigWallet, //FIXME: can I put the contract address?
            block.timestamp
        );

        /**
         * The swapAndLiquify function converts half of the contractTokenBalance SafeMoon tokens to BNB.
         * For every swapAndLiquify function call, a small amount of BNB remains in the contract.
         * This amount grows over time with the swapAndLiquify function being called throughout the life
         * of the contract. The Safemoon contract does not contain a method to withdraw these funds,
         * and the BNB will be locked in the Safemoon contract forever.
         */
        withdrawableBalance = address(this).balance;
        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);
    }

    /**
     * @dev Sets the PanCakeSwapV2 pair (router & factory) for swapping and liquifying tokens.
     * This is a precaution taken to upgrade the router address if PancakeSwap decided to move on to v3
     */
    function setRouterAddress(address router) external onlyManager {
        _setRouterAddress(router);
    }

    /**
     * @dev Sends the swap and liquify flag to the provided value. If set to `false` tokens collected in the contract will
     * NOT be converted into liquidity.
     */
    function setSwapAndLiquifyEnabled(bool enabled) external onlyManager {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }

    /**
     * @dev The owner can withdraw BNB collected in the contract from `swapAndLiquify`
     * or if someone (accidentally) sends BNB directly to the contract.
     *
     * Note: This addresses the contract flaw pointed out in the Certik Audit of Safemoon (SSL-03):
     *
     * The swapAndLiquify function converts half of the contractTokenBalance SafeMoon tokens to BNB.
     * For every swapAndLiquify function call, a small amount of BNB remains in the contract.
     * This amount grows over time with the swapAndLiquify function being called
     * throughout the life of the contract. The Safemoon contract does not contain a method
     * to withdraw these funds, and the BNB will be locked in the Safemoon contract forever.
     * https://www.certik.org/projects/safemoon
     */
    function withdrawLockedEth(address payable recipient) external onlyManager {
        require(
            recipient != address(0),
            "Cannot withdraw the BNB balance to the zero address"
        );
        require(
            withdrawableBalance > 0,
            "The BNB balance must be greater than 0"
        );

        // prevent re-entrancy attacks
        uint256 amount = withdrawableBalance;
        withdrawableBalance = 0;
        recipient.transfer(amount);
    }

    /**
     * @dev Use this delegate instead of having (unnecessarily) extend `BaseRfiToken` to gained access
     * to the `_approve` function.
     */
    function _approveDelegate(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual;
}

// Part: Presaleable

/**
 * The fee tokenomics start after the token auction. To achive this, a "isInPresale" flag is used.
 * As soon as the auction ends, the contract manager can set this value to false. This will start
 * ->fee deduction<- as per as per the tokenomics mentioned above.
 */
abstract contract Presaleable is Manageable {
    bool internal isInPresale;

    function setPreseableEnabled(bool value) external onlyManager {
        isInPresale = value;
    }
}

// Part: BaseRfiToken

abstract contract BaseRfiToken is
    IERC20,
    IERC20Metadata,
    Ownable,
    Presaleable,
    Tokenomics
{
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) internal _reflectedBalances;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    mapping(address => bool) internal _isExcludedFromFee;

    /** The difference between "_isExcludedFromRewards" and "_excluded"
     * Instead of each time looping through the whole array of exluded reward addresses, we map them and this will,
     * with only 1 call, tell us if it will be in the array or not. Example of function balanceOf:
     * There is no such code of x being an array and p an element: if(p in x) this doesnt exist. we need to loop over the array
     */
    mapping(address => bool) internal _isExcludedFromRewards;
    address[] private _excluded; //only excluded

    constructor() {
        _reflectedBalances[owner()] = _reflectedSupply;

        // exclude owner, R&D and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[rndAddress] = true;
        _isExcludedFromFee[controlledBurnAddress] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude this contract from rewards
        _exclude(address(this));

        emit Transfer(address(0), owner(), TOTAL_SUPPLY);
    }

    /** Functions required by IERC20Metadat **/
    function name() external pure override returns (string memory) {
        return NAME;
    }

    function symbol() external pure override returns (string memory) {
        return SYMBOL;
    }

    function decimals() external pure override returns (uint8) {
        return DECIMALS;
    }

    /** Functions required by IERC20Metadat - END **/

    /** Functions required by IERC20 **/
    function totalSupply() external pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromRewards[account]) return _balances[account];
        return tokenFromReflection(_reflectedBalances[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    //INFO: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/1494
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromRewards[account];
    }

    /**
     * @dev Calculates and returns the reflected amount for the given amount with or without
     * the transfer fees (deductTransferFee true/false)
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external
        view
        returns (uint256)
    {
        require(tAmount <= TOTAL_SUPPLY, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount, 0);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(
                tAmount,
                _getSumOfFees(_msgSender(), tAmount)
            );
            return rTransferAmount;
        }
    }

    /**
     * @dev Calculates and returns the amount of tokens corresponding to the given reflected amount.
     */
    function tokenFromReflection(uint256 rAmount)
        internal
        view
        returns (uint256)
    {
        require(
            rAmount <= _reflectedSupply,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcludedFromRewards[account], "Account is not included");
        _exclude(account);
    }

    function _exclude(address account) internal {
        if (_reflectedBalances[account] > 0) {
            _balances[account] = tokenFromReflection(
                _reflectedBalances[account]
            );
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balances[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function setExcludedFromFee(address account, bool value)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = value;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(
            owner != address(0),
            "BaseRfiToken: approve from the zero address"
        );
        require(
            spender != address(0),
            "BaseRfiToken: approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _isUnlimitedSender(address account) internal view returns (bool) {
        // the owner should be the only whitelisted sender
        return (account == owner());
    }

    function _isUnlimitedRecipient(address account)
        internal
        view
        returns (bool)
    {
        // the owner should be a white-listed recipient
        // and anyone should be able to burn as many tokens as
        // he/she wants
        return (account == owner() ||
            account == controlledBurnAddress ||
            account == rndAddress);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(
            sender != address(0),
            "BaseRfiToken: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "BaseRfiToken: transfer to the zero address"
        );
        require(
            sender != address(fundAddress),
            "BaseRfiToken: transfer from the fund address"
        );
        require(amount > 0, "Transfer amount must be greater than zero");

        // indicates whether or not feee should be deducted from the transfer
        bool takeFee = true;

        if (isInPresale) {
            takeFee = false;
        } else {
            /**
             * Check the amount is within the max allowed limit as long as a
             * unlimited sender/recepient is not involved in the transaction
             */
            if (
                amount > maxTransactionAmount &&
                !_isUnlimitedSender(sender) &&
                !_isUnlimitedRecipient(recipient)
            ) {
                revert("Transfer amount exceeds the maxTxAmount.");
            }
            /**
             * The pair needs to excluded from the max wallet balance check;
             * selling tokens is sending them back to the pair (without this
             * check, selling tokens would not work if the pair's balance
             * was over the allowed max)
             *
             * Note: This does NOT take into account the fees which will be deducted
             *       from the amount. As such it could be a bit confusing
             */
            if (
                maxWalletBalance > 0 &&
                !_isUnlimitedSender(sender) &&
                !_isUnlimitedRecipient(recipient) &&
                !_isV2Pair(recipient)
            ) {
                uint256 recipientBalance = balanceOf(recipient);
                require(
                    recipientBalance + amount <= maxWalletBalance,
                    "New balance would exceed the maxWalletBalance"
                );
            }
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        _beforeTokenTransfer(sender, recipient, amount, takeFee);
        _transferTokens(sender, recipient, amount, takeFee);
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        /**
         * We don't need to know anything about the individual fees here
         * (like Safemoon does with `_getValues`). All that is required
         * for the transfer is the sum of all fees to calculate the % of the total
         * transaction amount which should be transferred to the recipient.
         *
         * The `_takeFees` call will/should take care of the individual fees
         */
        uint256 sumOfFees = _getSumOfFees(sender, amount);
        if (!takeFee) {
            sumOfFees = 0;
        }

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tAmount,
            uint256 tTransferAmount,
            uint256 currentRate
        ) = _getValues(amount, sumOfFees);

        /**
         * Sender's and Recipient's reflected balances must be always updated regardless of
         * whether they are excluded from rewards or not.
         */
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(rAmount);
        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(
            rTransferAmount
        );

        /**
         * Update the true/nominal balances for excluded accounts
         */
        if (_isExcludedFromRewards[sender]) {
            _balances[sender] = _balances[sender].sub(tAmount);
        }
        if (_isExcludedFromRewards[recipient]) {
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
        }

        _takeFees(amount, currentRate, sumOfFees);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeFees(
        uint256 amount,
        uint256 currentRate,
        uint256 sumOfFees
    ) private {
        if (sumOfFees > 0 && !isInPresale) {
            _takeTransactionFees(amount, currentRate);
        }
    }

    function _getValues(uint256 tAmount, uint256 feesSum)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 currentRate = _getCurrentRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);

        return (
            rAmount,
            rTransferAmount,
            tAmount,
            tTransferAmount,
            currentRate
        );
    }

    function _getCurrentRate() internal view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() internal view returns (uint256, uint256) {
        uint256 rSupply = _reflectedSupply;
        uint256 tSupply = TOTAL_SUPPLY;

        /**
         * The code below removes balances of addresses excluded from rewards from
         * rSupply and tSupply, which effectively increases the % of transaction fees
         * delivered to non-excluded holders
         */
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectedBalances[_excluded[i]] > rSupply ||
                _balances[_excluded[i]] > tSupply
            ) return (_reflectedSupply, TOTAL_SUPPLY);
            rSupply = rSupply.sub(_reflectedBalances[_excluded[i]]);
            tSupply = tSupply.sub(_balances[_excluded[i]]);
        }
        if (tSupply == 0 || rSupply < _reflectedSupply.div(TOTAL_SUPPLY))
            return (_reflectedSupply, TOTAL_SUPPLY);
        return (rSupply, tSupply);
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     */
    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) internal virtual;

    /**
     * @dev Returns the total sum of fees to be processed in each transaction.
     *
     * To separate concerns this contract (class) will take care of ONLY handling RFI, i.e.
     * changing the rates and updating the holder's balance (via `_redistribute`).
     * It is the responsibility of the dev/user to handle all other fees and taxes
     * in the appropriate contracts (classes).
     */
    function _getSumOfFees(address sender, uint256 amount)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @dev A delegate which should return true if the given address is the V2 Pair and false otherwise
     */
    function _isV2Pair(address account) internal view virtual returns (bool);

    /**
     * @dev Redistributes the specified amount among the current holders via the reflect.finance
     * algorithm, i.e. by updating the _reflectedSupply (_rSupply) which ultimately adjusts the
     * current rate used by `tokenFromReflection` and, in turn, the value returns from `balanceOf`.
     * This is the bit of clever math which allows rfi to redistribute the fee without
     * having to iterate through all holders.
     */
    function _redistribute(
        uint256 amount,
        uint256 currentRate,
        uint256 fee,
        uint256 index
    ) internal {
        uint256 tFee = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rFee = tFee.mul(currentRate);

        _reflectedSupply = _reflectedSupply.sub(rFee);
        _addFeeCollectedAmount(index, tFee);
    }

    /**
     * @dev Hook that is called before the `Transfer` event is emitted if fees are enabled for the transfer
     */
    function _takeTransactionFees(uint256 amount, uint256 currentRate)
        internal
        virtual;
}

// Part: VokenToken

//////////////////////////////////////////////////////////////////////////

abstract contract VokenToken is BaseRfiToken, Liquifier, Antiwhale {
    using SafeMath for uint256;

    // constructor(string memory _name, string memory _symbol, uint8 _decimals){
    constructor(Env _env) {
        initializeLiquiditySwapper(
            _env,
            maxTransactionAmount,
            thresholdSwapToLiquidity
        );

        // exclude the pair address and fund from rewards - we don't want to redistribute
        // tx fees to these two; redistribution is only for holders, dah!
        _exclude(_pair);
        _exclude(fundAddress);
    }

    function _isV2Pair(address account) internal view override returns (bool) {
        return (account == _pair);
    }

    function _getSumOfFees(address sender, uint256 amount)
        internal
        view
        override
        returns (uint256)
    {
        return _getAntiwhaleFees(balanceOf(sender), amount);
    }

    // function _beforeTokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal override {
    function _beforeTokenTransfer(
        address sender,
        address,
        uint256,
        bool
    ) internal override {
        if (!isInPresale) {
            uint256 contractTokenBalance = balanceOf(address(this));
            liquify(contractTokenBalance, sender);
        }
    }

    function _takeTransactionFees(uint256 amount, uint256 currentRate)
        internal
        override
    {
        if (isInPresale) {
            return;
        }

        uint256 feesCount = _getFeesCount();
        for (uint256 index = 0; index < feesCount; index++) {
            (FeeType name, uint256 value, address recipient, ) = getFee(index);
            // no need to check value < 0 as the value is uint (i.e. from 0 to 2^256-1)
            if (value == 0) continue;

            if (name == FeeType.Rfi) {
                _redistribute(amount, currentRate, value, index);
            } else {
                _takeFee(amount, currentRate, value, recipient, index);
            }
        }
    }

    function _takeFee(
        uint256 amount,
        uint256 currentRate,
        uint256 fee,
        address recipient,
        uint256 index
    ) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(
            rAmount
        );
        if (_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);

        _addFeeCollectedAmount(index, tAmount);
    }

    function _approveDelegate(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        _approve(owner, spender, amount);
    }
}

// File: VokenToken.sol

contract VokenTokenV2 is VokenToken {
    constructor() VokenToken(Env.Testnet) {
        // pre-approve the initial liquidity supply (to safe a bit of time)
        _approve(owner(), address(_router), ~uint256(0));
    }
}