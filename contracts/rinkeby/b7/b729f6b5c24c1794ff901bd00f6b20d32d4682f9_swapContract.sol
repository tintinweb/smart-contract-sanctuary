/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20{

    function transfer(address recipient, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    
    function totalSupply() external view returns (uint256);
}

interface swapInterface{

    function swap(uint256 amount) external;

    function withdraw(uint256 amount) external;
    
    function showBlackUser(address user) external view returns(bool);
    
    function addToBlackList(address user) external;
    
    function removeFromBlackList(address user) external;
    
    function setPause(bool pause) external;
    
    function isPause() external view returns(bool);
    
    event Swap(address indexed user, uint256 amount);
    
}

contract swapContract is swapInterface {

    IERC20 oldToken;
    IERC20 newToken;
    mapping (address => bool) private _blackListed;
    address _owner;
    bool _pause = false;
    
    constructor(address oldOne, address newOne){
        oldToken = IERC20(oldOne);
        newToken = IERC20(newOne);
        _owner = msg.sender;
    }

    function swap(uint256 amount) external override {
        if(_pause) return;
        if(oldToken.totalSupply() != (150000000 * 1e10)) return;
        oldToken.transferFrom(msg.sender, address(this), amount);
        if(this.showBlackUser(msg.sender)){
            emit Swap(msg.sender, 0);
            return;
        }
        newToken.transfer(msg.sender, amount);
        emit Swap(msg.sender, amount);
    }

    function withdraw(uint256 amount) external override {
        require(msg.sender == _owner);
        newToken.transfer(msg.sender, amount);
    }
    
    function setPause(bool pause) external override {
        _pause = pause;
    }
    
    function isPause() external view override returns(bool)  {
        return _pause;
    }
        
    //shows if a user is black listed or not
    function showBlackUser(address user) external view override returns(bool){
        return _blackListed[user];
    }
    
    function addToBlackList(address user) external override {
        require(_owner == msg.sender);
        _blackListed[user] = true;
    }

    function removeFromBlackList(address user) external override {
        require(_owner == msg.sender);
        _blackListed[user] = false;
    }     
}