/*
                        ██╗      ██████╗████████╗██████╗ ██╗     ██
                        ██║     ██╔════╝╚══██╔══╝██╔══██╗██║     ██
                        ██║     ██║  ███╗  ██║   ██████╔╝██║ ██████████
                        ██║     ██║   ██║  ██║   ██╔══██╗██║     ██
                        ███████╗╚██████╔╝  ██║   ██████╔╝██║     ██
                        ╚══════╝ ╚═════╝   ╚═╝   ╚═════╝ ╚═╝
                                                            
                             ██████╗ ██████╗ ██╗███╗   ██╗  
                            ██╔════╝██╔═══██╗██║████╗  ██║  
                            ██║     ██║   ██║██║██╔██╗ ██║  
                            ██║     ██║   ██║██║██║╚██╗██║  
                            ╚██████╗╚██████╔╝██║██║ ╚████║  
                             ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝  
15 days presale
*/      
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
  library TransferHelper {
      function safeApprove(
          address token,
          address to,
          uint256 value
      ) internal {
          // bytes4(keccak256(bytes('approve(address,uint256)')));
          (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
          require(
              success && (data.length == 0 || abi.decode(data, (bool))),
              'TransferHelper::safeApprove: approve failed'
          );
      }

      function safeTransfer(
          address token,
          address to,
          uint256 value
      ) internal {
          // bytes4(keccak256(bytes('transfer(address,uint256)')));
          (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
          require(
              success && (data.length == 0 || abi.decode(data, (bool))),
              'TransferHelper::safeTransfer: transfer failed'
          );
      }

      function safeTransferFrom(
          address token,
          address from,
          address to,
          uint256 value
      ) internal {
          // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
          (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
          require(
              success && (data.length == 0 || abi.decode(data, (bool))),
              'TransferHelper::transferFrom: transferFrom failed'
          );
      }

      function safeTransferETH(address to, uint256 value) internal {
          (bool success, ) = to.call{value: value}(new bytes(0));
          require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
      }
  }
  library SafeMath {
        /**
        * @dev Returns the addition of two unsigned integers, reverting on
        * overflow.
        *
        * Counterpart to Solidity's `+` operator.
        *
        * Requirements:
        *
        * - Addition cannot overflow.
        */
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");

            return c;
        }

        /**
        * @dev Returns the subtraction of two unsigned integers, reverting on
        * overflow (when the result is negative).
        *
        * Counterpart to Solidity's `-` operator.
        *
        * Requirements:
        *
        * - Subtraction cannot overflow.
        */
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return sub(a, b, "SafeMath: subtraction overflow");
        }

        /**
        * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
        * overflow (when the result is negative).
        *
        * Counterpart to Solidity's `-` operator.
        *
        * Requirements:
        *
        * - Subtraction cannot overflow.
        */
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;

            return c;
        }

        /**
        * @dev Returns the multiplication of two unsigned integers, reverting on
        * overflow.
        *
        * Counterpart to Solidity's `*` operator.
        *
        * Requirements:
        *
        * - Multiplication cannot overflow.
        */
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) {
                return 0;
            }

            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");

            return c;
        }

        /**
        * @dev Returns the integer division of two unsigned integers. Reverts on
        * division by zero. The result is rounded towards zero.
        *
        * Counterpart to Solidity's `/` operator. Note: this function uses a
        * `revert` opcode (which leaves remaining gas untouched) while Solidity
        * uses an invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        *
        * - The divisor cannot be zero.
        */
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }

        /**
        * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
        * division by zero. The result is rounded towards zero.
        *
        * Counterpart to Solidity's `/` operator. Note: this function uses a
        * `revert` opcode (which leaves remaining gas untouched) while Solidity
        * uses an invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        *
        * - The divisor cannot be zero.
        */
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b > 0, errorMessage);
            uint256 c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold

            return c;
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        * Reverts when dividing by zero.
        *
        * Counterpart to Solidity's `%` operator. This function uses a `revert`
        * opcode (which leaves remaining gas untouched) while Solidity uses an
        * invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        *
        * - The divisor cannot be zero.
        */
        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            return mod(a, b, "SafeMath: modulo by zero");
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        * Reverts with custom message when dividing by zero.
        *
        * Counterpart to Solidity's `%` operator. This function uses a `revert`
        * opcode (which leaves remaining gas untouched) while Solidity uses an
        * invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        *
        * - The divisor cannot be zero.
        */
        function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b != 0, errorMessage);
            return a % b;
        }
  }
  //Contracts
  abstract contract Context {
          function _msgSender() internal view virtual returns (address) {
              return msg.sender;
          }

          function _msgData() internal view virtual returns (bytes memory) {
              this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
              return msg.data;
          }
  }
  contract Ownable is Context {
          address public _owner;
          address private _previousOwner;
          uint256 private _lockTime;

          event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

          constructor () {
              address msgSender = _msgSender();
              _owner = msgSender;
              emit OwnershipTransferred(address(0), msgSender);
          }

          function owner() public view returns (address) {
              return _owner;
          }   
          
          modifier onlyOwner() {
              require(_owner == _msgSender(), "Ownable: caller is not the owner");
              _;
          }
          
          function renounceOwnership() public virtual onlyOwner {
              emit OwnershipTransferred(_owner, address(0));
              _owner = address(0);
          }

          function transferOwnership(address newOwner) public virtual onlyOwner {
              require(newOwner != address(0), "Ownable: new owner is the zero address");
              emit OwnershipTransferred(_owner, newOwner);
              _owner = newOwner;
          }

          function getUnlockTime() public view returns (uint256) {
              return _lockTime;
          }
          
          function getTime() public view returns (uint256) {
              return block.timestamp;
          }

          function lock(uint256 time) public virtual onlyOwner {
              _previousOwner = _owner;
              _owner = address(0);
              _lockTime = block.timestamp + time;
              emit OwnershipTransferred(_owner, address(0));
          }
          
          function unlock() public virtual {
              require(_previousOwner == msg.sender, "You don't have permission to unlock");
              require(block.timestamp > _lockTime , "Contract is locked until 7 days");
              emit OwnershipTransferred(_owner, _previousOwner);
              _owner = _previousOwner;
          }
  }

