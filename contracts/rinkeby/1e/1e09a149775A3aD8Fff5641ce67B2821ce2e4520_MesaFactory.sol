// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

import "./interfaces/ITemplateLauncher.sol";

contract MesaFactory {
    event FactoryInitialized(
        address feeManager,
        address feeTo,
        address templateManager,
        address templateLauncher,
        uint256 feeNumerator,
        uint256 auctionFee
    );

    event TemplateLaunched(address indexed auction, uint256 templateId);
    event SetFeeTo(address indexed feeTo);
    event SetFeeNumerator(uint256 indexed feeNumerator);
    event SetAuctionFee(uint256 indexed auctionFee);
    event SetFeeManager(address indexed feeManager);
    event SetTemplateManager(address indexed templateManager);
    event SetTemplateLauncher(address indexed templateLauncher);

    uint256 public immutable feeDenominator = 1000;
    uint256 public feeNumerator;
    uint256 public auctionFee;
    address public feeTo;
    address public feeManager;
    address public templateManager;
    address public templateLauncher;
    address[] public allAuctions;
    uint256 public templateId;
    bool initalized = false;

    constructor() public {}

    function initalize(
        address _feeManager,
        address _feeTo,
        address _templateManager,
        address _templateLauncher,
        uint256 _feeNumerator,
        uint256 _auctionFee
    ) public {
        require(!initalized, "MesaFactory: ALREADY_INITIALIZED");
        feeManager = _feeManager;
        feeTo = _feeTo;
        feeNumerator = _feeNumerator;
        templateManager = _templateManager;
        templateLauncher = _templateLauncher;
        auctionFee = _auctionFee;

        emit FactoryInitialized(
            _feeManager,
            _feeTo,
            _templateManager,
            _templateLauncher,
            _feeNumerator,
            _auctionFee
        );
    }

    function launchTemplate(uint256 _templateId, bytes calldata _data)
        external
        payable
        returns (address newAuction)
    {
        newAuction = ITemplateLauncher(templateLauncher).launchTemplate(
            _templateId,
            _data
        );
        emit TemplateLaunched(newAuction, _templateId);
        allAuctions.push(newAuction);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeManager, "MesaFactory: FORBIDDEN");
        feeTo = _feeTo;
        emit SetFeeTo(_feeTo);
    }

    function setFeeNumerator(uint256 _feeNumerator) external {
        require(msg.sender == feeManager, "MesaFactory: FORBIDDEN");
        feeNumerator = _feeNumerator;
        emit SetFeeNumerator(_feeNumerator);
    }

    function setAuctionFee(uint256 _auctionFee) external {
        require(msg.sender == feeManager, "MesaFactory: FORBIDDEN");
        auctionFee = _auctionFee;
        emit SetAuctionFee(_auctionFee);
    }

    function setFeeManager(address _feeManager) external {
        require(msg.sender == feeManager, "MesaFactory: FORBIDDEN");
        feeManager = _feeManager;
        emit SetFeeManager(_feeManager);
    }

    function setTemplateManager(address _templateManager) external {
        require(msg.sender == templateManager, "MesaFactory: FORBIDDEN");
        templateManager = _templateManager;
        emit SetTemplateManager(_templateManager);
    }

    function setTemplateLauncher(address _templateLauncher) external {
        require(msg.sender == templateManager, "MesaFactory: FORBIDDEN");
        templateLauncher = _templateLauncher;
        emit SetTemplateLauncher(_templateLauncher);
    }

    function numberOfAuctions() external view returns (uint256) {
        return allAuctions.length;
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