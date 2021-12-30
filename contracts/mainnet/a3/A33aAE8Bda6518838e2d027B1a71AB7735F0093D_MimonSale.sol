/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File contracts/openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File contracts/openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/Mimon/IMimon.sol



pragma solidity ^0.8.4;

interface IMimon {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	function mint(address to) external;

	function totalSupply() external view returns (uint256);

	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

	function tokenByIndex(uint256 index) external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256 balance);

	function ownerOf(uint256 tokenId) external view returns (address owner);

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	function approve(address to, uint256 tokenId) external;

	function getApproved(uint256 tokenId) external view returns (address operator);

	function setApprovalForAll(address operator, bool _approved) external;

	function isApprovedForAll(address owner, address operator) external view returns (bool);

	function massTransferFrom(
		address from,
		address to,
		uint256[] memory _myTokensId
	) external;
}


// File contracts/Mimon-Sale/MimonSale.sol



pragma solidity ^0.8.10;



contract MimonSale is Context {
	using SafeMath for uint256;

	IMimon public MimonContract;
	uint256 public constant PRESALE_PRICE = 40000000000000000; // 0.04 Eth
	uint256 public publicSalePrice;
	uint256 public constant MAX_PRESALE_SUPPLY = 2000;
	uint256 public constant MAX_TOKEN_SUPPLY = 10000;
	uint256 public constant MAX_PRESALE_AMOUNT = 3;
	uint256 public constant MAX_PUBLICSALE_AMOUNT = 15;
	bool public isPreSale = false;
	bool public isPublicSale = false;
	address public C1;
	address public C2;
	address public devAddress;

	mapping(address => bool) public whitelist;
	mapping(address => uint256) public preSaleCount;

	modifier preSaleRole(uint256 numberOfTokens) {
		require(isPreSale, "The sale has not started.");
		require(MimonContract.totalSupply() < MAX_PRESALE_SUPPLY, "Pre-sale has already ended.");
		require(MimonContract.totalSupply().add(numberOfTokens) <= MAX_PRESALE_SUPPLY, "Pre-sale would exceed max supply of Mimon");
		require(numberOfTokens <= MAX_PRESALE_AMOUNT, "Can only mint 3 Mimon at a time");
		require(preSaleCount[_msgSender()] < MAX_PRESALE_AMOUNT, "Pre-sale max mint amount is 3");
		require(preSaleCount[_msgSender()].add(numberOfTokens) <= MAX_PRESALE_AMOUNT, "Pre-sale max mint amount is 3");
		require(PRESALE_PRICE.mul(numberOfTokens) <= msg.value, "Eth value sent is not correct");
		_;
	}

	modifier publicSaleRole(uint256 numberOfTokens) {
		require(isPublicSale, "The sale has not started.");
		require(MimonContract.totalSupply() < MAX_TOKEN_SUPPLY, "Sale has already ended.");
		require(MimonContract.totalSupply().add(numberOfTokens) <= MAX_TOKEN_SUPPLY, "Purchase would exceed max supply of Mimon");
		require(numberOfTokens <= MAX_PUBLICSALE_AMOUNT, "Can only mint 15 Mimon at a time");
		require(publicSalePrice.mul(numberOfTokens) <= msg.value, "Eth value sent is not correct");
		_;
	}

	/*
    C1: Team, C2: Dev
  */
	modifier onlyCreator() {
		require(C1 == _msgSender() || C2 == _msgSender() || devAddress == _msgSender(), "onlyCreator: caller is not the creator");
		_;
	}

	modifier onlyC1() {
		require(C1 == _msgSender(), "only C1: caller is not the C1");
		_;
	}

	modifier onlyC2() {
		require(C2 == _msgSender(), "only C2: caller is not the C2");
		_;
	}

	modifier onlyDev() {
		require(devAddress == _msgSender(), "only dev: caller is not the dev");
		_;
	}

	constructor(
		address _mimonCA,
		address _C1,
		address _C2,
		address _dev
	) {
		MimonContract = IMimon(_mimonCA);
		C1 = _C1;
		C2 = _C2;
		devAddress = _dev;
		setPublicSalePrice(60000000000000000); // 0.06 Eth
	}

	function preSale(uint256 numberOfTokens) public payable preSaleRole(numberOfTokens) {
		for (uint256 i = 0; i < numberOfTokens; i++) {
			if (MimonContract.totalSupply() < MAX_PRESALE_SUPPLY) {
				MimonContract.mint(_msgSender());
			}
		}
		preSaleCount[_msgSender()] = preSaleCount[_msgSender()].add(numberOfTokens);
	}

	function publicSale(uint256 numberOfTokens) public payable publicSaleRole(numberOfTokens) {
		for (uint256 i = 0; i < numberOfTokens; i++) {
			if (MimonContract.totalSupply() < MAX_TOKEN_SUPPLY) {
				MimonContract.mint(_msgSender());
			}
		}
	}

	function preMint(uint256 numberOfTokens, address receiver) public onlyCreator {
		for (uint256 i = 0; i < numberOfTokens; i++) {
			if (MimonContract.totalSupply() < MAX_TOKEN_SUPPLY) {
				MimonContract.mint(receiver);
			}
		}
	}

	function withdraw() public payable onlyCreator {
		uint256 contractBalance = address(this).balance;
		uint256 percentage = contractBalance.div(100);

		require(payable(C1).send(percentage.mul(90)));
		require(payable(C2).send(percentage.mul(10)));
	}

	function setC1(address changeAddress) public onlyC1 {
		C1 = changeAddress;
	}

	function setC2(address changeAddress) public onlyC2 {
		C2 = changeAddress;
	}

	function setDev(address changeAddress) public onlyDev {
		devAddress = changeAddress;
	}

	function setPreSale() public onlyCreator {
		isPreSale = !isPreSale;
	}

	function setPublicSale() public onlyCreator {
		if (isPreSale == true) {
			setPreSale();
		}
		isPublicSale = !isPublicSale;
	}

	function setPublicSalePrice(uint256 price) public onlyCreator {
		publicSalePrice = price;
	}

	function addToWhitelist(address _beneficiary) external onlyCreator {
		whitelist[_beneficiary] = true;
	}

	function addManyToWhitelist(address[] memory _beneficiaries) external onlyCreator {
		for (uint256 i = 0; i < _beneficiaries.length; i++) {
			whitelist[_beneficiaries[i]] = true;
		}
	}

	function removeFromWhitelist(address _beneficiary) external onlyCreator {
		whitelist[_beneficiary] = false;
	}
}