pragma solidity ^0.4.24;

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

/// @notice RenExTokens is a registry of tokens that can be traded on RenEx.
contract RenExTokens is Ownable {
    string public VERSION; // Passed in as a constructor parameter.

    struct TokenDetails {
        address addr;
        uint8 decimals;
        bool registered;
    }

    // Storage
    mapping(uint32 => TokenDetails) public tokens;
    mapping(uint32 => bool) private detailsSubmitted;

    // Events
    event LogTokenRegistered(uint32 tokenCode, address tokenAddress, uint8 tokenDecimals);
    event LogTokenDeregistered(uint32 tokenCode);

    /// @notice The contract constructor.
    ///
    /// @param _VERSION A string defining the contract version.
    constructor(string _VERSION) public {
        VERSION = _VERSION;
    }

    /// @notice Allows the owner to register and the details for a token.
    /// Once details have been submitted, they cannot be overwritten.
    /// To re-register the same token with different details (e.g. if the address
    /// has changed), a different token identifier should be used and the
    /// previous token identifier should be deregistered.
    /// If a token is not Ethereum-based, the address will be set to 0x0.
    ///
    /// @param _tokenCode A unique 32-bit token identifier.
    /// @param _tokenAddress The address of the token.
    /// @param _tokenDecimals The decimals to use for the token.
    function registerToken(uint32 _tokenCode, address _tokenAddress, uint8 _tokenDecimals) public onlyOwner {
        require(!tokens[_tokenCode].registered, "already registered");

        // If a token is being re-registered, the same details must be provided.
        if (detailsSubmitted[_tokenCode]) {
            require(tokens[_tokenCode].addr == _tokenAddress, "different address");
            require(tokens[_tokenCode].decimals == _tokenDecimals, "different decimals");
        } else {
            detailsSubmitted[_tokenCode] = true;
        }

        tokens[_tokenCode] = TokenDetails({
            addr: _tokenAddress,
            decimals: _tokenDecimals,
            registered: true
        });

        emit LogTokenRegistered(_tokenCode, _tokenAddress, _tokenDecimals);
    }

    /// @notice Sets a token as being deregistered. The details are still stored
    /// to prevent the token from being re-registered with different details.
    ///
    /// @param _tokenCode The unique 32-bit token identifier.
    function deregisterToken(uint32 _tokenCode) external onlyOwner {
        require(tokens[_tokenCode].registered, "not registered");

        tokens[_tokenCode].registered = false;

        emit LogTokenDeregistered(_tokenCode);
    }
}