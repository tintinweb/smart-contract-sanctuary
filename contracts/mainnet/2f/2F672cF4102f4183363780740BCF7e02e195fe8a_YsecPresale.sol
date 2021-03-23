/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC20Timelock{
    function AllocationLength() external view returns (uint256);
    function AddAllocation(string memory name, uint256 amount, uint256 releaseDate, bool isInterval, uint256 percentageOfRelease, uint256 intervalOfRelease, address token) external;
    function WithdrawFromAllocation(string memory name) external;
}

/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC20TimelockFactory
{
    function CreateTimelock(address owner, address tokenOwner) external returns(address);
}

/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./TokenAllocation.sol";
import "./PresaleDataAddresses.sol";
import "./PresaleDataState.sol";
import "./PresaleInfo.sol";

struct PresaleData{
    PresaleInfo Info;
    uint256 StartDate;
    uint256 EndDate;
    uint256 Softcap;
    uint256 Hardcap;
    uint256 TokenLiqAmount;
    uint256 LiqPercentage;
    uint256 TokenPresaleAllocation;
    bool PermalockLiq;
    TokenAllocation[] TokenAllocations;// will not be returned in view of PresaleData
    TokenAllocation LiquidityTokenAllocation;
    PresaleDataAddresses Addresses;
    PresaleDataState State;
    mapping(address => uint256) EthContributedPerAddress;// will not be returned in view of PresaleData
    mapping(address => bool) ClaimedAddress;// will not be returned in view of PresaleData
}

/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

struct PresaleDataAddresses
{
    address TokenOwnerAddress;
    address TokenAddress;
    address TokenTimeLock;
}

/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

struct PresaleDataState{
    uint256 TotalTokenAmount;
    uint256 Step;
    uint256 ContributedEth;
    uint256 RaisedFeeEth;
    bool Exists;
    uint256 RetrievedTokenAmount;
    uint256 RetrievedEthAmount;
    uint256 NumberOfContributors;
}

/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

struct PresaleInfo{
    string Name;
    string Website;
    string Telegram;
    string Twitter;
    string Github;
    string Medium;
}

/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./TokenAllocation.sol";

struct PresaleSettings{
    string Name;
    uint256 StartDate;
    uint256 EndDate;
    uint256 Softcap;
    uint256 Hardcap;
    uint256 TokenLiqAmount;
    uint256 LiqPercentage;
    uint256 TokenPresaleAllocation;
    bool PermalockLiq;
    TokenAllocation[] TokenAllocations;
    TokenAllocation LiquidityTokenAllocation;
    address Token;
    string Website;
    string Telegram;
    string Twitter;
    string Github;
    string Medium;
}

/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

struct TokenAllocation
{
    string Name;
    uint256 Amount;
    uint256 RemainingAmount;
    uint256 ReleaseDate;
    bool IsInterval;
    uint256 PercentageOfRelease;
    uint256 IntervalOfRelease;
    bool Exists;
    address Token;
}

