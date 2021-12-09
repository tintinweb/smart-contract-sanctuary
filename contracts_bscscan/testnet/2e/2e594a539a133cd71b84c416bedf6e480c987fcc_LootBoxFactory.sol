/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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

contract Random {

    uint256 private _randNonce = 0;

    function _randMod(uint256 modulus) internal returns(uint256) {
        _randNonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _randNonce))) % modulus;}
}

interface ICyberWayNFT {

    function transferFrom(address from, address to, uint256 tokenId) external;

    function mint(address to, uint8 kind_, uint8 newColorFrame_, uint8 rand_) external returns(uint256);

    function burn(uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function getTokenKind(uint256 tokenId) external view returns(uint8);

    function getTokenColor(uint256 tokenId) external view returns(uint8);

    function getTokenRand(uint256 tokenId) external view returns(uint8);
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract LootBoxFactory is Ownable, Random {

    struct LootBox {
        uint16[6] rand;
        uint256 price;
        uint256 maxCount;
        uint256 currentCount;
    }

    ICyberWayNFT public nft;
    LootBox[] public boxes;

    address payable public seller;

    event NewBoxBought(address buyer, uint256 tokenId);
    event NewSeller(address payable newSeller);

    constructor(address _nft) {
        nft = ICyberWayNFT(_nft);
        seller = payable(msg.sender);
        _addBox([330, 33, 2, 570, 60, 5], 64000000000000000, 20000);
        _addBox([270, 90, 6, 470, 150, 14], 160000000000000000, 5000);
        _addBox([270, 180, 40, 270, 200, 40], 430000000000000000, 1000);
        _addBox([0, 250, 350, 0, 0, 400], 1050000000000000000, 400);
    }


    receive() external payable {
        revert("LootBoxFactory: use buyBox");
    }


    function setPrices(uint256 boxOnePrice,
                        uint256 boxTwoPrice,
                        uint256 boxThreePrice,
                        uint256 boxFourPrice) public onlyOwner {
        require(boxOnePrice > 0 && boxTwoPrice > 0 &&
                boxThreePrice > 0 && boxFourPrice > 0, "LootBoxFactory: incorrect price");

        boxes[0].price = boxOnePrice;
        boxes[1].price = boxTwoPrice;
        boxes[2].price = boxThreePrice;
        boxes[3].price = boxFourPrice;
    }


    function buyBox(uint256 _boxId) public payable {
        require(_boxId < boxes.length, "LootBoxFactory: This box isn't exist");
        require(boxes[_boxId].price == msg.value, "LootBoxFactory: incorrect value");
        require(boxes[_boxId].currentCount + 1 < boxes[_boxId].maxCount, "LootBoxFactory: box limit is exhausted");

        (uint8 tokenKind, uint8 tokenColor, uint8 tokenRand) = _rand(_boxId); // got token parameters

        uint256 tokenId = nft.mint(msg.sender, tokenKind, tokenColor, tokenRand);
        Address.sendValue(seller, msg.value);

        boxes[_boxId].currentCount += 1;
        emit NewBoxBought(msg.sender, tokenId);
    }


    function updateSellerAddress(address payable newSeller_) public onlyOwner {
        require(newSeller_ != address(0x0), "LootBoxFactory: zero address");
        seller = newSeller_;
        emit NewSeller(newSeller_);
    }


    function withdrawFactoryBalance() public onlyOwner {
        Address.sendValue(seller, address(this).balance);
    }


    function getBox(uint256 boxId_) public view returns(LootBox memory) {
        return boxes[boxId_];
    }


    function getBoxPrice(uint256 boxId_) public view returns(uint256) {
        return boxes[boxId_].price;
    }


    function _addBox(uint16[6] memory rand_, uint256 price_, uint256 maxCount_) private {
        LootBox memory newBox = LootBox({rand: rand_, price: price_, maxCount: maxCount_, currentCount:0});
        boxes.push(newBox);
    }


    /*
    Getting token parameters
    */
    function _rand(uint256 _boxId) private returns(uint8 kind, uint8 color, uint8 rand) {
        uint8[2] memory result_ = _generateRarities(boxes[_boxId].rand);
        kind = result_[0];
        rand = result_[1];
        color =  _generateColor();
    }


    function _generateRarities(uint16[6] memory _chances) private returns(uint8[2] memory) {
        uint8[2] memory result_; // kind / rand
        uint256 chance = _randMod(1000);

        if (chance <= _chances[0]) {
            result_ = [0,0]; // character Common
        }
        if (chance <= _chances[1]) {
            result_ = [0,1]; // character Uncommon
        }
        if (chance <= _chances[2]) {
            result_ = [0,2]; // character Rare
        }
        if (chance <= _chances[3]) {
            result_ = [1,0]; // car Common
        }
        if (chance <= _chances[4]) {
            result_ = [1,1]; //  car Uncommon
        }
        if (chance <= _chances[5]) {
            result_ = [1,2]; // car Rare
        }
        return result_;
    }


    function _generateColor() private returns(uint8) {
        uint8 result_; // kind / rand
        uint256 chance = _randMod(1000);

        if (chance <= 1000) {
            result_ = 0; // Grey
        }
        if (chance <= 800) {
            result_ = 1; // Green
        }
        if (chance <= 600) {
            result_ = 2; // Blue
        }
        if (chance <= 400) {
            result_ = 3; // Purple
        }
        if (chance <= 200) {
            result_ = 4; // Gold
        }
        return result_;
    }
}