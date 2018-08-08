pragma solidity ^0.4.13;
// **-----------------------------------------------
// 0.4.13+commit.0fb4cb1a
// [Assistive Reality ARX ERC20 token & crowdsale contract w/10% dev alloc]
// [https://aronline.io/icoinfo]
// [v3.2 final released 10/09/17 final masterARXsale32mainnet.sol]
// [Adapted from Ethereum standard crowdsale contract]
// [Contact <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="82f1f6e3e4e4c2e3f0edeceeebece7acebed">[email&#160;protected]</a> for any queries]
// [Join us in changing the world]
// [aronline.io]
// **-----------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
// -------------------------------------------------
// Security reviews completed 10/09/17 [passed OK]
// Functional reviews completed 10/09/17 [passed OK]
// Final code revision and regression test cycle complete 10/09/17 [passed]
// https://github.com/assistivereality/ico/blob/master/3.2crowdsaletestsARXmainnet.txt
// -------------------------------------------------
contract owned { // security reviewed 10/09/17
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

contract SafeMath { // security reviewed 10/09/17
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

contract ERC20Interface is owned, SafeMath { // security reviewed 10/09/17
    function totalSupply() constant returns (uint256 tokenTotalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Buy(address indexed _sender, uint256 _eth, uint256 _ARX);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address _from, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Refund(address indexed _refunder, uint256 _value);
}

contract ARXCrowdsale is ERC20Interface { // security reviewed 10/09/17
    // deployment variables for dynamic supply token
    string  public constant standard              = "ARX";
    string  public constant name                  = "Assistive Reality";
    string  public constant symbol                = "ARX";
    uint8   public constant decimals              = 18;
    uint256 _totalSupply                          = 0;

    // multi-sig addresses and price variable
    address public admin = owner;                               // admin address
    address public beneficiaryMultiSig;                         // beneficiaryMultiSig (founder group) multi-sig wallet account
    address public foundationFundMultisig;                      // foundationFundMultisig multi-sig wallet address - Assistive Reality foundation fund
    uint256 public tokensPerEthPrice;                           // priceVar e.g. 2,000 tokens per Eth

    // uint256 values for min,max,caps,tracking
    uint256 public amountRaisedInWei;                           // total amount raised in Wei e.g. 21 000 000 000 000 000 000 = 21 Eth
    uint256 public fundingMaxInWei;                             // funding max in Wei e.g. 21 000 000 000 000 000 000 = 21 Eth
    uint256 public fundingMinInWei;                             // funding min in Wei e.g. 11 000 000 000 000 000 000 = 11 Eth
    uint256 public fundingMaxInEth;                             // funding max in Eth (approx) e.g. 21 Eth
    uint256 public fundingMinInEth;                             // funding min in Eth (approx) e.g. 11 Eth
    uint256 public remainingCapInWei;                           // amount of cap remaining to raise in Wei e.g. 1 200 000 000 000 000 000 = 1.2 Eth remaining
    uint256 public remainingCapInEth;                           // amount of cap remaining to raise in Eth (approx) e.g. 1
    uint256 public foundationFundTokenCountInWei;               // 10% additional tokens generated and sent to foundationFundMultisig/Assistive Reality foundation, 18 decimals

    // loop control, ICO startup and limiters
    string  public CurrentStatus                  = "";         // current crowdsale status
    uint256 public fundingStartBlock;                           // crowdsale start block#
    uint256 public fundingEndBlock;                             // crowdsale end block#
    bool    public isCrowdSaleFinished            = false;      // boolean for crowdsale completed or not
    bool    public isCrowdSaleSetup               = false;      // boolean for crowdsale setup
    bool    public halted                         = false;      // boolean for halted or not
    bool    public founderTokensAvailable         = false;      // variable to set false after generating founderTokens

    // balance mapping and transfer allowance array
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    event Buy(address indexed _sender, uint256 _eth, uint256 _ARX);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address _from, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Refund(address indexed _refunder, uint256 _value);

    // default function, map admin
    function ARXCrowdsale() onlyOwner {
      admin = msg.sender;
      CurrentStatus = "Crowdsale deployed to chain";
    }

    // total number of tokens issued so far, normalised
    function totalSupply() constant returns (uint256 tokenTotalSupply) {
        tokenTotalSupply = safeDiv(_totalSupply,1 ether);
    }

    // get the account balance
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // returns crowdsale max funding in Eth, low res
    function fundingMaxInEth() constant returns (uint256 fundingMaximumInEth) {
      fundingMaximumInEth = safeDiv(fundingMaxInWei,1 ether);
    }

    // returns crowdsale min funding in Eth, low res
    function fundingMinInEth() constant returns (uint256 fundingMinimumInEth) {
      fundingMinimumInEth = safeDiv(fundingMinInWei,1 ether);
    }

    // returns crowdsale progress (funds raised) in Eth, low res
    function amountRaisedInEth() constant returns (uint256 amountRaisedSoFarInEth) {
      amountRaisedSoFarInEth = safeDiv(amountRaisedInWei,1 ether);
    }

    // returns crowdsale remaining cap (hardcap) in Eth, low res
    function remainingCapInEth() constant returns (uint256 remainingHardCapInEth) {
      remainingHardCapInEth = safeDiv(remainingCapInWei,1 ether);
    }

    // ERC20 token transfer function
    function transfer(address _to, uint256 _amount) returns (bool success) {
        require(!(_to == 0x0));
        if ((balances[msg.sender] >= _amount)
        && (_amount > 0)
        && ((safeAdd(balances[_to],_amount) > balances[_to]))) {
            balances[msg.sender] = safeSub(balances[msg.sender], _amount);
            balances[_to] = safeAdd(balances[_to], _amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // ERC20 token transferFrom function
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount) returns (bool success) {
        require(!(_to == 0x0));
        if ((balances[_from] >= _amount)
        && (allowed[_from][msg.sender] >= _amount)
        && (_amount > 0)
        && (safeAdd(balances[_to],_amount) > balances[_to])) {
            balances[_from] = safeSub(balances[_from], _amount);
            allowed[_from][msg.sender] = safeSub((allowed[_from][msg.sender]),_amount);
            balances[_to] = safeAdd(balances[_to], _amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // ERC20 allow _spender to withdraw, multiple times, up to the _value amount
    function approve(address _spender, uint256 _amount) returns (bool success) {
        //Fix for known double-spend https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#
        //Input must either set allow amount to 0, or have 0 already set, to workaround issue
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    // ERC20 return allowance for given owner spender pair
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // setup the CrowdSale parameters
    function SetupCrowdsale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) onlyOwner returns (bytes32 response) {
        if ((msg.sender == admin)
        && (!(isCrowdSaleSetup))
        && (!(beneficiaryMultiSig > 0))
        && (!(fundingMaxInWei > 0))) {
            // mainnet values
            beneficiaryMultiSig = 0xd93333f8cb765397A5D0d0e0ba53A2899B48511f;
            foundationFundMultisig = 0x70A0bE1a5d8A9F39afED536Ec7b55d87067371aA;

            // mainnet funding targets with 18 decimals
            fundingMaxInWei = 70000000000000000000000; //70 000 000 000 000 000 000 000 = 70,000 Eth (hard cap) - crowdsale no longer accepts Eth after this value
            fundingMinInWei = 3500000000000000000000;   //3 500 000 000 000 000 000 000 =  3,500 Eth (soft cap) - crowdsale is considered success after this value

            // value of ARX token for mainnet. if hardcap is reached, this results in 280,000,000 ARX tokens in general supply (+28,000,000 in the foundationFundMultisig for a total supply of 308,000,000)
            tokensPerEthPrice = 4000; // 4,000 tokens per Eth

            // update values
            fundingMaxInEth = safeDiv(fundingMaxInWei,1 ether); //approximate to 1 Eth due to resolution, provided for ease/viewing only
            fundingMinInEth = safeDiv(fundingMinInWei,1 ether); //approximate to 1 Eth due to resolution, provided for ease/viewing only
            remainingCapInWei = fundingMaxInWei;
            remainingCapInEth = safeDiv(remainingCapInWei,1 ether); //approximate to 1 Eth due to resolution, provided for ease/viewing only
            fundingStartBlock = _fundingStartBlock;
            fundingEndBlock = _fundingEndBlock;

            // configure crowdsale
            isCrowdSaleSetup = true;
            CurrentStatus = "Crowdsale is setup";
            return "Crowdsale is setup";
        } else if (msg.sender != admin) {
            return "not authorized";
        } else  {
            return "campaign cannot be changed";
        }
    }

    // default payable function when sending ether to this contract
    function () payable {
      require(msg.data.length == 0);
      BuyTokens();
    }

    function BuyTokens() payable {
      // 0. conditions (length, crowdsale setup, zero check, exceed funding contrib check, contract valid check, within funding block range check, balance overflow check etc)
      require((!(msg.value == 0))
      && (!(halted))
      && (isCrowdSaleSetup)
      && (!((safeAdd(amountRaisedInWei,msg.value)) > fundingMaxInWei))
      && (block.number >= fundingStartBlock)
      && (block.number <= fundingEndBlock)
      && (!(isCrowdSaleFinished)));

      // 1. vars
      address recipient = msg.sender; // to simplify refunding
      uint256 amount = msg.value;
      uint256 rewardTransferAmount = 0;

      // 2. effects
      amountRaisedInWei = safeAdd(amountRaisedInWei,amount);
      remainingCapInWei = safeSub(fundingMaxInWei,amountRaisedInWei);
      rewardTransferAmount = safeMul(amount,tokensPerEthPrice);

      // 3. interaction
      balances[recipient] = safeAdd(balances[recipient], rewardTransferAmount);
      _totalSupply = safeAdd(_totalSupply, rewardTransferAmount);
      Transfer(this, recipient, rewardTransferAmount);
      Buy(recipient, amount, rewardTransferAmount);
    }

    function AllocateFounderTokens() onlyOwner {
      require(isCrowdSaleFinished && founderTokensAvailable && (foundationFundTokenCountInWei == 0));

      // calculate additional 10% tokens to allocate for foundation developer distributions
      foundationFundTokenCountInWei = safeMul((safeDiv(amountRaisedInWei,10)), tokensPerEthPrice);

      // generate and send foundation developer token distributions
      balances[foundationFundMultisig] = safeAdd(balances[foundationFundMultisig], foundationFundTokenCountInWei);

      _totalSupply = safeAdd(_totalSupply, foundationFundTokenCountInWei);
      Transfer(this, foundationFundMultisig, foundationFundTokenCountInWei);
      Buy(foundationFundMultisig, 0, foundationFundTokenCountInWei);
      founderTokensAvailable = false;
    }

    function beneficiaryMultiSigWithdraw(uint256 _amount) onlyOwner {
      require(isCrowdSaleFinished && (amountRaisedInWei >= fundingMinInWei));
      beneficiaryMultiSig.transfer(_amount);
    }

    function checkGoalReached() onlyOwner returns (bytes32 response) { // return crowdfund status to owner for each result case, update public constant
      require (!(halted) && isCrowdSaleSetup);

      if ((amountRaisedInWei < fundingMinInWei) && (block.number <= fundingEndBlock && block.number >= fundingStartBlock)) { // ICO in progress, under softcap
        founderTokensAvailable = false;
        isCrowdSaleFinished = false;
        CurrentStatus = "In progress (Eth < Softcap)";
        return "In progress (Eth < Softcap)";
      } else if ((amountRaisedInWei < fundingMinInWei) && (block.number < fundingStartBlock)) { // ICO has not started
        founderTokensAvailable = false;
        isCrowdSaleFinished = false;
        CurrentStatus = "Crowdsale is setup";
        return "Crowdsale is setup";
      } else if ((amountRaisedInWei < fundingMinInWei) && (block.number > fundingEndBlock)) { // ICO ended, under softcap
        founderTokensAvailable = false;
        isCrowdSaleFinished = true;
        CurrentStatus = "Unsuccessful (Eth < Softcap)";
        return "Unsuccessful (Eth < Softcap)";
      } else if ((amountRaisedInWei >= fundingMinInWei) && (amountRaisedInWei >= fundingMaxInWei)) { // ICO ended, at hardcap!
        if (foundationFundTokenCountInWei == 0) {
          founderTokensAvailable = true;
          isCrowdSaleFinished = true;
          CurrentStatus = "Successful (Eth >= Hardcap)!";
          return "Successful (Eth >= Hardcap)!";
        } else if (foundationFundTokenCountInWei > 0) {
          founderTokensAvailable = false;
          isCrowdSaleFinished = true;
          CurrentStatus = "Successful (Eth >= Hardcap)!";
          return "Successful (Eth >= Hardcap)!";
        }
      } else if ((amountRaisedInWei >= fundingMinInWei) && (amountRaisedInWei < fundingMaxInWei) && (block.number > fundingEndBlock)) { // ICO ended, over softcap!
        if (foundationFundTokenCountInWei == 0) {
          founderTokensAvailable = true;
          isCrowdSaleFinished = true;
          CurrentStatus = "Successful (Eth >= Softcap)!";
          return "Successful (Eth >= Softcap)!";
        } else if (foundationFundTokenCountInWei > 0) {
          founderTokensAvailable = false;
          isCrowdSaleFinished = true;
          CurrentStatus = "Successful (Eth >= Softcap)!";
          return "Successful (Eth >= Softcap)!";
        }
      } else if ((amountRaisedInWei >= fundingMinInWei) && (amountRaisedInWei < fundingMaxInWei) && (block.number <= fundingEndBlock)) { // ICO in progress, over softcap!
        founderTokensAvailable = false;
        isCrowdSaleFinished = false;
        CurrentStatus = "In progress (Eth >= Softcap)!";
        return "In progress (Eth >= Softcap)!";
      }
    }

    function refund() { // any contributor can call this to have their Eth returned, if not halted, soft cap not reached and deadline expires
      require (!(halted)
      && (amountRaisedInWei < fundingMinInWei)
      && (block.number > fundingEndBlock)
      && (balances[msg.sender] > 0));
      //Proceed with refund
      uint256 ARXbalance = balances[msg.sender];
      balances[msg.sender] = 0;
      _totalSupply = safeSub(_totalSupply, ARXbalance);
      uint256 ethValue = safeDiv(ARXbalance, tokensPerEthPrice);
      amountRaisedInWei = safeSub(amountRaisedInWei, ethValue);
      msg.sender.transfer(ethValue);
      Burn(msg.sender, ARXbalance);
      Refund(msg.sender, ethValue);
    }

    function halt() onlyOwner { // halt the crowdsale
        halted = true;
        CurrentStatus = "Halted";
    }

    function unhalt() onlyOwner { // resume the crowdsale
        halted = false;
        CurrentStatus = "Unhalted";
        checkGoalReached();
    }
}