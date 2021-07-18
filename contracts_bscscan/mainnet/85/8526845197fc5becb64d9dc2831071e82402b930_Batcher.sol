/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter = 1;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }
}

interface IERC20 {
    
    function transfer(address to, uint256 value) external returns (bool);

}

interface IBatcher {

    function revokeOwnership(address _newAdmin) external returns(bool);

    function batchTransfer(address[] memory addresses) external returns(bool);

    function withdrawTokens(uint256 amount) external returns(bool);

}

contract Batcher is ReentrancyGuard, IBatcher {

    /**
     * tokenContract reprensts the token to be transferred
     * this contract will be used for batching ERC-20 Transactions
     */

    address public tokenContract;

    /**
     * transferValue represents the amount of tokens to be transferred
     * this can be modified by the value modifier function.
     */

    uint256 public transferValue;

    /**
     * admin address will own the contract and can make transactions.
     * This prevents mis-use of the tokens deposited to the contract.
     */

    address public admin;
    
    /**
     * constructor accepts 2 arguments
     * _tokenContract - address of the token contract.

     */

    constructor() {
      admin = msg.sender;
    }

    /**
     * @dev checks the credibility of the function caller.
     * prevents bad actors from accessing the contract.
     */

    modifier onlyAdmin() {
        require(msg.sender == admin, "Access Error: Caller not admin");
        _;
    }

    /** 
     * @dev transfers the tokens to n wallets.
     * this will transfer the same amount of tokens.
     * to reduce the read from an array we send fixed amount.
     * Optimal for airdrops.
    */
    
    function batchTransfer(address[] memory addresses) public override onlyAdmin nonReentrant returns(bool) {
        for(uint256 i = 0; i < addresses.length; i++) {
            IERC20(tokenContract).transfer(addresses[i], transferValue);
        }
        return true;
    }

    /**
     * @dev will change the current admin of the contract.
     * It's an irreversible action. Excercise caution doing this.
     */

    function revokeOwnership(address _newAdmin) public override onlyAdmin nonReentrant returns(bool) {
        require(_newAdmin != address(0), "Error: Zero Address");
        admin = _newAdmin;
        return true;
    }

    /**
     * @dev withdraws the pending tokens from the contract.
     * No one likes to lock their tokens ! Haha
     */

    function withdrawTokens(uint256 amount) public override onlyAdmin nonReentrant returns(bool) {
        IERC20(tokenContract).transfer(admin, amount);
        return true;
    }


     function setTransferValue(uint256 _transferValue) public onlyAdmin nonReentrant returns(bool) {
        transferValue = _transferValue;
        return true;
    }
    
     function setTokenContract(address _tokenContract) public onlyAdmin nonReentrant returns(bool) {
        tokenContract =  _tokenContract;
        return true;
    }
    
}