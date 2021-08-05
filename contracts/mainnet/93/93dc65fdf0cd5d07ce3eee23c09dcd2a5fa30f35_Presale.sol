// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./INEON.sol";

contract Presale is Ownable {
    using SafeMath for uint256;
     
    uint256 private _depositMinAmount;
    uint256 private _depositMaxAmount;
    address private _neonTokenAddress;
    uint16 private _rate;

    mapping(address => uint256) _depositedAmounts;

    event Deposited(address account, uint256 amount);
    event SentToken(address account, uint256 fund, uint256 amount);
    event EmergencyWithdrewToken(address from, address to, uint256 amount);
    
    constructor() {
        // Number of tokens per 1 ETH = 5 (initial value)
        _rate = 5;
        // Minimum deposit amount  = 0.5 ETH (initial value)
        _depositMinAmount = 5E17;
        // Maximum deposit amount  = 20 ETH (initial value)
        _depositMaxAmount = 25E18;
    }

    // get number of tokens per 1 ETH
    function rate() external view returns (uint16) {
        return _rate;
    }

    // change number of tokens per 1 ETH
    function changeRate(uint16 rate_) external onlyGovernance {
        _rate = rate_;
    }

    // return min amount to deposite
    function depositeMinAmount() external view returns (uint256) {
        return _depositMinAmount;
    }

    // change min amount to deposite
    function changeDepositeMinAmount(uint256 depositMinAmount_) external onlyGovernance {
        _depositMinAmount = depositMinAmount_;
    }

    // return max amount to deposite
    function depositeMaxAmount() external view returns (uint256) {
        return _depositMaxAmount;
    }

    // change max amount to deposite
    function changeDepositeMaxAmount(uint256 depositMaxAmount_) external onlyGovernance {
        _depositMaxAmount = depositMaxAmount_;
    }

    // return user's deposited amount
    function depositedAmount(address account) external view returns (uint256) {
        return _depositedAmounts[account];
    }

    // return the total ether balance deposited by users
    function totalDepositedAmount() external view returns (uint256){
        return address(this).balance;
    }

    // return NEON token address
    function neonTokenAddress() external view returns (address) {
        return _neonTokenAddress;
    }

    // change NEON token address
    function changeNeonTokenAddress(address neonTokenAddress_) external onlyGovernance {
        _neonTokenAddress = neonTokenAddress_;
    }
    
    // Withdraw eth to owner when need it
    function withdraw() external payable onlyGovernance {
        require(address(this).balance > 0, "Ether balance is zero.");
        msg.sender.transfer(address(this).balance);
    }

    // Withdraw NEON token to governance when only emergency!
    function emergencyWithdrawToken() external onlyGovernance {
        require(_msgSender() != address(0), "Invalid address");
        
        uint256 tokenAmount = INEON(_neonTokenAddress).balanceOf(address(this));
        require(tokenAmount > 0, "Insufficient amount");

        INEON(_neonTokenAddress).transferWithoutFee(_msgSender(), tokenAmount);
        emit EmergencyWithdrewToken(address(this), _msgSender(), tokenAmount);
    }
    
    // fall back function to receive ether
    receive() external payable {
       _deposite();
    }
    
    // low level internal deposit function
    function _deposite() internal {
        require(!_isContract(_msgSender()), "Could not be a contract");
        require(governance() != _msgSender(), "You are onwer.");
        require(msg.value >= _depositMinAmount, "Should be great than minimum deposit amount.");
        require(msg.value <= _depositMaxAmount, "Should be less than maximum deposit amount.");

        uint256 fund = msg.value;
        _depositedAmounts[_msgSender()] = _depositedAmounts[_msgSender()].add(fund);
        emit Deposited(_msgSender(), fund);

        // send token to user
        uint256 tokenAmount = fund.mul(uint256(_rate));
        INEON(_neonTokenAddress).transferWithoutFee(_msgSender(), tokenAmount);

        emit SentToken(_msgSender(), fund, tokenAmount);
    }
    
    // check if address is contract
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}
