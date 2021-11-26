// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import './IBEP20.sol';
import './SafeERC20.sol';
import './Ownable.sol';

/**
 * Revert code and message pairs:
 * `Err01` No balance
 * `Err02` No internal balance
 * `Err03` Ivalid burn
 */
contract BEP20V1Migrator is Ownable {
  using SafeERC20 for IBEP20;

  enum state { CHECKED, FILLED }

  address bep20Addr;
  IBEP20 bep20;
  
  mapping (address => uint) private balance;
  mapping (address => state) private status;

  constructor(address smartContracAddress) {
    bep20Addr = smartContracAddress;
    bep20 = IBEP20(bep20Addr);
  }

  event OnMigrate (address userAddress, uint userBalance, state userStatus);

  // Method #1
  function migrateAndBurn() public {
    uint userBalance = bep20.balanceOf(msg.sender);
    
    require(userBalance > 0 && balance[msg.sender] == 0, 'Address has no tokens to migrate');

    balance[msg.sender] = userBalance;
    status[msg.sender] = state.CHECKED;
    
    // todo: delete
    bep20.safeTransferFrom(
      msg.sender,
      address(this),
      balance[msg.sender]
    );

    (bool ok, bytes memory data) = bep20Addr.delegatecall(
      abi.encodePacked(
        bytes4(
          keccak256("_burn(address, uint)")
        ),
        msg.sender, 
        userBalance
      )
    );

    // todo: uncomment
    // require(ok, 'Failed to burn tokens');

    status[msg.sender] = state.FILLED;

    emit OnMigrate(msg.sender, balance[msg.sender], status[msg.sender]);
  }

  // Method #2 (step 1)
  function migrate() public {
    uint userBalance = bep20.balanceOf(msg.sender);
    
    require(userBalance > 0 && balance[msg.sender] == 0, 'Address has no tokens to migrate');
    
    balance[msg.sender] = userBalance;
    status[msg.sender] = state.CHECKED;

    bep20.safeTransferFrom(
      msg.sender,
      address(this),
      balance[msg.sender]
    );

    status[msg.sender] = state.FILLED;

    emit OnMigrate(msg.sender, balance[msg.sender], status[msg.sender]);
  }

  // Method #2 (step 2)
  event OnWiped(address thisAddress, uint thisBalance);
  function wipeAllToken() onlyOwner public {
    uint thisBalance = bep20.balanceOf(address(this));

    require(thisBalance > 0 , 'Address has no tokens to migrate');

    (bool ok, bytes memory data) = bep20Addr.delegatecall(
      abi.encodePacked(
        bytes4(
          keccak256("_burn(address, uint)")
        ),
        address(this), 
        thisBalance
      )
    );

    // todo: uncomment
    // require(ok, 'Failed to burn tokens');

    emit OnWiped(address(this), bep20.balanceOf(address(this))); 
  }

  function getData(address user) external view returns (uint amount, state result) {
    return (balance[user], status[user]);
  }
}