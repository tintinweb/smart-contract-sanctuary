// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../third_party/gelato/PokeMeReady.sol";
import "../base/interface/ILinearPipeline.sol";
import "../base/interface/IController.sol";
import "../base/interface/IControllableExtended.sol";

contract GelatoAMBRebalancer is PokeMeReady {

  event GelatoRebalanceAllPipes(address AMBStrategy);

  /// @param _pokeMe Gelato PokeMe address https://docs.gelato.network/resources/contract-addresses
  constructor(address payable _pokeMe) PokeMeReady(_pokeMe) {}

  /// @dev Calls rebalanceAllPipes() for the strategy specified, calls restricted to PokeMe Gelato contract
  /// @param AMBStrategy AMB strategy address
  function rebalanceAllPipes(address AMBStrategy)
  external onlyPokeMe {
    address controller = IControllableExtended(AMBStrategy).controller();
    IController(controller).rebalance(AMBStrategy);
    emit GelatoRebalanceAllPipes(AMBStrategy);
  }

  /// @dev Gelato Resolver, that checks is rebalance needed for the strategy specified
  /// @param AMBStrategy AMB strategy address
  function isRebalanceNeededResolver(address AMBStrategy)
  external view returns (bool canExec, bytes memory execPayload) {
    canExec = ILinearPipeline(AMBStrategy).isRebalanceNeeded();
    execPayload = abi.encodeWithSelector(
      GelatoAMBRebalancer.rebalanceAllPipes.selector,
      AMBStrategy
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract PokeMeReady {
    address payable public immutable pokeMe;

    constructor(address payable _pokeMe) {
        pokeMe = _pokeMe;
    }

    modifier onlyPokeMe() {
        require(msg.sender == pokeMe, "PokeMeReady: onlyPokeMe");
        _;
    }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "./IPipe.sol";

interface ILinearPipeline {

  function pipes(uint index) external view returns (IPipe);

  function pipesLength() external view returns (uint);

  function isRebalanceNeeded() external view returns (bool);

  function getMostUnderlyingBalance() external view returns (uint);

  function getAmountOutReverted(uint256 amountIn, uint256 toPipeIndex) external;

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultsAndStrategies(address[] memory _vaults, address[] memory _strategies) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function distributor() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function rebalance(address _strategy) external;

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function changeWhiteListStatus(address[] calldata _targets, bool status) external;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @dev This interface contains additional functions for Controllable class
///      Don't extend exist Controllable for the reason huge coherence
interface IControllableExtended {

  function created() external view returns (uint256 ts);

  function controller() external view returns (address adr);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IPipe {

  function pipeline() external view returns (address);

  function name() external view returns (string memory);

  function sourceToken() external view returns (address);

  function outputToken() external view returns (address);

  function rewardTokens(uint index) external view returns (address);

  function rewardTokensLength() external view returns (uint);

  function prevPipe() external view returns (address);

  function nextPipe() external view returns (address);

  function setPipeline(address _pipeline) external;

  function setNextPipe(address _nextPipe) external;

  function setPrevPipe(address _prevPipe) external;

  function put(uint256 amount) external returns (uint256 output);

  function get(uint256 amount) external returns (uint256 output);

  function rebalance() external returns (uint256 imbalance, bool deficit);

  function needsRebalance() external view returns (bool);

  function claim() external;

  function sourceBalance() external view returns (uint256);

  function outputBalance() external view returns (uint256);

  function salvageFromPipe(address recipient, address token) external;

}