//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


contract CollectABallRoyaltiesDistribution {

    address private constant ARTIST_WALLET = 0x113Aed406B5f22190726F9C8B51d50e74569A98D;
    address private constant DEV_WALLET = 0x291f158F42794Db959867528403cdb382DbECfA3;
    address private constant FOUNDER_WALLET = 0xd04a78A2cF122e7bC7F96Bf90FB984000436CFCd;

    receive() external payable {
        withdrawAll();
    }

    function contractBalance() private view returns(uint256) {
        return address(this).balance;
    }
        
    function withdrawAll() private {
        uint256 balance = contractBalance();
        require(balance > 0, "The balance is 0");
        _withdraw(DEV_WALLET, (balance * 10)/100);
        _withdraw(ARTIST_WALLET, (balance * 10)/100);
        _withdraw(FOUNDER_WALLET, contractBalance());
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call { value: _amount}("");
        require(success, "failed with withdraw");
    }
}