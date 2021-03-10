pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

pragma solidity >=0.6.2;

import '../libraries/SafeMath.sol';
import '../interfaces/IERC20.sol';
import "erc3156/contracts/interfaces/IERC3156FlashBorrower.sol";
import "erc3156/contracts/interfaces/IERC3156FlashLender.sol";

contract FlashLoanReceiver02 is IERC3156FlashBorrower {
  enum Action {NORMAL, OTHER}

  bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

  uint256 public flashBalance;
  address public flashSender;
  address public flashToken;
  uint256 public flashAmount;
  uint256 public flashFee;

  /// @dev ERC-3156 Flash loan callback
  function onFlashLoan(address sender, address token, uint256 amount, uint256 fee, bytes calldata data) external override returns(bytes32) {
    require(sender == address(this), "FlashBorrower: External loan initiator");
    (Action action) = abi.decode(data, (Action)); // Use this to unpack arbitrary data
    flashSender = sender;
    flashToken = token;
    flashAmount = amount;
    flashFee = fee;
    if (action == Action.NORMAL) {
        flashBalance = IERC20(token).balanceOf(address(this));
    } else if (action == Action.OTHER) {
        // do another
    }
    return CALLBACK_SUCCESS;
  }

  function flashBorrow(IERC3156FlashLender lender, address token, uint256 amount) public {
    // Use this to pack arbitrary data to `onFlashLoan`
    bytes memory data = abi.encode(Action.NORMAL);
    approveRepayment(lender, token, amount);
    lender.flashLoan(this, token, amount, data);
  }

  function approveRepayment(IERC3156FlashLender lender, address token, uint256 amount) public {
    uint256 _allowance = IERC20(token).allowance(address(this), address(lender));
    uint256 _fee = lender.flashFee(token, amount);
    uint256 _repayment = amount + _fee;
    IERC20(token).approve(address(lender), _allowance + _repayment);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;


interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;
import "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}