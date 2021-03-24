/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

interface ERC20
{
    function balanceOf(address _who) view external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) view external returns (uint256);
}

contract TokenDrop
{
    using SafeMath for uint256;

    string constant internal ERROR_VALUE_NOT_VALID             = 'Reason: Value must be greater than 0.';
    string constant internal ERROR_BALANCE_NOT_ENOUGH          = 'Reason: Balance is not enough.';
    string constant internal ERROR_TOKEN_ADDRESS_NOT_VALID     = 'Reason: Token address is not valid.';
    string constant internal ERROR_NOT_VALID_RECEIVER_LIST     = 'Reason: Receiver list is not valid.';

    event Drop(address tokenAddress, address[] toList, uint256[] amountList);

    function drop(address _tokenAddress, address[] calldata _toList, uint256[] calldata _amountList) external
    {
        require(_tokenAddress != address(0), ERROR_TOKEN_ADDRESS_NOT_VALID);
        require(_toList.length == _amountList.length, ERROR_NOT_VALID_RECEIVER_LIST);

        uint256 sumOfAmounts = 0;
        for(uint256 i=0; i<_amountList.length; i++)
        {
            require(_amountList[i] != 0, ERROR_VALUE_NOT_VALID);

            sumOfAmounts = sumOfAmounts.add(_amountList[i]);
        }

        // 합계가 발란스보다 많은지 체크
        ERC20 token = ERC20(_tokenAddress);

        require(token.balanceOf(msg.sender) >= sumOfAmounts); // 발란스가 충분한지 체크

        for(uint256 i=0; i<_toList.length; i++)
        {
            token.transfer(_toList[i], _amountList[i]);
        }

        emit Drop(_tokenAddress, _toList, _amountList);
    }
}