// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
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

contract BartMinter is Ownable {
    struct MintParams {
        uint256 _tokenPrice;
        uint256 _methodId; // 3 is for mint(_to, _amount); 2 is for mint(_to); 1 is for mint(_amount); 0 is mint()
    }

    function mint(
        address _targetToken,
        address[] memory wallets,
        uint256[] memory _maxMintPerWallets,
        bytes calldata params
    ) external payable onlyOwner {
        TARGET _target = TARGET(_targetToken);

        MintParams memory decodedParams = _decodeParams(params);

        if (decodedParams._methodId == 3) {
            for (uint256 i = 0; i < wallets.length; i++) {
                _target.mint{value: decodedParams._tokenPrice}(
                    wallets[i],
                    _maxMintPerWallets[i]
                );
            }
        } else if (decodedParams._methodId == 2) {
            for (uint256 i = 0; i < wallets.length; i++) {
                _target.mint{value: decodedParams._tokenPrice}(wallets[i]);
            }
        } else if (decodedParams._methodId == 1) {
            for (uint256 i = 0; i < wallets.length; i++) {
                _target.mint{value: decodedParams._tokenPrice}(
                    _maxMintPerWallets[i]
                );
            }
        } else if (decodedParams._methodId == 0) {
            for (uint256 i = 0; i < wallets.length; i++) {
                _target.mint{value: decodedParams._tokenPrice}();
            }
        } else {
            // @dev TODO refactor to return codes instead to save gas
            revert(
                string(
                    abi.encode(
                        'Unsupported method id: ',
                        decodedParams._methodId
                    )
                )
            );
        }
    }

    function _decodeParams(bytes memory _params)
        internal
        pure
        returns (MintParams memory)
    {
        (uint256 _tokenPrice, uint256 _methodId) = abi.decode(
            _params,
            (uint256, uint256)
        );

        return MintParams(_tokenPrice, _methodId);
    }
}

interface TARGET {
    function mint(address, uint256) external payable;

    function mint(address) external payable;

    function mint(uint256) external payable;

    function mint() external payable;
}