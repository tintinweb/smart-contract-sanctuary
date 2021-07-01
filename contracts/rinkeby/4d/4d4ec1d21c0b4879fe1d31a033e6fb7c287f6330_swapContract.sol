/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
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
    
    event Swap(address indexed user, uint256 amount);
    
    event MassSwap();
    
}

contract swapContract is swapInterface, ReentrancyGuard {

    IERC20 oldToken;
    IERC20 newToken;
    address _owner;
    
    constructor(address oldOne, address newOne) ReentrancyGuard() {
        oldToken = IERC20(oldOne);
        newToken = IERC20(newOne);
        _owner = msg.sender;
    }

    function swap(address addr) external override nonReentrant {
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
    
}