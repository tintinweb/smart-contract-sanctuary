pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";


interface InitialInvestmentHelpers {
    function mint(address[] memory accounts, uint256[] memory amounts) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address sender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function canEditProperty(address wallet, address property) external view returns (bool);

    function cap() external view returns (uint256);
}

contract InitialInvestment is Ownable {
    using SafeMath for uint256;

    struct Offering {
        uint256 presaleStart;
        uint256 presaleEnd;
        uint256 saleStart;
        uint256 saleEnd;
        uint256 price;
        uint256 amountCollected;
        uint256 maxInvestment;
        uint256 minInvestment;
        address investmentToken;
        address collector;
    }

    mapping(address => Offering) _offerings;
    address private _dataProxy;

    modifier onlyCPOrAdmin(address admin, address property) {
        require(InitialInvestmentHelpers(_dataProxy).canEditProperty(admin, property), "Initial investment: You need to be able to edit property");
        _;
    }

    event Investment(address indexed property, address indexed wallet, address investmentToken, uint256 amountInvested, uint256 amountReceived);
    event InitialOffer(address indexed property, uint256 pricePerToken, uint256 maxInvestment, uint256 minInvestment, uint256 presaleStart, uint256 presaleEnd, uint256 saleStart, uint256 saleEnd, address token, address collector);

    constructor(address dataProxy) public {
        _dataProxy = dataProxy;
    }

    function changeDataProxy(address dataProxy) public onlyOwner {
        _dataProxy = dataProxy;
    }

    function addNewProperty(address property, uint256 price, uint256 maxInvestment, uint256 minInvestment, uint256 presaleStart, uint256 presaleEnd, uint256 saleEnd, address token, address collector) public onlyCPOrAdmin(_msgSender(), property) {
        Offering memory offering = _offerings[property];
        require(offering.presaleStart == 0 || offering.presaleStart > block.timestamp, "Initial investment: Offering already set and it started");
        offering = Offering(presaleStart, presaleEnd, presaleEnd + 3 days, saleEnd, price, 0, maxInvestment, minInvestment, token, collector);
        _offerings[property] = offering;
        emit InitialOffer(property, price, maxInvestment, minInvestment, presaleStart, presaleEnd, presaleStart + 3 days, saleEnd, token, collector);
    }

    function offer(address property, uint256 amount) public {
        Offering memory offering = _offerings[property];
        require(offering.saleStart <= block.timestamp && offering.saleEnd >= block.timestamp, "InitialInvestment: Offering is not active");
        require(amount >= offering.minInvestment, "InitialInvestment: You need to invest more");
        require(offering.maxInvestment == 0 || amount <= offering.maxInvestment, "InitialInvestment: You need to invest less");
        uint256 cap = InitialInvestmentHelpers(property).cap();
        uint256 mintAmount = amount.mul(10 ** 9).div(offering.price).div(10 ** 9);
        uint256 currentSupply = InitialInvestmentHelpers(property).totalSupply();

        require(currentSupply.add(mintAmount) <= cap, "InitialInvestment: Too many tokens would be minted");
        _offerings[property].amountCollected = offering.amountCollected.add(amount);

        require(InitialInvestmentHelpers(offering.investmentToken).transferFrom(_msgSender(), address(this), amount));

        uint256[] memory mAmount = new uint256[](1);
        mAmount[0] = mintAmount;
        address[] memory receiver = new address[](1);
        receiver[0] = _msgSender();
        require(InitialInvestmentHelpers(property).mint(receiver, mAmount));
        emit Investment(property, _msgSender(), offering.investmentToken, amount, mintAmount);
    }

    function collectOffer(address property) public {
        Offering memory offering = _offerings[property];
        require(offering.saleEnd < block.timestamp, "InitialInvestment: You need to wait for initial investment to finish");
        require(InitialInvestmentHelpers(_offerings[property].investmentToken).transfer(offering.collector, _offerings[property].amountCollected));
    }

    function currentSupply(address property) public view returns (uint256) {
        return InitialInvestmentHelpers(_offerings[property].investmentToken).totalSupply();
    }

    function offeringInfo(address property) public view returns (Offering memory) {
        return _offerings[property];
    }
}