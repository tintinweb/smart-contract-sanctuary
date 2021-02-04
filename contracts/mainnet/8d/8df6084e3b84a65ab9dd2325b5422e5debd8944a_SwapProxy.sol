// SPDX-License-Identifier: GNU-3.0
pragma solidity =0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

/** 
@title Coinbase Wallet Swap Proxy
This contract is meant to be stateless and not meant to custody funds.
Any funds sent directly to this contract may not be recoverable.
*/
contract SwapProxy is ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // ETH Indicator
  address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // WETH address
  address private immutable _WETH;

  // Fee collection beneficiary
  address payable private _beneficiary;

  // Uniswap V2 router
  IUniswapV2Router02 private immutable _uniswapV2Router;

  // Event fired after a successful swap
  event TokensTraded(
    address indexed sender,
    address indexed from,
    address indexed to,
    uint256 fromAmount,
    uint256 toAmount,
    uint256 fee
  );

  // Event fired after updating beneficiary address
  event BeneficiaryUpdate(address indexed beneficiary);

  constructor(address uniswapV2Router, address payable beneficiary, address WETH) public {
    _uniswapV2Router = IUniswapV2Router02(uniswapV2Router);
    _beneficiary = beneficiary;
    _WETH = WETH;
  }

  /// @dev Execute swap operation from ETH to ERC20
  /// @param path The series of ERC20 addresses to swap where 0 MUST be WETH and -1 is the resulting token give to the sender
  /// @param minAmount Minimum amount of ERC20 tokens to receive in base units
  /// @param fee Fee collected and sent to the beneficiary, deducted from msg.value
  function swapETHForTokens(
    address[] calldata path,
    uint256 minAmount, 
    uint256 fee
  ) external payable nonReentrant() {
    require(msg.value > fee, "fee cannot exceed msg.value");
    require(msg.sender != _beneficiary, "msg.sender can't be beneficiary");

    address contractAddress = address(this);
    uint256 beneficiaryBalance = _beneficiary.balance;

    // Send Coinbase fee
    _sendETH(_beneficiary, fee);

    require(
      _beneficiary.balance >= beneficiaryBalance.add(fee), 
      "beneficiary didn't receive fees"
    );

    // Execute the swap through Uniswap
    uint256 fromAmount = msg.value.sub(fee);
    uint256[] memory amounts = _uniswapV2Router.swapExactETHForTokens{ value: fromAmount }(
      minAmount,
      path,
      contractAddress,
      block.timestamp
    );

    uint256 toAmount = amounts[amounts.length - 1];

    // Send swapped ERC20s back to user
    IERC20 toERC20 = IERC20(path[path.length - 1]);
    _sendERC20(toERC20, msg.sender, toAmount);

    emit TokensTraded(msg.sender, ETH_ADDRESS, address(toERC20), fromAmount, toAmount, fee);
  }

  /// @dev Execute swap operation from ERC20 to ETH
  /// @param path The series of ERC20 addresses to swap where 0 is the token being provided and -1 MUST be WETH
  /// @param fromAmount Amount of ERC20 tokens to sell in base units
  /// @param minAmount Minimum amount of ETH to receive in base units
  /// @param fee Fee collected and sent to the beneficiary, deducted from fromAmount
  function swapTokensForETH(
    address[] calldata path,
    uint256 fromAmount,
    uint256 minAmount,
    uint256 fee
  ) external payable nonReentrant() {
    require(fromAmount > fee, "fee cannot exceed fromAmount");
    require(msg.sender != _beneficiary, "msg.sender can't be beneficiary");

    address contractAddress = address(this);
    IERC20 fromERC20 = IERC20(path[0]);
    uint256 beneficiaryBalance = fromERC20.balanceOf(_beneficiary);
    uint256 fromAmountMinusFee = fromAmount.sub(fee);

    // Pull the funds into the smart contract
    fromERC20.safeTransferFrom(msg.sender, contractAddress, fromAmountMinusFee);
    
    // Send Coinbase fee
    if (fee > 0) {
      fromERC20.safeTransferFrom(msg.sender, _beneficiary, fee);
    }

    require(
      fromERC20.balanceOf(_beneficiary) >= beneficiaryBalance.add(fee), 
      "beneficiary didn't receive fees"
    );

    // Execute the swap through Uniswap
    uint256[] memory amounts = _uniswapV2Router.swapExactTokensForETH(
      fromAmountMinusFee,
      minAmount,
      path,
      contractAddress,
      block.timestamp
    );

    uint256 toAmount = amounts[amounts.length - 1];

    // Send swapped ETH back to user
    _sendETH(msg.sender, toAmount);

    emit TokensTraded(
      msg.sender, 
      address(fromERC20), 
      ETH_ADDRESS, 
      fromAmountMinusFee, 
      toAmount, 
      fee
    );
  }

  /// @dev Execute swap operation from ERC20 to ERC20
  /// @param path The series of ERC20 addresses to swap where 0 is the token being provided and -1 is the token being received
  /// @param fromAmount Amount of ERC20 tokens to sell in base units
  /// @param minAmount Minimum amount of ERC20 tokens to receive in base units
  /// @param fee Fee collected and sent to the beneficiary, deducted from fromAmount
  function swapTokensForTokens(
    address[] calldata path,
    uint256 fromAmount,
    uint256 minAmount,
    uint256 fee
  ) external payable nonReentrant() {
    require(fromAmount > fee, "fee cannot exceed fromAmount");
    require(msg.sender != _beneficiary, "msg.sender can't be beneficiary");

    address contractAddress = address(this);
    IERC20 fromERC20 = IERC20(path[0]);
    uint256 beneficiaryBalance = fromERC20.balanceOf(_beneficiary);
    uint256 fromAmountMinusFee = fromAmount.sub(fee);
    
    // Pull the funds into the smart contract 
    fromERC20.safeTransferFrom(msg.sender, contractAddress, fromAmountMinusFee);

    // Send Coinbase fee    
    if (fee > 0) {
      fromERC20.safeTransferFrom(msg.sender, _beneficiary, fee);
    }

    require(
      fromERC20.balanceOf(_beneficiary) >= beneficiaryBalance.add(fee), 
      "beneficiary didn't receive fees"
    );

    // Execute the swap through Uniswap
    _uniswapV2Router.swapExactTokensForTokens(
      fromAmountMinusFee,
      minAmount,
      path,
      contractAddress,
      block.timestamp
    );

    IERC20 toERC20 = IERC20(path[path.length - 1]);
    uint256 toAmount = toERC20.balanceOf(contractAddress);

    // Send swapped ERC20s back to user
    _sendERC20(toERC20, msg.sender, toAmount);

    emit TokensTraded(
      msg.sender, 
      address(fromERC20), 
      address(toERC20), 
      fromAmountMinusFee, 
      toAmount, 
      fee
    );
  }

  /// @dev Grant ERC20 approval to the Uniswap V2 Router
  /// @param tokens List of tokens to approve
  function approve(IERC20[] calldata tokens) external onlyOwner {
    for (uint i = 0; i < tokens.length; i++) {
      IERC20 token = tokens[i];

      if (address(token) != ETH_ADDRESS) {
          // Approve for the max uint256 amount
          token.safeApprove(address(_uniswapV2Router), 2**256 - 1);
      }
    }
  }

  function getUniswapV2Router() public view returns(IUniswapV2Router02) {
    return _uniswapV2Router;
  }

  function getBeneficiary() public view returns(address) {
    return _beneficiary;
  }

  /// @dev Updates fee collection beneficiary
  /// @param beneficiary Address collecting all the fees
  function setBeneficiary(address payable beneficiary) external onlyOwner {
    require(beneficiary != address(0));
    _beneficiary = beneficiary;
    emit BeneficiaryUpdate(beneficiary);
  }

  // Needed to receive ETH
  receive() external payable {}

  function _sendETH(address payable toAddress, uint256 amount) private {
    if (amount > 0) {
      (bool success,) = toAddress.call{ value: amount }("");
      require(success, "Unable to send ETH");
    }
  }

  function _sendERC20(IERC20 token, address payable toAddress, uint256 amount) private {
    if (amount > 0) {
      token.safeTransfer(toAddress, amount);
    }
  }
}