// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";

contract AcquisitionRoyalePartnership is Ownable {
    uint256 private _counter;
    mapping(address => uint256) private _partnerTokenIds;
    mapping(address => uint256) private _partnerTokenPrices;
    mapping(address => mapping(uint256 => uint256)) private _purchaseCounts;

    constructor() {}

    function addPartnership(
        address _partnerToken,
        uint256 _price,
        uint256 _supply
    ) external onlyOwner {
        _partnerTokenIds[_partnerToken] = _counter++;
        _partnerTokenPrices[_partnerToken] = _price;
        _purchaseCounts[address(this)][
            _partnerTokenIds[_partnerToken]
        ] += _supply;
    }

    function purchase(address _partnerToken, uint256 _quantity) external {
        require(_partnerTokenPrices[_partnerToken] > 0, "unsupported partner");
        require(
            _quantity <=
                balanceOf(address(this), _partnerTokenIds[_partnerToken]),
            "exceeds supply"
        );
        IERC20(_partnerToken).transferFrom(
            msg.sender,
            owner(),
            _partnerTokenPrices[_partnerToken] * _quantity
        );
        _transferFrom(
            address(this),
            msg.sender,
            _partnerTokenIds[_partnerToken],
            _quantity
        );
    }

    function getCounter() external view returns (uint256) {
        return _counter;
    }

    function getPartnerId(address _partnerToken)
        external
        view
        returns (uint256)
    {
        return _partnerTokenIds[_partnerToken];
    }

    function getPartnerPrice(address _partnerToken)
        external
        view
        returns (uint256)
    {
        return _partnerTokenPrices[_partnerToken];
    }

    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _purchaseCounts[account][id];
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        require(to != address(0), "transfer to the zero address");
        uint256 fromBalance = _purchaseCounts[from][id];
        require(fromBalance >= amount, "insufficient balance for transfer");
        unchecked {
            _purchaseCounts[from][id] = fromBalance - amount;
        }
        _purchaseCounts[to][id] += amount;
    }
}