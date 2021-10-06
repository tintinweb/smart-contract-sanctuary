/**
 *Submitted for verification at polygonscan.com on 2021-10-05
*/

pragma solidity ^0.6.0;

contract CounterfactualFactory
{
	function _create2(bytes memory _code, bytes32 _salt)
	internal returns(address)
	{
		bytes memory code = _code;
		bytes32      salt = _salt;
		address      addr;
		// solium-disable-next-line security/no-inline-assembly
		assembly
		{
			addr := create2(0, add(code, 0x20), mload(code), salt)
			if iszero(extcodesize(addr)) { revert(0, 0) }
		}
		return addr;
	}

	function _predictAddress(bytes memory _code, bytes32 _salt)
	internal view returns (address)
	{
		return address(bytes20(keccak256(abi.encodePacked(
			bytes1(0xff),
			address(this),
			_salt,
			keccak256(_code)
		)) << 0x60));
	}
}

contract GenericFactory is CounterfactualFactory
{
	event NewContract(address indexed addr);

	function predictAddress(bytes memory _code, bytes32 _salt)
	public view returns(address)
	{
		return predictAddressWithCall(_code, _salt, bytes(""));
	}

	function createContract(bytes memory _code, bytes32 _salt)
	public returns(address)
	{
		return createContractAndCall(_code, _salt, bytes(""));
	}

	function predictAddressWithCall(bytes memory _code, bytes32 _salt, bytes memory _call)
	public view returns(address)
	{
		return _predictAddress(_code, keccak256(abi.encodePacked(_salt, _call)));
	}

	function createContractAndCall(bytes memory _code, bytes32 _salt, bytes memory _call)
	public returns(address)
	{
		address addr = _create2(_code, keccak256(abi.encodePacked(_salt, _call)));
		emit NewContract(addr);
		if (_call.length > 0)
		{
			// solium-disable-next-line security/no-low-level-calls
			(bool success, bytes memory reason) = addr.call(_call);
			require(success, string(reason));
		}
		return addr;
	}
}