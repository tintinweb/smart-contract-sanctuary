/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// Author: Elmar Eckstein.
pragma solidity ^0.8.4;

contract BatteryPassportBCC {
    /// @notice Keeps the value of the battery's parent.
    struct Parent {
        string name;
        uint256 dateOfProduction;
    }

    /// @notice Keeps the value of the battery's parts.
    struct PartList {
        string cobalt;
        string BMS;
        bool initialized;
    }

    /// @notice Keeps the value of the battery's health.
    struct StateOfHealth {
        uint256 remainingCapacity;
        uint256 maxCapacity;
        uint256 averageTemp;
    }

    /// @notice Keeps the value of all battery info.
    struct BatteryInfo {
        Parent parent;
        PartList partList;
        StateOfHealth stateOfHealth;
    }

    /// @notice Ensures that only authorized addresses can do certain operations.
    modifier onlyAuthorizedModifier() {
        require(
            authorizedModifiers[msg.sender] == true,
            "Account not authorized."
        );
        _;
    }

    /// @notice Tracks who is authorized to modify or add batteries.
    mapping(address => bool) public authorizedModifiers;

    /// @notice Tracks battery info by mapping the serial number to the data.
    mapping(uint256 => BatteryInfo) public batteryMapping;

    /// @notice An event that is emitted when somone's authorization changes.
    event AutorizedModifierChanged(bool isAuthorized);

    /// @notice An event that is emitted when a battery's info changes.
    event ChangedBatteryPassport(uint256 serialNumber, BatteryInfo info);

    /**
     * @notice Create the smart contract. After creation, only the contract creator is authorized to make changes or add other authorities.
     */
    constructor() {
        authorizedModifiers[msg.sender] = true;
    }

    /**
     * @notice Toggle an address' authority to the opposite of what it currently is.
     * @param _modifier The address that should be toggled.
     */
    function toggleAuthorizedModifier(address _modifier)
        public
        onlyAuthorizedModifier
    {
        require(_modifier != msg.sender, "Cannot deauthorize yourself.");
        authorizedModifiers[_modifier] = !authorizedModifiers[_modifier];
        emit AutorizedModifierChanged(authorizedModifiers[_modifier]);
    }

    /**
     * @notice Sets the parent of the battery to the values provided.
     * @param serialNumber The serial number of the battery that should be changed.
     * @param parentName The name of the parent.
     * @param parentDoP The date of production of the parent.
     */
    function setBatteryParent(
        uint256 serialNumber,
        string calldata parentName,
        uint256 parentDoP
    ) public onlyAuthorizedModifier {
        Parent storage current = batteryMapping[serialNumber].parent;
        current.name = parentName;
        current.dateOfProduction = parentDoP;
        emit ChangedBatteryPassport(serialNumber, batteryMapping[serialNumber]);
    }

    /**
     * @notice Sets the part list of the battery to the values provided. This method can only be executed once.
     * @param serialNumber The serial number of the battery that should be changed.
     * @param cobaltName The name of the cobalt supplier.
     * @param bmsName The name of the BMS supplier.
     */
    function setBatteryPartList(
        uint256 serialNumber,
        string calldata cobaltName,
        string calldata bmsName
    ) public onlyAuthorizedModifier {
        PartList storage current = batteryMapping[serialNumber].partList;
        // Ensure that the part list can never be changed after it has been initialized.
        require(
            current.initialized == false,
            "The part list cannot be changed."
        );
        current.cobalt = cobaltName;
        current.BMS = bmsName;
        current.initialized = true;
        emit ChangedBatteryPassport(serialNumber, batteryMapping[serialNumber]);
    }

    /**
     * @notice Sets the battery's state of health to the values provided.
     * @param serialNumber The serial number of the battery that should be changed.
     * @param remainingCapacity The battery's remaining capacity.
     * @param maxCapacity The battery's maximum capacity.
     * @param averageTemp The battery's average operating temperature.
     */
    function setBatteryStateOfHealth(
        uint256 serialNumber,
        uint256 remainingCapacity,
        uint256 maxCapacity,
        uint256 averageTemp
    ) public onlyAuthorizedModifier {
        StateOfHealth storage current = batteryMapping[serialNumber]
            .stateOfHealth;
        current.remainingCapacity = remainingCapacity;
        current.maxCapacity = maxCapacity;
        current.averageTemp = averageTemp;
        emit ChangedBatteryPassport(serialNumber, batteryMapping[serialNumber]);
    }
}