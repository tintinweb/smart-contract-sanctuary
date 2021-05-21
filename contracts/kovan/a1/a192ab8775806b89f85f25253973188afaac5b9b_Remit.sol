/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
 }

contract Ownable {
    
    modifier onlyOwner() {
        require(msg.sender==owner,"only owner allowed");
        _;
    }
    
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    
    address payable owner;
    address payable newOwner;

    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner, "only new owner allowed");
         emit OwnershipTransferred(
            owner,
            newOwner
        );
        owner = newOwner;
        
    }
}

abstract contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is Ownable,  ERC20 {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    string public symbol;
    string public name;
    uint8 public decimals;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    
 
    uint256 public circulationSupply;
    uint256 public stakeFarmSupply;
    uint256 public teamAdvisorSupply;
    uint256 public devFundSupply;
    uint256 public marketingSupply;
    uint256 public resverdSupply;
    
    uint256 public teamCounter; 
    uint256 public devFundCounter;
    
    mapping(uint256 => uint256) public  stakeFarmSupplyUnlockTime;
    mapping(uint256 => uint256) public  stakeFarmUnlockSupply;
    
    mapping(uint256 => uint256) public  teamAdvisorSupplyUnlockTime;
    mapping(uint256 => uint256) public  teamAdvisorSupplyUnlockSupply;
    
    mapping(uint256 => uint256) public  devFundSupplyUnlockTime;
    mapping(uint256 => uint256) public  devFundSupplyUnlockSupply;
    
    mapping(uint256 => uint256) public  marketingSupplyUnlockTime;
    mapping(uint256 => uint256) public  marketingUnlockSupply;
    
    mapping(uint256 => uint256) public  resverdSupplyUnlockTime;
    mapping(uint256 => uint256) public  resverdUnlockSupply;
    
	
	uint256 constant public maxSupply = 5000000 ether;
	uint256 constant public supplyPerYear =  1000000 ether;
	uint256 constant public oneYear = 31536000;
	uint256 constant public teamAdvisorPeriod = 5256000;
	uint256 constant public devFundPeriod = 2628000;
	

    EnumerableSet.AddressSet private farmAddress;
    address public stakeAddress;

   
    function balanceOf(address _owner) view public virtual override returns (uint256 balance) {return balances[_owner];}
    
    
    function transfer(address _to, uint256 _amount) public virtual override returns (bool success) {
      require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
      balances[msg.sender]-=_amount;
      balances[_to]+=_amount;
      emit Transfer(msg.sender,_to,_amount);
      return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public virtual override returns (bool success) {
      require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
      balances[_from]-=_amount;
      allowed[_from][msg.sender]-=_amount;
      balances[_to]+=_amount;
      emit Transfer(_from, _to, _amount);
      return true;
    }
  
    function approve(address _spender, uint256 _amount) public virtual override returns (bool success) {
      allowed[msg.sender][_spender]=_amount;
      emit Approval(msg.sender, _spender, _amount);
      return true;
    }
    
    function allowance(address _owner, address _spender) view public virtual override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function burn(uint256 _amount) public onlyOwner returns (bool success) {
      require(_amount <= totalSupply, "The burning value cannot be greater than the Total Supply!");
      address addressToBurn = 0x2323232323232323232323232323232323232323;
      uint256 feeToOwner = _amount * 3 / 100; // 3%
      transfer(addressToBurn, _amount - feeToOwner); // burn
      transfer(owner, feeToOwner); // transfer to owner address
      return true;
    }

    function mint(address _to, uint256 _amount) private returns (bool) {
      require((_amount + totalSupply) <= maxSupply, "The total supply cannot exceed 5.000.000");
      totalSupply = totalSupply + _amount;
      balances[_to] = balances[_to] + _amount;
      emit Transfer(address(0), _to, _amount);
      return true;
    }
    
    
    function mintCirculationSupply(address to,uint256 _amount) external onlyOwner returns(bool){
        require(circulationSupply >= _amount);    
        mint(to,_amount);
        circulationSupply -= _amount;
        return true;
    }
    
    function mintMarketingSupply(address to,uint256 _amount) external onlyOwner returns(bool){
        for(uint i = 1;i <= 4 ; i++){
            if(marketingSupplyUnlockTime[i] < now && marketingUnlockSupply[i] != 0){
                marketingSupply += marketingUnlockSupply[i];
                marketingUnlockSupply[i] = 0;
            }
            if(marketingSupplyUnlockTime[i] >  now)
              break;
        }
        require(marketingSupply >= _amount);    
        mint(to,_amount);
        marketingSupply -= _amount;
        return true;
    }
    
    
    function setFarmAddress(address[] memory _farm) external onlyOwner returns(bool){
        for(uint256 i= 0 ;i< _farm.length;i++)
        {
            farmAddress.add(_farm[i]);
        }
        
        return true;
    }
    
    function setStakeAddress(address _stake) external onlyOwner returns(bool){
        stakeAddress = _stake;
        return true;
    }
    
    function mintStakeFarmSupply(address to,uint256 _amount) external returns(uint256){
        require(farmAddress.contains(msg.sender) || msg.sender == stakeAddress,"err farm or stake address only");
        for(uint i = 1;i <= 4 ; i++){
            if(stakeFarmSupplyUnlockTime[i] < now && stakeFarmUnlockSupply[i] != 0){
                stakeFarmSupply += stakeFarmUnlockSupply[i];
                stakeFarmUnlockSupply[i] = 0;
            }
            if(stakeFarmSupplyUnlockTime[i] >  now)
              break;
        }
        if(_amount > stakeFarmSupply){
            _amount = stakeFarmSupply;
        }    
        mint(to,_amount);
        stakeFarmSupply -= _amount;
        return _amount;
    }
    
    
    function mintReservedSupply(address to,uint256 _amount) external onlyOwner returns(bool){
        for(uint i = 1;i <= 4 ; i++){
            if(resverdSupplyUnlockTime[i] < now && resverdUnlockSupply[i] != 0){
                resverdSupply += resverdUnlockSupply[i];
                resverdUnlockSupply[i] = 0;
            }
            if(resverdSupplyUnlockTime[i] >  now)
              break;
        }
        require(resverdSupply >= _amount);    
        mint(to,_amount);
        resverdSupply -= _amount;
        return true;
    }
    
    // for loop dont take too much cost as it only loop to 25
    function mintDevFundSupply(address to,uint256 _amount) external onlyOwner returns(bool){
        for(uint i = 1;i <= devFundCounter ; i++){
            if(devFundSupplyUnlockTime[i] < now && devFundSupplyUnlockSupply[i] != 0){
                devFundSupply += devFundSupplyUnlockSupply[i];
                devFundSupplyUnlockSupply[i] = 0;
            }
            if(devFundSupplyUnlockTime[i] >  now)
              break;
        }
        require(devFundSupply >= _amount);    
        mint(to,_amount);
        devFundSupply -= _amount;
        return true;
    }
    
    function mintTeamAdvisorFundSupply(address to,uint256 _amount) external onlyOwner returns(bool){
        for(uint i = 1;i <= teamCounter ; i++){
            if(teamAdvisorSupplyUnlockTime[i] < now && teamAdvisorSupplyUnlockSupply[i] != 0){
                teamAdvisorSupply += teamAdvisorSupplyUnlockSupply[i];
                teamAdvisorSupplyUnlockSupply[i] = 0;
            }
            if(teamAdvisorSupplyUnlockTime[i] >  now)
              break;
        }
        require(teamAdvisorSupply >= _amount);    
        mint(to,_amount);
        teamAdvisorSupply -= _amount;
        return true;
    }

    
    
    function _initSupply() internal returns (bool){
        
        circulationSupply = 370000 ether;
        stakeFarmSupply =  350000 ether;
        marketingSupply = 50000 ether;
        resverdSupply = 10000 ether;
        
        uint256 currentTime = now;
        uint256 tempAdvisor = 100000 ether;
        uint256 tempDev = 120000 ether;
    
        for(uint j = 1;j <= 6 ; j++){
            teamCounter+=1;
            teamAdvisorSupplyUnlockTime[teamCounter] = currentTime+(teamAdvisorPeriod*j);
            teamAdvisorSupplyUnlockSupply[teamCounter] = tempAdvisor/6;
            
        }
        
        for(uint k = 1;k <= 5 ; k++){
            devFundCounter+= 1;
            devFundSupplyUnlockTime[devFundCounter] = currentTime+(devFundPeriod*k);
            devFundSupplyUnlockSupply[devFundCounter] = tempDev/5;
            
        }
        
        
        for(uint i = 1;i <= 4 ; i++){
            currentTime += oneYear;
            
            stakeFarmSupplyUnlockTime[i] = currentTime;
            stakeFarmUnlockSupply[i] = 720000 ether;
         
            marketingSupplyUnlockTime[i] = currentTime;
            marketingUnlockSupply[i] = 50000 ether;
            
            resverdSupplyUnlockTime[i] = currentTime;
            resverdUnlockSupply[i] = 10000 ether;
            
            
           for(uint j = 1;j <= 6 ; j++){
                teamCounter+=1;
                teamAdvisorSupplyUnlockTime[teamCounter] = currentTime+(teamAdvisorPeriod*j);
                teamAdvisorSupplyUnlockSupply[teamCounter] = tempAdvisor/6;
            
           }
        
            for(uint k = 1;k <= 5 ; k++){
                devFundCounter+= 1;
                devFundSupplyUnlockTime[devFundCounter] = currentTime+(devFundPeriod*k);
                devFundSupplyUnlockSupply[devFundCounter] = tempDev/5;
                
            }
             
        }
            
 
    }
   
}

contract Remit is Token{
    
    
    
    constructor() public{
      symbol = "REMIT";
      name = "Remit";
      decimals = 18;
      totalSupply = 0;  
      owner = msg.sender;
      balances[owner] = totalSupply;
      _initSupply();
      
    }
    
    

    receive () payable external {
      require(msg.value>0);
      owner.transfer(msg.value);
    }
}