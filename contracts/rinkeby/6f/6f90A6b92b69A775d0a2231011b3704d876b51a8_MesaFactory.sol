// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

import "./shared/interfaces/ITemplateLauncher.sol";

contract MesaFactory {
    event FactoryInitialized(
        address feeManager,
        address feeTo,
        address templateManager,
        uint256 templateFee,
        uint256 feeNumerator,
        uint256 saleFee
    );
    event TemplateLaunched(address indexed template, uint256 templateId);
    event FeeToUpdated(address indexed feeTo);
    event FeeNumeratorUpdated(uint256 indexed feeNumerator);
    event SaleFeeUpdated(uint256 indexed saleFee);
    event TemplateFeeUpdated(uint256 indexed templateFee);
    event FeeManagerUpdated(address indexed feeManager);
    event TemplateManagerUpdated(address indexed templateManager);
    event TemplateLauncherUpdated(address indexed templateLauncher);

    uint256 public immutable feeDenominator = 1000;
    uint256 public feeNumerator;
    uint256 public saleFee;
    address public feeTo;
    address public feeManager;
    address public templateManager;
    address public templateLauncher;
    uint256 public templateFee;

    address[] public allTemplates;
    uint256 public templateId;
    bool public initialized = false;

    modifier isTemplateManager {
        require(msg.sender == templateManager, "MesaFactory: FORBIDDEN");
        _;
    }

    modifier isFeeManager {
        require(msg.sender == feeManager, "MesaFactory: FORBIDDEN");
        _;
    }

    /// @dev setup function to initialize the Mesa Factory
    /// @param _feeManager address that is allowed to update fees
    /// @param _feeTo address that receives fees
    /// @param _templateManager address that is allowed to manage templates
    /// @param _templateFee fixed amount of native currency (ETH) to be paid for adding a template
    /// @param _feeNumerator fee that is token on depositing tokens
    /// @param _saleFee fixed amount of native currency (ETH) to be paid for launch a project
    constructor(
        address _feeManager,
        address _feeTo,
        address _templateManager,
        uint256 _templateFee,
        uint256 _feeNumerator,
        uint256 _saleFee
    ) public {
        feeManager = _feeManager;
        feeTo = _feeTo;
        feeNumerator = _feeNumerator;
        templateManager = _templateManager;
        templateFee = _templateFee;
        saleFee = _saleFee;
        initialized = true;

        emit FactoryInitialized(
            _feeManager,
            _feeTo,
            _templateManager,
            _templateFee,
            _feeNumerator,
            _saleFee
        );
    }

    /// @dev function to launch a template on Mesa
    /// @param _templateId template to be deployed
    /// @param _data encoded template parameters
    /// @param _metaData ipfsHash pointing to the metadata
    function launchTemplate(
        uint256 _templateId,
        bytes calldata _data,
        string calldata _metaData
    ) external payable returns (address newTemplate) {
        newTemplate = ITemplateLauncher(templateLauncher).launchTemplate{
            value: msg.value
        }(_templateId, _data, _metaData, msg.sender);
        allTemplates.push(newTemplate);
        emit TemplateLaunched(newTemplate, _templateId);
    }

    /// @dev governance function to change the fee recipient
    /// @param _feeTo new address that receives fees
    function setFeeTo(address _feeTo) external isFeeManager {
        feeTo = _feeTo;
        emit FeeToUpdated(_feeTo);
    }

    /// @dev governance function to change the fee
    /// @param _feeNumerator new fee numerator
    function setFeeNumerator(uint256 _feeNumerator) external isFeeManager {
        feeNumerator = _feeNumerator;
        emit FeeNumeratorUpdated(_feeNumerator);
    }

    /// @dev governance function to change the sale fee
    /// @param _saleFee new sale fee amount
    function setSaleFee(uint256 _saleFee) external isFeeManager {
        saleFee = _saleFee;
        emit SaleFeeUpdated(_saleFee);
    }

    /// @dev governance function to change the template fee
    /// @param _templateFee new template fee amount
    function setTemplateFee(uint256 _templateFee) external isFeeManager {
        templateFee = _templateFee;
        emit TemplateFeeUpdated(_templateFee);
    }

    /// @dev governance function to change the feeManager
    /// @param _feeManager new address allowed to change fees
    function setFeeManager(address _feeManager) external isFeeManager {
        feeManager = _feeManager;
        emit FeeManagerUpdated(_feeManager);
    }

    /// @dev governance function to change the templateManager
    /// @param _templateManager new address allowed to change templates
    function setTemplateManager(address _templateManager)
        external
        isTemplateManager
    {
        templateManager = _templateManager;
        emit TemplateManagerUpdated(_templateManager);
    }

    /// @dev governance function to replace the templateLauncher
    /// @param _templateLauncher new address of templateLauncher
    function setTemplateLauncher(address _templateLauncher)
        external
        isTemplateManager
    {
        templateLauncher = _templateLauncher;
        emit TemplateLauncherUpdated(_templateLauncher);
    }

    function numberOfTemplates() external view returns (uint256) {
        return allTemplates.length;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

interface ITemplateLauncher {
    function launchTemplate(
        uint256 _templateId,
        bytes calldata _data,
        string calldata _metaDataContentHash,
        address _templateDeployer
    ) external payable returns (address newSale);

    function participantListLaucher() external view returns (address);
}

