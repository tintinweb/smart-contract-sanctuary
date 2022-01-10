/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface LandInterface{
    function assignNewParcel(int x, int y, address beneficiary) external;
    function encodeTokenId(int x, int y) external pure returns (uint256);
    function ownerOfLand(int x, int y) external view returns (address);
}

contract BatchMintLand{

    event AlreadyExistsLand(int x, int y, address user);

    receive() external payable{
        
    }
    
    fallback() external{
        
    }

    function mintLand(address land, int[] memory x, int[] memory y, address[] memory user) public{
        require(x.length == y.length, 'length false!');
        LandInterface landInterface = LandInterface(land);
        for(uint256 i=0; i<x.length; i++){
            if(landInterface.ownerOfLand(x[i], y[i]) == address(0)){
                emit AlreadyExistsLand(x[i], y[i], user[i]);
            }else{
                landInterface.assignNewParcel(x[i], y[i], user[i]);

                if(address(user[i]).balance < 0.03 ether){
                    payable(user[i]).transfer(0.03 ether);
                }
            }
        }
    }

    function withdraw(address to) public{
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0){
            payable(to).transfer(ethBalance);
        }
    }
}