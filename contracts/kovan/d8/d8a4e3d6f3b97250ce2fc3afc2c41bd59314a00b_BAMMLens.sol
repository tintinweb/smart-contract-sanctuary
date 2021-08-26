/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity 0.8.0;

interface SPLike {
    function getCompoundedLUSDDeposit(address a) external view returns(uint);
    function getDepositorETHGain(address a) external view returns(uint);
}

interface BAMMLike {
    function balanceOf(address a) external view returns(uint);
    function totalSupply() external view returns(uint);
}

contract BAMMLens {
    SPLike constant SP = SPLike(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);
    
    function getUserDeposit(address user, BAMMLike bamm) external view returns(uint lusd, uint eth) {
        uint lusdValue = SP.getCompoundedLUSDDeposit(address(bamm));
        uint ethValue = SP.getDepositorETHGain(address(bamm)) + (address(bamm).balance);

        uint numShares = bamm.balanceOf(user);
        uint total = bamm.totalSupply();

        lusd = lusdValue * numShares / total;
        eth = ethValue * numShares / total;        
    }
}