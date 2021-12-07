/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
  function policy() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
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

    function sub32(uint32 a, uint32 b) internal pure returns (uint32) {
        return sub32(a, b, "SafeMath: subtraction overflow");
    }

    function sub32(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        uint32 c = a - b;

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

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
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

    function functionCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target, 
        bytes memory data, 
        uint256 value, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target, 
        bytes memory data, 
        uint256 weiValue, 
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success, 
        bytes memory returndata, 
        string memory errorMessage
    ) private pure returns(bytes memory) {
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender)
            .sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
}

interface IStakingHelper {
    function stake( uint _amount, address _recipient ) external;
}

contract DawgstasInduction is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using SafeMath for uint32;




    /* ======== EVENTS ======== */

    event TokensBought( uint indexed buy);
    event TokensClaimed( address indexed recipient, uint claim, uint remaining );
    event addedAllocations( address[] wallet );




    /* ======== STATE VARIABLES ======== */

    address public immutable Dawgsta; // token being purchased
    address public immutable BUSD; // token used purchase DAWG
    address public immutable DAO; // withdraw unsold tokens and sale amounts

    uint public immutable tokenPrice; // price of each token
    uint public immutable maxBuyPerWallet; // maximum number of tokens that can be bought
    uint32 public immutable vestingTerm; // seconds the purchased tokens are vested for

    mapping( address => uint ) public buyAmount; // stores number of tokens purchased
    mapping( address => uint ) public allocAmount; // stores number of tokens allocated for claim
    mapping( address => uint ) public claimAmount; // stores number of tokens claimed

    uint public totalSold; // total number of sold tokens
    uint public totalAllocated; // total number of tokens allocated for claim
    bool public saleOngoing; // check for sale
    uint32 public vestingStart; // timestamp for start of vesting

    address public staking; // to auto-stake tokens
    address public stakingHelper; // to stake and claim if no staking warmup
    bool public useHelper;




    /* ======== INITIALIZATION ======== */

    constructor ( 
        address _Dawgsta,
        address _BUSD,
        address _DAO, 
        uint _tokenPrice, // in BUSD
        uint _maxBuyPerWallet, // in BUSD
        uint32 _vestingTerm // in seconds; 15 days = 1296000 seconds
    ) {
        Dawgsta = _Dawgsta;
        BUSD = _BUSD;
        DAO = _DAO;
        tokenPrice = _tokenPrice;
        maxBuyPerWallet = _maxBuyPerWallet.mul( 10 ** IERC20( _BUSD ).decimals() ).div( _tokenPrice ).div(10 ** IERC20( _Dawgsta ).decimals());
        vestingTerm = _vestingTerm;
    }



    
    /* ======== POLICY FUNCTIONS ======== */

    /**
     *  @notice toggles the sale on or off
     */
    function toggleSale() external onlyPolicy() {
        bool result = !saleOngoing;
        saleOngoing = result;
    }

    /**
     *  @notice adds wallets and their allocations
     *  @param _addresses address[]
     *  @param _allocations uint[]
     */
    function addAllocations(address[] memory _addresses, uint[] memory _allocations) external onlyPolicy() {
        require( _addresses.length == _allocations.length );
        for (uint i = 0; i < _addresses.length; i++) {
            setAllocation( _addresses[i], _allocations[i] );
        }
        emit addedAllocations(_addresses);
    }

    /**
     *  @notice starts vesting
     */
    function startVesting() external onlyPolicy() {
        vestingStart = uint32(block.timestamp);
    }

    /**
     *  @notice withdraw unsold tokens or any other token sent by mistake
     *  @param _token address
     */
    function recoverToken( address _token ) external onlyPolicy() {
        if (_token == Dawgsta) {
            //withdraw remaining, unsold Dawgsta
            require(!saleOngoing, "Sale Ongoing");
            uint balance = IERC20( Dawgsta ).balanceOf( address(this) );
            IERC20( Dawgsta ).safeTransfer( DAO, balance.sub(totalAllocated) );
        } else {
            IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
        }
    }

    /**
     *  @notice set contract for auto stake
     *  @param _staking address
     *  @param _helper bool
     */
    function setStaking( address _staking, bool _helper ) external onlyPolicy() {
        require( _staking != address(0) );
        if ( _helper ) {
            useHelper = true;
            stakingHelper = _staking;
        } else {
            useHelper = false;
            staking = _staking;
        }
    }


    

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice buy dawg
     *  @param _amount uint
     *  @return uint
     */
    function buyDawg( uint _amount ) external returns ( uint ) {
        require( saleOngoing, "Sale not ongoing");
        require( totalSold <= IERC20( Dawgsta ).balanceOf( address(this) ), "Max capacity reached" );

        uint busdBalance = IERC20( BUSD ).balanceOf( address(this) );
        IERC20( BUSD ).safeTransferFrom( msg.sender, address(this), _amount );
        uint busdReceived = IERC20( BUSD ).balanceOf( address(this) ).sub( busdBalance );
        
        //calculating amount of dawg in dawg decimals
        uint dawgAmount = busdReceived.mul( 10 ** IERC20( Dawgsta ).decimals() )
                                .div( tokenPrice ).div( 10 ** IERC20( BUSD ).decimals() );
        uint busdReturn = 0;
        uint busdSpent = 0;
        
        //auto-adjusting purchase to fit within max limit
        //allows a user to make multiple purchases without accounting for the net purchase
        if ( buyAmount[ msg.sender ].add( dawgAmount ) > maxBuyPerWallet) {
            dawgAmount = maxBuyPerWallet.sub( buyAmount[ msg.sender ] );
            busdSpent = dawgAmount.mul( 10 ** IERC20( BUSD ).decimals() ).mul( tokenPrice ).div( 10 ** IERC20( Dawgsta ).decimals() );
            busdReturn = busdReceived.sub( busdSpent );
        }
        
        if ( dawgAmount > 0 ) {
            buyAmount[ msg.sender ] = buyAmount[ msg.sender ].add( dawgAmount ); //buyer account is updated
            totalSold = totalSold.add( dawgAmount ); //total sold is increased
            setAllocation( msg.sender, dawgAmount ); // bought tokens allocated to buyer
            IERC20( BUSD ).safeTransfer( DAO, busdReceived.sub(busdReturn) ); //busd is sent to the DAO
        }

        //return any additional busd
        if (busdReturn > 0) {
            IERC20( BUSD ).safeTransfer( msg.sender, busdReturn ); //revert if fallback of msg.sender has heavy opertions
        }
        
        // indexed events are emitted
        emit TokensBought( dawgAmount );

        return dawgAmount; 
    }

    /** 
     *  @notice claim unlocked tokens
     *  @param _stake bool
     *  @return uint
     */ 
    function claimDawg( bool _stake ) external returns ( uint ) {        
        require( vestingStart != 0, "Vesting has not started");

        // (seconds since vesting start / vesting term passed)
        uint secondsSinceStart = uint32(block.timestamp).sub( vestingStart );
        uint percentVested = secondsSinceStart.mul( 10000 ).div( vestingTerm );
        uint dawgUnlocked = 0;

        if ( percentVested >= 10000 ) { // if fully vested
            dawgUnlocked = allocAmount[ msg.sender ].sub( claimAmount[ msg.sender ] );
            claimAmount[ msg.sender ] = allocAmount[ msg.sender ];
            emit TokensClaimed( msg.sender, dawgUnlocked, 0 ); // emit bond data
            return stakeOrSend( msg.sender, _stake, dawgUnlocked ); // pay user everything due

        } else { // if unfinished
            // calculate dawg unlocked
            uint dawgAmount = allocAmount[ msg.sender ].mul( percentVested ).div( 10000 );
            dawgUnlocked = dawgAmount.sub( claimAmount[ msg.sender ] );
            
            // increase claimed dawgs
            claimAmount[ msg.sender ] = claimAmount [ msg.sender ].add(dawgUnlocked);

            emit TokensClaimed( msg.sender, dawgUnlocked,  allocAmount[ msg.sender ].sub( claimAmount[ msg.sender ] ) );
            return stakeOrSend( msg.sender, _stake, dawgUnlocked );
        }
    }



    
    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to stake tokens automatically
     *  @param _stake bool
     *  @param _amount uint
     *  @return uint
     */
    function stakeOrSend( address _recipient, bool _stake, uint _amount ) internal returns ( uint ) {
        if ( !_stake ) { // if user does not want to stake
            IERC20( Dawgsta ).transfer( _recipient, _amount ); // send payout
        } else { // if user wants to stake
            if ( useHelper ) { // use if staking warmup is 0
                IERC20( Dawgsta ).approve( stakingHelper, _amount );
                IStakingHelper( stakingHelper ).stake( _amount, _recipient );
            } else {
                IERC20( Dawgsta ).approve( staking, _amount );
                IStaking( staking ).stake( _amount, _recipient );
            }
        }
        return _amount;
    }

    /**
     *  @notice assigns a wallets its allocations
     *  @param _wallet address
     *  @param _allocation uint
     */
    function setAllocation(address _wallet, uint _allocation) internal {
        uint dawgAmount = _allocation;
        allocAmount[ _wallet ] = allocAmount[ _wallet ].add( dawgAmount );
        
        totalAllocated = totalAllocated.add( dawgAmount );
    }




    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice calculate amount of Dawg outstanding for wallet
     *  @param _wallet address
     *  @return pendingDawg_ uint
     */
    function pendingDawg( address _wallet ) external view returns ( uint pendingDawg_ ) {
        pendingDawg_ = allocAmount[ _wallet ].sub( claimAmount[ _wallet ] );
    }

    /**
     *  @notice calculate amount of Dawg available for wallet to claim
     *  @param _wallet address
     *  @return claimableDawg_ uint
     */
    function claimableDawg( address _wallet ) external view returns ( uint claimableDawg_ ) {
        uint secondsSinceStart = uint32(block.timestamp).sub( vestingStart );
        uint percentVested = secondsSinceStart.mul( 10000 ).div( vestingTerm );

        if ( percentVested >= 10000 ) {
            claimableDawg_ = allocAmount[ _wallet ].sub( claimAmount[ _wallet ] );
        } else {
            uint dawgAmount = allocAmount[ _wallet ].mul( percentVested ).div( 10000 );
            claimableDawg_ = dawgAmount.sub( claimAmount[ _wallet ] );
        }
    }
}