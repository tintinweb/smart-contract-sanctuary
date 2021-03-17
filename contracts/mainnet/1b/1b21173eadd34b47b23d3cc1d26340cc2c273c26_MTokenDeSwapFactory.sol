//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;
import "./Claimable.sol";
import "./CanReclaimToken.sol";
import "./MTokenDeSwap.sol";
import "./TransparentUpgradeableProxy.sol";

contract MTokenDeSwapFactory is Claimable, CanReclaimToken {
    mapping(bytes32 => address) public deSwaps;

    function getDeSwap(string memory _nativeCoinType)
        public
        view
        returns (address)
    {
        bytes32 nativeCoinTypeHash =
            keccak256(abi.encodePacked(_nativeCoinType));
        return deSwaps[nativeCoinTypeHash];
    }

    function deployDeSwap(
        address _mtoken,
        string memory _nativeCoinType,
        address _mtokenRepository,
        address _operator
    ) public onlyOwner returns (bool) {
        bytes32 nativeCoinTypeHash =
            keccak256(abi.encodePacked(_nativeCoinType));
        require(_operator!=_owner(), "owner same as _operator");
        require(deSwaps[nativeCoinTypeHash] == (address)(0), "deEx exists.");
        MTokenDeSwap mtokenDeSwap = new MTokenDeSwap();
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(
                (address)(mtokenDeSwap),
                (address)(this),
                abi.encodeWithSignature(
                    "setup(address,string,address,address)",
                    _mtoken,
                    _nativeCoinType,
                    _mtokenRepository,
                    _operator
                )
            );

        proxy.changeAdmin(_owner());
        deSwaps[nativeCoinTypeHash] = (address)(proxy);

        return true;
    }
}