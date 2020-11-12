pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


//import "openzeppelin-eth/contracts/ownership/Ownable.sol";
//pragma solidity ^0.4.24;

//import "zos-lib/contracts/Initializable.sol";
//pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function initialize(address sender) public initializer {
    _owner = sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  uint256[50] private ______gap;
}

//import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";
//pragma solidity ^0.4.24;

//import "./IERC20.sol";
//pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is Initializable, IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function initialize(string name, string symbol, uint8 decimals) public initializer {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }

  uint256[50] private ______gap;
}


//import "./lib/SafeMathInt.sol";
/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

//pragma solidity 0.4.24;


/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}


/**
 * @title uFragments ERC20 token
 * @dev This is part of an implementation of the uFragments Ideal Money protocol.
 *      uFragments is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining tokens proportionally across all wallets.
 *
 *      uFragment balances are internally represented with a hidden denomination, 'gons'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'gons' and the public 'fragments'.
 */
contract UFragments is ERC20Detailed, Ownable {
    // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // Anytime there is division, there is a risk of numerical instability from rounding errors. In
    // order to minimize this risk, we adhere to the following guidelines:
    // 1) The conversion rate adopted is the number of gons that equals 1 fragment.
    //    The inverse rate must not be used--TOTAL_GONS is always the numerator and _totalSupply is
    //    always the denominator. (i.e. If you want to convert gons to fragments instead of
    //    multiplying by the inverse rate, you should divide by the normal rate)
    // 2) Gon balances converted into Fragments are always rounded down (truncated).
    //
    // We make the following guarantees:
    // - If address 'A' transfers x Fragments to address 'B'. A's resulting external balance will
    //   be decreased by precisely x Fragments, and B's external balance will be precisely
    //   increased by x Fragments.
    //
    // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
    // This is because, for any conversion function 'f()' that has non-zero rounding error,
    // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogMonetaryPolicyUpdated(address monetaryPolicy);

    // Used for authentication
    address public monetaryPolicy;

    modifier onlyMonetaryPolicy() {
        require(msg.sender == monetaryPolicy);
        _;
    }

    bool private rebasePausedDeprecated;
    bool private tokenPausedDeprecated;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 50 * 10**6 * 10**DECIMALS;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;

    /**
     * @param monetaryPolicy_ The address of the monetary policy contract to use for authentication.
     */
    function setMonetaryPolicy(address monetaryPolicy_)
        external
        onlyOwner
    {
        monetaryPolicy = monetaryPolicy_;
        emit LogMonetaryPolicyUpdated(monetaryPolicy_);
    }

    /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyMonetaryPolicy
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        // From this point forward, _gonsPerFragment is taken as the source of truth.
        // We recalculate a new _totalSupply to be in agreement with the _gonsPerFragment
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(TOTAL_GONS - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.
        // _totalSupply = TOTAL_GONS.div(_gonsPerFragment)

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function initialize(address owner_)
        public
        initializer
    {
        ERC20Detailed.initialize("AmpleForthGold", "AAU", uint8(DECIMALS));
        Ownable.initialize(owner_);

        rebasePausedDeprecated = false;
        tokenPausedDeprecated = false;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[owner_] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit Transfer(address(0x0), owner_, _totalSupply);
    }

    /**
     * @return The total number of fragments.
     */
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        public
        view
        returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
}

//import "./RebaseDelta.sol";
//pragma solidity >=0.4.24;

//import '@uniswap/v2-periphery/contracts/libraries/SafeMath.sol';

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library RB_SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint) {
        require(y != 0);
        return x / y;    
    }
}

