/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}

contract EthSpreader {
    using SafeERC20 for IERC20;

    function spreadWithCall(address payable[] calldata _addresses, uint256[] memory _amounts) public payable {
        require(_addresses.length > 0, 'addresses size should bigger than 0');
        require(_addresses.length == _amounts.length, 'invalid inputs');

        for (uint256 i = 0; i < _addresses.length; i++) {
            (bool success, ) = _addresses[i].call{value:_amounts[i]}('');
            require(success, 'fail to transfer funds using address.call');
        }
    }

    function spreadWithTransfer(address payable[] calldata _addresses, uint256[] memory _amounts) public payable {
        require(_addresses.length > 0, 'addresses size should bigger than 0');
        require(_addresses.length == _amounts.length, 'invalid inputs');

        for (uint256 i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(_amounts[i]);
        }
    }

    function spreadToken(address _tokenAddress, address payable[] calldata _addresses, uint256[] memory _amounts) public payable {
        require(_addresses.length > 0, 'addresses size should bigger than 0');
        require(_addresses.length == _amounts.length, 'invalid inputs');

        for (uint256 i = 0; i < _addresses.length; i++) {
            require(IERC20(_tokenAddress).balanceOf(address(this)) > 0, 'insufficient balance');
            IERC20(_tokenAddress).safeTransfer(_addresses[i], _amounts[i]);
        }
    }

    function payableRevert() public payable {
        revert();
    }

    receive() external payable {}
}