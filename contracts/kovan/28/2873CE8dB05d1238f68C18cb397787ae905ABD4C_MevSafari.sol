// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <=0.8.0;

import "./IERC20.sol";
import "./IERC3156FlashBorrower.sol";
import "./IERC3156FlashLender.sol";

contract MevSafari is IERC3156FlashBorrower {
    enum Action {NORMAL, MEV}

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    uint256 public flashBalance;
    address public flashSender;
    address public flashToken;
    uint256 public flashAmount;
    uint256 public flashFee;

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
      address sender,
      address token,
      uint256 amount,
      uint256 fee,
      bytes calldata data
    ) external override returns(bytes32) {
        require(sender == address(this), "FlashBorrower: External loan initiator");
        // @TODO add additional flash mint related security checks here
        (Action action) = abi.decode(data, (Action)); // Use this to unpack arbitrary data
        flashSender = sender;
        flashToken = token;
        flashAmount = amount;
        flashFee = fee;
        if (action == Action.NORMAL) {
            flashBalance = IERC20(token).balanceOf(address(this));
        } else if (action == Action.MEV) {
            flashBalance = IERC20(token).balanceOf(address(this));

            // @TODO placeholder for integration to Flashbots

            // @TODO placeholder for integration to ArcherDAO

            // @TODO placeholder for integration to bloXroute

            // @TODO placeholder for integration to Tai Chi

        }
        return CALLBACK_SUCCESS;
    }

    function flashBorrow(
      IERC3156FlashLender lender,
      address token,
      uint256 amount
    ) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.NORMAL);
        approveRepayment(lender, token, amount);
        lender.flashLoan(this, token, amount, data);
    }

    function approveRepayment(
      IERC3156FlashLender lender,
      address token, uint256 amount
    ) public {
        uint256 _allowance = IERC20(token).allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        IERC20(token).approve(address(lender), _allowance + _repayment);
    }

    function getFlashBalance() public returns(uint256) {
        return flashBalance;
    }

}