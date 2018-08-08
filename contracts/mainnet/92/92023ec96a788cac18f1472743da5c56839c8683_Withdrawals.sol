pragma solidity ^0.4.21;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/Withdrawals.sol

contract Withdrawals is Claimable {
    
    /**
    * @dev responsible for calling withdraw function
    */
    address public withdrawCreator;

    /**
    * @dev if it&#39;s token transfer the tokenAddress will be 0x0000... 
    * @param _destination receiver of token or eth
    * @param _amount amount of ETH or Tokens
    * @param _tokenAddress actual token address or 0x000.. in case of eth transfer
    */
    event AmountWithdrawEvent(
    address _destination, 
    uint _amount, 
    address _tokenAddress 
    );

    /**
    * @dev fallback function only to enable ETH transfer
    */
    function() payable public {

    }

    /**
    * @dev setter for the withdraw creator (responsible for calling withdraw function)
    */
    function setWithdrawCreator(address _withdrawCreator) public onlyOwner {
        withdrawCreator = _withdrawCreator;
    }

    /**
    * @dev withdraw function to send token addresses or eth amounts to a list of receivers
    * @param _destinations batch list of token or eth receivers
    * @param _amounts batch list of values of eth or tokens
    * @param _tokenAddresses what token to be transfered in case of eth just leave the 0x address
    */
    function withdraw(address[] _destinations, uint[] _amounts, address[] _tokenAddresses) public onlyOwnerOrWithdrawCreator {
        require(_destinations.length == _amounts.length && _amounts.length == _tokenAddresses.length);
        // itterate in receivers
        for (uint i = 0; i < _destinations.length; i++) {
            address tokenAddress = _tokenAddresses[i];
            uint amount = _amounts[i];
            address destination = _destinations[i];
            // eth transfer
            if (tokenAddress == address(0)) {
                if (this.balance < amount) {
                    continue;
                }
                if (!destination.call.gas(70000).value(amount)()) {
                    continue;
                }
                
            }else {
            // erc 20 transfer
                if (ERC20(tokenAddress).balanceOf(this) < amount) {
                    continue;
                }
                ERC20(tokenAddress).transfer(destination, amount);
            }
            // emit event in both cases
            emit AmountWithdrawEvent(destination, amount, tokenAddress);                
        }

    }

    modifier onlyOwnerOrWithdrawCreator() {
        require(msg.sender == withdrawCreator || msg.sender == owner);
        _;
    }

}