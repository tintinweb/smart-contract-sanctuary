// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

interface IERC20 { 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IFxERC20RootTunnel {
    function mapToken(address rootToken) external;
    function deposit(address rootToken, address user, uint256 amount, bytes memory data) external;
    function receiveMessage(bytes memory inputData) external;
}

interface IFxERC20ChildTunnel {
    function withdraw(address childToken, uint256 amount) external;
    function withdrawTo(address childToken, address receiver, uint256 amount) external;
}

contract FxCrossChainTransfer {
    IERC20 public immutable rootToken; 
    IFxERC20RootTunnel public immutable fxERC20RootTunnel;
    IFxERC20ChildTunnel public immutable fxERC20ChildTunnel;
    uint24 public immutable rootChainId;
    uint24 public immutable childChainId;

    constructor(
        IERC20 _rootToken,
        IFxERC20RootTunnel _fxERC20RootTunnel,
        IFxERC20ChildTunnel _fxERC20ChildTunnel,
        uint24 _rootChainId,
        uint24 _childChainId
    ) {
        rootToken = _rootToken;
        fxERC20RootTunnel = _fxERC20RootTunnel;
        fxERC20ChildTunnel = _fxERC20ChildTunnel;
        rootChainId = _rootChainId;
        childChainId = _childChainId;
    }

    modifier onlyRootChain() {
        require(block.chainid == rootChainId, "FxCrossChainTransfer: Only Root Chain");
        _;
    }

        modifier onlyChildChain() {
        require(block.chainid == childChainId, "FxCrossChainTransfer: Only Child Chain");
        _;
    }

    function mapToken(address fxRootToken) external onlyRootChain{
        fxERC20RootTunnel.mapToken(fxRootToken);
    }

     function deposit(
        address fxRootToken,
        address user,
        uint256 amount,
        bytes memory data
    ) external onlyRootChain {
        fxERC20RootTunnel.deposit(fxRootToken, user, amount, data);
    }

    function withdraw(address childToken, uint256 amount) external onlyChildChain {
        fxERC20ChildTunnel.withdraw(childToken, amount);
    }
        
    function exitOnEthereum(bytes memory data) external onlyRootChain {
        fxERC20RootTunnel.receiveMessage(data);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return rootToken.approve(spender, amount);
    }
}