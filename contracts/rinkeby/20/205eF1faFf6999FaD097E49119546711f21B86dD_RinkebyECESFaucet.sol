/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * 
 * @title Rinkeby Faucet EscuelaCryptoES
 * 
 * @author @EscuelaCryptoES & @Ivanovish10
 * 
 * @dev This is the official EscuelaCryptoES Rinkeby Faucet
 * to all the members
 * 
 */
contract RinkebyECESFaucet is Ownable {
    
    /**
     * @dev cooldownTime put to 1 days. One user cannot take more than 1 ETH daily
     */
    uint private cooldownTime = 1 days;
    
    /**
     * 
     * @dev Struct to store all the user info
     * 
     */
    struct User{
        string telegram_User;
        bool stored;
        uint64 readyTime;
    }
    
    /**
     * 
     * @dev Mapping to store all the users
     * 
     */
    mapping (address => User) users;
    
    /**
     * 
     * @dev Updates cooldownTime state variable ;; for 1 day 86400
     * 
     * @param _days is the new time to set cooldownTime
     * 
     */
    function setCooldownTime(uint _days) public onlyOwner {
        cooldownTime = _days;
    }
    
    /**
     * 
     * @dev Returns the actual cooldownTime
     * 
     * @return the cooldownTime in uint256
     * 
     */
    function getCooldownTime() external view onlyOwner returns(uint) {
        return cooldownTime;
    }

    /**
     * 
     * @notice Store in users mapping the users and their Ethereum addresses
     * 
     * @param _user is the Telegram user name
     * 
     */
    function refundUser(string memory _user) external payable {
        User storage u = users[msg.sender];
        
        if(!u.stored){
            // Not stored yet
            u.telegram_User = _user;
            u.stored = true;
        }
        _transferUser(u);
    }

    function _transferUser(User memory _user) public payable{
        require(_ethDeployed1Day());
        // Refund
        address payable chosenOne = payable(msg.sender); 
        chosenOne.transfer(1 ether);
        _user.readyTime = uint64(block.timestamp + cooldownTime);
    }
    
    /**
     * 
     * @notice This function lets you know if you are ready to 
     * receive 1 ether more
     * 
     * @dev Check if it works
     * 
     */
    function _ethDeployed1Day() internal view returns (bool) {
        User storage u = users[msg.sender];
        return u.readyTime <= block.timestamp;
    }
    
    /**
     * 
     * @notice This function returns your info stored
     * 
     * @return User info in tuple format
     * 
     */
    function seeMyInfo() external view returns(User memory){
        User storage u = users[msg.sender];
        return u;
    }
    
    /** 
     * 
     * @notice Returns the Smart Contract balance
     * 
     * @return Smart Contract balance in uint256
     * 
     */
    function getSmartContractBalance() public view onlyOwner returns(uint) {
        return address(this).balance;
    }
    
    /**
     * 
     * @notice Smart Contract feeding function
     * 
     */
    receive() external payable {}
    
}