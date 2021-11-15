// SPDX-License-Identifier: UNLICENSED

/**
 * Contract is deployed on Goerli Chain For Testing
 *
 * Requirements:
 *
 * Test ERC20 Tokens.
 * Mapping of mainnet to child contract.
 * Using PoS Chain.
 */

 /**
  * Key variables:
  *
  * Deposit Proxy Manager: 0xdD6596F2029e6233DEFfaCa316e6A95217d4Dc34
  * Test Token Contract  : 0x655F2166b0709cd575202630952D71E2bB0d61Af
  */
pragma solidity ^0.8.4;

import "../interfaces/IERC20.sol";
import "../interfaces/ITokenPredicate.sol";
import "../utils/Context.sol";

contract InterLayerComm is Context {
    IERC20 private token;
    ITokenPredicate private manager;

    address public depositManager;
    address public tokenContract;

    /**
     * @dev creates an instance of the token contract & deposit manager
     * during deployment
     *
     * {tokenContract_} creates an instance of the token
     * {predicateContract_} creates an instance of the deposit manager
     */
    constructor(address tokenContract_, address predicateContract_) {
      token = IERC20(tokenContract_);
      manager = ITokenPredicate(predicateContract_);

      tokenContract = tokenContract_;
      depositManager = predicateContract_;
    }

    /**
     * @dev approves the token balance of the SC and initiates a deposit to matic.
     *
     * `caller` should be a governor of the contract. 
     * For testing ownability is not declared.
     */
    function depositToMatic() public virtual returns (bool) {
      uint256 tokenBalance = token.balanceOf(address(this));
      require(tokenBalance > 0, "Error: insufficient balance");

      _beforeTokenTransfer(address(this), address(this), tokenBalance);

      /**
       * For Test reasons depositing to a ERC20 wallet in ethereum. Not to lost test tokens.
       *
       * Test tokens are rarer.
       */
      manager.lockTokens(address(this), msgSender(), tokenContract, abi.encodePacked(tokenBalance));

      return true;
    }

    function approveToPredicate() public virtual returns (bool) {
      uint256 tokenBalance = token.balanceOf(address(this));
      require(tokenBalance > 0, "Error: insufficient balance");

      _beforeTokenTransfer(address(this), address(this), tokenBalance);

      /**
       * For Test reasons depositing to a ERC20 wallet in ethereum. Not to lost test tokens.
       *
       * Test tokens are rarer.
       */
      token.approve(depositManager, tokenBalance);

      return true;
    }

    /** 
     * @dev returns the balance of `owner`
     *
     * Added for debugging
     */
    function balanceOf() public virtual view returns (uint256) {
      return token.balanceOf(address(this));
    }

    /** 
     * @dev returns the allowance of `predicate` over the `owner`
     *
     * Added for debugging
     */
    function allowance() public virtual view returns (uint256) {
      return token.allowance(address(this), depositManager);
    }

    /**
     * @dev returns the bytes equivalent of the balance of token
     */
    function byteEq() public virtual view returns (bytes memory) {
      uint256 balance = token.balanceOf(address(this));
      return abi.encodePacked(balance);
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual {
      /**
       * Hook to check conditions before transfer.
       */
     }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface ITokenPredicate {

    /**
     * @notice Deposit tokens into pos portal
     * @dev When `depositor` deposits tokens into pos portal, tokens get locked into predicate contract.
     * @param depositor Address who wants to deposit tokens
     * @param depositReceiver Address (address) who wants to receive tokens on side chain
     * @param rootToken Token which gets deposited
     * @param depositData Extra data for deposit (amount for ERC20, token id for ERC721 etc.) [ABI encoded]
     */
    function lockTokens(
        address depositor,
        address depositReceiver,
        address rootToken,
        bytes calldata depositData
    ) external;

    /**
     * @notice Validates and processes exit while withdraw process
     * @dev Validates exit log emitted on sidechain. Reverts if validation fails.
     * @dev Processes withdraw based on custom logic. Example: transfer ERC20/ERC721, mint ERC721 if mintable withdraw
     * @param sender Address
     * @param rootToken Token which gets withdrawn
     * @param logRLPList Valid sidechain log for data like amount, token id etc.
     */
    function exitTokens(
        address sender,
        address rootToken,
        bytes calldata logRLPList
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

abstract contract Context {

    function msgSender() internal virtual returns(address) {
        return msg.sender;
    }

}

