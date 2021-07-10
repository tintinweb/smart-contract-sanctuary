pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./interfaces/IPancakeRouter.sol";
import "./interfaces/IPancakeFactory.sol";

contract DoomerSale is Ownable, VRFConsumerBase {
    using SafeMathChainlink for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 constant public SALE_DAYS = 21;
    uint256 constant public VESTING_TIME = 60 * 60 * 24 * 30; // 30 Days.

    // Max DMR rewards per BNB if a day is undersubscribed.
    uint256 constant public MAX_DMR_PER_BNB = 15; // 15 DMR per BNB;

    mapping(address => mapping(uint256 => uint256)) public investorBalances;
    mapping(uint256 => uint256) public totalContribution;

    mapping(uint256 => uint256) public dailyMinSupply;
    mapping(uint256 => uint256) public dailyMaxSupply;
    mapping(uint256 => uint256) public dailySupply;
    // Gets set to true after the supplies have been randomized after the presale.

    IERC20 public doomerToken;

    bool public saleActive;
    bool public canClaim;
    // Contract will be sent an excess amount of tokens due to supplies being randomly generated.
    // The excess amount can be withdrawn after supplies have been randomized and can be determined.
    bool public hasWithdrawnExcessTokens = false;
    uint256 public saleStartTimestamp;
    uint256 public saleStopTimestamp;
    uint256 public claimStartTimestamp;

    struct ClaimInfo {
        uint256 claimedAmount;
        uint256 lastClaim; // Timestamp
    }

    // User token claim information for each user. Will be set for a user upon first claim.
    mapping(address => ClaimInfo) public claimInfo;
    uint256 public claimedAmount; // Total claimed amount.

    // LP interfaces.
    IPancakeRouter pancakeRouter;
    IPancakeFactory pancakeFactory;

    // Chainlink.
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    mapping(bytes32 => uint8) requestIdToDay;
    event RequestedRandomness(bytes32 requestId);

    // Storage for frontend helpers
    EnumerableSet.AddressSet investors;
    mapping(uint256 => EnumerableSet.AddressSet) investorDailySet; // Set storing all investorDailySet for each day.
    mapping(uint256 => uint256) public uniqueInvestors; // Number of unique investorDailySet for each day.

    constructor(
        address doomerTokenAddress,
        address _pancakeRouterAddress,
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyHash,
        uint256 _fee
    )
    public VRFConsumerBase(_VRFCoordinator, _LinkToken)
    {
        saleActive = false;
        canClaim = false;

        claimedAmount = 0;
        pancakeRouter = IPancakeRouter(_pancakeRouterAddress);
        doomerToken = IERC20(doomerTokenAddress);

        keyHash = _keyHash;
        fee = _fee;

        // MAX and MIN doomer tokens for each day.
        dailyMinSupply[0] = 230;
        dailyMaxSupply[0] = 270;

        dailyMinSupply[1] = 200;
        dailyMaxSupply[1] = 300;

        dailyMinSupply[2] = 100;
        dailyMaxSupply[2] = 450;

        dailyMinSupply[3] = 220;
        dailyMaxSupply[3] = 280;

        dailyMinSupply[4] = 150;
        dailyMaxSupply[4] = 350;

        dailyMinSupply[5] = 230;
        dailyMaxSupply[5] = 270;

        dailyMinSupply[6] = 130;
        dailyMaxSupply[6] = 370;

        dailyMinSupply[7] = 150;
        dailyMaxSupply[7] = 350;

        dailyMinSupply[8] = 230;
        dailyMaxSupply[8] = 270;

        dailyMinSupply[9] = 200;
        dailyMaxSupply[9] = 300;

        dailyMinSupply[10] = 150;
        dailyMaxSupply[10] = 350;

        dailyMinSupply[11] = 50;
        dailyMaxSupply[11] = 500;

        dailyMinSupply[12] = 230;
        dailyMaxSupply[12] = 260;

        dailyMinSupply[13] = 210;
        dailyMaxSupply[13] = 270;

        dailyMinSupply[14] = 150;
        dailyMaxSupply[14] = 350;

        dailyMinSupply[15] = 200;
        dailyMaxSupply[15] = 300;

        dailyMinSupply[16] = 230;
        dailyMaxSupply[16] = 270;

        dailyMinSupply[17] = 150;
        dailyMaxSupply[17] = 350;

        dailyMinSupply[18] = 200;
        dailyMaxSupply[18] = 300;

        dailyMinSupply[19] = 50;
        dailyMaxSupply[19] = 500;

        dailyMinSupply[20] = 20;
        dailyMaxSupply[20] = 600;


        for (uint256 i = 0; i < SALE_DAYS; i++) {
            uniqueInvestors[i] = 0;
        }
    }

    function invest(uint256 saleDay) public payable {
        require(msg.value >= 100 finney, "Minimum investment is 0.1 BNB");
        require(saleDay >= 0 && saleDay < SALE_DAYS, "Investment day is outside bounds");
        require(saleActive == true, "Sale isn't active!");
        require(block.timestamp < saleStopTimestamp, 'Sale has ended!');
        uint256 currentSaleDay = getCurrentSaleDay();
        require(saleDay >= currentSaleDay, "This day has already passed");

        totalContribution[saleDay] = totalContribution[saleDay].add(msg.value);
        investorBalances[msg.sender][saleDay] = investorBalances[msg.sender][saleDay].add(msg.value);

        if (! investorDailySet[saleDay].contains(msg.sender)) {
            uniqueInvestors[saleDay] = uniqueInvestors[saleDay].add(1);
            investorDailySet[saleDay].add(msg.sender);
        }
        
        investors.add(msg.sender);
    }

    function investDCA() public payable {
        require(msg.value >= 100 finney, "Minimum investment is 0.1 BNB");
        require(block.timestamp < saleStopTimestamp, 'Sale has ended!');
        require(saleActive == true, "Sale isn't active!");
        uint256 currentSaleDay = getCurrentSaleDay();
        uint256 dcaDays = SALE_DAYS - currentSaleDay;
        uint256 dcaAmount = uint256(msg.value).div(dcaDays);
        require (dcaDays > 0, "Can't DCA into zero days.");
        require (dcaAmount > 0, "Division error");

        for (uint256 i = currentSaleDay; i < SALE_DAYS; i++) {
            totalContribution[i] = totalContribution[i].add(dcaAmount);
            investorBalances[msg.sender][i] = investorBalances[msg.sender][i].add(dcaAmount);

            if (! investorDailySet[i].contains(msg.sender)) {
                investorDailySet[i].add(msg.sender);
                uniqueInvestors[i] = uniqueInvestors[i].add(1);
            }
        
        }
        
        investors.add(msg.sender);
    }

    function getCurrentSaleDay() public view returns (uint256) {
        require(saleActive == true, "Sale isn't active!");
        uint256 time = block.timestamp;
        uint256 diff = (time - saleStartTimestamp) / 60 / 60 / 24;
        return diff;
    }

    function claimTokens() public {
        require(saleActive == false, "Sale is still active!");
        require(canClaim == true, "Claims not opened yet");

        // Get total allocation.
        uint256 totalAllocation = getAccountAllocation();
        require(totalAllocation > 0, 'Nothing to claim');

        ClaimInfo storage info = claimInfo[msg.sender];
        uint256 time = block.timestamp;
        uint256 elapsedTimeSinceClaim = time - info.lastClaim;
        uint256 elapsedHours = elapsedTimeSinceClaim / 60 / 60;

        // Tokens are claimable every second hour.
        require (elapsedHours >= 2, 'Tokens can only be claimed every two hours');

        uint256 pendingReward = getPendingAmount();
        // Store how many tokens were claimed, so we know how many tokens can be claimed next time.
        info.claimedAmount = info.claimedAmount.add(pendingReward); 
        claimedAmount = claimedAmount.add(pendingReward);

        info.lastClaim = time;
        doomerToken.transfer(msg.sender, pendingReward);
    }

    function getPendingAmount() public view returns (uint256) {
        require(saleActive == false, "Sale is still active!");
        require(canClaim == true, "Claims not opened yet");
        
        // Get total allocation.
        uint256 totalAllocation = getAccountAllocation();

        require(totalAllocation > 0, 'No tokens to claim');

        ClaimInfo storage info = claimInfo[msg.sender];

        uint256 elapsedTimeSinceClaimStart = block.timestamp - claimStartTimestamp;

        // Linear vesting. User can claim 25% in the beginning. Then tokens will be vested linearly.
        uint256 pendingReward = totalAllocation.div(4).add(totalAllocation.mul(3).div(4).mul(elapsedTimeSinceClaimStart).div(VESTING_TIME));

        if (elapsedTimeSinceClaimStart >= VESTING_TIME) {
            //  User can claim all tokens.
            pendingReward = totalAllocation;
        }

        pendingReward = pendingReward.sub(info.claimedAmount);
        return pendingReward;
    }

    /**
     * @dev The number of DMR tokens that the user has been allocated.
     */
    function getAccountAllocation() public view returns (uint256) {
        require(canClaim == true, "Claims not opened yet");
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < SALE_DAYS; i++) {
            uint256 accountContribution = investorBalances[msg.sender][i];
            // Check if user has invested on this day.
            if (accountContribution > 0) {

                // Check if day is oversubscribed.
                if (MAX_DMR_PER_BNB.mul(totalContribution[i]) <= dailySupply[i].mul(1e18)) {
                    // Day is undersubscribed.
                    uint256 allocation = MAX_DMR_PER_BNB.mul(accountContribution);
                    totalAllocation = totalAllocation.add(allocation);
                } else {
                    // Day is oversubscribed. Split rewards between all investorDailySet.
                    // out = investorBalances[msg.sender][i];
                    uint256 allocation = accountContribution.mul(dailySupply[i]).mul(1e18).div(totalContribution[i]);
                    totalAllocation = totalAllocation.add(allocation);
                }
            }
        }
        return totalAllocation;
    }

    /*
        EXTERNAL VIEW FUNCTIONS
        ------------------------------------------------------------
     */
    function getInvestorByIndex(uint256 index) external view returns (address) {
        return investors.at(index);
    }

    function getInvestorCount() external view returns (uint256) {
        return investors.length();
    }

    /**
     * @dev Returns an array containing the number of investors that invested on each day.
     */
    function getDailyUinqueInevstors() external view returns (uint256[SALE_DAYS] memory allDays) {
        for (uint256 i = 0; i < SALE_DAYS; i++) {
            allDays[i] = uniqueInvestors[i]; 
        }
    }

    function getMyContributionDays() external view returns (uint256[SALE_DAYS] memory allDays) {
        for (uint256 i = 0; i < SALE_DAYS; i++) {
            allDays[i] = investorBalances[msg.sender][i];
        }
    }

    function getMyTotalContributions() external view returns (uint256) {
        uint256 totalContributions = 0;
        for (uint256 i = 0; i < SALE_DAYS; i++) {
            totalContributions += investorBalances[msg.sender][i];
        }
        return totalContributions;
    }

    /*
        PUBLIC VIEW FUNCTIONS
        ------------------------------------------------------------
    */

    function getTotalContributionDays() public view returns (uint256[SALE_DAYS] memory allDays) {
        for (uint256 i = 0; i < SALE_DAYS; i++) {
            allDays[i] = totalContribution[i];
        }
    }

    function getTotalContributions() public view returns (uint256) {
        uint256 totalContributions = 0;
        for (uint256 i = 0; i < SALE_DAYS; i++) {
            totalContributions = totalContributions.add(totalContribution[i]);
        }
        return totalContributions;
    }

    /**
     * Total amount of DMR to be distributed to all investors.
     */
    function getTotalAllocation() public view returns (uint256) {
        uint256 totalDoomerAllocated = 0;

        // Get number of tokens allocated to all investors.
        for (uint256 i = 0; i < SALE_DAYS; i++) {
            // Check if day is oversubscribed.
            uint256 allocation = 0;
            if (MAX_DMR_PER_BNB.mul(totalContribution[i]) <= dailySupply[i].mul(1e18)) {
                // Day is undersubscribed.
                allocation = MAX_DMR_PER_BNB.mul(totalContribution[i]);
            } else {
                // Day is oversubscribed. All daily rewards have been allocated.
                allocation = dailySupply[i].mul(1e18);
            }
            totalDoomerAllocated = totalDoomerAllocated.add(allocation);
        }

        return totalDoomerAllocated;
    }

    function getAverageSalePrice() public view returns (uint256) {
        uint256 totalDoomerAllocated = getTotalAllocation();
        uint256 totalContributions = getTotalContributions();
        return totalContributions.div(totalDoomerAllocated);
    }

    /*
        OWNER ONLY FUNCTIONS
        -------------------------------------------------------------
    */

    /**
    * @dev Sets the supply of tokens for a specific day. If the supply isn't predefined Chainlink VRF will be used
    * to generate a random supply.
    */
    function setDailySupply(uint8 day, uint256 userProvidedSeed) public onlyOwner {
        if (dailyMinSupply[day] == dailyMaxSupply[day]) {
            // Day has predefined supply.
            dailySupply[day] = dailyMaxSupply[day];
        } else {
            // Day has random supply so let's use Chainlink VRF.
            bytes32 requestId = requestRandomness(keyHash, fee);
            requestIdToDay[requestId] = day;
            emit RequestedRandomness(requestId);
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        uint8 day = requestIdToDay[requestId];

        // out = day;
        uint256 supplyRange = dailyMaxSupply[day] - dailyMinSupply[day];
        uint256 minSupply = dailyMinSupply[day];

        dailySupply[day] = minSupply.add(randomNumber.mod(supplyRange));
    }

    /**
    * @dev Withdraw BNB from this contract (Callable by owner only)
    * in order to add liquidity to PancakeSwap.
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
    * @dev Withdraw DMR from this contract (Callable by owner only).
    */
    function emergencyWithdrawDMR() public onlyOwner {
        uint256 tokenBalance = doomerToken.balanceOf(address(this));
        doomerToken.transfer(msg.sender, tokenBalance);
    }

    function startSale() public onlyOwner {
        require(saleActive == false, 'Sale is already open');
        saleActive = true;
        saleStartTimestamp = block.timestamp;
        saleStopTimestamp = saleStartTimestamp.add(60 * 60 * 24 * SALE_DAYS);
    }

    function resumeSale() public onlyOwner {
        saleActive = true;
    }

    function stopSale() public onlyOwner {
        saleActive = false;
    }

    function openClaims() public onlyOwner {
        canClaim = true;
        claimStartTimestamp = block.timestamp;
    }

    function pauseClaims() public onlyOwner {
        canClaim = false;
    }

    /**
    * @dev Withdraws the remaining DMR tokens that are not to be allocated.
    */
    function withdrawRemainingTokens() public onlyOwner {
        require(hasWithdrawnExcessTokens == false, "Can't withdraw excess tokens twice");
        // Tokens to be distributed to presale participators.
        uint256 tokensToBeDistributed = getTotalAllocation();
        uint256 tokenBalance = doomerToken.balanceOf(address(this));
        require(tokenBalance.add(claimedAmount) > tokensToBeDistributed, "Can't withdraw enough tokens to make rewards unclaimable.");

        doomerToken.transfer(msg.sender, tokenBalance.add(claimedAmount).sub(tokensToBeDistributed));
        hasWithdrawnExcessTokens = true;
    }

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

pragma solidity 0.6.6;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity 0.6.6;

interface IPancakeRouter {
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./vendor/SafeMathChainlink.sol";

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
library SafeMathChainlink {
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
    require(b <= a, "SafeMath: subtraction overflow");
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
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
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

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}