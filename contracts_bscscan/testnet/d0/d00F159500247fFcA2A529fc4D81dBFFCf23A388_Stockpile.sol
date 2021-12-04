// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity 0.7.4;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Stockpile is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public admin;
    address payable public operator;

    IERC20 token;

    event onPushPayment(address indexed _recipient, uint256 _amount1, uint256 _timestamp);

    constructor(address _token, address payable _operator) {
        token = IERC20(_token);
        operator = _operator;
    }

    receive() external payable {

    }

    // Funds for the VGP
    function tokenBalance() public view returns (uint256 _balance) {
        return token.balanceOf(address(this));
    }

    // Let's get this party started, RIIIIIIGHT?
    function withdraw(address payable _recipient) external onlyOwner() returns (bool _success) {
        
        // Get the payout values to transfer
        uint256 _payout = tokenBalance();
        // Send the tokens to the Party Lord
        token.transfer(_recipient, _payout);

        // Transfer any base to the Party Lord
        operator.transfer(address(this).balance);

        // Tell the network, successful event
        emit onPushPayment(_recipient, _payout, block.timestamp);
        return true;
    }
}