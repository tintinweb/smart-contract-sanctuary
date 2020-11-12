/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

pragma solidity ^0.5.0;

contract ClaimProofs {

  event ProofAdded(uint indexed coverId, address indexed owner, string ipfsHash);

  function addProof(uint _coverId, string calldata _ipfsHash) external {
    emit ProofAdded(_coverId, msg.sender, _ipfsHash);
  }

}