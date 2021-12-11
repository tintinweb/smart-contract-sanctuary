// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library EnumerableSet {

    struct Set {
        bytes32[] _values;

        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {

        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1; 

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 {
        

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external ;
}

contract NFTRenting is Ownable {

    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Lending {
        uint256 price;
        uint256 maxDuration;
        uint256[] rentingIds;
    }

    struct Renting {
        address renter;
        address lender;
        uint256 tokenId;
        uint256 duration;
        uint256 rentedAt;
    }

    constructor(
        address _nftAddress,
        address _beneficiary
    ) public {
        nftAddress = IERC721(_nftAddress);
        beneficiary = _beneficiary;
    }

    address beneficiary;

    IERC721 public nftAddress;

    uint256 private _feeService = 0;   
    uint256 public SECOND_PER_HOUR = 3600;
    uint256 public rentingId = 1;    

    mapping(address => mapping(uint256 => Lending)) private _lendingInfo;

    mapping(address => EnumerableSet.UintSet) private _tokenIdWithLending;

    mapping(uint256 => Renting) private _rentingInfo;

    mapping(address => EnumerableSet.UintSet) private _rentingIdWithRenting;

    event Lend(address indexed lender, uint256 indexed tokenId, uint256 maxDuration, uint256 price);
    event Rent(address indexed renter, address indexed lender, uint256 rentingId, uint256 price, uint256 duration, uint256 rentedAt);

    event CancelLending(address indexed lender, uint256 indexed tokenId);
    event UpdateLending(address indexed lender, uint256 indexed lendingId, uint256 price, uint256 maxDuration);


    //============================================VIEW FUNCTION ===========================================================
    //============================================VIEW LENDING ============================================================

    function getTokenLendingsByAddress(address lender)
        external
        view
        returns (Lending[] memory)
    {
            uint256 length = _tokenIdWithLending[lender].length(); 

            Lending[] memory lendings = new Lending[](length);
            for (uint256 i = 0; i < length; i++) {
                Lending memory lending = _lendingInfo[lender][_tokenIdWithLending[lender].at(i)];
                lendings[i] = lending;
            }
            return lendings;
    }

    function getLendingInfo(address lender, uint256 tokenId) external view returns(Lending memory) {
        Lending memory lending = _lendingInfo[lender][tokenId];
        return lending;
    }

    //===============================================VIEW RENTING ==================================================

    function getTokenRenting(uint256 _rentingId) external view returns(Renting memory) {
        Renting memory renting = _rentingInfo[_rentingId];

        return renting;
    }

    function getBatchTokenRentings(uint256 from, uint256 to) public view returns(Renting[] memory) {

        Renting[] memory rentings;
        for(uint256 i = from; i < to; i++) {
            Renting memory renting = _rentingInfo[i];
            rentings[i] = renting;
        }
        return rentings;
    }

    function getAllTokenRentings() external view returns(Renting[] memory) {

        return getBatchTokenRentings(0, rentingId);
    }

    // Hàm để xem cái này token ID của 1 thằng có bao nhiêu thằng đang thuê

    function  getAllRentingByTokenIdAndAddress(address lender, uint256 tokenId) external view returns(Renting[] memory) {
        uint256 length = _lendingInfo[lender][tokenId].rentingIds.length;
        Renting[] memory rentings = new Renting[](length);
        for(uint256 i = 0; i < length; i++) {
            Renting memory renting = _rentingInfo[i];
            if(!isRentingExpired(renting)){
                rentings[i] = renting;
            }
            
        }
        rentings;
    }

    //===================================================PRIVATE FUNCTION================================================

    function isRentingExpired(Renting memory renting) private view returns(bool) {
        if(block.timestamp > renting.rentedAt.add(renting.duration)) {
            return true;
        }
    }

    //==================================================== PUBLIC FUNCTION ==============================================
    //==================================================== LEND FUNCTION ================================================
    function lendToken(
        uint256 tokenId,
        uint256 rentPrice,
        uint256 maxDuration
    ) external {
        _lendToken(tokenId, rentPrice, maxDuration);
    }

    function cancelLendingToken(uint256 _tokenId) public {
        _cancelLendingToken(_tokenId);
    }

    //=============================================RENT FUNCTION =====================================================

    function rentToken(address lender, uint256 tokenId, uint256 duration) external payable {
        _rentToken(lender, tokenId, duration);

    }

    //================================================== PRIVATE FUNCTION =======================================================
    //================================================== LEND FUNCTION ==========================================================
    function _lendToken(uint256 _tokenId, uint256 _rentPrice, uint256 _maxDuration) private {
        address lender = msg.sender;
        Lending storage lending = _lendingInfo[lender][_tokenId];
        lending.price = _rentPrice;
        lending.maxDuration = _maxDuration;
        if(!_tokenIdWithLending[lender].contains(_tokenId)) {
            _tokenIdWithLending[lender].add(_tokenId);
        }
        nftAddress.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit Lend(msg.sender, _tokenId, _maxDuration, _rentPrice);
    }

    // hàm thôi không cho thuê nữa
    function _cancelLendingToken(uint256 _tokenId) private {

        address lender = msg.sender;
        require(_tokenIdWithLending[lender].contains(_tokenId), "not lender");
        uint256[] storage rentingIds = _lendingInfo[lender][_tokenId].rentingIds;

        uint256 length = rentingIds.length;
        for(uint256 i = 0; i < length; i++) {
            Renting memory renting = _rentingInfo[rentingIds[i]];
            if( block.timestamp > renting.rentedAt + renting.duration) {
                _rentingIdWithRenting[renting.renter].remove(rentingIds[i]);
                _removeElement(rentingIds, i);
            }
        }

        nftAddress.safeTransferFrom(address(this), lender, _tokenId);

        emit CancelLending(lender, _tokenId);

    }

    //================================================== RENT FUNCTION =========================================================

    function _rentToken(address lender, uint256 _tokenId, uint256 duration) private {
        address renter = msg.sender;
        require(renter != lender, "lender can't rent himself");

        Lending memory lending = _lendingInfo[lender][_tokenId];

        uint256[] storage rentingIds = _lendingInfo[lender][_tokenId].rentingIds;

        uint256 length = rentingIds.length;
        for(uint256 i = 0; i < length; i++) {
            Renting memory renting = _rentingInfo[rentingIds[i]];
            if( block.timestamp > renting.rentedAt + renting.duration) {
                _rentingIdWithRenting[renting.renter].remove(rentingIds[i]);
                _removeElement(rentingIds, i);
            }
        }
        require(duration <= lending.maxDuration, "exceeds time");

        uint256 amountPay = lending.price.mul(duration).div(SECOND_PER_HOUR);
        uint256 fees = amountPay.mul(_feeService).div(10000);
        require(msg.value >= amountPay, "exceeds balance");

        //send lender bnb
        payable(lender).transfer(amountPay.sub(fees));

        rentingIds.push(rentingId);

        _rentingInfo[rentingId] = Renting(renter, lender, _tokenId, duration, block.timestamp);
        
        emit Rent(renter, lender, rentingId, lending.price, duration, block.timestamp);
        
        //send overleft
        if(msg.value > amountPay) {
            payable(msg.sender).transfer(msg.value.sub(amountPay));
        }
        _rentingIdWithRenting[renter].add(rentingId);
        rentingId ++;

    }

    //==================================================RESTRICT FUNCTION=======================================================

    function setFee(uint256 _newFee) external onlyOwner {
        _feeService = _newFee;
    }
    
    //===================================================ACTION FUNCTION========================================================
    
    function _removeElement(uint256[] storage array , uint256 index) private {
        array[index] =  array[array.length - 1];
        array.pop();
    }
    
}