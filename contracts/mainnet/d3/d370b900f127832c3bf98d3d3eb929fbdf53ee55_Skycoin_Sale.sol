/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

//@title SKY Token contract interface
interface Skycoin_token {                                     
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

//@title SKY Initial Distribution Contract
contract Skycoin_Sale {
    uint256 public SKYPrice ;
    
    address public token_addr ; 
    Skycoin_token token_contract = Skycoin_token(token_addr) ;
    
    event sold(address seller, uint256 amount) ;
    event bought(address buyer, uint256 amount) ;
    event priceAdjusted(uint256 oldPrice, uint256 newPrice) ; 
    
    address public owner ; 
    
    uint256 public START_TIMESTAMP = 0 ; 

    constructor(uint256 SKYperETH) {
        SKYPrice = SKYperETH ;
        owner = msg.sender ; 
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Sender not owner!") ; 
        _;
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
     * @dev Set SKY Token contract address
     * @param addr Address of SKY Token contract
     */
    function set_token_contract(address addr) public onlyOwner {
        token_addr = addr ;
        token_contract = Skycoin_token(token_addr) ;
    }

    /**
     * @dev Buy SKY tokens directly from the contract
     */
    function buy_SKY() public payable returns (bool success) {
        require(msg.value > 0, "Message value should exceed 0") ; 
        uint256 scaledAmount = safeMultiply(msg.value, SKYPrice) ;
        require(token_contract.balanceOf(address(this)) >= scaledAmount, "Contract balance not sufficient") ;
        require(block.timestamp > START_TIMESTAMP, "Sale has not yet started!") ; 

        token_contract.transfer(msg.sender, scaledAmount) ;
        
        emit bought(msg.sender, scaledAmount) ; 
    
        return true ; 
    }
    
    /**
     * @dev Fallback function for when a user sends ether to the contract
     * directly instead of calling the function
     */
    receive() external payable {
        buy_SKY() ; 
    }

    /**
     * @dev Adjust the SKY token price
     * @param   SKYperETH the amount of SKY a user receives for 1 ETH
     */
    function adjustPrice(uint SKYperETH) external onlyOwner {
        require(block.timestamp < START_TIMESTAMP, "Cannot adjust price during sale!") ; 
        emit priceAdjusted(SKYPrice, SKYperETH) ; 
        
        SKYPrice = SKYperETH ; 
    }

    /**
     * @dev End the SKY token distribution by sending all leftover tokens and ether to the contract owner
     */
    function endSKYDistr() external onlyOwner {             
        require(token_contract.transfer(owner, token_contract.balanceOf(address(this))), "Error during transfer") ;

        msg.sender.transfer(address(this).balance) ;
    }
    
    /**
     * @dev Withdraw ether to contract owner
     */
    function withdrawEther() external onlyOwner {
        msg.sender.transfer(address(this).balance) ; 
    }
    
    /**
     * @dev Withdraw stuck ERC20 tokens 
     * @param   tokenAddress Cntract address of stuck ERC20 address
     *          amount Amount of tokens to be withdrawn
     */
    function withdrawERC20(address tokenAddress, uint amount) external onlyOwner {
        Skycoin_token ERC20_contract = Skycoin_token(tokenAddress) ;
        ERC20_contract.transfer(msg.sender, amount) ; 
    }
    
    /**
     * @dev Renenounce ownership of sale contract to new owner address. Ensure newOwner can call owner functions.
     * @param   newOwner address of new owner
     */
    function renounceOwnership(address newOwner) external onlyOwner {
        owner = newOwner ; 
    }
}