/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private m_Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        m_Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return m_Owner;
    }

    modifier onlyOwner() {
        require(_msgSender() == m_Owner, "Ownable: caller is not the owner");
        _;
    }                                                                                          
} 

interface UniV2Token {                                                                          // This is the contract for UniswapV2Pair
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface DecisionToken {                                                                       // This is the contract of actual coin
    function totalEarnings() external view returns (uint256);
}

contract LiqLockToBurn is Context, Ownable {

    UniV2Token private V2Token;
    DecisionToken private DToken;
    uint256 m_Balance;
    uint256 m_Earnings;
    uint256 m_EarningsLimit;
    address m_InvestorAddressA;
    address m_InvestorAddressB;
    
   constructor() {
       UniV2Token _uniV2Token = UniV2Token(address(this));
       V2Token = _uniV2Token;
       DecisionToken _decisionToken = DecisionToken(address(this));
       DToken = _decisionToken;
    }
   
    function getBalance() public returns (uint256) {
        m_Balance = V2Token.balanceOf(address(this));
        return m_Balance;
    }
    
    function checkEarnings() public returns (uint256) {
        m_Earnings = DToken.totalEarnings();
        return m_Earnings;
    }

    function executeTokenDecision() external onlyOwner() {
        uint256 _amount;
        
        V2Token.approve(address(this), getBalance());
        
        if(checkEarnings() >= m_EarningsLimit){ // 10 ETH
            _amount = m_Balance;
            V2Token.transferFrom(address(this), address(0), _amount);
        }
        else{
            _amount = m_Balance / 2;
            V2Token.transferFrom(address(this), m_InvestorAddressA, _amount);
            V2Token.transferFrom(address(this), m_InvestorAddressB, _amount);
        }   
    }
    
    function assignInvestorAddresses(address _addressA, address _addressB) external onlyOwner() {
        m_InvestorAddressA = _addressA;
        m_InvestorAddressB = _addressB;
    }
    
    function assignV2Pair(address _address) external onlyOwner() {
        UniV2Token _uniV2Token = UniV2Token(_address);
        V2Token = _uniV2Token;
    }
    
    function assignDecisionToken(address _address) external onlyOwner() {
        DecisionToken _decisionToken = DecisionToken(_address);
        DToken = _decisionToken;
    }
    
    function assignEarningsLimit(uint256 _amount) external onlyOwner() {
        m_EarningsLimit = _amount;
    }
}