/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract PriceFeed {

    event UpdatePrice(
        address _token,
        uint _price,
        uint _createdAt
    );

    mapping(address => uint) private _tokenPrice;


    function _updatePrice(
        address _token,
        uint _price
    )
        internal
    {
        _tokenPrice[_token] = _price;
        emit UpdatePrice(_token, _price, block.timestamp);
    }

    function updatePrice(
        address _token,
        uint _price
    )
        public
    {
        _updatePrice(_token, _price);
    }

    function getPrice(
        address _token
    )
        public
        view
        returns(uint)
    {
        return _tokenPrice[_token];
    }
}