/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT

/*
$$\        $$$$$$\  $$\   $$\ $$$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$$\  $$$$$$$$\ 
$$ |      $$  __$$\ $$$\  $$ |$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  _____|
$$ |      $$ /  $$ |$$$$\ $$ |$$ |  $$ |$$ /  \__|$$ /  \__|$$ /  $$ |$$ |  $$ |$$ |      
$$ |      $$$$$$$$ |$$ $$\$$ |$$ |  $$ |\$$$$$$\  $$ |      $$$$$$$$ |$$$$$$$  |$$$$$\    
$$ |      $$  __$$ |$$ \$$$$ |$$ |  $$ | \____$$\ $$ |      $$  __$$ |$$  ____/ $$  __|   
$$ |      $$ |  $$ |$$ |\$$$ |$$ |  $$ |$$\   $$ |$$ |  $$\ $$ |  $$ |$$ |      $$ |      
$$$$$$$$\ $$ |  $$ |$$ | \$$ |$$$$$$$  |\$$$$$$  |\$$$$$$  |$$ |  $$ |$$ |      $$$$$$$$\ 
\________|\__|  \__|\__|  \__|\_______/  \______/  \______/ \__|  \__|\__|      \________|

 >>> Contract starts at line #500
 >>> Made with ❤
*/


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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

