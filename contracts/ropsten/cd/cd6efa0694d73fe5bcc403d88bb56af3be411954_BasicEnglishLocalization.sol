pragma solidity ^0.4.25;

/// @title Holds a simple mapping of codes to their text representations
contract Localization {
    mapping(bytes32 => string) internal dictionary_;

    constructor() public {}

    /// @notice Sets a mapping of a code to its text representation
    /// @dev Currently overwrites a code to text representation mapping if it already exists
    /// @param _code The code with which to associate the text
    /// @param _message The text representation
    function set(bytes32 _code, string _message) public {
        dictionary_[_code] = _message;
    }

    /// @notice Fetches the localized text representation.
    /// @param _code The code to lookup
    /// @return The text representation for given code, or an empty string
    function textFor(bytes32 _code) external view returns (string _message) {
        return dictionary_[_code];
    }
}

/// @title Adds FISSION specific functionality to Localization
contract FissionLocalization is Localization {
    event FissionCode(bytes32 indexed code, string message);

    /// @notice Emits a FissionCode event for give _code
    /// @param _code The code with which to retrieve the message passed to FissionCode event
    function log(bytes32 _code) public {
        emit FissionCode(_code, dictionary_[_code]);
    }
}

contract BasicEnglishLocalization is FissionLocalization {
  constructor() public {
    set(hex"00", "Failure");
    set(hex"01", "Success");
    set(hex"02", "Accepted/Started");
    set(hex"03", "Awaiting/Before");
    set(hex"04", "Action Required");
    set(hex"05", "Expired");

    set(hex"0F", "Metadata Only");

    set(hex"10", "Disallowed");
    set(hex"11", "Allowed");
    set(hex"12", "Requested Permission");
    set(hex"13", "Awaiting Permission");
    set(hex"14", "Awaiting Your Permission");
    set(hex"15", "No Longer Allowed");

    set(hex"20", "Not Found");
    set(hex"21", "Found");
    set(hex"22", "Match Request Sent");
    set(hex"23", "Awaiting Match");
    set(hex"24", "Match Request Received");
    set(hex"25", "Out of Range");

    set(hex"30", "Other Party Disagreed");
    set(hex"31", "Other Party Agreed");
    set(hex"32", "Sent Offer");
    set(hex"33", "Awaiting Their Ratification");
    set(hex"34", "Awaiting Your Ratification");
    set(hex"35", "Offer Expired");

    set(hex"40", "Unavailable");
    set(hex"41", "Available");
    set(hex"42", "You May Begin");
    set(hex"43", "Not Yet Available");
    set(hex"44", "Awaiting Your Availability/Signal");
    set(hex"45", "No Longer Available");

    set(hex"E0", "Decrypt Failure");
    set(hex"E1", "Decrypt Success");
    set(hex"E2", "Signed");
    set(hex"E3", "Oter Party Signature Required");
    set(hex"E4", "Your Signature Expired");
    set(hex"E5", "Token Expired");

    set(hex"F0", "Off Chain Failure");
    set(hex"F1", "Off Chain Success");
    set(hex"F2", "Off Chain Process Started");
    set(hex"F3", "Awaiting Off Chain Completion");
    set(hex"F4", "Off Chain Action Required");
    set(hex"F5", "Off Chain Service Not Available");

    set(hex"FF", "Data Source is Off Chain (ie: no guarantees)");
  }
}