/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity 0.6.12;
// SPDX-License-Identifier: MIT

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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
 
library EnumerableSet {
   

    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

     
    function _remove(Set storage set, bytes32 value) private returns (bool) {
      
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {  
             
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

         

            bytes32 lastvalue = set._values[lastIndex];

         
            set._values[toDeleteIndex] = lastvalue;
            
            set._indexes[lastvalue] = toDeleteIndex + 1; 
            
            set._values.pop();
 
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

 
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

  
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
 

    struct AddressSet {
        Set _inner;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

   
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

   
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


  
    struct UintSet {
        Set _inner;
    }

    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

   
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

 
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

     
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
 
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SalvationPad_IDO is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
  
    /* Defining Initial Parameters */
    mapping(address => uint) stakers;
    mapping(address => uint) stakersActual;
    mapping(address => uint) nextClaim;
    mapping(address => bool) allowedUsers;
    bool public canClaim = false; 
    bool public refundEnabled = false; 
    uint public currentPoolAmount = 0;    

    address public idoToken = 0x262b92d7da5Cdb537A6a0d764aA64A22f94dD928; // ido token
    address public holdersToken = 0x262b92d7da5Cdb537A6a0d764aA64A22f94dD928; // slvtn token

    uint public  stakingStart = 1620518400; // staking starting time
    uint public  stakeEnds = 1620345600; // staking ending time
    uint public  userMaxStake = 5*1e18; // max stake 5 tokens

    uint public  softCapAmount = 500*1e18; // 500 bnb max
    uint public  hardCapAmount = 1000*1e18; // 1000 bnb max
    uint public  holdersAmount = 100*1e18; // Must hold to participate
    uint public  poolRate = 1650; // (16.5%) rate of token emission
    uint public  userMaxClaimPercentage = 2000; // (20%) max claim percentage per claimInterval
    uint public  claimInterval = 1 days;
    
    function stake() payable public {
        require(allowedUsers[msg.sender] == true , "User Not Allowed");
        require(Token(holdersToken).balanceOf(msg.sender) > holdersAmount, "Must own holdersAmount");
        require(msg.value.add(stakers[msg.sender]) <= userMaxStake, "Per user limit reached. Can't Pool");
        require(msg.value.add(currentPoolAmount) <= hardCapAmount, "No more Deposit Allowed. Pool is Full");
        require(stakingStart < now, "Pool Not Started Yet");
        require(stakeEnds > now, "Pool Expired");
        
        stakers[msg.sender] = stakers[msg.sender].add(msg.value);
        stakersActual[msg.sender] = stakersActual[msg.sender].add(msg.value);
        currentPoolAmount = currentPoolAmount.add(msg.value);   
    }  

    function includeAccount(address _user) public onlyOwner {
        allowedUsers[_user] = true;
    } 
    
    function excludeAccount(address _user) public onlyOwner {
        allowedUsers[_user] = false;
    } 

    function accountAllowed(address _user) public view returns (bool) {
           return allowedUsers[_user];
    } 
        
    function getStakers(address _user)  public view returns (uint) {
        uint amount = stakers[_user];
        return amount;
    }

    function getPendingToken(address _user)  public view returns (uint) {
        uint token = stakers[_user].mul(poolRate).div(100);
        return token;
    }
    
    function getNextClaim(address _user)  public view returns (uint) {
        uint nclaim = nextClaim[_user];
        return nclaim;
    }

    function getCurrentPendingToken(address _user)  public view returns (uint) {
        uint token = 0;
        if(nextClaim[_user] < now){
            token = stakersActual[_user].mul(poolRate).div(100);
            token = token.mul(userMaxClaimPercentage).div(1e4);
        }
        
        return token;
    }

    function claim(address _user)  public  {
        require(stakeEnds < now, "Pool is still on");
        require(currentPoolAmount < softCapAmount && canClaim == false, "Not Allowed. Pool softcap not met");
        require(canClaim == true, "Claim Not Allowed");
        require(nextClaim[_user] < now, "Claim Not Allowed. Next claim time not reached.");
        
        uint currentAmount = stakersActual[_user].mul(userMaxClaimPercentage).div(1e4);
        
        if(currentAmount > stakers[_user]){
            currentAmount = stakers[_user]; 
        }
        
        uint token = currentAmount.mul(poolRate).div(100);
            
        stakers[_user] = stakers[_user].sub(currentAmount);
        nextClaim[_user] = nextClaim[_user].add(now).add(claimInterval);
        Token(idoToken).transfer(_user, token);
    }

    function claimBNB() public {
        require(stakeEnds < now, "Pool is still on");
        require(currentPoolAmount > softCapAmount && refundEnabled == true, "Not Allowed. Pool softcap reached.");

        msg.sender.transfer(stakersActual[msg.sender]);
    }

    function withdrawBNB() public onlyOwner{
        msg.sender.transfer(address(this).balance);
    }

    function updateIDOToken(address _tokenAddr) public onlyOwner{
        idoToken = _tokenAddr;
    }
    
    function updateHoldersToken(address _tokenAddr) public onlyOwner{
        holdersToken = _tokenAddr;
    }

    function updatePoolRate(uint _poolRate) public onlyOwner{
        poolRate = _poolRate;
    }

    function updateStakeEnds(uint _stakeEnds) public onlyOwner{
        stakeEnds = _stakeEnds;
    }

    function updateStakingStart(uint _stakingStart) public onlyOwner{
        stakingStart = _stakingStart;
    }
    
    function updateCanClaim(bool _claim) public onlyOwner{
        canClaim = _claim;
    }

    function updateSoftcapAmount(uint _softcapAmount) public onlyOwner{
        softCapAmount = _softcapAmount;
    }

    function updateHardcapAmount(uint _hardCapAmount) public onlyOwner{
        hardCapAmount = _hardCapAmount;
    }
    
    function updateHoldersAmount(uint _holdersAmount) public onlyOwner{
        holdersAmount = _holdersAmount;
    }

    function updateCurrentPoolAmount(uint _currentPoolAmount) public onlyOwner{
        currentPoolAmount = _currentPoolAmount;
    }

    function updatePerUserMaxPool(uint _userMaxPool) public onlyOwner{
        userMaxStake = _userMaxPool;
    }

    function updateStakersPool(address _user, uint _amount) public onlyOwner{
        stakers[_user] = _amount;
    }

    function OwnertransferAnyERC20Tokens(address _tokenAddr, address _to, uint256 _amount) public onlyOwner {        
        Token(_tokenAddr).transfer(_to, _amount);
    }

}