// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Profitable.sol";

contract Controllable is Profitable {
    mapping(address => bool) private verifiedControllers;

    event ControllerSet(address account, bool isVerified);
    event DirectRedemption(uint256 punkId, address by, address indexed to);

    function isController(address account) internal view returns (bool) {
        return verifiedControllers[account];
    }

    function setController(address account, bool isVerified)
        public
        onlyOwner
        whenNotLockedM
    {
        verifiedControllers[account] = isVerified;
        emit ControllerSet(account, isVerified);
    }

    modifier onlyController() {
        require(isController(_msgSender()), "Not a controller");
        _;
    }

    function directRedeem(uint256 tokenId, address to) public onlyController {
        require(getERC20().balanceOf(to) >= 10**18, "ERC20 balance too small");
        bool toSelf = (to == address(this));
        require(
            toSelf || (getERC20().allowance(to, address(this)) >= 10**18),
            "ERC20 allowance too small"
        );
        require(getReserves().contains(tokenId), "Not in holdings");
        getERC20().burnFrom(to, 10**18);
        getReserves().remove(tokenId);
        if (!toSelf) {
            getCPM().transferPunk(to, tokenId);
        }
        emit DirectRedemption(tokenId, _msgSender(), to);
    }
}
