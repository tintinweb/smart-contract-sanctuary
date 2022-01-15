pragma solidity^0.8.0;
//SPDX-License-Identifier:MIT
import "./IERC20.sol"; 
import "./IERC721.sol";
/*
███╗   ███╗███████╗████████╗ █████╗  ██████╗  █████╗ ███╗   ███╗███████╗███████╗██████╗  █████╗  ██████╗███████╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝
██╔████╔██║█████╗     ██║   ███████║██║  ███╗███████║██╔████╔██║█████╗  ███████╗██████╔╝███████║██║     █████╗  
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝  
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗███████║██║     ██║  ██║╚██████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝
                                                                                                                
                        ███████╗ █████╗ ██╗     ███████╗    ████████╗███████╗ ██████╗██╗  ██╗                   
                        ██╔════╝██╔══██╗██║     ██╔════╝    ╚══██╔══╝██╔════╝██╔════╝██║  ██║                   
                        ███████╗███████║██║     █████╗         ██║   █████╗  ██║     ███████║                   
                        ╚════██║██╔══██║██║     ██╔══╝         ██║   ██╔══╝  ██║     ██╔══██║                   
                        ███████║██║  ██║███████╗███████╗       ██║   ███████╗╚██████╗██║  ██║                   
                        ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝       ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝   

                                Technology developed by the MetaGameSpace team.

    Website- https://metagamespace.net
    Telegram- https://t.me/metagamespace    
    Twitter- https://twitter.com/metagamespace            
                                                                                                                                                                                                                          
*/

