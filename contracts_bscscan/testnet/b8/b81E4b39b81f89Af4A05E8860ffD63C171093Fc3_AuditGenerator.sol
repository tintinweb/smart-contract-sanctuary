// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./IFactory.sol";

contract Audit {

    IFactory public factory;
    address public auditGenerator;

    struct Issues {
        uint256 critical;
        uint256 medium;
        uint256 low;
    }

    address public request;
    address[] public contracts;
    address public client;
    address public auditor;
    string public auditUrl;
    Issues public issues;

    constructor(
        address _factory
    ) {
        factory = IFactory(_factory);
    }

    function getContracts() external view returns (address[] memory) {
        return contracts;
    }

    function init(
        address _request,
        address _auditor,
        address _client,
        address[] calldata _contracts,
        uint256[3] calldata _issues,
        string memory _auditUrl
    ) external {
        require(msg.sender == factory.getGenerator(IFactory.GENERATOR.AUDIT));
        auditGenerator = msg.sender;
        request = _request;
        auditor = _auditor;
        client = _client;
        contracts = _contracts;
        issues.low = _issues[0];
        issues.medium = _issues[1];
        issues.critical = _issues[2];
        auditUrl = _auditUrl;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./Audit.sol";
import "./IFactory.sol";

contract AuditGenerator {
    IFactory factory;

    constructor(address _factoryAddress) {
        factory = IFactory(_factoryAddress);
    }

    function createAudit(
        address _auditor,
        address _client,
        address[] calldata _contracts,
        uint256[3] calldata _issues,
        string calldata _auditUrl
    ) external {
        require(factory.doesRequestExist(msg.sender));

        Audit newAudit = new Audit(address(factory));

        newAudit.init(msg.sender, _auditor, _client, _contracts, _issues, _auditUrl);

        factory.registerAudit(address(newAudit), _contracts);
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface IFactory {
    enum GENERATOR {
        AUDITOR,
        REQUEST,
        AUDIT
    }

    function getGenerator(GENERATOR _generator) external view returns (address);

    function getAuditByContractAddress(address _contract)
        external
        view
        returns (address);

    function doesRequestExist(address _request) external view returns (bool);

    function doesAuditorExist(address _auditor) external view returns (bool);

    function registerAudit(address _audit, address[] memory _contracts)
        external;

    function registerAuditor(address _auditor) external;

    function unregisterAuditor(bool _isCertified) external;

    function registerRequest(address _request) external;

    function unregisterRequest() external;

    function updateCertifiedAuditor(bool _isCertified) external;
}