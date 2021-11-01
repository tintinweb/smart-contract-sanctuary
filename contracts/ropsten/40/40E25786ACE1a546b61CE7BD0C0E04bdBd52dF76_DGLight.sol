// SPDX-License-Identifier: ---DG----

pragma solidity ^0.8.9;

import "./ERC20.sol";

interface IClassicDGToken {

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);
}

contract DGLight is ERC20("Decentral Games", "DG") {

    IClassicDGToken immutable public classicDG;
    uint16 constant public RATIO = 1000;

    constructor(
        address _classicDGTokenAddress
    ) {
        classicDG = IClassicDGToken(
            _classicDGTokenAddress
        );

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name())),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
    }

    function goLight(
        uint256 _classicAmountToDeposit
    )
        external
    {
        classicDG.transferFrom(
            msg.sender,
            address(this),
            _classicAmountToDeposit
        );

        _mint(
            msg.sender,
            _classicAmountToDeposit * RATIO
        );
    }

    function goClassic(
        uint256 _classicAmountToReceive
    )
        external
    {
        classicDG.transfer(
            msg.sender,
            _classicAmountToReceive
        );

        _burn(
            msg.sender,
            _classicAmountToReceive * RATIO
        );
    }
}