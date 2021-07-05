// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./TransferHelper.sol";

contract HashSale is Ownable {
	address public hashTokenAddress;
	address payable paymentAddress;
	uint public endTime;
	uint public stepAmount;
	uint public tokensSold = 0;
	uint public tokensWithdrawn = 0;
	uint8 public currentStep = 0;
	bool isFinished = false;
	uint public constant HASH_TOKEN_DECIMALS = 18;
	string public constant AGREEMENT = "I confirm that I'm not a USA Citizen and not a USA permanent resident, and I wasn't USA Citizinen in the past or wasn't USA permanent resident in the past.";
	string constant AGREEMENT_LENGTH = "155";

    struct Step {
        uint tokenPrice;
        uint tokensSold;
    }
	struct Sale {
	    address customerAddress;
		uint payAmount;
		uint tokenAmount;
		bytes agreementSignature;
		bool tokensWithdrawn;
	}

	Step[] public steps;
	Sale[] public sales;

	event NewSale(uint indexed saleId, address indexed customerAddress, uint payAmount, uint tokenAmount);
	event TokensWithdrawn(address indexed customerAddress, uint tokenAmount);

	constructor(
	    address _hashTokenAddress, address payable _paymentAddress, uint _endTime, uint _stepAmount,
	    uint _tokenPrice1, uint _tokenPrice2, uint _tokenPrice3, uint _tokenPrice4, uint _tokenPrice5
    ) {
        hashTokenAddress = _hashTokenAddress;
        paymentAddress = _paymentAddress;
        endTime = _endTime;
        stepAmount = _stepAmount * (10 ** HASH_TOKEN_DECIMALS);
        steps.push(Step(_tokenPrice1, 0));
        steps.push(Step(_tokenPrice2, 0));
		steps.push(Step(_tokenPrice3, 0));
		steps.push(Step(_tokenPrice4, 0));
		steps.push(Step(_tokenPrice5, 0));
    }

    function switchStep() public onlyOwner {
        require(!isSaleFinished(), "The sale is over");
        _switchStep();
    }

    function withdrawRemainingTokens() public onlyOwner {
        require(isSaleFinished(), "The sale is not finished");
        uint tokenAmount = _getHashBalance() + tokensWithdrawn - tokensSold;
        require (tokenAmount > 0, "Nothing to withdraw");
        TransferHelper.safeTransfer(hashTokenAddress, msg.sender, tokenAmount);
    }

	function buyTokens(bytes calldata _agreementSignature) payable public {
	    require(!isSaleFinished(), "The sale is over");
	    require(msg.value > 0, "Amount must be greater than 0");
        //require(tokenAmount <= _getHashBalance() + tokensWithdrawn - tokensSold, "Not enough HASH tokens to buy");
		require (_verifySign(_agreementSignature, msg.sender), "Incorrect agreement signature");
		uint etherAmount = msg.value;
		uint tokenAmount = 0;
		for (uint8 i = currentStep; i < steps.length && etherAmount > 0; i++) {
		    uint buyAmount = _calculateTokenAmount(etherAmount, i);
		    uint thisStepAmount = stepAmount - steps[i].tokensSold;
		    if (buyAmount >= thisStepAmount) {
		        tokenAmount += thisStepAmount;
		        etherAmount -= _calculateEtherAmount(thisStepAmount, i);
		        steps[i].tokensSold = stepAmount;
		        _switchStep();
		    } else {
		        tokenAmount += buyAmount;
		        etherAmount = 0;
		        steps[i].tokensSold = buyAmount;
		    }
		}
		require (etherAmount == 0, "Not enough HASH tokens to buy");
		require(tokenAmount > 0, "Amount must be greater than 0");
		tokensSold += tokenAmount;
		paymentAddress.transfer(msg.value);
		uint saleId = sales.length;
		sales.push(Sale(msg.sender, msg.value, tokenAmount, _agreementSignature, false));
		emit NewSale(saleId, msg.sender, msg.value, tokenAmount);
	}

	function getUnwithdrawnTokenAmount(address _customerAddress) public view returns (uint tokenAmount) {
	    tokenAmount = 0;
	    for (uint i = 0; i < sales.length; i++) {
			if (sales[i].customerAddress == _customerAddress && sales[i].tokensWithdrawn == false) {
				tokenAmount += sales[i].tokenAmount;
			}
		}
	}

	function withdrawTokens() public {
	    require (isSaleFinished(), "The withdrawal of HASH tokens is not yet available");
	    uint tokenAmount = 0;
	    for (uint i = 0; i < sales.length; i++) {
			if (sales[i].customerAddress == msg.sender && sales[i].tokensWithdrawn == false) {
				tokenAmount += sales[i].tokenAmount;
				sales[i].tokensWithdrawn = true;
			}
		}
		require(tokenAmount > 0, "You have nothing to withdraw");
		tokensWithdrawn += tokenAmount;
        TransferHelper.safeTransfer(hashTokenAddress, msg.sender, tokenAmount);
		emit TokensWithdrawn(msg.sender, tokenAmount);
	}

	function isSaleFinished() public view returns (bool) {
	    return isFinished || block.timestamp > endTime;
	}

	function calculateTokenAmount(uint etherAmount) public view returns(uint tokenAmount) {
	    for (uint8 i = currentStep; i < steps.length && etherAmount > 0; i++) {
		    uint buyAmount = _calculateTokenAmount(etherAmount, i);
		    uint thisStepAmount = stepAmount - steps[i].tokensSold;
		    if (buyAmount >= thisStepAmount) {
		        tokenAmount += thisStepAmount;
		        etherAmount -= _calculateEtherAmount(thisStepAmount, i);
		    } else {
		        tokenAmount += buyAmount;
		        etherAmount = 0;
		    }
		}
		require (etherAmount == 0, "Not enough HASH tokens to buy");
	}

	function _switchStep() private {
	    if (currentStep == steps.length - 1) {
	        isFinished = true;
        } else {
            currentStep++;
        }
	}

	function _calculateTokenAmount(uint etherAmount, uint8 step) private view returns(uint tokenAmount) {
	    tokenAmount = etherAmount * (10 ** HASH_TOKEN_DECIMALS) / steps[step].tokenPrice;
	}

	function _calculateEtherAmount(uint tokenAmount, uint8 step) private view returns(uint etherAmount) {
	    etherAmount = tokenAmount * steps[step].tokenPrice / (10 ** HASH_TOKEN_DECIMALS);
	}

    function _getHashBalance() private returns(uint balance) {
        (bool success, bytes memory data) = hashTokenAddress.call(
            abi.encodeWithSelector(bytes4(keccak256(bytes('balanceOf(address)'))), address(this))
        );
        require(success, "Getting HASH balance failed");
        balance = abi.decode(data, (uint));
    }

	function _verifySign(bytes memory _sign, address _signer) pure private returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", AGREEMENT_LENGTH, AGREEMENT));
        address[] memory signList = _recoverAddresses(hash, _sign);
        return signList[0] == _signer;
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