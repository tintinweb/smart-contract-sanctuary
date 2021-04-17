// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ECDSA.sol';
import './IERC20.sol';
import './Context.sol';

contract ZefuVaultETH is Context{
    using ECDSA for bytes32;
    
    struct Cross {
        uint256 nonce;
        mapping (uint256 => uint256) amount;
    }
    
    
    mapping(address => Cross) private _transferIn;
    mapping(address => Cross) private _transferOut;
    
    
    IERC20 private ZEFU;
    address private _validator;
    
    
    
    constructor(IERC20 token, address validator) {
        ZEFU = token;
        _validator = validator;
    }
    
    
    
    
    
    function vaultBalance() public view returns (uint256) {
        return ZEFU.balanceOf(address(this));
    }
    
    function getNonceIn(address user) public view returns (uint256) {
        return _transferIn[user].nonce;
    }
    
    function getNonceOut(address user) public view returns (uint256) {
        return _transferOut[user].nonce;
    }
    
    function getAmountIn(address user, uint256 nonce) public view returns (uint256) {
        return _transferIn[user].amount[nonce];
    }
    
    function getAmountOut(address user, uint256 nonce) public view returns (uint256) {
        return _transferOut[user].amount[nonce];
    }
    
    function getValidator() public view returns (address) {
        return _validator;
    }
    
    
    
    
    function setValidator(address validator) public {
        require(_msgSender() == _validator, "Valut: Invalid Validator.");
        _validator = validator;
    }
    
    function getHash(address user, uint256 nonce, uint256 amount) public pure returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(user, nonce, amount));
    }
    
    
    
    function swapToBSC(uint256 amount) public virtual {
        address user = _msgSender();
        ZEFU.transferFrom(user, address(this), amount);
        uint256 nonce = getNonceOut(user);
        _transferOut[user].amount[nonce] = amount;
        _transferOut[user].nonce++;
        
    }
    
    
    function swapFromBSC(uint256 amount, bytes memory signature) public virtual {
        address user = _msgSender();
        uint256 nonce = getNonceIn(user);
        bytes32 hash = keccak256(abi.encodePacked(user, nonce, amount));
        require(hash.recover(signature) == getValidator(), "Vault: Invalid transaction.");
        _transferIn[user].amount[nonce] = amount;
        _transferOut[user].nonce++;
        ZEFU.transfer(_msgSender(), amount);
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}