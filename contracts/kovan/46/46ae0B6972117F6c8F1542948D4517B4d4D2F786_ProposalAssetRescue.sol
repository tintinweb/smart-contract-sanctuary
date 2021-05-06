pragma solidity 0.7.5;

import {IProposalExecutor} from '../interfaces/IProposalExecutor.sol';
import {IDistributorFactory} from '../interfaces/IDistributorFactory.sol';

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
}

interface IAaveTokenV3 {
  function retrieveStuckTokens(
    address asset,
    address safeVault,
    uint256 amount
  ) external;

  function rescueLockedTokens(
    address holderWithLockedTokens,
    address safeVault,
    uint256 amountOfLockedTokens
  ) external;
}

interface ILendToAaveMigratorV2 {
  function retrieveStuckTokens(
    address asset,
    address safeVault,
    uint256 amount
  ) external;
}

/**
 * @title AIPX2
 * @notice Proposal payload to be executed by the Aave Governance contract via DELEGATECALL
 * - Retrieve stuck tokens from AAVE token contract
 * - Rescue locked AAVE tokens from AAVE token contract
 * - Retrieve stuck tokens from LendToAaveMigrator contract
 * @author Miguel Martinez
 **/
contract ProposalAssetRescue is IProposalExecutor {
  event ProposalExecuted();

  IDistributorFactory public constant DISTRIBUTOR_FACTORY =
    IDistributorFactory(0x6082731fdAba4761277Fb31299ebC782AD3bCf24);

  bytes32 public constant MERKLE_ROOT =
    0xd7ac7473fdd17b9a62035f682dd3b56d00489d37f3de472acf1099c4a06b9e04;

  address public constant SHORT_EXECUTOR = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  IAaveTokenV3 public constant AAVE_TOKEN =
    IAaveTokenV3(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

  ILendToAaveMigratorV2 public constant MIGRATOR =
    ILendToAaveMigratorV2(0x317625234562B1526Ea2FaC4030Ea499C5291de4);

  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute() external override {
    // 1 Create a new Distributor
    uint256 distributorRound = DISTRIBUTOR_FACTORY.createRound(MERKLE_ROOT, SHORT_EXECUTOR);
    address distributor = DISTRIBUTOR_FACTORY.getDistributorOfRound(distributorRound);

    // 2 Retrieve stuck tokens from AAVE token contract
    // Note: AAVE tokens redirection: old holdings + migrated LEND
    address payable[2] memory assetsWithStuckTokensInAaveContract =
      [
        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9, // AAVE
        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984 // UNISWAP
      ];
    uint256[2] memory amountsOfStuckTokensInAaveContract =
      [
        uint256(28205119617772043090614), // 28205.119617772043090614 AAVE
        uint256(10915644380000000000) // 10.91564438 UNI
      ];

    uint256 i;
    for (i = 0; i < assetsWithStuckTokensInAaveContract.length; i++) {
      AAVE_TOKEN.retrieveStuckTokens(
        assetsWithStuckTokensInAaveContract[i],
        distributor,
        amountsOfStuckTokensInAaveContract[i]
      );
    }

    // 3 Rescue locked AAVE tokens from AAVE token contract
    address payable[1] memory holdersWithLockedAAVE =
      [
        0x80fB784B7eD66730e8b1DBd9820aFD29931aab03 // LEND contract
      ];
    uint256[1] memory amountsOfLockedAAVE =
      [
        uint256(989000000000000000) // 0.989 AAVE sent to LEND contract
      ];

    for (i = 0; i < holdersWithLockedAAVE.length; i++) {
      AAVE_TOKEN.rescueLockedTokens(holdersWithLockedAAVE[i], distributor, amountsOfLockedAAVE[i]);
    }

    // 4 Retrieve stuck tokens from LendToAaveMigrator contract
    // Note: AAVE tokens redirection: holding to rescue + migrated LEND + migrated LEND from LendToken + migrated LEND from AaveToken
    address payable[1] memory assetsWithStuckTokensInMigratorContract =
      [
        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9 // AAVE
      ];
    uint256[1] memory amountsOfStuckTokensInMigratorContract =
      [
        uint256(8610977516837315278471) // 0 + 0 + 8412526187361881856904 + 198451329475433421567
      ];

    for (i = 0; i < assetsWithStuckTokensInMigratorContract.length; i++) {
      MIGRATOR.retrieveStuckTokens(
        assetsWithStuckTokensInMigratorContract[i],
        distributor,
        amountsOfStuckTokensInMigratorContract[i]
      );
    }

    emit ProposalExecuted();
  }
}

pragma solidity 0.7.5;

interface IProposalExecutor {
  function execute() external;
}

pragma solidity 0.7.5;

interface IDistributorFactory {
  event RoundCreated(uint256 round, address distributor, address drainer);

  function getDistributorOfRound(uint256 round) external view returns (address);

  function getRoundsCount() external view returns (uint256);

  function createRound(bytes32 merkleRoot, address drainer) external returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}