/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;
// import "https://github.com/enjin/erc-1155/blob/master/contracts/IERC1155TokenReceiver.sol";
// import "https://github.com/enjin/erc-1155/blob/master/contracts/SafeMath.sol";
// //import "./SafeMath.sol";
// import "https://github.com/enjin/erc-1155/blob/master/contracts/Address.sol";
// import "https://github.com/enjin/erc-1155/blob/master/contracts/Common.sol";




contract ERC1155{

    

    // Mapping from token ID to account balances
    // mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    // For logged events. I will allow you to search for these events using the indexed parameters as filters
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event TransferSingle(address _from,address  _to,uint256 _id ,uint256 _value);

//    emit TransferSingle(msg.sender, _from, _to, _id, _value);
//    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
//    emit ApprovalForAll(owner, operator, approved);

    
    

    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return balances[id][account];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    function _setApprovalForAll(address owner, address operator, bool approved) public virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual returns (bool) {
        return _operatorApprovals[account][operator];
    }
    
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external {

        // MUST Throw on errors
        require(_to != address(0x0), "destination address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array length must match.");
        require(_from == msg.sender || _operatorApprovals[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][_from] = balances[id][_from] - value;
            balances[id][_to]   = value + balances[id][_to];
        }

    }

    function uri(uint256) public view virtual returns (string memory) {
        return _uri;    
    }

    // function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {

    //     // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
    //     // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.


    //     // Note: if the below reverts in the onERC1155Received function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
    //     // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_ACCEPTED test.
    //     require(ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) == ERC1155_ACCEPTED, "contract returned an unknown value from onERC1155Received");
    // }
    // function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {

    //     require(_to != address(0x0), "_to must be non-zero.");
    //     require(_from == msg.sender || _operatorApprovals[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

    //   //  SafeMath will throw with insuficient funds _from
    //   //  or if _id is not valid (balance will be 0)
    //     balances[_id][_from] = balances[_id][_from].sub(_value);
    //     balances[_id][_to]   = _value.add(balances[_id][_to]);

    //   //  MUST emit event
    //     emit TransferSingle(msg.sender, _from, _to, _id, _value);

    //     // Now that the balance is updated and the event was emitted,
    //     // call onERC1155Received if the destination is a contract.
    //     if (_to.isContract()) {
    //         _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
    //     }
    // }
    // function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {

    //     // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
    //     // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.


    //     // Note: if the below reverts in the onERC1155Received function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
    //     // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_ACCEPTED test.
    //     require(ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data), "contract returned an unknown value from onERC1155Received");
    // }


       
}