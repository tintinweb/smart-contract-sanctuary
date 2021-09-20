pragma solidity ^0.4.23;

import "./General.sol";


contract Presale is Ownable, Pausable {

    uint256 public constant MAX_PACKAGES = 5000;

    uint256 public constant PRICE_START = 0.2 ether;
    uint256 public constant PRICE_INCREMENT = 0.00008 ether;
    uint256 public constant PRICE_MAX = PRICE_START + MAX_PACKAGES * PRICE_INCREMENT;
    // price(n) = 0.2 + n * 0.00008; (price(5000) = 0.6 ether)

    uint256 public remainingPackages = MAX_PACKAGES;
    uint256 public constant PACKAGES_MAX_PER_USER = 25;

    event SoldOutOfPackages();

    event Purchased(address buyer, uint256 pkgsBought, uint256 spend);

    mapping (address => uint) private packagesOwnedByUser;

    uint256 public constant PACKAGES_GIFTS = 100;
    mapping (address => uint) public giftPackagesForUser;

    constructor() public {
        //set aside packages for gift packages
        packagesOwnedByUser[owner] = PACKAGES_GIFTS;
        remainingPackages -= PACKAGES_GIFTS;
    }

    // Convenient purchase of as many packages as possible with given ether (excess refunded)
    function () public payable whenNotPaused {
        purchasePackages();
    }

    // EXTERNAL FUNCTIONS
    // For people who have been gifted packages from the owner
    function claimPackages() external {
        uint256 claimable = giftPackagesForUser[msg.sender];
        require(claimable > 0, "No packages to claim");
        giftPackagesForUser[msg.sender] = 0;
        packagesOwnedByUser[msg.sender] += claimable;
    }

    // Owner returning gift packages to supply
    function returnGiftPackages(uint256 packagesToReturn) external onlyOwner {
        require(packagesToReturn > 0, "No packages to return");
        require(packagesToReturn <= packagesOwnedByUser[msg.sender], "Can''t return more than you have");
        packagesOwnedByUser[msg.sender] -= packagesToReturn;
        remainingPackages += packagesToReturn;
    }

    // PUBLIC FUNCTIONS
    // Return how many packages are owned by given user
    function packagesOwned(address _user) public view returns (uint256) {
        require(_user != address(0), "NA: Packages owned by address(0)");
        return packagesOwnedByUser[_user];
    }

    // Purchase as many as possible with given ether (excess refunded)
    function purchasePackages() public payable whenNotPaused {
        purchasePackagesUpto(remainingPackages);
    }

    // execute function only if packages can be bought
    modifier presaleOpen() {
        if (remainingPackages == 0) {
            emit SoldOutOfPackages();
        }
        require(remainingPackages > 0, "No remainingPackages");
        _;
    }

    //Purchase upto given number of packages, fail if not enough eth
    function purchasePackagesUpto(uint256 _maxPkgs) public presaleOpen payable whenNotPaused {
        // Can't request more than the max
        if (_maxPkgs > PACKAGES_MAX_PER_USER) {
            _maxPkgs = PACKAGES_MAX_PER_USER;
        }

        // How much does the next package cost?
        uint256 unitPrice = nextPrice();

        // How many can be bought at this price?
        uint256 pkgs = msg.value / unitPrice;

        // Don't buy more than you want
        if (pkgs > _maxPkgs) {
            pkgs = _maxPkgs;
        }

        // Don't buy more than you can have
        require(packagesOwnedByUser[msg.sender] <= PACKAGES_MAX_PER_USER, "Package limit exceeded");
        if (pkgs + packagesOwnedByUser[msg.sender] > PACKAGES_MAX_PER_USER) {
            pkgs = PACKAGES_MAX_PER_USER - packagesOwnedByUser[msg.sender];
        }

        // Still be buying something
        require(pkgs > 0, "Unable to purchase packages with given ether");

        // Don't buy more than there is left
        if (pkgs >= remainingPackages) {
            pkgs = remainingPackages;
            emit LuckyLast(msg.sender); // ;)
        }
        purchase(pkgs, pkgs * unitPrice);
    }

    event LuckyLast(address);

    // Price increases linearly as packages are sold
    function nextPrice() public view returns (uint256) {
        //y = mx + b where x = packagesSold (ie, max - remaining)
        return PRICE_INCREMENT * (MAX_PACKAGES-remainingPackages) + PRICE_START;
    }

    // OWNER FUNCTIONS
    // Only owner can give 1 gift package per user in given addresses
    function giveGiftPackagePerUser(address[] _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            giveGiftPackages(1, _users[i]);
        }
    }

    // Only owner can give gift packages set aside for this purpose
    function giveGiftPackages(uint256 _amt, address _user) public onlyOwner {
        require(packagesOwnedByUser[msg.sender] >= _amt, "Not enough packages owned to gift");
        packagesOwnedByUser[msg.sender] -= _amt;
        giftPackagesForUser[_user] += _amt;
    }

    // Overrides ownership transfer to include package movement
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Unable to transfer to address(0)");
        giveGiftPackages(packagesOwnedByUser[owner], _newOwner);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    // Transfer amount to owner
    function withdraw(uint256 _amt) public onlyOwner {
        owner.transfer(_amt);
    }


    //INTERNAL/PRIVATE FUNCTIONS
    // Execute a valid purchase of packages, refund excess.
    function purchase(uint256 _pkgs, uint256 _totalCost) internal {
        // Double-check amount paid
        require(msg.value >= _totalCost, "Not enough ether for purchase");

        remainingPackages -= _pkgs;
        packagesOwnedByUser[msg.sender] += _pkgs;

        // Refund any overpayment
        uint256 refund = msg.value - _totalCost;
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
        emit Purchased(msg.sender, _pkgs, _totalCost);
    }

}