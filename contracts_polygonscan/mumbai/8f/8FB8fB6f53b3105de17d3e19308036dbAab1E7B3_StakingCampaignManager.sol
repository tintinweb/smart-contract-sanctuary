// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StakingCampaign {
   
    struct StackingInfo {
        uint seq;
        uint amount;
        uint reward;
        bool isPayout;
        uint unlockTime;
    }

    event Deposited (
        address indexed sender,
        uint seq,
        uint amount,
        uint256 timestamp
    );

    event Claimed (
        address indexed sender,
        uint seq,
        uint amount,
        uint reward,
        uint256 timestamp
    );

    address public owner;
    modifier onlyAdmin {
        require(msg.sender == owner, 'Caller is not owner');
        _;
    }

    // ERC20 token for staking campaign
    IERC20 public token;
    // campaign name
    string public name;
    // total day for staking (in second)
    uint public duration;
    // annual percentage rate
    uint public apr;
    // total cap for campaign, stop campaign if cap is reached
    uint public maxCap;
    // expired time of campaign, no more staking is accepted (in second)
    uint public expiredTime; 
    // min amount for one staking deposit
    uint public minTransactionAmount;
    // max amount for one staking deposit
    uint public maxTransactionAmount;
    // total amount already payout for staker (payout = staking amount + reward)
    uint public totalPayoutAmount;
    // total reward need for campaign
    uint public totalCampaignReward;
    // total staked amount
    uint public totalStakedAmount;
    //
    bool public isMaxCapReached = false;

    mapping(address => StackingInfo[]) internal stakingList;

    /**
     * 
     */
    constructor (IERC20 _token, string memory _campaignName, uint _expiredTime, 
                uint _maxCap, uint _maxTransactionAmount, uint _minTransactionAmount,
                uint _duration, uint _apr) {
        owner = msg.sender;
        token = _token;
        name = _campaignName;
        expiredTime = block.timestamp + _expiredTime;
        maxCap = _maxCap;
        maxTransactionAmount = _maxTransactionAmount;
        minTransactionAmount = _minTransactionAmount;
        duration = _duration;
        apr = _apr;
    }

    /**
     * Deposit amount of token to stack
     */
    function deposit(uint _amount, address _userAddr) external {
        require(totalStakedAmount + _amount <= maxCap, "Total cap is reached");
        require(_amount >= minTransactionAmount, "Staking amount is too small");
        require(_amount <= maxTransactionAmount, "Staking amount is too big");
        require(block.timestamp < expiredTime, "Campaign is over");

        token.transferFrom(_userAddr, address(this), _amount);
        uint unlockTime = block.timestamp + duration;
        uint seq = stakingList[_userAddr].length + 1;
        uint reward = _amount*apr*duration/(365*24*60*60*100);

        StackingInfo memory staking = StackingInfo(seq, _amount, reward, false, unlockTime);
        stakingList[_userAddr].push(staking);
       
        totalStakedAmount += _amount;
        totalCampaignReward += reward;

        isMaxCapReached = (totalStakedAmount == maxCap || totalStakedAmount + minTransactionAmount > maxCap);

        emit Deposited(_userAddr, seq, _amount, block.timestamp);
    }

    function claim(uint _seq, address _userAddr) public {
        StackingInfo[] memory userStakings = stakingList[_userAddr];
        require(_seq > 0 && userStakings.length >= _seq, "Invalid index");

        uint idx = _seq - 1;
        
        StackingInfo memory staking = userStakings[idx];

        require(!staking.isPayout, "Stake is already payout");
        require(staking.unlockTime < block.timestamp, "Staking is in lock period");
        
        uint payout = staking.amount + staking.reward;

        token.transfer(_userAddr, payout);
        totalPayoutAmount += payout;
        
        stakingList[_userAddr][idx].isPayout = true;
        
        emit Claimed(_userAddr, _seq, staking.amount, staking.reward, block.timestamp);
    }
    
    function claimRemainingReward(address _userAddr) public onlyAdmin {
        require(block.timestamp > expiredTime, "Campaign is not over yet");

        uint remainingPayoutAmount = totalStakedAmount + totalCampaignReward - totalPayoutAmount;
        uint balance = token.balanceOf(address(this));

        token.transfer(_userAddr, balance - remainingPayoutAmount);
    }

    function getClaimableRemainningReward() public view returns (uint) {
        if(block.timestamp < expiredTime) return 0;
        else {
            uint remainingPayoutAmount = totalStakedAmount + totalCampaignReward - totalPayoutAmount;
            uint balance = token.balanceOf(address(this));
            return balance - remainingPayoutAmount;
        }
    }
    
    function getStakings(address _staker) public view returns (uint[] memory _seqs, uint[] memory _amounts, uint[] memory _rewards, bool[] memory _isPayouts, uint[] memory _timestamps) {
        StackingInfo[] memory userStakings = stakingList[_staker];
        
        uint length = userStakings.length;
        
        uint256[] memory seqList = new uint256[](length);
        uint256[] memory amountList = new uint256[](length);
        uint256[] memory rewardList = new uint256[](length);
        bool[] memory isPayoutList = new bool[](length);
        uint256[] memory timeList = new uint256[](length);
        
        for(uint idx = 0; idx < length; idx++) {
            StackingInfo memory stackingInfo = userStakings[idx];
            
            seqList[idx] = stackingInfo.seq;
            amountList[idx] = stackingInfo.amount;
            rewardList[idx] = stackingInfo.reward;
            isPayoutList[idx] = stackingInfo.isPayout;
            timeList[idx] = stackingInfo.unlockTime;
        }
        
        return (seqList, amountList, rewardList, isPayoutList, timeList);
    }
    
    function getCampaignInfo() public view returns (
            IERC20 _token, string memory _campaignName, uint _expiredTime, 
            uint _maxCap, uint _maxTransactionAmount, uint _minTransactionAmount,
            uint _duration, uint _apr, uint _stakedAmount,uint _totalPayoutAmount) {

        return (token, name, expiredTime, maxCap, maxTransactionAmount, minTransactionAmount, duration, apr, totalStakedAmount, totalPayoutAmount);
    }

    function transferOwnership(address _newOwner) public onlyAdmin {
        owner = _newOwner;
    }
}

