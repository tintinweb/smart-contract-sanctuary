/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

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

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ORMstaking {
    using EnumerableSet for EnumerableSet.AddressSet;
    event RewardsTransferred(address holder, uint256 amount);

    IERC20 public tokenContract;

    address public tokenFeeAddress;
    
   

    // reward rate 40.00% per year
    uint256 public constant REWARD_RATE = 4000;
    uint256 public constant REWARD_INTERVAL = 365 days; 

    // staking fee 1.50 percent
    uint256 public constant STAKE_FEE_RATE = 150;

    // unstaking fee 0.50 percent
    uint256 public constant UNSTAKE_FEE_RATE = 50;

    EnumerableSet.AddressSet private holders;
    uint256 public rewardInitAmount;
    
    address private admin;

    struct Holder {
        uint256 depositAmount;
        uint256 stakedTime;
        uint256 lastClaimedTime;
        uint256 totalEarnedTokens;
      
    }

    mapping(address => Holder) public stakeHolders;
    // uint256 public totalReward;
    
    modifier checkAddress(address _tokenAddress,address _feeAddress){
        require(_tokenAddress != address(0) || _feeAddress !=address(0),"The address can not be zero.");
        _;
    }
    
    modifier onlyOwner {
        require(msg.sender == admin,'The admin is not.');
        _;
    }

    constructor(address tokenAddress_, address tokenFeeAddress_) 
    checkAddress(tokenAddress_,tokenFeeAddress_) {
       
        tokenContract = IERC20(tokenAddress_);
        tokenFeeAddress = tokenFeeAddress_;
        admin = msg.sender;
    }

    function getBalance(address account) internal view returns (uint256) {
        return tokenContract.balanceOf(account);
    }
    
    // distribute reward token to staker 
    function updateDistributedToken(address account) internal{
        uint256 lastReward = getPendingDivs(account);
        if(lastReward > 0) {
              stakeHolders[account].totalEarnedTokens =
                    stakeHolders[account].totalEarnedTokens +
                    lastReward;
        }
        
      
    }

    function updateStaking(address account) internal {
            uint256 currentReward = getPendingDivs(account);
            uint256 reward = stakeHolders[account].totalEarnedTokens + currentReward;
            require(reward >= rewardInitAmount,"The reward amount is over.");
            
            if(reward > 0){
          
            require(
                tokenContract.transfer(account, reward),
                "Could not transfer tokens."
            );
             
              stakeHolders[account].totalEarnedTokens = 0;
              stakeHolders[account].lastClaimedTime = block.number;
              
              // reward amount update
              rewardInitAmount = rewardInitAmount - reward;
         
              
              emit RewardsTransferred(account, reward);
            }
          
    }
    
    
    function getPendingDivs(address _holder) public view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (stakeHolders[_holder].depositAmount == 0) return 0;
        if(rewardInitAmount == 0) return 0;
        
            uint256 timeDiff = block.number -
                stakeHolders[_holder].lastClaimedTime;

            uint256 pendingDivs = (stakeHolders[_holder].depositAmount *
                timeDiff *
                REWARD_RATE) /
                REWARD_INTERVAL * 24 * 60 * 60/
                1e4;
          
            
            return pendingDivs;
    }

    function getNumberOfHolders() external view returns (uint256) {
        return holders.length();
    }

    function stake(uint256 amountToStake) external {
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(
            tokenContract.transferFrom(
                msg.sender,
                address(this),
                amountToStake
            ),
            "Insufficient Token Allowance"
        );
       
     
            uint256 fee = (amountToStake * STAKE_FEE_RATE) / 1e4;
            uint256 amountAfterFee = amountToStake - fee;
            require(
                tokenContract.transfer(tokenFeeAddress, fee),
                "Could not transfer deposit fee."
            );
          
        if (!holders.contains(msg.sender)) {
         
            holders.add(msg.sender);
            stakeHolders[msg.sender].stakedTime = block.number;
        
            
        } else{
            updateDistributedToken(msg.sender);
        }
        
        stakeHolders[msg.sender].depositAmount =
                stakeHolders[msg.sender].depositAmount +
                amountAfterFee;
        stakeHolders[msg.sender].lastClaimedTime = block.number;
    }
    
    
    

    function unstake(uint256 amountToWithdraw) external {
        require(
            stakeHolders[msg.sender].depositAmount >= amountToWithdraw,
            "Invalid amount to withdraw"
        );
         updateDistributedToken(msg.sender);

          uint256 fee = (amountToWithdraw * UNSTAKE_FEE_RATE) / 1e4;
          uint256 amountAfterFee = amountToWithdraw - fee;
          require(
                tokenContract.transfer(tokenFeeAddress, fee),
                "Could not transfer unstaking fee."
            );
            require(
                tokenContract.transfer(msg.sender, amountAfterFee),
                "Could not transfer tokens."
            );
            stakeHolders[msg.sender].depositAmount =
                stakeHolders[msg.sender].depositAmount -
                amountToWithdraw;
            stakeHolders[msg.sender].lastClaimedTime = block.number;
    }

    function claimDivs() external {
        updateStaking(msg.sender);
    }

    function getStakersList(uint256 startIndex, uint256 endIndex)
        external
        view
        returns (
            address[] memory stakers,
            uint256[] memory stakingTimestamps,
            uint256[] memory lastClaimedTimeStamps,
            uint256[] memory stakedTokens
        )
    {
        require(startIndex < endIndex);

        uint256 length = endIndex - startIndex;
        address[] memory _stakers = new address[](length);
        uint256[] memory _stakingTimestamps = new uint256[](length);
        uint256[] memory _lastClaimedTimeStamps = new uint256[](length);
        uint256[] memory _stakedTokens = new uint256[](length);

        for (uint256 i = startIndex; i < endIndex; i++) {
            address staker = holders.at(i);
            unchecked {
                uint256 listIndex = i - startIndex;
                _stakers[listIndex] = staker;
                _stakingTimestamps[listIndex] = stakeHolders[staker].stakedTime;
                _lastClaimedTimeStamps[listIndex] = stakeHolders[staker]
                .lastClaimedTime;
                _stakedTokens[listIndex] = stakeHolders[staker].depositAmount;
            }
        }

        return (
            _stakers,
            _stakingTimestamps,
            _lastClaimedTimeStamps,
            _stakedTokens
        );
    }
    
    function depositReward(uint256 amount) external onlyOwner{
        require(amount > 0,'The amount can not be zero.');
        require(
            tokenContract.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Insufficient Token Allowance"
        );
        rewardInitAmount = rewardInitAmount + amount;
        
  
    }
    
    function setAdmin(address newAddress) external onlyOwner{
        require(newAddress != address(0),"The new address can not be zero.");
        admin = newAddress;
    }
}