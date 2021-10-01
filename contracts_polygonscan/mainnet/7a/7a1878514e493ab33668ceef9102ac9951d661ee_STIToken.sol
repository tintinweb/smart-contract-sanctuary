/**
 *Submitted for verification at polygonscan.com on 2021-10-01
*/

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.0;

/*
 * STI - Les STI2D rentrent dans la finance
 * 
 * Nombre de token max:     69,420,000      STI - 100%
 *
 * Pour eviter une volatilité trop grande chaque transaction subit des frais. Les frais de transaction commence 
 * initialement a 10% puis baisse tous les jours de 1%. Si vous ne voulez pas attendre que vos frais baisse
 * vous pouvez tirer un nombre aleatoire de 1 a 20 et cela definira vos frais a la prochaine transaction.
 *
 * 50% des frais de transaction sont redistribuer a tous les detenteurs de STI
 * 50% vont dans la liquiditer de quickswap 
 */

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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

        (bool success, ) = recipient.call{value: amount}("");
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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

interface ISwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface ISwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface ISwapRouter01 {
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

interface ISwapRouter02 is ISwapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IRandom {
    function getRandom(address sender) external returns (uint randomNumber);

    function getViewRandom(address sender) external view returns (uint randomNumber);
}

/// @title La monaie du peuple
/// @author Alexandre Frede (@B0ssSuricate) <[email protected]>
/// @dev Le smart contract qui va revolutionner la DEFI !
contract STIToken is IERC20, Ownable {
    using Address for address;

    /// @dev L'address d'un router (QuickSwap)
    address private constant SWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    /// @dev Ben le nom quoi
    string private _name = "STI2D COIN";
    /// @dev Son symbol commme Bitcoin -> BTC
    string private _symbol = "STI";
    /// @dev Combien de chiffre apres la virgule
    uint8 private _decimals = 18;

    /// @dev liste des personne/contract qui non pas a payer de frais de transaction
    mapping (address => bool) private _isExcludedFromFee;
    /// @dev liste des personne/contract qui ne recevrons pas les frais de transaction
    mapping (address => bool) private _isExcludedFromReward;
    /// @dev liste des personne/contract qui non pas de reward
    address[] private _excluded;

    event ExcludedFromReward(address indexed user, bool excluded);
    event ExcludedFromFees(address indexed user, bool excluded);
    event ChangeMaxNormalFees(uint previous, uint now);
    event ChangeMaxRandomFees(uint previous, uint now);
    event ChangeOneDay(uint previous, uint now);
    event ChangeRandomContract(address previous, address now);
    event ChangeFeeLoose(uint previous, uint now);
    event ChangeMaxTransaction(uint previous, uint now);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event Withdraw(uint amount, address indexed token);
    event ChangeAutoDecrease(bool enabled);

    /// @dev Cette evenement donne les informations necessaire au bon fonctionnement des noeuds
    event TransferMessage(address from, address to, string message, uint amount, uint fee);


    /// @dev Relies vos wallet avec la reflection en gros les rewards
    mapping (address => uint256) private _rOwned;
    /// @dev Relies vos wallet avec ce que vous posseder sans reward
    mapping (address => uint256) private _tOwned;
    /// @dev Relie vos wallet au wallet que vous accorder de recuperer de l'argents
    /// utile pour les smart contract
    mapping (address => mapping (address => uint256)) private _allowances;

    /// @dev les frais maximum lorsque vous jouer au hasard
    uint256 public _maxRandFee = 20000; // 20%
    uint256 public _previousMaxRandFee = _maxRandFee;
    /// @dev les frais initiaux lorsque vous decider d'attendre
    uint256 public _defaultStartingFee = 10000; // 10%
    uint256 public _previousDefaultStartingFee = _defaultStartingFee;
    /// @dev Le nombre de block pour definir une journee
    uint256 public _oneDayInBlock = 28800;
    /// @dev Combien de frais on perd par jour
    uint256 public _everyDayFeesLoss = 1000; // 1% par jour
    /// @dev Garde en memoire les frais que vous deveze payer si vous
    /// choisie les frais au hasard
    uint nextFees = 0;
    /// @dev garde en memoire le block de la derniere transaction envoyer par une adresse
    mapping(address => uint) _lastTransactionBlock;

    /// @dev totale du supply max
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 69420000 * 10 ** _decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    /// @dev Le nombre constant de STIPW qui existe
    uint256 public _totalSupply = _tTotal;
    /// @dev Definie une limite de STIPW transferable dans la meme transaction
    /// cela fait baisser la volatilitee. Ici definit a 1%
    uint256 public _maxTxAmount = (_totalSupply * 40 )/100;
    /// @dev Definie le minimum de token pour pouvoir swap 0.0025% du supply
    uint256 public numTokensSellToAddToLiquidity = (_totalSupply * 25 )/1000000;

    /// @dev l'address pour echanger des STIPW <-> BNB
    address public pair;
    /// @dev le contrat router de pancakeswap
    ISwapRouter02 public immutable router;
    /// @dev le contrat qui permet d'avoir du random
    IRandom public randomContract;

    /// @dev permet d'empecher de boucler sur les swap
    bool private inSwapAndLiquify;
    /// @dev permet d'activer ou desactiver les swap manuellement
    bool public swapAndLiquifyEnabled = false;
    /// @dev active ou desactive la decroissance des frais de transaction avec le temps
    bool public autoDecrease = true;

    /// @dev Permet de recevoir des BNB lors des swap... Et bon je suis pas contre
    /// une petite donation (owner)
    receive() external payable {}

    constructor(address randomContractAddress) {
        _rOwned[_msgSender()] = _rTotal;

        ISwapRouter02 _router = ISwapRouter02(SWAP_ROUTER);
        router = _router;

        IRandom _randomContract = IRandom(randomContractAddress);
        randomContract = _randomContract;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
    }

    /// @dev Permet d'empecher les rebouclage de swap
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /// @dev Permet d'empecher les rebouclage de swap
    modifier tranferNextFees {
        nextFees = randomContract.getRandom(_msgSender());
        _;
        nextFees = 0;
    }

    /// @dev Retourne Sti Power
    function name() public view returns (string memory) {
        return _name;
    }

    /// @dev Retourne STIPW
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @dev Retourne le nombre de decimal
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /// @dev Retourne le nombre de decimal
    function getRandomContract() public view returns (address) {
        return address(randomContract);
    }

    /// @dev Retourne ce que possedent
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /// @dev Permet de transferee votre pouvoir d'autisme
    function transfer(address recipient, uint256 amount) public override tranferNextFees returns (bool) {
        _transfer(_msgSender(), recipient, amount, "");
        return true;
    }

    /// @dev Permet de transferee votre pouvoir d'autisme
    function transferMessage(address recipient, uint256 amount, string memory message) public tranferNextFees returns (bool) {
        require(bytes(message).length < 1024, "STI: Message must be less than 256 characters");
        _transfer(_msgSender(), recipient, amount, message);
        return true;
    }

    /// @dev Permet de savoir la quantite qui est allouer a une autre address
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @dev Permet de laisser une autre address utiliser vos STIPW
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    /// @dev le nombre totale de STIPW
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev Acheter des STIPW avec des BNB
    function buyTokens() public payable {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, _msgSender(), block.timestamp);
    }

