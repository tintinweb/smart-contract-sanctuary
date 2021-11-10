/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
contract PecSender {
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function multisendToken(IERC20 _token, address[] memory _to, uint256[] memory _values) external onlyOwner {
        require(_to.length == _values.length);
        for (uint256 i = 0; i < _to.length; i++) {
            require(_token.transfer(_to[i], _values[i]));
        }
    }
    
    function multisendTokenSingleValue(IERC20 _token, uint256 _value, address[] memory _to) external onlyOwner {
        require(_value > 0);
        for (uint256 i = 0; i < _to.length; i++) {
            require(_token.transfer(_to[i], _value));
        }
    }
    
    function withdraw(IERC20 _token) external onlyOwner {
        require(_token.transfer(msg.sender, _token.balanceOf(address(this))));
    }
}