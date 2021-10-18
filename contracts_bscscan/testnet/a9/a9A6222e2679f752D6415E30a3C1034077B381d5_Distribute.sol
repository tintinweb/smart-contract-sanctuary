/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface TokenTransfer {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function ownerOf(uint tokenId) external view returns (address nftOwner);
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

contract Distribute is Ownable {
    enum State { Active, Abandoned }
    address nftAddress;
    address coinAddress;

    TokenTransfer _tokenTransferNFT;
   
    TokenTransfer _tokenTransferCoin;
  
    struct ClaimInfo {
       uint tokenId; 
       uint canClaimTotal; 
       State claimState; 
       uint claimPercent; 
       uint claimedQuantity; 
       uint laveQuantity; 
       uint nextClaimTime;
       uint lastClaimTime; 
       uint firstClaimTime; 
       uint claimNum; 
       uint abandonedTime; 
       uint activeTime;
    }
 
    struct ClaimLog {
        address receiver; 
        address nftAddr;
        uint tokenId; 
        uint quantity; 
        uint claimTime; 
        uint claimPercent; 
        uint claimNum; 
    }
    
    
    mapping(address=>mapping(uint=>ClaimInfo)) nftInfo;
    
    ClaimInfo[] public nftInfoList;
   
    mapping(address=>mapping(uint=>uint)) nftInfoIndex;
    
    
    mapping(address=>mapping(uint=>ClaimLog)) claimLogs;
    
    ClaimLog[] public claimLogList;
    
    mapping(address=>mapping(uint=>uint)) claimLogIndex;
    
   
    event doClaimInfo(ClaimInfo claimInfo);
    event doClaimLog(ClaimLog claimLog);
    event changeClaimState(uint tokenId, State state, uint optTime);
    event addClaimInfoEvent(uint _tokenId, uint _canClaimTotal, uint _claimPercent);
    
    
    modifier hasClaimRight() {
        uint _balance = getNFTBalance(msg.sender);
        require(_balance > 0, 'Insufficient balance');
         _;
    }
    
 
    modifier onlyAdmin() {
        address _nftOwner = _tokenTransferNFT.ownerOf(0);
        require(_nftOwner == msg.sender, 'Only owner can call');
         _;
    }
    

    bool hasInit = false;

    function initDistribute(address _nftAddr, address _coinAddr, uint[][] memory _infos) public {
        require(hasInit == false, 'contract has init');
        require(nftAddress == address(0), "can't init this contract from nft");
        require(coinAddress == address(0), "can't init this contract from coin");
        require(_infos.length > 0, "can't init this contract from infos");
        nftAddress = _nftAddr;
        coinAddress = _coinAddr;
        _tokenTransferNFT = TokenTransfer(nftAddress);
        _tokenTransferCoin = TokenTransfer(coinAddress);
        
     
        for(uint i=0;i<_infos.length;i++) {
            uint[] memory _info = _infos[i];
            uint _tokenId = _info[0];
            uint _canClaimTotal = _info[1];
            uint _claimPercent = _info[2];
            addClaimInfo(_tokenId, _canClaimTotal, _claimPercent);
        }
        
        hasInit = true;
    }
    
   
    function addClaimInfo(uint _tokenId, uint _canClaimTotal, uint _claimPercent) internal {
        require(_tokenId != uint(0), "Distribute: tokenId null is not allowed");
        require(_canClaimTotal != uint(0), "Distribute: canClaimTotal null is not allowed");
        require(_claimPercent != uint(0), "Distribute: claimPercent null is not allowed");
        uint _percentTemp = SafeMath.mul(_claimPercent, (10**77));
        ClaimInfo memory _claimInfo = ClaimInfo({tokenId:_tokenId,canClaimTotal:_canClaimTotal,claimState:State.Active,
        claimPercent: _percentTemp,claimedQuantity: 0,laveQuantity: _canClaimTotal,nextClaimTime: block.timestamp,
        lastClaimTime: 0,firstClaimTime: 0,claimNum: 0,abandonedTime: 0,activeTime: block.timestamp });
        
        nftInfo[nftAddress][_tokenId] = _claimInfo;
		nftInfoList.push(_claimInfo);
		nftInfoIndex[nftAddress][_tokenId] = nftInfoList.length-1;
		
        emit addClaimInfoEvent(_tokenId, _canClaimTotal, _claimPercent);
    }
    
  
    function claim() hasClaimRight() public {
      
        uint[] memory _myTokenIds = _tokenTransferNFT.tokensOfOwner(msg.sender);
        uint _needSendTotal = 0;
        for(uint i=0;i<_myTokenIds.length; i++) {
            uint _tokenId =_myTokenIds[i];
            ClaimInfo memory _info = nftInfo[nftAddress][_tokenId];
           
            if(_info.claimState == State.Abandoned) {
                continue;
            }
          
            
            if(_info.lastClaimTime + 5 minutes >= block.timestamp) {
                continue;
            }
            
            if(_info.canClaimTotal <= 0) {
                continue;
            }
            if(_info.laveQuantity <=0) {
                continue;
            }
            uint _thisClaimTemp = SafeMath.mul(_info.claimPercent, _info.canClaimTotal);
            uint _thisClaim = SafeMath.div(_thisClaimTemp, (10 ** 77));
            _thisClaim = SafeMath.div(_thisClaim, 100);
            _needSendTotal = SafeMath.add(_needSendTotal, _thisClaim);
           
            _info.claimedQuantity = SafeMath.add(_info.claimedQuantity, _thisClaim);
            _info.laveQuantity = SafeMath.sub(_info.canClaimTotal, _info.claimedQuantity);
            _info.nextClaimTime = block.timestamp + 5 minutes;
            _info.lastClaimTime = block.timestamp;
            if (_info.claimNum == 0) {
                _info.firstClaimTime = block.timestamp;
            }
            _info.claimNum = SafeMath.add(_info.claimNum, 1);
            
            uint _nextNum = _info.claimNum + 1;
         
            uint _modNum = SafeMath.mod(_nextNum, 12);
            uint _currentPercent = _info.claimPercent;
            if (_modNum == 1) {
                _info.claimPercent = SafeMath.div(_currentPercent, 2);
            }
         
            nftInfo[nftAddress][_tokenId] = _info;
            nftInfoList[nftInfoIndex[nftAddress][_tokenId]] = _info;
            emit doClaimInfo(_info);
        
            ClaimLog memory _claimLog = ClaimLog({receiver:msg.sender, nftAddr: nftAddress, tokenId: _tokenId, quantity:_thisClaim, 
            claimTime: _info.lastClaimTime, claimPercent:_currentPercent, claimNum: _info.claimNum});
    		
    		claimLogs[nftAddress][_tokenId] = _claimLog;
    		claimLogList.push(_claimLog);
    		claimLogIndex[nftAddress][_tokenId] = claimLogList.length-1;
    		emit doClaimLog(_claimLog);
        }
        
		
		_tokenTransferCoin.transferFrom(address(this), msg.sender, _needSendTotal);
    }
    
  
    function abandonTokenId(uint[] memory _tokenIds) onlyAdmin() external {
        require(_tokenIds.length > 0, 'tokenId is null');
        for(uint i=0;i<_tokenIds.length;i++) {
            uint _tokenId =_tokenIds[i];
            ClaimInfo memory _info = nftInfo[nftAddress][_tokenId];
            if(_info.claimState == State.Abandoned) {
                continue;
            }
            _info.claimState = State.Abandoned;
            _info.abandonedTime = block.timestamp;
            nftInfo[nftAddress][_tokenId] = _info;
            emit changeClaimState(_tokenId, State.Abandoned, _info.abandonedTime);
        }
    }
    
 
    function activeTokenId(uint[] memory _tokenIds) onlyAdmin() external {
        require(_tokenIds.length > 0, 'tokenId is null');
        for(uint i=0;i<_tokenIds.length;i++) {
            uint _tokenId =_tokenIds[i];
            ClaimInfo memory _info = nftInfo[nftAddress][_tokenId];
            if(_info.claimState == State.Active) {
                continue;
            }
            _info.claimState = State.Active;
            _info.activeTime = block.timestamp;
            nftInfo[nftAddress][_tokenId] = _info;
            emit changeClaimState(_tokenId, State.Active, _info.activeTime);
        }
    }
    
    function getClaimInfo(uint _tokenId) external view returns(ClaimInfo memory claimInfo){
        return nftInfo[nftAddress][_tokenId];
    }
    
    function getAllClaimInfo()  external view returns(ClaimInfo[] memory claimInfoList){
        return nftInfoList;
    }
    
    function getClaimLog(uint _tokenId) external view returns(ClaimLog memory claimLog) {
        return claimLogs[nftAddress][_tokenId];
    }
    
    function getAllClaimLog() external view returns(ClaimLog[] memory claimLog) {
        return claimLogList;
    }
    
	function getNFTBalance(address _addr) public view returns(uint) {
	    return _tokenTransferNFT.balanceOf(_addr);
	}
	
	
	function getNFTTokenIds(address _addr) public view returns(uint[] memory) {
	    return _tokenTransferNFT.tokensOfOwner(_addr);
	}
	
	
	function getCoinBalance(address _addr) public view returns(uint) {
	    return _tokenTransferCoin.balanceOf(_addr);
	}
}