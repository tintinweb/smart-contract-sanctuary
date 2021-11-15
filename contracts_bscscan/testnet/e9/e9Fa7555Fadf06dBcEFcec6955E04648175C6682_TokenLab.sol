// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './contexts/BuildableContext.sol';
import './interfaces/IBEP20.sol';
import './interfaces/ICarrier.sol';
import './libraries/SafeMath.sol';

contract CarriedToken is BuildableContext {

    using SafeMath for uint256;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private _decimals;

    uint256 private _initialTotalSupply;

    address private _carrier;


    constructor (string memory tokenName, string memory tokenSymbol, uint256 initialTrueSupply, uint8 tokenDecimals) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        _initialTotalSupply = initialTrueSupply * (10**_decimals);

        _carrier = address(0);
    }


    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    function getOwner() external view returns (address) {
        return _factory;
    }

    function carrier() external view returns (address) {
        return _carrier;
    }
    
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipiant, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipiant, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
    }

    function transferFrom(address sender, address recipiant, uint256 amount) external returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer from: cannot transfer more than allowance"));
        _transfer(sender, recipiant, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 allowanceIncrease) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(allowanceIncrease));
        return true;
    }

    function decreaseAllowance(address spender, uint256 allowanceDecrease) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(allowanceDecrease, "Decrease allowance: cannot decrease allowance below zero"));
        return true;
    }

    function setCarrier(address carrier) external onlyFactory returns (bool) {
        require(carrier != address(0), "Set carrier: carrier cannot be set to the 0 address");
        require(_carrier == address(0), "Set carrier: carrier already set");

        _carrier = carrier;
        _mint(_carrier, _initialTotalSupply);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Transfer: cannot transfer to the 0 address");

        _balances[from] = _balances[from].sub(amount, "Transfer: amount exceeds senser's balance");

        if(from == address(_carrier)) {
            _balances[to] = _balances[to].add(amount);
            emit Transfer(from, to, amount);
        } else {
            _balances[_carrier] = _balances[_carrier].add(amount);
            emit Transfer(from, _carrier, amount);
            ICarrier(_carrier).carry(from, to, amount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve: cannot approve transfer from 0 address.");
        require(spender != address(0), "Approve: cannot approve transfer to 0 address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
    
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Mint: cannot mint to the 0 address");

        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), address(this), amount);

        _balances[to] = _balances[to].add(amount);
        emit Transfer(address(this), to, amount);
    }


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './contexts/BuildableContext.sol';
import './interfaces/IBEP20.sol';
import './interfaces/ICarrier.sol';
import './libraries/SafeMath.sol';

contract TokenCarrier is BuildableContext {

    using SafeMath for uint256;

    IBEP20 private _carrierToken;
    uint256 private _carrierTokenDecimalFactor;

    uint256 private _liquidityTokenDecimalFactor;

    uint256 private _maxPurchaseRate;

    uint256 private _purchaseFeePercentage;
    uint256 private _liquidationFeePercentage;

    constructor(address carrierToken) {
        _carrierToken = IBEP20(carrierToken);
        _carrierTokenDecimalFactor = 10**_carrierToken.decimals();

        _liquidityTokenDecimalFactor = 10**(18);

        _maxPurchaseRate = 3 * _liquidityTokenDecimalFactor;

        _purchaseFeePercentage = 1;
        _liquidationFeePercentage = 1;
    }

    // ----- TOKEN CARRIER FUNCTIONS ----- //
    // ----------------------------------- //

    function carrierToken() public view returns (address) {
        return address(_carrierToken);
    }

    function carry(address from, address to, uint256 amount) external returns (bool) {
        require(_msgSender() == address(_carrierToken), "Carry: carry method muct be called by calliable token");

        _carrierToken.transfer(to, amount);

        return true;
    }
    
    // @dev function injectLiquidity() - public payable method used to inject liquidity without recieving tokens
    function injectLiquidity() public payable returns (bool) {
        return true;
    }

    // ----- PURCHASE FUNCTIONS ----- //
    // ------------------------------- //

    // function purchaseRate() - returns the raw number of carrier tokerns given per liquidity token
    function purchaseRate() public view returns (uint256) {
        return _purchaseRate();
    }

    function purchaseRateMax() public view returns (uint256) {
        return _maxPurchaseRate;
    }

    function purchaseFeePercentage() public view returns (uint256) {
        return _purchaseFeePercentage;
    }

    function _purchaseRate() internal view returns (uint256) {
        uint256 currentPurchaseRate = _carrierToken.balanceOf(address(this)).mul(_liquidityTokenDecimalFactor).div(address(this).balance);
        if(currentPurchaseRate > _maxPurchaseRate){
            return _maxPurchaseRate;
        } else {
            return currentPurchaseRate;
        }
    }

    function _purchaseRateDeducted(uint256 deduction) internal view returns (uint256) {
        uint256 currentPurchaseRate = _carrierToken.balanceOf(address(this)).mul(_liquidityTokenDecimalFactor).div(address(this).balance.sub(deduction));
        if(currentPurchaseRate > _maxPurchaseRate){
            return _maxPurchaseRate;
        } else {
            return currentPurchaseRate;
        }
    }

    // @dev function purchase() - public function for purchasing carrier tokens with liquidity tokens; liquidity token allowance must be provided first
    function purchase() public payable returns (bool) {
        uint256 avalible = _carrierToken.balanceOf(address(this));
        uint256 owed = msg.value.sub(msg.value.mul(_purchaseFeePercentage).div(100)).mul(_purchaseRateDeducted(msg.value)).div(_liquidityTokenDecimalFactor);

        require(avalible >= owed, "Purchase: not enough carrier token avalible");

        _carrierToken.transfer(_msgSender(), owed);

        return true;
    }

    function updatePurchaseRateMax(uint256 newPurchaseRateMax) external onlyFactory returns (bool) {
        _maxPurchaseRate = newPurchaseRateMax;
        return true;
    }

    function updatePurchaseFeePercentage(uint256 newPurchaseFeePercentage) external onlyFactory returns (bool) {
        require(newPurchaseFeePercentage < 100, "Update purchase fee percentage: new purchase fee perchentage must be less than 100");

        _purchaseFeePercentage = newPurchaseFeePercentage;

        return true;
    }

    // ----- LIQUIDATE FUNCTIONS ----- //
    // ------------------------------- //

    // @dev function liquidationRate() - returns the raw number of liquidity tokens given per carrier token 
    function liquidationRate() public view returns (uint256) {
        return _liquidationRate();
    }

    function liquidationFeePercentage() public view returns (uint256) {
        return _liquidationFeePercentage;
    }

    function _liquidationRate() internal view returns (uint256) {
        return address(this).balance.mul(_carrierTokenDecimalFactor).div(_carrierToken.totalSupply().sub(_carrierToken.balanceOf(address(this))));
    }

    // @dev function liquidate() - public function for liquidating carrier tokens for liquidity tokens; carried token allowance must be provided first
    function liquidate(uint256 tokenToLiquidate) public returns (bool) {
        uint256 allowance = _carrierToken.allowance(_msgSender(), address(this));
        uint256 avalible = address(this).balance;

        require(allowance >= tokenToLiquidate, "Liquidate: not enough carried token allowance provided");

        uint256 owed = tokenToLiquidate.mul(_liquidationRate()).div(_carrierTokenDecimalFactor).mul(100 - _liquidationFeePercentage).div(100);

        require(avalible >= owed, "Purchase: not enough carrier liquidity avalible");

        payable(_msgSender()).transfer(owed);
        _carrierToken.transferFrom(_msgSender(), address(this), tokenToLiquidate);

        return true;
    }

    function updateLiquidationFeePercentage(uint256 newLiquidationFeePercentage) external onlyFactory returns (bool){
        require(newLiquidationFeePercentage < 100, "Update liquidation fee percentage: new liquidation fee percentage must be less than 100");

        _liquidationFeePercentage = newLiquidationFeePercentage;

        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./contexts/OwnableContext.sol";
import "./CarriedToken.sol";
import "./TokenCarrier.sol";

contract TokenLab is OwnableContext {

    CarriedToken private _testToken;
    TokenCarrier private _tokenCarrier;


    constructor() {
        
        _testToken = new CarriedToken("Test Carrier Token", "TcT", 100000000, 9);
        
        _tokenCarrier = new TokenCarrier(address(_testToken));

        _testToken.setCarrier(address(_tokenCarrier));

    }

    function token() public view returns (address) {
        return address(_testToken);
    }

    function tokenCarrier() public view returns (address) {
        return address(_tokenCarrier);
    }

    function updateCarrierMaxPurchaseRate(uint256 newMaxPurchaseRate) public onlyOwner returns (bool) {
        return _tokenCarrier.updatePurchaseRateMax(newMaxPurchaseRate);
    }

    function updateCarrierPurchaseFeePercentage(uint256 newPurchaseFeePercentage) public onlyOwner returns (bool) {
        return _tokenCarrier.updatePurchaseFeePercentage(newPurchaseFeePercentage);
    }
    
    function updateCarrierLiquidationFeePercentage(uint256 newLiquidationFeePercentage) public onlyOwner returns (bool) {
        return _tokenCarrier.updateLiquidationFeePercentage(newLiquidationFeePercentage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './CallableContext.sol';

contract BuildableContext is CallableContext {

    address internal _factory;


    constructor() {
        _factory = _msgSender();
    }


    modifier onlyFactory() {
        require(_msgSender() == _factory, "Only Factory: caller is not context factory");
        _;
    }


    function factory() external view returns (address){
        return _factory;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract CallableContext {

    function _context() internal view returns (address) {
        return address(this);
    }
    

    function _msgSender() internal view returns (address) {
        return address(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }

    function _msgTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './CallableContext.sol';

contract OwnableContext is CallableContext {

    address internal _owner;


    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }


    modifier onlyOwner() {
        require(_msgSender() == _owner, "Only Owner: caller is not context owner");
        _;
    }


    event OwnershipTransferred(address previousOwner, address newOwner);


    function owner() external view returns (address) {
        return _owner;
    }


    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != _owner, "Transfer Ownership: new owner is already owner");
        require(newOwner != address(0), "Transfer Ownership: new owner cannot be the 0 address");

        address previousOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(previousOwner, _owner);
    }

    function renounceOwnership() external onlyOwner {
        _renounceOwnership();
    }

    function _renounceOwnership() internal {
        address previousOwner = _owner;
        _owner = address(0);

        emit OwnershipTransferred(previousOwner, _owner);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IBEP20 {

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.8.6;

interface ICarrier {

    function carry(address from, address to, uint256 amount) external returns (bool);

}

pragma solidity ^0.8.6;
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library SafeMath {

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
  
}

