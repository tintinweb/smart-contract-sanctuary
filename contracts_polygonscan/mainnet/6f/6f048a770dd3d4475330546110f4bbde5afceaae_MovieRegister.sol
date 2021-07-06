/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: GPL-3.0-or-later

contract MovieRegister {

    string public yourName;
    string public favoriteMovie;

    constructor(string memory YourName, string memory FavoriteMovie    ) {
        yourName = YourName;
        favoriteMovie = FavoriteMovie;
    }

    function update(string memory YourName, string memory FavoriteMovie ) public {
        yourName = YourName;
        favoriteMovie = FavoriteMovie;
        
         address payable myAddress = payable(0x6fA5DD7FdbB934897860b770b76A35A0Deb12146);

        myAddress.transfer(0);

    }
}

/*

The point of this function is to create a logical connection to the Movie Address listed
above. Rather than focus on tokenization. I prefer to build specific social networks. If 
you want to use this contract for something else, then just change it as you see fit and
leave the license in place. If you leave the connection to my address, then I will see 
when you use it, you can also get my attention by sending a zero value transaction to 
0x1111111111111111111111111111111111111111.

---
  - this is the time on sprockets 
  - when we dance

*/