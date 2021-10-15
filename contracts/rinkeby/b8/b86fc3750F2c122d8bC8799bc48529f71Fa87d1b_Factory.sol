// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ITokenBaseDeployer.sol";
import "./interfaces/INFTBaseDeployer.sol";
import "./interfaces/IFixedPriceDeployer.sol";

contract Factory {
    address private tokenBaseDeployer;
    address private nftBaseDeployer;
    address private fixedPriceDeployer;

    constructor(
        address _tokenBaseDeployer,
        address _nftBaseDeployer,
        address _fixedPriceDeployer
    ) {
        tokenBaseDeployer = _tokenBaseDeployer;
        nftBaseDeployer = _nftBaseDeployer;
        fixedPriceDeployer = _fixedPriceDeployer;
    }

    event TokenBaseDeploy(
        address indexed _addr,  //address of deployed NFT PASS contract
        string _name,
        string _symbol,
        string _bURI,       //baseuri of NFT PASS
        address _erc20,     
        uint256 _rate
    );
    event NFTBaseDeploy(
        address indexed _addr,  
        string _name,
        string _symbol,
        string _bURI,       
        address _erc721
    );
    event FixedPriceDeploy(
        address indexed _addr, 
        string _name,
        string _symbol,
        string _bURI,       
        address _erc20,
        uint256 _rate,
        uint256 _maxSupply
    );

    function tokenBaseDeploy(
        string memory _name,
        string memory _symbol,
        string memory _bURI,
        address _erc20,
        uint256 _rate
    ) public payable {
        ITokenBaseDeployer factory = ITokenBaseDeployer(tokenBaseDeployer);
        //return the address of deployed NFT PASS contract
        address addr = factory.deployTokenBase(_name, _symbol, _bURI, _erc20, _rate);  
        emit TokenBaseDeploy(addr, _name, _symbol, _bURI, _erc20, _rate);
    }

    function nftBaseDeploy(
        string memory _name,
        string memory _symbol,
        string memory _bURI,
        address _erc721
    ) public payable {
        INFTBaseDeployer factory = INFTBaseDeployer(nftBaseDeployer);
        address addr = factory.deployNFTBase(_name, _symbol, _bURI, _erc721);
        emit NFTBaseDeploy(addr, _name, _symbol, _bURI, _erc721);
    }

    function fixedPriceDeploy(
        string memory _name,
        string memory _symbol,
        string memory _bURI,
        address _erc20,
        uint256 _rate,
        uint256 _maxSupply
    ) public payable {
        IFixedPriceDeployer factory = IFixedPriceDeployer(fixedPriceDeployer);
        address addr = factory.deployFixedPrice(_name, _symbol, _bURI, _erc20, _rate, _maxSupply);
        emit FixedPriceDeploy(addr, _name, _symbol, _bURI, _erc20, _rate, _maxSupply);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITokenBaseDeployer {
    function deployTokenBase(
        string memory _name,
        string memory _symbol,
        string memory _bURI,
        address _erc20,
        uint256 _rate
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INFTBaseDeployer {
    function deployNFTBase(
        string memory _name,
        string memory _symbol,
        string memory _bURI,
        address _erc721
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFixedPriceDeployer {
    function deployFixedPrice(
        string memory _name,
        string memory _symbol,
        string memory _bURI,
        address _erc20,
        uint256 _rate,
        uint256 _maxSupply
    ) external returns (address);
}