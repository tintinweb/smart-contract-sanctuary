// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

contract BeinBuildERC20Bridge is Context {
    event Response(bool success, bytes data);

    // transfer erc20 (original) to another chain
    event Lock(address sourceERC20, address destERC20, address receiverAddress, uint256 value);

    // transfer erc20 (not original) to another chain
    event Burn(address sourceERC20, address destERC20, address receiverAddress, uint256 value);

    event Unlock(address destERC20, address receiverAddress, uint256 value);
    event Mint(address destERC20, address receiverAddress, uint256 value);

    address public admin;   

    // bridgeDirection is "BSC TO BIC" OR "BIC TO BSC"
    // it depends on which chain this smart contract is lying on
    string public bridgeDirection;

    // Mapping from erc20 contract address on source chain to erc20 contract address on dest chain
    mapping (address => address) public addressMap;

    mapping (address => bool) public isOriginal;

    constructor(string memory _bridgeDirection) {
        admin = _msgSender();
        bridgeDirection = _bridgeDirection;
    }

    modifier onlyAdmin() {
        require(_msgSender() == admin, "restrict to admin");
        _;
    }

    function grantAdminRole(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    function buildOneWayBridge(
        address _sourceERC20, 
        address _destERC20, 
        bool _toOriginal
    ) public onlyAdmin {
        require(addressMap[_sourceERC20] == address(0), "bridge existed");
        isOriginal[_sourceERC20] = !_toOriginal;
        addressMap[_sourceERC20] = _destERC20;
    }

    // transfer erc20 from one chain to another chain by:
    // locking token () when erc20 is original on current chain
    // or burning token when erc20 is original on another chain
    function transferToOtherChain(
        address _sourceERC20, 
        address _receiverAddress, 
        uint256 _value
    ) public { 
        require(addressMap[_sourceERC20] != address(0), "bridge is not existed");
        require(_receiverAddress != address(0), "can not transfer to address 0");

        if (isOriginal[_sourceERC20]) {
            (bool success, bytes memory data) = _sourceERC20.call(
                abi.encodeWithSignature("transferFrom(address,address,uint256)", _msgSender(), address(this), _value)
            );
            emit Response(success, data);
            require(success, "tx failed when send token to bridger");
            emit Lock(_sourceERC20, addressMap[_sourceERC20], _receiverAddress, _value);
        } else {
            (bool success, bytes memory data) = _sourceERC20.call(
                abi.encodeWithSignature("burn(address,uint256)", _msgSender(), _value)
            );
            emit Response(success, data);
            require(success, "tx failed when burn token");
            emit Burn(_sourceERC20, addressMap[_sourceERC20], _receiverAddress, _value);
        }
    }

    // bridger handles the 
    function handleOnDestChain(
        address _destERC20, 
        address _receiverAddress, 
        uint256 _value
    ) public onlyAdmin {
        if (isOriginal[_destERC20]) {
            (bool success, bytes memory data) = _destERC20.call(
                abi.encodeWithSignature("transfer(address,uint256)", _receiverAddress, _value)
            );
            emit Response(success, data);
            require(success, "fail when bridger handles tx on dest chain");
            emit Unlock(_destERC20, _receiverAddress, _value);
        } else {
            (bool success, bytes memory data) = _destERC20.call(
                abi.encodeWithSignature("mint(address,uint256)", _receiverAddress, _value)
            );
            emit Response(success, data);
            require(success, "fail when bridger handles tx on dest chain");
            emit Mint(_destERC20, _receiverAddress, _value);
        }
    } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