contract EIP712Base {
    
  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
  }

  bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
    bytes(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    )
  );

  bytes32 private domainSeparator;

  constructor(string memory name, string memory version, uint256 chainId) {
    domainSeparator = keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        chainId,
        address(this)
      )
    );
  }

  function getDomainSeparator() public view returns (bytes32) {
    return domainSeparator;
  }

  /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
  function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
    return keccak256(
        abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash)
    );
  }
}


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


abstract contract EIP712MetaTransaction is EIP712Base {
  using SafeMath for uint256;

  bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
    bytes(
      "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
    )
  );

  event MetaTransactionExecuted(
    address userAddress,
    address payable relayerAddress,
    bytes functionSignature
  );

  mapping(address => uint256) nonces;

  /*
   * Meta transaction structure.
   * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
   * He should call the desired function directly in that case.
   */
  struct MetaTransaction {
    uint256 nonce;
    address from;
    bytes functionSignature;
  }

  function executeMetaTransaction(
    address userAddress,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public payable returns (bytes memory) {
    MetaTransaction memory metaTx = MetaTransaction({
      nonce: nonces[userAddress],
      from: userAddress,
      functionSignature: functionSignature
    });

    require(
      verify(userAddress, metaTx, sigR, sigS, sigV),
      "Signer and signature do not match"
    );

    // increase nonce for user (to avoid re-use)
    nonces[userAddress] = nonces[userAddress].add(1);

    emit MetaTransactionExecuted(
      userAddress,
      payable(msg.sender),
      functionSignature
    );

    // Append userAddress and relayer address at the end to extract it from calling context
    (bool success, bytes memory returnData) = address(this).call(
      abi.encodePacked(functionSignature, userAddress)
    );
    require(success, "Function call not successful");

    return returnData;
  }

  function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
    return keccak256(
      abi.encode(
        META_TRANSACTION_TYPEHASH,
        metaTx.nonce,
        metaTx.from,
        keccak256(metaTx.functionSignature)
      )
    );
  }

  function msgSender() internal view returns (address payable sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
            mload(add(array, index)),
            0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      sender = payable(msg.sender);
    }

    return sender;
  }

  function getNonce(address user) public view returns (uint256 nonce) {
    nonce = nonces[user];
  }

  function verify(
    address signer,
    MetaTransaction memory metaTx,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) internal view returns (bool) {
    require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
    return signer == ecrecover(
      toTypedMessageHash(hashMetaTransaction(metaTx)),
      sigV,
      sigR,
      sigS
    );
  }
}


