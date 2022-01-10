/**
 *Submitted for verification at FtmScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}

interface IFlashloanReceiver {
    function onFlashLoan(address initiator, address underlying, uint amount, uint fee, bytes calldata params) external;
}

interface ICTokenFlashloan {
    function flashLoan(
        address receiver,
        address initiator,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface SpiritRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) external;
}

interface BAMMInterface {
    function swap(uint lusdAmount, IERC20 returnToken, uint minReturn, address payable dest) external returns(uint);
}

contract CreamArb {
    ICTokenFlashloan constant public cUSDC = ICTokenFlashloan(0x328A7b4d538A2b3942653a9983fdA3C12c571141);
    IERC20 constant public USDC = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    SpiritRouter constant public ROUTER = SpiritRouter(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52);

    function f() public {
        cUSDC.flashLoan(address(this), address(cUSDC), 1e6, "");
    }

    function onFlashLoan(address initiator, address underlying, uint amount, uint fee, bytes calldata params) external returns(bytes32) {
        IERC20(underlying).approve(initiator, amount + fee);

        (BAMMInterface bamm, address[] memory path, IERC20 dest) = abi.decode(params, (BAMMInterface, address[], IERC20));
        // swap on the bamm
        IERC20(underlying).approve(address(bamm), amount);
        uint destAmount = bamm.swap(amount, dest, 1, address(this));

        dest.approve(address(ROUTER), destAmount);
        ROUTER.swapExactTokensForTokens(destAmount, 1, path, address(this), now);

        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }

    function arb(BAMMInterface bamm, address[] memory path, uint amount) public {
        bytes memory data = abi.encode(bamm, path, path[0]);
        cUSDC.flashLoan(address(this), address(cUSDC), amount, data);
    }

    fallback() payable external {

    }
}