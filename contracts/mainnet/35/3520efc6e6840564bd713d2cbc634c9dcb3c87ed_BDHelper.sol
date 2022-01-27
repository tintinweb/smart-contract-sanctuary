/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface BDNFT {
	function ownerOf(uint256 tokenID) external view returns(address);
	function totalSupply() external view returns(uint256);
	function balanceOf(address owner) external view returns(uint256);
}

contract BDHelper {

	address BasementDwellersNFT = 0x9A95eCEe5161b888fFE9Abd3D920c5D38e8539dA;

	function getOwner(uint256 tokenID) internal view returns(address _owner){
		return(BDNFT(BasementDwellersNFT).ownerOf(tokenID));
	}


   function walletOfOwner(address wallet) public view returns(uint256[] memory walletNFTs){
        uint256 _idx = 0;
        uint256 _total = BDNFT(BasementDwellersNFT).totalSupply();
        uint256 _walletBalance = BDNFT(BasementDwellersNFT).balanceOf(wallet);
        if(_walletBalance > 0){
	        walletNFTs = new uint256[](_walletBalance);
	        for(uint256 i=0; i<_total; i++){
	            if(getOwner(i) == wallet){
	                walletNFTs[_idx] = i;
	                _idx += 1;
	            }
	        	if(_idx == _walletBalance){
	        		return walletNFTs;
	        	}
	        }
        }
    }

}