contract StakingCampaignManager is EIP712MetaTransaction {

    string private constant DOMAIN_NAME = "morpheuslabs.io";
    string private constant DOMAIN_VERSION = "1";

    address public owner;
    modifier onlyAdmin {
        require(msgSender() == owner, 'StakingCampaignManager: Caller is not owner');
        _;
    }

    // Authorized list
    mapping(address => bool) public authorized;

    modifier isAuthorized() {
        require(
            msgSender() == owner || authorized[msgSender()] == true, 
            "StakingCampaignManager: unauthorized"
        );
        _;
    }

    bool public _authorizationEnabled;

    struct AddressBlockNum {
        address addr;
        uint256 blockNum;
    }
    AddressBlockNum[] public campaignAddressBlockNumList;

    constructor() EIP712Base(DOMAIN_NAME, DOMAIN_VERSION, block.chainid) {
        owner = msgSender();
        _authorizationEnabled = false;
    }

    function enableAuthorization() public onlyAdmin {
        _authorizationEnabled = true;
    }

    function disableAuthorization() public onlyAdmin {
        _authorizationEnabled = false;
    }

    function addAuthorized(address auth) public onlyAdmin {
        authorized[auth] = true;
    }

    function addAuthorizedBatch(address[] memory authList) public onlyAdmin {
        for (uint256 i = 0; i < authList.length; i++) {
            addAuthorized(authList[i]);
        }
    }

    function clearAuthorized(address auth) public onlyAdmin {
        authorized[auth] = false;
    }

    function clearAuthorizedBatch(address[] memory authList) public onlyAdmin {
        for (uint256 i = 0; i < authList.length; i++) {
            clearAuthorized(authList[i]);
        }
    }

    function checkAuthorized(address auth) public view returns (bool) {
        if (msgSender() == owner) {
            return true;
        } else {
            return authorized[auth];
        }
    }

    function getCampaignAddressBlockNumListCount() external view returns (uint256) {
        return campaignAddressBlockNumList.length;
    }

    function getCampaignAddressBlockNumAtIndex(uint256 _index) 
    external view returns (address, uint256) {
        return (
            campaignAddressBlockNumList[_index].addr,
            campaignAddressBlockNumList[_index].blockNum
        );
    }
   
    function deployCampaign (IERC20 _token, string memory _campaignName, uint _expiredTime, 
                uint _maxCap, uint _maxTransactionAmount, uint _minTransactionAmount,
                uint _duration, uint _apr) external onlyAdmin {

        StakingCampaign campaignContract = new StakingCampaign(
            _token, _campaignName, _expiredTime, 
            _maxCap, _maxTransactionAmount, _minTransactionAmount,
            _duration, _apr
        );

        AddressBlockNum memory addrBlockNum;
        addrBlockNum.addr = address(campaignContract);
        addrBlockNum.blockNum = block.number;
        campaignAddressBlockNumList.push(addrBlockNum);
    }

    /**
     * Deposit amount of token to stack
     */
    function deposit(uint _amount, address _campaignContractAddress) external {
        require(!_authorizationEnabled || checkAuthorized(msgSender()), "StakingCampaignManager: unauthorized deposit");
        StakingCampaign campaignContract = StakingCampaign(_campaignContractAddress);
        campaignContract.deposit(_amount, msgSender());
    }

    function claim(uint _seq, address _campaignContractAddress) external {
        StakingCampaign campaignContract = StakingCampaign(_campaignContractAddress);
        campaignContract.claim(_seq, msgSender());
    }
    
    function claimRemainingReward(address _campaignContractAddress) external onlyAdmin {
        StakingCampaign campaignContract = StakingCampaign(_campaignContractAddress);
        campaignContract.claimRemainingReward(msgSender());
    }

    function getClaimableRemainningReward(address _campaignContractAddress) external view returns (uint) {
        StakingCampaign campaignContract = StakingCampaign(_campaignContractAddress);
        return campaignContract.getClaimableRemainningReward();
    }
    
    function getStakings(address _staker, address _campaignContractAddress) 
        external view returns (
            uint[] memory _seqs, uint[] memory _amounts, uint[] memory _rewards, bool[] memory _isPayouts, uint[] memory _timestamps
        ) {
        StakingCampaign campaignContract = StakingCampaign(_campaignContractAddress);
        return campaignContract.getStakings(_staker);
    }
    
    function getCampaignInfo(address _campaignContractAddress) external view returns (
            IERC20 _token, string memory _campaignName, uint _expiredTime, 
            uint _maxCap, uint _maxTransactionAmount, uint _minTransactionAmount,
            uint _duration, uint _apr, uint _stakedAmount,uint _totalPayoutAmount) {

        StakingCampaign campaignContract = StakingCampaign(_campaignContractAddress);
        return campaignContract.getCampaignInfo();
    }
}