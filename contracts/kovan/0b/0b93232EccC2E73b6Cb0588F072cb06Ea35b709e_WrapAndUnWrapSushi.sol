// SPDX-License-Identifier: MIT

/*
                                       `.-:+osyhhhhhhyso+:-.`
                                   .:+ydmNNNNNNNNNNNNNNNNNNmdy+:.
                                .+ymNNNNNNNNNNNNNNNNNNNNNNNNNNNNmy+.
                             `/hmNNNNNNNNmdys+//:::://+sydmNNNNNNNNmh/`
                           .odNNNNNNNdy+-.`              `.-+ydNNNNNNNdo.
                         `omNNNNNNdo-`                        `-odNNNNNNmo`
                        :dNNNNNNh/`                              `/hNNNNNNd:
                      `oNNNNNNh:                     /-/.           :hNNNNNNo`
                     `yNNNNNm+`                      mNNm-           `+mNNNNNy`
                    `hNNNNNd-                        hNNNm.            -dNNNNNh`
                    yNNNNNd.                         .ymNNh             .dNNNNNy
                   /NNNNNm.                            -mNNys+.          .mNNNNN/
                  `mNNNNN:                           `:hNNNNNNNs`         :NNNNNm`
                  /NNNNNh                          `+dNNNNNNNNNNd.         hNNNNN/
                  yNNNNN/               .:+syyhhhhhmNNNNNNNNNNNNNm`        /NNNNNy
                  dNNNNN.            `+dNNNNNNNNNNNNNNNNNNNNNNNmd+         .NNNNNd
                  mNNNNN`           -dNNNNNNNNNNNNNNNNNNNNNNm-             `NNNNNm
                  dNNNNN.          -NNNNNNNNNNNNNNNNNNNNNNNN+              .NNNNNd
                  yNNNNN/          dNNNNNNNNNNNNNNNNNNNNNNNN:              /NNNNNy
                  /NNNNNh         .NNNNNNNNNNNNNNNNNNNNNNNNd`              hNNNNN/
                  `mNNNNN:        -NNNNNNNNNNNNNNNNNNNNNNNh.              :NNNNNm`
                   /NNNNNm.       `NNNNNNNNNNNNNNNNNNNNNh:               .mNNNNN/
                    yNNNNNd.      .yNNNNNNNNNNNNNNNdmNNN/               .dNNNNNy
                    `hNNNNNd-    `dmNNNNNNNNNNNNdo-`.hNNh              -dNNNNNh`
                     `yNNNNNm+`   oNNmmNNNNNNNNNy.   `sNNdo.         `+mNNNNNy`
                      `oNNNNNNh:   ....++///+++++.     -+++.        :hNNNNNNo`
                        :dNNNNNNh/`                              `/hNNNNNNd:
                         `omNNNNNNdo-`                        `-odNNNNNNmo`
                           .odNNNNNNNdy+-.`              `.-+ydNNNNNNNdo.
                             `/hmNNNNNNNNmdys+//:::://+sydmNNNNNNNNmh/`
                                .+ymNNNNNNNNNNNNNNNNNNNNNNNNNNNNmy+.
                                   .:+ydmNNNNNNNNNNNNNNNNNNmdy+:.
                                       `.-:+yourewelcome+:-.`
 /$$$$$$$  /$$                                               /$$      /$$
| $$__  $$| $$                                              | $$$    /$$$
| $$  \ $$| $$  /$$$$$$  /$$   /$$ /$$   /$$  /$$$$$$$      | $$$$  /$$$$  /$$$$$$  /$$$$$$$   /$$$$$$  /$$   /$$
| $$$$$$$/| $$ /$$__  $$|  $$ /$$/| $$  | $$ /$$_____/      | $$ $$/$$ $$ /$$__  $$| $$__  $$ /$$__  $$| $$  | $$
| $$____/ | $$| $$$$$$$$ \  $$$$/ | $$  | $$|  $$$$$$       | $$  $$$| $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$  | $$
| $$      | $$| $$_____/  >$$  $$ | $$  | $$ \____  $$      | $$\  $ | $$| $$  | $$| $$  | $$| $$_____/| $$  | $$
| $$      | $$|  $$$$$$$ /$$/\  $$|  $$$$$$/ /$$$$$$$/      | $$ \/  | $$|  $$$$$$/| $$  | $$|  $$$$$$$|  $$$$$$$
|__/      |__/ \_______/|__/  \__/ \______/ |_______/       |__/     |__/ \______/ |__/  |__/ \_______/ \____  $$
                                                                                                        /$$  | $$
                                                                                                       |  $$$$$$/
                                                                                                       \______/
*/

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/token/IWETH.sol";
import "./interfaces/token/ILPERC20.sol";
import "./interfaces/sushiswap/ISushiV2.sol";
import "./interfaces/uniswap/IUniswapFactory.sol";

