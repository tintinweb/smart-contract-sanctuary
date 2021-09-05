/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

pragma solidity 0.5.1;

//fl465734l3r


contract CTF {
    
    bytes x;
    bytes y;
    bytes z;
    bytes w;
    address owner;
    
    
    constructor() public {
        owner = msg.sender;
    }
    
    function encoder(string memory str) public returns (bytes memory) {
        require(msg.sender == owner);
        
        bytes memory flag = bytes(str);
        for (uint256 i = 0; i < flag.length; i++) {
            if (i < 1) {
                x.push(flag[i]);
            } else {
                x.push(flag[i] ^ flag[i - 1]);
            }
        }

        for (uint256 i = 0; i < flag.length; i++) {
            if (i < 1) {
                y.push(x[i]);
            } else {
                y.push(
                    x[i] ^ x[i - 1]
                );
            }
        }

        for (uint256 i = 0; i < flag.length; i++) {
            z.push(y[i] ^ 0xff);
        }
        for (uint256 i = 0; i < flag.length; i++) {
            w.push(z[flag.length - i - 1]);
        }

        return w;
    }

    function decoder() public pure returns (string memory) {
        return "Develop it";
    }

    function encoded_flag() public pure returns (string memory) {
        return "0xeab1e5f8faf8bdbdb8bdd2ff908690849195ac93ca93c3d2a0c994d690e089d28c96fea58dcc8fcef8e8bbc4f1fbd0fafef1feb2ab";
    }

    function about() public pure returns (string memory) {
        return "Develop a decoder to get the flag";
    }
}