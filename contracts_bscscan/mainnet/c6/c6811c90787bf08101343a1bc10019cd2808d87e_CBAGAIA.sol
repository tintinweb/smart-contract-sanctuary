/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: MIT

/*
  ______                                   __                _______                                
 /      \                                 /  |              /       \                               
/$$$$$$  |  ______   __    __   ______   _$$ |_     ______  $$$$$$$  |  ______    ______    _______ 
$$ |  $$/  /      \ /  |  /  | /      \ / $$   |   /      \ $$ |__$$ | /      \  /      \  /       |
$$ |      /$$$$$$  |$$ |  $$ |/$$$$$$  |$$$$$$/   /$$$$$$  |$$    $$< /$$$$$$  |/$$$$$$  |/$$$$$$$/ 
$$ |   __ $$ |  $$/ $$ |  $$ |$$ |  $$ |  $$ | __ $$ |  $$ |$$$$$$$  |$$    $$ |$$    $$ |$$      \ 
$$ \__/  |$$ |      $$ \__$$ |$$ |__$$ |  $$ |/  |$$ \__$$ |$$ |__$$ |$$$$$$$$/ $$$$$$$$/  $$$$$$  |
$$    $$/ $$ |      $$    $$ |$$    $$/   $$  $$/ $$    $$/ $$    $$/ $$       |$$       |/     $$/ 
 $$$$$$/  $$/        $$$$$$$ |$$$$$$$/     $$$$/   $$$$$$/  $$$$$$$/   $$$$$$$/  $$$$$$$/ $$$$$$$/  
                    /  \__$$ |$$ |                                                                  
                    $$    $$/ $$ |                                                                  
                     $$$$$$/  $$/                                                                   


                                                                               .
                                                                               .
                             `...                                              .
                          `.::-`                                               .
                        .-:/:.                                                 .
                      .:://:`                         `.:/+++/:-`              .
                    .::///-`    .-                 ./ymNMMMMMMMNmy:            .
                  `-:///::`   -hy/-+o-           :yNMMMMMMMMMMMMMMMs           .
                 `::::/::`   -m/.sy/.`         .yNMMMMmho/:--/smMMMM:          .
                .:::/:/:.    ss ss`           .dMMMms:`        .hMMM/          .
               .::::/:/:     s+`m`           .mMMm+.            :MMm`          .
              `:::::::/.     -h`d            hMNs`              oMN:           .
             `:::::::::`      o/h`  ```     /MN+              `+Nm:            .
             .:::::::::`      `sy+:yddds-   dMo             `:hNs.             .
            `::::::::::        `hNm+/omMN/ .Mh           `.+hms-               .
            .::::::::::`        -Mo   :MMm :N.        `-ohmd+.                 .
            -::::::://:`        .Md`  /MMN`/s     `:ohmNh+-                    .
            -::::::::/:.         sMy-:mMMd --  .ohNMds/`                       .
            -::::::::/::          +NMMMMM/   `ommmmmNNNmy+`                    .
            .:::::::::::.          `/shh/  `+-::-`   `-+ymNy.                  .
            `::::::::::::`                 +m-.  `.-::::-./mMo                 .
             :::::::::::/:                 +M: .:::-.` ``..-dMs                .
             .:::::::::://-`               `mm/:-`  `-::/::::NM:               .
              -:::::::::///:`               -mNo` .:/:-.```..yMh               .
              `:::::::::////:.               .hMd+::.``.-::::yMm               .
               `:::::::///////-`              `/mMm+`.:::.```dMh               .
                `:::::::///////:-`              `+dMmyo:`  `sMM:               .
                 `-::::::////////:-`              `:ymMNdhhmMMh                .
                   .:::/:://///////:-.`              ./hNMMMMM+                .
                    `-::://///////////::.``             ./sdmms                .
                      `-::////////////////::-.``            `.`  ``            .
                        `.::////////////////////:::---....---.--:-`            .
                           `.::///////////////////++++++++++//-.`              .
                              `.-::////////////////++++///:.`                  .
                                   `..--::://////:::--.``                      .
                                                                               .
                                                                               
*/
                                                                               

pragma solidity =0.8.4;

/*
 * This Contract is a binding contract between Cryptobees members for proof of ownership of 
 * Private allocation for Project "GAIA" with the code CBAGAIA. Each coin 
 * represents 1$ worth of Private Sale allocation. The private sale tokens will be distributed 
 * to the holders of this token according to their Share. This is an IOU representation model. 
 * Each token represents Cryptobees I Owe U 1$ worth of project allocation tokens. 
 * The contract will have a public dead wallet 0x000000000000000000000000000000000000dead, 
 * the Cryptobees members have to transfer the tokens to the declared burnaddress to receive their TGE Tokens. 
 * At any point in Time, the team members can sell their tokens to other Cryptobees members of their choice. 
 * The private allocation tokens will be distributed to them direcly at the Private round price.
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 * Cryptobees team does not held any liablity if the original project is delayed, scrapped, not responding or not progressing. 
 * This has been best vetted from the analysis done within Cryptobees capablity and via trusted contracts. However digital assets investments are upto 
 * individuals risk, hence DYOR before investing on any of our private allocation deals.
 * $GAIA tokens as part of strategic sale investment is procured at S$0.075 USD.
 * The $CBAGAIA tokens will be distributed according to the price value where 1 CBAGAIA represents 1$.
 * TGE Q4 2021 - The actual dates have to be published by the Gaia team in their official telegram channels.
 * The GAIA token is a ERC20 token on Polygon Matic chain.
 * 10% of GAIA tokens is relased to the Strategic investors and the release of tokens will happen over 1 year by releasing 10% every month.
 *The release of the total $Moni Token will be based on the above
 *Schedule.The transaction will be completed in 365 days i.e. on 15th September 2022.
 *The dates stated above are only for reference purpose and depends on GAIA teams timelines distribution.
 * IMPORTANT NOTE: you would have paid 5% in the transaction as handling fees for the team and admin purpose, however this token is a ERC20 hence each transfers occurs gas fees which should be beared by the purchaser
 * If the handling charge or gas fees is not paid, we will deduct and transfer the righteous tokens accordingly
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

pragma solidity =0.8.4;

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
    function allowance(address owner, address spender)
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

pragma solidity =0.8.4;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity =0.8.4;

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


contract CBAGAIA is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name = "Bees-CBA-GAIA";
    string private _symbol = "GAIA";
    uint8 private _decimals = 18;

    uint256 constant maxCap = 1000000 * (10**18);
    uint256 private _totalSupply = maxCap;
    
    address public cba_deadWallet;
    address public cba_owner;
    

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 8.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address _deadWallet) {
        _balances[msg.sender] = maxCap; //At the moment of creation all tokens will go to the owner.
        cba_deadWallet=_deadWallet;
        cba_owner=msg.sender;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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

        if (recipient == address(0)) {
            _burn(sender, amount);
        } else {
           
            uint256 senderBalance = _balances[sender];
            require(
                senderBalance >= amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[sender] = senderBalance - amount;
            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);
        }
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    
    function setDeadWallet(address _deadWallet) public onlyOwner {
            require(msg.sender !=cba_owner, "Only Owner can call this");
            cba_deadWallet=_deadWallet;
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