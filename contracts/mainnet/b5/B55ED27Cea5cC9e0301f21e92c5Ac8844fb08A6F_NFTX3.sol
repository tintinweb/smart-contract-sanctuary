/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface NFTXMinter {
  function mint(uint256[] calldata tokenIds, uint256[] calldata amounts) external returns (uint256);
  function approve(address _spender, uint256 _value) external returns (bool success);
  function balanceOf(address tokenOwner) external returns (uint balance);
}

interface SushiSwap {
  function swapExactTokensForETH(uint256 amountIn,
    uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
    external returns (uint[] memory amounts);
}

interface ERC721 {
  function approve(address to, uint256 tokenId) external;
}

contract NFTX3 {
  address payable private owner;

  constructor() {
    owner = payable(msg.sender);
  }

  // allow getting money
  fallback() external payable {}
  receive() external payable {}

  // function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
  function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4) { return NFTX3.onERC721Received.selector; }

  function withdraw() external {
    require(msg.sender == owner);
    owner.transfer(address(this).balance);
  }

  function money(address payable rarible_to, bytes calldata rarible_data, uint256 rarible_value,
                 NFTXMinter token, ERC721 nft, uint256 tokenId,
                 SushiSwap sushi, uint256 min_profit) external {
    uint256 startingBalance = address(this).balance;

    // buy the NFT on rarible
    {
      (bool success, ) = rarible_to.call{value:rarible_value}(rarible_data);
      require(success, "buy failed");
    }

    // mint the NFT into a token
    nft.approve(address(token), tokenId);
    {
      uint256[] memory tokenIds = new uint256[](1);
      uint256[] memory amounts = new uint256[](1);
      tokenIds[0] = tokenId;
      amounts[0] = 1;
      token.mint(tokenIds, amounts);
    }

    // approve the spend for the sushi router
    uint256 tokenAmount = token.balanceOf(address(this));
    token.approve(address(sushi), tokenAmount);

    // sell the token on SushiSwap
    {
      address[] memory path = new address[](2);
      path[0] = address(token);
      path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);  // WETH
      sushi.swapExactTokensForETH(tokenAmount, 0, path, address(this), block.timestamp + 15);
    }

    // revert if we didn't make enough money
    require(address(this).balance > startingBalance, "not make ANY MONEY :(");
    require(address(this).balance > (startingBalance + min_profit), "not make enough money");
  }
}