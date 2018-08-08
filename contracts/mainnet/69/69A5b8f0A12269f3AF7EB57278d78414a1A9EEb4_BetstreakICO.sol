pragma solidity ^0.4.11;


// **-----------------------------------------------
// Betstreak Token sale contract
// Revision 1.1
// Refunds integrated, full test suite passed
// **-----------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
// -------------------------------------------------
// ICO configuration:
// Presale Bonus      +30% = 1,300 BST   = 1 ETH       [blocks: start   -> s+25200]
// First Week Bonus   +20% = 1,200 BST  = 1 ETH       [blocks: s+3601  -> s+50400]
// Second Week Bonus  +10% = 1,100 BST  = 1 ETH       [blocks: s+25201 -> s+75600]
// Third Week Bonus   +5% = 1,050 BST   = 1 ETH       [blocks: s+50401 -> s+100800]
// Final Week         +0% = 1,000 BST   = 1 ETH       [blocks: s+75601 -> end]
// -------------------------------------------------

contract owned {
    address public owner;
  
	
    function owned() {
        owner = msg.sender;
        
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract safeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    safeAssert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    safeAssert(b > 0);
    uint256 c = a / b;
    safeAssert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    safeAssert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    safeAssert(c>=a && c>=b);
    return c;
  }

  function safeAssert(bool assertion) internal {
    if (!assertion) revert();
  }
}

