//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AdminStorage {

  /// @notice Administrator for the contract
  address public admin;

  /// @notice Pending administrator for the contract
  address public pendingAdmin;
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ControllerError {

  enum Error {
              NO_ERROR,
              UNAUTHORIZED
  }
  
  event Failure(uint error);

  function fail(Error err) internal returns (uint) {
    emit Failure(uint(err));
    return uint(err);
  }
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract QodaV1FixedRateLoan {

  /// @notice address of the ERC20 token that the loan will be denominated in
  address public tokenAddress;

  constructor(address _tokenAddress) public {
    tokenAddress = _tokenAddress;
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./AdminStorage.sol";
import "./ErrorCodes.sol";
import "./QodaV1FixedRateLoan.sol";

contract QodaV1Registry is AdminStorage, ControllerError {

  /// @notice Emitted when pendingAdmin is changed
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /// @notice Emitted when pendingAdmin is accepted
  event NewAdmin(address oldAdmin, address newAdmin);

  /// @notice Gets the Qoda Loan contract given a token address
  mapping(address => address) public tokenToContract;
  
  constructor() public {
    admin = msg.sender;
  }

  /// @notice Begin transfer of admin rights. The newPendingAdmin must call _acceptAdmin to finalize the transfer
  /// @param newPendingAdmin address of new pending admin
  /// @return uint 0 if successful, otherwise return an error code
  function _setPendingAdmin(address newPendingAdmin) public returns(uint) {
    if (msg.sender != admin) {
      return fail(Error.UNAUTHORIZED);
    }
    address oldPendingAdmin = pendingAdmin;
    pendingAdmin = newPendingAdmin;
    emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    return uint(Error.NO_ERROR);
  }

  /// @notice Finalize the admin transfer. Note msg.sender is the pendingAdmin
  /// @return uint 0 if successful, otherwise return an error code
  function _acceptAdmin() public returns(uint) {
    if (msg.sender != pendingAdmin || msg.sender == address(0)) {
      return fail(Error.UNAUTHORIZED);
    }
    address oldAdmin = admin;
    address oldPendingAdmin = pendingAdmin;
    admin = pendingAdmin;
    pendingAdmin = address(0);
    emit NewAdmin(oldAdmin, admin);
    emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    return uint(Error.NO_ERROR);
  }

  /// @notice deploys the contract with notional denominated from token address
  /// @param tokenAddress address of ERC20 token
  /// @return address address of the newly instantiated contract
  function instantiateContract(address tokenAddress) public returns(address) {
    require(msg.sender == admin, "unauthorized");
    require(tokenAddress != address(0), "invalid token address");
    require(tokenToContract[tokenAddress] == address(0), "contract already exists");
    QodaV1FixedRateLoan fixedRateLoan = new QodaV1FixedRateLoan(tokenAddress);
    tokenToContract[tokenAddress] = address(fixedRateLoan);
    return address(fixedRateLoan);
  }
  
  /// @notice Retrieves the Qoda Loan contract with notional denominated from token address
  /// @param tokenAddress address of ERC20 token
  /// @return address Qoda Loan contract address
  function getContract(address tokenAddress) public view returns(address) {
    return tokenToContract[tokenAddress];
  }
}