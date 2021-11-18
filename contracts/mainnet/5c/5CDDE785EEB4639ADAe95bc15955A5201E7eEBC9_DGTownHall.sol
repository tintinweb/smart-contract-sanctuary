// SPDX-License-Identifier: DG

pragma solidity ^0.8.9;

import "./ERC20.sol";

interface DGToken {

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

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

contract DGTownHall is ERC20("External DG", "xDG") {

    DGToken public immutable DG;

    constructor(
        address _tokenAddress
    ) {
        DG = DGToken(
            _tokenAddress
        );
    }

    function stepInside(
        uint256 _DGAmount
    )
        external
    {
        uint256 DGTotal = innerSupply();
        uint256 xDGTotal = totalSupply();

        DGTotal == 0 || xDGTotal == 0
            ? _mint(msg.sender, _DGAmount)
            : _mint(msg.sender, _DGAmount * xDGTotal / DGTotal);

        DG.transferFrom(
            msg.sender,
            address(this),
            _DGAmount
        );
    }

    function stepOutside(
        uint256 _xDGAmount
    )
        external
    {
        uint256 transferAmount = _xDGAmount
            * innerSupply()
            / totalSupply();

        _burn(
            msg.sender,
            _xDGAmount
        );

        DG.transfer(
            msg.sender,
            transferAmount
        );
    }

    function DGAmount(
        address _account
    )
        external
        view
        returns (uint256)
    {
        return balanceOf(_account)
            * innerSupply()
            / totalSupply();
    }

    function outsidAmount(
        uint256 _xDGAmount
    )
        external
        view
        returns (uint256 _DGAmount)
    {
        return _xDGAmount
            * innerSupply()
            / totalSupply();
    }

    function insideAmount(
        uint256 _DGAmount
    )
        external
        view
        returns (uint256 _xDGAmount)
    {
        uint256 xDGTotal = totalSupply();
        uint256 DGTotal = innerSupply();

        return xDGTotal == 0 || DGTotal == 0
            ? _DGAmount
            : _DGAmount * xDGTotal / DGTotal;
    }

    function innerSupply()
        public
        view
        returns (uint256)
    {
        return DG.balanceOf(address(this));
    }
}