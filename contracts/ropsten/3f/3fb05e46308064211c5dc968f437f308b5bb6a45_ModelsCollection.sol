/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT-License
pragma abicoder v2;
pragma solidity >=0.7.0 <0.8.0;

contract ModelsCollection {
    address private Owner;

    struct ModelRecord {
        string Title;
        string Link;
        string Hash;
        string Annotation;
        string Industry;
        uint256 DateTime;
    }

    ModelRecord[] private Models;

    uint256 private ModelsCount;

    mapping(address => bool) private Permissions;

    constructor() {
        Owner = msg.sender;
        Permissions[Owner] = true;

        // Default models
        AddModel(
            "Dispatch of goods",
            "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/dispatch.bpmn",
            "fb96d72d6c03821022ba871c1727fc124067c502892c07bfc5fe1d6b99639282",
            "This process happens at a small hardware company that ships small amounts of goods to end customers but as well big amounts to other shops",
            "Sales"
        );
        AddModel(
            "Recourse",
            "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/recourse.bpmn",
            "b89dfb71b3cfb290d911c6a87fdb1b974a90f5a636613336723c7c494ac41e3a",
            "Insurants can be forced to pay back money they received from the insurance company for different reasons. This is called recourse. Here the clerk describes how this process works",
            "Insurance"
        );
        AddModel(
            "Credit scoring",
            "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/scoring.bpmn",
            "afed6928c5c0498907d2ae5d1290b73baecbed89b07318a8f252b590b276456b",
            "A credit protection agency allows customers to query a credit rating for persons via a technical interface.",
            "Finance"
        );
        AddModel(
            "Self-service restaurant",
            "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/restaurant.bpmn",
            "b300e7942d96b6d3a97f6f9a638ab4181c43f0aea84405de558b4624126a095e",
            "A self-service restaurant is under chaotic conditions. Guests place their order at the till and receive their meals on call from the kitchen. As the restaurant is very popular, the processes need to be adapted to the increasing visitor numbers. In future, guests should only be in touch with one member of staff for their order. The chef should purely be concentrating on preparing the meals. Buzzers will be introduced to signalise to customers when their order has been completed.",
            "Public Catering"
        );
    }

    function SetPermission(address _User, bool _Permission) public {
        if (msg.sender == Owner && _User != Owner) {
            Permissions[_User] = _Permission;
        }
    }

    function GivePermission(address _User) public {
        SetPermission(_User, true);
    }

    function RevokePermission(address _User) public {
        SetPermission(_User, false);
    }

    function CheckPermission(address _User) public view returns (bool) {
        return Permissions[_User];
    }

    function CheckMyPermission() public view returns (bool) {
        return Permissions[msg.sender];
    }

    function AddModel(
        string memory _Title,
        string memory _Link,
        string memory _Hash,
        string memory _Annotation,
        string memory _Industry
    ) public {
        require(Permissions[msg.sender]);

        ModelRecord memory _Model = ModelRecord(
            _Title,
            _Link,
            _Hash,
            _Annotation,
            _Industry,
            block.timestamp
        );

        Models.push(_Model);
        ModelsCount++;
    }

    function ReadModels() public view returns (ModelRecord[] memory) {
        return Models;
    }

    function GetModelsCount() public view returns (uint256) {
        return ModelsCount;
    }
}