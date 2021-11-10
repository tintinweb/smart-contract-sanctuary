/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

pragma solidity ^0.8.0;

contract OfferHandler {
    address _studioAddress = 0xa5EDeaeCF39E0D4bD9295c9F840c49ACFE9D6691;
    // offer related mappings
    mapping(string => uint256) _currentOfferOnPiece;        // pieceId / value of offer
    mapping(string => address) _currentOfferOwner;          // pieceId / wallet address of person owning the offer
    mapping(string => uint256) _timeStampOfOfferOnPiece;    // pieceId / timestamp of most recent offer

    // piece ownership register
    mapping(string => address) _currentOwnerOfPiece;        // pieceId / owning wallet address
    mapping(string => address) _pieceCreator;               // pieceId / creators address

    // fund storage
    mapping(address => uint256) _salesFund;                 // sales amounts to seller address

    // events
    event OfferMadeOnPiece(address ownerOfOffer, uint256 offerAmount, string pieceId);
    event OfferAcceptedOnPiece(string pieceId, uint256 offerAmount);
    event OwnershipOfPieceTransferred(address previousOwner, address newOwner, string pieceId);

    constructor() {

    }

    function getCurrentOfferAmount(string memory pieceId) public view returns (uint256 offerAmount) {
        return(_currentOfferOnPiece[pieceId]);
    }

    function getCurrentOfferOwner(string memory pieceId) public view returns (address offerOwner) {
        return(_currentOfferOwner[pieceId]);
    }

    function getCurrentOwnerOfPiece(string memory pieceId) public view returns (address currentOwner) {
        return(_currentOwnerOfPiece[pieceId]);
    }

    function getCreatorOfPiece(string memory pieceId) public view returns (address currentCreator) {
        return(_pieceCreator[pieceId]);
    }

    function updatePieceCurrentOwner(string memory pieceId, address newOwner) public {
        address previousOwner = _currentOwnerOfPiece[pieceId];
        require(msg.sender == previousOwner || msg.sender == _studioAddress, "Only current owner or studio can change the current owner address");
        require(newOwner != address(0),"You cannot assign ownership of a piece to zero address");
        _currentOwnerOfPiece[pieceId] = newOwner;
        emit OwnershipOfPieceTransferred(previousOwner, newOwner, pieceId);
    }

    function updatePieceCreator(string memory pieceId, address newCreator) public {
        require(msg.sender == _pieceCreator[pieceId] || msg.sender == _studioAddress, "Only current creator or studio can change the piece creator address");
        _pieceCreator[pieceId] = newCreator;
    }

    function makeOfferOnPiece(string memory pieceId) public payable {
        require(msg.value > _currentOfferOnPiece[pieceId], "Offer is not greater than the current highest offer");
        require(msg.sender != _currentOwnerOfPiece[pieceId], "It is not possible to make an offer on a piece that you own");
        require(_currentOwnerOfPiece[pieceId] != address(0), "Piece does not appear to exist so you cannot make offers on it..");

        uint256 newOffer = msg.value;

        // check whether an offer already exists
        if(_currentOfferOnPiece[pieceId] > 0) {
            // check if this is the current offer owner adding to their original offer
            if(msg.sender == _currentOfferOwner[pieceId]) {
                newOffer = add(_currentOfferOnPiece[pieceId], msg.value);
                _currentOfferOnPiece[pieceId] = newOffer;
            }
            else if(_currentOfferOwner[pieceId] != address(0)) {
                // belt and braces test to check if the related address is not 0x0
                address currentHighestOfferAddress = _currentOfferOwner[pieceId];
                uint256 amount = _currentOfferOnPiece[pieceId];
                // another belt and braces test
                require(amount > 0, "Offer refund amount appears to be zero");
                _currentOfferOnPiece[pieceId] = 0;

                // return the lower offer amount to the previous offer owner
                (bool success, ) = currentHighestOfferAddress.call{value:amount}("");
                require(success, "Error returning funds to previous offer address");
                _currentOfferOnPiece[pieceId] = msg.value;  // update with new offer value
            }
        }
        else {
            _currentOfferOnPiece[pieceId] = msg.value;  // store initial offer value
        }

        // either way we need to maintain our records
        _currentOfferOwner[pieceId] = msg.sender;               // link sender address to pieceId
        _timeStampOfOfferOnPiece[pieceId] = block.timestamp;    // update timestamp

        // emit event
        emit OfferMadeOnPiece(_currentOfferOwner[pieceId], newOffer, pieceId);
    }

    function acceptOfferOnPiece(string memory pieceId) public {
        address currentOwner = _currentOwnerOfPiece[pieceId];
        bool isOwner = (msg.sender == currentOwner);
        require(isOwner || msg.sender == _studioAddress, "Only the current owner or the studio can accept offer made on a piece");

        uint256 amount = _currentOfferOnPiece[pieceId];
        require(amount > 0, "There does not appear to be an offer on this piece");

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

        if(currentOwner != _pieceCreator[pieceId]) {
            // this is a resale as the owner is not the same as the creator so creator and studio get 50% of the sales fee each
            uint256 splitAmount = div(studioAmount, 2); // 50% split
            _salesFund[_studioAddress] = add(_salesFund[_studioAddress], splitAmount);
            _salesFund[_pieceCreator[pieceId]] = add(_salesFund[_pieceCreator[pieceId]], splitAmount);
        }
        else {
            // this is first sale of this piece - studio gets 100% of the sales fee
            _salesFund[_studioAddress] = add(_salesFund[_studioAddress], studioAmount);
        }

        // update ownership
        address newOwner = _currentOfferOwner[pieceId];
        updatePieceCurrentOwner(pieceId, newOwner);

        // finally, we need to reset the mappings for this pieceId
        _currentOfferOnPiece[pieceId] = 0;
        _timeStampOfOfferOnPiece[pieceId] = block.timestamp;
        _currentOfferOwner[pieceId] = address(0);

        // belt and braces
        require(_currentOwnerOfPiece[pieceId] == newOwner, "Ownership transfer appears to have failed");
        emit OfferAcceptedOnPiece(pieceId, amount);
    }

    function withdrawElapsedOfferFunds(string memory pieceId) public {
        address currentOwner = _currentOfferOwner[pieceId];
        bool isOwner = (msg.sender == currentOwner);
        require(isOwner || msg.sender == _studioAddress, "Only the current owner or the studio can arrange the withdraw of an elapsed offer.");

        uint256 threeDays = 3 * 1 days;
        uint256 deadline = sub(block.timestamp,threeDays);

        require(_timeStampOfOfferOnPiece[pieceId] <= deadline, "Offer has not elapsed. You cannot withdraw offer funds until 3 days have passed since the offer was made.");

        uint256 amount = _currentOfferOnPiece[pieceId];
        require(amount > 0, "Nothing to withdraw");
        _currentOfferOnPiece[pieceId] = 0;

        if(_currentOfferOwner[pieceId] == msg.sender) {
            // offer rejected but no one else has made a higher offer so reset everything
            _currentOfferOwner[pieceId] = address(0);
            _currentOfferOnPiece[pieceId] = 0;
            _timeStampOfOfferOnPiece[pieceId] = 0;
        }
        (bool success, ) = _currentOfferOwner[pieceId].call{value:amount}("");
        require(success, "Error returning rejected offer funds to offerAddress");
    }

    function withdrawBalance() public {
        uint256 amount = _salesFund[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        _salesFund[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Error withdrawing from salesFund");
    }

    function checkBalance(address holder) public view returns (uint256 currentBalance) {
        return(_salesFund[holder]);
    }

    // SAFEMATH
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