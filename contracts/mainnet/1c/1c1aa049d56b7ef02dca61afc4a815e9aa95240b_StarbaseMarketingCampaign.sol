pragma solidity ^0.4.13;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AbstractStarbaseToken is ERC20 {
    function isFundraiser(address fundraiserAddress) public returns (bool);
    function company() public returns (address);
    function allocateToCrowdsalePurchaser(address to, uint256 value) public returns (bool);
    function allocateToMarketingSupporter(address to, uint256 value) public returns (bool);
}

/**
 * @title Crowdsale contract - Starbase marketing campaign contract to reward supportors
 * @author Starbase PTE. LTD. - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5c35323a331c2f283d2e3e3d2f39723f33">[email&#160;protected]</a>>
 */
contract StarbaseMarketingCampaign is Ownable {
    /*
     *  Events
     */
    event NewContributor (address indexed contributorAddress, uint256 tokenCount);
    event UpdateContributorsTokens(address indexed contributorAddress, uint256 tokenCount);
    event WithdrawContributorsToken(address indexed contributorAddress, uint256 tokenWithdrawn, uint remainingTokens);

    /**
     *  External contracts
     */
    AbstractStarbaseToken public starbaseToken;

    /**
     * Types
     */
    struct Contributor {
        uint256 rewardTokens;
        uint256 transferredRewardTokens;
        mapping (bytes32 => bool) contributions;  // example: keccak256(bcm-xda98sdf) => true
    }

    /**
     *  Storage
     */
    address public workshop;  // holds undelivered STARs
    address[] public contributors;
    mapping (address => Contributor) public contributor;

    /**
     *  Modifiers
     */
    modifier onlyOwnerOr(address _allowed) {
        // Only owner or specified address are allowed to do this action.
        assert(msg.sender == owner || msg.sender == _allowed);
        _;
    }

    /**
     *  Functions
     */

    /**
     * @dev Contract constructor sets owner and workshop address.
     * @param workshopAddr The address that will hold undelivered Star tokens
     */
    function StarbaseMarketingCampaign(address workshopAddr) {
        require(workshopAddr != address(0));
        owner = msg.sender;
        workshop = workshopAddr;
    }

    /*
     *  External Functions
     */

    /**
     * @dev Allows for marketing contributor&#39;s reward withdrawl
     * @param contributorAddress The address of the contributor
     * @param tokensToTransfer Token number to withdraw
     */
    function withdrawRewardedTokens (address contributorAddress, uint256 tokensToTransfer)
        external
        onlyOwnerOr(contributorAddress)
    {
        require(contributor[contributorAddress].rewardTokens > 0 && tokensToTransfer <= contributor[contributorAddress].rewardTokens && address(starbaseToken) != 0);

        contributor[contributorAddress].rewardTokens = SafeMath.sub(contributor[contributorAddress].rewardTokens, tokensToTransfer);

        contributor[contributorAddress].transferredRewardTokens = SafeMath.add(contributor[contributorAddress].transferredRewardTokens, tokensToTransfer);

        starbaseToken.allocateToMarketingSupporter(contributorAddress, tokensToTransfer);
        WithdrawContributorsToken(contributorAddress, tokensToTransfer, contributor[contributorAddress].rewardTokens);
    }

    /**
     * @dev Setup function sets external contracts&#39; addresses.
     * @param starbaseTokenAddress Token address.
     */
    function setup(address starbaseTokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        assert(address(starbaseToken) == 0);
        starbaseToken = AbstractStarbaseToken(starbaseTokenAddress);
        return true;
    }

    /**
     * @dev Include new contributor
     * @param contributorAddress A contributor&#39;s address
     * @param tokenCount number of tokens assigned to contributor on their inclusion
     * @param contributionId Id of contribution from bounty app db
     */
    function addRewardforNewContributor
        (
            address contributorAddress,
            uint256 tokenCount,
            string contributionId
        )
            external
            onlyOwner
    {
        bytes32 id = keccak256(contributionId);

        require(!contributor[contributorAddress].contributions[id]);
        assert(contributor[contributorAddress].rewardTokens == 0 && contributor[contributorAddress].transferredRewardTokens == 0);

        contributor[contributorAddress].rewardTokens = tokenCount;
        contributor[contributorAddress].contributions[id] = true;
        contributors.push(contributorAddress);
        NewContributor(contributorAddress, tokenCount);
    }

    /**
     * @dev Updates contributors rewardTokens
     * @param contributorAddress A contributor&#39;s address
     * @param tokenCount number of tokens to update for the contributor
     * @param contributionId Id of contribution from bounty app db
     */
    function updateRewardForContributor (address contributorAddress, uint256 tokenCount, string contributionId)
        external
        onlyOwner
        returns (bool)
    {
        bytes32 id = keccak256(contributionId);

        require(contributor[contributorAddress].contributions[id]);

        contributor[contributorAddress].rewardTokens = SafeMath.add(contributor[contributorAddress].rewardTokens, tokenCount);
        UpdateContributorsTokens(contributorAddress, tokenCount);
        return true;
    }

    /**
     *  Public Functions
     */

    /**
     * @dev Informs about contributors rewardTokens and transferredRewardTokens status
     * @param contributorAddress A contributor&#39;s address
     * @param contributionId Id of contribution from bounty app db
     */
    function getContributorInfo(address contributorAddress, string contributionId)
      constant
      public
      returns (uint256, uint256, bool)
    {
        bytes32 id = keccak256(contributionId);

        return(
          contributor[contributorAddress].rewardTokens,
          contributor[contributorAddress].transferredRewardTokens,
          contributor[contributorAddress].contributions[id]
        );
    }

    /**
     * @dev Returns number of contributors.
     */
    function numberOfContributors()
      constant
      public
      returns (uint256)
    {
      return contributors.length;
    }
}