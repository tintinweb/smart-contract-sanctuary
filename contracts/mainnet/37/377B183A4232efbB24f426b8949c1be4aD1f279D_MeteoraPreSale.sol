/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
/** 
 * METEORA - Pre Sale contract
 *
 * Lunaris Incorporation - 2021
 * https://meteora.lunaris.inc
 *
 * This is the Pre Sale contract of METEORA. As explained in the Whitepaper,
 * the amount of MRA bought is locked for a duration of three (3) months (90 days), 
 * after which the owner is free to retrieve his MRA in the wallet he used for the
 * purchase.
 *
 * Please note that the lockup period for the investor is reinitialized each 
 * time he makes a purchase. Also, once the MRA funds have been withdrawn,
 * the user address is not whitelisted anymore.
 * 
 * Finally, a getFundsRemainder Function is added to retreive the MRA remainder
 * from the contract to the Lunaris address after the Pre Sale operation.
 * 
 * RATIO: 6% - 6,000,000 MRA
 * TRANSFERRED FROM THE LUNARIS ADDRESS.
 * 
**/

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MeteoraPreSale {
    address private Lunaris = address(0xf0fA5BC481aDB0ed35c180B52aDCBBEad455e808);
    address private Meteora = address(0x0027089Ea6d8a5fD5c1Eec16cE582287E65ac409);
    
    bool private _isPaused;
    
    uint256 public _lockupPeriod = 86400; // 86400 * 90 seconds - 90 days
    uint256 public _MRAPrice = 62500; // 1 ETH = 62500 MRA - 1 MRA = 0.000016 ETH (~ 0.05 USD)
    uint256 public _MRALeft = 6000000000000000000000000;
    uint256 private _contractTimer;
    
    mapping(address => uint256) private _investorBalance;
    mapping(address => bool) private _isAdmin;
    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _lockupDate;
    
    constructor() {
        _isAdmin[Lunaris] = true;
        _whitelist[Lunaris] = true;
        _contractTimer = block.timestamp;
    }
    
    /**********************/
    /* CONTRACT FUNCTIONS */
    /**********************/
    
    function getMRALeft() public view returns (uint256) {
        return _MRALeft;
    }
    
    function getBalance(address investor) public view returns (uint256) {
        return _investorBalance[investor];
    }
    
    function buyMRA() payable public returns (bool) {
        require(!_isPaused, "METEORA PRESALE: The Pre Sale is put on pause!");
        require(_whitelist[_msgSender()], "METEORA PRESALE: You are not authorized to participate in the Meteora Pre Sale!");
        require(_MRALeft >= (msg.value * _MRAPrice), "METEORA PRESALE: There is not enough MRA in the contract to continue the operation!");
        require(msg.value > 10**17,"METEORA PRESALE: The minimum investment amount is 0.1 ETH!");
        
        uint256 ETH = msg.value;
        
        payable(Lunaris).transfer(msg.value);
        
        _MRALeft -= ETH * _MRAPrice;
        _investorBalance[_msgSender()] += ETH * _MRAPrice;
        _lockupDate[_msgSender()] = block.timestamp;
    
        emit HasInvested(_msgSender(), ETH, _lockupDate[_msgSender()]);
        return true;
    }
    
    function withdraw() public returns (bool) {
        require(!_isPaused, "METEORA PRESALE: The Pre Sale is put on pause!");
        require(_investorBalance[_msgSender()] > 0, "METEORA PRESALE: You do not have any MRA!");
        require(block.timestamp - _lockupDate[_msgSender()] > _lockupPeriod, "METEORA PRESALE: Your MRA is still in its lockup period!");
        
        uint256 amount = _investorBalance[_msgSender()];
        
        ERC20(Meteora).transfer(_msgSender(), amount);
        
        _investorBalance[_msgSender()] = 0;
        _whitelist[_msgSender()] = false;
        
        emit HasWithdrawn(_msgSender(), amount, block.timestamp);
        return true;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
    
    function getLockupDate(address user) public view returns (uint256) {
        return _lockupDate[user];
    }
    
    function getPassedLockupTime(address user) public view returns (uint256) {
        return block.timestamp - _lockupDate[user];
    }
    
    
    /*******************/
    /* ADMIN FUNCTIONS */
    /*******************/
    
    /** 
     * The named admin is granted the power to pause and
     * resume the contract for emergencies, as well as
     * whitelisting the addresses for the pre sale.
    **/
    
    function setWhitelist(address user, bool status) public returns (bool) {
        require(getAdmin(_msgSender()) == true, "METEORA PRESALE: You are not an admin for this operation!");
        require(user != address(0), "METEORA PRESALE: You cannot whitelist the Zero Address!");
        
        _whitelist[user] = status;
        emit Whitelisted(user);
        return _whitelist[user];
    }
    
    function getWhitelist(address user) public view returns (bool) {
        return _whitelist[user];
    }
    
    function setAdmin(address user, bool status) public returns (bool) {
        require(_isAdmin[_msgSender()], "METEORA PRESALE: You are not an admin for this operation!");
        require(user != address(0), "METEORA PRESALE: You cannot admin the Zero Address!");
        require(user != Lunaris, "METERORA PRESALE: Lunaris is the big boss, mkay?");
        
        _isAdmin[user] = status;
        emit AdminSet(_msgSender(), user, status);
        return _isAdmin[user];
    }
    
    function getAdmin(address user) public view returns (bool) {
        return _isAdmin[user];
    }
    
    function setPause(bool status) public returns (bool) {
        require(_isAdmin[_msgSender()], "METEORA PRESALE: You are not an admin for this operation!");
        
        _isPaused = status;
        return true;
    }
    
    function getPause() public view returns (bool) {
        return _isPaused;
    }
    
    function getPassedContractTime() public view returns (uint256) {
        return block.timestamp - _contractTimer;
    }
    
    function getFundsRemainder() public returns (bool) {
        require(_msgSender() == Lunaris, "METEORA PRESALE: You are not Lunaris for this operation!");
        require(_MRALeft > 0, "METEORA PRESALE: There is no MRA left anyway!");
        
        ERC20(Meteora).transfer(Lunaris, _MRALeft);
        _MRALeft = 0;
        
        return true;
    }
    
    
    /**********/
    /* EVENTS */
    /**********/
    
    event Whitelisted(address user);
    event AdminSet(address admin, address user, bool status);
    event HasInvested(address investor, uint256 amount, uint256 time);
    event HasWithdrawn(address investor, uint256 amount, uint256 time);
    
    /***********/
    /* CONTEXT */
    /***********/
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function getContractBalance() public view returns (uint256) {
        return ERC20(Meteora).balanceOf(address(this));
    }
}