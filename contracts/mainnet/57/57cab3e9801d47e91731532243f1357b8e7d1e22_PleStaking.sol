/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
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
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint256(_at(set._inner, index)));
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
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    // Mutative functions
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract PleStaking {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    event RewardsTransferred(address holder, uint256 amount);

    IERC20 public tokenContract;

    address public tokenFeeAddress;

    // reward rate 40.00% per year
    uint256 public constant rewardRate = 4000;
    uint256 public constant rewardInterval = 365 days;

    // staking fee 1.50 percent
    uint256 public constant stakingFeeRate = 150;

    // unstaking fee 0.50 percent
    uint256 public constant unstakingFeeRate = 50;

    uint256 public totalClaimedRewards = 0;

    EnumerableSet.AddressSet private holders;

    mapping(address => uint256) public depositedTokens;
    mapping(address => uint256) public stakingTime;
    mapping(address => uint256) public lastClaimedTime;
    mapping(address => uint256) public totalEarnedTokens;

    constructor(address _tokenAddress, address _tokenFeeAddress) public {
        tokenContract = IERC20(_tokenAddress);
        tokenFeeAddress = _tokenFeeAddress;
    }

    function getBalance() private view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }

    function getRewardToken() private view returns (uint256) {
        uint256 totalDepositedAmount = 0;
        uint256 length = getNumberOfHolders();
        for (uint256 i = 0; i < length; i = i.add(1)) {
            uint256 depositedAmount = depositedTokens[holders.at(i)];
            totalDepositedAmount = totalDepositedAmount.add(depositedAmount);
        }

        return tokenContract.balanceOf(address(this)).sub(totalDepositedAmount);
    }

    function distributeToken(address account) private {
        uint256 pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
            tokenContract.balanceOf(address(this)).sub(pendingDivs);
            tokenContract.balanceOf(account).add(pendingDivs);
            require(
                tokenContract.transfer(account, pendingDivs),
                "Could not transfer tokens."
            );
            totalEarnedTokens[account] = totalEarnedTokens[account].add(
                pendingDivs
            );
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
       lastClaimedTime[account] = now;
    }
  
   
    function getPendingDivs(address _holder) public view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;
        if (getRewardToken() == 0) return 0;

        uint256 timeDiff = now.sub(lastClaimedTime[_holder]);
        uint256 stakedAmount = depositedTokens[_holder];
        
        uint256 pendingDivs = stakedAmount.mul(timeDiff).mul(rewardRate).div(rewardInterval).div(1e4);

        return pendingDivs;
    }

    function getNumberOfHolders() public view returns (uint256) {
        return holders.length();
    }

    function stake(uint256 amountToStake) public {
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(
            tokenContract.transferFrom(
                msg.sender,
                address(this),
                amountToStake
            ),
            "Insufficient Token Allowance"
        );
        
      

        uint256 fee = amountToStake.mul(stakingFeeRate).div(1e4);
        uint256 amountAfterFee = amountToStake.sub(fee);

        require(
            tokenContract.transfer(tokenFeeAddress, fee),
            "Could not transfer deposit fee."
        );

        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(
            amountAfterFee
        );

        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = now;
            lastClaimedTime[msg.sender] = now;
        }
    }

    function unstake(uint256 amountToWithdraw) public {
        require(
            depositedTokens[msg.sender] >= amountToWithdraw,
            "Invalid amount to withdraw"
        );
        
     
        
        uint256 fee = amountToWithdraw.mul(unstakingFeeRate).div(1e4);
        uint256 amountAfterFee = amountToWithdraw.sub(fee);
        require(
            tokenContract.transfer(tokenFeeAddress, fee),
            "Could not transfer unstaking fee."
        );
        require(
            tokenContract.transfer(msg.sender, amountAfterFee),
            "Could not transfer tokens."
        );

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(
            amountToWithdraw
        );

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }

    function claimDivs() public {
        distributeToken(msg.sender);
    }

    function getStakersList(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (
            address[] memory stakers,
            uint256[] memory stakingTimestamps,
            uint256[] memory lastClaimedTimeStamps,
            uint256[] memory stakedTokens
        )
    {
        require(startIndex < endIndex);

        uint256 length = endIndex.sub(startIndex);
        address[] memory _stakers = new address[](length);
        uint256[] memory _stakingTimestamps = new uint256[](length);
        uint256[] memory _lastClaimedTimeStamps = new uint256[](length);
        uint256[] memory _stakedTokens = new uint256[](length);

        for (uint256 i = startIndex; i < endIndex; i = i.add(1)) {
            address staker = holders.at(i);
            uint256 listIndex = i.sub(startIndex);
            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] = stakingTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositedTokens[staker];
        }

        return (
            _stakers,
            _stakingTimestamps,
            _lastClaimedTimeStamps,
            _stakedTokens
        );
    }
}