// SPDX-License-Identifier: UNLICENSED

/**
 * Contract is deployed on Goerli Chain For Testing
 *
 * Requirements:
 *
 * Test ERC20 Tokens.
 * Mapping of mainnet to child contract.
 * Using Plasma Chain.
 */

 /**
  * Key variables:
  *
  * Deposit Proxy Manager: 0x7850ec290A2e2F40B82Ed962eaf30591bb5f5C96
  * Test Token Contract  : 0x3f152B63Ec5CA5831061B2DccFb29a874C317502
  */
pragma solidity ^0.8.4;

import "../interfaces/IERC20.sol";
import "../interfaces/IDepositManager.sol";
import "../utils/Context.sol";

contract InterLayerComm is Context {
    IERC20 private token;
    IDepositManager private manager;

    address private depositManager;
    address private tokenContract;

    /**
     * @dev creates an instance of the token contract & deposit manager
     * during deployment
     *
     * {tokenContract_} creates an instance of the token
     * {managerContract_} creates an instance of the deposit manager
     */
    constructor(address tokenContract_, address mangerContract_) {
      token = IERC20(tokenContract_);
      manager = IDepositManager(mangerContract_);

      tokenContract = tokenContract_;
      depositManager = mangerContract_;
    }

    /**
     * @dev approves the token balance of the SC and initiates a deposit to matic.
     *
     * `caller` should be a governor of the contract. 
     * For testing ownability is not declared.
     */
    function depositToMatic() public virtual returns(bool) {
      uint256 tokenBalance = token.balanceOf(address(this));
      require(tokenBalance > 0, "Error: insufficient balance");

      _beforeTokenTransfer(address(this), address(this), tokenBalance);

      /**
       * For Test reasons depositing to a ERC20 wallet in ethereum. Not to lost test tokens.
       *
       * Test tokens are rarer.
       */
      token.approve(depositManager, tokenBalance);
      manager.transferAssets(tokenContract, msgSender(), tokenBalance);

      return true;
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

interface IDepositManager {
    function depositEther() external payable;
    function transferAssets(
        address _token,
        address _user,
        uint256 _amountOrNFTId
    ) external;
    function depositERC20(address _token, uint256 _amount) external;
    function depositERC721(address _token, uint256 _tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

abstract contract Context {

    function msgSender() internal virtual returns(address) {
        return msg.sender;
    }

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}