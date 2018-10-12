pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/Beneficiary.sol

// solhint-disable-next-line
pragma solidity ^0.4.24;



/** @title Beneficiary */
contract Beneficiary is Ownable {
    address public beneficiary;

    constructor() public {
        beneficiary = msg.sender;
    }

    /**
     * @dev Change the beneficiary address
     * @param _beneficiary Address of the new beneficiary
     */
    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }
}

// File: contracts/Affiliate.sol

// solhint-disable-next-line
pragma solidity ^0.4.25;



/** @title Affiliate */
contract Affiliate is Ownable {
    mapping(address => bool) public canSetAffiliate;
    mapping(address => address) public userToAffiliate;

    /** @dev Allows an address to set the affiliate address for a user
      * @param _setter The address that should be allowed
      */
    function setAffiliateSetter(address _setter) public onlyOwner {
        canSetAffiliate[_setter] = true;
    }

    /**
     * @dev Set the affiliate of a user
     * @param _user user to set affiliate for
     * @param _affiliate address to set
     */
    function setAffiliate(address _user, address _affiliate) public {
        require(canSetAffiliate[msg.sender]);
        if (userToAffiliate[_user] == address(0)) {
            userToAffiliate[_user] = _affiliate;
        }
    }

}

// File: contracts/interfaces/ERC721.sol

contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public returns (bool) ;
    function transfer(address _to, uint256 _tokenId) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

// File: contracts/interfaces/PepeInterface.sol

contract PepeInterface is ERC721{
    function cozyTime(uint256 _mother, uint256 _father, address _pepeReceiver) public returns (bool);
    function getCozyAgain(uint256 _pepeId) public view returns(uint64);
}

// File: contracts/AuctionBase.sol

// solhint-disable-next-line
pragma solidity ^0.4.24;





