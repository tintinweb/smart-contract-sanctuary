// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./ContextMixin.sol";

import "./OwnableInitializable.sol";
import "./NativeMetaTransaction.sol";
import {SafeMath} from "./SafeMath.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Tips is OwnableInitializable, NativeMetaTransaction {
    using SafeMath for uint256;

    uint256 public ownerCutPerMillion;

    event ChangedOwnerCutPerMillion(uint256 ownerCutPerMillion);
    event TippedToken(
        address tokenAddress,
        address _to,
        address _from,
        uint256 _amount
    );

    constructor(uint256 _ownerCutPerMillion) {
        // EIP712 init
        _initializeEIP712("Amnesia Tips", "1");
        // Ownable init
        _initOwnable();
        require(
            _ownerCutPerMillion >= 0 && _ownerCutPerMillion <= 1000000,
            "Invalid commission rate"
        );
        ownerCutPerMillion = _ownerCutPerMillion;
    }

    /**
     * @dev Sets the share cut for the owner of the contract that's
     *  charged to the seller on a successful sale
     * @param _ownerCutPerMillion - Share amount, from 0 to 999,999
     */
    function setOwnerCutPerMillion(uint256 _ownerCutPerMillion)
        external
        onlyOwner
    {
        require(
            _ownerCutPerMillion < 1000000,
            "The owner cut should be between 0 and 999,999"
        );

        ownerCutPerMillion = _ownerCutPerMillion;
        emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
    }

    function tipToken(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) public {
        require(_amount > 0, "Amount should be > 0");

        IERC20 token = IERC20(_tokenAddress);

        require(
            token.allowance(_msgSender(), address(this)) >= _amount,
            "Not allowed"
        );

        uint256 saleShareAmount = 0;

        if (ownerCutPerMillion > 0) {
            // Calculate sale share
            saleShareAmount = _amount.mul(ownerCutPerMillion).div(1000000);

            // Transfer share amount for marketplace Owner
            require(
                token.transferFrom(_msgSender(), owner(), saleShareAmount),
                "Transfer cut failed"
            );
        }

        // Transfer sale amount to seller
        require(
            token.transferFrom(_msgSender(), _to, _amount.sub(saleShareAmount)),
            "Transfer tip failed"
        );

        emit TippedToken(_tokenAddress, _to, _msgSender(), _amount);
    }
}