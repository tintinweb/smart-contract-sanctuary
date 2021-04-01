/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity 0.4.23;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract DistributionContractETHandERC20 {

	function distributeERC20(address _tokenAddress, address[] _walletsToDistributeTo, uint[] _amountsToDistribute) public returns (bool success) {
		ERC20 tokenContract = ERC20(_tokenAddress);

		require(_walletsToDistributeTo.length <= 200, "Too large array");
		require(_walletsToDistributeTo.length == _amountsToDistribute.length, "the two arrays are not equal");

		for (uint i = 0; i < _walletsToDistributeTo.length; i++) {
			require(
				tokenContract.transferFrom(msg.sender, _walletsToDistributeTo[i], _amountsToDistribute[i]),
					"transaction failed");
		}

		return true;
	}

	function distributeETH(address[] _walletsToDistributeTo, uint[] _amountsToDistribute) public payable returns (bool success) {
		require(_walletsToDistributeTo.length <= 200, "Too large array");
		require(_walletsToDistributeTo.length == _amountsToDistribute.length, "the two arrays are not equal");

		uint256 distributedETH = 0;
		for (uint i = 0; i < _walletsToDistributeTo.length; i++) {
			distributedETH += _amountsToDistribute[i];

			_walletsToDistributeTo[i].transfer(_amountsToDistribute[i]);
		}

		// Refund if something is left
		if (msg.value > distributedETH) {
			msg.sender.transfer(msg.value - distributedETH);
		}

		return true;
	}
}