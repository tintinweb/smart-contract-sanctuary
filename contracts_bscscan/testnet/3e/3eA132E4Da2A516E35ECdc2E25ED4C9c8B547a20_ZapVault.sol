// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
000000d:clooodxkxccloooolllllllloxdolcllllllllccllloolcoOOOkkdlccccclllldoc::cc::::cclllllccc:codoc::cc:::cccllldk000000
00000x;ckkxkkxdoloOOxddooooddkOkdoodxkkxdddddxk000xoodollllllcccloxkdllllcllllooddxxddoldkOOOkdooooxOkocccllooolc:ok0000
0000Oc;xd:;:oO00000d;,,,,,,,;;lk000Odc:;,;;,;:lxO0xc;;lkOOOO0kl;,:xx:,,cx00d;,,;;;;;;;,:xOdlxO0000000d:,,,,,,;;lxdc:dO00
0000x:lkl;,,:x0000Oo;;:c;;;;;,;oO0xl;,::;,',,;,;lk0Oo;;oO00kxl;,;lkOl,;:x00d;,;lddoooodxOOo;lO0000000d:,,,,,,,,;:dkl;oO0
0000l:dd:,;,;oO000Oo,;c;...,:;;lOkl;;:c,.....,;;;lk0Oo;;oOOo:;;:;:x0o;,cx00d;,:x000000000Oo;ck0000000x:;,;::;;;,;:oko;oO
000k:cxl;:c;,ck000Oo;,:,...;c;,lOd:,;:'.......;:;;o00Ol;:oo;,,::':k0o;,ck00x:,;coddooook0Oo;:x0000000x:,;loc:cc:;,:dOl;d
000d;od;;ldc;;oO00Ol;,::,,;::;;oOd;,;,........,c:,lO00x:,;,,;;;'.:kOo;;oO00x:,,;;;;,,,;d00d;;d0000000x:,;l;...,cc;;ckk:;
00Oc:oc,;;:c;,cx00Ol,,,;;;;,,;lk0d;,;,........'::,lk00Od;,,;:;,co;lkl,:d000d;,:okxoloodO00d;;d0000000kc,:c,....'cc;:d0o,
00x:cl;;c;'cc,;oO0kl,,;:ccc:cdO00d;,;;'.......':;;lO000Ol;;co::kOc:dc,:x000d;,:x0000000000d;;d0000000kc,;:'.....:l;;oOx,
0Ol:lc,;l:,ol;;lO0Oo;,:xOOOxoodk0x:,,;;.......,;,;oO0000d;;co:cOOc:o:,:x000o;,;dO000000000o;;d0000000k:,;:'.....,l:,lOx;
0k:co;,;llcl:,,ck00d;,clllolclooxxc,,,:;....',,,,:x00000d;;co:cO0l:l:,:x00Oo;,;:cllllllokOl,;d0000000x:,;:'.....,c:,ckk;
0o;ol;,,,,,,,,,:x00d:;::cxkOO00dllc,,,;c:,,,,;;;cxO0OO00d;;cl;cO0o:l:;:d00Oo;,,,,,,,,,,;dOl,:x0000000x:,::'.....'c:,ckk;
Occdc,,,,,,,;,,;dO0d:;c:o00000Oo:c:,,,,,,,,,;:lxOkocc:lkd:cll:lO0dcdkxxxxxxdoooolcccllldkOl,:d0000000x:,::'.....,c:,ckx;
x:ld:,;coodddl;;ck0d;;c:o00000Oc;c;,,;:lllclc:coocloxo:dOkxoccd00xlldxdoooooloxoccclcoO00kc,;:oxkkO00x:,:c'.....,c:,ckd;
o:do;,cdxxolooc,;oOd;;c:o00000k::xdooloOOkdlcoo::d000OlldolooxO000kdocoO000Oocc:oxkOd:oO0kc,,,;;;:lxOd:,cc'.....;c;;lOo,
clxc,;:;:ldxlll;,:xo;:lco00000Occkkxl::oolodkOl,:x0000kl:oO000000000kloO0000kl;ck000Oo:dkkdolc:;;,,ckd:,cl'....'c:,;oOl,
:dx:,:;;d00Ollxc:okdlxocx00000Oo:c:cldxl:d000Ol'lO00000dcx0000000000OodO00000kxk00000d::ccllloxxoc;ckd:,;cc,'';cc;,:xOc;
:xd;;cc;d00Oolxxk00xolcdO000000d;ck000OdoO0000kdk000000kxO00000000000OO00000000000000xc;oOOkxccoddoxOd:,,;::ccc:;,;lOO:;
ckd:cdl;d00OocccoxdclxO00000000x:l000000000000000000000000000000000000000000000000000Oc;x0000kdlllccdxl:;,;,,,,,,;cx0k::
cOdlddc:x000dclxocclk0000000000Odk000000000000000000000000000000000000000000000000000Odok000000000Odcdkxdc;;,,;,;cxO0k::
cOko:,;oO000kcoOkl:oO000000000000000000000000000000000000000000000000000000000000000000000000000000klcc:lllccclodk000k::
lxo::dO00000OkO0Oo;lO000000000000000000000000000000000000000000000000000000000000000000000000000000Ol::odlcllldO00O00Oc:
olcdO000000000000d;o0000000000000000000000000000000000000000000000000000000000000000000000000000000Oo;ck00OOOd:oxl:dOOcc
olx00000000000000Oxk00000000000000000000000000000000000000000000000000000000000000000000000000000000kxk000000Ol::c:ckkcl
old00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000kddkxldocx
lcdO00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000Oc:clO
ddk000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000Oo;:oO
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000kl,lO
*
* MIT License
* ===========
*
* Copyright (c) 2020 Me
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IVault {
    // Transfer want tokens zap -> autoFarm ->
    function deposit(
        uint16 _pid,
        uint256 _wantAmt,
        address _to
    ) external;

    // Transfer want tokens autoFarm -> zap
    function withdraw(
        uint16 _pid,
        uint256 _wantAmt,
        address _to
    ) external;

    // Vault pool info to get want address
    function poolInfo(uint16 _pid)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint16,
            uint256
        );
}