/** @title AuctionBase */
contract AuctionBase is Beneficiary {
    mapping(uint256 => PepeAuction) public auctions;//maps pepes to auctions
    PepeInterface public pepeContract;
    Affiliate public affiliateContract;
    uint256 public fee = 37500; //in 1 10000th of a percent so 3.75% at the start
    uint256 public constant FEE_DIVIDER = 1000000; //Perhaps needs better name?

    struct PepeAuction {
        address seller;
        uint256 pepeId;
        uint64 auctionBegin;
        uint64 auctionEnd;
        uint256 beginPrice;
        uint256 endPrice;
    }

    event AuctionWon(uint256 indexed pepe, address indexed winner, address indexed seller);
    event AuctionStarted(uint256 indexed pepe, address indexed seller);
    event AuctionFinalized(uint256 indexed pepe, address indexed seller);

    constructor(address _pepeContract, address _affiliateContract) public {
        pepeContract = PepeInterface(_pepeContract);
        affiliateContract = Affiliate(_affiliateContract);
    }

    /**
     * @dev Return a pepe from a auction that has passed
     * @param  _pepeId the id of the pepe to save
     */
    function savePepe(uint256 _pepeId) external {
        // solhint-disable-next-line not-rely-on-time
        require(auctions[_pepeId].auctionEnd < now);//auction must have ended
        require(pepeContract.transfer(auctions[_pepeId].seller, _pepeId));//transfer pepe back to seller

        emit AuctionFinalized(_pepeId, auctions[_pepeId].seller);

        delete auctions[_pepeId];//delete auction
    }

    /**
     * @dev change the fee on pepe sales. Can only be lowerred
     * @param _fee The new fee to set. Must be lower than current fee
     */
    function changeFee(uint256 _fee) external onlyOwner {
        require(_fee < fee);//fee can not be raised
        fee = _fee;
    }

    /**
     * @dev Start a auction
     * @param  _pepeId Pepe to sell
     * @param  _beginPrice Price at which the auction starts
     * @param  _endPrice Ending price of the auction
     * @param  _duration How long the auction should take
     */
    function startAuction(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration) public {
        require(pepeContract.transferFrom(msg.sender, address(this), _pepeId));
        // solhint-disable-next-line not-rely-on-time
        require(now > auctions[_pepeId].auctionEnd);//can only start new auction if no other is active

        PepeAuction memory auction;

        auction.seller = msg.sender;
        auction.pepeId = _pepeId;
        // solhint-disable-next-line not-rely-on-time
        auction.auctionBegin = uint64(now);
        // solhint-disable-next-line not-rely-on-time
        auction.auctionEnd = uint64(now) + _duration;
        require(auction.auctionEnd > auction.auctionBegin);
        auction.beginPrice = _beginPrice;
        auction.endPrice = _endPrice;

        auctions[_pepeId] = auction;

        emit AuctionStarted(_pepeId, msg.sender);
    }

    /**
     * @dev directly start a auction from the PepeBase contract
     * @param  _pepeId Pepe to put on auction
     * @param  _beginPrice Price at which the auction starts
     * @param  _endPrice Ending price of the auction
     * @param  _duration How long the auction should take
     * @param  _seller The address selling the pepe
     */
    // solhint-disable-next-line max-line-length
    function startAuctionDirect(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration, address _seller) public {
        require(msg.sender == address(pepeContract)); //can only be called by pepeContract
        //solhint-disable-next-line not-rely-on-time
        require(now > auctions[_pepeId].auctionEnd);//can only start new auction if no other is active

        PepeAuction memory auction;

        auction.seller = _seller;
        auction.pepeId = _pepeId;
        // solhint-disable-next-line not-rely-on-time
        auction.auctionBegin = uint64(now);
        // solhint-disable-next-line not-rely-on-time
        auction.auctionEnd = uint64(now) + _duration;
        require(auction.auctionEnd > auction.auctionBegin);
        auction.beginPrice = _beginPrice;
        auction.endPrice = _endPrice;

        auctions[_pepeId] = auction;

        emit AuctionStarted(_pepeId, _seller);
    }

  /**
   * @dev Calculate the current price of a auction
   * @param  _pepeId the pepeID to calculate the current price for
   * @return currentBid the current price for the auction
   */
    function calculateBid(uint256 _pepeId) public view returns(uint256 currentBid) {
        PepeAuction storage auction = auctions[_pepeId];
        // solhint-disable-next-line not-rely-on-time
        uint256 timePassed = now - auctions[_pepeId].auctionBegin;

        // If auction ended return auction end price.
        // solhint-disable-next-line not-rely-on-time
        if (now >= auction.auctionEnd) {
            return auction.endPrice;
        } else {
            // Can be negative
            int256 priceDifference = int256(auction.endPrice) - int256(auction.beginPrice);
            // Always positive
            int256 duration = int256(auction.auctionEnd) - int256(auction.auctionBegin);

            // As already proven in practice by CryptoKitties:
            //  timePassed -> 64 bits at most
            //  priceDifference -> 128 bits at most
            //  timePassed * priceDifference -> 64 + 128 bits at most
            int256 priceChange = priceDifference * int256(timePassed) / duration;

            // Will be positive, both operands are less than 256 bits
            int256 price = int256(auction.beginPrice) + priceChange;

            return uint256(price);
        }
    }

  /**
   * @dev collect the fees from the auction
   */
    function getFees() public {
        beneficiary.transfer(address(this).balance);
    }


}

// File: contracts/CozyTimeAuction.sol

// solhint-disable-next-line
pragma solidity ^0.4.24;



