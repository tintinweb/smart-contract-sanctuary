pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// import "./interfaces/IMoneyPot.sol";
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BLSToken.sol";

contract BlocksRewardsPool is Ownable {

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many block.areas or LP tokens user provided.
        uint256 rewardDebt; // What user is not eligible for plus already harvested
        uint256 pendingRewards; // Rewards assigned, but not yet claimed
        uint256 lastRewardCalculatedBlock; // When pending rewards were last calculated for user
    }

    struct SpaceInfo {
        // mapping(address => uint256) amountOfBlocksOwnedBy; // owners of blocks (with amounts) so we know how to calculate rewards
        uint256 spaceId;
        uint256 amountOfBlocksBought; // Number of all blocks bought on this space
        address contractAddress;           // Address of space contract.
        uint256 blsPerBlockAreaPerBlock; // We will start with 830000 Gwei -> 830000000000000 wei (which is approx 24 BLS/1 block.area / day)
        uint256 accBlsPerBlockArea;
    }

    BLSToken public blsToken;
    SpaceInfo[] public spaceInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => bool) public spacesByAddress;
    uint256 public allAllocationBlocks; // Amount of all blocks from all spaces that are getting BLS rewards

    event SpaceAdded(uint256 indexed spaceId, address indexed space, address indexed addedBy);
    event Claim(address indexed user, uint256 amount);

    modifier onlySpace() {
        require(spacesByAddress[msg.sender] == true, "Not a space.");
        _;
    }

    constructor(BLSToken blsAddress){
        blsToken = BLSToken(blsAddress);
    }

    function spacesLength() external view returns (uint256) {
        return spaceInfo.length;
    }

    function addSpace(address _spaceContract, uint256 _blsPerBlockAreaPerBlock) public { // TODO: only owner
        spacesByAddress[_spaceContract] = true;
        uint256 spaceId = spaceInfo.length;
        SpaceInfo storage newSpace = spaceInfo.push();
        newSpace.contractAddress = _spaceContract;
        newSpace.spaceId = spaceId;
        newSpace.blsPerBlockAreaPerBlock = _blsPerBlockAreaPerBlock;
        emit SpaceAdded(spaceId, _spaceContract, msg.sender);
    }

    function pendingBlsTokens(uint256 _spaceId, address _user) public view returns(uint256){
        SpaceInfo storage space = spaceInfo[_spaceId];
        UserInfo storage user = userInfo[_spaceId][_user];
        uint256 rewards;
        if(user.amount > 0 && user.lastRewardCalculatedBlock < block.number){
            uint256 multiplier = block.number - user.lastRewardCalculatedBlock;
            uint256 blsRewards = multiplier * space.blsPerBlockAreaPerBlock * 1e12;
            rewards = user.amount * blsRewards;
        }
        return (user.pendingRewards + rewards) / 1e12;
    }

    function blockAreaBoughtOnSpace(uint256 _spaceId, address _buyer, uint256 _numberOfBlocksBought, address[] calldata _previousBlockOwners) public payable onlySpace {
    
        SpaceInfo storage space = spaceInfo[_spaceId];
        UserInfo storage user = userInfo[_spaceId][_buyer];
        
        // If user already had some block.areas then calculate all rewards pending
        if(user.lastRewardCalculatedBlock > 0){
            uint256 multiplier = block.number - user.lastRewardCalculatedBlock;
            uint256 blsRewards = multiplier * space.blsPerBlockAreaPerBlock * 1e12;
            user.pendingRewards += user.amount * blsRewards;
        }

        // Set user data
        user.amount += _numberOfBlocksBought;
        user.lastRewardCalculatedBlock = block.number;
        
        //remove blocks from previous owners that this guy took over. Max 42 loops
        uint256 amountOfBlocksToRemove;
        for(uint256 i = 0; i < _numberOfBlocksBought; i++){
            // If previous owners of block are non zero address, means we need to take block from them
            if(_previousBlockOwners[i] != address(0x0)){

                // Calculate previous users pending rewards
                UserInfo storage prevUser = userInfo[_spaceId][_previousBlockOwners[i]];          
                uint256 multiplier = block.number - prevUser.lastRewardCalculatedBlock;
                uint256 blsRewards = multiplier * space.blsPerBlockAreaPerBlock * 1e12;
                prevUser.pendingRewards += prevUser.amount * blsRewards;
                prevUser.lastRewardCalculatedBlock = block.number;
                // Remove his ownership of block
                prevUser.amount--;
                amountOfBlocksToRemove++;
            }           
        }

        // If amount of blocks on space changed, we need to update space state
        if(amountOfBlocksToRemove < _numberOfBlocksBought){           
            space.amountOfBlocksBought = space.amountOfBlocksBought - amountOfBlocksToRemove + _numberOfBlocksBought;
            allAllocationBlocks += _numberOfBlocksBought - amountOfBlocksToRemove;
        }

        // At this point we have all stuff to calculate rewards. 
        // We have how many blocks does a specific user (address has). 
        // And we know how many are all of blocks in space bought.
        // console.log("Money received:", msg.value);
    }

    // TODO: This shall be removed after testnet. If you see this, contact devs immediately
    function withdrawTestOnly() external onlyOwner{
        uint contractBalance = address(this).balance;
        (bool success, ) = msg.sender.call{value: contractBalance}("");
        require(success, "Transfer failed.");
    }

    function claim(uint256 _spaceId) public {
        SpaceInfo storage space = spaceInfo[_spaceId];
        UserInfo storage user = userInfo[_spaceId][msg.sender];

        uint256 rewards;
        if(user.amount > 0 && user.lastRewardCalculatedBlock < block.number){
            uint256 multiplier = block.number - user.lastRewardCalculatedBlock;
            uint256 blsRewards = multiplier * space.blsPerBlockAreaPerBlock * 1e12;
            user.pendingRewards += user.amount * blsRewards;
            user.lastRewardCalculatedBlock = block.number;
        }
        uint256 toClaimAmount = user.pendingRewards / 1e12;
        if(toClaimAmount > 0){
            uint256 claimedAmount = safeBlsTransfer(msg.sender, toClaimAmount);
            emit Claim(msg.sender, toClaimAmount);
            user.pendingRewards -= toClaimAmount * 1e12; // TODO: Check if possible we can get underflow
        }
    }

    // // Safe BLS transfer function, just in case if rounding error causes pool to not have enough BLSs.
    function safeBlsTransfer(address _to, uint256 _amount) internal returns (uint256){
        uint256 blsBalance = blsToken.balanceOf(address(this));
        if (_amount > blsBalance) {            
            blsToken.transfer(_to, blsBalance);
            return blsBalance;
        } else {
            blsToken.transfer(_to, _amount);
            return _amount;
        }
    }

}

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

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BLSToken is ERC20 {

    uint maxSupply = 42000000 ether; // 42 million max tokens

    constructor() ERC20("BlocksSpace Token", "BLS") {
        _mint(_msgSender(), maxSupply);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

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

