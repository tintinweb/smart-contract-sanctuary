// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IOpenEdition.sol";

contract OpenEditionCloneFactory {

    event OpenEditionCloneDeployed(address indexed cloneAddress);

    address public referenceOpenEdition;
    address public cloner;

    constructor(address _referenceOpenEdition) public {
        referenceOpenEdition = _referenceOpenEdition;
        cloner = msg.sender;
    }

    modifier onlyCloner {
        require(msg.sender == cloner);
        _;
    }

    function changeCloner(address _newCloner) external onlyCloner {
        cloner = _newCloner;
    }

    function newOpenEditionClone(
        address _hausAddress,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _priceWei,
        uint256 _limitPerOrder,
        uint256 _stakingRewardPercentageBasisPoints,
        address _stakingSwapContract
    ) external onlyCloner returns (address) {
        // Create new OpenEditionClone
        address newOpenEditionCloneAddress = Clones.clone(referenceOpenEdition);
        IOpenEdition openEdition = IOpenEdition(newOpenEditionCloneAddress);
        openEdition.initialize(
            _hausAddress,
            _startTime,
            _endTime,
            _tokenAddress,
            _tokenId,
            _priceWei,
            _limitPerOrder,
            _stakingRewardPercentageBasisPoints,
            _stakingSwapContract,
            msg.sender
        );
        emit OpenEditionCloneDeployed(newOpenEditionCloneAddress);
        return newOpenEditionCloneAddress;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

interface IOpenEdition {
  function initialize(
      address _hausAddress,
      uint256 _startTime,
      uint256 _endTime,
      address _tokenAddress,
      uint256 _tokenId,
      uint256 _priceWei,
      uint256 _limitPerOrder,
      uint256 _stakingRewardPercentageBasisPoints,
      address _stakingSwapContract,
      address _controllerAddress
  ) external;
  function buy(uint256 amount) external payable;
  function supply() external view returns(uint256);
  function setTokenAddress(address _tokenAddress) external;
  function setTokenId(uint256 _tokenId) external;
  function pull() external;
  function isClosed() external view returns (bool);
  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4);
}