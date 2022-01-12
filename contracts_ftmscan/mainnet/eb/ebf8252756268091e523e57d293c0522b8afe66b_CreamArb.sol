/**
 *Submitted for verification at FtmScan.com on 2022-01-11
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
    function LUSD() external view returns(address);
}

contract CreamArb {
    ICTokenFlashloan constant public cUSDC = ICTokenFlashloan(0x328A7b4d538A2b3942653a9983fdA3C12c571141);
    IERC20 constant public WFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    SpiritRouter constant public ROUTER = SpiritRouter(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52);


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

    function arb(BAMMInterface bamm, ICTokenFlashloan creamToken, uint srcAmount, address dest) public {
        IERC20 src = IERC20(bamm.LUSD());
        
        address[] memory path = new address[](3);
        path[0] = dest;
        path[1] = address(WFTM);
        path[2] = address(src);

        bytes memory data = abi.encode(bamm, path, dest);
        creamToken.flashLoan(address(this), address(creamToken), srcAmount, data);

        src.transfer(msg.sender, src.balanceOf(address(this)));
    }

    fallback() payable external {

    }
}