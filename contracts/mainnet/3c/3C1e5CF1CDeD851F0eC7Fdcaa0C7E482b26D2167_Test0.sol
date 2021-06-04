/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test0 {

	address public update = 0x740a637ADD6492e5FaA907AF0fe708770B737058;

    string[12] artifact = ["QmQdb77jfHZSwk8dGpN3mqx8q4N7EUNytiAgEkXrMPbMVw", //State 1
                           "QmS3kaQnxb28vcXQg35PrGarJKkSysttZdNLdZp3JquttQ", //State 2
                           "QmX8beRtZAsed6naFWqddKejV33NoXotqZoGTuDaV5SHqN", //State 3
                           "QmQvsAMYzJm8kGQ7YNF5ziWUb6hr7vqdmkrn1qEPDykYi4", //State 4
                           "QmZwHt9ZhCgVMqpcFDhwKSA3higVYQXzyaPqh2BPjjXJXU", //State 5
                           "Qmd2MNfgzPYXGMS1ZgdsiWuAkriRRx15pfRXU7ZVK22jce", //State 6
                           "QmWcYzNdUYbMzrM7bGgTZXVE4GBm7v4dQneKb9fxgjMdAX", //State 7
                           "QmaXX7VuBY1dCeK78TTGEvYLTF76sf6fnzK7TJSni4PHxj", //State 8
                           "QmaqeJnzF2cAdfDrYRAw6VwzNn9dY9bKTyUuTHg1gUSQY7", //State 9
                           "QmSZquD6yGy5QvsJnygXUnWKrsKJvk942L8nzs6YZFKbxY", //State 10
                           "QmYtdrfPd3jAWWpjkd24NzLGqH5TDsHNvB8Qtqu6xnBcJF", //State 11
                           "QmesagGNeyjDvJ2N5oc8ykBiwsiE7gdk9vnfjjAe3ipjx4"];//State 12


    function tokenIPFSHash(uint256 tokenId) external view returns (string memory) {

        DateTimeAPI dateTime = DateTimeAPI(update);
    
        uint value = dateTime.getMonth(block.timestamp);

        if (value == 1) {
            return artifact[0];
        }
        if (value == 2) {
            return artifact[1];
        }
        if (value == 3) {
            return artifact[2];
        }
        if (value == 4) {
            return artifact[3];
        }
        if (value == 5) {
            return artifact[4];
        }
        if (value == 6) {
            return artifact[5];
        }
        if (value == 7) {
            return artifact[6];
        }
        if (value == 8) {
            return artifact[7];
        }
        if (value == 9) {
            return artifact[8];
        }
        if (value == 10) {
            return artifact[9];
        }
        if (value == 11) {
            return artifact[10];
        }
        return artifact[11];
    }
}

abstract contract DateTimeAPI {
    function getMonth(uint timestamp) public view virtual returns (uint8);
}