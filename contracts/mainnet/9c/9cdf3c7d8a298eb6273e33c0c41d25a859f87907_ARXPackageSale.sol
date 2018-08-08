pragma solidity ^0.4.13;
// -------------------------------------------------
// 0.4.13+commit.0fb4cb1a
// [Assistive Reality ARX ERC20 client presold packages 25,50,100 ETH]
// [https://aronline.io/icoinfo]
// [Adapted from Ethereum standard crowdsale contract]
// [Contact <span class="__cf_email__" data-cfemail="e49790858282a485968b8a888d8a81ca8d8b">[email&#160;protected]</span> for any queries]
// [Join us in changing the world]
// [aronline.io]
// -------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
// -------------------------------------------------
// Security reviews completed 26/09/17 [passed OK]
// Functional reviews completed 26/09/17 [passed OK]
// Final code revision and regression test cycle complete 26/09/17 [passed]
// https://github.com/assistivereality/ico/blob/master/3.2packagesaletestsARXmainnet.txt
// -------------------------------------------------
// 3 packages offered in this contract:
// 25 ETH  = 8500 ARX per 1 ETH
// 50 ETH  = 10500 ARX per 1 ETH
// 100 ETH = 12500 ARX per 1 ETH
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

contract ARXPackageSale is owned, safeMath {
  // owner/admin & token reward
  address        public admin                       = owner;      // admin address
  ERC20Interface public tokenReward;                              // address of the token used as reward

  // deployment variables for static supply sale
  uint256 public initialARXSupplyInWei;                           // initial ARX to be sent to this packagesale contract (requires 6.25M ARX, sending 6.5M ARX)
  uint256 public CurrentARXSupplyInWei;                           // tracking to see how many to return
  uint256 public EthCapInWei;                                     // maximum amount to raise in Eth
  uint256 public tokensPerEthPrice;                               // floating price based on package size purchased

  // multi-sig addresses and price variable
  address public beneficiaryMultisig;                             // beneficiaryMultiSig (founder group) live is 0x00F959866E977698D14a36eB332686304a4d6AbA
  address public foundationMultisig;                              // foundationMultiSig (Assistive Reality foundation) live is

  // uint256 values for min,max,caps,tracking
  uint256 public amountRaisedInWei;                               // amount raised in Wei

  // loop control, ICO startup and limiters
  string  public CurrentStatus                     = "";          // current packagesale status
  uint256 public fundingStartBlock;                               // packagesale start block#
  uint256 public fundingEndBlock;                                 // packagesale end block#

  bool    public ispackagesaleSetup                = false;       // boolean for packagesale setup
  bool    public ispackagesaleClosed               = false;       // packagesale completion boolean

  event Buy(address indexed _sender, uint256 _eth, uint256 _ARX);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  // default function, map admin
  function ARXPackageSale() onlyOwner {
    admin = msg.sender;
    CurrentStatus = "packagesale deployed to chain";
  }

  // total number of tokens initially simplified from wei
  function initialARXtokenSupply() constant returns (uint256 initialARXtokenSupplyCount) {
      initialARXtokenSupplyCount = safeDiv(initialARXSupplyInWei,1 ether);
  }

  // current number of tokens simplified from wei
  function currentARXtokenSupply() constant returns (uint256 currentARXtokenSupplyCount) {
      currentARXtokenSupplyCount = safeDiv(CurrentARXSupplyInWei,1 ether);
  }

  // setup the packagesale parameters
  function Setuppackagesale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) onlyOwner returns (bytes32 response) {
      if ((msg.sender == admin)
      && (!(ispackagesaleSetup))
      && (!(beneficiaryMultisig > 0))){
          // init addresses
          tokenReward                             = ERC20Interface(0xb0D926c1BC3d78064F3e1075D5bD9A24F35Ae6C5);   // mainnet is 0x7D5Edcd23dAa3fB94317D32aE253eE1Af08Ba14d //testnet = 0x75508c2B1e46ea29B7cCf0308d4Cb6f6af6211e0
          beneficiaryMultisig                     = 0x5Ed4706A93b8a3239f97F7d2025cE1f9eaDcD9A4;                   // mainnet ARX foundation cold storage wallet
          foundationMultisig                      = 0x5Ed4706A93b8a3239f97F7d2025cE1f9eaDcD9A4;                   // mainnet ARX foundation cold storage wallet
          tokensPerEthPrice                       = 8500;                                                         // 8500 ARX per Eth default flat (this is altered in BuyTokens function based on amount sent for package deals)

          // funding targets
          initialARXSupplyInWei                   = 6500000000000000000000000;                                    //   6,500,000 + 18 decimals = 6500000000000000000000000 //testnet 650k tokens = 65000000000000000000000
          CurrentARXSupplyInWei                   = initialARXSupplyInWei;
          EthCapInWei                             = 500000000000000000000;                                        //   500000000000000000000 =  500 Eth (max cap) - packages won&#39;t sell beyond this amount //testnet 5Eth 5000000000000000000
          amountRaisedInWei                       = 0;

          // update values
          fundingStartBlock                       = _fundingStartBlock;
          fundingEndBlock                         = _fundingEndBlock;

          // configure packagesale
          ispackagesaleSetup                      = true;
          ispackagesaleClosed                     = false;
          CurrentStatus                           = "packagesale is activated";

          return "packagesale is setup";
      } else if (msg.sender != admin) {
          return "not authorized";
      } else  {
          return "campaign cannot be changed";
      }
    }

    // default payable function when sending ether to this contract
    function () payable {
      require(msg.data.length == 0);
      BuyARXtokens();
    }

    function BuyARXtokens() payable {
      // 0. conditions (length, packagesale setup, zero check, exceed funding contrib check, contract valid check, within funding block range check, balance overflow check etc)
      require(!(msg.value == 0)
      && (ispackagesaleSetup)
      && (block.number >= fundingStartBlock)
      && (block.number <= fundingEndBlock)
      && (amountRaisedInWei < EthCapInWei));

      // 1. vars
      uint256 rewardTransferAmount    = 0;

      // 2. effects
      if (msg.value==25000000000000000000) { // 25 ETH (18 decimals) = 8500 ARX per 1 ETH
        tokensPerEthPrice=8500;
      } else if (msg.value==50000000000000000000) { // 50 ETH (18 decimals) = 10500 ARX per 1 ETH
        tokensPerEthPrice=10500;
      } else if (msg.value==100000000000000000000) { // 100 ETH (18 decimals) = 12500 ARX per 1 ETH
        tokensPerEthPrice=12500;
      } else {
        revert();
      }

      amountRaisedInWei               = safeAdd(amountRaisedInWei,msg.value);
      rewardTransferAmount            = safeMul(msg.value,tokensPerEthPrice);
      CurrentARXSupplyInWei           = safeSub(CurrentARXSupplyInWei,rewardTransferAmount);

      // 3. interaction
      tokenReward.transfer(msg.sender, rewardTransferAmount);

      // 4. events
      Transfer(this, msg.sender, msg.value);
      Buy(msg.sender, msg.value, rewardTransferAmount);
    }

    function beneficiaryMultiSigWithdraw(uint256 _amount) onlyOwner {
      beneficiaryMultisig.transfer(_amount);
    }

    function updateStatus() onlyOwner {
      require((block.number >= fundingEndBlock) || (amountRaisedInWei >= EthCapInWei));
      CurrentStatus = "packagesale is closed";
    }

    function withdrawRemainingTokens(uint256 _amountToPull) onlyOwner {
      require(block.number >= fundingEndBlock);
      tokenReward.transfer(msg.sender, _amountToPull);
    }
}