// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
     * overloaded;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IKeeperImport.sol";

contract Auction is Ownable {
    enum State {Bid, BidEnded, Challenge, ChallengeEnded, Refund}

    struct AssetMeta {
        uint256 index;
        uint256 divisor;
        bool exist;
    }

    struct Bid {
        address user;
        address asset;
        uint256 amount;
        uint256 selectedAmount;
        bool live;
    }

    struct UserBids {
        uint256[] bidIds;
        uint256 uniAmount;
    }

    uint8 public constant BTC_DECIMALS = 8;
    uint256 constant REFUND_SPAN = 1000 days;

    State public state = State.Bid;
    uint256 public stateDeadline;
    uint256 public minBidAmount;
    uint256 public bidderCount;
    uint256 public maxNumBids;
    IKeeperImport keeperImport;

    mapping(address => AssetMeta) assetMeta;
    mapping(address => UserBids) allUserBids;
    Bid[] allBids;
    address[] assetList;
    address[] keepers;

    event StateChanged(State newState, uint256 deadline);
    event Bidded(address indexed user, uint256 bidId, address indexed asset, uint256 amount);
    event Canceled(address indexed user, uint256 bidId, address indexed asset, uint256 amount);
    event Refund(address indexed user, uint256 bidId, address indexed asset, uint256 amount);
    event KeepersExported(
        uint256 collateralAmount,
        address[] assets,
        uint256[] amount,
        address[] keepers
    );

    modifier inState(State _state) {
        checkDeadline();
        require(state == _state, "function invalid in current state");
        _;
    }

    constructor(
        IKeeperImport _keeperImport,
        address[] memory _assets,
        uint256 _bidDeadline,
        uint256 _minBidAmount
    ) {
        require(_assets.length > 0, "empty assets");
        require(
            block.timestamp < _bidDeadline && _bidDeadline <= block.timestamp + 30 * 24 * 3600,
            "invalid bid deadline"
        );
        require(_minBidAmount > 0, "invaild minimum bid amount");

        keeperImport = _keeperImport;
        stateDeadline = _bidDeadline;
        minBidAmount = _minBidAmount;
        maxNumBids = 5;

        for (uint256 i = 0; i < _assets.length; i++) {
            uint8 decimals = ERC20(_assets[i]).decimals();
            require(decimals >= BTC_DECIMALS, "asset decimals is less than btc decimals");
            assetMeta[_assets[i]] = AssetMeta(i, 10**(decimals - BTC_DECIMALS), true);
        }
        assetList = _assets;
    }

    function setMaxNumBids(uint256 _num) external inState(State.Bid) onlyOwner {
        require(_num > maxNumBids, "only increase");
        maxNumBids = _num;
    }

    function bid(address _asset, uint256 _amount) external inState(State.Bid) {
        AssetMeta storage meta = assetMeta[_asset];
        require(meta.exist, "unknown asset");
        uint256 uniAmount = _amount / meta.divisor;
        require((uniAmount >= minBidAmount) && (uniAmount % minBidAmount == 0), "invalid amount");

        UserBids storage userBids = allUserBids[msg.sender];
        require(userBids.bidIds.length < maxNumBids, "exceed maxNumBids");

        if (userBids.bidIds.length == 0) {
            bidderCount += 1;
        }
        uint256 bidId = allBids.length;
        allBids.push(Bid(msg.sender, _asset, _amount, 0, true));
        userBids.bidIds.push(bidId);
        userBids.uniAmount += uniAmount;

        require(ERC20(_asset).transferFrom(msg.sender, address(this), _amount));
        emit Bidded(msg.sender, bidId, _asset, _amount);
    }

    function cancel(uint256 _bidId) external inState(State.Bid) {
        Bid storage bd = allBids[_bidId];
        require(msg.sender == bd.user, "only owner can cancel");
        require(bd.live, "bid already canceled");

        UserBids storage userBids = allUserBids[msg.sender];
        AssetMeta storage meta = assetMeta[bd.asset];
        userBids.uniAmount -= bd.amount / meta.divisor;
        bd.live = false;

        require(ERC20(bd.asset).transfer(msg.sender, bd.amount));
        emit Canceled(msg.sender, _bidId, bd.asset, bd.amount);
    }

    function cancelAll() external inState(State.Bid) {
        cancelAllOrRefund(true);
    }

    function setBidResult(address[] calldata _keepers) external inState(State.BidEnded) onlyOwner {
        require(_keepers.length > 0, "empty keepers");

        for (uint256 i = 0; i < _keepers.length; i++) {
            require(i == 0 || _keepers[i] > _keepers[i - 1], "keepers not in ascending order");
            require(allUserBids[_keepers[i]].uniAmount > 0, "keeper's collateral is zero");
        }
        keepers = _keepers;
        changeState(State.Challenge, 1 days);
    }

    function challenge(address _user) external inState(State.Challenge) {
        require(findKeeper(msg.sender) == keepers.length, "is already keeper");
        uint256 index = findKeeper(_user);
        require(index != keepers.length, "user is not keeper");
        require(
            allUserBids[msg.sender].uniAmount > allUserBids[_user].uniAmount,
            "challenge failed"
        );

        keepers[index] = msg.sender;
    }

    function exportKeepers() external inState(State.ChallengeEnded) onlyOwner {
        uint256[] memory assetAmounts = new uint256[](assetList.length);
        uint256[] memory keeperAmounts = new uint256[](keepers.length * assetList.length);
        uint256 collateralAmount = calcCollateralAmount();

        for (uint256 i = 0; i < keepers.length; i++) {
            UserBids storage userBids = allUserBids[keepers[i]];
            uint256 remainAmount = collateralAmount;
            uint256 base = i * assetList.length;

            for (uint256 j = 0; j < userBids.bidIds.length; j++) {
                Bid storage bd = allBids[userBids.bidIds[j]];
                if (bd.live) {
                    AssetMeta storage asset = assetMeta[bd.asset];
                    uint256 selectedAmount = Math.min(remainAmount * asset.divisor, bd.amount);
                    bd.selectedAmount = selectedAmount;
                    remainAmount -= selectedAmount / asset.divisor;
                    assetAmounts[asset.index] += selectedAmount;
                    keeperAmounts[base + asset.index] += selectedAmount;

                    if (remainAmount == 0) break;
                }
            }
        }

        changeState(State.Refund, REFUND_SPAN);

        for (uint256 i = 0; i < assetList.length; i++) {
            require(ERC20(assetList[i]).approve(address(keeperImport), assetAmounts[i]));
        }
        keeperImport.importKeepers(address(this), assetList, keepers, keeperAmounts);
        emit KeepersExported(collateralAmount, assetList, assetAmounts, keepers);
    }

    function refund() external inState(State.Refund) {
        cancelAllOrRefund(false);
    }

    function checkDeadline() public {
        if (stateDeadline < block.timestamp) {
            if (state == State.Bid) {
                changeState(State.BidEnded, 7 days);
            } else if (state == State.BidEnded) {
                changeState(State.Refund, REFUND_SPAN);
            } else if (state == State.Challenge) {
                changeState(State.ChallengeEnded, 6 days);
            } else if (state == State.ChallengeEnded) {
                changeState(State.Refund, REFUND_SPAN);
            }
        }
    }

    function getStates() public view returns (uint256, uint256) {
        return (uint256(state), stateDeadline);
    }

    function getUserAmount(address _user) public view returns (uint256) {
        return allUserBids[_user].uniAmount;
    }

    function getBidCount() public view returns (uint256) {
        return allBids.length;
    }

    function getUserBids(address _user) public view returns (UserBids memory) {
        return allUserBids[_user];
    }

    function getUserBidsCount(address _user) public view returns (uint256) {
        return allUserBids[_user].bidIds.length;
    }

    function changeState(State _newState, uint256 _span) public {
        state = _newState;
        stateDeadline = block.timestamp + _span;
        emit StateChanged(_newState, stateDeadline);
    }

    function cancelAllOrRefund(bool _isCancel) private {
        uint256[] memory assetAmounts = new uint256[](assetList.length);
        UserBids storage userBids = allUserBids[msg.sender];
        for (uint256 i = 0; i < userBids.bidIds.length; i++) {
            uint256 bidId = userBids.bidIds[i];
            Bid storage bd = allBids[bidId];

            if (bd.live && bd.amount > bd.selectedAmount) {
                bd.live = false;
                AssetMeta storage asset = assetMeta[bd.asset];
                uint256 amount = bd.amount - bd.selectedAmount;
                assetAmounts[asset.index] += amount;

                if (_isCancel) {
                    emit Canceled(msg.sender, bidId, bd.asset, amount);
                } else {
                    emit Refund(msg.sender, bidId, bd.asset, amount);
                }
            }
        }

        userBids.uniAmount = 0;
        for (uint256 i = 0; i < assetAmounts.length; i++) {
            uint256 amount = assetAmounts[i];
            if (amount > 0) {
                require(ERC20(assetList[i]).transfer(msg.sender, amount));
            }
        }
    }

    function findKeeper(address _user) private view returns (uint256) {
        for (uint256 i = 0; i < keepers.length; i++) {
            if (keepers[i] == _user) {
                return i;
            }
        }
        return keepers.length;
    }

    function calcCollateralAmount() private view returns (uint256) {
        uint256 collateralAmount = allUserBids[keepers[0]].uniAmount;
        for (uint256 i = 1; i < keepers.length; i++) {
            uint256 uniAmount = allUserBids[keepers[i]].uniAmount;
            if (uniAmount < collateralAmount) {
                collateralAmount = uniAmount;
            }
        }
        return collateralAmount;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IKeeperImport {
    function importKeepers(
        address _from,
        address[] calldata _assets,
        address[] calldata _keepers,
        uint256[] calldata _keeper_amounts
    ) external;
}

