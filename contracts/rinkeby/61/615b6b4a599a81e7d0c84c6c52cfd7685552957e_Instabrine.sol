pragma solidity ^0.6.7;

import "./safe-math.sol";
import "./erc20.sol";

import "./uniswapv2.sol";
import "./curve.sol";
import "./jar.sol";

// Converts Primitive tokens to Pickle Jar Tokens
contract Instabrine {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Emergency withdrawal
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    // Safety logic

    function emergencyERC20Retrieve(address token) public {
        require(msg.sender == owner, "!owner");
        uint256 _bal = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, _bal);
    }

    // Internal functions

    function _curveLpToPickleJarAndRefund(address curveLp, address pickleJar)
        internal
        returns (uint256)
    {
        uint256 curveLpAmount = IERC20(curveLp).balanceOf(address(this));

        IERC20(curveLp).safeApprove(pickleJar, 0);
        IERC20(curveLp).safeApprove(pickleJar, curveLpAmount);

        IJar(pickleJar).depositAll();

        // Refund msg.sender
        uint256 _jar = IJar(pickleJar).balanceOf(address(this));
        IJar(pickleJar).transfer(msg.sender, _jar);

        return _jar;
    }

    // **** Primitive Tokens **** ///

    function primitiveToPickleJar(
        address underlying,
        uint256 amount,
        address jar
    ) public returns (uint256) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(underlying).safeApprove(jar, 0);
        IERC20(underlying).safeApprove(jar, amount);

        IJar(jar).deposit(amount);
        
        uint256 _jar = IJar(jar).balanceOf(address(this));
        IERC20(jar).safeTransfer(msg.sender, _jar);

        return _jar;
    }

    function pickleJarToPrimitive(
        address jar,
        uint256 amount,
        address underlying
    ) public returns (uint256) {
        IERC20(jar).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(jar).safeApprove(jar, 0);
        IERC20(jar).safeApprove(jar, amount);

        IJar(jar).withdrawAll();
        uint256 _underlying = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(msg.sender, _underlying);

        return _underlying;
    }

    // **** Curve **** //
    // Stupid non-standard API

    function primitiveToCurvePickleJar_2(
        address curve,
        address[2] memory underlying,
        uint256[2] memory underlyingAmounts,
        address curveLp,
        address pickleJar
    ) public returns (uint256) {
        // Primitive -> Curve LP
        for (uint256 i = 0; i < underlying.length; i++) {
            IERC20(underlying[i]).safeTransferFrom(
                msg.sender,
                address(this),
                underlyingAmounts[i]
            );

            IERC20(underlying[i]).safeApprove(curve, 0);
            IERC20(underlying[i]).safeApprove(curve, underlyingAmounts[i]);
        }

        ICurveFi_2(curve).add_liquidity(underlyingAmounts, 0);

        // Curve LP -> PickleJar
        return _curveLpToPickleJarAndRefund(curveLp, pickleJar);
    }

    function primitiveToCurvePickleJar_3(
        address curve,
        address[3] memory underlying,
        uint256[3] memory underlyingAmounts,
        address curveLp,
        address pickleJar
    ) public returns (uint256) {
        // Primitive -> Curve LP
        for (uint256 i = 0; i < underlying.length; i++) {
            IERC20(underlying[i]).safeTransferFrom(
                msg.sender,
                address(this),
                underlyingAmounts[i]
            );

            IERC20(underlying[i]).safeApprove(curve, 0);
            IERC20(underlying[i]).safeApprove(curve, underlyingAmounts[i]);
        }

        ICurveFi_3(curve).add_liquidity(underlyingAmounts, 0);

        // Curve LP -> PickleJar
        return _curveLpToPickleJarAndRefund(curveLp, pickleJar);
    }

    function primitiveToCurvePickleJar_4(
        address curve,
        address[4] memory underlying,
        uint256[4] memory underlyingAmounts,
        address curveLp,
        address pickleJar
    ) public returns (uint256) {
        // Primitive -> Curve LP
        for (uint256 i = 0; i < underlying.length; i++) {
            IERC20(underlying[i]).safeTransferFrom(
                msg.sender,
                address(this),
                underlyingAmounts[i]
            );

            IERC20(underlying[i]).safeApprove(curve, 0);
            IERC20(underlying[i]).safeApprove(curve, underlyingAmounts[i]);
        }

        ICurveFi_4(curve).add_liquidity(underlyingAmounts, 0);

        // Curve LP -> PickleJar
        return _curveLpToPickleJarAndRefund(curveLp, pickleJar);
    }

    // **** PickleJar **** //

    function curvePickleJarToPrimitive_1(
        address pickleJar,
        uint256 amount,
        address curveLp,
        address curve,
        int128 index,
        address underlying
    ) public returns (uint256) {
        IERC20(pickleJar).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(pickleJar).safeApprove(pickleJar, 0);
        IERC20(pickleJar).safeApprove(pickleJar, amount);

        IJar(pickleJar).withdraw(amount);

        uint256 curveLpAmount = IERC20(curveLp).balanceOf(address(this));

        IERC20(curveLp).safeApprove(curve, 0);
        IERC20(curveLp).safeApprove(curve, curveLpAmount);

        ICurveZap(curve).remove_liquidity_one_coin(
            curveLpAmount,
            index,
            uint256(0)
        );

        uint256 _underlying = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(msg.sender, _underlying);
        return _underlying;
    }

    function curvePickleJarToPrimitive_2(
        address pickleJar,
        uint256 amount,
        address curveLp,
        address curve,
        address[2] memory underlying
    ) public returns (uint256, uint256) {
        IERC20(pickleJar).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(pickleJar).safeApprove(pickleJar, 0);
        IERC20(pickleJar).safeApprove(pickleJar, amount);

        IJar(pickleJar).withdraw(amount);

        uint256 curveLpAmount = IERC20(curveLp).balanceOf(address(this));

        IERC20(curveLp).safeApprove(curve, 0);
        IERC20(curveLp).safeApprove(curve, curveLpAmount);

        ICurveFi_2(curve).remove_liquidity(
            curveLpAmount,
            [uint256(0), uint256(0)]
        );

        uint256[] memory ret = new uint256[](2);
        for (uint256 i = 0; i < underlying.length; i++) {
            uint256 _underlying = IERC20(underlying[i]).balanceOf(
                address(this)
            );
            IERC20(underlying[i]).safeTransfer(msg.sender, _underlying);
            ret[i] = _underlying;
        }
        return (ret[0], ret[1]);
    }

    function curvePickleJarToPrimitive_3(
        address pickleJar,
        uint256 amount,
        address curveLp,
        address curve,
        address[3] memory underlying
    )
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IERC20(pickleJar).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(pickleJar).safeApprove(pickleJar, 0);
        IERC20(pickleJar).safeApprove(pickleJar, amount);

        IJar(pickleJar).withdraw(amount);

        uint256 curveLpAmount = IERC20(curveLp).balanceOf(address(this));

        IERC20(curveLp).safeApprove(curve, 0);
        IERC20(curveLp).safeApprove(curve, curveLpAmount);

        ICurveFi_3(curve).remove_liquidity(
            curveLpAmount,
            [uint256(0), uint256(0), uint256(0)]
        );

        uint256[] memory ret = new uint256[](3);
        for (uint256 i = 0; i < underlying.length; i++) {
            uint256 _underlying = IERC20(underlying[i]).balanceOf(
                address(this)
            );
            IERC20(underlying[i]).safeTransfer(msg.sender, _underlying);
            ret[i] = _underlying;
        }
        return (ret[0], ret[1], ret[2]);
    }

    function curvePickleJarToPrimitive_4(
        address pickleJar,
        uint256 amount,
        address curveLp,
        address curve,
        address[4] memory underlying
    )
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        IERC20(pickleJar).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(pickleJar).safeApprove(pickleJar, 0);
        IERC20(pickleJar).safeApprove(pickleJar, amount);

        IJar(pickleJar).withdraw(amount);

        uint256 curveLpAmount = IERC20(curveLp).balanceOf(address(this));

        IERC20(curveLp).safeApprove(curve, 0);
        IERC20(curveLp).safeApprove(curve, curveLpAmount);

        ICurveFi_4(curve).remove_liquidity(
            curveLpAmount,
            [uint256(0), uint256(0), uint256(0), uint256(0)]
        );

        uint256[] memory ret = new uint256[](4);
        for (uint256 i = 0; i < underlying.length; i++) {
            uint256 _underlying = IERC20(underlying[i]).balanceOf(
                address(this)
            );
            IERC20(underlying[i]).safeTransfer(msg.sender, _underlying);
            ret[i] = _underlying;
        }
        return (ret[0], ret[1], ret[2], ret[3]);
    }
}