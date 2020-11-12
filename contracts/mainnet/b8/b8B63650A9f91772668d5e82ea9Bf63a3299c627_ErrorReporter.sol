pragma solidity ^0.5.16;

contract WanttrollerErrorReporter {
    enum Error {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW,
        UNAUTHORIZED
    }   

    enum FailureInfo {
      ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
      ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
      SET_PENDING_ADMIN_OWNER_CHECK,
      SET_PAUSE_GUARDIAN_OWNER_CHECK,
      SET_IMPLEMENTATION_OWNER_CHECK,
      SET_PENDING_IMPLEMENTATION_OWNER_CHECK
    }   

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);
        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