contract StandardToken is owned, safeMath {
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BetstreakICO is owned, safeMath {
    
  // owner/admin & token reward
  address        public admin = owner;      // admin address
  StandardToken  public tokenReward;        // address of the token used as reward
  

  // deployment variables for static supply sale
  uint256 public initialSupply;

  uint256 public tokensRemaining;

  // multi-sig addresses and price variable
  address public beneficiaryWallet;
  // beneficiaryMultiSig (founder group) or wallet account, live is 0x361e14cC5b3CfBa5D197D8a9F02caf71B3dca6Fd
  
  
  uint256 public tokensPerEthPrice;                           // set initial value floating priceVar 1,300 tokens per Eth

  // uint256 values for min,max,caps,tracking
  uint256 public amountRaisedInWei;                           //
  uint256 public fundingMinCapInWei;                          //

  // loop control, ICO startup and limiters
  string  public CurrentStatus                   = "";        // current crowdsale status
  uint256 public fundingStartBlock;                           // crowdsale start block#
  uint256 public fundingEndBlock;                             // crowdsale end block#
  bool    public isCrowdSaleClosed               = false;     // crowdsale completion boolean
  bool    public areFundsReleasedToBeneficiary   = false;     // boolean for founders to receive Eth or not
  bool    public isCrowdSaleSetup                = false;     // boolean for crowdsale setup

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Buy(address indexed _sender, uint256 _eth, uint256 _BST);
  event Refund(address indexed _refunder, uint256 _value);
  event Burn(address _from, uint256 _value);
  mapping(address => uint256) balancesArray;
  mapping(address => uint256) fundValue;

  // default function, map admin
  function BetstreakICO() onlyOwner {
    admin = msg.sender;
    CurrentStatus = "Crowdsale deployed to chain";
  }

  // total number of tokens initially
  function initialBSTSupply() constant returns (uint256 tokenTotalSupply) {
      tokenTotalSupply = safeDiv(initialSupply,100); 
  }

  // remaining number of tokens
  function remainingSupply() constant returns (uint256 tokensLeft) {
      tokensLeft = tokensRemaining;
  }

  // setup the CrowdSale parameters
  function SetupCrowdsale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) onlyOwner returns (bytes32 response) {
      
      if ((msg.sender == admin)
      && (!(isCrowdSaleSetup))  
      && (!(beneficiaryWallet > 0))){
      
          // init addresses
          tokenReward                             = StandardToken(0xA7F40CCD6833a65dD514088F4d419Afd9F0B0B52);  
          
          
          
          beneficiaryWallet                       = 0x361e14cC5b3CfBa5D197D8a9F02caf71B3dca6Fd;
          
         
          tokensPerEthPrice                       = 1300;                                         
          // set day1 initial value floating priceVar 1,300 tokens per Eth

          // funding targets
          fundingMinCapInWei                      = 1000000000000000000000;                          
          //300000000000000000000 =  1000 Eth (min cap) - crowdsale is considered success after this value  
          //testnet 5000000000000000000 = 5Eth


          // update values
          amountRaisedInWei                       = 0;
          initialSupply                           = 20000000000;                                      
          //   200,000,000 + 2 decimals = 200,000,000,00 
          //testnet 1100000 = 11,000
          
          tokensRemaining                         = safeDiv(initialSupply,100);

          fundingStartBlock                       = _fundingStartBlock;
          fundingEndBlock                         = _fundingEndBlock;

          // configure crowdsale
          isCrowdSaleSetup                        = true;
          isCrowdSaleClosed                       = false;
          CurrentStatus                           = "Crowdsale is setup";

          //gas reduction experiment
          setPrice();
          return "Crowdsale is setup";
          
      } else if (msg.sender != admin) {
          return "not authorized";
          
      } else  {
          return "campaign cannot be changed";
      }
    }

    
    
    function SetupPreSale(bool _isCrowdSaleSetup) onlyOwner returns (bytes32 response) {
      
      if ((msg.sender == admin))
      {
      isCrowdSaleSetup = _isCrowdSaleSetup;
          
      return "Executed.";
          
        }
    }
    


    function setPrice() {
        
        // ICO configuration:
        // Presale Bonus      +30% = 1,300 BST   = 1 ETH       [blocks: start   -> s+25200]
        // First Week Bonus   +20% = 1,200 BST  = 1 ETH       [blocks: s+25201  -> s+50400]
        // Second Week Bonus  +10% = 1,100 BST  = 1 ETH       [blocks: s+50401 -> s+75600]
        // Third Week Bonus   +5% = 1,050 BST   = 1 ETH       [blocks: s+75601 -> s+100800]
        // Final Week         +0% = 1,000 BST   = 1 ETH       [blocks: s+100801 -> end]
        
      if (block.number >= fundingStartBlock && block.number <= fundingStartBlock+25200) { 
          // Presale Bonus      +30% = 1,300 BST   = 1 ETH       [blocks: start   -> s+25200]
          
        tokensPerEthPrice=1300;
        
      } else if (block.number >= fundingStartBlock+25201 && block.number <= fundingStartBlock+50400) { 
          // First Week Bonus   +20% = 1,200 BST  = 1 ETH       [blocks: s+25201  -> s+50400]
          
        tokensPerEthPrice=1200;
        
      } else if (block.number >= fundingStartBlock+50401 && block.number <= fundingStartBlock+75600) { 
          // Second Week Bonus  +10% = 1,100 BST  = 1 ETH       [blocks: s+50401 -> s+75600]
          
        tokensPerEthPrice=1100;
        
      } else if (block.number >= fundingStartBlock+75601 && block.number <= fundingStartBlock+100800) { 
          // Third Week Bonus   +5% = 1,050 BST   = 1 ETH       [blocks: s+75601 -> s+100800]
          
        tokensPerEthPrice=1050;
        
      } else if (block.number >= fundingStartBlock+100801 && block.number <= fundingEndBlock) { 
          // Final Week         +0% = 1,000 BST   = 1 ETH       [blocks: s+100801 -> end]
          
        tokensPerEthPrice=1000;
      }
    }

    // default payable function when sending ether to this contract
    function () payable {
      require(msg.data.length == 0);
      BuyBSTtokens();
    }

    function BuyBSTtokens() payable {
        
      // 0. conditions (length, crowdsale setup, zero check, 
      //exceed funding contrib check, contract valid check, within funding block range check, balance overflow check etc)
      require(!(msg.value == 0)
      && (isCrowdSaleSetup)
      && (block.number >= fundingStartBlock)
      && (block.number <= fundingEndBlock)
      && (tokensRemaining > 0));

      // 1. vars
      uint256 rewardTransferAmount    = 0;

      // 2. effects
      setPrice();
      amountRaisedInWei               = safeAdd(amountRaisedInWei,msg.value);
      rewardTransferAmount            = safeDiv(safeMul(msg.value,tokensPerEthPrice),10000000000000000);

      // 3. interaction
      tokensRemaining                 = safeSub(tokensRemaining, safeDiv(rewardTransferAmount,100));  
      // will cause throw if attempt to purchase over the token limit in one tx or at all once limit reached
      tokenReward.transfer(msg.sender, rewardTransferAmount);

      // 4. events
      fundValue[msg.sender]           = safeAdd(fundValue[msg.sender], msg.value);
      Transfer(this, msg.sender, msg.value);
      Buy(msg.sender, msg.value, rewardTransferAmount);
    }
    

    function beneficiaryMultiSigWithdraw(uint256 _amount) onlyOwner {
      require(areFundsReleasedToBeneficiary && (amountRaisedInWei >= fundingMinCapInWei));
      beneficiaryWallet.transfer(_amount);
    }

    function checkGoalReached() onlyOwner returns (bytes32 response) {
        
        // return crowdfund status to owner for each result case, update public constant
        // update state & status variables
      require (isCrowdSaleSetup);
      
      if ((amountRaisedInWei < fundingMinCapInWei) && (block.number <= fundingEndBlock && block.number >= fundingStartBlock)) { 
        // ICO in progress, under softcap
        areFundsReleasedToBeneficiary = false;
        isCrowdSaleClosed = false;
        CurrentStatus = "In progress (Eth < Softcap)";
        return "In progress (Eth < Softcap)";
        
      } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number < fundingStartBlock)) { // ICO has not started
        areFundsReleasedToBeneficiary = false;
        isCrowdSaleClosed = false;
        CurrentStatus = "Presale is setup";
        return "Presale is setup";
        
        
      } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number > fundingEndBlock)) { // ICO ended, under softcap
        areFundsReleasedToBeneficiary = false;
        isCrowdSaleClosed = true;
        CurrentStatus = "Unsuccessful (Eth < Softcap)";
        return "Unsuccessful (Eth < Softcap)";
        
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining == 0)) { // ICO ended, all tokens gone
          areFundsReleasedToBeneficiary = true;
          isCrowdSaleClosed = true;
          CurrentStatus = "Successful (BST >= Hardcap)!";
          return "Successful (BST >= Hardcap)!";
          
          
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.number > fundingEndBlock) && (tokensRemaining > 0)) { 
          
          // ICO ended, over softcap!
          areFundsReleasedToBeneficiary = true;
          isCrowdSaleClosed = true;
          CurrentStatus = "Successful (Eth >= Softcap)!";
          return "Successful (Eth >= Softcap)!";
          
          
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining > 0) && (block.number <= fundingEndBlock)) { 
          
          // ICO in progress, over softcap!
        areFundsReleasedToBeneficiary = true;
        isCrowdSaleClosed = false;
        CurrentStatus = "In progress (Eth >= Softcap)!";
        return "In progress (Eth >= Softcap)!";
      }
      
      setPrice();
    }

    function refund() { 
        
        // any contributor can call this to have their Eth returned. 
        // user&#39;s purchased BST tokens are burned prior refund of Eth.
        //require minCap not reached
        
      require ((amountRaisedInWei < fundingMinCapInWei)
      && (isCrowdSaleClosed)
      && (block.number > fundingEndBlock)
      && (fundValue[msg.sender] > 0));

      //burn user&#39;s token BST token balance, refund Eth sent
      uint256 ethRefund = fundValue[msg.sender];
      balancesArray[msg.sender] = 0;
      fundValue[msg.sender] = 0;
      Burn(msg.sender, ethRefund);

      //send Eth back, burn tokens
      msg.sender.transfer(ethRefund);
      Refund(msg.sender, ethRefund);
    }
}