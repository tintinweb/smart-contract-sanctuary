/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;



interface IERC20{
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}


contract metaGoldDistContract{


    
    address public admin;

    IERC20 metaGoldInstance;


    constructor(address _admin){
        admin = _admin;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "only admin please");
        _;
    }

    function distributeMetaGold(address[] memory tokenHolders) public onlyAdmin {

        // calculate amount per address
        uint256 amountPerAddress = metaGoldInstance.balanceOf(address(this))/(tokenHolders.length);


        for(uint256 i = 0; i < tokenHolders.length; i++){
            require(metaGoldInstance.balanceOf(tokenHolders[i]) > 0, "this address is not a token holder");
            metaGoldInstance.transfer(tokenHolders[i], amountPerAddress);
        }
    }

    function setTokenInstance(address _tokenAddress) public onlyAdmin {
        metaGoldInstance = IERC20(_tokenAddress);
    }

    function metaGoldBalance() public view returns(uint256){
        return metaGoldInstance.balanceOf(address(this));
    }

    function setAdmin(address _admin) public onlyAdmin{
        admin = _admin;
    }


}