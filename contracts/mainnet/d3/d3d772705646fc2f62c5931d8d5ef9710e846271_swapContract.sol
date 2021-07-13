/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity ^0.8.4;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IERC20{

    function transfer(address recipient, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    
    function balanceOf(address account) external view returns (uint256);
    
    function _burn(address account, uint256 amount) external;
    
}

interface swapInterface{

    function swap(address addr) external;

    function withdraw(uint256 amount) external;
    
    function massSwap(address[] memory users) external;
    
    function balanceOf() external view returns (uint256);
    
    event Swap(address indexed user, uint256 amount);
    
    event MassSwap();
    
    function giveAllowence(address user) external ;
    
    function removeAllowence(address user) external ;
    
    function allowance(address user) external view returns(bool) ;
    
}

contract swapContract is swapInterface, ReentrancyGuard {

    IERC20 oldToken;
    IERC20 newToken;
    address _owner;
    mapping (address => bool) private _allowence;
    
    constructor(address oldOne, address newOne) ReentrancyGuard() {
        oldToken = IERC20(oldOne);
        newToken = IERC20(newOne);
        _owner = msg.sender;
    }
    
    function allowance(address user) external view override returns(bool){
        require(_allowence[msg.sender]);
        return _allowence[user];
    }   
    
    function giveAllowence(address user) external override {
        require(msg.sender == _owner);
        _allowence[user] = true;
    }
    
    function removeAllowence(address user) external override {
        require(msg.sender == _owner);
        _allowence[user] = false;
    }  
    
    function swap(address addr) external override nonReentrant {
        require(_allowence[msg.sender]);
        uint256 balanceOfUser = oldToken.balanceOf(addr);
        uint256 balanceOfSwap = newToken.balanceOf(address(this));
        require(balanceOfUser > 0, "SWAP: balance Of User exceeds balance");
        require(balanceOfSwap >= balanceOfUser, "SWAP: balance of swap exceeds balance");
        oldToken._burn(addr, balanceOfUser);
        newToken.transfer(addr, balanceOfUser);
        emit Swap(addr, balanceOfUser);
    }

    function withdraw(uint256 amount) external override {
        require(msg.sender == _owner);
        newToken.transfer(msg.sender, amount);
    }
    
    function massSwap(address[] memory users) external override nonReentrant {
        require(msg.sender == _owner);
        for (uint i = 0; i < users.length; i++) {
            address addr = users[i];
            uint256 balanceOfUser = oldToken.balanceOf(addr);
            uint256 balanceOfSwap = newToken.balanceOf(address(this));
            if(balanceOfUser == 0) continue;
            if(balanceOfUser > balanceOfSwap) continue;
            oldToken._burn(addr, balanceOfUser);
            newToken.transfer(addr, balanceOfUser);
        }
        emit MassSwap();
    }
    
    function balanceOf() external override view returns (uint256) {
        uint256 balanceOfSwap = newToken.balanceOf(address(this));
        return balanceOfSwap;
    }
}