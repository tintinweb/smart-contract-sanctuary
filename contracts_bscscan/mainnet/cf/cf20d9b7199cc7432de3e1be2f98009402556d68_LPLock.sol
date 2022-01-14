/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: Unlicenced

////////////////////////////////////////////////////////////////////////////////////////////////
//   Multi-chain Liquidity Token Locker
//   --------------------------------------------------------------
//   This smart contract works for LP liquidity tokens on the Uniswap DEX, or any other forks
//   such as PancakeSwap/Sushiswap/Etc.
//
//    
//   Liquidity Pool Tokens that will go to the addresses defined herewith will be 
//   time-locked, whereby the LP tokens cannot be withdrawn until the specifed date is reached.
////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.11;

contract LPToken {
    function thisContractAddress() public pure returns (address) {}
    function balanceOf(address) public pure returns (uint256) {}
    function transfer(address, uint) public {}
}

contract LPLock {

    LPToken public token;

    //////////////////////////////////////////////////////////////////////////////////
    ////////   contract address of the LP Token you wish to "lock"   /////////////////
    
    address public tokenContractAddress = 0x88710c9173bACf1B20EBEcFC3A635E3916cE482a;
    
    //////////////////////////////////////////////////////////////////////////////////

    address public thisContractAddress;
    address public admin;
    bool public mutex;
    

    // withdrawals can only be made after the time expressed as Unix epoch time
    // https://www.epochconverter.com/
    // Epoch value should be hardcoded to avoid any doubt
    
      uint256 public unlockDate1 = 1642180000;
//    uint256 public unlockDate2 = ;
//    uint256 public unlockDate3 = ;
//    uint256 public unlockDate4 = ;


    // wallet addresses of project team members entitlted to claim
    
      address public teamMemberWallet1 = 0xcd8827E6977d9c25CDcAF224f45d0e3D5Ea473b7;  
//    address public teamMemberWallet2 = ;  
//    address public teamMemberWallet3 = ;   
//    address public teamMemberWallet4 = ;  
//    address public teamMemberWallet5 = ;  


    // actual LP amounts to be withdrawn expressed as percentage of total LP tokens
    
      uint256 public teamMember1Percentage = 100;
//    uint256 public teamMember2Percentage = ;
//    uint256 public teamMember3Percentage = ;
//    uint256 public teamMember4Percentage = ;
//    uint256 public teamMember5Percentage = ;


    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier onlyTeam {
        require(
        msg.sender == admin 
          || msg.sender == teamMemberWallet1
//        || msg.sender == teamMemberWallet2
//        || msg.sender == teamMemberWallet3
//        || msg.sender == teamMemberWallet4
//        || msg.sender == teamMemberWallet5
        );
        _;
    }

    constructor() {
        admin = msg.sender;
        thisContractAddress = address(this);
        token = LPToken(tokenContractAddress);
        thisContractAddress = address(uint160(address(this)));
    }


    // fallback
    fallback() external payable {}
    receive() external payable {}

    // check the current time, expressed as Epoch time
    // https://www.epochconverter.com/
    
    function currentEpochtime() public view returns(uint256) {
        return block.timestamp;
    }

    // check the Native coin balance (ETH/BNB/XDAI/Etc.) stored in THIS contract 
    
    function thisContractBalanceNativeCoin() public view returns(uint) {
        return address(this).balance;
    }
    
    // check the LP token balance, stored in THIS contract  
    
    function thisContractBalanceLPToken() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    // public function to withdraw LP tokens from the contract
    // anyone from the team can call after epoch date has passed.
    // This function can be replicated if necessary
    // but remember to chancge reference to withdrawLP1 and payoutLP1 in each subsequent
    // function replication

    function withdrawLP1() public onlyTeam {
                    payoutLP1();
    }

    // function called by withdrawLP that pays out the LP tokens
    // entire function can be duplicated for multiple payout dates
    // but remember to chancge reference to payoutLP1 and unlockDate1 in each subsequent
    // function replication

    function payoutLP1() internal {
        require(mutex == false);
        require(block.timestamp >= unlockDate1); // first unlock date
        require (admin == msg.sender);
        require (token.balanceOf(address(this)) > 0);
        mutex = true;
        uint256 LPTotal;
        LPTotal = token.balanceOf(address(this)); 
        token.transfer(teamMemberWallet1, (LPTotal/100)*teamMember1Percentage); // team member 1
//      token.transfer(teamMemberWallet2, (LPTotal/100)*teamMember2Percentage); // team member 2
//      token.transfer(teamMemberWallet3, (LPTotal/100)*teamMember3Percentage); // team member 3
//      token.transfer(teamMemberWallet4, (LPTotal/100)*teamMember4Percentage); // team member 4
//      token.transfer(teamMemberWallet5, (LPTotal/100)*teamMember5Percentage); // team member 5
        mutex = false;
    }

    // admin can also withdraw any amount of native coin 
    // sometimes sent accidentally to the smart contract
    
    function devWithdrawNativeCoin() onlyAdmin public {
        require (admin == msg.sender);
        require(mutex == false);
        require((address(this).balance) > 0);
        mutex = true;
        payable(msg.sender).transfer(address(this).balance);
        mutex = false;
    }

}