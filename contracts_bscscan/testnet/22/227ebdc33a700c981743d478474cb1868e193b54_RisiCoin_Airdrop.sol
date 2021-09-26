/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: Unlicensed


/*

SET OWNER!
SET WALLETS!
ADD TRUSTED WALLET!
REMOVE TRUSTED WALLET!


    This contract distributes BNB to the winners of the RISICOIN Lottery! 
    For more details visit our website at https://www.risicoin-token.com/ 

    How to use

    1. The main contract will send all of the winning lottery bnb here
    2. Collect the winning wallets and enter them into the form
    3. Set the prize splits as a percent of the total prize fund (default is 10% each)
    4. Click "Send BNB to Winners!"

*/


pragma solidity ^0.8.7;


contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;
    mapping (address => bool) public _isTrusted;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;
        _isTrusted[owner()] = true;
        emit OwnershipTransferred(address(0), _owner);


    }

    function owner() public view virtual returns (address) {
        return _owner;
    }


    
}

contract RisiCoin_Airdrop is Ownable {

     

     
     address payable public Wallet_01;
     address payable public Wallet_02;
     address payable public Wallet_03;
     address payable public Wallet_04;
     address payable public Wallet_05;
     address payable public Wallet_06;
     address payable public Wallet_07;
     address payable public Wallet_08;
     address payable public Wallet_09;
     address payable public Wallet_10;

     uint256 public prize_01;
     uint256 public prize_02;
     uint256 public prize_03;
     uint256 public prize_04;
     uint256 public prize_05;
     uint256 public prize_06;
     uint256 public prize_07;
     uint256 public prize_08;
     uint256 public prize_09;
     uint256 public prize_10;

    // Restrict function to contract owner only 

    


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Only owner!");
        _;
    }


    modifier onlyTrusted() {

        require(_isTrusted[_msgSender()], "Only trusted!");
        _;
    }


    
    receive() external payable {}
    
    function Send_BNB_To_Winners() public onlyTrusted {

        uint256 contractBNB = address(this).balance;
        if (contractBNB > 0) {
        pay_BNB(Wallet_01, contractBNB*prize_01/100);
        pay_BNB(Wallet_02, contractBNB*prize_02/100);
        pay_BNB(Wallet_03, contractBNB*prize_03/100);
        pay_BNB(Wallet_04, contractBNB*prize_04/100);
        pay_BNB(Wallet_05, contractBNB*prize_05/100);
        pay_BNB(Wallet_06, contractBNB*prize_06/100);
        pay_BNB(Wallet_07, contractBNB*prize_07/100);
        pay_BNB(Wallet_08, contractBNB*prize_08/100);
        pay_BNB(Wallet_09, contractBNB*prize_09/100);
        pay_BNB(Wallet_10, contractBNB*prize_10/100);

        }
    }



    
    function pay_BNB(address payable sendTo, uint256 amount) private {
            sendTo.transfer(amount);
        }


    /*

    CHANGE WALLETS

    */

    function Set_Winning_Wallets(address payable _Wallet_01, 
                                 address payable _Wallet_02, 
                                 address payable _Wallet_03, 
                                 address payable _Wallet_04, 
                                 address payable _Wallet_05, 
                                 address payable _Wallet_06, 
                                 address payable _Wallet_07, 
                                 address payable _Wallet_08, 
                                 address payable _Wallet_09, 
                                 address payable _Wallet_10
        ) public onlyTrusted {

                         Wallet_01 = _Wallet_01; 
                         Wallet_02 = _Wallet_02; 
                         Wallet_03 = _Wallet_03; 
                         Wallet_04 = _Wallet_04; 
                         Wallet_05 = _Wallet_05; 
                         Wallet_06 = _Wallet_06; 
                         Wallet_07 = _Wallet_07; 
                         Wallet_08 = _Wallet_08; 
                         Wallet_09 = _Wallet_09; 
                         Wallet_10 = _Wallet_10;
    }


    function Set_Prize_Split(uint256 _prize_01,
                             uint256 _prize_02,
                             uint256 _prize_03,
                             uint256 _prize_04,
                             uint256 _prize_05,
                             uint256 _prize_06,
                             uint256 _prize_07,
                             uint256 _prize_08,
                             uint256 _prize_09,
                             uint256 _prize_10
        ) public onlyTrusted {

                             prize_01 = _prize_01;
                             prize_02 = _prize_02;
                             prize_03 = _prize_03;
                             prize_04 = _prize_04;
                             prize_05 = _prize_05;
                             prize_06 = _prize_06;
                             prize_07 = _prize_07;
                             prize_08 = _prize_08;
                             prize_09 = _prize_09;
                             prize_10 = _prize_10;



    }

    // Add Trusted Member 
    function Trusted_ADD(address account) external onlyOwner {
        _isTrusted[account] = true;
    }

    // Remove Trusted Member 
    function Trusted_REMOVE(address account) external onlyOwner {
        _isTrusted[account] = false;
    }
    

        
}

/*

Contract by GEN https://gentokens.com/

*/