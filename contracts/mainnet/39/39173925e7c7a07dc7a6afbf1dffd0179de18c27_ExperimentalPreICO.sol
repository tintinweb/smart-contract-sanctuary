pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="8efcebe3ede1cebc">[email&#160;protected]</span>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="83f1e6eee0ecc3b1">[email&#160;protected]</span>π.com>
 * @dev This blocks incoming ERC23 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract reclaimTokens is Ownable {

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param tokenAddr address The address of the token contract
   */
  function reclaimToken(address tokenAddr) external onlyOwner {
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(owner, balance);
  }
}

contract ExperimentalPreICO is reclaimTokens, HasNoContracts {
  using SafeMath for uint256;

  address public beneficiary;
  bool public fundingGoalReached = false;
  bool public crowdsaleClosed = false;
  ERC20Basic public rewardToken;
  uint256 public fundingGoal;
  uint256 public fundingCap;
  uint256 public paymentMin;
  uint256 public paymentMax;
  uint256 public amountRaised;
  uint256 public rate;

  mapping(address => uint256) public balanceOf;
  mapping(address => bool) public whitelistedAddresses;
  event GoalReached(address beneficiaryAddress, uint256 amount);
  event FundTransfer(address backer, uint256 amount, bool isContribution);

  /**
   * @dev data structure to hold information about campaign contributors
   */
  function ExperimentalPreICO(address _wallet,
                              uint256 _goalInEthers,
                              uint256 _capInEthers,
                              uint256 _minPaymentInEthers,
                              uint256 _maxPaymentInEthers,
                              uint256 _rate,
                              address _rewardToken) {
    require(_goalInEthers > 0);
    require(_capInEthers >= _goalInEthers);
    require(_minPaymentInEthers > 0);
    require(_maxPaymentInEthers > _minPaymentInEthers);
    require(_rate > 0);
    require(_wallet != 0x0);
    beneficiary = _wallet;
    fundingGoal = _goalInEthers.mul(1 ether);
    fundingCap = _capInEthers.mul(1 ether);
    paymentMin = _minPaymentInEthers.mul(1 ether);
    paymentMax = _maxPaymentInEthers.mul(1 ether);
    rate = _rate;
    rewardToken = ERC20Basic(_rewardToken);
  }

  /**
   * @dev The default function that is called whenever anyone sends funds to the contract
   */
  function () external payable crowdsaleActive {
    require(validPurchase());

    uint256 amount = msg.value;
    balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
    amountRaised = amountRaised.add(amount);
    rewardToken.transfer(msg.sender, amount.mul(rate));
    FundTransfer(msg.sender, amount, true);
  }

  /**
   * @dev Throws if called when crowdsale is still open.
   */
  modifier crowdsaleEnded() {
    require(crowdsaleClosed == true);
    _;
  }

  /**
   * @dev Throws if called when crowdsale has closed.
   */
  modifier crowdsaleActive() {
    require(crowdsaleClosed == false);
    _;
  }

  /**
   * @dev return true if the transaction can buy tokens
   */
  function validPurchase() internal returns (bool) {
    bool whitelisted = whitelistedAddresses[msg.sender] == true;
    bool validAmmount = msg.value >= paymentMin && msg.value <= paymentMax;
    bool availableFunding = fundingCap >= amountRaised.add(msg.value);
    return whitelisted && validAmmount && availableFunding;
  }

  /**
   * @dev checks if the goal has been reached
   */
  function checkGoal() external onlyOwner {
    if (amountRaised >= fundingGoal){
      fundingGoalReached = true;
      GoalReached(beneficiary, amountRaised);
    }
  }

  /**
   * @dev ends or resumes the crowdsale
   */
  function endCrowdsale() external onlyOwner {
    crowdsaleClosed = true;
  }

  /**
   * @dev Allows backers to withdraw their funds in the crowdsale was unsuccessful,
   * and allow the owner to send the amount raised to the beneficiary
   */
  function safeWithdrawal() external crowdsaleEnded {
    if (!fundingGoalReached) {
      uint256 amount = balanceOf[msg.sender];
      balanceOf[msg.sender] = 0;
      if (amount > 0) {
        if (msg.sender.send(amount)) {
          FundTransfer(msg.sender, amount, false);
        } else {
          balanceOf[msg.sender] = amount;
        }
      }
    }

    if (fundingGoalReached && owner == msg.sender) {
      if (beneficiary.send(amountRaised)) {
        FundTransfer(beneficiary, amountRaised, false);
      } else {
        //If we fail to send the funds to beneficiary, unlock funders balance
        fundingGoalReached = false;
      }
    }
  }

  /**
   * @dev Whitelists a list of addresses
   */
  function whitelistAddress (address[] addresses) external onlyOwner crowdsaleActive {
    for (uint i = 0; i < addresses.length; i++) {
      whitelistedAddresses[addresses[i]] = true;
    }
  }

}