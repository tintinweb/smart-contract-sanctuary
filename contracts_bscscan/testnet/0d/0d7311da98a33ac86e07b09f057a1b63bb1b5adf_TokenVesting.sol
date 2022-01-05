// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./TDD.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20 _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for TDD;

//   余额 tokenBalance
//             时间间隔 releaseInterval
//             解锁时间 unlockTime
//             解锁总次数（算比例）unlockNum
//             解锁计数 unlockCount
//             收益地址 benefitAddress
//             累计解锁总计数 unlockCountAll


  address public benefitAddress;
  uint256 public tokenBalance = 0;
  uint256 public releaseInterval;
  uint256 public unlockTime;
  uint256 public unlockNum = 0;
  uint256 public unlockCount = 0;
  uint256 public unlockCountAll;


  constructor(
  address _benefitAddress,
  uint256 _releaseInterval,
  uint256 _unlockTime,
  uint256 _unlockNum
  )
    public
  {
    require(_benefitAddress != address(0));
    benefitAddress = _benefitAddress;
    releaseInterval = _releaseInterval;
    unlockTime = _unlockTime;
    unlockNum = _unlockNum;
    unlockCountAll = unlockNum.sub(1);
  }



// 1、
//             sstore(0x01, unlockTime)
//             sstore(0x02, unlockNum)
//             sstore(0x03, 0)
//             sstore(0x04, 0)
//             sstore(0x05, benefitAdress)
//             sstore(0x06, sub(unlockNum, 1))

//             余额 tokenBalance
//             时间间隔 releaseInterval
//             解锁时间 unlockTime
//             解锁总次数（算比例）unlockNum
//             解锁计数 unlockCount
//             收益地址 benefitAddress
//             累计解锁总计数 unlockCountAll




  function release(TDD _token)  public {
  
    uint256 addTime = releaseInterval * 1 days;

    //1、检查解锁计数是否大于累计解锁总计数
 
     require(unlockCountAll >= unlockCount);

    //2、当前时间大于解锁时间
    
     require(block.timestamp >= unlockTime);

     //3、如果解锁计数!=累计解锁总计数,解锁计数+1, 解锁时间+1
    //如果unlockCount==0，tokenBalance= _token.balanceOf(this)

    // unrelease = tokenBalance.div(unlockNum)
    // _token.safeTransfer(benefitAddress, unrelease);

    if(unlockCount!=unlockCountAll){
        if(unlockCount==0){
           tokenBalance= _token.balanceOf(address(this));
        }
        unlockCount = unlockCount.add(1);
        unlockTime = unlockTime.add(addTime);
        uint256 unrelease = tokenBalance.div(unlockNum);
        _token.safeTransfer(benefitAddress, unrelease);
    }
    //4、如果解锁计数==累计解锁总计数,解锁计数+1, 解锁时间+1
    if(unlockCount==unlockCountAll){
        unlockCount = unlockCount.add(1);
        unlockTime = unlockTime.add(addTime);
        uint256 finalBalance = _token.balanceOf(address(this));
        _token.safeTransfer(benefitAddress, finalBalance);
    }
}
}