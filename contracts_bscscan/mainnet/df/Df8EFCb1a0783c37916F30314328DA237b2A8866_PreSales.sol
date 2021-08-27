// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

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
     * Function to calculate amount of RADS to be received
     */
    function calculateRADS(uint256 input) public view returns (uint256) {  
        uint256 amount = input.mul(RADSperBUSD).div(1e18);
        return amount;
    }

    /*
     * Function to accept BUSD and give RADS
     */
    function acceptBusd(uint256 _amount) public {

        address _token = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

        require(
            IERC20(_token).balanceOf(msg.sender) >= _amount,
            "!! Balance not enough !!"
        );
        require(
            IERC20(_token).allowance(msg.sender, address(this)) >= _amount,
            "!! Increase my _allowance_ OR _approve_ my spending limit !!"
        );

        uint256 rads = calculateRADS(_amount);
        require(
            IERC20(RADS).balanceOf(address(this)) >= rads,
            "!! Not enough presale tokens left !!"
        );

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        IERC20(RADS).transfer(msg.sender, rads);
    }

    function retrieveBUSD() external onlyOwner {
        address token = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function retrieveRADS() external onlyOwner {
        IERC20(RADS).transfer(msg.sender, IERC20(RADS).balanceOf(address(this)));
    }

}