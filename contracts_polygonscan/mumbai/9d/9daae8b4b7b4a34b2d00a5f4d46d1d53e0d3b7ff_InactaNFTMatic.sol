//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./InactaNFT.sol";

contract InactaNFTMatic is InactaNFT {
  bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

  function initialize(string calldata _uri, address _childChainManager) external initializer {
    InactaNFT.initialize(_uri);
    _setupRole(DEPOSITOR_ROLE, _childChainManager);
  }

  /**
   * @notice called when tokens are deposited on root chain
   * @dev Should be callable only by ChildChainManager
   * Should handle deposit by minting the required tokens for user
   * Make sure minting is done only by this function
   * @param user user address for whom deposit is being done
   * @param depositData abi encoded ids array and amounts array
   */
  function deposit(address user, bytes calldata depositData) external onlyRole(DEPOSITOR_ROLE) {
    (uint256[] memory ids, uint256[] memory amounts, bytes memory data) = abi.decode(depositData, (uint256[], uint256[], bytes));
    require(user != address(0), "ChildMintableERC1155: INVALID_DEPOSIT_USER");
    _mintBatch(user, ids, amounts, data);
  }

  /**
   * @notice called when user wants to withdraw single token back to root chain
   * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
   * @param id id to withdraw
   * @param amount amount to withdraw
   */
  function withdrawSingle(uint256 id, uint256 amount) external {
    _burn(_msgSender(), id, amount);
  }

  /**
   * @notice called when user wants to batch withdraw tokens back to root chain
   * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
   * @param ids ids to withdraw
   * @param amounts amounts to withdraw
   */
  function withdrawBatch(uint256[] calldata ids, uint256[] calldata amounts) external {
    _burnBatch(_msgSender(), ids, amounts);
  }
}