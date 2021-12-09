// SPDX-License-Identifier: MIT 
pragma solidity 0.8.2;

interface IERC20 {
       function transferFrom(
        address sender, address recipient, uint256 amount
    ) external returns (bool);
}
interface IERC721 {
    function safeTransferFrom(
        address from, address to, uint256 tokenId
    ) external;
}
interface IERC1155 {
        function safeTransferFrom(
        address from, address to, uint256 id,
        uint256 amount,  bytes calldata data
    ) external;
}

contract MultiSenderV2 {

    function transferETH(address[] memory _recipients, uint[] memory _amounts) external payable {
        require(_recipients.length == _amounts.length, "01");
        uint totalAmount;
        for(uint i=0; i<_amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        require(msg.value == totalAmount, "03");

        for(uint i=0; i<_recipients.length; i++) {
            payable(_recipients[i]).transfer(_amounts[i]);
        }
    }
    
    function transferERC20(address _tokenAddress, address[] memory _recipients, uint[] memory _amounts) external {
        require(_recipients.length == _amounts.length, "01");
        for(uint i=0; i<_recipients.length; i++) {
            IERC20(_tokenAddress).transferFrom(msg.sender, _recipients[i], _amounts[i]);
        }
    }
    
    function transferERC721(address _tokenAddress, address[] memory _recipients, uint[] memory _tokenIds) external {
        require(_recipients.length == _tokenIds.length, "02");
        for(uint i=0; i<_recipients.length; i++) {
            IERC721(_tokenAddress).safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i]);
        }
    }
    
    function transferERC1155(address _tokenAddress, address[] memory _recipients, uint[] memory _tokenIds, uint[] memory _amounts) external {
        require(_recipients.length == _tokenIds.length, "02");
        require(_recipients.length == _amounts.length, "01");
        for(uint i=0; i<_recipients.length; i++) {
            IERC1155(_tokenAddress).safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i], _amounts[i], '0x');
        }
    }
}