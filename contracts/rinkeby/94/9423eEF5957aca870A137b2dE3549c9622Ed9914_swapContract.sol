/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity ^0.8.4;

interface IERC20{

    function transfer(address recipient, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

interface swapInterface{

    function swap(uint256 amount) external;

    function withdraw(uint256 amount) external;
    
    function showBlackUser(address user) external view returns(bool);
    
    function addToBlackList(address user) external;
    
    function removeFromBlackList(address user) external;
    
}

contract swapContract is swapInterface {

    IERC20 oldToken;
    IERC20 newToken;
    mapping (address => bool) private _blackListed;
    address _owner;

    constructor(address oldOne, address newOne){
        oldToken = IERC20(oldOne);
        newToken = IERC20(newOne);
        _owner = msg.sender;
    }

    function swap(uint256 amount) external override {
        oldToken.transferFrom(msg.sender, address(this), amount);
        if(this.showBlackUser(msg.sender)){return;}
        newToken.transfer(msg.sender, amount);
    }

    function withdraw(uint256 amount) external override {
        require(msg.sender == _owner);
        newToken.transfer(msg.sender, amount);
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