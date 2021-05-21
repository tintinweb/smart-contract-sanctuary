/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//HIGH PRIORITY: SET THE MASTER ADDRESS WHEN YOU DEPLOY THIS FOR REAL. ALSO REMEMBER TO SET THE RECEIPT TOKEN ADDRESS
//WORKFLOW:
//1. DEPLOY TOKEN
//2. ENTER VAULT TOKEN ADDRESS IN VAULT CODE
//3. DEPLOY VAULT
//4. SET MASTER ADDRESS FOR TOKEN

//Etherscan web addresses are, for some reason, not case sensitive (maybe they cant be) but addresses are. that's a problem.

//Medium priority:
//Make all your private functions internal if it is cheaper or comparable on gas fees
//Is reentrancy guard necessary for sendViaCall?
//Should I enable optimization when compiling?

//Low priority:
//Get listed on CMC

interface IIndexToken {
    function totalSupply() external view returns (uint256);
    function mint(address _to, uint256 _value) external returns (bool success);
    function burnFrom(address _from, uint256 _value) external returns (bool success);
}

interface PortfolioToken {
    function balanceOf() external view returns (uint256);
}

interface IOracle {
    function latestAnswer() external view returns (uint256);
}

contract Vault 
{
    function deposit() public payable {
        address RECEIPT_TOKEN_ADDRESS = address(0xDf36d34F517Aa7b813937Aa5587c46ee2fdd1714);
        uint256 oldTokenSupply = getReceiptTokenTotalSupply(RECEIPT_TOKEN_ADDRESS); //this will be denominated in the smallest denomination of the new ERC-20 receipt token
        uint256 receiptTokensOwed;
        if (oldTokenSupply == 0) {
            receiptTokensOwed = 100000000000000000000; //This ensures that the first depositor gets some tokens.
        } else {
            uint256 depositValue = msg.value;
            uint256 newVaultValue = calculateValueOfVault();
            receiptTokensOwed = (depositValue * oldTokenSupply) / (newVaultValue - depositValue);
        }
        mint(msg.sender, receiptTokensOwed, RECEIPT_TOKEN_ADDRESS);
    }
    
    function withdraw(address payable customer, uint256 tokenValue, address RECEIPT_TOKEN_ADDRESS) private {
        uint256 weiOwed = (calculateValueOfVault() * tokenValue) / getReceiptTokenTotalSupply(RECEIPT_TOKEN_ADDRESS);
        if (IIndexToken(RECEIPT_TOKEN_ADDRESS).burnFrom(customer, tokenValue)) {
            sendViaCall(customer, weiOwed); //race condition possible here, esp. in regard to calculating wei owed too early
        }
    }
    
    function sendViaCall(address payable _to, uint256 amount) private {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent,) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    
    function receiveApproval(address payable _from, uint256 _value, address _token) external {
        withdraw(_from, _value, _token);
    }
    
    function mint(address customer, uint256 value, address RECEIPT_TOKEN_ADDRESS) private {
        IIndexToken(RECEIPT_TOKEN_ADDRESS).mint(customer, value); //consider adding events and figuring out how they work. Everything important needs to be broadcasted
    }
    
    function calculateValueOfVault() private view returns (uint256 currentValueOfVault) {
        address YFI_ORACLE = address(0xC5d1B1DEb2992738C0273408ac43e1e906086B6C); //Every address in this function is Kovan. Replace it with the actual addresses once you deploy to mainnet
        address MKR_ORACLE = address(0x0B156192e04bAD92B6C1C13cf8739d14D78D5701);
        address LINK_ORACLE = address(0x3Af8C569ab77af5230596Acf0E8c2F9351d24C38);
        address UNI_ORACLE = address(0x17756515f112429471F86f98D5052aCB6C47f6ee);
        uint256 YFI_ETH = IOracle(YFI_ORACLE).latestAnswer();
        uint256 MKR_ETH = IOracle(MKR_ORACLE).latestAnswer();
        uint256 LINK_ETH = IOracle(LINK_ORACLE).latestAnswer();
        uint256 UNI_ETH = IOracle(UNI_ORACLE).latestAnswer();
        uint256 YFI_IN_VAULT = 0; //change these values as you see fit for testing. we will need to use the token contracts to check the balance on mainnet
        uint256 MKR_IN_VAULT = 0;
        uint256 LINK_IN_VAULT = 0;
        uint256 UNI_IN_VAULT = 0;
        
        uint256 ETH_IN_VAULT = address(this).balance;
        return ETH_IN_VAULT + (YFI_ETH * YFI_IN_VAULT) + (MKR_ETH * MKR_IN_VAULT) + (LINK_ETH * LINK_IN_VAULT) + (UNI_ETH * UNI_IN_VAULT); 
    }
    
    function getReceiptTokenTotalSupply(address RECEIPT_TOKEN_ADDRESS) private view returns (uint256 totalSupply) {
        return IIndexToken(RECEIPT_TOKEN_ADDRESS).totalSupply();
    }
}