contract ZapVault is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant DSL = 0x72FEAC4C0887c12db21CEB161533Fd8467469e6b;
    address private constant SOUL = 0x67d012F731c23F0313CEA1186d0121779c77fcFE;
// 0x094616f0bdfb0b526bd735bf66eca0ad254ca81f main:0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    address private constant WBNB = 0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F;
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address private constant VAI = 0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7;
    address private constant BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;

    address public constant pixelFarm =
        0xa9725196e9dEeC71a35bCA5930C2A13CB5955D4E;

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private notFlip;
    mapping(address => address) private routePairAddresses;
    address[] public tokens;
    uint256 _taxFactor = 999;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
        require(owner() != address(0), "Zap: owner must be set");

        setNotFlip(CAKE);
        setNotFlip(DSL);
        setNotFlip(SOUL);
        setNotFlip(WBNB);
        setNotFlip(BUSD);
        setNotFlip(USDT);
        setNotFlip(DAI);
        setNotFlip(USDC);
        setNotFlip(VAI);
        setNotFlip(BTCB);
        setNotFlip(ETH);
    }

    receive() external payable {}

    /* ========== View Functions ========== */

    function isFlip(address _address) public view returns (bool) {
        return !notFlip[_address];
    }

    function routePair(address _address) external view returns (address) {
        return routePairAddresses[_address];
    }

    /* ========== External Functions ========== */
    function wantAddress(uint16 _pid) internal view returns (address) {
        (address _wantAddress, , , , , , ) = IVault(pixelFarm).poolInfo(_pid);
        return _wantAddress;
    }

    struct ZapInput {
        address _from;
        uint256 amount;
        address _to;
        address _router;
        uint16 _pid;
    }
    struct ZapInputBnb {
        address _to;
        address _router;
        uint16 _pid;
    }
    struct ZapOutStruct {
        uint256 amount;
        address _router;
        uint16 _pid;
    }

    function zapInToken(ZapInput memory a) external {
        IUniswapV2Router02 ROUTER = IUniswapV2Router02(a._router);
        IERC20(a._from).safeTransferFrom(msg.sender, address(this), a.amount);
        _approveTokenIfNeeded(a._from, ROUTER);

        if (isFlip(a._to)) {
            IUniswapV2Pair pair = IUniswapV2Pair(a._to);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (a._from == token0 || a._from == token1) {
                // swap half amount for other
                address other = a._from == token0 ? token1 : token0;
                _approveTokenIfNeeded(other, ROUTER);
                uint256 sellAmount = a.amount / 2;
                uint256 otherAmount = _swap(
                    a._from,
                    sellAmount,
                    other,
                    address(this),
                    ROUTER
                );

                address _wantAddress = wantAddress(a._pid);
                uint256 _beforeZap = IERC20(_wantAddress).balanceOf(
                    address(this)
                );

                ROUTER.addLiquidity(
                    a._from,
                    other,
                    a.amount - sellAmount,
                    otherAmount,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
                uint256 _afterZap = IERC20(_wantAddress).balanceOf(
                    address(this)
                );
                _approveTokenIfNeededVault(_wantAddress);
                IVault(pixelFarm).deposit(
                    a._pid,
                    _afterZap - _beforeZap,
                    msg.sender
                );
            } else {
                uint256 bnbAmount = _swapTokenForBNB(
                    a._from,
                    a.amount,
                    address(this),
                    ROUTER
                );
                address _wantAddress = wantAddress(a._pid);
                uint256 _beforeZap = IERC20(_wantAddress).balanceOf(
                    address(this)
                );
                _swapBNBToFlip(a._to, bnbAmount, address(this), ROUTER);
                uint256 _afterZap = IERC20(_wantAddress).balanceOf(
                    address(this)
                );
                _approveTokenIfNeededVault(_wantAddress);
                IVault(pixelFarm).deposit(
                    a._pid,
                    _afterZap - _beforeZap,
                    msg.sender
                );
            }
        } else {
            _swap(a._from, a.amount, a._to, msg.sender, ROUTER);
        }
    }

    function zapIn(ZapInputBnb memory a) external payable {
        IUniswapV2Router02 ROUTER = IUniswapV2Router02(a._router);
        address _wantAddress = wantAddress(a._pid);
        uint256 _beforeZap = IERC20(_wantAddress).balanceOf(address(this));
        uint256 taxedValue = (msg.value * (_taxFactor)) / (1000);
        _swapBNBToFlip(a._to, taxedValue, address(this), ROUTER);
        uint256 _afterZap = IERC20(_wantAddress).balanceOf(address(this));
        _approveTokenIfNeededVault(_wantAddress);
        IVault(pixelFarm).deposit(a._pid, _afterZap - _beforeZap, msg.sender);
    }

    function zapOut(ZapOutStruct memory a) external {

        IVault(pixelFarm).withdraw(a._pid, a.amount, msg.sender);
        address _from = wantAddress(a._pid);

        IUniswapV2Router02 ROUTER = IUniswapV2Router02(a._router);

        //IERC20(a._from).safeTransferFrom(msg.sender, address(this), a.amount);
        _approveTokenIfNeeded(_from, ROUTER);

        if (!isFlip(_from)) {
            _swapTokenForBNB(_from, a.amount, msg.sender, ROUTER);
        } else {
            IUniswapV2Pair pair = IUniswapV2Pair(_from);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WBNB || token1 == WBNB) {
                ROUTER.removeLiquidityETH(
                    token0 != WBNB ? token0 : token1,
                    a.amount,
                    0,
                    0,
                    msg.sender,
                    block.timestamp
                );
            } else {
                ROUTER.removeLiquidity(
                    token0,
                    token1,
                    a.amount,
                    0,
                    0,
                    msg.sender,
                    block.timestamp
                );
            }
        }
    }

    function getBalanceOfToken(address token) internal view returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        return balance;
    }

    /* ========== Private Functions ========== */

    function _approveTokenIfNeeded(address token, IUniswapV2Router02 ROUTER)
        private
    {
        if (IERC20(token).allowance(address(this), address(ROUTER)) == 0) {
            IERC20(token).safeApprove(address(ROUTER), type(uint256).max);
        }
    }

    function _approveTokenIfNeededVault(address token) private {
        if (IERC20(token).allowance(address(this), pixelFarm) == 0) {
            IERC20(token).safeApprove(pixelFarm, type(uint256).max);
        }
    }

    function _swapBNBToFlip(
        address flip,
        uint256 amount,
        address receiver,
        IUniswapV2Router02 ROUTER
    ) private {
        if (!isFlip(flip)) {
            _swapBNBForToken(flip, amount, receiver, ROUTER);
        } else {
            // flip
            IUniswapV2Pair pair = IUniswapV2Pair(flip);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WBNB || token1 == WBNB) {
                address token = token0 == WBNB ? token1 : token0;
                uint256 swapValue = amount / 2;
                uint256 tokenAmount = _swapBNBForToken(
                    token,
                    swapValue,
                    address(this),
                    ROUTER
                );

                _approveTokenIfNeeded(token, ROUTER);
                ROUTER.addLiquidityETH{value: amount - swapValue}(
                    token,
                    tokenAmount,
                    0,
                    0,
                    receiver,
                    block.timestamp
                );
            } else {
                uint256 swapValue = amount / 2;
                uint256 token0Amount = _swapBNBForToken(
                    token0,
                    swapValue,
                    address(this),
                    ROUTER
                );
                uint256 token1Amount = _swapBNBForToken(
                    token1,
                    amount - swapValue,
                    address(this),
                    ROUTER
                );

                _approveTokenIfNeeded(token0, ROUTER);
                _approveTokenIfNeeded(token1, ROUTER);
                ROUTER.addLiquidity(
                    token0,
                    token1,
                    token0Amount,
                    token1Amount,
                    0,
                    0,
                    receiver,
                    block.timestamp
                );
            }
        }
    }

    function _swapBNBForToken(
        address token,
        uint256 value,
        address receiver,
        IUniswapV2Router02 ROUTER
    ) private returns (uint256) {
        address[] memory path;

        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = WBNB;
            path[1] = routePairAddresses[token];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = WBNB;
            path[1] = token;
        }
        uint256 _beforeSwap = IERC20(token).balanceOf(address(this));
        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: value}(
            0,
            path,
            receiver,
            block.timestamp
        );
        uint256 _afterSwap = IERC20(token).balanceOf(address(this));
        uint256 amounts = _afterSwap - _beforeSwap;
        return amounts;
    }

    function _swapTokenForBNB(
        address token,
        uint256 amount,
        address receiver,
        IUniswapV2Router02 ROUTER
    ) private returns (uint256) {
        address[] memory path;
        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = routePairAddresses[token];
            path[2] = WBNB;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = WBNB;
        }
        uint256 _beforeSwap = IERC20(token).balanceOf(address(this));

        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            receiver,
            block.timestamp
        );
        uint256 _afterSwap = IERC20(token).balanceOf(address(this));
        uint256 amounts = _afterSwap - _beforeSwap;
        return amounts;
    }

    function _swap(
        address _from,
        uint256 amount,
        address _to,
        address receiver,
        IUniswapV2Router02 ROUTER
    ) private returns (uint256) {
        address intermediate = routePairAddresses[_from];
        if (intermediate == address(0)) {
            intermediate = routePairAddresses[_to];
        }

        address[] memory path;
        if (intermediate != address(0) && (_from == WBNB || _to == WBNB)) {
            // [WBNB, BUSD, VAI] or [VAI, BUSD, WBNB]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (
            intermediate != address(0) &&
            (_from == intermediate || _to == intermediate)
        ) {
            // [VAI, BUSD] or [BUSD, VAI]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else if (
            intermediate != address(0) &&
            routePairAddresses[_from] == routePairAddresses[_to]
        ) {
            // [VAI, DAI] or [VAI, USDC]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (
            routePairAddresses[_from] != address(0) &&
            routePairAddresses[_to] != address(0) &&
            routePairAddresses[_from] != routePairAddresses[_to]
        ) {
            // routePairAddresses[xToken] = xRoute
            // [VAI, BUSD, WBNB, xRoute, xToken]
            path = new address[](5);
            path[0] = _from;
            path[1] = routePairAddresses[_from];
            path[2] = WBNB;
            path[3] = routePairAddresses[_to];
            path[4] = _to;
        } else if (
            intermediate != address(0) &&
            routePairAddresses[_from] != address(0)
        ) {
            // [VAI, BUSD, WBNB, DSL]
            path = new address[](4);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = WBNB;
            path[3] = _to;
        } else if (
            intermediate != address(0) && routePairAddresses[_to] != address(0)
        ) {
            // [DSL, WBNB, BUSD, VAI]
            path = new address[](4);
            path[0] = _from;
            path[1] = WBNB;
            path[2] = intermediate;
            path[3] = _to;
        } else if (_from == WBNB || _to == WBNB) {
            // [WBNB, DSL] or [DSL, WBNB]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            // [USDT, DSL] or [DSL, USDT]
            path = new address[](3);
            path[0] = _from;
            path[1] = WBNB;
            path[2] = _to;
        }
        uint256 _beforeSwap = IERC20(_from).balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            receiver,
            block.timestamp
        );
        uint256 _afterSwap = IERC20(_from).balanceOf(address(this));
        uint256 amounts = _afterSwap - _beforeSwap;

        return amounts;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRoutePairAddress(address asset, address route)
        external
        onlyOwner
    {
        routePairAddresses[asset] = route;
    }

    function setTaxFactor(uint256 taxFactor) external onlyOwner {
        _taxFactor = taxFactor;
    }

    function setNotFlip(address token) public onlyOwner {
        bool needPush = notFlip[token] == false;
        notFlip[token] = true;
        if (needPush) {
            tokens.push(token);
        }
    }

    function removeToken(uint256 i) external onlyOwner {
        address token = tokens[i];
        notFlip[token] = false;
        tokens[i] = tokens[tokens.length - 1];
        tokens.pop();
    }

    function sweep(address _router) external onlyOwner {
        IUniswapV2Router02 ROUTER = IUniswapV2Router02(_router);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint256 amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                _swapTokenForBNB(token, amount, owner(), ROUTER);
            }
        }
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

