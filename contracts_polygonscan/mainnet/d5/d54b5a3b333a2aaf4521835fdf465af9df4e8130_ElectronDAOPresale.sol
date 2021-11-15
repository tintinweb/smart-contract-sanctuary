/**
 *Submitted for verification at polygonscan.com on 2021-11-15
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

abstract contract ERC20 is IERC20 {

  using SafeMath for uint256;

  // TODO comment actual hash value.
  bytes32 constant private ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256( "ERC20Token" );
    
  // Present in ERC777
  mapping (address => uint256) internal _balances;

  // Present in ERC777
  mapping (address => mapping (address => uint256)) internal _allowances;

  // Present in ERC777
  uint256 internal _totalSupply;

  // Present in ERC777
  string internal _name;
    
  // Present in ERC777
  string internal _symbol;
    
  // Present in ERC777
  uint8 internal _decimals;

  constructor (string memory name_, string memory symbol_, uint8 decimals_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");

      _beforeTokenTransfer(sender, recipient, amount);

      _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address( this ), account_, amount_);
        _totalSupply = _totalSupply.add(amount_);
        _balances[account_] = _balances[account_].add(amount_);
        emit Transfer(address( this ), account_, amount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  function _beforeTokenTransfer( address from_, address to_, uint256 amount_ ) internal virtual { }
}

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

contract ElectronDAOPresale is ERC20, Ownable {

    using SafeMath for uint256;

    IERC20Metadata public ELECTRON;
    IERC20Metadata public DAI;

    bool public presaleActive = false;
    bool public redeemEnabled = false;

    uint256 public startPrice = 75 * 10**18;
    uint256 public tierThreshold = 20000 * 10**18;
    uint256 public primaryFactor = 4 * 10**18;
    uint256 public cutoffAmount = 500000 * 10**18;
    uint256 public secondaryFactor = 20 * 10**18;

    uint256 public presalePrice = startPrice;
    uint256 public totalDAIRaised = 0;

    constructor(
        address _ELECTRON,
        address _DAI
    ) ERC20("Electron DAO Presale Token", "PROTON", 9) {
        ELECTRON = IERC20Metadata(_ELECTRON);
        DAI = IERC20Metadata(_DAI);
    }

    function estimateTokensOut(uint256 daiAmount) public view returns (uint256) {
        uint256 tokens = 0;
        uint256 price = presalePrice;
        uint256 totalRaised = totalDAIRaised;

        uint256 tierAmount = tierThreshold.sub(totalRaised.mod(tierThreshold));
        if (daiAmount <= tierAmount) {
            return daiAmount.mul(10**ELECTRON.decimals()).div(price);
        } else {
            daiAmount = daiAmount.sub(tierAmount);
            tokens = tokens.add(tierAmount.mul(10**ELECTRON.decimals()).div(price));
            totalRaised = totalRaised.add(tierAmount);
            if (totalRaised <= cutoffAmount) {
                price = price.add(primaryFactor);
            } else {
                price = price.add(secondaryFactor);
            }
        }

        uint256 tiers = daiAmount.div(tierThreshold);
        if (tiers > 0) {
            (uint256 endPrice, uint256 finalPrice) = calculateEndPrice(price, tiers, totalRaised);
            daiAmount = daiAmount.sub(tiers.mul(tierThreshold));
            tokens = tokens.add(tiers.mul(tierThreshold).mul(10**ELECTRON.decimals()).div(price.add(endPrice).div(2)));
            return tokens.add(daiAmount.mul(10**ELECTRON.decimals()).div(finalPrice));
        }

        return tokens.add(daiAmount.mul(10**ELECTRON.decimals()).div(price));
    }

    function calculateEndPrice(uint256 price, uint256 tiers, uint256 totalRaised) internal view returns (uint256, uint256) {
        uint256 endPrice;
        uint256 finalPrice;
        if (totalRaised.add(tiers.mul(tierThreshold)) <= cutoffAmount) {
            endPrice = price.add(tiers.mul(primaryFactor)).sub(primaryFactor);
            finalPrice = endPrice.add(primaryFactor);
        } else {
            if (totalRaised >= cutoffAmount) {
                endPrice = price.add(tiers.mul(secondaryFactor)).sub(secondaryFactor);
                finalPrice = endPrice.add(secondaryFactor);
            } else {
                uint256 primaryTiers = cutoffAmount.sub(totalRaised).div(tierThreshold);
                endPrice = price.add(primaryTiers.mul(primaryFactor));
                endPrice = price.add(tiers.sub(primaryTiers).mul(secondaryFactor)).sub(secondaryFactor);
                finalPrice = endPrice.add(secondaryFactor);
            }
        }
        return (endPrice, finalPrice);
    }

    function getTokensOut(uint256 daiAmount) internal returns (uint256) {
        uint256 tokens = 0;
        uint256 tierAmount = tierThreshold.sub(totalDAIRaised.mod(tierThreshold));
        while (daiAmount >= tierAmount) {
            daiAmount = daiAmount.sub(tierAmount);
            totalDAIRaised = totalDAIRaised.add(tierAmount);
            tokens = tokens.add(tierAmount.mul(10**ELECTRON.decimals()).div(presalePrice));
            if (totalDAIRaised <= cutoffAmount) {
                presalePrice = presalePrice.add(primaryFactor);
            } else {
                presalePrice = presalePrice.add(secondaryFactor);
            }
            tierAmount = tierThreshold;
        }
        totalDAIRaised = totalDAIRaised.add(daiAmount);
        tokens = tokens.add(daiAmount.mul(10**ELECTRON.decimals()).div(presalePrice));
        return tokens;
    }

    function presale(uint256 daiAmount) external {
        require(presaleActive, "presale is not active");
        DAI.transferFrom(msg.sender, address(this), daiAmount);
        _mint(msg.sender, getTokensOut(daiAmount));
    }

    function redeemPresaleTokens(uint256 amount) external {
        require(redeemEnabled, "redeeming presale tokens is not enabled");
        _burn(msg.sender, amount);
        ELECTRON.transfer(msg.sender, amount);
    }

    function setPresaleActive(bool active) external onlyOwner() {
        presaleActive = active;
    }

    function setRedeemEnabled(bool enabled) external onlyOwner() {
        redeemEnabled = enabled;
    }

    function withdrawDAI(uint256 amount) external onlyOwner() {
        DAI.transfer(owner(), amount);
    }

}