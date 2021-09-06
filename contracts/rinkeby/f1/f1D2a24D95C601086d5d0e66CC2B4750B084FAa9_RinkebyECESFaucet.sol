/**
 *Submitted for verification at Etherscan.io on 2021-09-05
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
 * to all the Telegram members
 * 
 */
contract RinkebyECESFaucet is Ownable {
    
    /**
     * @dev cooldownTime put to 1 days. One user cannot take more than 1 ETH daily
     */
    uint private cooldownTime = 1 days;
    
    /**
     * @dev reward in wei
     */
     uint private reward = 1000000000000000000;
    
    /**
     * 
     * @dev Struct to store all the user info
     * 
     */
    struct User{
        string telegram_User;
        address lastAddress;
        bool stored;
        uint64 readyTime;
    }
    
    /**
     * 
     * @dev Mapping to store all the users with their Telegram users
     * 
     */
    mapping (string => User) users;
    
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
     * @dev Updates reward state variable ;; 1000000000000000000 for 1 ether
     * 
     * @param _wei is the new reward
     * 
     */
    function setReward(uint _wei) public onlyOwner {
        reward = _wei;
    }
    
    /**
     * 
     * @dev Returns the actual reward value
     * 
     * @return the reward in uint256
     * 
     */
    function getReward() external view onlyOwner returns(uint) {
        return reward;
    }

    /**
     * 
     * @notice Function to pay a user with the set reward
     * 
     * @param _user is the Telegram user name
     * @param _to is the user's Ethereum address 
     * 
     */
    function payUser(string memory _user, address _to) external payable {
        User storage u = users[_user];
        
        if(!u.stored){
            // Not stored yet
            u.lastAddress = _to;
            u.telegram_User = _user;
            u.stored = true;
        }
        
        if(u.lastAddress != _to){
            u.lastAddress = _to;
        }
        
        require(_ethDeployed1Day(_user), "Solo puedes conseguir ETH cada 24 horas");
        
        // Pay
        address payable chosenOne = payable(_to); 
        chosenOne.transfer(reward);
        u.readyTime = uint64(block.timestamp + cooldownTime);
    }
    
    /**
     * 
     * @notice This function lets you know if you are ready to 
     * receive the set reward again
     * 
     */
    function _ethDeployed1Day(string memory _user) internal view returns (bool) {
        User storage u = users[_user];
        return u.readyTime <= block.timestamp;
    }
    
    /**
     * 
     * @notice This function returns your info stored
     * 
     * @dev Later, in frontend we transform the waiting time
     * into an understandable language.
     * 
     * @return User info in tuple format
     * 
     */
    function seeMyInfo(string memory _user) external view returns(User memory){
        User storage u = users[_user];
        return u;
    }
    
    /**
     * 
     * @notice Smart Contract feeding function
     * 
     */
    receive() external payable {}
    
}