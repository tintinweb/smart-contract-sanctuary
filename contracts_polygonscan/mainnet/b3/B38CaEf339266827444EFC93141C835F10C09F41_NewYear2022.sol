//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NewYear2022 is Ownable {
  mapping(address => bool) private _permittedAddress;

  function setPermittedAddress(address contractAddress_, bool permit) external onlyOwner{
    _permittedAddress[contractAddress_] = permit;
  }

  function generateSVG(uint256 id) external view returns(string memory) {
    require(_permittedAddress[_msgSender()]);

    // a base_line stroke:#000;stroke-width:5px
    // b horn_color fill:#b19b75
    // c stroke:#754d25;stroke-width:2px
    // r fill:red
    // w fill:#fff
    string memory svg = string(abi.encodePacked(
      "<svg xmlns='http://www.w3.org/2000/svg' width='1000px' height='1000px' viewBox='0 0 1000 1000'><defs><style>.a{stroke:#000;stroke-width:5px}.b{fill:#b19b75}.c{stroke:#754d25;stroke-width:2px}.r{fill:red}.w{fill:#fff}</style></defs>",
      back(),
      saurus(id),
      "</svg>"
    ));

    return svg;
  }

  function back() internal view returns(string memory) {
    return "<defs><clipPath id='a' transform='translate(88)'><path fill='none' d='M0 277h306v347H0z'/></clipPath></defs><path fill='#fff' d='M88 0h1000v1000H88z'/><path fill='#fff' d='M88 0h1000v1000H88z'/><path fill='none' d='M88 0h1000v1000H88z'/><path fill='#d7ede6' d='M88 0h1000v315H88z'/><path fill='#d8ede5' d='M88 17h1000v315H88z'/><path fill='#d9ede5' d='M88 33h1000v315H88z'/><path fill='#daece4' d='M88 50h1000v315H88z'/><path fill='#dbece3' d='M88 67h1000v315H88z'/><path fill='#dcece3' d='M88 84h1000v314H88z'/><path fill='#ddece2' d='M88 100h1000v315H88z'/><path fill='#deece1' d='M88 117h1000v315H88z'/><path fill='#dfece1' d='M88 134h1000v315H88z'/><path fill='#e0ebe0' d='M88 150h1000v315H88z'/><path fill='#e1ebdf' d='M88 167h1000v315H88z'/><path fill='#e2ebdf' d='M88 184h1000v315H88z'/><path fill='#e3ebde' d='M88 201h1000v314H88z'/><path fill='#e4ebdd' d='M88 217h1000v315H88z'/><path fill='#e5ebdd' d='M88 234h1000v315H88z'/><path fill='#e6eadc' d='M88 251h1000v315H88z'/><path fill='#e7eadb' d='M88 267h1000v315H88z'/><path fill='#e8eadb' d='M88 284h1000v315H88z'/><path fill='#e9eada' d='M88 301h1000v315H88z'/><path fill='#eaead9' d='M88 318h1000v314H88z'/><path fill='#ebead9' d='M88 334h1000v315H88z'/><path fill='#ebe9d8' d='M88 351h1000v315H88z'/><path fill='#ece9d8' d='M88 368h1000v315H88z'/><path fill='#ede9d7' d='M88 384h1000v315H88z'/><path fill='#eee9d6' d='M88 401h1000v315H88z'/><path fill='#efe9d6' d='M88 418h1000v315H88z'/><path fill='#f0e9d5' d='M88 435h1000v314H88z'/><path fill='#f1e8d4' d='M88 451h1000v315H88z'/><path fill='#f2e8d4' d='M88 468h1000v315H88z'/><path fill='#f3e8d3' d='M88 485h1000v315H88z'/><path fill='#f4e8d2' d='M88 501h1000v315H88z'/><path fill='#f5e8d2' d='M88 518h1000v315H88z'/><path fill='#f6e8d1' d='M88 535h1000v315H88z'/><path fill='#f7e7d0' d='M88 551h1000v315H88z'/><path fill='#f8e7d0' d='M88 568h1000v315H88z'/><path fill='#f9e7cf' d='M88 585h1000v315H88z'/><path fill='#fae7ce' d='M88 602h1000v315H88z'/><path fill='#fbe7ce' d='M88 618h1000v315H88z'/><path fill='#fce7cd' d='M88 635h1000v315H88z'/><path fill='#fde6cc' d='M88 652h1000v315H88z'/><path fill='#fee6cc' d='M88 668h1000v315H88z'/><path fill='#ffe6cb' d='M88 685h1000v315H88z'/><circle cx='253.3' cy='158.5' r='92.5' fill='red'/><g clip-path='url(#a)' stroke-miterlimit='10'><path d='M4 261s235 42 361 214' fill='none' stroke='#754c24' stroke-width='3'/><circle cx='366.1' cy='478.2' r='13.1' class='c r'/><circle cx='212.2' cy='341.8' r='13.1' class='c r'/><circle cx='295.5' cy='401.1' r='13.1' class='c r'/><circle cx='333' cy='438.3' r='13.1' class='c w'/><circle cx='256.3' cy='370.2' r='13.1' class='c w'/><circle cx='158.8' cy='313.6' r='13.1' class='c w'/><path d='M2 264s225 79 321 270' fill='none' stroke='#754c24' stroke-width='3'/><circle cx='323.8' cy='537.1' r='13.1' class='c r'/><circle cx='194.4' cy='377.3' r='13.1' class='c r'/><circle cx='266.8' cy='449.5' r='13.1' class='c r'/><circle cx='297.6' cy='492.2' r='13.1' class='c w'/><circle cx='233.2' cy='412.5' r='13.1' class='c w'/><circle cx='146.3' cy='340.7' r='13.1' class='c w'/><path d='M1 253s199 132 245 340' fill='none' stroke='#754c24' stroke-width='3'/><circle cx='246.4' cy='596.8' r='13.1' class='c r'/><circle cx='159.9' cy='410.3' r='13.1' class='c r'/><circle cx='212.5' cy='498' r='13.1' class='c r'/><circle cx='232' cy='547' r='13.1' class='c w'/><circle cx='188.9' cy='454' r='13.1' class='c w'/><circle cx='122.1' cy='363.1' r='13.1' class='c w'/></g>";
  }

  function saurus(uint256 id) internal view returns(string memory) {
    string memory saurusColor;
    string memory eyeColor;
    uint256 colorNum = id % 2;
    if(colorNum == 0){
      saurusColor = 'FFB4C3';
      eyeColor = 'FFAAC9';
    }else{
      saurusColor = '8AC43F';
      eyeColor = '009214';
    }

    string memory eggRibbon;
    uint256 eggType = id % 3;
    if(eggType == 0 || eggType == 1){
      eggRibbon = "";
    }else{
      eggRibbon = "<path d='M512 900s33-71 82-61c0 0 47 30-82 61Z' fill='none' stroke='red' stroke-miterlimit='10' stroke-width='12'/><path d='M513 900s-33-71-83-61c0 0-46 30 83 61Z' fill='none' stroke='red' stroke-miterlimit='10' stroke-width='12'/><path d='M435 945s36 13 81-45' fill='none' stroke='red' stroke-linecap='round' stroke-linejoin='round' stroke-width='12'/><path d='M588 945s-36 13-81-45' fill='none' stroke='red' stroke-linecap='round' stroke-linejoin='round' stroke-width='12'/><path fill='red' stroke='red' stroke-miterlimit='10' stroke-width='.8' d='m138 894 2 12h737l1-12H138z'/>";
    }

    return string(abi.encodePacked(
      "<path d='M317 332s-30-60 30-47ZM367 259c-6-33-8-46 42-38ZM451 195s-8-68 43-23ZM540 151s-13-56 53-16ZM653 127s7-30 16-1ZM724 159s28-46 25 14ZM790 227s43-20 17 17ZM859 358s37-18 1 16Z' class='a b'/><path d='M873 428s32 8-4 26Z' class='a b'/><path d='M307 587s-89-15-13-55ZM288 510s-71-39-2-63ZM294 416s-84-32 6-51Z' class='a b'/><path d='M467 597c-13-1-119-6-150 6a9 9 0 0 1-13-6c-21-62-100-362 291-467 205-55 335 307 266 375a10 10 0 0 1-4 3l-387 89a9 9 0 0 1-3 0Z' fill='#",
      saurusColor,
      "' class='a'/><path d='M361 598s-44 54-91 67-66 145-66 145l520 16 31-251Z' fill='#",
      saurusColor,
      "' class='a'/><path d='M767 600s-14 49 44 50c0 0-51 63-130 1l-4-46Z'/><path d='M772 669s-9-51-62-43c-38 5-30 21-30 21 1 0 63 29 92 22Z' fill='#e7bef0'/><path d='M550 678s-43 111-42 136l216 12 12-133ZM680 648l-1-49-64 6 65 43z' fill='#fff' class='a'/><path d='M811 650s-44 64-196-45l-100 41s32 62 159 52c13-1 93 15 105 19s47-26 32-67Z' fill='#fff' class='a'/><path d='M584 358s158-94 229 56 46 93 46 93-56 21-73 94c0 0-53-8-73 17s-63-11-63-11-42-11-76 24c0 0-62 11-59 17 0 0-38 21-55-96-3-19 8-71 15-80s-13-120 25-112 84-2 84-2Z' fill='#",
      saurusColor,
      "' class='a'/><path d='M494 382s62 57 82 0 13-115 4-126-22 28-37 47-36 21-49 79Z' stroke='#000' stroke-linejoin='round' stroke-width='5' class='b'/><path d='M774 360s76-68 80-83 34 78-43 133Z' class='a b'/><path d='M765 458s70-63 65-76 50 34 7 104c-6 10-59 10-65 1s-7-29-7-29Z' class='a b'/><path d='M852 507a10 10 0 0 1 10 6c10 23 45 110-8 138-21 11-21-27-32-35-7-5-18-9-28-11-6-1-9-7-7-13 8-26 30-81 65-85Z' class='b' stroke='#000' stroke-linejoin='round' stroke-width='5'/><path d='M768 453c-13-10-84 2-84 2' fill='none' class='a'/><path d='M592 486c-4-60 22-70 43-74s57 28 42 75c0 0 1 12-41 13s-44-14-44-14Z' fill='#fff' class='a'/><path d='M640 496s-6-68 11-68 34 37 23 60c0 0-24 14-34 8Z' fill='#",
      eyeColor,
      "' class='a'/><path d='M655 496s-2-52 7-50 22 36 13 44-20 6-20 6Z' class='a'/><ellipse cx='664.6' cy='446' rx='5.3' ry='10.7' transform='rotate(-4 664 446)' fill='#fff'/>",
      "<path d='M145 752h-1 1ZM873 752h-1l-51 40-69-61-55 42-18-21-27 38-25-43-21 45-68-70-62 70-76-45-29 25-86-70-44 64-42-20-7 31-47-25h-1a577 577 0 0 0-6 85c-2 271 184 398 370 392 186 6 372-121 370-392a577 577 0 0 0-5-85Z' fill='#eec825' stroke='#000' stroke-linejoin='round' stroke-width='5'/><path d='M859 805h-1l-45 33-59-86-43 60-14-20-22 29q0 24-2 47c-15 194-122 298-244 324a299 299 0 0 0 91 18c155 17 320-85 337-329a560 560 0 0 0 2-76Z' fill='#eeba26'/><path d='M526 1226c-181-2-356-124-354-377a518 518 0 0 1 3-57l1-8v-4l-24-12a534 534 0 0 0-6 82c-2 260 184 382 370 377h34l-8-1h-16Z' fill='#eeeb88'/><path d='M199 849a509 509 0 0 1 3-57l-24-12-1 4-1 8a509 509 0 0 0-2 57 352 352 0 0 0 361 377h25a352 352 0 0 1-361-377Z' fill='#eed915'/>",
      eggRibbon,
      "<path d='M672 777c-18-63 55-79 94-34' fill='#",
      saurusColor,
      "' class='a'/><path d='M672 777s22-49 50-25-8 94-8 94-19-69-42-69Z' fill='#b19b75' stroke='#000' stroke-linejoin='round' stroke-width='5'/><path d='M728 757s87-56 42 78c0 0-19-73-42-78Z' fill='#b19b75' stroke='#000' stroke-linejoin='round' stroke-width='5'/><path d='M324 752c-3-46 104-85 105 18' fill='#",
      saurusColor,
      "' class='a'/><path d='M318 760s34-42 56 5l-33 73s-32-70-23-78ZM430 771s-17-64-54-5l8 65s47-52 45-60' fill='#b19b75' stroke='#000' stroke-linejoin='round' stroke-width='5'/>"
    ));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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