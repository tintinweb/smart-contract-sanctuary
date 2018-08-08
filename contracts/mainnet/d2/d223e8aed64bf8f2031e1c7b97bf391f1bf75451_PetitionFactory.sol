pragma solidity 0.4.21;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/*
  ____      _   _ _   _               _       
 |  _ \ ___| |_(_) |_(_) ___  _ __   (_) ___  
 | |_) / _ \ __| | __| |/ _ \| &#39;_ \  | |/ _ \ 
 |  __/  __/ |_| | |_| | (_) | | | |_| | (_) |
 |_|   \___|\__|_|\__|_|\___/|_| |_(_)_|\___/ 

*/

contract PetitionFactory is Ownable {

    using SafeMath for uint;

    event NewPetition(uint petitionId, string name, string message, address creator, uint signaturesNeeded, bool featured, uint featuredExpires, uint totalSignatures, uint created, string connectingHash, uint advertisingBudget);
    event NewPetitionSigner(uint petitionSignerId, uint petitionId, address petitionSignerAddress, uint signed);
    event NewPetitionShareholder(uint PetitionShareholderId, address PetitionShareholderAddress, uint shares, uint sharesListedForSale, uint lastDividend);
    event DividendClaim(uint divId, uint PetitionShareholderId, uint amt, uint time, address userAddress);
    event NewShareholderListing(uint shareholderListingId, uint petitionShareholderId, uint sharesForSale, uint price, bool sold);

    struct Petition {
        string name;
        string message;
        address creator;
        uint signaturesNeeded;
        bool featured;
        uint featuredExpires;
        uint totalSignatures;
        uint created;
        string connectingHash;
        uint advertisingBudget; // an easy way for people to donate to the petition cause. We will use this budget for CPC, CPM text and banner ads around petition.io
    }

    struct PetitionSigner {
        uint petitionId;
        address petitionSignerAddress;
        uint signed;
    }

    struct PetitionShareholder {
        address PetitionShareholderAddress;
        uint shares;
        uint sharesListedForSale; // prevent being able to double list shares for sale
        uint lastDividend;
    }

    struct DividendHistory {
        uint PetitionShareholderId;
        uint amt;
        uint time;
        address userAddress;
    }

    struct ShareholderListing {
        uint petitionShareholderId;
        uint sharesForSale;
        uint price;
        bool sold;
    }

    Petition[] public petitions;

    PetitionSigner[] public petitionsigners;
    mapping(address => mapping(uint => uint)) ownerPetitionSignerArrayCreated;
    mapping(address => mapping(uint => uint)) petitionSignerMap;

    PetitionShareholder[] public PetitionShareholders;
    mapping(address => uint) ownerPetitionShareholderArrayCreated;
    mapping(address => uint) PetitionShareholderMap;

    DividendHistory[] public divs;

    ShareholderListing[] public listings;

    uint createPetitionFee = 1000000000000000; // 0.001 ETH
    uint featurePetitionFee = 100000000000000000; // 0.1 ETH
    uint featuredLength = 604800; // 1 week

    /********************************* */
    // shareholder details

    //uint petitionIoShares = 1000000; // 1,000,000 (20%) of shares given to Petition.io Inc. This is needed so Petition.io Inc can collect 20% of the fees to keep the lights on and continually improve the platform

    uint sharesSold = 0;

    uint maxShares = 5000000; // 5,000,000 shares exist

    // initial price per share from Petition.io (until all shares are sold). But can also be listed and sold p2p on our marketplace at the price set by shareholder
    uint initialPricePerShare  = 5000000000000000; // 0.005 ETH -> 
        // notice of bonuses: 
        // 10 ETH + get a 10% bonus
        // 50 ETH + get a 20% bonus 
        // 100 ETH + get a 30% bonus
        // 500 ETH + get a 40% bonus
        // 1000 ETH + get a 50% bonus
    
    uint initialOwnerSharesClaimed = 0; // owner can only claim their 1,000,000 shares once
    address ownerShareAddress;

    uint dividendCooldown = 604800; // 1 week

    uint peerToPeerMarketplaceTransactionFee = 100; // 1% (1 / 100 = 0.01, 2 / 100 = 0.02, etc)

    uint dividendPoolStarts = 0;
    uint dividendPoolEnds = 0;
    uint claimableDividendPool = 0; // (from the last dividendCooldown time pool)
    uint claimedThisPool = 0;
    uint currentDividendPool = 0; // (from this dividendCooldown pool)

    uint availableForWithdraw = 0;

    /********************************* */
    // shareholder functions

    function invest() payable public {
        require(sharesSold < maxShares);
        // calc how many shares
        uint numberOfShares = SafeMath.div(msg.value, initialPricePerShare); // example is 1 ETH (1000000000000000000) / 0.01 ETH (10000000000000000) = 100 shares

        // calc bonus
        uint numberOfSharesBonus;
        uint numberOfSharesBonusOne;
        uint numberOfSharesBonusTwo;
        if (msg.value >= 1000000000000000000000) { // 1000 ETH
            numberOfSharesBonus = SafeMath.div(numberOfShares, 2); // 50%
            numberOfShares = SafeMath.add(numberOfShares, numberOfSharesBonus);

        } else if (msg.value >= 500000000000000000000) { // 500 ETH
            numberOfSharesBonusOne = SafeMath.div(numberOfShares, 5); // 20%
            numberOfSharesBonusTwo = SafeMath.div(numberOfShares, 5); // 20%
            numberOfShares = numberOfShares + numberOfSharesBonusOne + numberOfSharesBonusTwo; // 40%

        } else if (msg.value >= 100000000000000000000) { // 100 ETH
            numberOfSharesBonusOne = SafeMath.div(numberOfShares, 5); // 20%
            numberOfSharesBonusTwo = SafeMath.div(numberOfShares, 10); // 10%
            numberOfShares = numberOfShares + numberOfSharesBonusOne + numberOfSharesBonusTwo; // 30%
        
        } else if (msg.value >= 50000000000000000000) { // 50 ETH
            numberOfSharesBonus = SafeMath.div(numberOfShares, 5); // 20%
            numberOfShares = numberOfShares + numberOfSharesBonus; // 20%

        } else if (msg.value >= 10000000000000000000) { // 10 ETH
            numberOfSharesBonus = SafeMath.div(numberOfShares, 10); // 10%
            numberOfShares = numberOfShares + numberOfSharesBonus; // 10%
        
        }

        require((numberOfShares + sharesSold) < maxShares);

        if (ownerPetitionShareholderArrayCreated[msg.sender] == 0) {
            // new investor
            uint id = PetitionShareholders.push(PetitionShareholder(msg.sender, numberOfShares, 0, now)) - 1;
            emit NewPetitionShareholder(id, msg.sender, numberOfShares, 0, now);
            PetitionShareholderMap[msg.sender] = id;
            ownerPetitionShareholderArrayCreated[msg.sender] = 1;
            
            sharesSold = sharesSold + numberOfShares;

            availableForWithdraw = availableForWithdraw + msg.value;

        } else {
            // add to amount
            PetitionShareholders[PetitionShareholderMap[msg.sender]].shares = PetitionShareholders[PetitionShareholderMap[msg.sender]].shares + numberOfShares;
            
            sharesSold = sharesSold + numberOfShares;

            availableForWithdraw = availableForWithdraw + msg.value;

        }

        // new div pool?
        endDividendPool();

    }

    function viewSharesSold() public view returns(uint) {
        return sharesSold;
    }

    function viewMaxShares() public view returns(uint) {
        return maxShares;
    }

    function viewPetitionShareholderWithAddress(address _investorAddress) view public returns (uint, address, uint, uint) {
        require (ownerPetitionShareholderArrayCreated[_investorAddress] > 0);

        PetitionShareholder storage investors = PetitionShareholders[PetitionShareholderMap[_investorAddress]];
        return (PetitionShareholderMap[_investorAddress], investors.PetitionShareholderAddress, investors.shares, investors.lastDividend);
    }

    function viewPetitionShareholder(uint _PetitionShareholderId) view public returns (uint, address, uint, uint) {
        PetitionShareholder storage investors = PetitionShareholders[_PetitionShareholderId];
        return (_PetitionShareholderId, investors.PetitionShareholderAddress, investors.shares, investors.lastDividend);
    }

    /********************************* */
    // dividend functions

    function endDividendPool() public {
        // we do if instead of require so we can call it throughout the smart contract. This way if someone signs, creates a petition, etc. It can ding to the next dividend pool.
        if (now > dividendPoolEnds) {

            // unclaimed dividends go to admin available
            availableForWithdraw = availableForWithdraw + (claimableDividendPool - claimedThisPool);

            // current div pool to claimable div pool
            claimableDividendPool = currentDividendPool;
            claimedThisPool = 0;

            // reset current div pool
            currentDividendPool = 0;

            // start new pool period
            dividendPoolStarts = now;
            dividendPoolEnds = (now + dividendCooldown);

        }

    }

    function collectDividend() payable public {
        require (ownerPetitionShareholderArrayCreated[msg.sender] > 0);
        require ((PetitionShareholders[PetitionShareholderMap[msg.sender]].lastDividend + dividendCooldown) < now);
        require (claimableDividendPool > 0);

        // calc amount
        uint divAmt = claimableDividendPool / (sharesSold / PetitionShareholders[PetitionShareholderMap[msg.sender]].shares);

        claimedThisPool = claimedThisPool + divAmt;

        //
        PetitionShareholders[PetitionShareholderMap[msg.sender]].lastDividend = now;

        // the actual ETH transfer
        PetitionShareholders[PetitionShareholderMap[msg.sender]].PetitionShareholderAddress.transfer(divAmt);

        uint id = divs.push(DividendHistory(PetitionShareholderMap[msg.sender], divAmt, now, PetitionShareholders[PetitionShareholderMap[msg.sender]].PetitionShareholderAddress)) - 1;
        emit DividendClaim(id, PetitionShareholderMap[msg.sender], divAmt, now, PetitionShareholders[PetitionShareholderMap[msg.sender]].PetitionShareholderAddress);
    }

    function viewInvestorDividendHistory(uint _divId) public view returns(uint, uint, uint, uint, address) {
        return(_divId, divs[_divId].PetitionShareholderId, divs[_divId].amt, divs[_divId].time, divs[_divId].userAddress);
    }

    function viewInvestorDividendPool() public view returns(uint) {
        return currentDividendPool;
    }

    function viewClaimableInvestorDividendPool() public view returns(uint) {
        return claimableDividendPool;
    }

    function viewClaimedThisPool() public view returns(uint) {
        return claimedThisPool;
    }

    function viewLastClaimedDividend(address _address) public view returns(uint) {
        return PetitionShareholders[PetitionShareholderMap[_address]].lastDividend;
    }

    function ViewDividendPoolEnds() public view returns(uint) {
        return dividendPoolEnds;
    }

    function viewDividendCooldown() public view returns(uint) {
        return dividendCooldown;
    }


    // transfer shares
    function transferShares(uint _amount, address _to) public {
        require(ownerPetitionShareholderArrayCreated[msg.sender] > 0);
        require((PetitionShareholders[PetitionShareholderMap[msg.sender]].shares - PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale) >= _amount);

        // give to receiver
        if (ownerPetitionShareholderArrayCreated[_to] == 0) {
            // new investor
            uint id = PetitionShareholders.push(PetitionShareholder(_to, _amount, 0, now)) - 1;
            emit NewPetitionShareholder(id, _to, _amount, 0, now);
            PetitionShareholderMap[_to] = id;
            ownerPetitionShareholderArrayCreated[_to] = 1;

        } else {
            // add to amount
            PetitionShareholders[PetitionShareholderMap[_to]].shares = PetitionShareholders[PetitionShareholderMap[_to]].shares + _amount;

        }

        // take from sender
        PetitionShareholders[PetitionShareholderMap[msg.sender]].shares = PetitionShareholders[PetitionShareholderMap[msg.sender]].shares - _amount;
        PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale = PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale - _amount;

        // new div pool?
        endDividendPool();

    }

    // p2p share listing, selling and buying
    function listSharesForSale(uint _amount, uint _price) public {
        require(ownerPetitionShareholderArrayCreated[msg.sender] > 0);
        require((PetitionShareholders[PetitionShareholderMap[msg.sender]].shares - PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale) >= _amount);
        
        PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale = PetitionShareholders[PetitionShareholderMap[msg.sender]].sharesListedForSale + _amount;

        uint id = listings.push(ShareholderListing(PetitionShareholderMap[msg.sender], _amount, _price, false)) - 1;
        emit NewShareholderListing(id, PetitionShareholderMap[msg.sender], _amount, _price, false);

        // new div pool?
        endDividendPool();
        
    }

    function viewShareholderListing(uint _shareholderListingId)view public returns (uint, uint, uint, uint, bool) {
        ShareholderListing storage listing = listings[_shareholderListingId];
        return (_shareholderListingId, listing.petitionShareholderId, listing.sharesForSale, listing.price, listing.sold);
    }

    function removeShareholderListing(uint _shareholderListingId) public {
        ShareholderListing storage listing = listings[_shareholderListingId];
        require(PetitionShareholderMap[msg.sender] == listing.petitionShareholderId);

        PetitionShareholders[listing.petitionShareholderId].sharesListedForSale = PetitionShareholders[listing.petitionShareholderId].sharesListedForSale - listing.sharesForSale;

        delete listings[_shareholderListingId];

        // new div pool?
        endDividendPool();
        
    }

    function buySharesFromListing(uint _shareholderListingId) payable public {
        ShareholderListing storage listing = listings[_shareholderListingId];
        require(msg.value >= listing.price);
        require(listing.sold == false);
        require(listing.sharesForSale > 0);
        
        // give to buyer
        if (ownerPetitionShareholderArrayCreated[msg.sender] == 0) {
            // new investor
            uint id = PetitionShareholders.push(PetitionShareholder(msg.sender, listing.sharesForSale, 0, now)) - 1;
            emit NewPetitionShareholder(id, msg.sender, listing.sharesForSale, 0, now);
            PetitionShareholderMap[msg.sender] = id;
            ownerPetitionShareholderArrayCreated[msg.sender] = 1;

        } else {
            // add to amount
            PetitionShareholders[PetitionShareholderMap[msg.sender]].shares = PetitionShareholders[PetitionShareholderMap[msg.sender]].shares + listing.sharesForSale;

        }

        listing.sold = true;

        // take from seller
        PetitionShareholders[listing.petitionShareholderId].shares = PetitionShareholders[listing.petitionShareholderId].shares - listing.sharesForSale;
        PetitionShareholders[listing.petitionShareholderId].sharesListedForSale = PetitionShareholders[listing.petitionShareholderId].sharesListedForSale - listing.sharesForSale;

        // 1% fee
        uint calcFee = SafeMath.div(msg.value, peerToPeerMarketplaceTransactionFee);
        cutToInvestorsDividendPool(calcFee);

        // transfer funds to seller
        uint toSeller = SafeMath.sub(msg.value, calcFee);
        PetitionShareholders[listing.petitionShareholderId].PetitionShareholderAddress.transfer(toSeller);

        // new div pool?
        endDividendPool();

    }

    /********************************* */
    // petition functions

    function createPetition(string _name, string _message, uint _signaturesNeeded, bool _featured, string _connectingHash) payable public {
        require(msg.value >= createPetitionFee);
        uint featuredExpires = 0;
        uint totalPaid = createPetitionFee;
        if (_featured) {
            require(msg.value >= (createPetitionFee + featurePetitionFee));
            featuredExpires = now + featuredLength;
            totalPaid = totalPaid + featurePetitionFee;
        }

        /////////////
        // cut to shareholders dividend pool:
        cutToInvestorsDividendPool(totalPaid);

        //////////

        uint id = petitions.push(Petition(_name, _message, msg.sender, _signaturesNeeded, _featured, featuredExpires, 0, now, _connectingHash, 0)) - 1;
        emit NewPetition(id, _name, _message, msg.sender, _signaturesNeeded, _featured, featuredExpires, 0, now, _connectingHash, 0);

    }

    function renewFeatured(uint _petitionId) payable public {
        require(msg.value >= featurePetitionFee);

        uint featuredExpires = 0;
        if (now > petitions[_petitionId].featuredExpires) {
            featuredExpires = now + featuredLength;
        }else {
            featuredExpires = petitions[_petitionId].featuredExpires + featuredLength;
        }

        petitions[_petitionId].featuredExpires = featuredExpires;

        /////////////
        // cut to shareholders dividend pool:
        cutToInvestorsDividendPool(msg.value);

    }

    function viewPetition(uint _petitionId) view public returns (uint, string, string, address, uint, bool, uint, uint, uint, string, uint) {
        Petition storage petition = petitions[_petitionId];
        return (_petitionId, petition.name, petition.message, petition.creator, petition.signaturesNeeded, petition.featured, petition.featuredExpires, petition.totalSignatures, petition.created, petition.connectingHash, petition.advertisingBudget);
    }

    function viewPetitionSignerWithAddress(address _ownerAddress, uint _petitionId) view public returns (uint, uint, address, uint) {
        require (ownerPetitionSignerArrayCreated[_ownerAddress][_petitionId] > 0);

        PetitionSigner storage signers = petitionsigners[petitionSignerMap[_ownerAddress][_petitionId]];
        return (petitionSignerMap[_ownerAddress][_petitionId], signers.petitionId, signers.petitionSignerAddress, signers.signed);
    }

    function viewPetitionSigner(uint _petitionSignerId) view public returns (uint, uint, address, uint) {
        PetitionSigner storage signers = petitionsigners[_petitionSignerId];
        return (_petitionSignerId, signers.petitionId, signers.petitionSignerAddress, signers.signed);
    }

    function advertisingDeposit (uint _petitionId) payable public {
        petitions[_petitionId].advertisingBudget = SafeMath.add(petitions[_petitionId].advertisingBudget, msg.value);

        /////////////
        // cut to shareholders dividend pool -> since its advertising we can cut 100% of the msg.value to everyone
        cutToInvestorsDividendPool(msg.value);

    }

    function cutToInvestorsDividendPool(uint totalPaid) internal {
        //
        // removed this because as petition.io we still have to claim owned shares % worth from the dividendpool.

        // calc cut for Petition.io
        //uint firstDiv = SafeMath.div(PetitionShareholders[PetitionShareholderMap[ownerShareAddress]].shares, sharesSold);
        //uint petitionIoDivAmt = SafeMath.mul(totalPaid, firstDiv);
        //availableForWithdraw = availableForWithdraw + petitionIoDivAmt;
        // calc for shareholders
        //uint divAmt = SafeMath.sub(totalPaid, petitionIoDivAmt);
        // add to investors dividend pool
        //currentDividendPool = SafeMath.add(currentDividendPool, divAmt);

        currentDividendPool = SafeMath.add(currentDividendPool, totalPaid);

        // new div pool?
        endDividendPool();

    }

    function advertisingUse (uint _petitionId, uint amount) public {
        require(petitions[_petitionId].creator == msg.sender);
        require(petitions[_petitionId].advertisingBudget >= amount);
        // (fills out advertising information on website and funds it here)
        petitions[_petitionId].advertisingBudget = petitions[_petitionId].advertisingBudget - amount;

    }

    /********************************* */
    // sign function

    function sign (uint _petitionId) public {
        // cant send it to a non existing petition
        require (keccak256(petitions[_petitionId].name) != keccak256(""));
        require (ownerPetitionSignerArrayCreated[msg.sender][_petitionId] == 0);

        //if (ownerPetitionSignerArrayCreated[msg.sender][_petitionId] == 0) {
            
        uint id = petitionsigners.push(PetitionSigner(_petitionId, msg.sender, now)) - 1;
        emit NewPetitionSigner(id, _petitionId, msg.sender, now);
        petitionSignerMap[msg.sender][_petitionId] = id;
        ownerPetitionSignerArrayCreated[msg.sender][_petitionId] = 1;
        
        petitions[_petitionId].totalSignatures = petitions[_petitionId].totalSignatures + 1;

        //}

        // new div pool?
        endDividendPool();

    }

    /********************************* */
    // unsign function

    function unsign (uint _petitionId) public {
        require (ownerPetitionSignerArrayCreated[msg.sender][_petitionId] == 1);

        ownerPetitionSignerArrayCreated[msg.sender][_petitionId] = 0;

        petitions[_petitionId].totalSignatures = petitions[_petitionId].totalSignatures - 1;

        delete petitionsigners[petitionSignerMap[msg.sender][_petitionId]];

        delete petitionSignerMap[msg.sender][_petitionId];

    }

    /********************************* */
    // start admin functions

    function initialOwnersShares() public onlyOwner(){
        require(initialOwnerSharesClaimed == 0);

        uint numberOfShares = 1000000;

        uint id = PetitionShareholders.push(PetitionShareholder(msg.sender, numberOfShares, 0, now)) - 1;
        emit NewPetitionShareholder(id, msg.sender, numberOfShares, 0, now);
        PetitionShareholderMap[msg.sender] = id;
        ownerPetitionShareholderArrayCreated[msg.sender] = 1;
        
        sharesSold = sharesSold + numberOfShares;

        ownerShareAddress = msg.sender;

        // dividend pool
        dividendPoolStarts = now;
        dividendPoolEnds = (now + dividendCooldown);

        initialOwnerSharesClaimed = 1; // owner can only claim the intial 1,000,000 shares once
    }

    function companyShares() public view returns(uint){
        return PetitionShareholders[PetitionShareholderMap[ownerShareAddress]].shares;
    }
    
    function alterDividendCooldown (uint _dividendCooldown) public onlyOwner() {
        dividendCooldown = _dividendCooldown;
    }

    function spendAdvertising(uint _petitionId, uint amount) public onlyOwner() {
        require(petitions[_petitionId].advertisingBudget >= amount);

        petitions[_petitionId].advertisingBudget = petitions[_petitionId].advertisingBudget - amount;
    }

    function viewFeaturedLength() public view returns(uint) {
        return featuredLength;
    }

    function alterFeaturedLength (uint _newFeaturedLength) public onlyOwner() {
        featuredLength = _newFeaturedLength;
    }

    function viewInitialPricePerShare() public view returns(uint) {
        return initialPricePerShare;
    }

    function alterInitialPricePerShare (uint _initialPricePerShare) public onlyOwner() {
        initialPricePerShare = _initialPricePerShare;
    }

    function viewCreatePetitionFee() public view returns(uint) {
        return createPetitionFee;
    }

    function alterCreatePetitionFee (uint _createPetitionFee) public onlyOwner() {
        createPetitionFee = _createPetitionFee;
    }

    function alterPeerToPeerMarketplaceTransactionFee (uint _peerToPeerMarketplaceTransactionFee) public onlyOwner() {
        peerToPeerMarketplaceTransactionFee = _peerToPeerMarketplaceTransactionFee;
    }

    function viewPeerToPeerMarketplaceTransactionFee() public view returns(uint) {
        return peerToPeerMarketplaceTransactionFee;
    }

    function viewFeaturePetitionFee() public view returns(uint) {
        return featurePetitionFee;
    }

    function alterFeaturePetitionFee (uint _featurePetitionFee) public onlyOwner() {
        featurePetitionFee = _featurePetitionFee;
    }

    function withdrawFromAmt() public view returns(uint) {
        return availableForWithdraw;
    }

    function withdrawFromContract(address _to, uint _amount) payable external onlyOwner() {
        require(_amount <= availableForWithdraw);
        availableForWithdraw = availableForWithdraw - _amount;
        _to.transfer(_amount);

        // new div pool?
        endDividendPool();

    }

    /*
    NOTE: Instead of adding this function to the smart contract and have the power of deleting a petition (having this power doesnt sound very decentralized), in case of anything inappropriate: Petition.io will instead flag the said petition from showing up on the website. Sure someone can make their own website and link to our smart contract and show all the dirty stuff people will inevitably post.. go for it.
    function deletePetition(uint _petitionId) public onlyOwner() {
        delete petitions[_petitionId];
    }*/

}