/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;
// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y>0,'ds-math-div-overflow');
        z = x / y;
        //require((z = x / y) * y == x, 'ds-math-div-overflow');
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
contract Ownable {

    address public owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    

    /**
     * @dev Set contract deployer as owner
     */
     constructor () {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    // modifier to check if caller is owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"newOwner is null.");
        owner = newOwner;
        emit OwnerSet(owner, newOwner);
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
library LibERC20 {
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: Address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
        handleReturn(success, result);
    }

    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: Address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
        handleReturn(success, result);
    }

    function handleReturn(bool _success, bytes memory _result) internal pure {
        if (_success) {
            if (_result.length > 0) {
                require(abi.decode(_result, (bool)), "LibERC20: contract call returned false");
            }
        } else {
            if (_result.length > 0) {
                // bubble up any reason for revert
                revert(string(_result));
            } else {
                revert("LibERC20: contract call reverted");
            }
        }
    }
}
struct LockInfo{
   //param
   uint lockAmount;
   uint firstUnlockTime;
   uint firstUnlockRate;
   uint secondUnlockTime;
   uint secondlockDays;
   //record
   bool isFirstUnlocked;
   uint unlockedDays;
   uint unlockedAmount;
   bool isClosed;
}
struct LockInput{
   //param
   address userAddr;
   uint lockAmount;
   uint firstUnlockTime;
   uint firstUnlockRate;
   uint secondUnlockTime;
   uint secondlockDays;
}
contract SADAILock is Ownable{
   using SafeMath for uint;
   address public sadai;
   uint tokenDecimals=18;
   mapping(address => LockInfo) public lockList;
   uint public totalAccount;
   uint public totalSupply;
   uint public leftSupply;
   uint public basePeriod=5 minutes;//1 days;
   bool isEnableUnlock;

   event TokenDeposit(address sender,uint amount);
   event TokenUnlocked(address sender,uint amount);
   event LockAdded(address userAddr,uint amount);

   constructor(address token,uint decimal) payable{
      require(token!=address(0),'invalid token');
      require(decimal>=0,'invalid decimals');
      sadai=token;
      tokenDecimals=decimal;
      isEnableUnlock=true;
   }
   function queryLockInfo(address userAddr) external view returns(LockInfo memory){
    require(userAddr!=address(0),'invalid address');
   
    //require(lockList[userAddr].lockAmount>0,'lock not exsit');
    return lockList[userAddr];
   }
   function queryUnlockAmount(address userAddr) external view returns(uint avail,bool isFirstUnlocked,uint unlockedDays){
     return _queryUnlockAmount(userAddr);
   }
   function _queryUnlockAmount(address userAddr) internal view returns(uint avail,bool isFirstUnlocked,uint unlockedDays){
     if(!lockList[userAddr].isClosed && lockList[userAddr].lockAmount>0 && block.timestamp>=lockList[userAddr].firstUnlockTime){
         if(lockList[userAddr].unlockedAmount>=lockList[userAddr].lockAmount){
             return (0,false,0);
         }
         if(!lockList[userAddr].isFirstUnlocked && lockList[userAddr].firstUnlockRate>0){
            avail=avail.add(lockList[userAddr].lockAmount.mul(lockList[userAddr].firstUnlockRate).div(100));
            isFirstUnlocked=true;
         }
         if(block.timestamp>=lockList[userAddr].secondUnlockTime){
            unlockedDays=block.timestamp.sub(lockList[userAddr].secondUnlockTime).div(basePeriod).sub(lockList[userAddr].unlockedDays);
            if(unlockedDays>lockList[userAddr].secondlockDays.sub(lockList[userAddr].unlockedDays)){
                unlockedDays=lockList[userAddr].secondlockDays.sub(lockList[userAddr].unlockedDays);
            }
            avail=avail.add(lockList[userAddr].lockAmount.mul(100-lockList[userAddr].firstUnlockRate).div(100).mul(unlockedDays).div(lockList[userAddr].secondlockDays));
         }
         if(avail.add(lockList[userAddr].unlockedAmount)>lockList[userAddr].lockAmount){
                avail=lockList[userAddr].lockAmount.sub(lockList[userAddr].unlockedAmount);
         }
         if(avail<=0){
            unlockedDays=0;
         }         
         
     }else{
        return (0,false,0);
     }
   }
   function unlockAmount(uint amount) external returns(uint unlockedmount) {
      require(isEnableUnlock,'unlock is disabled now');
      (uint avail,bool isFirstUnlocked,uint unlockedDays)=_queryUnlockAmount(msg.sender);
      unlockedmount=avail.min(amount);
      require(unlockedmount>0,'insufficient unlocked amount');
      require(leftSupply>=unlockedmount,'insufficient left Supply');

      //record
      leftSupply=leftSupply.sub(unlockedmount);
      if(isFirstUnlocked){
        lockList[msg.sender].isFirstUnlocked=true;
      }
      lockList[msg.sender].unlockedDays=lockList[msg.sender].unlockedDays.add(unlockedDays);
      lockList[msg.sender].unlockedAmount=lockList[msg.sender].unlockedAmount.add(unlockedmount);
      if(lockList[msg.sender].unlockedAmount>=lockList[msg.sender].lockAmount){
          //close
          lockList[msg.sender].isClosed=true;
          if(totalAccount>0){
              totalAccount=totalAccount.sub(1);
          }
      }
      LibERC20.transfer(sadai, msg.sender,amount);
      emit TokenUnlocked(msg.sender,amount);
   }
   function getTotalInfo() external view returns(uint supply,uint left,uint account){
       supply=totalSupply;
       left=leftSupply;
       account=totalAccount;
   }
   /**************以下为管理方法******/
   function deposit(uint amount) external onlyOwner returns(bool result){
     totalSupply=totalSupply.add(amount);
     leftSupply=leftSupply.add(amount);
     LibERC20.transferFrom(sadai, msg.sender,address(this), amount);
     result=true;
     emit TokenDeposit(msg.sender, amount);
   }

   function addLockAccount(address userAddr,uint lockAmount,uint firstUnlockTime,uint firstUnlockRate,uint secondUnlockTime,uint lockDays) external onlyOwner returns(bool success) {
     return _addLockAccount(userAddr,lockAmount,firstUnlockTime,firstUnlockRate,secondUnlockTime,lockDays);
   }

   function _addLockAccount(address userAddr,uint lockAmount,uint firstUnlockTime,uint firstUnlockRate,uint secondUnlockTime,uint secondLockDays) internal returns(bool success){
     require(userAddr!=address(0),'invalid address');
     require(lockList[userAddr].lockAmount<=0 || lockList[userAddr].unlockedAmount>=lockList[userAddr].lockAmount,'lock exsit');
     require(firstUnlockRate>=0 && firstUnlockRate<=100,'invalid firstUnlockRate');
     require(secondUnlockTime>=firstUnlockTime,'second lock time error');
     require(secondLockDays>0 || firstUnlockRate==100,'lockDays must be greater than 0');
     if(firstUnlockTime<=0){
         firstUnlockTime=block.timestamp;
     }
     if(secondUnlockTime<=0){
         secondUnlockTime=block.timestamp;
     }
     lockList[userAddr].lockAmount=lockAmount * 10 ** tokenDecimals;
     lockList[userAddr].firstUnlockTime=firstUnlockTime;
     lockList[userAddr].firstUnlockRate=firstUnlockRate;
     lockList[userAddr].secondUnlockTime=secondUnlockTime;
     lockList[userAddr].secondlockDays=secondLockDays;
     //record reset
     lockList[userAddr].isFirstUnlocked=false;
     lockList[userAddr].unlockedDays=0;
     lockList[userAddr].unlockedAmount=0;
     lockList[userAddr].isClosed=false;
     totalAccount=totalAccount.add(1);
     success=true;
     emit LockAdded(userAddr,lockAmount);
     
   }

   function multiAddLockInfo(LockInput[] calldata lockInputs) external onlyOwner{
      require(lockInputs.length>0,'array is empty');
      require(lockInputs.length<=100,'array length must be less than 100');
      for(uint i=0;i<lockInputs.length;i++){
        _addLockAccount(lockInputs[i].userAddr,lockInputs[i].lockAmount,lockInputs[i].firstUnlockTime,lockInputs[i].firstUnlockRate,lockInputs[i].secondUnlockTime,lockInputs[i].secondlockDays);
      }
   }
   function pauseUnlock(bool isPause) external onlyOwner{
      isEnableUnlock=isPause;
   }
   function getCurrentTime() external view returns(uint){
       return block.timestamp;
   }



}