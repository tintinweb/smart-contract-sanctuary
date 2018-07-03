pragma solidity 0.4.24;

/*

    Copyright 2018, Vicent Nos & Ignacio Bedoya

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

 */

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Token {
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract LescovexProxySweeper is Ownable  {
    address public owner;

    constructor (address _owner) public {
        owner = _owner;
    }

    function () payable public {
        owner.transfer(msg.value);
    }

    function sweep(address _token, uint256 _amount) public onlyOwner {
        Token token = Token(_token);

        token.transfer(owner, _amount);
    }
}