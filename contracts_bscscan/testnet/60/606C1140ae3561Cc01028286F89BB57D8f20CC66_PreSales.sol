// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./RADS.sol";

contract PreSales is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public RADS;
    uint256 public RADSperBUSD;

    constructor(
        address _RADS,
        uint256 _RADSperBUSD
    ) public {
        RADS = _RADS;
        RADSperBUSD = _RADSperBUSD;
    }

    /*
     * Function to view RADS left in the contract
     */
    function balanceRADS() public view returns (uint256) {
        uint256 balance = IERC20(RADS).balanceOf(address(this));
        return balance;
    }

    /*
     * Function to accept BUSD and give RADS
     */
    function acceptBusd(uint256 _amount) public {

        address _token = address(0x339a13a05bbB2D85AE77aDF398803fCD6E309B2b);

        require(
            IERC20(_token).balanceOf(msg.sender) >= _amount,
            "!! Balance not enough !!"
        );
        require(
            IERC20(_token).allowance(msg.sender, address(this)) >= _amount,
            "!! Increase my _allowance_ OR _approve_ my spending limit !!"
        );

        uint256 rads = _amount.mul(RADSperBUSD);
        require(
            IERC20(RADS).balanceOf(address(this)) >= rads,
            "!! Not enough presale tokens left !!"
        );

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        IERC20(RADS).transfer(msg.sender, rads);
    }

    function collectBUSD() external onlyOwner {
        address token = address(0x339a13a05bbB2D85AE77aDF398803fCD6E309B2b);
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

}