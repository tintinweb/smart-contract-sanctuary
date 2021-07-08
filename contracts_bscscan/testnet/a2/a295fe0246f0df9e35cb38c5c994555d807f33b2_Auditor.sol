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