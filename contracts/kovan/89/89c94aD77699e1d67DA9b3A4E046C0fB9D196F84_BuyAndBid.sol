// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./Wanters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract BuyAndBid is Wanters {
    using SafeMath for uint256;

    // =========================================================================================
    // Events
    // =========================================================================================

    event NewBuyingBid(
        bytes32 _rentalId,
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _priceProposed,
        uint256 _deadLineToAccept
    );

    event BuyingBidCanceled(
        bytes32 _rentalId,
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _priceProposed
    );

    event NFTSold(
        bytes32 _rentalId,
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _price
    );

    // =========================================================================================
    // buyers and biders actions
    // =========================================================================================

    mapping(bytes32 => uint256) public bidingBlock;

    // buyNft is direct buy function
    // User have to send salePrice[_rentalId]
    function buyNft(bytes32 _rentalId) public payable notThief {
        require(isOnSale[_rentalId], "This NFT is not on sailing Platform");
        require(
            msg.value > 0 && msg.value >= salePrice[_rentalId],
            "You didn't pay the good value"
        );

        emit NFTSold(
            _rentalId,
            rentalInstance[_rentalId].nftAddress,
            rentalInstance[_rentalId].tokenId,
            msg.value
        );

        //If NFT doesn't got renter
        //Proceed to instant transfer
        if (rentalInstance[_rentalId].renter == address(0x0)) {
            //Transfer token to buyer
            _nftWithdraw(
                rentalInstance[_rentalId].tokenId,
                rentalInstance[_rentalId].nftAddress,
                msg.sender
            );

            //Transfer ETH to owner
            rentalInstance[_rentalId].owner.transfer(
                _getValueSubFees(msg.value)
            );

            // delete RentalInstance
            _deleteInstance(_rentalId);
        } else {
            require(
                renterRespectedRules(_rentalId),
                "There's a renter who didn't respect rules, buying is not possible"
            );
            // Else token is considered sold
            // and will be transfered when renter stop his renting process
            buyer[_rentalId] = msg.sender;

            // during waiting process, buyer will farm NFTR
            Farming(farmingAddress).COLLATERAL_POOL_stake(
                msg.sender,
                msg.value
            );
        }
    }

    // Each token on a renting instance can receive buying bid
    // User have to send eth value of his offer
    // Offer is locked 20 000 Blocks (3 days) bider can't cancel his offer during this locked time
    function bidForBuyingNft(bytes32 _rentalId) public payable notThief {
        require(
            msg.value > bidValue[_rentalId],
            "There is a pending bid higher than yours"
        );
        require(
            buyer[_rentalId] == address(0x0) && !bidAccepted[_rentalId],
            "There is a pending transfer for this NFT"
        );

        if (rentalInstance[_rentalId].renter != address(0x0)) {
            require(
                renterRespectedRules(_rentalId),
                "There's a renter who didn't respect rules, buying is not possible"
            );
        }

        //Return back the old bid to bidner
        if (bidValue[_rentalId] > 0) {
            uint256 _toReturn = bidValue[_rentalId];
            bidValue[_rentalId] = 0;
            bider[_rentalId].transfer(_toReturn);

            Farming(farmingAddress).COLLATERAL_POOL_unstake(
                bider[_rentalId],
                _toReturn
            );
        }

        // Store new bid Values
        bidingBlock[_rentalId] = block.number;
        bidValue[_rentalId] = msg.value;
        bider[_rentalId] = msg.sender;

        // farming:
        Farming(farmingAddress).COLLATERAL_POOL_stake(msg.sender, msg.value);

        emit NewBuyingBid(
            _rentalId,
            rentalInstance[_rentalId].nftAddress,
            rentalInstance[_rentalId].tokenId,
            msg.value,
            block.number.add(20000)
        );
    }

    function cancelMyBuyingBid(bytes32 _rentalId) public notThief {
        require(bider[_rentalId] == msg.sender, "This is not your bid");
        require(
            block.number.add(20000) >= bidingBlock[_rentalId],
            "Bids are locked for 20 000 Blocks, please wait for cancel your bid"
        );
        require(
            bidAccepted[_rentalId] == false,
            "Bid has been accepted, you can't canceled it"
        );

        emit BuyingBidCanceled(
            _rentalId,
            rentalInstance[_rentalId].nftAddress,
            rentalInstance[_rentalId].tokenId,
            bidValue[_rentalId]
        );

        //return value
        uint256 _valueToReturn = bidValue[_rentalId];
        bidValue[_rentalId] = 0;
        bider[_rentalId].transfer(_valueToReturn);

        // stop farming
        Farming(farmingAddress).COLLATERAL_POOL_unstake(
            bider[_rentalId],
            _valueToReturn
        );

        // Delete bid Values
        bidingBlock[_rentalId] = 0;
        bidValue[_rentalId] = 0;
        bider[_rentalId] = address(0x0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Stacking {
    function receiveFees() external payable;

    function bannishUser(address _user) external;
}

interface Farming {
    function NFT_POOL_stake(address _user) external;

    function NFT_POOL_unstake(address _user) external;

    function COLLATERAL_POOL_stake(address _user, uint256 amount) external;

    function COLLATERAL_POOL_unstake(address _user, uint256 amount) external;

    function bannishUser(address _user) external;
}

contract Rental is ERC721Holder, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 public DEV_FEES = 75; // means 0,75%
    uint256 public TEAM_FEES = 75; // means 0,75%
    uint256 public PUBLIC_FEES = 100; // means 1,00%
    address payable public DEV_FUND;
    address payable public TEAM_FUND;
    address public PUBLIC_STACKING_FUND;
    address public farmingAddress;

    // used for check if stacking got LPs stacked
    // If stacking balance of LP = 0, we don't send fees to stacking contract
    address public lpToken;

    constructor() {
        DEV_FUND = msg.sender;
        TEAM_FUND = msg.sender;
    }

    address[] _NftAcceptedForFarming;

    // Define a rental instance
    // active define if instance exist
    // if renter !== address(0x0) => the token is on rental process
    struct RentalInstance {
        address payable owner;
        address payable renter;
        address nftAddress;
        uint256 ethValueCollateral;
        uint256 tokenId;
        uint256 amountPricePerDay;
        uint256 endOfRent;
        uint8 minRentPeriod;
        uint8 maxRentPeriod;
        bool farmNFTR;
        bool extendAccepted;
    }

    // Store all rental instances by creating a bytes32 ID
    mapping(bytes32 => RentalInstance) public rentalInstance;
    bytes32[] _rentalInstances;

    // Value a renter got in Collateral for a rentalInstance
    // Used for security re entry
    // each address is supposed to have nativly 0 ETH in collateral in each Instances
    mapping(address => mapping(bytes32 => uint256)) _collatInThisInstance;

    // An address who stolen a NFT
    mapping(address => bool) public asStolenANft;

    // Each NFT can be sold if owner decide it
    // When create a rental instance, owner can add "on sale" option with fixed price
    mapping(bytes32 => bool) public isOnSale;
    mapping(bytes32 => uint256) public salePrice;
    mapping(bytes32 => address payable) public buyer;

    // Each rental instances can receive bid by a buyer
    // If accepted by the NFT's owner, token is directly sent to bider
    mapping(bytes32 => uint256) public bidValue;
    mapping(bytes32 => address payable) public bider;
    mapping(bytes32 => bool) public bidAccepted;

    modifier notThief() {
        require(!asStolenANft[msg.sender]);
        _;
    }

    // =========================================================================================
    // Events
    // =========================================================================================

    event NewRentalInstance(
        bytes32 _rentalId,
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _pricePerDay,
        uint256 _ethCollateralAsked
    );

    event RentalInstanceCanceled(
        bytes32 _rentalId,
        address _nftContractAddress,
        uint256 _nftId
    );

    event NFTRented(
        bytes32 _rentalId,
        address _nftContractAddress,
        uint256 _nftId,
        address _renter
    );

    event RentalFinished(
        bytes32 _rentalId,
        address _nftContractAddress,
        uint256 _nftId
    );

    event NFTStolen(
        bytes32 _rentalId,
        address _nftContractAddress,
        uint256 _nftId,
        address _stoler
    );

    // =========================================================================================
    // View of Instances
    // =========================================================================================

    // Get number of rental instances opened
    function getRentalInstancesNumber() public view returns (uint256) {
        return _rentalInstances.length;
    }

    // Get the Id of the instance by the index of the stored array
    // the order of the array will moove each time an instance is closed
    // That's why we don't use index of array for get the instance
    function getRentalInstanceIdbyIndex(uint256 _index)
        public
        view
        returns (bytes32)
    {
        return _rentalInstances[_index];
    }

    // Function let know user if address of NFT can get Farming rewards
    function nftCanGetFarmingReward(address _nft) public view returns (bool) {
        bool _result = false;

        for (uint256 i = 0; i < _NftAcceptedForFarming.length; i++) {
            if (_NftAcceptedForFarming[i] == _nft) {
                _result = true;
                break;
            }
        }
        return _result;
    }

    // =========================================================================================
    // Owner functions
    // =========================================================================================

    function changeDevFees(uint256 _devFees) public onlyOwner() {
        DEV_FEES = _devFees;
    }

    function changeTeamFees(uint256 _teamFees) public onlyOwner() {
        TEAM_FEES = _teamFees;
    }

    function changePublicFees(uint256 _publicFees) public onlyOwner() {
        PUBLIC_FEES = _publicFees;
    }

    function setDevWallet(address payable _wallet) public onlyOwner() {
        DEV_FUND = _wallet;
    }

    function setTeamWallet(address payable _wallet) public onlyOwner() {
        TEAM_FUND = _wallet;
    }

    function setPublicStackingFund(address _stackingContract)
        public
        onlyOwner()
    {
        PUBLIC_STACKING_FUND = _stackingContract;
    }

    function setFarming(address _farmingAddress) public onlyOwner() {
        farmingAddress = _farmingAddress;
    }

    function addNftCanGetFarmingReward(address _nft) public onlyOwner() {
        _NftAcceptedForFarming.push(_nft);
    }

    function setLpToken(address _lp) public onlyOwner() {
        lpToken = _lp;
    }

    // =========================================================================================
    // Internals functions
    // =========================================================================================

    function _nftDeposit(
        uint256 _tokenId,
        address _token,
        address _from
    ) internal {
        IERC721(_token).transferFrom(_from, address(this), _tokenId);
    }

    function _nftWithdraw(
        uint256 _tokenId,
        address _token,
        address _to
    ) internal {
        IERC721(_token).transferFrom(address(this), _to, _tokenId);
    }

    function _nftTransferFrom(
        uint256 _tokenId,
        address _token,
        address _from,
        address _to
    ) internal {
        IERC721(_token).transferFrom(_from, _to, _tokenId);
    }

    function _deleteInstance(bytes32 _rentalId) internal {
        //erase onsale data
        if (isOnSale[_rentalId]) {
            isOnSale[_rentalId] = false;
            salePrice[_rentalId] = 0;
        }

        // if buyer was waiting for his token
        // (token was in renting process when he bought it)
        // Stop farming
        if (buyer[_rentalId] != address(0x0)) {
            Farming(farmingAddress).COLLATERAL_POOL_unstake(
                buyer[_rentalId],
                salePrice[_rentalId]
            );
            buyer[_rentalId] = address(0x0);
            salePrice[_rentalId] = 0;
            isOnSale[_rentalId] = false;
        }

        //erase bid data
        if (bidValue[_rentalId] > 0) {
            // First secure re entry
            uint256 _bidValue = bidValue[_rentalId];
            bidValue[_rentalId] = 0;

            // stop farming
            Farming(farmingAddress).COLLATERAL_POOL_unstake(
                bider[_rentalId],
                _bidValue
            );

            if (bidAccepted[_rentalId] == false) {
                // if bider had sent value, return the value
                bider[_rentalId].transfer(_bidValue);
            }
            bider[_rentalId] = address(0x0);
            bidAccepted[_rentalId] = false;
        }

        emit RentalInstanceCanceled(
            _rentalId,
            rentalInstance[_rentalId].nftAddress,
            rentalInstance[_rentalId].tokenId
        );

        //erase rental instance
        _removeIdFromMyInstances(_rentalId, rentalInstance[_rentalId].owner);
        _removeIdFromAllInstances(_rentalId);

        if (rentalInstance[_rentalId].farmNFTR == true) {
            Farming(farmingAddress).NFT_POOL_unstake(
                rentalInstance[_rentalId].owner
            );
        }

        delete rentalInstance[_rentalId];
    }

    function _getValueSubFees(uint256 _value) internal returns (uint256) {
        uint256 _devFees = (_value.mul(DEV_FEES)).div(10000);
        uint256 _teamFees = (_value.mul(TEAM_FEES)).div(10000);
        uint256 _publicFees = (_value.mul(PUBLIC_FEES)).div(10000);
        DEV_FUND.transfer(_devFees);
        TEAM_FUND.transfer(_teamFees);

        // Before send fees for stackers
        // Check if there are some stackers by checking lp balance of stacking contract
        if (IERC20(lpToken).balanceOf(PUBLIC_STACKING_FUND) > 0) {
            Stacking(PUBLIC_STACKING_FUND).receiveFees{value: _publicFees}();
        } else {
            // If lp balance is 0, fees go to dev fund
            DEV_FUND.transfer(_publicFees);
        }

        return (_value.sub(_devFees).sub(_publicFees).sub(_teamFees));
    }

    function _applyLateFeesAndReturnCollateral(
        bytes32 _rentalId,
        address payable _to
    ) internal {
        uint256 _lateFees = getLateFeesValue(_rentalId);
        uint256 _collateral = _collatInThisInstance[_to][_rentalId];
        _collatInThisInstance[_to][_rentalId] = 0;
        //Send Late fees to owner
        _to.transfer(_getValueSubFees(_lateFees));

        //Return back collateral to renter minus Late Fees
        rentalInstance[_rentalId].renter.transfer(_collateral.sub(_lateFees));

        //Stop Farming token from collateral
        Farming(farmingAddress).COLLATERAL_POOL_unstake(
            rentalInstance[_rentalId].renter,
            _collateral
        );
    }

    function _returnCollateralToRenter(bytes32 _rentalId) internal {
        // re entry secure
        uint256 _valueToReturn = rentalInstance[_rentalId].ethValueCollateral;
        rentalInstance[_rentalId].ethValueCollateral = 0;
        _collatInThisInstance[rentalInstance[_rentalId].renter][_rentalId] = 0;
        rentalInstance[_rentalId].renter.transfer(_valueToReturn);

        //Stop Farming token from collateral
        Farming(farmingAddress).COLLATERAL_POOL_unstake(
            rentalInstance[_rentalId].renter,
            _valueToReturn
        );
    }

    // =========================================================================================
    // Owners of NFT actions
    // =========================================================================================

    // Store rental instances of the user
    mapping(address => bytes32[]) _myRentalInstances;

    // Get number of rental instance user got
    function myNumberOfRentalInstances(address _user)
        public
        view
        returns (uint256)
    {
        return _myRentalInstances[_user].length;
    }

    // Get id of rental instance user by index in array
    function myRentalInstanceId(address _user, uint256 _index)
        public
        view
        returns (bytes32)
    {
        return (_myRentalInstances[_user][_index]);
    }

    // Frontend need to get from user the NFT address contract, the token Id , the token he wants
    // renter use for collateral and the amount of this token he wants for a renting day (need to be : X * 1E18)
    function openRentalInstance(
        address _nftAddress,
        uint256 _ethValueCollateral, // The value is in ETH and must be an 1E18 number => 1ETH = 1*1E18
        uint256 _tokenId,
        uint256 _amountPricePerDay,
        bool _extendAccepted,
        bool _isOnSale,
        uint256 _fixedPrice,
        uint8 _minRentPeriod,
        uint8 _maxRentPeriod
    ) public notThief {
        //Check if msg.sender is owner of NFT
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender,
            "This is not your NFT"
        );
        //Need to approve the platform in web3 frontend before call this function
        require(IERC721(_nftAddress).getApproved(_tokenId) == address(this));

        //Build an Id with NFT address and Token Id
        bytes32 _rentalId = keccak256(abi.encodePacked(_nftAddress, _tokenId));
        // Check if instance already exist
        require(
            rentalInstance[_rentalId].nftAddress == address(0x0),
            "An instance for this token already exist"
        );

        //Transfer the token
        _nftDeposit(_tokenId, _nftAddress, msg.sender);

        // If is on sale
        if (_isOnSale && _fixedPrice > 0) {
            isOnSale[_rentalId] = true;
            salePrice[_rentalId] = _fixedPrice;
        }

        // Store the ID
        _rentalInstances.push(_rentalId);
        _myRentalInstances[msg.sender].push(_rentalId);

        //Create instance
        rentalInstance[_rentalId] = RentalInstance(
            msg.sender,
            address(0x0),
            _nftAddress,
            _ethValueCollateral,
            _tokenId,
            _amountPricePerDay,
            0,
            _minRentPeriod,
            _maxRentPeriod,
            false,
            _extendAccepted
        );

        emit NewRentalInstance(
            _rentalId,
            _nftAddress,
            _tokenId,
            _amountPricePerDay,
            _ethValueCollateral
        );

        //if NFT can claim farming
        if (nftCanGetFarmingReward(_nftAddress)) {
            rentalInstance[_rentalId].farmNFTR = true;
            Farming(farmingAddress).NFT_POOL_stake(msg.sender);
        }
    }

    // function for owner who want to change extend rental auth
    function changeExtendAccepted(bytes32 _rentalId) public notThief {
        require(
            rentalInstance[_rentalId].owner == msg.sender,
            "You are not the owner of this instance"
        );

        rentalInstance[_rentalId].extendAccepted = !rentalInstance[_rentalId]
            .extendAccepted;
    }

    function cancelRentalInstance(bytes32 _rentalId) public notThief {
        require(
            rentalInstance[_rentalId].owner == msg.sender,
            "You are not the owner of this instance"
        );
        require(
            rentalInstance[_rentalId].renter == address(0x0),
            "There is a renter"
        );

        //Return back the NFT to the owner
        _nftWithdraw(
            rentalInstance[_rentalId].tokenId,
            rentalInstance[_rentalId].nftAddress,
            msg.sender
        );

        _deleteInstance(_rentalId);
    }

    // If owner accept offer for his
    function acceptSaleBid(bytes32 _rentalId) public notThief {
        require(
            rentalInstance[_rentalId].owner == msg.sender,
            "You are not the owner of this instance"
        );

        require(
            bidAccepted[_rentalId] == false,
            "This bid have already been accepted"
        );

        bidAccepted[_rentalId] = true;

        //If NFT doesn't got renter
        //Proceed to instant transfer
        if (rentalInstance[_rentalId].renter == address(0x0)) {
            // Re-entry secure
            uint256 _bidValue = bidValue[_rentalId];
            bidValue[_rentalId] = 0;
            //Transfer token to bider
            _nftWithdraw(
                rentalInstance[_rentalId].tokenId,
                rentalInstance[_rentalId].nftAddress,
                bider[_rentalId]
            );

            //Transfer ETH to owner
            msg.sender.transfer(_getValueSubFees(_bidValue));

            // delete RentalInstance
            _deleteInstance(_rentalId);
        }
    }

    // =========================================================================================
    // Utils
    // =========================================================================================

    function _removeIdFromMyInstances(bytes32 _rentalId, address _user)
        internal
    {
        uint256 _index;
        for (uint256 i = 0; i < _myRentalInstances[_user].length; i++) {
            if (_myRentalInstances[_user][i] == _rentalId) {
                _index = i;
                break;
            }
        }
        _myRentalInstances[_user][_index] = _myRentalInstances[_user][
            _myRentalInstances[_user].length - 1
        ];
        _myRentalInstances[_user].pop();
    }

    function _removeIdFromAllInstances(bytes32 _rentalId) internal {
        uint256 _index;
        for (uint256 i = 0; i < _rentalInstances.length; i++) {
            if (_rentalInstances[i] == _rentalId) {
                _index = i;
                break;
            }
        }
        _rentalInstances[_index] = _rentalInstances[
            _rentalInstances.length - 1
        ];
        _rentalInstances.pop();
    }

    // =========================================================================================
    // Renters actions
    // =========================================================================================

    //Before calling this function, user need to pre approve for the return of NFT
    // IERC721(_NFTAddress).setApprovalForAll(address(this),true) must be init in the front end
    // _rentalDuration must be number of day
    function rentNft(bytes32 _rentalId, uint256 _numberOfDays)
        public
        payable
        notThief
    {
        require(
            rentalInstance[_rentalId].nftAddress != address(0x0),
            "Instance doesn't exist"
        );
        require(
            asStolenANft[msg.sender] == false,
            "Your address didn't respected rules !"
        );
        require(
            _numberOfDays >= rentalInstance[_rentalId].minRentPeriod &&
                _numberOfDays <= rentalInstance[_rentalId].maxRentPeriod,
            "Number of days Not autorized, check min and max value"
        );
        require(
            IERC721(rentalInstance[_rentalId].nftAddress).isApprovedForAll(
                msg.sender,
                address(this)
            ),
            "You need to approve the contract before renting this NFT"
        );
        require(
            rentalInstance[_rentalId].renter == address(0x0),
            "Instance is on renting proccess"
        );
        // need to send eth value collateral + (Eth price Per day * number of renting days)
        require(
            msg.value >=
                rentalInstance[_rentalId].ethValueCollateral.add(
                    getRentalPrice(_rentalId, _numberOfDays)
                ),
            "Not enough value "
        );

        // Calculate the value to send to owner of NFT
        uint256 _rentingValue =
            msg.value.sub(rentalInstance[_rentalId].ethValueCollateral);

        // Send ETH payment to owner of NFT
        rentalInstance[_rentalId].owner.transfer(
            _getValueSubFees(_rentingValue)
        );

        // Store collateral
        _collatInThisInstance[msg.sender][_rentalId] = rentalInstance[_rentalId]
            .ethValueCollateral;

        // Update rental instance
        rentalInstance[_rentalId].renter = msg.sender;
        rentalInstance[_rentalId].endOfRent = block.number.add(
            _numberOfDays.mul(6400)
        );

        // transfer token to renter
        _nftWithdraw(
            rentalInstance[_rentalId].tokenId,
            rentalInstance[_rentalId].nftAddress,
            msg.sender
        );

        emit NFTRented(
            _rentalId,
            rentalInstance[_rentalId].nftAddress,
            rentalInstance[_rentalId].tokenId,
            msg.sender
        );

        //Farm token from collateral
        Farming(farmingAddress).COLLATERAL_POOL_stake(
            msg.sender,
            rentalInstance[_rentalId].ethValueCollateral
        );
    }

    function getRentalPrice(bytes32 _rentalId, uint256 _numberOfDays)
        public
        view
        returns (uint256)
    {
        return (rentalInstance[_rentalId].amountPricePerDay.mul(_numberOfDays));
    }

    // Get the NFT Back to contract
    // Function can only be called by renter if deadline didn't passed
    function returnNftRented(bytes32 _rentalId) public {
        require(
            rentalInstance[_rentalId].renter == msg.sender,
            "Not your rental instance"
        );
        require(
            rentalInstance[_rentalId].endOfRent >= block.number,
            "Dead Line passed, you need to activate getNftBackToRent() and pay late fees"
        );

        emit RentalFinished(
            _rentalId,
            rentalInstance[_rentalId].nftAddress,
            rentalInstance[_rentalId].tokenId
        );

        _returnCollateralToRenter(_rentalId);

        if (buyer[_rentalId] != address(0x0)) {
            //Transfer token to buyer
            _nftTransferFrom(
                rentalInstance[_rentalId].tokenId,
                rentalInstance[_rentalId].nftAddress,
                rentalInstance[_rentalId].renter,
                buyer[_rentalId]
            );

            //reentry secure
            uint256 _salePrice = salePrice[_rentalId];
            salePrice[_rentalId] = 0;

            //Transfer ETH to owner
            rentalInstance[_rentalId].owner.transfer(
                _getValueSubFees(_salePrice)
            );

            // delete RentalInstance
            _deleteInstance(_rentalId);
        }
        if (bidAccepted[_rentalId]) {
            //Transfer token to bider
            _nftTransferFrom(
                rentalInstance[_rentalId].tokenId,
                rentalInstance[_rentalId].nftAddress,
                rentalInstance[_rentalId].renter,
                bider[_rentalId]
            );

            //reentry secure
            uint256 _salePrice = bidValue[_rentalId];
            bidValue[_rentalId] = 0;

            //Transfer ETH to owner
            rentalInstance[_rentalId].owner.transfer(
                _getValueSubFees(_salePrice)
            );

            // delete RentalInstance
            _deleteInstance(_rentalId);
        } else {
            //Transfer back NFT to contract
            _nftDeposit(
                rentalInstance[_rentalId].tokenId,
                rentalInstance[_rentalId].nftAddress,
                rentalInstance[_rentalId].renter
            );

            //Update Rental instance
            rentalInstance[_rentalId].renter = address(0x0);
            rentalInstance[_rentalId].endOfRent = 0;
        }
    }

    // Extend the rental period if renter want to keep the NFT more days without late fees
    // Only the renter can call this function
    // If function is called after deadline of rental instance, Late fees are asked
    function extendRental(bytes32 _rentalId, uint8 _numberOfDays)
        public
        payable
        notThief
    {
        require(
            rentalInstance[_rentalId].renter == msg.sender,
            "Not your rental instance"
        );
        require(
            rentalInstance[_rentalId].extendAccepted == true,
            "Extend is not accepted for this instance"
        );
        require(
            _numberOfDays >= rentalInstance[_rentalId].minRentPeriod &&
                _numberOfDays <= rentalInstance[_rentalId].maxRentPeriod,
            "Number of days Not autorized, check min and max value"
        );
        require(renterRespectedRules(_rentalId), "You didn't respect te rules");
        require(
            msg.value >=
                getLateFeesValue(_rentalId).add(
                    getRentalPrice(_rentalId, _numberOfDays)
                ),
            "Not enough value"
        );
        require(
            bidAccepted[_rentalId] == false && buyer[_rentalId] == address(0x0),
            "NFT is in transfer process"
        );

        rentalInstance[_rentalId].owner.transfer(_getValueSubFees(msg.value));

        // Update rental instance
        rentalInstance[_rentalId].endOfRent = rentalInstance[_rentalId]
            .endOfRent
            .add(_numberOfDays.mul(6400));
    }

    // Get the NFT Back to contract when rental instance have passed its deadline
    // This function can be called by anyone
    function liquidateRent(bytes32 _rentalId) public notThief {
        require(
            rentalInstance[_rentalId].renter != address(0x0),
            "NFT is not in renting process"
        );

        require(
            block.number > rentalInstance[_rentalId].endOfRent,
            "Rental is not terminated"
        );

        emit RentalFinished(
            _rentalId,
            rentalInstance[_rentalId].nftAddress,
            rentalInstance[_rentalId].tokenId
        );

        // Check if NFT is sold
        if (
            buyer[_rentalId] != address(0x0) && renterRespectedRules(_rentalId)
        ) {
            //Transfer token to buyer
            _nftTransferFrom(
                rentalInstance[_rentalId].tokenId,
                rentalInstance[_rentalId].nftAddress,
                rentalInstance[_rentalId].renter,
                buyer[_rentalId]
            );

            // re entry secure
            uint256 _priceValue = salePrice[_rentalId];
            salePrice[_rentalId] = 0;

            //Transfer ETH to owner
            rentalInstance[_rentalId].owner.transfer(
                _getValueSubFees(_priceValue)
            );

            _applyLateFeesAndReturnCollateral(_rentalId, buyer[_rentalId]);

            // delete RentalInstance
            _deleteInstance(_rentalId);
        } else if (bidAccepted[_rentalId] && renterRespectedRules(_rentalId)) {
            //Transfer token to bider
            _nftTransferFrom(
                rentalInstance[_rentalId].tokenId,
                rentalInstance[_rentalId].nftAddress,
                rentalInstance[_rentalId].renter,
                bider[_rentalId]
            );

            // re entry secure
            uint256 _priceValue = bidValue[_rentalId];
            bidValue[_rentalId] = 0;

            //Transfer ETH to owner
            rentalInstance[_rentalId].owner.transfer(
                _getValueSubFees(_priceValue)
            );

            _applyLateFeesAndReturnCollateral(_rentalId, bider[_rentalId]);

            // delete RentalInstance
            _deleteInstance(_rentalId);
        } else if (!renterRespectedRules(_rentalId)) {
            liquidateThief(_rentalId);
        } else {
            //Transfer back NFT to contract
            _nftDeposit(
                rentalInstance[_rentalId].tokenId,
                rentalInstance[_rentalId].nftAddress,
                rentalInstance[_rentalId].renter
            );

            _applyLateFeesAndReturnCollateral(
                _rentalId,
                rentalInstance[_rentalId].owner
            );

            //Update Rental instance
            rentalInstance[_rentalId].renter = address(0x0);
            rentalInstance[_rentalId].endOfRent = 0;
        }
    }

    function liquidateThief(bytes32 _rentalId) public notThief {
        require(
            !renterRespectedRules(_rentalId),
            "This renter have respected rules "
        );
        // if renter didn't respect rules
        // He doesn't have the NFT in his wallet or he changes allowance
        // send collateral to owner

        // store this address to forbidens addresses
        asStolenANft[rentalInstance[_rentalId].renter] = true;
        // Ban user for farming and stacking
        Farming(farmingAddress).bannishUser(rentalInstance[_rentalId].renter);
        Stacking(PUBLIC_STACKING_FUND).bannishUser(
            rentalInstance[_rentalId].renter
        );

        // re entry secure
        uint256 _value = rentalInstance[_rentalId].ethValueCollateral;
        rentalInstance[_rentalId].ethValueCollateral = 0;

        rentalInstance[_rentalId].owner.transfer(_value);

        emit NFTStolen(
            _rentalId,
            rentalInstance[_rentalId].nftAddress,
            rentalInstance[_rentalId].tokenId,
            rentalInstance[_rentalId].renter
        );

        // refund bider if necessary
        if (bidAccepted[_rentalId]) {
            //re entry secure
            uint256 _bidValue = bidValue[_rentalId];
            bidValue[_rentalId] = 0;

            bider[_rentalId].transfer(_bidValue);
        }
        // refund Buyer if necessary
        if (buyer[_rentalId] != address(0x0)) {
            // re entry secure
            uint256 _saleValue = salePrice[_rentalId];
            salePrice[_rentalId] = 0;
            buyer[_rentalId].transfer(_saleValue);
        }

        // delete RentalInstance
        _deleteInstance(_rentalId);
    }

    function getLateFeesValue(bytes32 _rentalId) public view returns (uint256) {
        uint256 _toSend;
        if (block.number > rentalInstance[_rentalId].endOfRent) {
            uint256 _numberOfAddDays = 1;
            uint256 _numberOfAddBlocks =
                block.number.sub(rentalInstance[_rentalId].endOfRent);
            if (_numberOfAddBlocks > 6400) {
                _numberOfAddDays = (
                    (_numberOfAddBlocks.sub(_numberOfAddBlocks.mod(6400))).div(
                        6400
                    )
                )
                    .add(1);
            }
            _toSend = (
                (
                    _numberOfAddDays.mul(
                        rentalInstance[_rentalId].amountPricePerDay
                    )
                )
                    .mul(150)
            )
                .div(100);
        }
        //Return a wei value (1E18 WEI = 1 ETH)
        return _toSend;
    }

    // public function for checking if renter still have the token on his wallet
    // and didn't change allowance
    function renterRespectedRules(bytes32 _rentalId)
        public
        view
        returns (bool)
    {
        if (rentalInstance[_rentalId].renter == address(0x0)) {
            return true;
        } else if (
            IERC721(rentalInstance[_rentalId].nftAddress).ownerOf(
                rentalInstance[_rentalId].tokenId
            ) ==
            rentalInstance[_rentalId].renter &&
            IERC721(rentalInstance[_rentalId].nftAddress).isApprovedForAll(
                rentalInstance[_rentalId].renter,
                address(this)
            ) ==
            true
        ) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Rental.sol";

contract Wanters is Rental {
    using SafeMath for uint256;

    // =========================================================================================
    // Wanters/Bidders actions
    // =========================================================================================

    // Define a bid
    struct Bid {
        address payable bider;
        address nftAddress;
        uint256 tokenId;
        uint256 ethValueCollateral;
        uint256 amountPricePerDay;
        uint256 numberOfDays;
    }

    // Store all bid instances by creating a bytes32 ID
    mapping(bytes32 => Bid) public bid;
    bytes32[] _bids;

    // Store bids instances of the user
    mapping(address => bytes32[]) _myBidsInstances;

    // =========================================================================================
    // Events
    // =========================================================================================

    event NewRentalBid(
        bytes32 _bidId,
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _pricePerDay,
        uint256 _numberOfDays,
        uint256 _ethCollateral
    );

    event RentingBidCanceled(
        bytes32 _bidId,
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _pricePerDay,
        uint256 _numberOfDays,
        uint256 _ethCollateral
    );

    event RentingBidAccepted(
        bytes32 _bidId,
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _pricePerDay,
        uint256 _numberOfDays,
        uint256 _ethCollateral
    );

    // =========================================================================================
    // Functions
    // =========================================================================================

    // Get number of bids instances on platform
    function numberOfBidInstances() public view returns (uint256) {
        return _bids.length;
    }

    // Get id of bid instance in array of all instances
    function bidInstanceId(uint256 _index) public view returns (bytes32) {
        return (_bids[_index]);
    }

    // Get number of bids instances user got
    function myNumberOfBidInstances(address _user)
        public
        view
        returns (uint256)
    {
        return _myBidsInstances[_user].length;
    }

    // Get id of bid instance user by index in array
    function myBidInstanceId(address _user, uint256 _index)
        public
        view
        returns (bytes32)
    {
        return (_myBidsInstances[_user][_index]);
    }

    function _removeIdFromMyBidInstances(bytes32 _bidId, address _user)
        internal
    {
        uint256 _index;
        for (uint256 i = 0; i < _myBidsInstances[_user].length; i++) {
            if (_myBidsInstances[_user][i] == _bidId) {
                _index = i;
                break;
            }
        }
        _myBidsInstances[_user][_index] = _myBidsInstances[_user][
            _myBidsInstances[_user].length - 1
        ];
        _myBidsInstances[_user].pop();
    }

    function _removeIdFromAllBidInstances(bytes32 _bidId) internal {
        uint256 _index;
        for (uint256 i = 0; i < _bids.length; i++) {
            if (_bids[i] == _bidId) {
                _index = i;
                break;
            }
        }
        _bids[_index] = _bids[_bids.length - 1];
        _bids.pop();
    }

    // Creating a wanted instance for a specific NFT
    // Need to approveForAll contract for NFT address before create a bid
    function askForNft(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _numberOfDays,
        uint256 _amountPricePerDay,
        uint256 _ethValueCollateral
    ) public payable notThief {
        require(
            msg.value >=
                _ethValueCollateral.add(_amountPricePerDay.mul(_numberOfDays)),
            "Not enough value"
        );
        require(
            IERC721(_nftAddress).isApprovedForAll(msg.sender, address(this)),
            "You need to approve the contract before biding for this NFT"
        );

        //Build an Id with NFT address, Token Id and address of bider
        bytes32 _bidId =
            keccak256(abi.encodePacked(_nftAddress, _tokenId, msg.sender));
        require(bid[_bidId].bider == address(0x0), "Bid already exist, ");

        _bids.push(_bidId);
        _myBidsInstances[msg.sender].push(_bidId);
        bid[_bidId] = Bid(
            msg.sender,
            _nftAddress,
            _tokenId,
            _ethValueCollateral,
            _amountPricePerDay,
            _numberOfDays
        );

        Farming(farmingAddress).COLLATERAL_POOL_stake(msg.sender, msg.value);

        emit NewRentalBid(
            _bidId,
            bid[_bidId].nftAddress,
            _tokenId,
            _amountPricePerDay,
            _numberOfDays,
            _ethValueCollateral
        );
    }

    // Bider can cancel his bid
    function cancelMyBid(bytes32 _bidId) public notThief {
        require(bid[_bidId].bider == msg.sender, "This not your bid");

        Farming(farmingAddress).COLLATERAL_POOL_unstake(
            msg.sender,
            bid[_bidId].ethValueCollateral
        );

        uint256 _valueToReturn =
            bid[_bidId].ethValueCollateral.add(
                bid[_bidId].amountPricePerDay.mul(bid[_bidId].numberOfDays)
            );
        bid[_bidId].ethValueCollateral = 0;
        bid[_bidId].amountPricePerDay = 0;

        msg.sender.transfer(_valueToReturn);

        emit RentingBidCanceled(
            _bidId,
            bid[_bidId].nftAddress,
            bid[_bidId].tokenId,
            bid[_bidId].amountPricePerDay,
            bid[_bidId].numberOfDays,
            bid[_bidId].ethValueCollateral
        );

        _removeIdFromAllBidInstances(_bidId);
        _removeIdFromMyBidInstances(_bidId, msg.sender);

        delete bid[_bidId];
    }

    // Accept a bid if got the NFT requested
    function acceptRentBid(
        bytes32 _bidId,
        bool _extendAccepted,
        uint8 _minRentPeriod,
        uint8 _maxRentPeriod
    ) public notThief {
        require(
            IERC721(bid[_bidId].nftAddress).getApproved(bid[_bidId].tokenId) ==
                address(this),
            "You need to approve the contract before renting this NFT"
        );

        //Build an Id with NFT address and Token Id
        bytes32 _rentalId =
            keccak256(
                abi.encodePacked(bid[_bidId].nftAddress, bid[_bidId].tokenId)
            );

        require(
            IERC721(bid[_bidId].nftAddress).ownerOf(bid[_bidId].tokenId) ==
                msg.sender ||
                rentalInstance[_rentalId].owner == msg.sender,
            "This is not your NFT"
        );

        if (rentalInstance[_rentalId].owner == msg.sender) {
            require(
                rentalInstance[_rentalId].renter == address(0x0),
                "There is already a renter"
            );

            rentalInstance[_rentalId].renter = bid[_bidId].bider;
            rentalInstance[_rentalId].ethValueCollateral = bid[_bidId]
                .ethValueCollateral;

            _collatInThisInstance[bid[_bidId].bider][_rentalId] = bid[_bidId]
                .ethValueCollateral;

            rentalInstance[_rentalId].amountPricePerDay = bid[_bidId]
                .amountPricePerDay;
            rentalInstance[_rentalId].endOfRent = block.number.add(
                bid[_bidId].numberOfDays.mul(6400)
            );
        } else {
            // Store the ID
            _rentalInstances.push(_rentalId);
            _myRentalInstances[msg.sender].push(_rentalId);

            // Create instance
            rentalInstance[_rentalId] = RentalInstance(
                msg.sender,
                bid[_bidId].bider,
                bid[_bidId].nftAddress,
                bid[_bidId].ethValueCollateral,
                bid[_bidId].tokenId,
                bid[_bidId].amountPricePerDay,
                block.number.add(bid[_bidId].numberOfDays.mul(6400)),
                _minRentPeriod,
                _maxRentPeriod,
                false,
                _extendAccepted
            );

            //if NFT can claim farming
            if (nftCanGetFarmingReward(bid[_bidId].nftAddress)) {
                rentalInstance[_rentalId].farmNFTR = true;
                Farming(farmingAddress).NFT_POOL_stake(msg.sender);
            }
        }

        // Directly transfer token to bider
        _nftTransferFrom(
            bid[_bidId].tokenId,
            bid[_bidId].nftAddress,
            msg.sender,
            bid[_bidId].bider
        );

        // Calculate value of rent
        uint256 _valueOfRent =
            bid[_bidId].amountPricePerDay.mul(bid[_bidId].numberOfDays);
        bid[_bidId].amountPricePerDay = 0;

        // Pay owner
        msg.sender.transfer(_getValueSubFees(_valueOfRent));

        emit RentingBidAccepted(
            _bidId,
            bid[_bidId].nftAddress,
            bid[_bidId].tokenId,
            bid[_bidId].amountPricePerDay,
            bid[_bidId].numberOfDays,
            bid[_bidId].ethValueCollateral
        );

        //delete bid

        _removeIdFromAllBidInstances(_bidId);
        _removeIdFromMyBidInstances(_bidId, bid[_bidId].bider);

        delete bid[_bidId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}