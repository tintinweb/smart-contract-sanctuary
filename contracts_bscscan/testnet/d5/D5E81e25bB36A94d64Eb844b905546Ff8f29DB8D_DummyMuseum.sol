// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IApe.sol";
import "./IBEP20.sol";
import "./IMuseum.sol";

contract DummyMuseum is IMuseum {
    address constant MULTI_SIG_TEAM_WALLET = 0x48e065F5a65C3Ba5470f75B65a386A2ad6d5ba6b;
    address constant MARKETING_WALLET = 0x0426760C100E3be682ce36C01D825c2477C47292;

    IBEP20 constant BANANA = IBEP20(0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95);
    IBEP20 constant GNANA = IBEP20(0xdDb3Bd8645775F59496c821E4F55A7eA6A6dc299);
    IBEP20 public babyBanana;

    IApeRouter public router = IApeRouter(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7);
    IApeTreasury public treasury = IApeTreasury(0xec4b9d1fd8A3534E31fcE1636c7479BcD29213aE);

    uint256 transferGas = 25000;

    modifier onlyTeam() {
        require(msg.sender == MULTI_SIG_TEAM_WALLET);
        _;
    }

    modifier onlyMarketing() {
        require(msg.sender == MARKETING_WALLET);
        _;
    }

    function deposit() external payable override {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(BANANA);

        router.swapExactETHForTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 bananaAmount = BANANA.balanceOf(address(this));
        BANANA.approve(address(treasury), bananaAmount);
        treasury.buy(bananaAmount);
    }

    // Maintenance

    function recover() external onlyMarketing {
		(bool sent,) = payable(MARKETING_WALLET).call{value: address(this).balance, gas: transferGas}("");
		require(sent, "Tx failed");
	}

    function updateTransferGas(uint256 newGas) external onlyMarketing {
        transferGas = newGas;
    }

    function updateBabyBanana(address newAddress) external onlyTeam {
        babyBanana = IBEP20(newAddress);
    }

    function migrate(address newMuseum) external onlyTeam {
        babyBanana.transfer(newMuseum, babyBanana.balanceOf(address(this)));
        GNANA.transfer(newMuseum, GNANA.balanceOf(address(this)));
    }
}