contract DirectPrivate
{
    IERC20 token;
    IERC721 nft;
    address public owner;
    bool public tokenSet;
    uint public ratePerBNB;
    bool public rateImplemented;
    address public contractAddress;
    uint public contractTBalance;
    bool public amountVerified;
    address payable public ceoAddress;    
    bool public saleStarted;
    uint public amountSentIn;
    mapping(address=>uint) public addressTotalSentValue;
    mapping(address=>bool) public addressFilledCompletely;
    mapping(address=>uint) public addressTotalRawValue;
    mapping(address=>uint) public addressTotalTokenValue;
    mapping(address=>uint) public addressInWeiValue;
    uint public minimumContribution;
    uint public maximumContribution;
    bool public transferSuccessful;
    bool public nftsEnabled;
    uint public nftMintCount; //Set it at Maximum 100
    address public nftCAddress;
    bool public nftCAddressSet;
    uint public cNFTBalance;
    bool public nftVerified;
    bool public nftTransferStarted;
    uint public nftAmountCap;
    bool public nftCapSet;
    mapping(address=>uint) public numberOfNftsMinted;
    uint public minimumForNFT;
    constructor() public
    {
        token= IERC20(0x87106b92E5DE4975EBd694a9A83aDd0dF43e8714);
        nft= IERC721(0xfe2C42c6bFF0Cb3a2a82cf40E35a1aE10DBac5F0);
        owner=msg.sender;
        contractAddress=address(this);
        amountVerified=false;
        contractTBalance=token.balanceOf(contractAddress);
        ceoAddress=payable(0x5ABCBa326711288410537D8b9d9bdFCa17c7983E);
        saleStarted=false;
        nftMintCount=0;
        nftCAddressSet=false;
        cNFTBalance=0;
        nftTransferStarted=false;
        minimumForNFT=500;
    }

    modifier onlyDeveloper
    {
        require(owner==msg.sender,"The caller should be the Developer");
        _;
    }
    modifier tDetailsSet
    {
        require(tokenSet==true,"The Details needs to be set yet");
        _;
    }
    modifier rateSet
    {
        require(rateImplemented==true,"The rate needs to be set yet");
        _;
    }
    modifier amountHasBeenVerified
    {
        require(amountVerified,"The amount has not been verified, please send and recheck");
        _;
    }
    modifier saleStartedSuccessfully
    {
        require(saleStarted==true,"Please wait for the start");
        _;
    }
    modifier nftHasBeenEnabled
    {
        require(nftsEnabled,"The NFT option has not be set to true yet.");
        _;
    }
    modifier nftContractAddressSet
    {
        require(nftCAddressSet,"The Contract Address for NFT has been set");
        _;
    }
    modifier nftHasBeenVerified
    {
        require(nftVerified,"The amount of NFTs have not been verified");
        _;
    }
    modifier nftCapHasBeenSet
    {
        require(nftCapSet,"The NFT Cap needs to be set yet");
        _;
    }
    function _setTokenContract(address tokenContract) public onlyDeveloper
    {
        token= IERC20(tokenContract);
        tokenSet=true;
        contractTBalance=token.balanceOf(contractAddress);
        //Token Contract Set.
    }
    function _setSaleRate(uint rate) public onlyDeveloper tDetailsSet
    {
        ratePerBNB=rate*10**9;
        rateImplemented=true;
        contractTBalance=token.balanceOf(contractAddress);
    }
    function refreshContractbalance() public returns(uint)
    {
        contractTBalance=token.balanceOf(contractAddress);
        return token.balanceOf(contractAddress);
    }
    function  resetDetails(bool option) public 
    {
        if(option==true)
        {
        token=IERC20(0x87106b92E5DE4975EBd694a9A83aDd0dF43e8714);
        tokenSet=false;
        rateImplemented=false;
        amountVerified=false;
        saleStarted=false;
        }
        else
        {
            //Don't reset.
        }
    }
    function pause_Execution(bool option) public
    {
        if(option==true)
        {
            saleStarted=false;
            //Execution paused temporarily
        }
        else if(option==false)
        {
            saleStarted=true;
            //Execution Resumed Successfully.
        }
    }
    function _verifyAmountSentIn(uint tokensSentIn) public onlyDeveloper rateSet
    {
        amountSentIn=tokensSentIn *10**9;
        contractTBalance=token.balanceOf(contractAddress);
        if(contractTBalance==amountSentIn)
        {
            amountVerified=true;
           
        }
        else
        {
            amountVerified=false;
        }
        require(amountVerified==true,"The tokens sent amount is not verified, send and recheck");
    }
    function _MinMaxContribution(uint min, uint max) public onlyDeveloper amountHasBeenVerified
    {
        saleStarted=true;
        //Set the rates according to 1 BNB= 1000, 0.1 BNB=100 and so on.
        minimumContribution=min;
        maximumContribution=max;
        //Convert the values into wei
    }
    function nft_Enabled(bool option) public onlyDeveloper
    {
        nftsEnabled=option;
        //Start counter for the first 100 transfers.
    }
    function nft_Contract(address nftAddress) public onlyDeveloper nftHasBeenEnabled 
    {
        //nftCAddress=nftAddress;
        nft= IERC721(nftAddress);
        cNFTBalance=nft.balanceOf(contractAddress);
        //The NFT Contract has been set now.
        nftCAddressSet=true;
    }
    function nft_VerifyNftMints(uint nftMintAmount) public onlyDeveloper nftContractAddressSet
    {
        cNFTBalance=nft.balanceOf(contractAddress);
        if(cNFTBalance==nftMintAmount)
        {
            nftVerified=true;
            //The amount has been verified.
        }
        else
        {
            nftVerified=false;
        }
        require(nftVerified,"The amount of NFTs have not been verified.");
    }
     function nft_dSetNFTAmountCap(uint NFTcap) public onlyDeveloper nftHasBeenVerified
    {
        nftAmountCap=NFTcap;
        nftCapSet=true;
    }
    function nft_StartNFTTransfer(bool option) public onlyDeveloper nftCapHasBeenSet
    {
        nftTransferStarted=option; //The main executor of code.
    }
    function nft_weiSendMinimum(uint amount) public onlyDeveloper
    {
        minimumForNFT=amount;
    }
   
    uint public sentAmount;
    uint public sentInWei;
    uint public tokensBought;
    receive() external payable
    {
        sentAmount=msg.value;
        sentInWei=sentAmount/10**15;
        ceoAddress.transfer(msg.value);
        addressFilledCompletely[msg.sender]=false;
        require(rateImplemented==true,"The rate has not been set yet.");
        require(saleStarted==true,"The sale has not been started yet.");
        require(sentInWei>=minimumContribution && sentInWei<=maximumContribution,"The sent amount is not in range. Kindly recheck");
        
        addressTotalRawValue[msg.sender]+=msg.value;
        addressInWeiValue[msg.sender]=addressTotalRawValue[msg.sender]/10**15;
        if(addressInWeiValue[msg.sender]>maximumContribution)
        {
            addressFilledCompletely[msg.sender]=true;
            addressTotalRawValue[msg.sender]-=msg.value;
        }
        require(addressFilledCompletely[msg.sender]!=true,"The address is exceeding the maximum participating amount.");
        contractTBalance=token.balanceOf(contractAddress);
        tokensBought=(sentInWei*ratePerBNB)/1000;
        require(tokensBought<=contractTBalance,"The contract Balance needs to be filled. Contact the Developer");
        token.transfer(msg.sender,tokensBought);
        addressTotalTokenValue[msg.sender]+=tokensBought;
        if(nftsEnabled)
        {
            if(nftTransferStarted)
            {
                if(nftMintCount<nftAmountCap)
                {
                    if(numberOfNftsMinted[msg.sender]==0 )
                    {
                        if(sentInWei>=minimumForNFT)
                        {
                        nft.transferFrom(contractAddress,msg.sender,nftMintCount);
                        nftMintCount++;
                        numberOfNftsMinted[msg.sender]++;
                        }
                        else
                        {
                            return;
                        }
                    }
                    else if(numberOfNftsMinted[msg.sender]!=0)
                    {
                        // //Transfer only Tokens
                        //  transferSuccessful=true;
                        // //Swap Successful.
                        // if(transferSuccessful)
                        // {
                        //     addressTotalSentValue[msg.sender]+=msg.value;
                        // }
                        // else
                        // {
                        //      //Continue.
                        // }
                        //The above code was adding the amount to it again as the tokens are being transferred before the process.
                        return;
                    }
                }
                else
                {
                    //Cap has been set as small.
                }
            }
        }
        transferSuccessful=true;
        //Swap Successful.
        if(transferSuccessful)
        {
            addressTotalSentValue[msg.sender]+=msg.value;
        }
        else
        {
            //Continue.
        }

    }
}