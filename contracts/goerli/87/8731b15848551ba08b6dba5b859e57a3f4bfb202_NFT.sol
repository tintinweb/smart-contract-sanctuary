/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;



interface IJungleFreaks {
    function mint(uint256 amount) external payable;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )  external;
}


//NFT基本上都是ETH支付
contract NFT  {

    address public nft_contract;
    address private admin_addr;
    mapping(address => bool) public allowList;

    constructor(address addr) {
        nft_contract = addr;
        admin_addr = msg.sender;
    }

    receive() external payable {}
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual  returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    function SetAllows(address[] memory _allowList) public {
        require(msg.sender == admin_addr,"invalid msg.sender");
        for (uint256 i=0; i < _allowList.length; i++) {
            allowList[_allowList[i]] = true;
        }
    }


    function mint(uint256  mint_amount,uint256  single_pay_amount,uint256  coinbase_amount,uint256 num) external payable {
        require(allowList[address(msg.sender)],"invalid msg.sender");
        for (uint256 i=0;i<num;i++) {
            (bool success,bytes memory data) = nft_contract.call{value: single_pay_amount}(abi.encodeWithSignature("mint(uint256)", mint_amount));
            require(success, string(data));
        }
        block.coinbase.transfer(coinbase_amount);
    }

    function claim(uint256[] memory tokenids,address to) external {
        require(msg.sender == admin_addr,"invalid msg.sender");
        for (uint256 ind = 0; ind < tokenids.length; ind++) {
            IJungleFreaks(nft_contract).safeTransferFrom(address(this),to,tokenids[ind]);
        }
    }

    function withdraw() external {
        require(msg.sender == admin_addr,"invalid msg.sender");
        payable(admin_addr).transfer(address(this).balance);
    }
}