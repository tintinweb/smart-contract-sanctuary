/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >0.5.0;

contract SimpleStorage {

    event  Transfer(address indexed src, address indexed dst, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

	function transferFrom(address src, address dst, uint wad) public returns (bool)
	{
		require(balanceOf[src] >= wad);

		if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
			require(allowance[src][msg.sender] >= wad);
			allowance[src][msg.sender] -= wad;
		}

		balanceOf[src] -= wad;
		balanceOf[dst] += wad;

		emit Transfer(src, dst, wad);

		return true;
	}

  uint data;
  
  function updateData(uint _data) external {
    data = _data;  
  }
  
  function readData() external view returns(uint) {
    return data;
  }
  
  function transfer(address dest, uint wad) external returns (bool) {
    return transferFrom(msg.sender, dest, wad);
  }
}