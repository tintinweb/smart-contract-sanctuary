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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract AbstractStarbaseToken {
    function isFundraiser(address fundraiserAddress) public returns (bool);
    function company() public returns (address);
    function allocateToCrowdsalePurchaser(address to, uint256 value) public returns (bool);
    function allocateToMarketingSupporter(address to, uint256 value) public returns (bool);
}

/**
 * @title Crowdsale contract - Starbase marketing campaign contract to reward supportors
 * @author Starbase PTE. LTD. - <<span class="__cf_email__" data-cfemail="fa93949c95ba898e9b88989b899fd49995">[email&#160;protected]</span>>
 */
contract StarbaseMarketingCampaign is Ownable {
    /*
     *  Events
     */
    event NewContributor (address indexed contributorAddress, uint256 tokenCount);
    event WithdrawContributorsToken(address indexed contributorAddress, uint256 tokenWithdrawn);

    /**
     *  External contracts
     */
    AbstractStarbaseToken public starbaseToken;

    /**
     * Types
     */
    struct Contributor {
        uint256 rewardedTokens;
        mapping (bytes32 => bool) contributions;  // example: keccak256(bcm-xda98sdf) => true
        bool isContributor;
    }

    /**
     *  Storage
     */
    address[] public contributors;
    mapping (address => Contributor) public contributor;

    /**
     *  Functions
     */

    /**
     * @dev Contract constructor sets owner address.
     */
    function StarbaseMarketingCampaign() {
        owner = msg.sender;
    }

    /*
     *  External Functions
     */

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
     * @dev Allows for marketing contributor&#39;s reward adding and withdrawl
     * @param contributorAddress The address of the contributor
     * @param tokenCount Token number to awarded and to be withdrawn
     * @param contributionId Id of contribution from bounty app db
     */
    function deliverRewardedTokens(
        address contributorAddress,
        uint256 tokenCount,
        string contributionId
    )
        external
        onlyOwner
        returns(bool)
    {

        bytes32 id = keccak256(contributionId);

        assert(!contributor[contributorAddress].contributions[id]);
        contributor[contributorAddress].contributions[id] = true;

        contributor[contributorAddress].rewardedTokens = SafeMath.add(contributor[contributorAddress].rewardedTokens, tokenCount);

        if (!contributor[contributorAddress].isContributor) {
            contributor[contributorAddress].isContributor = true;
            contributors.push(contributorAddress);
            NewContributor(contributorAddress, tokenCount);
        }

        starbaseToken.allocateToMarketingSupporter(contributorAddress, tokenCount);
        WithdrawContributorsToken(contributorAddress, tokenCount);

        return true;
    }


    /**
     *  Public Functions
     */

    /**
     * @dev Informs about contributors rewardedTokens and transferredRewardTokens status
     * @param contributorAddress A contributor&#39;s address
     * @param contributionId Id of contribution from bounty app db
     */
    function getContributorInfo(address contributorAddress, string contributionId)
        constant
        public
        returns (uint256, bool, bool)
    {
        bytes32 id = keccak256(contributionId);

        return(
          contributor[contributorAddress].rewardedTokens,
          contributor[contributorAddress].contributions[id],
          contributor[contributorAddress].isContributor
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