/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

pragma solidity ^0.4.0;

contract Balances {
    address _studioAddress = 0xa5EDeaeCF39E0D4bD9295c9F840c49ACFE9D6691;
    mapping(address => uint256) _buyersBalances;            // current offer made by buyer
    mapping(string => uint256) _pieceOffers;                // current highest offer for a piece
    mapping(string => uint256) _timeStampOfOfferForPiece;   // timestamp of when offer was made
    mapping(string => address) _pieceToOfferAddress;        //
    mapping(address => uint256) _salesFund;                 // sales amounts to seller address
    mapping(string => address) _pieceCurrentOwner;          // needs to be maintained by the studio

    function buy() public payable {
        require(msg.value > 0);
        _buyersBalances[msg.sender] = msg.value;
    }

    function withdraw() public {
        uint256 amount = _buyersBalances[msg.sender];
        require(amount > 0);
        _buyersBalances[msg.sender] = 0;
        bool success = msg.sender.call.value(amount)("");
        require(success, "Error withdrawing funds");
    }

    function checkBalance() public view returns (uint256) {
        return _buyersBalances[msg.sender];
    }

    function checkSalesFundBalance() public view returns (uint256) {
        return _salesFund[msg.sender];
    }

    function checkCurrentOffer(string pieceId) public view returns (uint256) {
        return _pieceOffers[pieceId];
    }

    function checkCurrentOwner(string pieceId) public view returns (address) {
        return _pieceCurrentOwner[pieceId];
    }

    function updatePieceCurrentOwner(string pieceId, address newOwner) public {
        require(msg.sender == _pieceCurrentOwner[pieceId] || msg.sender == _studioAddress, "Only current owner or studio can change the current owner");
        _pieceCurrentOwner[pieceId] = newOwner;
    }

    // TODO - THINK ABOUT MORE THAN ONE PIECE BEING UNDER OFFER BY SOMEONE!!
    function storeOfferFunds(string pieceId) public payable {
        require(msg.value > _pieceOffers[pieceId], "Offer is not greater than the current highest offer");

        // check whether an offer already exists
        if(_pieceOffers[pieceId] > 0) {
            // belt and braces test to see if the related address is not 0x0
            if(_pieceToOfferAddress[pieceId] != address(0)) {
                address currentHighestOfferAddress = _pieceToOfferAddress[pieceId];
                uint256 amount = _buyersBalances[currentHighestOfferAddress];
                // another belt and braces test
                require(amount > 0, "Transfer amount appears to be zero");
                _buyersBalances[_pieceToOfferAddress[pieceId]] = 0;

                bool success = currentHighestOfferAddress.call.value(amount)("");
                require(success, "Error returning funds to previous offer address");
            }
        }
        // either way we need to maintain our records
        _buyersBalances[msg.sender] = msg.value; // store buyer's offer for later retrieval etc
        _pieceOffers[pieceId] = msg.value; // store offer value against pieceId for later validation comparison
        _pieceToOfferAddress[pieceId] = msg.sender; // link sender address to pieceId
        _timeStampOfOfferForPiece[pieceId] = now;
    }

    function withdrawRejectedOfferFunds(string pieceId) public {
//        require(msg.sender == _studioAddress, "Only studio can arrange the return of rejected funds");
        uint256 threeDays = 3 * 1 days;
        uint256 timeElapsedSinceOffer = sub(_timeStampOfOfferForPiece[pieceId],threeDays);
        
        require(timeElapsedSinceOffer <= 0, "You cannot withdraw offer funds until 3 days have passed since the offer was made");
        
        uint256 amount = _buyersBalances[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        _buyersBalances[msg.sender] = 0;

        if(_pieceToOfferAddress[pieceId] == msg.sender) {
            // offer rejected but no one else has made a higher offer so reset everything
            _pieceToOfferAddress[pieceId] = address(0);
            _pieceOffers[pieceId] = 0;
            _timeStampOfOfferForPiece[pieceId] = 0;
        }
        bool success = msg.sender.call.value(amount)("");
        require(success, "Error returning rejected offer funds to offerAddress");
    }

    function transferAcceptedOfferFunds(string pieceId, address newOwner) public {
        address currentOwner = _pieceCurrentOwner[pieceId];
        bool isOwner = (msg.sender == currentOwner);

        // TODO - think whether this needs to be the case...
        require(msg.sender == _studioAddress || isOwner, "Only studio or new owner can arrange transfer of accepted offer funds");
        uint256 amount = _pieceOffers[pieceId];
        require(amount > 0, "Nothing to transfer");
        _pieceOffers[pieceId] = 0;
        _pieceToOfferAddress[pieceId] = address(0);
        _buyersBalances[msg.sender] = 0;
        _timeStampOfOfferForPiece[pieceId] = 0;

        // calculate the split
        uint256 ownerAmount = mul(div(amount, 5), 4);   // current owner 80%
        uint256 studioAmount = div(amount, 5);          // studio 20%

        // check the balances make sense
        uint256 finalCheck = 0;
        finalCheck = sub(amount, ownerAmount);
        finalCheck = sub(finalCheck, studioAmount);
        require(finalCheck == 0, "Problem with apportioning of the funds");

        // apportion the funds
        if(msg.sender != _studioAddress) {
            // address doing withdrawal is current owner
            _salesFund[msg.sender] = add(_salesFund[msg.sender], ownerAmount);
        }
        else {
            // studio is doing the withdrawal so add owner amount to owners balance
            _salesFund[currentOwner] = add(_salesFund[currentOwner], ownerAmount);
        }

        // give the studio share
        _salesFund[_studioAddress] = add(_salesFund[_studioAddress], studioAmount);

        // transfer ownership to newOwner
        _pieceCurrentOwner[pieceId] = newOwner;

        // belt and braces - we will back everything out if ownership isn't transferred successfully
        require(_pieceCurrentOwner[pieceId] == newOwner, "Final ownership transfer failed");
    }

    function withdrawSalesFundBalance() public {
        uint256 amount = _salesFund[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        _salesFund[msg.sender] = 0;
        bool success = msg.sender.call.value(amount)("");
        require(success, "Error withdrawing from salesFund");
    }

    function setStudioAddress(address newAddress) public {
        require(msg.sender == _studioAddress, "Only the current studio address can change the _studioAddress value");

        // changing address so get the funds out first if there are any
        if(_salesFund[msg.sender] > 0) {
            withdrawSalesFundBalance();
        }

        _studioAddress = newAddress;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
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
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: attempt to divide by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
         * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
         * overflow (when the result is negative).
         *
         * Counterpart to Solidity's `-` operator.
         *
         * Requirements:
         * - Subtraction cannot overflow.
         */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
         * @dev Returns the addition of two unsigned integers, reverting on
         * overflow.
         *
         * Counterpart to Solidity's `+` operator.
         *
         * Requirements:
         * - Addition cannot overflow.
         */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}