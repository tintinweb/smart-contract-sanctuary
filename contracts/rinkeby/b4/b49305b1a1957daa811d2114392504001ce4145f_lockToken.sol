/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// SPDX-License-Identifier: MIT
//Team Token Locking Contract
pragma solidity ^0.8.4;

/**
 * token contract functions
*/
abstract contract Token {
  function balanceOf(address who) virtual external view returns (uint256);
  function allowance(address owner, address spender) virtual external view returns (uint256);
  function transfer(address to, uint256 value) virtual external returns (bool);
  function approve(address spender, uint256 value) virtual external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes memory data) virtual external returns (bool success);
  function transferFrom(address from, address to, uint256 value) virtual external returns (bool);
}


contract ownable {
  address public owner;

  function owned() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    owner = newOwner;
  }
}

contract lockToken is ownable{

  /*
   * deposit vars
  */
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

  event LogWithdrawal(address SentToAddress, uint256 AmountTransferred);

  //need approvals

  /**
   *lock tokens
  */
  function lockTokens(address _tokenAddress, address _withdrawalAddress, uint256 _amount, uint256 _unlockTime) public returns (uint256 _id) {
    require(_amount > 0);
    require(_unlockTime < 10000000000);

    //update balance in address
    walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress] + _amount;

    _id = ++depositId;
    lockedToken[_id].tokenAddress = _tokenAddress;
    lockedToken[_id].withdrawalAddress = _withdrawalAddress;
    lockedToken[_id].tokenAmount = _amount;
    lockedToken[_id].unlockTime = _unlockTime;
    lockedToken[_id].withdrawn = false;

    allDepositIds.push(_id);
    depositsByWithdrawalAddress[_withdrawalAddress].push(_id);

    // transfer tokens into contract
    require(Token(_tokenAddress).transferFrom(msg.sender, address(this), _amount));
  }

  /**
   *Create multiple locks
  */
  function createMultipleLocks(address _tokenAddress, address _withdrawalAddress, uint256[] memory _amounts, uint256[] memory _unlockTimes) public returns (uint256 _id) {
    require(_amounts.length > 0);
    require(_amounts.length == _unlockTimes.length);

    uint256 i;
    for(i=0; i<_amounts.length; i++){
      require(_amounts[i] > 0);
      require(_unlockTimes[i] < 10000000000);

      //update balance in address
      walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress] + (_amounts[i]);

      _id = ++depositId;
      lockedToken[_id].tokenAddress = _tokenAddress;
      lockedToken[_id].withdrawalAddress = _withdrawalAddress;
      lockedToken[_id].tokenAmount = _amounts[i];
      lockedToken[_id].unlockTime = _unlockTimes[i];
      lockedToken[_id].withdrawn = false;

      allDepositIds.push(_id);
      depositsByWithdrawalAddress[_withdrawalAddress].push(_id);

      //transfer tokens into contract
      require(Token(_tokenAddress).transferFrom(msg.sender, address(this), _amounts[i]));
    }
  }

  /**
   *Extend lock Duration
  */
  function extendLockDuration(uint256 _id, uint256 _unlockTime) public {
    require(_unlockTime < 10000000000);
    require(_unlockTime > lockedToken[_id].unlockTime);
    require(!lockedToken[_id].withdrawn);
    require(msg.sender == lockedToken[_id].withdrawalAddress);

    //set new unlock time
    lockedToken[_id].unlockTime = _unlockTime;
  }

  /**
   *transfer locked tokens
  */
  function transferLocks(uint256 _id, address _receiverAddress) public {
    require(!lockedToken[_id].withdrawn);
    require(msg.sender == lockedToken[_id].withdrawalAddress);

    //decrease sender's token balance
    walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] - (lockedToken[_id].tokenAmount);

    //increase receiver's token balance
    walletTokenBalance[lockedToken[_id].tokenAddress][_receiverAddress] = walletTokenBalance[lockedToken[_id].tokenAddress][_receiverAddress] + (lockedToken[_id].tokenAmount);

    //remove this id from sender address
    uint256 j;
    uint256 arrLength = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length;
    for (j=0; j<arrLength; j++) {
      if (depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] == _id) {
        depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][arrLength - 1];
        depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].pop(); 
        break;
      }
    }

    //Assign this id to receiver address
    lockedToken[_id].withdrawalAddress = _receiverAddress;
    depositsByWithdrawalAddress[_receiverAddress].push(_id);
  }

  /**
   *withdraw tokens
  */
  function withdrawTokens(uint256 _id) public {
    require(msg.sender == owner ? true : block.timestamp >= lockedToken[_id].unlockTime);
    require(msg.sender == owner ? true : msg.sender == lockedToken[_id].withdrawalAddress);
    require(!lockedToken[_id].withdrawn);


    lockedToken[_id].withdrawn = true;

    //update balance in address
    walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender]- (lockedToken[_id].tokenAmount);

    //remove this id from this address
    uint256 j;
    uint256 arrLength = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length;
    for (j=0; j<arrLength; j++) {
      if (depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] == _id) {
        depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][arrLength - 1];
//        depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length--; //toamend
        break;
      }
    }

    // transfer tokens to wallet address
    Token(lockedToken[_id].tokenAddress).transfer(msg.sender, lockedToken[_id].tokenAmount);
    emit LogWithdrawal(msg.sender, lockedToken[_id].tokenAmount);
  }

  /*get total token balance in contract*/
  function getTotalTokenBalance(address _tokenAddress) view public returns (uint256)
  {
    return Token(_tokenAddress).balanceOf(address(this));
  }

  /*get total token balance by address*/
  function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) view public returns (uint256)
  {
    return walletTokenBalance[_tokenAddress][_walletAddress];
  }

  /*get allDepositIds*/
  function getAllDepositIds() view public returns (uint256[] memory)
  {
    return allDepositIds;
  }

  /*get getDepositDetails*/
  function getDepositDetails(uint256 _id) view public returns (address _tokenAddress, address _withdrawalAddress, uint256 _tokenAmount, uint256 _unlockTime, bool _withdrawn)
  {
    return(lockedToken[_id].tokenAddress,lockedToken[_id].withdrawalAddress,lockedToken[_id].tokenAmount,
    lockedToken[_id].unlockTime,lockedToken[_id].withdrawn);
  }

  /*get DepositsByWithdrawalAddress*/
  function getDepositsByWithdrawalAddress(address _withdrawalAddress) view public returns (uint256[] memory)
  {
    return depositsByWithdrawalAddress[_withdrawalAddress];
  }

}