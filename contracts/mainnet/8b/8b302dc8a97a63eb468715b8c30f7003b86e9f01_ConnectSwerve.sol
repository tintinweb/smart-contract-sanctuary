pragma solidity ^0.6.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface EventInterface {
    function emitEvent(uint connectorType, uint connectorID, bytes32 eventCode, bytes calldata eventData) external;
}


contract Stores {

  /**
   * @dev Return ethereum address
   */
  function getEthAddr() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
  }

  /**
   * @dev Return memory variable address
   */
  function getMemoryAddr() internal pure returns (address) {
    return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
  }

  /**
   * @dev Return InstaEvent Address.
   */
  function getEventAddr() internal pure returns (address) {
    return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97; // InstaEvent Address
  }

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
  }

  /**
  * @dev emit event on event contract
  */
  function emitEvent(bytes32 eventCode, bytes memory eventData) virtual internal {
    (uint model, uint id) = connectorID();
    EventInterface(getEventAddr()).emitEvent(model, id, eventCode, eventData);
  }

  /**
  * @dev Connector Details.
  */
  function connectorID() public view returns(uint model, uint id) {
    (model, id) = (1, 44);
  }

}

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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

}

interface ISwerve {
  function underlying_coins(int128 tokenId) external view returns (address token);
  function calc_token_amount(uint256[4] calldata amounts, bool deposit) external returns (uint256 amount);
  function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;
  function get_dy(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt) external returns (uint256 buyTokenAmt);
  function exchange(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt, uint256 minBuyToken) external;
  function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;
}

interface ISwerveZap {
  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external returns (uint256 amount);
}


