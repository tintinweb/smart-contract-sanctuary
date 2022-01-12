// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "./Ownable.sol";
import "./ITransferController.sol";

//implementation to control transfer of q2

contract TransferController is ITransferController, Ownable {
    mapping(address => bool) public whitelistedAddresses;

    mapping(address => bool) moderator;

    // add addresss to transfer q2
    function addAddressToWhiteList(address[] memory _users, bool status)
        public
        override
        returns (bool isWhitelisted)
    {
        require(msg.sender == owner || moderator[msg.sender]);
        for (uint256 x = 0; x < _users.length; x++) {
            if (!isWhiteListed(_users[x])) {
                whitelistedAddresses[_users[x]] = status;
            }
        }

        return true;
    }

    function isWhiteListed(address _user) public view override returns (bool) {
        return whitelistedAddresses[_user];
    }

    function addModerator(address _user, bool status) public onlyOwner {
        moderator[_user] = status;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Ownable {
  address public owner;

  // Event
  event OwnershipChanged(address indexed oldOwner, address indexed newOwner);

  // Modifier
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  constructor(){
    owner = msg.sender;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipChanged(owner, newOwner);
    owner = newOwner;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

//Interface to control transfer of q2
interface ITransferController {
    function addAddressToWhiteList(address[] memory _users, bool status)
       external 
        returns (bool);

    function isWhiteListed(address _user)  external view returns (bool);
}