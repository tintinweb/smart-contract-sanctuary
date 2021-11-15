// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

import "./interfaces/ITemplateLauncher.sol";

contract MesaFactory {
    event FactoryInitialized(
        address feeManager,
        address feeTo,
        address templateManager,
        address templateLauncher,
        uint256 templateFee,
        uint256 feeNumerator,
        uint256 saleFee
    );

    event TemplateLaunched(address indexed template, uint256 templateId);
    event SetFeeTo(address indexed feeTo);
    event SetFeeNumerator(uint256 indexed feeNumerator);
    event SetSaleFee(uint256 indexed saleFee);
    event SetTemplateFee(uint256 indexed templateFee);
    event SetFeeManager(address indexed feeManager);
    event SetTemplateManager(address indexed templateManager);
    event SetTemplateLauncher(address indexed templateLauncher);

    uint256 public immutable feeDenominator = 1000;
    uint256 public feeNumerator;
    uint256 public saleFee;
    address public feeTo;
    address public feeManager;
    address public templateManager;
    address public templateLauncher;
    uint256 public templateFee;
    address[] public allSales;
    uint256 public templateId;
    bool initalized = false;

    constructor() public {}

    /// @dev setup function to initialize the Mesa Factory
    /// @param _feeManager address that is allowed to update fees
    /// @param _feeTo address that receives fees
    /// @param _templateManager address that is allowed to manage templates
    /// @param _templateLauncher address of the template launcher used to launch projects
    /// @param _templateFee fixed amount of native currency (ETH) to be paid for adding a template
    /// @param _feeNumerator fee that is token on depositing tokens
    /// @param _saleFee fixed amount of native currency (ETH) to be paid for launch a project
    function initalize(
        address _feeManager,
        address _feeTo,
        address _templateManager,
        address _templateLauncher,
        uint256 _templateFee,
        uint256 _feeNumerator,
        uint256 _saleFee
    ) public {
        require(!initalized, "MesaFactory: ALREADY_INITIALIZED");
        feeManager = _feeManager;
        feeTo = _feeTo;
        feeNumerator = _feeNumerator;
        templateManager = _templateManager;
        templateLauncher = _templateLauncher;
        templateFee = _templateFee;
        saleFee = _saleFee;

        emit FactoryInitialized(
            _feeManager,
            _feeTo,
            _templateManager,
            _templateLauncher,
            _templateFee,
            _feeNumerator,
            _saleFee
        );
    }

    /// @dev function to launch a template on Mesa
    /// @param _templateId template to be deployed
    /// @param _data encoded template parameters
    function launchTemplate(uint256 _templateId, bytes calldata _data)
        external
        payable
        returns (address newSale)
    {
        newSale = ITemplateLauncher(templateLauncher).launchTemplate.value(msg.value)(
            _templateId,
            _data
        );
        emit TemplateLaunched(newSale, _templateId);
        allSales.push(newSale);
    }

    /// @dev governance function to change the fee recipient
    /// @param _feeTo new address that receives fees
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeManager, "MesaFactory: FORBIDDEN");
        feeTo = _feeTo;
        emit SetFeeTo(_feeTo);
    }

    /// @dev governance function to change the fee
    /// @param _feeNumerator new fee numerator
    function setFeeNumerator(uint256 _feeNumerator) external {
        require(msg.sender == feeManager, "MesaFactory: FORBIDDEN");
        feeNumerator = _feeNumerator;
        emit SetFeeNumerator(_feeNumerator);
    }

    /// @dev governance function to change the sale fee
    /// @param _saleFee new sale fee amount
    function setSaleFee(uint256 _saleFee) external {
        require(msg.sender == feeManager, "MesaFactory: FORBIDDEN");
        saleFee = _saleFee;
        emit SetSaleFee(_saleFee);
    }

    /// @dev governance function to change the template fee
    /// @param _templateFee new template fee amount
    function setTemplateFee(uint256 _templateFee) external {
        require(msg.sender == feeManager, "MesaFactory: FORBIDDEN");
        templateFee = _templateFee;
        emit SetTemplateFee(_templateFee);
    }

    /// @dev governance function to change the feeManager
    /// @param _feeManager new address allowed to change fees
    function setFeeManager(address _feeManager) external {
        require(msg.sender == feeManager, "MesaFactory: FORBIDDEN");
        feeManager = _feeManager;
        emit SetFeeManager(_feeManager);
    }

    /// @dev governance function to change the templateManager
    /// @param _templateManager new address allowed to change templates
    function setTemplateManager(address _templateManager) external {
        require(msg.sender == templateManager, "MesaFactory: FORBIDDEN");
        templateManager = _templateManager;
        emit SetTemplateManager(_templateManager);
    }

    /// @dev governance function to replace the templateLauncher
    /// @param _templateLauncher new address of templateLauncher
    function setTemplateLauncher(address _templateLauncher) external {
        require(msg.sender == templateManager, "MesaFactory: FORBIDDEN");
        templateLauncher = _templateLauncher;
        emit SetTemplateLauncher(_templateLauncher);
    }

    function numberOfSales() external view returns (uint256) {
        return allSales.length;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

interface ITemplateLauncher {
    function launchTemplate(uint256 _templateId, bytes calldata _data)
        external
        payable
        returns (address newAuction);
}

