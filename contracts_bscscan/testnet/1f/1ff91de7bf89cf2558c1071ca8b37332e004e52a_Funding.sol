// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Address.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Funding is Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 public fee = 0.0016 ether;
    address payable public adminWallet =
        payable(0x62F46e2b272F0775C0872CF939800793FFe23654);

    uint256 public id = 0;

    event FundingTxSent(uint256 id, address player);

    function setAdminWallet(address payable adminWallet_) external onlyOwner {
        require(
            adminWallet_ != address(0),
            "Admin wallet cannot be null address."
        );
        adminWallet = adminWallet_;
    }

    function setFee(uint256 fee_) external onlyOwner {
        fee = fee_;
    }

    function _forwardFee() internal {
        adminWallet.transfer(fee);
    }

    function payTxFee() external payable {
        require(fee == msg.value, "Amount of BNB sent is not correct.");

        _forwardFee();

        emit FundingTxSent(id++, msg.sender);
    }
}