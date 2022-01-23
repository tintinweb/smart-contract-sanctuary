//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IERC20.sol";
import "./interfaces/IElemonNFT.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Runnable.sol";

contract CryptizenSender is Runnable, ReentrancyGuard{
    function distribute(address tokenAddress, address[] memory addresses, uint256[] memory amounts) public whenRunning nonReentrant{
        IERC20 token = IERC20(tokenAddress);
        for(uint256 index = 0; index < addresses.length; index++){
            token.transferFrom(_msgSender(), addresses[index], amounts[index]);
        }
    }

    function airdrop(address tokenAddress, address[] memory addresses, uint256[] memory amounts) public whenRunning nonReentrant{
        IERC20 token = IERC20(tokenAddress);
        for(uint256 index = 0; index < addresses.length; index++){
            token.transferFrom(_msgSender(), addresses[index], amounts[index]);
        }
    }

    function presale(address tokenAddress, address[] memory addresses, uint256[] memory amounts) public whenRunning nonReentrant{
        IERC20 token = IERC20(tokenAddress);
        for(uint256 index = 0; index < addresses.length; index++){
            token.transferFrom(_msgSender(), addresses[index], amounts[index]);
        }
    }

    function distributeWithSameQuantity(address tokenAddress, address[] memory addresses, uint256 amount) public whenRunning nonReentrant{
        IERC20 token = IERC20(tokenAddress);
        for(uint256 index = 0; index < addresses.length; index++){
            token.transferFrom(_msgSender(), addresses[index], amount);
        }
    }

    function withdrawToken(address tokenAddress, address recepient) public onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        token.transfer(recepient, token.balanceOf(address(this)));
    }

    function withdrawNative(address recepient) public onlyOwner{
        payable(recepient).transfer(address(this).balance);
    }

    function distributeNative(address[] memory addresses, uint256 amount) payable public whenRunning nonReentrant{
        for(uint256 index = 0; index < addresses.length; index++){
            payable(addresses[index]).transfer(amount);
        }
    }

    function mintMultiple(address nftAddress, address[] memory recepients) public onlyOwner{
        IElemonNFT nft = IElemonNFT(nftAddress);
        for(uint256 index = 0; index < recepients.length; index++){
            nft.mint(recepients[index]);
        }
    }

    function transferNftMultiple(address nftAddress, address[] memory recepients, uint256[] memory tokenIds) public onlyOwner{
        require(recepients.length == tokenIds.length, "Invalid parameter length");
        IElemonNFT nft = IElemonNFT(nftAddress);
        for(uint256 index = 0; index < recepients.length; index++){
            nft.safeTransferFrom(_msgSender(), recepients[index], tokenIds[index]);
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IElemonNFT{
    function mint(address to) external returns(uint256);
    function setContractOwner(address newOwner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract ReentrancyGuard {
    uint256 public constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 internal _status;

    constructor() {
         _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";

contract Runnable is Ownable{
    modifier whenRunning{
        require(_isRunning, "Paused");
        _;
    }
    
    modifier whenNotRunning{
        require(!_isRunning, "Running");
        _;
    }
    
    bool public _isRunning;
    
    constructor(){
        _isRunning = true;
    }
    
    function toggleRunning() public onlyOwner{
        _isRunning = !_isRunning;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './Context.sol';

contract Ownable is Context {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
     _owner = _msgSender();
     emit OwnershipTransferred(address(0), _msgSender());
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
  
  function _now() internal view returns (uint256) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return block.timestamp;
  }
}