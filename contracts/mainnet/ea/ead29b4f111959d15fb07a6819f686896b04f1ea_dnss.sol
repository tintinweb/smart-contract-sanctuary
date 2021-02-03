/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

pragma solidity ^0.4.23;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

//manager contract
//manager superAdmin
//manager admin
//manager superAdmin Auth
contract managerContract{
    /**
      * Token holder :
      *     a.Holding tokens
      *     b.No permission to transfer tokens privately
      *     c.Cannot receive tokens, similar to dead accounts
      *     d.Can delegate second-level administrators, but only one can be delegated
      *     e.Have the permission to unlock and transfer tokens, but it depends on the unlocking rules (9800 DNSS unlocked every day)
      *     f.Has the unlock time setting permission, but can only set one time  the unlock time node once
      */
    address superAdmin;

    // Secondary ：The only management is to manage illegal users to obtain DNSS by abnormal means
    mapping(address => address) internal admin;

    //pool address
    address pool;

    //Depends on super administrator authority
    modifier onlySuper {
        require(msg.sender == superAdmin,'Depends on super administrator');
        _;
    }
}

//unLock contract
//manager unLock startTime
//manager circulation ( mining pool out total  )
//manager calculate the number of unlocked DNSS fuction
contract unLockContract {

    //use safeMath for Prevent overflow
    using SafeMath for uint256;

    //start unLock time
    uint256 public startTime;
    //use totalOut for Prevent Locked DNSS overflow
    uint256 public totalToPool = 0;
    //Can't burn DNSS Is 10% of the totalSupply
    uint256 public sayNo = 980 * 1000 * 1000000000000000000 ;

    //get totalUnLockAmount
    function totalUnLockAmount() internal view returns (uint256 _unLockTotalAmount) {
        //unLock start Time not is zero
        if(startTime==0){ return 0;}
        //Has not started to unlock
        if(now <= startTime){ return 0; }
        //unlock total count
        uint256 dayDiff = (now.sub(startTime)) .div (1 days);
        //Total unlocked quantity in calculation period
        uint256 totalUnLock = dayDiff.mul(9800).mul(1000000000000000000);
        //check totalSupply overflow
        if(totalUnLock >= (980 * 10000 * 1000000000000000000)){
            return 980 * 10000 * 1000000000000000000;
        }
        //return Unlocked DNSS total
        return totalUnLock;
    }
}



/**
* DNSS follows the erc-20 protocol
* In order to maintain the maximum rights and interests of DNSS users and achieve
* a completely decentralized consensus mechanism, DNSS will restrict anyone from
* stealing any 9.8 million DNSS from the issuing account, including holders.
* The only way is through the DNSS community committee. The cycle is unlocked for circulation,
* and the DNSS community committee will rigidly restrict the circulation of tokens through this smart contract.
* In order to achieve future deflation of DNSS, the contract will destroy DNSS through the destruction mechanism.
*/
contract dnss is managerContract,unLockContract{

    string public constant name     = "Distributed Number Shared Settlement";
    string public constant symbol   = "DNSS";
    uint8  public constant decimals = 18;
    uint256 public totalSupply = 980 * 10000 * 1000000000000000000 ;

    mapping (address => uint256) public balanceOf;
    
    //use totalBurn for Record the number of burns
    mapping (address => uint256) public balanceBurn;
   

    //event
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    //init
    constructor() public {
        superAdmin = msg.sender ;
        balanceOf[superAdmin] = totalSupply;
    }
    
    //Get unlocked DNSS total
    function totalUnLock() public view returns(uint256 _unlock){
       return totalUnLockAmount();
    }


    //Only the super administrator can set the start unlock time
    function setTime(uint256 _startTime) public onlySuper returns (bool success) {
        require(startTime==0,'already started');
        require(_startTime > now,'The start time cannot be less than or equal to the current time');
        startTime = _startTime;
        require(startTime == _startTime,'The start time was not set successfully');
        return true;
    }

    //Approve admin
    function superApproveAdmin(address _adminAddress) public onlySuper  returns (bool success) {
        //check admin
        require(_adminAddress != 0x0,'is bad');
        admin[_adminAddress] = _adminAddress;
        //check admin
        if(admin[_adminAddress] == 0x0){
             return false;
        }
        return true;
    }


   //Approve pool address
    function superApprovePool(address _poolAddress) public onlySuper  returns (bool success) {
        require(_poolAddress != 0x0,'is bad');
        pool = _poolAddress; //Approve pool
        require(pool == _poolAddress,'is failed');
        return true;
    }


    //burn target address token amout
    //burn total DNSS not more than 90% of the totalSupply
    function superBurnFrom(address _burnTargetAddess, uint256 _value) public onlySuper returns (bool success) {
        require(balanceOf[_burnTargetAddess] >= _value,'Not enough balance');
        require(totalSupply > _value,' SHIT ! YOURE A FUCKING BAD GUY ! Little bitches ');
        //check burn not more than 90% of the totalSupply
        require(totalSupply.sub(_value) >= sayNo,' SHIT ! YOURE A FUCKING BAD GUY ! Little bitches ');
        //burn target address
        balanceOf[_burnTargetAddess] = balanceOf[_burnTargetAddess].sub(_value);
        //totalSupply reduction
        totalSupply=totalSupply.sub(_value);
        emit Burn(_burnTargetAddess, _value);
        //Cumulative DNSS of burns
        balanceBurn[superAdmin] = balanceBurn[superAdmin].add(_value);
        //burn successfully
        return true;
    }


    //Unlock to the mining pool account
    function superUnLock( address _poolAddress , uint256 _amount ) public onlySuper {
        require(pool==_poolAddress,'Mine pool address error');
        require( totalToPool.add(_amount)  <= totalSupply ,'totalSupply balance low');
        //get total UnLock Amount
        uint256 _unLockTotalAmount = totalUnLockAmount();
        require( totalToPool.add(_amount)  <= _unLockTotalAmount ,'Not enough dnss has been unlocked');
        //UnLock totalSupply to pool
        balanceOf[_poolAddress]=balanceOf[_poolAddress].add(_amount);
        //UnLock totalSupply to pool
        balanceOf[superAdmin]=balanceOf[superAdmin].sub(_amount);
        //Cumulative DNSS of UnLock
        totalToPool=totalToPool.add(_amount);
    }


    function _transfer(address _from, address _to, uint _value) internal {
       require(_from != superAdmin,'Administrator has no rights transfer');
       require(_to != superAdmin,'Administrator has no rights transfer');
       require(_to != 0x0);
       require(balanceOf[_from] >= _value);
       require(balanceOf[_to] + _value > balanceOf[_to]);
       uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
       balanceOf[_from] -= _value;
       balanceOf[_to] += _value;
       emit Transfer(_from, _to, _value);
       assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }


     //superAdmin not transfer
    function transfer(address _to, uint256 _value) public returns (bool) {
         _transfer(msg.sender, _to, _value);
    }

     //superAdmin not transfer ;
     //allowance transfer
     //everyone can transfer
     //admin can transfer Illegally acquired assets
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //admin Manage illegal assets
        if(admin[msg.sender] != 0x0){
          _transfer(_from, _to, _value);
        } 
        return true;
    }

}