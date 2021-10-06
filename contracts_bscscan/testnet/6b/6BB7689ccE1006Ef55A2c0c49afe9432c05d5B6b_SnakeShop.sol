//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./IBEP20.sol";
import "./IRouter.sol";
import "./IFactory.sol";

interface IStakingManager {
    function processStake(address token, uint256 amount, address user) external;
}

contract SnakeShop is Ownable {
    IStakingManager public stakingManager;
    IRouter public router;
    IFactory public factory;

    mapping(address => bool) public allowedTokens;
    mapping(uint256 => uint256) public snakePrices;
    mapping(uint256 => uint256) public artifactPrices;

    address public swapToken;

    constructor(address router_, address swapToken_, address factory_, address stakingManager_) {
        require(Address.isContract(stakingManager_), "stakingManager_ is not a contract");
        require(Address.isContract(router_), "router_ is not a contract");
        require(Address.isContract(swapToken_), "swapToken_ is not a contract");
        require(Address.isContract(factory_), "factory_ is not a contract");

        stakingManager = IStakingManager(stakingManager_);
        router = IRouter(router_);
        swapToken = swapToken_;
        factory = IFactory(factory_);
    }

    function updateAllowedTokens(address token, bool value) external onlyOwner {
        require(token != address(0), "SnakeShop: token address is equal to zero");
        allowedTokens[token] = value;
    }

    function updateStakingManager(address stakingManager_) external onlyOwner {
        require(Address.isContract(stakingManager_), "stakingManager_ is not a contract");
        stakingManager = IStakingManager(stakingManager_);
    }

    function updateSnakePrices(uint256 id, uint256 price) external onlyOwner {
        snakePrices[id] = price;
    }

    function updateArtifactPrices(uint256 id, uint256 price) external onlyOwner {
        artifactPrices[id] = price;
    }

    function buySnake(address token, uint256 snakeId) external {
        require(allowedTokens[token], "SnakeShop: not allowed token for buying snakes");
        uint snakePrice = snakePrices[snakeId];
        require(snakePrice != 0, "SnakeShop: snake not found");
        _processBuying(token, snakePrice);
    }

    function buyArtefact(address token, uint artifactId) external {
        require(allowedTokens[token], "SnakeShop: not allowed token for buying artifacts");
        uint artifactPrice = artifactPrices[artifactId];
        require(artifactPrice != 0, "SnakeShop: artifact not found");
        _processBuying(token, artifactPrice);
    }

    function _processBuying(address token, uint price) internal {
        require(factory.getPair(token, swapToken) != address(0), "SnakeShop: no pair with swap token");
        address[] memory path = new address[](2);
        path[0] = swapToken;
        path[1] = token;
        uint256 amount = router.getAmountsIn(price, path)[0];
        stakingManager.processStake(token, amount, _msgSender());
    }
}