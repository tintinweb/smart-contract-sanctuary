pragma solidity 0.7.4;

/* solhint-disable indent */

// This contract manages the membership rules
// it is responsible for storing pod rules, and validating rule compliance

contract RuleManager {
    // Rules
    struct Rule {
        address contractAddress;
        bytes4 functionSignature;
        bytes32[5] functionParams;
        uint256 comparisonLogic;
        uint256 comparisonValue;
        bool isFinalized;
    }

    address controller;
    mapping(uint256 => Rule) public rulesByPod;

    event UpdateRule(
        uint256 podId,
        address contractAddress,
        bytes4 functionSignature,
        bytes32[5] functionParams,
        uint256 comparisonLogic,
        uint256 comparisonValue
    );

    constructor() {
        controller = msg.sender;
    }

    /**
     * @param _controller The account address to be assigned as controller
     */
    function updateController(address _controller) external {
        require(_controller != address(0), "Invalid gnosisMaster address");
        require(controller == msg.sender, "!controller");
        controller = _controller;
    }

    function setPodRule(
        uint256 _podId,
        address _contractAddress,
        bytes4 _functionSignature,
        bytes32[5] memory _functionParams,
        uint256 _comparisonLogic,
        uint256 _comparisonValue
    ) external {
        require(controller == msg.sender, "!controller");
        rulesByPod[_podId] = Rule(
            _contractAddress,
            _functionSignature,
            _functionParams,
            _comparisonLogic,
            _comparisonValue,
            false
        );
    }

    /**
     * @param _podId The id number of the pod
     */
    function finalizeRule(uint256 _podId) external {
        require(controller == msg.sender, "!controller");
        rulesByPod[_podId].isFinalized = true;

        emit UpdateRule(
            _podId,
            rulesByPod[_podId].contractAddress,
            rulesByPod[_podId].functionSignature,
            rulesByPod[_podId].functionParams,
            rulesByPod[_podId].comparisonLogic,
            rulesByPod[_podId].comparisonValue
        );
    }

    /**
     * @param _podId The id number of the pod
     */
    function hasRules(uint256 _podId) external view returns (bool) {
        Rule memory currentRule = rulesByPod[_podId];
        return (currentRule.contractAddress != address(0));
    }

    /**
     * @param _podId The id number of the pod
     * @param _user The account address of a pod member
     */
    function isRuleCompliant(uint256 _podId, address _user)
        external
        view
        returns (bool)
    {
        Rule memory currentRule = rulesByPod[_podId];

        // if there are no rules return true
        if (currentRule.contractAddress != address(0)) return true;

        // check function params for keywords
        for (uint256 i = 0; i < currentRule.functionParams.length; i++) {
            if (currentRule.functionParams[i] == bytes32("MEMBER")) {
                currentRule.functionParams[i] = bytes32(uint256(_user));
            }
        }

        (bool success, bytes memory result) = currentRule
            .contractAddress
            .staticcall(
                abi.encodePacked(
                    currentRule.functionSignature,
                    currentRule.functionParams[0],
                    currentRule.functionParams[1],
                    currentRule.functionParams[2],
                    currentRule.functionParams[3],
                    currentRule.functionParams[4]
                )
            );
        require(success, "Rule Transaction Failed");

        if (currentRule.comparisonLogic == 0) {
            return toUint256(result) == currentRule.comparisonValue;
        }
        if (currentRule.comparisonLogic == 1) {
            return toUint256(result) > currentRule.comparisonValue;
        }
        if (currentRule.comparisonLogic == 2) {
            return toUint256(result) < currentRule.comparisonValue;
        }
        // if invalid rule it is impossible to be compliant
        return false;
    }

    function toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }
}

