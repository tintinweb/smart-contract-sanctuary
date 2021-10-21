/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title FanFanStorage
 * @dev Store & retrieve a list of cryptos 
 */
contract StorageFanFan {

    struct Crypto {
        string name;
        uint amount;
        string platform;
    }
    
    Crypto[] cryptos;

    /**
     * @dev Store value in variable
     * @param _cryptoName name of coin
     * @param _amount amount of coin
     * @param _platform name of exchange
     */
    function FanFanStore(string memory _cryptoName, uint _amount, string memory _platform) public {
        cryptos.push(Crypto(_cryptoName, _amount, _platform));
    }

    /**
     * @dev Return value 
     * @return list of cryptos
     */
    function FanFanRetrieve() public view returns (Crypto[] memory){
        return cryptos;
    }
}