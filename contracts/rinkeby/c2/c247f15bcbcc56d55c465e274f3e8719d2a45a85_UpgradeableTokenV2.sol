// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC20Upgradeable.sol';
import './OwnableUpgradeable.sol';

contract UpgradeableTokenV2 is ERC20Upgradeable, OwnableUpgradeable {
 
    bool public paused;

    event Upgraded(string upgradeMsg);

    mapping (address=>bool) public blacklisted;
    
    function initialize() initializer public {
        __ERC20_init("UpgradeableToken", "UTK");
        __Ownable_init();
        _mint(msg.sender, 10**11);
    }

    function blacklist(address _user) external onlyOwner {
        require(!blacklisted[_user], "User already blacklisted");
        blacklisted[_user] = true;
    }
    
    function whitelist(address _user) external onlyOwner {
        require(blacklisted[_user], "User already whitelisted");
        blacklisted[_user] = false;
    }

    function pause() external onlyOwner {
        require(!paused, "Already paused");
        paused = true;
    }

    function unpause() external onlyOwner {
        require(paused, "Not paused");
        paused = false;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!paused, 'Token paused');
        require(!blacklisted[msg.sender], 'You cannot send or receive tokens.');
        require(!blacklisted[recipient], 'The recipient cannot send or receive tokens.');
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function testDeprecated() external {
        emit Upgraded('This function does not exist');
    }
    
    function testUpgraded() external {
        // do something
        emit Upgraded('This is a new function');
    }
}