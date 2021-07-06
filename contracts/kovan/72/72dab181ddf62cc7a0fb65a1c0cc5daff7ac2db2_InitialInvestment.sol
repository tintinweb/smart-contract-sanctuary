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

    function contractBurn(address user, uint256 amount) external returns (bool);

    function cap() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
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
        uint256 softCap;
        address investmentToken;
        address collector;
        bool investmentCollected;
    }

    mapping(address => mapping(address => mapping(uint16 => uint256))) private _userInvestment;
    mapping(address => Offering) private _offerings;
    mapping(address => uint16) private _numOfSuccessfulOfferings;
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

    // Price should support 2 decimal meaning for 10.12 put 1012 for 10 put 1000
    function modifyOfferingInfo(address property, uint256 price, uint256 maxInvestment, uint256 minInvestment, uint256 softCap, uint256 presaleStart, uint256 presaleEnd, uint256 saleEnd, address token, address collector) public onlyCPOrAdmin(_msgSender(), property) {
        require(presaleStart <= presaleEnd && (presaleEnd + 3 days) <= saleEnd, "InitialInvestment: Start time must be before end time");
        Offering memory offering = _offerings[property];
        require(offering.presaleStart == 0 || offering.presaleStart > block.timestamp || offering.saleEnd < block.timestamp, "Initial investment: Offering already set and it started");
        require(offering.amountCollected == 0 || offering.investmentCollected, "InitialInvestment: You need to collect investments first");
        offering = Offering(presaleStart, presaleEnd, presaleEnd + 3 days, saleEnd, price, 0, maxInvestment, minInvestment, softCap, token, collector, false);
        _offerings[property] = offering;
        emit InitialOffer(property, price, maxInvestment, minInvestment, presaleStart, presaleEnd, presaleStart + 3 days, saleEnd, token, collector);
    }

    function invest(address property, uint256 amount) public {
        Offering memory offering = _offerings[property];
        require(offering.saleStart <= block.timestamp && offering.saleEnd >= block.timestamp, "InitialInvestment: Offering is not active");
        require(amount >= offering.minInvestment, "InitialInvestment: You need to invest more");
        require(amount <= offering.maxInvestment, "InitialInvestment: You need to invest less");
        uint256 cap = InitialInvestmentHelpers(property).cap();
        uint256 mintAmount = amount.mul(10 ** 9).div(offering.price).div(10 ** 7);
        uint256 currentSupply = InitialInvestmentHelpers(property).totalSupply();

        require(currentSupply.add(mintAmount) <= cap, "InitialInvestment: Too many tokens would be minted");
        _offerings[property].amountCollected = offering.amountCollected.add(amount);

        require(InitialInvestmentHelpers(offering.investmentToken).transferFrom(_msgSender(), address(this), amount));

        uint256[] memory mAmount = new uint256[](1);
        mAmount[0] = mintAmount;
        address[] memory receiver = new address[](1);
        receiver[0] = _msgSender();
        _userInvestment[property][_msgSender()][_numOfSuccessfulOfferings[property]] = _userInvestment[property][_msgSender()][_numOfSuccessfulOfferings[property]].add(amount);
        require(InitialInvestmentHelpers(property).mint(receiver, mAmount));
        emit Investment(property, _msgSender(), offering.investmentToken, amount, mintAmount);
    }

    function collectInvestments(address property) public {
        Offering storage offering = _offerings[property];
        require(offering.softCap <= offering.amountCollected, "InitialInvestment: Soft cap not reached");
        require(offering.saleEnd < block.timestamp, "InitialInvestment: You need to wait for initial investment to finish");
        uint256 collected = offering.amountCollected;
        offering.amountCollected = 0;
        offering.investmentCollected = true;
        _numOfSuccessfulOfferings[property] = _numOfSuccessfulOfferings[property] + 1;
        require(InitialInvestmentHelpers(_offerings[property].investmentToken).transfer(offering.collector, collected));
    }

    function returnInvestment(address property, address[] memory wallets) public onlyCPOrAdmin(msg.sender, property) {
        Offering storage offering = _offerings[property];
        require(offering.saleEnd <= block.timestamp && offering.softCap > offering.amountCollected, "InitialInvestment: Soft cap must not be reached");
        for (uint i = 0; i < wallets.length; i++) {
            uint256 userBalance = InitialInvestmentHelpers(property).balanceOf(_msgSender());
            uint256 userInvestment = _userInvestment[property][_msgSender()][_numOfSuccessfulOfferings[property]];
            address wallet = wallets[i];
            _userInvestment[property][wallet][_numOfSuccessfulOfferings[property]] = 0;
            require(InitialInvestmentHelpers(property).contractBurn(wallet, userBalance));
            require(InitialInvestmentHelpers(property).transfer(wallet, userInvestment));
            _offerings[property].amountCollected = _offerings[property].amountCollected.sub(userInvestment);
        }
    }

    function currentSupply(address property) public view returns (uint256) {
        return InitialInvestmentHelpers(property).totalSupply();
    }

    function hardCap(address property) public view returns (uint256) {
        return InitialInvestmentHelpers(property).cap();
    }

    function offeringInfo(address property) public view returns (Offering memory) {
        return _offerings[property];
    }
}