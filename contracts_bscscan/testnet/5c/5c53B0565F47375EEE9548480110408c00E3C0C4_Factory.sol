// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IAlphaDeployer.sol";
import "./interfaces/IBetaDeployer.sol";
import "./interfaces/IGammaDeployer.sol";
import "./interfaces/IDeltaDeployer.sol";

contract Factory {
    address private alphaDeployer;
    address private betaDeployer;
    address private gammaDeployer;
    address private deltaDeployer;

    constructor(
        address _alphaDeployer,
        address _betaDeployer,
        address _gammaDeployer,
        address _deltaDeployer
    ) {
        alphaDeployer = _alphaDeployer;
        betaDeployer = _betaDeployer;
        gammaDeployer = _gammaDeployer;
        deltaDeployer = _deltaDeployer;
    }

    event AlphaDeploy(
        address indexed _addr,
        uint256 indexed id,
        string _name,
        string _symbol,
        address _erc20,
        uint256 _rate
    );
    event BetaDeploy(
        address indexed _addr,
        uint256 indexed id,
        string _name,
        string _symbol,
        address _erc721
    );
    event GamaDeploy(
        address indexed _addr,
        uint256 indexed id,
        string _name,
        string _symbol,
        address _erc20,
        uint256 _rate
    );
    event DeltaDeploy(
        address indexed _addr,
        uint256 indexed id,
        string _name,
        string _symbol,
        address _erc20,
        uint256 _ownerRate,
        uint256 _startPrice,
        uint256 _totalSupply,
        address _incentiveAddress,
        uint256 _amount
    );

    function alphaDeploy(
        uint256 _id,
        string memory _name,
        string memory _symbol,
        address _erc20,
        uint256 _rate
    ) public payable {
        IAlphaDeployer factory = IAlphaDeployer(alphaDeployer);
        address addr = factory.deployAlpha(_name, _symbol, _erc20, _rate);
        emit AlphaDeploy(addr, _id, _name, _symbol, _erc20, _rate);
    }

    function betaDeploy(
        uint256 _id,
        string memory _name,
        string memory _symbol,
        address _erc721
    ) public payable {
        IBetaDeployer factory = IBetaDeployer(betaDeployer);
        address addr = factory.deployBeta(_name, _symbol, _erc721);
        emit BetaDeploy(addr, _id, _name, _symbol, _erc721);
    }

    function gammaDeploy(
        uint256 _id,
        string memory _name,
        string memory _symbol,
        address _erc20,
        uint256 _rate
    ) public payable {
        IGammaDeployer factory = IGammaDeployer(gammaDeployer);
        address addr = factory.deployGamma(_name, _symbol, _erc20, _rate);
        emit GamaDeploy(addr, _id, _name, _symbol, _erc20, _rate);
    }

    function deltaDeploy(
        uint256 _id,
        string memory _name,
        string memory _symbol,
        address _erc20,
        uint256 _ownerRate,
        uint256 _startPrice,
        uint256 _totalSupply,
        address _incentiveAddress,
        uint256 _amount
    ) public payable {
        IDeltaDeployer factory = IDeltaDeployer(deltaDeployer);
        address addr = factory.deployDelta(
            _name,
            _symbol,
            _erc20,
            _ownerRate,
            _startPrice,
            _totalSupply,
            _incentiveAddress,
            _amount
        );
        emit DeltaDeploy(
            addr,
            _id,
            _name,
            _symbol,
            _erc20,
            _ownerRate,
            _startPrice,
            _totalSupply,
            _incentiveAddress,
            _amount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAlphaDeployer {
    function deployAlpha(
        string memory _name,
        string memory _symbol,
        address _erc20,
        uint256 _rate
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBetaDeployer {
    function deployBeta(
        string memory _name,
        string memory _symbol,
        address _erc721
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGammaDeployer {
    function deployGamma(
        string memory _name,
        string memory _symbol,
        address _erc20,
        uint256 _rate
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDeltaDeployer {
    function deployDelta(
        string memory _name,
        string memory _symbol,
        address _erc20,
        uint256 _ownerRate,
        uint256 _startPrice,
        uint256 _totalSupply,
        address _incentiveAddress,
        uint256 _amount
    ) external returns (address);
}

