/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract EtherCraftPlayers {

    address public owner;
    uint256 public collateralAmount;

    constructor() {
        owner = msg.sender;
        collateralAmount = 1 ether;
    }

    struct Player {
        address account;
        bool validity;
        uint256 collateral;
    }

    mapping(bytes32 => Player) public players;

    /*
    *   @notice Player verification happens off-chain. A player cannot be tied back to an Ethereum address.
    *   @param key Hash of official Minecraft encrypted player name, signed message and the server's private key
    *   @param account Connected Ethereum wallet address
    */
    function login(bytes32 key, address account) external onlyOwner {
        players[key].validity = true;
        players[key].collateral = collateralAmount;
        players[key].account = account;
        // todo collateral
    }

    /*
    *   @notice Ethereum account owner can log out through the server if they have their Minecraft account connected
    *   @param  key Hash of official Minecraft encrypted player name, signed message and the server's private key
    */
    function logout(bytes32 key) external onlyOwner {
        require(players[key].validity == true, "Player already logged out");
        uint256 sendAmount = players[key].collateral;
        delete players[key];
        // todo collateral
    }

    /*
    *   @notice Dev sets required collateral amount to log in
    */
    function setCollateralAmount(uint256 amount) external {
        require(msg.sender == owner, "!Permission");
        collateralAmount = amount;
    }

    // Modifiers

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Demo functions
    function createKey(bytes32 usernameHash, bytes calldata signature, string memory password) external pure returns (bytes32) {
        return keccak256(abi.encode(usernameHash, signature, password));
    }

}