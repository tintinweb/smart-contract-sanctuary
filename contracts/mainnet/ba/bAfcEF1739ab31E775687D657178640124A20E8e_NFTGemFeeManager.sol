// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../interfaces/INFTGemFeeManager.sol";
import "../interfaces/IERC20.sol";

contract NFTGemFeeManager is INFTGemFeeManager {
    address private operator;

    uint256 private constant MINIMUM_LIQUIDITY = 100;
    uint256 private constant FEE_DIVISOR = 1000;

    mapping(address => uint256) private feeDivisors;
    uint256 private _defaultFeeDivisor;

    mapping(address => uint256) private _liquidity;
    uint256 private _defaultLiquidity;

    /**
     * @dev constructor
     */
    constructor() {
        _defaultFeeDivisor = FEE_DIVISOR;
        _defaultLiquidity = MINIMUM_LIQUIDITY;
    }

    /**
     * @dev Set the address allowed to mint and burn
     */
    receive() external payable {
        //
    }

    /**
     * @dev Set the address allowed to mint and burn
     */
    function setOperator(address _operator) external {
        require(operator == address(0), "IMMUTABLE");
        operator = _operator;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function liquidity(address token) external view override returns (uint256) {
        return _liquidity[token] != 0 ? _liquidity[token] : _defaultLiquidity;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function defaultLiquidity() external view override returns (uint256 multiplier) {
        return _defaultLiquidity;
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setDefaultLiquidity(uint256 _liquidityMult) external override returns (uint256 oldLiquidity) {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(_liquidityMult != 0, "INVALID");
        oldLiquidity = _defaultLiquidity;
        _defaultLiquidity = _liquidityMult;
        emit LiquidityChanged(operator, oldLiquidity, _defaultLiquidity);
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function feeDivisor(address token) external view override returns (uint256 divisor) {
        divisor = feeDivisors[token];
        divisor = divisor == 0 ? FEE_DIVISOR : divisor;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function defaultFeeDivisor() external view override returns (uint256 multiplier) {
        return _defaultFeeDivisor;
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setDefaultFeeDivisor(uint256 _feeDivisor) external override returns (uint256 oldDivisor) {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(_feeDivisor != 0, "DIVISIONBYZERO");
        oldDivisor = _defaultFeeDivisor;
        _defaultFeeDivisor = _feeDivisor;
        emit DefaultFeeDivisorChanged(operator, oldDivisor, _defaultFeeDivisor);
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setFeeDivisor(address token, uint256 _feeDivisor) external override returns (uint256 oldDivisor) {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(_feeDivisor != 0, "DIVISIONBYZERO");
        oldDivisor = feeDivisors[token];
        feeDivisors[token] = _feeDivisor;
        emit FeeDivisorChanged(operator, token, oldDivisor, _feeDivisor);
    }

    /**
     * @dev get the ETH balance of this fee manager
     */
    function ethBalanceOf() external view override returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev get the token balance of this fee manager
     */
    function balanceOF(address token) external view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev transfer ETH from this contract to the to given recipient
     */
    function transferEth(address payable recipient, uint256 amount) external override {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(address(this).balance >= amount, "INSUFFICIENT_BALANCE");
        recipient.transfer(amount);
    }

    /**
     * @dev transfer tokens from this contract to the to given recipient
     */
    function transferToken(
        address token,
        address recipient,
        uint256 amount
    ) external override {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(IERC20(token).balanceOf(address(this)) >= amount, "INSUFFICIENT_BALANCE");
        IERC20(token).transfer(recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

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
pragma solidity >=0.7.0;

interface INFTGemFeeManager {

    event DefaultFeeDivisorChanged(address indexed operator, uint256 oldValue, uint256 value);
    event FeeDivisorChanged(address indexed operator, address indexed token, uint256 oldValue, uint256 value);
    event ETHReceived(address indexed manager, address sender, uint256 value);
    event LiquidityChanged(address indexed manager, uint256 oldValue, uint256 value);

    function liquidity(address token) external view returns (uint256);

    function defaultLiquidity() external view returns (uint256);

    function setDefaultLiquidity(uint256 _liquidityMult) external returns (uint256);

    function feeDivisor(address token) external view returns (uint256);

    function defaultFeeDivisor() external view returns (uint256);

    function setFeeDivisor(address token, uint256 _feeDivisor) external returns (uint256);

    function setDefaultFeeDivisor(uint256 _feeDivisor) external returns (uint256);

    function ethBalanceOf() external view returns (uint256);

    function balanceOF(address token) external view returns (uint256);

    function transferEth(address payable recipient, uint256 amount) external;

    function transferToken(
        address token,
        address recipient,
        uint256 amount
    ) external;

}

{
  "evmVersion": "istanbul",
  "libraries": {
    "src/fees/NFTGemFeeManager.sol:NFTGemFeeManager": {
      "GovernanceLib": "0x8B4207A13a5a13bDb2bBf15c137820e61e3c4AAc",
      "Strings": "0x98ccd9cb27398a6595f15cbc4b63ac525b942aad",
      "SafeMath": "0xD34a551B4a262230a373D376dDf8aADb2B0D49FD",
      "ProposalsLib": "0x54812b41409912bd065e9d3920ce196ff9bfc995",
      "Create2": "0xa511e209a01e27d134b4f564263f7db8fcbdeba6"
    }
  },
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 9999
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}