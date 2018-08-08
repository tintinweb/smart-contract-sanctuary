pragma solidity ^0.4.13;
// -------------------------------------------------
// 0.4.13+commit.0fb4cb1a
// [Assistive Reality ARX token ETH cap presale contract]
// [Contact <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d0a3a4b1b6b690b1a2bfbebcb9beb5feb9bf">[email&#160;protected]</a> for any queries]
// [Join us in changing the world]
// [aronline.io]
// -------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
// -------------------------------------------------
// 1,000 ETH capped Pre-sale contract
// Security reviews completed 26/09/17 [passed OK]
// Functional reviews completed 26/09/17 [passed OK]
// Final code revision and regression test cycle complete 26/09/17 [passed OK]
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

contract ERC20Interface is owned, safeMath {
  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function increaseApproval (address _spender, uint _addedValue) returns (bool success);
  function decreaseApproval (address _spender, uint _subtractedValue) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  event Buy(address indexed _sender, uint256 _eth, uint256 _ARX);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ARXpresale is owned, safeMath {
  // owner/admin & token reward
  address         public admin                   = owner;     // admin address
  ERC20Interface  public tokenReward;                         // address of the token used as reward

  // multi-sig addresses and price variable
  address public foundationWallet;                            // foundationMultiSig (foundation fund) or wallet account, for company operations/licensing of Assistive Reality products
  address public beneficiaryWallet;                           // beneficiaryMultiSig (founder group) or wallet account, live is 0x00F959866E977698D14a36eB332686304a4d6AbA
  uint256 public tokensPerEthPrice;                           // set initial value floating priceVar 1,500 tokens per Eth

  // uint256 values for min,max caps & tracking
  uint256 public amountRaisedInWei;                           // 0 initially (0)
  uint256 public fundingMinCapInWei;                          // 100 ETH (10%) (100 000 000 000 000 000 000)
  uint256 public fundingMaxCapInWei;                          // 1,000 ETH in Wei (1000 000 000 000 000 000 000)
  uint256 public fundingRemainingAvailableInEth;              // ==((fundingMaxCapInWei - amountRaisedInWei)/1 ether); (resolution will only be to integer)

  // loop control, ICO startup and limiters
  string  public currentStatus                   = "";        // current presale status
  uint256 public fundingStartBlock;                           // presale start block#
  uint256 public fundingEndBlock;                             // presale end block#
  bool    public isPresaleClosed                 = false;     // presale completion boolean
  bool    public isPresaleSetup                  = false;     // boolean for presale setup

  event Buy(address indexed _sender, uint256 _eth, uint256 _ARX);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Refund(address indexed _refunder, uint256 _value);
  event Burn(address _from, uint256 _value);

  mapping(address => uint256) balances;
  mapping(address => uint256) fundValue;

  // default function, map admin
  function ARXpresale() onlyOwner {
    admin = msg.sender;
    currentStatus = "presale deployed to chain";
  }

  // setup the presale parameters
  function Setuppresale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) onlyOwner returns (bytes32 response) {
      if ((msg.sender == admin)
      && (!(isPresaleSetup))
      && (!(beneficiaryWallet > 0))){
          // init addresses
          tokenReward                             = ERC20Interface(0xb0D926c1BC3d78064F3e1075D5bD9A24F35Ae6C5);   // mainnet is 0xb0D926c1BC3d78064F3e1075D5bD9A24F35Ae6C5
          beneficiaryWallet                       = 0xd93333f8cb765397A5D0d0e0ba53A2899B48511f;                   // mainnet is 0xd93333f8cb765397A5D0d0e0ba53A2899B48511f
          foundationWallet                        = 0x70A0bE1a5d8A9F39afED536Ec7b55d87067371aA;                   // mainnet is 0x70A0bE1a5d8A9F39afED536Ec7b55d87067371aA
          tokensPerEthPrice                       = 8000;                                                         // set day1 presale value floating priceVar 8,000 ARX tokens per 1 ETH

          // funding targets
          fundingMinCapInWei                      = 100000000000000000000;                                        // 100000000000000000000  = 100 Eth (min cap) //testnet 2500000000000000000   = 2.5 Eth
          fundingMaxCapInWei                      = 1000000000000000000000;                                       // 1000000000000000000000 = 1000 Eth (max cap) //testnet 6500000000000000000  = 6.5 Eth

          // update values
          amountRaisedInWei                       = 0;                                                            // init value to 0
          fundingRemainingAvailableInEth          = safeDiv(fundingMaxCapInWei,1 ether);

          fundingStartBlock                       = _fundingStartBlock;
          fundingEndBlock                         = _fundingEndBlock;

          // configure presale
          isPresaleSetup                          = true;
          isPresaleClosed                         = false;
          currentStatus                           = "presale is setup";

          //gas reduction experiment
          setPrice();
          return "presale is setup";
      } else if (msg.sender != admin) {
          return "not authorized";
      } else  {
          return "campaign cannot be changed";
      }
    }

    function setPrice() {
      // Price configuration mainnet:
      // Day 0-1 Price   1 ETH = 8000 ARX [blocks: start    -> s+3600]  0 - +24hr
      // Day 1-3 Price   1 ETH = 7250 ARX [blocks: s+3601   -> s+10800] +24hr - +72hr
      // Day 3-5 Price   1 ETH = 6750 ARX [blocks: s+10801  -> s+18000] +72hr - +120hr
      // Dau 5-7 Price   1 ETH = 6250 ARX [blocks: s+18001  -> <=fundingEndBlock] = +168hr (168/24 = 7 [x])

      if (block.number >= fundingStartBlock && block.number <= fundingStartBlock+3600) { // 8000 ARX Day 1 level only
        tokensPerEthPrice=8000;
      } else if (block.number >= fundingStartBlock+3601 && block.number <= fundingStartBlock+10800) { // 7250 ARX Day 2,3
        tokensPerEthPrice=7250;
      } else if (block.number >= fundingStartBlock+10801 && block.number <= fundingStartBlock+18000) { // 6750 ARX Day 4,5
        tokensPerEthPrice=6750;
      } else if (block.number >= fundingStartBlock+18001 && block.number <= fundingEndBlock) { // 6250 ARX Day 6,7
        tokensPerEthPrice=6250;
      } else {
        tokensPerEthPrice=6250; // default back out to this value instead of failing to return or return 0/halting;
      }
    }

    // default payable function when sending ether to this contract
    function () payable {
      require(msg.data.length == 0);
      BuyARXtokens();
    }

    function BuyARXtokens() payable {
      // 0. conditions (length, presale setup, zero check, exceed funding contrib check, contract valid check, within funding block range check, balance overflow check etc)
      require(!(msg.value == 0)
      && (isPresaleSetup)
      && (block.number >= fundingStartBlock)
      && (block.number <= fundingEndBlock)
      && !(safeAdd(amountRaisedInWei,msg.value) > fundingMaxCapInWei));

      // 1. vars
      uint256 rewardTransferAmount    = 0;

      // 2. effects
      setPrice();
      amountRaisedInWei               = safeAdd(amountRaisedInWei,msg.value);
      rewardTransferAmount            = safeMul(msg.value,tokensPerEthPrice);
      fundingRemainingAvailableInEth  = safeDiv(safeSub(fundingMaxCapInWei,amountRaisedInWei),1 ether);

      // 3. interaction
      tokenReward.transfer(msg.sender, rewardTransferAmount);
      fundValue[msg.sender]           = safeAdd(fundValue[msg.sender], msg.value);

      // 4. events
      Transfer(this, msg.sender, msg.value);
      Buy(msg.sender, msg.value, rewardTransferAmount);
    }

    function beneficiaryMultiSigWithdraw(uint256 _amount) onlyOwner {
      require(amountRaisedInWei >= fundingMinCapInWei);
      beneficiaryWallet.transfer(_amount);
    }

    function checkGoalandPrice() onlyOwner returns (bytes32 response) {
      // update state & status variables
      require (isPresaleSetup);
      if ((amountRaisedInWei < fundingMinCapInWei) && (block.number <= fundingEndBlock && block.number >= fundingStartBlock)) { // presale in progress, under softcap
        currentStatus = "In progress (Eth < Softcap)";
        return "In progress (Eth < Softcap)";
      } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number < fundingStartBlock)) { // presale has not started
        currentStatus = "presale is setup";
        return "presale is setup";
      } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number > fundingEndBlock)) { // presale ended, under softcap
        currentStatus = "Unsuccessful (Eth < Softcap)";
        return "Unsuccessful (Eth < Softcap)";
      } else if (amountRaisedInWei >= fundingMaxCapInWei) {  // presale successful, at hardcap!
          currentStatus = "Successful (ARX >= Hardcap)!";
          return "Successful (ARX >= Hardcap)!";
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.number > fundingEndBlock)) { // presale ended, over softcap!
          currentStatus = "Successful (Eth >= Softcap)!";
          return "Successful (Eth >= Softcap)!";
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.number <= fundingEndBlock)) { // presale in progress, over softcap!
        currentStatus = "In progress (Eth >= Softcap)!";
        return "In progress (Eth >= Softcap)!";
      }
      setPrice();
    }

    function refund() { // any contributor can call this to have their Eth returned. user&#39;s purchased ARX tokens are burned prior refund of Eth.
      //require minCap not reached
      require ((amountRaisedInWei < fundingMinCapInWei)
      && (isPresaleClosed)
      && (block.number > fundingEndBlock)
      && (fundValue[msg.sender] > 0));

      //burn user&#39;s token ARX token balance, refund Eth sent
      uint256 ethRefund = fundValue[msg.sender];
      balances[msg.sender] = 0;
      fundValue[msg.sender] = 0;
      Burn(msg.sender, ethRefund);

      //send Eth back, burn tokens
      msg.sender.transfer(ethRefund);
      Refund(msg.sender, ethRefund);
    }

    function withdrawRemainingTokens(uint256 _amountToPull) onlyOwner {
      require(block.number >= fundingEndBlock);
      tokenReward.transfer(msg.sender, _amountToPull);
    }

    function updateStatus() onlyOwner {
      require((block.number >= fundingEndBlock) || (amountRaisedInWei >= fundingMaxCapInWei));
      isPresaleClosed = true;
      currentStatus = "packagesale is closed";
    }
  }