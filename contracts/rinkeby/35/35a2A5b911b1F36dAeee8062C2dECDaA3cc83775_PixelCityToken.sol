// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ultra721, Ultra721Enumerable} from "ultra721/contracts/Ultra721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./lib/ERCWithdrawable.sol";

import "./interfaces/IPixelCityToken.sol";

contract PixelCityToken is
  IPixelCityToken,
  ERCWithdrawable,
  Ultra721Enumerable,
  Pausable,
  Ownable
{
  uint8 public maxSupply;
  uint8 public maxMintAmount;

  bool public isActive;
  bool public isRevealed;

  IPixelCityDescritor public descriptor;

  mapping(uint256 => PixelCityLibrary.Pixel) internal _pixelTraits;
  mapping(address => uint8) public addressToMinted;

  modifier onlyValidTokenId(uint256 _tokenId) {
    require(_exists(_tokenId), "Query for nonexisting token Id");
    _;
  }

  constructor(IPixelCityDescritor _descriptor) Ultra721("Pixel City", "PIXEL") {
    descriptor = _descriptor;

    maxSupply = 128;
    maxMintAmount = 8;

    isActive = false;
    isRevealed = false;
  }

  /*	                .__           ________                                    	*/
  /*	  ____    ____  |  |   ___.__.\_____  \  __  _  __  ____    ____  _______ 	*/
  /*	 /  _ \  /    \ |  |  <   |  | /   |   \ \ \/ \/ / /    \ _/ __ \ \_  __ \	*/
  /*	(  <_> )|   |  \|  |__ \___  |/    |    \ \     / |   |  \\  ___/  |  | \/	*/
  /*	 \____/ |___|  /|____/ / ____|\_______  /  \/\_/  |___|  / \___  > |__|   	*/
  /*	             \/        \/             \/               \/      \/         	*/

  function setIsActive(bool _isActive) external onlyOwner {
    isActive = _isActive;
  }

  function setIsRevealed(bool _isRevealed) external onlyOwner {
    isRevealed = _isRevealed;
  }

  function setDescriptor(IPixelCityDescritor _descriptor) external onlyOwner {
    descriptor = _descriptor;
  }

  /*	___________         __                     __      __ .__   __   .__         .___                         	*/
  /*	\__    ___/  ____  |  | __  ____    ____  /  \    /  \|__|_/  |_ |  |__    __| _/_______ _____   __  _  __	*/
  /*	  |    |    /  _ \ |  |/ /_/ __ \  /    \ \   \/\/   /|  |\   __\|  |  \  / __ | \_  __ \\__  \  \ \/ \/ /	*/
  /*	  |    |   (  <_> )|    < \  ___/ |   |  \ \        / |  | |  |  |   Y  \/ /_/ |  |  | \/ / __ \_ \     / 	*/
  /*	  |____|    \____/ |__|_ \ \___  >|___|  /  \__/\  /  |__| |__|  |___|  /\____ |  |__|   (____  /  \/\_/  	*/
  /*	                        \/     \/      \/        \/                   \/      \/              \/          	*/

  function withdrawERC20(address contractAddress_, uint256 amount_)
    external
    onlyOwner
  {
    _withdrawERC20(contractAddress_, amount_);
  }

  function withdrawERC721(address contractAddress_, uint256 tokenId_)
    external
    onlyOwner
  {
    _withdrawERC721(contractAddress_, tokenId_);
  }

  function withdrawERC1155(
    address contractAddress_,
    uint256 tokenId_,
    uint256 amount_
  ) external onlyOwner {
    _withdrawERC1155(contractAddress_, tokenId_, amount_);
  }

  function withdrawERC1155Batch(
    address contractAddress_,
    uint256[] calldata ids_,
    uint256[] calldata amounts_
  ) external onlyOwner {
    _withdrawERC1155Batch(contractAddress_, ids_, amounts_);
  }

  function withdrawEther(uint256 _amount) external onlyOwner {
    payable(msg.sender).transfer(_amount);
  }

  /*	   _____             __               .___          __           	*/
  /*	  /     \    ____  _/  |_ _____     __| _/_____   _/  |_ _____   	*/
  /*	 /  \ /  \ _/ __ \ \   __\\__  \   / __ | \__  \  \   __\\__  \  	*/
  /*	/    Y    \\  ___/  |  |   / __ \_/ /_/ |  / __ \_ |  |   / __ \_	*/
  /*	\____|__  / \___  > |__|  (____  /\____ | (____  / |__|  (____  /	*/
  /*	        \/      \/             \/      \/      \/             \/ 	*/

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    onlyValidTokenId(_tokenId)
    returns (string memory)
  {
    if (isRevealed) {
      PixelCityLibrary.Pixel memory pixel = _pixelTraits[_tokenId];
      return descriptor.tokenURI(_tokenId, pixel);
    } else {
      return descriptor.baseTokenURI(_tokenId);
    }
  }

  function walletOfOwner(address owner_)
    external
    view
    returns (uint256[] memory)
  {
    return Ultra721Enumerable._walletOfOwner(owner_);
  }

  function pixelTraits(uint256 _tokenId)
    external
    view
    onlyValidTokenId(_tokenId)
    returns (PixelCityLibrary.Pixel memory)
  {
    return _pixelTraits[_tokenId];
  }

  /*	   _____   .__           __   .__                  	*/
  /*	  /     \  |__|  ____  _/  |_ |__|  ____     ____  	*/
  /*	 /  \ /  \ |  | /    \ \   __\|  | /    \   / ___\ 	*/
  /*	/    Y    \|  ||   |  \ |  |  |  ||   |  \ / /_/  >	*/
  /*	\____|__  /|__||___|  / |__|  |__||___|  / \___  / 	*/
  /*	        \/          \/                 \/ /_____/  	*/

  function claimPixels(uint8 _amount) external payable {
    require(_amount > 0 && _amount <= maxMintAmount, "Invalid mint amount");

    uint8 _addressToMinted = addressToMinted[msg.sender];

    require(
      _addressToMinted + _amount <= maxMintAmount,
      "Address mint cap reached"
    );

    addressToMinted[msg.sender] += _amount;
    for (uint8 i = 0; i < _amount; i++) {
      _safeMint(msg.sender);
    }
  }

  function claimPixelsTo(address _to, uint8 _amount) external payable {
    require(_amount > 0 && _amount <= maxMintAmount, "Invalid mint amount");

    uint8 _addressToMinted = addressToMinted[_to];

    require(
      _addressToMinted + _amount <= maxMintAmount,
      "Address mint cap reached"
    );

    addressToMinted[msg.sender] += _amount;
    for (uint8 i = 0; i < _amount; i++) {
      _safeMint(_to);
    }
  }

  function _currentId() internal view returns (uint256) {
    return _owners.length + 1;
  }

  function _safeMint(address _to) internal {
    require(isActive || msg.sender == owner(), "Sale is not active");
    require(_to != address(0), "Invalid recipient");

    uint256 tokenId = _currentId();

    require(tokenId <= maxSupply, "Max supply reached");

    _pixelTraits[tokenId] = descriptor.genPixel(tokenId);

    super._safeMint(_to, tokenId);
  }

  /*	  _________                               	*/
  /*	 /   _____/ __ __ ______    ____  _______ 	*/
  /*	 \_____  \ |  |  \\____ \ _/ __ \ \_  __ \	*/
  /*	 /        \|  |  /|  |_> >\  ___/  |  | \/	*/
  /*	/_______  /|____/ |   __/  \___  > |__|   	*/
  /*	        \/        |__|         \/         	*/

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*                 && &                     */
/*             & &&&&&&&&                   */
/*          & &&&  &&&             &        */
/*          &  && //~&&&  &  &    & &&&&    */
/*     &    &&& &/|&&& && &      &&&&&\&&&  */
/*   &&&  && & & /~&&&&& &        &|&\&&&&  */
/*   &&&&&\_&&&&&\&/~&&&& &     &\&&        */
/*      &&&\&/    /~_/&&&&&&   \|           */
/*       &     / \_/\&_& &   _/_/           */
/*     &         /  \     _/_/              */
/*                   /~_/_/                 */
/*                     /                    */
/*                    /~~                   */
/*                      /                   */
/*                     /~                   */
/*                      /|                  */
/*                      /~                  */
/*        :___________./~~\.___________:    */
/*         \                          /     */
/*          \________________________/      */
/*          (_)                    (_)      */

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./Ultra721.sol";

/**
 * @title Ultra721Enumerable
 * @author Omar <https://twitter.com/Naomsa666>
 * @notice This is an improved version of the original OpenZeppelin's
 * ERC721Enumerable contract.
 * @dev As you can see, there's no state variable, meaning that the code doesn't
 * get bigger over time and won't you cost virtually nothing.
 */
abstract contract Ultra721Enumerable is Ultra721, IERC721Enumerable {
  /*    ___  _   _  _ _      __   _ __    */
  /*  /',__)( ) ( )( '_`\  /'__`\( '__)   */
  /*  \__, \| (_) || (_) )(  ___/| |      */
  /*  (____/`\___/'| ,__/'`\____)(_)      */
  /*               | |                    */
  /*               (_)                    */

  // As proposed on ERC165.
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, Ultra721)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /*   _           _                          */
  /*  ( )_        ( )                         */
  /*  | ,_)   _   | |/')    __    ___    ___  */
  /*  | |   /'_`\ | , <   /'__`\/' _ `\/',__) */
  /*  | |_ ( (_) )| |\`\ (  ___/| ( ) |\__, \ */
  /*  `\__)`\___/'(_) (_)`\____)(_) (_)(____/ */

  // Returns the amount of tokens minted.
  function totalSupply() public view virtual override returns (uint256) {
    return _owners.length;
  }

  // Returns the tokenId for the index in the owner's wallet.
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(
      index < Ultra721.balanceOf(owner),
      "Ultra721Enumerable: owner index out of bounds"
    );
    return _walletOfOwner(owner)[index];
  }

  // Returns the tokenId for determined index.
  function tokenByIndex(uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(
      index < totalSupply(),
      "Ultra721Enumerable: global index out of bounds"
    );

    return index;
  }

  // Returns an array of tokenIds held by the owner.
  function _walletOfOwner(address owner_)
    internal
    view
    virtual
    returns (uint256[] memory)
  {
    uint256 _balance = balanceOf(owner_);
    uint256[] memory _tokens = new uint256[](_balance);
    uint256 _index;
    for (uint256 i = 0; i < totalSupply(); i++) {
      if (owner_ == ownerOf(i)) {
        _tokens[_index] = i;
        _index++;
      }
    }
    delete _balance;
    return _tokens;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract ERCWithdrawable {
	/*  All functions in this abstract contract are marked as internal because it should
        generally be paired with ownable.
        Virtual is for overwritability.
    */
	function _withdrawERC20(address contractAddress_, uint256 amount_)
		internal
		virtual
	{
		IERC20(contractAddress_).transferFrom(address(this), msg.sender, amount_);
	}

	function _withdrawERC721(address contractAddress_, uint256 tokenId_)
		internal
		virtual
	{
		IERC721(contractAddress_).transferFrom(address(this), msg.sender, tokenId_);
	}

	function _withdrawERC1155(
		address contractAddress_,
		uint256 tokenId_,
		uint256 amount_
	) internal virtual {
		IERC1155(contractAddress_).safeTransferFrom(
			address(this),
			msg.sender,
			tokenId_,
			amount_,
			""
		);
	}

	function _withdrawERC1155Batch(
		address contractAddress_,
		uint256[] calldata ids_,
		uint256[] calldata amounts_
	) internal virtual {
		IERC1155(contractAddress_).safeBatchTransferFrom(
			address(this),
			msg.sender,
			ids_,
			amounts_,
			""
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../lib/PixelCityLibrary.sol";

interface IPixelCityDescritor {
	function baseTokenURI(uint256 _tokenId) external view returns (string memory);

	function tokenURI(uint256 _tokenId, PixelCityLibrary.Pixel memory _pixel)
		external
		view
		returns (string memory);

	function genPixel(uint256 _tokenId)
		external
		view
		returns (PixelCityLibrary.Pixel memory);
}

interface IPixelCityToken {
	/*	                .__           ________                                    	*/
	/*	  ____    ____  |  |   ___.__.\_____  \  __  _  __  ____    ____  _______ 	*/
	/*	 /  _ \  /    \ |  |  <   |  | /   |   \ \ \/ \/ / /    \ _/ __ \ \_  __ \	*/
	/*	(  <_> )|   |  \|  |__ \___  |/    |    \ \     / |   |  \\  ___/  |  | \/	*/
	/*	 \____/ |___|  /|____/ / ____|\_______  /  \/\_/  |___|  / \___  > |__|   	*/
	/*	             \/        \/             \/               \/      \/         	*/

	function setIsActive(bool _isActive) external;

	function setIsRevealed(bool _isRevealed) external;

	function setDescriptor(IPixelCityDescritor _descriptor) external;

	/*	___________         __                     __      __ .__   __   .__         .___                         	*/
	/*	\__    ___/  ____  |  | __  ____    ____  /  \    /  \|__|_/  |_ |  |__    __| _/_______ _____   __  _  __	*/
	/*	  |    |    /  _ \ |  |/ /_/ __ \  /    \ \   \/\/   /|  |\   __\|  |  \  / __ | \_  __ \\__  \  \ \/ \/ /	*/
	/*	  |    |   (  <_> )|    < \  ___/ |   |  \ \        / |  | |  |  |   Y  \/ /_/ |  |  | \/ / __ \_ \     / 	*/
	/*	  |____|    \____/ |__|_ \ \___  >|___|  /  \__/\  /  |__| |__|  |___|  /\____ |  |__|   (____  /  \/\_/  	*/
	/*	                        \/     \/      \/        \/                   \/      \/              \/          	*/

	function withdrawERC20(address contractAddress_, uint256 amount_) external;

	function withdrawERC721(address contractAddress_, uint256 tokenId_) external;

	function withdrawERC1155(
		address contractAddress_,
		uint256 tokenId_,
		uint256 amount_
	) external;

	function withdrawERC1155Batch(
		address contractAddress_,
		uint256[] calldata ids_,
		uint256[] calldata amounts_
	) external;

	function withdrawEther(uint256 _amount) external;

	/*	   _____             __               .___          __           	*/
	/*	  /     \    ____  _/  |_ _____     __| _/_____   _/  |_ _____   	*/
	/*	 /  \ /  \ _/ __ \ \   __\\__  \   / __ | \__  \  \   __\\__  \  	*/
	/*	/    Y    \\  ___/  |  |   / __ \_/ /_/ |  / __ \_ |  |   / __ \_	*/
	/*	\____|__  / \___  > |__|  (____  /\____ | (____  / |__|  (____  /	*/
	/*	        \/      \/             \/      \/      \/             \/ 	*/

	function pixelTraits(uint256 _tokenId)
		external
		view
		returns (PixelCityLibrary.Pixel memory);

	function walletOfOwner(address address_) external returns (uint256[] memory);

	/*	   _____   .__           __   .__                  	*/
	/*	  /     \  |__|  ____  _/  |_ |__|  ____     ____  	*/
	/*	 /  \ /  \ |  | /    \ \   __\|  | /    \   / ___\ 	*/
	/*	/    Y    \|  ||   |  \ |  |  |  ||   |  \ / /_/  >	*/
	/*	\____|__  /|__||___|  / |__|  |__||___|  / \___  / 	*/
	/*	        \/          \/                 \/ /_____/  	*/

	function claimPixels(uint8 _amount) external payable;

	function claimPixelsTo(address _to, uint8 _amount) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*                 && &                     */
/*             & &&&&&&&&                   */
/*          & &&&  &&&             &        */
/*          &  && //~&&&  &  &    & &&&&    */
/*     &    &&& &/|&&& && &      &&&&&\&&&  */
/*   &&&  && & & /~&&&&& &        &|&\&&&&  */
/*   &&&&&\_&&&&&\&/~&&&& &     &\&&        */
/*      &&&\&/    /~_/&&&&&&   \|           */
/*       &     / \_/\&_& &   _/_/           */
/*     &         /  \     _/_/              */
/*                   /~_/_/                 */
/*                     /                    */
/*                    /~~                   */
/*                      /                   */
/*                     /~                   */
/*                      /|                  */
/*                      /~                  */
/*        :___________./~~\.___________:    */
/*         \                          /     */
/*          \________________________/      */
/*          (_)                    (_)      */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title Ultra721
 * @author Omar <https://twitter.com/Naomsa666>
 * @notice An upgraded ERC721 standard contract, focused on gas saving and utility.
 */
abstract contract Ultra721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  string internal _name;

  string internal _symbol;

  address[] internal _owners;

  mapping(uint256 => address) private _tokenApprovals;

  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /*         _           _            */
  /*        ( )_        ( )_          */
  /*    ___ | ,_)   _ _ | ,_)   __    */
  /*  /',__)| |   /'_` )| |   /'__`\  */
  /*  \__, \| |_ ( (_| || |_ (  ___/  */
  /*  (____/`\__)`\__,_)`\__)`\____)  */

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(
      owner != address(0),
      "Ultra721: balance query for the zero address"
    );

    uint256 count = 0;
    uint256 length = _owners.length;
    for (uint256 i = 0; i < length; ++i) {
      if (owner == _owners[i]) {
        count++;
      }
    }

    delete length;
    return count;
  }

  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    address owner = _owners[tokenId];
    require(owner != address(0), "Ultra721: owner query for nonexistent token");
    return owner;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /*   _                              */
  /*  (_ )                _           */
  /*   | |    _      __  (_)   ___    */
  /*   | |  /'_`\  /'_ `\| | /'___)   */
  /*   | | ( (_) )( (_) || |( (___    */
  /*  (___)`\___/'`\__  |(_)`\____)   */
  /*              ( )_) |             */
  /*               \___/'             */

  function approve(address to, uint256 tokenId) public virtual override {
    address owner = Ultra721.ownerOf(tokenId);
    require(to != owner, "Ultra721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "Ultra721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    require(_exists(tokenId), "Ultra721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    require(operator != _msgSender(), "Ultra721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "Ultra721: transfer caller is not owner nor approved"
    );

    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "Ultra721: transfer caller is not owner nor approved"
    );
    _safeTransfer(from, to, tokenId, _data);
  }

  /*             _                               _      */
  /*   _        ( )_                            (_ )    */
  /*  (_)  ___  | ,_)   __   _ __   ___     _ _  | |    */
  /*  | |/' _ `\| |   /'__`\( '__)/' _ `\ /'_` ) | |    */
  /*  | || ( ) || |_ (  ___/| |   | ( ) |( (_| | | |    */
  /*  (_)(_) (_)`\__)`\____)(_)   (_) (_)`\__,_)(___)   */

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "Ultra721: transfer to non Ultra721Receiver implementer"
    );
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return tokenId < _owners.length && _owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    require(_exists(tokenId), "Ultra721: operator query for nonexistent token");
    address owner = Ultra721.ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender));
  }

  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      "Ultra721: transfer to non Ultra721Receiver implementer"
    );
  }

  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "Ultra721: mint to the zero address");
    require(!_exists(tokenId), "Ultra721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);
    _owners.push(to);

    emit Transfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = Ultra721.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);
    _owners[tokenId] = address(0);

    emit Transfer(owner, address(0), tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(
      Ultra721.ownerOf(tokenId) == from,
      "Ultra721: transfer of token that is not own"
    );
    require(to != address(0), "Ultra721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(Ultra721.ownerOf(tokenId), to, tokenId);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("Ultra721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library PixelCityLibrary {
	struct Trait {
		string value;
		string png;
	}

	struct Pixel {
		uint256 accessory;
		uint256 face;
		uint256 tee;
		uint256 head;
	}
}