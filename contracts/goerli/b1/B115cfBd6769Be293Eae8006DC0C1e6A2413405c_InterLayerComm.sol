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
  * Test Token Contract: 0x655f2166b0709cd575202630952d71e2bb0d61af
  * Root Chain Manager: 0xBbD7cBFA79faee899Eaf900F13C9065bF03B1A74
  * ERC20 Predicate: 0xdD6596F2029e6233DEFfaCa316e6A95217d4Dc34
  */
pragma solidity ^0.8.4;

import "../interfaces/IERC20.sol";
import "../interfaces/IRootChainManager.sol";
import "../utils/Context.sol";

contract InterLayerComm is Context {
    IERC20 private token;
    IRootChainManager private manager;

    address public depositManager;
    address public tokenContract;
    address public predicate;

    /**
     * @dev creates an instance of the token contract & deposit manager
     * during deployment
     *
     * {tokenContract_} creates an instance of the token
     * {predicateContract_} creates an instance of the deposit manager
     */
    constructor(address tokenContract_, address predicateContract_, address predicateProxy_) {
      token = IERC20(tokenContract_);
      manager = IRootChainManager(predicateContract_);

      tokenContract = tokenContract_;
      depositManager = predicateContract_;
      predicate = predicateProxy_;
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
      token.approve(predicate, tokenBalance);
      manager.depositFor(msgSender(), tokenContract, abi.encode(tokenBalance));

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

interface IRootChainManager {
    event TokenMapped(
        address indexed rootToken,
        address indexed childToken,
        bytes32 indexed tokenType
    );

    event PredicateRegistered(
        bytes32 indexed tokenType,
        address indexed predicateAddress
    );

    function registerPredicate(bytes32 tokenType, address predicateAddress)
        external;

    function mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function cleanMapToken(
        address rootToken,
        address childToken
    ) external;

    function remapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function exit(bytes calldata inputData) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

abstract contract Context {

    function msgSender() internal virtual returns(address) {
        return msg.sender;
    }

}

