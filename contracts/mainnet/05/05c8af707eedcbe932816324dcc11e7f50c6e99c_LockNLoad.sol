/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  /* getRoundData and latestRoundData should both raise "No data present" */
  /* if they do not have data to report, instead of returning unset values */
  /* which could be misinterpreted as actual reported values. */
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

/* Token Contract call and send Functions */
interface Token {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function approveAndCall(address spender, uint tokens, bytes memory data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract Ownable {
        address public owner;
        event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        constructor() {
            owner = payable(msg.sender);
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address _newOwner) onlyOwner public {
            require(_newOwner != address(0));
            emit onOwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
        }
}

contract LockNLoad is Ownable{
    using SafeMath for uint256;
    
    /* Deposit Variables */
    struct Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }
    
    uint256 public depositId;
    uint256[] public allDepositIds;
    mapping (address => uint256[]) public depositsByWithdrawalAddress;
    mapping (uint256 => Items) public lockedToken;
    mapping (address => mapping(address => uint256)) public walletTokenBalance;
    mapping(address => bool) public premiumMember;
    bool public premium = true;
    int private feerate = 1;
    uint256 systemFeeCollected;
    
    event LogWithdrawal(address SentToAddress, uint256 AmountTransferred);
    AggregatorV3Interface internal priceFeed;
    
    constructor()  {
        priceFeed = AggregatorV3Interface(0x773616E4d11A78F511299002da57A0a94577F1f4);
    }
    
    /* Calculate 1$ Price from Blockchain */
    function getLatestPrice() public view returns (uint256) {
        (
            , 
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }
    
    /* Calculate the original Fee */
    function getSystemFees() public view returns (uint256) {
        (
            , 
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        return uint256(price*feerate);
    }

    /* Calculate Price for Multiple Locks */
    function getSystemFeesBatch(uint256 _totalBatch) public view returns (uint256) {
      return(getSystemFees()*_totalBatch);
    }
    
    /* Lock the Tokens */
    function lockTokens(address _tokenAddress, address _withdrawalAddress, uint256 _amount, uint256 _unlockTime) public payable returns (uint256 _id) {
        require(_amount > 0);
        require(_unlockTime < 10000000000);
        uint256 fee = getSystemFees();
        
        if(premium){
            if(!premiumMember[_withdrawalAddress]){
                require(msg.value>=fee,"System Fee Required");
                payable(owner).transfer(msg.value);
                systemFeeCollected = systemFeeCollected + msg.value;
            }
        }
        
        /* update balance in address */
        walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(_amount);
        
        _id = ++depositId;
        lockedToken[_id].tokenAddress = _tokenAddress;
        lockedToken[_id].withdrawalAddress = _withdrawalAddress;
        lockedToken[_id].tokenAmount = _amount;
        lockedToken[_id].unlockTime = _unlockTime;
        lockedToken[_id].withdrawn = false;
        
        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
        
        /* transfer tokens into contract */
        require(Token(_tokenAddress).transferFrom(msg.sender, address(this), _amount));
    }
    
    /* Create Multiple Locks */
    function createMultipleLocks(address _tokenAddress, address _withdrawalAddress, uint256[] memory _amounts, uint256[] memory _unlockTimes) public payable returns (uint256 _id) {
        require(_amounts.length > 0);
        require(_amounts.length == _unlockTimes.length);
        
        uint256 fee = getSystemFees() * _amounts.length;
        
        if(premium){
            if(!premiumMember[_withdrawalAddress]){
                require(msg.value>=fee,"System Fee Required");
                payable(owner).transfer(msg.value);
                systemFeeCollected = systemFeeCollected + msg.value;
            }
        }
        
        uint256 i;
        for(i=0; i<_amounts.length; i++){
            require(_amounts[i] > 0);
            require(_unlockTimes[i] < 10000000000);
            
            /* update balance in address */
            walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(_amounts[i]);
            
            _id = ++depositId;
            lockedToken[_id].tokenAddress = _tokenAddress;
            lockedToken[_id].withdrawalAddress = _withdrawalAddress;
            lockedToken[_id].tokenAmount = _amounts[i];
            lockedToken[_id].unlockTime = _unlockTimes[i];
            lockedToken[_id].withdrawn = false;
            
            allDepositIds.push(_id);
            depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
            
            /* transfer tokens into contract */
            require(Token(_tokenAddress).transferFrom(msg.sender, address(this), _amounts[i]));
        }
    }
    
    /* Extend the Lock Duration */
    function extendLockDuration(uint256 _id, uint256 _unlockTime) public {
        require(_unlockTime < 10000000000);
        require(_unlockTime > lockedToken[_id].unlockTime);
        require(!lockedToken[_id].withdrawn);
        require(msg.sender == lockedToken[_id].withdrawalAddress);
        
        /* set new unlock time */
        lockedToken[_id].unlockTime = _unlockTime;
    }
    
    /* Transfer the Locked Tokens */
    function transferLocks(uint256 _id, address _receiverAddress) public {
        require(!lockedToken[_id].withdrawn);
        require(msg.sender == lockedToken[_id].withdrawalAddress);
        
        /* decrease sender's token balance */
        walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender].sub(lockedToken[_id].tokenAmount);
        
        /* increase receiver's token balance */
        walletTokenBalance[lockedToken[_id].tokenAddress][_receiverAddress] = walletTokenBalance[lockedToken[_id].tokenAddress][_receiverAddress].add(lockedToken[_id].tokenAmount);
        
        /* remove this id from sender address */
        uint256 j;
        uint256 arrLength = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length;
        for (j=0; j<arrLength; j++) {
            if (depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] == _id) {
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][arrLength - 1];
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].pop();
                break;
            }
        }
        
