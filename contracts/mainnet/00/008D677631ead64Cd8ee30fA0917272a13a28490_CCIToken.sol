// contracts/CCIToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";

contract CCIToken is Context, ERC20 {
    
    
    address public _feeAddress;
    uint16 public _feePercent;
    
    // Mapping owner address to freezeBalance
    mapping(address => uint256) public _freezeBalance;
    mapping(address => uint256) public _freezeBlock;
    
    address private _playToEarn;
    address private _loan;
    address private _socialContact;
    address private _ecosystemFund;
    address private _coreTeam;
    address private _publicSale;
    address private _privateSale;
    
    uint256 private constant _playToEarnPercentage = 35;
    uint256 private constant _loanPercentage = 15;
    uint256 private constant _socialContactPercentage = 15;
    uint256 private constant _ecosystemFundPercentage = 10;
    uint256 private constant _coreTeamPercentage = 15;
    uint256 private constant _publicSalePercentage = 5;
    uint256 private constant _privateSalePercentage = 5;
    
    // release block lock
    uint256 private constant _firstReleaseBlockLock = 0;
    uint256 private constant _secondReleaseBlockLock = 1036800;
    uint256 private constant _thirdReleaseBlockLock = 2073600;
    uint256 private constant _fourthReleaseBlockLock = 3110400;
    uint256 private constant _fifthReleaseBlockLock = 4147200;
    
    // first release 5%
    uint256 private constant _firstReleaseFreezeRatio = 95;
    // second release 10%
    uint256 private constant _secondReleaseFreezeRatio = 85;
    // third release 15%
    uint256 private constant _thirdReleaseFreezeRatio = 70;
    // fourth release 20%
    uint256 private constant _fourthReleaseFreezeRatio = 50;
    // fifth release 50%
    uint256 private constant _fifthReleaseFreezeRatio = 0;
    
    
    constructor(uint256 initialSupply, address playToEarn, address loan, address socialContact, 
    address ecosystemFund, address coreTeam, address publicSale, address privateSale, 
    address feeAddress, uint16 feePercent) ERC20("GemFi.vip", "CCI") {
        require(_feePercent <= 10000, "GMFToken: input value is more than 100%");
        
        _playToEarn = playToEarn;
        _loan = loan;
        _socialContact = socialContact;
        _ecosystemFund = ecosystemFund;
        _coreTeam = coreTeam;
        _publicSale = publicSale;
        _privateSale = privateSale;
        
        super._mint(_playToEarn, initialSupply * _playToEarnPercentage / 100);
        super._mint(_loan, initialSupply * _loanPercentage / 100);
        super._mint(_socialContact, initialSupply * _socialContactPercentage / 100);
        super._mint(_ecosystemFund, initialSupply * _ecosystemFundPercentage / 100);
        super._mint(_coreTeam, initialSupply * _coreTeamPercentage / 100);
        super._mint(_publicSale, initialSupply * _publicSalePercentage / 100);
        super._mint(_privateSale, initialSupply * _privateSalePercentage / 100);
        
        _feeAddress = feeAddress;
        _feePercent = feePercent;
    }
    
    
    
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        uint256 fee = amount * _feePercent / 10000;
        _transfer(_msgSender(), _feeAddress, fee);
        _burn(_msgSender(), amount - fee);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "GMFToken: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        uint256 fee = amount * _feePercent / 10000;
        _transfer(_msgSender(), _feeAddress, fee);
        _burn(account, amount);
    }
    
    
    /**
     * get account freeze balance
     * 20blocks = 5 mins in Etherium.
     */
    function getFreezeBalance(address account) public view virtual returns (uint256) {
        uint256 freezeBalance = _freezeBalance[account];
        uint256 freezeBlock = _freezeBlock[account];
        if (freezeBalance == 0 || freezeBlock == 0) {
            return 0;
        }
        
        uint256 blockAlreadyFrozen = block.number - freezeBlock;
        
        if (_firstReleaseBlockLock <= blockAlreadyFrozen &&  blockAlreadyFrozen < _secondReleaseBlockLock) {
            return freezeBalance * _firstReleaseFreezeRatio / 100;
        } else if (_secondReleaseBlockLock <= blockAlreadyFrozen && blockAlreadyFrozen < _thirdReleaseBlockLock) {
            return freezeBalance * _secondReleaseFreezeRatio / 100;
        } else if (_thirdReleaseBlockLock <= blockAlreadyFrozen && blockAlreadyFrozen < _fourthReleaseBlockLock) {
            return freezeBalance * _thirdReleaseFreezeRatio / 100;
        } else if (_fourthReleaseBlockLock <= blockAlreadyFrozen && blockAlreadyFrozen < _fifthReleaseBlockLock) {
            return freezeBalance * _fourthReleaseFreezeRatio / 100;
        } else if (_fifthReleaseBlockLock <= blockAlreadyFrozen) {
            return freezeBalance * _fifthReleaseFreezeRatio / 100;
        }else {
            return freezeBalance;
        }
    }
    
    function setAccountTransactionBlockLock(address account, uint256 amount) internal virtual {
        require(_freezeBlock[account] == 0, "GMFToken: The account has received the balance and locked it, please change the account to receive");
        
        _freezeBlock[account] = block.number;
        _freezeBalance[account] = amount;
    }
    
    
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements: 
     *
     * - there are not enough amounts available.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        
        if (from == _coreTeam || from == _privateSale) {
            setAccountTransactionBlockLock(to, amount);
        }
        
        if (from != address(0)) {
            require(amount <= super.balanceOf(from) - getFreezeBalance(from), "GMFToken: The transfer amount is greater than the available amount");
        }
    }
    
    
}