/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

// File: contracts/BulkAirdrop.sol



pragma solidity >=0.7.0 <0.9.0;





interface IERC20{

    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

}

interface IERC721{
    function safeTransferFrom(address from,address to,uint256 tokenId) external;

}

interface IERC1155{

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount,bytes calldata data) external;
}

contract BulkAirDrop {
    constructor() {}

    function BulkAirDropERC20(IERC20 _token, address[] calldata _to, uint256[] calldata _value) public {
        require(_to.length == _value.length, "Recievers and amounts are different length");
        for (uint256 i = 0; i < _to.length; i++) {
            require(_token.transferFrom(msg.sender, _to[i], _value[i]));
        }
    }


    function bulkAirdropERC721(IERC721 _token, address[] calldata _to, uint256[] calldata _id) public{
        require(_to.length == _id.length, "Recievers and amounts are different length");
        for (uint256 i = 0; i < _to.length; i++) {
            _token.safeTransferFrom(msg.sender, _to[i], _id[i]);

        }
    }

    function bulkAirdropERC1155(IERC1155 _token, address[] calldata _to, uint256[] calldata _id, uint256[] calldata _amount) public{
        require(_to.length == _id.length, "Recievers and amounts are different length");
        for (uint256 i = 0; i < _to.length; i++) {
            _token.safeTransferFrom(msg.sender, _to[i], _id[i], _amount[i], "");

        }
    }
}