/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Models/PresaleData.sol";
import "./Models/PresaleSettings.sol";
import "./Interfaces/IERC20Timelock.sol";
import "./Interfaces/IERC20TimelockFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract YsecPresale is Ownable, ReentrancyGuard{
    using SafeMath for uint;

    //steps
    //0:initialized
    //1:Tokens transfered and ready for contributions
    //>1 presale finished
    //2:Tokens transfered to locks
    //3:Liquidity Added on Uni and ready for withdrawal
    //>3 tokens claimable and eth distributable

    address public UniswapRouterAddress;
    address public UniswapFactoryAddress;
    
    address public TimelockFactoryAddress;
    address public YieldFeeAddress;
    address public FeeAddress;

    mapping(uint256 => PresaleData) public Presales;
    uint256[] public PresaleIndexer;

    event TokensTransfered(uint256 presaleId, uint256 amount);
    event Contributed(uint256 presaleId, address contributor, uint256 amount);
    event RetrievedEth(uint256 presaleId, address contributor, uint256 amount);
    event RetrievedTokens(uint256 presaleId, uint256 amount);
    event TokensTransferedToLocks(uint256 presaleId, uint256 amount);
    event NoTokensTransferedToLocks(uint256 presaleId);
    event UniswapLiquidityAdded(uint256 presaleId, bool permaLockedLiq, uint256 amountOfEth, uint256 amountOfTokens);
    event ClaimedTokens(uint256 presaleId, address claimer, uint256 amount);
    event EthYieldFeeDistributed(uint256 presaleId, address reciever, uint256 amount);
    event EthFeeDistributed(uint256 presaleId, address reciever, uint256 amount);
    event EthDistributed(uint256 presaleId, address reciever, uint256 amount);

    constructor(address timelockFactoryAddress, address yieldFeeAddress, address feeAddress) public{
        UniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        UniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        TimelockFactoryAddress = timelockFactoryAddress;
        YieldFeeAddress = yieldFeeAddress;
        FeeAddress = feeAddress;
    }

    function SetTimelockFactory(address timelockFactoryAddress) onlyOwner() external{
        TimelockFactoryAddress = timelockFactoryAddress;
    }

    function SetYieldFeeAddress(address yieldFeeAddress) onlyOwner() external{
        YieldFeeAddress = yieldFeeAddress;
    }

    function SetFeeAddress(address feeAddress) onlyOwner() external{
        FeeAddress = feeAddress;
    }

    function SetUniswapRouterAddress(address router) onlyOwner() external{
        UniswapRouterAddress = router;
    }

    function SetUniswapFactoryAddress(address router) onlyOwner() external{
        UniswapFactoryAddress = router;
    }

    function CreatePresale(PresaleSettings memory settings) external returns(uint256 presaleId){
        require(settings.EndDate > settings.StartDate, "Do not start before end");
        require(settings.StartDate > block.timestamp, "Start in future");
        require(settings.Hardcap >= settings.Softcap, "Hardcap has to equal or exceed softcap");

        presaleId = PresaleIndexer.length.add(1);

        Presales[presaleId].StartDate = settings.StartDate;
        Presales[presaleId].EndDate = settings.EndDate;
        Presales[presaleId].Softcap = settings.Softcap;
        Presales[presaleId].Hardcap = settings.Hardcap;
        Presales[presaleId].TokenLiqAmount = settings.TokenLiqAmount;
        Presales[presaleId].LiqPercentage = settings.LiqPercentage;
        Presales[presaleId].TokenPresaleAllocation = settings.TokenPresaleAllocation;
        Presales[presaleId].PermalockLiq = settings.PermalockLiq;
        if(!settings.PermalockLiq) require(settings.LiquidityTokenAllocation.ReleaseDate > block.timestamp, "Liquidity allocation not set in future");
        Presales[presaleId].LiquidityTokenAllocation = settings.LiquidityTokenAllocation;

        Presales[presaleId].Addresses.TokenOwnerAddress = _msgSender();
        Presales[presaleId].Addresses.TokenAddress = settings.Token;
        Presales[presaleId].Addresses.TokenTimeLock = address(0x0);

        Presales[presaleId].State.TotalTokenAmount = 0;
        Presales[presaleId].State.Step = 0;
        Presales[presaleId].State.ContributedEth = 0;
        Presales[presaleId].State.RaisedFeeEth = 0;
        Presales[presaleId].State.Exists = true;
        Presales[presaleId].State.RetrievedTokenAmount = 0;
        Presales[presaleId].State.RetrievedEthAmount = 0;
        Presales[presaleId].State.NumberOfContributors = 0;

        Presales[presaleId].Info.Name = settings.Name;
        Presales[presaleId].Info.Website = settings.Website;
        Presales[presaleId].Info.Telegram = settings.Telegram;
        Presales[presaleId].Info.Twitter = settings.Twitter;
        Presales[presaleId].Info.Github = settings.Github;
        Presales[presaleId].Info.Medium = settings.Medium;

        Presales[presaleId].State.TotalTokenAmount = Presales[presaleId].State.TotalTokenAmount.add(settings.TokenLiqAmount);
        Presales[presaleId].State.TotalTokenAmount = Presales[presaleId].State.TotalTokenAmount.add(settings.TokenPresaleAllocation);
        for(uint i=0; i<settings.TokenAllocations.length; i++)
        {
            require(settings.TokenAllocations[i].ReleaseDate > block.timestamp, "Allocation not set in future");
            TokenAllocation memory allocation = settings.TokenAllocations[i];
            if(allocation.Token == Presales[presaleId].Addresses.TokenAddress) Presales[presaleId].State.TotalTokenAmount = Presales[presaleId].State.TotalTokenAmount.add(allocation.Amount);
            Presales[presaleId].TokenAllocations.push(allocation);
        }
        PresaleIndexer.push(presaleId);
    }

    //step 0 -> part of init
    function TransferTokens(uint256 presaleId) nonReentrant() RequireTokenOwner(presaleId) external{
        RequireStep(presaleId, 0);
        require(IERC20(Presales[presaleId].Addresses.TokenAddress).allowance(_msgSender(), address(this)) >= Presales[presaleId].State.TotalTokenAmount , "Transfer of token has not been approved");
        IERC20(Presales[presaleId].Addresses.TokenAddress).transferFrom(_msgSender(), address(this), Presales[presaleId].State.TotalTokenAmount);
        Presales[presaleId].State.Step = 1;
        emit TokensTransfered(presaleId, Presales[presaleId].State.TotalTokenAmount);
    }

    //step 1 -> contributions open
    function Contribute(uint256 presaleId) nonReentrant() public payable{
        RequireStep(presaleId, 1);
        require(msg.value > 0, "Cannot contribute 0");
        require(!PresaleFinished(presaleId), "Presale has already finished");
        require(PresaleStarted(presaleId), "Presale has not started yet!");

        uint256 amountRecieved = msg.value;
        require(Presales[presaleId].State.ContributedEth + amountRecieved <= Presales[presaleId].Hardcap, "Incoming contribution exceeds hardcap");
        Presales[presaleId].State.ContributedEth = Presales[presaleId].State.ContributedEth.add(amountRecieved);
        Presales[presaleId].State.RaisedFeeEth = Presales[presaleId].State.RaisedFeeEth.add(amountRecieved.div(100).mul(5));//5% is fee
        if(Presales[presaleId].EthContributedPerAddress[_msgSender()] == 0) Presales[presaleId].State.NumberOfContributors = Presales[presaleId].State.NumberOfContributors.add(1);
        Presales[presaleId].EthContributedPerAddress[_msgSender()] = Presales[presaleId].EthContributedPerAddress[_msgSender()].add(amountRecieved);
        emit Contributed(presaleId, _msgSender(), amountRecieved);
     }

    //step 1 -> in case of failed presale allow users to retrieve invested eth
    //https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now
    function RetrieveEth(uint256 presaleId, address contributor) nonReentrant() external{
        RequireStep(presaleId, 1);
        require(!SoftcapMet(presaleId), "Softcap has been met! you are not able to retrieve ETH");
        require(PresaleFinished(presaleId), "Presale has not finished! you are not able to retrieve ETH");

        uint256 ethContributedForAddress = Presales[presaleId].EthContributedPerAddress[contributor];
        require(ethContributedForAddress > 0, "No eth available for withdrawal");
        Presales[presaleId].EthContributedPerAddress[contributor] = 0;
        (bool success, ) = contributor.call{value:ethContributedForAddress}('');
        require(success, "Transfer failed.");
        emit RetrievedEth(presaleId, contributor, ethContributedForAddress);
    }

    //step 1 -> in case of failed presale allow tokenowner to retrieve tokens
    function RetrieveTokens(uint256 presaleId) RequireTokenOwner(presaleId) nonReentrant() external{
        RequireStep(presaleId, 1);
        require(!SoftcapMet(presaleId), "Softcap has been met! you are not able to retrieve ETH");
        require(PresaleFinished(presaleId), "Presale has not finished! you are not able to retrieve ETH");
        
        uint256 remainingAmount = Presales[presaleId].State.TotalTokenAmount.sub(Presales[presaleId].State.RetrievedTokenAmount);
        require(remainingAmount > 0, "No remaining tokens for retrieval");
        uint256 balance = IERC20(Presales[presaleId].Addresses.TokenAddress).balanceOf(address(this));
        require(balance >= remainingAmount, "No tokens left!");

        Presales[presaleId].State.RetrievedTokenAmount = Presales[presaleId].State.RetrievedTokenAmount.add(remainingAmount);
        IERC20(Presales[presaleId].Addresses.TokenAddress).transfer(_msgSender(), remainingAmount);
        emit RetrievedTokens(presaleId, remainingAmount);
    }

    //step 1 -> transfer tokens to allocated locks in preperation for step 2 
    function TransferTokensToLocks(uint256 presaleId) nonReentrant() external{
        RequireStep(presaleId, 1);
        require(SoftcapMet(presaleId), "Softcap has not been met!");
        require(PresaleFinished(presaleId), "Presale has not finished!");
        //create timelock
        Presales[presaleId].Addresses.TokenTimeLock = IERC20TimelockFactory(TimelockFactoryAddress).CreateTimelock(address(this), Presales[presaleId].Addresses.TokenOwnerAddress);

        if(Presales[presaleId].State.TotalTokenAmount.sub(Presales[presaleId].TokenPresaleAllocation).sub(Presales[presaleId].TokenLiqAmount) == 0){
            Presales[presaleId].State.Step = 2;
            emit NoTokensTransferedToLocks(presaleId);
        }else{
            //approve all tokens except used for presale and liq
            IERC20(Presales[presaleId].Addresses.TokenAddress).approve(Presales[presaleId].Addresses.TokenTimeLock, Presales[presaleId].State.TotalTokenAmount.sub(Presales[presaleId].TokenPresaleAllocation).sub(Presales[presaleId].TokenLiqAmount));
            //create and transfer allocations
            for(uint i=0; i<Presales[presaleId].TokenAllocations.length; i++)
            {
                IERC20Timelock(Presales[presaleId].Addresses.TokenTimeLock).AddAllocation(Presales[presaleId].TokenAllocations[i].Name, Presales[presaleId].TokenAllocations[i].Amount, Presales[presaleId].TokenAllocations[i].ReleaseDate, Presales[presaleId].TokenAllocations[i].IsInterval, Presales[presaleId].TokenAllocations[i].PercentageOfRelease, Presales[presaleId].TokenAllocations[i].IntervalOfRelease, Presales[presaleId].Addresses.TokenAddress);
            }
            Presales[presaleId].State.Step = 2;
            emit TokensTransferedToLocks(presaleId, Presales[presaleId].State.TotalTokenAmount.sub(Presales[presaleId].TokenPresaleAllocation).sub(Presales[presaleId].TokenLiqAmount));
        }
    }

    //step 2 -> add liquidity to uniswap in preperation for step 3
    function AddUniswapLiquidity(uint256 presaleId) nonReentrant() external{
        RequireStep(presaleId, 2);
        IERC20(Presales[presaleId].Addresses.TokenAddress).approve(UniswapRouterAddress, Presales[presaleId].TokenLiqAmount);//approve unirouter
        uint256 amountOfEth = Presales[presaleId].State.ContributedEth.sub(Presales[presaleId].State.RaisedFeeEth).div(100).mul(Presales[presaleId].LiqPercentage);
        if(Presales[presaleId].PermalockLiq)//permanently locked liq
        {
            IUniswapV2Router02(UniswapRouterAddress).addLiquidityETH{value : amountOfEth}(address(Presales[presaleId].Addresses.TokenAddress), Presales[presaleId].TokenLiqAmount, 0, 0, address(0x000000000000000000000000000000000000dEaD), block.timestamp.add(1 days));
        }
        else// use allocation for locking
        {
            IUniswapV2Router02(UniswapRouterAddress).addLiquidityETH{value : amountOfEth}(address(Presales[presaleId].Addresses.TokenAddress), Presales[presaleId].TokenLiqAmount, 0, 0, address(this), block.timestamp.add(1 days));
            address pairAddress = IUniswapV2Factory(UniswapFactoryAddress).getPair(IUniswapV2Router02(UniswapRouterAddress).WETH(), Presales[presaleId].Addresses.TokenAddress);
            IERC20(pairAddress).approve(Presales[presaleId].Addresses.TokenTimeLock, IERC20(pairAddress).balanceOf(address(this)));
            IERC20Timelock(Presales[presaleId].Addresses.TokenTimeLock).AddAllocation(Presales[presaleId].LiquidityTokenAllocation.Name, IERC20(pairAddress).balanceOf(address(this)), Presales[presaleId].LiquidityTokenAllocation.ReleaseDate, Presales[presaleId].LiquidityTokenAllocation.IsInterval, Presales[presaleId].LiquidityTokenAllocation.PercentageOfRelease, Presales[presaleId].LiquidityTokenAllocation.IntervalOfRelease, pairAddress);
        }
        Presales[presaleId].State.RetrievedEthAmount = Presales[presaleId].State.RetrievedEthAmount.add(amountOfEth);
        Presales[presaleId].State.Step = 3;
        emit UniswapLiquidityAdded(presaleId, Presales[presaleId].PermalockLiq, amountOfEth, Presales[presaleId].TokenLiqAmount);
    }

    //step 3 -> claim tokens for presale contributors
    function ClaimTokens(uint256 presaleId) nonReentrant() external{
        RequireStep(presaleId, 3);
        require(Presales[presaleId].EthContributedPerAddress[_msgSender()] > 0, "No contributions for address");
        require(Presales[presaleId].ClaimedAddress[_msgSender()] == false, "Already claimed for address");

        uint256 amountToSend = Presales[presaleId].EthContributedPerAddress[_msgSender()].mul(Presales[presaleId].TokenPresaleAllocation).div(Presales[presaleId].State.ContributedEth);
        Presales[presaleId].ClaimedAddress[_msgSender()] = true;
        IERC20(Presales[presaleId].Addresses.TokenAddress).transfer(_msgSender(), amountToSend);
        emit ClaimedTokens(presaleId, _msgSender(), amountToSend);
    }

    //step 3 -> distribute eth to presale host and fees to ysec
    function DistributeEth(uint256 presaleId) nonReentrant() external{
        RequireStep(presaleId, 3);
        require(Presales[presaleId].State.ContributedEth.sub(Presales[presaleId].State.RetrievedEthAmount) > 0, "No eth left to distribute");
        
        (bool successDiv, ) = YieldFeeAddress.call{value: Presales[presaleId].State.RaisedFeeEth.div(2)}('');
        require(successDiv, "Transfer to yield fee address failed.");
        Presales[presaleId].State.RetrievedEthAmount = Presales[presaleId].State.RetrievedEthAmount.add(Presales[presaleId].State.RaisedFeeEth.div(2));
        (bool successFee, ) = FeeAddress.call{value: Presales[presaleId].State.RaisedFeeEth.div(2)}('');
        require(successFee, "Transfer to fee address failed.");
        Presales[presaleId].State.RetrievedEthAmount = Presales[presaleId].State.RetrievedEthAmount.add(Presales[presaleId].State.RaisedFeeEth.div(2));
        uint256 amountSendToOwner = Presales[presaleId].State.ContributedEth.sub(Presales[presaleId].State.RetrievedEthAmount);
        (bool successOwner, ) = Presales[presaleId].Addresses.TokenOwnerAddress.call{value: amountSendToOwner}('');
        require(successOwner, "Transfer to owner failed.");
        Presales[presaleId].State.RetrievedEthAmount = Presales[presaleId].State.RetrievedEthAmount.add(amountSendToOwner);

        emit EthYieldFeeDistributed(presaleId, YieldFeeAddress, Presales[presaleId].State.RaisedFeeEth.div(2));
        emit EthFeeDistributed(presaleId, FeeAddress, Presales[presaleId].State.RaisedFeeEth.div(2));
        emit EthDistributed(presaleId, Presales[presaleId].Addresses.TokenOwnerAddress, amountSendToOwner);
    }

    modifier RequireTokenOwner(uint256 presaleId){
        ValidPresale(presaleId);
        require(Presales[presaleId].Addresses.TokenOwnerAddress == _msgSender(), "Sender is not owner of tokens!");
        _;
    }

    function PresaleStarted(uint256 presaleId) public view returns(bool){
        return Presales[presaleId].State.Step > 0 && Presales[presaleId].StartDate <= block.timestamp && !PresaleFinished(presaleId);
    }

     function PresaleFinished(uint256 presaleId) public view returns(bool){
        return HardcapMet(presaleId) || Presales[presaleId].EndDate <= block.timestamp;
    }

    function SoftcapMet(uint256 presaleId) public view returns (bool){
        return Presales[presaleId].State.ContributedEth >= Presales[presaleId].Softcap;
    }

    function HardcapMet(uint256 presaleId) public view returns (bool){
        return Presales[presaleId].State.ContributedEth >= Presales[presaleId].Hardcap;
    }

    function RequireStep(uint256 presaleId, uint256 step) private{
        require(Presales[presaleId].State.Step == step, "Required step is not active!");
    }

    function ValidPresale(uint256 presaleId) private{
        require(Presales[presaleId].State.Exists, "Presale does not exist");
    }
    
    function PresaleIndexerLength() public view returns(uint256){
        return PresaleIndexer.length;
    }

    function GetTokenAllocations(uint256 presaleId) public view returns(TokenAllocation[] memory){
        TokenAllocation[] memory result = new TokenAllocation[](Presales[presaleId].TokenAllocations.length);
        for(uint i=0; i< Presales[presaleId].TokenAllocations.length; i++)
        {
            TokenAllocation storage allocation = Presales[presaleId].TokenAllocations[i];
            result[i] = allocation;
        }
        return result;
    }

    function GetEthContributedForAddress(uint256 presaleId, address forAddress) public view returns(uint256){
        return Presales[presaleId].EthContributedPerAddress[forAddress];
    }

    function GetAmountOfTokensForAddress(uint256 presaleId, address forAddress) public view returns(uint256){
        return Presales[presaleId].EthContributedPerAddress[forAddress].mul(Presales[presaleId].TokenPresaleAllocation).div(Presales[presaleId].State.ContributedEth);
    }

    function GetHardcapAmountOfTokensForAddress(uint256 presaleId, address forAddress) public view returns(uint256){
        return Presales[presaleId].EthContributedPerAddress[forAddress].mul(Presales[presaleId].TokenPresaleAllocation).div(Presales[presaleId].Hardcap);
    }

    function GetRatio(uint256 presaleId) public view returns(uint256){
        uint256 oneEth = 1000000000000000000;
        return oneEth.mul(Presales[presaleId].TokenPresaleAllocation).div(Presales[presaleId].State.ContributedEth);
    }

    function GetNumberOfContributors(uint256 presaleId) public view returns(uint256){
        return Presales[presaleId].State.NumberOfContributors;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}