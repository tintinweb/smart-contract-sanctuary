// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Token for the platform 5ive.
 * The owner is the company FIATWISE AG
 */

contract FiveBuckToken is ERC20, Ownable {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;

    string public constant _name = "5ife Buck Token";
    string public constant _symbol = "5IFE";
    uint256 _initalSupply = 500000000000*(10**18);
    uint256 _MintTokenPerUser = 3000000*(10**18);
    uint256 _BurnTokenPerUser = 1000000*(10**18);
    uint256 _UserAmount = 0;
    uint256 _BurnedUserAmount = 0;
  
    /**
     * @dev constructor() ERC20(_name,_symbol) — is executed once when the smartcontract is deployed. It initializes the contract and generates the inital tokens.
     * */
    constructor() ERC20(_name,_symbol)
    {
       _mint(owner(), _initalSupply);
    }
    
    /**
     * @dev mintForUsers(uint256 amount) public — this function calculates the total number of tokens that need to be minted / generated for the given number of users and destroys them. The tokens will be sent from the address "0x0000000000000000000000000000000000000000" to the owner address
     * */
    function mintForUsers(uint256 amount) public
    {
      require(msg.sender == owner());
      _UserAmount+=amount;
      mint(amount * _MintTokenPerUser);
    }
  
    /**
     * @dev mint(uint256 amount) public — mints / generates the passed amount of token. The tokens will be sent from the address "0x0000000000000000000000000000000000000000" to the owner address.
     * */
    function mint(uint256 amount) public
    {
      require(msg.sender == owner());
      _mint(owner(), amount);
    }
    
    /**
     * @dev burn(uint256 amount) public — this function calculates the total number of tokens that need to be burned / destroyed for the given number of users and destroys them. The tokens will be sent to the address "0x0000000000000000000000000000000000000000".
     * */
    function burnForUsers(uint256 amount) public
    {
      require(msg.sender == owner());
      require((_UserAmount-amount) >= 0, "You can not burn more Users than existing"); // Not more Burnable than existing users.
      _UserAmount-=amount;
      _BurnedUserAmount+=amount;
      burn(amount * _BurnTokenPerUser);
    }
    
    /**
     * @dev burn(uint256 amount) public — burns / destroys the passed amount of token. The tokens will be sent to the address "0x0000000000000000000000000000000000000000".
     * */
    function burn(uint256 amount) public
    {
      require(msg.sender == owner());
      _burn(owner(), amount);
    }
    
    /**
     * @dev GetNumberOfUsersOnThePlatform() public view returns(uint256) — returns the amount of active users on the platform.
     * */
    function GetNumberOfUsersOnThePlatform() public view returns(uint256)
    {
        return _UserAmount;
    }
    
    /**
     * @dev GetNumberOfBurnedUsersOnThePlatform() public view returns(uint256) — returns the amount of users that have been burned / destroyed since the start of the contract.
     * */
    function GetNumberOfBurnedUsersOnThePlatform() public view returns(uint256)
    {
        return _BurnedUserAmount;
    }
    
    /**
     * @dev GetMintingAmountPerUser() public view returns(uint256) — changes the amount of tokens that are minted / generated per user.
     * */
    function ChangeMintingAmountPerUser(uint256 amount) public
    {
        require(msg.sender == owner());
        require(amount >= 0);
        _MintTokenPerUser = amount;
    }
    
    /**
     * @dev GetBurningAmountPerUser() public view returns(uint256) — changes the amount of tokens that are burned / destroyed per user.
     * */
    function ChangeBurningAmountPerUser(uint256 amount) public
    {
        require(msg.sender == owner());
        require(amount >= 0);
        _BurnTokenPerUser = amount;
    }
    
    /**
     * @dev GetMintingAmountPerUser() public view returns(uint256) — returns the amount of tokens that are minted / generated per user.
     * */
    function GetMintingAmountPerUser() public view returns(uint256)
    {
        return _MintTokenPerUser;
    }
    
    /**
     * @dev GetBurningAmountPerUser() public view returns(uint256) — returns the amount of tokens that are burned / destroyed per user.
     * */
    function GetBurningAmountPerUser() public view returns(uint256)
    {
        return _BurnTokenPerUser;
    }
    
    /**
     * @dev fallback() external payable  — when no other function matches (not even the receive function). Optionally payable.
     * */
    fallback() external payable 
    {
        revert("The contract cannot receive ETH payments.");
    }

    /**
     * @dev receive() external payable — for empty calldata (and any value).
     * */
    receive() external payable 
    {
        revert("The contract cannot receive ETH payments.");
    }
}