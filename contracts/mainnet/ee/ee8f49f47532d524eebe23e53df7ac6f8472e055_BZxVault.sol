/**
 * Copyright 2017–2018, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
 
pragma solidity 0.4.24;


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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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

contract BZxOwnable is Ownable {

    address public bZxContractAddress;

    event BZxOwnershipTransferred(address indexed previousBZxContract, address indexed newBZxContract);

    // modifier reverts if bZxContractAddress isn&#39;t set
    modifier onlyBZx() {
        require(msg.sender == bZxContractAddress, "only bZx contracts can call this function");
        _;
    }

    /**
    * @dev Allows the current owner to transfer the bZx contract owner to a new contract address
    * @param newBZxContractAddress The bZx contract address to transfer ownership to.
    */
    function transferBZxOwnership(address newBZxContractAddress) public onlyOwner {
        require(newBZxContractAddress != address(0) && newBZxContractAddress != owner, "transferBZxOwnership::unauthorized");
        emit BZxOwnershipTransferred(bZxContractAddress, newBZxContractAddress);
        bZxContractAddress = newBZxContractAddress;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    * This overrides transferOwnership in Ownable to prevent setting the new owner the same as the bZxContract
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0) && newOwner != bZxContractAddress, "transferOwnership::unauthorized");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface NonCompliantEIP20 {
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
}

contract EIP20Wrapper {

    function eip20Transfer(
        address token,
        address to,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).transfer(to, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, "eip20Transfer failed");
    }

    function eip20TransferFrom(
        address token,
        address from,
        address to,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).transferFrom(from, to, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, "eip20TransferFrom failed");
    }

    function eip20Approve(
        address token,
        address spender,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).approve(spender, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, "eip20Approve failed");
    }
}

contract BZxVault is EIP20Wrapper, BZxOwnable {

    // Only the bZx contract can directly deposit ether
    function() public payable onlyBZx {}

    function withdrawEther(
        address to,
        uint value)
        public
        onlyBZx
        returns (bool)
    {
        uint amount = value;
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }

        return (to.send(amount)); // solhint-disable-line check-send-result, multiple-sends
    }

    function depositToken(
        address token,
        address from,
        uint tokenAmount)
        public
        onlyBZx
        returns (bool)
    {
        if (tokenAmount == 0) {
            return false;
        }

        eip20TransferFrom(
            token,
            from,
            this,
            tokenAmount);

        return true;
    }

    function withdrawToken(
        address token,
        address to,
        uint tokenAmount)
        public
        onlyBZx
        returns (bool)
    {
        if (tokenAmount == 0) {
            return false;
        }

        eip20Transfer(
            token,
            to,
            tokenAmount);

        return true;
    }

    function transferTokenFrom(
        address token,
        address from,
        address to,
        uint tokenAmount)
        public
        onlyBZx
        returns (bool)
    {
        if (tokenAmount == 0) {
            return false;
        }

        eip20TransferFrom(
            token,
            from,
            to,
            tokenAmount);

        return true;
    }
}