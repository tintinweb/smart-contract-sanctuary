/**
 *Submitted for verification at polygonscan.com on 2022-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract EtherRealmPlayers {

    address public owner;
    uint256 public collateralAmount;
    uint256 public timer;
    uint private constant HOUR = 3600;

    constructor() {
        owner = msg.sender;
        collateralAmount = 1 ether;
    }

    struct Player {
        address account;
        bool validity;
        uint256 collateral;
        uint256 logCheckpoint;
    }

    mapping(string => Player) private players;
    mapping(address => uint) private validCollateral;

    /*
    *   @notice Players deposit collateral before login to disincentivize cheating/hacking. Collateral will be returned on logout.
    */
    function depositCollateral() external payable returns (bool) {
        require(msg.value == collateralAmount, "Must provide correct collateral");
        require(validCollateral[msg.sender] == 0, "Collateral already deposited");
        validCollateral[msg.sender] = collateralAmount;
        return true;
    }

    /*
    *   @notice Player verification happens off-chain. A player cannot be tied back to an Ethereum address.
    *   @param key Hash of official Minecraft encrypted player name, signed message and the server's private key
    *   @param account Connected Ethereum wallet address
    */
    function login(string memory key, address account) external onlyOwner returns (bool) {
        if (collateralAmount > 0) require(validCollateral[account] > 0, "!Collateral");
        require(players[key].validity == false, "Already logged in");
        players[key].validity = true;
        players[key].collateral = validCollateral[account];
        players[key].account = account;
        players[key].logCheckpoint = block.timestamp;
        delete validCollateral[account];
        return true;
    }

    /*
    *   @notice Ethereum account owner can log out through the server if they have their Minecraft account connected
    *   @param  key Hash of official Minecraft encrypted player name, signed message and the server's private key
    */
    function logout(string memory key) external onlyOwner returns (bool) {
        require(block.timestamp > players[key].logCheckpoint + timer, "Must wait after logging in");
        require(players[key].validity == true, "Already logged out");
        uint256 sendAmount = players[key].collateral;
        address sendAccount = players[key].account;
        delete players[key];
        delete validCollateral[sendAccount];
        payable(sendAccount).transfer(sendAmount);
        return true;
    }

    // Useful read functions
    function createKey(string memory usernameHash, string memory signature, string memory password) external pure returns (string memory) {
        return toHex(keccak256(abi.encode(usernameHash, signature, password)));
    }

    function hashUsername(string memory username) external pure returns (string memory) {
        return toHex(keccak256(abi.encode(username)));
    }

    function validityPlayer(string memory key) external view returns (bool) {
        return players[key].validity;
    }

    function accountPlayer(string memory key) external view returns (address) {
        return players[key].account;
    }

    function collateralPlayer(string memory key) external view returns (uint) {
        return players[key].collateral;
    }

    function logCheckpointPlayer(string memory key) external view returns (uint) {
        return players[key].logCheckpoint;
    }

    function canLogout(string memory key) external view returns (bool) {
        return (block.timestamp > players[key].logCheckpoint + timer);
    }

    // Gov functions

    /*
    *   @notice Dev sets required collateral amount to log in
    *   @param  amount New amount needed to collateralize account
    */
    function setCollateralAmount(uint256 amount) external onlyOwner {
       require(msg.sender == owner, "!Permission");
       collateralAmount = amount;
    }

    /*
    *   @dev    Time unit is HOUR
    *   @notice Dev sets required time needed to wait between logging in and logging out
    *   @param  time Time in hours
    */
    function setTime(uint256 time) external onlyOwner {
       require(msg.sender == owner, "!Permission");
       timer = time * HOUR;
    }

    /*
    *   @notice Owner changes address
    *   @param _owner New owner address
    */
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    // Modifiers

    modifier onlyOwner {
        require(msg.sender == owner, "!Permission");
        _;
    }

    // Converting bytes32 to string with bytes32 as the content

    function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
        result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
            (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
            (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
            (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
            (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
            (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
            uint256 (result) +
            (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);
    }

    function toHex (bytes32 data) internal pure returns (string memory) {
        return string (abi.encodePacked ("0x", toHex16 (bytes16 (data)), toHex16 (bytes16 (data << 128))));
    }

}