/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract ERC1155{
    
   

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private balance_of;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;




function balanceOf(address _owner, uint256 _token_id) public view returns (uint){
        
        require(_owner != address(0), "The address is not valid");

        uint balance_of_token_owner = balance_of[_token_id][_owner];
        return balance_of_token_owner;
    }


    function balanceOfBatch(address[] calldata _owners, uint[] calldata _token_ids) public view returns (uint[] memory){

        require(_owners.length == _token_ids.length, "There is a mismatch in addresses and token ids.");

        uint[] memory batchBalances;//= new uint256[](accounts.length);

        for (uint i = 0; i < _owners.length; i++) {
            batchBalances[i] = balanceOf(_owners[i], _token_ids[i]);
        }

        return batchBalances;
        
    }



 function setApprovalForAll(address _operator, bool _approved) public {
        
        require(msg.sender != _operator, "ERC1155: setting approval status for self");
        
        _operatorApprovals[msg.sender][_operator] = _approved;
        //emit ApprovalForAll(owner, operator, approved);
    }



function isApprovedForAll(address _owner, address _operator) external view returns (bool _approved){
        _approved = _operatorApprovals[_owner][_operator];
        return  _approved;

    }

    

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) public {
    
        balance_of[_id][_from] = balance_of[_id][_from] - _value;
        
        balance_of[_id][_to] =balance_of[_id][_to] + _value;
    
    }



   function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint[] calldata _values) public{

        require(_ids.length == _values.length, "ERC1155: ids and amounts length mismatch");

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 _value = _values[i];

            balance_of[_id][_from] = balance_of[_id][_from] - _value;
        
            balance_of[_id][_to] =balance_of[_id][_to] + _value;
        }

   }

    

}