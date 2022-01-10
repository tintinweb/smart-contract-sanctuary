/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
* You could use this very simple example contract to test a deploy to the Mainnet
*/

contract HelloKbsb {

    string private shebang = "#!/kaboom/shebang";

    function printShebang() public view returns (string memory) {
        return shebang;
    }
}