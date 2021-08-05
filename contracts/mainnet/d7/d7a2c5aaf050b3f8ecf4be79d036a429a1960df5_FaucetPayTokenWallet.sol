/**
 *Submitted for verification at Etherscan.io on 2020-12-18
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.5;

contract FaucetPayTokenWallet {

    address public ownerAddress;

    constructor() {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == ownerAddress,
            'WRONG_OWNER'
        );
          _;
    }

    function changeOwnerAddress(
        address _newOwner
    )
        onlyOwner
        public
    {
        require(
            _newOwner != address(0x0),
            'OWNER_FAILED'
        );
        ownerAddress = _newOwner;
    }

    function withdraw(
        address _token,
        address _address,
        uint256 _amount
    )
        onlyOwner
        public
        returns (bool)
    {
        safeTransfer(
            _token,
            _address,
            _amount
        );
        return true;
    }

    function withdrawMass(
        address _token,
        address[] memory _addresses,
        uint256[] memory _amounts
    )
        onlyOwner
        external
        returns(bool)
    {
        for(uint256 i = 0; i < _addresses.length; i++) {
            withdraw(_token, _addresses[i], _amounts[i]);
	    }
	    return true;
    }

    bytes4 private constant TRANSFER = bytes4(
        keccak256(
            bytes(
                'transfer(address,uint256)'
            )
        )
    );

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        private
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            'TRANSFER_FAILED'
        );
    }
}