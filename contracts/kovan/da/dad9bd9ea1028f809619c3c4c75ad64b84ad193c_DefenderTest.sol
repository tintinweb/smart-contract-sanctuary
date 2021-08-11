/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity >=0.5.15 <0.6.0;

contract DefenderTest {
    address public proxy;
    address public owner;
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor (address _proxy) public {
        proxy = _proxy;
        owner = msg.sender;
    }

    // see: https://github.com/polynetwork/eth-contracts/blob/d16252b2b857eecf8e558bd3e1f3bb14cff30e9b/contracts/libs/utils/Utils.sol#L296
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function setProxy(address _proxy) onlyOwner external {
        require(isContract(_proxy));
        proxy = _proxy;
    }

    function updateProxy(address _proxy, address _implementation) onlyOwner external {
        bytes memory returnData;
        bool success;
        (success, returnData) = proxy.call(abi.encodePacked(bytes4(0x99a88ec4),abi.encode(_proxy, _implementation)));
        require(success == true);
    }

}