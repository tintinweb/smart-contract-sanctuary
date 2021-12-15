/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function walletOfOwner(address _owner) external view returns(uint256[] memory);
}

interface IRoot {
    function balanceOf(address owner) external view returns (uint256 balance);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function checkDailyReward(uint tokenID) external view returns (uint256);
}


contract BearXproxy  {
    INFT public NFTContract;
    IRoot public TokenContract;
    address public Owner;
    constructor()  {
        Owner =  msg.sender;
    }    
    
    function setBearXToken(address _contarct) public {
        require(Owner == msg.sender, "Only Onwer");
        require(_contarct != address(0), "Invalid address");
        NFTContract = INFT(_contarct);
    }

    function NFTBalance(address __address) public view returns(uint256) {
        return NFTContract.balanceOf(__address);
    }

    function NFTOwner(uint256 __id) public view returns(address) {
        if(__id < 10000000000000){
            return NFTContract.ownerOf(__id);
        } else {
            return address(0);
        }
    }

    function NFTWallet(address __address) public view returns(uint256[] memory) {
        return NFTContract.walletOfOwner(__address);
    }


    // ---------------------------------------------------------------------


    function setRootToken (IRoot _TokenContract) public {
        require(Owner == msg.sender, "Only Onwer");
        TokenContract = _TokenContract;
    }
    
    function getRootToken(address __address) public view returns(uint256) {
        require(__address != address(0), "Contract address can't be zero address");
        return TokenContract.balanceOf(__address);
    }
    
    function getRootAllowance(address __address) public view returns(uint256) {
        require(__address != address(0), "Contract address can't be zero address");
        return TokenContract.allowance(__address, address(this));
    }

    function CDR(uint256 tokenID) public view returns(uint256) {
        require(tokenID < 1000000000100, "Invalid ID");
        return TokenContract.checkDailyReward(tokenID);
    }


    // ---------------------------------------------------------------------


    function ownerOf(uint tokenID) public view returns(address){
        return NFTOwner(tokenID);
    }
}