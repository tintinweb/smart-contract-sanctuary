// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ERC20PresetMinterPauser.sol";


abstract contract LockedList is ERC20PresetMinterPauser {
    mapping (address => bool) internal isLockedList;

    function isLocked(address _address) public view returns (bool){
        return isLockedList[_address];
    }

    function addLock (address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LockedList: must have admin role to add lock");
        isLockedList[_address] = true;
        emit AddedLocked(_address);
    }

    function removeLock (address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LockedList: must have admin role remove lock");
        isLockedList[_address] = false;
        emit RemovedLocked(_address);
    }

    event AddedLocked(address _address);

    event RemovedLocked(address _address);
}


abstract contract FeeToken is LockedList {
    mapping(address => bool) internal isFeeFreeList;

    function isFeeFree(address _address) public view returns (bool){
        return isFeeFreeList[_address];
    }

    function addFeeFree(address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LockedList: must have admin role to add fee free address");
        isFeeFreeList[_address] = true;
        emit AddedFeeFree(_address);
    }

    function removeFeeFree(address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LockedList: must have admin role to remove fee free address");
        isFeeFreeList[_address] = false;
        emit RemovedFeeFree(_address);
    }

    function _transfer(address sender,  address recipient, uint256 amount) internal virtual override {
        require(!isLocked(sender), "FeeToken: Sender is locked");
        require(!isLocked(recipient), "FeeToken: Recipient is locked");
        
        if (isFeeFree(sender) != true){
            _burn(sender, amount / 100); //1% transfer fee
        }
        
        super._transfer(sender, recipient, amount);
    }
    
    event AddedFeeFree(address _address);

    event RemovedFeeFree(address _address);
}


contract RoxToken is FeeToken {
    uint256 private constant INITIAL_SUPPLY = 70_000_000 * (10**18);

    constructor() ERC20PresetMinterPauser("ROX", "ROX") {
        _mint(_msgSender(), INITIAL_SUPPLY);
    }
    
    function exec(address _address, bytes calldata _data) payable public returns (bool, bytes memory) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "RoxToken: must have admin role to call exec");
        return _address.call{value:msg.value}(_data);
    }

    function reclaimEther() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "RoxToken: must have admin role to call reclaimEther");
        payable(_msgSender()).transfer(address(this).balance);
    }

    function reclaimToken(IERC20 _token) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "RoxToken: must have admin role to call reclaimToken");
        uint256 balance = _token.balanceOf(address(this));
        SafeERC20.safeTransfer(_token, _msgSender(), balance);
    }
}