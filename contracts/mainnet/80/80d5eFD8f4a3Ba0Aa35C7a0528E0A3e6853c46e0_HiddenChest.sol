// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// You stumble across a cave and see a bright flash of light.
// Upon inspection, there is a medium size chest with a display.
// Beneeth the display are a list of engraved numbers:
//  "3241"

// Whoever left this chest also left a sheet of paper which read:
//  - Congratulations for finding this. If you have found this, you know why you are here.
//  - This chest requires a passcode. To generate a passcode, you need a password.
//  - If you have generated the correct passcode, enter it into the chest and the reward will be yours.
//  - Good luck.

contract HiddenChest {
	bytes32 public password =
		0xb00ff1d2c3bb83f8608718651506c56a6739f2c2765cddfd9068a1bcf3c1f668;

	function generatePasscode(string memory _password, address _wallet)
		external
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked(
					keccak256(abi.encodePacked(_password)),
					_wallet
				)
			);
	}

	function claimPrize(bytes32 _passcode) external {
		require(
			keccak256(abi.encodePacked(password, msg.sender)) == _passcode,
			"Bad password"
		);
		require(address(this).balance > 0, "Prize is already claimed!");

		payable(msg.sender).transfer(address(this).balance);
	}
}

// 0x40707231736d5f646576