// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface ILockable {

    event Locked();
    event Unlocked();

    function lock() external /* onlyLockOwner */;
    function unlock() external /* onlyLockOwner */;
    function isLocked() view external returns (bool);

}
