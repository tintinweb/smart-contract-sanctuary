/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;

contract IMainToken{
    function transfer(address, uint256) public pure  returns (bool);
    function transferFrom(address, address, uint256) public pure  returns (bool);
 }
 
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Invalid values");
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Invalid values");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a,"Invalid values");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a,"Invalid values");
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,"Invalid values");
        return a % b;
    }
}

contract MultiPadLaunchApp {
    
    using SafeMath for uint256;
    
    IMainToken iMainToken;
    
    //variable declaration
    address private _owner = msg.sender;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    address private tokenContractAddress;
    


    function setTokenAddress(address _ITokenContract) onlyOwner external returns(bool){
        tokenContractAddress = _ITokenContract;
        iMainToken = IMainToken(_ITokenContract);
    }

    
    /*----------------------------------------------------------------------------
     * Functions for owner
     *----------------------------------------------------------------------------
    */

    /**
    * @dev get address of smart contract owner
    * @return address of owner
    */
    function getowner() external view returns (address) {
        return _owner;
    }

    /**
    * @dev modifier to check if the message sender is owner
    */
    modifier onlyOwner() {
        require(isOwner(),"You are not authenticate to make this transfer");
        _;
    }

    /**
     * @dev Internal function for modifier
     */
    function isOwner() internal view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfer ownership of the smart contract. For owner only
     * @return request status
      */
    function transferOwnership(address newOwner) external onlyOwner returns (bool){
        require(newOwner != address(0), "Owner address cant be zero");
        _owner = newOwner;
        return true;
    }
    
    
     /**
      * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
      * @param _addresses array of address in serial order
      * @param _amount amount in serial order with respect to address array
      */
      function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) public onlyOwner returns (bool){
          require(_addresses.length == _amount.length,"Invalid Array");
          uint256 count = _addresses.length;
          uint256 airdropcount = 0;
          for (uint256 i = 0; i < count; i++){
               iMainToken.transfer(_addresses[i],_amount[i]);
               airdropcount = airdropcount + 1;
          }
          return true;
      }
      
    function withdrawPeningTokens(uint256 _amount) external onlyOwner returns(bool){
       iMainToken.transfer(msg.sender, _amount);
       return true;
         
    }
    
    /*
     * @dev Admin can withdraw the bnb  
     */
    function withdrawCurrency(uint256 _amount) external onlyOwner returns(bool){
        msg.sender.transfer(_amount);
        return true;
    }

}