/** @title CozyTimeAuction */
contract CozyTimeAuction is AuctionBase {
    // solhint-disable-next-line
    constructor (address _pepeContract, address _affiliateContract) AuctionBase(_pepeContract, _affiliateContract) public {

    }

    /**
     * @dev Start an auction
     * @param  _pepeId The id of the pepe to start the auction for
     * @param  _beginPrice Start price of the auction
     * @param  _endPrice End price of the auction
     * @param  _duration How long the auction should take
     */
    function startAuction(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration) public {
        // solhint-disable-next-line not-rely-on-time
        require(pepeContract.getCozyAgain(_pepeId) <= now);//need to have this extra check
        super.startAuction(_pepeId, _beginPrice, _endPrice, _duration);
    }

    /**
     * @dev Start a auction direclty from the PepeBase smartcontract
     * @param  _pepeId The id of the pepe to start the auction for
     * @param  _beginPrice Start price of the auction
     * @param  _endPrice End price of the auction
     * @param  _duration How long the auction should take
     * @param  _seller The address of the seller
     */
    // solhint-disable-next-line max-line-length
    function startAuctionDirect(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration, address _seller) public {
        // solhint-disable-next-line not-rely-on-time
        require(pepeContract.getCozyAgain(_pepeId) <= now);//need to have this extra check
        super.startAuctionDirect(_pepeId, _beginPrice, _endPrice, _duration, _seller);
    }

    /**
     * @dev Buy cozy right from the auction
     * @param  _pepeId Pepe to cozy with
     * @param  _cozyCandidate the pepe to cozy with
     * @param  _candidateAsFather Is the _cozyCandidate father?
     * @param  _pepeReceiver address receiving the pepe after cozy time
     */
    // solhint-disable-next-line max-line-length
    function buyCozy(uint256 _pepeId, uint256 _cozyCandidate, bool _candidateAsFather, address _pepeReceiver) public payable {
        require(address(pepeContract) == msg.sender); //caller needs to be the PepeBase contract

        PepeAuction storage auction = auctions[_pepeId];
        // solhint-disable-next-line not-rely-on-time
        require(now < auction.auctionEnd);// auction must be still going

        uint256 price = calculateBid(_pepeId);
        require(msg.value >= price);//must send enough ether
        uint256 totalFee = price * fee / FEE_DIVIDER; //safe math needed?

        //Send ETH to seller
        auction.seller.transfer(price - totalFee);
        //send ETH to beneficiary

        address affiliate = affiliateContract.userToAffiliate(_pepeReceiver);

        //solhint-disable-next-line
        if (affiliate != address(0) && affiliate.send(totalFee / 2)) { //if user has affiliate
            //nothing just to suppress warning
        }

        //actual cozytiming
        if (_candidateAsFather) {
            if (!pepeContract.cozyTime(auction.pepeId, _cozyCandidate, _pepeReceiver)) {
                revert();
            }
        } else {
          // Swap around the two pepes, they have no set gender, the user decides what they are.
            if (!pepeContract.cozyTime(_cozyCandidate, auction.pepeId, _pepeReceiver)) {
                revert();
            }
        }

        //Send pepe to seller of auction
        if (!pepeContract.transfer(auction.seller, _pepeId)) {
            revert(); //can&#39;t complete transfer if this fails
        }

        if (msg.value > price) { //return ether send to much
            _pepeReceiver.transfer(msg.value - price);
        }

        emit AuctionWon(_pepeId, _pepeReceiver, auction.seller);//emit event

        delete auctions[_pepeId];//deletes auction
    }

    /**
     * @dev Buy cozytime and pass along affiliate
     * @param  _pepeId Pepe to cozy with
     * @param  _cozyCandidate the pepe to cozy with
     * @param  _candidateAsFather Is the _cozyCandidate father?
     * @param  _pepeReceiver address receiving the pepe after cozy time
     * @param  _affiliate Affiliate address to set
     */
    //solhint-disable-next-line max-line-length
    function buyCozyAffiliated(uint256 _pepeId, uint256 _cozyCandidate, bool _candidateAsFather, address _pepeReceiver, address _affiliate) public payable {
        affiliateContract.setAffiliate(_pepeReceiver, _affiliate);
        buyCozy(_pepeId, _cozyCandidate, _candidateAsFather, _pepeReceiver);
    }
}