// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./LERC20.sol";

interface LosslessController {
    function setProtectedAddress(address token, address guardedAddress, address strategy) external;

    function removeProtectedAddress(address token, address guardedAddress) external;

    function admin() external returns(address);

    function pauseAdmin() external returns(address);
}

contract LosslessGuardian {
    mapping(address => address) public protectionAdmin;
    mapping(address => bool) public verifiedStrategies;
    mapping(address => bool) public verifiedTokens;
    mapping(address => VerifiedAddress) private verifiedAddresses;
    LosslessController public lossless;

    struct VerifiedAddress {
        mapping(address => bool) verified;
    }

    // --- EVENTS ---

    event TokenVerified(address indexed token, bool value);
    event AddressVerified(address indexed token, address indexed verifiedAddress, bool value);
    event ProtectionAdminSet(address indexed token, address indexed admin);
    event StrategyVerified(address indexed strategy, bool value);

    constructor(address _lossless) {
        lossless = LosslessController(_lossless);
    }

    // --- MODIFIERS ---

    modifier onlyLosslessAdmin() {
        require(msg.sender == lossless.admin(),"LOSSLESS: Not lossless admin");
        _;
    }

    modifier onlyVerifiedStrategy() {
        require(verifiedStrategies[msg.sender], "LOSSLESS: Strategy not verified");
        _;
    }

    modifier onlyVerifiedToken(address token) {
        require(verifiedTokens[token], "LOSSLESS: Token not verified");
        _;
    }

    // --- VIEWS ---

    function isAddressVerified(address token, address addressToCheck) external view returns(bool) {
        return verifiedAddresses[token].verified[addressToCheck];
    }

    // --- METHODS

    // @dev Strategies are where all the protection implementation logic lives.
    function verifyStrategies(address[] calldata strategies, bool value) external onlyLosslessAdmin {
        for(uint8 i = 0; i < strategies.length; i++) {
            verifiedStrategies[strategies[i]] = value;
            emit StrategyVerified(strategies[i], value);
        }
    }

    // @dev Lossless team has to verify projects that can use protection functionality.
    function verifyToken(address token, bool value) external onlyLosslessAdmin {
        verifiedTokens[token] = value;
        emit TokenVerified(token, value);
    }

    // @dev Lossless team has to verify addresses that projects want to protect.
    function verifyAddress(address token, address verifiedAddress, bool value) external onlyLosslessAdmin onlyVerifiedToken(token) {
        verifiedAddresses[token].verified[verifiedAddress] = value;
        emit AddressVerified(token, verifiedAddress, value);
    }   

    // @notice Token admin sets up another admin that is responsible for managing protection.
    function setProtectionAdmin(address token, address admin) external onlyVerifiedToken(token) {
        require(LERC20(token).getAdmin() == msg.sender, "LOSSLESS: Not token admin");
        protectionAdmin[token] = admin;
        emit ProtectionAdminSet(token, admin);
    }

    // @dev This is called from strategy conctract and forwards that call to the controller.
    function setProtectedAddress(address token, address guardedAddress) external onlyVerifiedStrategy {
        require(verifiedAddresses[token].verified[guardedAddress], "LOSSLESS: Address not verified");
        lossless.setProtectedAddress(token, guardedAddress, msg.sender);
    }
    
    // @dev This is called from strategy conctract or protection admin and forwards that call to the controller.
    function removeProtectedAddresses(address token, address protectedAddress) external {
        require(verifiedStrategies[msg.sender] || (msg.sender == protectionAdmin[token] && msg.sender != address(0)), "LOSSLESS: Unauthorized access");
        lossless.removeProtectedAddress(token, protectedAddress);
    }
}