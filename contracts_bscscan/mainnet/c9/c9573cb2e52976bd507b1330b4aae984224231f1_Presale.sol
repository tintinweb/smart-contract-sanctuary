/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// Presale Contract for BITMINE FINANCE TOKEN.
//Official Website: www.bitmine.finance
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address payable owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = payable(msg.sender);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address payable newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface BitMineFinance {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address _owner) external returns (uint256 balance);
    function mint(address wallet, address buyer, uint256 tokenAmount) external;
    function showMyTokenBalance(address addr) external;
}

contract Presale is Ownable {
    
    using SafeMath for uint256;
    uint256 public startTime;
    uint256 public endTime;
    address payable public adminAddress;
    mapping(address=>uint256) public BuyerList;
    address public _burnaddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public MAX_BUY_LIMIT = 10000000000000000000;
    uint256 public majorOwnerShares = 100;
    uint public    referralReward = 5;
    uint256 public rate = 3000;
    uint256 public airdropTokens = 500000000000000000;
    uint256 public weiRaised;
    bool public isPresaleStopped = false;
    bool public isAirdropStopped = false;
    bool public isPresalePaused = false;
    uint public userCurrentId = 0;
    mapping (uint => address) public userList;
    struct UserStruct {
        bool isExist;
        uint id;
    }
    mapping (address => UserStruct) public users;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Transfered(address indexed purchaser, address indexed referral, uint256 amount);

  
    BitMineFinance public token;
    
    
    constructor(address payable _walletMajorOwner) 
    {
        token = BitMineFinance(0x1a386E7118996Dee2B15943fBa506d5478c86E0e); 
        startTime = 1625819286 ;   
        endTime = startTime + 90 days;
        require(endTime >= startTime);
        require(_walletMajorOwner != address(0));
        adminAddress = _walletMajorOwner;
    }
    
    fallback() external payable {
        buy(msg.sender, owner);
    }
    
    receive() external payable {}
    
    function isContract(address _addr) public view returns (bool _isContract){
        uint32 size;
        assembly {
        size := extcodesize(_addr)}
        return (size > 0);
    }

    function claimAirdrop() public{
        require (isAirdropStopped != true, 'Airdrop is stopped');
        require(users[msg.sender].isExist == false, "Aridrop Already Claimed");
        userCurrentId = userCurrentId.add(1);
        userList[userCurrentId] = msg.sender;
        UserStruct memory userStruct;
        userStruct = UserStruct({
            isExist: true,
            id: userCurrentId
        });
        users[msg.sender] = userStruct;
        token.transfer(msg.sender,airdropTokens);
    }
    
    function buy(address beneficiary, address payable referral) public payable
    {
        require (isPresaleStopped != true, 'Presale is stopped');
        require (isPresalePaused != true, 'Presale is paused');
        require(beneficiary != address(0), 'user asking for tokens sent to be on 0 address');
        require(validPurchase(), 'its not a valid purchase');
        require(BuyerList[msg.sender] < MAX_BUY_LIMIT, 'MAX_BUY_LIMIT Achieved already for this wallet');
        uint256 weiAmount = msg.value;
        require(weiAmount <5000000000000000001 , 'MAX_BUY_LIMIT is 5 BNB'); 
        uint256 tokens = weiAmount.mul(rate);
        uint256 refReward = tokens * referralReward / 100;
        weiRaised = weiRaised.add(weiAmount);
        token.transfer(referral,refReward);
        token.transfer(beneficiary,tokens);
        adminAddress.transfer(msg.value);
        BuyerList[msg.sender] = BuyerList[msg.sender].add(msg.value);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    function validPurchase() internal returns (bool) {
        bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    function hasEnded() public view returns (bool) {
        return block.timestamp > endTime;
    }
  
    function showMyTokenBalance(address myAddress) public returns (uint256 tokenBalance) {
       tokenBalance = token.balanceOf(myAddress);
    }

    function setEndDate(uint256 daysToEndFromToday) public onlyOwner returns(bool) {
        daysToEndFromToday = daysToEndFromToday * 1 days;
        endTime = block.timestamp + daysToEndFromToday;
        return true;
    }

    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) {
        rate = newPrice;
         return true;
    }

    function setAirdropRate(uint256 newAirdrop) public onlyOwner returns (bool) {
         airdropTokens = newAirdrop;
         return true;
    }
    
    function setReferralReward(uint256 newReward) public onlyOwner returns (bool) {
         referralReward = newReward;
         return true;
    }

    function pausePresale() public onlyOwner returns(bool) {
        isPresalePaused = true;
         return isPresalePaused;
    }

    function resumePresale() public onlyOwner returns (bool) {
        isPresalePaused = false;
        return !isPresalePaused;
    }

    function stopPresale() public onlyOwner returns (bool) {
        isPresaleStopped = true;
        return true;
    }

    function stopAirdrop() public onlyOwner returns (bool) {
        isAirdropStopped = true;
        return true;
    }

    function BurnUnsoldTokens() public onlyOwner {
        uint256 unsold = token.balanceOf(address(this));
        token.transfer(_burnaddress,unsold);
    }
    
    function startPresale() public onlyOwner returns (bool) {
        isPresaleStopped = false;
        startTime = block.timestamp; 
        return true;
    }
    
    function tokensRemainingForSale(address contractAddress) public returns (uint balance) {
        balance = token.balanceOf(contractAddress);
        return balance;
    }
}