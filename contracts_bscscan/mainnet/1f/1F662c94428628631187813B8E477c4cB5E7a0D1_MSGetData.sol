// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMSSpaceToken.sol";
import "./IMSNft.sol";


contract MSGetData  {
    IMSSpaceToken private msSpaceToken;
    IMSNft private msGemoNft;

    constructor( 
        address _IMSSpaceToken,
        address _IMSGemoNft
        ) {
        msSpaceToken    = IMSSpaceToken(_IMSSpaceToken);
        msGemoNft       = IMSNft(_IMSGemoNft);
    }
//NFT_DATA//////////////////////////////////////////////////////////////////////////////////////
    function GetNftBalanceOf(address _Owner) view external returns(uint256)  {
        return msGemoNft.msGetBalanceOf(_Owner);
    }

    function GetNftBalanceOfArray(address[] memory _OwnerAry) view external returns(uint256[] memory){
        uint256[] memory balanceOfArray = new uint256[](_OwnerAry.length);
        for(uint256 i = 0; i < _OwnerAry.length; i++)
        {
            balanceOfArray[i] = this.GetNftBalanceOf(_OwnerAry[i]);
        }
        return balanceOfArray;
    }

    function GetNftOwner(uint256 _nftID) view external returns(address)  {
        return msGemoNft.msIsExists(_nftID)? msGemoNft.msGetOwner(_nftID) : address(0);
    }

    function GetNftOwnerArray(uint256 beginId, uint256 endId) view external returns(address[] memory)  {
        address[] memory  addAry = new address[](endId - beginId+1);
        for (uint256 i = beginId; i <= endId; i++)
        {
            addAry[i-beginId] = this.GetNftOwner(i);
        }
        return addAry;
    }

    function GetNftOwnerArray(uint256[] memory NftIDArray) view external returns(address[] memory)  {
        address[] memory  addAry = new address[](NftIDArray.length);
        for (uint256 i = 0; i <= NftIDArray.length; i++)
        {
            addAry[i] = this.GetNftOwner(NftIDArray[i]);
        }
        return addAry;
    }
//SPACETOKEN_DATA//////////////////////////////////////////////////////////////////////////////////////
    function GetMSSpaceTokenBalanceOf(address _Owner) view  external returns(uint256)  {
        return msSpaceToken.msGetBalanceOf(_Owner);
    }

    function GetMSSpaceTokenBalanceArray(address[] memory _OwnerAry)view external returns(uint256[] memory)
    {
        uint256[] memory  addAry = new uint256[](_OwnerAry.length);
        for (uint256 i = 0; i <= _OwnerAry.length; i++)
        {
            addAry[i] = this.GetMSSpaceTokenBalanceOf(_OwnerAry[i]);
        }
        return addAry;        
    }

//SPACETOKEN_NFT_DATA//////////////////////////////////////////////////////////////////////////////////////
    function GetAllTypeBalanceOfArray(address[] memory _OwnerAry) external view returns(uint256[] memory,uint256[] memory){
        uint256[] memory  tokenBalaceAry = new uint256[](_OwnerAry.length);
        uint256[] memory  gemoBalanceAry = new uint256[](_OwnerAry.length);
        for(uint256 i = 0; i < _OwnerAry.length; i++)
        {
            tokenBalaceAry[i] = this.GetMSSpaceTokenBalanceOf(_OwnerAry[i]);
            gemoBalanceAry[i] = this.GetNftBalanceOf(_OwnerAry[i]);
        }

        return (tokenBalaceAry, gemoBalanceAry);
    } 
}