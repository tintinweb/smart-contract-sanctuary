/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.4;

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
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

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () public {
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
}

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Airdrop is Ownable {
    using SafeMath for uint256;

    uint256 public commission = 0.002 ether;
    uint256 public commissionLimit = 3 ether;
    
    /* options for 50% discount */
    address public baseToken = 0xC974bE717f52Dcc701fE50fAD36d163b1e9A3a82;
    uint256 public minimumTokenLimit = 40 * 10**9 * 10**9;

    address[] private tokensForDiscount;

    /* list of addresses for no fee */
    address[] private whitelist;

    address public feeAddress;

    /* events */
    event AddedToWhitelist(address addr);
    event RemovedFromWhitelist(address addr);

    event AddedToDicountList(address token);
    event RemovedFromDicountList(address token);

    event FeeAddressUpdated(address addr);
    event MinimumTokenLimitUpdated(uint256 amount);

    event CommissionUpdated(uint256 amount);
    event CommissionLimitUpdated(uint256 amount);

    constructor() {
        feeAddress = msg.sender;
    }

    /* Airdrop Begins */
    function multiTransfer(address token, address[] calldata addresses, uint256[] calldata amounts) external payable {
        require(token != address(0x0), "Invalid token");
        require(addresses.length < 501 && addresses.length > 1, "GAS Error: max airdrop limit is 500 addresses");
        require(addresses.length == amounts.length,"Mismatch between Address and token count");

        uint256 sum = 0;
        for(uint i=0; i < addresses.length; i++){
            require(amounts[i] > 0, "Airdrop token amount must be greater than zero.");
            sum = sum.add(amounts[i]);
        }

        require(IERC20(token).balanceOf(msg.sender) >= sum, "Not enough tokens in wallet");

        for(uint i=0; i < addresses.length; i++){
            IERC20(token).transferFrom(msg.sender, addresses[i], amounts[i]);
        }
        
        uint256 fee = estimateServiceFee(token, addresses.length);
        if(fee > 0) {
            require(msg.value == fee, "must send correct fee");
            
            payable(feeAddress).transfer(fee);
        }

    }

    function multiTransfer_fixed(address token, address[] calldata addresses, uint256 amount) external payable {
        require(token != address(0x0), "Invalid token");
        require(addresses.length < 801 && addresses.length > 1,"GAS Error: max airdrop limit is 800 addresses");
        require(amount > 0, "Airdrop token amount must be greater than zero.");


        uint256 sum = amount.mul(addresses.length);
        require(IERC20(token).balanceOf(msg.sender) >= sum, "Not enough tokens in wallet");

        for(uint i=0; i < addresses.length; i++){
            IERC20(token).transferFrom(msg.sender, addresses[i], amount);
        }

        uint256 fee = estimateServiceFee(token, addresses.length);
        if(fee > 0) {
            require(msg.value == fee, "must send correct fee");
            
            payable(feeAddress).transfer(fee);
        }
    }

    function estimateServiceFee(address token, uint256 count) public view returns(uint256) {
        if(isInWhitelist(msg.sender)) return 0;

        uint256 fee = commission.mul(count);
        if(fee > commissionLimit) fee = commissionLimit;

        if(isInDiscountList(token)) return fee.div(2);

        uint256 balance = IERC20(baseToken).balanceOf(msg.sender);
        if(balance >= minimumTokenLimit) {
            return fee.div(2);
        }

        return fee;
    }
    
    function addToDiscount(address token) external onlyOwner {
        require(token != address(0x0), "Invalid address");
        require(isInDiscountList(token) == false, "Already added to token list for discount");

        tokensForDiscount.push(token);

        emit AddedToDicountList(token);
    }
    
    function removeFromDiscount(address token) external onlyOwner {
        require(token != address(0x0), "Invalid address");
        require(isInDiscountList(token) == true, "Not exist in token list for discount");

        for(uint i = 0; i < tokensForDiscount.length; i++) {
            if(tokensForDiscount[i] == token) {
                tokensForDiscount[i] = tokensForDiscount[tokensForDiscount.length - 1];
                tokensForDiscount[tokensForDiscount.length - 1] = address(0x0);
                tokensForDiscount.pop();
                break;
            }
        }

        emit RemovedFromDicountList(token);
    }

    function isInDiscountList(address token) public view returns (bool){
        for(uint i = 0; i < tokensForDiscount.length; i++) {
            if(tokensForDiscount[i] == token) {
                return true;
            }
        }

        return false;
    }

    function addToWhitelist(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");
        require(isInWhitelist(addr) == false, "Already added to whitelsit");

        whitelist.push(addr);

        emit AddedToWhitelist(addr);
    }
    
    function removeFromWhitelist(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");
        require(isInWhitelist(addr) == true, "Not exist in whitelist");

        for(uint i = 0; i < whitelist.length; i++) {
            if(whitelist[i] == addr) {
                whitelist[i] = whitelist[whitelist.length - 1];
                whitelist[whitelist.length - 1] = address(0x0);
                whitelist.pop();
                break;
            }
        }

        emit RemovedFromWhitelist(addr);
    }

    function isInWhitelist(address addr) public view returns (bool){
        for(uint i = 0; i < whitelist.length; i++) {
            if(whitelist[i] == addr) {
                return true;
            }
        }

        return false;
    }

    function setMinimumTokenLimit(uint256 amount) external onlyOwner {
        require(amount >= 0, "Invalid amount");

        minimumTokenLimit = amount;

        emit MinimumTokenLimitUpdated(amount);
    }

    function setFeeAddress(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");

        feeAddress = addr;

        emit FeeAddressUpdated(addr);
    }

    function setCommission(uint256 _commission) external onlyOwner {
        require(_commission > 0, "Invalid amount");
        commission = _commission;

        emit CommissionUpdated(_commission);
    }

    function setCommissionLimit(uint256 _limit) external onlyOwner {
        require(_limit > 0, "Invalid amount");
        commissionLimit = _limit;

        emit CommissionLimitUpdated(_limit);
    }
}