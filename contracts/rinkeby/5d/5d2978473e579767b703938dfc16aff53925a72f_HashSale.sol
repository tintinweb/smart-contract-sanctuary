// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./TransferHelper.sol";

contract HashSale is Ownable {
	address public hashTokenAddress;
	address payable public paymentAddress;
	uint public endTime;
	uint public rate;
	uint public softCap;
	uint public constant RATE_DECIMALS = 18;
	string public constant AGREEMENT = "I confirm that I'm not a USA Citizen and not a USA permanent resident, and I wasn't USA Citizinen in the past or wasn't USA permanent resident in the past.";

	struct Sale {
	    address customerAddress;
		uint payAmount;
		uint tokenAmount;
		string agreementSignature;
		bool tokensWithdrawn;
	}

	Sale[] sales;

	event NewSale(address indexed customerAddress, uint payAmount, uint tokenAmount, string agreementSignature, bool tokensWithdrawn);
	event TokensWithdrawn(address indexed customerAddress, uint tokenAmount);

	constructor(address _hashTokenAddress, address payable _paymentAddress, uint _endTime, uint _rate, uint _softCap) {
        hashTokenAddress = _hashTokenAddress;
        paymentAddress = _paymentAddress;
		endTime = _endTime;
		rate = _rate;
		softCap = _softCap;
    }

	function changeRate(uint _rate) public onlyOwner {
		rate = _rate;
	}

	function changeSoftCap(uint _softCap) public onlyOwner {
		softCap = _softCap;
	}

	function buyTokens(uint _payAmount, uint _tokenAmount, string calldata _agreementSignature) payable public {
		if (_tokenAmount > 0) {
			_payAmount = _tokenAmount * rate / (10 ** RATE_DECIMALS);
		} else {
			_tokenAmount = _payAmount * (10 ** RATE_DECIMALS) / rate;
		}
		require(_tokenAmount > 0 && _payAmount > 0, "Amount must be greater than 0");
        require(_getHashBalance() >= _tokenAmount, "Not enough HASH tokens in the contract");

		//ToDo: проверка подписи

		paymentAddress.transfer(msg.value);
		sales.push(Sale(msg.sender, _payAmount, _tokenAmount, _agreementSignature, false));
		emit NewSale(msg.sender, _payAmount, _tokenAmount, _agreementSignature, false);
	}

	function withdrawTokens() public {
	    //ToDo: поиск в sales покупок текущего пользователя, для которых токены ещё не выведены

	    //ToDo: проверка, можно ли уже выводить токены

        //ToDo: вывод токенов, проставление tokensWithdrawn = true для всех найденныз sales

		//ToDo: выбрасывание события TokensWithdrawn
	}

    function _getHashBalance() private returns(uint balance) {
        (bool success, bytes memory data) = hashTokenAddress.call(
            abi.encodeWithSelector(bytes4(keccak256(bytes('balanceOf(address)'))), address(this))
        );
        require(success, "Getting HASH balance failed");
        balance = abi.decode(data, (uint));
    }

	function _verifySign(bytes32 _data, bytes memory _sign, address _signer) pure private returns (bool) {
        bytes32 hash = _toEthBytes32SignedMessageHash(_data);
        address[] memory signList = _recoverAddresses(hash, _sign);
        return signList[0] == _signer;
    }

	function _toEthBytes32SignedMessageHash (bytes32 _data) pure private returns (bytes32 signHash) {
        signHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _data));
    }

	function _recoverAddresses(bytes32 _hash, bytes memory _signatures) pure private returns (address[] memory addresses) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }

	function _parseSignature(bytes memory _signatures, uint _pos) pure private returns (uint8 v, bytes32 r, bytes32 s) {
        uint offset = _pos * 65;
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }
        if (v < 27) v += 27;
        require(v == 27 || v == 28);
    }

    function _countSignatures(bytes memory _signatures) pure private returns (uint) {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }
}