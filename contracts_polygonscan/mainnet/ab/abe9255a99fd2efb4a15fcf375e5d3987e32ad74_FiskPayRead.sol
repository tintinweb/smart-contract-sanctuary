//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./FiskPayWrite.sol";


contract FiskPayRead is FiskPayWrite{

    //Admin
    function ViewAdmin(uint8 _adminIndex) external view returns(address){
        
        if(projectAdmins.length <= _adminIndex){

            return address(0);
        }

        return projectAdmins[_adminIndex];
    }
    
    function CheckIfAdmin(address _adminAddress) external view returns(bool){
        
        for(uint8 i = 0; i < projectAdmins.length; i++){
            
            if(projectAdmins[i] == _adminAddress){
                
                return true;
            }
        }
        
        return false;
    }


    //Developer
    function ViewDeveloper(uint8 _developerIndex) external view returns(address){

        if(projectDevelopers.length <= _developerIndex){

            return address(0);
        }
        
        return projectDevelopers[_developerIndex];
    }
    
    function CheckIfDeveloper(address _developerAddress) external view returns(bool){
        
        for(uint8 i = 0; i < projectDevelopers.length; i++){
            
            if(projectDevelopers[i] == _developerAddress){
                
                return true;
            }
        }
        
        return false;
    }

    function CountDevelopers() external view returns(uint8){
        
        return numberOfDevelopers;
    }

    //Blacklist
    function CheckIfBlacklist(address _blacklistAddress) external view returns(bool){
        
        if(blacklistedAddresses[_blacklistAddress] == true){

            return true;
        }
        
        return false;
    }


    //Burn
    function ViewBurn(uint8 _burnIndex) external view returns(address){
        
        if(burnAddresses.length <= _burnIndex){

            return address(0);
        }

        return burnAddresses[_burnIndex];
    }

    function CheckIfBurn(address _burnAddress) external view returns(bool){
        
        for(uint8 i = 0; i < burnAddresses.length; i++){
            
            if(burnAddresses[i] == _burnAddress){
                
                return true;
            }
        }
        
        return false;
    } 


    //Trading   
    function GetTradingState() external view returns(bool){
        
        return canTradeTokens;
    }

    
    //Funding
    function GetFundBalance() external view returns(uint256){
        
        return totalFunding;
    }

    function GetNumberOfFunders() external view returns(uint8){
        
        return numberOfFunders;
    }

    //Tokens
    function ViewToken(uint8 _tokenIndex) external view returns(address){

        if(erc20Addresses.length <= _tokenIndex){

            return address(0);
        }
        
        return erc20Addresses[_tokenIndex];
    }

    function CheckIfTokenEnabled(address _tokenAddress) external view returns(bool){

        if(erc20Developer[_tokenAddress] != address(0)){

            if(erc20Expire[_tokenAddress] != 0){

                if(erc20Enabled[_tokenAddress] == true){

                    return true;
                }
            }
        }

        return false;
    }

    function CountTokens() external view returns(uint8){
        
        return numberOfTokens;
    }

    function GetTokenName(address _tokenAddress) external view returns(string memory){
        
        return erc20Name[_tokenAddress];
    }

    function GetTokenSymbol(address _tokenAddress) external view returns(string memory){
        
        return erc20Symbol[_tokenAddress];
    }

    function GetTokenDecimals(address _tokenAddress) external view returns(uint8){
        
        return erc20Decimals[_tokenAddress];
    }

    function GetTokenDeveloper(address _tokenAddress) external view returns(address){
        
        return erc20Developer[_tokenAddress];
    }

    function GetTokenExpiration(address _tokenAddress) external view returns(uint256){
        
        return erc20Expire[_tokenAddress];
    }

    function TokenSymbolToAddress(string memory _tokenSymbol) external view returns(address){
        
        return erc20SymbolToAddress[_tokenSymbol];
    }


    //Fisk Token
    function name() external pure returns (string memory){

        return tokenName;
    }

    function symbol() external pure returns (string memory){

        return tokenSymbol;
    }

    function decimals() external pure returns (uint8){

        return tokenDecimals;
    }
    
    function totalSupply() external view returns (uint256){
        
        return tokenTotalSupply;
    }

    function balanceOf(address _ownerAddress) external view returns (uint256){
        
        return balances[_ownerAddress];
    }

    function allowance(address _ownerAddress, address _delegateAddress) external view returns (uint256){
        
        return allowed[_ownerAddress][_delegateAddress];
    }


    //FiskPay Wallet
    function GetFiskPayWalletAddress() external view returns(address){

        return fiskWallet;
    }


    //Factory
    function GetFactoryAddress() external view returns(address){

        return walletFactory;
    }

    function CanCreateWallet(address _senderAddress) external view returns(bool){

        if(creatorExpireTimestamp[_senderAddress] <= block.timestamp || creatorExpireTimestamp[_senderAddress] == 0){

            return true;
        }

        return false;
    }


    //Customer Wallets
    function VerifyCustomerWallet(address _walletAddress) external view returns(bool){

        if(walletToOwner[_walletAddress] != address(0)){

            for(uint8 i = 0; i < ownerToWallets[walletToOwner[_walletAddress]].length; i++){

                if(ownerToWallets[walletToOwner[_walletAddress]][i] == _walletAddress){

                    return true;
                }
            }
        }

        return false;
    }

    function GetWalletContractOwner(address _walletAddress) external view returns(address){
        
        return walletToOwner[_walletAddress];
    }

    function GetWalletCreationTimestamp(address _walletAddress) external view returns(uint256){
        
        return walletCreationTimestamp[_walletAddress];
    }

    function GetOwnerWallet(address _ownerAddress, uint256 _ownerWalletIndex) external view returns(address){
        
        return ownerToWallets[_ownerAddress][_ownerWalletIndex];
    }

}