contract LgtbiPreSaleV3 is Ownable {
 	address public lgtbiAddress;
	address payable paymentAddress;
	address kycSigner;
	uint public endTime;
	uint public stageAmount;
	uint public minPayAmount;
	uint public tokensSold = 0;
	uint public tokensWithdrawn = 0;
	uint public discountThreshold;
	uint8 public discount = 25;
	uint8 public currentStage = 0;
	bool isFinished = false;
	uint public constant LGTBI_DECIMALS = 9;
	string public constant AGREEMENT = "I confirm I am not a citizen, national, resident (tax or otherwise) or holder of a green card of the USA and have never been a citizen, national, resident (tax or otherwise) or holder of a green card of the USA in the past.";
	
  struct Stage {
        uint tokenPrice;
        uint tokensSold;
    }
	struct Sale {
	    address customerAddress;
		uint payAmount;
		uint tokenAmount;
		bytes agreementSignature;
		uint16 referral;
		bool tokensWithdrawn;
	}

	Stage[] public stages;
	Sale[] public sales;

	event NewSale(uint indexed saleId, address indexed customerAddress, uint16 indexed referral, uint payAmount, uint tokenAmount, uint8 stage, uint stageSales, bool isSaleFinished);
	event TokensWithdrawn(address indexed customerAddress, uint tokenAmount);
	event StageSwitch(uint8 previousStage, uint8 newStage, bool isSaleFinished);

constructor(
	    address _lgtbiAddress, address payable _paymentAddress, address _kycSigner, 
      uint _endTime,
	    uint _stageAmount, uint _minPayAmount, uint _discountThreshold,
	    uint _tokenPrice1, uint _tokenPrice2, uint _tokenPrice3, 
      uint _tokenPrice4, uint _tokenPrice5
    ) {
        lgtbiAddress = _lgtbiAddress;
        paymentAddress = _paymentAddress;
        endTime = _endTime;
        stageAmount = _stageAmount * (10 ** LGTBI_DECIMALS);
        minPayAmount = _minPayAmount;
        kycSigner = _kycSigner;
        discountThreshold = _discountThreshold;
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

    function changeDiscount(uint8 _discount) public onlyOwner {
        discount = _discount;
    }

    function changeDiscountThreshold(uint _discountThreshold) public onlyOwner {
        discountThreshold = _discountThreshold;
    }

    function switchStage(uint8 _stage) public onlyOwner {
        require(!isSaleFinished(), "The sale is over");
        uint8 previousStage = currentStage;
        _switchStage(_stage);
        emit StageSwitch(previousStage, currentStage, isFinished);
    }

    function withdrawRemainingTokens(uint _tokenAmount) public onlyOwner {
        require(_tokenAmount > 0, "Nothing to withdraw");
        require(_tokenAmount <= _get_Balance(), "Not enough Lgtbi+ tokens to withdraw");
        TransferHelper.safeTransfer(lgtbiAddress, msg.sender, _tokenAmount);
    }
	function getUnwithdrawnTokenAmount(address _customerAddress) public view returns (uint tokenAmount) {
	    tokenAmount = 0;
	    for (uint i = 0; i < sales.length; i++) {
			if (sales[i].customerAddress == _customerAddress && sales[i].tokensWithdrawn == false) {
				tokenAmount += sales[i].tokenAmount;
			}
		}
	}
  function _verifyUser(bytes calldata _signature, address signer) internal view returns (bool)
  {
    bytes32 message = prefixed(keccak256(abi.encodePacked(
        msg.sender,
        'withdrawMyTokens'
      )));
      return recoverSigner(message, _signature)==signer ;

  }
	function withdrawTokens(bytes calldata _kycSignature) public {
	    require(isSaleFinished(), "The withdrawal of Lgtbi+ tokens is not yet available");
	    require(_verifyUser(_kycSignature, msg.sender), "Incorrect withdrawTokens signature");
	    uint tokenAmount = 0;
	    for (uint i = 0; i < sales.length; i++) {
			if (sales[i].customerAddress == msg.sender && sales[i].tokensWithdrawn == false) {
				tokenAmount += sales[i].tokenAmount;
				sales[i].tokensWithdrawn = true;
			}
		}
		require(tokenAmount > 0, "You have nothing to withdraw");
		tokensWithdrawn += tokenAmount;
    TransferHelper.safeTransfer(lgtbiAddress, msg.sender, tokenAmount);
		emit TokensWithdrawn(msg.sender, tokenAmount);
	}

	function isSaleFinished() public view returns (bool) {
	    return isFinished || block.timestamp > endTime;
	}

	function calculateTokenAmount(uint etherAmount) public view returns(uint tokenAmount) {
	    require(!isSaleFinished(), "The sale is over");
	    require(etherAmount >= minPayAmount, "Amount must be greater than the minimal value");
	    if (etherAmount >= discountThreshold) {
            etherAmount = etherAmount * 100 / (100 - discount);
        }
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
		require(etherAmount == 0, "Not enough Lgtbi+ tokens to buy");
	}

	function getMinAndMaxPayAmounts() public view returns(uint, uint) {
	    uint maxPayAmount = 0;
	    for (uint8 i = currentStage; i < stages.length && !isSaleFinished(); i++) {
		    uint thisStageAmount = stageAmount - stages[i].tokensSold;
		    maxPayAmount += _calculateEtherAmount(thisStageAmount, i);
		}
		if (maxPayAmount >= discountThreshold) {
		    uint maxPayAmountWithDiscount = maxPayAmount * (100 - discount) / 100;
		    if (maxPayAmountWithDiscount >= discountThreshold) {
		        maxPayAmount = maxPayAmountWithDiscount;
		    } else {
		        maxPayAmount = discountThreshold - 1;
		    }
		}
		return (minPayAmount, maxPayAmount);
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
	    tokenAmount = etherAmount * (10 ** LGTBI_DECIMALS) / stages[stage].tokenPrice;
	}

	function _calculateEtherAmount(uint tokenAmount, uint8 stage) private view returns(uint etherAmount) {
	    etherAmount = tokenAmount * stages[stage].tokenPrice / (10 ** LGTBI_DECIMALS);
	}

  function _get_Balance() private returns(uint balance) {
      (bool success, bytes memory data) = lgtbiAddress.call(
          abi.encodeWithSelector(bytes4(keccak256(bytes('balanceOf(address)'))), address(this))
      );
      require(success, "Getting Lgtbi+ balance failed");
      balance = abi.decode(data, (uint));
  }  

    function buyTokens(bytes calldata _agreementSignature,string memory _UserSignature,  uint256 amount) payable public  
    {
      require(!isSaleFinished(), "The sale is over");
      bytes32 message = prefixed(keccak256(abi.encodePacked(
        msg.sender,
        amount,
        _UserSignature

      )));
      require(recoverSigner(message, _agreementSignature)==msg.sender , '3 . wrong signature sender');
      require(msg.value >= minPayAmount, "Amount must be greater than the minimal value");
      uint etherAmount = msg.value;
		if (etherAmount >= discountThreshold) {
		    etherAmount = etherAmount * 100 / (100 - discount);
		}
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
		require(etherAmount == 0, "Not enough Lgtbi+ tokens to buy");
		require(tokenAmount > 0, "Amount must be greater than 0");
		tokensSold += tokenAmount;
		paymentAddress.transfer(msg.value);
		uint saleId = sales.length;
		sales.push(Sale(msg.sender, msg.value, tokenAmount, _agreementSignature, 0, false));
		emit NewSale(saleId, msg.sender, 0, msg.value, tokenAmount, currentStage, stages[currentStage].tokensSold, isFinished);
      
    }
    
    function recoverSigner(bytes32 message, bytes memory sig) internal  pure returns (address)
    {
      uint8 v;
      bytes32 r;
      bytes32 s;
    
      (v, r, s) = splitSignature(sig);
    
      return ecrecover(message, v, r, s);
    }

	  

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
      return keccak256(abi.encodePacked(
        '\x19Ethereum Signed Message:\n32', 
        hash
      ));
    }

    function splitSignature(bytes memory sig)
      internal
      pure
      returns (uint8, bytes32, bytes32){
      require(sig.length == 65);
    
      bytes32 r;
      bytes32 s;
      uint8 v;
    
      assembly {
          // first 32 bytes, after the length prefix
          r := mload(add(sig, 32))
          // second 32 bytes
          s := mload(add(sig, 64))
          // final byte (first byte of the next 32 bytes)
          v := byte(0, mload(add(sig, 96)))
      }
    
      return (v, r, s);
    }
}

