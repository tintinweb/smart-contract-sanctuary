/*
MIT License

Copyright (c) 2021 Joshua Iván Mendieta Zurita

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.9;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'ConsumerRole' to manage this role - add, remove, check
contract ConsumerRole {
      using Roles for Roles.Role;
      
      // Define 2 events, one for Adding, and other for Removing
      event ConsumerAdded(address indexed account);
      event ConsumerRemoved(address indexed account);

      // Define a struct 'consumers' by inheriting from 'Roles' library, struct Role
      Roles.Role private consumers;

      constructor() {
      }

      // Define a modifier that checks to see if msg.sender has the appropriate role
      modifier onlyConsumer() {
            require(isConsumer(msg.sender));
            _;
      }

      // Define a function 'isConsumer' to check this role
      function isConsumer(address account) internal view returns (bool) {
            return consumers.has(account);
      }

      // Define a function 'addConsumer' that adds this role
      function registerConsumer() external {
            _addConsumer(msg.sender);
      }

      // Define a function 'renounceConsumer' to renounce this role
      function renounceConsumer() external {
            _removeConsumer(msg.sender);
      }

      // Define an internal function '_addConsumer' to add this role, called by 'addConsumer'
      function _addConsumer(address account) internal {
            consumers.add(account);
            emit ConsumerAdded(account);
      }

      // Define an internal function '_removeConsumer' to remove this role, called by 'removeConsumer'
      function _removeConsumer(address account) internal {
            consumers.remove(account);
            emit ConsumerRemoved(account);
      }
}