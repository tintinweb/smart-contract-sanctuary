// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./interfaces/IERC20.sol";

interface IMisoTokenFactory {
    function createToken(
        uint256 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address token);
}

interface IPointList {
    function deployPointList(
        address _listOwner,
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external payable returns (address pointList);
}

interface IMisoLauncher {
    function createLauncher(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address newLauncher);
}

interface IMisoMarket {
    function createMarket(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address newMarket);
}

contract MISOReceipe {
    IMisoTokenFactory public misoTokenFactory;
    IPointList public pointListFactory;
    IMisoLauncher public misoLauncher;
    IMisoMarket public misoMarket;
    address public factory;

    constructor(
        IMisoTokenFactory _misoTokenFactory,
        IPointList _pointListFactory,
        IMisoLauncher _misoLauncher,
        IMisoMarket _misoMarket,
        address _factory
    ) public {
        misoTokenFactory = _misoTokenFactory;
        pointListFactory = _pointListFactory;
        misoLauncher = _misoLauncher;
        misoMarket = _misoMarket;
        factory = _factory;
    }

    function prepareMiso(
        bytes memory tokenFactoryData,
        address[] memory _accounts,
        uint256[] memory _amounts,
        bytes memory marketData,
        bytes memory launcherData
    ) external payable {
        require(_accounts.length == _amounts.length, "!len");

        address token;
        uint256 totalSupply;
        {
            (
                uint256 _misoTokenFactoryTemplateId,
                string memory _name,
                string memory _symbol,
                uint256 _initialSupply
            ) = abi.decode(
                    tokenFactoryData,
                    (uint256, string, string, uint256)
                );

            token = misoTokenFactory.createToken(
                _misoTokenFactoryTemplateId,
                address(0),
                abi.encode(_name, _symbol, msg.sender, _initialSupply)
            );
            totalSupply = _initialSupply;
        }

        address pointList;
        if (_accounts.length != 0) {
            pointList = pointListFactory.deployPointList(
                msg.sender,
                _accounts,
                _amounts
            );
        }

        address newMarket;
        {
            (uint256 _marketTemplateId, bytes memory mData) = abi.decode(
                marketData,
                (uint256, bytes)
            );
            newMarket = misoMarket.createMarket(
                _marketTemplateId,
                token,
                totalSupply,
                address(0),
                abi.encode(
                    msg.sender,
                    token,
                    mData,
                    msg.sender,
                    pointList,
                    msg.sender
                )
            );
        }

        address newLauncher;
        {
            (
                uint256 _launcherTemplateId,
                uint256 _liquidityPercent,
                uint256 _locktime
            ) = abi.decode(launcherData, (uint256, uint256, uint256));
            newLauncher = misoLauncher.createLauncher(
                _launcherTemplateId,
                token,
                totalSupply,
                address(0),
                abi.encode(
                    newMarket,
                    factory,
                    msg.sender,
                    msg.sender,
                    _liquidityPercent,
                    _locktime
                )
            );
        }
    }
}

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}