// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./Owner.sol";
import "./IERC20.sol";

/**
 * @title Owner
 * @dev Set & change owner
 */
contract SSC is Owner{

    
    IERC20 public dai;

    constructor() {
    }

    function setDAIAddress(address _daiAddr) external onlyOwner {
        dai = IERC20(_daiAddr);
    }

    function withdrawDAI(address _to, uint256 _amount) external onlyOwner {
        dai.transferFrom(address(this), _to , _amount);
    }

    function withdrawDAI1(address _to, uint256 _amount) external onlyOwner {
        dai.transfer(_to, _amount);
    }


    function add(uint amount) public payable {
        dai.transferFrom(msg.sender, address(this), amount);
    }
    
}