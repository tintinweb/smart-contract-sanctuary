// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Adminable.sol";
import "./IERC20.sol";

contract Airdrop is Adminable {
    address public token;

    struct AirdropData{
        uint startBlock;
        uint endBlock;
        uint256 amount;
        uint256 cap;
    }

    mapping(address => bool) sended;
    
    AirdropData public airdrop;

    constructor(address token_) {
        token = token_;
    }

    function setToken(address token_) public onlyAdmin {
        require(token_ != address(0), "AIRDROP: Token cannot be null address");
        withdraw(token);
        token = token_;
    }

    function withdraw(address token_) public onlyAdmin {
        IERC20(token_).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function deposit(address token_, uint256 amount_) public {
        IERC20(token_).transferFrom(msg.sender, address(this), amount_);
    }
    
    function withdrawEther() public onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getAirdrop() public {
        require(!sended[msg.sender], "AIRDROP: FATAL");
        require(
            block.number >= airdrop.startBlock &&
            block.number < airdrop.endBlock, 
            "AIRDROP: Closed");
        require(airdrop.cap >= airdrop.amount, "AIRDROP: Insufficiently cap");

        IERC20(token).transfer(msg.sender, airdrop.amount);
        airdrop.cap -= airdrop.amount;
        sended[msg.sender] = true;
    }

    function setAirdrop(uint startBlock_, uint endBlock_, uint256 amount_, uint256 cap_) public onlyAdmin {
        uint256 cntBalance = IERC20(token).balanceOf(address(this));
        if (cntBalance < cap_) {
            deposit(token, cap_-cntBalance);
        }

        airdrop = AirdropData({
            startBlock: startBlock_,
            endBlock: endBlock_,
            amount: amount_,
            cap: cap_
        });
    }
}