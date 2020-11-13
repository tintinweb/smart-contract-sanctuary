// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Ownable.sol" ;

//@title PRDX Token contract interface
interface PRDX_token {                                     
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

//@title PRDX Initial Distribution Contract
//@author Predix Network Team
contract PRDXDistr is Ownable{
    uint256 public PRDXPrice ;
    
    address public token_addr ; 
    PRDX_token token_contract = PRDX_token(token_addr) ;
    
    event sold(address seller, uint256 amount) ;
    event bought(address buyer, uint256 amount) ;
    event priceAdjusted(uint256 oldPrice, uint256 newPrice) ; 

    constructor(uint256 PRDXperETH) {
        PRDXPrice = PRDXperETH ; 
    }

    /**
     * @dev Multiply two integers with extra checking the result
     * @param   a Integer 1 
     *          b Integer 2
     */
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0 ;
        } else {
            uint256 c = a * b ;
            assert(c / a == b) ;
            return c ;
        }
    }
    
    /**
     * @dev Divide two integers with checking b is positive
     * @param   a Integer 1 
     *          b Integer 2
     */
    function safeDivide(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); 
        uint256 c = a / b;

        return c;
    }
    
    /**
     * @dev Set PRDX Token contract address
     * @param addr Address of PRDX Token contract
     */
    function set_token_contract(address addr) public onlyOwner {
        token_addr = addr ;
        token_contract = PRDX_token(token_addr) ;
    }
    
    /**
     * @dev Sell PRDX tokens through Predix Network token contract
     * @param   seller Account to sell PRDX tokens from
     *          amount Amount of PRDX to sell
     */
    function sell_PRDX(address payable seller, uint256 amount) public returns (bool success) {
        require(token_contract.transferFrom(seller, address(this), amount), "Error transacting tokens to contract") ;
        
        uint256 a = safeDivide(amount, PRDXPrice) ; 
        
        seller.transfer(a) ; 
        
        emit sold(seller, a) ; 
        
        return true ; 
    }

    /**
     * @dev Buy PRDX tokens directly from the contract
     */
    function buy_PRDX() public payable returns (bool success) {
        require(msg.value > 0) ; 
        uint256 scaledAmount = safeMultiply(msg.value, PRDXPrice) ;
        require(token_contract.balanceOf(address(this)) >= scaledAmount) ;

        token_contract.transfer(msg.sender, scaledAmount) ;
        
        emit bought(msg.sender, scaledAmount) ; 
    
        return true ; 
    }
    
    /**
     * @dev Fallback function for when a user sends ether to the contract
     * directly instead of calling the function
     */
    receive() external payable {
        buy_PRDX() ; 
    }

    /**
     * @dev Adjust the PRDX token price
     * @param   PRDXperETH the amount of PRDX a user receives for 1 ETH
     */
    function adjustPrice(uint PRDXperETH) public onlyOwner {
        emit priceAdjusted(PRDXPrice, PRDXperETH) ; 
        
        PRDXPrice = PRDXperETH ; 
        
    }

    /**
     * @dev End the PRDX token distribution by sending all leftover tokens and ether to the contract owner
     */
    function endPRDXDistr() public onlyOwner {             
        require(token_contract.transfer(owner(), token_contract.balanceOf(address(this)))) ;

        msg.sender.transfer(address(this).balance) ;
    }
}