    /// @dev La fonction appeler par la personne que vous avez autoriser a prendre vos STIPW
    function transferFrom(address sender, address recipient, uint256 amount) public override tranferNextFees returns (bool) {
        _transfer(sender, recipient, amount, "");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    /// @dev augmenter la quantiter de STIPW que peut prendre le spender
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /// @dev baisser la quantiter de STIPW que peut prendre le spender
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    /// @dev Permet de savoir si une address recois les frais de transaction
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    /// @dev Permet de savoir si une address recois les frais de transaction
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, address account, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "STI: Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount, account);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount, account);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "STI: Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    /// @dev Exclu un wallet des recompense des frais de transaction
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
        emit ExcludedFromReward(account, true);
    }

    /// @dev Rajouter un wallet des recompense des frais de transaction
    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "STI: Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }
        emit ExcludedFromReward(account, false);
    }

    /// @dev permet de cree une pair au token
    function createTokenPair() external onlyOwner {
        pair = ISwapFactory(router.factory()).createPair(address(this), router.WETH());
    }

    /// @dev permet de rajouter de la liquiditer manuellement
    function setTokenPrice() external onlyOwner lockTheSwap {
        addLiquidity(balanceOf(address(this)), address(this).balance);
    }

    /// @dev Na plus a payer des frais de transaction
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFees(account, true);
    }
    
    /// @dev Na plus a payer des frais de transaction
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        emit ExcludedFromFees(account, false);
    }

    /// @dev Pour definir _maxRandFee
    function setMaxRandomFee(uint256 maxRandomFee) external onlyOwner() {
        emit ChangeMaxRandomFees(_maxRandFee, maxRandomFee);
        _maxRandFee = maxRandomFee;
    }

    /// @dev Pour definir _defaultStartingFee
    function setDefaultFee(uint256 defaultFee) external onlyOwner() {
        emit ChangeMaxNormalFees(_defaultStartingFee, defaultFee);
        _defaultStartingFee = defaultFee;
    }

    /// @dev Pour definir _defaultStartingFee
    function setOneDayInBlock(uint256 oneDayInBlock) external onlyOwner() {
        emit ChangeOneDay(_oneDayInBlock, oneDayInBlock);
        _oneDayInBlock = oneDayInBlock;
    }

    /// @dev Pour definir _defaultStartingFee
    function setRandomContract(address randomAddress) external onlyOwner() {
        emit ChangeRandomContract(address(randomContract), randomAddress);
        randomContract = IRandom(randomAddress);
    }

    /// @dev Change
    function setFeeLoose(uint256 feeLoose) external onlyOwner() {
        emit ChangeFeeLoose(_everyDayFeesLoss, feeLoose);
        _everyDayFeesLoss = feeLoose;
    }

    /// @dev Pour definir _maxTxAmount
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent <= 100, "STI: You can't send more than max supply");
        uint nextTxAmount = _tTotal * maxTxPercent / 100;
        emit ChangeMaxTransaction(_maxTxAmount, nextTxAmount);
        _maxTxAmount = nextTxAmount;
    }

    /// @dev Pour definir swapAndLiquifyEnabled
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        emit SwapAndLiquifyEnabledUpdated(_enabled);
        swapAndLiquifyEnabled = _enabled;
    }

    /// @dev Pour definir autoDecrease
    function setAutoDecrease(bool _enabled) public onlyOwner {
        emit ChangeAutoDecrease(_enabled);
        autoDecrease = _enabled;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }
    
    function _getValues(uint256 tAmount, address account) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount, account);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount, address account) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(account, tAmount);
        uint256 tLiquidity = calculateLiquidityFee(account, tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply / _rOwned[_excluded[i]];
            tSupply = tSupply / _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }

    function getFeesFor(address account, uint256 amount) view external returns (uint tFee, uint tLiquidty) {
        if(_isExcludedFromFee[account]) {
            return (0,0);
        }

        uint determinedFees = randomContract.getViewRandom(account);
        if(determinedFees != 0) {
            if(swapAndLiquifyEnabled) {
                return (determinedFees/200000,determinedFees/200000);
            } else {

                return (determinedFees / 100000, 0);
            }
        }

        return (calculateTaxFee(account, amount), calculateLiquidityFee(account, amount));
    }

    function calculateTaxFee(address account, uint256 _amount) private view returns (uint256) {
        uint determinedFees = nextFees;
        uint divider;
        if(swapAndLiquifyEnabled) {
            divider = 200000;
        } else {
            divider = 100000;
        }

        if(_defaultStartingFee == 0 && _maxRandFee == 0) {
            return 0;
        }

        if(determinedFees == 0){
            determinedFees = _defaultStartingFee;
            if(autoDecrease) {
                uint daysElapsed = (block.number - _lastTransactionBlock[account]) / _oneDayInBlock;
                for (uint256 i = 0; i < daysElapsed; i++) {
                    determinedFees = (determinedFees * (100000 - _everyDayFeesLoss))/100000;
                    if(determinedFees == 0) break;
                }
            }
        }
        return (_amount * determinedFees) / divider;
    }

    function calculateLiquidityFee(address account, uint256 _amount) private view returns (uint256) {
        if(swapAndLiquifyEnabled) {
            return calculateTaxFee(account, _amount);
        } else {
            return 0;
        }
    }
    
    function removeAllFee() private {
        if(_maxRandFee == 0 && _defaultStartingFee == 0) return;
        
        _previousMaxRandFee = _maxRandFee;
        _previousDefaultStartingFee = _defaultStartingFee;
        
        _maxRandFee = 0;
        _defaultStartingFee = 0;
    }
    
    function restoreAllFee() private {
        _defaultStartingFee = _previousDefaultStartingFee;
        _maxRandFee = _previousMaxRandFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }



    /// @dev Fonction interne pour transerer des STIPW
    function _transfer(
        address from,
        address to,
        uint256 amount,
        string memory message
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address"); // Pas trop parano le gars
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "STI: Transfer amount must be greater than zero");
        if(from != owner() && to != owner()) require(amount <= _maxTxAmount, "STI: Transfer amount exceeds the maxTxAmount.");

        // On doit verifier que le contract possede bien assez pour effectuer
        // un swap + rajouter la liquiditer
        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance =
            contractTokenBalance >= numTokensSellToAddToLiquidity;
        
        // Si le contrat possede plus de STIPW que ce qu'il est possible d'envoyer
        // alors on envoie le maximum possible
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
    
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pair &&
            swapAndLiquifyEnabled
        ) {
            // Rajoute la liquiditer
            swapAndLiquify(contractTokenBalance);
        }
        
        // Est ce que les frais doivent etre appliquer ?
        bool takeFee = true;
        
        // Frais exclu si l'envoyeur ou le receveur est exclu de frais
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        // et enfin on applique le transfer
        _tokenTransfer(from,to,amount,takeFee, message);

        _lastTransactionBlock[from] = block.number;
        if(_lastTransactionBlock[to] == 0){
            _lastTransactionBlock[to] = block.number;
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee, string memory message) private {
        if(!takeFee) removeAllFee();
        
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount, message);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount, message);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, amount, message);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount, message);
        } else {
            _transferStandard(sender, recipient, amount, message);
        }
        
        if(!takeFee){
            restoreAllFee();
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, string memory message) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, sender);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        emit TransferMessage(_msgSender(), recipient, message, tAmount, tFee + tLiquidity);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, string memory message) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, sender);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        emit TransferMessage(_msgSender(), recipient, message, tAmount, tFee + tLiquidity);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount, string memory message) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, sender);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        emit TransferMessage(_msgSender(), recipient, message, tAmount, tFee + tLiquidity);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, string memory message) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, sender);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        emit TransferMessage(_msgSender(), recipient, message, tAmount, tFee + tLiquidity);
    }

    /// @dev Fonction qui permet de transformer 50% des frais de transaction en liquidity
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // On cree deux variable qui possedent la meme quantiter de STIPW
        uint256 half = contractTokenBalance / 2; // A convertir en BNB
        uint256 otherHalf = contractTokenBalance - half; // A laisser en STIPW

        // On recupere le sold actuel du contract pour eviter de melanger
        // les BNB que on va acheter et ce qu'on a envoyer au contrat
        // manuellement
        uint256 initialBalance = address(this).balance;

        // On swap les tokens
        swapTokensForEth(half);

        // On peut savoir combien on a obtenu grace a la difference de ce qu'on
        // possedais puis ce que l'on apres le swap
        uint256 newBalance = address(this).balance - initialBalance;

        // Et on rajoute la liquiditer a PancakeSwap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    /// @dev Nous permet d'acheter du BNB pour du STIPW
    function swapTokensForEth(uint256 tokenAmount) private {
        // bon rien d'insterresent ici
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // On autorise le Router de nous prendre des STIPW
        _approve(address(this), address(router), tokenAmount);

        // On effectue le swap STIPW <-> BNB
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Nous permet de rajouter de la liquiditer a PancakeSwap
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // On autorise le Router de nous prendre des STIPW
        _approve(address(this), address(router), tokenAmount);

        // Et on rajoute la liquiditer
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    /// @dev Permet de laisser une autre address recuperer vos STIPW
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @dev recuperer les BNB envoyer par donation
    function rescueBNBFromContract() external onlyOwner {
        emit Withdraw(address(this).balance, address(0));
        payable(_msgSender()).transfer(address(this).balance);
    }

    /// @dev owner peut recuperer les token envoyer par donation
    /// @dev Mais ne peux pas recuperer les STIPW
    function transferAnyBEP20Tokens(address _tokenAddr, uint _amount) public onlyOwner {
        require(_tokenAddr != address(this), "STI: Cannot transfer out STI2D Coin !");
        emit Withdraw(_amount, _tokenAddr);
        IERC20(_tokenAddr).transfer(_msgSender(), _amount);
    }
}