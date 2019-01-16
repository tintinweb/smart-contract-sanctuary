pragma solidity ^0.4.11;
/*

████████╗██████╗ ██╗██╗     ██╗     ██╗ ██████╗ ███╗   ██╗███████╗██████╗ ███████╗██╗   ██╗███╗   ███╗    ██╗███╗   ██╗ ██████╗   
╚══██╔══╝██╔══██╗██║██║     ██║     ██║██╔═══██╗████╗  ██║██╔════╝██╔══██╗██╔════╝██║   ██║████╗ ████║    ██║████╗  ██║██╔════╝   
   ██║   ██████╔╝██║██║     ██║     ██║██║   ██║██╔██╗ ██║█████╗  ██████╔╝█████╗  ██║   ██║██╔████╔██║    ██║██╔██╗ ██║██║        
   ██║   ██╔══██╗██║██║     ██║     ██║██║   ██║██║╚██╗██║██╔══╝  ██╔══██╗██╔══╝  ██║   ██║██║╚██╔╝██║    ██║██║╚██╗██║██║        
   ██║   ██║  ██║██║███████╗███████╗██║╚██████╔╝██║ ╚████║███████╗██║  ██║███████╗╚██████╔╝██║ ╚═╝ ██║    ██║██║ ╚████║╚██████╗██╗
   ╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝    ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═

  Copyright 2018 Trillionereum Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
contract Trillionereum {

    string public name = "Trillionereum";      //  token name
    string public symbol = "TRLN";           //  token symbol
    uint256 public decimals = 6;            //  token digit

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 0;
    bool public stopped = false;

    uint256 constant valueFounder = 21000000000000000000;
    address owner = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isRunning {
        assert (!stopped);
        _;
    }

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function Trillionereum(address _addressFounder) {
        owner = msg.sender;
        totalSupply = valueFounder;
        balanceOf[_addressFounder] = valueFounder;
        Transfer(0x0, _addressFounder, valueFounder);
    }

    function transfer(address _to, uint256 _value) isRunning validAddress returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) isRunning validAddress returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) isRunning validAddress returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function stop() isOwner {
        stopped = true;
    }

    function start() isOwner {
        stopped = false;
    }

    function setName(string _name) isOwner {
        name = _name;
    }

    function burn(uint256 _value) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[0x0] += _value;
        Transfer(msg.sender, 0x0, _value);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}