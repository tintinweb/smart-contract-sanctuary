// SPDX-License-Identifier: UNLICENSED
// This code is the property of the Aardbanq DAO.
// The Aardbanq DAO is located at 0x829c094f5034099E91AB1d553828F8A765a3DaA1 on the Ethereum Main Net.
// It is the author's wish that this code should be open sourced under the MIT license, but the final 
// decision on this would be taken by the Aardbanq DAO with a vote once sufficient ABQ tokens have been 
// distributed.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity >=0.7.0;
import "./SafeMathTyped.sol";
import "./ScaleBuying.sol";
import './InitialLiquidityOffering.sol';
import "./IUniswapV2Router02.sol";
import "./Erc20.sol";

/// @notice A contract to help convert ETH to DAI with uniswap, and then buy into the Aardbanq DAO ICO or ILO.
contract EthToDaiFacilitator
{
    IUniswapV2Router02 public immutable uniswapRouter;
    Erc20 public immutable dai;
    ScaleBuying public immutable ico;
    InitialLiquidityOffering public immutable ilo;

    /// @notice Construct a EthToDaiFacilitator.
    /// @param _router The uniswap router to use.
    /// @param _dai The DAI contract address.
    /// @param _ico The Aardbanq DAO ICO.
    /// @param _ilo The Aardbanq DAO ILO.
    constructor(IUniswapV2Router02 _router, Erc20 _dai, ScaleBuying _ico, InitialLiquidityOffering _ilo)
    {
        uniswapRouter = _router;
        dai = _dai;
        ico = _ico;
        ilo = _ilo;
    }

    /// @notice Converts the ETH sent into the function to DAI and buy into the Aardbanq DAO ICO.
    /// @param _for The address that should be awarded the ABQ tokens.
    function BuyInIco(address _for)
        payable
        external
    {
        // CG: Trade ETH for DAI via uniswap.
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] =  address(dai);
        uniswapRouter.swapExactETHForTokens{value: address(this).balance}(0, path, address(this), block.timestamp);

        // CG: Buy in the ICO
        uint256 paymentAmount = dai.balanceOf(address(this));
        dai.approve(address(ico), paymentAmount);
        uint256 paymentLeft = ico.buy(paymentAmount, _for);

        // CG: if there is more than 10 DAI left send it back. If less than 10 DAI is left don't sent it back, the gas cost will be more than returning the change costing the client.
        if (paymentLeft > 10 ether)
        {
            bool isSuccess = dai.transfer(msg.sender, paymentLeft);
            require(isSuccess, "ABQICO/could-not-refund-change");
        }
    }

    /// @notice Converts the ETH sent into the function to DAI and buy into the Aardbanq DAO ILO.
    /// @param _for The address that should be awarded the liquidity pool tokens and the ABQ reward tokens.
    function BuyInIlo(address _for)
        payable
        external
    {
        // CG: Trade ETH for DAI via uniswap.
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] =  address(dai);
        uniswapRouter.swapExactETHForTokens{value: address(this).balance}(0, path, address(this), block.timestamp);

        // CG: Buy in the ILO
        uint256 paymentAmount = dai.balanceOf(address(this));
        dai.approve(address(ilo), paymentAmount);
        ilo.provideLiquidity(_for, paymentAmount);
        uint256 paymentLeft = dai.balanceOf(address(this));

        // CG: if there is more than 10 DAI left send it back. If less than 10 DAI is left don't sent it back, the gas cost will be more than returning the change costing the client.
        if (paymentLeft > 10 ether)
        {
            bool isSuccess = dai.transfer(msg.sender, paymentLeft);
            require(isSuccess, "ABQICO/could-not-refund-change");
        }
    }
}