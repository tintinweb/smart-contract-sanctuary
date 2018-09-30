pragma solidity ^0.4.23;

/// @title Endpoint Registry
/// @notice This contract is a registry which maps an Ethereum address to its
/// endpoint. The Raiden node registers its ethereum address in this registry.
contract EndpointRegistry {
    string constant public contract_version = "0.3._";

    event AddressRegistered(address indexed eth_address, string endpoint);
    mapping (address => string) private address_to_endpoint;

    modifier noEmptyString(string str) {
        require(equals(str, "") != true);
        _;
    }

    /// @notice Registers the Ethereum address to the given endpoint.
    /// @param endpoint String in the format "127.0.0.1:38647".
    function registerEndpoint(string endpoint)
        public
        noEmptyString(endpoint)
    {
        string storage old_endpoint = address_to_endpoint[msg.sender];

        // Compare if the new endpoint matches the old one, if it does just
        // return
        if (equals(old_endpoint, endpoint)) {
            return;
        }

        // Update the storage with the new endpoint value
        address_to_endpoint[msg.sender] = endpoint;
        emit AddressRegistered(msg.sender, endpoint);
    }

    /// @notice Finds the endpoint if given a registered Ethereum address.
    /// @param eth_address A 20 byte Ethereum address.
    /// @return endpoint which the current Ethereum address is using.
    function findEndpointByAddress(address eth_address)
        public
        view
        returns (string endpoint)
    {
        return address_to_endpoint[eth_address];
    }

    /// @notice Checks if two strings are equal or not.
    /// @param a First string.
    /// @param b Second string.
    /// @return result True if `a` and `b` are equal, false otherwise.
    function equals(string a, string b) internal pure returns (bool result)
    {
        if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))) {
            return true;
        }

        return false;
    }
}