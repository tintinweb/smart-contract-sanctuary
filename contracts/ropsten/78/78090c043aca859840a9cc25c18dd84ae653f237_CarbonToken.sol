// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Pausable.sol";


contract CarbonToken is ERC20, Ownable, ERC20Burnable, Pausable {
    using SafeMath for uint256;

    mapping (address => uint256) private _retirees;
    mapping(address => bool) private whitelist;
    uint256 private _totalRetired;
    string private constant _name = "CarbonToken";
    string private constant _symbol = "CBT";

    event Retire(address indexed account, uint256 value);
    event Whitelisted(address indexed wallet);
    event Dewhitelisted(address indexed wallet);

    constructor() ERC20(_name, _symbol) {
    }
    
    // Distribution Functions
    // Whitelist Functions

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    // Receive and collect fund
    
    receive() external payable {}
    function collect(address tokenAddress) public onlyOwner {
        if (tokenAddress == address(0)) {
            address(uint160(owner())).transfer(address(this).balance);
        }
        else {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(owner(), token.balanceOf(address(this)));
        }
    }

    function addToWhitelistBatch(address[] calldata wallets) public onlyOwner {
         for (uint256 i = 0; i < wallets.length; i++) {
            addToWhitelist(wallets[i]);
        }
    }

    function addToWhitelist(address wallet) public onlyOwner {
        require(wallet != address(0), "Invalid wallet");
        whitelist[wallet] = true;
        emit Whitelisted(wallet);
    }

    function removeFromWhitelist(address wallet) public onlyOwner {
        require(wallet != address(0), "Invalid wallet");
        whitelist[wallet] = false;
        emit Dewhitelisted(wallet);
    }

    function removeFromWhitelistBatch(address[] calldata wallets) public onlyOwner {
         for (uint256 i = 0; i < wallets.length; i++) {
            removeFromWhitelist(wallets[i]);
        }
    }

    function checkWhitelisted(address wallet) public view returns (bool){
        return whitelist[wallet];
    }

    // ERC20Pausable Functions

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function _pause() override public onlyOwner {
        super._pause();
    }

    function _unpause() override public onlyOwner {
        super._unpause();
    }

    // Core Functions

    function retire(uint256 amount) public {
        require(checkWhitelisted(_msgSender()), "Transaction sender is not whitelisted.");
        require(amount <= balanceOf(_msgSender()), "Insufficient CarbonToken to perform this action");
        super.burn(amount);
        _totalRetired = _totalRetired.add(amount);
        _retirees[_msgSender()] = _retirees[_msgSender()].add(amount);
        emit Retire(_msgSender(), amount);
    }

    function retired(address account) public view returns (uint256) {
        return _retirees[account];
    }

    function totalRetired() public view returns (uint256) {
        return _totalRetired;
    }

    // ERC20Burnable Functions

    function burn(uint256 value) override public onlyOwner {
        super.burn(value);
    }

    function burnFrom(address from, uint256 value) override public onlyOwner {
        super.burnFrom(from, value);
    }

    // ERC20 Functions

    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        require(checkWhitelisted(to), "Receiver is not whitelisted.");
        super._mint(to, value);
        return true;
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(checkWhitelisted(_msgSender()), "Sender is not whitelisted.");
        require(checkWhitelisted(to), "Receiver is not whitelisted.");
        return super.transfer(to, value);
    }

    function transferFrom(address from,address to, uint256 value) public override returns (bool) {
        require(checkWhitelisted(_msgSender()), "Transaction sender is not whitelisted.");
        require(checkWhitelisted(from), "Token sender is not whitelisted.");
        require(checkWhitelisted(to), "Receiver is not whitelisted.");
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(checkWhitelisted(_msgSender()), "Sender is not whitelisted.");
        require(checkWhitelisted(spender), "Spender is not whitelisted.");
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public override returns (bool success) {
        require(checkWhitelisted(_msgSender()), "Sender is not whitelisted.");
        require(checkWhitelisted(spender), "Spender is not whitelisted.");
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public override returns (bool success) {
        require(checkWhitelisted(_msgSender()), "Sender is not whitelisted.");
        require(checkWhitelisted(spender), "Spender is not whitelisted.");
        return super.decreaseAllowance(spender, subtractedValue);
    }

}