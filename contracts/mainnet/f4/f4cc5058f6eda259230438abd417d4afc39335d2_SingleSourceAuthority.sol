pragma solidity ^0.4.17;

contract SingleSourceAuthority {
    // Struct and Enum
    struct Authority {
        bool valid;
        address authorizedBy;
        address revokedBy;
        uint validFrom;
        uint validTo;
    }

    // Instance variables
    address public rootAuthority;
    mapping(address => Authority) public authorities;

    // Modifier
    modifier restricted() {
        if (msg.sender == rootAuthority)
            _;
    }

    // Init
    function SingleSourceAuthority() public {
        rootAuthority = msg.sender;
    }

    // Functions
    function changeRootAuthority(address newRootAuthorityAddress)
      public
      restricted()
    {
        rootAuthority = newRootAuthorityAddress;
    }

    function isRootAuthority(address authorityAddress)
      public
      view
      returns (bool)
    {
        if (authorityAddress == rootAuthority) {
            return true;
        } else {
            return false;
        }
    }

    function isValidAuthority(address authorityAddress, uint blockNumber)
      public
      view
      returns (bool)
    {
        Authority storage authority = authorities[authorityAddress];
        if (authority.valid) {
            if (authority.validFrom <= blockNumber && (authority.validTo == 0 || authority.validTo >= blockNumber)) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function approveAuthority(address authorityAddress) public restricted() {
        Authority memory authority = Authority({
            valid: true,
            authorizedBy: msg.sender,
            revokedBy: 0x0,
            validFrom: block.number,
            validTo: 0
        });
        authorities[authorityAddress] = authority;
    }

    function revokeAuthority(address authorityAddress, uint blockNumber) public restricted() {
        Authority storage authority = authorities[authorityAddress];
        authority.revokedBy = msg.sender;
        authority.validTo = blockNumber;
    }
}