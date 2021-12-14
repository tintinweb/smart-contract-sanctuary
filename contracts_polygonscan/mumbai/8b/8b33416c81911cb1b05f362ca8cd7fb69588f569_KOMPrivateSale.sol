// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./IERC20.sol";
import "./Safemath.sol";

contract KOMPrivateSale {

    using SafeMath for uint256;
    IERC20 public dai;
    uint256 public daiprice = 1000000000000000000;
    mapping(uint=>address[]) public userBetArr;


    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    

    function bet(uint16 amount,uint number) callerIsUser
        external
    {
        userBetArr[number].push(msg.sender);
        
        uint256 totalMintDAIPrice = daiprice.mul(amount);
        dai.transferFrom(msg.sender, address(this), totalMintDAIPrice);
    }


    function setDAIAddress(address _daiAddr) external {
        dai = IERC20(_daiAddr);
    }


}