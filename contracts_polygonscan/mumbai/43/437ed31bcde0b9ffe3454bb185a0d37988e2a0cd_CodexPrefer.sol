/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/codex/codex-prefer.sol

pragma solidity >=0.6.7 <0.7.0;

////// src/interfaces/ISettingsRegistry.sol
/* pragma solidity ^0.6.7; */

interface ISettingsRegistry {
    function uintOf(bytes32 _propertyName) external view returns (uint256);
    function addressOf(bytes32 _propertyName) external view returns (address);
}

////// src/codex/codex-prefer.sol
/* pragma solidity ^0.6.7; */

/* import "../interfaces/ISettingsRegistry.sol"; */

contract CodexPrefer {
    string constant public index = "Base";
    string constant public class = "Prefer";

    bytes32 public constant CONTRACT_ELEMENT_TOKEN = "CONTRACT_ELEMENT_TOKEN";
    bytes32 public constant CONTRACT_LP_ELEMENT_TOKEN = "CONTRACT_LP_ELEMENT_TOKEN";

    bytes32 public constant CONTRACT_GOLD_ERC20_TOKEN = "CONTRACT_GOLD_ERC20_TOKEN";
    bytes32 public constant CONTRACT_WOOD_ERC20_TOKEN = "CONTRACT_WOOD_ERC20_TOKEN";
    bytes32 public constant CONTRACT_WATER_ERC20_TOKEN = "CONTRACT_WATER_ERC20_TOKEN";
    bytes32 public constant CONTRACT_FIRE_ERC20_TOKEN = "CONTRACT_FIRE_ERC20_TOKEN";
    bytes32 public constant CONTRACT_SOIL_ERC20_TOKEN = "CONTRACT_SOIL_ERC20_TOKEN";

    bytes32 public constant CONTRACT_LP_GOLD_ERC20_TOKEN = "CONTRACT_LP_GOLD_ERC20_TOKEN";
    bytes32 public constant CONTRACT_LP_WOOD_ERC20_TOKEN = "CONTRACT_LP_WOOD_ERC20_TOKEN";
    bytes32 public constant CONTRACT_LP_WATER_ERC20_TOKEN = "CONTRACT_LP_WATER_ERC20_TOKEN";
    bytes32 public constant CONTRACT_LP_FIRE_ERC20_TOKEN = "CONTRACT_LP_FIRE_ERC20_TOKEN";
    bytes32 public constant CONTRACT_LP_SOIL_ERC20_TOKEN = "CONTRACT_LP_SOIL_ERC20_TOKEN";

    uint256 public constant PREFER_GOLD = 1 << 1;
    uint256 public constant PREFER_WOOD = 1 << 2;
    uint256 public constant PREFER_WATER = 1 << 3;
    uint256 public constant PREFER_FIRE = 1 << 4;
    uint256 public constant PREFER_SOIL = 1 << 5;

    ISettingsRegistry public registry;
    mapping(bytes32 => mapping(address => uint256)) public prefers;
    mapping(bytes32 => mapping(uint256 => address)) public elements;

    constructor(address _registry) public {
        registry = ISettingsRegistry(_registry);
        prefers[CONTRACT_ELEMENT_TOKEN][
            registry.addressOf(CONTRACT_GOLD_ERC20_TOKEN)
        ] = PREFER_GOLD;
        prefers[CONTRACT_ELEMENT_TOKEN][
            registry.addressOf(CONTRACT_WOOD_ERC20_TOKEN)
        ] = PREFER_WOOD;
        prefers[CONTRACT_ELEMENT_TOKEN][
            registry.addressOf(CONTRACT_WATER_ERC20_TOKEN)
        ] = PREFER_WATER;
        prefers[CONTRACT_ELEMENT_TOKEN][
            registry.addressOf(CONTRACT_FIRE_ERC20_TOKEN)
        ] = PREFER_FIRE;
        prefers[CONTRACT_ELEMENT_TOKEN][
            registry.addressOf(CONTRACT_SOIL_ERC20_TOKEN)
        ] = PREFER_SOIL;

        prefers[CONTRACT_LP_ELEMENT_TOKEN][
            registry.addressOf(CONTRACT_LP_GOLD_ERC20_TOKEN)
        ] = PREFER_GOLD;
        prefers[CONTRACT_LP_ELEMENT_TOKEN][
            registry.addressOf(CONTRACT_LP_WOOD_ERC20_TOKEN)
        ] = PREFER_WOOD;
        prefers[CONTRACT_LP_ELEMENT_TOKEN][
            registry.addressOf(CONTRACT_LP_WATER_ERC20_TOKEN)
        ] = PREFER_WATER;
        prefers[CONTRACT_LP_ELEMENT_TOKEN][
            registry.addressOf(CONTRACT_LP_FIRE_ERC20_TOKEN)
        ] = PREFER_FIRE;
        prefers[CONTRACT_LP_ELEMENT_TOKEN][
            registry.addressOf(CONTRACT_LP_SOIL_ERC20_TOKEN)
        ] = PREFER_SOIL;

        elements[CONTRACT_ELEMENT_TOKEN][PREFER_GOLD] = registry.addressOf(CONTRACT_GOLD_ERC20_TOKEN);
        elements[CONTRACT_ELEMENT_TOKEN][PREFER_WOOD] = registry.addressOf(CONTRACT_WOOD_ERC20_TOKEN);
        elements[CONTRACT_ELEMENT_TOKEN][PREFER_WATER] = registry.addressOf(CONTRACT_WATER_ERC20_TOKEN);
        elements[CONTRACT_ELEMENT_TOKEN][PREFER_FIRE] = registry.addressOf(CONTRACT_FIRE_ERC20_TOKEN);
        elements[CONTRACT_ELEMENT_TOKEN][PREFER_SOIL] = registry.addressOf(CONTRACT_SOIL_ERC20_TOKEN);

        elements[CONTRACT_LP_ELEMENT_TOKEN][PREFER_GOLD] = registry.addressOf(CONTRACT_LP_GOLD_ERC20_TOKEN);
        elements[CONTRACT_LP_ELEMENT_TOKEN][PREFER_WOOD] = registry.addressOf(CONTRACT_LP_WOOD_ERC20_TOKEN);
        elements[CONTRACT_LP_ELEMENT_TOKEN][PREFER_WATER] = registry.addressOf(CONTRACT_LP_WATER_ERC20_TOKEN);
        elements[CONTRACT_LP_ELEMENT_TOKEN][PREFER_FIRE] = registry.addressOf(CONTRACT_LP_FIRE_ERC20_TOKEN);
        elements[CONTRACT_LP_ELEMENT_TOKEN][PREFER_SOIL] = registry.addressOf(CONTRACT_LP_SOIL_ERC20_TOKEN);
    }

    function getPrefer(bytes32 minor, address token) public view returns (uint256) {
        return prefers[minor][token];
    }

    function getElement(bytes32 minor, uint256 prefer) public view returns (address) {
        return elements[minor][prefer];
    }

}