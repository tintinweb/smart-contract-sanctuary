/**
 *Submitted for verification at Etherscan.io on 2020-12-05
*/

// SPDX-License-Identifier: MIT

//
//   ██████  ██▓███   ██▓    ▄▄▄        ██████  ██░ ██ ▓█████ ▓█████▄       ██▓ ▒█████
// ▒██    ▒ ▓██░  ██▒▓██▒   ▒████▄    ▒██    ▒ ▓██░ ██▒▓█   ▀ ▒██▀ ██▌     ▓██▒▒██▒  ██▒
// ░ ▓██▄   ▓██░ ██▓▒▒██░   ▒██  ▀█▄  ░ ▓██▄   ▒██▀▀██░▒███   ░██   █▌     ▒██▒▒██░  ██▒
//   ▒   ██▒▒██▄█▓▒ ▒▒██░   ░██▄▄▄▄██   ▒   ██▒░▓█ ░██ ▒▓█  ▄ ░▓█▄   ▌     ░██░▒██   ██░
// ▒██████▒▒▒██▒ ░  ░░██████▒▓█   ▓██▒▒██████▒▒░▓█▒░██▓░▒████▒░▒████▓  ██▓ ░██░░ ████▓▒░
// ▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░░ ▒░▓  ░▒▒   ▓▒█░▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░░ ▒░ ░ ▒▒▓  ▒  ▒▓▒ ░▓  ░ ▒░▒░▒░
// ░ ░▒  ░ ░░▒ ░     ░ ░ ▒  ░ ▒   ▒▒ ░░ ░▒  ░ ░ ▒ ░▒░ ░ ░ ░  ░ ░ ▒  ▒  ░▒   ▒ ░  ░ ▒ ▒░
// ░  ░  ░  ░░         ░ ░    ░   ▒   ░  ░  ░   ░  ░░ ░   ░    ░ ░  ░  ░    ▒ ░░ ░ ░ ▒
//       ░               ░  ░     ░  ░      ░   ░  ░  ░   ░  ░   ░      ░   ░      ░ ░
//
//
// ███████╗████████╗ █████╗ ██╗  ██╗██╗███╗   ██╗ ██████╗      ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  █████╗  ██████╗████████╗
// ██╔════╝╚══██╔══╝██╔══██╗██║ ██╔╝██║████╗  ██║██╔════╝     ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
// ███████╗   ██║   ███████║█████╔╝ ██║██╔██╗ ██║██║  ███╗    ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝███████║██║        ██║
// ╚════██║   ██║   ██╔══██║██╔═██╗ ██║██║╚██╗██║██║   ██║    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██╔══██║██║        ██║
// ███████║   ██║   ██║  ██║██║  ██╗██║██║ ╚████║╚██████╔╝    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║  ██║╚██████╗   ██║
// ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝      ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝


// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.7.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

pragma solidity ^0.7.0;

contract SPLASH_Staking is Context {
    address private _owner;
    string private _name = "Staking contract of SPLASHED.IO";
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = address(0);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }
}