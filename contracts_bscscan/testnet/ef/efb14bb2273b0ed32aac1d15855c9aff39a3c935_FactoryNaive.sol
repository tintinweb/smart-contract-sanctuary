/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;



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



library AddressUpgradeable {

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


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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


abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal initializer {
        _setOwner(initialOwner);
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

interface MyNFT  {

    function getRoyaltyWallet() external view returns (address);

    function getRoyalty(uint256 _id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

}


contract EscrowUpgradable is Initializable, ContextUpgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address;

    uint256 private _tokenId;

    uint256 private _price;

    MyNFT private _mainContract;

    function initialize(
        uint256 tokenId,
        address cOwner,
        uint256 price,
        address _contract
    ) public virtual initializer {
        __EscrowUpgradable_init(tokenId, cOwner, price, _contract);
    }

    function __EscrowUpgradable_init (
        uint256 tokenId,
        address cOwner,
        uint256 price,
        address _contract
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained(cOwner);
        __EscrowUpgradable_init_unchained(tokenId, price, _contract);
    }

    function __EscrowUpgradable_init_unchained (
        uint256 tokenId,
        uint256 price,
        address _contract
    ) internal initializer {
        _tokenId = tokenId;
        _price = price;
        _mainContract = MyNFT(_contract);
    }

    function getSupply() public view returns (uint256) {
        uint256 balance = _mainContract.balanceOf(address(this), _tokenId);
        return balance;
    }

    function withdraw(uint256 _amount) public onlyOwner  {
        uint256 supply = getSupply();
        require(_amount <= supply, "Insufficient amount to withdraw.");
        _mainContract.safeTransferFrom(address(this), owner(), _tokenId, _amount, "");
    }


    fallback() external payable {
        require(!msg.sender.isContract(), "Payments from contracts are not accepted.");
        require(msg.sender != owner(), "Seller cannot buy own NFT tokens.");
        //require(msg.value >= _price, "Insufficient amount to buy NFT");
        uint256 change = msg.value % _price;
        uint256 amount = msg.value - change;
        uint256 tokenAmount = amount /_price;
        uint256 supply = getSupply();
        require (supply >= tokenAmount, "Insufficient NFT balance to sell.");
        uint256 royaltyPercentage = _mainContract.getRoyalty(_tokenId);
        uint256 royalty = amount * royaltyPercentage / 100;
        address payable royaltyWallet = payable(_mainContract.getRoyaltyWallet());
        address payable seller = payable(owner());
        _mainContract.safeTransferFrom(address(this), msg.sender, _tokenId, tokenAmount, "");
        royaltyWallet.transfer(royalty);
        seller.transfer(amount-royalty);
        if (change > 0) {
            address payable changeWallet = payable(msg.sender);
            changeWallet.transfer(change);
        }

    }

    uint256[50] private __gap;
}

contract FactoryNaive {
    function createEscrow(
        uint256 tokenId,
        uint256 price
    ) external returns (address) {
        EscrowUpgradable escrow = new EscrowUpgradable();
        escrow.initialize(tokenId, msg.sender, price, 0x0766dc4AF61783C90EAf301a8Be876Ce0a1389c1);
        return address(escrow);
    }
}