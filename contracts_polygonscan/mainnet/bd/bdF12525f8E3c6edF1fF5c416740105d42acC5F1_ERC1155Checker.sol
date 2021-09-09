/**
 *Submitted for verification at polygonscan.com on 2021-09-09
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.7;

interface IERC1155 {

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

}

contract ERC1155Checker{
    
    IERC1155 public thisERC1155;
    address public admin;
    
    constructor(){
        admin = msg.sender;
    }
    
    modifier onlyAdmin{
        require(msg.sender == admin);
        _;
    }
    
    function setAdmin(address _admin) public onlyAdmin{
        admin = _admin;
    }
    
    function setERC1155Address(address _thisERC1155) public onlyAdmin{
        thisERC1155 = IERC1155(_thisERC1155);
    }
    
    function balanceOf(address _owner, uint256 _id) public view returns (uint256){
        return thisERC1155.balanceOf(_owner,_id);
    }
    
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) public view returns (uint256[] memory){
        return thisERC1155.balanceOfBatch(_owners,_ids);
    }


}