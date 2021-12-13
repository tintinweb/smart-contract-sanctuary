/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
 

contract WWW   {
     
 
    mapping(address => bool) public winnerList;
    mapping(address => uint256) public winnerListClaimed;


    function addWinnerList(address[] calldata addresses, uint256[] calldata mintcount) external   {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "You can't add the null address");

            winnerList[addresses[i]] = true;
            // winnerListClaimed[addresses[i]] = mintcount[i];
            /**
            * @dev We don't want to reset _winnerListClaimed count
            * if we try to add someone more than once.
            */
            //   winnerListClaimed[addresses[i]] > 0 ? winnerListClaimed[addresses[i]] : 0;
        }
    }

  function winnerListClaimedBy(address winner)  view public returns (uint256){
    require(winner != address(0), 'Zero address not on Allow List');

    return winnerListClaimed[winner];
  }

// 구매 가능한 address 면 true
  function onWinnerList(address winner)  view public returns (bool) {
    return winnerList[winner];
  }

  function removeWinnerList(address[] calldata addresses) public {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "You can't add the null address");
        winnerList[addresses[i]] = false;
        winnerListClaimed[addresses[i]] = 0;
    }
  }
 
}