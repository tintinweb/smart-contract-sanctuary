// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

// Home token interface to get the list of students
interface IHome {
    function getStudentsList() external view returns(string[] memory);
}

contract Exchange {
	modifier onlyOwner () {
       require(msg.sender == owner, "This can only be called by the contract owner!");
       _;
    }
	
	address[] public acceptableTokens = [
		0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa
	];

	address public owner;
	address private nftKeyTokenAddress;

	AggregatorV3Interface internal priceFeedETHUSD;
	AggregatorV3Interface internal priceFeedDAIUSD;
	IHome public homeToken;
	IERC20 public tokenFDRT;
	uint256 public deployedTimestamp = block.timestamp;

	event Bought(address payer, uint256 value);
	event BoughtFailed(address payer, uint256 value, string reason);
	event Destroy(address currentContract);

	constructor(
		address _tokenContractAddress,
		address _homeTokenAddress,
		address _chainLinkETHUSDAddress,
		address _chainLinkDAIUSDAddress,
		address _nftKeyTokenAddress
	) {
		tokenFDRT = IERC20(_tokenContractAddress);
		homeToken = IHome(_homeTokenAddress);
        priceFeedETHUSD = AggregatorV3Interface(_chainLinkETHUSDAddress);
        priceFeedDAIUSD = AggregatorV3Interface(_chainLinkDAIUSDAddress);
		nftKeyTokenAddress = _nftKeyTokenAddress;
		owner = msg.sender;
	}

	// Get latest eth/usd price
    function getLatestPriceETHUSD() public view returns (uint) {
        (, int price,,,) = priceFeedETHUSD.latestRoundData();
        return uint(price);
    }

    // Get students count
    function getStudentsCount() public view returns (uint) {
        string[] memory studentsList = homeToken.getStudentsList();
        return uint(studentsList.length);
    }

	//Get wei cost of spesific [amount] of tokens 
    function getCostETHUSD(uint amount) public view returns (uint) {
        uint costWei = amount * (getLatestPriceETHUSD()/getStudentsCount()) / (10 ** priceFeedETHUSD.decimals()) ;
        return costWei;
    }

	function getLatestPriceDAIUSD() public view returns (uint) {
        (, int price,,,) = priceFeedDAIUSD.latestRoundData();
        return uint(price);
    }

	function getCostDAIUSD(uint amount) public view returns (uint) {
		uint costDai = amount * getLatestPriceDAIUSD() / (10 ** priceFeedDAIUSD.decimals()) ;
        return costDai;
	}
	/**
	* Sender requests to buy tokens from the contract.
	*/

	function buyTokens() payable public {
		require(IERC721(nftKeyTokenAddress).balanceOf(msg.sender) > 0, "You should have a key NFT token");
		require(msg.value > 0, "Send ETH to buy some tokens");

		uint amountToBuy = getCostETHUSD(msg.value);

		// Ensure that the contract has enough tockens
		if(tokenFDRT.balanceOf(address(this)) >= amountToBuy){
		    assert(tokenFDRT.transfer(msg.sender, amountToBuy));
			emit Bought(msg.sender, msg.value);
        }
        else {
			msg.sender.call{value: msg.value}("Sorry, there is not enough tokens to buy");
			emit BoughtFailed(msg.sender, msg.value, "Sorry, there is not enough tokens to buy");
        }
	}

	//Method reloading for buying tokens for tokens
	function buyTokens(uint daiAmount, address _token) public {
		require(IERC721(nftKeyTokenAddress).balanceOf(msg.sender) > 0, "You should have a key NFT token");
		require(daiAmount > 0, "Impossible to buy 0 DAI tokens");

		uint fenderTokenAmount = getCostDAIUSD(daiAmount);
		require(tokenFDRT.balanceOf(address(this)) >= fenderTokenAmount, "Sorry, there is not enough tokens to buy");
		require(isTokenAcceptable(_token), "Sorry, token is not acceptable");

		//check if sender has enough tokens
		IERC20 tokenToPay = IERC20(_token);
		require(
			tokenToPay.balanceOf(msg.sender) >= daiAmount &&
			tokenToPay.allowance(msg.sender, address(this)) >= daiAmount,
			"You do not have enough tokens or not in allowence"
		);

		tokenToPay.transferFrom(
			msg.sender,
			address(this),
			daiAmount
		);

		tokenFDRT.transfer(
			msg.sender,
			fenderTokenAmount
		);	
	}

	//Get Exchange Balance
	function getBalance() public view returns(uint) {
        return address(this).balance;
    }
	//Withdraw all eth and tokens from contract to the owner
	function withdraw(address payable _to) onlyOwner public {
		//withdraw FenderTokens
		if(tokenFDRT.balanceOf(address(this)) > 0) {
			tokenFDRT.transfer(
				_to,
				tokenFDRT.balanceOf(address(this))
			);
		}
		//withdraw Eth
		if(getBalance() > 0) {
			_to.transfer(getBalance());
		}
    }
	//Check if tokeb acceptable
	function isTokenAcceptable(address _tokenToCheck) public view returns(bool) {
		for(uint i = 0; i < acceptableTokens.length; i++) {
			if(acceptableTokens[i] == _tokenToCheck)	{
				return true;
			}
		}
		return false;
	}
	//Destroy contract
	function destroy() public onlyOwner {
		emit Destroy(address(this));
		selfdestruct(payable(owner));
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}