contract LandscapeProtocol is ERC20 {  // Test version : v0.01

    struct Node {
        uint size;  // Can be 1, 2 or 3 depending on the type of node
        address owner;  //  Node owner's address
        uint nodeId;  // Unique Id of the node
        uint creationTime;  // Block on which the node was created
        uint lastClaim;  // Last claim block
    }

    modifier isMultisig() {
        bool approved = false;
        for (uint i = 0; i<multisigMembers.length; i++) {
            if (msg.sender==multisigMembers[i]) {approved = true;}
        }
        require(approved, "You are not a member of the multidig");
        _;
    }

    function checkMultisig(string memory _function) public view returns(bool) {
        return(multisig[_function].length >= 2*multisigMembers.length/3);
    }

    function multisigApprove(string memory _function) public isMultisig {
        multisig[_function].push(msg.sender);
    }


    address public owner;  // Owner of the project

    address public liquidityWallet; // In v1, the liquidity funds are transferred to this wallet

    uint private phasis = 0; // Current state of the project

    uint[] private nodePrices = [5, 10, 20];  // Prices of a little node, a medium node, a big node

    uint[] private nodeRewards = [3, 4, 5];  // 4 times the daily rewards for a little node, a medium node, a big node

    uint public nodeCounter = 0;  // Number of Nodes
    
    Node[] public Nodes; // List of the existing nodes

    mapping(address => Node[]) public nodeBalances; // List of an user's nodes

    mapping(uint => address) public nodeOwners;  // Owners of a Node (Id)

    uint public salePrice = 2*10**(decimals()-2);  // Avax per token at launch

    uint public alloc = 500*10**decimals(); // Max alloc per user during the direct sale
    mapping(address => uint) public spentAlloc;  // Spent allocation of user

    uint public maxPresaleAlloc = 200*10**decimals(); // Max alloc per user during the presale
    mapping(address => uint) public presaleAlloc;  // Spent presale allocation of user

    uint public saleTokens = 60000*10**decimals();  // Amount of tokens to be sold during 1st phasis 

    mapping(string => address[]) public multisig;  // Approvals of the multisig members
    address[] public multisigMembers;  // Members of the multisig


    constructor() ERC20("Landscape Protocol", "LDSP") {
        _mint(msg.sender, 100000 * 10 ** decimals());
        owner = msg.sender;
        multisigMembers.push(msg.sender);
    }

    modifier onlyOwner() {
    require(msg.sender == owner, "You are not the owner");
    _;
    }
    
    function addToMultisig(address _member) public onlyOwner {
        multisigMembers.push(_member);
    }

    function defLiquidityWallet(address _account) public onlyOwner {
        liquidityWallet = _account;
    }

    function changeNodesPrice(uint[] memory newPrices) public onlyOwner {
        nodePrices = newPrices;
    }

    function changeRewards(uint[] memory newRewards) public onlyOwner {
        nodeRewards = newRewards;
    }

    function changeSalePrice(uint newPrice) public onlyOwner {
        salePrice = newPrice;
    }

    function changeTokensForSale(uint newAmount) public onlyOwner {
        saleTokens = newAmount;
    }

    function changeAlloc(uint newAlloc) public onlyOwner {
        alloc = newAlloc;
    }

    function changePhasis(uint newPhasis) public onlyOwner {
        phasis = newPhasis;
    }

    function addToWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i<_addresses.length; i++) {
            presaleAlloc[_addresses[i]] = maxPresaleAlloc;
        }
    }

    function nodesOf(address _account) public view returns(Node[] memory) {
        return nodeBalances[_account];
    }

    function rewardsOf(uint _nodeId) public view returns(uint) {
        require(nodeOwners[_nodeId]!=address(0x0), "Requested node doesn't exist or has been burned!");
        Node memory _node = Nodes[_nodeId];
        uint roundedTime = (block.timestamp- _node.creationTime) - (block.timestamp - _node.creationTime)%960;
        return roundedTime / 92160 * nodeRewards[_node.size-1] / 4 * decimals();
    }

    function remainingAlloc(address _address) public view returns(uint) {
        return alloc-spentAlloc[_address];
    }

    function remainingPresaleAlloc(address _address) public view returns(uint) {
        return presaleAlloc[_address];
    }

    function remainingTokensToSale() public view returns(uint) {
        return saleTokens;
    }

    function buy(uint _amount) public payable {
        require(phasis==2, "Direct sale is not available.");
        require(remainingAlloc(msg.sender)>=_amount, "Remaining allocation is too low.");
        require(msg.value>=salePrice*_amount, "Value sent is too low");
        require(_amount<=saleTokens, "Insuffisant liquidity");
        _transfer(address(this), msg.sender, _amount);
        saleTokens -= _amount;
        if (saleTokens==0) {
            uint half = (address(this).balance)-(address(this).balance%2)/2;
            payable(owner).transfer(half);
            payable(liquidityWallet).transfer(half);
        }
    }

    function presaleBuy(uint _amount) public payable {
        require(phasis==1, "Direct sale is not available.");
        require(remainingAlloc(msg.sender)>=_amount, "Remaining allocation is too low.");
        require(msg.value>=salePrice*_amount, "Value sent is too low");
        require(_amount<=saleTokens, "Insuffisant liquidity");
        _transfer(address(this), msg.sender, _amount);
        saleTokens -= _amount;
        if (saleTokens==0) {
            uint half = (address(this).balance)-(address(this).balance%2)/2;
            payable(owner).transfer(half);
            payable(liquidityWallet).transfer(half);
        }
    }

    function createNode(uint size) public {
        require(phasis>=1, "Node creation isn't available yet");
        require(nodesOf(msg.sender).length<100, "You have too many nodes !");
        require(balanceOf(msg.sender)>=nodePrices[size-1], "Amount of token too low.");

        if (size == 2) {  // Medium node
            _transfer(msg.sender, address(this), 7*10**decimals());  // 7 SDCN => Reward pool
            _burn(msg.sender, 10**decimals());  // 1 SCDN is burned
            _transfer(msg.sender, liquidityWallet, 10**decimals()); // 1 SCDN => Liquidity wallet
            _transfer(msg.sender, owner, 10**decimals());  // 1 SCDN => Team Wallet
        }
        else {
            if (size == 1) {  // Small node
                _transfer(msg.sender, address(this), 7*10**decimals()/2);  // 3.5 SDCN => Reward pool
                _burn(msg.sender, 10**decimals()/2);  // 0.5 SCDN is burned
                _transfer(msg.sender, liquidityWallet, 10**decimals()/2); // 0.5 SCDN => Liquidity wallet
                _transfer(msg.sender, owner, 10**decimals()/2);  // 0.5 SCDN => Team Wallet
            }
            else {  // Big node
                _transfer(msg.sender, address(this), 14*10**decimals());  // 14 SDCN => Reward pool
                _burn(msg.sender, 2*10**decimals());  // 2 SCDN is burned
                _transfer(msg.sender, liquidityWallet, 2*10**decimals()); // 2 SCDN => Liquidity wallet
                _transfer(msg.sender, owner, 2*10**decimals());  // 2 SCDN => Team Wallet
            }

        Node memory createdNode = Node(size, msg.sender, nodeCounter, block.timestamp, block.timestamp);
        Nodes.push(createdNode);
        nodeBalances[msg.sender].push(createdNode);
        nodeOwners[createdNode.nodeId] = msg.sender;
        nodeCounter += 1;
        }

    }

    function claim(uint _nodeId) public {
        require(phasis>=1, "Node operations aren't available for the moment.");
        require(nodeOwners[_nodeId]==msg.sender, "Requested node doesn't belong to you !");
        uint pendingReward = rewardsOf(_nodeId);
        if (pendingReward<=balanceOf(address(this))) {
            _transfer(address(this), msg.sender, pendingReward);
        }
        else {
            _mint(msg.sender, pendingReward);
        }
    }

    function withdraw () public onlyOwner{
        require(checkMultisig("withdraw"), "Action is not allowed by the multisig members !");
        payable(msg.sender).transfer(address(this).balance);
    }
}