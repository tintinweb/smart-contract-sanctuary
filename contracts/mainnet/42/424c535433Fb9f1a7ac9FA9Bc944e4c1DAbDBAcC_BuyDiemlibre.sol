/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

//SPDX-License-Identifier: SourceLibre

/**
 * Elysium
 * Powered by Diemlibre.
 * A SourceLibre Product.
 * DApp for buying Diemlibre $DLB.
 * 
 * This file includes:
 * 1) interface IERC20.
 * 2) library SafeMath.
 * 3) contract BuyDiemlibre.
 * 
 * Note: Token is in its smallet unit with respect to its decimal value.
 */
pragma solidity 0.8.1;


/**
 * ERC Interface for Diemlibre Token.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Safe Math Library.
 */
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


/**
 * BuyDiemlibre Contract.
 * 
 * Default Attribues:
 * - `owner` -> The owner of the contract.
 * - `rate` -> The rate of the exchange in WEI, to be set by the `owner`.
 * - `token` -> The ERC20 token handle.
 * - `holder` -> The address of the holder of coins which this contract will be spending on its behave.
 * - `self` -> The address of this contract. To be set by the owner after deployment.
 * - `fees` -> The fees per transaction to be set by the owner.
 */
contract BuyDiemlibre {
    
    using SafeMath for uint256;
    address owner;
    uint256 rate; // Rate is in WEI per Diemlibre
    IERC20 token;
    uint256 tokenDecimalsValue;
    address holder;
    address self;
    uint256 fees;
    
    /**
     * 
     * Method Name: constructor
     * Initialises the contract.
     * Set most of the default attribues.
     *
     * Parameters:
     * - `address _tokenAddress` -> non zero address of the token contract.
     * - `address _holderAddress` -> non zero address of the holder of the tokens which has tokens.
     * - the caller is recommeded to be the owner or has some admin control of the token contract.
     * 
     */
    constructor(address _tokenAddress, address _holderAddress) {
        require(_tokenAddress != address(0), "Error! Invalid Token Address.");
        require(_holderAddress != address(0), "Error! Invalid Holder Address.");
        require(_tokenAddress != _holderAddress, "Token Address and Spender Address cann't be the same.");
        
        token = IERC20(_tokenAddress);
        holder = _holderAddress;
        owner = msg.sender;
        rate = 1000000000000000000; // in WEI
        fees = 0;
        tokenDecimalsValue = 10**token.decimals();
    }
    
    /**
     * 
     * Method Name: withdrawETHToOwner, private
     * Withdraw ETH to the owner.
     *
     * Parameters:
     * - `uint256 _amount` -> non zero amount of ETH to be sent to the owner.
     * 
     * Returns:
     * Boolean if the transaction was successfull or not.
     * 
     */
    function withdrawETHToOwner(uint256 _amount) private returns(bool) {
         payable(owner).transfer(_amount);
         return true;
    }
    
    function getRate() external view returns(uint256) {
        return rate;
    }
    
    function getSelf() external view returns(address) {
        return self;
    }
    
    function getFees() external view returns(uint256) {
        return fees;
    }
    
    
    /**
     * 
     * Method Name: currentETHValue, external view
     * Gets the current ETH value of 1 Token.
     *
     * Parameters:
     * - `uint256 _tokenAmount` -> non zero amount of tokens to get its equivilence in ETH.
     * 
     * Returns:
     * The amount in ETH.
     * 
     */
    function currentETHValue(uint256 _tokenAmount) external view returns(uint256) {
        return _tokenAmount.mul(rate).div(tokenDecimalsValue);
    }
    
    
    /**
     * 
     * Method Name: currentTokenValue, external view
     * Gets the current token value of 1 ETH.
     *
     * Parameters:
     * - `uint256 _WEIETHAmount` -> non zero amount of ETH in WEI to get its equivilence in token.
     * 
     * Returns:
     * The amount in token.
     * 
     */
    function currentTokenValue(uint256 _WEIETHAmount) external view returns(uint256) {
        return _WEIETHAmount.mul(tokenDecimalsValue).div(rate);
    }
    
    
    /**
     * 
     * Method Name: _buy, private
     * Payable the sends equivilent tokens calculated based on the rate to the msg.sender.
     *
     * Parameters:
     * - `address _msgSender` -> non zero address of the Message sender.
     * - `uint256 _msgValue` -> non zero amount of ETH in WEI the sender sent.
     * 
     * Returns:
     * The total amount of tokens the sender has.
     * 
     */
    function _buy(address _msgSender, uint256 _msgValue) private returns(uint256) {
        require(_msgValue > 0, "Error! Invalid or Insufficient Amount.");
        require(self != address(0), "Error! Uninitialized self.");
        
        uint256 tokenAmount = _msgValue.mul(tokenDecimalsValue).div(rate);
        uint256 tokenAllowance = token.allowance(holder, self);
        
        require(tokenAmount > 0 && tokenAmount <= tokenAllowance, "Insufficient Liquidity");
        
        withdrawETHToOwner(_msgValue);
        require(token.transferFrom(holder, _msgSender, tokenAmount), "Oops... Could not complete Transaction. Please try again later.");
        return token.balanceOf(_msgSender);
    }
    
    
     /**
     * 
     * Method: _buyFor, private
     * Payable the sends equivilent tokens calculated based on the rate to the _receiver set by msg.sender.
     *
     * Parameters:
     * - `address _receiver` -> non zero address of the receiver of the tokens.
     * - `uint256 _msgValue` -> non zero amount of ETH in WEI the sender sent.
     * 
     * Returns:
     * The total amount of tokens the _receiver has.
     * 
     */
    function _buyFor(address _receiver, uint256 _msgValue) private returns(uint256) {
        require(_msgValue > 0, "Error! Invalid or Insufficient Amount.");
        require(self != address(0), "Error! Uninitialized self.");
        
        uint256 tokenAmount = _msgValue.mul(tokenDecimalsValue).div(rate);
        uint256 tokenAllowance = token.allowance(holder, self);
        
        require(tokenAmount > 0 && tokenAmount <= tokenAllowance, "Insufficient Liquidity");
        
        withdrawETHToOwner(_msgValue);
        require(token.transferFrom(holder, _receiver, tokenAmount), "Oops... Could not complete Transaction. Please try again later.");
        return token.balanceOf(_receiver);
    }
    
    /**
     * 
     * Method: buy, external payable
     * External implementation of _buy()
     * 
     */
    function buy() external payable returns(uint256) {
        return _buy(msg.sender, msg.value);
    }
    
    /**
     * 
     * Method: buyFor, external payable
     * External implementation of _buyFor()
     * 
     */
    function buyFor(address _receiver) external payable returns(uint256) {
        return _buyFor(_receiver,  msg.value);
    }
    
    /**
     * 
     * Fancy names for Web3.js Providers to read method names.
     * 
     */
    
    // Buy
    function buyDLB() external payable returns(uint256) {
        return _buy(msg.sender, msg.value);
    }
    
    function buyDlb() external payable returns(uint256) {
        return _buy(msg.sender, msg.value);
    }
    
    function buyDiemlibre() external payable returns(uint256) {
        return _buy(msg.sender, msg.value);
    }
    
    // BuyFor
    function buyDLBFor(address _receiver) external payable returns(uint256) {
        return _buyFor(_receiver,  msg.value);
    }
    
    function buyDlbFor(address _receiver) external payable returns(uint256) {
        return _buyFor(_receiver,  msg.value);
    }
    
    function buyDiemlibreFor(address _receiver) external payable returns(uint256) {
        return _buyFor(_receiver,  msg.value);
    }
    
    
    
    /**
     * 
     * Methods to be ran only by the owner
     * 
     */
    function getHolder() external view returns(address) {
        require(msg.sender == owner, "Error! Unauthorized access.");
        return holder;
    }
    
    function setHolder(address _newHolder) external returns(address) {
        require(msg.sender == owner, "Error! Unauthorized access.");
        require(_newHolder != address(0), "Error! Invalid New Holder Address.");
        
        holder = _newHolder;
        return holder;
    }
    
    function withdrawETH(address _receiver, uint256 _amount) external returns(bool) {
        require(msg.sender == owner, "Error! Unauthorized access.");
        require(_receiver != address(0), "Error! Invalid Receiver Address.");
        
        payable(_receiver).transfer(_amount);
        return true;
    }
    
    function setRate(uint256 _newRate) external returns(uint256) {
        require(msg.sender == owner, "Error! Unauthorized access.");
        rate = _newRate;
        return rate;
    }
    
    function setFees(uint256 _newFees) external returns(uint256) {
        require(msg.sender == owner, "Error! Unauthorized access.");
        fees = _newFees;
        return fees;
    }
    
    function setSelf(address _selfAddress) external returns(address) {
        require(msg.sender == owner, "Error! Unauthorized access.");
        require(_selfAddress != address(0), "Error! Invalid Self Address.");
        
        self = _selfAddress;
        return self;
    }
}