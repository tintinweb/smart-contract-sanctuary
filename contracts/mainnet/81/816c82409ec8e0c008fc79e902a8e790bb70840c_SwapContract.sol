// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./TransferHelper.sol";
import "./SafeMath.sol";

contract SwapContract {
    using SafeMath for uint256;
    
    address public unc;
    address public uncx;

    constructor (address _unc, address _uncx) public {
        unc = _unc;
        uncx = _uncx;
    }

    function swapAmount (uint256 _amount) public pure returns (uint256) {
      uint256 credit = _amount.div(4000);
      return credit;
    }

    function doSwap (uint256 _amount) public {
      TransferHelper.safeTransferFrom(unc, address(msg.sender), address(this), _amount);
      uint256 credit = _amount.div(4000);
      require(credit > 0, 'Amount 0');
      TransferHelper.safeTransfer(uncx, address(msg.sender), credit);
    }
}