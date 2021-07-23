/**
 *Submitted for verification at polygonscan.com on 2021-07-23
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: GPL-3.0-or-later

contract URL {

    string public url;
    string public title;
    string public category;
    address public index;
 
    function record (
       string memory Url,
       string memory Title,
       string memory Category,
       address payable Index
              ) public
   {
       url = Url;
       title = Title;
       category = Category;
       index = Index;

// You can correctly fill this out
// through Polyscan, but you need
// to do a bit of calcution.
//
// You will also need to initialize
// each index to your account
// by sending a zero amount
// transaction to it.
//
// The majority of the work is
// done outside of the smart
// contract, but it is not
// hard to figure out.
//
// Here is an example, I want to
// create a YouTube reference
// so I figure out the address
// echo -n "YouTube" | xxd -p -r
// echo -n "https://youtube.com " | xxd -p -c 20
// 68747470733a2f2f796f75747562652e636f6d20
//
// You have to add the '0x' to the
// beginning, Paste this into the
// contract and then you will need
// to also send it one time from your
// account. You also need to make a
// one-time empty payment to
// 0x1111111111111111111111111111111111111111
// from the account.
// Then it is logically possible to
// find you from the polyscan api
// and figure out that you are posting to
// a youtube index and finally discover
// your message.
//
// This system may seem overly simplistic
// but it just does all of its heavy
// lifting outside of solidity
//
// https://www.linkedin.com/in/jrigler/


    }
}