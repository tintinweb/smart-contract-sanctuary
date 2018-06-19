pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title IHFVesting
 * @dev IHFVesting is a token holder contract that allows the specified beneficiary
 * to claim stored tokens after 6 month intervals
*/

 contract IHFVesting {
    using SafeMath for uint256;

    address public beneficiary;
    uint256 public fundingEndBlock;

    bool private initClaim = false; // state tracking variables

    uint256 public firstRelease; // vesting times
    bool private firstDone = false;
    uint256 public secondRelease;
    bool private secondDone = false;
    uint256 public thirdRelease;
    bool private thirdDone = false;
    uint256 public fourthRelease;

    ERC20Basic public ERC20Token; // ERC20 basic token contract to hold

    enum Stages {
        initClaim,
        firstRelease,
        secondRelease,
        thirdRelease,
        fourthRelease
    }

    Stages public stage = Stages.initClaim;

    modifier atStage(Stages _stage) {
        if(stage == _stage) _;
    }

    function IHFVesting(address _token, uint256 fundingEndBlockInput) public {
        require(_token != address(0));
        beneficiary = msg.sender;
        fundingEndBlock = fundingEndBlockInput;
        ERC20Token = ERC20Basic(_token);
    }

    function changeBeneficiary(address newBeneficiary) external {
        require(newBeneficiary != address(0));
        require(msg.sender == beneficiary);
        beneficiary = newBeneficiary;
    }

    function updateFundingEndBlock(uint256 newFundingEndBlock) public {
        require(msg.sender == beneficiary);
        require(block.number < fundingEndBlock);
        require(block.number < newFundingEndBlock);
        fundingEndBlock = newFundingEndBlock;
    }

    function checkBalance() public view returns (uint256 tokenBalance) {
        return ERC20Token.balanceOf(this);
    }

    // in total 2.5% of IHF tokens will be sent to this contract
    // INVICTUS: 1%
    // TEAM: 1.5%
    //  initalPaymen: 0.3%
    //  firstRelease: 0.3%
    //  secondRelease: 0.3%
    //  thirdRelease: 0.3%
    //  fourthRelease: 0.3%
    // initial claim is Invictus + initial team payment
    // initial claim is thus (1 + 0.3)/2.5 = 52% of C20 tokens sent here
    // each other release (for team) is 12% of tokens sent here

    function claim() external {
        require(msg.sender == beneficiary);
        require(block.number > fundingEndBlock);
        uint256 balance = ERC20Token.balanceOf(this);
        // in reverse order so stages changes don&#39;t carry within one claim
        fourth_release(balance);
        third_release(balance);
        second_release(balance);
        first_release(balance);
        init_claim(balance);
    }

    function nextStage() private {
        stage = Stages(uint256(stage) + 1);
    }

    function init_claim(uint256 balance) private atStage(Stages.initClaim) {
        firstRelease = now + 26 weeks; // assign 4 claiming times
        secondRelease = firstRelease + 26 weeks;
        thirdRelease = secondRelease + 26 weeks;
        fourthRelease = thirdRelease + 26 weeks;
        uint256 amountToTransfer = balance.mul(52).div(100);
        ERC20Token.transfer(beneficiary, amountToTransfer); // now 48% tokens left
        nextStage();
    }
    function first_release(uint256 balance) private atStage(Stages.firstRelease) {
        require(now > firstRelease);
        uint256 amountToTransfer = balance.div(4);
        ERC20Token.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
        nextStage();
    }
    function second_release(uint256 balance) private atStage(Stages.secondRelease) {
        require(now > secondRelease);
        uint256 amountToTransfer = balance.div(3);
        ERC20Token.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
        nextStage();
    }
    function third_release(uint256 balance) private atStage(Stages.thirdRelease) {
        require(now > thirdRelease);
        uint256 amountToTransfer = balance.div(2);
        ERC20Token.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
        nextStage();
    }
    function fourth_release(uint256 balance) private atStage(Stages.fourthRelease) {
        require(now > fourthRelease);
        ERC20Token.transfer(beneficiary, balance); // send remaining 25 % of team releases
    }

    function claimOtherTokens(address _token) external {
        require(msg.sender == beneficiary);
        require(_token != address(0));
        ERC20Basic token = ERC20Basic(_token);
        require(token != ERC20Token);
        uint256 balance = token.balanceOf(this);
        token.transfer(beneficiary, balance);
     }

 }