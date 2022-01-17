// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IUniswapRouter {

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function getAmountsOut(
    uint amountIn,
    address[] memory path
  ) external view returns (uint[] memory amounts);
}

interface IPairFactory {
  function pairByTokens(address _tokenA, address _tokenB) external view returns(address);
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC721 {
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

struct TestContractAcceptTerm {
  address acceptAssetAddress;
  uint256 acceptTokenId;
  uint256 acceptAmount;
  address recipient;
}

struct TestContractOffer {
  address offerAssetAddress;
  uint256 offerTokenId;
  uint256 offerAmount;
  address recipient;
  TestContractAcceptTerm term;
}

contract TestContract is Ownable {
  mapping (address => TestContractOffer) offers;

  function createOfferWith721For20(
    address _assetAddress,
    uint256 _tokenId,
    uint256 _amount,
    address _recipient
  ) public virtual {
  }

  function createOfferWith20For721(
    address _assetAddress,
    uint256 _tokenId,
    uint256 _amount,
    address _recipient
  ) public virtual {
  }

  function createOfferWith20For20(
    address _assetAddress,
    uint256 _tokenId,
    uint256 _amount,
    address _recipient
  ) public virtual {
  }

  function createOfferWith721For721(
    address _assetAddress,
    uint256 _tokenId,
    uint256 _amount,
    address _recipient
  ) public virtual {
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}