// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Airdrop is Ownable {

    struct Investor {
        uint256 amountLeft;
        bool locked;
    }

    ERC20 public Token;

    mapping(address => bool) public whitelisted;
    mapping(address => Investor) public investorDetails;

    event LogWhitelisted(address _investor, uint256 _amount, uint256 _timestamp);

    /**
     * @dev constructor is getting tokens from the token contract
     * @param _token Address of the token
     * @return ERC20 standard token 
     */
    constructor(address _token) public {
        Token = ERC20(_token);
    }


    /**
     * @notice Use to whitelist the investor
     * @param _investorAddresses Array of investors need to whitelist
     * only be called by the owner
     */

    function whitelist(address[] _investorAddresses,uint256[] _tokenAmount) external onlyOwner {
        require(_investorAddresses.length == _tokenAmount.length,"Input array's length mismatch");
        for (uint i = 0; i < _investorAddresses.length; i++) {
            whitelisted[_investorAddresses[i]] = true;
            investorDetails[_investorAddresses[i]] = Investor(_tokenAmount[i],false);
            emit LogWhitelisted(_investorAddresses[i], _tokenAmount[i], now);
        }
    }

     /**
      * @notice user can claim their airdrop tokens 
      */
    function claimTokens() external {
        require(whitelisted[msg.sender]);
        require(!investorDetails[msg.sender].locked);
        uint256 _amount = investorDetails[msg.sender].amountLeft;
        investorDetails[msg.sender] = Investor(0, true);
        Token.transfer(msg.sender, _amount);
    } 
    
    /**
     * @dev This function is used to sort the array of address and token to send tokens 
     * @param _investorsAdd Address array of the investors
     * @param _tokenVal Array of the tokens
     * @return tokens Calling function to send the tokens
     */
    function airdropTokenDistributionMulti(address[] _investorsAdd, uint256[] _tokenVal) public onlyOwner  returns (bool success){
        require(_investorsAdd.length == _tokenVal.length, "Input array's length mismatch");
        for(uint i = 0; i < _investorsAdd.length; i++ ){
            require(airdropTokenDistribution(_investorsAdd[i], _tokenVal[i]));
        }
        return true;
    }

    /**
     * @dev This function is used to get token balance at oddresses  from the array
     * @param _investorsAdd Array if address of the investors
     * @param _tokenVal Array of tokens to be send
     * @return bal Balance 
     */
    function airdropTokenDistribution(address _investorsAdd, uint256 _tokenVal) public onlyOwner returns (bool success){
        require(_investorsAdd != owner, "Reciever should not be the owner of the contract");
        require(Token.transfer(_investorsAdd, _tokenVal));
        return true;
    }

    function mahTest(address _investorsAdd, uint256 _tokenVal) public onlyOwner {
        Token.approve(address(this), _tokenVal);
        Token.transfer(_investorsAdd, _tokenVal);
    }

    /**
     * @dev This function is used to add remaining token balance to the owner address
     * @param _tokenAddress Address of the token contract
     * @return true  
     */
    function withdrawTokenBalance(address _tokenAddress) public onlyOwner returns (bool success){
        require(Token.transfer(_tokenAddress, Token.balanceOf(address(this))));
        return true;
    }

    /**
     * @dev This function is used to add remaining balance to the owner address
     * @return true 
     */
    function withdrawEtherBalance() public onlyOwner returns (bool success){
        owner.transfer(address(this).balance);
        return true;
    }
}

pragma solidity ^0.4.23;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.4.23;

import "./ERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

pragma solidity ^0.4.23;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}