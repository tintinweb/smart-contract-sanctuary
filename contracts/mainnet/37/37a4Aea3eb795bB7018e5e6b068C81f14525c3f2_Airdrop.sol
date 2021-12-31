// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import './Prey.sol';
// 0x7f36182dee28c45de6072a34d29855bae76dbe2f
// 0x2C88aA0956bC9813505d73575f653F69ADa60923
// 0xBDa2481db91fc0F942eD3F53De378Ba45ba9d17E
struct SheepWolf {
  bool isSheep;
  uint8 fur;
  uint8 head;
  uint8 ears;
  uint8 eyes;
  uint8 nose;
  uint8 mouth;
  uint8 neck;
  uint8 feet;
  uint8 alphaIndex;
}

interface IWOLF {
  function ownerOf(uint256 tokenId) external view returns(address);
  function balanceOf(address owner) external view returns(uint);
  function tokenOfOwnerByIndex(address owner, uint index) external view returns(uint);
  function getTokenTraits(uint256 tokenId) external view returns(SheepWolf memory);
}

struct AirdropToken {
  uint256 tokenId;
  bool claimed;
  bool isSheep;
}


contract Airdrop is Ownable, Pausable {

  uint constant WOLF_PER_TOKEN = 10000 ether;
  uint constant SHEEP_PER_TOKEN = 8000 ether;
  uint constant LAND_PER_TOKEN = 5000 ether;
  uint constant FARMER_PER_TOKEN = 5000 ether;

  uint constant MAX_AIRDROP_AMOUNT = 100000000 ether;
   
  IWOLF _wolf;
  IWOLF _land;
  IWOLF _farmer;

  IWOLF _wolfTraits;

  Prey _prey;

  mapping(address => mapping(uint256 => bool)) claimedTokens;

  uint256 public claimedAmount;

  constructor(address wolf_, address land_, address farmer_, address wolfTraits_, address prey_) {
    _wolf = IWOLF(wolf_);
    _land = IWOLF(land_);
    _farmer = IWOLF(farmer_);
    _wolfTraits = IWOLF(wolfTraits_);
    _prey = Prey(prey_);
  }

  function getTokens(address owner, IWOLF wolf) internal view returns(AirdropToken[] memory tokens, uint claimablePrey, uint totalPrey) {
    uint totalCount = wolf.balanceOf(owner);
      if (totalCount > 0) {
        tokens = new AirdropToken[](totalCount);
        
        for (uint256 i = 0; i < totalCount; i++) {
          uint256 tokenId = wolf.tokenOfOwnerByIndex(owner, i);
          bool claimed = claimedTokens[address(wolf)][tokenId];
          
          tokens[i] = AirdropToken({
            tokenId: tokenId,
            claimed: claimed,
            isSheep: false
          });
          uint preyPerToken;
          if (wolf == _land) {
            preyPerToken = LAND_PER_TOKEN;
          } else if (wolf == _farmer) {
            preyPerToken = FARMER_PER_TOKEN;
          }
          
          if (claimed == false) {
            claimablePrey += preyPerToken;
          }
          totalPrey += preyPerToken;
        }
      }
  }

  function tokensByOwner(address owner, bool checkLand, bool checkFarmer, uint256[] calldata wolfTokenIds) public view 
    returns(AirdropToken[] memory wolfs, AirdropToken[] memory lands, AirdropToken[] memory farmers, uint claimablePrey, uint totalPrey) {
    uint claimable;
    uint total;
    if (checkLand) {
      (lands, claimable, total) = getTokens(owner, _land);
      claimablePrey += claimable;
      totalPrey += total;
    }

    if (checkFarmer) {
      (farmers, claimable, total) = getTokens(owner, _farmer);
      claimablePrey += claimable;
      totalPrey += total;
    }
    
    if (wolfTokenIds.length > 0) {
      wolfs = new AirdropToken[](wolfTokenIds.length);
      for (uint256 i = 0; i < wolfTokenIds.length; i++) {
        uint256 tokenId = wolfTokenIds[i];
        address tokenOwner = _wolf.ownerOf(tokenId);
        if (owner == tokenOwner) {
          bool claimed = claimedTokens[address(_wolf)][tokenId];
          bool isSheep = _wolfTraits.getTokenTraits(tokenId).isSheep;

          wolfs[i] = AirdropToken({
            tokenId: tokenId,
            claimed: claimed,
            isSheep: isSheep
          });

          uint preyPerToken;
          if (isSheep) {
            preyPerToken = SHEEP_PER_TOKEN;
          } else {
            preyPerToken = WOLF_PER_TOKEN;
          }
          if (claimed == false) {
            claimablePrey += preyPerToken;
          }
          totalPrey += preyPerToken;
        }
      }
    }
  }

  function claim(bool checkLand, bool checkFarmer, uint256[] calldata wolfTokenIds) external whenNotPaused {
    require(tx.origin == msg.sender, "No Access");
    require(claimedAmount < MAX_AIRDROP_AMOUNT, "No more prey");

    uint256 claimablePrey;
    AirdropToken[] memory wolfs;
    AirdropToken[] memory lands;
    AirdropToken[] memory farmers;
    (wolfs, lands, farmers, claimablePrey,) = tokensByOwner(msg.sender, checkLand, checkFarmer, wolfTokenIds);
    require(claimablePrey > 0, "No token can be claim");

    if (wolfs.length > 0) {
      markTokenClaimed(wolfs, _wolf);
    }
    if (lands.length > 0) {
      markTokenClaimed(lands, _land);
    }
    if (farmers.length > 0) {
      markTokenClaimed(farmers, _farmer);
    }
    
    if (claimedAmount + claimablePrey > MAX_AIRDROP_AMOUNT) {
      claimablePrey = MAX_AIRDROP_AMOUNT - claimedAmount;
    }
    claimedAmount += claimablePrey;
    _prey.mintByCommunity(msg.sender, claimablePrey);
  }

  function markTokenClaimed(AirdropToken[] memory wolfs, IWOLF wolf) internal {
    for (uint256 i = 0; i < wolfs.length; i++) {
      if (wolfs[i].tokenId > 0 && wolfs[i].claimed == false) {
        claimedTokens[address(wolf)][wolfs[i].tokenId] = true;
      }
    }
  }

  function setWolfAddress(address address_) external onlyOwner {
    _wolf = IWOLF(address_);
  }

  function setLandAddress(address address_) external onlyOwner {
    _land = IWOLF(address_);
  }

  function setFarmerAddress(address address_) external onlyOwner {
    _farmer = IWOLF(address_);
  }

  function setPreyAddress(address address_) external onlyOwner {
    _prey = Prey(address_);
  }

  function setWolfTraits(address address_) external onlyOwner {
    _wolfTraits = IWOLF(address_);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './Prey.sol';

/**
 * Useful for simple vesting schedules like "developers get their tokens
 * after 2 years".
 */
contract TokenTimelock {

    // ERC20 basic token contract being held
    Prey private immutable _token;

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled
    uint256 private immutable _releaseTime;
    
    //a vesting duration to release tokens 
    uint256 private immutable _releaseDuration;
    
    //record last withdraw time, through which calculate the total withdraw amount
    uint256 private lastWithdrawTime;
    //total amount of tokens to release
    uint256 private immutable _totalToken;

    constructor(
        Prey token_,
        address beneficiary_,
        uint256 releaseTime_,
        uint256 releaseDuration_,
        uint256 totalToken_
    ) {
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
        lastWithdrawTime = _releaseTime;
        _releaseDuration = releaseDuration_;
        _totalToken = totalToken_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (Prey) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        uint256 releaseAmount = (block.timestamp - lastWithdrawTime) * _totalToken / _releaseDuration;
        
        require(amount >= releaseAmount, "TokenTimelock: no tokens to release");

        lastWithdrawTime = block.timestamp;
        token().transfer(beneficiary(), releaseAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './TokenTimelock.sol';

/**
 * $PREY token contract
 */
contract Prey is ERC20, Ownable {

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) public controllers;
  
  // the total amount allocated for developers
  uint constant developerTokenAmount = 600000000 ether;

  // the total amount allocated for community rewards
  uint constant communityTokenAmount = 2000000000 ether;

  // the total amount of tokens staked in the forest to yeild
  uint constant forestTokenAmount = 2400000000 ether;
  
  // the amount of $PREY tokens community has yielded
  uint mintedByCommunity;
  // the amount of $PREY tokens staked and yielded in the forest
  uint mintedByForest;

  /**
   * Contract constructor function
   * @param developerAccount The address that receives locked $PREY rewards for developers, in total 600 million
   */
  constructor(address developerAccount) ERC20("Prey", "PREY") {

    // create contract to lock $PREY token for 2 years (732 days in total) for developers, after which there is a 10 months(300 days in total) vesting schedule to release 600 million tokens
    TokenTimelock timelock = new TokenTimelock(this, developerAccount, block.timestamp + 732 days, 300 days, developerTokenAmount);
    _mint(address(timelock), developerTokenAmount);
    controllers[_msgSender()] = true;
  }
  /**
   * the function mints $PREY tokens to community members, effectively controls maximum yields
   * @param account mint $PREY to account
   * @param amount $PREY amount to mint
   */
  function mintByCommunity(address account, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    require(mintedByCommunity + amount <= communityTokenAmount, "No mint out");
    mintedByCommunity = mintedByCommunity + amount;
    _mint(account, amount);
  }

  /**
   * the function mints $PREY tokens to community members, effectively controls maximum yields
   * @param accounts mint $PREY to accounts
   * @param amount $PREY amount to mint
   */
  function mintsByCommunity(address[] calldata accounts, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    require(mintedByCommunity + (amount * accounts.length) <= communityTokenAmount, "No mint out");
    mintedByCommunity = mintedByCommunity + (amount * accounts.length);
    for (uint256 i = 0; i < accounts.length; i++) {
      _mint(accounts[i], amount);
    }
  }

  /**
   * the function mints $PREY tokens by the forest, effectively controls maximum yields
   * @param account mint $PREY to account
   * @param amount $PREY amount to mint
   */
  function mintByForest(address account, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    require(mintedByForest + amount <= forestTokenAmount, "No mint out");
    mintedByForest = mintedByForest + amount;
    _mint(account, amount);
  }

  /**
   * burn $PREY token by controller
   * @param account account holds $PREY token
   * @param amount the amount of $PREY token to burn
   */
  function burn(address account, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    _burn(account, amount);
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}