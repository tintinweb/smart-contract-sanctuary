/**
 *Submitted for verification at polygonscan.com on 2022-01-13
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


interface FiskPayWalletInterface{

    //Admin
    function CheckIfAdmin(address _adminAddress) external view returns(bool);

    //Developer
    function ViewDeveloper(uint8 _developerIndex) external view returns(address);
    function CountDevelopers() external view returns(uint8);

    //Tokens
    function ViewToken(uint8 _tokenIndex) external view returns(address);
    function CheckIfTokenEnabled(address _tokenAddress) external view returns(bool);
    function CountTokens() external view returns(uint8);
    function GetTokenDeveloper(address _tokenAddress) external view returns(address);

    function RefreshToken(address _tokenAddress) external returns(bool);
    function TokenExpired(address _tokenAddress) external returns(bool);

    //ERC20 Token Interface
    function symbol() external pure returns (string memory);
    function balanceOf(address _tokenOwner) external view returns (uint256);
    function allowance(address _owner, address _delegate) external view returns (uint256);

    function approve(address _delegate, uint256 _tokenAmount) external returns(bool);
    function transfer(address _receiverAddress, uint256 _tokenAmount) external returns(bool);
    function transferFrom(address _ownerAddress, address _receiverAddress, uint256 _tokenAmount) external returns(bool);

    //FiskPay Wallet
    function GetFiskPayWalletAddress() external view returns(address);

    //Customer Wallets
    function VerifyCustomerWallet(address _walletAddress) external view returns(bool);
}

contract FiskpayWallet{

    address constant private fiskPayAddress = 0xaBE9255A99fd2EFB4a15fcF375E5D3987E32Ad74;

    FiskPayWalletInterface constant private fisk = FiskPayWalletInterface(fiskPayAddress);

    uint256 private checkBlock = block.number;

    event Message(string message);
    event Reverted(string symbol, string text, string error);

    function FiskPayWithdraw() external returns(bool){

        require(fisk.CheckIfAdmin(msg.sender));
        require(fisk.CountDevelopers() > 0);

        require(checkBlock < block.number);
        checkBlock = block.number;

        uint8 devCount = fisk.CountDevelopers();
        uint8 tokenCount = fisk.CountTokens();

        if(fisk.balanceOf(address(this)) >= 1000000){

            uint256 burnTokens = (fisk.balanceOf(address(this)) * 9) / 1000;
            uint256 devTokens = (fisk.balanceOf(address(this)) - burnTokens) / uint256(devCount);

            try fisk.transfer(fiskPayAddress, burnTokens) returns (bool success){

                if(success){

                    for(uint8 i = 0; i < devCount; i++){

                        fisk.transfer(fisk.ViewDeveloper(i), devTokens);
                    }
                }
            }
            catch Error(string memory reason){

                emit Reverted(fisk.symbol()," withdrawal failed! Reason: ", reason);
            }
        }

        for(uint8 i = 1; i < tokenCount; i++){

            address tokenAddress = fisk.ViewToken(i);
            FiskPayWalletInterface token = FiskPayWalletInterface(tokenAddress);

            if(fisk.CheckIfTokenEnabled(tokenAddress)){

                if(token.balanceOf(address(this)) >= 1000000){

                    uint256 payTokens = (token.balanceOf(address(this)) * 15) / 100;
                    uint256 devTokens = (token.balanceOf(address(this)) - payTokens) / uint256(devCount);

                    try token.transfer(fisk.GetTokenDeveloper(tokenAddress), payTokens) returns (bool success){

                        if(success){

                            for(uint8 j = 0; j < devCount; j++){

                                token.transfer(fisk.ViewDeveloper(j), devTokens);
                            }

                            try fisk.TokenExpired(tokenAddress) returns(bool expired){

                                if(!expired){

                                    fisk.RefreshToken(tokenAddress);
                                }
                            }
                            catch Error(string memory reason){

                                emit Reverted(token.symbol()," expire check failed! Reason: ", reason);
                            }
                        }
                    }
                    catch Error(string memory reason){

                        emit Reverted(token.symbol()," withdrawal failed! Reason: ", reason);
                    }
                }
            }
            else{

                try fisk.TokenExpired(tokenAddress){}
                catch{}
            }
        }

        if(address(this).balance >= 1000000){

            uint256 devCoins = address(this).balance / uint256(devCount);

            (bool sent,) = payable(fisk.ViewDeveloper(0)).call{value : devCoins}("");
            
            if(sent){

                for(uint8 i = 1; i < devCount; i++){

                    payable(fisk.ViewDeveloper(i)).call{value : devCoins}("");
                }
            }

        }

        emit Message("Funds Withdrawn");
        
        return true;
    }

    function TokenDonation(address _tokenAddress, uint256 _tokenAmount) external returns(bool){

        require(fisk.GetFiskPayWalletAddress() == address(this), "Deprecated donation button");
        require(fisk.CheckIfTokenEnabled(_tokenAddress), "Token not enabled to payment system");

        FiskPayWalletInterface token = FiskPayWalletInterface(_tokenAddress);

        require(token.allowance(msg.sender, address(this)) >= _tokenAmount, "You must approve the token, before paying");
        require(token.balanceOf(msg.sender) >= _tokenAmount, "Not enough tokens");

        uint256 previousBlance = token.balanceOf(msg.sender);

        require(token.transferFrom(msg.sender, address(this), _tokenAmount), "Tokens could not be transfered");
        require(previousBlance == (token.balanceOf(msg.sender) + _tokenAmount), "Balance missmatch. Contact a FiskPay developer");

        emit Message("Donation Sent");
        
        return true;
    }

    function CoinDonation(uint256 _amount) external payable returns(bool){

        require(fisk.GetFiskPayWalletAddress() == address(this), "Deprecated donation button");
        require(_amount == msg.value, "Amount security check errored");

        emit Message("Donation Sent");
        
        return true;
    }

    receive() external payable{

        require(fisk.VerifyCustomerWallet(msg.sender));
    }

    fallback() external payable{
        
        require(fisk.VerifyCustomerWallet(msg.sender));
    }
}