contract SwerveHelpers is Stores, DSMath {
  /**
  * @dev Return Swerve Swap Address
  */
  function getSwerveSwapAddr() internal pure returns (address) {
    return 0x329239599afB305DA0A2eC69c58F8a6697F9F88d;
  }

  /**
  * @dev Return Swerve Token Address
  */
  function getSwerveTokenAddr() internal pure returns (address) {
    return 0x77C6E4a580c0dCE4E5c7a17d0bc077188a83A059;
  }

  /**
  * @dev Return Swerve Zap Address
  */
  function getSwerveZapAddr() internal pure returns (address) {
    return 0xa746c67eB7915Fa832a4C2076D403D4B68085431;
  }

  function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
    amt = (_amt / 10 ** (18 - _dec));
  }

  function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
    amt = mul(_amt, 10 ** (18 - _dec));
  }

  function getTokenI(address token) internal pure returns (int128 i) {
    if (token == address(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {
      // DAI Token
      i = 0;
    } else if (token == address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) {
      // USDC Token
      i = 1;
    } else if (token == address(0xdAC17F958D2ee523a2206206994597C13D831ec7)) {
      // USDT Token
      i = 2;
    } else if (token == address(0x0000000000085d4780B73119b644AE5ecd22b376)) {
      // TUSD Token
      i = 3;
    } else {
      revert("token-not-found.");
    }
  }
}

contract SwerveProtocol is SwerveHelpers {

  event LogSell(
    address indexed buyToken,
    address indexed sellToken,
    uint256 buyAmt,
    uint256 sellAmt,
    uint256 getId,
    uint256 setId
  );
  event LogDeposit(address token, uint256 amt, uint256 mintAmt, uint256 getId, uint256 setId);
  event LogWithdraw(address token, uint256 amt, uint256 burnAmt, uint256 getId,  uint256 setId);

  /**
    * @dev Sell Stable ERC20_Token.
    * @param buyAddr buying token address.
    * @param sellAddr selling token amount.
    * @param sellAmt selling token amount.
    * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function sell(
    address buyAddr,
    address sellAddr,
    uint sellAmt,
    uint unitAmt,
    uint getId,
    uint setId
  ) external payable {
    uint _sellAmt = getUint(getId, sellAmt);
    ISwerve swerve = ISwerve(getSwerveSwapAddr());
    TokenInterface _buyToken = TokenInterface(buyAddr);
    TokenInterface _sellToken = TokenInterface(sellAddr);
    _sellAmt = _sellAmt == uint(-1) ? _sellToken.balanceOf(address(this)) : _sellAmt;
    _sellToken.approve(address(swerve), _sellAmt);

    uint _slippageAmt = convert18ToDec(_buyToken.decimals(), wmul(unitAmt, convertTo18(_sellToken.decimals(), _sellAmt)));

    uint intialBal = _buyToken.balanceOf(address(this));
    swerve.exchange(getTokenI(sellAddr), getTokenI(buyAddr), _sellAmt, _slippageAmt);
    uint finalBal = _buyToken.balanceOf(address(this));

    uint _buyAmt = sub(finalBal, intialBal);

    setUint(setId, _buyAmt);

    emit LogSell(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    bytes32 _eventCode = keccak256("LogSell(address,address,uint256,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    emitEvent(_eventCode, _eventParam);

  }

  /**
    * @dev Deposit Token.
    * @param token token address.
    * @param amt token amount.
    * @param unitAmt unit amount of swerve_amt/token_amt with slippage.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function deposit(
    address token,
    uint amt,
    uint unitAmt,
    uint getId,
    uint setId
  ) external payable {
    uint256 _amt = getUint(getId, amt);
    TokenInterface tokenContract = TokenInterface(token);

    _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
    uint[4] memory _amts;
    _amts[uint(getTokenI(token))] = _amt;

    tokenContract.approve(getSwerveSwapAddr(), _amt);

    uint _amt18 = convertTo18(tokenContract.decimals(), _amt);
    uint _slippageAmt = wmul(unitAmt, _amt18);

    TokenInterface swerveTokenContract = TokenInterface(getSwerveTokenAddr());
    uint initialSwerveBal = swerveTokenContract.balanceOf(address(this));

    ISwerve(getSwerveSwapAddr()).add_liquidity(_amts, _slippageAmt);

    uint finalSwerveBal = swerveTokenContract.balanceOf(address(this));

    uint mintAmt = sub(finalSwerveBal, initialSwerveBal);

    setUint(setId, mintAmt);

    emit LogDeposit(token, _amt, mintAmt, getId, setId);
    bytes32 _eventCode = keccak256("LogDeposit(address,uint256,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(token, _amt, mintAmt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }

  /**
    * @dev Withdraw Token.
    * @param token token address.
    * @param amt token amount.
    * @param unitAmt unit amount of swerve_amt/token_amt with slippage.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function withdraw(
    address token,
    uint256 amt,
    uint256 unitAmt,
    uint getId,
    uint setId
  ) external payable {
    uint _amt = getUint(getId, amt);
    int128 tokenId = getTokenI(token);

    TokenInterface swerveTokenContract = TokenInterface(getSwerveTokenAddr());
    ISwerveZap swerveZap = ISwerveZap(getSwerveZapAddr());
    ISwerve swerveSwap = ISwerve(getSwerveSwapAddr());

    uint _swerveAmt;
    uint[4] memory _amts;
    if (_amt == uint(-1)) {
      _swerveAmt = swerveTokenContract.balanceOf(address(this));
      _amt = swerveZap.calc_withdraw_one_coin(_swerveAmt, tokenId);
      _amts[uint(tokenId)] = _amt;
    } else {
      _amts[uint(tokenId)] = _amt;
      _swerveAmt = swerveSwap.calc_token_amount(_amts, false);
    }


    uint _amt18 = convertTo18(TokenInterface(token).decimals(), _amt);
    uint _slippageAmt = wmul(unitAmt, _amt18);

    swerveTokenContract.approve(address(swerveSwap), 0);
    swerveTokenContract.approve(address(swerveSwap), _slippageAmt);

    swerveSwap.remove_liquidity_imbalance(_amts, _slippageAmt);

    setUint(setId, _amt);

    emit LogWithdraw(token, _amt, _swerveAmt, getId, setId);
    bytes32 _eventCode = keccak256("LogWithdraw(address,uint256,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(token, _amt, _swerveAmt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }

}

contract ConnectSwerve is SwerveProtocol {
  string public name = "Swerve-swUSD-v1.0";
}