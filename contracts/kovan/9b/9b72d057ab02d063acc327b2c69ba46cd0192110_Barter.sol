/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
/* is ERC165 */
interface IERC1155 {
    /**
    @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    MUST revert if `_to` is the zero address.
    MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    MUST revert on any other error.
    MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
    @param _from    Source address
    @param _to      Target address
    @param _id      ID of the token type
    @param _value   Transfer amount
    @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
    @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    MUST revert if `_to` is the zero address.
    MUST revert if length of `_ids` is not the same as length of `_values`.
    MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    MUST revert on any other error.        
    MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
    @param _from    Source address
    @param _to      Target address
    @param _ids     IDs of each token type (order and length must match _values array)
    @param _values  Transfer amounts per token type (order and length must match _ids array)
    @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes memory _data
    ) external;

    /**
    @notice Get the balance of an account's tokens.
    @param _owner  The address of the token holder
    @param _id     ID of the token
    @return        The _owner's balance of the token type requested
    */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
    @notice Get the balance of multiple account/token pairs
    @param _owners The addresses of the token holders
    @param _ids    ID of the tokens
    @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
    */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
    @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    @dev MUST emit the ApprovalForAll event on success.
    @param _operator  Address to add to the set of authorized operators
    @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
    @notice Queries the approval status of an operator for a given owner.
    @param _owner     The owner of the tokens
    @param _operator  Address of authorized operator
    @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract Barter {
    //IERC1155 diamondERC1155 = IERC1155(0x86935F11C86623deC8a25696E1C19a8659CbF95d);
    address private diamondAddy = 0x07543dB60F19b9B48A69a7435B5648b46d4Bb58E;
    IERC1155 diamondERC1155 = IERC1155(diamondAddy);
    mapping(address => uint256[]) private barters;
    mapping(address => uint256[]) private offers;
    uint256 private barterCounter = 0;

    constructor() {}

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) private {
        diamondERC1155.safeTransferFrom(_from, _to, _id, _value, _data);
    }

    function balanceOf(address _owner, uint256 _id) private view returns (uint256) {
        return diamondERC1155.balanceOf(_owner, _id);
    }

    function setApprovalForAll() external {
        diamondAddy.delegatecall(abi.encodeWithSignature("setApprovalForAll(address, bool)", address(this), true));
    }

    function isApprovedForAll(address _owner) private view returns (bool) {
        return diamondERC1155.isApprovedForAll(_owner, address(this));
    }


    function createBarter(uint256 _myTokenId) external returns (uint256) {
        require(isApprovedForAll(msg.sender));
        require(balanceOf(msg.sender, _myTokenId) > 0);

        barterCounter++;
        require(barters[msg.sender][barterCounter] == 0);

        barters[msg.sender][barterCounter] = _myTokenId;

        return barterCounter;
    }

    function createOffer(uint256 _fromTokenId, uint256 _barterId) external {
        require(isApprovedForAll(msg.sender));
        require(balanceOf(msg.sender, _fromTokenId) > 0);
        offers[msg.sender][_barterId] = _fromTokenId;
    }

    function removeBarter(uint256 _barterId) external {
        barters[msg.sender][_barterId] = 0;
    }

    function removeOffer(uint256 _barterId) external {
        offers[msg.sender][_barterId] = 0;
    }

    function acceptOffer(uint256 _myTokenId, address _from, uint256 _fromTokenId, uint256 _barterId) external {
        require(isApprovedForAll(_from));
        require(isApprovedForAll(msg.sender));
        require(balanceOf(_from, _fromTokenId) > 0);
        require(balanceOf(msg.sender, _myTokenId) > 0);

        require(barters[msg.sender][_barterId] == _myTokenId);
        require(offers[_from][_barterId] == _fromTokenId);

        barters[msg.sender][_barterId] = 0;
        offers[_from][_barterId] = 0;

        safeTransferFrom(_from, msg.sender, _fromTokenId, 1, new bytes(0));
        safeTransferFrom(msg.sender, _from, _myTokenId, 1, new bytes(0));
    }

}