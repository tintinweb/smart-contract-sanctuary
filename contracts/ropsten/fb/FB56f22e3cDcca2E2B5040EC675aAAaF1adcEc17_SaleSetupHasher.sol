// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISaleSetupHasher.sol";
import "../registry/FakeRegistryUser.sol";

// we deploy this standalone to reduce the size of SaleFactory

contract SaleSetupHasher is ISaleSetupHasher, FakeRegistryUser {
  /**
   * @dev Validate and pack a VestingStep[]. It must be called by the dApp during the configuration of the Sale setup. The same code can be executed in Javascript, but running a function on a smart contract guarantees future compatibility.
   * @param vestingStepsArray The array of VestingStep
   */

  function validateAndPackVestingSteps(ISaleDB.VestingStep[] memory vestingStepsArray)
    external
    pure
    override
    returns (uint256[] memory, string memory)
  {
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
    return (steps, "Success");
  }

  /*
  abi.encodePacked is unable to pack structs. To get a signable hash, we need to
  put the data contained in the struct in types that are packable.
  */
  function packAndHashSaleConfiguration(
    ISaleDB.Setup memory setup,
    uint256[] memory extraVestingSteps,
    address paymentToken
  ) public pure override returns (bytes32) {
    require(setup.remainingAmount == 0 && setup.tokenListTimestamp == 0, "SaleFactory: invalid setup");
    return
      keccak256(
        abi.encodePacked(
          "\x19\x00", /* EIP-191 */
          setup.sellingToken,
          setup.owner,
          setup.isTokenTransferable,
          setup.isFutureToken,
          setup.futureTokenSaleId,
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
            uint256(setup.extraFeePoints)
          ]
        )
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISaleDB.sol";

interface ISaleSetupHasher {
  function validateAndPackVestingSteps(ISaleDB.VestingStep[] memory vestingStepsArray)
    external
    pure
    returns (uint256[] memory, string memory);

  function packAndHashSaleConfiguration(
    ISaleDB.Setup memory setup,
    uint256[] memory extraVestingSteps,
    address paymentToken
  ) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFakeRegistryUser.sol";

contract FakeRegistryUser is IFakeRegistryUser {
  function updateRegisteredContracts() external override {}
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

interface IFakeRegistryUser {
  function updateRegisteredContracts() external;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
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