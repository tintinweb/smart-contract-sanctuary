//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Allowable.sol";
import "./Address.sol";
import "./SafeBEP20.sol";
import "./IBEP20.sol";
import "./IBEP1155.sol";
import "./IRouter.sol";

contract ArtifactsShop is Allowable {
    using SafeBEP20 for IBEP20;

    IRouter public router;

    address public snakeToken;

    IBEP1155 public artifactsNFT;
    mapping(uint => uint) public artifactsPrices;
    
    address public custodian;
    address public artifactsOwner;

    mapping(address => bool) public allowedTokens;

    bool public useWeightedRates;
    mapping(address => uint) public weightedTokenNbuExchangeRates;

    event BuyArtifact(address indexed buyer, uint indexed artifactId, address indexed token, uint artifactCount, uint totalEquivalentPrice);
    event UpdateArtifactsOwner(address indexed newOwner);
    event UpdateArtifactConract(address indexed artifacts);
    event UpdateSnakeToken(address indexed token);
    event UpdateAllowedTokens(address indexed token, bool indexed isAllowed);
    event UpdateCustodian(address indexed newCustodian);
    event UpdateArtifactPrice(uint indexed id, uint price);

    event ToggleUseWeightedRates(bool indexed useWeightedRates);
    event UpdateTokenWeightedExchangeRate(address indexed token, uint newRate);
    event Rescue(address indexed receiver, uint amount);
    event RescueToken(address indexed receiver, address indexed token, uint amount);

    constructor(address _router, address _artifactsNFT, address _custodian, address _artifactsOwner) {
        require(Address.isContract(_artifactsNFT), "SnakeShop: _artifactsNFT is not a contract");
        require(Address.isContract(_router), "SnakeShop: _router is not a contract");

        artifactsNFT = IBEP1155(_artifactsNFT);
        router = IRouter(_router);
        custodian = _custodian;
        artifactsOwner = _artifactsOwner;
        useWeightedRates = true;
    }

    function buyArtifact(uint artifactId, address token, uint artifactCount) external {
        require(artifactCount > 0, "SnakeShop: Artifacts count must be greater than 0");
        require(allowedTokens[token], "SnakeShop: Buying artifacts for this token is not allowed");
        uint price = getArtifactPriceConverted(artifactId, token);
        require(price > 0, "SnakeShop: Artifact not found or no corresponding pair");
        
        uint finalPrice = price * artifactCount;
        IBEP20(token).safeTransferFrom(msg.sender, custodian, finalPrice);
        artifactsNFT.safeTransferFrom(artifactsOwner, msg.sender, artifactId, artifactCount, "0x");
        emit BuyArtifact(msg.sender, artifactId, token, artifactCount, finalPrice);
    }


    function getArtifactPriceConverted(uint id, address token) public view returns (uint equivalentAmount) {
        uint priceInSnake = getArtifactPrice(id);
        require(priceInSnake > 0, "SnakeShop: Artifact not found");
        
        if (!useWeightedRates) {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = snakeToken;
            equivalentAmount = router.getAmountsIn(priceInSnake, path)[0];
        } else {
            equivalentAmount = priceInSnake * 1e18 / weightedTokenNbuExchangeRates[token];
        }
    }

    function getArtifactPrice(uint id) public view returns (uint) {
        return artifactsPrices[id];
    }


    function rescue(address payable _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "SnakeShop: Cannot rescue to 0x0");
        require(_amount > 0, "SnakeShop: Cannot rescue 0");

        _to.transfer(_amount);
        emit Rescue(_to, _amount);
    }

    function rescue(address _to, IBEP20 _token, uint256 _amount) external onlyOwner {
        require(_to != address(0), "SnakeShop: Cannot rescue to 0x0");
        require(_amount > 0, "SnakeShop: Cannot rescue 0");

        _token.safeTransfer(_to, _amount);
        emit RescueToken(_to, address(_token), _amount);
    }
    
    function updateArtifactsOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "SnakeShop: newOwner can not be zero address");
        artifactsOwner = newOwner;
        emit UpdateArtifactsOwner(newOwner);
    }

    function updateArtifactConract(address _artifactsNFT) external onlyOwner {
        require(Address.isContract(_artifactsNFT), "StakingManager: _artifactsNFT is not a contract");
        artifactsNFT = IBEP1155(_artifactsNFT);
        emit UpdateArtifactConract(_artifactsNFT);
    }

    function updateSnakeToken(address token) external onlyOwner {
        require(Address.isContract(token), "SnakeShop: token is not a contract");
        snakeToken = token;
        emit UpdateSnakeToken(token);
    }

    function updateAllowedTokens(address token, bool isAllowed) external onlyOwner {
        require(Address.isContract(token), "SnakeShop: token is not a contract");
        allowedTokens[token] = isAllowed;
        emit UpdateAllowedTokens(token, isAllowed);
    }

    function updateCustodian(address newCustodian) external onlyOwner {
        require(newCustodian != address(0), "SnakeShop: newCustodian can not be zero address");
        custodian = newCustodian;
        emit UpdateCustodian(newCustodian);
    }

    function toggleUseWeightedRates() external onlyOwner {
        useWeightedRates = !useWeightedRates;
        emit ToggleUseWeightedRates(useWeightedRates);
    }

    function updateTokenWeightedExchangeRate(address token, uint rate) external onlyOwner {
        weightedTokenNbuExchangeRates[token] = rate;
        emit UpdateTokenWeightedExchangeRate(token, rate);
    }

    function updateArtifactPrice(uint id, uint price) external onlyOwner {
        artifactsPrices[id] = price;
    }
}