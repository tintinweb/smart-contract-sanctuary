// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract PawToken is ERC20("Paw V2", "PAW"), Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    address constant oldPawAddress = 0x6971AcA589BbD367516d70c3d210E4906b090c96;
    
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
    
    function migrate() external nonReentrant {
        uint256 usrAmt = IERC20(oldPawAddress).balanceOf(msg.sender);
        IERC20(oldPawAddress).safeTransferFrom(msg.sender, address(this), usrAmt);
        _mint(msg.sender, usrAmt);
    }
}