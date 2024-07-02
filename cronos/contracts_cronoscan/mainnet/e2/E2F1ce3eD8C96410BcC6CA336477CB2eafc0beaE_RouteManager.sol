/**
 *Submitted for verification at cronoscan.com on 2022-05-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IRouteStorage {
    function setRouterPath(address inputToken, address outputToken, address[] memory _path, bool overwrite) external;
    function getRouterPath(address inputToken, address outputToken) external view returns (address[] memory);
}

abstract contract Constants {
    address constant usdtAddr = 0x66e428c3f67a68878562e79A0234c1F83c208770;
    address constant btcbAddr = 0x062E66477Faf219F25D27dCED647BF57C3107d52;
    address constant wethAddr = 0xe44Fd7fCb2b1581822D0c862B68222998a0c299a;
    address constant daiAddr = 0xF2001B145b43032AAF5Ee2884e456CCd805F677D;
    address constant usdcAddr = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;
    address constant wcroAddr = 0x5C7F8A570d578ED84E63fdFA7b1eE72dEae1AE23;
    address constant smxAddr = 0x53B988068cb6f8CB87c6428307e5f642e473D820;

    address constant routerAddr = 0xFc0D2D06Efe8d44F3EeCc8e1Df7c1509F7bA8e31;
    address constant burnAddr = 0x000000000000000000000000000000000000dEaD;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'no whitelist');
        _;
    }

    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
        return success;
    }

    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
        return success;
    }

    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
        return success;
    }
}

/*
  ____  _                         _                     _              
 / ___|| |_ _ __ ___  _ __   __ _| |__   __ _ _ __   __| |___          
 \___ \| __| '__/ _ \| '_ \ / _` | '_ \ / _` | '_ \ / _` / __|         
  ___) | |_| | | (_) | | | | (_| | | | | (_| | | | | (_| \__ \         
 |____/ \__|_|  \___/|_| |_|\__, |_| |_|\__,_|_| |_|\__,_|___/         
  __  __                    |___/ ____            _                  _ 
 |  \/  | ___  _ __   ___ _   _  |  _ \ _ __ ___ | |_ ___   ___ ___ | |
 | |\/| |/ _ \| '_ \ / _ \ | | | | |_) | '__/ _ \| __/ _ \ / __/ _ \| |
 | |  | | (_) | | | |  __/ |_| | |  __/| | | (_) | || (_) | (_| (_) | |
 |_|  |_|\___/|_| |_|\___|\__, | |_|   |_|  \___/ \__\___/ \___\___/|_|
                          |___/                                        
RouteStorage - to ensure stability of trade within the ecosystem
*/

contract RouteManager is Whitelist, Constants, IRouteStorage {

    //mapping(InputToken => mapping(OutputToken => path))
    mapping(address => mapping(address => address[])) public paths;

    constructor() public {

        paths[usdcAddr][usdtAddr] = [usdcAddr, usdtAddr];
        paths[usdtAddr][usdcAddr] = [usdtAddr, usdcAddr];

        paths[wcroAddr][smxAddr] = [wcroAddr, smxAddr];
        paths[smxAddr][wcroAddr] = [smxAddr, wcroAddr];

        paths[usdcAddr][wcroAddr] = [usdcAddr, wcroAddr];
        paths[wcroAddr][usdcAddr] = [wcroAddr, usdcAddr];

        paths[usdcAddr][smxAddr] = [usdcAddr, smxAddr];
        paths[smxAddr][usdcAddr] = [smxAddr, usdcAddr];
    }

    function getRouterPath(address inputToken, address outputToken) override external view returns (address[] memory){
        address[] storage path = paths[inputToken][outputToken];
        require(path.length > 0, "getRouterPath: MISSING PATH");
        return path;
    }

    function setRouterPath(address inputToken, address outputToken, address[] memory _path, bool overwrite) override external onlyWhitelisted {
        address[] storage path = paths[inputToken][outputToken];
        uint256 length = _path.length;
        if (!overwrite) {
            require(path.length == 0, "setRouterPath: ALREADY EXIST");
        }
        for (uint256 i = 0; i < length; i++) {
            path.push(_path[i]);
        }
    }
}