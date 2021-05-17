// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.16;

import "./SafeMath.sol";


contract KetherHomepage {
    using SafeMath for uint256;

    /// Buy is emitted when an ad unit is reserved.
    event Buy(
        uint indexed idx,
        address owner,
        uint x,
        uint y,
        uint width,
        uint height
    );

    /// Publish is emitted whenever the contents of an ad is changed.
    event Publish(
        uint indexed idx,
        string link,
        string image,
        string title,
        bool NSFW
    );

    /// SetAdOwner is emitted whenever the ownership of an ad is transfered
    event SetAdOwner(
        uint indexed idx,
        address from,
        address to
    );

    /// Price is 1 kether divided by 1,000,000 pixels
    uint public weiPixelPrice = 1000000000000000;

    /// Each grid cell represents 100 pixels (10x10).
    uint public pixelsPerCell = 100;

    bool[100][100] public grid;

    /// contractOwner can withdraw the funds and override NSFW status of ad units.
    address contractOwner;

    /// withdrawWallet is the fixed destination of funds to withdraw. It is
    /// separate from contractOwner to allow for a cold storage destination.
    address payable withdrawWallet;

    struct Ad {
        address owner;
        uint x;
        uint y;
        uint width;
        uint height;
        string link;
        string image;
        string title;

        /// NSFW is whether the ad is suitable for people of all
        /// ages and workplaces.
        bool NSFW;
        /// forceNSFW can be set by owner.
        bool forceNSFW;
    }

    /// ads are stored in an array, the id of an ad is its index in this array.
    Ad[] public ads;

    constructor(address _contractOwner, address payable _withdrawWallet) public {
        require(_contractOwner != address(0));
        require(_withdrawWallet != address(0));

        contractOwner = _contractOwner;
        withdrawWallet = _withdrawWallet;
    }

    /// getAdsLength tells you how many ads there are
    function getAdsLength() public view returns (uint) {
        return ads.length;
    }

    /// Ads must be purchased in 10x10 pixel blocks.
    /// Each coordinate represents 10 pixels. That is,
    ///   _x=5, _y=10, _width=3, _height=3
    /// Represents a 30x30 pixel ad at coordinates (50, 100)
    function buy(uint _x, uint _y, uint _width, uint _height) external payable returns (uint idx) {
        uint cost = _width.mul(_height).mul(pixelsPerCell).mul(weiPixelPrice);
        require(cost > 0);
        require(msg.value >= cost);

        // Loop over relevant grid entries
        for(uint i=0; i<_width; i++) {
            for(uint j=0; j<_height; j++) {
                if (grid[_x.add(i)][_y.add(j)]) {
                    // Already taken, undo.
                    revert();
                }
                grid[_x.add(i)][_y.add(j)] = true;
            }
        }

        // We reserved space in the grid, now make a placeholder entry.
        Ad memory ad = Ad(msg.sender, _x, _y, _width, _height, "", "", "", false, false);
        ads.push(ad);
        idx = ads.length - 1;

        emit Buy(idx, msg.sender, _x, _y, _width, _height);
        return idx;
    }

    /// Publish allows for setting the link, image, and NSFW status for the ad
    /// unit that is identified by the idx which was returned during the buy step.
    /// The link and image must be full web3-recognizeable URLs, such as:
    ///  - bzz://a5c10851ef054c268a2438f10a21f6efe3dc3dcdcc2ea0e6a1a7a38bf8c91e23
    ///  - bzz://mydomain.eth/ad.png
    ///  - https://cdn.mydomain.com/ad.png
    /// Images should be valid PNG.
    function publish(uint _idx, string memory _link, string memory _image, string memory _title, bool _NSFW) public {
        Ad storage ad = ads[_idx];
        require(msg.sender == ad.owner);
        ad.link = _link;
        ad.image = _image;
        ad.title = _title;
        ad.NSFW = _NSFW;

        emit Publish(_idx, ad.link, ad.image, ad.title, ad.NSFW || ad.forceNSFW);
    }

    /// setAdOwner changes the owner of an ad unit
    function setAdOwner(uint _idx, address _newOwner) public {
        Ad storage ad = ads[_idx];
        require(msg.sender == ad.owner);
        ad.owner = _newOwner;

        emit SetAdOwner(_idx, msg.sender, _newOwner);
    }

    /// forceNSFW allows the owner to override the NSFW status for a specific ad unit.
    function forceNSFW(uint _idx, bool _NSFW) public {
        require(msg.sender == contractOwner);
        Ad storage ad = ads[_idx];
        ad.forceNSFW = _NSFW;

        emit Publish(_idx, ad.link, ad.image, ad.title, ad.NSFW || ad.forceNSFW);
    }

    /// withdraw allows the owner to transfer out the balance of the contract.
    function withdraw() public {
        require(msg.sender == contractOwner);
        withdrawWallet.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}