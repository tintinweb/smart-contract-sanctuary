/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;
/*

    SPDX-License-Identifier: Apache-2.0

*/


import {InitializableERC20} from "../InitializableERC20.sol";
import {InitializableMintableERC20} from "../InitializableMintableERC20.sol";
import {InitializableBurnableERC20} from "../InitializableBurnableERC20.sol";
import {InitializableMintableBurnableERC20} from "../InitializableMintableBurnableERC20.sol";



interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}


contract MoneyPrintingMachine {
    
    struct money{
        address moneyAddress;
    }
    
    constructor() public { 
        owner = payable(msg.sender); 
        fee = 10000000000000000 wei;
    }
    address payable owner;
    uint256 fee;
    mapping(address => money[]) userList;
    
    function withdraw() public {
        owner.transfer(address(this).balance);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    } 
    
    function getFee() public view returns (uint256){
        return fee;
    }

    function getUserList(address _userAddress) view public returns (money[] memory moneyList){
        return userList[_userAddress];
    }
    
    function changeFee(uint256 newFee) public {
        require(msg.sender == owner);
        fee = newFee;
    }
    
    function addMoneyToUser(address _userAddress, address _moneyAddress) public {
        money memory newMoney= money(_moneyAddress); 
        userList[_userAddress].push(newMoney);
    }

    
    function printMoney(
         address _creator,
         uint256 _totalSupply,
         string memory _name,
         string memory _symbol,
         uint256 _decimals,
         uint256 _tokenType
        ) external payable returns (address proxy) {
        require(msg.value > fee);
        owner.transfer(fee);
        //standard 0x3e2cb3603c1c946B8fCB144FE10a52264A58c4C4
        //bm 0x4cC3bf54Ba05E58bEe2656e34FBeb39d2dA119cB
        //mint 0x855EEdD600CCf8f0A06401e691c0b614567b014B
        //burn 0xd501d8C719F8a1d051fEF444102268656115697a
        ICloneFactory factory = ICloneFactory(0x167eF99EB4c677405F1A4142858aCCb7c525eF8F);
        address result;
        if(_tokenType == 0){
            result = factory.clone(address(0x3e2cb3603c1c946B8fCB144FE10a52264A58c4C4));
            InitializableERC20 coin = InitializableERC20(result);
            coin.init(_creator,_totalSupply,_name,_symbol,_decimals);
            addMoneyToUser(msg.sender,result);
        }else if (_tokenType == 1) {
            result = factory.clone(address(0xE9CBf580bBf2b3559cc4bB2E46bf17582a9c6CE3));
            InitializableMintableBurnableERC20 coin = InitializableMintableBurnableERC20(result);
            coin.init(_creator,_totalSupply,_name,_symbol,_decimals);
            addMoneyToUser(msg.sender,result);
        }else if (_tokenType == 2) {
            result = factory.clone(address(0x855EEdD600CCf8f0A06401e691c0b614567b014B));
            InitializableMintableERC20 coin = InitializableMintableERC20(result);
            coin.init(_creator,_totalSupply,_name,_symbol,_decimals);
            addMoneyToUser(msg.sender,result);
        }else if (_tokenType == 3) {
            result = factory.clone(address(0xd501d8C719F8a1d051fEF444102268656115697a));
            InitializableBurnableERC20 coin = InitializableBurnableERC20(result);
            coin.init(_creator,_totalSupply,_name,_symbol,_decimals);
            addMoneyToUser(msg.sender,result);
        }
        

        return result;
    }
}