// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

import "./ISaleFactory.sol";
import "./ISaleDB.sol";
import "./Sale.sol";
import "../registry/RegistryUser.sol";

import {SaleLib} from "../libraries/SaleLib.sol";

contract SaleFactory is ISaleFactory, RegistryUser {
  bytes32 internal constant _SALE_DATA = keccak256("SaleData");
  bytes32 internal constant _SALE_DB = keccak256("SaleDB");

  mapping(bytes32 => uint16) private _setupHashes;
  mapping(address => bool) private _operators;

  modifier onlyOperator() {
    require(isOperator(_msgSender()), "SaleFactory: only operators can call this function");
    _;
  }

  constructor(address registry, address operator) RegistryUser(registry) {
    setOperator(operator, true);
  }

  ISaleData private _saleData;
  ISaleDB private _saleDB;

  function getSaleIdBySetupHash(bytes32 hash) external view virtual override returns (uint16) {
    return _setupHashes[hash];
  }

  function updateRegisteredContracts() external virtual override onlyRegistry {
    address addr = _get(_SALE_DATA);
    if (addr != address(_saleData)) {
      _saleData = ISaleData(addr);
    }
    addr = _get(_SALE_DB);
    if (addr != address(_saleDB)) {
      _saleDB = ISaleDB(addr);
    }
  }

  function setOperator(address operator, bool isOperator_) public override onlyOwner {
    if (!isOperator_ && _operators[operator]) {
      delete _operators[operator];
      emit OperatorUpdated(operator, false);
    } else if (isOperator_ && !_operators[operator]) {
      _operators[operator] = true;
      emit OperatorUpdated(operator, true);
    }
  }

  function isOperator(address operator) public view override returns (bool) {
    return _operators[operator];
  }

  function approveSale(bytes32 setupHash) external override onlyOperator {
    uint16 saleId = _saleDB.nextSaleId();
    _saleData.increaseSaleId();
    _setupHashes[setupHash] = saleId;
    emit SaleApproved(saleId);
  }

  function revokeSale(bytes32 setupHash) external override onlyOperator {
    delete _setupHashes[setupHash];
    emit SaleRevoked(_setupHashes[setupHash]);
  }

  function newSale(
    uint16 saleId,
    ISaleDB.Setup memory setup,
    uint256[] memory extraVestingSteps,
    address paymentToken
  ) external override {
    bytes32 setupHash = SaleLib.packAndHashSaleConfiguration(setup, extraVestingSteps, paymentToken);
    require(saleId != 0 && _setupHashes[setupHash] == saleId, "SaleFactory: non approved sale or modified params");
    if (setup.futureTokenSaleId != 0) {
      ISaleDB.Setup memory futureTokenSetup = _saleData.getSetupById(setup.futureTokenSaleId);
      require(futureTokenSetup.isFutureToken, "SaleFactory: futureTokenSaleId does not point to a future Token sale");
      require(futureTokenSetup.totalValue == setup.totalValue, "SaleFactory: token value mismatch");
    }
    Sale sale = new Sale(saleId, address(registry));
    address addr = address(sale);
    _saleData.setUpSale(saleId, addr, setup, extraVestingSteps, paymentToken);
    delete _setupHashes[setupHash];
    emit NewSale(saleId, addr);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISaleData.sol";

interface ISaleFactory {
  event SaleApproved(uint256 saleId);
  event SaleRevoked(uint256 saleId);
  event NewSale(uint256 saleId, address saleAddress);
  event OperatorUpdated(address operator, bool isOperator);

  function getSaleIdBySetupHash(bytes32 hash) external view returns (uint16);

  function setOperator(address operator, bool isOperator_) external;

  function isOperator(address operator) external view returns (bool);

  function approveSale(bytes32 setupHash) external;

  function revokeSale(bytes32 setupHash) external;

  function newSale(
    uint16 saleId,
    ISaleDB.Setup memory setup,
    uint256[] memory extraVestingSteps,
    address paymentToken
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Min.sol";

interface ISaleDB {
  // VestingStep is used only for input.
  // The actual schedule is stored as a single uint256
  struct VestingStep {
    uint256 waitTime;
    uint256 percentage;
  }

  // We groups the parameters by 32bytes to save space.
  struct Setup {
    // first 32 bytes - full
    address owner; // 20 bytes
    uint32 minAmount; // << USD, 4 bytes
    uint32 capAmount; // << USD, it can be = totalValue (no cap to single investment), 4 bytes
    uint32 tokenListTimestamp; // 4 bytes
    // second 32 bytes - full
    uint120 remainingAmount; // << selling token
    // pricingPayments and pricingToken builds a fraction to define the price of the token
    uint64 pricingToken;
    uint64 pricingPayment;
    uint8 paymentTokenId; // << TokenRegistry Id of the token used for the payments (USDT, USDC...)
    // third 32 bytes - full
    uint256 vestingSteps; // < at most 15 vesting events
    // fourth 32 bytes - 31 bytes
    IERC20Min sellingToken;
    uint32 totalValue; // << USD
    uint16 tokenFeePoints; // << the fee in sellingToken due by sellers at launch
    // a value like 3.25% is set as 325 base points
    uint16 extraFeePoints; // << the optional fee in USD paid by seller at launch
    uint16 paymentFeePoints; // << the fee in USD paid by buyers when investing
    bool isTokenTransferable;
    // fifth 32 bytes - 12 bytes remaining
    address saleAddress; // 20 bytes
    bool isFutureToken;
    uint16 futureTokenSaleId;
    uint16 tokenFeeInvestorPoints; // << the fee in sellingToken due by the investor
  }

  function nextSaleId() external view returns (uint16);

  function increaseSaleId() external;

  function getSaleIdByAddress(address saleAddress) external view returns (uint16);

  function getSaleAddressById(uint16 saleId) external view returns (address);

  function initSale(
    uint16 saleId,
    Setup memory setup,
    uint256[] memory extraVestingSteps
  ) external;

  function triggerTokenListing(uint16 saleId) external;

  function updateRemainingAmount(
    uint16 saleId,
    uint120 remainingAmount,
    bool increment
  ) external;

  function makeTransferable(uint16 saleId) external;

  function getSetupById(uint16 saleId) external view returns (Setup memory);

  function getExtraVestingStepsById(uint16 saleId) external view returns (uint256[] memory);

  function setApproval(
    uint16 saleId,
    address investor,
    uint32 usdValueAmount
  ) external;

  function deleteApproval(uint16 saleId, address investor) external;

  function getApproval(uint16 saleId, address investor) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../nft/ISANFT.sol";
import "./ISaleData.sol";
import "./ISale.sol";
import "./IERC20Min.sol";
import "../registry/IApeRegistry.sol";
import "../libraries/SafeERC20Min.sol";

contract Sale is ISale, Ownable {
  using SafeMath for uint256;
  using SafeERC20Min for IERC20Min;

  bytes32 internal constant _SALE_DATA = keccak256("SaleData");
  bytes32 internal constant _SANFT_MANAGER = keccak256("SANFTManager");

  uint16 private _saleId;
  IApeRegistry private _apeRegistry;

  modifier onlyFromManager() {
    require(
      _msgSender() == _apeRegistry.get(_SANFT_MANAGER),
      string(abi.encodePacked("RegistryUser: only SANFTManager can call this function"))
    );
    _;
  }

  constructor(uint16 saleId_, address registry) {
    _saleId = saleId_;
    _apeRegistry = IApeRegistry(registry);
  }

  function saleId() external view override returns (uint16) {
    return _saleId;
  }

  function _getSaleData() internal view returns (ISaleData) {
    return ISaleData(_apeRegistry.get(_SALE_DATA));
  }

  function _isSaleOwner(ISaleData saleData) internal view {
    require(_msgSender() == saleData.getSetupById(_saleId).owner, "Sale: caller is not the owner");
  }

  // Sale creator calls this function to start the sale.
  // Precondition: Sale creator needs to approve cap + fee Amount of token before calling this
  function launch() external virtual override {
    ISaleData saleData = _getSaleData();
    _isSaleOwner(saleData);
    (IERC20Min sellingToken, uint256 amount) = saleData.setLaunchOrExtension(_saleId, 0);
    sellingToken.safeTransferFrom(_msgSender(), address(this), amount);
  }

  // Sale creator calls this function to extend a sale.
  // Precondition: Sale creator needs to approve cap + fee Amount of token before calling this
  function extend(uint256 extraValue) external virtual override {
    ISaleData saleData = _getSaleData();
    _isSaleOwner(saleData);
    (IERC20Min sellingToken, uint256 extraAmount) = saleData.setLaunchOrExtension(_saleId, extraValue);
    sellingToken.safeTransferFrom(_msgSender(), address(this), extraAmount);
  }

  // Invest amount into the sale.
  // Investor needs to approve the payment + fee amount need for purchase before calling this
  function invest(uint32 usdValueAmount) external virtual override {
    ISaleData saleData = _getSaleData();
    ISaleDB.Setup memory setup = saleData.getSetupById(_saleId);
    require(setup.futureTokenSaleId == 0, "Cannot invest in swap");
    (uint256 paymentTokenAmount, uint256 buyerFee) = saleData.setInvest(_saleId, _msgSender(), usdValueAmount);
    IERC20Min paymentToken = IERC20Min(saleData.paymentTokenById(setup.paymentTokenId));
    paymentToken.safeTransferFrom(_msgSender(), saleData.apeWallet(), buyerFee);
    paymentToken.safeTransferFrom(_msgSender(), address(this), paymentTokenAmount);
  }

  function withdrawPayment(uint256 amount) external virtual override {
    ISaleData saleData = _getSaleData();
    _isSaleOwner(saleData);
    IERC20Min paymentToken = IERC20Min(saleData.paymentTokenById(saleData.getSetupById(_saleId).paymentTokenId));
    if (amount == 0) {
      amount = paymentToken.balanceOf(address(this));
    }
    paymentToken.transfer(_msgSender(), amount);
  }

  function withdrawToken(uint256 amount) external virtual override {
    ISaleData saleData = _getSaleData();
    _isSaleOwner(saleData);
    IERC20Min sellingToken = saleData.setWithdrawToken(_saleId, amount);
    sellingToken.transfer(_msgSender(), amount);
  }

  function vest(
    address saOwner,
    uint120 fullAmount,
    uint120 remainingAmount,
    uint256 requestedAmount
  ) external virtual override onlyFromManager returns (uint256) {
    ISaleData saleData = _getSaleData();
    uint256 vestedAmount = saleData.vestedAmount(_saleId, fullAmount, remainingAmount);
    if (requestedAmount == 0) {
      requestedAmount = vestedAmount;
    }
    if (requestedAmount <= vestedAmount) {
      saleData.getSetupById(_saleId).sellingToken.transfer(saOwner, requestedAmount);
      return requestedAmount;
    } else {
      return 0;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IApeRegistry.sol";
import "./IRegistryUser.sol";

// for debugging only
//import "hardhat/console.sol";

contract RegistryUser is IRegistryUser, Ownable {
  IApeRegistry public registry;

  modifier onlyRegistry() {
    require(
      _msgSender() == address(registry),
      string(abi.encodePacked("RegistryUser: only ApeRegistry can call this function"))
    );
    _;
  }

  constructor(address addr) {
    // we do not check in addr == address(0) because the deployment is
    // done by a script and the registry's address can never be zero
    registry = IApeRegistry(addr);
  }

  function _get(bytes32 contractHash) internal view returns (address) {
    return registry.get(contractHash);
  }

  // This must be overwritten by passive users.
  function updateRegisteredContracts() external virtual override {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../sale/ISaleDB.sol";

library SaleLib {
  /**
   * @dev Validate and pack a VestingStep[]. It must be called by the dApp during the configuration of the Sale setup. The same code can be executed in Javascript, but running a function on a smart contract guarantees future compatibility.
   * @param vestingStepsArray The array of VestingStep

   A single ISaleDB.VestingStep is an object like:

   {
    "waitTime": 30,     // 30 days
    "percentage": 15    // 15%
  }

   Putting the data in the blockchain would be very expensive for vesting schedules with many steps.
   Consider the following edge case (taken from our tests):

   ISaleDB.VestingStep[] memory steps = [
    {"waitTime":10,"percentage":1},{"waitTime":20,"percentage":2}, {"waitTime":30,"percentage":3},
    {"waitTime":40,"percentage":4},{"waitTime":50,"percentage":5},
    {"waitTime":60,"percentage":6},{"waitTime":70,"percentage":7},{"waitTime":80,"percentage":8},
    {"waitTime":90,"percentage":9},{"waitTime":100,"percentage":10},{"waitTime":110,"percentage":11},
    {"waitTime":120,"percentage":12},{"waitTime":130,"percentage":13},{"waitTime":140,"percentage":14},
    {"waitTime":150,"percentage":15},{"waitTime":160,"percentage":16},{"waitTime":170,"percentage":17},
    {"waitTime":180,"percentage":18},{"waitTime":190,"percentage":19},{"waitTime":200,"percentage":20},
    {"waitTime":210,"percentage":21},{"waitTime":220,"percentage":22},{"waitTime":230,"percentage":23},
    {"waitTime":240,"percentage":24},{"waitTime":250,"percentage":25},{"waitTime":260,"percentage":26},
    {"waitTime":270,"percentage":27},{"waitTime":280,"percentage":28},{"waitTime":290,"percentage":29},
    {"waitTime":300,"percentage":30},{"waitTime":310,"percentage":31},{"waitTime":320,"percentage":32}
  ]

  Saving it in a mapping(uint => VestingStep) would cost a lot of gas, with the risk of going out of gas.

  The idea is to pack steps in uint256. In the case above, we would get
  the following array, which would cost only 3 words.

    [
      "11010010009009008008007007006006005005004004003003002002001001000",
      "22021021020020019019018018017017016016015015014014013013012012011",
      "32031031030030029029028028027027026026025025024024023023022"
    ]

  For better optimization, the first element of the array is saved in the sale
  setup struct (ISaleDB.Setup)), because it is mandatory. The remaining 2
  elements would be saved in the _extraVestingSteps array.

  Look at the first uint256 in the array above. It can be seen as

  011010 010009 009008 008007 007006 006005 005004 004003 003002 002001 001000

  where any element is composed by a composition of 4 digits for the number of days,
  and 2 digits for the percentage. The percentage is diminished by 1 because
  it can never be zero. So, for example, the VestingStep

    {
      "waitTime": 300,
      "percentage": 50
    }

  becomes 300 days * 100 + (50% - 1) = 030049

  We can pack 11 vesting steps in a single uint256

   */

  function validateAndPackVestingSteps(ISaleDB.VestingStep[] memory vestingStepsArray)
    internal
    pure
    returns (uint256[] memory)
  {
    // the number 11 is because we can pack at most 11 steps in a single uint256
    uint256 len = vestingStepsArray.length / 11;
    if (vestingStepsArray.length % 11 > 0) len++;
    uint256[] memory steps = new uint256[](len);
    uint256 j;
    uint256 k;
    for (uint256 i = 0; i < vestingStepsArray.length; i++) {
      if (vestingStepsArray[i].waitTime > 9999) {
        revert("waitTime cannot be more than 9999 days");
      }
      if (i > 0) {
        if (vestingStepsArray[i].percentage <= vestingStepsArray[i - 1].percentage) {
          revert("Vest percentage should be monotonic increasing");
        }
        if (vestingStepsArray[i].waitTime <= vestingStepsArray[i - 1].waitTime) {
          revert("waitTime should be monotonic increasing");
        }
      }
      steps[j] += ((vestingStepsArray[i].percentage - 1) + 100 * (vestingStepsArray[i].waitTime % (10**4))) * (10**(6 * k));
      if (i % 11 == 10) {
        j++;
        k = 0;
      } else {
        k++;
      }
    }
    if (vestingStepsArray[vestingStepsArray.length - 1].percentage != 100) {
      revert("Vest percentage should end at 100");
    }
    return steps;
  }

  /**
   * @dev Calculate the vesting percentage, based on values in Setup.vestingSteps and extraVestingSteps[]
   * @param vestingSteps The vales of Setup.VestingSteps, first 11 events
   * @param extraVestingSteps The array of extra vesting steps
   * @param tokenListTimestamp The timestamp when token has been listed
   * @param currentTimestamp The current timestamp (it'd be, most likely, block.timestamp)

   This function is a bit tricky but it does the job very well.
   Take the example above, where the packed vesting steps are

   [
    "11010010009009008008007007006006005005004004003003002002001001000",
    "22021021020020019019018018017017016016015015014014013013012012011",
    "33032032031031030030029029028028027027026026025025024024023023022",
    "35099034033"
  ]

   The variable step is a group of 6 digits representing a VestingStep.
   The algorithm starts from the right and extract the last 6 digits to
   convert them in days and percentages. Then moves to the next 6 digits towards the left.
   When it reaches the left of the uint256, the step will be empty, i.e., equal to zero.
   Then, the parent loop proceeds with next i in the parent loop, i.e., moves
   to the next uint256 in the array.

   */
  function calculateVestedPercentage(
    uint256 vestingSteps,
    uint256[] memory extraVestingSteps,
    uint256 tokenListTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint8) {
    // must add 1 to the length to avoid that diminishing i we reach the floor and
    // the function reverts
    for (uint256 i = extraVestingSteps.length + 1; i >= 1; i--) {
      uint256 steps = i > 1 ? extraVestingSteps[i - 2] : vestingSteps;
      // the number 12 is because there are at most 11 steps
      // in any single uint256. Must add 1 to avoid a revert, like above
      for (uint256 k = 12; k >= 1; k--) {
        uint256 step = steps / (10**(6 * (k - 1)));
        if (step != 0) {
          uint256 days_ = (step / 100);
          uint256 percentage = (step % 100) + 1;
          if ((days_ * 1 days) + tokenListTimestamp <= currentTimestamp) {
            return uint8(percentage);
          }
        }
        steps %= (10**(6 * (k - 1)));
      }
    }
    return 0;
  }

  /*
  abi.encodePacked is unable to pack structs. To get a signable hash, we need to
  put the data contained in the struct in types that are packable.
  */
  function packAndHashSaleConfiguration(
    ISaleDB.Setup memory setup,
    uint256[] memory extraVestingSteps,
    address paymentToken
  ) internal pure returns (bytes32) {
    require(setup.remainingAmount == 0 && setup.tokenListTimestamp == 0, "SaleFactory: invalid setup");
    return
      keccak256(
        abi.encodePacked(
          "\x19\x01", /* EIP-191 */
          setup.sellingToken,
          setup.owner,
          setup.isTokenTransferable,
          setup.isFutureToken,
          paymentToken,
          setup.vestingSteps,
          extraVestingSteps,
          [
            uint256(setup.pricingToken),
            uint256(setup.tokenListTimestamp),
            uint256(setup.remainingAmount),
            uint256(setup.minAmount),
            uint256(setup.capAmount),
            uint256(setup.pricingPayment),
            uint256(setup.tokenFeePoints),
            uint256(setup.totalValue),
            uint256(setup.paymentFeePoints),
            uint256(setup.extraFeePoints),
            uint256(setup.futureTokenSaleId),
            uint256(setup.tokenFeeInvestorPoints)
          ]
        )
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../nft/ISANFT.sol";
import "./ISaleDB.sol";
import "./IERC20Min.sol";

interface ISaleData {
  event ApeWalletUpdated(address wallet);
  event DaoWalletUpdated(address wallet);
  event SaleSetup(uint16 saleId, address saleAddress);
  event SaleLaunched(uint16 saleId, uint32 totalValue, uint120 totalTokens);
  event SaleExtended(uint16 saleId, uint32 extraValue, uint120 extraTokens);
  event TokenListed(uint16 saleId);
  event TokenForcefullyListed(uint16 saleId);

  function apeWallet() external view returns (address);

  function updateApeWallet(address apeWallet_) external;

  function updateDAOWallet(address apeWallet_) external;

  function increaseSaleId() external;

  function vestedPercentage(uint16 saleId) external view returns (uint8);

  function setUpSale(
    uint16 saleId,
    address saleAddress,
    ISaleDB.Setup memory setup,
    uint256[] memory extraVestingSteps,
    address paymentToken
  ) external;

  function getTokensAmountAndFeeByValue(uint16 saleId, uint32 value) external view returns (uint256, uint256);

  function paymentTokenById(uint8 id) external view returns (address);

  function makeTransferable(uint16 saleId) external;

  function fromValueToTokensAmount(uint16 saleId, uint32 value) external view returns (uint256);

  function fromTokensAmountToValue(uint16 saleId, uint120 amount) external view returns (uint32);

  function setLaunchOrExtension(uint16 saleId, uint256 value) external returns (IERC20Min, uint256);

  function getSetupById(uint16 saleId) external view returns (ISaleDB.Setup memory);

  // before calling this the dApp should verify that the proposed amount
  // is realistic, i.e., if there are enough tokens in the sale
  function approveInvestors(
    uint16 saleId,
    address[] memory investors,
    uint32[] memory amounts
  ) external;

  function setInvest(
    uint16 saleId,
    address investor,
    uint256 amount
  ) external returns (uint256, uint256);

  function setWithdrawToken(uint16 saleId, uint256 amount) external returns (IERC20Min);

  function vestedAmount(
    uint16 saleId,
    uint120 fullAmount,
    uint120 remainingAmount
  ) external view returns (uint256);

  function triggerTokenListing(uint16 saleId) external;

  function emergencyTriggerTokenListing(uint16 saleId) external;

  function setSwap(uint16 saleId, uint120 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../sale/ISaleData.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISANFT is IERC721 {
  // Hold the data of a Smart Agreement, packed into an uint256
  struct SA {
    uint16 saleId; // the sale that generated this SA
    uint120 fullAmount; // the initial amount without any vesting
    // the amount remaining in the SA that's not withdrawn.
    // some of the remainingAmount can be vested already.
    uint120 remainingAmount;
  }

  function mint(
    address recipient,
    uint16 saleId,
    uint120 fullAmount,
    uint120 remainingAmount
  ) external;

  function mint(address recipient, SA[] memory bundle) external;

  function nextTokenId() external view returns (uint256);

  function burn(uint256 tokenId) external;

  function withdraw(uint256 tokenId, uint256[] memory amounts) external;

  function withdrawables(uint256 tokenId) external view returns (uint16[] memory, uint256[] memory);

  function addSAToBundle(uint256 bundleId, SA memory newSA) external;

  function getBundle(uint256 bundleId) external view returns (SA[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Min {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../nft/ISANFT.sol";

interface ISale {
  function saleId() external view returns (uint16);

  function launch() external;

  function extend(uint256 extraValue) external;

  function invest(uint32 amount) external;

  function withdrawPayment(uint256 amount) external;

  function withdrawToken(uint256 amount) external;

  function vest(
    address saOwner,
    uint120 fullAmount,
    uint120 remainingAmount,
    uint256 requestedAmount
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IApeRegistry {
  event RegistryUpdated(bytes32 contractHash, address addr);
  event ChangePushedToSubscribers();

  function register(bytes32[] memory contractHashes, address[] memory addrs) external;

  function get(bytes32 contractHash) external view returns (address);

  function updateContracts(uint256 initialIndex, uint256 limit) external;

  function updateAllContracts() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../sale/IERC20Min.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Min {
  using Address for address;

  function safeTransferFrom(
    IERC20Min token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20Min token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20Min: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20Min: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

interface IRegistryUser {
  function updateRegisteredContracts() external;
}