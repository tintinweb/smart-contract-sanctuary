pragma solidity ^0.6.0;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";



contract eCLD is ERC20Burnable {

    address private _owner;
    mapping (bytes32 => bool) private _receipts;

	function _check_signature(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view {

		address signer = ecrecover(hash, v, r, s);
		require(_owner == signer, "Signature invalid");
	}

	function mint_with_receipt(address recipient, uint256 amount, uint256 uuid, uint8 v, bytes32 r, bytes32 s) public {

		bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n84", recipient, amount, uuid));
		require(!_receipts[hash], "Receipt already used");

		_check_signature(hash, v, r, s);

		_mint(recipient, amount);
		_receipts[hash] = true;
	}


    function mint(address recipient, uint256 amount) public {
        
        require(_owner == _msgSender());
        
        _mint(recipient, amount);
    }


	constructor() ERC20("CloudCoin Etherium", "CCE") public {
        
        _owner = _msgSender();
    }

}

