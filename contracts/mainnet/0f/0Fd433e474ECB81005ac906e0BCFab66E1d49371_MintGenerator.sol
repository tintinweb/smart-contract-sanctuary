// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

// This contract generates ENMT tokens and registers them in the Unicrypt ENMT MintFactory.

pragma solidity ^0.8.0;


import "./IERC20.sol";
import "./Ownable.sol";

import "./ENMT.sol";
import "./MintFactory.sol";
import "./TokenFees.sol";


interface IMintFactory {
    function registerToken (address _tokenOwner, address _tokenAddress) external;
    function tokenGeneratorsLength() external view returns (uint256);
}

contract MintGenerator is Ownable {
    
    IMintFactory public MINT_FACTORY;
    ITokenFees public TOKEN_FEES;
    
    constructor(address _mintFactory, address _tokenFees) {
        MINT_FACTORY = IMintFactory(_mintFactory);
        TOKEN_FEES = ITokenFees(_tokenFees);
    }
    
    /**
     * @notice Creates a new Token contract and registers it in the TokenFactory.sol.
     */
    
    function createToken (
      string memory name, 
      string memory symbol, 
      uint8 decimals, 
      uint256 totalSupply
      ) public payable {
          // Charge ETH fee for contract creation
        require(msg.value == TOKEN_FEES.getFlatFee(), 'FEE NOT MET');
        payable(TOKEN_FEES.getTokenFeeAddress()).transfer(TOKEN_FEES.getFlatFee());

        IERC20 newToken = new ENMT(name, symbol, decimals, payable(msg.sender), totalSupply);
        uint256 bal = newToken.balanceOf(address(this));
        uint256 tsFee = bal * TOKEN_FEES.getTotalSupplyFee() / 1000;
        newToken.transfer(TOKEN_FEES.getTokenFeeAddress(), tsFee);
        newToken.transfer(msg.sender, bal - tsFee);
        MINT_FACTORY.registerToken(msg.sender, address(newToken));
    }
}