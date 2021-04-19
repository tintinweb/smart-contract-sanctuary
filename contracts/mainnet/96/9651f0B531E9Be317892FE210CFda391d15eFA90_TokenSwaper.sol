/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokenSwaper {
    using SafeMath for uint256;

    address public newTokenAddr = 0x46d0DAc0926fa16707042CAdC23F1EB4141fe86B;
    address public oldTokenAddr = 0x983F6d60db79ea8cA4eB9968C6aFf8cfA04B3c63;
    address public newApprover;
    address public oldApprover;
    address public owner;
    
    uint256 public toNewDeadline;
    uint256 public toOldDeadline;
    uint256 public toNewRate;

    constructor(
        address _newApprover,
        address _oldApprover,
        uint256 _toNewDeadline,
        uint256 _toOldDeadline,
        uint256 _toNewRate
    ) 
        public 
    {
        newApprover = _newApprover;
        oldApprover = _oldApprover;
        toNewDeadline = _toNewDeadline;
        toOldDeadline = _toOldDeadline;
        toNewRate = _toNewRate;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function SwapToNew(uint256 _amount) external {
        require(block.number <= toNewDeadline, "toNew: ended");
        IERC20(oldTokenAddr).transferFrom(msg.sender, address(this), _amount);
        uint256 newAmount = _amount.div(toNewRate);
        uint256 newBal = IERC20(newTokenAddr).balanceOf(address(this));
        if(newBal >= newAmount){
            IERC20(newTokenAddr).transfer(msg.sender, newAmount);
        }else{
            IERC20(newTokenAddr).transferFrom(newApprover, msg.sender, newAmount);
        }
    }

    function SwapToOld(uint256 _amount) external {
        require(block.number <= toOldDeadline, "toOld: ended");
        IERC20(newTokenAddr).transferFrom(msg.sender, address(this), _amount);
        uint256 oldAmount = _amount.mul(toNewRate);
        uint256 oldBal = IERC20(oldTokenAddr).balanceOf(address(this));
        if(oldBal >= oldAmount){
            IERC20(oldTokenAddr).transfer(msg.sender, oldAmount);
        }else{
            IERC20(oldTokenAddr).transferFrom(oldApprover, msg.sender, oldAmount);
        }
    }

    function withdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function setToOldDeadline(uint256 _toOldDeadline) external onlyOwner {
        toOldDeadline = _toOldDeadline;
    }

    function setToNewDeadline(uint256 _toNewDeadline) external onlyOwner {
        toNewDeadline = _toNewDeadline;
    }

    function setOldApprover(address _oldApprover) external onlyOwner {
        oldApprover = _oldApprover;
    }

    function setNewApprover(address _newApprover) external onlyOwner {
        newApprover = _newApprover;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}