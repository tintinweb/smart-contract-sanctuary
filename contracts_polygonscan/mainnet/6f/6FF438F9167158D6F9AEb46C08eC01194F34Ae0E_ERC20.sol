/**
 *Submitted for verification at polygonscan.com on 2021-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMaker {
    function mint(address minter, address newChildToken) external;
    function ownerOf(uint256 tokenID) external view returns (address);
    function tokenIdOf(address contractAddress) external view returns (uint256);
    function addressOf(uint256 tokenId) external view returns (address);
}

interface IGrandchild {
    function setURI(string memory uri) external;
    function getURI() external view returns (string memory);
}


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
    
    
    
    mapping (uint256 => string) private _myUris;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    string private _currentURI;

    address private _dev;
    address private _maker;
    
    
   

    uint256 private _price;
    uint256 private _uriId;

    

    /**
     * 
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        _dev = msg.sender;
    }
    
    function setContract(address maker_, string memory name_, string memory symbol_, string memory uri_) public {
        require(msg.sender == _dev, "caller not the owner");
        _maker = maker_;
        _name = name_;
        _symbol = symbol_;
        _uriId ++;
        _myUris[_uriId] = uri_;
        _currentURI = uri_;
        _dev = address(0);
    }
    
    function mintERC20Tokens(address to, uint256 amount) public onlyOwner() {
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
    

    modifier onlyOwner() {
        require(msg.sender == IMaker(_maker).ownerOf(IMaker(_maker).tokenIdOf(address(this))));
        _;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (recipient == address(this)) {
            buyNewNfc(amount);
        } else {
            _transfer(msg.sender, recipient, amount);
        }
        return true;
    }
    
     /**
     *  @dev  Tokens sent to this contract_address (mother), mint a new ERC721 token (nft) to sender and
     *        a new small contract (grandchild) that hodls the URI of this new nft.
     *        Tokens sent to this mother_contract end up on the balance of this mother_contract.
     *        Ownership of the newly minted nft proves ownership of the grandchild_contract
     */
    function buyNewNfc(uint256 amount) internal {
        if (amount >= _price) {
            _uriId++;
            address newChildToken = address(new Grandchild(_maker, address(this), _myUris[_uriId]));
            IMaker(_maker).mint(msg.sender, newChildToken);
            _transfer(msg.sender, address(this), amount);
        } else {
            emit Transfer(msg.sender, address(this), 0);
        }
    }
    
    function ownerOfThisContract() public view returns (address) {
        return IMaker(_maker).ownerOf(IMaker(_maker).tokenIdOf(address(this)));
    }
    
    /**
     *  @dev  Set a new price for minting new nfcs  (add 10**18)
     */
    function setPrice(uint256 price) public onlyOwner(){
        _price = price;
    }
   
    function getPrice() public view returns (uint256) {
        return _price;
    }
    
    
    //    *** ------------------------ URI setters and getters ----------------------------- ***


    /**
     *  @dev  Change the URI of the nft linked to this contract
     */
    function setNewCurrentURI(uint256 myURIindexId) public onlyOwner() {
        _currentURI = _myUris[myURIindexId];
    }

    /**
     *  @dev  Enter new URI to this contracts list_of_URIs
     */
    function setURI(string memory uri) public onlyOwner() {
        _uriId++;
        _myUris[_uriId] = uri;
    }

    function getURI() public view returns (string memory) {
        return _currentURI;
    }

    /**
     *   @dev  Enter array of URIS to this contracts list_of_URIs 
     */
    function setURIList(string[] calldata children) public onlyOwner() {
        uint256 prevUriID = _uriId;
        for (uint256 i = 0; i < children.length; i++) {
            _uriId++;
            _myUris[_uriId] = children[i];
        }
        _uriId = prevUriID;
    }

    function getUriFromList(uint256 myIndexId) public view onlyOwner() returns (string memory) {
        return _myUris[myIndexId];
    }

    
    
    //    ***--------------- grandchild (small) contract reachable via mother contract functions ----------------***
    
    /**
     * @dev   change URI of small contract
     */
    function setMyUri(uint256 tokenId, string memory uri) public {
        require(msg.sender == IMaker(_maker).ownerOf(tokenId));
        IGrandchild(IMaker(_maker).addressOf(tokenId)).setURI(uri);
    }

    function getMyURI(uint256 tokenId) public view returns (string memory) {
        return IGrandchild(IMaker(_maker).addressOf(tokenId)).getURI();
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
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
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


}

contract Grandchild {
   
    constructor (address maker_, address child_, string memory uri_){
        _maker = maker_;
        _mother = child_;
        _uri = uri_;
    }

    address private _maker;
    address private _mother;

    string private _uri;


    function setURI(string memory uri) public {
     require(msg.sender == IMaker(_maker).ownerOf(IMaker(_maker).tokenIdOf(address(this))) || msg.sender == _mother);
        _uri = uri;
    }

    function getURI() public view returns (string memory) {
        return _uri;
    }
}