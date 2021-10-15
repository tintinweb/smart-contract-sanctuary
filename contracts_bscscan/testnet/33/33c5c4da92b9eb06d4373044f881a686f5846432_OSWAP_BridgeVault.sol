/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// Sources flattened with hardhat v2.6.6 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

/*
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


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/libraries/TransferHelper.sol


pragma solidity >= 0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/OSWAP_Governance.sol


pragma solidity >= 0.8.6;

contract OSWAP_Governance {
    uint256 public superTrollMinStake;
    uint256 public generalTrollMinStake;
    uint256 public superTrollMinCount;
    uint256 public superTrollCount;
    address public govToken;

    mapping(address => address) public trollStakingAddress; 
    mapping(address => uint256) public trollStakingBalance;
    mapping(address => uint256) public stakingBalance;

    mapping(address => bool) public superTrollCandidates;
    mapping(address => bool) public isSuperTroll;

    event Stake(         
        address troll,
        uint256 amount,
        bool isSuperTroll,
        bool isGeneralTroll
    );
    event Unstake(         
        address troll,
        uint256 amount,
        bool isSuperTroll,
        bool isGeneralTroll
    );
    constructor(address _govToken, uint256 _minSuperTrollCount, uint256 _superTrollMinStake, uint256 _generalTrollMinStake){
        require(_superTrollMinStake > 1, "OSWAP_Governance: ");
        govToken = _govToken;
        superTrollMinCount = _minSuperTrollCount;
        superTrollMinStake = _superTrollMinStake;
        generalTrollMinStake = _generalTrollMinStake;
        superTrollCandidates[msg.sender] = true;
        isSuperTroll[msg.sender] = true;
        superTrollCount = 1;
    }
    function registerSuperTroll(address troll) external{
        require(isSuperTroll[msg.sender] == true, "OSWAP_Governance: ");
        superTrollCandidates[troll] = true;
        if (isSuperTroll[troll] == false && trollStakingBalance[troll] >= superTrollMinStake){
            isSuperTroll[troll] = true;
            superTrollCount ++;
        }
    }
    function isGeneralTroll(address troll) public view returns(bool){
        return isSuperTroll[troll] == false && trollStakingBalance[troll] >= generalTrollMinStake;
    }
    function stake(address troll, uint256 amount) external {      
        TransferHelper.safeTransferFrom(govToken, msg.sender, address(this), amount);
        uint256 stakedAmount = stakingBalance[msg.sender];
        address stakedAddress = trollStakingAddress[msg.sender];
        trollStakingBalance[stakedAddress] -= stakedAmount;

        if (isSuperTroll[stakedAddress] == true && trollStakingBalance[stakedAddress] < superTrollMinStake){
            isSuperTroll[stakedAddress] = false;
            superTrollCount --;
        }
        trollStakingAddress[msg.sender] = troll;
        stakingBalance[msg.sender] += amount;
        trollStakingBalance[troll] = stakingBalance[msg.sender];
        
        if (isSuperTroll[troll] == false && superTrollCandidates[troll] == true && trollStakingBalance[troll] >= superTrollMinStake){
            isSuperTroll[troll] = true;
            superTrollCount ++;
        }
        require(superTrollCount >= superTrollMinCount, "OSWAP_Governance: ");
        emit Stake(troll, amount, isSuperTroll[troll], isGeneralTroll(troll));
    }
    function unstake(uint256 amount) external {
        address stakedAddress = trollStakingAddress[msg.sender];
        stakingBalance[msg.sender] -= amount;
        trollStakingBalance[stakedAddress] -= amount;
        TransferHelper.safeTransfer(govToken, msg.sender, amount);
        if (isSuperTroll[stakedAddress] && trollStakingBalance[stakedAddress] < superTrollMinStake){
            isSuperTroll[stakedAddress] = false;
            superTrollCount --;
        }
        require(superTrollCount >= superTrollMinCount, "OSWAP_Governance: ");
        emit Unstake(stakedAddress, amount, isSuperTroll[stakedAddress], isGeneralTroll(stakedAddress));
    }
}


// File contracts/interfaces/IOAXDEX_HybridRouter2.sol


pragma solidity >= 0.8.6;

interface IOAXDEX_HybridRouter2 {

    function registry() external view returns (address);
    function WETH() external view returns (address);

    function getPathIn(address[] calldata pair, address tokenIn) external view returns (address[] memory path);
    function getPathOut(address[] calldata pair, address tokenOut) external view returns (address[] memory path);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata pair,
        address tokenIn,
        address to,
        uint deadline,
        bytes calldata data
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata pair,
        address tokenOut,
        address to,
        uint deadline,
        bytes calldata data
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address tokenIn,
        address to,
        uint deadline,
        bytes calldata data
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bytes calldata data
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bytes calldata data
    ) external;
}


// File contracts/OSWAP_BridgeVault.sol


pragma solidity >= 0.8.6;





contract OSWAP_BridgeVault is ERC20 {    
    OSWAP_Governance public governance;
    address public govToken;
    address public router;
    address public asset;
    uint256 public assetPrice;

    enum OrderStatus{pending, executed, requestCancel, approvedCancel, cancelled}

    // mapping(address => uint256) public liquidityBalance;
    mapping(address => uint256) public pendingWithdrawalAmount;
    mapping(address => uint256) public pendingWithdrawalTimeout;
    mapping(address => address) public trollStakingAddress; 
    mapping(address => uint256) public trollStakingBalance;
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public pendingUnstakeAmount;
    mapping(address => uint256) public pendingUnstakeTimeout;
    mapping(bytes32 => OrderStatus) public swapOrderStatus;
    
    struct Order {
        uint256 targetChain;
        uint256 inAmount;        
        address outToken;
        uint256 minOutAmount;
        address to;
        uint256 expire;
        OrderStatus status;
    }    
    mapping(address => Order[]) public orders;
    event NewOrder( 
        uint256 orderId,
        address owner,
        uint256 targetChain,
        uint256 inAmount,     
        address outToken,
        uint256 minOutAmount,
        address to,
        uint256 expire
    );
    event RequestCancelOrder(address owner, uint256 orderId);

    modifier onlyEndUser() {
        require(tx.origin == msg.sender, "OSWAP_BridgeVault: Not from end user or whitelisted");
        _;
    }
    constructor(OSWAP_Governance _governance, address _asset, address _router) ERC20("OSWAP Bridge Vault", "OSWAP-VAULT"){
        governance = _governance;
        govToken = governance.govToken();
        asset = _asset;
        router = _router;
    }
    function addLiquidity(uint256 amount) external {        
        TransferHelper.safeTransferFrom(asset, msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }
    // function cancelOrder(bytes[] memory signatures, uint256 price, address owner, uint256 orderId
    // ) external{
    //     Order memory order = orders[owner][orderId];
    //     require(order.status == OrderStatus.requestCancel, "OSWAP_BridgeVault: ");
    //     uint256 value = stakedValue(signatures, price, hashCancelOrderParams(price, owner, orderId));        
    //     require(value >= order.inAmount, "OSWAP_BridgeVault: ");        
    //     order.status = OrderStatus.approvedCancel;        
    // }
    function hashCancelOrderParams(uint256 price, address owner, uint256 orderId) internal view returns(bytes32){
        uint chainId;
        assembly {            
            chainId := chainid()
        }
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",keccak256(abi.encodePacked(chainId,address(this),price,owner,orderId))));
    }
    function hashSwapParams(bytes32 orderId, uint256 price, uint inAmount,
        address outToken,
        uint minOutAmount,
        address[] calldata pairs,
        address to,
        uint deadline
    ) internal view returns (bytes32){
        uint chainId;
        assembly {            
            chainId := chainid()
        }
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",keccak256(abi.encodePacked(chainId,address(this),orderId,price,inAmount,outToken,minOutAmount,pairs,to,deadline))));
    }
    function getChainId() public view returns (uint){
        uint chainId;
        assembly {            
            chainId := chainid()
        }
        return chainId;
    }
    function getOrderCount(address account) external view returns (uint256){
        return orders[account].length;
    }
    function getOrders(address account, uint256 start, uint256 length) external view returns (Order[] memory list) {
        Order[] memory accountOrders = orders[account];
        if (start < accountOrders.length) {
            if (start + length > accountOrders.length) {
                length = accountOrders.length - start;
            }
            list = new Order[](length);
            for (uint256 i = 0 ; i < length ; i++) {
                list[i] = accountOrders[i+start];
            }
        }
        return list;
    }
    function newOrder(uint256 targetChain, uint256 inAmount, address outToken, uint256 minOutAmount, address to, uint256 expire) external {
        TransferHelper.safeTransferFrom(asset, msg.sender, address(this), inAmount);
        Order memory order = Order({
            targetChain: targetChain,
            inAmount: inAmount,
            outToken: outToken,
            minOutAmount: minOutAmount,
            to: to,
            expire: expire,
            status: OrderStatus.pending
        });
        uint256 orderId = orders[msg.sender].length;
        orders[msg.sender].push(order);
        emit NewOrder(orderId, msg.sender, targetChain, inAmount, outToken, minOutAmount, to, expire);
    }
    function requestCancelOrder(uint256 orderId) external{        
        Order memory order = orders[msg.sender][orderId];
        require(order.status == OrderStatus.pending, "OSWAP_BridgeVault: ");

        orders[msg.sender][orderId].status = OrderStatus.requestCancel; //request cancel
        emit RequestCancelOrder(msg.sender, orderId);
    }
    function recover(bytes32 paramHash, bytes memory signature) internal pure returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (signature.length != 65) {
            return (address(0));
        }
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(paramHash, v, r, s);
        }
    }
    function removeLiquidity(uint256 amount) external {
        //TODO: move liquidity to pending withdrawal, increase withdrawal timeout for 24 hours
        TransferHelper.safeTransfer(asset, msg.sender, amount);
        _burn(msg.sender, amount);    
    }
    function stake(address troll, uint256 amount) external {
        //stake gov tokens for a troll, move existing staked amount if troll address changed
        TransferHelper.safeTransferFrom(govToken, msg.sender, address(this), amount);
        uint256 stakedAmount = stakingBalance[msg.sender];
        address stakedAddress = trollStakingAddress[msg.sender];
        trollStakingBalance[stakedAddress] = trollStakingBalance[stakedAddress] - stakedAmount;
        stakingBalance[msg.sender] = stakedAmount + amount;        
        trollStakingBalance[troll] = trollStakingBalance[troll] + stakedAmount + amount;
        trollStakingAddress[msg.sender] = troll;
    }    
    function stakedValue(bytes[] memory signatures, uint256 _assetPrice, bytes32 paramsHash) public view returns (uint256) {
        uint256 value; 
        //TODO check signatures for price update
        // assetPrice = _assetPrice;
        uint256 superTrollCount = 0;
        for (uint i = 0; i < signatures.length; ++i) {             
            address troll = recover(paramsHash, signatures[i]);
            if (governance.isSuperTroll(troll))
                superTrollCount ++;
            value += (trollStakingBalance[troll] * _assetPrice / 100000);
        }        
        require(superTrollCount >= signatures.length -1, "OSWAP_BridgeVault: SuperTroll signature count not met");
        require(superTrollCount >= governance.superTrollMinCount(), "OSWAP_BridgeVault: Mininum SuperTroll count not met");        
        return value;
    }
    function swapExactTokensForTokens(bytes[] memory signatures, 
        bytes32 orderId,
        uint256 price,         
        uint inAmount,
        address outToken,
        uint minOutAmount,
        address[] calldata pair,        
        address to,
        uint deadline
    ) external onlyEndUser returns (uint[] memory amounts){
        require(swapOrderStatus[orderId] == OrderStatus.pending,"OSWAP_BridgeVault: Order already processed");
        address[] memory paths = IOAXDEX_HybridRouter2(router).getPathIn(pair, asset);
        require(paths[paths.length-1] == outToken,"OSWAP_BridgeVault: Token out not match");
        bytes32 hash = hashSwapParams(orderId, price, inAmount, outToken, minOutAmount, pair, to, deadline);        
        uint256 value = stakedValue(signatures, price, hash);        
        require(value >= inAmount, "OSWAP_BridgeVault: Insufficient staked value");
        IERC20(asset).approve(router, inAmount);
        swapOrderStatus[orderId] = OrderStatus.executed;
        return IOAXDEX_HybridRouter2(router).swapExactTokensForTokens(inAmount, minOutAmount, pair, asset, to, deadline, "0x00");
    }
    function unstake(uint256 amount) external {
        //unstake gov tokens from a troll, move to pendingUnstake
        require(stakingBalance[msg.sender] >= amount,"");
        address stakedAddress = trollStakingAddress[msg.sender];
        stakingBalance[msg.sender] = stakingBalance[msg.sender] - amount;        
        trollStakingBalance[stakedAddress] = trollStakingBalance[stakedAddress] - amount;        
        pendingUnstakeAmount[msg.sender] = pendingUnstakeAmount[msg.sender] + amount;
        pendingUnstakeTimeout[msg.sender] = block.timestamp + 1 days;
    }
    // function voidOrder(bytes32 orderId, bytes[] memory signature) external {
    //     require(swapOrderStatus[orderId] == OrderStatus.pending,"OSWAP_BridgeVault: Order already processed");
    // }
    function withdrawLiquidity(uint256 lpTokenAmount) external {
        //check withdrawal timeout, burn vault token, return assets
    }  
    function withdrawStake(uint256 amount) external {
        //check withdrawal timeout, return gov tokens
        require(pendingUnstakeTimeout[msg.sender] > block.timestamp, "OSWAP_BridgeVault: ");
        require(pendingUnstakeAmount[msg.sender] >= amount, "OSWAP_BridgeVault: ");
        pendingUnstakeAmount[msg.sender] = pendingUnstakeAmount[msg.sender] - amount;
        TransferHelper.safeTransfer(govToken, msg.sender, amount);
    }
    function wtihdrawUnexecutedOrder(uint256 orderId) external {        
        Order memory order = orders[msg.sender][orderId];
        require(order.status == OrderStatus.approvedCancel, "OSWAP_BridgeVault: ");
        order.status = OrderStatus.cancelled;
        orders[msg.sender][orderId] = order;
        //TODO: deduct protocol/transaction fee
        TransferHelper.safeTransfer(govToken, msg.sender, order.inAmount);
    }
}