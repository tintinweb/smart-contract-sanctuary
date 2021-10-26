// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable not-rely-on-time, reason-string, var-name-mixedcase */

import { VRFConsumerBase } from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import { IAugmentedSushiswapRouter } from "./interfaces/IAugmentedSushiswapRouter.sol";
import { IChainlinkPegSwap } from "./interfaces/IChainlinkPegSwap.sol";
import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { IProgrammableLoot } from "./interfaces/IProgrammableLoot.sol";
import { IWETH9 } from "./interfaces/IWETH9.sol";
import { Governable } from "./libraries/Governable.sol";
import { IBlackbeard } from "./interfaces/IBlackbeard.sol";
import { IJollyRoger } from "./interfaces/IJollyRoger.sol";

/// @author 0xBlackbeard
contract ProgrammableLoot is VRFConsumerBase, ReentrancyGuard, Governable, IProgrammableLoot {
	using Address for address payable;
	using SafeERC20 for IERC20;

	uint256 public constant RELIQUARY_MINT_FLOOR = 9 ether;
	uint256 public constant TROVE_MINT_FLOOR = 4 ether;
	uint256 public constant CHEST_MINT_FLOOR = 2 ether;
	uint256 public constant COFFER_MINT_FLOOR = 0.4 ether;
	uint256 public constant URN_MINT_FLOOR = 0.2 ether;
	uint256 public constant CRATE_MINT_FLOOR = 0.02 ether;
	uint256 public constant BARREL_MINT_FLOOR = 0.01 ether;
	uint256 public constant SACK_MINT_FLOOR = 0.001 ether;

	IJollyRoger public immutable JOLLY_ROGER;
	IBlackbeard public immutable BLACKBEARD;

	uint16 public genesisInflationGauge = 10;
	bool public areRewardsEnabled = true;

	IChainlinkPegSwap public immutable CHAINLINK_PEG_SWAP;
	AggregatorV3Interface public immutable CHAINLINK_ETH_LINK_FEED;
	bytes32 public CHAINLINK_VRF_KEY_HASH;
	uint256 public CHAINLINK_VRF_LINK_FEE;

	IERC20 public immutable WETH;
	IERC20 public immutable WLINK;
	IAugmentedSushiswapRouter public immutable SUSHISWAP_ROUTER;

	mapping(uint8 => uint256) public containerFloors;
	mapping(bytes32 => GenesisRequest) public genesisRequest;
	mapping(address => ContainerGenesis[]) public claimantGenesis;
	mapping(address => mapping(uint256 => ContainerGenesis)) public claimantGenesisIndex;

	ILootContainer public immutable CONTAINERS;

	constructor(
		ILootContainer containers,
		IJollyRoger jollyRoger,
		IBlackbeard blackbeard,
		address vrfCoordinator,
		address wrappedLinkToken,
		address linkToken,
		bytes32 vrfKeyHash,
		uint256 vrfFee,
		address linkEthFeed,
		address linkPegSwap,
		address sushiRouter,
		address weth
	) VRFConsumerBase(vrfCoordinator, linkToken) Governable() {
		CONTAINERS = containers;
		BLACKBEARD = blackbeard;
		JOLLY_ROGER = jollyRoger;

		CHAINLINK_VRF_KEY_HASH = vrfKeyHash;
		CHAINLINK_VRF_LINK_FEE = vrfFee;
		CHAINLINK_ETH_LINK_FEED = AggregatorV3Interface(linkEthFeed);
		CHAINLINK_PEG_SWAP = IChainlinkPegSwap(linkPegSwap);
		SUSHISWAP_ROUTER = IAugmentedSushiswapRouter(sushiRouter);
		WLINK = IERC20(wrappedLinkToken);
		WETH = IERC20(weth);

		containerFloors[uint8(ILootContainer.Containers.SACK)] = SACK_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.BARREL)] = BARREL_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.CRATE)] = CRATE_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.URN)] = URN_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.COFFER)] = COFFER_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.CHEST)] = CHEST_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.TROVE)] = TROVE_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.RELIQUARY)] = RELIQUARY_MINT_FLOOR;

		uint8 container = uint8(type(ILootContainer.Containers).min);
		while (container < uint8(type(ILootContainer.Containers).max)) {
			require(containerFloors[container] * 2 <= containerFloors[container + 1]);
			container++;
		}
	}

	/**
	 * @notice Requests the latest oracle reading for safely establishing the ETH/LINK exchange rate
	 * @dev Can be used before calling the `generate` function to determine the correct `msg.value` payload
	 */
	function getContainerPriceWithFee(ILootContainer.Containers container)
		public
		view
		override
		returns (uint256 priceInEth, uint256 feeInEth)
	{
		(, int256 _price, , , ) = CHAINLINK_ETH_LINK_FEED.latestRoundData();
		feeInEth = (uint256(_price) * CHAINLINK_VRF_LINK_FEE * 2) / 1e18;
		priceInEth = containerFloors[uint8(container)] + feeInEth;
	}

	/// @notice View to allow for measuring and filtering all container genesis structs belonging to `claimant`
	function getContainerGenesisFor(address claimant) external view override returns (ContainerGenesis[] memory genesis) {
		genesis = claimantGenesis[claimant];
	}

	/**
	 * @notice Requests a new container genesis, asking the VRF oracle for a real random seed
	 * @dev If caller is a contract, then it should implement the native receive function for ETH refunds
	 */
	function generateContainerSeed(ILootContainer.Containers container)
		external
		payable
		override
		nonReentrant
		returns (bytes32 requestId)
	{
		require(
			CONTAINERS.totalSupply() <= (block.number / genesisInflationGauge) + 1,
			"ProgrammableLoot::generateContainerSeed: illegal container supply growth"
		);

		(uint256 priceInEth, uint256 feeInEth) = getContainerPriceWithFee(container);
		require(
			WETH.allowance(msg.sender, address(this)) >= priceInEth,
			"ProgrammableLoot::generateContainerSeed: wrapped ether allowance too low"
		);

		WETH.safeTransferFrom(msg.sender, address(this), priceInEth);

		if (LINK.balanceOf(address(this)) < CHAINLINK_VRF_LINK_FEE) {
			uint256 wethBalanceBefore = WETH.balanceOf(address(this));
			WETH.safeApprove(address(SUSHISWAP_ROUTER), 0);
			WETH.safeIncreaseAllowance(address(SUSHISWAP_ROUTER), feeInEth);

			address[] memory path = new address[](2);
			path[0] = address(WETH);
			path[1] = address(WLINK);
			SUSHISWAP_ROUTER.swapExactTokensForTokens(
				feeInEth,
				CHAINLINK_VRF_LINK_FEE,
				path,
				address(this),
				block.timestamp
			);
			require(
				WLINK.balanceOf(address(this)) >= CHAINLINK_VRF_LINK_FEE,
				"ProgrammableLoot::generateContainerSeed: fraudulent wrapped LINK balance"
			);

			WLINK.approve(address(CHAINLINK_PEG_SWAP), 0);
			WLINK.safeIncreaseAllowance(address(CHAINLINK_PEG_SWAP), CHAINLINK_VRF_LINK_FEE);
			CHAINLINK_PEG_SWAP.swap(CHAINLINK_VRF_LINK_FEE, address(WLINK), address(LINK));

			uint256 wethBalanceAfter = WETH.balanceOf(address(this));
			require(
				wethBalanceAfter == wethBalanceBefore - feeInEth,
				"ProgrammableLoot::generateContainerSeed: fraudulent ETH balance"
			);
		}

		require(
			LINK.balanceOf(address(this)) >= CHAINLINK_VRF_LINK_FEE,
			"ProgrammableLoot::generateContainerSeed: not enough LINK"
		);
		requestId = requestRandomness(CHAINLINK_VRF_KEY_HASH, CHAINLINK_VRF_LINK_FEE);

		ContainerGenesis memory genesis = ContainerGenesis(
			container,
			0, // 0 is not a valid LootContainer ID
			claimantGenesis[msg.sender].length,
			requestId,
			msg.sender,
			false,
			uint80(block.timestamp)
		);
		claimantGenesis[genesis.claimant].push(genesis);
		claimantGenesisIndex[genesis.claimant][genesis.genesisIndex] = genesis;
		genesisRequest[requestId] = GenesisRequest(0);

		emit GenesisRequested(msg.sender, container, requestId);
	}

	/**
	 * @notice Claims an old container genesis, assembling the loot items at runtime and minting the relative tokens
	 * @dev Should be called only after checking for random seed delivery from the VRF oracle by either checking against
	 * `claimantGenesis` array or more expeditiously with `genesisRequest` if in possession of the genesis' `requestId`
	 */
	function claimContainer(uint256 genesisIndex) external override nonReentrant {
		ContainerGenesis storage genesis = claimantGenesis[msg.sender][genesisIndex];
		ContainerGenesis storage indexedGenesis = claimantGenesisIndex[genesis.claimant][genesis.genesisIndex];
		require(!genesis.claimed, "ProgrammableLoot::fulfillRandomness: genesis already claimed!");
		require(genesisIndex == genesis.genesisIndex, "ProgrammableLoot::fulfillRandomness: malformed claim");
		require(msg.sender == genesis.claimant, "ProgrammableLoot::fulfillRandomness: illegal claim");

		GenesisRequest memory genReq = genesisRequest[genesis.requestId];
		require(genReq.randomness != 0, "ProgrammableLoot::fulfillRandomness: missing random seed");

		uint256 containerId = CONTAINERS.mint(msg.sender, genesis.container, genReq.randomness);
		genesis.containerId = containerId;
		genesis.claimed = true;
		indexedGenesis.containerId = containerId;
		indexedGenesis.claimed = true;

		emit LootContainerClaimed(genesis.containerId, genesis.container, genReq.randomness, genesis.claimant);

		if (areRewardsEnabled && BLACKBEARD.hasRole(keccak256("MINTER_ROLE"), address(this))) {
			uint256 jjReward = _calculateContainerReward(genesis.container);
			if (jjReward <= JOLLY_ROGER.mintable()) BLACKBEARD.sew(msg.sender, jjReward);
		}
	}

	function setContainerFloor(ILootContainer.Containers container, uint256 floor) external override onlyGovernance {
		require(uint8(container) < 3, "ProgrammableLoot::setContainerFloor: rarer containers floor is immutable");
		require(
			floor * 2 <= containerFloors[uint8(container) + 1],
			"ProgrammableLoot::setContainerFloor: floor is over half the next rarer"
		);

		if (container != ILootContainer.Containers.SACK) {
			require(floor > 0, "ProgrammableLoot::setContainerFloor: only sacks may be claimed for free");
		}

		containerFloors[uint8(container)] = floor;
		emit ContainerFloorChanged(container, floor);
	}

	function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
		GenesisRequest storage genesis = genesisRequest[requestId];
		require(randomness != 0, "ProgrammableLoot::fulfillRandomness: malformed genesis");
		require(genesis.randomness == 0, "ProgrammableLoot::fulfillRandomness: illegal genesis");
		genesis.randomness = randomness;
	}

	/**
	 * @notice Sets the new container genesis inflation rate
	 */
	function toggleRewards() external override onlyGovernance {
		areRewardsEnabled = !areRewardsEnabled;
	}

	/**
	 * @notice Sets the new container genesis inflation rate
	 */
	function setGenesisInflationGauge(uint16 gauge) external override onlyGovernance {
		require(gauge >= 1, "ProgrammableLoot::setLootInflation: rampant inflation");
		emit GenesisInflationChanged(genesisInflationGauge, gauge);
		genesisInflationGauge = gauge;
	}

	/**
	 * @notice Sets the new VRF coordinator key hash and LINK fee (paid to the VRF oracle, in bips)
	 */
	function setChainlinkFee(uint256 linkFee) external override onlyGovernance {
		emit ChainlinkFeeChanged(CHAINLINK_VRF_LINK_FEE, linkFee);
		CHAINLINK_VRF_LINK_FEE = linkFee;
	}

	function rescueToken(IERC20 token) external override nonReentrant onlyGovernance {
		if (address(this).balance > 0) {
			payable(msg.sender).sendValue(address(this).balance);
		}

		uint256 tokenBal = token.balanceOf(address(this));
		if (tokenBal > 0) {
			token.transfer(msg.sender, tokenBal);
		}
	}

	function _calculateContainerReward(ILootContainer.Containers container) internal returns (uint256) {
		if (container == ILootContainer.Containers.SACK) return 213333333333333;
		else if (container == ILootContainer.Containers.BARREL) return 2133333333333333;
		else if (container == ILootContainer.Containers.CRATE) return 4266666666666666;
		else if (container == ILootContainer.Containers.URN) return 10666666666666668;
		else if (container == ILootContainer.Containers.COFFER) return 21333333333333336;
		else if (container == ILootContainer.Containers.CHEST) return 53333333333333340;
		else if (container == ILootContainer.Containers.TROVE) return 200000000000000000;
		else if (container == ILootContainer.Containers.RELIQUARY) return 400000000000000000;
		else revert("ProgrammableLoot::_calculateContainerReward: unknown container");
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

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
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
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
    nonces[_keyHash] = nonces[_keyHash] + 1;
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
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

interface IAugmentedSushiswapRouter {
	function factory() external pure returns (address);

	function WETH() external pure returns (address); // solhint-disable-line func-name-mixedcase

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
		external
		payable
		returns (
			uint256 amountToken,
			uint256 amountETH,
			uint256 liquidity
		);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountETH);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

interface IChainlinkPegSwap {
	function swap(
		uint256 amount,
		address source,
		address target
	) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { IERC721Permit } from "../interfaces/IERC721Permit.sol";
import { IGovernable } from "./IGovernable.sol";
import { ILootItem } from "./ILootItem.sol";

interface ILootContainer is IERC721Enumerable, IERC721Permit {
	enum Containers {
		SACK,
		BARREL,
		CRATE,
		URN,
		COFFER,
		CHEST,
		TROVE,
		RELIQUARY
	}

	struct Container {
		Containers class;
		uint256 seed;
		uint80 timestamp;
	}

	event LootContainerMinted(
		uint256 indexed id,
		ILootContainer.Containers container,
		uint256 randomness,
		address indexed to
	);

	event LootWithdrawn(uint256 containerId, ILootItem.Items item, uint256 indexed itemId);
	event LootDeposited(uint256 containerId, ILootItem.Items item, uint256 indexed itemId);

	function mint(
		address to,
		Containers container,
		uint256 seed
	) external returns (uint256);

	function withdraw(
		uint256 containerId,
		ILootItem.Items item,
		address to
	) external;

	function withdrawAll(uint256 containerId, address to) external;

	function deposit(
		uint256 containerId,
		ILootItem.Items item,
		uint256 itemId
	) external;

	function depositWithPermit(
		uint256 containerId,
		ILootItem.Items item,
		uint256 itemId,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { IGovernable } from "./IGovernable.sol";
import { ILootContainer } from "./ILootContainer.sol";

interface IProgrammableLoot is IGovernable {
	struct ContainerGenesis {
		ILootContainer.Containers container;
		uint256 containerId;
		uint256 genesisIndex;
		bytes32 requestId;
		address claimant;
		bool claimed;
		uint80 timestamp;
	}

	struct GenesisRequest {
		uint256 randomness;
	}

	event LootContainerClaimed(
		uint256 indexed id,
		ILootContainer.Containers container,
		uint256 randomness,
		address indexed claimant
	);
	event GenesisRequested(
		address indexed claimant,
		ILootContainer.Containers indexed container,
		bytes32 indexed requestId
	);
	event GenesisInflationChanged(uint16 oldInflation, uint16 newInflation);
	event ContainerFloorChanged(ILootContainer.Containers container, uint256 newFloor);
	event ChainlinkFeeChanged(uint256 oldFee, uint256 newFee);

	function getContainerGenesisFor(address claimant) external view returns (ContainerGenesis[] memory genesis);

	function getContainerPriceWithFee(ILootContainer.Containers container)
		external
		view
		returns (uint256 priceInEth, uint256 feeInEth);

	function generateContainerSeed(ILootContainer.Containers container) external payable returns (bytes32 requestId);

	function claimContainer(uint256 index) external;

	function rescueToken(IERC20 token) external;

	function setContainerFloor(ILootContainer.Containers container, uint256 floor) external;

	function setGenesisInflationGauge(uint16 inflation) external;

	function setChainlinkFee(uint256 linkFee) external;

	function toggleRewards() external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH9 is IERC20 {
	function deposit() external payable;

	function withdraw(uint256) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable reason-string */

import { Context } from "@openzeppelin/contracts/utils/Context.sol";

import { IGovernable } from "../interfaces/IGovernable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a governance) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governance account will be the one that deploys the contract. This
 * can later be changed with {changeGovernance}.
 *
 * This module is used through inheritance. It will make available the modifier `onlyGovernance`,
 * which can be applied to your functions to restrict their use to the governance.
 */
abstract contract Governable is Context, IGovernable {
	address private _governance;
	address private _pendingGovernance;

	event GovernanceChanged(address indexed formerGov, address indexed newGov);

	/**
	 * @dev Initializes the contract setting the deployer as the initial governance.
	 */
	constructor() {
		address msgSender = _msgSender();
		_governance = msgSender;
		emit GovernanceChanged(address(0), msgSender);
	}

	/**
	 * @dev Throws if called by any account other than the governance.
	 */
	modifier onlyGovernance() {
		require(governance() == _msgSender(), "Governable::onlyGovernance: caller is not governance");
		_;
	}

	/**
	 * @dev Returns the address of the current governance.
	 */
	function governance() public view virtual override returns (address) {
		return _governance;
	}

	/**
	 * @dev Returns the address of the pending governance.
	 */
	function pendingGovernance() public view virtual override returns (address) {
		return _pendingGovernance;
	}

	/**
	 * @dev Begins the governance transfer handshake with a new account (`newGov`).
	 *
	 * Requirements:
	 *   - can only be called by the current governance
	 */
	function changeGovernance(address _newGov) public virtual override onlyGovernance {
		require(_newGov != address(0), "Governable::changeGovernance: new governance cannot be the zero address");
		_pendingGovernance = _newGov;
	}

	/**
	 * @dev Ends the governance transfer handshake that results in governance powers being handed to the caller
	 *
	 * Requirements:
	 *   - caller must be the pending governance address
	 */
	function acceptGovernance() external virtual override {
		require(_msgSender() == _pendingGovernance, "Governable::acceptGovernance: only pending governance can accept");
		emit GovernanceChanged(_governance, _pendingGovernance);
		_governance = _pendingGovernance;
		_pendingGovernance = address(0);
	}

	/**
	 * @dev Leaves the contract without governance. It will not be possible to call
	 * `onlyGovernance` functions anymore. Can only be called by the current governance.
	 *
	 * NOTE: Renouncing governance will leave the contract without an governance,
	 * thereby removing any functionality that is only available to the governance.
	 */
	function removeGovernance() public virtual override onlyGovernance {
		emit GovernanceChanged(_governance, address(0));
		_governance = address(0);
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

interface IBlackbeard {
	function sew(address dst, uint256 amount) external;

	function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IJollyRoger is IERC20, IERC20Metadata {
	function maximumSupply() external view returns (uint256);

	function mintable() external view returns (uint256);

	function mint(address dst, uint256 amount) external returns (bool);

	function burn(address src, uint256 amount) external returns (bool);

	function increaseAllowance(address spender, uint256 amount) external returns (bool);

	function decreaseAllowance(address spender, uint256 amount) external returns (bool);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function metadataManager() external view returns (address);

	function updateTokenMetadata(string memory tokenName, string memory tokenSymbol) external returns (bool);

	function supplyManager() external view returns (address);

	function supplyFreezeEnds() external view returns (uint256);

	function supplyFreeze() external view returns (uint32);

	function supplyFreezeMinimum() external view returns (uint32);

	function supplyGrowthMaximum() external view returns (uint256);

	function setSupplyManager(address newSupplyManager) external returns (bool);

	function setMetadataManager(address newMetadataManager) external returns (bool);

	function setSupplyFreeze(uint32 period) external returns (bool);

	function setMaximumSupply(uint256 newMaxSupply) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
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
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;
/* solhint-disable func-name-mixedcase */

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Permit is IERC721 {
	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function permit(
		address spender,
		uint256 tokenId,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function nonces(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

interface IGovernable {
	function governance() external view returns (address);

	function pendingGovernance() external view returns (address);

	function changeGovernance(address newGov) external;

	function acceptGovernance() external;

	function removeGovernance() external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { IERC721Permit } from "../interfaces/IERC721Permit.sol";
import { IGovernable } from "./IGovernable.sol";
import { ILootContainer } from "./ILootContainer.sol";

interface ILootItem is IERC721Enumerable, IERC721Permit {
	enum Items {
		FREE_SLOT,
		HEAD,
		NECK,
		CHEST,
		HANDS,
		LEGS,
		FEET,
		WEAPON,
		OFF_HAND
	}

	enum Rarity {
		UNKNOWN,
		COMMON,
		UNCOMMON,
		RARE,
		EPIC,
		LEGENDARY,
		MYTHIC,
		RELIC
	}

	struct Item {
		uint256 seed;
		uint8 index;
		uint8 appearance;
		uint8 prefix;
		uint8 suffix;
		uint8 augmentation;
		Rarity rarity;
	}

	event LootItemMinted(uint256 indexed id, Items item, Rarity rarity);

	function mint(
		address to,
		ILootContainer.Containers container,
		uint256 seed
	) external;

	function lootURI(uint256 id, Items itemType) external view returns (string memory);

	function lootSVG(
		uint256 id,
		Items itemType,
		bool single
	) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}