contract WrapAndUnWrapSushi is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //placehodler token address for specifying eth tokens
    address public ETH_TOKEN_ADDRESS;
    address public WETH_TOKEN_ADDRESS;
    bool public changeRecpientIsOwner;
    address private sushiAddress;
    address private uniFactoryAddress;
    uint256 private approvalAmount;
    uint256 private longTimeFromNow;
    uint256 public fee;
    uint256 public maxfee;
    mapping(address => address[]) public lpTokenAddressToPairs;
    mapping(string => address) public stablecoins;
    mapping(address => mapping(address => address[])) public presetPaths;
    IWETH private wethToken;
    ISushiV2 private sushiExchange;
    IUniswapFactory private factory;

    constructor() payable {}

    function initialize(
        address _weth,
        address _sushiAddress,
        address _uniFactoryAddress,
        address _dai,
        address _usdt,
        address _usdc
    ) 
        public 
        initializeOnceOnly 
    {
        ETH_TOKEN_ADDRESS = address(0x0);
        WETH_TOKEN_ADDRESS = _weth;
        wethToken = IWETH(WETH_TOKEN_ADDRESS);
        approvalAmount = 1000000000000000000000000000000;
        longTimeFromNow = 1000000000000000000000000000;
        sushiAddress = _sushiAddress;
        sushiExchange = ISushiV2(sushiAddress);
        uniFactoryAddress = _uniFactoryAddress;
        factory = IUniswapFactory(uniFactoryAddress);
        fee = 0;
        maxfee = 0;
        stablecoins["DAI"] = _dai;
        stablecoins["USDT"] = _usdt;
        stablecoins["USDC"] = _usdc;
        changeRecpientIsOwner = false;
    }

    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Amount specified is zero");
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    function updateStableCoinAddress(string memory coinName, address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        stablecoins[coinName] = newAddress;
        return true;
    }

    function updatePresetPaths(
        address sellToken,
        address buyToken,
        address[] memory newPath
    ) 
        external 
        onlyOwner 
        returns (bool) 
    {
        presetPaths[sellToken][buyToken] = newPath;
        return true;
    }

    // Owner can turn on ability to collect a small fee from trade imbalances on LP conversions
    function updateChangeRecipientBool(bool changeRecpientIsOwnerBool)
        external
        onlyOwner
        returns (bool)
    {
        changeRecpientIsOwner = changeRecpientIsOwnerBool;
        return true;
    }

    function updateSushiExchange(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        sushiExchange = ISushiV2(newAddress);
        sushiAddress = newAddress;
        return true;
    }

    function updateUniswapFactory(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        factory = IUniswapFactory(newAddress);
        uniFactoryAddress = newAddress;
        return true;
    }

    function addLPPair(
        address lpAddress,
        address token1,
        address token2
    ) 
        external 
        onlyOwner
        returns (bool) 
    {
        lpTokenAddressToPairs[lpAddress] = [token1, token2];
        return true;
    }

    function getLPTokenByPair(
        address token1, 
        address token2
    )
        external
        view
        returns (address lpAddr)
    {
        address thisPairAddress = factory.getPair(token1, token2);
        return thisPairAddress;
    }

    function getUserTokenBalance(
        address userAddress, 
        address tokenAddress
    )
        external
        view
        returns (uint256)
    {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(userAddress);
    }

    function adminEmergencyWithdrawTokens(
        address token,
        uint256 amount,
        address payable destination
    ) 
        public 
        onlyOwner 
        returns (bool) 
    {
        if (address(token) == ETH_TOKEN_ADDRESS) {
            destination.transfer(amount);
        } else {
            IERC20 token_ = IERC20(token);
            token_.safeTransfer(destination, amount);
        }
        return true;
    }

    function setFee(uint256 newFee) public onlyOwner returns (bool) {
        require(
            newFee <= maxfee,
            "Admin cannot set the fee higher than the current maxfee"
        );
        fee = newFee;
        return true;
    }

    function setMaxFee(uint256 newMax) public onlyOwner returns (bool) {
        require(maxfee == 0, "Admin can only set max fee once and it is perm");
        maxfee = newMax;
        return true;
    }

    function wrap(
        address sourceToken,
        address[] memory destinationTokens,
        uint256 amount,
        uint256 userSlippageTolerance
    ) 
        public 
        payable 
        returns (address, uint256) 
    {
        IERC20 sToken = IERC20(sourceToken);
        IERC20 dToken = IERC20(destinationTokens[0]);

        if (destinationTokens.length == 1) {
            if (sourceToken != ETH_TOKEN_ADDRESS) {
                sToken.safeTransferFrom(msg.sender, address(this), amount);

                if (
                    sToken.allowance(address(this), sushiAddress) <
                    amount.mul(2)
                ) {
                    sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
                }
            }

            conductUniswap(
                sourceToken,
                destinationTokens[0],
                amount,
                userSlippageTolerance
            );
            uint256 thisBalance = dToken.balanceOf(address(this));
            dToken.safeTransfer(msg.sender, thisBalance);
            return (destinationTokens[0], thisBalance);
        } else {
            bool updatedweth = false;
            if (sourceToken == ETH_TOKEN_ADDRESS) {
                IWETH sToken1 = IWETH(WETH_TOKEN_ADDRESS);
                sToken1.deposit{value: msg.value}();
                sToken = IERC20(WETH_TOKEN_ADDRESS);
                amount = msg.value;
                sourceToken = WETH_TOKEN_ADDRESS;
                updatedweth = true;
            }

            if (sourceToken != ETH_TOKEN_ADDRESS && updatedweth == false) {
                sToken.safeTransferFrom(msg.sender, address(this), amount);
                if (
                    sToken.allowance(address(this), sushiAddress) <
                    amount.mul(2)
                ) {
                    sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
                }
            }

            if (destinationTokens[0] == ETH_TOKEN_ADDRESS) {
                destinationTokens[0] = WETH_TOKEN_ADDRESS;
            }
            if (destinationTokens[1] == ETH_TOKEN_ADDRESS) {
                destinationTokens[1] = WETH_TOKEN_ADDRESS;
            }

            if (sourceToken != destinationTokens[0]) {
                conductUniswap(
                    sourceToken,
                    destinationTokens[0],
                    amount.div(2),
                    userSlippageTolerance
                );
            }

            if (sourceToken != destinationTokens[1]) {
                conductUniswap(
                    sourceToken,
                    destinationTokens[1],
                    amount.div(2),
                    userSlippageTolerance
                );
            }

            IERC20 dToken2 = IERC20(destinationTokens[1]);
            uint256 dTokenBalance = dToken.balanceOf(address(this));
            uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

            if (
                dToken.allowance(address(this), sushiAddress) <
                dTokenBalance.mul(2)
            ) {
                dToken.safeIncreaseAllowance(
                    sushiAddress,
                    dTokenBalance.mul(3)
                );
            }

            if (
                dToken2.allowance(address(this), sushiAddress) <
                dTokenBalance2.mul(2)
            ) {
                dToken2.safeIncreaseAllowance(
                    sushiAddress,
                    dTokenBalance2.mul(3)
                );
            }

            (, , uint256 liquidityCoins) = sushiExchange.addLiquidity(
                destinationTokens[0],
                destinationTokens[1],
                dTokenBalance,
                dTokenBalance2,
                1,
                1,
                address(this),
                longTimeFromNow
            );

            address thisPairAddress = factory.getPair(
                destinationTokens[0],
                destinationTokens[1]
            );
            IERC20 lpToken = IERC20(thisPairAddress);
            lpTokenAddressToPairs[thisPairAddress] = [
                destinationTokens[0],
                destinationTokens[1]
            ];
            uint256 thisBalance = lpToken.balanceOf(address(this));

            if (fee > 0) {
                uint256 totalFee = (thisBalance.mul(fee)).div(10000);
                if (totalFee > 0) {
                    lpToken.safeTransfer(owner(), totalFee);
                }
                thisBalance = lpToken.balanceOf(address(this));
                lpToken.safeTransfer(msg.sender, thisBalance);
            } else {
                lpToken.safeTransfer(msg.sender, thisBalance);
            }

            // Transfer any change to changeRecipient (from a pair imbalance. 
            // Should never be more than a few basis points)
            address changeRecipient = msg.sender;
            if (changeRecpientIsOwner == true) {
                changeRecipient = owner();
            }
            if (dToken.balanceOf(address(this)) > 0) {
                dToken.safeTransfer(
                    changeRecipient,
                    dToken.balanceOf(address(this))
                );
            }
            if (dToken2.balanceOf(address(this)) > 0) {
                dToken2.safeTransfer(
                    changeRecipient,
                    dToken2.balanceOf(address(this))
                );
            }

            return (thisPairAddress, thisBalance);
        }
    }

    function unwrap(
        address sourceToken,
        address destinationToken,
        uint256 amount,
        uint256 userSlippageTolerance
    ) 
        public 
        payable 
        returns (uint256) 
    {
        address originalDestinationToken = destinationToken;
        IERC20 sToken = IERC20(sourceToken);
        if (destinationToken == ETH_TOKEN_ADDRESS) {
            destinationToken = WETH_TOKEN_ADDRESS;
        }
        IERC20 dToken = IERC20(destinationToken);

        if (sourceToken != ETH_TOKEN_ADDRESS) {
            sToken.safeTransferFrom(msg.sender, address(this), amount);
        }

        ILPERC20 thisLpInfo = ILPERC20(sourceToken);
        lpTokenAddressToPairs[sourceToken] = [
            thisLpInfo.token0(),
            thisLpInfo.token1()
        ];

        if (lpTokenAddressToPairs[sourceToken].length != 0) {
            if (sToken.allowance(address(this), sushiAddress) < amount.mul(2)) {
                sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
            }

            sushiExchange.removeLiquidity(
                lpTokenAddressToPairs[sourceToken][0],
                lpTokenAddressToPairs[sourceToken][1],
                amount,
                0,
                0,
                address(this),
                longTimeFromNow
            );

            IERC20 pToken1 = IERC20(lpTokenAddressToPairs[sourceToken][0]);
            IERC20 pToken2 = IERC20(lpTokenAddressToPairs[sourceToken][1]);

            uint256 pTokenBalance = pToken1.balanceOf(address(this));
            uint256 pTokenBalance2 = pToken2.balanceOf(address(this));

            if (
                pToken1.allowance(address(this), sushiAddress) <
                pTokenBalance.mul(2)
            ) {
                pToken1.safeIncreaseAllowance(
                    sushiAddress,
                    pTokenBalance.mul(3)
                );
            }

            if (
                pToken2.allowance(address(this), sushiAddress) <
                pTokenBalance2.mul(2)
            ) {
                pToken2.safeIncreaseAllowance(
                    sushiAddress,
                    pTokenBalance2.mul(3)
                );
            }

            if (lpTokenAddressToPairs[sourceToken][0] != destinationToken) {
                conductUniswap(
                    lpTokenAddressToPairs[sourceToken][0],
                    destinationToken,
                    pTokenBalance,
                    userSlippageTolerance
                );
            }
            if (lpTokenAddressToPairs[sourceToken][1] != destinationToken) {
                conductUniswap(
                    lpTokenAddressToPairs[sourceToken][1],
                    destinationToken,
                    pTokenBalance2,
                    userSlippageTolerance
                );
            }

            uint256 destinationTokenBalance = dToken.balanceOf(address(this));

            if (originalDestinationToken == ETH_TOKEN_ADDRESS) {
                wethToken.withdraw(destinationTokenBalance);
                if (fee > 0) {
                    uint256 totalFee = (address(this).balance.mul(fee)).div(
                        10000
                    );
                    if (totalFee > 0) {
                        payable(owner()).transfer(totalFee);
                    }
                    payable(msg.sender).transfer(address(this).balance);
                } else {
                    payable(msg.sender).transfer(address(this).balance);
                }
            } else {
                if (fee > 0) {
                    uint256 totalFee = (destinationTokenBalance.mul(fee)).div(
                        10000
                    );
                    if (totalFee > 0) {
                        dToken.safeTransfer(owner(), totalFee);
                    }
                    destinationTokenBalance = dToken.balanceOf(address(this));
                    dToken.safeTransfer(msg.sender, destinationTokenBalance);
                } else {
                    dToken.safeTransfer(msg.sender, destinationTokenBalance);
                }
            }

            return destinationTokenBalance;
        } else {
            if (sToken.allowance(address(this), sushiAddress) < amount.mul(2)) {
                sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
            }
            if (sourceToken != destinationToken) {
                conductUniswap(
                    sourceToken,
                    destinationToken,
                    amount,
                    userSlippageTolerance
                );
            }
            uint256 destinationTokenBalance = dToken.balanceOf(address(this));
            dToken.safeTransfer(msg.sender, destinationTokenBalance);
            return destinationTokenBalance;
        }
    }

    // Gets the best path to route the transaction on Uniswap
    function getBestPath(
        address sellToken,
        address buyToken,
        uint256 amount
    ) 
        public 
        view 
        returns (address[] memory) 
    {
        address[] memory defaultPath = new address[](2);
        defaultPath[0] = sellToken;
        defaultPath[1] = buyToken;

        if (presetPaths[sellToken][buyToken].length != 0) {
            return presetPaths[sellToken][buyToken];
        }

        if (
            sellToken == stablecoins["DAI"] ||
            sellToken == stablecoins["USDC"] ||
            sellToken == stablecoins["USDT"]
        ) {
            return defaultPath;
        }
        if (
            buyToken == stablecoins["DAI"] ||
            buyToken == stablecoins["USDC"] ||
            buyToken == stablecoins["USDT"]
        ) {
            return defaultPath;
        }

        address[] memory daiPath = new address[](3);
        address[] memory usdcPath = new address[](3);
        address[] memory usdtPath = new address[](3);

        daiPath[0] = sellToken;
        daiPath[1] = stablecoins["DAI"];
        daiPath[2] = buyToken;

        usdcPath[0] = sellToken;
        usdcPath[1] = stablecoins["USDC"];
        usdcPath[2] = buyToken;

        usdtPath[0] = sellToken;
        usdtPath[1] = stablecoins["USDT"];
        usdtPath[2] = buyToken;

        uint256 directPathOutput = getPriceFromSushiswap(defaultPath, amount)[
            1
        ];

        uint256[] memory daiPathOutputRaw = getPriceFromSushiswap(
            daiPath,
            amount
        );
        uint256[] memory usdtPathOutputRaw = getPriceFromSushiswap(
            usdtPath,
            amount
        );
        uint256[] memory usdcPathOutputRaw = getPriceFromSushiswap(
            usdcPath,
            amount
        );

        // uint256 directPathOutput = directPathOutputRaw[directPathOutputRaw.length-1];
        uint256 daiPathOutput = daiPathOutputRaw[daiPathOutputRaw.length - 1];
        uint256 usdtPathOutput = usdtPathOutputRaw[
            usdtPathOutputRaw.length - 1
        ];
        uint256 usdcPathOutput = usdcPathOutputRaw[
            usdcPathOutputRaw.length - 1
        ];

        uint256 bestPathOutput = directPathOutput;
        address[] memory bestPath = new address[](2);
        address[] memory bestPath3 = new address[](3);
        // return defaultPath;
        bestPath = defaultPath;

        bool isTwoPath = true;

        if (directPathOutput < daiPathOutput) {
            isTwoPath = false;
            bestPathOutput = daiPathOutput;
            bestPath3 = daiPath;
        }
        if (bestPathOutput < usdcPathOutput) {
            isTwoPath = false;
            bestPathOutput = usdcPathOutput;
            bestPath3 = usdcPath;
        }
        if (bestPathOutput < usdtPathOutput) {
            isTwoPath = false;
            bestPathOutput = usdtPathOutput;
            bestPath3 = usdtPath;
        }

        require(
            bestPathOutput > 0,
            "This trade will result in getting zero tokens back. Reverting"
        );

        if (isTwoPath == true) {
            return bestPath;
        } else {
            return bestPath3;
        }
    }

    function getPriceFromSushiswap(
        address[] memory theAddresses,
        uint256 amount
    ) 
        public 
        view 
        returns (uint256[] memory amounts1) 
    {
        try sushiExchange.getAmountsOut(amount, theAddresses) returns (
            uint256[] memory amounts
        ) {
            return amounts;
        } catch {
            uint256[] memory amounts2 = new uint256[](2);
            amounts2[0] = 0;
            amounts2[1] = 0;
            return amounts2;
        }
    }

    function getAmountOutMin(
        address[] memory theAddresses,
        uint256 amount,
        uint256 userSlippageTolerance
    ) 
        public 
        view 
        returns (uint256) 
    {
        uint256[] memory assetAmounts = getPriceFromSushiswap(
            theAddresses,
            amount
        );
        require(
            userSlippageTolerance <= 100,
            "userSlippageTolerance can not be larger than 100"
        );
        return
            SafeMath.div(
                SafeMath.mul(assetAmounts[1], (100 - userSlippageTolerance)),
                100
            );
    }

    function conductUniswap(
        address sellToken,
        address buyToken,
        uint256 amount,
        uint256 userSlippageTolerance
    ) 
        internal 
        returns (uint256 amounts1) 
    {
        if (sellToken == ETH_TOKEN_ADDRESS && buyToken == WETH_TOKEN_ADDRESS) {
            wethToken.deposit{value: msg.value}();
        } else if (sellToken == address(0x0)) {
            // address[] memory addresses = new address[](2);
            address[] memory addresses = getBestPath(
                WETH_TOKEN_ADDRESS,
                buyToken,
                amount
            );
            // addresses[0] = WETH_TOKEN_ADDRESS;
            // addresses[1] = buyToken;
            uint256 amountOutMin = getAmountOutMin(
                addresses,
                amount,
                userSlippageTolerance
            );
            sushiExchange.swapExactETHForTokens{value: msg.value}(
                amountOutMin,
                addresses,
                address(this),
                1000000000000000
            );
        } else if (sellToken == WETH_TOKEN_ADDRESS) {
            wethToken.withdraw(amount);

            // address[] memory addresses = new address[](2);
            address[] memory addresses = getBestPath(
                WETH_TOKEN_ADDRESS,
                buyToken,
                amount
            );
            // addresses[0] = WETH_TOKEN_ADDRESS;
            // addresses[1] = buyToken;
            uint256 amountOutMin = getAmountOutMin(
                addresses,
                amount,
                userSlippageTolerance
            );
            sushiExchange.swapExactETHForTokens{value: amount}(
                amountOutMin,
                addresses,
                address(this),
                1000000000000000
            );
        } else {
            address[] memory addresses = getBestPath(
                sellToken,
                buyToken,
                amount
            );
            uint256[] memory amounts = conductUniswapT4T(
                addresses,
                amount,
                userSlippageTolerance
            );
            uint256 resultingTokens = amounts[amounts.length - 1];
            return resultingTokens;
        }
    }

    function conductUniswapT4T(
        address[] memory theAddresses,
        uint256 amount,
        uint256 userSlippageTolerance
    ) 
        internal
        returns (uint256[] memory amounts1)
    {
        uint256 deadline = 1000000000000000;
        uint256 amountOutMin = getAmountOutMin(
            theAddresses,
            amount,
            userSlippageTolerance
        );
        uint256[] memory amounts = sushiExchange.swapExactTokensForTokens(
            amount,
            amountOutMin,
            theAddresses,
            address(this),
            deadline
        );
        return amounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import './OwnableProxied.sol';

contract OwnableUpgradeable is OwnableProxied {
    /*
     * @notice Modifier to make body of function only execute if the contract has not already been initialized.
     */
    address payable public proxy;
    modifier initializeOnceOnly() {
         if(!initialized[target]) {
             initialized[target] = true;
             emit EventInitialized(target);
             _;
         } else revert();
     }

    modifier onlyProxy() {
        require(msg.sender == proxy);
        _;
    }

    /**
     * @notice Will always fail if called. This is used as a placeholder for the contract ABI.
     * @dev This is code is never executed by the Proxy using delegate call
     */
    function upgradeTo(address) public pure override {
        assert(false);
    }

    /**
     * @notice Initialize any state variables that would normally be set in the contructor.
     * @dev Initialization functionality MUST be implemented in inherited upgradeable contract if the child contract requires
     * variable initialization on creation. This is because the contructor of the child contract will not execute
     * and set any state when the Proxy contract targets it.
     * This function MUST be called stright after the Upgradeable contract is set as the target of the Proxy. This method
     * can be overwridden so that it may have arguments. Make sure that the initializeOnceOnly() modifier is used to protect
     * from being initialized more than once.
     * If a contract is upgraded twice, pay special attention that the state variables are not initialized again
     */
    /*function initialize() public initializeOnceOnly {
        // initialize contract state variables here
    }*/

    function setProxy(address payable theAddress) public onlyOwner {
        proxy = theAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ILPERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISushiV2 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

/*
 * @title Proxied v0.5
 * @author Jack Tanner
 * @notice The Proxied contract acts as the parent contract to Proxy and Upgradeable with and creates space for
 * state variables, functions and events that will be used in the upgraeable system.
 *
 * @dev Both the Proxy and Upgradeable need to hae the target and initialized state variables stored in the exact
 * same storage location, which is why they must both inherit from Proxied. Defining them in the saparate contracts
 * does not work.
 *
 * @param target - This stores the current address of the target Upgradeable contract, which can be modified by
 * calling upgradeTo()
 *
 * @param initialized - This mapping records which targets have been initialized with the Upgradeable.initialize()
 * function. Target Upgradeable contracts can only be intitialed once.
 */
abstract contract OwnableProxied is Ownable {
    address public target;
    mapping(address => bool) public initialized;

    event EventUpgrade(
        address indexed newTarget,
        address indexed oldTarget,
        address indexed admin
    );
    event EventInitialized(address indexed target);

    function upgradeTo(address _target) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner returns (bool) {
        _owner = newOwner;
        return true;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

