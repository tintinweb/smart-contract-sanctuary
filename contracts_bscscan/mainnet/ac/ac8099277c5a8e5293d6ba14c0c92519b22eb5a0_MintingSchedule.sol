/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

//
// _____/\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\____________/\\\\__/\\\\\\\\\\\\\\\____/\\\\\\\\\________________________________/\\\\\\\\\_____        
//  ___/\\\//////////____/\\\\\\\\\\\\\__\/\\\\\\________/\\\\\\_\/\\\///////////___/\\\///////\\\____________________________/\\\///////\\\___       
//   __/\\\______________/\\\/////////\\\_\/\\\//\\\____/\\\//\\\_\/\\\_____________\/\\\_____\/\\\___________________________\///______\//\\\__      
//    _\/\\\____/\\\\\\\_\/\\\_______\/\\\_\/\\\\///\\\/\\\/_\/\\\_\/\\\\\\\\\\\_____\/\\\\\\\\\\\/_______________/\\\____/\\\___________/\\\/___     
//     _\/\\\___\/////\\\_\/\\\\\\\\\\\\\\\_\/\\\__\///\\\/___\/\\\_\/\\\///////______\/\\\//////\\\______________\//\\\__/\\\_________/\\\//_____    
//      _\/\\\_______\/\\\_\/\\\/////////\\\_\/\\\____\///_____\/\\\_\/\\\_____________\/\\\____\//\\\______________\//\\\/\\\_______/\\\//________   
//       _\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\_____________\/\\\_\/\\\_____________\/\\\_____\//\\\______________\//\\\\\______/\\\/___________  
//        _\//\\\\\\\\\\\\/__\/\\\_______\/\\\_\/\\\_____________\/\\\_\/\\\\\\\\\\\\\\\_\/\\\______\//\\\______________\//\\\______/\\\\\\\\\\\\\\\_ 
//         __\////////////____\///________\///__\///______________\///__\///////////////__\///________\///________________\///______\///////////////__
//

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
contract MintingSchedule {

  address public GMRV2TokenContract;

  // seconds in 365 days
  uint256 constant private ONE_YEAR = 31536000;

  // This is the unixtimestamp for may 4th 2022 0:0::0
  uint256 constant public START_SCHEDULE = 1651640400;

  // This is the unixtimestamp for january 1st 2022 0:0::0
  uint256 constant public START_YEAR = 1641016800;

  // Array having the max amount of tokens to mint for each year
  uint256[5] public maxMintOfYears;

  // Used to know if one year has passed since last minting
  uint256 public latestMinting;

// Deploy gmrV2Contract is needed first
  constructor(address addressToken) {
    GMRV2TokenContract = addressToken;
    maxMintOfYears[0] = 225000000 ether; // Max Mintable 2022
    maxMintOfYears[1] = 175000000 ether; // Max Mintable 2023
    maxMintOfYears[2] = 125000000 ether; // Max Mintable 2024
    maxMintOfYears[3] = 75000000 ether;  // Max Mintable 2025
    maxMintOfYears[4] = 50000000 ether;  // Max Mintable 2026 -->
  }

  // amount needs to be passed with the 18 decimals
  function ableToMint(uint256 amount) external returns(bool) {
    require(msg.sender == GMRV2TokenContract, 'ableToMint::Only GMRV2TokenContract can call this function');
    require(START_SCHEDULE < block.timestamp, "ableToMint::minting not allowed yet");

    uint256 year = getYear();
    if(year < 4){
      uint256 tokensLeft = maxMintOfYears[year];
      require(amount <= tokensLeft, "ableToMint::the amount requested is greater than the remaining balance for this year");
      maxMintOfYears[year] -= amount;
      return true;
    }
    else{
      require(latestMinting + ONE_YEAR <= block.timestamp, "ableToMint::minting not allowed yet");
      require(amount <= maxMintOfYears[4], "ableToMint::You can mint up to 50M tokens once a year");
      latestMinting = block.timestamp;
      return true;
    }
  }

  // Internal function to know how many years have passed
  function getYear() internal view returns(uint256) {
    uint256 numerator = block.timestamp - START_YEAR;
    uint256 denominator = ONE_YEAR;
    return(numerator/denominator);
  }
}