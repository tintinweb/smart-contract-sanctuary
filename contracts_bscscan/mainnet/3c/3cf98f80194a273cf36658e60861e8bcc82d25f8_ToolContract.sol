/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

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
        return msg.data;
    }
}

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

library StringUtil {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

}

contract ToolContract is Ownable {

    using StringUtil for *;

    mapping(string => uint8) public whitelist;

    function addWhitelist(string memory newWhitelist) public onlyOwner {
        StringUtil.slice memory s = newWhitelist.toSlice();
        StringUtil.slice memory delim = ",".toSlice();
        uint256 len=s.count(delim) + 1;
        for (uint i = 0; i < len; i++) {
            string memory str=s.split(delim).toString();
//            if (whitelist[str] == 0)
            {
                whitelist[str] = 1;
            }
        }
    }

    function checkExistWhitelist(address addr) public view returns(bool)
    {
        return whitelist[toAsciiString(addr)] == 1;
    }

    function updateWhitelist(address addr) public
    {
        whitelist[toAsciiString(addr)]=2;
    }

    //length:40
    function toAsciiString(address x) public pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) public pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }


    function getTokenURIBase() public pure returns (string memory) {
        return '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" id="1"    xmlns="http://www.w3.org/2000/svg"    xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="750px" height="750px" viewBox="0 0 750 750" style="enable-background:new 0 0 750 750;" xml:space="preserve">    <style type="text/css">.st0{fill:#023E6B;}.st1{fill:#05517F;stroke:#05517F;stroke-width:3;stroke-miterlimit:10;}.st2{fill:#FFFFFF;}</style>    <title>image</title>    <rect class="st0" width="750" height="750"/>    <path class="st1" d="M84.7,100.35H64.12V58.28h20.12c11.58-0.15,17.3,3.36,17.15,10.52c-0.13,3.81-2.2,7.28-5.49,9.2c4.57,1.37,6.93,4.57,7.09,9.6C103.14,96.11,97.05,100.36,84.7,100.35z M82.87,68.11h-4.81V75h5.72c3.2,0,4.8-1.22,4.8-3.66C88.73,68.89,86.83,67.81,82.87,68.11z M82.41,82.75h-4.35v7.77h6c4.11,0.15,6.09-1.14,5.94-3.89C90.28,83.74,87.75,82.44,82.41,82.75z"/>    <path class="st1" d="M142.54,100.35H130l-0.46-3.2c-2.74,2.6-6.63,3.81-11.66,3.66c-7.01-0.31-10.67-3.29-11-8.92c0-5.63,4.88-9.06,14.63-10.29c4.88-0.45,7.32-1.45,7.32-3c0-1.67-1.38-2.51-4.12-2.51c-2.59,0-4,1-4.12,3h-11.66c-0.15-6.86,5.41-10.29,16.69-10.29c11.28-0.46,16.39,3.81,15.32,12.8v14.18c-0.15,1.83,0.38,3.13,1.6,3.89L142.54,100.35z M123.34,94.41c3.81,0,5.64-2.52,5.49-7.55c-1.39,0.58-2.85,0.97-4.35,1.14c-3.51,0.45-5.18,1.68-5,3.65C119.61,93.34,120.89,94.26,123.34,94.41z"/>    <path class="st1" d="M180.5,100.35h-10.75v-4.11c-2.24,3.03-5.84,4.74-9.6,4.57c-8.84-0.31-13.51-5.42-14-15.32c0.46-10.36,4.79-15.92,13-16.69c3.96-0.15,7.01,1.15,9.14,3.89V58.28h12.21V100.35z M163.35,92.35c3.51,0,5.34-2.36,5.49-7.09c-0.15-4.72-1.9-7.08-5.26-7.09c-3.2,0.16-4.87,2.6-5,7.32C158.56,90.06,160.15,92.35,163.35,92.35z"/>    <path class="st1" d="M186.9,101.5H199c0.17,0.49,0.4,0.95,0.69,1.37c0.83,0.48,1.78,0.71,2.74,0.68c3.35,0.15,5-1.67,4.8-5.48v-2.52c-2,2.29-4.89,3.44-8.68,3.43c-8.24-0.46-12.66-5.34-13.27-14.63c0.48-10.06,5.05-15.24,13.72-15.55c3.7,0.01,7.15,1.89,9.15,5v-4.09h10.75v24.7c1.06,11.12-4.27,16.45-16,16C193.15,110.26,187.81,107.29,186.9,101.5z M202.22,77.5c-3.2,0-4.8,2.36-4.8,7.09c0.15,3.65,1.75,5.64,4.8,5.94c3.21,0,4.88-2.13,5-6.4c0.03-4.43-1.64-6.64-5-6.64V77.5z"/>    <path class="st1" d="M259.39,87.78h-23.33c0.31,3.66,2.37,5.64,6.18,5.94c1.87,0.06,3.62-0.9,4.57-2.51h11.43c-1.82,6.25-7.46,9.45-16.92,9.6c-11.13-0.31-16.92-5.5-17.37-15.55c0.6-10.36,6.39-15.85,17.37-16.46C253.06,69.41,259.08,75.74,259.39,87.78z M236.06,81.6h11.21c-0.31-3.2-2.14-4.95-5.49-5.26C238.12,76.34,236.21,78.1,236.06,81.6z"/>    <path class="st2" d="M84.7,100.35H64.12V58.28h20.12c11.58-0.15,17.3,3.36,17.15,10.52c-0.13,3.81-2.2,7.28-5.49,9.2c4.57,1.37,6.93,4.57,7.09,9.6C103.14,96.11,97.05,100.36,84.7,100.35z M82.87,68.11h-4.81V75h5.72c3.2,0,4.8-1.22,4.8-3.66C88.73,68.89,86.83,67.81,82.87,68.11z M82.41,82.75h-4.35v7.77h6c4.11,0.15,6.09-1.14,5.94-3.89C90.28,83.74,87.75,82.44,82.41,82.75z"/>    <path class="st2" d="M142.54,100.35H130l-0.46-3.2c-2.74,2.6-6.63,3.81-11.66,3.66c-7.01-0.31-10.67-3.29-11-8.92c0-5.63,4.88-9.06,14.63-10.29c4.88-0.45,7.32-1.45,7.32-3c0-1.67-1.38-2.51-4.12-2.51c-2.59,0-4,1-4.12,3h-11.66c-0.15-6.86,5.41-10.29,16.69-10.29c11.28-0.46,16.39,3.81,15.32,12.8v14.18c-0.15,1.83,0.38,3.13,1.6,3.89L142.54,100.35z M123.34,94.41c3.81,0,5.64-2.52,5.49-7.55c-1.39,0.58-2.85,0.97-4.35,1.14c-3.51,0.45-5.18,1.68-5,3.65C119.61,93.34,120.89,94.26,123.34,94.41z"/>    <path class="st2" d="M180.5,100.35h-10.75v-4.11c-2.24,3.03-5.84,4.74-9.6,4.57c-8.84-0.31-13.51-5.42-14-15.32c0.46-10.36,4.79-15.92,13-16.69c3.96-0.15,7.01,1.15,9.14,3.89V58.28h12.21V100.35z M163.35,92.35c3.51,0,5.34-2.36,5.49-7.09c-0.15-4.72-1.9-7.08-5.26-7.09c-3.2,0.16-4.87,2.6-5,7.32C158.56,90.06,160.15,92.35,163.35,92.35z"/>    <path class="st2" d="M186.9,101.5H199c0.17,0.49,0.4,0.95,0.69,1.37c0.83,0.48,1.78,0.71,2.74,0.68c3.35,0.15,5-1.67,4.8-5.48v-2.52c-2,2.29-4.89,3.44-8.68,3.43c-8.24-0.46-12.66-5.34-13.27-14.63c0.48-10.06,5.05-15.24,13.72-15.55c3.7,0.01,7.15,1.89,9.15,5v-4.09h10.75v24.7c1.06,11.12-4.27,16.45-16,16C193.15,110.26,187.81,107.29,186.9,101.5z M202.22,77.5c-3.2,0-4.8,2.36-4.8,7.09c0.15,3.65,1.75,5.64,4.8,5.94c3.21,0,4.88-2.13,5-6.4c0.03-4.43-1.64-6.64-5-6.64V77.5z"/>    <path class="st2" d="M259.39,87.78h-23.33c0.31,3.66,2.37,5.64,6.18,5.94c1.87,0.06,3.62-0.9,4.57-2.51h11.43c-1.82,6.25-7.46,9.45-16.92,9.6c-11.13-0.31-16.92-5.5-17.37-15.55c0.6-10.36,6.39-15.85,17.37-16.46C253.06,69.41,259.08,75.74,259.39,87.78z M236.06,81.6h11.21c-0.31-3.2-2.14-4.95-5.49-5.26C238.12,76.34,236.21,78.1,236.06,81.6z"/><text id="Male-Demons-Chaotic" font-family="Georgia" font-size="28" font-weight="normal" line-spacing="44" fill="#FFFFFF"><tspan x="60" y="212">';
    }


}