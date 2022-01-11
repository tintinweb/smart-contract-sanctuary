//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './GTokenERC20.sol';
import './AuctionHouse.sol';
import './base/Feed.sol';

contract Minter {
  address public owner;

  GTokenERC20 public collateralToken;
  Feed public  collateralFeed;
  AuctionHouse auctionHouse;
  GTokenERC20[] public synths;

  uint256 public constant PENALTY_FEE = 11;
  uint256 public constant FLAG_TIP = 3 ether;
  uint public ratio = 9 ether;

  mapping (address => mapping (GTokenERC20 => uint256)) public collateralBalance;
  mapping (GTokenERC20 => uint256) public cRatioActive;
  mapping (GTokenERC20 => uint256) public cRatioPassive;
  mapping (GTokenERC20 => Feed) public feeds;
  mapping (address => mapping (GTokenERC20 => uint256)) public synthDebt;
  mapping (address => mapping (GTokenERC20 => uint256)) public auctionDebt;
  mapping (address => mapping (GTokenERC20 => uint256)) public plrDelay;

  // Events
  event CreateSynth(address token, string name, string symbol, address feed);
  event Mint(address indexed account, uint256 totalAmount);
  event Burn(address indexed account, address token, uint256 amount);
  event WithdrawnCollateral(address indexed account, address token, uint amount);
  event DepositedCollateral(address indexed account, address token, uint amount);

  // Events for liquidation
  event AccountFlaggedForLiquidation(address indexed account, address indexed keeper, uint256 deadline);
  event Liquidate(address indexed accountLiquidated, address indexed accountFrom, address token);

  event AuctionFinish(uint256 indexed id, address user, uint256 finished_at);

  modifier onlyOwner() {
    require(msg.sender == owner, 'unauthorized');
    _;
  }

  modifier isCollateral(GTokenERC20 token) {
    require(address(token) != address(collateralToken), 'invalid token');
    _;
  }

  modifier isValidKeeper(address user) {
    require(user != address(msg.sender), 'Sender cannot be the liquidated');
    _;
  }

  constructor(address collateralToken_, address collateralFeed_, address auctionHouse_) {
    collateralToken = GTokenERC20(collateralToken_);
    collateralFeed  = Feed(collateralFeed_);
    auctionHouse  = AuctionHouse(auctionHouse_);
    owner = msg.sender;
  }

  function getSynth(uint256 index) public view returns (GTokenERC20) {
    return synths[index];
  }

  function createSynth(string calldata name, string calldata symbol, uint initialSupply, uint256 cRatioActive_, uint256 cRatioPassive_, Feed feed) external onlyOwner {
    require(cRatioPassive_ > cRatioActive_, 'Invalid cRatioActive');

    uint id = synths.length;
    GTokenERC20 token = new GTokenERC20(name, symbol, initialSupply);
    synths.push(token);
    cRatioActive[synths[id]] = cRatioActive_;
    cRatioPassive[synths[id]] = cRatioPassive_;
    feeds[synths[id]] = feed;

    emit CreateSynth(address(token), name, symbol, address(feed));
  }

  function withdrawnCollateral(GTokenERC20 token, uint256 amount) external {
    require(collateralBalance[msg.sender][token] >= amount, 'Insufficient quantity');
    uint256 futureCollateralValue = (collateralBalance[msg.sender][token] - amount) * collateralFeed.price() / 1 ether;
    uint256 debtValue = synthDebt[msg.sender][token] * feeds[token].price() / 1 ether;
    require(futureCollateralValue >= debtValue * cRatioActive[token] / 100, 'below cRatio');

    collateralBalance[msg.sender][token] -= amount;
    collateralToken.transfer(msg.sender, amount);

    emit WithdrawnCollateral(msg.sender, address(token), amount);
  }

  function depositCollateral(GTokenERC20 token, uint256 amount) public isCollateral(token) {
    collateralToken.approve(msg.sender, amount);
    require(collateralToken.transferFrom(msg.sender, address(this), amount), 'transfer failed');
    collateralBalance[msg.sender][token] += amount;

    emit DepositedCollateral(msg.sender, address(token), amount);
  }

  function mint(GTokenERC20 token, uint256 amountToDeposit, uint256 amountToMint) external isCollateral(token) {
    depositCollateral(token, amountToDeposit);
    require(collateralBalance[msg.sender][token] > 0, 'Without collateral deposit');

    uint256 futureCollateralValue = collateralBalance[msg.sender][token] * collateralFeed.price() / 1 ether;
    uint256 futureDebtValue = (synthDebt[msg.sender][token] + amountToMint) * feeds[token].price() / 1 ether;
    require((futureCollateralValue / futureDebtValue) * 1 ether >= ratio, 'Above max amount');

    token.mint(msg.sender, amountToMint);
    synthDebt[msg.sender][token] += amountToMint;

    emit Mint(msg.sender, synthDebt[msg.sender][token]);
  }

  function burn(GTokenERC20 token, uint256 amount) external {
    require(token.transferFrom(msg.sender, address(this), amount), 'transfer failed');
    token.burn(amount);
    synthDebt[msg.sender][token] -= amount;

    emit Burn(msg.sender, address(token), amount);
  }

  function getCRatio(GTokenERC20 token) external view returns (uint256) {
    if (collateralBalance[msg.sender][token] == 0 || synthDebt[msg.sender][token] == 0) {
      return 0;
    }

    uint256 collateralValue = collateralBalance[msg.sender][token] * collateralFeed.price() / 1 ether;
    uint256 debtValue = synthDebt[msg.sender][token] * feeds[token].price() / 1 ether;

    return (collateralValue / debtValue) * 1 ether;
  }

  function liquidate(address user, GTokenERC20 token) external isValidKeeper(user) {
    require(plrDelay[user][token] > 0);
    Feed syntFeed = feeds[token];
    uint256 priceFeed = collateralFeed.price();
    uint256 collateralValue = (collateralBalance[user][token] * priceFeed) / 1 ether;
    uint256 debtValue = synthDebt[user][token] * syntFeed.price() / 1 ether;
    require((collateralValue < debtValue * cRatioActive[token] / 100) || (collateralValue < debtValue * cRatioPassive[token] / 100 && plrDelay[user][token] < block.timestamp), 'above cRatio');

    collateralToken.approve(address(auctionHouse), collateralBalance[user][token]);
    {
      uint debtAmountTransferable = debtValue / 10;
      _mintPenalty(token, user, msg.sender, debtAmountTransferable);
      _transferLiquidate(token, msg.sender, debtAmountTransferable);
      auctionDebt[user][token] += synthDebt[user][token];
      uint256 collateralBalance = collateralBalance[user][token];
      uint256 auctionDebt = (auctionDebt[user][token] * syntFeed.price()) / 1 ether;
      auctionHouse.start(user, address(token), address(collateralToken), msg.sender, collateralBalance, collateralValue, auctionDebt, priceFeed);
      updateCollateralAndSynthDebt(user, token);

      emit Liquidate(user, msg.sender, address(token));
    }
  }

  function updateCollateralAndSynthDebt(address user, GTokenERC20 token) private {
    collateralBalance[user][token] = 0;
    synthDebt[user][token] = 0;
  }

  function auctionFinish(uint256 auctionId, address user, GTokenERC20 collateralToken, GTokenERC20 synthToken, uint256 collateralAmount, uint256 synthAmount) public {
    require(address(auctionHouse) == msg.sender, 'Only auction house!');
    require(collateralToken.transferFrom(msg.sender, address(this), collateralAmount), 'transfer failed');
    require(synthToken.transferFrom(msg.sender, address(this), synthAmount), 'transfer failed');
    synthToken.burn(synthAmount);

    collateralBalance[user][synthToken] = collateralAmount;
    auctionDebt[user][synthToken] -= synthAmount;
    plrDelay[user][synthToken] = 0;

    emit AuctionFinish(auctionId, user, block.timestamp);
  }

  function flagLiquidate(address user, GTokenERC20 token) external isValidKeeper(user) {
    require(plrDelay[user][token] < block.timestamp);
    require(collateralBalance[user][token] > 0 && synthDebt[user][token] > 0, 'User cannot be flagged for liquidate');

    uint256 collateralValue = (collateralBalance[user][token] * collateralFeed.price()) / 1 ether;
    uint256 debtValue = synthDebt[user][token] * feeds[token].price() / 1 ether;
    require(collateralValue < debtValue * cRatioPassive[token] / 100, "Above cRatioPassivo");
    plrDelay[user][token] = block.timestamp + 10 days;

    _mintPenalty(token, user, msg.sender, FLAG_TIP);

    emit AccountFlaggedForLiquidation(user, msg.sender, plrDelay[user][token]);
  }

  function settleDebt(address user, GTokenERC20 token, uint amount) public {}

  function balanceOfSynth(address from, GTokenERC20 token) external view returns (uint) {
    return token.balanceOf(from);
  }

  function updateSynthCRatio(GTokenERC20 token, uint256 cRatio_, uint256 cRatioPassivo_) external onlyOwner {
    require(cRatioPassivo_ > cRatio_, 'invalid cRatio');
    cRatioActive[token] = cRatio_;
    cRatioPassive[token] = cRatioPassivo_;
  }

  function _mintPenalty(GTokenERC20 token, address user, address keeper, uint256 amount) public {
    token.mint(address(keeper), amount);
    synthDebt[address(user)][token] += amount;
  }

  // address riskReserveAddress, address liquidationVaultAddress
  function _transferLiquidate(GTokenERC20 token, address keeper, uint256 amount) public {
    uint keeperAmount = (amount / 100) * 60;
    // uint restAmount = (amount / 100) * 20;
    require(token.transfer(address(keeper), keeperAmount), 'failed transfer incentive');
    // token.transfer(address(riskReserveAddress), restAmount);
    // token.transfer(address(liquidationVaultAddress), restAmount);
  }

  function maximumByCollateral(GTokenERC20 token, uint256 amount) external view returns (uint256) {
    require(amount != 0, 'Incorrect values');
    uint256 collateralValue = (collateralBalance[msg.sender][token] + amount) * collateralFeed.price() / 1 ether;

    return (collateralValue / ratio) * 1 ether;
  }

  function maximumByDebt(GTokenERC20 token, uint256 amount) external view returns (uint256) {
    require(amount != 0, 'Incorrect values');
    uint256 debtValue = (synthDebt[msg.sender][token] + amount) * feeds[token].price() / 1 ether;

    return (debtValue * ratio) / 1 ether;
  }

  function simulateCRatio(GTokenERC20 token, uint256 amountGHO, uint256 amountGDAI) external view returns (uint256) {
    require(amountGHO != 0 || amountGDAI != 0, 'Incorrect values');
    uint256 collateralValue = (collateralBalance[msg.sender][token] + amountGHO) * collateralFeed.price() / 1 ether;
    uint256 debtValue = (synthDebt[msg.sender][token] + amountGDAI) * feeds[token].price() / 1 ether;

    return (collateralValue / debtValue) * 1 ether;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GTokenERC20 is ERC20, Ownable, Pausable {

  constructor(string memory name_, string memory symbol_, uint256 initialSupply) ERC20(name_, symbol_) {
    _mint(msg.sender, initialSupply);
  }

  function mint(address receiver, uint amount) external onlyOwner {
    _mint(receiver, amount);
  }

  function burn(uint256 amount) external  {
    _burn(msg.sender, amount);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './GTokenERC20.sol';
import './Minter.sol';
import './base/Feed.sol';
import './base/CoreMath.sol';

contract AuctionHouse is CoreMath {
  struct Auction {
    address user;
    address tokenAddress;
    address collateralTokenAddress;
    address keeperAddress;
    uint256 collateralBalance;
    uint256 collateralValue;
    uint256 synthAmount;
    uint256 auctionTarget;
    uint256 initialFeedPrice;
    address minterAddress;
    uint startTimestamp;
    uint endTimestamp;
  }

  uint256 constant PRICE_REDUCTION_RATIO = (uint256(99) * RAY) / 100;
  uint256 constant ratio = 9;
  uint256 constant buf = 1 ether;
  uint256 constant step = 90;
  uint256 constant dust = 10 ether;
  uint256 constant PENALTY_FEE = 11;
  uint256 constant chost = (dust * PENALTY_FEE) / 10;

  Auction[] public auctions;

  event Start(address indexed cdp, address indexed keeper, uint amount, uint start, uint end);
  event Take(uint256 indexed id, address indexed keeper, address indexed to, uint256 amount, uint256 price, uint256 end);

  function start (
    address user_,
    address tokenAddress_,
    address collateralTokenAddress_,
    address keeperAddress_,
    uint256 collateralBalance_,
    uint256 collateralValue_,
    uint256 auctionTarget_,
    uint256 initialFeedPrice_
  ) public {
    uint256 startTimestamp_ = block.timestamp;
    uint256 endTimestamp_ = startTimestamp_ + 1 weeks;

    auctions.push(
      Auction(
        user_,
        tokenAddress_,
        collateralTokenAddress_,
        keeperAddress_,
        collateralBalance_,
        collateralValue_,
        0,
        auctionTarget_,
        initialFeedPrice_,
        msg.sender,
        startTimestamp_,
        endTimestamp_
      )
    );

    emit Start(tokenAddress_, keeperAddress_, collateralBalance_, startTimestamp_, endTimestamp_);
    require(GTokenERC20(collateralTokenAddress_).transferFrom(msg.sender, address(this), collateralBalance_), "token transfer fail");
  }

  function take(uint256 auctionId, uint256 amount, uint256 maxCollateralPrice, address receiver) public  {
    Auction storage auction = auctions[auctionId];
    uint slice;
    uint keeperAmount;

    require(amount > 0 && auction.auctionTarget > 0, 'Invalid amount or auction finished');
    require(block.timestamp > auction.startTimestamp && block.timestamp < auction.endTimestamp, 'Auction period invalid');
    if (amount > auction.collateralBalance) {
      slice = auction.collateralBalance;
    } else {
      slice = amount;
    }

    uint priceTimeHouse = price(auction.initialFeedPrice, block.timestamp - auction.startTimestamp);
    require(maxCollateralPrice >= priceTimeHouse, 'price time house is bigger than collateral price');

    uint owe = mul(slice, priceTimeHouse) / WAD;
    uint liquidationTarget = calculateAmountToFixCollateral(auction.auctionTarget, (auction.collateralBalance * priceTimeHouse) / WAD);
    require(liquidationTarget > 0);

    if (liquidationTarget > owe) {
      keeperAmount = owe;

      if (auction.auctionTarget - owe >= chost) {
        slice = radiv(owe, priceTimeHouse);
        auction.auctionTarget -= owe;
        auction.collateralBalance -= slice;
      } else {
        require(auction.auctionTarget > chost, 'No partial purchase');
        slice = radiv((auction.auctionTarget - chost), priceTimeHouse);
        auction.auctionTarget = chost;
        auction.collateralBalance -= slice;
      }

      auction.synthAmount += mul(slice, priceTimeHouse) / WAD;
    } else {
      keeperAmount = liquidationTarget;
      slice = radiv(liquidationTarget, priceTimeHouse);
      auction.auctionTarget = 0;
      auction.collateralBalance -= slice;
      auction.synthAmount += keeperAmount;
    }


    GTokenERC20 synthToken = GTokenERC20(auction.tokenAddress);
    GTokenERC20 collateralToken = GTokenERC20(auction.collateralTokenAddress);

    require(synthToken.transferFrom(msg.sender, address(this), keeperAmount), 'transfer token from keeper fail');
    require(collateralToken.transfer(receiver, slice), "transfer token to keeper fail");

    if (auction.auctionTarget == 0) {
      collateralToken.approve(address(auction.minterAddress), auction.collateralBalance);
      synthToken.approve(address(auction.minterAddress), auction.synthAmount);

      auctionFinishCallback(
        auctionId,
        Minter(auction.minterAddress),
        address(auction.user),
        collateralToken,
        synthToken,
        auction.collateralBalance,
        auction.synthAmount
      );
    }

    emit Take(auctionId, msg.sender, receiver, slice, priceTimeHouse, auction.endTimestamp);
  }

  function calculateAmountToFixCollateral(uint256 debtBalance, uint256 collateral) public pure returns (uint) {
    uint dividend = (ratio * debtBalance) - collateral;

    return dividend / (ratio - 1);
  }

  function getAuction(uint auctionId) public view returns (Auction memory) {
    return auctions[auctionId];
  }

  function price(uint256 initialPrice, uint256 duration) public pure returns (uint256) {
    return rmul(initialPrice, rpow(PRICE_REDUCTION_RATIO, duration / step, RAY));
  }

  function auctionFinishCallback(uint256 id, Minter minter, address user, GTokenERC20 tokenCollateral, GTokenERC20 synthToken, uint256 collateralBalance, uint256 synthAmount) public {
    minter.auctionFinish(id, user, tokenCollateral, synthToken, collateralBalance, synthAmount);
  }
}

//SPDX-License-Identifier: MIT
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Feed {
  uint256 public price;
  string public name;

  constructor(uint price_, string memory name_) {
    price = price_;
    name = name_;
  }

  function updatePrice(uint price_) public {
    price = price_;
  }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract CoreMath {
  using SafeMath for uint256;

  uint256 constant WAD = 10**18;
  uint256 constant RAY = 10**27;
  uint256 constant RAD = 10**45;

  function radiv(uint256 dividend, uint256 divisor) public pure returns (uint256) {
    return div(div(dividend * RAD, divisor), RAY);
  }

  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = mul(x, y);
    require(y == 0 || z / y == x);
    z = div(z, RAY);
  }

  function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
    assembly {
      switch n case 0 { z := b }
      default {
        switch x case 0 { z := 0 }
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if shr(128, x) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x * y;
  }

  function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x / y;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}