/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity >=0.6.5 <=0.8.0;

interface GameItem {
    function balanceOf(address _address) external view  returns (uint256);
}

interface SGDToken {
    function transfer(address _to, uint256 _value) external;
    function checkAdmin(address msgUser) external view returns(bool);
    function balanceOf(address _address) external view  returns (uint256);

}

contract SGDTAirdrop {
    fallback() external payable{}

    SGDToken sgdToken = SGDToken(address(0x36E231fB0c7341Fe716296053bCDBf353a34Da18));
    GameItem nftToken = GameItem(address(0x44A3fcB1244dcEb2BE980820f0eE7f63E5009Fe5));

    function airDrop(address[] memory walletAddresses,uint256 amount) public { 
        sgdToken.checkAdmin(msg.sender);
        for (uint i=0; i < walletAddresses.length; i++) {
            require(nftToken.balanceOf(walletAddresses[i]) != 0, "address do not have nft");
            sgdToken.transfer(walletAddresses[i],amount);
        }
    }
    
    function getTokenBalance(address _address) public view returns(uint256){
        return sgdToken.balanceOf(_address);
    }
    
}