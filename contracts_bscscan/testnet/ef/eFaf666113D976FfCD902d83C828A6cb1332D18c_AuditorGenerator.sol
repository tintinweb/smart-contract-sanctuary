// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./IFactory.sol";
import "./ISettings.sol";

interface IRequestGenerator {
    function createRequest(address _client, address[] memory _contracts)
        external;
}

contract Auditor {
    IFactory factory;
    ISettings settings;
    IRequestGenerator requestGenerator;
    address auditorGenerator;

    bool public isCertified;
    address public owner;
    string public companyName;

    address[] public audits;

    constructor(address _factory, address _settings) {
        owner = 0x000000000000000000000000000000000000dEaD;
        factory = IFactory(_factory);
        requestGenerator = IRequestGenerator(
            factory.getGenerator(IFactory.GENERATOR.REQUEST)
        );
        settings = ISettings(_settings);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    modifier onlyActive() {
        require(
            owner != 0x000000000000000000000000000000000000dEaD,
            "AUDITOR IS NOT ACTIVE"
        );
        _;
    }

    function clientRequestsAudit(address[] calldata _contracts) external onlyActive {
        require(
            _contracts.length <=
                settings.getMaxLength(ISettings.MAX_LENGTH.CONTRACTS),
            "MAX CONTRACTS LIMIT REACHED"
        );
        requestGenerator.createRequest(msg.sender, _contracts);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT AUDIT OWNER");
        _;
    }

    function init(address _owner, string memory _companyName) external {
        require(
            msg.sender == factory.getGenerator(IFactory.GENERATOR.AUDITOR),
            "UNAUTHORIZED"
        );
        auditorGenerator = msg.sender;
        owner = _owner;
        companyName = _companyName;
    }

    function updateAuditorInfos(string memory _companyName) external onlyOwner {
        require(
            bytes(_companyName).length <=
                settings.getMaxLength(ISettings.MAX_LENGTH.COMPANY_NAME),
            "COMPANY NAME MAX LENGTH"
        );
        companyName = _companyName;
    }

    function transferOwnership(address _auditorOwner) external onlyOwner {
        owner = _auditorOwner;
    }

    function closeAuditor() external onlyOwner {
        owner = 0x000000000000000000000000000000000000dEaD;
        factory.unregisterAuditor(isCertified);
    }

    modifier onlyAdmin() {
        require(msg.sender == settings.getAdminAddress(), "NOT ADMIN");
        _;
    }

    function setIsCertified(bool _isCertified) external onlyAdmin {
        if (isCertified != _isCertified) {
            factory.updateCertifiedAuditor(_isCertified);
        }
        isCertified = _isCertified;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./Auditor.sol";
import "./ISettings.sol";
import "./IFactory.sol";

contract AuditorGenerator {
    ISettings settings;
    IFactory factory;

    constructor(address _factory, address _settings) {
        factory = IFactory(_factory);
        settings = ISettings(_settings);
    }

    function createAuditor(string calldata _companyName) external {
        require(
            bytes(_companyName).length <=
                settings.getMaxLength(ISettings.MAX_LENGTH.COMPANY_NAME),
            "COMPANY NAME TOO LONG"
        );

        Auditor newAuditor = new Auditor(
            address(factory),
            address(settings)
        );

        newAuditor.init(msg.sender, _companyName);

        factory.registerAuditor(address(newAuditor));
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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface ISettings {
  enum MAX_LENGTH {
      COMPANY_NAME,
      URL,
      CONTRACTS
  }

  function getMaxLength(MAX_LENGTH _index) external view returns (uint256);

  function getAuditDeliveryFeesPercentage() external view returns (uint256);

  function getAdminAddress() external view returns (address);
}