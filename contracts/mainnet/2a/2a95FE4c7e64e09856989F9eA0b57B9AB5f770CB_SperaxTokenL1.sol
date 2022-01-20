// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./L1CustomGateway.sol";
import "./L1GatewayRouter.sol";
import "./ICustomToken.sol";
import "./ISperaxToken.sol";

contract SperaxTokenL1 is ERC20, Ownable, ICustomToken {
    using SafeERC20 for IERC20;
    address public spaAddress;
    address public bridge;
    address public router;
    bool private shouldRegisterGateway;
    event ArbitrumGatewayRouterChanged(address newBridge, address newRouter);
    event SPAaddressUpdated(address oldSPA, address newSPA);

    modifier onlyGateway() {
        require(_msgSender() == bridge, "ONLY_GATEWAY");
        _;
    }

    constructor(string memory name_, string memory symbol_, address _spaAddress, address _bridge, address _router) ERC20(name_, symbol_) public {
        spaAddress = _spaAddress;
        bridge = _bridge;
        router = _router;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override(ERC20, ICustomToken) returns (bool) {
        return ERC20.transferFrom(sender, recipient, amount);
    }

    function balanceOf(address account) public view override(ERC20, ICustomToken) returns (uint256) {
        return ERC20.balanceOf(account);
    }

    /**
     * @dev mint SperaxTokenL1
     */
    function mint(uint256 amount) external {
        ISperaxToken(spaAddress).burnFrom(_msgSender(), amount);
        _mint(_msgSender(), amount);
    }

    /**
     * @dev burn SperaxTokenL1
     */
    function burn(uint256 amount) external {
        ISperaxToken(spaAddress).mintForUSDs(_msgSender(), amount);
        _burn(_msgSender(), amount);
    }

    /**
     * @dev mint SPA when user withdraw from Arbitrum L2
     */
    function bridgeMint(address account, uint256 amount) onlyGateway external {
        ISperaxToken(spaAddress).mintForUSDs(account, amount);
    }

    // Arbitrum
    /// @dev we only set shouldRegisterGateway to true when in `registerTokenOnL2`
    function isArbitrumEnabled() external view override returns (uint8) {
        require(shouldRegisterGateway, "NOT_EXPECTED_CALL");
        return uint8(0xa4b1);
    }

    /**
     * @notice change the arbitrum bridge and router address
     * @dev normally this function should not be called
     * @param newBridge the new bridge address
     * @param newRouter the new router address
     */
    function changeArbToken(address newBridge, address newRouter) external onlyOwner {
        bridge = newBridge;
        router = newRouter;
        emit ArbitrumGatewayRouterChanged(bridge, router);
    }

    function changeSpaAddress(address newSPA) external onlyOwner {
        emit SPAaddressUpdated(spaAddress, newSPA);
        spaAddress = newSPA;
    }

    function registerTokenOnL2(
        address l2CustomTokenAddress,
        uint256 maxSubmissionCostForCustomBridge,
        uint256 maxSubmissionCostForRouter,
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 valueForGateway,
        uint256 valueForRouter,
        address creditBackAddress
    ) external payable onlyOwner override {
        // we temporarily set `shouldRegisterGateway` to true for the callback in registerTokenToL2 to succeed
        bool prev = shouldRegisterGateway;
        shouldRegisterGateway = true;

        L1CustomGateway(bridge).registerTokenToL2{value:valueForGateway}(
            l2CustomTokenAddress,
            maxGas,
            gasPriceBid,
            maxSubmissionCostForCustomBridge,
            creditBackAddress
        );

        L1GatewayRouter(router).setGateway{value:valueForRouter}(
            bridge,
            maxGas,
            gasPriceBid,
            maxSubmissionCostForRouter,
            creditBackAddress
        );

        shouldRegisterGateway = prev;
    }
}