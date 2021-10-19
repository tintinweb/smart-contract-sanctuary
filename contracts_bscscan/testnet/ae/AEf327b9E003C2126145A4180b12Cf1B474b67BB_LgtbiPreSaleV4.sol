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

        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");

            return c;
        }

        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return sub(a, b, "SafeMath: subtraction overflow");
        }

        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;

            return c;
        }

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

        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }

        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b > 0, errorMessage);
            uint256 c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold

            return c;
        }

        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            return mod(a, b, "SafeMath: modulo by zero");
        }

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
  interface IERC20 {
        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
  } 

contract LgtbiPreSaleV4 is Ownable {
    using SafeMath for uint256;
 	address public lgtbiAddress;
    IERC20 LGTBI;
	address payable paymentAddress;
	address kycSigner;
	uint public stageAmount;
	uint public minPayAmount;
	uint public tokensSold = 0;
	uint public tokensWithdrawn = 0;
	uint8 public currentStage = 0;
	bool isFinished = false;

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
    struct Card {
        uint16 CardN;
        uint payAmount;
        uint Discount;
    }

	Stage[] public stages;
	Sale[] public sales;
    Card[] public cards;

	event NewSale(uint indexed saleId, address indexed customerAddress, uint16 indexed referral, uint payAmount, uint tokenAmount, uint8 stage, uint stageSales, bool isSaleFinished);

    event TokensWithdrawn(address indexed customerAddress, uint tokenAmount);
	event StageSwitch(uint8 previousStage, uint8 newStage, bool isSaleFinished);
constructor(
	    address _lgtbiAddress, address payable _paymentAddress, address _kycSigner, 
	    uint _stageAmount, uint _minPayAmount, 
	    uint _tokenPrice1, uint _tokenPrice2, uint _tokenPrice3, 
      uint _tokenPrice4, uint _tokenPrice5
    ) {
        lgtbiAddress = _lgtbiAddress;
        paymentAddress = _paymentAddress;
        LGTBI = IERC20(lgtbiAddress);
        stageAmount = _stageAmount;
        minPayAmount = _minPayAmount;
        kycSigner = _kycSigner;

        stages.push(Stage(_tokenPrice1, 0));
        stages.push(Stage(_tokenPrice2, 0));
        stages.push(Stage(_tokenPrice3, 0));
        stages.push(Stage(_tokenPrice4, 0));
        stages.push(Stage(_tokenPrice5, 0));
        cards.push(Card(0,10 * (10 ** 18)  , 5));
        cards.push(Card(1,15 * (10 ** 18)  , 10));
        cards.push(Card(2,20 * (10 ** 18)  , 15));
    }
    function changePrice(uint _stage, uint price) public onlyOwner
    {
        stages[_stage].tokenPrice = price;
    }
    function changeCard(uint16 _card, uint _amount, uint _discount) public onlyOwner
    {
        cards[_card].Discount = _discount;
        cards[_card].payAmount = _amount;
    }

    function getPrice(uint _stage) public view returns(uint)
    {
        return stages[_stage].tokenPrice ;
    }

    function changeKycSigner(address _kycSigner) public onlyOwner {
        require(_kycSigner != address(0), "Incorrect address");
        kycSigner = _kycSigner;
    }
    function activateSaleStatus(bool _openSale) public onlyOwner
    {
        isFinished = !_openSale;
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

	function isSaleFinished() public view returns (bool) {
	    return isFinished;
	}

	function getMinAndMaxPayAmounts() public view returns(uint, uint) {
	    uint maxPayAmount = 0;
	    for (uint8 i = currentStage; i < stages.length && !isSaleFinished(); i++) {
		    uint thisStageAmount = stageAmount - stages[i].tokensSold;
		    maxPayAmount += _calculateEtherAmount(thisStageAmount, i);
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

  function _get_Balance() private returns(uint balance) {
      (bool success, bytes memory data) = lgtbiAddress.call(
          abi.encodeWithSelector(bytes4(keccak256(bytes('balanceOf(address)'))), address(this))
      );
      require(success, "Getting Lgtbi+ balance failed");
      balance = abi.decode(data, (uint));
    }  
    function getmin() public view returns(uint)
    {
        return minPayAmount;
    }
    function _calculateTokenAmount(uint etherAmount, uint8 stage) private view returns(uint tokenAmount) {
	    tokenAmount = etherAmount.mul( stages[stage].tokenPrice).div(10 ** 18,"Div error calculating token amount");
    }

	function _calculateEtherAmount(uint tokenAmount, uint8 stage) private view returns(uint etherAmount) {
	    etherAmount = tokenAmount.mul(10 ** 18).div(stages[stage].tokenPrice);
	}
    function calculateEtherAmount(uint tokenAmount, uint8 stage) public view returns(uint etherAmount) {
	    etherAmount = tokenAmount.mul(10 ** 18).div(stages[stage].tokenPrice);
	}
	function calculateTokenAmount(uint etherAmount) public view returns(uint tokenAmount) {
	    require(!isSaleFinished(), "The sale is over");
	    require(etherAmount >= minPayAmount, "Amount must be greater than the minimal value");

	    for (uint8 i = currentStage; i < stages.length && etherAmount > 0; i++) {
		    uint buyAmount = _calculateTokenAmount(etherAmount, i);
		    uint thisStageAmount = stageAmount.sub(stages[i].tokensSold);
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
    function calculateCardTokenAmount(uint16 card, uint etherAmount) public view returns(uint tokenAmount) {
	    require(!isSaleFinished(), "The sale is over");
	    require(etherAmount >= minPayAmount, "Amount must be greater than the minimal value");
        require(etherAmount >= cards[card].payAmount, "Amount must be equal than the card value");
        
        etherAmount = etherAmount.add(etherAmount.mul(cards[card].Discount.div(100))  );

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
   
    function withdrawTokens() public {
	    require(isSaleFinished(), "The withdrawal of Lgtbi+ tokens is not yet available");
	   
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

    function buyTokens(bytes calldata _agreementSignature,string memory _UserSignature) payable public  
    {
        require(!isSaleFinished(), "The sale is over");
        bytes32 message = prefixed(keccak256(abi.encodePacked(
            msg.sender,
            msg.value,
            _UserSignature

        )));
        require(recoverSigner(message, _agreementSignature)==kycSigner , 'Error firma' );
        require(msg.value >= minPayAmount, 'Value > que el minimo');
        uint etherAmount = msg.value;
        uint tokenAmount = 0;
		for (uint8 i = currentStage; i < stages.length && etherAmount > 0; i++) {
		    uint buyAmount = _calculateTokenAmount(etherAmount, i);
		    uint thisStageAmount = stageAmount.sub(stages[i].tokensSold);
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
    function buyCardTokens(uint16 card, bytes calldata _agreementSignature,string memory _UserSignature) payable public  
    {
        require(!isSaleFinished(), "The sale is over");
        bytes32 message = prefixed(keccak256(abi.encodePacked(
            msg.sender,
            msg.value,
            _UserSignature

        )));
        require(recoverSigner(message, _agreementSignature)==kycSigner , 'Error firma' );
        require(msg.value >= minPayAmount, 'Value > que el minimo');
        require(msg.value >= cards[card].payAmount, "Amount must be equal than the card value");
        uint etherAmount = msg.value;
       
        etherAmount = msg.value.add(etherAmount.mul(cards[card].Discount).div(100))  ;
        
        uint tokenAmount = 0;
		for (uint8 i = currentStage; i < stages.length && etherAmount > 0; i++) {
		    uint buyAmount = _calculateTokenAmount(etherAmount, i);
		    uint thisStageAmount = stageAmount.sub(stages[i].tokensSold);
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
		sales.push(Sale(msg.sender, msg.value, tokenAmount, _agreementSignature, card, false));
		emit NewSale(saleId, msg.sender, card, msg.value, tokenAmount, currentStage, stages[currentStage].tokensSold, isFinished);
    }
    function privateSellTokens(uint tokenAmount, address buyer) public onlyOwner  
    {
        require(!isSaleFinished(), "The sale is over");
        require(tokenAmount > 0, "Amount must be greater than 0");
        require( tokenAmount < stageAmount.sub(stages[currentStage].tokensSold),"To many tokens to sell");
        stages[currentStage].tokensSold += tokenAmount;
	    tokensSold += tokenAmount;

		uint saleId = sales.length;
		sales.push(Sale(buyer, 0, tokenAmount, 'PrivateSell', 4, false));
		emit NewSale(saleId, buyer, 4, 0, tokenAmount, currentStage, stages[currentStage].tokensSold, isFinished);
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