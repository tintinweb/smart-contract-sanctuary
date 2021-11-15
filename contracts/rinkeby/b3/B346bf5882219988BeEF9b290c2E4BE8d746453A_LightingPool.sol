// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./Ownable.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract LightingPool is Ownable {

  //token attributes
  string public constant NAME = "lightning.network"; //name of the contract
  uint public maxCap; // Max cap in BNB
  uint256 public saleStartTime; // start sale time
  uint256 public saleEndTime; // end sale time
  uint256 public totalBnbReceivedInAllTier; // total bnd received
  uint256 public totalBnbInBronzeTier; // total bnb for bronze tier
  uint256 public totalBnbInSilverTier; // total bnb for silver tier
  uint256 public totalBnbInGoldTier; // total bnb for gold tier
  uint256 public totalBnbInDiamondTier; // total bnb for diamond tier
  uint public totalparticipants; // total participants in ido
  address payable public projectOwner; // project Owner

  address public lightToken;
  
  // max cap per tier
  uint public bronzeMaxCap;
  uint public silverMaxCap;
  uint public goldMaxCap;
  uint public diamondMaxCap;
  
  //total users per tier
  uint public totalUserInBronzeTier;
  uint public totalUserInSilverTier;
  uint public totalUserInGoldTier;
  uint public totalUserInDiamondTier;
  
  //max allocations per user in a tier
  uint public maxAllocaPerUserBronzeTier;
  uint public maxAllocaPerUserSilverTier; 
  uint public maxAllocaPerUserGoldTier;
  uint public maxAllocaPerUserDiamondTier;
 
  // address array for bronze tier whitelist
  address[] private whitelistBronzeTier; 
  
  // address array for silver tier whitelist
  address[] private whitelistSilverTier; 
  
  // address array for gold tier whitelist
  address[] private whitelistGoldTier; 
  
  // address array for diamond tier whitelist
  address[] private whitelistDiamondTier;

  //mapping the user purchase per tier
  mapping(address => uint) public buyInBronzeTier;
  mapping(address => uint) public buyInSilverTier;
  mapping(address => uint) public buyInGoldTier;
  mapping(address => uint) public buyInDiamondTier;

  mapping(uint => uint) public tierLevelLimit;

  // CONSTRUCTOR  
  constructor(
      uint _maxCap,
      uint256 _saleStartTime,
      uint256 _saleEndTime,
      address payable _projectOwner,
      uint256 _bronzeTierValue,
      uint256 _silverTierValue,
      uint256 _goldTierValue,
      uint256 _diamondTierValue,
      uint256 _totalUserInBronzeTier,
      uint256 _totalUserInSilverTier,
      uint256 _totalUserInGoldTier,
      uint256 _totalUserInDiamondTier,
      uint _totalparticipants) public {
    maxCap = _maxCap;
    saleStartTime = _saleStartTime;
    saleEndTime = _saleEndTime;
    projectOwner = _projectOwner;
    bronzeMaxCap =_bronzeTierValue;
    silverMaxCap = _silverTierValue;
    goldMaxCap = _goldTierValue;
    diamondMaxCap = _diamondTierValue;
    totalUserInBronzeTier =_totalUserInBronzeTier;
    totalUserInSilverTier = _totalUserInSilverTier;
    totalUserInGoldTier = _totalUserInGoldTier;
    totalUserInDiamondTier = _totalUserInDiamondTier;
    maxAllocaPerUserBronzeTier = bronzeMaxCap / totalUserInBronzeTier;
    maxAllocaPerUserSilverTier = silverMaxCap / totalUserInSilverTier; 
    maxAllocaPerUserGoldTier = goldMaxCap / totalUserInGoldTier;
    maxAllocaPerUserDiamondTier = diamondMaxCap / totalUserInDiamondTier;
    totalparticipants = _totalparticipants;
  }

  // function to update the tiers value manually
  function updateTierValues(uint256 _bronzeTierValue, uint256 _silverTierValue, uint256 _goldTierValue, uint256 _diamondTierValue) external onlyOwner {
    bronzeMaxCap =_bronzeTierValue;
    silverMaxCap = _silverTierValue;
    goldMaxCap =_goldTierValue;
    diamondMaxCap = _diamondTierValue;
    
    maxAllocaPerUserBronzeTier = bronzeMaxCap / totalUserInBronzeTier;
    maxAllocaPerUserSilverTier = silverMaxCap / totalUserInSilverTier; 
    maxAllocaPerUserGoldTier = goldMaxCap / totalUserInGoldTier;
    maxAllocaPerUserDiamondTier = diamondMaxCap / totalUserInDiamondTier;
  }
  
  // function to update the tiers users value manually
  function updateTierUsersValue(uint256 _totalUserInBronzeTier, uint256 _totalUserInSilverTier, uint256 _totalUserInGoldTier, uint256 _totalUserInDiamondTier) external onlyOwner {
    totalUserInBronzeTier =_totalUserInBronzeTier;
    totalUserInSilverTier = _totalUserInSilverTier;
    totalUserInGoldTier =_totalUserInGoldTier;
    totalUserInDiamondTier = _totalUserInDiamondTier;
    
    maxAllocaPerUserBronzeTier = bronzeMaxCap / totalUserInBronzeTier;
    maxAllocaPerUserSilverTier = silverMaxCap / totalUserInSilverTier; 
    maxAllocaPerUserGoldTier = goldMaxCap / totalUserInGoldTier;
    maxAllocaPerUserDiamondTier = diamondMaxCap / totalUserInDiamondTier;
  }

  function whitelistAddressToBronzeTier(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistBronzeTier.push(_address);
  }

  function whitelistAddressToSilverTier(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistSilverTier.push(_address);
  }

  function whitelistAddressToGoldTier(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistGoldTier.push(_address);
  }

  function whitelistAddressToDiamondTier(address _address) external onlyOwner {
      require(_address != address(0), "Invalid address");
      whitelistDiamondTier.push(_address);
  }

  // check the address in whitelist tier one
  function getBronzeTierWhitelist(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistBronzeTier.length;
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistBronzeTier[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }

  // check the address in whitelist tier two
  function getSilverTierWhitelist(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistSilverTier.length;
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistSilverTier[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }

  // check the address in whitelist tier three
  function getGoldTierWhitelist(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistGoldTier.length; 
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistGoldTier[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }

  function getDiamondTierWhitelist(address _address) public view returns(bool) {
      uint i;
    uint length = whitelistDiamondTier.length; 
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistGoldTier[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }
  // send bnb to the contract address
  receive() external payable {
     require(block.timestamp >= saleStartTime, "The sale is not started yet "); // solhint-disable
     require(block.timestamp <= saleEndTime, "The sale is closed"); // solhint-disable
     require(totalBnbReceivedInAllTier + msg.value <= maxCap, "buyTokens: purchase would exceed max cap");
     
    if (getBronzeTierWhitelist(msg.sender)) { 
      require(totalBnbInBronzeTier + msg.value <= bronzeMaxCap, "buyTokens: purchase would exceed Tier one max cap");
      require(buyInBronzeTier[msg.sender] + msg.value <= maxAllocaPerUserBronzeTier ,"buyTokens:You are investing more than your tier-1 limit!");
      buyInBronzeTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInBronzeTier += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    } else if (getSilverTierWhitelist(msg.sender)) {
      require(totalBnbInSilverTier + msg.value <= silverMaxCap, "buyTokens: purchase would exceed Tier two max cap");
      require(buyInSilverTier[msg.sender] + msg.value <= maxAllocaPerUserSilverTier ,"buyTokens:You are investing more than your tier-2 limit!");
      buyInSilverTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInSilverTier += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    } else if (getGoldTierWhitelist(msg.sender)) { 
      require(totalBnbInGoldTier + msg.value <= goldMaxCap, "buyTokens: purchase would exceed Tier three max cap");
      require(buyInGoldTier[msg.sender] + msg.value <= maxAllocaPerUserGoldTier ,"buyTokens:You are investing more than your tier-3 limit!");
      buyInGoldTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInGoldTier += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    } else if (getDiamondTierWhitelist(msg.sender)) { 
      require(totalBnbInGoldTier + msg.value <= goldMaxCap, "buyTokens: purchase would exceed Tier three max cap");
      require(buyInDiamondTier[msg.sender] + msg.value <= maxAllocaPerUserGoldTier ,"buyTokens:You are investing more than your tier-3 limit!");
      buyInDiamondTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInDiamondTier += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    } else {
      revert();
    }
  }

  function ckeckUsersTier (address _user) external view returns (uint256) {
    if (IERC20(lightToken).balanceOf(_user) >= tierLevelLimit[3]) {
        uint256 index = 3;
        return index;
      }
    else if (IERC20(lightToken).balanceOf(_user) >= tierLevelLimit[2]) {
        uint256 index = 2;
        return index;
      }
    else if (IERC20(lightToken).balanceOf(_user) >= tierLevelLimit[1]) {
        uint256 index = 1;
        return index;
      }
    else if (IERC20(lightToken).balanceOf(_user) >= tierLevelLimit[0]) {
        uint256 index = 0;
        return index;
      }
    }

    function setBronzeTierLevelLimit(uint256 _amount) external onlyOwner {
      tierLevelLimit[0] = _amount;
    }
    function setSilverTierLevelLimit(uint256 _amount) external onlyOwner {
      tierLevelLimit[1] = _amount;
    }
    function setGoldTierLevelLimit(uint256 _amount) external onlyOwner {
      tierLevelLimit[2] = _amount;
    }
    function setDiamondTierLevelLimit(uint256 _amount) external onlyOwner {
      tierLevelLimit[3] = _amount;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(msg.sender == owner, "Only owner has the right to perform this action");
        _;
    }

    /**
        * @dev Allows the current owner to transfer control of the contract to a newOwner.
        * @param newOwner The address to transfer ownership to.
        */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

interface IERC20 {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

