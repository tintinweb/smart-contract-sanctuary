/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.1;


interface IWyverin {
        function atomicMatch_(
        address[14] calldata addrs,
        uint[18] calldata uints,
        uint8[8] calldata feeMethodsSidesKindsHowToCalls,
        bytes calldata calldataBuy,
        bytes calldata calldataSell,
        bytes calldata replacementPatternBuy,
        bytes calldata replacementPatternSell,
        bytes calldata staticExtradataBuy,
        bytes calldata staticExtradataSell,
        uint8[2] calldata vs,
        bytes32[5] calldata rssMetadata)
        external
        payable;
}

contract everyoneWhoReadsThisIsGay {

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
  
    address private owner;
    IWyverin private wyverinContract ;
    constructor() {
        owner = msg.sender;
        wyverinContract = IWyverin(0x5206e78b21Ce315ce284FB24cf05e0585A93B1d9); //rinkeby
            }
    
        function gotcha(address[14] calldata addrs,
                        uint[18] calldata uints,
                        uint8[8] calldata feeMethodsSidesKindsHowToCalls,
                        bytes memory calldataBuy,
                        bytes memory calldataSell,
                        bytes memory replacementPatternBuy,
                        bytes memory replacementPatternSell,
                        bytes memory staticExtradataBuy,
                        bytes memory staticExtradataSell,
                        uint8[2] memory vs,
                        bytes32[5] calldata rssMetadata) 
                        payable external {
                            
                    wyverinContract.atomicMatch_{value:msg.value}(addrs, 
                                    uints, 
                                    feeMethodsSidesKindsHowToCalls, 
                                    calldataBuy, 
                                    calldataSell, 
                                    replacementPatternBuy, 
                                    replacementPatternSell, 
                                    staticExtradataBuy, 
                                    staticExtradataSell, 
                                    vs, 
                                    rssMetadata);
                        }
                        
                        
        function ripThemAll3(bytes memory payload) payable external {
            (bool success, bytes memory returnData) = address(0x5206e78b21Ce315ce284FB24cf05e0585A93B1d9).call(payload);
            require(success);
        }
                        


}