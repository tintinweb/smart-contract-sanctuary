// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./TransferHelper.sol";

contract HashSale is Ownable {
	address public hashTokenAddress;
	address payable paymentAddress;
	address kycSigner;
	uint public endTime;
	uint public stageAmount;
	uint public minPayAmount;
	uint public tokensSold = 0;
	uint public tokensWithdrawn = 0;
	uint8 public currentStage = 0;
	bool isFinished = false;
	uint public constant HASH_TOKEN_DECIMALS = 18;
	string public constant AGREEMENT = "I confirm that I'm not a USA Citizen and not a USA permanent resident, and I wasn't USA Citizinen in the past or wasn't USA permanent resident in the past.";
	string constant AGREEMENT_LENGTH = "155";

    struct Stage {
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

	Stage[] public stages;
	Sale[] public sales;

	event NewSale(uint indexed saleId, address indexed customerAddress, uint payAmount, uint tokenAmount, uint8 stage, uint stageSales, bool isSaleFinished);
	event TokensWithdrawn(address indexed customerAddress, uint tokenAmount);
	event StageSwitch(uint8 previousStage, uint8 newStage, bool isSaleFinished);

	constructor(
	    address _hashTokenAddress, address payable _paymentAddress, uint _endTime, uint _stageAmount, uint _minPayAmount,
	    address _kycSigner, uint _tokenPrice1, uint _tokenPrice2, uint _tokenPrice3, uint _tokenPrice4, uint _tokenPrice5
    ) {
        hashTokenAddress = _hashTokenAddress;
        paymentAddress = _paymentAddress;
        endTime = _endTime;
        stageAmount = _stageAmount * (10 ** HASH_TOKEN_DECIMALS);
        minPayAmount = _minPayAmount;
        kycSigner = _kycSigner;
        stages.push(Stage(_tokenPrice1, 0));
        stages.push(Stage(_tokenPrice2, 0));
		stages.push(Stage(_tokenPrice3, 0));
		stages.push(Stage(_tokenPrice4, 0));
		stages.push(Stage(_tokenPrice5, 0));
    }

    function changeKycSigner(address _kycSigner) public onlyOwner {
        require(_kycSigner != address(0), "Incorrect address");
        kycSigner = _kycSigner;
    }

    function changeMinPayAmount(uint _minPayAmount) public onlyOwner {
        minPayAmount = _minPayAmount;
    }

    function switchStage(uint8 _stage) public onlyOwner {
        require(!isSaleFinished(), "The sale is over");
        uint8 previousStage = currentStage;
        _switchStage(_stage);
        emit StageSwitch(previousStage, currentStage, isFinished);
    }

    function withdrawRemainingTokens(uint _tokenAmount) public onlyOwner {
        require(_tokenAmount > 0, "Nothing to withdraw");
        require(_tokenAmount <= _getHashBalance(), "Not enough HASH tokens to withdraw");
        TransferHelper.safeTransfer(hashTokenAddress, msg.sender, _tokenAmount);
    }

	function buyTokens(bytes calldata _agreementSignature) payable public {
	    require(!isSaleFinished(), "The sale is over");
	    require(msg.value >= minPayAmount, "Amount must be greater than the minimal value");
		require (_verifySign(_agreementSignature, msg.sender), "Incorrect agreement signature");
		uint etherAmount = msg.value;
		uint tokenAmount = 0;
		for (uint8 i = currentStage; i < stages.length && etherAmount > 0; i++) {
		    uint buyAmount = _calculateTokenAmount(etherAmount, i);
		    uint thisStageAmount = stageAmount - stages[i].tokensSold;
		    if (buyAmount >= thisStageAmount) {
		        tokenAmount += thisStageAmount;
		        etherAmount -= _calculateEtherAmount(thisStageAmount, i);
		        stages[i].tokensSold = stageAmount;
		        _switchStage(currentStage + 1);
		    } else {
		        tokenAmount += buyAmount;
		        etherAmount = 0;
		        stages[i].tokensSold += buyAmount;
		    }
		}
		require(etherAmount == 0, "Not enough HASH tokens to buy");
		require(tokenAmount > 0, "Amount must be greater than 0");
		tokensSold += tokenAmount;
		paymentAddress.transfer(msg.value);
		uint saleId = sales.length;
		sales.push(Sale(msg.sender, msg.value, tokenAmount, _agreementSignature, false));
		emit NewSale(saleId, msg.sender, msg.value, tokenAmount, currentStage, stages[currentStage].tokensSold, isFinished);
	}

	function getUnwithdrawnTokenAmount(address _customerAddress) public view returns (uint tokenAmount) {
	    tokenAmount = 0;
	    for (uint i = 0; i < sales.length; i++) {
			if (sales[i].customerAddress == _customerAddress && sales[i].tokensWithdrawn == false) {
				tokenAmount += sales[i].tokenAmount;
			}
		}
	}

	function withdrawTokens(bytes calldata _kycSignature) public {
	    require(isSaleFinished(), "The withdrawal of HASH tokens is not yet available");
	    require(_verifyKycSign(_kycSignature, msg.sender), "Incorrect KYC signature");
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
	    require(etherAmount >= minPayAmount, "Amount must be greater than the minimal value");
	    for (uint8 i = currentStage; i < stages.length && etherAmount > 0; i++) {
		    uint buyAmount = _calculateTokenAmount(etherAmount, i);
		    uint thisStageAmount = stageAmount - stages[i].tokensSold;
		    if (buyAmount >= thisStageAmount) {
		        tokenAmount += thisStageAmount;
		        etherAmount -= _calculateEtherAmount(thisStageAmount, i);
		    } else {
		        tokenAmount += buyAmount;
		        etherAmount = 0;
		    }
		}
		require(etherAmount == 0, "Not enough HASH tokens to buy");
	}

	function _switchStage(uint8 _stage) private {
	    require(_stage > currentStage, "The next stage value must be more than the current one");
	    if (_stage >= stages.length) {
	        isFinished = true;
        } else {
            currentStage = _stage;
        }
	}

	function _calculateTokenAmount(uint etherAmount, uint8 stage) private view returns(uint tokenAmount) {
	    tokenAmount = etherAmount * (10 ** HASH_TOKEN_DECIMALS) / stages[stage].tokenPrice;
	}

	function _calculateEtherAmount(uint tokenAmount, uint8 stage) private view returns(uint etherAmount) {
	    etherAmount = tokenAmount * stages[stage].tokenPrice / (10 ** HASH_TOKEN_DECIMALS);
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

    function _verifyKycSign(bytes memory _sign, address _customerAddress) view private returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n20", _customerAddress));
        address[] memory signList = _recoverAddresses(hash, _sign);
        return signList[0] == kycSigner;
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