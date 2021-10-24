/**
 *Submitted for verification at polygonscan.com on 2021-10-23
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

/// @notice Brief interface for Moloch DAO v2. 
interface IMolMinimal { 
    function getProposalFlags(uint256 proposalId) external view returns (bool[6] memory);
    
    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);

    function withdrawBalance(address token, uint256 amount) external;
}

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

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

/// @notice Low-level caller, ETH/NFT holder, separate bank for Moloch DAO v2 - based on Raid Guild `Minion`.
/// @author Ross Campbell.
contract SuChef is ReentrancyGuard {
    address internal depositToken;
    IMolMinimal public mochiMol; // parent 

    mapping(uint256 => Action) public actions; // proposalId => Action

    struct Action {
        uint256 value;
        address to;
        address proposer;
        bool executed;
        bytes data;
    }

    event ProposeAction(uint256 proposalId, address proposer);
    event ExecuteAction(uint256 proposalId, address executor);

    function init(address _depositToken, IMolMinimal _mochiMol) external {
        require(address(mochiMol) == address(0), "INITIALIZED");
        depositToken = _depositToken;
        mochiMol = _mochiMol;
    }

    function doWithdraw(address token, uint256 amount) external nonReentrant {
        mochiMol.withdrawBalance(token, amount); // withdraw funds from parent
    }

    function proposeAction(
        address actionTo,
        uint256 actionValue,
        bytes calldata actionData,
        string calldata details
    ) external nonReentrant returns (uint256) {
        // No calls to zero address allows us to check that proxy submitted
        // the proposal without getting the proposal struct from parent
        require(actionTo != address(0), "INVALID_ACTION_TO");

        uint256 proposalId = mochiMol.submitProposal(
            address(this),
            0,
            0,
            0,
            depositToken,
            0,
            depositToken,
            details
        );

        Action memory action = Action({
            value: actionValue,
            to: actionTo,
            proposer: msg.sender,
            executed: false,
            data: actionData
        });

        actions[proposalId] = action;

        emit ProposeAction(proposalId, msg.sender);
        return proposalId;
    }

    function executeAction(uint256 proposalId) external nonReentrant returns (bytes memory) {
        Action memory action = actions[proposalId];
        bool[6] memory flags = mochiMol.getProposalFlags(proposalId);

        require(action.to != address(0), "INVALID_ID");
        require(!action.executed, "ACTION_EXECUTED");
        require(address(this).balance >= action.value, "INSUFF_ETH");
        require(flags[2], "PROPOSAL_NOT_PASSED");

        // execute call
        actions[proposalId].executed = true;
        (bool success, bytes memory retData) = action.to.call{value: action.value}(action.data);
        require(success, "CALL_FAILURE");
        emit ExecuteAction(proposalId, msg.sender);
        return retData;
    }
    
    /// @dev Returns confirmation for 'safe' ERC-721 (NFT) transfers.
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4 sig) {
        sig = 0x150b7a02; // 'onERC721Received(address,address,uint,bytes)'
    }
    
    /// @dev Returns confirmation for 'safe' ERC-1155 transfers.
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4 sig) {
        sig = 0xf23a6e61; // 'onERC1155Received(address,address,uint,uint,bytes)'
    }
    
    /// @dev Returns confirmation for 'safe' batch ERC-1155 transfers.
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4 sig) {
        sig = 0xbc197c81; // 'onERC1155BatchReceived(address,address,uint[],uint[],bytes)'
    }

    receive() external payable {}
}