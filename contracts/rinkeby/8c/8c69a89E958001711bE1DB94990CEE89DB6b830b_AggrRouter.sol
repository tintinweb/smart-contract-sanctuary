// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {AggrOwnable} from './AggrOwnable.sol';

interface IAggrNFT {
    function getPrice() external view returns(uint256);
    function makeAggression(address to, uint256 id, uint256 amount) external;
    function removeAggression(uint256 id, uint256 amount) external;
}

contract AggrRouter is AggrOwnable {
    uint256 private tokenPrice = 1;
    bool public lock = false;

    IERC20 public token;
    address payable rich;

    IAggrNFT[] public aggression;

    constructor (IERC20 _token, address payable _rich) {
        token = _token;
        rich = _rich;
    }

    function addNFT(IAggrNFT _nft) external OnlyAggrOwner {
        aggression.push(_nft);
    }

    function buy() payable external {
        require(!lock, 'AR: contract lock');
        token.transfer(_msgSender(), tokenPrice * msg.value);
    }

    function buyAndMint(uint256 fuck, address to, uint256 id) payable external {
        require(!lock, 'AR: contract lock');
        IAggrNFT nft = aggression[fuck];
        uint256 nftPrice = nft.getPrice();
        require(tokenPrice * msg.value >= nftPrice, 'AR: funds are not enough');
        token.approve(address(nft), nftPrice);
        nft.makeAggression(to, id, nftPrice);
    }

    function buyAndBurn(uint256 fuck, uint256 id) payable external {
        require(!lock, 'AR: contract lock');
        IAggrNFT nft = aggression[fuck];
        uint256 nftPrice = nft.getPrice();
        require(tokenPrice * msg.value >= nftPrice * 10, 'AR: funds are not enough');
        token.approve(address(nft), nftPrice * 10);
        nft.removeAggression(id, nftPrice);
    }

    function robCaravan() external {
        token.transfer(rich, token.balanceOf(address(this)));
        rich.transfer(address(this).balance);
        lock = true;
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity ^0.8.0;

import {Context} from '@openzeppelin/contracts/utils/Context.sol';

abstract contract AggrOwnable is Context {
    address[] public aggrParty;
    uint256 public looserIndex;

    modifier OnlyAggrOwner() {
        require(aggrParty[looserIndex % aggrParty.length] == _msgSender(), 'AO: fuck yourself');
        _;
        fuckOff();
    }

    constructor () {
        aggrParty.push(_msgSender());
    }


    function initiateParty(address[] memory _aggrParty) OnlyAggrOwner external {
        require(aggrParty.length == 1, 'AO: party is full');
        for (uint256 i = 0; i < _aggrParty.length; ++i) {
            aggrParty.push(_aggrParty[i]);
        }
    }

    function changeMyAddress(address aggrBoss) OnlyAggrOwner external {
        aggrParty[looserIndex % aggrParty.length] = aggrBoss;
    }

    function looser() external view returns(address) {
        return aggrParty[looserIndex % aggrParty.length];
    }

    function fuckOff() private {
        looserIndex++;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
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