library RB_UnsignedSafeMath {
    function add(int x, int y) internal pure returns (int z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(int x, int y) internal pure returns (int z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(int x, int y) internal pure returns (int z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(int x, int y) internal pure returns (int) {
        require(y != 0);
        return x / y;    
    }
}


//import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes /* calldata */ data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


/** Calculates the Delta for a rebase based on the ratio
*** between the price of two different token pairs on 
*** Uniswap 
***
*** - minimalist design
*** - low gas design
*** - free for anyone to call. 
***
****/
contract RebaseDelta {

    using RB_SafeMath for uint256;
    using RB_UnsignedSafeMath for int256;
    
    uint256 private constant PRICE_PRECISION = 10**9;

    function getPrice(IUniswapV2Pair pair_, bool flip_) 
    public
    view
    returns (uint256) 
    {
        require(address(pair_) != address(0));

        (uint256 reserves0, uint256 reserves1, ) = pair_.getReserves();

        if (flip_) {
            (reserves0, reserves1) = (reserves1, reserves0);            
        }

        // reserves0 = base (probably ETH/WETH)
        // reserves1 = token of interest (maybe ampleforthgold or paxusgold etc)

        // multiply to equate decimals, multiply up to PRICE_PRECISION

        uint256 price = (reserves1.mul(PRICE_PRECISION)).div(reserves0);

        return price;
    }

    // calculates the supply delta for moving the price of token X to the price
    // of token Y (with the understanding that they are both priced in a common
    // tokens value, i.e. WETH).  
    function calculate(IUniswapV2Pair X_,
                      bool flipX_,
                      uint256 decimalsX_,
                      uint256 SupplyX_, 
                      IUniswapV2Pair Y_,
                      bool flipY_,
                      uint256 decimalsY_)
    public
    view
    returns (int256)
    {
        uint256 px = getPrice(X_, flipX_);
        require(px != uint256(0));
        uint256 py = getPrice(Y_, flipY_);
        require(py != uint256(0));

        uint256 targetSupply = (SupplyX_.mul(py)).div(px);

        // adust for decimals
        if (decimalsX_ == decimalsY_) {
            // do nothing
        }
        else if (decimalsX_ > decimalsY_) {
            uint256 ddg = (10**decimalsX_).div(10**decimalsY_);
            require (ddg != uint256(0));
            targetSupply = targetSupply.mul(ddg); 
        }
        else {
            uint256 ddl = (10**decimalsY_).div(10**decimalsX_);
            require (ddl != uint256(0));
            targetSupply = targetSupply.div(ddl);        
        }

        int256 delta = int256(SupplyX_).sub(int256(targetSupply));

        return delta;
    }
}

//==Developed and deployed by the AmpleForthGold Team: https://ampleforth.gold
//  With thanks to:  
//         https://github.com/Auric-Goldfinger
//         https://github.com/z0sim0s
//         https://github.com/Aurum-hub

/**
 * @title Orchestrator 
 * @notice The orchestrator is the main entry point for rebase operations. It coordinates the rebase
 * actions with external consumers (price oracles) and provides timing / access control for when a 
 * rebase occurs.
 * 
 * Orchestrator is based on Ampleforth.org implmentation with modifications by the AmpleForthgold team.
 * It is a merge and modification of the Orchestrator.sol and UFragmentsPolicy.sol from the original 
 * Ampleforth project. Thanks to the Ampleforth.org team!
 *
 * Code ideas also come from the RMPL.IO (RAmple Project), YAM team and BASED team. 
 * Thanks to the all whoose ideas we stole! 
 * 
 * We have simplifed the design to lower the gas fees. In some places we have removed things that were
 * "nice to have" because of the cost of GAS. Specifically we have lowered the number of events and 
 * hard coded things that we know are going to be constant (such as not looking up a uniswap pair,
 * we just pass the pair pointer into the contract). This was done to save GAS and lower the execution
 * cost of the contract.
 *
 * The Price used for rebase calculations shall be sourced from Uniswap (on chain liquidity pools).
 * 
 * Relying on price Oracles (either on chain or off chain) will never be perfect. Oracles go bad, 
 * others come good. At present we will use liquidity pools on uniswap to provide the oracles
 * for pricing. However those oracles may go bad and need to be replaced. We think that oracle 
 * failure in the short term is unlikly, but not impossible. In the long term it may be likely
 * to see oracle failure. Due to this the contract 'owners' (the AmpleForthGold team) shall 
 * have an 'off switch' in the code to disable and override rebase operations. At some point 
 * it may be needed...but we hope it is not needed.  
 *      
 */
contract Orchestrator is Ownable {

    using SafeMath for uint16;
    using SafeMath for uint256;
    using SafeMathInt for int256;
    
    // The ERC20 Token for ampleforthgold
    UFragments public afgToken = UFragments(0x8E54954B3Bbc07DbE3349AEBb6EAFf8D91Db5734);
    
    // oracle configuration - see RebaseDelta.sol for details.
    RebaseDelta public oracle = RebaseDelta(0xF09402111AF6409B410A8Dd07B82F1cd1674C55F);
    IUniswapV2Pair public tokenPairX = IUniswapV2Pair(0x2d0C51C1282c31d71F035E15770f3214e20F6150);
    IUniswapV2Pair public tokenPairY = IUniswapV2Pair(0x9C4Fe5FFD9A9fC5678cFBd93Aa2D4FD684b67C4C);
    bool public flipX = false;
    bool public flipY = false;
    uint8 public decimalsX = 9;
    uint8 public decimalsY = 9;
    
    // The timestamp of the last rebase event generated from this contract.
    // Technically another contract cauld also cause a rebase event, 
    // so this cannot be relied on globally. uint64 should not clock
    // over in forever. 
    uint64 public lastRebase = uint64(0);

    // The number of rebase cycles since inception. Why the original
    // designers did not keep this inside uFragments is a question
    // that really deservers an answer? We can use a uint16 cause we
    // will be about 179 years old before it clocks over. 
    uint16 public epoch = 3;

    // Transactions are used to generate call back to DEXs that need to be 
    // informed about rebase events. Specifically with uniswap the function
    // on the IUniswapV2Pair.sync() needs to be called so that the 
    // liquidity pool can reset it reserves to the correct value.  
    // ...Stable transaction ordering is not guaranteed.
    struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }
    event TransactionFailed(address indexed destination, uint index, bytes data);
    Transaction[] public transactions;
    
    /**
     * Just initializes the base class.
     */
    constructor() 
        public {
        Ownable.initialize(msg.sender);
    }

    /**
     * @notice Owner entry point to initiate a rebase operation.
     * @param supplyDelta the delta as passed to afgToken.rebase.
     *        (the delta needs to be calulated off chain or by the 
     *        calling contract).
     * @param disable_ passing true will disable the ability of 
     *        users (other then the owner) to cause a rebase.
     *
     * The owner can always generate a rebase operation. At some point in the future
     * the owners keys shall be burnt. However at this time (and until we are certain
     * everthing is working as it should) the owners shall keep their keys.
     * The ability for the owners to generate a rebase of any value at any time is a 
     * carry over from the original ampleforth project. This function is just a little
     * more direct.  
     */ 
    function ownerForcedRebase(int256 supplyDelta, bool disable_)
        external
        onlyOwner
    {
        /* If lastrebase is set to 0 then *users* cannot cause a rebase. 
         * This should allow the owner to disable the auto-rebase operations if
         * things go wrong (see things go wrong above). */
        if (disable_) {
            lastRebase = uint64(0);
        } else {
            lastRebase = uint64(block.timestamp);
        }
         
        afgToken.rebase(epoch.add(1), supplyDelta);
        popTransactionList();
    }

    /**
     * @notice Main entry point to initiate a rebase operation.
     *         On success returns the new supply value.
     */
    function rebase()
        external
        returns (uint256)
    {
        // The owner shall call this member for the following reasons:
        //   (1) Something went wrong and we need a rebase now!
        //   (2) At some random time at least 24 hours, but no more then 48
        //       hours after the last rebase.  
        if (Ownable.isOwner())
        {
            return internal_rebase();
        }

        // we require at least 1 owner rebase event prior to being enabled!
        require (lastRebase != uint64(0));        

        // at least 24 hours shall have passed since the last rebase event.
        require (lastRebase + 1 days < uint64(block.timestamp));

        // if more then 48 hours have passed then allow a rebase from anyone
        // willing to pay the GAS.
        if (lastRebase + 2 days < uint64(block.timestamp))
        {
            return internal_rebase();
        }

        // There is (currently) no way of generating a random number in a 
        // contract that cannot be seen/used by the miner. Thus a big miner 
        // could use information on a rebase for their advantage. We do not
        // want to give any advantage to a big miner over a little trader,
        // thus the traders ability to generate and see a rebase (ahead of time)
        // should be about the same as a that of a large miners.
        //
        // If (in the future) the ability to provide true randomeness 
        // changes then we would like to re-write this bit of code to provide
        // true random rebases where no one gets an advantage. 
        // 
        // A day after the last rebase, anyone can call this rebase function
        // to generate a rebase. However to give it a little bit of complexity 
        // and mildly lower the ability of traders/miners to take advantage 
        // of the rebase we will set the *fair* odds of a rebase() call
        // succeeding at 20%. Of course it can still be gamed, but this 
        // makes gaming it just that little bit harder.
        // 
        // MINERS: To game it the miner would need to adjust his coinbase to 
        // correctly solve the xor with the preceeding block hashs,
        // That is do-able, but the miner would need to go out of there
        // way to do it...but no perfect solutions so this is it at the
        // moment.  
        //
        // TRADERS: To game it they could just call this function many times
        // until it triggers. They have a 20% chance of triggering each 
        // time they call it. They could get lucky, or they could burn a lot of 
        // GAS. Whatever they do it will be obvious from the many calls to this
        // function. 
        uint256 odds = uint256(blockhash(block.number - 1)) ^ uint256(block.coinbase);
        if ((odds % uint256(5)) == uint256(1))
        {
            return internal_rebase(); 
        }      

        // no change, no rebase!
        return uint256(0);
    }

    /**
     * @notice Internal entry point to initiate a rebase operation.
     *         If we get here then a rebase call to the erc20 token 
     *         will occur.
     * 
     *         returns the new supply value.
     */
    function internal_rebase() 
        private 
        returns(uint256) {
        lastRebase = uint64(block.timestamp);
        uint256 z = afgToken.rebase(epoch.add(1), calculateRebaseDelta(true));
        popTransactionList();
        return z;
    }

    /**
     * @notice Configures the oracle & information passed to the oracle 
     *         to calculate the rebase. See RebaseDelta for definition
     *         of params.
     *      
     *         Initially tokenPairX is the uniswap pair for AAU/WETH
     *         and tokenPairY is the uniswap pair for PAXG/WETH.
     *         These addresses can be verified on etherscan.io.
     */
    function configureOracle(IUniswapV2Pair tokenPairX_,
                      bool flipX_,
                      uint8 decimalsX_,
                      IUniswapV2Pair tokenPairY_,
                      bool flipY_,
                      uint8 decimalsY_,
                      RebaseDelta oracle_)
        external
        onlyOwner
        {
            tokenPairX = tokenPairX_;
            flipX = flipX_;
            decimalsX = decimalsX_;
            tokenPairY = tokenPairY_;
            flipY = flipY_;
            decimalsY = decimalsY_;
            oracle = oracle_;
    }

    /**
     * @notice tries to calculate a rebase based on the configured oracle info. 
     *
     * @param limited_ passing true will limit the rebase based on the 5% rule. 
     */
    function calculateRebaseDelta(bool limited_) 
        public
        view 
        returns (int256) 
        { 
            require (afgToken != UFragments(0));
            require (oracle != RebaseDelta(0));
            require (tokenPairX != IUniswapV2Pair(0));
            require (tokenPairY != IUniswapV2Pair(0));
            require (decimalsX != uint8(0));
            require (decimalsY != uint8(0));
            
            uint256 supply = afgToken.totalSupply();
            int256 delta = - oracle.calculate(
                tokenPairX,
                flipX,
                decimalsX,
                supply, 
                tokenPairY,
                flipY,
                decimalsY);

            if (!limited_) {
                // Unlimited (brutal) rebase.
                return delta;
            }   

            if (delta == int256(0))
            {
                // no rebase needed!
                return int256(0);
            }

            /** 5% rules: 
             *      (1) If the price is in the +-5% range do not rebase at all. This 
             *          allows the market to fix the price to within a 10% range.
             *      (2) If the price is within +-10% range then only rebase by 1%.
             *      (3) If the price is more then +-10% then the change shall be half the 
             *          delta. i.e. if the price diff is -28% then the change will be -14%.
             */
            int256 supply5p = int256(supply.div(uint256(20))); // 5% == 5/100 == 1/20
   
            if (delta < int256(0)) {
                if (-delta < supply5p) {
                    return int256(0); // no rebase: 5% rule (1)
                }
                if (-delta < supply5p.mul(int256(2))) {
                    return (-supply5p).div(int256(5)); // -1% rebase
                }
            } else {
                if (delta < supply5p) {
                    return int256(0); // no rebase: 5% rule (1)
                }
                if (delta < supply5p.mul(int256(2))) {
                    return supply5p.div(int256(5)); // +1% rebase
                }
            }

            return (delta.div(2)); // half delta rebase
    }

    // for testing purposes only!
    // winds back time a day at a time. 
    function windbacktime() 
        public
        onlyOwner {         
        require (lastRebase > 1 days);
        lastRebase-= 1 days;
    }

    //===TRANSACTION FUNCTIONALITY (mostly identical to original Ampleforth implementation)

    /* generates callbacks after a rebase */
    function popTransactionList()
        private
    {
        // we are getting an AAU price feed from this uniswap pair, thus when the rebase occurs 
        // we need to ask it to rebase the AAU tokens in the pair. We always know this needs
        // to be done, so no use making a transcation for it.
        if (tokenPairX != IUniswapV2Pair(0)) {  
            tokenPairX.sync();
        }

        // iterate thru other interested parties and generate a call to update their 
        // contracts. 
        for (uint i = 0; i < transactions.length; i++) {
            Transaction storage t = transactions[i];
            if (t.enabled) {
                bool result =
                    externalCall(t.destination, t.data);
                if (!result) {
                    emit TransactionFailed(t.destination, i, t.data);
                    revert("Transaction Failed");
                }
            }
        }
    } 

    /**
     * @notice Adds a transaction that gets called for a downstream receiver of rebases
     * @param destination Address of contract destination
     * @param data Transaction data payload
     */
    function addTransaction(address destination, bytes data)
        external
        onlyOwner
    {
        transactions.push(Transaction({
            enabled: true,
            destination: destination,
            data: data
        }));
    }

    /**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */
    function removeTransaction(uint index)
        external
        onlyOwner
    {
        require(index < transactions.length, "index out of bounds");

        if (index < transactions.length - 1) {
            transactions[index] = transactions[transactions.length - 1];
        }

        transactions.length--;
    }

    /**
     * @param index Index of transaction. Transaction ordering may have changed since adding.
     * @param enabled True for enabled, false for disabled.
     */
    function setTransactionEnabled(uint index, bool enabled)
        external
        onlyOwner
    {
        require(index < transactions.length, "index must be in range of stored tx list");
        transactions[index].enabled = enabled;
    }

    /**
     * @return Number of transactions, both enabled and disabled, in transactions list.
     */
    function transactionsSize()
        external
        view
        returns (uint256)
    {
        return transactions.length;
    }

    /**
     * @dev wrapper to call the encoded transactions on downstream consumers.
     * @param destination Address of destination contract.
     * @param data The encoded data payload.
     * @return True on success
     */
    function externalCall(address destination, bytes data)
        internal
        returns (bool)
    {
        bool result;
        assembly {  // solhint-disable-line no-inline-assembly
            // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let outputAddress := mload(0x40)

            // First 32 bytes are the padded length of data, so exclude that
            let dataAddress := add(data, 32)

            result := call(
                // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB)
                // + callValueTransferGas (9000) + callNewAccountGas
                // (25000, in case the destination address does not exist and needs creating)
                sub(gas, 34710),


                destination,
                0, // transfer value in wei
                dataAddress,
                mload(data),  // Size of the input, in bytes. Stored in position 0 of the array.
                outputAddress,
                0  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}