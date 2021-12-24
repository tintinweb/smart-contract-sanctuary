//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20Standart.sol";
import "SafeMath.sol";
import "Roles.sol";


contract RPGC is ERC20, Ownable, AdminRole, TokenProviderRole{
    using SafeMath for uint;

    mapping (address => bool) public isBlacklisted;

    constructor(uint initialIssue) ERC20("RPGC", "RPGC") {
        _mint(msg.sender, initialIssue);
        addAdmin(msg.sender);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(!isBlacklisted[sender], "[Blacklist]: the sender is blacklisted");
        super._transfer(sender, recipient, amount);
    }

    function transferToProxy(address exchanger, uint amount) public onlyTokenProvider {
        this.transferFrom(exchanger, msg.sender, amount);
    }

    function transferToExchange(address exchanger, uint amount) public onlyOwner {
        transfer(exchanger, amount);
        _approve(exchanger, address(this), amount);
    }

    function addAdmin(address account) public onlyOwner {
        require(!isAdmin(account), "[Admin Role]: account already has admin role");
        _addAdmin(account);
    }

    function removeAdmin(address account) public onlyOwner {
        require(isAdmin(account), "[Admin Role]: account has not admin role");
        _removeAdmin(account);
    }

    function addTokenProvider(address account) public onlyAdmin {
        require(!isTokenProvider(account), "[Token Provider Role]: account already has token provider role");
        _addTokenProvider(account);
    }

    function removeTokenProvider(address account) public onlyAdmin {
        require(isTokenProvider(account), "[Token Provider Role]: account has not token provider role");
        _removeTokenProvider(account);
    }
    
    function mint(uint amount) public onlyOwner {
        _mint(msg.sender, amount);
    } 

    function burn(uint amount) public onlyOwner {
        _burn(msg.sender, amount);
    }

    function ban(address account) public onlyAdmin {
        require(!isBlacklisted[account], "[Blacklist]: the account is already blacklisted");
        isBlacklisted[account] = true;
    }

    function unban(address account) public onlyAdmin {
        require(isBlacklisted[account], "[Blacklist]: the account has to be blacklisted");
        isBlacklisted[account] = false;
    }
}