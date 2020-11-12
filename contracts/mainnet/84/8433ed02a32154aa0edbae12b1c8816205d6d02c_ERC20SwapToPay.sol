pragma solidity ^0.5.12;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC20FeeProxy.sol";

interface IUniswapV2Router02 {
  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
}

/**
 * @title ERC20SwapToPay
 * @notice This contract swaps ERC20 tokens before paying a request thanks to a payment proxy
  */
contract ERC20SwapToPay is Ownable {
  using SafeERC20 for IERC20;

  IUniswapV2Router02 public swapRouter;
  IERC20FeeProxy public paymentProxy;

  constructor(address _swapRouterAddress, address _paymentProxyAddress) public {
    swapRouter = IUniswapV2Router02(_swapRouterAddress);
    paymentProxy = IERC20FeeProxy(_paymentProxyAddress);
  }

 /**
  * @notice Authorizes the proxy to spend a new request currency (ERC20).
  * @param _erc20Address Address of an ERC20 used as a request currency
  */
  function approvePaymentProxyToSpend(address _erc20Address) public {
    IERC20 erc20 = IERC20(_erc20Address);
    uint256 max = 2**256 - 1;
    erc20.safeApprove(address(paymentProxy), max);
  }

 /**
  * @notice Authorizes the swap router to spend a new payment currency (ERC20).
  * @param _erc20Address Address of an ERC20 used for payment
  */
  function approveRouterToSpend(address _erc20Address) public {
    IERC20 erc20 = IERC20(_erc20Address);
    uint256 max = 2**256 - 1;
    erc20.safeApprove(address(swapRouter), max);
  }

  /**
  * @notice Performs a token swap between a payment currency and a request currency, and then
  *         calls a payment proxy to pay the request, including fees.
  * @param _to Transfer recipient = request issuer
  * @param _amount Amount to transfer in request currency
  * @param _amountInMax Maximum amount allowed to spend for currency swap, in payment currency.
            This amount should take into account the fees.
    @param _path, path of ERC20 tokens to swap from requestedToken to spentToken. The first 
            address of the path should be the payment currency. The last element should be the
            request currency.
  * @param _paymentReference Reference of the payment related
  * @param _feeAmount Amount of the fee in request currency
  * @param _feeAddress Where to pay the fee
  * @param _deadline Deadline for the swap to be valid
  */
  function swapTransferWithReference(
    address _to,
    uint256 _amount,      // requestedToken
    uint256 _amountInMax, // spentToken
    address[] calldata _path, // from requestedToken to spentToken
    bytes calldata _paymentReference,
    uint256 _feeAmount,   // requestedToken
    address _feeAddress,
    uint256 _deadline
  )
    external
  {
    IERC20 spentToken = IERC20(_path[0]);
    IERC20 requestedToken = IERC20(_path[_path.length-1]);
    
    uint256 requestedTotalAmount = _amount + _feeAmount;

    require(spentToken.allowance(msg.sender, address(this)) > _amountInMax, "Not sufficient allowance for swap to pay.");
    require(spentToken.safeTransferFrom(msg.sender, address(this), _amountInMax), "Could not transfer payment token from swapper-payer");

    // Allow the router to spend all this contract's spentToken
    if (spentToken.allowance(address(this),address(swapRouter)) < _amountInMax) {
      approveRouterToSpend(address(spentToken));
    }

    swapRouter.swapTokensForExactTokens(
      requestedTotalAmount,
      _amountInMax,
      _path,
      address(this),
      _deadline
    );

    // Allow the payment network to spend all this contract's requestedToken
    if (requestedToken.allowance(address(this),address(paymentProxy)) < requestedTotalAmount) {
      approvePaymentProxyToSpend(address(requestedToken));
    }

    // Pay the request and fees
    paymentProxy.transferFromWithReferenceAndFee(
      address(requestedToken),
      _to,
      _amount,
      _paymentReference,
      _feeAmount,
      _feeAddress
    );

    // Give the change back to the payer, in both currencies (only spent token should remain)

    if (spentToken.balanceOf(address(this)) > 0) {
      spentToken.safeTransfer(msg.sender, spentToken.balanceOf(address(this)));
    }    
    if (requestedToken.balanceOf(address(this)) > 0) {
      requestedToken.safeTransfer(msg.sender, requestedToken.balanceOf(address(this)));
    }
  }

  /*
  * Admin functions to edit the admin, router address or proxy address
  */
  
  function setPaymentProxy(address _paymentProxyAddress) public onlyOwner {
    paymentProxy = IERC20FeeProxy(_paymentProxyAddress);
  }
  
  function setRouter(address _newSwapRouterAddress) public onlyOwner {
    swapRouter = IUniswapV2Router02(_newSwapRouterAddress);
  }
}