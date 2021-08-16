// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import './ERC20.sol';
import './Address.sol';
import './Ownable.sol';

contract TrustCommunityToken is ERC20, Ownable {

    mapping(address => uint256) private _blockedAddresses;
    mapping(address => uint256) private _blockNumberByAddress;
    mapping(address => uint256) private _sellLimitAddresses;
    address private _tctBurnAddress;
    address private _communityWallet;
    uint256 private _burnRate;
    bool private _turnOffSellLimit;
    uint256 private constant _totalSupply = 1000000000000000000000000000000000; //2.5 quad with 18 decimals

    struct TaxFreeFund {
        address toAddress;  
        uint256 amount;
    }
     constructor() ERC20('Trust Community Token', 'TRUST') {
        _tctBurnAddress = address(0x8cd3c5fF5C6d094CeFEEDB1c8669DfF76d8c1c95);
        _communityWallet = address(0x5c66E55fE639e8cD2b20aD48a7fb669d1cfd2622);
        _burnRate = 100;
        _turnOffSellLimit = true;
        _mint(msg.sender, _totalSupply);
    }

    function transfer(address _to, uint256 _value) public virtual override returns (bool) {
        require(_blockedAddresses[_to] != 1, "You are currently blocked from transferring tokens. Please contact TCT Team");
        address _from = _msgSender();
        address human = ensureOneHuman(_from, _to);
        ensureOneTxPerBlock(human);
        checkIfExceedsLimit(_to, _value);
        checkIfExceedsLimit(_from, _value);
        uint256 toBurnAndToShare = _value / _burnRate;
        if (ERC20.transfer(_to, _value - (2 * toBurnAndToShare))) {
            ERC20.transfer(_communityWallet, toBurnAndToShare);
            ERC20.transfer(_tctBurnAddress, toBurnAndToShare);
            _blockNumberByAddress[human] = block.number;
            return true;
        } else return false;
        
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
        require(_blockedAddresses[_from] != 1, "You are currently blocked from transferring tokens. Please contact TCT Team");
        require(_blockedAddresses[_to] != 1, "Your receiver is currently blocked from receiving tokens. Please contact TCT Team");

        address human = ensureOneHuman(_from, _to);
        ensureOneTxPerBlock(human);
      
        checkIfExceedsLimit(_from, _value);
        checkIfExceedsLimit(_to, _value);
        
        uint256 toBurnAndToShare = _value / _burnRate;
        if (ERC20.transferFrom(_from, _to, _value - (2 * toBurnAndToShare))) {
            _burn(_from, toBurnAndToShare);
            ERC20.transferFrom(_from, _communityWallet, toBurnAndToShare);
            ERC20.transfer(_tctBurnAddress, toBurnAndToShare);
            _blockNumberByAddress[human] = block.number;
            return true;
        } else return false;
    }

    function burnAddress() public virtual override view returns (address) {
        return _tctBurnAddress;
    }

    function communityWallet() public view returns (address) {
        return _communityWallet;
    }

    function isAddressBlocked(address addr) public view returns (bool) {
        return _blockedAddresses[addr] > 0;
    }

    function burnTokens(address from, uint amount) external onlyOwner() {
        _burn(from, amount);
    }

    function taxFreeTransfer(address _to, uint256 _value) external onlyOwner() returns (bool) {
        ERC20.transfer(_to, _value);
        return true;
    }
    
    function taxFreeTransfers(address[] memory addresses, uint256 amount) external onlyOwner() returns (bool) {
      for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            ERC20.transfer(addr, amount);
        }
        return true;
    }
    
    function taxFreeTransfersAmounts(TaxFreeFund[] memory taxFreeFunds) external onlyOwner() returns (bool) {
        for (uint256 i = 0; i < taxFreeFunds.length; i++) {
            TaxFreeFund memory taxFreeFund = taxFreeFunds[i];
            ERC20.transfer(taxFreeFund.toAddress, taxFreeFund.amount);
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
        _turnOffSellLimit = enableDisable;
    }

    function isSellLimitForAddress(address addr) external onlyOwner() view returns(uint256) {
       return  _sellLimitAddresses[addr];
    }
    
    function isSellLimitEnabled() external onlyOwner() view returns(bool) {
      return _turnOffSellLimit;
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
    
    function removeSellLimitAddresses(address[] memory addresses) external onlyOwner() {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            delete _sellLimitAddresses[addr];
        }
    }
    
    function checkIfExceedsLimit(address addr, uint256 amount) internal virtual {
        if(_turnOffSellLimit) {
            uint256 basePoints =  _sellLimitAddresses[addr];
            uint256 addrBalance = ERC20.balanceOf(addr);
            if(basePoints > 0 && addrBalance > 0) {
                uint256 maxAmount = (addrBalance * basePoints) /10000;
                require(amount <= maxAmount, "Your sale exceeds the amount you are allowed at this time. Please contact TCT Team for assistance");
            }
        }
    }
    
    function ensureOneTxPerBlock(address addr) internal virtual {
        bool isNewBlock = _blockNumberByAddress[addr] == 0 ||
        _blockNumberByAddress[addr] < block.number;
        require(isNewBlock, 'Only one transaction per block!');
    }

    function ensureOneHuman(address _to, address _from) internal virtual returns (address) {
        require(!Address.isContract(_to) || !Address.isContract(_from), 'No bots allowed!');
        if (Address.isContract(_to)) return _from;
        else return _to;
    }
}