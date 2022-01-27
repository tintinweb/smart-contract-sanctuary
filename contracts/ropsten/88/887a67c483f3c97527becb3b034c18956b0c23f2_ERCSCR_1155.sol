/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERCSCR_1155{

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
}