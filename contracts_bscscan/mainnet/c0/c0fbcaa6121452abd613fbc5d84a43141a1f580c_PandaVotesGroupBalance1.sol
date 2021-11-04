/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function unlockedSupply() external view returns (uint256);
    function totalLock() external view returns (uint256);
    function lockOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract PandaVotesGroupBalance1 {

  function name() public pure returns(string memory) { return "PandaVotesGroupBalance1"; }
  function symbol() public pure returns(string memory) { return "PandaVotesGroupBalance1"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
    IERC20 lp1 = IERC20(0xbc4E371b84cA1190854B2C68F727862aDe4F9338);
    IERC20 lp2 = IERC20(0x571af1B56Cc219eed9eeA33445AEe452AbACA11e);
    IERC20 lp3 = IERC20(0x44Bf868030b8D0B6Cdb8c405eFF1b8567159aEB0);
    IERC20 lp4 = IERC20(0x4995FC38477A7E7bdD35881ED5973862aedE2a6b);
    IERC20 lp5 = IERC20(0x913a9a4b544C61Eb006FA44B447098543454dF3b);
    uint256 lp1_balance = lp1.totalSupply();
    uint256 lp2_balance = lp2.totalSupply();
    uint256 lp3_balance = lp3.totalSupply();
    uint256 lp4_balance = lp4.totalSupply();
    uint256 lp5_balance = lp5.totalSupply();

    return (lp1_balance*(1000000000))+(lp2_balance*(1000000000))+lp3_balance+lp4_balance+lp5_balance;
  }
  
  function balanceOf(address owner) public view returns (uint256) {
    IERC20 lp1 = IERC20(0xbc4E371b84cA1190854B2C68F727862aDe4F9338);
    IERC20 lp2 = IERC20(0x571af1B56Cc219eed9eeA33445AEe452AbACA11e);
    IERC20 lp3 = IERC20(0x44Bf868030b8D0B6Cdb8c405eFF1b8567159aEB0);
    IERC20 lp4 = IERC20(0x4995FC38477A7E7bdD35881ED5973862aedE2a6b);
    IERC20 lp5 = IERC20(0x913a9a4b544C61Eb006FA44B447098543454dF3b);

    // Add balances 
    uint256 lp1_balance = lp1.balanceOf(owner);
    uint256 lp2_balance = lp2.balanceOf(owner);
    uint256 lp3_balance = lp3.balanceOf(owner);
    uint256 lp4_balance = lp4.balanceOf(owner);
    uint256 lp5_balance = lp5.balanceOf(owner);

    // Add total voting balance
    uint256 lp_powah = (lp1_balance*(1000000000))+(lp2_balance*(1000000000))+lp3_balance+lp4_balance+lp5_balance;
    
    return lp_powah;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}