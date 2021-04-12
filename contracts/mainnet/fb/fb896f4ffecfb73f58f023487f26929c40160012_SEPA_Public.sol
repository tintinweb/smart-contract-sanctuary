// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../Ownable.sol" ;

//@title SEPA Token contract interface
interface SEPA_Token {                                     
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

//@title SEPA Public Contract
contract SEPA_Public is Ownable {
    uint256 public SEPAPrice ;
    
    address public token_addr ; 
    SEPA_Token token_contract = SEPA_Token(token_addr) ;
    
    event bought(address buyer, uint256 amount) ;
    event priceAdjusted(uint256 oldPrice, uint256 newPrice) ; 
    
    mapping(address => uint256) claimed_amount;

    constructor(uint256 SEPAperETH) {
        SEPAPrice = SEPAperETH ; 
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
     * @dev Set SEPA Token contract address
     * @param addr Address of SEPA Token contract
     */
    function set_token_contract(address addr) external onlyOwner {
        token_addr = addr ;
        token_contract = SEPA_Token(token_addr) ;
    }

    /**
     * @dev Buy SEPA tokens directly from the contract
     */
    function buy_SEPA() public payable returns (bool success) {
        uint256 scaledAmount = safeMultiply(msg.value, SEPAPrice) ;
        require(block.timestamp >= 1617912000, "Contract not yet active") ; //Thu, 08 Apr 2021 20:00:00 UTC

        require(token_contract.balanceOf(address(this)) >= scaledAmount) ;
        require(msg.value <= 3 ether, "Transaction value exceeds 3 ether") ; 
        require(claimed_amount[msg.sender] + msg.value <= 3 ether, "Maximum amount reached");


        token_contract.transfer(msg.sender, scaledAmount) ;
        
        emit bought(msg.sender, scaledAmount) ; 
    
        success =  true ; 
    }
    
    /**
     * @dev Fallback function for when a user sends ether to the contract
     * directly instead of calling the function
     */
    receive() external payable {
        buy_SEPA() ; 
    }

    /**
     * @dev Adjust the SEPA token price
     * @param   SEPAperETH the amount of SEPA a user receives for 1 ETH
     */
    function adjustPrice(uint SEPAperETH) external onlyOwner {
        emit priceAdjusted(SEPAPrice, SEPAperETH) ; 
        
        SEPAPrice = SEPAperETH ; 
        
    }

    /**
     * @dev End the SEPA token distribution by sending all leftover tokens and ether to the contract owner
     */
    function endSEPAPublic() external onlyOwner {             
        require(token_contract.transfer(owner(), token_contract.balanceOf(address(this)))) ;

        msg.sender.transfer(address(this).balance) ;
    }
}