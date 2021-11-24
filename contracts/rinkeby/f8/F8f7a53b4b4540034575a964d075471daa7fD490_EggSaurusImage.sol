//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EggSaurusImage is Ownable {
  mapping(address => bool) private _permittedAddress;
    
  // 最悪なくてもいい
  function setPermittedAddress(address contractAddress_, bool permit) external onlyOwner{
    _permittedAddress[contractAddress_] = permit;
  }

  function generateSVG(uint256 id, uint256 saurusItem, uint256 saurusCollar) external view returns(string memory) {
    require(_permittedAddress[_msgSender()], 'invalid');

    string memory backColor;
    uint256 backNum = id % 11;
    if(backNum == 0){
      backColor = '4d4d4d';
    }else if(backNum == 1){
      backColor = 'b9a48b';
    }else if(backNum == 2){
      backColor = '39a74a';
    }else if(backNum == 3){
      backColor = '006837';
    }else if(backNum == 4){
      backColor = 'e34044';
    }else if(backNum == 5){
      backColor = '754c24';
    }else if(backNum == 6){
      backColor = 'c48f2c';
    }else if(backNum == 7){
      backColor = '299dd4';
    }else if(backNum == 8){
      backColor = '213368';
    }else if(backNum == 9){
      backColor = 'ffb633';
    }else{
      backColor = 'e68b9d';
    }

    string memory svg = string(abi.encodePacked(
      "<svg xmlns='http://www.w3.org/2000/svg' width='1000px' height='1000px' viewBox='0 0 1000 1000' style='background-color:#",
      backColor,
      // a 基本のライン
      // b 歯の色
      // d 手の爪の色
      "'><defs><style>.a{stroke:#000;stroke-width:5px}.b{fill:#929492}.d{fill:#909090}</style></defs>",
      saurus(id),
      eye(id),
      hat(id),
      collar(saurusCollar),
      item(saurusItem),    
      "</svg>"
    ));

    return svg;
  }

  function generateEggSVG() external view returns(string memory) {
    string memory svg = string(abi.encodePacked(
      "<svg xmlns='http://www.w3.org/2000/svg' width='1000px' height='1000px' viewBox='0 0 1000 1000'>",
      "<rect width='1000' height='1000' style='fill:#00b994'/>",
      "</svg>"
    ));

    return svg;
  }

  function saurus(uint256 id) internal view returns(string memory) {
    string memory saurusColor;
    uint256 colorNum = id % 8;
    if(colorNum == 0){
      saurusColor = '657c80';
    }else if(colorNum == 1){
      saurusColor = 'b88e6d';
    }else if(colorNum == 2){
      saurusColor = 'efbdb8';
    }else if(colorNum == 3){
      saurusColor = '0071ae';
    }else if(colorNum == 4){
      saurusColor = 'e9851e';
    }else if(colorNum == 5){
      saurusColor = 'bdd05d';
    }else if(colorNum == 6){
      saurusColor = 'b3272d';
    }else{
      saurusColor = '8b8b8b';
    }

    string memory eggColor;
    uint256 eggColorNum = id % 5;
    if(eggColorNum == 0){
      eggColor = "";
    }else if(eggColorNum == 1){
      eggColor = "";
    }else if(eggColorNum == 2){
      eggColor = "";
    }else if(eggColorNum == 3){
      eggColor = "";
    }else{
      eggColor = "";
    }

    string memory egg;
    if(id % 501 == 0) {
      // gold
      egg = "";
    }else{
      egg = string(abi.encodePacked(
        "aaaa",
        eggColor,
        "bbbb"
      ));
    }

    return string(abi.encodePacked(
             "<path d='M531.51,396.18S529.29,365,592,368l314,.9-10.83,48.56-14-28.68-17.33,48.39L842.41,416.9l-7.75,28-14.13-17.62-11.78,24.44-15-13.52-24.33,9.5,15.75,12.62,3.87-9.71,18.66,18.81,16.53-18.5,10.14,17.58,12.71-15.61,5.1,19.39,7,8.24L737.51,512.57l-205-107Z'/><path d='M890,205.42c-206.87,38.49-242.05-52.77-242.05-52.77-19.89-3.32-54.73,18.24-79.66,36.22L460.46,155.71,374.9,215.59,301.35,212l-5.42,76.41-30.79,22.47,17.67,36.83-28.66,42.65,25.92,37.85L263,472.23c20.18,34.25,54.58,110.41,32.67,124.15s-75.78,197-75.78,197l.39,92.44L777.29,747.24,691.6,658.11C655.16,647,672.36,585,672.36,585L532.78,396.64c5.32-62.14,253.61-2.81,253.61-2.81,41.15-31.57,127.7-24,127.7-24C960.27,351.26,890,205.42,890,205.42Z' class='a' style='fill: #",
             saurusColor,
             "'/><path d='M723.18,504.55l-98.86-55.3s22.46-29.85,50.5-2.12c0,0,15.47-20,28.27-13.83,0,0,79.8,36.44,80.27,44.3C783.36,477.6,749.63,515.08,723.18,504.55Z' style='fill:#e5a189'/><path d='M544.82,379.93s29.47-11.65,46-9.61L557.43,410Z' class='b'/><polygon points='656.13 373.07 614.11 410.45 592.04 368.01 656.13 373.07' class='b'/><polygon points='702.08 377.97 656.13 373.07 651.34 379.11 668.37 417.35 702.08 377.97' class='b'/><polygon points='752.79 386.37 721.95 422.75 703.83 377.47 752.79 386.37' class='b'/><path d='M817,381s-33.16,11.14-31.34,14.64-.85.22-.85.22l-31.33-8.77,25.92,28.5Z' class='b'/><polygon points='845.87 372.59 817.59 380.03 824.73 407.15 845.87 372.59' class='b'/><polygon points='872.41 370.39 848.04 372.02 855.17 399.14 872.41 370.39' class='b'/><polygon points='894.48 369.37 873.91 370 877.21 394.66 894.48 369.37' class='b'/><polygon points='581.69 429.09 595.58 409.75 616.31 447.5 581.69 429.09' class='b'/><polygon points='632.74 453.87 643.92 445.92 651.91 464.59 632.74 453.87' class='a b'/><polygon points='677.62 478.97 692.26 461 712.36 498.4 677.62 478.97' class='a b'/><polygon points='720.61 502.89 738.67 480.58 753.66 505.95 720.61 502.89' class='a b'/><polyline points='803.93 492.13 779.35 475.46 751.06 503.41' class='a b'/><polygon points='826.6 489.06 807.62 472.81 794.91 497.4 826.6 489.06' class='b'/><polygon points='848.22 483.37 837.46 472.77 829.61 488.33 848.22 483.37' class='b'/><path d='M526.93,403.75c-84.82,10.66-147.73,37.16-110.42,114.7S581.25,601,581.25,601s92.31-29.8,125.69-24.47S789.17,597,808.17,590.73s103.82-74.92,63.3-112c0,0-129.43,34.08-147.88,25Z' style='fill:#eedfa8;' class='a'/><path d='M569.18,188.44s77.6,38.88,115.61,37.35,73.26,1.94,90.73,14' style='fill:none;' class='a'/><line x1='882.62' y1='228.99' x2='880.03' y2='231.27' class='a'/><line x1='852.54' y1='242.01' x2='864.08' y2='243.44' class='a'/>",
             egg,
             "<path d='M183.24,759.11c-12.37-56.1,118-123.06,137.29,4' class='a c'/><path d='M183.68,763.15s32.23-58.91,70.55-7.23l-37.16,91.34S175.07,775.86,183.68,763.15Z' class='a d'/><path d='M319.13,764s-28.84-77.81-67.63,0l5.79,71.7s64.31-62.45,60.88-72.38' class='a d'/><path d='M686.87,761.77C678,680.59,775.14,680.26,813.3,744' class='a c'/><path d='M688.8,764s37.09-55,67.21-20.3S716,846.91,716,846.91,716.83,768.35,688.8,764Z' class='a d'/><path d='M761.15,749.36s112-53.84,17.71,95.85C778.86,845.21,787.7,762.25,761.15,749.36Z' class='a d'/>"
           ));
  }

  function eye(uint256 id) internal view returns(string memory) {
    uint256 num = id % 9;
    if(num == 0){
      return "";
    }else if(num == 1){
      return "";
    }else if(num == 2){
      return "";
    }else if(num == 3){
      return "";
    }else if(num == 4){
      return "";
    }else if(num == 5){
      return "";
    }else if(num == 6){
      return "";
    }else if(num == 7){
      return "";
    }else{
      return "";
    }
  }

  function hat(uint256 id) internal view returns(string memory) {
    uint256 num = id % 7;
    if(num == 0){
      return "";
    }else if(num == 1){
      return "";
    }else if(num == 2){
      return "";
    }else if(num == 3){
      return "";
    }else if(num == 4){
      return "";
    }else if(num == 5){
      return "";
    }else{
      return "";
    }
  }

  function collar(uint256 saurusCollar) internal view returns(string memory) {
    uint256 num = saurusCollar % 1001;

    if(num < 450) {
      return "";
    }
    if(num < 900) {
      return "";
    }else if(num < 1000) {
      return "";
    }else{
      return "";
    }
  }

  function item(uint256 saurusItem) internal view returns(string memory) {
    uint256 num = saurusItem % 901;

    if(num < 150){
      return "";
    }else if(num < 300){
      return "";
    }else if(num < 450){
      return "";
    }else if(num < 600){
      return "";
    }else if(num < 750){
      return "";
    }else if(num < 900){
      return "";
    }else{
      return "";
    }
  }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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