        /* Assign this id to receiver address */
        lockedToken[_id].withdrawalAddress = _receiverAddress;
        depositsByWithdrawalAddress[_receiverAddress].push(_id);
    }
    
    /* Withdraw Tokens */
    function withdrawTokens(uint256 _id) public {
        require(block.timestamp >= lockedToken[_id].unlockTime);
        require(msg.sender == lockedToken[_id].withdrawalAddress);
        require(!lockedToken[_id].withdrawn);
        
        
        lockedToken[_id].withdrawn = true;
        
        /* update balance in address */
        walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender].sub(lockedToken[_id].tokenAmount);
        
        /* remove this id from this address */
        uint256 j;
        uint256 arrLength = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length;
        for (j=0; j<arrLength; j++) {
            if (depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] == _id) {
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][arrLength - 1];
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].pop();
                break;
            }
        }
        
        /* transfer tokens to wallet address */
        require(Token(lockedToken[_id].tokenAddress).transfer(msg.sender, lockedToken[_id].tokenAmount));
        emit LogWithdrawal(msg.sender, lockedToken[_id].tokenAmount);
    }

    /* Get Total Token Balance in Contract */
    function getTotalTokenBalance(address _tokenAddress) view public returns (uint256)
    {
       return Token(_tokenAddress).balanceOf(address(this));
    }
    
    /* Get Total Token Balance by Address */
    function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) view public returns (uint256)
    {
       return walletTokenBalance[_tokenAddress][_walletAddress];
    }
    
    /* Get All Deposit IDs */
    function getAllDepositIds() view public returns (uint256[] memory)
    {
        return allDepositIds;
    }
    
    /* Get Deposit Details */
    function getDepositDetails(uint256 _id) view public returns (address _tokenAddress, address _withdrawalAddress, uint256 _tokenAmount, uint256 _unlockTime, bool _withdrawn)
    {
        return(lockedToken[_id].tokenAddress,lockedToken[_id].withdrawalAddress,lockedToken[_id].tokenAmount,
        lockedToken[_id].unlockTime,lockedToken[_id].withdrawn);
    }
    
    /* Get Deposit Details by Withdrawal Address */
    function getDepositsByWithdrawalAddress(address _withdrawalAddress) view public returns (uint256[] memory)
    {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }
    
    /* Turn Premium Feature ON or OFF */
    function turnPremiumFeature() public onlyOwner returns (bool success)  {
        if (premium) {
            premium = false;
        } else {
            premium = true;
        }
        return true;
        
    }

    /* View BNB Balance */
    function bnbBalance() public view returns (uint256){
        return address(this).balance;
    }
    
    /* Update fee Rate with respect to $ */
    function updateFeeRate(int _feerate) public onlyOwner returns (bool success){
        feerate = _feerate;
        return true;
    }
    
    /* Only Recieve Token for Lock */
    receive() payable external {
        payable(owner).transfer(msg.value);
    }
    
}