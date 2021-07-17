/**
 *Submitted for verification at polygonscan.com on 2021-07-16
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: GPL-3.0-or-later

contract Token {

    string public name;
    string public title;
    string public description;
    string public fungible;
    string public count;
    string public location;
    
    string public owner;

    function create (
       string memory Name,
       string memory Title,
       string memory Description,
       string memory Fungible,
       string memory Count,
       string memory Location ) public
   {
       name = Name;
       title = Title;
       description = Description;
       fungible = Fungible;
       count = Count;
       location = Location;
    }

    function transfer (
       string memory Owner ) public
    {
       owner = Owner;
    }
 }