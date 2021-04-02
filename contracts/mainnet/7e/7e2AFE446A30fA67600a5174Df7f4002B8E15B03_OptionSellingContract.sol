/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.8.2;

// SPDX-License-Identifier: MIT

interface IERC20 {
    
    /**
    * @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view returns (uint256);
    
    /**
    * @dev Returns the token decimals.
    */    
    function decimals() external view returns (uint8);
    
    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory);
    
    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);
    
    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);
    
    /**
    * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view returns (uint256);
    
    /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
    function allowance(address _owner, address spender) external view returns (uint256);
    
    /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * IMPORTANT: Beware that changing an allowance with this method brings the risk
    * that someone may use both the old and the new allowance by unfortunate
    * transaction ordering. One possible solution to mitigate this race
    * condition is to first reduce the spender's allowance to 0 and set the
    * desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    *
    * Emits an {Approval} event.
    */
    function approve(address spender, uint256 amount) external returns (bool);
    
    /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    /**
    * @dev Emitted when `value` tokens are moved from one account (`from`) to
    * another (`to`).
    *
    * Note that `value` may be zero.
    */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /**
    * @dev Emitted when the allowance of a `spender` for an `owner` is set by
    * a call to {approve}. `value` is the new allowance.
    */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OptionSellingContract {
    IERC20 buyingTokenContract;
    uint buyingAmount;
    
    IERC20 sellingtokenContract;
    uint sellingAmount;
    
    /**
    * @dev Returns the Buyers address
    */
    address public buyerAddress;
    
    /**
    * @dev Returns the sellers address
    */
    address public sellerAddress;
    
    /**
    * @dev Returns the state of the contract, if true tokens are deposited and 
    * trades can be excecuted
    */
    bool public isInitialised;
    
    /**
    * @dev Returns the amount of tokens that were sold through this contract
    */
    uint public soldAmount;
    
    /**
    * @dev Returns the amount of tokens that were bought through this contract
    */
    uint public boughtAmount;
    
    /**
    * @dev Initializes the contract setting the needed values for the trade.
    */
    constructor () {
        buyingTokenContract = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        buyingAmount = 40e8;
        buyerAddress = 0x1574c679261C3715c789c02a496a443Fea7A1474;
        sellingtokenContract = IERC20(0x191557728e4d8CAa4Ac94f86af842148c0FA8F7E);
        sellingAmount = 120000000e8;
        sellerAddress = 0x7c50038b33DE3679cf2A5783AAfF5FE358709680;
    }
    
    /**
    * @dev This method thakes the predefined amount of selling tokens from the 
    * sellers account and initializes the contract which means that 
    * trading can start.
    * 
    * IMPORTANT: This method will not work if allowance on the selling token is 
    * not set to the appropriate ammount
    */
    function initializeContract() public {
        require(msg.sender == sellerAddress);
        require(!isInitialised, "Contract is already initialised!");
        sellingtokenContract.transferFrom(msg.sender, address(this), sellingAmount);
        isInitialised = true;
    }
    
    /**
    * @dev Creates the trade, it sends the amount of buying tokens that are ont the smart 
    * contract to the seller and withdraws the appropriate amount of selling tokens to the buyer
    * 
    * IMPORTANT: This method will only work if contract is initialised and if balance of buying token is at leats 0.1.
    */
    function executeSell() public {
        require(msg.sender == sellerAddress || msg.sender == buyerAddress);
        require(buyingTokenContract.balanceOf(address(this)) >= 1e7, "Selling ammount must me greater than 0.1 WBTC!");
        require(isInitialised, "Contract is not initialised!");
        
        uint buyingBalance = buyingTokenContract.balanceOf(address(this));
        if (buyingAmount - boughtAmount < buyingBalance){
            buyingTokenContract.transfer(buyerAddress, buyingBalance - (buyingAmount - boughtAmount));
            buyingBalance = buyingAmount - boughtAmount;
        }
        boughtAmount += buyingBalance;
        buyingTokenContract.transfer(sellerAddress, buyingBalance);
        
        
        uint activeSoldAmount = (buyingBalance * (sellingAmount/buyingAmount));
        soldAmount += activeSoldAmount;
        sellingtokenContract.transfer(buyerAddress, activeSoldAmount);
    }
    
    /**
    * @dev Returns the amount of selling tokens on the smart contract
    */
    function sellingTokenBalance() public view returns (uint){
        return sellingtokenContract.balanceOf(address(this));
    }
    
    /**
    * @dev Returns the amount of buying tokens on the smart contract
    */
    function buyingTokenBalance() public view returns (uint){
        return buyingTokenContract.balanceOf(address(this));
    }
    
    /**
    * @dev After the trading is complete and all the tokens are sent 
    * appropriatly the buyer gets the control of the smart contract 
    * so he can salvage wrongly sent tokens.
    */
    function salvageTokensFromContract(address tokenAddress, address to, uint amount) public {
        require(msg.sender == buyerAddress);
        require(boughtAmount == buyingAmount);
        IERC20(tokenAddress).transfer(to, amount);
    }
}