// File: contracts/helpers/Owned.sol

pragma solidity >=0.4.0 <0.6.0;

contract Owned {
  address payable public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "Sender not owner");
    _;
  }

  function transferOwnership(address payable newOwner) public onlyOwner {
    owner = newOwner;
  }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Gems/Staking.sol

pragma solidity ^0.5.10;



interface IStakingErc20 {
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  // This only applies to Cargo Credits 
  function increaseBalance(address user, uint balance) external;
  function transfer(address to, uint256 value) external returns (bool success);
}

interface IStakingCargoData {
  function verifySigAndUuid(bytes32 hash, bytes calldata signature, bytes32 uuid) external;
  function verifyContract(address contractAddress) external returns (bool);
}

interface IStakingErc721 {
  function ownerOf(uint256 tokenId) external view returns (address);
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

contract CargoGemsStaking is Owned {
  using SafeMath for uint256;

  event TotalStakeUpdated(uint totalStakedAmount);
  event TokenStakeUpdated(
    address indexed tokenContract, 
    uint256 indexed tokenId, 
    uint256 stakedAmount, 
    bool genesis
  );
  event Claim(
    address indexed claimant, 
    address indexed tokenContractAddress, 
    uint256 indexed tokenId, 
    uint256 gemsReward, 
    uint256 creditsReward
  );

  IStakingCargoData cargoData;
  IStakingErc20 cargoGems;
  IStakingErc20 cargoCredits;

  struct Stake {
    uint amount;
    uint lastBlockClaimed;
    uint genesisBlock;
    bool exists;
  }

  uint256 public totalStaked = 0;
  mapping(string => bool) config;

  // Token Contract Address => Token ID => Staked Amount
  mapping(address => mapping(uint256 => Stake)) tokenStakes;
  mapping(address => bool) public whiteList;
  mapping(address => bool) public blackList;

  constructor(address cargoDataAddress, address cargoGemsAddress, address cargoCreditsAddress) public {
    cargoData = IStakingCargoData(cargoDataAddress);
    cargoGems = IStakingErc20(cargoGemsAddress);
    cargoCredits = IStakingErc20(cargoCreditsAddress);
    config["enabled"] = true;
    config["onlyCargoContracts"] = true;
  }

  modifier onlyEnabled() {
    require(config["enabled"] == true, "Staking: Not enabled"); 
    _;
  }

  modifier onlyExists(address contractAddress, uint tokenId) {
    require(tokenStakes[contractAddress][tokenId].exists, "Staking: Token ID at address not staked");
    _;
  }

  function updateBlacklist(address contractAddress, bool val) external onlyOwner {
    blackList[contractAddress] = val;
  }

  function updateWhitelist(address contractAddress, bool val) external onlyOwner {
    whiteList[contractAddress] = val;
  }

  function updateConfig(string calldata key, bool value) external onlyOwner {
    config[key] = value;
  }

  function getStakedAmount(address contractAddress, uint tokenId) onlyExists(contractAddress, tokenId) external view returns (uint) {
    return tokenStakes[contractAddress][tokenId].amount;
  }

  function getLastBlockClaimed(address contractAddress, uint tokenId) onlyExists(contractAddress, tokenId) external view returns (uint) {
    return tokenStakes[contractAddress][tokenId].lastBlockClaimed;
  }

  function getStakeGenesis(address contractAddress, uint tokenId) onlyExists(contractAddress, tokenId) external view returns (uint) {
    return tokenStakes[contractAddress][tokenId].genesisBlock;
  }

  /** @notice Function to claim rewards. Rewards are calculated off-chain by using on-chain data */
  function claim(
    address tokenContractAddress, 
    uint tokenId, 
    uint gemsReward,
    uint creditsReward,
    uint blockNumber,
    uint amountToWithdraw,
    bytes32 uuid,
    bytes calldata signature
  ) external onlyEnabled {
    cargoData.verifySigAndUuid(keccak256(
      abi.encodePacked(
        "CLAIM",
        tokenContractAddress,
        tokenId,
        gemsReward,
        creditsReward,
        amountToWithdraw,
        blockNumber,
        uuid
      )
    ), signature, uuid);

    IStakingErc721 erc721 = IStakingErc721(tokenContractAddress);
    require(erc721.ownerOf(tokenId) == msg.sender, "Staking: Sender not owner");
    require(tokenStakes[tokenContractAddress][tokenId].lastBlockClaimed < blockNumber, "Staking: block number invalid");

    tokenStakes[tokenContractAddress][tokenId].amount = tokenStakes[tokenContractAddress][tokenId].amount.add(gemsReward);
    totalStaked = totalStaked.add(gemsReward);

    if(amountToWithdraw > 0) {
      require(amountToWithdraw <= tokenStakes[tokenContractAddress][tokenId].amount, "Staking: Withdrawl amount must be lte staked amount");

      // transfer rewards to sender
      cargoGems.transfer(msg.sender, amountToWithdraw);
      
      // Decrease staked amount
      tokenStakes[tokenContractAddress][tokenId].amount = tokenStakes[tokenContractAddress][tokenId].amount.sub(amountToWithdraw);
      totalStaked = totalStaked.sub(amountToWithdraw);
    }

    // Regardless of whether its a withdrawl the user will still be rewarded credits.
    cargoCredits.increaseBalance(msg.sender, creditsReward);

    // Save block number 
    tokenStakes[tokenContractAddress][tokenId].lastBlockClaimed = block.number;

    emit Claim(msg.sender, tokenContractAddress, tokenId, gemsReward, creditsReward);
    emit TotalStakeUpdated(totalStaked);
    emit TokenStakeUpdated(
      tokenContractAddress, 
      tokenId, 
      tokenStakes[tokenContractAddress][tokenId].amount, 
      !tokenStakes[tokenContractAddress][tokenId].exists
    );
  }

  /**
    @notice function to stake 
    @param tokenContractAddress Address of ERC721 contract
    @param tokenId ID of token
    @param amountToStake Amount of Cargo gems, must account for decimals when sending this
   */
  function stake(address tokenContractAddress, uint tokenId, uint amountToStake) external onlyEnabled {
    require(amountToStake > 0, "Staking: Amount must be gt 0");
    if(config["onlyCargoContracts"]) {
      require(cargoData.verifyContract(tokenContractAddress), "Staking: Must be a cargo contract");
    }
    IStakingErc721 erc721 = IStakingErc721(tokenContractAddress);
    require(
      (erc721.supportsInterface(0x80ac58cd) || whiteList[tokenContractAddress]) 
      && !blackList[tokenContractAddress], 
      "Staking: 721 not supported"
    );
    require(erc721.ownerOf(tokenId) == msg.sender, "Staking: Sender not owner");
    // User must approve this contract to transfer the given amount
    cargoGems.transferFrom(msg.sender, address(this), amountToStake);

    // Increase token's staked amount
    tokenStakes[tokenContractAddress][tokenId].amount = tokenStakes[tokenContractAddress][tokenId].amount.add(amountToStake);

    // Increase the total staked amount
    totalStaked = totalStaked.add(amountToStake);

    emit TotalStakeUpdated(totalStaked);
    emit TokenStakeUpdated(
      tokenContractAddress, 
      tokenId, 
      tokenStakes[tokenContractAddress][tokenId].amount, 
      !tokenStakes[tokenContractAddress][tokenId].exists
    );

    if(!tokenStakes[tokenContractAddress][tokenId].exists) {
      tokenStakes[tokenContractAddress][tokenId].genesisBlock = block.number;
      tokenStakes[tokenContractAddress][tokenId].exists = true;
    }
  }
}