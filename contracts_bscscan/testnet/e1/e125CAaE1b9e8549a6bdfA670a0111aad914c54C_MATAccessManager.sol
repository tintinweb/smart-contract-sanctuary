// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IMATAccessManager {
    function isBornAllowed(address _caller, uint256 _gene)
        external
        view
        returns (bool);

    function isEvolveAllowed(
        address _caller,
        uint256 _gene,
        uint256 _nftId
    ) external view returns (bool);

    function isBreedAllowed(
        address _caller,
        uint256 _nftId1,
        uint256 _nftId2
    ) external view returns (bool);

    function isDestroyAllowed(address _caller, uint256 _nftId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IMATAccessManager.sol";
import "./Ownable.sol";

contract MATAccessManager is IMATAccessManager, Ownable {
    bool publicAll;
    bool bornPublicAll;
    bool evolvePublicAll;
    bool breedPublicAll;
    bool destroyPublicAll;

    mapping(address => bool) bornWhilelist;
    mapping(address => bool) evolveWhilelist;
    mapping(address => bool) breedWhilelist;
    mapping(address => bool) destroyWhilelist;

    function setPublicAll(bool _publicAll) public onlyOwner {
        publicAll = _publicAll;
    }

    function setBornWhilelist(address _to, bool _isWhilelist) public onlyOwner {
        bornWhilelist[_to] = _isWhilelist;
    }

    function setEvolveWhilelist(address _to, bool _isWhilelist)
        public
        onlyOwner
    {
        evolveWhilelist[_to] = _isWhilelist;
    }

    function setBreedWhilelist(address _to, bool _isWhilelist)
        public
        onlyOwner
    {
        breedWhilelist[_to] = _isWhilelist;
    }

    function setDestroyWhilelist(address _to, bool _isWhilelist)
        public
        onlyOwner
    {
        destroyWhilelist[_to] = _isWhilelist;
    }

    function setBornPublicAll(bool _bornPublicAll) public onlyOwner {
        bornPublicAll = _bornPublicAll;
    }

    function setEvolvePublicAll(bool _evolvePublicAll) public onlyOwner {
        evolvePublicAll = _evolvePublicAll;
    }

    function setBreedPublicAll(bool _breedPublicAll) public onlyOwner {
        breedPublicAll = _breedPublicAll;
    }

    function setDestroyPublicAll(bool _destroyPublicAll) public onlyOwner {
        destroyPublicAll = _destroyPublicAll;
    }

    function isBornAllowed(address _caller, uint256 _gene)
        external
        view
        override
        returns (bool)
    {
        //TODO: can check _gene validation
        return publicAll || bornPublicAll || bornWhilelist[_caller];
    }

    function isEvolveAllowed(
        address _caller,
        uint256 _gene,
        uint256 _nftId
    ) external view override returns (bool) {
        //TODO: can check _gene and _nftId validation
        return publicAll || bornPublicAll || evolveWhilelist[_caller];
    }

    function isBreedAllowed(
        address _caller,
        uint256 _nftId1,
        uint256 _nftId2
    ) external view override returns (bool) {
        //TODO: can check _gene and _nftId validation
        return publicAll || bornPublicAll || breedWhilelist[_caller];
    }

    function isDestroyAllowed(address _caller, uint256 _nftId)
        external
        view
        override
        returns (bool)
    {
        //TODO: can check _gene and _nftId validation
        return publicAll || bornPublicAll || destroyWhilelist[_caller];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../util/Context.sol";

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}