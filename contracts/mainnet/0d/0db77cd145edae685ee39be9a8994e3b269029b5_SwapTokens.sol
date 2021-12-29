/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract SwapTokens {
    address public owner;
    address public wol;
    address public adam;

    uint256 public feePercent;
    uint256 public percentDivider;

    modifier onlyOwner() {
        require(msg.sender == owner, "Owned: Not an owner");
        _;
    }

    constructor(
        address _owner,
        address _wol,
        address _adam
    ) {
        owner = _owner;
        wol = _wol;
        adam = _adam;
        feePercent = 11111111111;
        percentDivider = 100000000000;
    }

    function swap(
        address _token1,
        address _token2,
        uint256 _amount
    ) public {
        IBEP20(_token1).transferFrom(msg.sender, owner, _amount);
        if (_token2 == adam) {
            IBEP20(_token2).transferFrom(owner, msg.sender, _amount);
        } else {
            uint256 _feeAmount = _amount * feePercent / percentDivider;
            IBEP20(_token2).transferFrom(owner, msg.sender, _amount + _feeAmount);
        }
    }

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function changeWol(address _token) public onlyOwner {
        wol = _token;
    }

    function changeAdam(address _token) public onlyOwner {
        adam = _token;
    }

    function changeFeePercent(uint256 _percent, uint256 _divider) public onlyOwner {
        feePercent = _percent;
        percentDivider = _divider;
    }
}