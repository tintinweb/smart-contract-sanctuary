//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

interface IERC20 {
    function withdraw(uint256 amount) external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

interface IERC20Predicate {
    function startExitWithBurntTokens(bytes calldata data) external;
}

interface IWithdrawManager {
    function processExits(address _token) external;
}

contract EIP1559Burn {
    IERC20 public immutable maticRootToken;
    IERC20 public immutable maticChildToken = IERC20(0x0000000000000000000000000000000000001010);
    IERC20Predicate public immutable erc20Predicate;
    IWithdrawManager public immutable withdrawManager;
    uint24 public immutable rootChainId;
    uint24 public immutable childChainId;

    constructor(
        IERC20 _maticRootToken,
        IERC20Predicate _erc20Predicate,
        IWithdrawManager _withdrawManager,
        uint24 _rootChainId,
        uint24 _childChainId
        ) {
        maticRootToken = _maticRootToken;
        erc20Predicate = _erc20Predicate;
        withdrawManager = _withdrawManager;
        rootChainId = _rootChainId;
        childChainId = _childChainId;
    }

    modifier onlyRootChain() {
        require(block.chainid == rootChainId, "ONLY_ROOT");
        _;
    }

    modifier onlyChildChain() {
        require(block.chainid == childChainId, "ONLY_CHILD");
        _;
    }

    receive() external payable {

    }

    function withdraw() external onlyChildChain payable {
        maticChildToken.withdraw{value: address(this).balance}(address(this).balance);
    }

    function initiateExit(bytes calldata data) external onlyRootChain {
        erc20Predicate.startExitWithBurntTokens(data);
    }

    function exit() external onlyRootChain {
        withdrawManager.processExits(address(maticRootToken));
        uint256 tokenBalance = maticRootToken.balanceOf(address(this));
        if (tokenBalance > 0) {
            maticRootToken.transfer(0x000000000000000000000000000000000000dEaD, tokenBalance);
        }
    }
}