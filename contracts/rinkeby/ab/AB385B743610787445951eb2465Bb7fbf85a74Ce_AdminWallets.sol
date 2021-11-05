/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract AdminWallets is Ownable {

    address private OWNER_WALLET = 0x2565053B002ea3C52dC533C00838335Bf49D0FE9; 
    address private DIVERSITY_WALLET = 0xe2165a834F93C39483123Ac31533780b9c679ed4; 
    address private ASSETBENDER_WALLET = 0x650802BD9dF24DF295241684185265196f88BA7D; 
    address private MARKETING_WALLET = 0x9cE09Fd065f2C6b5668b458627608F561b3B1336; 
    address private DIVINETREASURY_WALLET = 0x650802BD9dF24DF295241684185265196f88BA7D; 
    uint256 private _presaleRound = 1;
    bool private _presaleActive = true;
    
    mapping(address => bool) private EMPEROR_LIST; 

    // Wallet setters.
    function setOwnerWallet(address _OWNER_WALLET) external onlyOwner {
        OWNER_WALLET = _OWNER_WALLET;
    }

    function setDiversityWallet(address _DIVERSITY_WALLET) external onlyOwner {
        DIVERSITY_WALLET = _DIVERSITY_WALLET;
    }

    function setAssetBenderWallet(address _ASSETBENDER_WALLET) external onlyOwner {
        ASSETBENDER_WALLET = _ASSETBENDER_WALLET;
    }

    function setMarketingWallet(address _MARKETING_WALLET) external onlyOwner {
        MARKETING_WALLET = _MARKETING_WALLET;
    }

    function setDivineTreasuryWallet(address _DIVINETREASURY_WALLET) external onlyOwner {
        DIVINETREASURY_WALLET = _DIVINETREASURY_WALLET;
    }

    // Wallet getters.
    function getOwnerWallet() external view returns(address) {
        return OWNER_WALLET;
    }

    function getDiversityWallet() external view returns(address) {
        return DIVERSITY_WALLET;
    }

    function getAssetBenderWallet() external view returns(address) {
        return ASSETBENDER_WALLET;
    }

    function getMarketingWallet() external view returns(address) {
        return MARKETING_WALLET;
    }

    function getDivineTreasuryWallet() external view returns(address) {
        return DIVINETREASURY_WALLET;
    }

    // Emperor list functions.
    function joinEmperorList(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            EMPEROR_LIST[accounts[i]] = true;
        }
    }

    function isInEmperorList(address account) external view returns(bool) {
        return EMPEROR_LIST[account];
    }

    

    
    

   

   
}