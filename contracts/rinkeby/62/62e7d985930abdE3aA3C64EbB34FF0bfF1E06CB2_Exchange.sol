/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

abstract contract IAppleSillicon {
    function balanceOf(address account) public view virtual returns (uint256);

    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool);
}

contract Exchange {
    address public tokenAddress;
    IAppleSillicon token;

    function setTokenAddress(address _tokenAddress) public {
        token = IAppleSillicon(_tokenAddress);
        tokenAddress = _tokenAddress;
    }

    function contractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transferToken(address _reciepent, uint256 _amount) public {
        require(_amount <= contractTokenBalance());
        token.transfer(_reciepent, _amount);
    }
}