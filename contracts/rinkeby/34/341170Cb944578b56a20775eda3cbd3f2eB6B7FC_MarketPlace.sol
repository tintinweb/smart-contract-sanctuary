/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// File: contracts\interfaces\IAdmin.sol

pragma solidity 0.6.6;

interface IAdmin {
    function isSuperAdmin(address _addr) external view returns (bool);

    function isAdmin(address _addr) external view returns (bool);
}

// File: contracts\interfaces\IKYC.sol

pragma solidity 0.6.6;

interface IKYC {
    function kycsLevel(address _addr) external view returns (uint256);
}

// File: contracts\interfaces\IPubgNFT.sol

pragma solidity 0.6.6;

interface IPubgNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function cardHolder(address _offerAddr, uint256 _offerCardType) external view returns (uint256 [] memory);
}

// File: contracts\interfaces\IPubgRouter.sol

pragma solidity 0.6.6;

interface IPubgRouter {
    function batchTransferFrom(address[] calldata _from, address[] calldata _to, uint256[] calldata _typeId) external returns (bool);
}

// File: contracts\libraries\SafeMath.sol

pragma solidity 0.6.6;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts\libraries\EnumerableSet.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

library EnumerableSet {

    struct UIntSet {
        // Storage of set values
        uint256[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (uint256 => uint256) _indexes;
    }

    // @dev Add a value to a set. O(1).
    function add(UIntSet storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    // @dev Removes a value from a set. O(1).
    function remove(UIntSet storage set, uint256 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            uint256 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    // @dev Returns true if the value is in the set. O(1).
    function contains(UIntSet storage set, uint256 value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }  

    // @dev Returns the number of values on the set. O(1).
    function length(UIntSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    // @dev Returns the number of values on the set. O(1).
    function getAll(UIntSet storage set) internal view returns (uint256 [] memory) {
        return set._values;
    }
    
    // @dev Returns the value stored at position `index` in the set. O(1).
    function at(UIntSet storage set, uint256 index) internal view returns (uint256) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
}

// File: contracts\MarketPlace.sol

pragma solidity 0.6.6;







contract MarketPlace {
    using SafeMath for uint32;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UIntSet;

    //////////////////////////////////////////////////////////////////////

    event tradeCreated(
        uint256 indexed offerID,
        address offerAddr,
        uint256 offerCardID,
        uint256 offerCardType,
        uint256 requestCardType
    );

    event tradeClosed(uint256 indexed offerID);

    event tradeCompleted(
        uint256 indexed offerID,
        address offerAddr,
        uint256 offerCardID,
        address completeAddr,
        uint256 requestCardID
    );

    //////////////////////////////////////////////////////////////////////

    IAdmin public admin;
    IKYC public kyc;
    IPubgNFT public kap721;
    IPubgRouter public router;
    bool public isActivatedOnlyKycAddress;

    function activateOnlyKycAddress() external onlySuperAdmin {
        isActivatedOnlyKycAddress = true;
    }

    //////////////////////////////////////////////////////////////////////

    struct tradeInformationStruct {
        uint256 offerID;
        address offerAddr;
        uint256 offerCardID;
        uint256 offerCardType;
        uint256 requestCardType;
        bool close;
    }

    tradeInformationStruct[] public allTradeInformation;
    EnumerableSet.UIntSet private openTradeID;
    mapping(address => EnumerableSet.UIntSet) private openTradeIDByAddr;
    mapping(uint256 => mapping(uint256 => uint256)) private openTradeCountByCardType;

    uint256 public offerIDCounter = 0;
    uint256 public maxOffer = 5;

    //////////////////////////////////////////////////////////////////////

    modifier onlySuperAdmin() {
        // require(admin.isSuperAdmin(msg.sender), "Restricted only super admin");
        require(1 == 1);
        _;
    }

    modifier onlyKYC(address _addr) {
        if (isActivatedOnlyKycAddress == true) {
            require(
                kyc.kycsLevel(_addr) > 1,
                "Only kyc address allowed to trade"
            );
        }
        _;
    }

    modifier onlyOpen(uint256 _offerID) {
        require(
            !allTradeInformation[_offerID].close,
            "The trade is already closed"
        );
        _;
    }

    //////////////////////////////////////////////////////////////////////

    constructor(address _admin, address _kyc, address _kap721, address _router) public {
        admin = IAdmin(_admin);
        kyc = IKYC(_kyc);
        kap721 = IPubgNFT(_kap721);
        router = IPubgRouter(_router);
    }

    //////////////////////////////////////////////////////////////////////

    function setMaxOffter(uint256 _maxOffer) external onlySuperAdmin returns (bool) {
        maxOffer = _maxOffer;
        return true;
    }

    function getOpenTradeID() external view returns (uint256[] memory) {
        return openTradeID.getAll();
    }

    function getOpenTradeIDByAddr(address _addr) external view returns (uint256[] memory) {
        return openTradeIDByAddr[_addr].getAll();
    }

    //////////////////////////////////////////////////////////////////////
    // getOpenTradeID
    // getOpenTradeIDByAddr
    // createTrade
    // batchCreateTrade
    // closeTrade
    // batchCloseTrade
    // _closeTrade
    // completeTrade
    // completeCloseTrade
    // searchTrade

    function createTrade(
        address _offerAddr,
        uint256 _offerCardType,
        uint256 _requestCardType
    ) external onlySuperAdmin onlyKYC(_offerAddr) returns (bool) {
        // Amount of created offers needs to be less than maxOffer
        require(openTradeIDByAddr[_offerAddr].length() < maxOffer, "Offer exceeds maxOffer");

        // Get the array of available cards of the card type
        // uint256[] memory availableCard = kap721.cardHolder(_offerAddr, _offerCardType);
        // require(availableCard.length != 0, "Offered card not available");

        // Transfer the last card in the array to this contract
        // uint256 offerCardID = availableCard[availableCard.length.sub(1)];

        // {
        //     // Define array of one
        //     address[] memory _offerAddrArr = new address[](1);
        //     address[] memory addressThisArr = new address[](1);
        //     uint256[] memory offerCardIDArr = new uint256[](1);
        //     _offerAddrArr[0] = _offerAddr;
        //     addressThisArr[0] = address(this);
        //     offerCardIDArr[0] = offerCardID;
        //     // kap721.safeTransferFrom(_offerAddr, address(this), offerCardID);
        //     router.batchTransferFrom(_offerAddrArr, addressThisArr, offerCardIDArr);
        // }

        // Create information of the trade
        // and push to allTradeInformation
        // tradeInformationStruct memory tradeInformation =
        //     tradeInformationStruct({
        //         offerID: offerIDCounter,
        //         offerAddr: _offerAddr,
        //         offerCardType: _offerCardType,
        //         requestCardType: _requestCardType,
        //         close: false
        //     });
        // allTradeInformation.push(tradeInformation);

        // Push offerID to openTrade
        // openTradeID.add(offerIDCounter);
        // openTradeIDByAddr[_offerAddr].add(offerIDCounter);
        // openTradeCountByCardType[_offerCardType][_requestCardType] = openTradeCountByCardType[_offerCardType][_requestCardType].add(1);

        // emit tradeCreated(
        //     offerIDCounter,
        //     _offerAddr,
        //     offerCardID,
        //     _offerCardType,
        //     _requestCardType
        // );

        // Increment counter by one
        offerIDCounter = offerIDCounter.add(1);

        return true;
    }
    
    function batchCreateTrade(
        address[] calldata _offerAddr,
        uint256[] calldata _offerCardType,
        uint256[] calldata _requestCardType
    ) external onlySuperAdmin returns (bool) {
        require(_offerAddr.length == _offerCardType.length && _offerCardType.length == _requestCardType.length, "Need all input in same length");

        for (uint32 i = 0; i < _offerAddr.length; i++) {
            // onlyKYC
            if (isActivatedOnlyKycAddress == true) {
                if (kyc.kycsLevel(_offerAddr[i]) <= 1) {
                    continue;
                }
            }
            if (openTradeIDByAddr[_offerAddr[i]].length() >= maxOffer) {
                // Offer exceeds maxOffer
                continue;
            }

            // // Get the array of available cards of the card type
            // uint256[] memory availableCard = kap721.cardHolder(_offerAddr[i], _offerCardType[i]);
            // if (availableCard.length == 0) {
            //     // Offered card not available
            //     continue;
            // }
            // uint256 offerCardID = availableCard[availableCard.length.sub(1)];
            uint offerCardID = 123;

            // {
            //     // Define array of one
            //     address[] memory _offerAddrArr = new address[](1);
            //     address[] memory addressThisArr = new address[](1);
            //     uint256[] memory offerCardIDArr = new uint256[](1);
            //     _offerAddrArr[0] = _offerAddr[i];
            //     addressThisArr[0] = address(this);
            //     offerCardIDArr[0] = offerCardID;
            //     // kap721.safeTransferFrom(_offerAddr[i], address(this), offerCardID);
            //     router.batchTransferFrom(_offerAddrArr, addressThisArr, offerCardIDArr);
            // }

            // Create information of the trade
            // and push to allTradeInformation
            tradeInformationStruct memory tradeInformation =
                tradeInformationStruct({
                    offerID: offerIDCounter,
                    offerAddr: _offerAddr[i],
                    offerCardID: offerCardID,
                    offerCardType: _offerCardType[i],
                    requestCardType: _requestCardType[i],
                    close: false
                });
            allTradeInformation.push(tradeInformation);

            // Push offerID to openTrade
            openTradeID.add(offerIDCounter);
            openTradeIDByAddr[_offerAddr[i]].add(offerIDCounter);
            openTradeCountByCardType[_offerCardType[i]][_requestCardType[i]] = openTradeCountByCardType[_offerCardType[i]][_requestCardType[i]].add(1);

            // emit tradeCreated(
            //     offerIDCounter,
            //     _offerAddr[i],
            //     offerCardID,
            //     _offerCardType[i],
            //     _requestCardType[i]
            // );

            // Increment counter by one
            offerIDCounter = offerIDCounter.add(1);
        }
        
        return true;
    }

    //////////////////////////////////////////////////////////////////////

    function closeTrade(uint256 _offerID)
        public
        onlySuperAdmin
        onlyOpen(_offerID) returns (bool)
    {
        // Transfer the NFT back to the owner
        kap721.safeTransferFrom(
            address(this),
            allTradeInformation[_offerID].offerAddr,
            allTradeInformation[_offerID].offerCardID
        );

        // Close trade
        _closeTrade(_offerID, allTradeInformation[_offerID].offerAddr);

        emit tradeClosed(_offerID);

        return true;
    }

    function batchCloseTrade(uint256[] calldata _offerID) external onlySuperAdmin returns (bool) {
        for (uint32 i = 0; i < _offerID.length; i++) {
            // onlyOpen
            if (allTradeInformation[_offerID[i]].close) {
                continue;
            }
            // onlyKYC
            if (isActivatedOnlyKycAddress == true) {
                if (kyc.kycsLevel(allTradeInformation[_offerID[i]].offerAddr) <= 1) {
                    continue;
                }
            }

            // Transfer the NFT back to the owner
            kap721.safeTransferFrom(
                address(this),
                allTradeInformation[_offerID[i]].offerAddr,
                allTradeInformation[_offerID[i]].offerCardID
            );

            // Close trade
            _closeTrade(_offerID[i], allTradeInformation[_offerID[i]].offerAddr);

            emit tradeClosed(_offerID[i]);
        }

        return true;
    }

    function _closeTrade(uint256 _offerID, address _offerAddr) private {
        // Close trade
        allTradeInformation[_offerID].close = true;
        // Push offerID to openTrade
        openTradeID.remove(_offerID);
        openTradeIDByAddr[_offerAddr].remove(_offerID);

        uint256 offerCardType = allTradeInformation[_offerID].offerCardType;
        uint256 requestCardType = allTradeInformation[_offerID].requestCardType;
        openTradeCountByCardType[offerCardType][requestCardType] = openTradeCountByCardType[offerCardType][requestCardType].sub(1);
    }

    //////////////////////////////////////////////////////////////////////

    function completeTrade(address _completeAddr, uint256 _offerID)
        public
        onlySuperAdmin
        onlyKYC(_completeAddr)
        onlyOpen(_offerID)
        returns (bool)
    {
        address offerAddr = allTradeInformation[_offerID].offerAddr;
        uint256 offerCardID = allTradeInformation[_offerID].offerCardID;
        uint256 requestCardType = allTradeInformation[_offerID].requestCardType;

        // Get the array of available cards of the card type
        uint256[] memory availableCard =
            kap721.cardHolder(_completeAddr, requestCardType);
        require(availableCard.length != 0, "Requested card not available");
        
        // Transfer the cards
        uint256 requestCardID = availableCard[availableCard.length.sub(1)];

        {
            // Define array of one
            address[] memory _completeAddrArr = new address[](1);
            address[] memory offerAddrArr = new address[](1);
            uint256[] memory requestCardIDArr = new uint256[](1);
            _completeAddrArr[0] = _completeAddr;
            offerAddrArr[0] = offerAddr;
            requestCardIDArr[0] = requestCardID;
            // from completeAddr to offerAddr
            // kap721.safeTransferFrom(_completeAddr, offerAddr, requestCardID);
            router.batchTransferFrom(_completeAddrArr, offerAddrArr, requestCardIDArr);
        }

        // from this contract to completeAddr
        kap721.safeTransferFrom(address(this), _completeAddr, offerCardID);

        // Close trade
        _closeTrade(_offerID, offerAddr);

        emit tradeCompleted(
            _offerID,
            offerAddr,
            offerCardID,
            _completeAddr,
            requestCardID
        );

        return true;
    }

    function batchCompleteTrade(
        address[] calldata _completeAddr,
        uint256[] calldata _offerID
    ) external onlySuperAdmin returns (bool) {
        require(_completeAddr.length == _offerID.length, "Need all input in same length");

        for (uint32 i = 0; i < _completeAddr.length; i++) {
            // onlyOpen
            if (allTradeInformation[_offerID[i]].close) {
                continue;
            }
            // onlyKYC
            if (isActivatedOnlyKycAddress == true) {
                if (kyc.kycsLevel(allTradeInformation[_offerID[i]].offerAddr) <= 1) {
                    continue;
                }
            }

            address offerAddr = allTradeInformation[_offerID[i]].offerAddr;
            uint256 offerCardID = allTradeInformation[_offerID[i]].offerCardID;
            uint256 requestCardType = allTradeInformation[_offerID[i]].requestCardType;

            // Get the array of available cards of the card type
            uint256[] memory availableCard = kap721.cardHolder(_completeAddr[i], requestCardType);
            if (availableCard.length == 0) {
                // Requested card not available
                continue;
            }
            uint256 requestCardID = availableCard[availableCard.length.sub(1)];


            {
                // Transfer the cards
                // Define array of one
                address[] memory _completeAddrArr = new address[](1);
                address[] memory offerAddrArr = new address[](1);
                uint256[] memory requestCardIDArr = new uint256[](1);
                _completeAddrArr[0] = _completeAddr[i];
                offerAddrArr[0] = offerAddr;
                requestCardIDArr[0] = requestCardID;
                // from completeAddr to offerAddr
                // kap721.safeTransferFrom(_completeAddr[i], offerAddr, requestCardID);
                router.batchTransferFrom(_completeAddrArr, offerAddrArr, requestCardIDArr);
            }

            // from this contract to completeAddr
            kap721.safeTransferFrom(address(this), _completeAddr[i], offerCardID);

            // Close trade
            _closeTrade(_offerID[i], offerAddr);

            emit tradeCompleted(
                _offerID[i],
                offerAddr,
                offerCardID,
                _completeAddr[i],
                requestCardID
            );
        }

        return true;
    }

    //////////////////////////////////////////////////////////////////////

    function searchTrade(uint256 _offerCardType, uint256 _requestCardType)
        external
        view
        returns (uint256 [] memory) 
    {   
        uint256 count = 0;
        uint256 id;
        uint256[] memory toReturn = new uint256[](openTradeCountByCardType[_offerCardType][_requestCardType]); 
        for (uint32 i = 0; i < openTradeID.length(); i++) {
            id = openTradeID.at(i);
            if (allTradeInformation[id].offerCardType != _offerCardType) {
                continue;
            }
            if (allTradeInformation[id].requestCardType != _requestCardType) {
                continue;
            }
            toReturn[count] = id;
            count.add(1);
        }

        return toReturn;
    }

    //////////////////////////////////////////////////////////////////////
}