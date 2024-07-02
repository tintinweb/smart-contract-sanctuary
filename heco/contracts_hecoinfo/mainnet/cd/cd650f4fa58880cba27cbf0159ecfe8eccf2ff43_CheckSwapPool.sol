/**
 *Submitted for verification at hecoinfo.com on 2022-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface IERC20 {
    // function balanceOf(address account) external view returns (uint256);
    // function transfer(address recipient, uint256 amount) external returns (bool);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC721Enumerable {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface s {
      struct claimiItem {
        uint256 tokenId;
        bool hasClaim;
    }
}

interface SwapPool is s {
   function swapToken() external view returns(IERC20);
   function swapPrice() external view returns(uint256);
   function SwapNFT() external view returns(IERC721Enumerable);
   function claimTimes() external view returns(uint256);
   function canClaimBlockNumList(uint256 _time) external view returns(uint256);
   function canClaimAmountList(uint256 _time) external view returns(uint256);
   function userClaimList(address _user,uint256 _tokenId,uint256 _time) external view returns(claimiItem memory);
   function userTokenIdList(address _user) external view returns(uint256[] memory);
}

contract CheckSwapPool is s {
    struct claimList {
        uint256 canClaimAmount;
        uint256 canClaimBlockNum;
        bool hasClaim;
        uint256 tokenId;
    }
    
    struct tokenInfo {
        address token;
        string name;
        string symbol;
        uint256 decimals;
    }
    
    
    function get(SwapPool _swap,address _user,uint256 _tokenId) external view returns (bool canSwap,bool hasSwap,claimList[] memory claimListAll,IERC721Enumerable SwapNFT,uint256 swapPrice,uint256 claimTimes,tokenInfo memory swapTokenInfo) {
        IERC20 swapToken = _swap.swapToken();
        swapTokenInfo.token = address(swapToken);
        swapTokenInfo.name = swapToken.name();
        swapTokenInfo.symbol = swapToken.symbol();
        swapTokenInfo.decimals = swapToken.decimals();
        SwapNFT = _swap.SwapNFT();
        swapPrice = _swap.swapPrice();
        if (SwapNFT.ownerOf(_tokenId) == _user) {
            canSwap = true;
        }
        hasSwap = (_swap.userClaimList(_user,_tokenId,0).tokenId == _tokenId)?true:false;
        claimTimes = _swap.claimTimes();
        claimListAll = new claimList[](claimTimes);
        for (uint256 i=0;i<claimTimes;i++) {
            claimListAll[i] = claimList({
                canClaimAmount:_swap.canClaimAmountList(i),
                canClaimBlockNum:_swap.canClaimBlockNumList(i),
                hasClaim:_swap.userClaimList(_user,_tokenId,i).hasClaim,
                tokenId:_swap.userClaimList(_user,_tokenId,i).tokenId
            });
        }
    }
}